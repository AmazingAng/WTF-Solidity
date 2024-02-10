# 27. Codificação e Decodificação ABI

## ABI Encoding

ABI (Application Binary Interface) é o padrão para interação de contratos inteligentes na Ethereum. Os dados são codificados com base em seus tipos e, devido ao fato de que a codificação não contém informações sobre os tipos, é necessário especificar os tipos ao decodificar.

Em Solidity, existem 4 funções de codificação ABI: `abi.encode`, `abi.encodePacked`, `abi.encodeWithSignature`, `abi.encodeWithSelector`. E há 1 função de decodificação ABI: `abi.decode`, que é usada para decodificar dados codificados com `abi.encode`.

Vamos ver como usar essas funções com um exemplo de codificação de quatro variáveis de tipos diferentes: `uint256` (alias `uint`), `address`, `string`, `uint256[2]`:

```solidity
uint x = 10;
address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
string name = "0xAA";
uint[2] array = [5, 6];
```

### `abi.encode`

A função `abi.encode` codifica os parâmetros fornecidos de acordo com as [regras da ABI](https://learnblockchain.cn/docs/solidity/abi-spec.html). A ABI foi projetada para interagir com contratos inteligentes, preenchendo cada parâmetro com dados de 32 bytes e concatenando-os juntos.

```solidity
function encode() public view returns(bytes memory result) {
    result = abi.encode(x, addr, name, array);
}
```

O resultado da codificação será `0x...`, que consiste em muitos `0` devido ao fato de que `abi.encode` preenche cada dado com 32 bytes.

### `abi.encodePacked`

A função `abi.encodePacked` codifica os parâmetros com o espaço de armazenamento mínimo necessário. Ela é semelhante à `abi.encode`, mas omitirá muitos dos `0` de preenchimento. Por exemplo, um `uint8` pode ser codificado em apenas 1 byte. Essa função é útil quando se quer economizar espaço e não se está interagindo com um contrato específico.

```solidity
function encodePacked() public view returns(bytes memory result) {
    result = abi.encodePacked(x, addr, name, array);
}
```

O resultado da codificação será `0x...`, que é muito mais curto que o resultado de `abi.encode`.

### `abi.encodeWithSignature`

A função `abi.encodeWithSignature` é semelhante à `abi.encode`, mas o primeiro parâmetro é a `assinatura da função`, como `"foo(uint256,address,string,uint256[2])"`. É útil ao chamar funções de outros contratos.

```solidity
function encodeWithSignature() public view returns(bytes memory result) {
    result = abi.encodeWithSignature("foo(uint256,address,string,uint256[2])", x, addr, name, array);
}
```

O resultado da codificação será `0x...`, semelhante à `abi.encode`, mas com 4 bytes adicionais no início que são o `seletor da função`.

### `abi.encodeWithSelector`

A função `abi.encodeWithSelector` é semelhante à `abi.encodeWithSignature`, mas o primeiro parâmetro é o `seletor da função`, que é os primeiros 4 bytes do hash Keccak da `assinatura da função`.

```solidity
function encodeWithSelector() public view returns(bytes memory result) {
    result = abi.encodeWithSelector(bytes4(keccak256("foo(uint256,address,string,uint256[2])")), x, addr, name, array);
}
```

O resultado da codificação será `0x...`, semelhante ao `abi.encodeWithSignature`.

## ABI Decoding

### `abi.decode`

A função `abi.decode` é usada para decodificar dados previamente codificados com `abi.encode`, restaurando os parâmetros originais.

```solidity
function decode(bytes memory data) public pure returns(uint dx, address daddr, string memory dname, uint[2] memory darray) {
    (dx, daddr, dname, darray) = abi.decode(data, (uint, address, string, uint[2]));
}
```

Dê uma olhada na imagem acima para ver como os dados codificados podem ser decodificados de volta para seus valores originais.

Isso resume como utilizar a codificação e decodificação ABI em Ethereum.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->