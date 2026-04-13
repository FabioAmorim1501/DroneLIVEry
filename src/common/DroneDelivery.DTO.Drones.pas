unit DroneDelivery.DTO.Drones;

interface

type
  TDroneDTO = class
  private
    Fid: string;
    Fname: string;
    Fmax_payload_kg: Double;
    Fmax_range_km: Double;
    Fbattery_wh: Double;
    Fspeed_kmh: Double;
    Fstatus: string;
    Fimage_url: string;
  public
    // Usamos nomenclaturas idênticas ao Swagger para desserialização nativa fácil
    property id: string read Fid write Fid;
    property image_url: string read Fimage_url write Fimage_url;
    property name: string read Fname write Fname;
    property max_payload_kg: Double read Fmax_payload_kg write Fmax_payload_kg;
    property max_range_km: Double read Fmax_range_km write Fmax_range_km;
    property battery_wh: Double read Fbattery_wh write Fbattery_wh;
    property speed_kmh: Double read Fspeed_kmh write Fspeed_kmh;
    property status: string read Fstatus write Fstatus;
  end;

implementation

end.
