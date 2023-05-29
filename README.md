# CoFi Money

## High-Level Summary
User deposits a supported crypto-asset (e.g., USDC) and receives fiAsset equivalent.

On day 1, these are as follows:

inputAsset  | fiAsset
------------- | -------------
USDC, vUSDC  | COFI
wETH, vwETH  | ETHFI
wBTC, vwBTC  | BTCFI

"vTKN" refers to whichever Vault the underlyingAsset is currently deployed in.

fiAssets are rebasing, in accordance with the yield earned from the underlying Vault.

CoFi captures a conversion fee for minting/redeeming fiAssets, and a service fee, which is a cut of the yield earned.

Additionally, users earn _CoFi Points_. Users' points are stored internally, and there is no ERC20 representation currently.

It is hoped that, in the future, points will serve as part of a merchant play, such as cashback/discounts, or other benefits.

Points are earned in line with the yield earned for the respective fiAsset. Each fiAsset has a _'pointsRate'_ associated with it.

Ensuring this equivalence (with yield earned), will help translate Points spent <> discount, for e.g.
