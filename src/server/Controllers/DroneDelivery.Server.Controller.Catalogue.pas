unit DroneDelivery.Server.Controller.Catalogue;

{
  Módulo: Catálogo Interno de Aeronaves Comerciais
  
  Fornece dados de referência de modelos populares de drones para
  uso como "ponto de início" no CRUD de Frotas da aplicação FMX Client.
  
  Nenhuma dependência de API externa — dados são compilados a partir de
  especificações públicas dos fabricantes (DJI, Zipline, Wing, Amazon).
}

interface

uses
  Horse, System.JSON, System.SysUtils;

procedure Registry;

implementation

// ---------------------------------------------------------------------------
// Catálogo estático de aeronaves conhecidas. Em produção, mover para DB.
// ---------------------------------------------------------------------------
function BuildDroneCatalogue: TJSONArray;
begin
  Result := TJSONArray.Create;

  Result.Add(TJSONObject.Create
    .AddPair('model', 'DJI Agras T10')
    .AddPair('manufacturer', 'DJI')
    .AddPair('max_payload_kg', TJSONNumber.Create(10.0))
    .AddPair('max_range_km', TJSONNumber.Create(7.0))
    .AddPair('battery_wh', TJSONNumber.Create(1350.0))
    .AddPair('speed_kmh', TJSONNumber.Create(54.0))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/agras_t10.jpg'));

  Result.Add(TJSONObject.Create
    .AddPair('model', 'DJI Matrice 350 RTK')
    .AddPair('manufacturer', 'DJI')
    .AddPair('max_payload_kg', TJSONNumber.Create(2.7))
    .AddPair('max_range_km', TJSONNumber.Create(20.0))
    .AddPair('battery_wh', TJSONNumber.Create(2400.0))
    .AddPair('speed_kmh', TJSONNumber.Create(82.8))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/matrice350.jpg'));

  Result.Add(TJSONObject.Create
    .AddPair('model', 'Zipline P2 Zip')
    .AddPair('manufacturer', 'Zipline')
    .AddPair('max_payload_kg', TJSONNumber.Create(1.75))
    .AddPair('max_range_km', TJSONNumber.Create(160.0))
    .AddPair('battery_wh', TJSONNumber.Create(1200.0))
    .AddPair('speed_kmh', TJSONNumber.Create(128.0))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/zipline_p2.jpg'));

  Result.Add(TJSONObject.Create
    .AddPair('model', 'Wing Hummingbird')
    .AddPair('manufacturer', 'Wing (Alphabet)')
    .AddPair('max_payload_kg', TJSONNumber.Create(1.5))
    .AddPair('max_range_km', TJSONNumber.Create(12.0))
    .AddPair('battery_wh', TJSONNumber.Create(700.0))
    .AddPair('speed_kmh', TJSONNumber.Create(110.0))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/wing_hummingbird.jpg'));

  Result.Add(TJSONObject.Create
    .AddPair('model', 'Amazon Prime Air MK27')
    .AddPair('manufacturer', 'Amazon')
    .AddPair('max_payload_kg', TJSONNumber.Create(2.27))
    .AddPair('max_range_km', TJSONNumber.Create(24.0))
    .AddPair('battery_wh', TJSONNumber.Create(1100.0))
    .AddPair('speed_kmh', TJSONNumber.Create(120.0))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/amazon_mk27.jpg'));

  Result.Add(TJSONObject.Create
    .AddPair('model', 'Flytrex Core 2')
    .AddPair('manufacturer', 'Flytrex')
    .AddPair('max_payload_kg', TJSONNumber.Create(3.0))
    .AddPair('max_range_km', TJSONNumber.Create(50.0))
    .AddPair('battery_wh', TJSONNumber.Create(1680.0))
    .AddPair('speed_kmh', TJSONNumber.Create(80.0))
    .AddPair('status', 'available')
    .AddPair('image_url', 'https://dronelivery.cgriff.dev/media/drones/flytrex_core2.jpg'));
end;

// ---------------------------------------------------------------------------
// Handler: GET /drones/catalogue
// ---------------------------------------------------------------------------
procedure GetCatalogue(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LCatalogue: TJSONArray;
begin
  LCatalogue := BuildDroneCatalogue;
  try
    Res
      .Status(200)
      .ContentType('application/json')
      .Send(LCatalogue.ToJSON);
  finally
    LCatalogue.Free;
  end;
end;

procedure Registry;
begin
  // IMPORTANTE: Registrar ANTES de /drones/:drone_id para evitar conflito de rota
  THorse.Get('/drones/catalogue', GetCatalogue);
end;

end.
