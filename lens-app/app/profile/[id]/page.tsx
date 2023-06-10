// app/profile/[id]/page.tsx
'use client'
import { usePathname } from 'next/navigation';
// new imports
import { useProfile, useWalletLogin, useWalletLogout, useActiveProfile,
} from '@lens-protocol/react-web';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { InjectedConnector } from 'wagmi/connectors/injected';
import { formatPicture } from '../../../utils';
import { Follow } from '@/app/components/Follow';
import { Publications } from '@/app/components/Publications';
import { PostComposer } from '@/app/components/PostComposer';

export default function Profile() {
  // new hooks
  const { execute: login } = useWalletLogin();
  const { execute: logout } = useWalletLogout();
  const { data: wallet } = useActiveProfile();
  const { isConnected } = useAccount();
  const { disconnectAsync } = useDisconnect();
  
  const pathName = usePathname()
  const handle = pathName?.split('/')[2]

  let { data: profile, loading } = useProfile({ handle })

  const { connectAsync } = useConnect({
    connector: new InjectedConnector(),
  });
  
  // new login function
  const onLoginClick = async () => {
    if (isConnected) {
      await disconnectAsync();
    }
    const { connector } = await connectAsync();
    if (connector instanceof InjectedConnector) {
      const signer = await connector.getSigner();
      await login(signer);
    }
  }

  if (loading) return <p className="p-14">Loading ...</p>

  return (
    <div >
      <div className="p-14 max-w-[900px]">
        {
          !wallet && (
            <button className="bg-white text-black px-14 py-4 rounded-full mb-4" onClick={onLoginClick}>Sign In</button>
          )
        }
        {
          wallet && profile && (
            <>
            <Follow
              isConnected={isConnected}
              profile={profile}
              wallet={wallet}
            />
            <button className="ml-4 bg-white text-black px-14 py-4 rounded-full mb-4" onClick={logout}>Sign Out</button>
            </>
          )
        }
        {
          profile && profile.picture?.__typename === 'MediaSet' && (
            <img
              width="200"
              height="200"
              alt={profile.handle}
              className='rounded-xl'
              src={formatPicture(profile.picture)}
            />
          )
        }
        <h1 className="text-3xl my-3">{profile?.handle}</h1>
        <h3 className="text-xl mb-4">{profile?.bio}</h3>
        
        { profile && 
        <>
          { profile?.ownedBy === wallet?.ownedBy && <PostComposer profile={wallet} /> }
          <Publications profile={profile} />
        </>  }
      </div>
    </div>
  )
}



