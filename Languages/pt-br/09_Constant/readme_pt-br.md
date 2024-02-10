# WTF Introdução Simples ao Solidity: 9. Constante `constant` e `immutable`

Recentemente, tenho revisado o Solidity para consolidar os detalhes e escrever uma "Introdução Simples ao Solidity" para os novatos (os mestres da programação podem procurar outros tutoriais). Serão publicadas de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

Nesta lição, apresentaremos dois palavras-chave relacionadas a constantes no Solidity: `constant` (constante) e `immutable` (imutável). Quando essas palavras-chave são utilizadas na declaração de variáveis de estado, os valores não podem ser alterados após a inicialização. Isso melhora a segurança do contrato e economiza `gas`.

Além disso, somente variáveis numéricas podem ser declaradas como `constant` e `immutable`; `string` e `bytes` podem ser declarados como `constant`, mas não como `immutable`.

## constant e immutable

### constant

As variáveis `constant` devem ser inicializadas no momento da declaração e não podem mais ser modificadas. Tentar alterar essas variáveis resultará em erro de compilação.

``` solidity
// Variáveis constantes devem ser inicializadas no momento da declaração e não podem ser alteradas posteriormente
uint256 constant CONSTANT_NUM = 10;
string constant CONSTANT_STRING = "0xAA";
bytes constant CONSTANT_BYTES = "WTF";
address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
```

### immutable

As variáveis `immutable` podem ser inicializadas durante a declaração ou no construtor, tornando-as mais flexíveis.

``` solidity
// Variáveis immutable podem ser inicializadas no constructor e não podem mais ser alteradas
uint256 public immutable IMMUTABLE_NUM = 9999999999;
address public immutable IMMUTABLE_ADDRESS;
uint256 public immutable IMMUTABLE_BLOCK;
uint256 public immutable IMMUTABLE_TEST;
```

Você pode usar variáveis globais como `address(this)`, `block.number` ou funções personalizadas para inicializar variáveis `immutable`. No exemplo abaixo, usamos a função `test()` para inicializar `IMMUTABLE_TEST` com o valor `9`:

``` solidity
// Inicializa variáveis immutable no constructor e pode ser usado
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

## Verificação no remix

1. Após implantar o contrato, você pode obter os valores previamente inicializados das variáveis `constant` e `immutable` usando a função `getter` no remix.

   ![9-1.png](./img/9-1.png)

2. Após a inicialização da variável `constant`, tentar alterar seu valor resultará em erro de compilação `TypeError: Cannot assign to a constant variable.`.

   ![9-2.png](./img/9-2.png)

3. Após a inicialização da variável `immutable`, tentar alterar seu valor resultará em erro de compilação `TypeError: Immutable state variable already initialized.`.

   ![9-3.png](./img/9-3.png)

## Conclusão

Nesta lição, apresentamos duas palavras-chave no Solidity, `constant` (constante) e `immutable` (imutável), para manter variáveis que não devem mudar, inalteradas. Essa prática não apenas economiza `gas`, mas também aumenta a segurança do contrato.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->