unit DroneDelivery.DTO.Drones;

interface

type
  TDroneDTO = class
  public
    Id: Integer;
    Nome: string;
    PayloadMaximo: Double;
    AutonomiaKm: Double;
    VelocidadeKmH: Double;
  end;

implementation

end.
