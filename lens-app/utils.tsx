// utils.ts
export function formatPicture(picture: any) {
    if (picture.__typename === 'MediaSet') {
      if (picture.original.url.startsWith('ipfs://')) {
        return picture.original.url.replace('ipfs://', 'https://lens.infura-ipfs.io/ipfs/')
      } else if (picture.original.url.startsWith('ar://')) {
        return picture.original.url.replace('ar://', 'https://arweave.net/')
      } else {
        return picture.original.url
      }
    } else {
      return picture
    }
  }