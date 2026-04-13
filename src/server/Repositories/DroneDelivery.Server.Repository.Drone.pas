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
    function GetById(const AId: Integer): TDroneEntity;
    function GetAll: TArray<TDroneEntity>;
    procedure Insert(const AEntity: TDroneEntity);
    procedure Update(const AEntity: TDroneEntity);
    procedure Delete(const AId: Integer);
  end;

implementation

{ TRepositoryDrone }

constructor TRepositoryDrone.Create;
begin
  FConn := TProviderConnection.GetInstance;
end;

procedure TRepositoryDrone.Delete(const AId: Integer);
begin
  // Logic here
end;

function TRepositoryDrone.GetAll: TArray<TDroneEntity>;
begin
  // Qry := TFDQuery.Create(nil) ...
  SetLength(Result, 0);
end;

function TRepositoryDrone.GetById(const AId: Integer): TDroneEntity;
begin
  Result := nil;
end;

procedure TRepositoryDrone.Insert(const AEntity: TDroneEntity);
begin
  // Logic here
end;

procedure TRepositoryDrone.Update(const AEntity: TDroneEntity);
begin
  // Logic here
end;

end.
