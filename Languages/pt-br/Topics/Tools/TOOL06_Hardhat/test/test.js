const {expect} = require('chai');
const { ethers } = require('hardhat');


describe("ERC20 合约测试", ()=>{
  it("合约部署", async () => {
     // ethers.getSigners, representa uma conta eth. ethers é uma função global que pode ser chamada diretamente.
     const [owner, addr1, addr2] = await ethers.getSigners();
     // A ContractFactory in ethers.js is an abstraction used to deploy new smart contracts, so here ERC20 is the factory for instances of our token contract. ERC20 represents the ERC20.sol file in the contracts folder.
     const Token = await ethers.getContractFactory("ERC20");
     // Implante o contrato, passando os parâmetros do construtor da ERC20.sol, que são nome e símbolo, ambos chamados de WTF aqui.
     const hardhatToken = await Token.deploy("WTF", "WTF"); 
      // Aguardando a conclusão da implantação do contrato
      await hardhatToken.deployed();
      // Obter endereço do contrato
      const ContractAddress = await hardhatToken.address;
      expect(ContractAddress).to.properAddress;
  });
})