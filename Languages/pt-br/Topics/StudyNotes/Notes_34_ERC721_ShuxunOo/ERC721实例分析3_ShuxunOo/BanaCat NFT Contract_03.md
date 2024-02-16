# Contrato BanaCat NFT (3/3)

# Sobre o BanaCatNFT

O projeto BanaCat é uma coleção de arte digital de avatar implantada na blockchain Polygon.

Link do projeto: [BanaCato_O - Collection | OpenSea](https://opensea.io/collection/banacat-v2)

Endereço do contrato: https://polygonscan.com/address/0xd2bc5c3990c06ccd26f10a3e9d93b19450136c8d#code

Além disso, com base nesta arte digital, foram criados pacotes de emojis relacionados. Atualmente, um desses pacotes já está disponível na loja de emojis do WeChat. Link do pacote de emojis: [香蕉猫看戏篇](https://sticker.weixin.qq.com/cgi-bin/mmemoticon-bin/emoticonview?oper=single&t=shop/detail&productid=aL2PCfwK/89qO7sF6/+I+UDhfwEjhec2ZNvdnLLJRd/N7QVyYnUnFpeB0t9OOOGqFiGlj08OJVil+/ruMQmJp3eFNlkqDVcbCJC9A4/2eWbE=)

---

Este artigo explora o canal especial de mint incorporado no BanaCatNFT. Antes de lançar o BanaCatNFT, devido à falta de divulgação prévia e coleta de whitelist, mas para permitir que o projeto seja lançado o mais rápido possível e reduzir a barreira de acesso dos usuários, em vez de usar uma lista de whitelist tradicional ou uma árvore de Merkle, o BanaCatNFT da primeira fase usa senhas para realizar o mint. A seguir, analisaremos as vantagens e desvantagens desse esquema especial de freeMint.

Ideia geral: Defina uma matriz de senhas com comprimento 5 para registrar 5 senhas diferentes correspondentes a diferentes cenários de mint. Cada senha pode ser configurada para corresponder a uma quantidade específica de NFTs que podem ser mintados. Quando o usuário conhece a senha, ele a insere em um canal especial e, se a senha estiver correta, o NFT é atribuído ao usuário sem a necessidade de pagamento.

# Configurando senhas

Defina uma estrutura de dados para informações de senha e, em seguida, defina uma matriz para armazenar essas informações de senha.

![Untitled](./img/Untitled.png)

`showSecretattributes()`: _ID corresponde ao índice da senha na matriz, secret corresponde à própria senha e supplyAmount corresponde à quantidade de NFTs que podem ser mintados com essa senha.

Observação: Para alterar as propriedades de senhas diferentes no mesmo índice da matriz, é necessário primeiro esgotar a quantidade restante de NFTs da senha anterior.

![Untitled](./img/1.png)

`setMaxTokenAmountForEachAddress()`: Define o número máximo de NFTs que um único endereço pode mintar ao usar o canal especial.

![Untitled](./img/2.png)

# Verificando senhas

`checkSecret()`: Compara userInput com as senhas já configuradas na matriz. Se uma senha correspondente for encontrada, o loop é interrompido.

![Untitled](./img/3.png)

`isEqual()`: Compara se duas strings de entrada são iguais. Como a linguagem Solidity não possui uma sintaxe direta para comparar se duas strings são iguais, essa função compara os valores hash das strings para verificar se são iguais.

![Untitled](./img/4.png)

# Mint pelo canal especial

`specialMint_tunnel()`: Usa as funções de verificação acima para verificar a senha inserida pelo usuário e, se aprovada, atribui o NFT à conta atual.

![Untitled](./img/5.png)

Exemplo de transação de mint pelo canal especial

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0xc50d4022ff5a9e3b906ede41cf014a55bfe93d901711e3514f844778d31e9abd)

# Visualizando as propriedades das senhas

`showSecretattributes()`: Visualiza a senha com base no número de senha fornecido. Apenas o proprietário pode visualizar (aqui eu me coloquei em uma armadilha)

![Untitled](./img/6.png)

`getRemainingtokenAmount()`: Visualiza quantos NFTs ainda podem ser mintados com a senha atual.

![Untitled](./img/7.png)

A armadilha que eu me coloquei: `showSecretattributes()` e `getRemainingtokenAmount()` são métodos de visualização (apenas leitura) e são definidos como onlyOwner. Depois de implantados no Remix, eles podem ser visualizados, mas esses dois métodos não estão disponíveis no navegador Polyscan.

# Vantagens e desvantagens do mecanismo de whitelist de senhas

Vantagens: Não é necessário coletar uma whitelist, qualquer pessoa que conheça a senha pode mintar gratuitamente, pode ser usado para eventos temporários.

Desvantagens: Até agora, as desvantagens são mais evidentes.

1. Qualquer pessoa que conheça a senha pode mintar, não importa quem seja. Quando alguém que conhece a senha a divulga, a situação se torna incontrolável, a menos que seja intencional por parte do projeto.
2. A restrição na quantidade de mint por endereço "não impede os bons, mas impede os maus". Apenas dois endereços são necessários para esgotar os NFTs do projeto.
3. As senhas configuradas são exibidas em texto claro nos registros de transações, o que torna necessário definir senhas temporárias.

# Melhorias: Combinação do mecanismo de verificação de whitelist de Merkle Tree e senhas

- O mecanismo de verificação de whitelist de Merkle Tree consiste em fazer o hash de cada par de endereços da whitelist para gerar uma raiz de árvore, armazenando apenas essa raiz no contrato, em vez de armazenar toda a whitelist na blockchain. Esse mecanismo de verificação pode economizar muito nos custos de emissão. Uma solução que combina o mecanismo de verificação de whitelist de Merkle Tree e senhas que consigo pensar é: definir um número fixo de senhas e substituí-las pelos endereços da whitelist para calcular a raiz da árvore de Merkle, e então armazenar essa raiz no contrato. As senhas podem ser distribuídas aos usuários por algum meio quando a whitelist é emitida.
- Substituir a matriz por um mapeamento, para economizar gás ao verificar a validade da senha, eliminando a necessidade de percorrer a matriz.

# Cenário de aplicação: Integração de loteria de raspadinha e NFT.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->