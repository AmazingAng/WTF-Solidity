import { ethers } from "ethers";

// Inicializando os provedores das duas cadeias
const providerGoerli = new ethers.JsonRpcProvider("Goerli_Provider_URL");
//eth-sepolia.g.alchemy.com/v2/RgxsjQdKTawszh80TpJ-14Y8tY7cx5W2");

// Inicializando os signatários das duas cadeias
// privateKey preencha com a chave privada da carteira do administrador
const privateKey = "Your_Key";
const walletGoerli = new ethers.Wallet(privateKey, providerGoerli);
const walletSepolia = new ethers.Wallet(privateKey, providerSepolia);

// Endereço do contrato e ABI
const contractAddressGoerli = "0xa2950F56e2Ca63bCdbA422c8d8EF9fC19bcF20DD";
const contractAddressSepolia = "0xad20993E1709ed13790b321bbeb0752E50b8Ce69";

const abi = [
    "event Bridge(address indexed user, uint256 amount)",
    "function bridge(uint256 amount) public",
    "function mint(address to, uint amount) external",
];

// Inicializando a instância do contrato
const contractGoerli = new ethers.Contract(contractAddressGoerli, abi, walletGoerli);
const contractSepolia = new ethers.Contract(contractAddressSepolia, abi, walletSepolia);

const main = async () => {
    try{
        console.log(`Começando a ouvir eventos de interconexão`)

        // Ouvir eventos de ponte do Chain Sepolia e executar a operação de mint no Goerli para concluir a transferência entre cadeias.
        contractSepolia.on("Bridge", async (user, amount) => {
            console.log(`Evento de ponte na Chain Sepolia: Usuário ${user} queimou ${amount} tokens`)

            // Ao executar a operação de queima
            let tx = await contractGoerli.mint(user, amount);
            await tx.wait();

            console.log(`Cunhou ${amount} tokens para ${user} na Chain Goerli`)
        });

        // Ouvir eventos de ponte do Chain Sepolia e executar a operação de mint no Goerli para concluir a transferência entre cadeias.
        contractGoerli.on("Bridge", async (user, amount) => {
            console.log(`Evento de ponte na Chain Goerli: Usuário ${user} queimou ${amount} tokens`)

            // Ao executar a operação de queima
            let tx = await contractSepolia.mint(user, amount);
            await tx.wait();

            console.log(`Cunhou ${amount} tokens para ${user} na Chain Sepolia`)
        });

    }catch(e){
        console.log(e)
    
    } 
}

main();