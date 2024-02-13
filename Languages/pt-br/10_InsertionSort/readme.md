# WTF Introdução Simples ao Solidity: 10. Fluxo de Controle, Implementando Ordenação por Inserção em Solidity

Recentemente, tenho estado a reestudar Solidity para consolidar alguns detalhes e estou a escrever uma "Introdução Simples ao Solidity" para iniciantes (programadores avançados podem preferir outros tutoriais). Vou atualizar 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---
Nesta lição, vamos discutir o fluxo de controle em Solidity e depois explicar como implementar a ordenação por inserção (Insertion Sort) em Solidity, um algoritmo que parece simples, mas é fácil introduzir erros.

## Fluxo de Controle

O controle de fluxo em Solidity é semelhante a outras linguagens e inclui as seguintes estruturas:

1. `if-else`

    ```solidity
    function ifElseTest(uint256 _number) public pure returns(bool){
        if(_number == 0){
            return(true);
        } else {
            return(false);
        }
    }
    ```

2. `for`

    ```solidity
    function forLoopTest() public pure returns(uint256){
        uint sum = 0;
        for(uint i = 0; i < 10; i++){
            sum += i;
        }
        return(sum);
    }
    ```

3. `while`

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

4. `do-while`

    ```solidity
    function doWhileTest() public pure returns(uint256){
        uint sum = 0;
        uint i = 0;
        do{
            sum += i;
            i++;
        } while(i < 10);
        return(sum);
    }
    ```

5. Operador ternário

    O operador ternário é o único operador em Solidity que aceita três operandos e segue a regra `condição? expressão se verdadeira: expressão se falsa`. É frequentemente utilizado como uma forma abreviada de uma instrução `if`.

    ```solidity
    // Operador ternário
    function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
        // retorna o maior entre x e y
        return x >= y ? x: y; 
    }
    ```

Além disso, existem palavras-chave `continue` (avançar para a próxima iteração) e `break` (sair do loop atual) que podem ser utilizadas.

## Implementando a Ordenação por Inserção em Solidity

**Aviso: Mais de 90% das pessoas cometem erros ao escrever algoritmos de ordenação em Solidity.**

### Ordenação por Inserção

O objetivo dos algoritmos de ordenação é ordenar uma lista de números em ordem crescente, por exemplo `[2, 5, 3, 1]`. A ordenação por inserção (Insertion Sort) é um dos algoritmos de ordenação mais simples e geralmente é o primeiro algoritmo que as pessoas aprendem. A sua lógica é simples: iterar sobre a lista e comparar cada elemento com os elementos anteriores, movendo-os para a posição correta. Veja a ilustração:

![Ordenação por Inserção](https://i.pinimg.com/originals/92/b0/34/92b034385c440e08bc8551c97df0a2e3.gif)

### Código em Python

Antes de implementar em Solidity, vejamos o código em Python para a ordenação por inserção:

```python
# Programa em Python para a implementação da Ordenação por Inserção
def insertionSort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i-1
        while j >= 0 and key < arr[j]:
            arr[j+1] = arr[j]
            j -= 1
        arr[j+1] = key
    return arr
```

### Implementação Incorreta em Solidity

Com apenas 8 linhas de código em Python, o algoritmo de ordenação por inserção parece simples. Ao transcrevê-lo para Solidity em apenas 9 linhas de código, ocorre um erro:

``` solidity
    // Ordenação por Inserção - Versão Incorreta
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

Ao executar o código no Remix e inserir `[2, 5, 3, 1]`, o programa apresenta um erro! Depois de passar horas tentando encontrar o erro, sem sucesso, pesquisei "solidity insertion sort" e descobri que os tutoriais online de algoritmos de ordenação em Solidity estavam incorretos, como este: [Sorting in Solidity without Comparison](https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d)

### Implementação Correta da Ordenação por Inserção em Solidity

Depois de algumas horas e da ajuda de um amigo do grupo de aprendizagem, finalmente encontrei o erro. O problema é que em Solidity, o tipo de variável mais comum é `uint` (inteiro não negativo), o que pode causar um erro de "underflow" ao tentar obter um valor negativo. No algoritmo de ordenação, a variável `j` pode chegar a `-1`, gerando um erro.

Para resolver esse problema, precisamos garantir que `j` nunca possa ser negativo. Aqui está o código corrigido:

```solidity
// Ordenação por Inserção - Versão Correta
function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
    // Observe que uint não pode ter valor negativo
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

Depois de executar o código e inserir `[2, 5, 3, 1]`, o resultado foi o esperado.

## Conclusão

Nesta lição, discutimos o controle de fluxo em Solidity e implementamos o algoritmo de ordenação por inserção. Embora pareça simples, é fácil cometer erros. Este é o mundo de Solidity, cheio de armadilhas, onde projetos perdem milhões ou até bilhões de dólares devido a pequenos bugs como esse. Dominar os fundamentos e praticar constantemente ajudará a escrever um código Solidity de melhor qualidade.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->