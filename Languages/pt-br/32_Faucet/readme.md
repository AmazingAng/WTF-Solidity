# WTF Solidity Crash Course: 32. Token Faucet

Recentemente, tenho revisado meus conhecimentos sobre Solidity para consolidar detalhes e escrever um "Curso Rápido de Solidity". Este curso é destinado a iniciantes (programadores experientes podem procurar outras fontes), e eu pretendo adicionar de 1 a 3 aulas por semana.

Siga-me no Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Junte-se à comunidade WTF Scientists, onde você pode encontrar informações sobre como entrar no nosso grupo do Discord: [Link](https://discord.gg/5akcruXrsk)

Todo o código e tutorial estão disponíveis no meu GitHub (obteremos um certificado de curso com 1024 estrelas e um NFT comunitário com 2048 estrelas): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

No último tutorial, aprendemos sobre o padrão de token ERC20. Nesta aula, vamos aprender sobre contratos inteligentes de faucet ERC20. Neste contrato, os usuários podem receber tokens ERC20 gratuitos.

## Faucet de Tokens

Assim como você vai a uma torneira para beber água quando está com sede, você também pode ir a um "faucet de tokens" para receber tokens gratuitos quando deseja. Um faucet de tokens é um site/aplicativo que permite aos usuários receber tokens gratuitos.

O primeiro exemplo de faucet de tokens foi o faucet de Bitcoin (BTC): hoje, um BTC custa cerca de $30.000, mas em 2010, o preço de um BTC era menos de $0.1 e havia poucos detentores. Para aumentar sua base de usuários, Gavin Andresen, da comunidade do Bitcoin, criou o faucet de Bitcoin, permitindo que outras pessoas recebessem BTC gratuitamente. Muitos foram atraídos por esta oportunidade, e uma parte dessas pessoas se tornaram entusiastas do Bitcoin. O Bitcoin faucet distribuiu mais de 19.700 BTC, que atualmente valem cerca de $600 milhões!

## Contrato Faucet ERC20

Neste exemplo, vamos implementar uma versão simplificada de um faucet ERC20. A lógica é simples: transferimos alguns tokens ERC20 para o contrato do faucet e os usuários podem solicitar 100 unidades desses tokens através da função `requestToken()`, com cada endereço podendo solicitar apenas uma vez.

### Variáveis de Estado

Vamos definir 3 variáveis de estado no contrato do faucet:

- `amountAllowed` define a quantidade de tokens que cada pessoa pode receber a cada solicitação (pode ser menos que 100 devido à divisão decimal dos tokens).
- `tokenContract` registra o endereço do contrato dos tokens ERC20 distribuídos.
- `requestedAddress` mantém o registro dos endereços que solicitaram tokens.

```solidity
uint256 public amountAllowed = 100; // Receber 100 unidades de token por solicitação
address public tokenContract;   // Endereço do contrato dos tokens
mapping(address => bool) public requestedAddress;   // Registro de endereços que solicitaram tokens
```

### Eventos

No contrato do faucet, definimos um evento `SendToken`, que registra o endereço e a quantidade de tokens solicitados a cada transferência, quando a função `requestTokens()` é chamada.

```solidity
// Evento de envio de token
event SendToken(address indexed Receiver, uint256 indexed Amount); 
```

### Funções

O contrato possui apenas duas funções:

- Construtor: inicializa a variável de estado `tokenContract`, definindo o endereço do contrato dos tokens ERC20 a serem distribuídos.

```solidity
// Definir o contrato ERC20 ao implantar
constructor(address _tokenContract) {
    tokenContract = _tokenContract; // definir contrato de token
}
```

- Função `requestTokens()`: os usuários podem chamar essa função para receber tokens ERC20.

```solidity
// Função para os usuários receberem tokens
function requestTokens() external {
    require(requestedAddress[msg.sender] == false, "Não é possível solicitar várias vezes!"); // cada endereço só pode solicitar uma vez
    IERC20 token = IERC20(tokenContract); // cria o objeto do contrato IERC20
    require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Vazio!"); // o faucet está vazio

    token.transfer(msg.sender, amountAllowed); // enviar tokens
    requestedAddress[msg.sender] = true; // registrar o endereço que solicitou
    
    emit SendToken(msg.sender, amountAllowed); // emite o evento SendToken
}
```

## Demonstração no Remix

1. Primeiro, implantamos o contrato dos tokens ERC20, com nome e símbolo `WTF`, e criamos 10.000 unidades de tokens usando a função `mint`.
    ![Implantar contrato ERC20](./img/32-1.png)

2. Em seguida, implantamos o contrato do faucet, passando o endereço do contrato dos tokens ERC20 como parâmetro de inicialização.
    ![Implantar contrato do Faucet](./img/32-2.png)

3. Usamos a função `transfer()` do contrato dos tokens ERC20 para transferir 10.000 unidades de tokens para o endereço do contrato do faucet.
    ![Transferir tokens para o Faucet](./img/32-3.png)

4. Em uma nova conta, chamamos a função `requestTokens()` do contrato do faucet para receber os tokens. Podemos ver o evento `SendToken` sendo emitido no console.
    ![Mudar de conta](./img/32-4.png)
    
    ![requestToken](./img/32-5.png)
    
5. Usando a função `balanceOf` no contrato dos tokens ERC20, verificamos o saldo da conta que recebeu os tokens do faucet, que agora é de 100 unidades. A solicitação foi bem-sucedida!
    ![Solicitação bem-sucedida](./img/32-6.png)

## Conclusão

Nesta aula, exploramos a história dos faucets de tokens e o contrato de faucet ERC20. Onde você acha que será o próximo faucet de Bitcoin?

---

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->