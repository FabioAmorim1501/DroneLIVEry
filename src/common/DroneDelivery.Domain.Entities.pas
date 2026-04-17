unit DroneDelivery.Domain.Entities;

interface

uses
  System.SysUtils;

type
  TLocalType = (ltBase, ltCliente);

  TLocalEntity = class
  private
    FId: string;
    FNome: string;
    FLatitude: Double;
    FLongitude: Double;
    FTipo: TLocalType;
  public
    property Id: string read FId write FId;
    property Nome: string read FNome write FNome;
    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
    property Tipo: TLocalType read FTipo write FTipo;
  end;

  TDroneEntity = class
  private
    FId: string;
    FNome: string;
    FPayloadMaximo: Double;
    FAutonomiaKm: Double;
    FVelocidadeKmH: Double;
    FBatteryWh: Double;
    FImageUrl: string;
    FStatus: string;
  public
    property Id: string read FId write FId;
    property Nome: string read FNome write FNome;
    property PayloadMaximo: Double read FPayloadMaximo write FPayloadMaximo;
    property AutonomiaKm: Double read FAutonomiaKm write FAutonomiaKm;
    property VelocidadeKmH: Double read FVelocidadeKmH write FVelocidadeKmH;
    property BatteryWh: Double read FBatteryWh write FBatteryWh;
    property ImageUrl: string read FImageUrl write FImageUrl;
    property Status: string read FStatus write FStatus;
  end;

  TPedidoEntity = class
  private
    FId: Integer;
    FLocalOrigemId: Integer;
    FLocalDestinoId: Integer;
    FPesoLiquido: Double;
  public
    property Id: Integer read FId write FId;
    property LocalOrigemId: Integer read FLocalOrigemId write FLocalOrigemId;
    property LocalDestinoId: Integer read FLocalDestinoId write FLocalDestinoId;
    property PesoLiquido: Double read FPesoLiquido write FPesoLiquido;
  end;

implementation

end.
