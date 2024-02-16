---
title: 17. Contrato de Biblioteca
tags:
  - solidity
  - avançado
  - wtfacademy
  - biblioteca
  - usando para
---

# WTF Introdução Simples ao Solidity: 17. Contrato de Biblioteca - Ficando nos ombros de gigantes

Recentemente, tenho estudado Solidity novamente para consolidar alguns detalhes e escrever um "WTF Introdução Simples ao Solidity" para iniciantes (programadores experientes podem procurar outros tutoriais). Serão lançadas de 1 a 3 aulas por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk)｜[Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
Nesta aula, vamos usar o contrato de biblioteca `String` referenciado pelo `ERC721` para explicar os contratos de biblioteca (`Library`) no Solidity e resumir as bibliotecas mais comumente usadas.

## Contratos de Biblioteca

Contratos de biblioteca são um tipo especial de contrato que existe para aumentar a reutilização de código no Solidity e reduzir o consumo de gás. Contratos de biblioteca são uma coleção de funções criadas por especialistas ou pelos desenvolvedores de um projeto. Nós apenas precisamos ficar nos ombros de gigantes e saber como usá-los.

![Contratos de Biblioteca: Ficando nos ombros de gigantes](https://images.mirror-media.xyz/publication-images/HJC0UjkALdrL8a2BmAE2J.jpeg?height=300&width=388)

Eles têm algumas diferenças em relação aos contratos normais:

1. Não podem ter variáveis de estado
2. Não podem ser herdados nem herdar outros contratos
3. Não podem receber Ether
4. Não podem ser destruídos

## Contrato de Biblioteca String

O contrato de biblioteca `String` é uma biblioteca de código que converte um tipo `uint256` em seu equivalente em `string`. O código de exemplo é o seguinte:

```solidity
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
```

Ele contém principalmente duas funções: `toString()`, que converte `uint256` em `string`, e `toHexString()`, que converte `uint256` em sua representação hexadecimal em `string`.

### Como usar contratos de biblioteca

Vamos usar a função `toHexString()` do contrato de biblioteca `String` para demonstrar duas maneiras de usar as funções de um contrato de biblioteca.

1. Usando a instrução `using for`

    A instrução `using A for B;` pode ser usada para anexar uma biblioteca (A) a qualquer tipo (B). Após adicionar a instrução, as funções da biblioteca A serão automaticamente adicionadas como membros da variável do tipo B e podem ser chamadas diretamente. Observe que, ao chamar a função, essa variável será passada como o primeiro parâmetro:

    ```solidity
    // Usando a instrução using for
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // As funções do contrato de biblioteca serão automaticamente adicionadas como membros da variável uint256
        return _number.toHexString();
    }
    ```

2. Chamando a função pelo nome da biblioteca

    ```solidity
    // Chamando a função diretamente pelo nome da biblioteca
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
    ```

Vamos implantar o contrato e testar com o valor `170`, ambas as formas retornarão a string hexadecimal correta "0xaa". Isso prova que chamamos com sucesso o contrato de biblioteca!

![Chamando o contrato de biblioteca com sucesso](https://images.mirror-media.xyz/publication-images/bzB_JDC9f5VWHRjsjQyQa.png?height=750&width=580)

## Conclusão

Nesta aula, usamos o contrato de biblioteca `String`, referenciado pelo `ERC721`, para explicar os contratos de biblioteca (`Library`) no Solidity. 99% dos desenvolvedores não precisam escrever seus próprios contratos de biblioteca, apenas precisam saber quando usar um contrato de biblioteca escrito por especialistas. Alguns dos mais comumente usados são:

1. [String](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Strings.sol): converte `uint256` em `String`
2. [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Address.sol): verifica se um endereço é um contrato
3. [Create2](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Create2.sol): uso mais seguro da opcode `Create2` do EVM
4. [Arrays](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Arrays.sol): biblioteca relacionada a arrays.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->