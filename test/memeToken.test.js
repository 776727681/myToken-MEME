const { ethers } = require("hardhat")

describe("MemeToken", ()=>{
    it("Should deploy with correct supply", async()=>{
       const Token = ethers.getContractFactory("MemeToken");
       const token = (await Token).deploy("Test","TST",1000000,owner.address);
       expect(await token.totalSupply()).to.equal(
            ethers.utils.parseUnits("1000000",18)
       );
    });

})