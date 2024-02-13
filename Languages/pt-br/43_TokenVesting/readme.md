# WTF Introdução Simples à Solidity: 43. Liberação Linear

Recentemente, tenho revisado meus conhecimentos em Solidity e consolidando alguns detalhes, e escrevendo um "WTF Introdução Simples à Solidity" para ajudar os novatos (os programadores experientes podem procurar outro tutorial), com atualizações semanais de 1 a 3 aulas.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WhatsApp](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website wtf.academy](https://wtf.academy)

Todo o código e os tutoriais estão disponíveis no Github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

---

Nesta aula, vamos falar sobre termos de titularidade de tokens e escrever um contrato de token ERC20 para liberação linear. O código foi simplificado do contrato `VestingWallet` da `OpenZeppelin`.

## Termos de Titularidade de Tokens

![Deploy](./img/43-1.jpeg)

No mundo financeiro tradicional, algumas empresas oferecem ações para funcionários e gestores. No entanto, a liberação de grandes quantidades de ações ao mesmo tempo pode gerar uma pressão de venda a curto prazo, afetando o preço das ações. Portanto, as empresas costumam introduzir um período de titularidade para retardar a posse dos ativos prometidos. Da mesma forma, no ecossistema blockchain, empresas iniciantes do Web3 distribuem tokens para suas equipes e também vendem tokens a baixo custo para investidores e em rodadas privadas. Se eles levarem esses tokens de baixo custo para exchanges simultaneamente para obter lucro, o preço do token será impactado, e os investidores diretos se tornarão compradores. Portanto, as equipes de projeto geralmente estabelecem termos de titularidade de tokens (token vesting), liberando gradualmente os tokens durante o período de titularidade para reduzir a pressão de venda e impedir que as equipes e os investidores obtenham lucro muito cedo.

## Liberação Linear

A liberação linear significa que os tokens são liberados de maneira uniforme durante o período de titularidade. Por exemplo, se um investidor privado detém 365.000 tokens `ICU`, com um período de titularidade de 1 ano (365 dias), serão liberados 1.000 tokens por dia.

A seguir, vamos escrever um contrato `TokenVesting` que bloqueia e libera tokens ERC20 de forma linear. A lógica é simples:

- O projeto especifica o beneficiário, o início do período de titularidade e o beneficiário.
- O projeto transfere os tokens ERC20 bloqueados para o contrato `TokenVesting`.
- O beneficiário pode chamar a função `release` para retirar os tokens liberados do contrato.

### Eventos

Existem 1 evento no contrato de liberação linear.

- `ERC20Released`: Evento de liberação, acionado quando o beneficiário retira os tokens liberados.

```solidity
contract TokenVesting {
    // Eventos
    event ERC20Released(address indexed token, uint256 amount); // Evento acionado ao retirar os tokens
```

### Variáveis de Estado

Existem 4 variáveis de estado no contrato de liberação linear.

- `beneficiary`: Endereço do beneficiário.
- `start`: Timestamp de início do período de titularidade.
- `duration`: Duração do período de titularidade em segundos.
- `erc20Released`: Mapeamento de endereço de token para quantidade liberada, registrando a quantidade de tokens liberada ao beneficiário.

```solidity
    // Variáveis de Estado
    mapping(address => uint256) public erc20Released; // Mapeamento de endereço de token para quantidade liberada
    address public immutable beneficiary; // Endereço do beneficiário
    uint256 public immutable start; // Timestamp de início
    uint256 public immutable duration; // Duração
```

### Funções

Existem 3 funções no contrato de liberação linear.

- Construtor: Inicializa o endereço do beneficiário, a duração do período de titularidade e o timestamp de início. Os parâmetros são o endereço do beneficiário `beneficiaryAddress` e a duração do período `durationSeconds`. Para facilitar, o timestamp de início é o timestamp de bloco atual `block.timestamp`.
- `release()`: Função para retirar tokens, transfere os tokens liberados para o beneficiário. Chama a função `vestedAmount()` para calcular a quantidade de tokens liberados, emite o evento `ERC20Released` e, em seguida, transfere os tokens para o beneficiário. O parâmetro é o endereço do token `token`.
- `vestedAmount()`: Calcula a quantidade de tokens liberados com base na fórmula de liberação linear. Os desenvolvedores podem personalizar esse cálculo modificando a função. Os parâmetros são o endereço do token `token` e o timestamp de consulta `timestamp`.

```solidity
    /**
     * @dev Inicializa o endereço do beneficiário, o período de liberação (em segundos) e o timestamp de início (timestamp atual do bloco).
     */
    constructor(
        address beneficiaryAddress,
        uint256 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    /**
     * @dev O beneficiário retira os tokens liberados.
     * Chama a função vestedAmount() para calcular a quantidade de tokens a serem retirados e transfere esses tokens ao beneficiário.
     * Emite o evento {ERC20Released}.
     */
    function release(address token) public {
        // Calcula a quantidade de tokens a serem retirados usando a função vestedAmount()
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        // Atualiza a quantidade de tokens liberados
        erc20Released[token] += releasable; 
        // Transfere os tokens para o beneficiário
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    /**
     * @dev Calcula a quantidade de tokens liberados com base na fórmula de liberação linear. Os desenvolvedores podem personalizar essa função.
     * @param token: Endereço do token
     * @param timestamp: Timestamp de consulta
     */
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        // Calcula o total de tokens recebidos pelo contrato (saldo atual + liberados)
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        // Calcula a quantidade de tokens liberados com base na fórmula de liberação linear
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
```

## Demonstração no `Remix`

### 1. Implemente o contrato `ERC20` da [Aula 31](../31_ERC20/readme.md) e crie `10000` tokens para si mesmo.

### 2. Implemente o contrato `TokenVesting` de liberação linear, com você mesmo como beneficiário e um período de titularidade de `100` segundos.

### 3. Transfira `10000` tokens `ERC20` para o contrato de liberação linear.

### 4. Chame a função `release()` para retirar os tokens.

## Conclusão

O desbloqueio em massa de tokens pode gerar uma grande pressão de venda nos preços, enquanto os termos de titularidade de tokens podem reduzir essa pressão e evitar que as equipes e investidores saiam muito cedo. Nesta aula, apresentamos os termos de titularidade de tokens e escrevemos um contrato para liberação linear de tokens ERC20.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->