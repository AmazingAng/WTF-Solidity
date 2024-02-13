# WTF Introdução Simples ao Solidity: 21. Chamando Outros Contratos

Recentemente, tenho revisitado o Solidity para consolidar alguns detalhes e escrever um "WTF Introdução Simples ao Solidity" para iniciantes (os programadores mais avançados podem procurar outros tutoriais), atualizando de 1 a 3 lições por semana.

Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

Comunidade: [Discord](https://discord.gg/5akcruXrsk) | [Grupo do WeChat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link) | [Website do WTF Academy](https://wtf.academy)

Todo o código e tutoriais são de código aberto no github: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTF-Solidity)

## Chamando Contratos Já Desdobrados

Em `Solidity`, um contrato pode chamar as funções de outro contrato, o que é útil ao desenvolver DApps mais complexos. Neste tutorial, vou explicar como chamar contratos que já estão desdobrados, conhecendo o código (ou interface) do contrato e seu endereço.

## Contrato Alvo

Primeiro, vamos escrever um contrato simples chamado `OtherContract`, que será chamado por outros contratos.

```solidity
contract OtherContract {
    uint256 private _x = 0; // Variável de estado _x
    // Evento acionado ao receber ETH, registrando o amount e gas
    event Log(uint amount, uint gas);
    
    // Retorna o saldo ETH do contrato
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // Função ajustável para alterar o valor da variável de estado _x e enviar ETH para o contrato (pagável)
    function setX(uint256 x) external payable{
        _x = x;
        // Se ETH for enviado, o evento Log é acionado
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // Lê o valor de _x
    function getX() external view returns(uint x){
        x = _x;
    }
}
```

Este contrato contém uma variável de estado `_x`, um evento `Log` que é acionado ao receber ETH e três funções:

- `getBalance()`: Retorna o saldo ETH do contrato.
- `setX()`: Função `external payable` que pode definir o valor de `_x` e enviar ETH para o contrato.
- `getX()`: Retorna o valor de `_x`.

## Chamando o Contrato `OtherContract`

Podemos criar uma referência ao contrato utilizando o nome do contrato e seu endereço: `_Nome(_Endereço)`, onde `_Nome` é o nome do contrato, que deve corresponder ao nome definido no código (ou interface) do contrato, e `_Endereço` é o endereço do contrato. Em seguida, podemos chamar as funções do contrato utilizando essa referência: `_Nome(_Endereço).f()`, onde `f()` é a função que desejamos chamar.

A seguir, apresento quatro exemplos de como chamar contratos. Após compilar os contratos no Remix, implantei os contratos `OtherContract` e `CallContract`:

### 1. Passando o Endereço do Contrato

Podemos passar o endereço do contrato como parâmetro da função e, em seguida, utilizar esse endereço para criar uma referência ao contrato alvo e chamar a função desejada. Vamos utilizar o exemplo de chamar a função `setX` do contrato `OtherContract` em um novo contrato.

```solidity
function callSetX(address _Address, uint256 x) external{
    OtherContract(_Address).setX(x);
}
```

Copie o endereço do contrato `OtherContract`, insira-o como argumento da função `callSetX` e confirme a chamada. Em seguida, chame a função `getX` do contrato `OtherContract` para verificar se o valor de `x` mudou para 123.

### 2. Passando a Variável do Contrato

Podemos passar diretamente a referência ao contrato como parâmetro da função. No exemplo seguinte, implementamos a chamada da função `getX()` do contrato alvo.

```solidity
function callGetX(OtherContract _Address) external view returns(uint x){
    x = _Address.getX();
}
```

Copie o endereço do contrato `OtherContract`, insira-o como argumento da função `callGetX` e confirme a chamada. Em seguida, verifique se o valor de `x` foi obtido com sucesso.

### 3. Criando uma Variável de Contrato

Podemos criar uma variável do tipo do contrato desejado e utilizá-la para chamar a função alvo. No exemplo a seguir, armazenamos a referência do contrato `OtherContract` na variável `oc`:

```solidity
function callGetX2(address _Address) external view returns(uint x){
    OtherContract oc = OtherContract(_Address);
    x = oc.getX();
}
```

Copie o endereço do contrato `OtherContract`, insira-o como argumento da função `callGetX2` e confirme a chamada. Verifique se o valor de `x` foi obtido com sucesso.

### 4. Chamar um Contrato e Enviar ETH

Se a função do contrato alvo for `payable`, podemos transferir ETH para o contrato chamando essa função da seguinte maneira: `_Nome(_Endereço).f{value: _Valor}()`, onde `_Nome` é o nome do contrato, `_Endereço` é o endereço do contrato, `f` é o nome da função alvo e `_Valor` é a quantidade de ETH a ser transferida (em wei).

No contrato a seguir, utilizamos a chamada da função `setX` para transferir ETH para o contrato alvo.

```solidity
function setXTransferETH(address otherContract, uint256 x) payable external{
    OtherContract(otherContract).setX{value: msg.value}(x);
}
```

Copie o endereço do contrato `OtherContract`, insira-o como argumento da função `setXTransferETH` e insira 10 ETH para transferência. Em seguida, verifique o saldo ETH do contrato alvo e observe as alterações através do evento `Log`.

## Conclusão

Neste tutorial, aprendemos como criar uma referência a um contrato utilizando o seu código (ou interface) e endereço, a fim de chamar as suas funções.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->