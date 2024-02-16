# _safeTransferFrom() usando proxy para transferir NFT (1)

O endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` possui os tokens com IDs `[951, 952]`

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_.png)

O endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f` não possui NFTs

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_1.png)

Agora vamos autorizar o NFT com ID 951 do endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` para o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f`

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_2.png)

Detalhes da transação:

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x58873c6278ed0f7448afcc8a4f8225c7912de7c8b8497048fcfd8f3cd70f0cc4)

Agora, verificando novamente, o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f` ainda não possui NFTs

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_3.png)

O NFT com ID 951 ainda pertence ao endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd`

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_4.png)

Mas ao chamar a função `getApprove()`, vemos que o NFT com ID 951 já foi autorizado para o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f`

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_5.png)

Agora, vamos usar o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f` para transferir o NFT com ID 951 do endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` para o endereço `0x8600C2E501f145C2EaA1fC2a46334Fe7B29493c1`

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_6.png)

Detalhes da transação:

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x042fa2f76ba9716255f2c399e3abf881978a15c7b27f925fe2373c4eadce71a5)

Agora o endereço `0x8600C2E501f145C2EaA1fC2a46334Fe7B29493c1` possui o NFT com ID 951

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_7.png)

O endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` agora possui apenas o NFT com ID 952

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_8.png)

## Uma pequena questão:

Quando o NFT com ID 951 foi transferido do endereço original `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` para o endereço `0x8600C2E501f145C2EaA1fC2a46334Fe7B29493c1`, a autorização anterior do endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` para o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f` como proxy ainda está válida?

Intuitivamente, com a perda da propriedade do NFT com ID 951 pelo endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd`, todas as operações relacionadas à propriedade feitas anteriormente pelo endereço `0xb9016E740176B54755cBAad721dCDD6a65aB40Fd` seriam invalidadas. Se a autorização ainda estivesse válida, o endereço `0x0FD745DB2fd13f1598c65fa3d32696C1fF6DA23f` ainda poderia transferir o NFT com ID 951 secretamente para outra pessoa, o que claramente não faz sentido. Vamos verificar nossa suposição.

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_9.png)

O endereço autorizado para o NFT com ID 951 agora é 0, a autorização anterior foi automaticamente cancelada, tudo isso foi implementado pelos desenvolvedores.

Relação entre as funções: `safeTransferFrom()` chama `safeTransferFrom()` (mesmo nome de função, mas com parâmetros diferentes) que chama `_transfer()`, e em `_transfer()`, a alteração de autorização é cancelada.

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_10.png)

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_11.png)

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_12.png)

A alteração de autorização é cancelada em `_transfer()`.

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_13.png)

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x41de905938fc10782b4269dc4ad065be2a1391caa12f8afabd92902b4a2b4835)

![Untitled](./img/_safeTransferFrom()使用代理转移NFT_14.png)

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->