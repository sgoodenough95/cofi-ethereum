# CoFi Money

## High-Level Summary
User deposits a supported crypto-asset (e.g., USDC) and receives fiAsset equivalent.

On day 1, these are as follows:

inputAsset  | fiAsset
------------- | -------------
DAI/USDC, vDAI/vUSDC  | COFI
wETH, vwETH  | fiETH
wBTC, vwBTC  | fiBTC

"vTKN" refers to whichever Vault the underlyingAsset is currently deployed in.

fiAssets are rebasing, in accordance with the yield earned from the underlying Vault.

CoFi captures a conversion fee for minting/redeeming fiAssets, and a service fee, which is a cut of the yield earned.

Additionally, users earn _CoFi Points_. Users' points are stored internally, and there is no ERC20 representation currently.

It is hoped that, in the future, points will serve as part of a merchant play, such as cashback/discounts, or other benefits.

Points are earned in line with the yield earned for the respective fiAsset. Each fiAsset has a _'pointsRate'_ associated with it.

Ensuring this equivalence (with yield earned), will help translate Points spent <> discount, for e.g.

## Yield Venue

At any time, there is ONE ERC4626-compliant yield venue for each fiAsset.

Although *COFI* accepts both USDC and DAI, there shall be a prior/post transformation DAI <> USDC.

For e.g., if yvDAI is yielding more than yvUSDC, the protocol will elect to convert USDC -> DAI prior to depositing.

MakerDAO's DAI<>USDC PSM provides a low fee gateway to perform this exchange.

Logic for migrating between Vaults has also been added (if DAI/USDC is yielding more in Aave, for e.g.).

## TO-DO

- Add MakerRouter (PSM) logic.
- Add WETHGateway logic (such that User can deposit ETH without wrapping beforehand).
- Other periphery components where required.
- Extensive unit tetsing (e.g., for migrating Vaults, Points, etc.).
