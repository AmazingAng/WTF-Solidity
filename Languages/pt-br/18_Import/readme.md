# WTF Introdução Simples ao Solidity: 18. Import

Recentemente, tenho revisado meu conhecimento sobre Solidity para reforçar os detalhes e estou escrevendo um "WTF Introdução Simples ao Solidity" para iniciantes (os programadores experientes podem buscar outros tutoriais), com atualizações semanais de 1 a 3 palestras.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais são de código aberto no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

-----

No Solidity, a declaração `import` nos permite referenciar o conteúdo de um arquivo em outro, aumentando a reutilização e organização do código. Este tutorial irá te mostrar como utilizar a declaração `import` no Solidity.

## Uso do `import`

- Importação por posição relativa do arquivo, exemplo:

  ```text
  Estrutura de Arquivos
  ├── Import.sol
  └── Yeye.sol

  // Importar por posição relativa do arquivo
  import './Yeye.sol';
  ```

- Importação do símbolo global do contrato de um arquivo online através do URL, exemplo:

  ```text
  // Importar por URL
  import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
  ```

- Importação do diretório npm, exemplo:

  ```solidity
  import '@openzeppelin/contracts/access/Ownable.sol';
  ```

- Importação de um símbolo global específico do contrato, exemplo:

  ```solidity
  import {Yeye} from './Yeye.sol';
  ```

- O posicionamento do `import` no código é após a declaração da versão e antes do restante do código.

## Testando a Importação

Podemos testar se a importação do código externo foi bem-sucedida com o seguinte trecho de código:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Importar por posição relativa do arquivo
import './Yeye.sol';
// Importar um contrato específico
import {Yeye} from './Yeye.sol';
// Importar por URL
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol';
// Importar o contrato Ownable do OpenZeppelin
import '@openzeppelin/contracts/access/Ownable.sol';

contract Import {
    // Importar a biblioteca Address com sucesso
    using Address for address;
    // Declarar a variável yeye
    Yeye yeye = new Yeye();

    // Testar se é possível chamar uma função de yeye
    function test() external {
        yeye.hip();
    }
}
```

![result](./img/18-1.png)

## Conclusão

Nesta palestra, exploramos o uso da palavra-chave `import` para importar código externo. Com o `import`, podemos referenciar contratos ou funções de outros arquivos que escrevemos, bem como importar diretamente códigos pré-escritos por terceiros, o que é muito prático.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->