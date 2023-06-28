
### function getSourceAmount
https://github.com/KlimaDAO/klimadao-solidity/blob/e1b1037908be955d34bcf2987f124bb4d7ad62de/src/retirement_v1/KlimaRetirementAggregator.sol#L543

for given source and pool tokens returns corresponding amounts

input:
  [source_token: address,
     pool_token: address,
     amount: number,
     amountInCarbon: false
     ]
return:
  - if swap path and liquidity exists:
    - amounts of source and pool token
  - if swap path does not exist:
    - error, reverted transaction
    - depending on tokens, e.g. uniswap error message
  - if liquitiy low:
    - pool token amount is inconsistent with current pricing
    - pool token amount will not increase if source token amount increases
  - if entered amount way too large
    - error, math mul failed

swap paths:
- sometimes suboptimal behaviour
- e.g. large quantity of USDC to BCT:
  - will swap via USDC/BCT LP instead of using USDC/KLIMA and KLIMA/BCT LPs, even though the latter have higher liquidity


