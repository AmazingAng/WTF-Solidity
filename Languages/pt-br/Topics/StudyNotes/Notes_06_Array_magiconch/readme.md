# Como remover um elemento específico de um array em Solidity

Em comparação com outras linguagens, os arrays em Solidity têm funcionalidades limitadas, com apenas as funções push/pop disponíveis. No entanto, em desenvolvimento real, podemos encontrar situações em que precisamos remover um elemento específico. Como podemos fazer isso?

## Solução Simples

Em Solidity, existe uma palavra-chave chamada `delete`. Podemos usar essa palavra-chave para remover um elemento específico?

```solidity
pragma solidity ^0.8.9;

contract itemRemoval {
  uint[] public arrs = [1,2,3,4,5];

  function removeItem(uint i) public {
    delete arrs[i];
  }

  function getLength() public view returns(uint) {
    return arrs.length;
  }
}
```

No código acima, tentamos remover o primeiro elemento executando `removeItem(0)`. O array `arrs` se tornará `[0,2,3,4,5]`. Em seguida, executamos `getLength()` e obtemos o resultado `5`. O que está acontecendo?

> ```markdown
> ## delete
> `a` assigns the initial value for the type to `a`. I.e. for integers it is equivalent to `a = 0`
> ```

Ao consultar a documentação, descobrimos que, em Solidity, a palavra-chave `delete` atribui o valor inicial do tipo à variável. Ou seja, para inteiros, é equivalente a `a = 0`. Portanto, a remoção usando `delete` não remove o elemento do array, mas o redefine para o valor padrão. Isso pode levar a um aumento contínuo das taxas de gas se o código continuar sendo executado e exceder o limite máximo.

Se você acha que isso não é um problema, vamos expandir o problema:

```solidity
pragma solidity ^0.8.9;

contract itemRemoval {
  uint[] public arrs = [0,1,2,3,4];

  function deleteZeroItem() public {
    for (uint i = 0; i < arrs.length; i++) {
      if (arrs[i] == 0) {
        delete arrs[i];
      }
    }
  }

  function getLength() public view returns(uint) {
    return arrs.length;
  }
}
```

Neste exemplo, tentamos criar uma função que remove elementos com valor zero. No entanto, ao executar o código acima, você verá que não é possível remover esse elemento.

Podemos ver que, embora a remoção usando `delete` seja simples e economize gas, ela traz riscos imprevisíveis.

## Trocar com o último elemento

```solidity
pragma solidity ^0.8.9;

contract itemRemoval {
  uint[] public arrs = [1,2,3,4,5];

  function removeItem(uint i) public {
    arrs[i] = arrs[arrs.length - 1];
    arrs.pop();
  }

  function getLength() public view returns(uint) {
    return arrs.length;
  }
}
```

Ao trocar o elemento alvo com o último elemento do array e, em seguida, remover o último elemento, o custo de gas será maior em comparação com a solução anterior. No entanto, dessa forma, podemos controlar o tamanho do array e evitar que ele cresça indefinidamente com o tempo.

No entanto, essa solução também não é perfeita, pois a remoção de um elemento dessa forma alterará a ordem dos elementos no array. Se for necessário manter a ordem dos elementos, devemos usar a seguinte abordagem:

```solidity
pragma solidity ^0.8.9;

contract itemRemoval {
  uint[] public arrs = [1,2,3,4,5];

  function removeItem(uint i) public {
    for (; i < arrs.length - 1; i++) {
      arrs[i] = arrs[i + 1];
    }
    arrs.pop();
  }

  function getLength() public view returns(uint) {
    return arrs.length;
  }
}
```

No entanto, essa abordagem tem um alto custo de gas, pois a alteração de um estado tem um custo de gas muito maior do que uma operação. Portanto, a menos que seja absolutamente necessário, não é recomendado usar essa abordagem.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->