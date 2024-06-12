require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    "mainnet": {
      "url": "https://mainnet.infura.io/v3/35466ea974844d3fa4066151068fbbd8",
      "accounts": ["0x99589bb37ca91fcba43a3cacb463452224fbbc35d6ee6f6a45dc7ee5da82282d"],
      "gasPrice": 20000000000
    }
  }
};
