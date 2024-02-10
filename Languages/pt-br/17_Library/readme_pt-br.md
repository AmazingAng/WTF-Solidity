# 17. Contratos de Biblioteca

Eu tenho estado revisitando o Solidity ultimamente, consolidando os detalhes e escrevendo um "Guia WTF de Introdução ao Solidity" para iniciantes (programadores experientes podem procurar outras fontes), com até 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
Nesta lição, vamos utilizar o contrato de biblioteca `String`, que é referenciado por`ERC721`, para explicar os contratos de biblioteca (`Library`) em Solidity, e vamos resumir as bibliotecas comumente utilizadas.

## Contratos de Biblioteca

Um contrato de biblioteca é um tipo especial de contrato que existe para melhorar a reusabilidade do código em Solidity e reduzir o uso de gas. O contrato de biblioteca consiste em uma coleção de funções, criadas por especialistas ou pelos desenvolvedores de um projeto. Podemos usá-las sem necessidade de conhecer todos os detalhes internos.

![Contratos de Biblioteca: Em cima dos ombros de gigantes](https://images.mirror-media.xyz/publication-images/HJC0UjkALdrL8a2BmAE2J.jpeg?height=300&width=388)

Ele possui algumas diferenças em relação aos contratos regulares:

1. Não pode conter variáveis de estado
2. Não pode ser herdado e não pode herdar de outros contratos
3. Não pode receber Ether
4. Não pode ser destruído

## Biblioteca String

O contrato de biblioteca `String` converte um tipo `uint256` para sua representação `string` correspondente. Abaixo está o código de exemplo:

```solidity
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        // implementação omitida
        return string(buffer);
    }

    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        // implementação omitida
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        // implementação omitida
        return string(buffer);
    }
}
```

Este contrato de biblioteca contém duas funções principais: `toString()` que converte `uint256` em `string`, e `toHexString()` que converte `uint256` em hexadecimal e então em `string`.

### Como usar um contrato de Biblioteca

Vamos usar a função `toHexString()` da biblioteca `String` para demonstrar duas maneiras de usar as funções presentes em uma biblioteca.

1. Usando a instrução `using for`

    A instrução `using A for B;` é usada para anexar uma biblioteca (de biblioteca `A`) a qualquer tipo (B). Depois de adicionar a instrução, as funções do contrato de biblioteca `A` serão automaticamente adicionadas como membros da variável do tipo `B` e podem ser chamadas diretamente. Observe que ao chamar a função, a variável será tratada como o primeiro parâmetro da função:

    ```solidity
    // Usando a instrução using for
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        return _number.toHexString();
    }
    ```

2. Chamando a função diretamente pelo nome da biblioteca

    ```solidity
    // Chamando a função diretamente pelo nome da biblioteca
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
    ```

Vamos implantar o contrato e testar com o número `170`, ambos os métodos devem retornar a mesma `string` hexadecimal correta "0xaa". Isso prova que conseguimos chamar a biblioteca com sucesso!

![Chamada bem sucedida de um contrato de biblioteca](https://images.mirror-media.xyz/publication-images/bzB_JDC9f5VWHRjsjQyQa.png?height=750&width=580)

## Conclusão

Nesta lição, utilizamos o contrato de biblioteca `String` referenciado pelo `ERC721` como exemplo para explicar os contratos de biblioteca (`Library`) em Solidity. 99% dos desenvolvedores não precisam escrever seus próprios contratos de biblioteca, basta saber quando e como usar os contratos disponíveis. Alguns contratos de biblioteca comumente usados incluem:

1. [String](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Strings.sol): converter `uint256` em `String`
2. [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Address.sol): verificar se um endereço é um contrato
3. [Create2](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Create2.sol): uso mais seguro do opcode `Create2 EVM`
4. [Arrays](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Arrays.sol): biblioteca relacionada a arrays.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->