# Biblioteca Padrão Forge • [![testes](https://github.com/brockelmore/forge-std/actions/workflows/tests.yml/badge.svg)](https://github.com/brockelmore/forge-std/actions/workflows/tests.yml)

A Biblioteca Padrão Forge é uma coleção de contratos úteis para uso com [`forge` e `foundry`](https://github.com/foundry-rs/foundry). Ela utiliza os "cheatcodes" do `forge` para facilitar e acelerar a escrita de testes, melhorando a experiência do usuário com os "cheatcodes".

**Aprenda a usar o Forge Std com o [📖 Livro Foundry (Guia Forge Std)](https://book.getfoundry.sh/forge/forge-std.html).**

## Instalação

```bash
forge install foundry-rs/forge-std
```

## Contratos
### stdError

Este é um contrato auxiliar para erros e reverts. No `forge`, este contrato é especialmente útil para o "cheatcode" `expectRevert`, pois ele fornece todos os erros embutidos do compilador.

Consulte o próprio contrato para ver todos os códigos de erro.

#### Exemplo de uso

```solidity

import "forge-std/Test.sol";

contract TestContract is Test {
    ErrorsTest test;

    function setUp() public {
        test = new ErrorsTest();
    }

    function testExpectArithmetic() public {
        vm.expectRevert(stdError.arithmeticError);
        test.arithmeticError(10);
    }
}

contract ErrorsTest {
    function arithmeticError(uint256 a) public {
        uint256 a = a - 100;
    }
}
```

### stdStorage

Este é um contrato bastante extenso devido a todas as sobrecargas para tornar a experiência do desenvolvedor decente. Primariamente, é uma camada de abstração em torno dos "cheatcodes" `record` e `accesses`. Ele pode *sempre* encontrar e escrever nos slots de armazenamento associados a uma variável específica sem conhecer o layout de armazenamento. A única _grande_ ressalva é que, embora seja possível encontrar um slot para variáveis de armazenamento compactadas, não podemos escrever nessa variável com segurança. Se um usuário tentar escrever em um slot compactado, a execução lançará um erro, a menos que ele esteja não inicializado (`bytes32(0)`).

Isso funciona registrando todos os `SLOAD`s e `SSTORE`s durante uma chamada de função. Se houver uma única leitura ou escrita em um slot, ele retorna imediatamente o slot. Caso contrário, nos bastidores, iteramos e verificamos cada um (assumindo que o usuário passou um parâmetro `depth`). Se a variável for uma struct, você pode passar um parâmetro `depth`, que é basicamente a profundidade do campo.

Por exemplo:
```solidity
struct T {
    // profundidade 0
    uint256 a;
    // profundidade 1
    uint256 b;
}
```

#### Exemplo de uso

```solidity
import "forge-std/Test.sol";

contract TestContract is Test {
    using stdStorage for StdStorage;

    Storage test;

    function setUp() public {
        test = new Storage();
    }

    function testFindExists() public {
        // Digamos que queremos encontrar o slot para a variável pública
        // `exists`. Basta passar o seletor da função para o comando `find`
        uint256 slot = stdstore.target(address(test)).sig("exists()").find();
        assertEq(slot, 0);
    }

    function testWriteExists() public {
        // Digamos que queremos escrever no slot para a variável pública
        // `exists`. Basta passar o seletor da função para o comando `checked_write`
        stdstore.target(address(test)).sig("exists()").checked_write(100);
        assertEq(test.exists(), 100);
    }

    // Ele suporta layouts de armazenamento arbitrários, como localizações de armazenamento baseadas em assembly
    function testFindHidden() public {
        // `hidden` é um hash aleatório de bytes, a iteração pelos slots não o encontraria. Nosso mecanismo o encontra
        // Além disso, você pode usar o seletor em vez de uma string
        uint256 slot = stdstore.target(address(test)).sig(test.hidden.selector).find();
        assertEq(slot, uint256(keccak256("my.random.var")));
    }

    // Se o alvo for um mapeamento, você precisará passar as chaves necessárias para realizar a busca
    // por exemplo:
    function testFindMapping() public {
        uint256 slot = stdstore
            .target(address(test))
            .sig(test.map_addr.selector)
            .with_key(address(this))
            .find();
        // no construtor de `Storage`, escrevemos que o valor deste endereço era 1 no mapa
        // então, quando carregamos o slot, esperamos que seja 1
        assertEq(uint(vm.load(address(test), bytes32(slot))), 1);
    }

    // Se o alvo for uma struct, você pode especificar a profundidade do campo:
    function testFindStruct() public {
        // NOTA: veja o parâmetro de profundidade - 0 significa 0º campo, 1 significa 1º campo, etc.
        uint256 slot_for_a_field = stdstore
            .target(address(test))
            .sig(test.basicStruct.selector)
            .depth(0)
            .find();

        uint256 slot_for_b_field = stdstore
            .target(address(test))
            .sig(test.basicStruct.selector)
            .depth(1)
            .find();

        assertEq(uint(vm.load(address(test), bytes32(slot_for_a_field))), 1);
        assertEq(uint(vm.load(address(test), bytes32(slot_for_b_field))), 2);
    }
}

// Um contrato de armazenamento complexo
contract Storage {
    struct UnpackedStruct {
        uint256 a;
        uint256 b;
    }

    constructor() {
        map_addr[msg.sender] = 1;
    }

    uint256 public exists = 1;
    mapping(address => uint256) public map_addr;
    // mapping(address => Packed) public map_packed;
    mapping(address => UnpackedStruct) public map_struct;
    mapping(address => mapping(address => uint256)) public deep_map;
    mapping(address => mapping(address => UnpackedStruct)) public deep_map_struct;
    UnpackedStruct public basicStruct = UnpackedStruct({
        a: 1,
        b: 2
    });

    function hidden() public view returns (bytes32 t) {
        // um slot de armazenamento extremamente oculto
        bytes32 slot = keccak256("my.random.var");
        assembly {
            t := sload(slot)
        }
    }
}
```

### stdCheats

Este é um invólucro sobre "cheatcodes" diversos que precisam de invólucros para serem mais amigáveis para desenvolvedores. Atualmente, existem apenas funções relacionadas a `prank`. Em geral, os usuários podem esperar que ETH seja colocado em um endereço em `prank`, mas isso não é verdade por motivos de segurança. Explicitamente, esta função `hoax` deve ser usada apenas para endereços que têm saldos esperados, pois eles serão sobrescritos. Se um endereço já tiver ETH, você deve usar apenas `prank`. Se você quiser alterar esse saldo explicitamente, basta usar `deal`. Se você quiser fazer as duas coisas, `hoax` também é adequado.

#### Exemplo de uso:
```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Herde stdCheats
contract StdCheatsTest is Test {
    Bar test;
    function setUp() public {
        test = new Bar();
    }

    function testHoax() public {
        // chamamos `hoax`, que dá ao endereço de destino
        // eth e depois chama `prank`
        hoax(address(1337));
        test.bar{value: 100}(address(1337));

        // sobrecarregado para permitir que você especifique a quantidade de eth para
        // inicializar o endereço
        hoax(address(1337), 1);
        test.bar{value: 1}(address(1337));
    }

    function testStartHoax() public {
        // chamamos `startHoax`, que dá ao endereço de destino
        // eth e depois chama `startPrank`
        //
        // também é sobrecarregado para que você possa especificar uma quantidade de eth
        startHoax(address(1337));
        test.bar{value: 100}(address(1337));
        test.bar{value: 100}(address(1337));
        vm.stopPrank();
        test.bar(address(this));
    }
}

contract Bar {
    function bar(address expectedSender) public payable {
        require(msg.sender == expectedSender, "!prank");
    }
}
```

### Std Assertions

Expanda as funções de assertivas da biblioteca `DSTest`.

### `console.log`

O uso segue o mesmo formato do [Hardhat](https://hardhat.org/hardhat-network/reference/#console-log).
É recomendado usar `console2.sol` como mostrado abaixo, pois isso mostrará os logs decodificados nas traces do Forge.

```solidity
// importe indiretamente via Test.sol
import "forge-std/Test.sol";
// ou importe diretamente
import "forge-std/console2.sol";
...
console2.log(someValue);
```

Se você precisa de compatibilidade com o Hardhat, você deve usar o `console.sol` padrão em vez disso.
Devido a um bug no `console.sol`, logs que usam os tipos `uint256` ou `int256` não serão decodificados corretamente nas traces do Forge.

```solidity
// importe indiretamente via Test.sol
import "forge-std/Test.sol";
// ou importe diretamente
import "forge-std/console.sol";
...
console.log(someValue);
```
.

