# ETHprague2023

Monorepo for ETHPrague 2023 Hackathon submission

## Project Overview

### Project name
Lens carbon

### Tagline
Lens collect carbon retirements

### Summary

- A user can publish a post and set collection rule to carbon offsetting. In this case, a fraction of their income is sent to carbon retirements.
- Another user can collect such posts. The fact that a collection leads to carbon retirements does not chance their workflow, but can me made visible to further incentivise collection.
- The profile page of a user shows their total retired carbon through collections of their posts by others as well as through their own collections.


## Technical Roadmap and TODOs

### Features

#### Profile view
- total kg carbon retired by others in own publications
- total kg carbon retired by collecting publications from others

#### Publish a publication
- choose "retire carbon" as collection function

#### Collect a publication
- usual workflow


## Implementation
- use BCTCollectRetire module on Mumbai https://mumbai.polygonscan.com/address/0x05A6841cBdc292f83b0642954C5497Cb02dED05A
- use Lens SDK for everything else --> see keyword mainnet(testnet) in import statements
- use two existing lens profiles on Mumai or create two profiles
- build minimal app with Nader workshop template

## TODOs

- Deploy app on localhost
  - works for Niels and Robert
- Set SDK to testnet
  - done -> in layout.tsx, try some reloads
- 
- Create 2 lens profiles on testnet or use two existing
  - try using testnet API https://docs.lens.xyz/docs/deployed-contract-addresses#mumbai-testnet-addresses
  - created with https://lens-do-it.vercel.app/
  - on testnet.lenster.xyz created post with one account


- Implement publish/collect functions in app
  - Basic functionality in development
  - Currently being debugged

- Implement BCTRetireCollect function in app
  - Test functionality using testnet.lenster.xyz and polygonscan
  - use profiles from above
  - on testnet.lenster, create collectable post with one account
  - find profileId and pubId of profile and post somehow

  - use this to initialize BCT module and collect
  - 


  - on same site, with other account, collect it
  - allow module
  - but now with other module
- Implement carbon summary in profile view




# Possible next steps

- Set collection rule: choose "carbon percentage" instead of everything
- Collection workflow: make visible that collection will retire carbon