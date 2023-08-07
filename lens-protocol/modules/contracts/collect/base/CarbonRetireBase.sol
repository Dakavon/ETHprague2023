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
     * @param currency Fee currency of publication
     * @param poolToken carbon pool token for retirement
     * @param retirementAmount Amount of currency that goes into carbon retirement
     */
    function _retireCarbon(
        address collector, 
        address recipient,
        address currency,
        address poolToken,
        uint256 retirementAmount,
        string memory retiringEntityString,
        string memory beneficiaryString,
        string memory retirementMessage
    ) internal {
        // Transfer retirementAmount
        // 2 transfers, because retirement function requires that token is received by msg.sender,
        // which is collect module, not collector wallet (tx.origin).
        IERC20(currency).safeTransferFrom(collector, address(this), retirementAmount);
        IERC20(currency).safeTransfer(KLIMA_INFINITY, retirementAmount);

        // TODO:  
        // There's another safeTransferFrom inside retirement function, but with 0 amount
        // https://github.com/KlimaDAO/klimadao-solidity/blob/88ff87907f8319407728b1488323ce9912cdd3ed/src/infinity/libraries/Token/LibTransfer.sol#L52
        // --> Will this require an approval by address(this)??
        // --> Does fromMode INTERNAL solve it?

        IKlimaInfinity(KLIMA_INFINITY).retireExactSourceDefault(
            currency,
            poolToken,
            retirementAmount,
            retiringEntityString,
            recipient, 
            beneficiaryString,
            retirementMessage,
            1 // TODO: Is 1 equal fromMode INTERNAL? https://github.com/KlimaDAO/klimadao-solidity/blob/88ff87907f8319407728b1488323ce9912cdd3ed/src/infinity/libraries/Token/LibTransfer.sol#L17
            );
    }

    /**
     * @dev Check if retirementAggregator can swap from currency to poolToken.
     * 
     * This function should not fail, but always return true/false
     * Reason: processCollect should not fail, but instead lead to normal collect.
     *
     * @param sourceToken Address of the source token that is used to pay the retirement.
     * @param poolToken Address of the carbon pool token that is used for retirement.
     * @param amountIn Amount of the source token that is used for retirement.
     *
     * @return The ProfilePublicationData struct mapped to that publication.
     */
    function checkRetirementSwapFeasibility(
        address sourceToken,
        address poolToken,
        uint256 amountIn
    ) public view returns (bool) {

        if ( !(amountIn > 0) ) {
            return false;
            }

        // TODO: Check if desired behaviour is fulfilled:
        // - _poolToken is not accepted by KlimaInfinity: return false
        // - No swap path exists: return false
        // - _poolToken accepted and swap path exists: return true
        // - Check on liquidity/slippage/price_impact possible???
        
        try IKlimaInfinity(KLIMA_INFINITY).getRetireAmountSourceDefault(sourceToken, poolToken, amountIn) returns (uint256 amountOut) {
            if ( !(amountOut > 0) ) {
                return false;
            }
        } catch {
            return false;
        }
        return true;
    }
    
}