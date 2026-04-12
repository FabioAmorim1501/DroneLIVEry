unit DroneDelivery.Server.Controller.Rotas;

interface

uses
  Horse, System.JSON, System.SysUtils;

procedure Registry;

implementation

procedure GetRotasCalcular(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // TODO: Injetar Service de Rotas e executar o DDP (Drone Delivery Problem)
  Res.Send('{"status": "Rotas Calculadas", "rotas": []}');
end;

procedure Registry;
begin
  THorse.Post('/rotas/calcular', GetRotasCalcular);
  // Opcionalmente .Get com query params, mas POST é melhor devido aos dados das paradas/pedidos.
end;

end.
