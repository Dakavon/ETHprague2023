import { useApproveModule, CollectablePublication, TokenAllowanceLimit, useCurrencies, Amount } from '@lens-protocol/react-web';

export function ApproveCollect({ publication }: { publication: CollectablePublication }) {
  const {execute: approveModule} = useApproveModule();
  const { data: currencies } = useCurrencies();

  const handleClick = async () => {

    // @ts-ignore
    const fee = publication.collectModule.feeOptional.amount.value;
    // @ts-ignore
    const tokenAddress = publication.collectModule.feeOptional.amount.asset.address;
    const tokenInfo = currencies?.find(currency => currency.address === tokenAddress);

    if (fee > 0 && tokenAddress) {
      const result = await approveModule({
        // The collect fee amount
        // @ts-ignore
        amount: Amount.erc20(tokenInfo, fee),

        // The collect module contract address
        spender: publication.collectPolicy.contractAddress,

        // In this case we want to  approve the exact amount
        limit: TokenAllowanceLimit.EXACT,
      })
    }
  };
  
  return (
    <button onClick={handleClick} className='btn'>Approve collect module</button>
  );
}
