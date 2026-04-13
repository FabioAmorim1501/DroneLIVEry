unit DroneDelivery.Domain.Entities;

interface

uses
  System.SysUtils;

type
  TLocalType = (ltBase, ltCliente);

  TLocalEntity = class
  private
    FId: Integer;
    FNome: string;
    FLatitude: Double;
    FLongitude: Double;
    FTipo: TLocalType;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Latitude: Double read FLatitude write FLatitude;
    property Longitude: Double read FLongitude write FLongitude;
    property Tipo: TLocalType read FTipo write FTipo;
  end;

  TDroneEntity = class
  private
    FId: Integer;
    FNome: string;
    FPayloadMaximo: Double;
    FAutonomiaKm: Double;
    FVelocidadeKmH: Double;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property PayloadMaximo: Double read FPayloadMaximo write FPayloadMaximo;
    property AutonomiaKm: Double read FAutonomiaKm write FAutonomiaKm;
    property VelocidadeKmH: Double read FVelocidadeKmH write FVelocidadeKmH;
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
