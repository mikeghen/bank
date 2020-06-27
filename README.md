![Bank protocol](./bank-protocol.png)
This is a framework fixed-rate collateral-backed loans on Ethereum. This repository contains the core smart contracts and DApp code.

# Design Considerations

- Transparency
  - The contract code is simple enough to understand by anyone familiar with Solidity
  - It is easy to find where smart contract code is executed during contract interactions

- Flexibility
  - The contract code can be deployed in many configurations
  - The type of collateral, debt, and rates can all be changed

- Easy of Use
  - Deployment and configuration is simple enough for anyone familiar with Ethereum
  - Interactions with the contract are simple and intuitive for end users

# Deployment
For deployment on test or main networks, edit the `migrations/3_tellor_contracts.js` and comment out everything except the contract deployment:
```
await deployer.deploy(Bank, 12, 1, 150, 25, 846000, "0xfe41cb708cd98c5b20423433309e55b53f79134a", 50, 1000000, 1000000, "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa", 39, 1000000, 1000000, "0x0D17ED8DDE4AF196ff638F3704e94A77419Df2b8");
```
Replace the values with those you wish to use for your bank deployment and visit the `Bank.sol` constructor for more details about these parameters.

# Protocol Summary
On deployment, the bank _owner_ specifies the following parameters:

* **Debt Token:** This is the token users borrow from the bank (i.e. USDC)
* **Collateral Token:** This is the token the bank accepts as collateral (i.e. TRB)
* **Interest Rate:** The annual interest rate the bank charges borrowers
* **Origination Fee:** The fixed fee charged to borrowers
* **Collateralization Ratio:** The loan-to-value amount borrowers must maintain to avoid a liquidation
* **Liquidation Penalty:** The fixed fee charged to borrowers who get liquidated
* **Period:** The period for calculating interest in seconds

Once deployed, the bank owner must deposit some debt tokens into the bank's reserve. After depositing debt tokens, users can deposit collateral tokens and borrow the bank's debt tokens. During the borrow, the borrower is charged an origination fee and then interest will accumulate until they repay what they've borrowed plus interest and fees. If at anytime the price of the collateral falls, then the bank owner will liquidate the borrowers collateral to repay their debt.

# Usage on Ganache
First, `truffle migrate` the contract to deploy to Ganache, then setup the contract using `truffle console`.

From the console, approve and deposit debt tokens (i.e. `USDToken`) into the bank's reserve.
```
let bank = await Bank.deployed()
let dt = await USDToken.deployed()
let accounts = await web3.eth.getAccounts()
await dt.approve(bank.address, web3.utils.toWei("1000", "ether"), {from: accounts[0]})
await bank.reserveDeposit(web3.utils.toWei("1000", "ether"), {from: accounts[0]})
```

## Working with the Oracle
Initialize the oracle objects and get accounts:
```
let oracle = await TellorMaster.deployed()
let oracleAddress = (web3.utils.toChecksumAddress(oracle.address))
let oracle2 = await new web3.eth.Contract(Tellor.abi, oracleAddress)
let accounts = await web3.eth.getAccounts()
```
Then make a request to the oracle:
```
await web3.eth.sendTransaction({to: oracleAddress, from: accounts[0], gas: 4000000, data: oracle2.methods.requestData("USDT","USDT/USD",1000,0).encodeABI()})
```
Next, submit 5 values through mining:
```
await web3.eth.sendTransaction({to: oracle.address, from: accounts[1],gas:4000000, data: oracle2.methods.submitMiningSolution("nonce", 2, 1000000).encodeABI()})
await web3.eth.sendTransaction({to: oracle.address, from: accounts[2],gas:4000000, data: oracle2.methods.submitMiningSolution("nonce", 2, 1000000).encodeABI()})
await web3.eth.sendTransaction({to: oracle.address, from: accounts[3],gas:4000000, data: oracle2.methods.submitMiningSolution("nonce", 2, 1000000).encodeABI()})
await web3.eth.sendTransaction({to: oracle.address, from: accounts[4],gas:4000000, data: oracle2.methods.submitMiningSolution("nonce", 2, 1000000).encodeABI()})
await web3.eth.sendTransaction({to: oracle.address, from: accounts[5],gas:4000000, data: oracle2.methods.submitMiningSolution("nonce", 2, 1000000).encodeABI()})
```
Because the Bank contract is UsingTellor, you can get the current data from the oracle using:
```
let vars = await bank.getCurrentValue.call(1)
```
And the price will be contained in `vars[1]`.

And you can update the price with:
```
await bank.updatePrice({from: accounts[0]})
```

## Regression Test Plan
Run these tests manually on localhost, Rinkeby, to confirm things work as built.

- [ ] Update the debt and collateral token prices
- [ ] As the owner, deposit debt tokens
- [ ] As a borrower, deposit collateral and withdraw some debt
- [ ] - Borrow and repay debt
- [ ] - Add and remove collateral
- [ ] - Repay all the debt and withdraw all collateral
- [ ] With a borrower undercollateralized, liquidate the borrower
- [ ] As the owner, withdraw collateral and debt
