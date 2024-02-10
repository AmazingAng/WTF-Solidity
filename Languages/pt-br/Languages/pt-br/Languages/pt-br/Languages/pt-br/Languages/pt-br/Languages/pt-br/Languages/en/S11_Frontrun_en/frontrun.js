// english translation by 22X

// provider.on("pending", listener)
import { ethers, utils } from "ethers";

// 1. Create provider
var url = "http://127.0.0.1:8545";
const provider = new ethers.providers.WebSocketProvider(url);
let network = provider.getNetwork();
network.then(res =>
  console.log(
    `[${new Date().toLocaleTimeString()}] Connected to chain ID ${res.chainId}`,
  ),
);

// 2. Create interface object for decoding transaction details.
const iface = new utils.Interface(["function mint() external"]);

// 3. Create wallet for sending frontrun transactions.
const privateKey =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
const wallet = new ethers.Wallet(privateKey, provider);

const main = async () => {
  // 4. Listen for pending mint transactions, get transaction details, and decode them.
  console.log("\n4. Listen for pending transactions, get txHash, and output transaction details.");
  provider.on("pending", async txHash => {
    if (txHash) {
      // Get transaction details
      let tx = await provider.getTransaction(txHash);
      if (tx) {
        // Filter pendingTx.data
        if (
          tx.data.indexOf(iface.getSighash("mint")) !== -1 &&
          tx.from != wallet.address
        ) {
          // Print txHash
          console.log(
            `\n[${new Date().toLocaleTimeString()}] Listening to Pending transaction: ${txHash} \r`,
          );

          // Print decoded transaction details
          let parsedTx = iface.parseTransaction(tx);
          console.log("Decoded pending transaction details:");
          console.log(parsedTx);
          // Decode input data
          console.log("Raw transaction:");
          console.log(tx);

          // Build frontrun tx
          const txFrontrun = {
            to: tx.to,
            value: tx.value,
            maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
            maxFeePerGas: tx.maxFeePerGas * 1.2,
            gasLimit: tx.gasLimit * 2,
            data: tx.data,
          };
          // Send frontrun transaction
          var txResponse = await wallet.sendTransaction(txFrontrun);
          console.log(`Sending frontrun transaction`);
          await txResponse.wait();
          console.log(`Frontrun transaction successful`);
        }
      }
    }
  });

  provider._websocket.on("error", async () => {
    console.log(`Unable to connect to ${ep.subdomain} retrying in 3s...`);
    setTimeout(init, 3000);
  });

  provider._websocket.on("close", async code => {
    console.log(
      `Connection lost with code ${code}! Attempting reconnect in 3s...`,
    );
    provider._websocket.terminate();
    setTimeout(init, 3000);
  });
};

main();
