# Depuração de Transações OnChain: 6. Análise do Projeto CirculateBUSD Rugpull, Perda de $2,27 Milhões!

Autor: [Numen Cyber Technology](https://twitter.com/numencyber)

12 de janeiro de 2023, às 07:22:39 AM +UTC, de acordo com o monitoramento on-chain da NUMEN, o projeto CirculateBUSD foi drenado pelo criador do contrato, causando uma perda de 2,27 milhões de dólares.

A transferência de fundos deste projeto ocorre principalmente porque o administrador chama a função CirculateBUSD.startTrading, e o parâmetro principal de julgamento em startTrading é o valor retornado pelo contrato SwapHelper.TradingInfo, que não é de código aberto, definido pelo administrador, e em seguida chama SwapHelper.swaptoToken para transferir os fundos.

Transação: [https://bscscan.com/tx/0x3475278b4264d4263309020060a1af28d7be02963feaf1a1e97e9830c68834b3](https://bscscan.com/tx/0x3475278b4264d4263309020060a1af28d7be02963feaf1a1e97e9830c68834b3)

<div align=center>
<img src="https://miro.medium.com/max/1400/1*fLhvqu5spyN0EIycnFNqiw.png" alt="Capa" width="80%"/>
</div>

**Análise:**
=============

Primeiramente, é chamada a função startTrading do contrato ([https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff](https://bscscan.com/address/0x9639d76092b2ae074a7e2d13ac030b4b6a0313ff)), e dentro da função é chamada a função TradingInfo do contrato SwapHelper, com os seguintes detalhes. O código é o seguinte.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*2LithcaYFRGcqls5IY_83g.png" alt="Capa" width="80%"/>
</div>

---

<div align=center>
<img src="https://miro.medium.com/max/1400/1*XbJHPldO3T-9frrr0SQrHA.png" alt="Capa" width="80%"/>
</div>

A figura acima é a pilha de chamadas da transação. Combinando com o código, podemos ver que o TradingInfo faz apenas algumas chamadas estáticas, o problema chave não está nesta função. Continuando com a análise, encontramos que a pilha de chamadas corresponde à operação de aprovação e safeapprove. Em seguida, é chamada a função swaptoToken do contrato SwapHelper, que foi encontrada como uma função chave em combinação com a pilha de chamadas, e a transação de transferência foi executada nesta chamada. O contrato SwapHelper não é de código aberto, como encontrado nas informações on-chain no seguinte endereço.

[https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code](https://bscscan.com/address/0x112f8834cd3db8d2dded90be6ba924a88f56eb4b#code)

Tentando reverter a análise, primeiro localizamos a assinatura da função 0x63437561.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*i7kEvPo_8gYbNs9UGlo-KA.png" alt="Capa" width="80%"/>
</div>

Em seguida, localizamos esta função após descompilar e tentamos encontrar palavras-chave como transfer porque você vê que a pilha de chamadas aciona uma transferência.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*n8BEIqfn0tZ6plky2MFd7w.png" alt="Capa" width="80%"/>
</div>

Localizamos então este trecho da função, primeiro stor\_6\_0\_19, e lemos essa parte primeiro.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*ZGTqmc1sIz2_onKUT6-56Q.png" alt="Capa" width="80%"/>
</div>

Neste ponto, obtivemos o endereço de transferência, 0x0000000000000000000000005695ef5f2e997b2e142b38837132a6c3ddc463b7, que foi encontrado ser o mesmo endereço de transferência da pilha de chamadas.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*v37FEiN6L-0Nwn5OtbDgxQ.png" alt="Capa" width="80%"/>
</div>

Quando analisamos cuidadosamente os ramos if e else desta função, descobrimos que se a condição if for atendida, será feita uma redenção normal. Porque através do slot para obter stor5 é 0x00000000000000000000000010ed43c718714eb63d5aa57b78b54704e256024e, este contrato é pancakerouter. A função backdoor está no ramo else, desde que os parâmetros passados e o valor armazenado no slot7 sejam iguais, será acionada.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*xlYEmp6nsdLA85FUmANxfw.png" alt="Capa" width="80%"/>
</div>

A função abaixo é para modificar o valor da posição do slot 7, e a permissão de chamada é de propriedade apenas do proprietário do contrato.

<div align=center>
<img src="https://miro.medium.com/max/1400/1*lHLaCA9HM1HtmL3pXYxltw.png" alt="Capa" width="80%"/>
</div>

Toda a análise acima é suficiente para determinar que este é um evento de execução lateral do projeto.

Resumo
=======

A Numen Cyber Labs lembra aos usuários que, ao fazer investimentos, é necessário realizar auditorias de segurança nos contratos do projeto. Pode haver funções no contrato não verificado onde a autoridade do projeto é muito grande ou afeta diretamente a segurança dos ativos do usuário. Os problemas deste projeto são apenas a ponta do iceberg de todo o ecossistema blockchain. Quando os usuários investem e as partes do projeto desenvolvem projetos, é necessário realizar auditorias de segurança no código.

A Numen Cyber Labs está comprometida em proteger a segurança ecológica do Web3. Fique atento para mais notícias e análises sobre ataques.

<!-- This file was translated using AI by repo_ai_translate. For more information, visit https://github.com/marcelojsilva/repo_ai_translate -->