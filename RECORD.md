1. 安装工具

    浏览器钱包（推荐 MetaMask）
    代码编辑器（Remix 在线 IDE 或本地 VS Code）
    测试网 ETH（通过水龙头获取）

### 2. 获取测试币


    - Sepolia 测试网: https://sepoliafaucet.com
    - Goerli 测试网: https://goerlifaucet.com
    - 每次可领取 0.1-0.5 ETH（需登录 Alchemy 账户）

    
### 项目初始化


    mkdir mytoken && cd mytoken
    npm init -y
    npm install --save-dev hardhat @nomiclabs/hardhat-waffle ethers @openzeppelin/contracts
    npx hardhat

### 配置 hardhat.config.js


    require("@nomiclabs/hardhat-waffle");
    require('dotenv').config();

    module.exports = {
        solidity: "0.8.4",
        networks: {
            sepolia: {
                url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
                accounts: [process.env.PRIVATE_KEY]
            }
        }
    };
### 部署脚本


    // scripts/deploy.js
    async function main() {
        const [deployer] = await ethers.getSigners();
        console.log("Deploying with account:", deployer.address);

        const Token = await ethers.getContractFactory("MyToken");
        const token = await Token.deploy(1000000); // 100万代币

        console.log("Token deployed to:", token.address);
    }
### 执行部署


    npx hardhat run scripts/deploy.js --network sepolia

### 合约不可升级 ，如需可升级合约，使用 OpenZeppelin Upgradeable 模板：


    import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";




    