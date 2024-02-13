# WTF Solidity Simplified: 57. Flash Loans

Eu tenho revisitado o aprendizado de Solidity recentemente, consolidando alguns detalhes e escrevendo um "WTF Solidity Simplified" para iniciantes (programadores experientes podem procurar outros tutoriais). Atualização semanal de 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais são open source no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

A expressão "ataque de empréstimo-relâmpago" é algo que muitas pessoas já ouviram falar, mas o que exatamente é um empréstimo-relâmpago? Como escrever contratos inteligentes que utilizam empréstimos-relâmpago? Nesta lição, vamos falar sobre empréstimos-relâmpago no contexto das criptomoedas, implementando contratos inteligentes de empréstimos-relâmpago baseados em Uniswap V2, Uniswap V3 e AAVE V3 e testando-os com o Foundry.

## Empréstimos-Relâmpago

Provavelmente você já ouviu falar sobre "empréstimos-relâmpago" no mundo DeFi (Finanças Descentralizadas), pois esse conceito não existe no mundo financeiro tradicional. Empréstimos-relâmpago (flash loans) são uma inovação no DeFi que permitem aos usuários tomar empréstimos e devolvê-los rapidamente em uma única transação, sem a necessidade de fornecer qualquer garantia.

Imagine que você identifica uma oportunidade de arbitragem no mercado que requer uma quantia de 1 milhão de tokens. No mundo financeiro tradicional, você teria que solicitar um empréstimo ao banco, passar por um processo de aprovação e, muitas vezes, perderia a oportunidade de arbitragem. Além disso, se a arbitragem não fosse bem-sucedida, você teria que pagar os juros e ainda devolver o capital perdido.

No mundo DeFi, você pode pegar um empréstimo-relâmpago em uma plataforma como Uniswap, AAVE ou Dodo, para obter os fundos necessários e realizar a arbitragem. Depois, você devolve o empréstimo, juntamente com os juros, em uma única transação. Os empréstimos-relâmpago se beneficiam da atomicidade das transações Ethereum: ou a transação é totalmente executada, ou é totalmente revertida. Isso significa que se um usuário tentar usar um empréstimo-relâmpago e não devolver os fundos na mesma transação, tudo será desfeito como se a transação nunca tivesse acontecido. Portanto, as plataformas DeFi não precisam se preocupar com a inadimplência dos mutuários, pois a transação falharia se os fundos não fossem devolvidos.

## Implementação de Empréstimos-Relâmpago

A seguir, vamos mostrar como implementar contratos de empréstimo-relâmpago para Uniswap V2, Uniswap V3 e AAVE V3.

### 1. Empréstimo-Relâmpago Uniswap V2

O contrato `UniswapV2Pair` da [Uniswap V2](https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L159) possui a função `swap()` que suporta empréstimos-relâmpago. O código relacionado aos empréstimos-relâmpago é o seguinte:

```solidity
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
    // Outras lógicas...

    // Transferência otimista dos tokens para o endereço 'to'
    if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
    if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

    // Chamada da função de retorno 'uniswapV2Call' no endereço 'to'
    if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

    // Outras lógicas...

    // Verificação se o empréstimo-relâmpago foi devolvido com sucesso utilizando a fórmula k=x*y
    require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
}
```

No código acima, na função `swap()`:

1. Os tokens do pool são transferidos otimisticamente para o endereço `to`.
2. Se o tamanho dos dados passados for maior que 0, a função de retorno `uniswapV2Call` do endereço `to` é chamada, executando a lógica do empréstimo-relâmpago.
3. Por fim, é verificado se o empréstimo-relâmpago foi devolvido com sucesso usando a fórmula `k=x*y`. Se não foi devolvido, a transação é revertida.

A seguir, concluímos o contrato de empréstimo-relâmpago `UniswapV2Flashloan.sol`. Ele herda a interface `IUniswapV2Callee` e a lógica principal do empréstimo-relâmpago é escrita na função de retorno `uniswapV2Call`.

A lógica geral é simples: na função `flashloan()`, pegamos emprestado `WETH` do pool `WETH-DAI` da Uniswap V2. Após o empréstimo ser acionado, a função de retorno `uniswapV2Call` é chamada pelo contrato do par, mas não realizamos arbitragem. Em vez disso, calculamos os juros e devolvemos o empréstimo-relâmpago. Os juros de um empréstimo-relâmpago na Uniswap V2 são de 0,3%.

**Nota:** Certifique-se de controlar adequadamente as permissões da função de retorno para garantir que apenas o contrato do par Uniswap possa chamar, caso contrário, os fundos do contrato podem ser roubados por um hacker.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// Interface de retorno para o empréstimo-relâmpago UniswapV2
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// Contrato de empréstimo-relâmpago UniswapV2
contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

    // Função de empréstimo-relâmpago
    function flashloan(uint wethAmount) external {
        // Os dados são codificados para serem passados à função de retorno
        bytes memory data = abi.encode(WETH, wethAmount);

        // amount0Out é a quantia de DAI a ser pedida, amount1Out é a quantidade de WETH a ser pedida
        pair.swap(0, wethAmount, address(this), data);
    }

    // Função de retorno para empréstimo-relâmpago, pode ser chamada apenas pelo contrato de par do DAI/WETH
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        // Confirma que a chamada veio do par DAI/WETH
        address token0 = IUniswapV2Pair(msg.sender).token0(); // Obtém o endereço do token0
        address token1 = IUniswapV2Pair(msg.sender).token1(); // Obtém o endereço do token1
        assert(msg.sender == factory.getPair(token0, token1)); // Garante que o msg.sender seja um par V2 válido

        // Decodifica os dados
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // Lógica do empréstimo, omitida neste exemplo
        require(tokenBorrow == WETH, "token borrow != WETH");

        // Calcula a taxa do empréstimo
        // fee / (amount + fee) = 3/1000
        // Arredondando para cima
        uint fee = (amount1 * 3) / 997 + 1;
        uint amountToRepay = amount1 + fee;

        // Devolve o empréstimo-relâmpago
        weth.transfer(address(pair), amountToRepay);
    }
}
```

Contrato de teste do Foundry `UniswapV2Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV2Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV2Flashloan();
    }

    function testFlashloan() public {
        // Depositar WETH no contrato e fornecer como taxa
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 1e18);
        // Montante do empréstimo-relâmpago
        uint amountToBorrow = 100 * 1e18;
        flashloan.flashloan(amountToBorrow);
    }

    // Se a taxa não for suficiente, o teste falhará
    function testFlashloanFail() public {
        // Depositar WETH no contrato e fornecer como taxa
        weth.deposit{value: 1e18}();
        weth.transfer(address(flashloan), 3e17);
        // Montante do empréstimo-relâmpago
        uint amountToBorrow = 100 * 1e18;
        // Taxa insuficiente
        vm.expectRevert();
        flashloan.flashloan(amountToBorrow);
    }
}
```

No contrato de teste, testamos cenários em que a taxa é suficiente e insuficiente. Você pode executar os testes com o Foundry utilizando o seguinte comando (pode trocar o RPC por outro fornecido pela Ethereum):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV2Flashloan.t.sol -vv
```

### 2. Empréstimo-Relâmpago Uniswap V3

Ao contrário do Uniswap V2, o Uniswap V3 possui as funções `flash()` no contrato de [Pool](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L791C1-L835C1), que oferecem suporte direto a empréstimos-relâmpago. O trecho relevante do código é o seguinte:

```solidity
function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
) external override lock noDelegateCall {
    // Outras lógicas...

    // Transferência otimista dos tokens para o endereço 'to'
    if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
    if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

    // Chamada da função de retorno 'uniswapV3FlashCallback'
    IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

    // Verificação se o empréstimo-relâmpago foi devolvido com sucesso
    uint256 balance0After = balance0();
    uint256 balance1After = balance1();
    require(balance0Before.add(fee0) <= balance0After, 'F0');
    require(balance1Before.add(fee1) <= balance1After, 'F1');

    // Outras lógicas...
}
```

Em seguida, completamos o contrato de empréstimo relâmpago `UniswapV3Flashloan.sol`. Fazemos com que ele herde `IUniswapV3FlashCallback` e escrevemos a lógica principal do empréstimo relâmpago na função de retorno de chamada `uniswapV3FlashCallback`.

A lógica geral é semelhante à da V2. Na função de empréstimo relâmpago `flashloan()`, pegamos emprestado `WETH` do pool `WETH-DAI` do Uniswap V3. Após o empréstimo relâmpago ser acionado, a função de retorno de chamada `uniswapV3FlashCallback` será chamada pelo contrato Pool. Não realizamos arbitragem e apenas devolvemos o empréstimo relâmpago após calcular os juros. A taxa de manuseio para cada empréstimo relâmpago no Uniswap V3 é consistente com a taxa de transação.

**Nota**: A função de retorno de chamada deve ter controle de permissão para garantir que apenas o contrato Pair da Uniswap possa ser chamado. Caso contrário, todos os fundos no contrato serão roubados por hackers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

// Interface de retorno de chamada do empréstimo relâmpago do UniswapV3
// Precisa ser implementado e reescrever a função uniswapV3FlashCallback()
interface IUniswapV3FlashCallback {
     /// Na implementação, você deve reembolsar o pool pelos tokens enviados pelo flash e o valor da taxa calculada.
     /// O contrato que chama este método deve ser verificado pelo UniswapV3Pool implantado pela UniswapV3Factory oficial.
     /// @param fee0 O valor da taxa do token0 que deve ser pago ao pool quando o empréstimo relâmpago terminar
     /// @param fee1 O valor da taxa do token1 que deve ser pago ao pool quando o empréstimo relâmpago terminar
     /// @param data Quaisquer dados passados pelo chamador são chamados via IUniswapV3PoolActions#flash
     function uniswapV3FlashCallback(
         uint256 fee0,
         uint256 fee1,
         bytes calldata data
     ) external;
}

// Contrato de empréstimo relâmpago do UniswapV3
contract UniswapV3Flashloan is IUniswapV3FlashCallback {
    address private constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 private constant poolFee = 3000;

    IERC20 private constant weth = IERC20(WETH);
    IUniswapV3Pool private immutable pool;

    constructor() {
        pool = IUniswapV3Pool(getPool(DAI, WETH, poolFee));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public pure returns (address) {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(UNISWAP_V3_FACTORY, poolKey);
    }

// Função de empréstimo relâmpago
     function flashloan(uint wethAmount) external {
         bytes memory data = abi.encode(WETH, wethAmount);
         IUniswapV3Pool(pool).flash(address(this), 0, wethAmount, data);
     }

     // A função de retorno de chamada do empréstimo relâmpago só pode ser chamada pelo contrato DAI/WETH
     function uniswapV3FlashCallback(
         uint fee0,
         uint fee1,
         bytes calldata data
     ) external {
         // Confirmar que a chamada é do contrato DAI/WETH
         require(msg.sender == address(pool), "not authorized");
        
         //Decodificar calldata
        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        // lógica do empréstimo relâmpago, omitida aqui
        require(tokenBorrow == WETH, "token borrow != WETH");

        //Reembolsar o empréstimo relâmpago
        weth.transfer(address(pool), wethAmount + fee1);
    }
}
```

Contrato de teste do Foundry `UniswapV3Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/UniswapV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    UniswapV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new UniswapV3Flashloan();
    }

function testFlashloan() public {
         //Trocar weth e transferir para o contrato flashloan para usá-lo como taxa de manuseio
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
                
         uint balBefore = weth.balanceOf(address(flashloan));
         console2.logUint(balBefore);
         // Valor do empréstimo relâmpago
         uint amountToBorrow = 1 * 1e18;
         flashloan.flashloan(amountToBorrow);
    }

// Se a taxa de manuseio for insuficiente, ela será revertida.
     function testFlashloanFail() public {
         //Trocar weth e transferir para o contrato flashloan para usá-lo como taxa de manuseio
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e17);
         // Valor do empréstimo relâmpago
         uint amountToBorrow = 100 * 1e18;
         // Taxa de manuseio insuficiente
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
```

No contrato de teste, testamos os casos de taxas de manuseio suficientes e insuficientes, respectivamente. Você pode usar a linha de comando a seguir para testar depois de instalar o Foundry (você pode alterar o RPC para outro RPC Ethereum):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/UniswapV3Flashloan.t.sol -vv
```

### 3. Empréstimo Relâmpago AAVE V3

AAVE é uma plataforma de empréstimo descentralizada. Seu contrato [Pool](https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/Pool.sol#L424) passa as funções `flashLoan()` e `flashLoanSimple()` que suportam empréstimos relâmpago de um único ativo e de vários ativos. Aqui, usamos apenas `flashLoan()` para implementar o empréstimo relâmpago de um único ativo (`WETH`).

Em seguida, completamos o contrato de empréstimo relâmpago `AaveV3Flashloan.sol`. Fazemos com que ele herde `IFlashLoanSimpleReceiver` e escrevemos a lógica principal do empréstimo relâmpago na função de retorno de chamada `executeOperation`.

A lógica geral é semelhante à da V2. Na função de empréstimo relâmpago `flashloan()`, pegamos emprestado `WETH` do pool `WETH` do AAVE V3. Após o empréstimo relâmpago ser acionado, a função de retorno de chamada `executeOperation` será chamada pelo contrato Pool. Não realizamos arbitragem e apenas devolvemos o empréstimo relâmpago após calcular os juros. A taxa de empréstimo relâmpago do AAVE V3 é de `0,05%` por transação, o que é menor do que a do Uniswap.

**Nota**: A função de retorno de chamada deve ter controle de permissão para garantir que apenas o contrato Pool da AAVE possa ser chamado e o iniciador seja este contrato, caso contrário, os fundos no contrato serão roubados por hackers.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Lib.sol";

interface IFlashLoanSimpleReceiver {
     /**
     * @notice executa operações após receber ativos de empréstimo relâmpago
     * @dev garante que o contrato possa pagar a dívida + taxas adicionais, por exemplo, com
     * Fundos suficientes para pagar e o Pool foi aprovado para sacar o valor total
     * @param asset O endereço do ativo de empréstimo relâmpago
     * @param amount A quantidade de ativos de empréstimo relâmpago
     * @param premium A taxa para empréstimo relâmpago de ativos
     * @param initiator O endereço onde os empréstimos relâmpago são iniciados
     * @param params codificação de bytes dos parâmetros passados durante a inicialização do empréstimo relâmpago
     * @return Verdadeiro se a operação for executada com sucesso, Falso caso contrário
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// Contrato de empréstimo relâmpago AAVE V3
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

// Função de empréstimo relâmpago
     function flashloan(uint256 wethAmount) external {
         aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
     }

     // A função de retorno de chamada do empréstimo relâmpago só pode ser chamada pelo contrato pool
     function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {   
// Confirmar que a chamada é do contrato DAI/WETH
         require(msg.sender == AAVE_V3_POOL, "not authorized");
         // Confirmar que o iniciador do empréstimo relâmpago é este contrato
         require(initiator == address(this), "invalid initiator");

         // lógica do empréstimo relâmpago, omitida aqui

         // Calcular as taxas do empréstimo relâmpago
         // taxa = 5/1000 * quantidade
         uint fee = (amount * 5) / 10000 + 1;
         uint amountToRepay = amount + fee;

         //Reembolsar o empréstimo relâmpago
         IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

         return true;
    }
}
```

Contrato de teste do Foundry `AaveV3Flashloan.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AaveV3Flashloan.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract UniswapV2FlashloanTest is Test {
    IWETH private weth = IWETH(WETH);

    AaveV3Flashloan private flashloan;

    function setUp() public {
        flashloan = new AaveV3Flashloan();
    }

function testFlashloan() public {
         //Trocar weth e transferir para o contrato flashloan para usá-lo como taxa de manuseio
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 1e18);
         // Valor do empréstimo relâmpago
         uint amountToBorrow = 100 * 1e18;
         flashloan.flashloan(amountToBorrow);
     }

     // Se a taxa de manuseio for insuficiente, ela será revertida.
     function testFlashloanFail() public {
         //Trocar weth e transferir para o contrato flashloan para usá-lo como taxa de manuseio
         weth.deposit{value: 1e18}();
         weth.transfer(address(flashloan), 4e16);
         // Valor do empréstimo relâmpago
         uint amountToBorrow = 100 * 1e18;
         // Taxa de manuseio insuficiente
         vm.expectRevert();
         flashloan.flashloan(amountToBorrow);
     }
}
```

No contrato de teste, testamos os casos de taxas de manuseio suficientes e insuficientes, respectivamente. Você pode usar a linha de comando a seguir para testar depois de instalar o Foundry (você pode alterar o RPC para outro RPC Ethereum):

```shell
FORK_URL=https://singapore.rpc.blxrbdn.com
forge test  --fork-url $FORK_URL --match-path test/AaveV3Flashloan.t.sol -vv
```

## Resumo

Nesta aula, apresentamos empréstimos relâmpago, que permitem que os usuários emprestem e retornem rapidamente fundos em uma única transação sem fornecer qualquer garantia. Além disso, implementamos os contratos de empréstimo relâmpago da Uniswap V2, Uniswap V3 e AAVE, respectivamente.

Através dos empréstimos relâmpago, podemos alavancar grandes quantidades de fundos sem garantia para arbitragem sem risco ou ataques de vulnerabilidade. O que você vai fazer com os empréstimos relâmpago?

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->