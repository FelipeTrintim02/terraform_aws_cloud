# Arquitetura Cloud na AWS com Terraform

## Objetivo do projeto
Provisionar uma arquitetura na AWS utilizando o Terraform, que englobe o uso de um Application Load Balancer (ALB), instâncias EC2 com Auto Scaling e um banco de dados RDS.

## Explicando cada parte da aquitetura implementada e as motivações de cada escolha

### VPC (Virtual Private Cloud)
    A VPC é um serviço que permite a criação de uma rede virtual na AWS, onde é possível definir um range de IPs, criar subnets, configurar rotas, entre outros. A VPC é o primeiro passo para a criação de uma arquitetura na AWS, pois é nela que serão criados os outros recursos.

    No caso do projeto utilizamos a região us-east-1 (N. Virginia) por ter um preço mais acessível e por ser a região padrão da conta utilizada. 

    Adotamos uma rede com CIDR 10.0.0.0;16, que permite a criação de até 65.536 IPs, tendo muita flexibilidade para a criação de subnets e instâncias, podendo ser expandida facilmente caso necessário.

    Para a criação das subnets, optamos por criar 2 subnets públicas e 2 subnets privadas, sendo que as subnets públicas são subnets que possuem acesso à internet e as subnets privadas não possuem acesso à internet.

    As subnets públicas são subnets que possuem acesso à internet, sendo que as instâncias criadas nelas podem ser acessadas diretamente pela internet. Já as subnets privadas não possuem acesso à internet, sendo que as instâncias criadas nelas não podem ser acessadas diretamente pela internet, sendo necessário o uso de um NAT Gateway para que as instâncias privadas possam acessar a internet.

    Para a criação das subnets públicas, optamos por criar uma subnet para cada zona de disponibilidade (AZ) da região us-east-1, sendo que cada AZ possui uma subnet com CIDR 10.0.1.0/24 com a zona "us-east-1a" com 32 IPs e outra subnet com CIDR 10.0.2.0/24 com a zona "us-east-1b" também com 32 IPs. Para a criação das subnets privadas, optamos por criar uma subnet para cada zona de disponibilidade (AZ) da região us-east-1, sendo que cada AZ possui uma subnet com CIDR 10.0.101.0/24 com a zona "us-east-1a" com 32 IPs e outra subnet com CIDR 10.0.102.0/24 com a zona "us-east-1b" também com 32 IPs.

    Os IPs públicos necessitam de um gate para poderem se comunicar com a internet, sendo que para isso foi criado um Internet Gateway (IGW) que permite a comunicação entre a VPC e a internet. Para que as subnets públicas possam se comunicar com a internet, foi criada uma route table de rotas da VPC que permite a comunicação entre a VPC e a internet.

    Já os IPs privados necessitam de um gate para primeiro conseguirem se comunicar com os IPs públicos e depois com a internet, sendo criado um NAT Gateway que permite a comunicação entre a internet, IPs públicos e IPs privados. Para que as subnets privadas possam se comunicar com os IPs públicos e com a internet, foi criada uma route table de rotas da VPC que permite a comunicação entre eles.


### ALB (Application Load Balancer)
    O ALB é um serviço que permite a distribuição de tráfego entre instâncias EC2, sendo que ele é capaz de distribuir o tráfego entre instâncias EC2 de acordo com o tipo de requisição, sendo que é possível configurar o ALB para que ele distribua o tráfego de acordo com o tipo de requisição, como por exemplo, distribuir o tráfego de requisições HTTP para uma instância EC2 e o tráfego de requisições HTTPS para outra instância EC2.

    Primeiramente criamos um security group para o ALB, sendo que essa seguranca serve para controlar o tráfego de rede permitido para o próprio balanceador de carga na AWS. Ele define as regras de entrada e saída de tráfego, especificando quais tipos de comunicação são permitidos e de onde podem vir. No meu caso, permiti o apenas portas e protocolos expecifícos, como por exemplo, a porta 80 e o protocolo HTTP e a porta 443 e o protocolo HTTPS vindos de qualquer lugar, CIDR 0.0.0.0/0. Tomei essa decisão pois o ALB é um serviço que precisa estar acessível para a internet, sendo que ele é o ponto de entrada da aplicação, recebendo as requisições e as distribui para as instâncias EC2.

    Depois criamos o próprio Application Load Balancer, usamos o security group criado anteriormente, configuramos o ALB para ser externo sendo útil pois permite que usuários externos acessem as instâncias EC2 por meio do balanceamento de carga. Utilizamos também somente subnets públicas, distribuíndo a capacidade de processamento do ALB em diferentes zonas de disponibilidade, aumentando a disponibilidade do aplicativo e garantindo a redundância em caso de falhas em uma das sub-redes. O load balancer também depende de um gateway, evitando problemas de conectividade com a internet, sendo que foi utilizado o Internet Gateway criado anteriormente.

    Logo em seguida criamos um Target group que é responsável por direcionar o tráfego do ALB para instâncias EC2 específicas. Associamos ele ao VPC criado anteriormente, especificamos o protocolo HTTP e a porta 80, pois o ALB irá receber requisições HTTP e irá distribuir para as instâncias EC2. Também foi criado um health check para o target group, sendo que o health check é responsável por verificar se as instâncias EC2 estão saudáveis, sendo que se uma instância EC2 não estiver saudável, o ALB não irá distribuir o tráfego para ela.

    Por fim, criamos um listener para o ALB, sendo que o listener é responsável por receber as requisições e distribuir para as instâncias EC2. Configuramos o listener para receber requisições HTTP na porta 80 e distribuir para o target group criado anteriormente.

### EC2 (Elastic Compute Cloud) com Auto Scaling
    O EC2 é um serviço que permite a criação de instâncias de máquinas virtuais na AWS, sendo que é possível escolher o sistema operacional, a quantidade de memória, a quantidade de processadores, entre outros. O EC2 é um serviço muito importante para a criação de uma arquitetura na AWS, pois é nele que serão criadas as instâncias que irão executar a aplicação.

    O Auto Scaling é um serviço que permite a criação de um grupo de instâncias EC2, sendo que é possível definir uma capacidade desejada, uma capacidade mínima e uma capacidade máxima, sendo que ele criará instâncias EC2 de acordo com a capacidade desejada, sendo que se a capacidade desejada for maior que a capacidade atual, o Auto Scaling irá criar novas instâncias EC2, e se a capacidade desejada for menor que a capacidade atual, irá destruir instâncias EC2. O Auto Scaling é muito útil pois permite que a aplicação tenha uma capacidade de processamento dinâmica, sendo que se a aplicação estiver recebendo muitas requisições, ele irá criar novas instâncias EC2 para atender a demanda, e se a aplicação estiver recebendo poucas requisições, o Auto Scaling irá destruir instâncias EC2 para economizar recursos.

    Primeiramente criamos um security group para as instâncias EC2, sendo que essa seguranca serve para controlar o tráfego de rede permitido para as instâncias EC2 na AWS. Ele define as regras de entrada e saída de tráfego, especificando quais tipos de comunicação são permitidos e de onde podem vir. No meu caso, permiti o apenas portas e protocolos expecifícos, como por exemplo, a porta 80 e o protocolo HTTP e a porta 22 e o protocolo SSH vindos de qualquer lugar, CIDR 0.0.0.0/0. Tomei essa decisão pois as instâncias EC2 precisam estar acessíveis para a internet, sendo que elas são o ponto de entrada da aplicação, recebendo as requisições do ALB e respondendo elas.

    Depois criamos um launch template, sendo que o launch template é um modelo que contém as configurações necessárias para a criação de uma instância EC2, como por exemplo, o tipo de instância, o sistema operacional, a quantidade de memória, a quantidade de processadores, entre outros. O launch template é muito útil pois permite a criação de várias instâncias EC2 com as mesmas configurações, sendo que é possível alterar as configurações do launch template e todas as instâncias EC2 criadas com ele serão alteradas. No meu caso, criei um launch template com o sistema operacional Ubuntu Server 20.04 LTS (HVM), co um tipo de instância t2.micro, sendo que o launch template é configurado para receber o script de instalação da aplicação, que nesse caso é uma Fast-API com CRUD, e executá-lo na inicialização da instância EC2. Associamos também o security group criado anteriormente e a um IP público, sendo que o IP público é necessário para que a instância EC2 possa ser acessada pela internet.

    Logo em seguida o Auto scaling group foi criado com uma capacidade desejada de 3 instâncias EC2, com no mínimo 2 e no máximo 6. Linkamos ele a um IP público, ao target group e ao launch template na versão mais recente. Para checar a saúde das instâncias EC2, foi criado um health check, sendo que o health check é responsável por verificar se as instâncias EC2 estão saudáveis, sendo que se uma instância EC2 não estiver saudável, o Auto Scaling irá destruir ela e criar uma nova instância EC2 para substituí-la.

    Criamos também uma policy, sendo que a policy é responsável por definir o que o Auto Scaling irá fazer quando a capacidade desejada for maior que a capacidade atual e quando a capacidade desejada for menor que a capacidade atual. No meu caso, defini que quando a capacidade desejada for maior que 70% da capacidade atual, será criado uma nova instância EC2, e quando a capacidade desejada for menor 10% da capacidade atual, a instância será destruída.

    Por fim, fizemos um alarme, sendo que o alarme é responsável por monitorar a capacidade atual e a capacidade desejada, sendo que se a capacidade atual for maior que 70% da capacidade desejada, o alarme irá disparar, e se a capacidade atual for menor que 10% da capacidade desejada, o alarme também irá disparar.

### RDS (Relational Database Service)