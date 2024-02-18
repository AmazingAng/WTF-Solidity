# WTF Introdução Simples à Solidity: 29. Seletor de Funções

Recentemente, tenho revisado meus conhecimentos em Solidity para consolidar alguns detalhes e estou escrevendo uma série chamada "WTF Introdução Simples à Solidity" para ajudar iniciantes (os programadores experientes podem procurar outros tutoriais). Atualizo o conteúdo semanalmente com 1-3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

## Seletor de Funções

Quando chamamos um contrato inteligente, essencialmente estamos enviando um conjunto de `calldata` para o contrato de destino. Após enviar uma transação no remix, podemos ver os dados `input` na aba de detalhes, que corresponde à `calldata` da transação.

![tx input in remix](./img/29-1.png)

Os primeiros 4 bytes dos dados `calldata` são o `seletor` da função. Nesta lição, vamos explicar o que é um `seletor` e como utilizá-lo.

### msg.data

`msg.data` é uma variável global em Solidity que contém toda a `calldata` enviada ao chamar uma função.

No código a seguir, podemos utilizar o evento `Log` para imprimir a `calldata` da chamada da função `mint`:

```solidity
// evento para retornar msg.data
event Log(bytes data);

function mint(address to) external {
    emit Log(msg.data);
}
```

Quando o argumento é `0x2c44b726ADF1963cA47Af88B284C06f30380fC78`, a `calldata` de saída é:

```text
0x6a6278420000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

Esse bytecode confuso pode ser dividido em duas partes:

```text
Os primeiros 4 bytes são o seletor da função:
0x6a627842

Os 32 bytes subsequentes são os parâmetros de entrada:
0x0000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

Basicamente, a `calldata` informa ao contrato inteligente qual função deve ser chamada e quais são os parâmetros.

### id do método, seletor e assinatura da função

O `id do método` é definido como os 4 primeiros bytes do `hash Keccak` da `assinatura da função`. Quando o `seletor` corresponde ao `id do método`, significa que a função correspondente será chamada. Mas afinal, qual é a `assinatura da função`?

Na 21ª lição, brevemente explicamos que a `assinatura da função` é a `"nome da função (tipos de parâmetros separados por vírgulas)"`. Por exemplo, a `assinatura da função mint` no código acima é `"mint(address)"`. Em um mesmo contrato inteligente, diferentes funções têm assinaturas diferentes, o que nos permite determinar qual função deve ser chamada.

**Nota**: Na assinatura da função, `uint` e `int` devem ser escritos como `uint256` e `int256`.

Vamos escrever uma função para verificar se o `id do método` da função `mint` é realmente `0x6a627842`. Você pode executar a função abaixo para ver o resultado.

```solidity
function mintSelector() external pure returns(bytes4 mSelector) {
    return bytes4(keccak256("mint(address)"));
}
```

O resultado realmente é `0x6a627842`:

![method id in remix](./img/29-2.png)

### Utilizando o seletor

Podemos usar o `seletor` para chamar uma função específica. Por exemplo, se quisermos chamar a função `mint`, basta codificar o `id do método` da função `mint` como seletor, juntamente com os parâmetros, e passar isso para a função `call`:

```solidity
function callWithSignature() external returns(bool, bytes memory) {
    (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0x6a627842, 0x2c44b726ADF1963cA47Af88B284C06f30380fC78));
    return (success, data);
}
```

Nos logs, podemos ver que a função `mint` foi chamada com sucesso e o evento `Log` foi registrado.

![logs in remix](./img/29-3.png)

## Conclusão

Nesta lição, explicamos o que é um `seletor de função` (`selector`), como ele se relaciona com `msg.data` e a `assinatura da função`, e como utilizá-lo para chamar funções específicas.

