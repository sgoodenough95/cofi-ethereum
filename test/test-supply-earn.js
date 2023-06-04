/* global ethers */

const { getSelectors, FacetCutAction } = require('../scripts/libraries/diamond.js')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { ethers } = require('hardhat')
const hre = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

/* Optimism */

const USDC_ABI = [{"inputs":[{"internalType":"address","name":"_l2Bridge","type":"address"},{"internalType":"address","name":"_l1Token","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"},{"internalType":"uint8","name":"decimals","type":"uint8"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"}],"name":"Blacklisted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newBlacklister","type":"address"}],"name":"BlacklisterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"pauser","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousPauser","type":"address"},{"indexed":true,"internalType":"address","name":"newPauser","type":"address"}],"name":"PauserChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"}],"name":"UnBlacklisted","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"pauser","type":"address"}],"name":"Unpaused","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"blacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"blacklister","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"changeOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isBlacklisted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"l1Token","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"l2Bridge","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pauser","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"setPauser","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"_interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"unBlacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newBlacklister","type":"address"}],"name":"updateBlacklister","outputs":[],"stateMutability":"nonpayable","type":"function"}]
const WBTC_ABI = [{"inputs":[{"internalType":"address","name":"_l2Bridge","type":"address"},{"internalType":"address","name":"_l1Token","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"l1Token","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"l2Bridge","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"_interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]
const WETH_ABI = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"guy","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]
const OP_ABI = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"delegator","type":"address"},{"indexed":true,"internalType":"address","name":"fromDelegate","type":"address"},{"indexed":true,"internalType":"address","name":"toDelegate","type":"address"}],"name":"DelegateChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"delegate","type":"address"},{"indexed":false,"internalType":"uint256","name":"previousBalance","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"newBalance","type":"uint256"}],"name":"DelegateVotesChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"burnFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint32","name":"pos","type":"uint32"}],"name":"checkpoints","outputs":[{"components":[{"internalType":"uint32","name":"fromBlock","type":"uint32"},{"internalType":"uint224","name":"votes","type":"uint224"}],"internalType":"struct ERC20Votes.Checkpoint","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"delegatee","type":"address"}],"name":"delegate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"delegatee","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"delegateBySig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"delegates","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"getPastTotalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"blockNumber","type":"uint256"}],"name":"getPastVotes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getVotes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"numCheckpoints","outputs":[{"internalType":"uint32","name":"","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
const YVUSDC_ABI = [{"name":"Transfer","inputs":[{"name":"sender","type":"address","indexed":true},{"name":"receiver","type":"address","indexed":true},{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Approval","inputs":[{"name":"owner","type":"address","indexed":true},{"name":"spender","type":"address","indexed":true},{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Deposit","inputs":[{"name":"recipient","type":"address","indexed":true},{"name":"shares","type":"uint256","indexed":false},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Withdraw","inputs":[{"name":"recipient","type":"address","indexed":true},{"name":"shares","type":"uint256","indexed":false},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Sweep","inputs":[{"name":"token","type":"address","indexed":true},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"LockedProfitDegradationUpdated","inputs":[{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyAdded","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"debtRatio","type":"uint256","indexed":false},{"name":"minDebtPerHarvest","type":"uint256","indexed":false},{"name":"maxDebtPerHarvest","type":"uint256","indexed":false},{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyReported","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"gain","type":"uint256","indexed":false},{"name":"loss","type":"uint256","indexed":false},{"name":"debtPaid","type":"uint256","indexed":false},{"name":"totalGain","type":"uint256","indexed":false},{"name":"totalLoss","type":"uint256","indexed":false},{"name":"totalDebt","type":"uint256","indexed":false},{"name":"debtAdded","type":"uint256","indexed":false},{"name":"debtRatio","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"FeeReport","inputs":[{"name":"management_fee","type":"uint256","indexed":false},{"name":"performance_fee","type":"uint256","indexed":false},{"name":"strategist_fee","type":"uint256","indexed":false},{"name":"duration","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"WithdrawFromStrategy","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"totalDebt","type":"uint256","indexed":false},{"name":"loss","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateGovernance","inputs":[{"name":"governance","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateManagement","inputs":[{"name":"management","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateRewards","inputs":[{"name":"rewards","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateDepositLimit","inputs":[{"name":"depositLimit","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdatePerformanceFee","inputs":[{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateManagementFee","inputs":[{"name":"managementFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateGuardian","inputs":[{"name":"guardian","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"EmergencyShutdown","inputs":[{"name":"active","type":"bool","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateWithdrawalQueue","inputs":[{"name":"queue","type":"address[20]","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateDebtRatio","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"debtRatio","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateMinDebtPerHarvest","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"minDebtPerHarvest","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateMaxDebtPerHarvest","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"maxDebtPerHarvest","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdatePerformanceFee","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyMigrated","inputs":[{"name":"oldVersion","type":"address","indexed":true},{"name":"newVersion","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyRevoked","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyRemovedFromQueue","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyAddedToQueue","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"NewPendingGovernance","inputs":[{"name":"pendingGovernance","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"},{"name":"guardian","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"},{"name":"guardian","type":"address"},{"name":"management","type":"address"}],"outputs":[]},{"stateMutability":"pure","type":"function","name":"apiVersion","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32"}]},{"stateMutability":"nonpayable","type":"function","name":"setName","inputs":[{"name":"name","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setSymbol","inputs":[{"name":"symbol","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setGovernance","inputs":[{"name":"governance","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"acceptGovernance","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setManagement","inputs":[{"name":"management","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setRewards","inputs":[{"name":"rewards","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setLockedProfitDegradation","inputs":[{"name":"degradation","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setDepositLimit","inputs":[{"name":"limit","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setPerformanceFee","inputs":[{"name":"fee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setManagementFee","inputs":[{"name":"fee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setGuardian","inputs":[{"name":"guardian","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setEmergencyShutdown","inputs":[{"name":"active","type":"bool"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setWithdrawalQueue","inputs":[{"name":"queue","type":"address[20]"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"transfer","inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"transferFrom","inputs":[{"name":"sender","type":"address"},{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"approve","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"increaseAllowance","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"decreaseAllowance","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"permit","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"},{"name":"amount","type":"uint256"},{"name":"expiry","type":"uint256"},{"name":"signature","type":"bytes"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"view","type":"function","name":"totalAssets","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[{"name":"_amount","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[{"name":"_amount","type":"uint256"},{"name":"recipient","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"maxAvailableShares","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"},{"name":"recipient","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"},{"name":"recipient","type":"address"},{"name":"maxLoss","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"pricePerShare","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"addStrategy","inputs":[{"name":"strategy","type":"address"},{"name":"debtRatio","type":"uint256"},{"name":"minDebtPerHarvest","type":"uint256"},{"name":"maxDebtPerHarvest","type":"uint256"},{"name":"performanceFee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyDebtRatio","inputs":[{"name":"strategy","type":"address"},{"name":"debtRatio","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyMinDebtPerHarvest","inputs":[{"name":"strategy","type":"address"},{"name":"minDebtPerHarvest","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyMaxDebtPerHarvest","inputs":[{"name":"strategy","type":"address"},{"name":"maxDebtPerHarvest","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyPerformanceFee","inputs":[{"name":"strategy","type":"address"},{"name":"performanceFee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"migrateStrategy","inputs":[{"name":"oldVersion","type":"address"},{"name":"newVersion","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revokeStrategy","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revokeStrategy","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"addStrategyToQueue","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"removeStrategyFromQueue","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"debtOutstanding","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"debtOutstanding","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"creditAvailable","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"creditAvailable","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"availableDepositLimit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"expectedReturn","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"expectedReturn","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"report","inputs":[{"name":"gain","type":"uint256"},{"name":"loss","type":"uint256"},{"name":"_debtPayment","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"sweep","inputs":[{"name":"token","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"sweep","inputs":[{"name":"token","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"name","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"symbol","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"decimals","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"balanceOf","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"allowance","inputs":[{"name":"arg0","type":"address"},{"name":"arg1","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalSupply","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"token","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"governance","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"management","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"guardian","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"strategies","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"tuple","components":[{"name":"performanceFee","type":"uint256"},{"name":"activation","type":"uint256"},{"name":"debtRatio","type":"uint256"},{"name":"minDebtPerHarvest","type":"uint256"},{"name":"maxDebtPerHarvest","type":"uint256"},{"name":"lastReport","type":"uint256"},{"name":"totalDebt","type":"uint256"},{"name":"totalGain","type":"uint256"},{"name":"totalLoss","type":"uint256"}]}]},{"stateMutability":"view","type":"function","name":"withdrawalQueue","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"emergencyShutdown","inputs":[],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"view","type":"function","name":"depositLimit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"debtRatio","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalIdle","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalDebt","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lastReport","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"activation","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lockedProfit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lockedProfitDegradation","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"rewards","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"managementFee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"performanceFee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"nonces","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"uint256"}]}]
const YVETH_ABI = [{"name":"Transfer","inputs":[{"name":"sender","type":"address","indexed":true},{"name":"receiver","type":"address","indexed":true},{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Approval","inputs":[{"name":"owner","type":"address","indexed":true},{"name":"spender","type":"address","indexed":true},{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Deposit","inputs":[{"name":"recipient","type":"address","indexed":true},{"name":"shares","type":"uint256","indexed":false},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Withdraw","inputs":[{"name":"recipient","type":"address","indexed":true},{"name":"shares","type":"uint256","indexed":false},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"Sweep","inputs":[{"name":"token","type":"address","indexed":true},{"name":"amount","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"LockedProfitDegradationUpdated","inputs":[{"name":"value","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyAdded","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"debtRatio","type":"uint256","indexed":false},{"name":"minDebtPerHarvest","type":"uint256","indexed":false},{"name":"maxDebtPerHarvest","type":"uint256","indexed":false},{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyReported","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"gain","type":"uint256","indexed":false},{"name":"loss","type":"uint256","indexed":false},{"name":"debtPaid","type":"uint256","indexed":false},{"name":"totalGain","type":"uint256","indexed":false},{"name":"totalLoss","type":"uint256","indexed":false},{"name":"totalDebt","type":"uint256","indexed":false},{"name":"debtAdded","type":"uint256","indexed":false},{"name":"debtRatio","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"FeeReport","inputs":[{"name":"management_fee","type":"uint256","indexed":false},{"name":"performance_fee","type":"uint256","indexed":false},{"name":"strategist_fee","type":"uint256","indexed":false},{"name":"duration","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"WithdrawFromStrategy","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"totalDebt","type":"uint256","indexed":false},{"name":"loss","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateGovernance","inputs":[{"name":"governance","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateManagement","inputs":[{"name":"management","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateRewards","inputs":[{"name":"rewards","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateDepositLimit","inputs":[{"name":"depositLimit","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdatePerformanceFee","inputs":[{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateManagementFee","inputs":[{"name":"managementFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateGuardian","inputs":[{"name":"guardian","type":"address","indexed":false}],"anonymous":false,"type":"event"},{"name":"EmergencyShutdown","inputs":[{"name":"active","type":"bool","indexed":false}],"anonymous":false,"type":"event"},{"name":"UpdateWithdrawalQueue","inputs":[{"name":"queue","type":"address[20]","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateDebtRatio","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"debtRatio","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateMinDebtPerHarvest","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"minDebtPerHarvest","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdateMaxDebtPerHarvest","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"maxDebtPerHarvest","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyUpdatePerformanceFee","inputs":[{"name":"strategy","type":"address","indexed":true},{"name":"performanceFee","type":"uint256","indexed":false}],"anonymous":false,"type":"event"},{"name":"StrategyMigrated","inputs":[{"name":"oldVersion","type":"address","indexed":true},{"name":"newVersion","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyRevoked","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyRemovedFromQueue","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"StrategyAddedToQueue","inputs":[{"name":"strategy","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"name":"NewPendingGovernance","inputs":[{"name":"pendingGovernance","type":"address","indexed":true}],"anonymous":false,"type":"event"},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"},{"name":"guardian","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"initialize","inputs":[{"name":"token","type":"address"},{"name":"governance","type":"address"},{"name":"rewards","type":"address"},{"name":"nameOverride","type":"string"},{"name":"symbolOverride","type":"string"},{"name":"guardian","type":"address"},{"name":"management","type":"address"}],"outputs":[]},{"stateMutability":"pure","type":"function","name":"apiVersion","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32"}]},{"stateMutability":"nonpayable","type":"function","name":"setName","inputs":[{"name":"name","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setSymbol","inputs":[{"name":"symbol","type":"string"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setGovernance","inputs":[{"name":"governance","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"acceptGovernance","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setManagement","inputs":[{"name":"management","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setRewards","inputs":[{"name":"rewards","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setLockedProfitDegradation","inputs":[{"name":"degradation","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setDepositLimit","inputs":[{"name":"limit","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setPerformanceFee","inputs":[{"name":"fee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setManagementFee","inputs":[{"name":"fee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setGuardian","inputs":[{"name":"guardian","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setEmergencyShutdown","inputs":[{"name":"active","type":"bool"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"setWithdrawalQueue","inputs":[{"name":"queue","type":"address[20]"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"transfer","inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"transferFrom","inputs":[{"name":"sender","type":"address"},{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"approve","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"increaseAllowance","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"decreaseAllowance","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"nonpayable","type":"function","name":"permit","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"},{"name":"amount","type":"uint256"},{"name":"expiry","type":"uint256"},{"name":"signature","type":"bytes"}],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"view","type":"function","name":"totalAssets","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[{"name":"_amount","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"deposit","inputs":[{"name":"_amount","type":"uint256"},{"name":"recipient","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"maxAvailableShares","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"},{"name":"recipient","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"withdraw","inputs":[{"name":"maxShares","type":"uint256"},{"name":"recipient","type":"address"},{"name":"maxLoss","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"pricePerShare","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"addStrategy","inputs":[{"name":"strategy","type":"address"},{"name":"debtRatio","type":"uint256"},{"name":"minDebtPerHarvest","type":"uint256"},{"name":"maxDebtPerHarvest","type":"uint256"},{"name":"performanceFee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyDebtRatio","inputs":[{"name":"strategy","type":"address"},{"name":"debtRatio","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyMinDebtPerHarvest","inputs":[{"name":"strategy","type":"address"},{"name":"minDebtPerHarvest","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyMaxDebtPerHarvest","inputs":[{"name":"strategy","type":"address"},{"name":"maxDebtPerHarvest","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"updateStrategyPerformanceFee","inputs":[{"name":"strategy","type":"address"},{"name":"performanceFee","type":"uint256"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"migrateStrategy","inputs":[{"name":"oldVersion","type":"address"},{"name":"newVersion","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revokeStrategy","inputs":[],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"revokeStrategy","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"addStrategyToQueue","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"removeStrategyFromQueue","inputs":[{"name":"strategy","type":"address"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"debtOutstanding","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"debtOutstanding","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"creditAvailable","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"creditAvailable","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"availableDepositLimit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"expectedReturn","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"expectedReturn","inputs":[{"name":"strategy","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"report","inputs":[{"name":"gain","type":"uint256"},{"name":"loss","type":"uint256"},{"name":"_debtPayment","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"nonpayable","type":"function","name":"sweep","inputs":[{"name":"token","type":"address"}],"outputs":[]},{"stateMutability":"nonpayable","type":"function","name":"sweep","inputs":[{"name":"token","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[]},{"stateMutability":"view","type":"function","name":"name","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"symbol","inputs":[],"outputs":[{"name":"","type":"string"}]},{"stateMutability":"view","type":"function","name":"decimals","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"balanceOf","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"allowance","inputs":[{"name":"arg0","type":"address"},{"name":"arg1","type":"address"}],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalSupply","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"token","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"governance","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"management","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"guardian","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"strategies","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"tuple","components":[{"name":"performanceFee","type":"uint256"},{"name":"activation","type":"uint256"},{"name":"debtRatio","type":"uint256"},{"name":"minDebtPerHarvest","type":"uint256"},{"name":"maxDebtPerHarvest","type":"uint256"},{"name":"lastReport","type":"uint256"},{"name":"totalDebt","type":"uint256"},{"name":"totalGain","type":"uint256"},{"name":"totalLoss","type":"uint256"}]}]},{"stateMutability":"view","type":"function","name":"withdrawalQueue","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"emergencyShutdown","inputs":[],"outputs":[{"name":"","type":"bool"}]},{"stateMutability":"view","type":"function","name":"depositLimit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"debtRatio","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalIdle","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"totalDebt","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lastReport","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"activation","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lockedProfit","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"lockedProfitDegradation","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"rewards","inputs":[],"outputs":[{"name":"","type":"address"}]},{"stateMutability":"view","type":"function","name":"managementFee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"performanceFee","inputs":[],"outputs":[{"name":"","type":"uint256"}]},{"stateMutability":"view","type":"function","name":"nonces","inputs":[{"name":"arg0","type":"address"}],"outputs":[{"name":"","type":"uint256"}]}]
const ABTC_ABI = [{"inputs":[{"internalType":"contract IPool","name":"pool","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"}],"name":"BalanceTransfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"target","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"balanceIncrease","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"underlyingAsset","type":"address"},{"indexed":true,"internalType":"address","name":"pool","type":"address"},{"indexed":false,"internalType":"address","name":"treasury","type":"address"},{"indexed":false,"internalType":"address","name":"incentivesController","type":"address"},{"indexed":false,"internalType":"uint8","name":"aTokenDecimals","type":"uint8"},{"indexed":false,"internalType":"string","name":"aTokenName","type":"string"},{"indexed":false,"internalType":"string","name":"aTokenSymbol","type":"string"},{"indexed":false,"internalType":"bytes","name":"params","type":"bytes"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"caller","type":"address"},{"indexed":true,"internalType":"address","name":"onBehalfOf","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"balanceIncrease","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"index","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"ATOKEN_REVISION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"EIP712_REVISION","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"POOL","outputs":[{"internalType":"contract IPool","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RESERVE_TREASURY_ADDRESS","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"UNDERLYING_ASSET_ADDRESS","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"receiverOfUnderlying","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getIncentivesController","outputs":[{"internalType":"contract IAaveIncentivesController","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"getPreviousIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"getScaledUserBalanceAndSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address","name":"onBehalfOf","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"handleRepayment","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IPool","name":"initializingPool","type":"address"},{"internalType":"address","name":"treasury","type":"address"},{"internalType":"address","name":"underlyingAsset","type":"address"},{"internalType":"contract IAaveIncentivesController","name":"incentivesController","type":"address"},{"internalType":"uint8","name":"aTokenDecimals","type":"uint8"},{"internalType":"string","name":"aTokenName","type":"string"},{"internalType":"string","name":"aTokenSymbol","type":"string"},{"internalType":"bytes","name":"params","type":"bytes"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"caller","type":"address"},{"internalType":"address","name":"onBehalfOf","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"mintToTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"rescueTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"scaledBalanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"scaledTotalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract IAaveIncentivesController","name":"controller","type":"address"}],"name":"setIncentivesController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferOnLiquidation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferUnderlyingTo","outputs":[],"stateMutability":"nonpayable","type":"function"}]

const USDC = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607"
const wBTC = "0x68f180fcCe6836688e9084f035309E29Bf0A2095"
const wETH = "0x4200000000000000000000000000000000000006"
const OP = "0x4200000000000000000000000000000000000042"

const yvUSDC = "0xaD17A225074191d5c8a37B50FdA1AE278a2EE6A2"
const yvETH = "0x5B977577Eb8a480f63e11FC615D6753adB8652Ae"
const yvOP = "0x7D2382b1f8Af621229d33464340541Db362B4907"
const aOptWBTC = "0x078f358208685046a11C85e8ad32895DED33A249"

const yvUSDCStakingRewards = "0xB2c04C55979B6CA7EB10e666933DE5ED84E6876b"
const yvETHStakingRewards = "0xE35Fec3895Dcecc7d2a91e8ae4fF3c0d43ebfFE0"

/* Swap params */
const minHarvest = "1000000000000000000" // 1 yvOP
const slippage = "200" // 2%
const wait = "30" // 30 seconds
const poolFee = "3000" // 0.3%
const enabled = "1"

const wethAccount = "0x9e99F56FC8550a83496b2199D126EF004c8A598c"
const usdcAccount = "0x7F5c764cBc14f9669B88837ca1490cCa17c31607"
const wbtcAccount = "0xc20B6e32175Cc6367b172306aE863d5B5Cd990b0"
const opAccount = "0x3FFe8Df98a9C8e80b7E5D2bBFcd82C41168aa058"

describe('First test', function() {

  async function deploy() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]
    const feeCollector = accounts[1]

    signer = ethers.provider.getSigner(owner.address)

    console.log(await helpers.time.latestBlock())

    // Deploy COFI Dollar
    const COFI = await ethers.getContractFactory('FiToken')
    const cofi = await COFI.deploy('COFI Dollar', 'COFI')
    await cofi.deployed()
    console.log('COFI Dollar deployed:', cofi.address)

    // Deploy COFI Ethereum
    const ETHFI = await ethers.getContractFactory('FiToken')
    const ethfi = await ETHFI.deploy('COFI Ethreum', 'ETHFI')
    await ethfi.deployed()
    console.log('COFI Ethereum deployed:', ethfi.address)

    // Deploy COFI Bitcoin
    const BTCFI = await ethers.getContractFactory('FiToken')
    const btcfi = await BTCFI.deploy('COFI Bitcoin', 'BTCFI')
    await btcfi.deployed()
    console.log('COFI Bitcoin deployed:', btcfi.address)

    const WYVUSDC = await ethers.getContractFactory('YearnZapReinvestWrapper')
    const wyvUSDC = await WYVUSDC.deploy(
      yvUSDC,
      yvOP,
      yvUSDCStakingRewards,
      '0x0000000000000000000000000000000000000000',
      USDC,
      minHarvest,
      slippage,
      wait,
      poolFee,
      enabled,
      {gasLimit: '30000000'}
    )
    await wyvUSDC.deployed()
    console.log('wyvUSDC deployed: ', wyvUSDC.address)

    const WYVETH = await ethers.getContractFactory('YearnZapReinvestWrapper')
    const wyvETH = await WYVETH.deploy(
      yvETH,
      yvOP,
      yvETHStakingRewards,
      '0x13e3Ee699D1909E989722E753853AE30b17e08c5',
      wETH,
      minHarvest,
      slippage,
      wait,
      poolFee,
      enabled,
      {gasLimit: '30000000'}
    )
    await wyvETH.deployed()
    console.log('wyvETH deployed: ', wyvETH.address)

    const ABTC = await ethers.getContractFactory('AaveV3ERC4626Reinvest')
    const waBTC = await ABTC.deploy(
      wBTC,
      aOptWBTC,
      "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
      "0x929EC64c34a17401F460460D4B9390518E5B473e",
      owner.address
    )
    await waBTC.deployed()
    console.log('waBTC deployed: ', waBTC.address)
      
    // deploy DiamondCutFacet
    const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
    const diamondCutFacet = await DiamondCutFacet.deploy()
    await diamondCutFacet.deployed()
    console.log('DiamondCutFacet deployed:', diamondCutFacet.address)
      
    // deploy Diamond
    const Diamond = await ethers.getContractFactory('Diamond')
    const diamond = await Diamond.deploy(owner.address, diamondCutFacet.address)
    await diamond.deployed()
    console.log('Diamond deployed:', diamond.address)

    // Set Diamond address in FiToken contract(s).
    await cofi.setDiamond(diamond.address)
    await ethfi.setDiamond(diamond.address)
    await btcfi.setDiamond(diamond.address)

    await wyvUSDC.toggleAuthorized(diamond.address)
    await wyvETH.toggleAuthorized(diamond.address)
    await waBTC.toggleAuthorized(diamond.address)
      
    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await ethers.getContractFactory('InitDiamond')
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.deployed()
    console.log('DiamondInit deployed:', diamondInit.address)
      
    // deploy facets
    console.log('')
    console.log('Deploying facets')
    const FacetNames = [
      'DiamondLoupeFacet',
      'OwnershipFacet',
      'SupplyFacet',
      'SupplyAdminFacet',
      'PointFacet',
      'AccessFacet',
      'YieldFacet',
      'PartnerFacet'
    ]
    const cut = []
    for (const FacetName of FacetNames) {
      const Facet = await ethers.getContractFactory(FacetName)
      const facet = await Facet.deploy()
      await facet.deployed()
      console.log(`${FacetName} deployed: ${facet.address}`)
      cut.push({
        facetAddress: facet.address,
        action: FacetCutAction.Add,
        functionSelectors: getSelectors(facet)
      })
    }
      
    const initArgs = [{
      COFI:   cofi.address,
      ETHFI:  ethfi.address,
      BTCFI:  btcfi.address,
      vUSDC:  wyvUSDC.address,
      vETH:   wyvETH.address,
      vBTC:   waBTC.address,
      USDC:   USDC,
      wETH:   wETH,
      wBTC:   wBTC,
      admins: [
        owner.address, // owner
        owner.address, // backupOwner
        feeCollector.address // feeCollector
      ],
      feeCollector: feeCollector.address
    }]
      
    // upgrade diamond with facets
    console.log('')
    console.log('Diamond Cut:', cut)
    const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
    let tx
    let receipt
    // call to init function
    let functionCall = diamondInit.interface.encodeFunctionData('init', initArgs)
    tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
    console.log('Diamond cut tx: ', tx.hash)
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    console.log('Completed diamond cut')

    return {
      owner, signer, diamond, feeCollector, cofi, ethfi, btcfi, wyvUSDC, wyvETH, waBTC
    }
  }

  describe('SupplyFacet', function() {

    it('Should exchange underlying for fiAsset, rebase, and back again', async function() {

      const { owner, signer, diamond, feeCollector, cofi, wyvUSDC, ethfi, wyvETH, btcfi, waBTC } = await loadFixture(deploy)

      const _impersonatedSigner = await ethers.getImpersonatedSigner(usdcAccount)
      const impersonatedSigner = await ethers.getImpersonatedSigner(wethAccount)
      const __impersonatedSigner = await ethers.getImpersonatedSigner(wbtcAccount)
      // aBTC whale
      const ___impersonatedSigner = await ethers.getImpersonatedSigner('0x5A49d30D54D0f05b76b6E65f42D627da10eAF0C1')

      const _usdc = (await ethers.getContractAt(USDC_ABI, USDC)).connect(_impersonatedSigner)
      const _weth = (await ethers.getContractAt(WETH_ABI, wETH)).connect(impersonatedSigner)
      const _wbtc = (await ethers.getContractAt(WBTC_ABI, wBTC)).connect(__impersonatedSigner)

      // Transfer owner 1,000 USDC
      await _usdc.transfer(owner.address, '1000000000')

      // Transfer owner 0.5 wETH
      await _weth.transfer(owner.address, '500000000000000000')

      // Transfer owner 0.04 wBTC
      await _wbtc.transfer(owner.address, '4000000')

      const usdc = (await ethers.getContractAt(USDC_ABI, USDC)).connect(signer)
      const weth = (await ethers.getContractAt(WETH_ABI, wETH)).connect(signer)
      const wbtc = (await ethers.getContractAt(WBTC_ABI, wBTC)).connect(signer)

      // Approve 10,000 USDC spend
      await usdc.approve(diamond.address, '1000000000') // USDC has 6 digits
      await weth.approve(diamond.address, '500000000000000000')
      await wbtc.approve(diamond.address, '4000000')

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      console.log(await helpers.time.latestBlock())

      // Owner USDC bal
      console.log('t0 Owner USDC bal: ' + await usdc.balanceOf(owner.address))
      // Owner wETH bal
      console.log('t0 Owner wETH bal: ' + await weth.balanceOf(owner.address))
      // Owner wETH bal
      console.log('t0 Owner wBTC bal: ' + await wbtc.balanceOf(owner.address))
      // Owner COFI bal
      console.log('t0 Owner COFI bal: ' + await cofi.balanceOf(owner.address))
      // Owner ETHFI bal
      console.log('t0 Owner ETHFI bal: ' + await ethfi.balanceOf(owner.address))
      // Owner COFI bal
      console.log('t0 Owner BTCFI bal: ' + await btcfi.balanceOf(owner.address))

      await cofiMoney.underlyingToFi(
        '1000000000',
        '997500000000000000000',  // minOut in COFI decimals [18]
        cofi.address,
        owner.address,
        owner.address,
        feeCollector.address  // Referrer
      )
      console.log("USDC deposited")

      await cofiMoney.underlyingToFi(
        '500000000000000000',
        '498750000000000000',
        ethfi.address,
        owner.address,
        owner.address,
        feeCollector.address
      )
      console.log("wETH deposited")

      await cofiMoney.underlyingToFi(
        '4000000',
        '39900000000000000',
        btcfi.address,
        owner.address,
        owner.address,
        feeCollector.address
      )
      console.log("wBTC deposited")

      const yvusdc = (await ethers.getContractAt(YVUSDC_ABI, yvUSDC)).connect(signer)
      const yveth = (await ethers.getContractAt(YVETH_ABI, yvETH)).connect(signer)
      const abtc = (await ethers.getContractAt(ABTC_ABI, aOptWBTC)).connect(signer)

      // Owner USDC bal
      console.log('t1 Owner USDC bal: ' + await usdc.balanceOf(owner.address))
      // Owner wETH bal
      console.log('t1 Owner WETH bal: ' + await weth.balanceOf(owner.address))
      // Owner wBTC bal
      console.log('t1 Owner wBTC bal: ' + await wbtc.balanceOf(owner.address))
      // Owner COFI bal
      console.log('t1 Owner COFI bal: ' + await cofi.balanceOf(owner.address))
      // Owner ETHFI bal
      console.log('t1 Owner ETHFI bal: ' + await ethfi.balanceOf(owner.address))
      // Owner BTCFI bal
      console.log('t1 Owner BTCFI bal: ' + await btcfi.balanceOf(owner.address))
      // Wrapper A yvUSDC bal
      console.log('t1 wyvUSDC yvUSDC bal: ' + await yvusdc.balanceOf(wyvUSDC.address))
      // Wrapper B yvETH bal
      console.log('t1 wyvETH yvETH bal: ' + await yveth.balanceOf(wyvETH.address))
      // Wrapper C aBTC bal
      console.log('t1 waBTC aBTC bal: ' + await abtc.balanceOf(waBTC.address))
      // wyvUSDC tokens held in Diamond
      console.log('t1 Diamond wyvUSDC bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // wyvETH tokens held in Diamond
      console.log('t1 Diamond wyvETH bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // waBTC tokens held in Diamond
      console.log('t1 Diamond waBTC bal: ' + await waBTC.balanceOf(diamond.address))
      // COFI fee minted to fee collector
      console.log('t1 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t1 feeCollector ETHFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t1 feeCollector BTCFI bal: ' + await btcfi.balanceOf(feeCollector.address))

      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [btcfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address, ethfi.address, btcfi.address]))

      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [btcfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address, ethfi.address, btcfi.address]))

      const impersonatedSigner_ = await ethers.getImpersonatedSigner(opAccount);

      const op = (await ethers.getContractAt(OP_ABI, OP)).connect(impersonatedSigner_)
      const _abtc = (await ethers.getContractAt(ABTC_ABI, aOptWBTC)).connect(___impersonatedSigner)

      // Transfer 1.1 OP to wrapper to simulate reward harvesting
      await op.transfer(wyvUSDC.address, '1100000000000000000')
      console.log('OP transferred to wyvUSDC')

      // Transfer 1.1 OP to wrapper to simulate reward harvesting
      await op.transfer(wyvETH.address, '1100000000000000000')
      console.log('OP transferred to wyvETH')

      // Transfer 0.0001 aBTC to waBTC
      await _abtc.transfer(waBTC.address, '10000')
      console.log('aBTC transferred to waBTC')

      await cofiMoney.rebase(cofi.address)
      console.log('COFI rebased')

      await cofiMoney.rebase(ethfi.address)
      console.log('ETHFI rebased')

      await cofiMoney.rebase(btcfi.address)
      console.log('BTCFI rebased')

      const t2OwnerCOFIBal = await cofi.balanceOf(owner.address)
      const t2OwnerETHFIBal = await ethfi.balanceOf(owner.address)
      const t2OwnerBTCFIBal = await btcfi.balanceOf(owner.address)

      // Owner USDC bal
      console.log('t2 Owner USDC bal: ' + await usdc.balanceOf(owner.address))
      // Owner wETH bal
      console.log('t2 Owner WETH bal: ' + await weth.balanceOf(owner.address))
      // Owner wBTC bal
      console.log('t2 Owner wBTC bal: ' + await wbtc.balanceOf(owner.address))
      // Owner COFI bal
      console.log('t2 Owner COFI bal: ' + await cofi.balanceOf(owner.address))
      // Owner ETHFI bal
      console.log('t2 Owner ETHFI bal: ' + await ethfi.balanceOf(owner.address))
      // Owner BTCFI bal
      console.log('t2 Owner BTCFI bal: ' + await btcfi.balanceOf(owner.address))
      // Wrapper A yvUSDC bal
      console.log('t2 wyvUSDC yvUSDC bal: ' + await yvusdc.balanceOf(wyvUSDC.address))
      // Wrapper B yvETH bal
      console.log('t2 wyvETH yvETH bal: ' + await yveth.balanceOf(wyvETH.address))
      // Wrapper C aBTC bal
      console.log('t2 waBTC aBTC bal: ' + await abtc.balanceOf(waBTC.address))
      // wyvUSDC tokens held in Diamond
      console.log('t2 Diamond wyvUSDC bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // wyvETH tokens held in Diamond
      console.log('t2 Diamond wyvETH bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // waBTC tokens held in Diamond
      console.log('t2 Diamond waBTC bal: ' + await waBTC.balanceOf(diamond.address))
      // COFI fee minted to fee collector
      console.log('t2 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t2 feeCollector ETHFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t2 feeCollector BTCFI bal: ' + await btcfi.balanceOf(feeCollector.address))

      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [btcfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address, ethfi.address, btcfi.address]))

      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [btcfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address, ethfi.address, btcfi.address]))

      // Convert back to USDC (redeem operation on FiToken contract skips approval check).
      await cofiMoney.fiToUnderlying(
        t2OwnerCOFIBal.toString(),
        '1',   // Test slippage
        cofi.address,
        owner.address,
        owner.address
      )

      await cofiMoney.fiToUnderlying(
        t2OwnerETHFIBal.toString(),
        '1',   // Test slippage
        ethfi.address,
        owner.address,
        owner.address
      )

      await cofiMoney.fiToUnderlying(
        t2OwnerBTCFIBal.toString(),
        '1',   // Test slippage
        btcfi.address,
        owner.address,
        owner.address
      )

      // Owner USDC bal
      console.log('t3 Owner USDC bal: ' + await usdc.balanceOf(owner.address))
      // Owner wETH bal
      console.log('t3 Owner WETH bal: ' + await weth.balanceOf(owner.address))
      // Owner wBTC bal
      console.log('t3 Owner wBTC bal: ' + await wbtc.balanceOf(owner.address))
      // Owner COFI bal
      console.log('t3 Owner COFI bal: ' + await cofi.balanceOf(owner.address))
      // Owner ETHFI bal
      console.log('t3 Owner ETHFI bal: ' + await ethfi.balanceOf(owner.address))
      // Owner BTCFI bal
      console.log('t3 Owner BTCFI bal: ' + await btcfi.balanceOf(owner.address))
      // Wrapper A yvUSDC bal
      console.log('t3 wyvUSDC yvUSDC bal: ' + await yvusdc.balanceOf(wyvUSDC.address))
      // Wrapper B yvETH bal
      console.log('t3 wyvETH yvETH bal: ' + await yveth.balanceOf(wyvETH.address))
      // Wrapper C aBTC bal
      console.log('t3 waBTC aBTC bal: ' + await abtc.balanceOf(waBTC.address))
      // wyvUSDC tokens held in Diamond
      console.log('t3 Diamond wyvUSDC bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // wyvETH tokens held in Diamond
      console.log('t3 Diamond wyvETH bal: ' + await wyvUSDC.balanceOf(diamond.address))
      // waBTC tokens held in Diamond
      console.log('t3 Diamond waBTC bal: ' + await waBTC.balanceOf(diamond.address))
      // COFI fee minted to fee collector
      console.log('t3 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t3 feeCollector ETHFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      // ETHFI fee minted to fee collector
      console.log('t3 feeCollector BTCFI bal: ' + await btcfi.balanceOf(feeCollector.address))

      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [btcfi.address]))
      console.log('User points: ' + await cofiMoney.getPoints(owner.address, [cofi.address, ethfi.address, btcfi.address]))

      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [btcfi.address]))
      console.log('Referrer points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address, ethfi.address, btcfi.address]))
    })
  })
})