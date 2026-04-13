unit DroneDelivery.Client.Service.Maps;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Math,
  System.Net.HttpClient, System.NetEncoding, System.Generics.Collections;

type
  TMapPoint = class
  public
    Lat: Double;
    Lng: Double;
    LabelName: string;
    BatteryEstimated: Double;
    constructor Create(ALat, ALng: Double; ALabel: string);
  end;

  TMapService = class
  public
    // Geocoding: converte endereco em coordenadas (primeira ocorrencia)
    class procedure GeocodeAddressAsync(const AAddress: string; AOnSuccess: TProc<Double, Double>; AOnError: TProc<string>);

    // Autocomplete: retorna lista de nomes de lugares para o dropdown
    class procedure SearchAddressSuggestionsAsync(const AQuery: string;
      AOnSuccess: TProc<TArray<string>>; AOnError: TProc<string>);

    // Distancia Euclidiana/Haversine entre dois pontos
    class function TryCalculateDistanceKm(Lat1, Lon1, Lat2, Lon2: Double): Double;

    // Gerador de Polyline Payload consumido pelo mapa Leaflet
    class function GenerateRoutePayload(AHub: TMapPoint; AWaypoints: TObjectList<TMapPoint>;
      DroneMaxRangeKm, DroneBatteryWh: Double): string;
  end;

implementation

{ TMapPoint }

constructor TMapPoint.Create(ALat, ALng: Double; ALabel: string);
begin
  Lat := ALat;
  Lng := ALng;
  LabelName := ALabel;
  BatteryEstimated := 100.0;
end;

{ TMapService }

class procedure TMapService.GeocodeAddressAsync(const AAddress: string; AOnSuccess: TProc<Double, Double>; AOnError: TProc<string>);
var
  LHttp: THTTPClient;
  LUrl: string;
begin
  LUrl := 'https://nominatim.openstreetmap.org/search?format=json&q=' + TNetEncoding.URL.Encode(AAddress);
  
  TThread.CreateAnonymousThread(
    procedure
    var
      LResp: IHTTPResponse;
      LJsonArray: TJSONArray;
      LJsonObj: TJSONObject;
      LLat, LLng: Double;
      LHttpLocal: THTTPClient;
    begin
      LHttpLocal := THTTPClient.Create;
      try
        try
          // Header obrigatorio do OSM
          LHttpLocal.CustomHeaders['User-Agent'] := 'DroneLIVEry-App/1.0';
          LResp := LHttpLocal.Get(LUrl);
          
          if LResp.StatusCode = 200 then
          begin
            LJsonArray := TJSONObject.ParseJSONValue(LResp.ContentAsString) as TJSONArray;
            if Assigned(LJsonArray) then
            begin
              try
                if LJsonArray.Count > 0 then
                begin
                  LJsonObj := LJsonArray.Items[0] as TJSONObject;
                  LLat := StrToFloatDef(LJsonObj.GetValue<string>('lat').Replace('.', ','), 0.0);
                  LLng := StrToFloatDef(LJsonObj.GetValue<string>('lon').Replace('.', ','), 0.0);
                  
                  // fallback de locale
                  if LLat = 0 then LLat := StrToFloatDef(LJsonObj.GetValue<string>('lat').Replace(',', '.'), 0.0);
                  if LLng = 0 then LLng := StrToFloatDef(LJsonObj.GetValue<string>('lon').Replace(',', '.'), 0.0);

                  TThread.Queue(nil, procedure begin AOnSuccess(LLat, LLng); end);
                end
                else
                begin
                  TThread.Queue(nil, procedure begin AOnError('Endereço não encontrado.'); end);
                end;
              finally
                LJsonArray.Free;
              end;
            end;
          end
          else
            TThread.Queue(nil, procedure begin AOnError('Erro HTTP ' + LResp.StatusCode.ToString); end);
        except
          on E: Exception do
            TThread.Queue(nil, procedure begin AOnError(E.Message); end);
        end;
      finally
        LHttpLocal.Free;
      end;
    end).Start;
end;

class procedure TMapService.SearchAddressSuggestionsAsync(const AQuery: string;
  AOnSuccess: TProc<TArray<string>>; AOnError: TProc<string>);
var
  LUrl: string;
begin
  LUrl := 'https://nominatim.openstreetmap.org/search?format=json&limit=5&q='
    + TNetEncoding.URL.Encode(AQuery);

  TThread.CreateAnonymousThread(
    procedure
    var
      LHttpLocal: THTTPClient;
      LResp: IHTTPResponse;
      LJsonArray: TJSONArray;
      LInner: TJSONObject;
      LSuggestions: TArray<string>;
      I: Integer;
    begin
      LHttpLocal := THTTPClient.Create;
      try
        try
          LHttpLocal.CustomHeaders['User-Agent'] := 'DroneLIVEry-App/1.0';
          LResp := LHttpLocal.Get(LUrl);
          if LResp.StatusCode = 200 then
          begin
            LJsonArray := TJSONObject.ParseJSONValue(LResp.ContentAsString) as TJSONArray;
            if Assigned(LJsonArray) then
            begin
              try
                SetLength(LSuggestions, LJsonArray.Count);
                for I := 0 to LJsonArray.Count - 1 do
                begin
                  LInner := LJsonArray.Items[I] as TJSONObject;
                  LSuggestions[I] := LInner.GetValue<string>('display_name');
                end;
                TThread.Queue(nil, procedure begin AOnSuccess(LSuggestions); end);
              finally
                LJsonArray.Free;
              end;
            end;
          end
          else
            TThread.Queue(nil, procedure begin AOnError('HTTP ' + LResp.StatusCode.ToString); end);
        except
          on E: Exception do
            TThread.Queue(nil, procedure begin AOnError(E.Message); end);
        end;
      finally
        LHttpLocal.Free;
      end;
    end).Start;
end;

class function TMapService.TryCalculateDistanceKm(Lat1, Lon1, Lat2, Lon2: Double): Double;
var
  Radius, DLat, DLon, A, C: Double;
begin
  // Formula Haversine
  Radius := 6371.0; // raio da terra em km
  DLat := DegToRad(Lat2 - Lat1);
  DLon := DegToRad(Lon2 - Lon1);
  A := Sin(DLat/2) * Sin(DLat/2) +
       Cos(DegToRad(Lat1)) * Cos(DegToRad(Lat2)) *
       Sin(DLon/2) * Sin(DLon/2);
  C := 2 * ArcTan2(Sqrt(A), Sqrt(1-A));
  Result := Radius * C;
end;

class function TMapService.GenerateRoutePayload(AHub: TMapPoint; AWaypoints: TObjectList<TMapPoint>;
  DroneMaxRangeKm, DroneBatteryWh: Double): string;
var
  LJsonArray: TJSONArray;
  LPonto, LUltimoPonto: TMapPoint;
  LDistanciaKm, LBatPerc: Double;
  LTotalDist: Double;
begin
  LJsonArray := TJSONArray.Create;
  LTotalDist := 0;
  LBatPerc := 100.0;
  
  // HUB Origem Inicial
  LJsonArray.AddElement(TJSONObject.Create
    .AddPair('lat', TJSONNumber.Create(AHub.Lat))
    .AddPair('lng', TJSONNumber.Create(AHub.Lng))
    .AddPair('label', 'HUB Base')
    .AddPair('battery', TJSONNumber.Create(LBatPerc)));
    
  LUltimoPonto := AHub;

  // Waypoints Intermediários
  for LPonto in AWaypoints do
  begin
    LDistanciaKm := TryCalculateDistanceKm(LUltimoPonto.Lat, LUltimoPonto.Lng, LPonto.Lat, LPonto.Lng);
    LTotalDist := LTotalDist + LDistanciaKm;
    
    // Perda linear de bateria baseada na autonomia maxima. Drone morre se perder 100%
    if DroneMaxRangeKm > 0 then
      LBatPerc := LBatPerc - ((LDistanciaKm / DroneMaxRangeKm) * 100.0)
    else
      LBatPerc := 0;
      
    if LBatPerc < 0 then LBatPerc := 0;

    LJsonArray.AddElement(TJSONObject.Create
      .AddPair('lat', TJSONNumber.Create(LPonto.Lat))
      .AddPair('lng', TJSONNumber.Create(LPonto.Lng))
      .AddPair('label', LPonto.LabelName)
      .AddPair('battery', TJSONNumber.Create(LBatPerc)));
      
    LUltimoPonto := LPonto;
  end;
  
  // Retorno Final (Volta pro Hub)
  if AWaypoints.Count > 0 then
  begin
    LDistanciaKm := TryCalculateDistanceKm(LUltimoPonto.Lat, LUltimoPonto.Lng, AHub.Lat, AHub.Lng);
    LTotalDist := LTotalDist + LDistanciaKm;
    
    if DroneMaxRangeKm > 0 then
      LBatPerc := LBatPerc - ((LDistanciaKm / DroneMaxRangeKm) * 100.0)
    else
      LBatPerc := 0;
      
    LJsonArray.AddElement(TJSONObject.Create
      .AddPair('lat', TJSONNumber.Create(AHub.Lat))
      .AddPair('lng', TJSONNumber.Create(AHub.Lng))
      .AddPair('label', 'HUB (Retorno)')
      .AddPair('battery', TJSONNumber.Create(LBatPerc)));
  end;
  
  Result := LJsonArray.ToJSON;
  LJsonArray.Free;
end;

end.
