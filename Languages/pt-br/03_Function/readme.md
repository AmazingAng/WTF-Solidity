# WTF Introdução Simples ao Solidity: 3. Funções

Eu tenho revisado Solidity recentemente para reforçar os detalhes e decidi escrever um "WTF Introdução Simples ao Solidity" para uso dos novatos (os programadores experientes podem procurar outros tutoriais). Estarei atualizando 1-3 sessões por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

## Funções

As funções em Solidity são muito versáteis e podem realizar diversas operações complexas. Neste tutorial, vamos abordar os conceitos básicos de funções e demonstrar como utilizá-las por meio de exemplos.

Vamos dar uma olhada na forma das funções em Solidity:

```solidity
function <nome_da_função>(<tipos_de_parâmetros>) {internal|external|public|private} [pure|view|payable] [returns (<tipos_de_retorno>)]
```

Vamos explicar cada parte, de trás para frente (os itens entre colchetes são palavras-chave opcionais):

1. `function`: Palavra-chave fixa usada para declarar uma função. Para escrever uma função, é necessário começar com a palavra-chave `function`.

2. `<nome_da_função>`: Nome da função.

3. `(<tipos_de_parâmetros>)`: Colchetes contendo os tipos e nomes dos parâmetros que a função aceita.

4. `{internal|external|public|private}`: Modificador de visibilidade da função, com 4 opções.

    - `public`: Visível interna e externamente.
    - `private`: Acesso permitido apenas internamente ao contrato, contratos herdados também não podem acessá-lo.
    - `external`: Acesso permitido apenas externamente (internamente pode ser acessado através de `this.f()`, sendo `f` o nome da função).
    - `internal`: Acesso permitido apenas internamente, contratos herdados podem acessá-lo.

    **Observação 1**: Funções definidas em contratos precisam especificar explicitamente a visibilidade, pois não possuem um valor padrão.

    **Observação 2**: `public|private|internal` também podem ser usados para modificar variáveis de estado. Variáveis `public` geram automaticamente uma função `getter` com o mesmo nome para consultar o valor. Variáveis de estado não marcadas com um modificador de visibilidade são consideradas `internal` por padrão.

5. `[pure|view|payable]`: Palavras-chave que determinam as permissões/funções da função. A explicação de `payable` é clara, indica que uma função pode receber ETH ao ser executada. A explicação de `pure` e `view` está na próxima seção.

6. `[returns ()]`: Tipos e nomes das variáveis de retorno da função.

## O que é `Pure` e `View` afinal?

Ao começar a aprender Solidity, as palavras-chave `pure` e `view` podem parecer confusas, pois outras linguagens de programação não possuem equivalentes. A introdução dessas palavras-chave em Solidity é principalmente devido ao fato de que transações do Ethereum requerem pagamento de taxa de gás. Funções marcadas como `pure` e `view` não alteram o estado na cadeia de blocos, e ao chamar diretamente essas funções, não é necessário pagar gás (Observação: funções não `pure`/`view` que chamam funções `pure`/`view` ainda precisam pagar gás).

No Ethereum, as seguintes ações são consideradas modificação do estado na cadeia de blocos:

1. Alterar variáveis de estado.
2. Emitir eventos.
3. Criar outros contratos.
4. Usar o `selfdestruct`.
5. Enviar ETH por chamadas de função.
6. Chamar qualquer função não marcada como `view` ou `pure`.
7. Usar chamadas de baixo nível (`low-level calls`).
8. Usar o assembly inline que inclui certos opcodes.

Para ajudar a entender, criei uma ilustração do Mario. Na ilustração, comparo a variável de estado do contrato (armazenada na cadeia) com a Princesa Peach, e diferentes personagens representam as diferentes palavras-chave.

[Imagem ilustrativa explicando Pure e View]

- `pure`: Significa "puro", neste caso pode ser entendido como “sem efeitos colaterais”. Funções `pure` não podem ler nem escrever em variáveis de estado. É como um inimigo que não pode ver ou tocar na Princesa Peach.

- `view`: Significa “visualização”, neste caso pode ser entendido como “espectador”. Funções `view` podem ler, mas não escrever em variáveis de estado. É como o Mario, que pode ver a Princesa Peach, mas é apenas um espectador, não pode interagir com ela.

- Funções que não são `pure` nem `view` podem ler e escrever em variáveis de estado. Funcionam como o "boss" no jogo do Mario, que pode fazer o que bem entender com a Princesa Peach.

## Código

### 1. Pure e View

Vamos primeiro definir no contrato uma variável de estado `number` inicializada como 5.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract FunctionTypes{
    uint256 public number = 5;
}
```

Vamos definir uma função `add()` que incrementa a variável `number` em 1 sempre que é chamada.

```solidity
// Função padrão
function add() external{
    number = number + 1;
}
```

Se a função `add()` for marcada como `pure`, por exemplo `function add() external pure`, um erro será gerado. Isso ocorre porque uma função `pure` não pode ler variáveis de estado do contrato, muito menos modificá-las. Mas o que uma função `pure` pode fazer? Por exemplo, ela pode receber um parâmetro `_number`, e retornar `_number + 1`, sem ler ou escrever em variáveis de estado.

```solidity
// pure: "pura zoeira"
function addPure(uint256 _number) external pure returns(uint256 new_number){
    new_number = _number + 1;
}
```

Se a função `add()` for marcada como `view`, por exemplo `function add() external view`, também será gerado um erro. Isso porque uma função `view` pode ler, mas não modificar variáveis de estado. Podemos realizar uma pequena modificação na função para ler `number`, mas sem modificar seu valor, retornando um novo valor.

```solidity
// view: espectador
function addView() external view returns(uint256 new_number) {
    new_number = number + 1;
}
```

### 2. internal vs. external

```solidity
// internal: função interna
function minus() internal {
    number = number - 1;
}

// Funções internas podem ser chamadas a partir de funções no contrato
function minusCall() external {
    minus();
}
```

Vamos definir a função `minus()`, marcada como `internal`, que reduz o valor da variável `number` em 1 a cada chamada. Como funções `internal` só podem ser chamadas internamente dentro do contrato, precisamos definir uma função `external` `minusCall()` para chamar indiretamente a função `minus()`.

### 3. payable

```solidity
// payable: aceita pagamento, função que permite contratos receberem ETH
function minusPayable() external payable returns(uint256 balance) {
    minus();    
    balance = address(this).balance;
}
```

Vamos definir a função `minusPayable()`, marcada como `external payable`, que indiretamente chama `minus()` e retorna o saldo de ETH no contrato (usamos `this` para referenciar o endereço do contrato). Podemos chamar a função `minusPayable()` e enviar 1 ETH para o contrato.

## Conclusão

Nesta sessão, apresentamos as funções em Solidity. As palavras-chave `pure` e `view` podem ser difíceis de entender, pois não existem equivalentes em outras linguagens de programação: uma função `view` pode ler variáveis de estado, mas não pode modificá-las; uma função `pure` não pode ler nem modificar variáveis de estado.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->