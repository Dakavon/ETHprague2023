import { uploadToIpfs } from './myIpfsUploader';
import { ContentFocus, ProfileOwnedByMe, useCreatePost } from '@lens-protocol/react-web';

export function PostComposer({ publisher }: { publisher: ProfileOwnedByMe }) {
  const { execute: post, error, isPending } = useCreatePost({ publisher, upload: uploadToIpfs });

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    const form = event.currentTarget;

    const formData = new FormData(form);
    const content = (formData.get('content') as string | null) ?? never();

    let result = await post({
      content,
      contentFocus: ContentFocus.TEXT_ONLY,
      locale: 'en',
    });

    if (result.isSuccess()) {
      form.reset();
    }
  };

  return (
    <form onSubmit={submit} className='flex items-center justify-between my-4 bg-zinc-900'>
      <textarea
      className='w-full p-4 rounded-xl bg-zinc-800 text-white m-4'
        name="content"
        minLength={1}
        required
        rows={1}
        placeholder="What's happening?"
        style={{ resize: 'none' }}
        disabled={isPending}
      ></textarea>

      <button type="submit" disabled={isPending} className='btn'>
        Post
      </button>

      {error && <pre>{error.message}</pre>}
    </form>
  );
}
