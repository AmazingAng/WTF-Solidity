---
Título: 29. Selector de Funciones
tags:
  - solidity
  - advanced
  - wtfacademy
  - selector
---
# Tutorial WTF Solidity: 29. Selector de Funciones

Recientemente, he estado revisando Solidity y escribiendo tutoriales en "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Sitio web wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Jonathan Díaz con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@jonthdiaz](https://twitter.com/jonthdiaz)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)
---

## `selector`

Cuando se llama a un contrato inteligente, esencialmente se envía un `calldata` al contrato de destino. Después de enviar una transacción en remix, se pueden ver en los detalles que `input` es el `calldata` de esta transacción.

![tx input in remix](./img/29-1.png)

Lo primero que se envía en el `calldata` son los primeros 4 bytes, llamados `selector`. En esta sección, se presentará qué es `selector` y cómo usarlo.

### `msg.data`

`msg.data` es una variable global en `solidity`. El valor de `msg.data` es el `calldata` completo (los datos pasados cuando se llama a la función).

En el siguiente código, se puede emitir el `calldata` que llama a la función `mint` a través del evento `Log`:
```solidity
    // event retorna msg.data
    event Log(bytes data);

    function mint(address to) external{
        emit Log(msg.data);
    }
```

Cuando el parámetro es `0x2c44b726ADF1963cA47Af88B284C06f30380fC78`, el `calldata` de salida es

```
0x6a6278420000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

Este bytecode desordenado se puede dividir en dos partes:

```
Los primeros 4 bytes son el selector:
0x6a627842

Los siguientes 32 bytes son los parámetros de entrada:
0x0000000000000000000000002c44b726adf1963ca47af88b284c06f30380fc78
```

En realidad, este `calldata` es para decirle al contrato inteligente qué función quiero llamar y cuáles son los parámetros.

### `method id`、`selector` y `Function Signatures`

El `method id` es definido como los primeros 4 bytes después del `hash Keccak` de la `firma de la función`. La función es llamada cuando el `selector` coincide con el `method id`.

Entonces, ¿cuál es la `firma de la función`? En la sección 21, se introdujo la firma de la función. La firma de la función es `"nombre_de_la_función(tipos_de_parámetros_separados_por_comas)"`. Por ejemplo, la firma de la función `mint` en el código anterior es `"mint(address)"`. En el mismo contrato inteligente, diferentes funciones tienen diferentes firmas de función, por lo que se puede determinar qué función llamar por la firma de la función.

Por favor note que `uint` y `int` se escriben como `uint256` y `int256` en la firma de la función.

Se definira una función para verificar que el `method id` de la función `mint` es `0x6a627842`. Se puede llamar a la función a continuación y ver el resultado.
```solidity
    function mintSelector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("mint(address)"));
    }
```

El resultado es `0x6a627842`:

![method id in remix](./img/29-2.png)

### Como usar `selector`

Se puede usar `selector` para llamar a la función de destino. Por ejemplo, si se quiere llamar a la función `mint`, solo se necesita usar `abi.encodeWithSelector` para empaquetar y codificar el `method id` de la función `mint` como el `selector` y los parámetros, y pasarlo a la función `call`:
```solidity
    function callWithSignature() external returns(bool, bytes memory){
        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0x6a627842, "0x2c44b726ADF1963cA47Af88B284C06f30380fC78"));
        return(success, data);
    }
```

Se puede ver en el log que la función `mint` fue llamada con éxito y el evento `Log` fue emitido.

![logs in remix](./img/29-3.png)

## Resumen
En esta sección, se presentó el `selector` y su relación con `msg.data`, `firma de la función`, y cómo usarlo para llamar a la función de destino.
