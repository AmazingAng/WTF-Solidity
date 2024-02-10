const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("create2 test", function () {
  it("Should return the new create2test once it's changed", async function () {
    console.log("1.==> deploy pair");
    const PairFactory = await ethers.getContractFactory("Pair");
    const Pair = await PairFactory.deploy();
    await Pair.deployed();
    console.log("pair address =>",Pair.address);

    console.log();
    console.log("2.==> deploy PairFactory2");   
    const PairFactory2Factory = await ethers.getContractFactory("PairFactory2");
    const PairFactory2 = await PairFactory2Factory.deploy();
    await PairFactory2.deployed();
    console.log("PairFactory2 address =>",PairFactory2.address);
    
    console.log("3.==> calculateAddr for wbnb people");  
    const WBNBAddress = "0x2c44b726ADF1963cA47Af88B284C06f30380fC78";
    const PEOPLEAddress = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";

    let predictedAddress = await PairFactory2.calculateAddr(WBNBAddress, PEOPLEAddress);
    console.log("predictedAddress address =>",predictedAddress);

    console.log("4.==> createPair2 for wbnb people");  
    await PairFactory2.createPair2(WBNBAddress, PEOPLEAddress);
    let createPair2Address = await PairFactory2.allPairs(0);
    console.log("createPair2Address address =>",createPair2Address);

    expect(createPair2Address).to.equal(predictedAddress);

  });
});