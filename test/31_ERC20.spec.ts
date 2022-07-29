import { deployContract, waitTx } from './helper';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  ERC20
} from '../typechain-types';
// @ts-ignore
import { ethers } from 'hardhat';
import { expect } from 'chai';

const log = console.log;

describe('31 ERC20 Test', () => {
    const unit = ethers.constants.WeiPerEther;
    let operator: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let erc20: ERC20;
    let signers: SignerWithAddress[];

    before('before', async () => {
        signers = await ethers.getSigners();
        [operator, alice, bob] = signers;
        erc20 = (await deployContract(operator, '31_ERC20/ERC20.sol:ERC20', 'MyToken', 'MyToken')) as ERC20;
    });

    beforeEach('beforeEach', async () => {});

    it('test mint', async () => {
        const balance = await erc20.balanceOf(operator.address)
        const expectMintAmount = unit.mul(99999)
        await waitTx(erc20.mint(expectMintAmount))
        const balanceAfter = await erc20.balanceOf(operator.address)

        expect(balanceAfter).to.be.equal(balance.add(expectMintAmount));
    });

    it('test transfer', async () => {
        // mint to alice
        const balance = await erc20.balanceOf(alice.address)
        const expectMintAmount = unit.mul(99999)
        await waitTx(erc20.connect(alice).mint(expectMintAmount))
        const balanceAfter = await erc20.balanceOf(alice.address)
        expect(balanceAfter).to.be.equal(balance.add(expectMintAmount));

        // alice transfer to bob
        const transferAmount = unit.mul(123)
        await waitTx(erc20.connect(alice).transfer(bob.address, transferAmount))
        expect(await erc20.balanceOf(bob.address)).to.be.equal(transferAmount);
        expect(await erc20.balanceOf(alice.address)).to.be.equal(balanceAfter.sub(transferAmount));
    });

});
