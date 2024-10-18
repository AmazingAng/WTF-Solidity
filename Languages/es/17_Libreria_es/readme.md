---
Título: 17. Biblioteca
tags:
  - solidity
  - advanced
  - wtfacademy
  - library
  - using for
---

# Tutorial WTF Solidity: 17. Biblioteca: Pararse sobre los hombros de los gigantes

Recientemente, he estado revisando Solidity y escribiendo tutoriales en "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Sitio web wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Jonathan Díaz con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@jonthdiaz](https://twitter.com/jonthdiaz)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

En este capítulo se usará el contrato de biblioteca `String` referenciado por `ERC721` como ejemplo para introducir el contrato de biblioteca en `solidity`,
y luego resumir las funciones de biblioteca comúnmente utilizadas.


## Funciones de biblioteca

Una librería es un contrato especial que existe para mejorar la reutilización en `solidity` y reducir el consumo de `gas`.
Los contratos de biblioteca son generalmente una colección de funciones útiles (`funciones de biblioteca`),
que son creadas por los grandes proyectos o personas que trabajan en ellos.
Solo se necesita pararse sobre los hombros de los gigantes y usar esas funciones.

![Biblioteca de contratos: Pararse sobre los hombros de los gigantes](https://images.mirror-media.xyz/publication-images/HJC0UjkALdrL8a2BmAE2J.jpeg?height=300&width=388)

Es diferente de los contratos ordinarios en los siguientes puntos:

1. Las variables de estado no están permitidas
2. No puede recibir ether
3. No puede heredar ni ser heredado
4. No puede ser destruido

## Contrato de biblioteca de cadenas

`String Library Contract` es una biblioteca de código que convierte un `uint256` al tipo `string` correspondiente. El código de ejemplo es el siguiente:

```solidity
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Convierte un `uint256` a su representación decimal ASCII `string`.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspirado en la implementación de OraclizeAPI - licencia MIT
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
     * @dev Convierte un `uint256` a su representación hexadecimal ASCII `string`.
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
     * @dev Convierte un `uint256` a su representación hexadecimal ASCII `string` con longitud fija.
     */
    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: insuficiente longitud hexadecimal");
        return string(buffer);
    }
}
```

Principalmente contiene dos funciones, `toString()` convierte `uint256` a `string`,
`toHexString()` convierte `uint256` a `hexadecimal`, y luego lo convierte a `string`.

### Cómo usar contratos de biblioteca
Se usa la función toHexString() en la función de biblioteca String para demostrar dos formas de usar las funciones en el contrato de biblioteca.

**1. Usar comando `for` **

El comando `using A for B` se puede usar para adjuntar funciones de biblioteca (de la biblioteca A) a cualquier tipo (B). Después de la instrucción,
la función en la biblioteca `A` se agregará automáticamente como miembro de la variable de tipo `B`, 
que se puede llamar directamente. Nota: Al llamar, esta variable se pasará a la función como el primer parámetro:

```solidity
    // Usando la biblioteca con el comando "using for" 
    using Strings for uint256;
    function getString1(uint256 _number) public pure returns(string memory){
        // Las funciones de la biblioteca se agregan automáticamente como miembros de las variables de tipo uint256
        return _number.toHexString();
    }
```

**2. Llamado directamente por el nombre del contrato de biblioteca**
```solidity
    // Llamado directamente por el nombre del contrato de biblioteca
    function getString2(uint256 _number) public pure returns(string memory){
        return Strings.toHexString(_number);
    }
```

Se despliega el contrato y se ingresa `170` para probar,
ambos métodos pueden devolver la cadena `hexadecimal` correcta "0xaa",
¡demostrando que llamamos a la función de la biblioteca con éxito!

![Llamando a la función de la biblioteca con éxito](https://images.mirror-media.xyz/publication-images/bzB_JDC9f5VWHRjsjQyQa.png?height=750&width=580)

## Resumen

En este capítulo, se ha introducido el contrato de biblioteca en `solidity` y resumido las funciones de biblioteca comúnmente utilizadas.
99% de los desarrolladores no necesitan escribir contratos de biblioteca ellos mismos, pueden usar los escritos por personas con más experiencia.
Lo único que se necesita saber es qué contrato de biblioteca usar y dónde es más adecuada usarlo.

Algunas bibliotecas comúnmente utilizadas son:
1. [String](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Strings.sol)：Convertir `uint256` a `String`
2. [Address](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Address.sol)：Determinar si auna dirección es una dirección de contrato.
3. [Create2](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Create2.sol)：Uso más seguro de  `Create2 EVM opcode`
4. [Arrays](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4a9cc8b4918ef3736229a5cc5a310bdc17bf759f/contracts/utils/Arrays.sol)：Funciones de biblioteca con arreglos.
