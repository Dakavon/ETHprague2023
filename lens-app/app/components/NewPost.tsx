import { Profile, usePublications } from "@lens-protocol/react-web";
import { Collect } from "./Collect";

export function NewPost({
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
        <div className="flex justify-between items-center space-x-4 py-4 bg-zinc-900 rounded mb-8 px-4">
            <input className="w-fit border rounded-sm bg-gray-800 py-1 px-3" placeholder="What's happening?"></input>
            <button className="btn">Post</button>
        </div>
    )
  }