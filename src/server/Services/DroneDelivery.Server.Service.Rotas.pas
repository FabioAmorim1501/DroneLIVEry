unit DroneDelivery.Server.Service.Rotas;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math, System.JSON,
  DroneDelivery.Domain.Entities;

type
  TServiceRotas = class
  private
    { Motor Matemático: Fórmula de Haversine para distâncias geográficas }
    function CalcularDistanciaKm(Lat1, Lon1, Lat2, Lon2: Double): Double;
  public
    { A assinatura agora requer ALocais para resolver as coordenadas do destino e do HUB }
    function CalcularMelhorRota(APedidos: TObjectList<TPedidoEntity>;
      ADrones: TObjectList<TDroneEntity>; ALocais: TObjectList<TLocalEntity>): string;
  end;

implementation

{ TServiceRotas }

function TServiceRotas.CalcularDistanciaKm(Lat1, Lon1, Lat2, Lon2: Double): Double;
var
  Radius, DLat, DLon, A, C: Double;
begin
  Radius := 6371.0; // Raio volumétrico médio da Terra em Km
  DLat := DegToRad(Lat2 - Lat1);
  DLon := DegToRad(Lon2 - Lon1);

  A := Sin(DLat/2) * Sin(DLat/2) +
       Cos(DegToRad(Lat1)) * Cos(DegToRad(Lat2)) *
       Sin(DLon/2) * Sin(DLon/2);

  C := 2 * ArcTan2(Sqrt(A), Sqrt(1-A));
  Result := Radius * C;
end;

function TServiceRotas.CalcularMelhorRota(APedidos: TObjectList<TPedidoEntity>;
  ADrones: TObjectList<TDroneEntity>; ALocais: TObjectList<TLocalEntity>): string;
var
  LDrone: TDroneEntity;
  LPedido, LPedidoMaisProximo: TPedidoEntity;
  LLocalHub, LLocalDestino, LLocalDestinoCandidato: TLocalEntity;
  LArrayRotas, LArrayParadas: TJSONArray;
  LObjRota: TJSONObject;
  LDistanciaAtePedido, LDistanciaRegresso, LMenorDistancia: Double;
  LCurrentLat, LCurrentLng: Double;
  LCargaAtual, LDistanciaPercorrida: Double;
  LPedidosPendentes: TList<TPedidoEntity>;
  LLocaisMap: TDictionary<string, TLocalEntity>;
  LPedidoDestinos: TDictionary<TPedidoEntity, TLocalEntity>;
  LDistanciasRegresso: TDictionary<TLocalEntity, Double>;
  I, LMelhorIndex: Integer;
begin
  LArrayRotas := TJSONArray.Create;
  LPedidosPendentes := TList<TPedidoEntity>.Create;
  LLocaisMap := TDictionary<string, TLocalEntity>.Create;
  LPedidoDestinos := TDictionary<TPedidoEntity, TLocalEntity>.Create;
  LDistanciasRegresso := TDictionary<TLocalEntity, Double>.Create;
  try
    // 1. Localiza a Base Operacional (Hub) e indexa os locais para O(1) lookup
    LLocalHub := nil;
    for LLocalDestino in ALocais do
    begin
      LLocaisMap.AddOrSetValue(LLocalDestino.Id, LLocalDestino);

      if LLocalDestino.Tipo = ltBase then
        LLocalHub := LLocalDestino;
    end;

    if LLocalHub = nil then
      raise Exception.Create('Falha de roteamento: Base operacional (Hub) não localizada na matriz de locais.');

    // 2. Alimenta a fila de processamento em memória e pré-calcula distâncias estáticas
    for LPedido in APedidos do
    begin
      LPedidosPendentes.Add(LPedido);
      if LLocaisMap.TryGetValue(LPedido.LocalDestinoId.ToString, LLocalDestinoCandidato) then
      begin
        LPedidoDestinos.AddOrSetValue(LPedido, LLocalDestinoCandidato);
        if not LDistanciasRegresso.ContainsKey(LLocalDestinoCandidato) then
        begin
          // ⚡ Bolt: Performance Fix - Cache Haversine calculation to prevent O(N^2) evaluation
          LDistanciasRegresso.Add(LLocalDestinoCandidato, CalcularDistanciaKm(LLocalDestinoCandidato.Latitude, LLocalDestinoCandidato.Longitude, LLocalHub.Latitude, LLocalHub.Longitude));
        end;
      end;
    end;

    // 3. Orquestração da Frota
    for LDrone in ADrones do
    begin
      if LPedidosPendentes.Count = 0 then Break; // Operação concluída

      LCurrentLat := LLocalHub.Latitude;
      LCurrentLng := LLocalHub.Longitude;
      LCargaAtual := 0.0;
      LDistanciaPercorrida := 0.0;

      LArrayParadas := TJSONArray.Create;

      // Algoritmo Guloso (Nearest Neighbor) com Dupla Restrição (Payload e Autonomia)
      while LPedidosPendentes.Count > 0 do
      begin
        LMenorDistancia := MaxDouble;
        LPedidoMaisProximo := nil;
        LLocalDestino := nil;
        LMelhorIndex := -1;

        for I := 0 to LPedidosPendentes.Count - 1 do
        begin
          LPedido := LPedidosPendentes[I];

          // Restrição rápida de payload (impede cálculos desnecessários)
          if LCargaAtual + LPedido.PesoLiquido > LDrone.PayloadMaximo then
            Continue;

          // Resolve o ID do Destino em O(1) puro, sem conversão de string
          if not LPedidoDestinos.TryGetValue(LPedido, LLocalDestinoCandidato) then
            Continue;

          // ⚡ Bolt: Performance Fix - Add early lightweight arithmetic checks
          // Validate payload constraints before computationally expensive trigonometric Haversine math.
          if LCargaAtual + LPedido.PesoLiquido > LDrone.PayloadMaximo then
            Continue;

          LDistanciaAtePedido := CalcularDistanciaKm(LCurrentLat, LCurrentLng,
                                                     LLocalDestinoCandidato.Latitude, LLocalDestinoCandidato.Longitude);

          if LDistanciaAtePedido < LMenorDistancia then
          begin
            // Projetar o custo de bateria para o regresso à base
            // ⚡ Bolt: Performance Fix - O(1) Dictionary Lookup for static expensive Math calculation
            if not LDistanciasRegresso.TryGetValue(LLocalDestinoCandidato, LDistanciaRegresso) then
              Continue;

            // Validação absoluta das restrições de autonomia da aeronave
            if (LDistanciaPercorrida + LDistanciaAtePedido + LDistanciaRegresso <= LDrone.AutonomiaKm) then
            begin
              LMenorDistancia := LDistanciaAtePedido;
              LPedidoMaisProximo := LPedido;
              LLocalDestino := LLocalDestinoCandidato;
              LMelhorIndex := I;
            end;
          end;
        end;

        // Se a aeronave atingiu a capacidade máxima (peso ou bateria), encerra o turno deste drone
        if LPedidoMaisProximo = nil then Break;

        // Efetiva a alocação e desconta recursos com Swap-and-Pop O(1)
        LPedidosPendentes[LMelhorIndex] := LPedidosPendentes.Last;
        LPedidosPendentes.Delete(LPedidosPendentes.Count - 1);

        LCargaAtual := LCargaAtual + LPedidoMaisProximo.PesoLiquido;
        LDistanciaPercorrida := LDistanciaPercorrida + LMenorDistancia;
        LCurrentLat := LLocalDestino.Latitude;
        LCurrentLng := LLocalDestino.Longitude;

        // Registo tático da parada
        LArrayParadas.AddElement(TJSONObject.Create
          .AddPair('pedido_id', TJSONNumber.Create(LPedidoMaisProximo.Id))
          .AddPair('local_id', LLocalDestino.Id)
          .AddPair('nome_cliente', LLocalDestino.Nome)
          .AddPair('lat', TJSONNumber.Create(LLocalDestino.Latitude))
          .AddPair('lng', TJSONNumber.Create(LLocalDestino.Longitude))
        );
      end;

      if LArrayParadas.Count > 0 then
      begin
        // Consolida a distância com o trajeto de retorno à base operacional
        LDistanciaPercorrida := LDistanciaPercorrida + CalcularDistanciaKm(LCurrentLat, LCurrentLng, LLocalHub.Latitude, LLocalHub.Longitude);

        LObjRota := TJSONObject.Create;
        LObjRota.AddPair('drone_id', LDrone.Id);
        LObjRota.AddPair('drone_nome', LDrone.Nome);
        LObjRota.AddPair('payload_utilizado_kg', TJSONNumber.Create(LCargaAtual));
        LObjRota.AddPair('distancia_total_km', TJSONNumber.Create(LDistanciaPercorrida));
        LObjRota.AddPair('paradas', LArrayParadas);

        LArrayRotas.AddElement(LObjRota);
      end
      else
        LArrayParadas.Free;
    end;

    Result := LArrayRotas.ToJSON;
  finally
    LDistanciasRegresso.Free;
    LPedidoDestinos.Free;
    LLocaisMap.Free;
    LPedidosPendentes.Free;
    LArrayRotas.Free;
  end;
end;

end.
