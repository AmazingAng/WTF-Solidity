const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("create2 Prueba", function () {
    it("Debe retornar el nuevo create2test una vez que se haya cambiado", async function () {
        console.log("1.==> Desplegar PairFactory2");
        const PairFactory = await ethers.getContractFactory("Pair");
        const Pair = await PairFactory.deploy();
        await Pair.waitForDeployment();
        console.log("Dirección de pair =>", Pair.target);

        console.log();
        console.log("2.==> Desplegar PairFactory2");
        const PairFactory2Factory =
            await ethers.getContractFactory("PairFactory2");
        const PairFactory2 = await PairFactory2Factory.deploy();
        await PairFactory2.waitForDeployment();
        console.log("Dirección de PairFactory2 =>", PairFactory2.target);

        console.log("3.==> calculateAddr para wbnb people");
        const WBNBAddress = "0x2c44b726ADF1963cA47Af88B284C06f30380fC78";
        const PEOPLEAddress = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";

        let predictedAddress = await PairFactory2.calculateAddr(
            WBNBAddress,
            PEOPLEAddress
        );
        console.log("Dirección de predictedAddress =>", predictedAddress);

        console.log("4.==> createPair2 para wbnb people");
        await PairFactory2.createPair2(WBNBAddress, PEOPLEAddress);
        let createPair2Address = await PairFactory2.allPairs(0);
        console.log("Dirección de createPair2Address =>", createPair2Address);

        expect(createPair2Address).to.equal(predictedAddress);
    });
});
