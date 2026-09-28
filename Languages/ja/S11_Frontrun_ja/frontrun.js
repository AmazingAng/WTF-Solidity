// provider.on("pending", listener)
import { ethers, utils } from "ethers";

// 1. providerを作成
var url = "http://127.0.0.1:8545";
const provider = new ethers.providers.WebSocketProvider(url);
let network = provider.getNetwork()
network.then(res => console.log(`[${(new Date).toLocaleTimeString()}] chain ID ${res.chainId}に接続`));

// 2. interfaceオブジェクトを作成、取引詳細をデコードするために使用
const iface = new utils.Interface([
    "function mint() external",
])

// 3. ウォレットを作成、フロントランニング取引を送信するために使用
const privateKey = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
const wallet = new ethers.Wallet(privateKey, provider)

const main = async () => {
    // 4. pendingのmint取引を監視し、取引詳細を取得してデコード
    console.log("\n4. pending取引を監視、txHashを取得し、取引詳細を出力。")
    provider.on("pending", async (txHash) => {
        if (txHash) {
            // tx詳細を取得
            let tx = await provider.getTransaction(txHash);
            if (tx) {
                // pendingTx.dataをフィルタ
                if (tx.data.indexOf(iface.getSighash("mint")) !== -1 && tx.from != wallet.address ) {
                    // txHashを印刷
                    console.log(`\n[${(new Date).toLocaleTimeString()}] Pending取引を監視: ${txHash} \r`);

                    // デコードされた取引詳細を印刷
                    let parsedTx = iface.parseTransaction(tx)
                    console.log("pending取引詳細デコード：")
                    console.log(parsedTx);
                    // Input dataデコード
                    console.log("raw transaction")
                    console.log(tx);

                    // フロントランニングtxを構築
                    const txFrontrun = {
                        to: tx.to,
                        value: tx.value,
                        maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
                        maxFeePerGas: tx.maxFeePerGas * 1.2,
                        gasLimit: tx.gasLimit * 2,
                        data: tx.data
                    }
                    // フロントランニング取引を送信
                    var txResponse = await wallet.sendTransaction(txFrontrun)
                    console.log(`フロントランニング取引中`)
                    await txResponse.wait()
                    console.log(`フロントランニング取引成功`)
                }
            }
        }
    });

    provider._websocket.on("error", async () => {
        console.log(`Unable to connect to ${ep.subdomain} retrying in 3s...`);
        setTimeout(init, 3000);
      });

    provider._websocket.on("close", async (code) => {
        console.log(
            `Connection lost with code ${code}! Attempting reconnect in 3s...`
        );
        provider._websocket.terminate();
        setTimeout(init, 3000);
    });
};

main()