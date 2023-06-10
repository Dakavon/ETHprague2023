import { useApproveModule, CollectablePublication, TokenAllowanceLimit, Amount, Erc20 } from '@lens-protocol/react-web';

export function ApproveCollect({ publication }: { publication: CollectablePublication }) {
  const {execute: approveModule} = useApproveModule();

  const handleClick = async () => {
    if(!publication.collectModule.feeOptional?.amount?.asset) return;
    const fee = publication.collectModule.feeOptional.amount.value;
    const tokenAddress = publication.collectModule.feeOptional.amount.asset.address;
    console.log("publication", publication, fee, tokenAddress)
    if (fee > 0 && tokenAddress) {
      const result = await approveModule({
        // The collect fee amount
        amount: fee as Amount<Erc20>,

        // The collect module contract address
        spender: tokenAddress,

        // In this case we want to  approve the exact amount
        limit: TokenAllowanceLimit.EXACT,
      })
      console.log("result", result);
    }
  };
  
  return (
    <button onClick={handleClick} className='btn'>Approve collect module</button>
  );
}
