// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {Errors} from '@aave/lens-protocol/contracts/libraries/Errors.sol';
import {IKlimaInfinity} from '../../interfaces/IKlimaInfinity.sol';


/**
 * @title CarbonRetireBase
 * @author 
 *
 * @notice Abstract contract for carbon retirements
 * 
 * basic layout copied from https://github.com/lens-protocol/core/blob/main/contracts/core/modules/FeeModuleBase.sol
 */
abstract contract CarbonRetireBase {
    using SafeERC20 for IERC20;

    // https://github.com/KlimaDAO/klimadao-solidity/blob/main/src/protocol/bonds/CarbonRetirementBondDepository.sol#L27
    address public immutable KLIMA_INFINITY;

    constructor(address _klimaInfinity) {
        KLIMA_INFINITY = _klimaInfinity;
    }

    /**
     * @dev Performs carbon retirement
     *
     * @param collector The address that collects the post
     * @param recipient The address that published the publication and receives the fee
     * @param pubId The token ID of publication
     * @param profileId The token ID of the profile of collector
     * @param currency Fee currency of publication
     * @param poolToken carbon pool token for retirement
     * @param retirementAmount Amount of currency that goes into carbon retirement
     */
    function _retireCarbon(
        address collector, 
        address recipient,
        uint256 pubId,
        uint256 profileId,
        address currency,
        address poolToken,
        uint256 retirementAmount
    ) internal {

        // Messages to make retirement better connected to 
        // collector, recipient, profileId, pubId
        // (but that alone not fool-proof -> anyone could add such messages to a retirement)
        // otherwise:
        // collector --> visible as tx.origin
        // recipient/publisher --> beneficiary
        // profileId of collector and pubId of publication: retirement message (? could be faked, but call by module might be good filter)
        string memory retiringEntityString = string(abi.encodePacked(
            "Collecting Lens profile: ",
            Strings.toString(profileId), 
            ", by collector:", 
            Strings.toHexString(collector) 
        ));
        string memory beneficiaryString = string(abi.encodePacked(
            "Lens publication: ",
            Strings.toString(pubId),
            ", by publisher: ",
            Strings.toHexString(recipient)
        ));
        string memory retirementMessage = string(abi.encodePacked(
            "Lens Protocol carbon retirement for collect of publication: ",
            Strings.toString(pubId)
        ));

        // Transfer retirementAmount
        IERC20(currency).safeTransferFrom(collector, address(this), retirementAmount);
        IERC20(currency).safeTransfer(KLIMA_INFINITY, retirementAmount);

        // TODO: 
        // Retirement function requires that token is received by msg.sender,
        // which is the collect module, not the collector wallet (tx.origin).
        // There's another safeTransferFrom inside retirement function, but with 0 amount
        // https://github.com/KlimaDAO/klimadao-solidity/blob/88ff87907f8319407728b1488323ce9912cdd3ed/src/infinity/libraries/Token/LibTransfer.sol#L52
        // --> Will this require an approval by address(this)??
        // --> check if fromMode INTERNAL solves it

        IKlimaInfinity(KLIMA_INFINITY).retireExactSourceDefault(
            currency,
            poolToken,
            retirementAmount,
            retiringEntityString,
            recipient, 
            beneficiaryString,
            retirementMessage,
            1 // TODO: check if this is fromMode INTERNAL https://github.com/KlimaDAO/klimadao-solidity/blob/88ff87907f8319407728b1488323ce9912cdd3ed/src/infinity/libraries/Token/LibTransfer.sol#L17
            );
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
     * @dev Check if retirementAggregator can swap from currency to poolToken.
     * 
     * TODO: This function should not fail, but always return true/false
     * Reason: 
     * - During module init, it doesn't matter. It can also fail.
     * - During processCollect, it should not fail, but instead lead to normal collect.
     *
     * @param _sourceToken Address of the source token that is used to pay the retirement.
     * @param _poolToken Address of the carbon pool token that is used for retirement.
     * @param _amountIn Amount of the source token that is used for retirement.
     *
     * @return The ProfilePublicationData struct mapped to that publication.
     */
    function checkRetirementSwapFeasibility(
        address _sourceToken,
        address _poolToken,
        uint256 _amountIn
    ) public view returns (bool) {

        if (!(_amountIn > 0)) {
            //emit Log("Cannot retire zero tonnes");
            return false;
            }

        // TODO: Check if desired behaviour is fulfilled:
        // - _poolToken is not accepted by KlimaInfinity: return false
        // - No swap path exists: return false
        // - _poolToken accepted and swap path exists: return true
        // - Check on liquidity/slippage possible??
        
        try IKlimaInfinity(KLIMA_INFINITY).getRetireAmountSourceDefault(_sourceToken, _poolToken, _amountIn) returns (uint256 amountOut) {
            //emit Log("Carbon amount is:", amountOut);
            if (!(amountOut > 0)) {
                //emit Log("Carbon amount is not greater zero");
                return false;
            }
        } catch {
            //emit Log("Swap path from sourceToken to poolToken not found.");
            return false;
        }
        return true;
    }
}