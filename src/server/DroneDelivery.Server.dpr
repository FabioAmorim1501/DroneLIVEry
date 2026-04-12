program DroneDelivery.Server;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.CORS,
  Horse.Jhonson, // Equivalente moderno ao JHose (JSON middleware para Horse)
  DataSet.Serialize,
  DroneDelivery.Server.Controller.Drones in 'Controllers\DroneDelivery.Server.Controller.Drones.pas',
  DroneDelivery.Server.Controller.Rotas in 'Controllers\DroneDelivery.Server.Controller.Rotas.pas',
  DroneDelivery.Server.Provider.Connection in 'Providers\DroneDelivery.Server.Provider.Connection.pas';

begin
  // Middlewares
  THorse.Use(Cors);
  THorse.Use(Jhonson());

  // Registrar Controllers / Endpoints
  DroneDelivery.Server.Controller.Drones.Registry;
  DroneDelivery.Server.Controller.Rotas.Registry;

  Writeln('Servidor DroneDelivery rodando na porta 9000...');
  THorse.Listen(9000);
end.
