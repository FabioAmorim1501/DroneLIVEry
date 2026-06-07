unit DroneDelivery.Client.Service.Maps;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Math,
  System.Net.HttpClient, System.NetEncoding, System.Generics.Collections,
  System.RegularExpressions;

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
  private
    class function UrlEncodeUtf8(const S: string): string;
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

class function TMapService.UrlEncodeUtf8(const S: string): string;
begin
  // ⚡ Bolt: Performance Fix - Prevent O(N^2) memory reallocation overhead during string concatenation
  // Use native optimized URL encoding from System.NetEncoding instead of byte-by-byte manual concatenation
  Result := TNetEncoding.URL.Encode(S);
end;

class procedure TMapService.GeocodeAddressAsync(const AAddress: string; AOnSuccess: TProc<Double, Double>; AOnError: TProc<string>);
var
  LUrl: string;
begin
  LUrl := 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?f=json&maxLocations=1&sourceCountry=BRA&SingleLine=' + UrlEncodeUtf8(AAddress);

  TThread.CreateAnonymousThread(
    procedure
    var
      LResp: IHTTPResponse;
      LJsonObj: TJSONObject;
      LJsonArr: TJSONArray;
      LInner, LLoc: TJSONObject;
      LLat, LLng: Double;
      LHttpLocal: THTTPClient;
    begin
      LHttpLocal := THTTPClient.Create;
      try
        try
          LHttpLocal.CustomHeaders['User-Agent'] := 'DroneLIVEry-App/1.0';
          LResp := LHttpLocal.Get(LUrl);

          if LResp.StatusCode = 200 then
          begin
            LJsonObj := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
            if Assigned(LJsonObj) then
            begin
              try
                LJsonArr := LJsonObj.GetValue('candidates') as TJSONArray;
                if Assigned(LJsonArr) and (LJsonArr.Count > 0) then
                begin
                  LInner := LJsonArr.Items[0] as TJSONObject;
                  LLoc := LInner.GetValue('location') as TJSONObject;

                  LLat := StrToFloatDef(LLoc.GetValue<string>('y').Replace('.', ','), 0.0);
                  LLng := StrToFloatDef(LLoc.GetValue<string>('x').Replace('.', ','), 0.0);

                  if LLat = 0 then LLat := StrToFloatDef(LLoc.GetValue<string>('y').Replace(',', '.'), 0.0);
                  if LLng = 0 then LLng := StrToFloatDef(LLoc.GetValue<string>('x').Replace(',', '.'), 0.0);

                  TThread.Queue(nil, procedure begin AOnSuccess(LLat, LLng); end);
                end
                else
                begin
                  TThread.Queue(nil, procedure begin AOnError('Endereço não encontrado.'); end);
                end;
              finally
                LJsonObj.Free;
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
  LUrl := 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?f=json&maxLocations=5&sourceCountry=BRA&SingleLine='
    + UrlEncodeUtf8(AQuery);

  TThread.CreateAnonymousThread(
    procedure
    var
      LHttpLocal: THTTPClient;
      LResp: IHTTPResponse;
      LJsonObj: TJSONObject;
      LJsonArr: TJSONArray;
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
            LJsonObj := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
            if Assigned(LJsonObj) then
            begin
              try
                LJsonArr := LJsonObj.GetValue('candidates') as TJSONArray;
                if Assigned(LJsonArr) then
                begin
                  // ⚡ Bolt: Performance Fix - Changed O(N^2) dynamic SetLength inside loop to O(N) pre-allocation.
                  // Reduces redundant memory reallocations, improving JSON parsing speed for large address sets.
                  SetLength(LSuggestions, LJsonArr.Count);
                  for I := 0 to LJsonArr.Count - 1 do
                  begin
                    LInner := LJsonArr.Items[I] as TJSONObject;
                    LSuggestions[I] := LInner.GetValue<string>('address');
                  end;
                  TThread.Queue(nil, procedure begin AOnSuccess(LSuggestions); end);
                end else
                  TThread.Queue(nil, procedure begin AOnSuccess([]); end);
              finally
                LJsonObj.Free;
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
