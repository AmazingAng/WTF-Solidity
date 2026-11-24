import assert from "node:assert/strict";
import { network } from "hardhat";
import { describe, it } from "mocha";

describe("ERC20", () => {
  it("deploys a token with the configured name and symbol", async () => {
    const { ethers } = await network.create();
    const token = await ethers.deployContract("ERC20", ["WTF", "WTF"]);
    await token.waitForDeployment();

    assert.equal(await token.name(), "WTF");
    assert.equal(await token.symbol(), "WTF");
  });
});
