unit DroneDelivery.Server.Controller.Rotas;

interface

uses
  Horse, System.JSON, System.SysUtils;

procedure Registry;

implementation

procedure GetHealth(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('{"status": "ok"}').Status(200);
end;

procedure PostCalculateRoutes(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // TODO: Executar rota haversine e procurar drone
  Res.Send('{"route": {"waypoints": []}}');
end;

procedure GetRoutesDistance(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // TODO: Calcular distancia via parametro lon1 lat1 lon2 lat2
  Res.Send('{"distance_km": 0}');
end;

procedure Registry;
begin
  THorse.Get('/health', GetHealth);
  THorse.Post('/routes/calculate', PostCalculateRoutes);
  THorse.Get('/routes/distance', GetRoutesDistance);
end;

end.
