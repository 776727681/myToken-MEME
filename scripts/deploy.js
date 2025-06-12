
const { ethers } = require("hardhat");
async function main(){
    //部署参数
    const tokenName = "MemeToken";
    const tokenSymbol = "MEME";
    const initialSuooly = 10000; // 1万代币
    const initialOwner = "0x4D7bCb3d66f6CBB3bd8f7FB102575dBfAe1aD2D5"; //测试网地址

    //部署合约
    const MemeToken = await ethers.getContractFactory("MemeToken");
    const memeToken = await MemeToken.deploy(
        tokenName,
        tokenSymbol,
        initialSuooly,
        initialOwner
    );
    //等待部署完成
    await memeToken.waitForDeployment();
    console.log('MemeToken deployed to:',memeToken.target);
}


main().catch((error)=>{
    console.error(error);
    process.exitCode = 1;
});