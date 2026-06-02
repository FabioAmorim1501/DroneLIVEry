unit DroneDelivery.Server.Controller.Rotas;

interface

uses
  Horse, System.JSON, System.SysUtils;

procedure Registry;

implementation

procedure GetHealth(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  try
    LObj.AddPair('status', 'ok');
    Res.Status(200).ContentType('application/json').Send(LObj.ToJSON);
  finally
    LObj.Free;
  end;
end;

procedure PostCalculateRoutes(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LObj, LRoute: TJSONObject;
  LWaypoints: TJSONArray;
begin
  // TODO: Executar rota haversine e procurar drone
  LObj := TJSONObject.Create;
  try
    LRoute := TJSONObject.Create;
    LWaypoints := TJSONArray.Create;
    LRoute.AddPair('waypoints', LWaypoints);
    LObj.AddPair('route', LRoute);
    Res.Status(200).ContentType('application/json').Send(LObj.ToJSON);
  finally
    LObj.Free;
  end;
end;

procedure GetRoutesDistance(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LObj: TJSONObject;
begin
  // TODO: Calcular distancia via parametro lon1 lat1 lon2 lat2
  LObj := TJSONObject.Create;
  try
    LObj.AddPair('distance_km', TJSONNumber.Create(0));
    Res.Status(200).ContentType('application/json').Send(LObj.ToJSON);
  finally
    LObj.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/health', GetHealth);
  THorse.Post('/routes/calculate', PostCalculateRoutes);
  THorse.Get('/routes/distance', GetRoutesDistance);
end;

end.
