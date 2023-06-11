// new component

import { formatPicture } from "@/utils";
import { InsufficientAllowanceError, InsufficientFundsError, Profile, ProfileOwnedByMe, useActiveProfile, useCollect } from "@lens-protocol/react-web";
import { ApproveCollect } from "./Approve";

// TODO: Show if already following
export function Collect({
    pub, profile
  } : {
    pub: any,
    profile: Profile
  }) {
    const { data: wallet } = useActiveProfile();
    const { execute: collect, error } = useCollect({collector: wallet as ProfileOwnedByMe, publication: pub});

    async function handleClick() {
      try {
        await collect();
      } catch (e) {
        console.log(e);
    }

    if (error instanceof InsufficientFundsError) {
      alert('Insufficient funds');
    } else if (error instanceof InsufficientAllowanceError) {
      alert('Insufficient allowance');
      } else {
      alert('Something went wrong');
    }
  }

    return (
        <>
            <div className="flex items-center justify-between py-4 bg-zinc-900 rounded mb-3 px-4">
              <p>{pub.metadata.content}</p>
              {
                pub.metadata?.media[0]?.original && ['image/jpeg', 'image/png'].includes(pub.metadata?.media[0]?.original.mimeType) && (
                  <img
                    width="400"
                    height="400"
                    alt={profile.handle}
                    className='rounded-xl mt-6 mb-2'
                    src={formatPicture(pub.metadata.media[0])}
                  />
                )
              }
              <div className="flex items-center space-x-2">
              {wallet && <ApproveCollect publication={pub} />}
              <button className="btn" onClick={handleClick}>Collect</button>
              </div>
            </div>
      </>
    )
  }