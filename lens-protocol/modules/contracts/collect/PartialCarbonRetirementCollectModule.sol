// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {ICollectModule} from '@aave/lens-protocol/contracts/interfaces/ICollectModule.sol';
import {Errors} from '@aave/lens-protocol/contracts/libraries/Errors.sol';
import {FeeModuleBase} from '@aave/lens-protocol/contracts/core/modules/FeeModuleBase.sol';
import {ModuleBase} from '@aave/lens-protocol/contracts/core/modules/ModuleBase.sol';
import {FollowValidationModuleBase} from '@aave/lens-protocol/contracts/core/modules/FollowValidationModuleBase.sol';

//import {BaseFeeCollectModule} from './base/BaseFeeCollectModule.sol';
//import {BaseFeeCollectModuleInitData, BaseProfilePublicationData} from './base/IBaseFeeCollectModule.sol';

import {IKlimaRetirementAggregator} from '../interfaces/IKlimaRetirementAggregator.sol';

// TODO: check and implement switch from recipientAmount, retirementAmount to
// amount, retirementFraction
// reason: initial idea was to avoid the calculation of recipientAmount, retirementAmount
// during each collect, but current implementation might be problematic with spending
// allowance of the currency (would require allowance of sum of the amounts)

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 * @param recipientAmount The collecting cost associated with this publication. 0 for free collect.
 * @param currency The currency associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 * @param recipient The recipient address associated with this publication.
 * @param endTimestamp The end timestamp after which collecting is impossible.
 * @param currentCollects The current number of collects for this publication.
 * @param collectLimit The maximum number of collects for this publication (0 for unlimited)
 * @param poolToken The carbon token to be used for carbon retirement.
 * @param retirementAmount Amount that goes into carbon retirement.
 */
struct ProfilePublicationData {
    uint160 recipientAmount;
    address currency;
    uint16 referralFee;
    bool followerOnly;
    address recipient;
    uint40 endTimestamp;
    uint64 currentCollects;
    uint64 collectLimit;
    address poolToken;
    uint160 retirementAmount;
}

/**
 * @notice A struct containing the necessary data to initialize Stepwise Collect Module.
 * @param recipientAmount The collecting cost associated with this publication. 0 for free collect.
 * @param collectLimit The maximum number of collects for this publication (0 for unlimited)
 * @param currency The currency associated with this publication.
 * @param recipient The recipient address associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 * @param endTimestamp The end timestamp after which collecting is impossible.
 * @param poolToken The carbon token to be used for carbon retirement.
 * @param retirementAmount Amount that goes into carbon retirement.
 */
struct PartialCarbonRetirementCollectModuleInitData {
    uint160 recipientAmount;
    uint64 collectLimit;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
    uint40 endTimestamp;
    address poolToken;
    uint160 retirementAmount;
}

/**
 * @title PartialCarbonRetirementCollectModule
 * @author Lens Protocol
 *
 * @notice This module sends a chosen fraction of the collect fee to perform carbon retirement.
 *
 */
contract PartialCarbonRetirementCollectModule is FeeModuleBase, FollowValidationModuleBase, ICollectModule {
    using SafeERC20 for IERC20;

    address public immutable RETIREMENT_HELPER;

    mapping(uint256 => mapping(uint256 => ProfilePublicationData))
        internal _dataByPublicationByProfile;

    constructor(address hub, address moduleGlobals, address retirementHelper) FeeModuleBase(moduleGlobals) ModuleBase(hub) {
        RETIREMENT_HELPER = retirementHelper;
    }

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
     *        pooltToken:
     *        retirementAmount:
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
            if (
                !checkRetirementSwapFeasibility(initData.currency, initData.poolToken, initData.retirementAmount) ||
                !_currencyWhitelisted(initData.currency) ||
                //initData.recipient == address(0) || // TODO: should this be included?
                initData.referralFee > BPS_MAX ||
                (initData.endTimestamp != 0 && initData.endTimestamp < block.timestamp) 
            ) revert Errors.InitParamsInvalid();
        }

        _dataByPublicationByProfile[profileId][pubId] = ProfilePublicationData({
            recipientAmount: initData.recipientAmount,
            currency: initData.currency,
            referralFee: initData.referralFee,
            followerOnly: initData.followerOnly,
            recipient: initData.recipient,
            endTimestamp: initData.endTimestamp,
            currentCollects: 0,
            collectLimit: initData.collectLimit,
            poolToken: initData.poolToken,
            retirementAmount: initData.retirementAmount
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
                _processPartialRetirementCollect(collector, profileId, pubId, data);
            } else {
                _processPartialRetirementCollectWithReferral(referrerProfileId, collector, profileId, pubId, data);
            }
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
    function _processPartialRetirementCollect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal virtual {

        address currency = _dataByPublicationByProfile[profileId][pubId].currency;
        uint160 recipientAmount = _dataByPublicationByProfile[profileId][pubId].recipientAmount;

        // TODO: this part is not understood, with regards to calldata. Also unclear if it makes sense.
        // this validation is regarding the core funtionality without the retirement
        _validateDataIsExpected(data, currency, recipientAmount);
        // this validation is regarding the retirement
        _validateCarbonDataIsExpected(data, currency, _dataByPublicationByProfile[profileId][pubId].retirementAmount);

        // Attempt retirement
        // TODO: Do only if checkSwapFeasibility works.
        // Otherwise skip and either send everything to publisher or leave retirementAmount in collectors wallet.
        if (checkRetirementSwapFeasibility(
            currency, 
            _dataByPublicationByProfile[profileId][pubId].poolToken, 
            _dataByPublicationByProfile[profileId][pubId].retirementAmount))
            {
                _retireCarbon(
                    collector, 
                    collector,
                    pubId,
                    currency,
                    _dataByPublicationByProfile[profileId][pubId].poolToken,
                    _dataByPublicationByProfile[profileId][pubId].retirementAmount
                    );
            }

        (address treasury, uint16 treasuryFee) = _treasuryData();
        uint256 treasuryAmount = (recipientAmount * treasuryFee) / BPS_MAX;

        // Send amount after treasury cut, to all recipients
        _transferToRecipients(currency, collector, profileId, pubId, recipientAmount - treasuryAmount);

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
    function _processPartialRetirementCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal virtual {
        // TODO: implement
    }

    function _retireCarbon(
        address collector,
        address beneficiary,
        uint256 pubId,
        address currency,
        address poolToken,
        uint256 retirementAmount
    ) internal {
        // TODO: do in calling function, not here, to be able to wrap into if statement
        // require(checkRetirementSwapFeasibility(currency, poolToken, retirementAmount));
        
        // Swap adjusted fee to carbon and retire
        string memory retirementMessage = string(abi.encodePacked(
            "Lens Protocol carbon retirement for collect of publication: ",
            Strings.toString(pubId)
        ));

        // TODO: does Lens only use erc20 tokens for collects or are native currency or other allowed, too?
        // In that case, handle those currencies accordingly
        // Transfer retirementAmount to be retired to the retirement helper contract
        IERC20(currency).safeTransferFrom(collector, RETIREMENT_HELPER, retirementAmount);

        IKlimaRetirementAggregator(RETIREMENT_HELPER).retireCarbonFrom(
            beneficiary, //TODO: should this be collector, because above safeTransferFrom was done from collector?
            currency,
            poolToken,
            retirementAmount,
            false,
            beneficiary,
            "Lens Protocol Profile",
            retirementMessage
        );
    }

    /**
     * @dev Tranfers the fee to recipient
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

    // TODO: this part is not understood, with regards to calldata. Also unclear if it makes sense.
    function _validateCarbonDataIsExpected(
        bytes calldata data,
        address currency,
        uint256 amount
    ) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency)
            revert Errors.ModuleDataMismatch();
    }
    
    /**
     * @dev Check if retirementAggregator can swap from currency to poolToken:
     *
     * @param _sourceToken Address of the source token that is used to pay the retirement.
     * @param _poolToken Address of the carbon pool token that is used for retirement.
     * @param _amount Amount of the source token that is used for retirement.
     *
     * @return The ProfilePublicationData struct mapped to that publication.
     */
    function checkRetirementSwapFeasibility(
        address _sourceToken,
        address _poolToken,
        uint256 _amount
    ) external view returns (bool) {

        // TODO: This function should not fail, but always return true/false
        // Reason: 
        // - During module init, it doesn't matter. It can also fail.
        // - During processCollect, it should not fail, but instead lead to normal collect.

        try IKlimaRetirementAggregator(RETIREMENT_HELPER).isPoolToken(_poolToken) returns (bool result) {
            emit Log("poolToken accepted": result);
        } catch {
            emit Log("poolToken not accepted.");
            return false;
        }

        //require(IKlimaRetirementAggregator(RETIREMENT_HELPER).isPoolToken(_poolToken), "Pool Token Not Accepted.");
        
        // Check if path from currency to poolToken exists
        // TODO: Make sure the requirement really fails if no path exists. 
        // Behaviour:
        // No swap path exists: will raise error and revert transaction
        // -> collect would fail
        // Swap path exists: will return numbers for checkedSourceAmount and checkedPoolAmount
        // -> collect would succeed
        // Liquidity low: will return values, but checkedPoolAmount will saturate to a max value
        // -> I guess, collect would succeed, but retired carbon would be low
        try IKlimaRetirementAggregator(RETIREMENT_HELPER).getSourceAmount(_sourceToken, _poolToken, _amount, false) returns (uint256 checkedSourceAmount, uint256 checkedPoolAmount) {
            emit Log("poolAmount is": checkedPoolAmount);
            if (checkedPoolAmount !> 0) {
                emit Log("poolAmount is not greater zero");
                return false;
            }
        } catch {
            emit Log("Swap path from sourceToken to poolToken not found.");
            return false;
        }

        //(uint256 checkedSourceAmount, uint256 checkedPoolAmount) = IKlimaRetirementAggregator(RETIREMENT_HELPER).getSourceAmount(_sourceToken, _poolToken, _amount, false);
        //require(checkedPoolAmount > 0, "No swap path from currency to poolToken found.");
        // return true only if no fail
        return true;
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
    function getPublicationData(uint256 profileId, uint256 pubId)
        external
        view
        virtual
        returns (ProfilePublicationData memory)
    {
        return _dataByPublicationByProfile[profileId][pubId];
    }
}
