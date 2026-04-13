unit DroneDelivery.Client.Service.API;

interface

uses
  RESTRequest4D, System.JSON, System.SysUtils;

type
  TServiceAPI = class
  private
    FBaseURL: string;
  public
    constructor Create(const ABaseURL: string = 'http://localhost:9000');
    property BaseURL: string read FBaseURL write FBaseURL;
    
    function GetDrones: string;
    function CalcularPreco(const ADroneId: string; ADistanciaKm: Double): string;
    function CalcularRotas(const ABodyJSON: string): string;
  end;

implementation

{ TServiceAPI }

constructor TServiceAPI.Create(const ABaseURL: string);
begin
  FBaseURL := ABaseURL;
  if FBaseURL.Trim = '' then
    FBaseURL := 'http://localhost:9000';
end;

function TServiceAPI.CalcularRotas(const ABodyJSON: string): string;
var
  LResponse: IResponse;
begin
  LResponse := TRequest.New.BaseURL(FBaseURL + '/routes/calculate')
    .Accept('application/json')
    .AddBody(ABodyJSON)
    .Post;
  Result := LResponse.Content;
end;

function TServiceAPI.GetDrones: string;
var
  LResponse: IResponse;
begin
  LResponse := TRequest.New.BaseURL(FBaseURL + '/drones/')
    .Accept('application/json')
    .Get;
  Result := LResponse.Content;
end;

function TServiceAPI.CalcularPreco(const ADroneId: string; ADistanciaKm: Double): string;
var
  LResponse: IResponse;
  LEndpoint: string;
begin
  LEndpoint := FBaseURL + Format('/drones/%s/pricing?distance_km=%g', [ADroneId, ADistanciaKm]);
  // Trocando a vírgula regional por ponto em Double via Format Settings
  LEndpoint := StringReplace(LEndpoint, ',', '.', [rfReplaceAll]); 
  
  LResponse := TRequest.New.BaseURL(LEndpoint)
    .Accept('application/json')
    .Get;
  Result := LResponse.Content;
end;

end.
