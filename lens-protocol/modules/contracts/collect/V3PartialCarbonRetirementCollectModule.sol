// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import {ICollectModule} from '@aave/lens-protocol/contracts/interfaces/ICollectModule.sol';
import {Errors} from '@aave/lens-protocol/contracts/libraries/Errors.sol';
import {FeeModuleBase} from '@aave/lens-protocol/contracts/core/modules/FeeModuleBase.sol';
import {ModuleBase} from '@aave/lens-protocol/contracts/core/modules/ModuleBase.sol';
import {FollowValidationModuleBase} from '@aave/lens-protocol/contracts/core/modules/FollowValidationModuleBase.sol';

import {CarbonRetireBase} from './base/CarbonRetireBase.sol';

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 * @param amount The collecting cost associated with this publication. 0 for free collect.
 * @param currency The currency associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 * @param recipient The recipient address associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible.
 * @param currentCollects The current number of collects for this publication.
 * @param collectLimit The maximum number of collects for this publication (0 for unlimited)
 * @param poolToken The carbon token to be used for carbon retirement.
 * @param retirementSplit Fraction (BPS) of amount that goes into carbon retirement.
 */
struct ProfilePublicationData {
    uint160 amount;
    address currency;
    uint16 referralFee;
    bool followerOnly;
    address recipient;
    uint40 endTimestamp;
    uint64 currentCollects;
    uint64 collectLimit;
    address poolToken;
    uint16 retirementSplit;
}

/**
 * @notice A struct containing the necessary data to initialize Stepwise Collect Module.
 * @param amount The collecting cost associated with this publication. 0 for free collect.
 * @param collectLimit The maximum number of collects for this publication (0 for unlimited)
 * @param currency The currency associated with this publication.
 * @param recipient The recipient address associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 * @param endTimestamp The end timestamp after which collecting is impossible.
 * @param poolToken The carbon token to be used for carbon retirement.
 * @param retirementSplit Fraction (BPS) of amount that goes into carbon retirement.
 */
struct PartialCarbonRetirementCollectModuleInitData {
    uint160 amount;
    uint64 collectLimit;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
    uint40 endTimestamp;
    address poolToken;
    uint16 retirementSplit;
}

/**
 * @title PartialCarbonRetirementCollectModule
 * @author Lens Protocol
 *
 * @notice This module sends a chosen fraction of the collect fee to perform carbon retirement.
 *
 */
contract V3PartialCarbonRetirementCollectModule is
    CarbonRetireBase,
    FeeModuleBase,
    FollowValidationModuleBase,
    ICollectModule
{
    using SafeERC20 for IERC20;

    mapping(uint256 => mapping(uint256 => ProfilePublicationData))
        internal _dataByPublicationByProfile;

    constructor(
        address hub,
        address moduleGlobals,
        address klimaInfinity
    ) FeeModuleBase(moduleGlobals) ModuleBase(hub) CarbonRetireBase(klimaInfinity) {}

    /**
     * @notice This collect module levies a fee on collects and supports referrals. Thus, we need to decode data.
     * @param data The arbitrary data parameter, decoded into:
     *        recipientAmount: The collecting cost associated with this publication. 0 for free collect.
     *        collectLimit: The maximum number of collects for this publication. 0 for no limit.
     *        currency: The currency associated with this publication.
     *        referralFee: The referral fee associated with this publication.
     *        followerOnly: True if only followers of publisher may collect the post.
     *        endTimestamp: The end timestamp after which collecting is impossible. 0 for no expiry.
     *        recipient: Recipient of collect fees.
     *        pooltToken: Carbon token for retierement
     *        retirementSplit: Fration of amount to go to retirement
     *
     * @return An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external virtual onlyHub returns (bytes memory) {
        PartialCarbonRetirementCollectModuleInitData memory initData = abi.decode(
            data,
            (PartialCarbonRetirementCollectModuleInitData)
        );
        {
            uint256 retirementAmount = (initData.retirementSplit * initData.amount) / BPS_MAX;
            if (
                !checkRetirementSwapFeasibility(
                    initData.currency,
                    initData.poolToken,
                    retirementAmount
                ) ||
                !_currencyWhitelisted(initData.currency) ||
                // TODO: should this be included? Removed, because 100% retirement doesn't need recipient
                //initData.recipient == address(0) || 
                initData.referralFee > BPS_MAX ||
                (initData.endTimestamp != 0 && initData.endTimestamp < block.timestamp)
            ) revert Errors.InitParamsInvalid();
        }

        _dataByPublicationByProfile[profileId][pubId] = ProfilePublicationData({
            amount: initData.amount,
            currency: initData.currency,
            referralFee: initData.referralFee,
            followerOnly: initData.followerOnly,
            recipient: initData.recipient,
            endTimestamp: initData.endTimestamp,
            currentCollects: 0,
            collectLimit: initData.collectLimit,
            poolToken: initData.poolToken,
            retirementSplit: initData.retirementSplit
        });
        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower
     *  2. Ensuring the current timestamp is less than or equal to the collect end timestamp
     *  3. Ensuring the collect does not pass the collect limit
     *  4. Charging a fee
     *  5. Performing the retirement and collect
     *
     * @inheritdoc ICollectModule
     */
    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub {
        if (_dataByPublicationByProfile[profileId][pubId].followerOnly)
            _checkFollowValidity(profileId, collector);
        uint256 endTimestamp = _dataByPublicationByProfile[profileId][pubId].endTimestamp;
        if (endTimestamp != 0 && block.timestamp > endTimestamp) revert Errors.CollectExpired();

        if (
            _dataByPublicationByProfile[profileId][pubId].collectLimit != 0 &&
            _dataByPublicationByProfile[profileId][pubId].currentCollects >=
            _dataByPublicationByProfile[profileId][pubId].collectLimit
        ) {
            revert Errors.MintLimitExceeded();
        } else {
            unchecked {
                ++_dataByPublicationByProfile[profileId][pubId].currentCollects;
            }
            if (referrerProfileId == profileId) {
                _processCollect(collector, profileId, pubId, data);
            } else {
                _processCollectWithReferral(referrerProfileId, collector, profileId, pubId, data);
            }
        }
    }

    /**
     * @dev Internal processing of a collect:
     *  1. Calculation of fees
     *  2. Validation that fees are what collector expected
     *  3. Transfer of fees to recipient and treasury
     *
     * @param collector The address that will collect the post.
     * @param profileId The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function _processCollect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal virtual {
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        uint256 retirementAmount = (_dataByPublicationByProfile[profileId][pubId].retirementSplit *
            _dataByPublicationByProfile[profileId][pubId].amount) / BPS_MAX;

        // TODO: Learn what this does. Guess: checks that calldata of collect equals init data of publication
        _validateDataIsExpected(
            data,
            currency,
            _dataByPublicationByProfile[profileId][pubId].amount
        );

        // Try retirement and return recipientAmount.
        uint256 recipientAmount = _performCarbonRetirement(
                collector,
                _dataByPublicationByProfile[profileId][pubId].recipient,
                pubId,
                profileId,
                currency,
                _dataByPublicationByProfile[profileId][pubId].poolToken,
                retirementAmount
            );

        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (recipientAmount * treasuryFee) / BPS_MAX;

        // Send amount after treasury cut, to all recipients
        _transferToRecipients(
            currency,
            collector,
            profileId,
            pubId,
            recipientAmount - treasuryAmount
        );

        if (treasuryAmount > 0) {
            IERC20(currency).safeTransferFrom(collector, treasury, treasuryAmount);
        }
    }

    /**
     * @dev Internal processing of a collect:
     *  1. Calculation of fees
     *  2. Validation that fees are what collector expected
     *  3. Transfer of fees to recipient(-s) and treasury
     *
     * @param collector The address that will collect the post.
     * @param profileId The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function _processCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal virtual {
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        uint256 retirementAmount = (_dataByPublicationByProfile[profileId][pubId].retirementSplit *
            _dataByPublicationByProfile[profileId][pubId].amount) / BPS_MAX;

        // TODO: Learn what this does. Guess: checks that calldata of collect equals init data of publication
        _validateDataIsExpected(
            data,
            currency,
            _dataByPublicationByProfile[profileId][pubId].amount
        );

        // Try retirement and return recipientAmount.
        uint256 recipientAmount = _performCarbonRetirement(
                collector,
                _dataByPublicationByProfile[profileId][pubId].recipient,
                pubId,
                profileId,
                currency,
                _dataByPublicationByProfile[profileId][pubId].poolToken,
                retirementAmount
            );

        address treasury;
        uint256 treasuryAmount;

        // Avoids stack too deep
        {
            uint16 treasuryFee;
            (treasury, treasuryFee) = _treasuryData();
            treasuryAmount = (recipientAmount * treasuryFee) / BPS_MAX;
        }

        uint256 adjustedAmount = recipientAmount - treasuryAmount;
        adjustedAmount = _transferToReferrals(
            currency,
            referrerProfileId,
            collector,
            profileId,
            pubId,
            adjustedAmount
        );

        _transferToRecipients(currency, collector, profileId, pubId, adjustedAmount);

        if (treasuryAmount > 0) {
            IERC20(currency).safeTransferFrom(collector, treasury, treasuryAmount);
        }
    }

    /**
     * @dev Wrapper for carbon retirement:
     *  Creates retirement messages
     *  Performs (attempts) retirement
     *  Returns remaining recipient amount
     *
     * @param collector The address that will collect the post.
     * @param recipient The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param profileId Arbitrary data __passed from the collector!__ to be decoded.
     * @param currency Currency of the collect
     * @param poolToken Carbon pool token for retirement
     * @param retirementAmount Amount of currency to be retired
     */
    function _performCarbonRetirement(
        address collector, 
        address recipient,
        uint256 pubId,
        uint256 profileId,
        address currency,
        address poolToken,
        uint256 retirementAmount
    ) internal returns (uint256 recipientAmount) {
        // Perform retirement if checkSwapFeasibility works.
        if (
            checkRetirementSwapFeasibility(
                currency,
                poolToken,
                retirementAmount
            )
        ) {
            string memory retiringEntityString = string(
                abi.encodePacked(
                    'Collecting Lens profile: ',
                    Strings.toString(profileId),
                    ', by collector:',
                    Strings.toHexString(collector)
                )
            );
            string memory beneficiaryString = string(
                abi.encodePacked(
                    'Lens publication: ',
                    Strings.toString(pubId),
                    ', by publisher: ',
                    Strings.toHexString(recipient)
                )
            );
            string memory retirementMessage = string(
                abi.encodePacked(
                    'Lens Protocol carbon retirement for collect of publication: ',
                    Strings.toString(pubId)
                )
            );
            _retireCarbon(
                collector,
                recipient,
                currency,
                poolToken,
                retirementAmount,
                retiringEntityString,
                beneficiaryString,
                retirementMessage
            );

            recipientAmount = _dataByPublicationByProfile[profileId][pubId].amount - retirementAmount;
        } else {
            // TODO: Up to debate. This fallback sends everything to recipient with treasury fee for everything.
            recipientAmount = _dataByPublicationByProfile[profileId][pubId].amount;
            // TODO: Add event or something to signal to recipient that they should perform
            // a manual retirement of all failed retirements at a later time
        }
    }

    /**
     * @dev Transfers the fee to recipient
     *
     * Override this to add additional functionality (e.g. multiple recipients)
     *
     * @param currency Currency of the transaction
     * @param collector The address that collects the post (and pays the fee).
     * @param profileId The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param amount Amount to transfer to recipient(-s)
     */
    function _transferToRecipients(
        address currency,
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 amount
    ) internal virtual {
        address recipient = _dataByPublicationByProfile[profileId][pubId].recipient;

        if (amount > 0) {
            IERC20(currency).safeTransferFrom(collector, recipient, amount);
        }
    }

    /**
     * @dev Transfers the part of fee to referral(-s)
     *
     * Override this to add additional functionality (e.g. multiple referrals)
     *
     * @param currency Currency of the transaction
     * @param referrerProfileId The address of the referral.
     * @param collector The address that collects the post (and pays the fee).
     * @param profileId The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param adjustedAmount Amount of the fee after subtracting the Treasury part.
     */
    function _transferToReferrals(
        address currency,
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 adjustedAmount
    ) internal virtual returns (uint256) {
        uint256 referralFee = _dataByPublicationByProfile[profileId][pubId].referralFee;
        if (referralFee != 0) {
            // The reason we levy the referral fee on the adjusted amount is so that referral fees
            // don't bypass the treasury fee, in essence referrals pay their fair share to the treasury.
            uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;
            if (referralAmount > 0) {
                adjustedAmount = adjustedAmount - referralAmount;

                address referralRecipient = IERC721(HUB).ownerOf(referrerProfileId);

                // Send referral fee in normal ERC20 tokens
                IERC20(currency).safeTransferFrom(collector, referralRecipient, referralAmount);
            }
        }
        return adjustedAmount;
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 profileId,
        uint256 pubId
    ) external view virtual returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[profileId][pubId];
    }

}