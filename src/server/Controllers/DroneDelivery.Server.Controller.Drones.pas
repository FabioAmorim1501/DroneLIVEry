unit DroneDelivery.Server.Controller.Drones;

interface

uses
  Horse, System.JSON, System.SysUtils, System.Net.HttpClient;

procedure Registry;

implementation

procedure GetDrones(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
begin
  LHttp := THTTPClient.Create;
  try
    try
      LResponse := LHttp.Get('https://dronelivery.cgriff.dev/drones/');
      Res.Status(LResponse.StatusCode).ContentType('application/json').Send(LResponse.ContentAsString);
    except
      Res.Status(500).Send('{"error": "Falha na comunicação com a Cloud API."}');
    end;
  finally
    LHttp.Free;
  end;
end;

procedure PostDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('{"message": "Drone Criado"}').Status(201);
end;

procedure GetDroneById(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send('{"message": "Detalhes do Drone ' + Req.Params['drone_id'] + '"}');
end;

procedure PutDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Status(200).Send('{"message": "Drone Atualizado"}');
end;

procedure DeleteDrone(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Status(200).Send('{"message": "Drone Deletado"}');
end;

procedure GetDronePricing(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LHttp: THTTPClient;
  LResponse: IHTTPResponse;
  LUrl, LDist: string;
begin
  LHttp := THTTPClient.Create;
  try
    try
      LDist := Req.Query['distance_km'];
      // Corrige caso FMX tenha enviado com vírgula acidentalmente em locale pt-BR
      LDist := StringReplace(LDist, ',', '.', [rfReplaceAll]);
      LUrl := Format('https://dronelivery.cgriff.dev/drones/%s/pricing?distance_km=%s',
        [Req.Params['drone_id'], LDist]);
        
      LResponse := LHttp.Get(LUrl);
      Res.Status(LResponse.StatusCode).ContentType('application/json').Send(LResponse.ContentAsString);
    except
      Res.Status(500).Send('{"error": "Falha na comunicação com API de Pricing."}');
    end;
  finally
    LHttp.Free;
  end;
end;

procedure Registry;
begin
  THorse.Get('/drones', GetDrones);
  THorse.Post('/drones', PostDrone);
  THorse.Get('/drones/:drone_id', GetDroneById);
  THorse.Put('/drones/:drone_id', PutDrone);
  THorse.Delete('/drones/:drone_id', DeleteDrone);
  THorse.Get('/drones/:drone_id/pricing', GetDronePricing);
end;

end.
