unit DroneDelivery.Client.ViewModel.Dashboard;

interface

uses
  DroneDelivery.Client.Service.API, DroneDelivery.DTO.Drones, System.JSON,
  System.Generics.Collections, System.SysUtils, REST.Json,
  DroneDelivery.Client.Service.Maps, JsonDataObjects;

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
      
    // Hub (CD) Methods
    function GetHangar(out AName: string; out ALat, ALng: Double): Boolean;
    function GravarHangar(const AName: string; ALat, ALng: Double): Boolean;
  end;

implementation

uses
  RESTRequest4D;

{ TViewModelDashboard }

function TViewModelDashboard.GetHangar(out AName: string; out ALat, ALng: Double): Boolean;
var
  LResponse: IResponse;
  LJson: TJsonObject;
begin
  Result := False;
  AName := ''; ALat := 0; ALng := 0;
  try
    LResponse := TRequest.New
      .BaseURL('http://localhost:9000')
      .Resource('locations/hangar')
      .Accept('application/json')
      .AcceptCharset('utf-8')
      .Get;

    if LResponse.StatusCode = 200 then
    begin
      LJson := TJsonObject.Parse(LResponse.Content) as TJsonObject;
      if Assigned(LJson) then
      begin
        try
          if LJson.Contains('name') then AName := LJson.S['name'];
          if LJson.Contains('latitude') then ALat := LJson.D['latitude'];
          if LJson.Contains('longitude') then ALng := LJson.D['longitude'];
          Result := True;
        finally
          LJson.Free;
        end;
      end;
    end;
  except
    // Falha silenciosa pra rede fora do ar (Usa Fallback da Praça da Sé original)
  end;
end;

function TViewModelDashboard.GravarHangar(const AName: string; ALat, ALng: Double): Boolean;
var
  LBodyObj: System.JSON.TJSONObject;
  LResponse: IResponse;
begin
  Result := False;
  LBodyObj := System.JSON.TJSONObject.Create;
  // RESTRequest4D takes ownership of LBodyObj and frees it automatically!
  LBodyObj.AddPair('name', AName);
  LBodyObj.AddPair('latitude', System.JSON.TJSONNumber.Create(ALat));
  LBodyObj.AddPair('longitude', System.JSON.TJSONNumber.Create(ALng));

  LResponse := TRequest.New
    .BaseURL('http://localhost:9000')
    .Resource('locations/hangar')
    .ContentType('application/json')
    .AcceptCharset('utf-8')
    .AddBody(LBodyObj)
    .RaiseExceptionOn500(False)
    .Put;

  if LResponse.StatusCode <> 200 then
    raise Exception.Create(LResponse.Content);

  Result := LResponse.StatusCode = 200;
end;

procedure TViewModelDashboard.CalcularRota(const ADroneId: string;
  AWaypoints: TObjectList<TMapPoint>; OnSuccess: TProcSuccess; OnError: TProcError);
var
  LBody: TJsonObject;
  LArrayWaypoints: TJsonArray;
  LObjPoint: TJsonObject;
  LPoint: TMapPoint;
  LResponse: IResponse;
begin
  LBody := TJsonObject.Create;
  try
    LBody.S['drone_id'] := ADroneId;

    // Converte a lista de waypoints para o JSON
    if Assigned(AWaypoints) then
    begin
      LArrayWaypoints := LBody.A['waypoints'];
      for LPoint in AWaypoints do
      begin
        LObjPoint := LArrayWaypoints.AddObject;
        LObjPoint.D['lat'] := LPoint.Lat;
        LObjPoint.D['lng'] := LPoint.Lng;
        LObjPoint.S['label'] := LPoint.LabelName;
      end;
    end;

    LResponse := TRequest.New
      .BaseURL('http://localhost:9000')
      .Resource('routes/calculate')
      .AddBody(LBody.ToJSON)
      .ContentType('application/json')
      .Accept('application/json')
      .AcceptCharset('utf-8')
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
  LJsonObj: TJsonObject;
begin
  LJSONStr := FAPI.CalcularPreco(ADroneId, ADistanciaKm);
  try
    LJsonObj := TJsonObject.Parse(LJSONStr) as TJsonObject;
    if Assigned(LJsonObj) then
    begin
      try
        if LJsonObj.Contains('error') then
          Exit(LJsonObj.S['error']); 
          
        if LJsonObj.Contains('estimated_price') then
          Result := Format('Custo Calculado: R$ %s', [LJsonObj.S['estimated_price']])
        else if LJsonObj.Contains('delivery_price_brl') then
          Result := Format('Custo Calculado: R$ %s', [LJsonObj.S['delivery_price_brl']])
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
  LJsonArr: System.JSON.TJSONArray;
  LJsonVal: System.JSON.TJSONValue;
  LDrone: TDroneDTO;
begin
  Result := TObjectList<TDroneDTO>.Create(True);
  try
    LJsonString := FAPI.GetDrones;
    
    if LJsonString.Trim <> '' then
    begin
      LJsonArr := System.JSON.TJSONObject.ParseJSONValue(LJsonString) as System.JSON.TJSONArray;
      if Assigned(LJsonArr) then
      begin
        try
          for LJsonVal in LJsonArr do
          begin
            LDrone := TJson.JsonToObject<TDroneDTO>(LJsonVal as System.JSON.TJSONObject);
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
      Result.Free;
      Result := nil;
    end;
  end;
end;

end.
