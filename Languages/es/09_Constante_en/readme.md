# WTF Tutorial Solidity: 9. Constante e Inmutable

Recientemente, he estado revisando Solidity, consolidando detalles y escribiendo tutoriales "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Sebas G con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@scguaquetam](https://twitter.com/scguaquetam)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)


-----

En esta sección, introduciremos dos palabras clave para restringir modificaciones a su estado en Solidity: `constant` e `immutable`. Si una variable de estado se declara con `constant` o `immutable`, su valor no puede modificarse después de la compilación del contrato.

Las variables de tipo de valor pueden declararse como `constant` o `immutable`; `string` y `bytes` pueden declararse como `constant`, pero no como `immutable`.

## Constante e Inmutable

### Constante

La variable `constant` debe inicializarse durante la declaración y no puede cambiarse después. Cualquier intento de modificación resultará en un error en la compilación.

``` solidity
    // La variable constante debe inicializarse cuando se declara y no puede cambiarse después de eso
    uint256 constant CONSTANT_NUM = 10;
    string constant CONSTANT_STRING = "0xAA";
    bytes constant CONSTANT_BYTES = "WTF";
    address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
```

### Inmutable

La variable `immutable` puede inicializarse durante la declaración o en el constructor, esto la hace más flexible. Una vez inicializada, no puede ser cambiada..

``` solidity
    // La variable inmutable puede inicializarse en el constructor y no puede cambiarse después
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;
```

Puedes inicializar la variable `immutable` usando una variable global como `address(this)`, `block`.`number`, o una función personalizada. En el siguiente ejemplo, usamos la función `test()` para inicializar la variable `IMMUTABLE_TEST` a un valor de `9`:

``` solidity`
    // Las variables inmutables se inicializan con constructor, para que puedan ser usadas
    constructor(){
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_BLOCK = block.number;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }
```


## Verificar en Remix

1. Después de que se despliegue el contrato, puedes obtener los valores de las variables `constant` e `immutable` a través de la función `getter`.

   ![9-1.png](./img/9-1.png)   
   
2. Después de que la variable `constant` se inicializa, cualquier intento de cambiar su valor resultará en un mensaje como en el ejemplo, el compilador arrojará: `TypeError: Cannot assign to a constant variable.` (TypeError: No se puede asignar a una variable constante.)

   ![9-2.png](./img/9-2.png)   
   
3. Después de que la variable `immutable` se inicializa, cualquier intento de cambiar su valor resultará en un mensaje como en el ejemplo, el compilador arrojará: `TypeError: Immutable state variable already initialized.` (TypeError: Variable de estado inmutable ya inicializada.)

   ![9-3.png](./img/9-3.png)

## Resumen

En esta sección, introducimos dos palabras clave para restringir modificaciones a su estado en Solidity: `constant` e `immutable`. Estas mantienen restringidas las variables que no deben cambiarse. Ayudan a ahorrar gas al tiempo que mejora la seguridad del contrato.


