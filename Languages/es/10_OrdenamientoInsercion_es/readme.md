# WTF Tutorial Solidity: 10. Flujo de Control

Recientemente, he estado revisando Solidity, consolidando detalles y escribiendo tutoriales "WTF Solidity" para principiantes.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidad: [Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[Website wtf.academy](https://wtf.academy)

La traducción al español ha sido realizada por Sebas G con el objetivo de hacer estos recursos accesibles a la comunidad de habla hispana.

Twitter: [@scguaquetam](https://twitter.com/scguaquetam)

Los códigos y tutoriales están como código abierto en GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)


-----

En esta sección, introduciremos el flujo de control en Solidity y escribiremos un ordenamiento por inserción `(InsertionSort)`, un programa que parece simple pero es propenso a errores.

## Flujo de Control

El flujo de control en Solidity es similar al de otros lenguajes, e incluye principalmente los siguientes componentes:

1. `if-else`

```solidity
function ifElseTest(uint256 _number) public pure returns(bool){
    if(_number == 0){
	return(true);
    }else{
	return(false);
    }
}
```

2. `bucle for`

```solidity
function forLoopTest() public pure returns(uint256){
    uint sum = 0;
    for(uint i = 0; i < 10; i++){
	sum += i;
    }
    return(sum);
}
```

3. `bucle while`

```solidity
function whileTest() public pure returns(uint256){
    uint sum = 0;
    uint i = 0;
    while(i < 10){
	sum += i;
	i++;
    }
    return(sum);
}
```

4. `bucle do-while`

```solidity
function doWhileTest() public pure returns(uint256){
    uint sum = 0;
    uint i = 0;
    do{
	sum += i;
	i++;
    }while(i < 10);
    return(sum);
}
```

5. Operador condicional (`ternario`)

El operador `ternario` es el único operador en Solidity que acepta tres operandos: una condición seguida por un signo de interrogación (`?`), luego una expresión `x` para ejecutar si la condición es verdadera seguida por dos puntos (`:`), y finalmente la expresión `y` para ejecutar si la condición es falsa: `condición ? x : y`.

Este operador se usa frecuentemente como una alternativa a una declaración `if-else`.

```solidity
// operador ternario/condicional
function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
    // devuelve el máximo entre x e y, si x es mayor que y, devuelve x, de lo contrario, devuelve y
    return x >= y ? x : y; 
}
```

Además, hay palabras clave `continue` (ingresar inmediatamente al siguiente bucle) y `break` (salir del bucle actual) que se pueden usar.

## Implementación de Ordenamiento por Inserción en `Solidity`.

**Nota**: Más del 90% de las personas que escriben el algoritmo de inserción con Solidity lo harán mal en el primer intento.

### Ordenamiento por Inserción

El algoritmo de ordenamiento resuelve el problema de ordenar un conjunto desordenado de números de menor a mayor, por ejemplo, ordenar `[2, 5, 3, 1]` a `[1, 2, 3, 5]`. El ordenamiento por Inserción (`InsertionSort`) es el algoritmo de ordenamiento más simple y el primero que la mayoría de los desarrolladores aprenden en su clase de ciencias de la computación. La lógica de `InsertionSort`:

1. Desde el primer elemento del arreglo `x` hasta el último, compara el elemento `x[i]` con el elemento frente a él `x[i-1]`; si `x[i]` es más pequeño, cambia sus posiciones, luego lo compara con `x[i-2]`, y repite el proceso.

El esquema del ordenamiento por inserción:
- Sorted = Ordenado
- Unsorted = No ordenado

![InsertionSort](https://i.pinimg.com/originals/92/b0/34/92b034385c440e08bc8551c97df0a2e3.gif)

### Implementación en Python

Veamos primero la implementación en Python del ordenamiento por inserción:

```python
# Programa en Python para la implementación del Ordenamiento por Inserción
def insertionSort(arr):
	for i in range(1, len(arr)):
		key = arr[i]
		j = i-1
		while j >=0 and key < arr[j] :
				arr[j+1] = arr[j]
				j -= 1
		arr[j+1] = key
    return arr
```

### Implementación en Solidity (con Error)

La versión en Python del Ordenamiento por Inserción ocupa 9 líneas. Reescribámoslo en Solidity reemplazando `funciones`, `variables` y `bucles` con la sintaxis de Solidity correspondiente. Esta solo ocupa 9 líneas de código:

``` solidity
    // Ordenamiento por Inserción (Versión incorrecta)
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i-1;
            while( (j >= 0) && (temp < a[j])){
                a[j+1] = a[j];
                j--;
            }
            a[j+1] = temp;
        }
        return(a);
    }
```

Pero cuando compilamos la versión modificada y tratamos de ordenar `[2, 5, 3, 1]`. *BOOM!* ¡Hay errores! Después de 3 horas de depuración, aún no pude encontrar dónde estaba el error. Busqué "Solidity insertion sort" en Google, y encontré que todos los algoritmos de inserción escritos con Solidity estaban equivocados, como: [Ordenamiento en Solidity sin Comparación](https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d) 

Aquí los errores en la consola de `Remix`:

![10-1](./img/10-1.jpg)

### Implementación en Solidity (Correcta)

Con la ayuda de un amigo de la comunidad `Dapp-Learning`, finalmente encontramos el problema. El tipo de variable más utilizado en Solidity es `uint`, que representa un entero no negativo. Si se intenta tomar un valor negativo, se producirá un error de  `underflow`. En el código anterior, la variable `j` tomaba `-1`, causando el error.

Por lo tanto, necesitamos agregar `1` a `j` para que nunca tome un valor negativo. El código correcto de ordenamiento por inserción en Solidity:

```solidity
    // Ordenamiento por Inserción (Versión Correcta)
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // nota que uint no puede tomar valor negativo
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i;
            while( (j >= 1) && (temp < a[j-1])){
                a[j] = a[j-1];
                j--;
            }
            a[j] = temp;
        }
        return(a);
    }
```

Resultado:

   !["Input [2,5,3,1] Output[1,2,3,5]"](https://images.mirror-media.xyz/publication-images/S-i6rwCMeXoi8eNJ0fRdB.png?height=300&width=554)

## Resumen

En esta lección, se introdujo el flujo de control en Solidity y escribimos un algoritmo de ordenamiento simple pero propenso a errores. Solidity parece simple pero tiene muchas trampas. Cada mes, proyectos son hackeados y pierden millones de dólares debido a pequeños errores en los contratos inteligentes. Para escribir un contrato seguro, necesitamos dominar los fundamentos de Solidity y seguir practicando.