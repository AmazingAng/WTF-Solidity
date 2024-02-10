## 16. Sobrecarga de Funções

Recentemente, tenho revisitado o Solidity para revisar os detalhes e escrever um "Guia Simples de Solidity" para iniciantes (programadores mais experientes podem procurar outros tutoriais), com atualizações semanais de 1 a 3 lições.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

---

## Sobrecarga

No `Solidity`, funções podem ser sobrecarregadas (`overloaded`), o que significa que funções com o mesmo nome, mas tipos de parâmetros diferentes, podem coexistir, sendo tratadas como funções distintas. É importante notar que o `Solidity` não permite a sobrecarga de modificadores (`modifiers`).

### Sobrecarga de Funções

Por exemplo, podemos definir duas funções chamadas `saySomething()`, uma sem parâmetros que retorna `"Nada"` e outra que recebe um parâmetro do tipo `string` e retorna essa `string`.

```solidity
function saySomething() public pure returns (string memory){
    return "Nada";
}

function saySomething(string memory algo) public pure returns (string memory){
    return algo;
}
```

Após a compilação pelo compilador, as funções sobrecarregadas são transformadas em seletores de função diferentes devido aos tipos de parâmetros distintos. Para mais informações sobre seletores de função, consulte [Guia Simples de Solidity: 29. Seletor de Função](https://github.com/AmazingAng/WTFSolidity/tree/main/29_Selector).

Tomando como exemplo o contrato `Overloading.sol`, após compilação e implantação no Remix, ao chamar as funções sobrecarregadas `saySomething()` e `saySomething(string memory something)`, é possível observar que elas retornam resultados diferentes, sendo tratadas como funções distintas.

### Correspondência de Argumentos

Ao chamar uma função sobrecarregada, os argumentos reais passados são correspondidos aos tipos de variáveis dos parâmetros da função. Se houver múltiplas funções sobrecarregadas que correspondam aos argumentos passados, um erro será gerado. No exemplo a seguir, temos duas funções chamadas `f()`, uma com um parâmetro `uint8` e outra com um parâmetro `uint256`:

```solidity
function f(uint8 _in) public pure returns (uint8 out) {
    out = _in;
}

function f(uint256 _in) public pure returns (uint256 out) {
    out = _in;
}
```

Se chamarmos `f(50)`, como `50` pode ser convertido tanto para `uint8` quanto para `uint256`, um erro será gerado.

## Conclusão

Nesta lição, exploramos o uso básico da sobrecarga de funções no `Solidity`: funções com o mesmo nome, mas com tipos de parâmetros diferentes, podem coexistir e ser tratadas como funções distintas.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->