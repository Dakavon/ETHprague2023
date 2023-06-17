Thoughts:

- Module simply calls BaseCollectModule and RetirementAggregator with desired fee split.
- RetirementAggregator contains swap router for token swaps. We might therefore be able to use it with any input token.
- Fallback, when retirement fails, might be simple transfer of that amount to recipient. This way the recipient will later be responsible to repeat the retirements in order to keep their social reputation up.
- Gas for retirement may not be a big issue. If yes, check later for solution. (E.g. in Sushi-x-Klima contract.)
- Specific retirement settings could be stored in an NFT of the publisher.


Possible implementation:

The executed collect module contract ("MultiCallFeeCollectModule") executes two different collect modules with the desired collect fee split. The first one is the existing SimpleFeeCollectModule that transfers the collect fee to the publisher. The second one performs the retirement. It tries to do the retirement with the KlimaDAO retirement aggregator, and if it fails, then it just transfers the remaining amount to the publisher, too. This way the publisher will be responsible for repeating the failed retirements themselves at a later time.


- lens-protocol/modules/contracts/collect/IMultiCallFeeCollectModule

An interface, similar to the existing MultirecipientFeeCollectModule https://github.com/lens-protocol/modules/blob/master/contracts/collect/MultirecipientFeeCollectModule.sol
But calls arbitary smart contract functions instead of just ERC20-transfers.
The interface design might help to enable other types of such split contracts in the future.

- lens-protocol/modules/contracts/collect/PartialRetirementCollectModule

Performs the basic fee collection and the retirement
inputs:
- fee_recipient_address: address of the recipient of the fee
- fee_token: which token it is
- fee_amount: how much
- retirement_fraction: fraction that goes into retirement 
- retirement_pool_token: which carbon pool token to use for retirement
- retirement_args: optional additional arguments, e.g. for selective retirements

