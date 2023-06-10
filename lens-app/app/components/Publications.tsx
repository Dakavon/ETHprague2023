import { Profile, usePublications } from "@lens-protocol/react-web";
import { Collect } from "./Collect";

export function Publications({
    profile
  }: {
    profile: Profile
  }) {
    let { data: publications } = usePublications({
      profileId: profile.id,
      limit: 10,
    })
    publications = publications?.map(publication => {
      if (publication.__typename === 'Mirror') {
        return publication.mirrorOf;
      } else {
        return publication;
      }
    });
  
    return (
      <>
        {
          publications?.map((pub: any, index: number) => (
            <Collect key={pub.id} pub={pub} profile={profile}/>
          ))
      }
      </>
    )
  }