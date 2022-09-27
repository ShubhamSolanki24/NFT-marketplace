# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
A seller can use the smart contract to:

approve an NFT to market contract
create a market item with a listing fee
waiting for a buyer to buy the NFT
receive the price value
When a buyer buys an NFT in the marketplace, the market contract processes the purchase process:

buyer buys by paying the price value
market contract completes the purchase process:
transfer the price value to the seller
transfer the NFT from seller to buyer
transfer the listing fee to the market owner
change market item state from Created to Release
