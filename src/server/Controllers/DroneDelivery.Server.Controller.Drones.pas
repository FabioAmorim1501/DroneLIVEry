unit DroneDelivery.Server.Controller.Drones;

interface

uses
  Horse, System.JSON, System.SysUtils,
  DroneDelivery.Domain.Entities,
  DroneDelivery.Server.Repository.Drone;

procedure Registry;

implementation

function GetJsonDouble(Obj: TJSONObject; const Key: string; Def: Double = 0): Double;
var Val: TJSONValue;
begin
  Val := Obj.GetValue(Key);
  if Assigned(Val) and (Val is TJSONNumber) then Result := (Val as TJSONNumber).AsDouble
  else Result := Def;
end;

function GetJsonString(Obj: TJSONObject; const Key: string; Def: string = ''): string;
var Val: TJSONValue;
begin
  Val := Obj.GetValue(Key);
  if Assigned(Val) and (Val is TJSONString) then Result := Val.Value
  else Result := Def;
end;

procedure GetDrones(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryDrone;
  LList: TArray<TDroneEntity>;
  LArray: TJSONArray;
  I: Integer;
  LObj: TJSONObject;
begin
  LRepo := TRepositoryDrone.Create;
  try
    LList := LRepo.GetAll;
    LArray := TJSONArray.Create;
    for I := 0 to High(LList) do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LList[I].Id);
      LObj.AddPair('name', LList[I].Nome);
      LObj.AddPair('max_payload_kg', TJSONNumber.Create(LList[I].PayloadMaximo));
      LObj.AddPair('max_range_km', TJSONNumber.Create(LList[I].AutonomiaKm));
      LObj.AddPair('battery_wh', TJSONNumber.Create(LList[I].BatteryWh));
      LObj.AddPair('speed_kmh', TJSONNumber.Create(LList[I].VelocidadeKmH));
      LObj.AddPair('image_url', LList[I].ImageUrl);
      LObj.AddPair('status', LList[I].Status);
      LArray.AddElement(LObj);
      LList[I].Free;
    end;
    Res.Status(200).ContentType('application/json').Send(LArray);
  finally
    LRepo.Free;
  end;
end;

procedure PostDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryDrone;
  LDrone: TDroneEntity;
  LBody: TJSONObject;
begin
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then begin Res.Status(400); Exit; end;
  
  LDrone := TDroneEntity.Create;
  try
    LDrone.Id := GetJsonString(LBody, 'id', TGUID.NewGuid.ToString.Replace('{','').Replace('}','').Replace('-','').Substring(0, 24));
    LDrone.Nome := GetJsonString(LBody, 'name', 'Drone Sem Nome');
    LDrone.PayloadMaximo := GetJsonDouble(LBody, 'max_payload_kg');
    LDrone.AutonomiaKm := GetJsonDouble(LBody, 'max_range_km');
    LDrone.BatteryWh := GetJsonDouble(LBody, 'battery_wh');
    LDrone.VelocidadeKmH := GetJsonDouble(LBody, 'speed_kmh');
    LDrone.ImageUrl := GetJsonString(LBody, 'image_url');
    LDrone.Status := GetJsonString(LBody, 'status', 'available');
    
    LRepo := TRepositoryDrone.Create;
    try
      LRepo.Insert(LDrone);
      Res.Status(201).Send('{"message": "Drone Criado Localmente", "id": "' + LDrone.Id + '"}');
    finally
      LRepo.Free;
    end;
  finally
    LDrone.Free;
  end;
end;

procedure GetDroneById(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryDrone;
  LDrone: TDroneEntity;
  LObj: TJSONObject;
begin
  LRepo := TRepositoryDrone.Create;
  try
    LDrone := LRepo.GetById(Req.Params['drone_id']);
    if Assigned(LDrone) then
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LDrone.Id);
      LObj.AddPair('name', LDrone.Nome);
      LObj.AddPair('max_payload_kg', TJSONNumber.Create(LDrone.PayloadMaximo));
      LObj.AddPair('max_range_km', TJSONNumber.Create(LDrone.AutonomiaKm));
      LObj.AddPair('battery_wh', TJSONNumber.Create(LDrone.BatteryWh));
      LObj.AddPair('speed_kmh', TJSONNumber.Create(LDrone.VelocidadeKmH));
      LObj.AddPair('image_url', LDrone.ImageUrl);
      LObj.AddPair('status', LDrone.Status);
      Res.Status(200).ContentType('application/json').Send(LObj);
      LDrone.Free;
    end
    else
      Res.Status(404).Send('{"error": "Drone não encontrado no BD Local"}');
  finally
    LRepo.Free;
  end;
end;

procedure PutDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryDrone;
  LDrone: TDroneEntity;
  LBody: TJSONObject;
begin
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then begin Res.Status(400); Exit; end;
  
  LRepo := TRepositoryDrone.Create;
  try
    LDrone := LRepo.GetById(Req.Params['drone_id']);
    if Assigned(LDrone) then
    begin
      LDrone.Nome := GetJsonString(LBody, 'name', LDrone.Nome);
      LDrone.PayloadMaximo := GetJsonDouble(LBody, 'max_payload_kg', LDrone.PayloadMaximo);
      LDrone.AutonomiaKm := GetJsonDouble(LBody, 'max_range_km', LDrone.AutonomiaKm);
      LDrone.BatteryWh := GetJsonDouble(LBody, 'battery_wh', LDrone.BatteryWh);
      LDrone.VelocidadeKmH := GetJsonDouble(LBody, 'speed_kmh', LDrone.VelocidadeKmH);
      LDrone.ImageUrl := GetJsonString(LBody, 'image_url', LDrone.ImageUrl);
      LDrone.Status := GetJsonString(LBody, 'status', LDrone.Status);
      
      LRepo.Update(LDrone);
      Res.Status(200).Send('{"message": "Drone Atualizado no BD"}');
      LDrone.Free;
    end
    else
      Res.Status(404).Send('{"error": "Drone não encontrado"}');
  finally
    LRepo.Free;
  end;
end;

procedure DeleteDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryDrone;
begin
  LRepo := TRepositoryDrone.Create;
  try
    LRepo.Delete(Req.Params['drone_id']);
    Res.Status(200).Send('{"message": "Drone Deletado do BD"}');
  finally
    LRepo.Free;
  end;
end;

procedure GetDronePricing(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LDist: string;
  LDistVal: Double;
  LPrice: Double;
begin
  LDist := Req.Query['distance_km'];
  LDist := StringReplace(LDist, ',', '.', [rfReplaceAll]);
  LDistVal := StrToFloatDef(LDist, 0.0);
  
  // Algoritmo nativo de cálculo substituindo o servidor remoto!
  // Preço Base R$ 10 + R$ 2.50 por Km
  LPrice := 10.0 + (LDistVal * 2.50);
  
  Res.Status(200).ContentType('application/json').Send('{"distance_km": ' + LDist + ', "estimated_price": ' + FloatToStr(LPrice).Replace(',','.') + '}');
end;

procedure Registry;
begin
  THorse.Get('/drones', GetDrones);
  THorse.Post('/drones', PostDrone);
  THorse.Get('/drones/:drone_id', GetDroneById);
  THorse.Put('/drones/:drone_id', PutDrone);
  THorse.Delete('/drones/:drone_id', DeleteDrone);
  THorse.Get('/drones/:drone_id/pricing', GetDronePricing);
end;

end.
