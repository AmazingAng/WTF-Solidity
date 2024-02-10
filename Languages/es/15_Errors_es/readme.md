---
Título: 15. Errores
tags:
  - solidity
  - advanced
  - wtfacademy
  - error
  - revert/assert/require
---

# Tutorial WTF Solidity: 15. Errores

Recientemente, he estado revisando Solidity y escribiendo tutoriales en "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Sitio web wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Jonathan Díaz con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@jonthdiaz](https://twitter.com/jonthdiaz)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

En este capítulo, se introducirá tres formas de lanzar excepciones en solidity: `error`, `require` y `assert`.

## Errores
Solidity tiene muchas funciones para el manejo de errores. Los errores pueden ocurrir en tiempo de compilación o en tiempo de ejecución.

### Error
La declaración `error` es una característica nueva en solidity `0.8`. Ahorra gas e informa a los usuarios por qué la operación falló. Es la manera recomendada de lanzar un error en Solidity.
Los errores personalizados se definen utilizando la declaración de error, que se puede usar dentro y fuera de los contratos. A continuación, creamos un error `TransferNotOwner`, que lanzará un error cuando el usuario que realice la transacción no sea el `propietario` del token.

```solidity
error TransferNotOwner(); // error personalizado
```

En funciones, `error` debe usarse junto con la declaración `revert`.

```solidity
function transferOwner1(uint256 tokenId, address newOwner) public {
    if(_owners[tokenId] != msg.sender){
        revert TransferNotOwner();
    }
    _owners[tokenId] = newOwner;
}
```
La función `transferOwner1()` verificará si el usuario que ejecuta la transacción es el propietario del token; si no lo es, lanzará un error `TransferNotOwner` y revertirá la transacción.

### Requerir
La declaración `require` era el método más comúnmente utilizado para el manejo de errores antes de la versión solidity `0.8`. Todavía es bastante popular entre los desarrolladores.

Sintaxis de `require`: 
```
require(condition, "mensaje de error");
```

Se lanzará una excepción cuando la condición no se cumpla.

A pesar de su simplicidad, el consumo de gas es mayor que en la declaración `error`: el consumo de gas crece linealmente a medida que aumenta la longitud del mensaje de error.

Ahora, se reescribirá la función `transferOwner` anterior con la declaración `require`:
```solidity
function transferOwner2(uint256 tokenId, address newOwner) public {
    require(_owners[tokenId] == msg.sender, "Usuario no es el propietario del token");
    _owners[tokenId] = newOwner;
}
```

### Afirmar
La declaración `assert` generalmente se usa para propósitos de depuración, porque no incluye un mensaje de error para informar al usuario.

Sintaxis de `assert`: 
```solidity
`assert(condition);
```
Si la condición no se cumple, se lanzará un error

Se reescribe la función `transferOwner` con la declaración `assert`:
```solidity
    function transferOwner3(uint256 tokenId, address newOwner) public {
        assert(_owners[tokenId] == msg.sender);
        _owners[tokenId] = newOwner;
    }
```

## Demo en Remix
Después de desplegar el contrato `Error`.

1. `error`: Ingrese un número `uint256` y una dirección no cero, y llame a la función `transferOwner1()`. La consola lanzará un error personalizado `TransferNotOwner`.

    ![15-1.png](./img/15-1.png)
   
2. `require`: Ingrese un número `uint256` y una dirección no cero, y llame la función `transferOwner2()`. La consola lanzará un error y mostrará el mensaje de error `"El usuario no es el propietario del token"`.

    ![15-2.png](./img/15-2.png)
   
3. `assert`: Ingrese un número `uint256` y una dirección no cero, y llame a la función `transferOwner3()`. La consola lanzará un error sin ningún mensaje de error.

    ![15-3.png](./img/15-3.png)
   

## Comparación de gas
Se comparara el consumo de gas de `error`, `require` y `assert`.
Puede encontrar el consumo de gas para cada llamada a la función con el botón Debug de la consola en remix: 

1. **gas para `error`**：24457 `wei`
2. **gas para `require`**：24755 `wei`
3. **gas para `assert`**：24473 `wei`

Se puede ver que `error` consume menos gas, seguido por `assert`, mientras que `require` consume más gas.
Por lo tanto, `error` no solo informa al usuario sobre el mensaje del error, sino que también ahorra gas.

## Resumen
En este capítulo, introdujimos 3 declaraciones para manejar errores en Solidity: `error`, `require` y `assert`. Después de comparar su consumo de gas, la declaración `error` es la más barata, mientras que `require` tiene el consumo de gas más alto. 
