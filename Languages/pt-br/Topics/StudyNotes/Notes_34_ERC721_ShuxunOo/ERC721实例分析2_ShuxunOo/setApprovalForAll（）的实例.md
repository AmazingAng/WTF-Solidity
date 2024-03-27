# Exemplo de setApprovalForAll()

O contrato padrão ERC721 não fornece uma interface para transferir em massa NFTs para endereços diferentes. Se o projeto deseja fazer um airdrop para usuários em uma lista branca, o contrato de proxy em conjunto com a função setApprovalForAll() oferece uma solução.

Introdução básica ao contrato de interface:

[Solidity8.0全面精通-42-接口合约_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1fS4y127BX/?spm_id_from=333.788&vd_source=8c3c6813b187818a0ba1a67277a795d2)

Você pode consultar os seguintes vídeos para entender o princípio do airdrop:

[https://www.youtube.com/watch?v=-0nU2usv4S4&t=2s](https://www.youtube.com/watch?v=-0nU2usv4S4&t=2s)

[https://www.youtube.com/watch?v=M7ThuAS47Cc](https://www.youtube.com/watch?v=M7ThuAS47Cc)

Contrato usado para o airdrop:

```solidity
/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface BC_Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function symbol() external returns (string memory);
}

contract BanaCatBot {
    BC_Interface public BanaCat;
    string public symbol;

    function setInterfaceContract(BC_Interface _addr) external{
        BanaCat = _addr;
    }

    function bulkTransfer(address[] calldata addrList, uint[] calldata nftlist) external {
        require(addrList.length == nftlist.length, "length doesn't match");
        for (uint i = 0; i < addrList.length; i++){
            BanaCat.safeTransferFrom(msg.sender, addrList[i], nftlist[i]);
        }
    }
    function showSymbol() external{
        symbol = BanaCat.symbol();
    }

}
```

O contrato também foi disponibilizado na rede Polygon e pode ser usado diretamente.

[https://polygonscan.com/address/0x2A6dFC4C69a716b7F02b55CE76432226AefCB193#code](https://polygonscan.com/address/0x2A6dFC4C69a716b7F02b55CE76432226AefCB193#code)

# Como usar

**Observação: Durante o processo, o contrato BanaCatNFT pode ser substituído pelo contrato principal desejado para a transferência em massa de NFTs.**

1. Chame a função `setApprovalForAll()` no contrato principal para autorizar o contrato de proxy que fornece a funcionalidade de transferência em massa de NFTs.

Esta etapa é concluída no contrato principal do NFT, autorizando todos os NFTs em seu endereço para o contrato de proxy, para que ele tenha permissão para transferi-los.

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x92342888a4ecbe3775fe920c7efc9cab1eb5befe643c955d9a7bc786cc6e29a5)

2. Chame a função `setInterfaceContract()` no contrato de proxy para definir o endereço do contrato BanaCatNFT como a interface de destino do contrato de proxy.

O objetivo desta etapa é informar ao contrato de proxy de qual contrato principal de NFT ele deve transferir os NFTs.

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0x56f289faaab56c3cb1ac1401f970a23c9f79d0c193d0e76d9d3e049494c37f03#eventlog)

3. Construa as listas `NFTList` e `addressList` para iniciar a transação.

    ![Untitled](./img/setApprovalForAll（）的实例.png)

Aqui está um pequeno problema que precisa ser observado: os dois parâmetros da função `bulkTransfer()` podem variar dependendo do contexto de execução da função.

1. Implante no Remix e envie a transação no backend do Remix, a forma dos parâmetros é:

addrList: ["address1", "address2", ...] (os endereços são colocados entre aspas duplas e separados por vírgula) por exemplo

```solidity
["0x204Eb0dDD556Fc33805A53BA29572B349Ea3c288","0xcd06Db13ACff23EEa734f771ed52cE59642E52b1",......]
```

nftlist: [tokenID1, tokenID2, ...] (os tokenIDs são separados por vírgula)

```solidity
[1,2,3,......]
```

2. Implante e envie a transação por meio de RPC local: igual ao acima
3. Inicie a transação no navegador polyscan:

addrList: [address1, address2, ...] (os endereços não precisam de aspas duplas e são separados por vírgula) por exemplo

```solidity
[0x204Eb0dDD556Fc33805A53BA29572B349Ea3c288,0xcd06Db13ACff23EEa734f771ed52cE59642E52b1,......]
```

nftlist: [tokenID1, tokenID2, ...] (os tokenIDs são separados por vírgula, ‼️**não pode haver espaços entre os tokenIDs‼️**)

```solidity
[1,2,3,......]
```

A transação final terá a seguinte aparência:

[Polygon Transaction Hash (Txhash) Details | PolygonScan](https://polygonscan.com/tx/0xa57405133607002ef92260f91ee8f56001fcabe0c34cd9c4c77661d9b893c2f0).

