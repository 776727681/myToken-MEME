# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

# 编译合约

    npx hardhat compile

# 部署到本地网络

    npx hardhat run scripts/deploy.js

# 部署到测试网

    npx hardhat run scripts/deploy.js --network sepolia

# 验证合约 (需要ETHERSCAN_API_KEY)

    npx hardhat verify --network sepolia <合约地址> "MemeToken" "MEME" 1000000



<!-- npx hardhat verify --network sepolia 0xD6F90E12C3746cF825FF5d5845FBEe726368ba09 "MemeToken" "MEME" 10000 -->

