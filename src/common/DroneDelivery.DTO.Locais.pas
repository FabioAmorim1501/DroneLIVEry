unit DroneDelivery.DTO.Locais;

interface

type
  TLocalDTO = class
  public
    Id: Integer;
    Nome: string;
    Latitude: Double;
    Longitude: Double;
    Tipo: string; // 'Base' ou 'Cliente'
  end;

implementation

end.
