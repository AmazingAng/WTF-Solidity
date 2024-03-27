# Tutorial WTF Solidity: 1. HolaWeb3 (Solidity en 3 lineas)

Recientemente, he estado revisando Solidity y escribiendo tutoriales en "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Sitio web wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Jonathan Díaz con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@jonthdiaz](https://twitter.com/jonthdiaz)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

## WTF es Solidity?

`Solidity` es un lenguaje de programación utilizado para crear contratos inteligentes en la Ethereum Virtual Machine. Es una habilidad necesaria para trabajar en proyectos blockchain. Además, como muchos de ellos son de código abierto, entender el código puede ayudar a evitar proyectos que impliquen pérdida de dinero. 


`Solidity` tiene dos características:

1. Orientado a objetos: Después de aprenderlo, puedes usarlo para ganar dinero encontrando los proyectos adecuados. 
2. Avanzado: Si se escribe un contracto inteligente en Solidity, se es un ciudadano de primer clase de Ethereum.

## Herramienta de desarrollo: Remix

En este tutorial, se usara `Remix` para ejecutar contratos de `solidity`. `Remix` es un IDE (Entorno de desarrollo integrado) de desarrollo de contratos inteligentes recomendado oficialmente por Ethereum. Es adecuado para principiantes, ya que permite la implementación y pruebas rápidas de contratos inteligentes en el navegador, sin necesidad de instalar programas en la máquina local. 

Sitio Web: [remix.ethereum.org](https://remix.ethereum.org)

Al ingresar a `Remix`, Se puede ver que el menú en el lado izquierdo tiene tres botones, correspondientes a archivo (donde se escribe el texto), compilar (donde se ejecuta el código) y desplegar (donde se despliega en la blockchain). Al hacer clic en el botón "Crear Nuevo Archivo", se puede crear un contrato en blanco de `Solidity`.


Dentro de Remix, observamos que hay cuatro botones en el menú vertical a mano izquierda, correspondientes al EXPLORADOR DE ARCHIVOS (donde escribir el código), BUSCAR EN ARCHIVOS (para encontrar y reemplazar archivos), COMPILADOR DE SOLIDITY (para ejecutar código),  DESPLEGAR Y EJECUTAR TRANSACCIONES (para desplegar en la blockchain). Podemos crear un contrato de Solidity en blanco haciendo clic en el botón `Crear nuevo archivo`.


![Remix Menú](./img/1-1.png)

## El primer programa en Solidity

Este primer programa es sencillo, el programa solo contiene 1 linea con un comentario y 3 lineas de código.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract HolaWeb3{
    string public _string = "Hola Web3!";}
```

Ahora, vamos a desplegar y analizar el código fuente, comprendiendo su estructura básica: 

1. La primera linea es un comentario que indica el identificador de la licencia de software utilizada por el programa. Se esta utilizando la licencia MIT. Si no se indica  la licencia utilizada, el programa puede compilar con éxito, pero reportará una advertencia durante la compilación. Los comentarios en Solidity se denotan con "//", seguidos del contenido del comentario (el cual no sera ejecutado por el programa).

```solidity
// SPDX-License-Identifier: MIT
```

2. La segunda linea declara la versión de Solidity utilizada por el archivo fuente, ya que la sintaxis varia entre diferentes versiones. Esta línea de código significa que el archivo fuente no permitirá la compilación por compiladores con versiones inferiores a v0.8.21 y no superiores a v0.9.0 (la segunda condición se proporciona con `^`)

```solidity
pragma solidity ^0.8.21;
```
    
3. Las lineas 3 y 4 constituyen el cuerpo principal del contrato inteligente. La linea 3 crea un contrato con el nombre `HolaWeb3`. La linea 4 es el contenido del contrato. Aquí se ha creado una variable de cadena llamada `_string` y le asignamos el valor "Hola Web3!".

```solidity
contract HolaWeb3{
    string public _string = "Hola Web3!";}
```
Se introducirán los diferentes tipos de variable en Solidity luego.

## Compilar el código y desplegar

En el editor, presionar CTRL+S para compilar el código, o dar click en el botón de compilar.

Después de compilar, clic en el botón de `Deploy` en el menú de mano izquierda para entrar en la página de despliegue. 

   ![](./img/1-2.png)

Por defecto, Remix utiliza la máquina virtual de Javascript para simular la cadena de Ethereum y ejecutar contratos inteligentes, similar a ejecutar en testnet en el navegador. Remix asignará varias cuentas de prueba, cada una con 100ETH (token de prueba). Si se hace clic en `Deploy` (botón amarillo) para desplegar el contrato. 

   ![](./img/1-3.png)

Después de un despliegue exitoso, se verá un contrato llamado `HolaWeb3` debajo. Al hacer clic en la variable `_string`, imprimirá su valor: "Hola Web3!".

## Resumen

En este turorial, brevemente introdujimos Solidity, El IDE `Remix` y completamos nuestro primer programa en Solidity - `HolaWeb3`. A partir de ahora, continuaremos con nuestro viaje por Solidity.

### Materiales recomendados en Solidity:

1. [Documentación de Solidity](https://docs.soliditylang.org/en/latest/)
2. [Tutorial de Solidity por freeCodeCamp](https://www.youtube.com/watch?v=ipwxYa-F1uY)
