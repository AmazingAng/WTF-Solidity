import { network } from "hardhat";

async function main() {
  const { ethers } = await network.create();
  const token = await ethers.deployContract("ERC20", ["WTF", "WTF"]);
  await token.waitForDeployment();
  console.log(await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
