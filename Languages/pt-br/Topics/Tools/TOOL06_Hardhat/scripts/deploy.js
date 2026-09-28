// Podemos executar o script desejado usando npx hardhat run <script>
// Aqui você pode usar npx hardhat run deploy.js para executar
const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("ERC20");
  const token = await Contract.deploy("WTF","WTF");

  await token.waitForDeployment();

  console.log("Contrato implantado com sucesso:", token.target)
}

// Executar script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
