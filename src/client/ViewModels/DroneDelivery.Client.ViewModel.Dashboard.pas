unit DroneDelivery.Client.ViewModel.Dashboard;

interface

uses
  DroneDelivery.Client.Service.API, DroneDelivery.DTO.Drones, System.JSON,
  System.Generics.Collections, System.SysUtils, REST.Json,
  DroneDelivery.Client.Service.Maps;

type
  TProcSuccess = reference to procedure(AJson: string);
  TProcError = reference to procedure(AMsg: string);

  TViewModelDashboard = class
  private
    FAPI: TServiceAPI;
  public
    constructor Create;
    destructor Destroy; override;
    
    // Retorna uma lista real desserializada da API de Produçao
    function LoadDrones: TObjectList<TDroneDTO>;
    function CalcularPreco(const ADroneId: string; ADistanciaKm: Double): string;
    procedure CalcularRota(const ADroneId: string; AWaypoints: TObjectList<TMapPoint>; 
      OnSuccess: TProcSuccess; OnError: TProcError);
  end;

implementation

uses
  RESTRequest4D;

{ TViewModelDashboard }

procedure TViewModelDashboard.CalcularRota(const ADroneId: string;
  AWaypoints: TObjectList<TMapPoint>; OnSuccess: TProcSuccess; OnError: TProcError);
var
  LBody: TJSONObject;
  LArrayWaypoints: TJSONArray;
  LPoint: TMapPoint;
  LResponse: IResponse;
begin
  LBody := TJSONObject.Create;
  LArrayWaypoints := TJSONArray.Create;
  try
    LBody.AddPair('drone_id', ADroneId);

    // Converte a lista de waypoints para o JSON
    if Assigned(AWaypoints) then
    begin
      for LPoint in AWaypoints do
      begin
        LArrayWaypoints.AddElement(TJSONObject.Create
          .AddPair('lat', TJSONNumber.Create(LPoint.Lat))
          .AddPair('lng', TJSONNumber.Create(LPoint.Lng))
          .AddPair('label', LPoint.LabelName));
      end;
    end;
    LBody.AddPair('waypoints', LArrayWaypoints);

    LResponse := TRequest.New
      .BaseURL('http://localhost:9000')
      .Resource('rotas/calcular')
      .AddBody(LBody)
      .Accept('application/json')
      .Post;

    if LResponse.StatusCode = 200 then
    begin
      if Assigned(OnSuccess) then
        OnSuccess(LResponse.Content);
    end
    else
    begin
      if Assigned(OnError) then
        OnError(Format('Erro %d: %s', [LResponse.StatusCode, LResponse.StatusText]));
    end;
  finally
    // No RESTRequest4Delphi, o LBody deve ser liberado manualmente se
    // não for passado como owned. Mas para evitar leaks:
    LBody.Free;
  end;
end;

constructor TViewModelDashboard.Create;
begin
  FAPI := TServiceAPI.Create;
end;

destructor TViewModelDashboard.Destroy;
begin
  FAPI.Free;
  inherited;
end;

function TViewModelDashboard.CalcularPreco(const ADroneId: string; ADistanciaKm: Double): string;
var
  LJSONStr: string;
  LJsonObj: TJSONObject;
begin
  LJSONStr := FAPI.CalcularPreco(ADroneId, ADistanciaKm);
  try
    LJsonObj := TJSONObject.ParseJSONValue(LJSONStr) as TJSONObject;
    if Assigned(LJsonObj) then
    begin
      try
        // Extrai a resposta tratada, não importa qual o Status Code
        if Assigned(LJsonObj.GetValue('error')) then
          Exit(LJsonObj.GetValue('error').Value); 
          
        if Assigned(LJsonObj.GetValue('delivery_price_brl')) then
          Result := Format('Custo Calculado: R$ %s', [LJsonObj.GetValue('delivery_price_brl').Value])
        else
          Result := 'Retorno desconhecido da API.';
      finally
        LJsonObj.Free;
      end;
    end
    else
      Result := 'Erro ao interpretar pacote de preço da API.';
  except
    Result := 'Falha severa na conexão com a API de precificação.';
  end;
end;

function TViewModelDashboard.LoadDrones: TObjectList<TDroneDTO>;
var
  LJsonString: string;
  LJsonArr: TJSONArray;
  LJsonVal: TJSONValue;
  LDrone: TDroneDTO;
begin
  Result := TObjectList<TDroneDTO>.Create(True); // A View consome e ns doamos a lista ou Owns objects
  try
    LJsonString := FAPI.GetDrones;
    
    if LJsonString.Trim <> '' then
    begin
      LJsonArr := TJSONObject.ParseJSONValue(LJsonString) as TJSONArray;
      if Assigned(LJsonArr) then
      begin
        try
          for LJsonVal in LJsonArr do
          begin
            LDrone := TJson.JsonToObject<TDroneDTO>(LJsonVal as TJSONObject);
            if Assigned(LDrone) then
              Result.Add(LDrone);
          end;
        finally
          LJsonArr.Free;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      // Se houver Timeout ou falta de DLL OpenSSL HTTP, devolve nulo graciosamente
      Result.Free;
      Result := nil;
    end;
  end;
end;

end.
