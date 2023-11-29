# Arquitetura Cloud na AWS com Terraform

## Objetivo do projeto

Provisionar uma arquitetura na AWS utilizando o Terraform, que englobe o uso de um Application Load Balancer (ALB), instâncias EC2 com Auto Scaling e um banco de dados RDS.

## Desenho da arquitetura

<img src="/img/Desenho_arquitetura.png">

## Explicando a arquitetura

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

Criamos também uma policy, sendo que a policy é responsável por definir o que o Auto Scaling irá fazer quando a capacidade desejada for maior que a capacidade atual e quando a capacidade desejada for menor que a capacidade atual. No meu caso, defini que quando a capacidade desejada for maior que 70% da capacidade atual, será criado uma nova instância EC2, e quando a capacidade desejada for menor 10% da capacidade atual, a instância será destruída. Outra policy foi a de controle de requisições por segundo, sendo que a policy é responsável por definir o que o Auto Scaling irá fazer quando a quantidade de requisições por segundo for maior que 1000. No meu caso, será criada uma nova instância EC2.

Por fim, fizemos um alarme, sendo que o alarme é responsável por monitorar a capacidade atual e a capacidade desejada, sendo que se a capacidade atual for maior que 70% da capacidade desejada, o alarme irá disparar, e se a capacidade atual for menor que 10% da capacidade desejada, o alarme também irá disparar.

### RDS (Relational Database Service)

O RDS é um serviço que permite a criação de bancos de dados relacionais na AWS, sendo que é possível escolher o tipo de banco de dados, o tipo de instância, a quantidade de memória, a quantidade de processadores, entre outros. O RDS é um serviço muito importante para a criação de uma arquitetura na AWS, pois é nele que será criado o banco de dados que irá armazenar os dados da aplicação.

Assim como em todos os módulos, fizemos um security group para o RDS, sendo que essa seguranca serve para controlar o tráfego de rede permitido para o próprio banco de dados na AWS. Ele define as regras de entrada e saída de tráfego, especificando quais tipos de comunicação são permitidos e de onde podem vir. No meu caso, permiti o apenas portas e protocolos expecifícos, mas para ficar mais fácil o acesso liberei para todos os tipos de entradas e saídas, com o protocolo -1, porta 0 para 0 e o CIDR 0.0.0.0/0.

Para proteger a database, não deixei ele em um IP público e sim privado, tendo um db_subnet_group, com as duas subnets privadas criadas anteriormente, sendo que o db_subnet_group é responsável por definir em quais subnets o banco de dados irá ser criado. Para que o banco de dados possa se comunicar com a internet, foi criada uma route table de rotas da VPC que permite a comunicação entre o banco de dados e a internet.

Partindo para a própria database, criamos um banco de dados MySQL, com o nome "dbfelipe", com o usuário "root" e a senha "root12345", com o tipo de instância db.t2.micro, com o armazenamento de 20GB, com o backup automático habilitado e com o Multi-AZ habilitado, sendo que o Multi-AZ é responsável por criar uma réplica do banco de dados em outra zona de disponibilidade, aumentando a disponibilidade do banco de dados e garantindo a redundância em caso de falhas em uma das zonas de disponibilidade, com um backup retido por 7 dias para garantir a segurança dos dados. Essa base foi conectada com o security group e com o db_subnet_group criados anteriormente.

### Locust

O Locust é uma ferramenta de teste de carga de código aberto, sendo que ele é capaz de simular milhares de usuários simultâneos, sendo que é possível definir o número de usuários, a taxa de usuários, entre outros. O Locust é muito importante para a criação de uma arquitetura na AWS, pois é nele que será testado o desempenho da aplicação. Em resumo isso é uma distribuição de teste de carga usando o framework Locust na AWS.

Primeiramente criamos um security group para o Locust, sendo que essa seguranca serve para controlar o tráfego de rede permitido para o próprio Locust na AWS. Ele define as regras de entrada e saída de tráfego, especificando quais tipos de comunicação são permitidos e de onde podem vir. No meu caso, permiti o apenas portas e protocolos expecifícos, como por exemplo, a porta 8089 e o protocolo HTTP vindos de qualquer lugar, CIDR 0.0.0.0/0. Tomei essa decisão pois o Locust é um serviço que precisa estar acessível para a internet, sendo que ele é o ponto de entrada da aplicação, recebendo as requisições e as distribui para as instâncias EC2.

Depois criei um loadtest distributed que define a quantidade de workers para o teste de distribuição de carga. No meu caso, criei 2 workers, sendo que cada worker é responsável por simular 1000 usuários simultâneos, sendo que o teste de carga irá simular 2000 usuários simultâneos. O loadtest distributed foi linkado ao security group criado anteriormente e a um IP público, sendo que o IP público é necessário para que o Locust possa ser acessado pela internet. Ainda nesse module são criados
o mestre e os workers, sendo que o mestre é responsável por receber as requisições e distribuir para os workers, e os workers são responsáveis por simular os usuários simultâneos. Os workers estão ligados ao IP do mestre.

Tudo isso está ligado a uma arquivo em python que ele define um comportamento para esse usuário durante o teste. Nesse caso específico, quando esse usuário é acionado, ele faz uma requisição GET para a raiz do site especificado pela URL base do Locust (self.client.get("/")). Em outras palavras, ele simula o comportamento de acessar a página inicial do site.

### S3 (Simple Storage Service)

O S3 é um serviço que permite o armazenamento de arquivos na AWS, sendo que é possível armazenar qualquer tipo de arquivo, como por exemplo, imagens, vídeos, documentos, entre outros. O S3 é um serviço muito importante para a criação de uma arquitetura na AWS, pois é nele que serão armazenados os arquivos da aplicação.

Primeiramente criamos um bucket, sendo que o bucket é o local onde os arquivos serão armazenados, sendo que é possível definir o nome do bucket, a região onde ele será criado, entre outros. No meu caso, criei um bucket com o nome "felipe-bucket", com a região us-east-1 (N. Virginia), sendo que a região us-east-1 é a região padrão da conta utilizada.

### Aplicação

Peguei a aplicação de um repositório e implementei ela no projeto, sendo que a aplicação é uma Fast-API com CRUD, sendo que ela é capaz de criar, ler, atualizar e deletar dados de um banco de dados MySQL. A aplicação é muito importante para a criação de uma arquitetura na AWS, pois é nela que será criada e executada.

### Melhorias futuras

1. Segurança

- Security Groups Mais Estruturados: Em vez de permitir todos os tipos de tráfego, considere restringir por IPs específicos, reduzindo a superfície de ataque.
- Criptografia de Dados Sensíveis: Para dados confidenciais, como senhas no código ou na base de dados, considere implementar criptografia.

2.  Resiliência e Backup

- Monitoramento Avançado e Recuperação de Falhas: Integração de sistemas de monitoramento mais avançados, como CloudWatch Logs e EventBridge, para uma detecção e resposta mais rápidas a falhas.
- Aprimoramento de Backup e Restauração: Ajustar a frequência de backups, explorar snapshots EBS regulares e avaliar a eficiência do período de retenção dos backups.

entre outros ...

## Custos

## Script de instalação da aplicação

Primeiramente siga as intruções para instalar o Terraform em sua máquina: https://learn.hashicorp.com/tutorials/terraform/install-cli

Com o terraform instalado, instale o AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Crie uma conta na AWS, configure as credenciais e utilize as credenciais IAM para autenticar o terraform no provedor AWS.

Com tudo isso pronto, clone o repositório e execute o seguinte comando para iniciar o terraform:

```
terraform init -upgrade
```

```
terraform plan
```

```
terraform apply -auto-approve
```

para destruir a infraestrutura criada, execute o seguinte comando:

```
terraform destroy -auto-approve
```

## Checando o funcionamento do projeto na AWS

Para checar o funcionamento do projeto na AWS, acesse o painel da AWS e vá até o serviço EC2, e verifique se as instâncias EC2 estão sendo criadas e destruídas de acordo com a capacidade desejada e a capacidade atual.

Vá até o serviço RDS e verifique se o banco de dados está sendo criado e se está sendo criado uma réplica do banco de dados em outra zona de disponibilidade.

Vá até o serviço S3 e verifique se o bucket está sendo criado.

Vá até o serviço CloudWatch e verifique se o alarme está sendo disparado de acordo com a capacidade desejada e a capacidade atual.

Vá até Load Balancer e verifique se o ALB está sendo criado e se está distribuindo o tráfego para as instâncias EC2. Clique no DNS do ALB e verifique se a aplicação está funcionando corretamente. O link do ALB é um dos outputs do terraform.
Ainda dentro do load balancer, verifique se o target grupo linkado a ele está saudável.

Teste o auto scaling, destruindo uma máquina e verificando se o auto scaling cria uma nova máquina para substituí-la.

Para testar o lucost tem q acessar o link: http://<ip_publico_locust>:8089, sel=ndo ele um dos outputs do terraform.
Com isso vai pegar o link do crud e colocar no site do locust, e vai fazer o teste de carga com uma quantidade alta de usuários, exemplo (1300). Assim quando ele recebre muitos requests ele vai criar mais instâncias para atender a demanda.
