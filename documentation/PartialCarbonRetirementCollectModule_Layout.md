
## The module PartialCarbonRetirementCollectModule

### Requirements:
- fee collection for publisher with basic functionality
  - publisher defines fee amount and currency
  - some other features like collectLimit, followerOnly etc.
- carbon retirement with good workflow, flexibility and stability
  - publisher defines amount and carbon token for retirement
  - input currency for retirement is the same as collect currency
  - a range of currencies and carbon tokens should be supported
  - retirement feature should not lead to failures, e.g due to bad currency/carbon combinations or low liquidity
  - if retirement feature has a fallback, then retirement amount should be sent to publisher -> more incentiviced to perform retirement by hand later on
- fair lens fee
  - fee for lens treasury should be only charged on collect fee, not retirement amount
- good traceability
  - retirement and connected publication should be easily connected to both, publisher and collector so that statistics can be made easily


### Implementation:
- init specifies recipientAmount and retirementAmount
  - compute from fraction in frontend
- use KlimaDAO retirement aggregator https://github.com/KlimaDAO/klimadao-solidity/blob/e1b1037908be955d34bcf2987f124bb4d7ad62de/src/retirement_v1/KlimaRetirementAggregator.sol
- implement only default retirement with carbon poolToken. Specific retirement, where user chooses specific carbon token, maybe later.
- during module init, check that poolToken is supported and swap route from currency to poolToken exists
  - is check of liquidiy a good idea?
- decide if fallback for failed retirement should be implemented
- follow file changes and implementation here: https://github.com/lens-protocol/core/pull/36/files#diff-d00ac2894f3176adb82ce1f387553b3a1d38d111517262320668d421ba914ad5
- follow general patterns of collect modules in lens-protocol/modules/contracts/collect


## Considerations
### To keep in mind or decide
- upcoming Lens V2, which probably has different module interface
- upcoming KlimaDAO retirement bonds in addition to or instead of retirement aggregator
### Ideas for later
- Implement specific retirement, where publisher chooses (a list of) specific carbon projects
- Store default retirement settings of publisher in an NFT of his profile
