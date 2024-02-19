# WTF Solidity极简入门-工具篇6：Hardhat以太坊开发环境

Eu recentemente comecei a estudar solidity novamente, revisando os detalhes e escrevendo um "WTF Solidity Guia Básico" para iniciantes. Serão lançadas de 1 a 3 aulas por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade técnica do WTF no Discord, com informações sobre como entrar no grupo do WeChat: [link](https://discord.gg/5akcruXrsk)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Hardhat é o ambiente de desenvolvimento mais popular para Ethereum. Ele pode ajudar você a compilar e implantar contratos inteligentes e fornece suporte para testar e executar Solidity na rede Hardhat. Nesta aula, vamos aprender como instalar o Hardhat, escrever e compilar contratos usando o Hardhat e executar testes simples.

## Instalando o Hardhat

### Instalando o Node.js

Você pode usar o nvm para instalar o Node.js

[GitHub - nvm-sh/nvm: Node Version Manager - POSIX-compliant bash script to manage multiple active node.js versions](https://github.com/nvm-sh/nvm)

### Instalando o Hardhat

Abra o terminal e digite:
```shell
mkdir hardhat-demo
cd hardhat-demo
npm init -y
npm install --save-dev hardhat
```

### Criando um projeto Hardhat
Abra o terminal e digite:

```shell
cd hardhat-demo
npx hardhat
```

Escolha a terceira opção: "Create an empty hardhat.config.js"

```shell
👷 Welcome to Hardhat v2.9.9 👷‍

? What do you want to do? …
  Create a JavaScript project
  Create a TypeScript project
❯ Create an empty hardhat.config.js
  Quit

```

### Instalando plugins
```shell
npm install --save-dev @nomicfoundation/hardhat-toolbox
```

Adicione o plugin ao seu arquivo de configuração do hardhat `hardhat.config.js`

```js
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
};
```

## Escrevendo e compilando contratos
Se você já usou o Remix, ao salvar o contrato ele será compilado automaticamente. Mas no ambiente de desenvolvimento local do Hardhat, você precisa compilar o contrato manualmente.

### Criando um diretório para contratos

Crie um diretório chamado `contracts` e adicione o contrato ERC20 da aula 31.

### Escrevendo o contrato
Use o contrato da aula 31 do [WTF Solidity](../31_ERC20/readme.md)

```js
// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.4;

import "./IERC20.sol";

contract ERC20 is IERC20 {

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;   // 代币总供给

    string public name;   // 名称
    string public symbol;  // 符号
    
    uint8 public decimals = 18; // 小数位数

    // @dev 在合约部署的时候实现合约名称和符号
    constructor(string memory name_, string memory symbol_){
        name = name_;
        symbol = symbol_;
    }

    // @dev 实现`transfer`函数，代币转账逻辑
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // @dev 实现 `approve` 函数, 代币授权逻辑
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // @dev 实现`transferFrom`函数，代币授权转账逻辑
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // @dev 铸造代币，从 `0` 地址转账给 调用者地址
    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // @dev 销毁代币，从 调用者地址 转账给  `0` 地址
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

```

### Compilando o contrato
```shell
npx hardhat compile
```

Se você vir a seguinte saída, significa que o contrato foi compilado com sucesso:

```shell
Compiling 2 Solidity files successfully
```

Após a compilação, você verá a pasta `artifacts` no diretório, que contém os arquivos `json` resultantes da compilação.

## Escrevendo testes unitários

Os testes unitários são muito simples e apenas verificam se o contrato foi implantado corretamente (se o endereço do contrato é válido).

Crie uma pasta chamada `test` e dentro dela crie um arquivo chamado `test.js`. Nos testes unitários, usaremos as bibliotecas `chai` e `ethers.js`, que são usadas para testar e interagir com a blockchain, respectivamente. Se você não está familiarizado com o `ethers.js`, pode dar uma olhada nas primeiras 6 aulas do [WTF Ethers Tutorial](https://github.com/WTFAcademy/WTF-Ethers). Nos próximos tutoriais, vamos explorar mais detalhes sobre o `chai` e o `mocha`.

```js
const { expect } = require('chai');
const { ethers } = require('hardhat');


describe("Teste do contrato ERC20", ()=>{
  it("Implantação do contrato", async () => {
     // ethers.getSigners, representa as contas eth
     // ethers é uma função global que pode ser chamada diretamente
     const [owner, addr1, addr2] = await ethers.getSigners();
     // O ContractFactory em ethers.js é usado para implantar novos contratos inteligentes, então aqui o Token é a fábrica de instâncias do contrato de token. ERC20 representa o arquivo ERC20.sol na pasta contracts
     const Token = await ethers.getContractFactory("ERC20");
     // Implantação do contrato, passando os argumentos do construtor do ERC20.sol, que são name e symbol, ambos chamados de WTF
     const hardhatToken = await Token.deploy("WTF", "WTF"); 
      // Obtendo o endereço do contrato
     const ContractAddress = await hardhatToken.address;
     expect(ContractAddress).to.properAddress;
  });
})
```

## Executando os testes

No terminal, digite o seguinte comando para executar os testes:

```shell
npx hardhat test
# Se você tiver vários arquivos de teste e quiser executar um arquivo específico, use
npx mocha test/test.js
```

Se você vir a seguinte saída, significa que os testes foram executados com sucesso.

```shell
  Teste do contrato ERC20
    ✔ Implantação do contrato (1648ms)


  1 passing (2s)
```

## Implantação do contrato

No Remix, basta clicar em "deploy" para implantar o contrato. Mas no Hardhat local, precisamos escrever um script de implantação.

Crie uma pasta chamada `scripts` e escreva um script de implantação do contrato. Em seguida, crie um arquivo chamado `deploy.js` dentro dessa pasta.

Digite o seguinte código:

```js
// Podemos executar o script desejado usando npx hardhat run <script>
// Aqui você pode usar npx hardhat run deploy.js para executar
const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("ERC20");
  const token = await Contract.deploy("WTF","WTF");

  await token.deployed();

  console.log("Contrato implantado com sucesso:", token.address);
}

// Executando o script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

```

Execute o seguinte comando para implantar o contrato na rede de teste local:

O Hardhat fornece uma rede padrão, consulte: [Rede padrão do Hardhat](https://hardhat.org/hardhat-network/docs/overview)

```shell
npx hardhat run --network hardhat  scripts/deploy.js
```

Se você vir a seguinte saída, significa que o contrato foi implantado com sucesso:

```shell
(node:45779) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
Contrato implantado com sucesso: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

## Implantação do contrato na rede de teste Goerli | Configuração de rede

### Preparação

1. Solicite uma chave de API da Alchemy
Consulte [Aula 4: Alchemy, API Blockchain e Infraestrutura de Nós](../Topics/Tools/TOOL04_Alchemy/readme.md) 
2. Solicite tokens de teste Goerli
[Clique aqui para solicitar](https://goerlifaucet.com/) Faça login na sua conta Alchemy e você poderá receber 0,2 tokens de teste por dia.
3. Exporte a chave privada
Como precisamos implantar o contrato na rede de teste Goerli, a conta de teste deve ter alguns tokens de teste. Exporte a chave privada da conta de teste que já possui tokens de teste para implantar o contrato.
4. Solicite uma chave de API do Etherscan para verificar o contrato
[Clique aqui para solicitar](https://etherscan.io/myapikey)

### Configurando a rede

No arquivo `hardhat.config.js`, podemos configurar várias redes, aqui vamos configurar a rede de teste Goerli.

Edite o arquivo `hardhat.config.js`

```js
require("@nomicfoundation/hardhat-toolbox");

// Solicite uma chave de API da Alchemy
const ALCHEMY_API_KEY = "KEY";

// Substitua esta chave privada pela chave privada da sua conta de teste
// Exporte sua chave privada do Metamask, abra o Metamask e vá para "Detalhes da conta"> "Exportar chave privada"
// Atenção: nunca coloque ETH real em uma conta de teste
const GOERLI_PRIVATE_KEY = "YOUR GOERLI PRIVATE KEY";

// Solicite uma chave de API do Etherscan
const ETHERSCAN_API_KEY = "YOUR_ETHERSCAN_API_KEY";

module.exports = {
  solidity: "0.8.9", // Versão de compilação do solidity
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
```

Após a configuração, execute o seguinte comando para implantar o contrato na rede de teste Goerli:

```shell
npx hardhat run --network goerli scripts/deploy.js
```

Agora você implantou seu contrato na rede de teste Goerli.

Se você vir a seguinte saída, significa que o contrato foi implantado com sucesso na rede de teste Goerli:

```shell
(node:46996) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
(node:46999) ExperimentalWarning: stream/web is an experimental feature. This feature could change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
Contrato implantado com sucesso: 0xeEAcef71084Dd1Ae542***9D8F64E3c68e15****
```

Você pode verificar o contrato no [etherscan](https://etherscan.io/)

Da mesma forma, você pode configurar várias redes, como `mainnet`, `rinkeby`, etc.

Por fim, verifique seu contrato:

```shell
npx hardhat verify --network goerli DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1"
```


## Conclusão

Nesta aula, aprendemos o básico do Hardhat. Com o Hardhat, podemos criar projetos de Solidity de forma mais estruturada e ele fornece muitos recursos úteis. Nos próximos artigos, exploraremos recursos avançados do Hardhat, como plugins e frameworks de teste.

