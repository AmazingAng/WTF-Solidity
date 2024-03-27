const {expect} = require('chai');
const { ethers } = require('hardhat');


describe("ERC20 合约测试", ()=>{
  it("合约部署", async () => {
     // ethers.getSigners,代表eth账号  ethers 是一个全局函数，可以直接调用
     const [owner, addr1, addr2] = await ethers.getSigners();
     // ethers.js 中的 ContractFactory 是用于部署新智能合约的抽象，因此这里的 ERC20 是我们代币合约实例的工厂。ERC20代表contracts 文件夹中的 ERC20.sol 文件
     const Token = await ethers.getContractFactory("ERC20");
     // 部署合约, 传入参数 ERC20.sol 中的构造函数参数分别是 name, symbol 这里我们都叫做WTF
     const hardhatToken = await Token.deploy("WTF", "WTF"); 
      // 等待合约部署完成
      await hardhatToken.waitForDeployment();
      // 获取合约地址
      const ContractAddress = await hardhatToken.target;
      expect(ContractAddress).to.properAddress;
  });
})