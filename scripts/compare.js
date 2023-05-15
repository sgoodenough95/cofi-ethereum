/* global ethers */
/* eslint prefer-const: "off" */

// Get the contract addresses
const contractAddress1 = "0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE";
const contractAddress2 = "0xA5269A8e31B93Ff27B887B56720A25F844db0529";

// Connect to the Ethereum blockchain
const provider = new ethers.providers.HttpProvider("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID");

// Get the contracts
const contract1 = new ethers.Contract(
  {
    abi: [
      {
        constant: true,
        inputs: [],
        name: "deposit",
        outputs: [
          {
            name: "",
            type: "uint256",
          },
        ],
      },
      {
        constant: true,
        inputs: [],
        name: "convertToAssets",
        outputs: [
          {
            name: "",
            type: "uint256",
          },
        ],
      },
    ],
    address: contractAddress1,
  },
  provider
);

const contract2 = new ethers.Contract(
  {
    abi: [
      {
        constant: true,
        inputs: [],
        name: "deposit",
        outputs: [
          {
            name: "",
            type: "uint256",
          },
        ],
      },
      {
        constant: true,
        inputs: [],
        name: "convertToAssets",
        outputs: [
          {
            name: "",
            type: "uint256",
          },
        ],
      },
    ],
    address: contractAddress2,
  },
  provider
);

// Get the number of shares when depositing first
const shares1 = await contract1.deposit.call();
const shares2 = await contract2.deposit.call();

// Call convertToAssets() at the beginning and after 7 days to determine the difference
const assets1_initial = await contract1.convertToAssets.call();
const assets1_after_7_days = await contract1.convertToAssets.call(7 * 24 * 60 * 60);
const assets2_initial = await contract2.convertToAssets.call();
const assets2_after_7_days = await contract2.convertToAssets.call(7 * 24 * 60 * 60);

// Compare the differences
if (assets1_after_7_days - assets1_initial > assets2_after_7_days - assets2_initial) {
  console.log("Vault 1 has a higher yield");
} else if (assets1_after_7_days - assets1_initial < assets2_after_7_days - assets2_initial) {
  console.log("Vault 2 has a higher yield");
} else {
  console.log("The yields are equal");
}