
# The module PartialCarbonRetirementCollectModule

## Requirements:

### fee collection for publisher with basic functionality
- publisher defines fee amount and currency
- some other features like collectLimit, followerOnly etc.

### carbon retirement with good workflow and flexibility
- publisher defines amount and carbon token for retirement
- input currency for retirement is the same as collect currency
- a range of currencies and carbon tokens should be supported
- retirement feature should not lead to failures, e.g due to bad currency/carbon combinations or low liquidity
- if retirement feature has a fallback, then retirement amount should be sent to publisher -> more incentiviced to perform retirement by hand later on

### carbon retirement with high stability
- if retirement fails, the collection process should not fail, too
- if retirement fails, the retirementAmount should go to publisher, minus lens fee
  - publisher has inventive to perform retirement later
  - lens fee so that this system cannot be gamed
- OR: 
  - check if failures can really happen that often
  - treat module as PoC, before lens V2, and see how it goes    

### fair lens fee
- fee for lens treasury should be only charged on amount that goes to publisher, not retirement amount

### good traceability
- retirement and connected publication should be easily connected to both, publisher and collector so that statistics can be made easily


## Implementation:

### use basic functionality of BaseFeeCollectModule
- add poolToken and retirementAmount as additional input parameters
- init specifies recipientAmount and retirementAmount
  - compute from fraction in frontend

### use KlimaDAO retirement aggregator for retirement 
- https://github.com/KlimaDAO/klimadao-solidity/blob/e1b1037908be955d34bcf2987f124bb4d7ad62de/src/retirement_v1/KlimaRetirementAggregator.sol
- implement only default retirement with carbon poolToken for now. 
- allow all possible currency/poolToken combinations

### check feasibility of retirements during module init
- check that poolToken is supported and swap route from currency to poolToken exists
- ? is check of liquidiy a good idea?
  - perhaps liquidity check in frontend?

### implement fallback for retirement failure
- ? retirement has a ERC20 transfer first -> can this be reverted?

### traceablility
-

### general 
- follow file changes and implementation here: https://github.com/lens-protocol/core/pull/36/files#diff-d00ac2894f3176adb82ce1f387553b3a1d38d111517262320668d421ba914ad5



# Considerations
## To keep in mind or decide
- upcoming Lens V2, which probably has different module interface
- upcoming KlimaDAO retirement bonds in addition to or instead of retirement aggregator
## Ideas for later
- Implement specific retirement, where publisher chooses (a list of) specific carbon projects
- Store default retirement settings of publisher in an NFT of his profile