// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

    const initialBalance = hre.ethers.utils.parseEther("10");

    const Roulette = await hre.ethers.getContractFactory("Roulette");
    const roulette = await Roulette.deploy({value: initialBalance});

    await roulette.deployed();

    console.log(
        `合约地址 ${roulette.address}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
