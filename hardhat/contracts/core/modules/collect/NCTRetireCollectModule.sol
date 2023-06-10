// SPDX-License-Identifier: MIT

/**
 * This NCTRetireCollectModule is a fork of the FeeCollectModule.
 * Instead of transfering the fee to the recipient, the fee is used to buy and retire
 * NCT tokens. You can find our retire functions from line 167 to line 204.
 */

pragma solidity ^0.8.10;

import {ICollectModule} from '../../../interfaces/ICollectModule.sol';
import {Errors} from '../../../libraries/Errors.sol';
import {FeeModuleBase} from '../FeeModuleBase.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidationModuleBase} from '../FollowValidationModuleBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IToucanOffsetHelper} from '../../../interfaces/IToucanOffsetHelper.sol';

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param amount The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param recipient The recipient address associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 */
struct ProfilePublicationData {
    uint256 amount;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
}

/**
 * @title NTCRetireCollectModule
 * @author Lens Protocol & ToucanFrens
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract. It was developed further by ToucanFrens to retire carbon credits (NCTs) direcly
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract NCTRetireCollectModule is FeeModuleBase, FollowValidationModuleBase, ICollectModule {
    using SafeERC20 for IERC20;

    //Constants
    address public immutable NATURE_CARBON_TONNE;
    address public immutable TOUCAN_OFFSET_HELPER;

    //Mapping
    mapping(uint256 => mapping(uint256 => ProfilePublicationData))
        internal _dataByPublicationByProfile;

    //Events
    event LogNCTretired(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed pubId,
        uint256 amount
    );

    //Constructor
    constructor(
        address hub,
        address moduleGlobals,
        address natureCarbonTonne,
        address toucanOffsetHelper
    ) FeeModuleBase(moduleGlobals) ModuleBase(hub) {
        NATURE_CARBON_TONNE = natureCarbonTonne;
        TOUCAN_OFFSET_HELPER = toucanOffsetHelper;
    }

    /**
     * @notice This collect module levies a fee on collects and supports referrals. Thus, we need to decode data.
     *
     * @param profileId The token ID of the profile of the publisher, passed by the hub.
     * @param pubId The publication ID of the newly created publication, passed by the hub.
     * @param data The arbitrary data parameter, decoded into:
     *      uint256 amount: The currency total amount to levy.
     *      address currency: The currency address, must be internally whitelisted.
     *      address recipient: The custom recipient address to direct earnings to.
     *      uint16 referralFee: The referral fee to set.
     *      bool followerOnly: Whether only followers should be able to collect.
     *
     * @return bytes An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            uint256 amount,
            address currency,
            address recipient,
            uint16 referralFee,
            bool followerOnly
        ) = abi.decode(data, (uint256, address, address, uint16, bool));
        if (
            !_currencyWhitelisted(currency) ||
            recipient == address(0) ||
            referralFee > BPS_MAX ||
            amount == 0
        ) revert Errors.InitParamsInvalid();

        _dataByPublicationByProfile[profileId][pubId].amount = amount;
        _dataByPublicationByProfile[profileId][pubId].currency = currency;
        _dataByPublicationByProfile[profileId][pubId].recipient = recipient;
        _dataByPublicationByProfile[profileId][pubId].referralFee = referralFee;
        _dataByPublicationByProfile[profileId][pubId].followerOnly = followerOnly;

        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower
     *  2. Charging a fee
     */
    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external virtual override onlyHub {
        if (_dataByPublicationByProfile[profileId][pubId].followerOnly)
            _checkFollowValidity(profileId, collector);
        if (referrerProfileId == profileId) {
            _processCollect(collector, profileId, pubId, data);
        } else {
            _processCollectWithReferral(referrerProfileId, collector, profileId, pubId, data);
        }
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(uint256 profileId, uint256 pubId)
        external
        view
        returns (ProfilePublicationData memory)
    {
        return _dataByPublicationByProfile[profileId][pubId];
    }

    /**
     * @notice Retires automatically NCT tokens
     *
     * @param collector Public address of user who is collection.
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     * @param currency The currency address, must be internally whitelisted.
     * @param adjustedAmount The adjusted amount of the ERC20 which will be swapped to buy and retire NCT.
     *
     */
    function _retireNCT(
        address collector,
        uint256 profileId,
        uint256 pubId,
        address currency,
        uint256 adjustedAmount
    ) internal {
        //Calculate how much ERC20 token ("currency") is required
        //in order to swap for the desired amount of a NCT
        uint256 amountOfNCT = IToucanOffsetHelper(TOUCAN_OFFSET_HELPER).calculateNeededTokenAmount(
            NATURE_CARBON_TONNE,
            currency,
            adjustedAmount
        );

        IToucanOffsetHelper(TOUCAN_OFFSET_HELPER).autoOffsetUsingToken(
            currency,
            NATURE_CARBON_TONNE,
            amountOfNCT
        );

        emit LogNCTretired(collector, profileId, pubId, amountOfNCT);
    }

    function _retireNCTwithNCT(
        address collector,
        uint256 profileId,
        uint256 pubId,
        uint256 adjustedAmount
    ) internal {
        IToucanOffsetHelper(TOUCAN_OFFSET_HELPER).autoOffsetUsingPoolToken(
            NATURE_CARBON_TONNE,
            adjustedAmount
        );

        //NCT was already the currency that is retired
        emit LogNCTretired(collector, profileId, pubId, adjustedAmount);
    }

    function _processCollect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        _validateDataIsExpected(data, currency, amount);

        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;

        //Retire NCT
        if (currency != NATURE_CARBON_TONNE) {
            _retireNCT(collector, profileId, pubId, currency, adjustedAmount);
        } else {
            _retireNCTwithNCT(collector, profileId, pubId, adjustedAmount);
        }

        if (treasuryAmount > 0)
            IERC20(currency).safeTransferFrom(collector, treasury, treasuryAmount);
    }

    function _processCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        _validateDataIsExpected(data, currency, amount);

        uint256 referralFee = _dataByPublicationByProfile[profileId][pubId].referralFee;
        address treasury;
        uint256 treasuryAmount;

        // Avoids stack too deep
        {
            uint16 treasuryFee;
            (treasury, treasuryFee) = _treasuryData();
            treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        }

        uint256 adjustedAmount = amount - treasuryAmount;

        if (referralFee != 0) {
            // The reason we levy the referral fee on the adjusted amount is so that referral fees
            // don't bypass the treasury fee, in essence referrals pay their fair share to the treasury.
            uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;
            adjustedAmount = adjustedAmount - referralAmount;

            address referralRecipient = IERC721(HUB).ownerOf(referrerProfileId);

            IERC20(currency).safeTransferFrom(collector, referralRecipient, referralAmount);
        }

        //Retire NCT
        if (currency != NATURE_CARBON_TONNE) {
            _retireNCT(collector, profileId, pubId, currency, adjustedAmount);
        } else {
            _retireNCTwithNCT(collector, profileId, pubId, adjustedAmount);
        }

        if (treasuryAmount > 0)
            IERC20(currency).safeTransferFrom(collector, treasury, treasuryAmount);
    }
}
