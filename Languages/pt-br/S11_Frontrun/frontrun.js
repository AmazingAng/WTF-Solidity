// provider.on("pendente", ouvinte)
import { ethers, utils } from "ethers";

// 1. Criar provedor
//127.0.0.1:8545";
const provider = new ethers.providers.WebSocketProvider(url);
let network = provider.getNetwork()
console.log(`[${(new Date).toLocaleTimeString()}] Conectado ao ID da cadeia ${res.chainId}`)

// 2. Criar objeto de interface para decodificar os detalhes da transação.
const iface = new utils.Interface([
    "function mint() external",
])

// 3. Criar uma carteira para enviar transações de corrida
const privateKey = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'
const wallet = new ethers.Wallet(privateKey, provider)

const main = async () => {
    // 4. Ouvir transações de mint pendentes, obter detalhes da transação e, em seguida, decodificar.
    console.log("\n4. Ouvir transações pendentes, obter txHash e imprimir detalhes da transação.")
    provider.on("pending", async (txHash) => {
        if (txHash) {
            // Obter detalhes do tx
            let tx = await provider.getTransaction(txHash);
            if (tx) {
                // filtrar pendingTx.data
                if (tx.data.indexOf(iface.getSighash("mint")) !== -1 && tx.from != wallet.address ) {
                    // Imprimir txHash
                    console.log(`\n[${(new Date).toLocaleTimeString()}] Ouvindo transação Pendente: ${txHash} \r`)

                    // Imprimir detalhes da transação decodificada
                    let parsedTx = iface.parseTransaction(tx)
                    console.log("Detalhes da transação pendente decodificados:")
                    console.log(parsedTx)
                    // Decodificando dados de entrada
                    console.log("transação bruta")
                    console.log(tx)

                    // Construindo o sistema de corrida de revezamento.
                    const txFrontrun = {
                        to: tx.to,
                        value: tx.value,
                        maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
                        maxFeePerGas: tx.maxFeePerGas * 1.2,
                        gasLimit: tx.gasLimit * 2,
                        data: tx.data
                    }
                    // Enviar transação de corrida de largada
                    var txResponse = await wallet.sendTransaction(txFrontrun)
                    console.log(`Realizando transação de frontrun`)
                    await txResponse.wait()
                    console.log(`frontrun transação bem-sucedida`)
                }
            }
        }
    });

    provider._websocket.on("error", async () => {
        console.log(`Não foi possível conectar a ${ep.subdomain} tentando novamente em 3s...`)
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
