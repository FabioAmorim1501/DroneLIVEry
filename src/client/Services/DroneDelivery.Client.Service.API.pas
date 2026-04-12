unit DroneDelivery.Client.Service.API;

interface

uses
  RESTRequest4D, System.JSON, System.SysUtils;

type
  TServiceAPI = class
  public
    function GetDrones: string;
    function CalcularRotas(const ABodyJSON: string): string;
  end;

implementation

{ TServiceAPI }

function TServiceAPI.CalcularRotas(const ABodyJSON: string): string;
var
  LResponse: IResponse;
begin
  LResponse := TRequest.New.BaseURL('http://localhost:9000/rotas/calcular')
    .Accept('application/json')
    .AddBody(ABodyJSON)
    .Post;
  Result := LResponse.Content;
end;

function TServiceAPI.GetDrones: string;
var
  LResponse: IResponse;
begin
  LResponse := TRequest.New.BaseURL('http://localhost:9000/drones')
    .Accept('application/json')
    .Get;
  Result := LResponse.Content;
end;

end.
