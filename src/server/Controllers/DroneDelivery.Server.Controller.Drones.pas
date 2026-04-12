unit DroneDelivery.Server.Controller.Drones;

interface

uses
  Horse, System.JSON, System.SysUtils;

procedure Registry;

implementation

procedure GetDrones(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // TODO: Buscar dos repositórios via Service e serializar para JSON
  Res.Send('{"message": "Listagem de Drones"}');
end;

procedure GetDroneById(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('{"message": "Detalhes do Drone ' + Req.Params['id'] + '"}');
end;

procedure PostDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('{"message": "Drone Criado"}').Status(201);
end;

procedure Registry;
begin
  THorse.Get('/drones', GetDrones);
  THorse.Get('/drones/:id', GetDroneById);
  THorse.Post('/drones', PostDrone);
end;

end.
