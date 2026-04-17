unit DroneDelivery.Server.Repository.Drone;

interface

uses
  DroneDelivery.Domain.Interfaces,
  DroneDelivery.Domain.Entities,
  DroneDelivery.Server.Provider.Connection,
  FireDAC.Comp.Client;

type
  TRepositoryDrone = class(TInterfacedObject, IRepository<TDroneEntity>)
  private
    FConn: TFDConnection;
  public
    constructor Create;
    function GetById(const AId: string): TDroneEntity;
    function GetAll: TArray<TDroneEntity>;
    procedure Insert(const AEntity: TDroneEntity);
    procedure Update(const AEntity: TDroneEntity);
    procedure Delete(const AId: string);
  end;

implementation

{ TRepositoryDrone }

constructor TRepositoryDrone.Create;
begin
  FConn := TProviderConnection.GetInstance;
end;

procedure TRepositoryDrone.Delete(const AId: string);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'DELETE FROM drones WHERE id = :id';
    Qry.ParamByName('id').AsString := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

function TRepositoryDrone.GetAll: TArray<TDroneEntity>;
var
  Qry: TFDQuery;
  LDrone: TDroneEntity;
begin
  SetLength(Result, 0);
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT * FROM drones';
    Qry.Open;
    while not Qry.Eof do
    begin
      LDrone := TDroneEntity.Create;
      LDrone.Id := Qry.FieldByName('id').AsString;
      LDrone.Nome := Qry.FieldByName('name').AsString;
      LDrone.PayloadMaximo := Qry.FieldByName('max_payload_kg').AsFloat;
      LDrone.AutonomiaKm := Qry.FieldByName('max_range_km').AsFloat;
      LDrone.BatteryWh := Qry.FieldByName('battery_wh').AsFloat;
      LDrone.VelocidadeKmH := Qry.FieldByName('speed_kmh').AsFloat;
      LDrone.ImageUrl := Qry.FieldByName('image_url').AsString;
      LDrone.Status := Qry.FieldByName('status').AsString;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LDrone;
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TRepositoryDrone.GetById(const AId: string): TDroneEntity;
var
  Qry: TFDQuery;
begin
  Result := nil;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT * FROM drones WHERE id = :id';
    Qry.ParamByName('id').AsString := AId;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result := TDroneEntity.Create;
      Result.Id := Qry.FieldByName('id').AsString;
      Result.Nome := Qry.FieldByName('name').AsString;
      Result.PayloadMaximo := Qry.FieldByName('max_payload_kg').AsFloat;
      Result.AutonomiaKm := Qry.FieldByName('max_range_km').AsFloat;
      Result.BatteryWh := Qry.FieldByName('battery_wh').AsFloat;
      Result.VelocidadeKmH := Qry.FieldByName('speed_kmh').AsFloat;
      Result.ImageUrl := Qry.FieldByName('image_url').AsString;
      Result.Status := Qry.FieldByName('status').AsString;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TRepositoryDrone.Insert(const AEntity: TDroneEntity);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'INSERT INTO drones (id, name, max_payload_kg, max_range_km, battery_wh, speed_kmh, image_url, status) ' +
                    'VALUES (:id, :name, :payload, :range, :battery, :speed, :img, :status)';
    Qry.ParamByName('id').AsString := AEntity.Id;
    Qry.ParamByName('name').AsString := AEntity.Nome;
    Qry.ParamByName('payload').AsFloat := AEntity.PayloadMaximo;
    Qry.ParamByName('range').AsFloat := AEntity.AutonomiaKm;
    Qry.ParamByName('battery').AsFloat := AEntity.BatteryWh;
    Qry.ParamByName('speed').AsFloat := AEntity.VelocidadeKmH;
    Qry.ParamByName('img').AsString := AEntity.ImageUrl;
    Qry.ParamByName('status').AsString := AEntity.Status;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TRepositoryDrone.Update(const AEntity: TDroneEntity);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'UPDATE drones SET name = :name, max_payload_kg = :payload, max_range_km = :range, ' +
                    'battery_wh = :battery, speed_kmh = :speed, image_url = :img, status = :status WHERE id = :id';
    Qry.ParamByName('id').AsString := AEntity.Id;
    Qry.ParamByName('name').AsString := AEntity.Nome;
    Qry.ParamByName('payload').AsFloat := AEntity.PayloadMaximo;
    Qry.ParamByName('range').AsFloat := AEntity.AutonomiaKm;
    Qry.ParamByName('battery').AsFloat := AEntity.BatteryWh;
    Qry.ParamByName('speed').AsFloat := AEntity.VelocidadeKmH;
    Qry.ParamByName('img').AsString := AEntity.ImageUrl;
    Qry.ParamByName('status').AsString := AEntity.Status;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
