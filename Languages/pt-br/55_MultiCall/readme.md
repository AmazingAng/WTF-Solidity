---
title: 55. Chamada Múltipla
tags:
  - solidity
  - erc20
---

# WTF Solidity Simplificado: 55. Chamada Múltipla

Recentemente, tenho estudado solidity novamente para revisar os detalhes e escrever um guia simplificado de "WTF Solidity" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão publicadas de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, vamos falar sobre o contrato MultiCall, que tem como objetivo executar várias chamadas de função em uma única transação, reduzindo significativamente as taxas e aumentando a eficiência.

## MultiCall

Em Solidity, o contrato MultiCall permite que executemos várias chamadas de função em uma única transação. Suas vantagens são as seguintes:

1. Conveniência: Com o MultiCall, você pode chamar diferentes funções de diferentes contratos em uma única transação, usando diferentes parâmetros para cada chamada. Por exemplo, você pode consultar o saldo de várias contas de tokens ERC20 de uma só vez.

2. Economia de gás: O MultiCall permite combinar várias transações em uma única transação com várias chamadas, economizando gás.

3. Atomicidade: O MultiCall permite que o usuário execute todas as operações em uma única transação, garantindo que todas as operações sejam bem-sucedidas ou todas falhem, mantendo a atomicidade. Por exemplo, você pode realizar uma série de transações de tokens em uma ordem específica.

## Contrato MultiCall

Agora vamos estudar o contrato MultiCall, que é uma versão simplificada do contrato MultiCall da MakerDAO [MultiCall](https://github.com/mds1/multicall/blob/main/src/Multicall3.sol).

O contrato MultiCall define duas estruturas:

- `Call`: Esta é uma estrutura de chamada que contém o contrato de destino a ser chamado `target`, uma flag indicando se a chamada pode falhar `allowFailure` e os dados da chamada `callData`.

- `Result`: Esta é uma estrutura de resultado que contém uma flag indicando se a chamada foi bem-sucedida `success` e os dados de retorno da chamada `returnData`.

O contrato contém apenas uma função para executar chamadas múltiplas:

- `multicall()`: Esta função recebe um array de estruturas Call como parâmetro, garantindo que o tamanho dos targets e callData sejam iguais. A função executa as chamadas em um loop e reverte a transação se alguma chamada falhar.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Estrutura Call, contendo o contrato de destino target, a flag allowFailure e os dados da chamada callData
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Estrutura Result, contendo a flag success e os dados de retorno da chamada returnData
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Combina várias chamadas (com diferentes contratos/métodos/parâmetros) em uma única chamada
    /// @param calls Array de estruturas Call
    /// @return returnData Array de estruturas Result
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;
        
        // Executa as chamadas em um loop
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // Se tanto calli.allowFailure quanto result.success forem falsos, reverte a transação
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}
```

## Reproduzindo no Remix

1. Primeiro, implantamos um contrato ERC20 muito simples chamado `MCERC20` e anotamos o endereço do contrato.

    ```solidity
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.19;
    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MCERC20 is ERC20{
        constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

        function mint(address to, uint amount) external {
            _mint(to, amount);
        }
    }
    ```

2. Implantamos o contrato `MultiCall`.

3. Obtemos os `calldata` para as chamadas. Vamos criar 50 e 100 unidades de tokens para dois endereços. Você pode preencher os parâmetros da função `mint()` na página de chamadas do Remix e clicar no botão **Calldata** para copiar o calldata codificado. Exemplo:

    ```solidity
    to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    amount: 50
    calldata: 0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032
    ```

    .[](./img/55-1.png)

    Se você não está familiarizado com `calldata`, pode ler a lição 29 do WTF Solidity.

4. Usamos a função `multicall()` do contrato `MultiCall` para chamar a função `mint()` do contrato ERC20 e criar 50 e 100 unidades de tokens para dois endereços. Exemplo:

    ```solidity
    calls: [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x40c10f190000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000000000000000032"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x40c10f19000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb20000000000000000000000000000000000000000000000000000000000000064"]]
    ```

5. Usamos a função `multicall()` do contrato `MultiCall` para chamar a função `balanceOf()` do contrato ERC20 e verificar o saldo dos dois endereços que criamos tokens anteriormente. O seletor da função `balanceOf()` é `0x70a08231`. Exemplo:

    ```solidity
    [["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", true, "0x70a082310000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4"], ["0x0fC5025C764cE34df352757e82f7B5c4Df39A836", false, "0x70a08231000000000000000000000000ab8483f64d9c6d1ecf9b849ae677dd3315835cb2"]]
    ```

    Você pode verificar os valores de retorno das chamadas na seção `decoded output`. Os saldos dos dois endereços são `0x000000000000000000000000000000000000000

