import { Signer } from '@ethersproject/abstract-signer';
import { Contract, ContractReceipt, ContractTransaction } from '@ethersproject/contracts';
import web3 from 'web3';
// @ts-ignore
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';
import { formatEther, formatUnits } from 'ethers/lib/utils';
import { ERC20 } from '../typechain-types';

export async function deployContract(
    signer: Signer,
    factoryPath: string,
    ...args: Array<any>
): Promise<Contract> {
    const factory = await ethers.getContractFactory(factoryPath);
    const contract = await factory.connect(signer).deploy(...args);
    await contract.deployTransaction.wait(1);
    return contract;
}

export async function waitTx(txRequest: Promise<ContractTransaction>): Promise<ContractReceipt> {
    const txResponse = await txRequest;
    console.log('txHash: ', txResponse.hash)
    return await txResponse.wait(1);
}

export function toBytes32String(input: any) {
    let initialInputHexStr = web3.utils.toBN(input).toString(16);
    const initialInputHexStrLength = initialInputHexStr.length;

    let inputHexStr = initialInputHexStr;
    for (let i = 0; i < 64 - initialInputHexStrLength; i++) {
        inputHexStr = '0' + inputHexStr;
    }
    return inputHexStr;
}

export async function mineBlocks(addedBlocksCount: number) {
    for (let i = 0; i < addedBlocksCount; i++) {
        await ethers.provider.send('evm_mine', []);
    }
}

export const toHuman = (x: BigNumber, decimals = 18) => {
    return formatUnits(x, decimals);
};

export const getDeadline = () => {
    return Math.floor(new Date().getTime() / 1000) + 1800;
};

export const unit = ethers.constants.WeiPerEther;
