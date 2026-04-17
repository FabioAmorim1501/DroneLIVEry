unit DroneDelivery.Server.Controller.Locations;

interface

uses
  Horse, System.JSON, System.SysUtils,
  DroneDelivery.Domain.Entities,
  DroneDelivery.Server.Repository.Location;

procedure Registry;

implementation

procedure GetHangar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryLocation;
  LLocal: TLocalEntity;
  LObj: TJSONObject;
begin
  LRepo := TRepositoryLocation.Create;
  try
    // Busca a ID fixa da BaseModel seedada no BD
    LLocal := LRepo.GetById('base_hangar_01');
    if Assigned(LLocal) then
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LLocal.Id);
      LObj.AddPair('name', LLocal.Nome);
      LObj.AddPair('latitude', TJSONNumber.Create(LLocal.Latitude));
      LObj.AddPair('longitude', TJSONNumber.Create(LLocal.Longitude));
      LObj.AddPair('type', 'base');
      Res.Status(200).ContentType('application/json').Send(LObj);
      LLocal.Free;
    end
    else
      Res.Status(404).Send('{"error": "Hangar Base não encontrado no BD"}');
  finally
    LRepo.Free;
  end;
end;

procedure PutHangar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LRepo: TRepositoryLocation;
  LLocal: TLocalEntity;
  LBody: TJSONObject;
begin
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then begin Res.Status(400); Exit; end;
  
  LRepo := TRepositoryLocation.Create;
  try
    LLocal := LRepo.GetById('base_hangar_01');
    if not Assigned(LLocal) then
    begin
      // Se por algum motivo deletaram do BD, recria automático
      LLocal := TLocalEntity.Create;
      LLocal.Id := 'base_hangar_01';
      LLocal.Tipo := ltBase;
      
      if Assigned(LBody.GetValue('name')) then LLocal.Nome := LBody.GetValue('name').Value;
      if Assigned(LBody.GetValue('latitude')) then LLocal.Latitude := (LBody.GetValue('latitude') as TJSONNumber).AsDouble;
      if Assigned(LBody.GetValue('longitude')) then LLocal.Longitude := (LBody.GetValue('longitude') as TJSONNumber).AsDouble;
      LRepo.Insert(LLocal);
    end
    else
    begin
      // Atualiza normal
      if Assigned(LBody.GetValue('name')) then LLocal.Nome := LBody.GetValue('name').Value;
      if Assigned(LBody.GetValue('latitude')) then LLocal.Latitude := (LBody.GetValue('latitude') as TJSONNumber).AsDouble;
      if Assigned(LBody.GetValue('longitude')) then LLocal.Longitude := (LBody.GetValue('longitude') as TJSONNumber).AsDouble;
      LRepo.Update(LLocal);
    end;
    Res.Status(200).Send('{"message": "Endereço do CD Base Atualizado com Sucesso!"}');
    LLocal.Free;
  finally
    LRepo.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/locations/hangar', GetHangar);
  THorse.Put('/locations/hangar', PutHangar);
end;

end.
