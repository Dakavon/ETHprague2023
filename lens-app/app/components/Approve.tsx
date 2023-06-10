import { useApproveModule, CollectPolicyType, CollectablePublication, TokenAllowanceLimit, useWalletLogin } from '@lens-protocol/react-web';

export function ApproveCollect({ publication }: { publication: CollectablePublication }) {
  const approveModule = useApproveModule();

  const handleClick = async () => {
    console.log("publication", publication)
    if (publication.collectPolicy.type === CollectPolicyType.CHARGE) {
      const result = await approveModule({
        // The collect fee amount
        amount: publication.collectPolicy.amount,

        // The collect module contract address
        spender: publication.collectPolicy.contractAddress,

        // In this case we want to  approve the exact amount
        limit: TokenAllowanceLimit.EXACT,
      })
      console.log("approveModule", result);
    }
  };
  
  return (
    <button onClick={handleClick} className='btn'>Approve collect module</button>
  );
}
