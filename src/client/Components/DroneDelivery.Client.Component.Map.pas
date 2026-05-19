unit DroneDelivery.Client.Component.Map;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math, System.JSON,
  System.Generics.Collections, System.UITypes, System.Net.HttpClient,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Objects, FMX.Layouts;

type
  TMapNode = class
  public
    Lat, Lng: Double;
    LabelName: string;
    Battery: Double;
    IsHub: Boolean;
  end;

  TTileKey = string; // formato: 'z/x/y'

  TTileStatus = (tsNone, tsDownloading, tsReady);

  TTileInfo = class
    Status: TTileStatus;
    Bitmap: TBitmap;
    destructor Destroy; override;
  end;

  TGenericMap = class(TControl)
  private
    FMapCenterLat, FMapCenterLng: Double;
    FZoomLevel: Integer; // 0 to 19 (Web Mercator padrão)
    FNodes: TObjectList<TMapNode>;

    // Sistema de Cache de Tiles
    FTileCache: TObjectDictionary<TTileKey, TTileInfo>;

    // Controle de movimentação (Pan)
    FPanOffset: TPointF;
    FIsDragging: Boolean;
    FLastMousePos: TPointF;

    procedure DrawBackgroundGrid(Canvas: TCanvas; const ARect: TRectF);
    procedure DrawPolyline(Canvas: TCanvas; const ARect: TRectF);
    procedure DrawNodes(Canvas: TCanvas; const ARect: TRectF);

    function LatLngToPoint(ALat, ALng: Double): TPointF;
    procedure PointToLatLng(X, Y: Single; out ALat, ALng: Double);
    
    // Projeção Web Mercator
    function LonToTileX(Lon: Double; Zoom: Integer): Double;
    function LatToTileY(Lat: Double; Zoom: Integer): Double;
    
    procedure RequestTile(Z, X, Y: Integer);
    function GetTileKey(Z, X, Y: Integer): string;

  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearMap;
    procedure SetCenter(ALat, ALng: Double; AZoomLevel: Integer = 15);
    
    procedure DrawDroneMission(const AMissionJson: string);
    procedure ZoomIn;
    procedure ZoomOut;
  end;

implementation

{ TTileInfo }
destructor TTileInfo.Destroy;
begin
  if Assigned(Bitmap) then
    Bitmap.Free;
  inherited;
end;

{ TGenericMap }

constructor TGenericMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ClipChildren := True;
  HitTest := True;
  AutoCapture := True;
  
  FNodes := TObjectList<TMapNode>.Create(True);
  FTileCache := TObjectDictionary<TTileKey, TTileInfo>.Create([doOwnsValues]);
  
  FMapCenterLat := -23.5505;
  FMapCenterLng := -46.6333;
  FZoomLevel := 15; 
  FPanOffset := TPointF.Create(0, 0);
  FIsDragging := False;
end;

destructor TGenericMap.Destroy;
begin
  FTileCache.Free;
  FNodes.Free;
  inherited Destroy;
end;

// =======================================================================
// MATEMÁTICA DE PROJEÇÃO (Web Mercator - Spherical Mercator)
// =======================================================================

function TGenericMap.LonToTileX(Lon: Double; Zoom: Integer): Double;
begin
  Result := ((Lon + 180.0) / 360.0) * Power(2.0, Zoom);
end;

function TGenericMap.LatToTileY(Lat: Double; Zoom: Integer): Double;
var
  LatRad: Double;
begin
  LatRad := DegToRad(Lat);
  Result := (1.0 - (Ln(Tan(LatRad) + (1.0 / Cos(LatRad))) / PI)) / 2.0 * Power(2.0, Zoom);
end;

function TGenericMap.LatLngToPoint(ALat, ALng: Double): TPointF;
var
  CenterXTile, CenterYTile: Double;
  TargetXTile, TargetYTile: Double;
  CenterXScreen, CenterYScreen: Single;
begin
  CenterXScreen := Width / 2 + FPanOffset.X;
  CenterYScreen := Height / 2 + FPanOffset.Y;

  CenterXTile := LonToTileX(FMapCenterLng, FZoomLevel);
  CenterYTile := LatToTileY(FMapCenterLat, FZoomLevel);
  
  TargetXTile := LonToTileX(ALng, FZoomLevel);
  TargetYTile := LatToTileY(ALat, FZoomLevel);

  Result.X := CenterXScreen + ((TargetXTile - CenterXTile) * 256.0);
  Result.Y := CenterYScreen + ((TargetYTile - CenterYTile) * 256.0);
end;

procedure TGenericMap.PointToLatLng(X, Y: Single; out ALat, ALng: Double);
var
  CenterXTile, CenterYTile: Double;
  TargetXTile, TargetYTile: Double;
  CenterXScreen, CenterYScreen: Single;
  N: Double;
begin
  CenterXScreen := Width / 2 + FPanOffset.X;
  CenterYScreen := Height / 2 + FPanOffset.Y;

  CenterXTile := LonToTileX(FMapCenterLng, FZoomLevel);
  CenterYTile := LatToTileY(FMapCenterLat, FZoomLevel);

  TargetXTile := CenterXTile + ((X - CenterXScreen) / 256.0);
  TargetYTile := CenterYTile + ((Y - CenterYScreen) / 256.0);

  N := Power(2.0, FZoomLevel);
  ALng := (TargetXTile / N) * 360.0 - 180.0;
  ALat := RadToDeg(ArcTan(Sinh(PI * (1.0 - 2.0 * TargetYTile / N))));
end;

// =======================================================================
// ENGINE DE TILES / RENDERIZAÇÃO
// =======================================================================

function TGenericMap.GetTileKey(Z, X, Y: Integer): string;
begin
  Result := Format('%d/%d/%d', [Z, X, Y]);
end;

procedure TGenericMap.RequestTile(Z, X, Y: Integer);
var
  LKey: string;
  LUrl: string;
  LTile: TTileInfo;
begin
  LKey := GetTileKey(Z, X, Y);
  
  if FTileCache.TryGetValue(LKey, LTile) then Exit; 
  
  LTile := TTileInfo.Create;
  LTile.Status := tsDownloading;
  LTile.Bitmap := nil;
  FTileCache.Add(LKey, LTile);
  
  LUrl := Format('https://a.tile.openstreetmap.org/%d/%d/%d.png', [Z, X, Y]);
  
  TThread.CreateAnonymousThread(
    procedure
    var
      LStream: TMemoryStream;
      LResp: IHTTPResponse;
      LHttpLocal: THTTPClient;
    begin
      LStream := TMemoryStream.Create;
      LHttpLocal := THTTPClient.Create;
      try
        LHttpLocal.CustomHeaders['User-Agent'] := 'DroneLIVEry-App/1.0';
        try
          LResp := LHttpLocal.Get(LUrl, LStream);
          if (LResp.StatusCode = 200) and (LStream.Size > 0) then
          begin
            // Synchronize garante que as variáveis locais (LKey, LStream) permaneçam vivas
            // na memória até a UI terminar de desenhar o Bitmap
            TThread.Synchronize(nil, procedure
            var
              LUpdTile: TTileInfo;
              LBmp: TBitmap;
            begin
              if FTileCache.TryGetValue(LKey, LUpdTile) then
              begin
                LStream.Position := 0;
                LBmp := TBitmap.Create;
                try
                  LBmp.LoadFromStream(LStream);
                  LUpdTile.Bitmap := LBmp;
                  LUpdTile.Status := tsReady;
                  Self.Repaint;
                except
                  LBmp.Free;
                  FTileCache.Remove(LKey); // falhou a leitura, remove do cache
                end;
              end;
            end);
          end
          else
          begin
            TThread.Synchronize(nil, procedure
            begin
              FTileCache.Remove(LKey); // falhou HTTP, limpa para tentar de novo
            end);
          end;
        except
          TThread.Synchronize(nil, procedure
          begin
            FTileCache.Remove(LKey); 
          end);
        end;
      finally
        LStream.Free; // Sempre é seguro limpar pois Synchronize trava a thread
        LHttpLocal.Free;
      end;
    end).Start;
end;

procedure TGenericMap.ClearMap;
begin
  FNodes.Clear;
  FPanOffset := TPointF.Create(0, 0);
  Repaint;
end;

procedure TGenericMap.SetCenter(ALat, ALng: Double; AZoomLevel: Integer);
begin
  FMapCenterLat := ALat;
  FMapCenterLng := ALng;
  FZoomLevel := AZoomLevel;
  FPanOffset := TPointF.Create(0, 0);
  Repaint;
end;

procedure TGenericMap.ZoomIn;
begin
  if FZoomLevel < 19 then
  begin
    Inc(FZoomLevel);
    FPanOffset := TPointF.Create(FPanOffset.X * 2, FPanOffset.Y * 2);
    Repaint;
  end;
end;

procedure TGenericMap.ZoomOut;
begin
  if FZoomLevel > 1 then
  begin
    Dec(FZoomLevel);
    FPanOffset := TPointF.Create(FPanOffset.X / 2, FPanOffset.Y / 2);
    Repaint;
  end;
end;

procedure TGenericMap.DrawDroneMission(const AMissionJson: string);
var
  LJsonArray: TJSONArray;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LNode: TMapNode;
  i: Integer;
begin
  ClearMap;
  if AMissionJson.IsEmpty or (AMissionJson = '[]') then Exit;

  LJsonArray := TJSONObject.ParseJSONValue(AMissionJson) as TJSONArray;
  if Assigned(LJsonArray) then
  begin
    try
      for i := 0 to LJsonArray.Count - 1 do
      begin
        LObj := LJsonArray.Items[i] as TJSONObject;
        if Assigned(LObj) then
        begin
          LNode := TMapNode.Create;
          
          LVal := LObj.GetValue('lat');
          if Assigned(LVal) then
          begin
            if LVal is TJSONNumber then LNode.Lat := TJSONNumber(LVal).AsDouble
            else LNode.Lat := StrToFloatDef(LVal.Value.Replace('.', FormatSettings.DecimalSeparator).Replace(',', FormatSettings.DecimalSeparator), 0.0);
          end;
          
          LVal := LObj.GetValue('lng');
          if Assigned(LVal) then
          begin
            if LVal is TJSONNumber then LNode.Lng := TJSONNumber(LVal).AsDouble
            else LNode.Lng := StrToFloatDef(LVal.Value.Replace('.', FormatSettings.DecimalSeparator).Replace(',', FormatSettings.DecimalSeparator), 0.0);
          end;
          
          LNode.LabelName := LObj.GetValue<string>('label', '');
          
          LVal := LObj.GetValue('battery');
          if Assigned(LVal) then
          begin
            if LVal is TJSONNumber then LNode.Battery := TJSONNumber(LVal).AsDouble
            else LNode.Battery := StrToFloatDef(LVal.Value.Replace('.', FormatSettings.DecimalSeparator).Replace(',', FormatSettings.DecimalSeparator), 100.0);
          end else LNode.Battery := 100.0;
          
          LNode.IsHub := (i = 0) or (i = LJsonArray.Count - 1);
          
          FNodes.Add(LNode);
        end;
      end;
      
      // Auto-center nas cordenadas reais com nível de zoom padronizado (15)
      if FNodes.Count > 0 then
      begin
        SetCenter(FNodes[0].Lat, FNodes[0].Lng, 15);
      end;

    finally
      LJsonArray.Free;
    end;
  end;
  Repaint;
end;

procedure TGenericMap.Paint;
begin
  inherited Paint;
  if (Width = 0) or (Height = 0) then Exit;
  if not Assigned(Canvas) then Exit;

  Canvas.BeginScene;
  try
    DrawBackgroundGrid(Canvas, LocalRect);
    if FNodes.Count > 1 then DrawPolyline(Canvas, LocalRect);
    DrawNodes(Canvas, LocalRect);
  finally
    Canvas.EndScene;
  end;
end;

procedure TGenericMap.DrawBackgroundGrid(Canvas: TCanvas; const ARect: TRectF);
var
  CenterTileX, CenterTileY: Double;
  TopLeftTileX, TopLeftTileY: Integer;
  BottomRightTileX, BottomRightTileY: Integer;
  TX, TY: Integer;
  ScreenCenter, TileScreenPos: TPointF;
  TileRect: TRectF;
  LTile: TTileInfo;
  LKey: string;
begin
  // Background base para cobrir cantos enquanto os tiles carregam
  Canvas.Fill.Color := $FF0F172A; // slate-900
  Canvas.FillRect(ARect, 0, 0, AllCorners, 1);

  CenterTileX := LonToTileX(FMapCenterLng, FZoomLevel);
  CenterTileY := LatToTileY(FMapCenterLat, FZoomLevel);

  ScreenCenter.X := Width / 2 + FPanOffset.X;
  ScreenCenter.Y := Height / 2 + FPanOffset.Y;

  // Calculando limites visíveis baseados no offset da tela (Tiles de 256px)
  TopLeftTileX := Floor(CenterTileX - (ScreenCenter.X / 256.0));
  TopLeftTileY := Floor(CenterTileY - (ScreenCenter.Y / 256.0));
  
  BottomRightTileX := Floor(CenterTileX + ((Width - ScreenCenter.X) / 256.0));
  BottomRightTileY := Floor(CenterTileY + ((Height - ScreenCenter.Y) / 256.0));

  // Limitando aos maximos do OSM (para nao pedir tiles invalidos nos pólos)
  TopLeftTileX := Max(0, TopLeftTileX);
  TopLeftTileY := Max(0, TopLeftTileY);
  BottomRightTileX := Min(Trunc(Power(2, FZoomLevel)) - 1, BottomRightTileX);
  BottomRightTileY := Min(Trunc(Power(2, FZoomLevel)) - 1, BottomRightTileY);

  for TX := TopLeftTileX to BottomRightTileX do
  begin
    for TY := TopLeftTileY to BottomRightTileY do
    begin
      TileScreenPos.X := ScreenCenter.X + ((TX - CenterTileX) * 256.0);
      TileScreenPos.Y := ScreenCenter.Y + ((TY - CenterTileY) * 256.0);
      
      TileRect := TRectF.Create(TileScreenPos.X, TileScreenPos.Y, TileScreenPos.X + 256, TileScreenPos.Y + 256);
      
      LKey := GetTileKey(FZoomLevel, TX, TY);
      
      if FTileCache.TryGetValue(LKey, LTile) then
      begin
        if (LTile.Status = tsReady) and Assigned(LTile.Bitmap) then
        begin
          // Renderiza o Tile exato!
          Canvas.DrawBitmap(LTile.Bitmap, TRectF.Create(0, 0, 256, 256), TileRect, 1.0);
        end;
      end
      else
      begin
        // Dispara o download assincrono e segue a vida
        RequestTile(FZoomLevel, TX, TY);
      end;
      
      // Desenha gradezinha transparente opcional pra dar aspecto de radar
      Canvas.Stroke.Color := $15FFFFFF;
      Canvas.Stroke.Thickness := 1;
      Canvas.DrawRect(TileRect, 0, 0, AllCorners, 1);
    end;
  end;

  // OVERLAY DARK - Filtro Cyberpunk! (Deixa o mapa do OSM escuro e com o tom "slate")
  Canvas.Fill.Color := $D00F172A; // slate-900 com Alpha 80%
  Canvas.FillRect(ARect, 0, 0, AllCorners, 1);
end;

procedure TGenericMap.DrawPolyline(Canvas: TCanvas; const ARect: TRectF);
var
  i: Integer;
  P1, P2: TPointF;
begin
  Canvas.Stroke.Color := $FF38BDF8; // Azul neon
  Canvas.Stroke.Thickness := 3;
  Canvas.Stroke.Dash := TStrokeDash.Dash;

  for i := 0 to FNodes.Count - 2 do
  begin
    P1 := LatLngToPoint(FNodes[i].Lat, FNodes[i].Lng);
    P2 := LatLngToPoint(FNodes[i+1].Lat, FNodes[i+1].Lng);
    Canvas.DrawLine(P1, P2, 1);
  end;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
end;

procedure TGenericMap.DrawNodes(Canvas: TCanvas; const ARect: TRectF);
var
  i: Integer;
  Node: TMapNode;
  P: TPointF;
  NodeRect, TextRect: TRectF;
  BatColor: TAlphaColor;
begin
  for i := 0 to FNodes.Count - 1 do
  begin
    Node := FNodes[i];
    P := LatLngToPoint(Node.Lat, Node.Lng);

    // Circulo
    NodeRect := TRectF.Create(P.X - 8, P.Y - 8, P.X + 8, P.Y + 8);
    if Node.IsHub then
      Canvas.Fill.Color := $FFFACC15 // Amarelo
    else
      Canvas.Fill.Color := $FF38BDF8; // Azul neon

    Canvas.FillEllipse(NodeRect, 1);
    Canvas.Stroke.Color := $FFFFFFFF;
    Canvas.Stroke.Thickness := 2;
    Canvas.DrawEllipse(NodeRect, 1);

    // Bateria/Status
    if Node.Battery >= 40 then BatColor := $FF22C55E
    else if Node.Battery >= 20 then BatColor := $FFEAB308
    else BatColor := $FFEF4444;

    Canvas.Font.Size := 12;
    Canvas.Font.Family := 'Segoe UI';
    
    TextRect := TRectF.Create(P.X + 15, P.Y - 15, P.X + 150, P.Y + 15);
    
    Canvas.Fill.Color := $D0000000;
    Canvas.FillRect(TextRect, 4, 4, AllCorners, 1);

    Canvas.Fill.Color := $FFFFFFFF;
    TextRect.Top := TextRect.Top + 2;
    TextRect.Left := TextRect.Left + 5;
    Canvas.FillText(TextRect, Node.LabelName, False, 1, [], TTextAlign.Leading, TTextAlign.Leading);

    Canvas.Fill.Color := BatColor;
    TextRect.Top := TextRect.Top + 14;
    Canvas.FillText(TextRect, Format('Bat: %.1f%%', [Node.Battery]), False, 1, [], TTextAlign.Leading, TTextAlign.Leading);
  end;
end;

procedure TGenericMap.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = TMouseButton.mbLeft then
  begin
    FIsDragging := True;
    FLastMousePos := TPointF.Create(X, Y);
  end;
end;

procedure TGenericMap.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging then
  begin
    FPanOffset.X := FPanOffset.X + (X - FLastMousePos.X);
    FPanOffset.Y := FPanOffset.Y + (Y - FLastMousePos.Y);
    FLastMousePos := TPointF.Create(X, Y);
    Repaint;
  end;
end;

procedure TGenericMap.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FIsDragging and (Button = TMouseButton.mbLeft) then
  begin
    FIsDragging := False;
    
    // Atualiza centro real para evitar que FPanOffset cresca infinitamente ou quebre o Math dos Tiles
    PointToLatLng(Width / 2, Height / 2, FMapCenterLat, FMapCenterLng);
    FPanOffset := TPointF.Create(0, 0);
    Repaint;
  end;
end;

procedure TGenericMap.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  inherited MouseWheel(Shift, WheelDelta, Handled);
  if WheelDelta > 0 then
    ZoomIn
  else
    ZoomOut;
  Handled := True;
end;

end.
