# DroneDelivery

Projeto base para sistema de rotas e entrega por Drones utilizando Clean Architecture, Backend Horse REST API, e Frontend Multi-device FMX.

## Estrutura do Projeto

* `/src/common`: Classes de Domínio, Entidades e DTOs (Data Transfer Objects). Compartilhado entre Server e Client.
* `/src/server`: Backend MVC utilizando framework **Horse** e conexão **FireDAC** PostgreSQL.
* `/src/client`: Frontend **FMX** utilizando padrão arquitetural **MVVM** com chamadas via RESTRequest4Delphi.
* `/sql`: Scripts de banco de dados.

## Backend Rest API (porta 9000)

**Endpoints:**
* `GET /drones` - Listar todos os Drones.
* `GET /drones/:id` - Buscar um Drone.
* `POST /drones` - Cadastrar Drone.
* `POST /rotas/calcular` - Baseado no Drone Delivery Problem, calcula payload e restrições.

## Setup no RAD Studio / Delphi

1. Instale o pacote `boss` caso queira usar gerenciamento de dependências.
2. `boss install` na raiz de server e client para baixar (Horse, Jhonson, DataSet-Serialize, e RESTRequest4Delphi).
3. Abra as units `.dpr` em `/src/server/` e `/src/client/`. (Isto criará automaticamente arquivos de projetos limpos `.dproj` no Delphi moderno).
4. Configure sua string de conexão no `Provider.Connection.pas`.
