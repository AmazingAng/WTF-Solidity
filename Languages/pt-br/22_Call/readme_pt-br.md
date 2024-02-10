# 22. Chamada

Eu recentemente tenho revisado meus conhecimentos em Solidity para reforçar os detalhes, e estou escrevendo um "Guia WTF de Introdução Simples ao Solidity" para iniciantes (programadores experientes podem buscar outros tutoriais), com atualizações semanais de 1 a 3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo código e tutorial estão disponíveis no github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nós já introduzimos o uso do `call` para enviar `ETH` na [Liçăo 20: Enviando ETH](https://github.com/AmazingAng/WTFSolidity/tree/main/20_SendETH). Nesta lição, vamos explorar como utilizar o `call` para chamar funções de contratos.

## Call

O `call` é uma função de membro de tipo `address` que permite a interação com outros contratos. Seu retorno é do tipo `(bool, bytes memory)`, indicando respectivamente se a chamada foi bem-sucedida e o valor de retorno da função alvo.

- O `call` é recomendado oficialmente pela Solidity para enviar `ETH` ativando funções `fallback` ou `receive`.
- Não é recomendado usar o `call` para chamar funções de outros contratos, pois ao fazer isso, você está dando controle ao contrato alvo. A maneira recomendada é declarar a variável do contrato e chamar a função, conforme visto na [Liçăo 21: Chamar Contrato](https://github.com/AmazingAng/WTFSolidity/tree/main/21_CallContract).
- Quando não temos o código fonte ou o `ABI` do contrato alvo, não podemos criar a variável do contrato; nesse caso, ainda podemos chamar a função do contrato alvo utilizando o `call`.

### Regras de uso do `call`

As regras de uso do `call` são as seguintes:

```text
enderecoContratoAlvo.call(bytecode);
```

O `bytecode` é obtido usando a função de codificação estruturada `abi.encodeWithSignature`:

```text
abi.encodeWithSignature("nomeDaFuncao(tipoParametro)", parametrosSeparadosPorVírgula)
```

O "nomeDaFuncao(tipoParametro)" é a "assinatura da função" como por exemplo `abi.encodeWithSignature("f(uint256,address)", _x, _addr)`.

Além disso, ao chamar o contrato utilizando o `call`, é possível especificar a quantidade de `ETH` e de `gas` a enviar na transação:

```text
enderecoContratoAlvo.call{value:valor, gas:quantidadeGas}(bytecode);
```

Parece um pouco complexo, então vamos ver um exemplo de aplicação do `call`.

### Contrato Alvo

Primeiramente, vamos escrever um contrato simples chamado `OtherContract` e implantá-lo. O código é praticamente o mesmo da lição 21, com a adição de uma função `fallback`.

```solidity
contract OtherContract {
    uint256 private _x = 0; // variável de estado x
    // evento para quando recebe ETH, registra o valor e o gas
    event Log(uint amount, uint gas);
    
    fallback() external payable{}

    // retorna o saldo de ETH do contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // função ajusta o valor da variável de estado _x e pode enviar ETH para o contrato (pagável)
    function setX(uint256 x) external payable{
        _x = x;
        // se enviar ETH, dispara o evento Log
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // lê o valor de x
    function getX() external view returns(uint x){
        x = _x;
    }
}
```

Este contrato possui uma variável de estado `x`, um evento `Log` que é acionado ao receber `ETH`, e três funções:

- `getBalance()`: retorna o saldo de ETH do contrato.
- `setX()`: função `external payable` que permite ajustar o valor de `x` e enviar `ETH` para o contrato.
- `getX()`: retorna o valor de `x`.

### Chamando o contrato alvo

#### 1. Evento de Resposta

Vamos criar uma função `Response` para chamar as funções do contrato alvo. Primeiro, definimos um evento `Response` que exibe o `success` e `data` da chamada, permitindo-nos verificar os resultados.

```solidity
// Definir evento Response para exibir o sucesso e os dados da chamada
event Response(bool success, bytes data);
```

#### 2. Chamando a função setX

Definimos a função `callSetX` para chamar a função `setX()` do contrato alvo, enviando a quantidade de `ETH` recebida e emitindo o evento `Response` para exibir o `success` e `data`.

```solidity
function callSetX(address payable _addr, uint256 x) public payable {
    // Chamando setX() e enviando ETH
    (bool success, bytes memory data) = _addr.call{value: msg.value}(
        abi.encodeWithSignature("setX(uint256)", x)
    );

    emit Response(success, data); // Emite o evento
}
```

Em seguida, chamamos o `callSetX` para definir a variável `_x` como 5, passando o endereço do contrato `OtherContract` e o valor `5`. Como a função alvo `setX()` não possui valor de retorno, o `data` retornado no evento `Response` será `0x`, o que representa um valor vazio.

#### 3. Chamando a função getX

Agora, vamos chamar a função `getX()`, que retornará o valor da variável `_x` do contrato alvo. Utilizamos o `abi.decode` para decodificar o `data` retornado pelo `call` e obter o valor numérico.

```solidity
function callGetX(address _addr) external returns(uint256){
    // Chamando getX()
    (bool success, bytes memory data) = _addr.call(
        abi.encodeWithSignature("getX()")
    );

    emit Response(success, data); // Emite o evento
    return abi.decode(data, (uint256));
}
```

O valor de retorno do `getX()` é mostrado no evento `Response`, sendo representado em hexadecimal (`0x0000000000000000000000000000000000000000000000000000000000000005`). Depois de decodificar esse valor, obtemos o número `5`.

#### 4. Chamando uma função inexistente

Se chamarmos uma função que não existe no contrato alvo, o `fallback` do contrato será acionado.

```solidity
function callNonExist(address _addr) external{
    // Chamando uma função inexistente
    (bool success, bytes memory data) = _addr.call(
        abi.encodeWithSignature("foo(uint256)")
    );

    emit Response(success, data); // Emite o evento
}
```

Neste exemplo, chamamos a função inexistente `foo`. O `call` ainda é bem-sucedido e retorna `success`, no entanto, na verdade, está chamando a função de `fallback` do contrato alvo.

## Conclusão

Nesta lição, aprendemos como usar o `call`, uma função de baixo nível, para chamar funções de outros contratos. Embora não seja a maneira recomendada de chamar contratos devido aos riscos de segurança, o `call` é útil quando não temos o código fonte ou o `ABI` do contrato alvo.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->