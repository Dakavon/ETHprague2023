# Overview

Repo for Lens Carbon based on ETHPrague 2023 Hackathon submission

Project name: **Lens carbon**

Tagline: **Lens collect partial carbon retirements**

## Summary
- A publisher of a publication can set partial carbon retirement of their collection fee. I.e. a fraction of their income is directly sent to carbon retirements with their specified details.
- A collector of a publication collects the same way as usual. They see the fee as well as the amount for retirement and related details. Publications with carbon retirements can be made more visible to further incentivise collection.
- The profile page of a user shows their total amount of retired carbon through collections of their publications by others as well as through their own collections.
- A leadership dashboard shows a ranking of users based on retired carbon.
- Where applicable, carbon amounts are clickable links that lead to a dashboard that shows the trace of each carbon retirement all the way to the carbon certificates and their details.

## Features
### Publish a publication
- set collect fee and currency as usual
- choose "retire carbon" as additional collection function
- specify fraction of fee, carbon token and optionally more details

<img src="wireframes/publish.png?raw=true" width=70%>

### Collect a publication
- see collect fee, retirement amount, carbon token and details
- collect as usual without any additional interaction
- user only needs to hold enough currency. Swap to carbon token is part of the collect transaction.

<img src="wireframes/collect.png?raw=true" width=70%>

### Profile view
- total t carbon retired by others via own publications
- total t carbon retired by collecting publications from others

<img src="wireframes/profile.png?raw=true" width=40%>


### Leadership dashboard
- ranking of users based on either metric from profile view

<img src="wireframes/ranking.png?raw=true" width=30%>


### Future features
- enable carbon retirements for sponsored publications or collects with quadratic funding etc.

<img src="wireframes/sponsored_retirements.png?raw=true" width=70%>

## Implementation

### Partial carbon retirement collect module (PCRCM)
- use KlimaDAO's retirement aggregator (RA) for maximum flexibility https://github.com/KlimaDAO/klimadao-solidity/tree/main/src/infinity
- RA performs the token swap from collect currency to carbon token and the token retirement
- allow any collect currency that is whitelisted by Lens and any carbon token that is included in the RA
- at module init, check if swap path & liquidity exists. If not, revert.
- at collect process, check if swap path & liquidity exists. If not:
  - process collect without retirement (do not revert)
  - send retirement amount to publisher, deduct treasury fee, but send an event on blockchain to signal to publisher that they should perform retirement manually to cover all such failed retirements.
- include retirement messages to make it possible to search for all retirements by a Lens profile, publication

### Frontend
- follow Lenster
