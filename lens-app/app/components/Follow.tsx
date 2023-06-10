// new component

import { Profile, ProfileOwnedByMe, useFollow } from "@lens-protocol/react-web";

// TODO: Show if already following
export function Follow({
    wallet,
    profile,
    isConnected
  } : {
    isConnected: boolean,
    profile: Profile,
    wallet: ProfileOwnedByMe
  }) {
    const { execute: follow } = useFollow({ followee: profile, follower: wallet  });
    return (
      <>
        {
          isConnected && (
            <button
              className="bg-white text-black px-14 py-4 rounded-full"
              onClick={follow}
            >Follow {profile.handle}</button>
          )
        }
      </>
    )
  }