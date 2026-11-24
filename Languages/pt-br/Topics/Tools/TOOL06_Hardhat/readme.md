# WTF Solidity极简入门-工具篇6：Hardhat以太坊开发环境

Eu recentemente comecei a estudar solidity novamente, revisando os detalhes e escrevendo um "WTF Solidity Guia Básico" para iniciantes. Serão lançadas de 1 a 3 aulas por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade técnica do WTF no Discord, com informações sobre como entrar no grupo do WeChat: [link](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTF-Solidity](https://github.com/AmazingAng/WTF-Solidity)

---

Este exemplo usa Node.js 22.12 ou superior, Hardhat 3.22.0, Solidity 0.8.39 e ethers 6.17.0.

```sh
npm ci
npx hardhat compile
npm test
npx hardhat run scripts/deploy.js
npx hardhat node
```

[ERC20.sol](./contracts/ERC20.sol) usa o contrato ERC-20 da lição 31.
O Hardhat compila os arquivos em `contracts/` seguindo a
[configuração](./hardhat.config.js). A lista `plugins` carrega o ethers e o Mocha.
O campo `"type": "module"` habilita os módulos ES.

O [teste](./test/test.js) abre uma conexão local com `network.create()`,
implanta o contrato por meio de `ethers.deployContract` e confere o nome
e o símbolo depois da confirmação da implantação.

O [script](./scripts/deploy.js) imprime o endereço do contrato. Sem
`--network`, o script usa uma rede local temporária. Para usar o nó local
em execução, rode `npx hardhat run scripts/deploy.js --network localhost`
em outro terminal.

## Implantação na Sepolia

Configure `SEPOLIA_RPC_URL` e `SEPOLIA_PRIVATE_KEY` no terminal. Use uma conta
dedicada a testes, com Sepolia ETH para pagar a taxa. Execute:

```sh
npx hardhat run scripts/deploy.js --network sepolia
```

Consulte a [documentação do Hardhat 3](https://hardhat.org/docs) para detalhes
sobre variáveis, redes simuladas e plugins.
