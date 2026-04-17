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
  LJson: TJSONObject;
begin
  Result := False;
  AName := ''; ALat := 0; ALng := 0;
  try
    LResponse := TRequest.New
      .BaseURL('http://localhost:9000')
      .Resource('locations/hangar')
      .Accept('application/json')
      .Get;

    if LResponse.StatusCode = 200 then
    begin
      LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
      if Assigned(LJson) then
      begin
        try
          if Assigned(LJson.GetValue('name')) then AName := LJson.GetValue('name').Value;
          if Assigned(LJson.GetValue('latitude')) then ALat := (LJson.GetValue('latitude') as TJSONNumber).AsDouble;
          if Assigned(LJson.GetValue('longitude')) then ALng := (LJson.GetValue('longitude') as TJSONNumber).AsDouble;
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
  LBody: TJSONObject;
  LResponse: IResponse;
begin
  Result := False;
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', AName);
    LBody.AddPair('latitude', TJSONNumber.Create(ALat));
    LBody.AddPair('longitude', TJSONNumber.Create(ALng));

    LResponse := TRequest.New
      .BaseURL('http://localhost:9000')
      .Resource('locations/hangar')
      .AddBody(LBody)
      .Accept('application/json')
      .Put;

    Result := LResponse.StatusCode = 200;
  finally
    LBody.Free;
  end;
end;

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
      .Resource('routes/calculate')
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
        if Assigned(LJsonObj.GetValue('error')) then
          Exit(LJsonObj.GetValue('error').Value); 
          
        if Assigned(LJsonObj.GetValue('estimated_price')) then
          Result := Format('Custo Calculado: R$ %s', [LJsonObj.GetValue('estimated_price').Value])
        else if Assigned(LJsonObj.GetValue('delivery_price_brl')) then
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
  Result := TObjectList<TDroneDTO>.Create(True);
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
      Result.Free;
      Result := nil;
    end;
  end;
end;

end.
