unit DroneDelivery.Server.Repository.Location;

interface

uses
  DroneDelivery.Domain.Interfaces,
  DroneDelivery.Domain.Entities,
  DroneDelivery.Server.Provider.Connection,
  FireDAC.Comp.Client;

type
  TRepositoryLocation = class(TInterfacedObject, IRepository<TLocalEntity>)
  private
    FConn: TFDConnection;
  public
    constructor Create;
    function GetById(const AId: string): TLocalEntity;
    function GetAll: TArray<TLocalEntity>;
    procedure Insert(const AEntity: TLocalEntity);
    procedure Update(const AEntity: TLocalEntity);
    procedure Delete(const AId: string);
  end;

implementation

{ TRepositoryLocation }

constructor TRepositoryLocation.Create;
begin
  FConn := TProviderConnection.GetInstance;
end;

procedure TRepositoryLocation.Delete(const AId: string);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'DELETE FROM locations WHERE id = :id';
    Qry.ParamByName('id').AsString := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

function TRepositoryLocation.GetAll: TArray<TLocalEntity>;
var
  Qry: TFDQuery;
  LLocal: TLocalEntity;
begin
  SetLength(Result, 0);
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT * FROM locations';
    Qry.Open;
    while not Qry.Eof do
    begin
      LLocal := TLocalEntity.Create;
      LLocal.Id := Qry.FieldByName('id').AsString;
      LLocal.Nome := Qry.FieldByName('name').AsString;
      LLocal.Latitude := Qry.FieldByName('latitude').AsFloat;
      LLocal.Longitude := Qry.FieldByName('longitude').AsFloat;
      if Qry.FieldByName('loc_type').AsString = 'base' then LLocal.Tipo := ltBase else LLocal.Tipo := ltCliente;
      
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LLocal;
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TRepositoryLocation.GetById(const AId: string): TLocalEntity;
var
  Qry: TFDQuery;
begin
  Result := nil;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConn;
    Qry.SQL.Text := 'SELECT * FROM locations WHERE id = :id';
    Qry.ParamByName('id').AsString := AId;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result := TLocalEntity.Create;
      Result.Id := Qry.FieldByName('id').AsString;
      Result.Nome := Qry.FieldByName('name').AsString;
      Result.Latitude := Qry.FieldByName('latitude').AsFloat;
      Result.Longitude := Qry.FieldByName('longitude').AsFloat;
      if Qry.FieldByName('loc_type').AsString = 'base' then Result.Tipo := ltBase else Result.Tipo := ltCliente;
    end;
  finally
    Qry.Free;
  end;
end;

procedure TRepositoryLocation.Insert(const AEntity: TLocalEntity);
var
  Qry: TFDQuery;
  LType: string;
begin
  Qry := TFDQuery.Create(nil);
  try
    if AEntity.Tipo = ltBase then LType := 'base' else LType := 'client';
    
    Qry.Connection := FConn;
    Qry.SQL.Text := 'INSERT INTO locations (id, name, latitude, longitude, loc_type) ' +
                    'VALUES (:id, :name, :lat, :lng, :type)';
    Qry.ParamByName('id').AsString := AEntity.Id;
    Qry.ParamByName('name').AsString := AEntity.Nome;
    Qry.ParamByName('lat').AsFloat := AEntity.Latitude;
    Qry.ParamByName('lng').AsFloat := AEntity.Longitude;
    Qry.ParamByName('type').AsString := LType;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TRepositoryLocation.Update(const AEntity: TLocalEntity);
var
  Qry: TFDQuery;
  LType: string;
begin
  Qry := TFDQuery.Create(nil);
  try
    if AEntity.Tipo = ltBase then LType := 'base' else LType := 'client';
    
    Qry.Connection := FConn;
    Qry.SQL.Text := 'UPDATE locations SET name = :name, latitude = :lat, longitude = :lng, ' +
                    'loc_type = :type WHERE id = :id';
    Qry.ParamByName('id').AsString := AEntity.Id;
    Qry.ParamByName('name').AsString := AEntity.Nome;
    Qry.ParamByName('lat').AsFloat := AEntity.Latitude;
    Qry.ParamByName('lng').AsFloat := AEntity.Longitude;
    Qry.ParamByName('type').AsString := LType;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
