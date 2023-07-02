// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IKlimaInfinity {

    // https://github.com/KlimaDAO/klimadao-solidity/blob/main/src/infinity/facets/Retire/RetireSourceFacet.sol#L35
    function retireExactSourceDefault(
        address sourceToken,
        address poolToken,
        uint256 maxAmountIn,
        string memory retiringEntityString,
        address beneficiaryAddress,
        string memory beneficiaryString,
        string memory retirementMessage,
        uint8 fromMode
    ) external payable returns (uint256 retirementIndex);

    /* Views */

    // https://github.com/KlimaDAO/klimadao-solidity/blob/main/src/infinity/facets/RetirementQuoter.sol#L88
    function getRetireAmountSourceDefault(
        address sourceToken,
        address carbonToken,
        uint amount
    ) external view returns (uint amountOut);
}