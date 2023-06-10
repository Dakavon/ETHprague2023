// new component

import { formatPicture } from "@/utils";
import { AnyPublication, Profile, ProfileOwnedByMe, useActiveProfile, useCollect } from "@lens-protocol/react-web";
import { useChainId } from "wagmi";

// TODO: Show if already following
export function Collect({
    pub, profile
  } : {
    pub: any,
    profile: Profile
  }) {
    const { data: wallet } = useActiveProfile();
    if(!wallet) return;
    const { execute: collect } = useCollect({collector: wallet, publication: pub})
    const chainId = useChainId();
    console.log("chainId", chainId)
    return (
        <>
            <div className="py-4 bg-zinc-900 rounded mb-3 px-4">
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
              <button onClick={collect}>Collect</button>
            </div>
      </>
    )
  }