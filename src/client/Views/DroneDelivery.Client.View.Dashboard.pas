unit DroneDelivery.Client.View.Dashboard;

{
  View Principal: Centro de Controle DroneLIVEry
  
  Módulos:
    - Frota de Drones  : Lista paginada de aeronaves com status e simulador de preço
    - Rotas & Logística: Mapa interativo (Leaflet/OSM), geocoding e simulação de bateria
    - Estação & Frota  : CRUD de drones com catálogo de modelos e configuração do Hangar
  
  Padrão de Navegação: View-Switch por Layout visibility (sem TTabControl)
  Padrão de Concorrência: TThread.CreateAnonymousThread + TThread.Synchronize
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.JSON, System.Net.HttpClient, System.Generics.Collections, System.RegularExpressions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Effects, FMX.Ani,
  FMX.Edit, FMX.ListBox, FMX.ComboEdit,
  DroneDelivery.DTO.Drones, DroneDelivery.Client.ViewModel.Dashboard,
  DroneDelivery.Client.Service.Maps, System.IOUtils,
  DroneDelivery.Client.Component.Map;

type
  { Enum para identificar a visão ativa }
  TActiveView = (avFleet, avOps, avCrud);

  TViewDashboard = class(TForm)
    rctSidebar: TRectangle;
    lblLogo: TLabel;
    lblMenuSectionFleet: TLabel;
    rctMenu1: TRectangle;
    lblMenu1: TLabel;
    lblMenuSectionOps: TLabel;
    rctMenu2: TRectangle;
    lblMenu2: TLabel;
    lblMenuSectionAdmin: TLabel;
    rctMenu3: TRectangle;
    lblMenu3: TLabel;
    rctBackground: TRectangle;
    rctHeader: TRectangle;
    lblTitle: TLabel;
    btnRefresh: TCornerButton;
    rctSeparator: TRectangle;
    ScrollDrones: TVertScrollBox;
    lytOps: TLayout;
    lytCrud: TLayout;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure MenuFleetClick(Sender: TObject);
    procedure MenuOpsClick(Sender: TObject);
    procedure MenuCrudClick(Sender: TObject);
    procedure OnLoadCatalogueClick(Sender: TObject);
    procedure OnDroneComboChange(Sender: TObject);

  private
    { Estado }
    FViewModel: TViewModelDashboard;
    FCards: TList<TRectangle>;
    FActiveView: TActiveView;
    FHubLat, FHubLng: Double;
    FWaypoints: TObjectList<TMapPoint>;
    FSelectedDroneId: string;
    FSelectedDroneRange: Double;
    FOpsDrones: TObjectList<TDroneDTO>;

    { Componentes do Modal de Preço }
    FModalOverlay: TRectangle;
    FModalPanel: TRectangle;
    FModalEditDist: TEdit;
    FModalLblResult: TLabel;
    FModalBtnConfirm, FModalBtnClose: TCornerButton;

    { Componentes da tela de Operações (Mapa) }
    FWebMap: TGenericMap;
    FEditWaypoint: TComboEdit;
    FLblMapStatus: TLabel;
    FListBoxWaypoints: TLayout;
    FWaypointCount: Integer;
    FComboDrone: TComboBox;
    FAutocompleteTimer: TTimer;
    FHangarAutocompleteTimer: TTimer;

    { Componentes da tela de CRUD }
    FEditCrudName: TEdit;
    FEditCrudPayload: TEdit;
    FEditCrudRange: TEdit;
    FEditCrudBattery: TEdit;
    FEditCrudSpeed: TEdit;
    FEditCrudImageUrl: TEdit;
    FEditCrudStatus: TEdit;
    FEditHangarAddress: TComboEdit;
    FLblCrudStatus: TLabel;

    { --- Módulo: Frota --- }
    procedure BuildDroneCard(ADrone: TDroneDTO);
    procedure ClearDroneCards;
    procedure SetActiveView(AView: TActiveView);
    procedure UpdateMenuHighlight(AActive: TActiveView);

    { --- Módulo: Modal de Preço (Frota) --- }
    procedure OnDroneActionClick(Sender: TObject);
    procedure ActionModalCloseClick(Sender: TObject);
    procedure ActionModalConfirmClick(Sender: TObject);
    procedure ActionModalKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);

    { --- Módulo: Operações / Mapa --- }
    procedure BuildOpsView;
    procedure AddWaypointToMap(const AAddress: string; ALat, ALng: Double);
    procedure RefreshMapRoute;
    procedure OnAddWaypointClick(Sender: TObject);
    procedure OnWaypointKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure OnClearRouteClick(Sender: TObject);
    procedure OnCalculateRouteClick(Sender: TObject);
    procedure OnWaypointEditChange(Sender: TObject);
    procedure OnAutocompleteTimer(Sender: TObject);
    procedure OnAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure OnHangarEditChange(Sender: TObject);
    procedure OnHangarAutocompleteTimer(Sender: TObject);
    procedure OnHangarAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem);

    { --- Módulo: CRUD / Estação --- }
    procedure BuildCrudView;
    procedure LoadCatalogueAsync;
    procedure OnBtnZoomInClick(Sender: TObject);
    procedure OnBtnZoomOutClick(Sender: TObject);
    procedure OnSaveDroneClick(Sender: TObject);
    procedure OnSaveHangarClick(Sender: TObject);
    procedure OnHangarKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure EnviarRotaAoMapa(const AJsonPontos: string);
    procedure ProcessHangarSave(const AAddr: string; ALat, ALng: Double);

  public
  end;

var
  ViewDashboard: TViewDashboard;

implementation

{$R *.fmx}

uses
  System.NetEncoding, FMX.Platform;

// ===========================================================================
// HELPERS DE ESTILO
// ===========================================================================

const
  COLOR_ACCENT   = $FF3B82F6;
  COLOR_SUCCESS  = $FF16A34A;
  COLOR_DANGER   = $FFDC2626;
  COLOR_DARK     = $FF1E293B;
  COLOR_MUTED    = $FF64748B;
  COLOR_BG       = $FFF3F4F6;
  COLOR_WHITE    = $FFFFFFFF;
  SIDEBAR_COLOR_ACTIVE = $FF2B2D42;
  SIDEBAR_COLOR_IDLE   = $FF1E1E2D;
  SIDEBAR_TEXT_ACTIVE  = $FFFFFFFF;
  SIDEBAR_TEXT_IDLE    = $FF94A3B8;

function MergeAddressWithNumber(const AOriginal, ASuggestion: string): string;
var
  LMatch: TMatch;
  LParts: TArray<string>;
  I: Integer;
begin
  Result := ASuggestion;
  LMatch := TRegEx.Match(AOriginal, '(?:,\s*|\s+)(\d+[A-Za-z]?)(?:\s*)$');
  if LMatch.Success then
  begin
    LParts := ASuggestion.Split([',']);
    var LHasNumber := False;
    for I := 0 to High(LParts) do
      if LParts[I].Trim = LMatch.Groups[1].Value then LHasNumber := True;
      
    if not LHasNumber then
    begin
      if Length(LParts) > 1 then
      begin
        Result := LParts[0].Trim + ', ' + LMatch.Groups[1].Value;
        for I := 1 to High(LParts) do
          Result := Result + ', ' + LParts[I].Trim;
      end else
        Result := ASuggestion + ', ' + LMatch.Groups[1].Value;
    end;
  end;
end;

function MakeLabel(AParent: TFmxObject; const AText: string; AFontSize: Single;
  AColor: TAlphaColor; ABold: Boolean = False): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.HitTest := False;
  Result.Font.Size := AFontSize;
  Result.TextSettings.FontColor := AColor;
  if ABold then Result.Font.Style := [TFontStyle.fsBold] else Result.Font.Style := [];
  Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor];
  Result.Text := AText;
  Result.HitTest := False;
end;

function MakeEdit(AParent: TFmxObject; const APrompt: string; AFontSize: Single = 14): TEdit;
begin
  Result := TEdit.Create(AParent);
  Result.Parent := AParent;
  Result.Font.Size := AFontSize;
  Result.TextPrompt := APrompt;
end;

function MakeComboEdit(AParent: TFmxObject; const APrompt: string; AFontSize: Single = 14): TComboEdit;
begin
  Result := TComboEdit.Create(AParent);
  Result.Parent := AParent;
  Result.Font.Size := AFontSize;
  Result.TextPrompt := APrompt;
end;

function MakeButton(AParent: TFmxObject; const AText: string; AColor: TAlphaColor = COLOR_ACCENT): TCornerButton;
begin
  Result := TCornerButton.Create(AParent);
  Result.Parent := AParent;
  Result.Text := AText;
  Result.XRadius := 6;
  Result.YRadius := 6;
  Result.Cursor := crHandPoint;
end;

// ===========================================================================
// INICIALIZAÇÃO
// ===========================================================================

procedure TViewDashboard.FormCreate(Sender: TObject);
begin
  FCards := TList<TRectangle>.Create;
  FViewModel := TViewModelDashboard.Create;
  FWaypoints := TObjectList<TMapPoint>.Create(True);
  FHubLat := -23.5505;
  FHubLng := -46.6333;
  FWaypointCount := 0;
  FSelectedDroneRange := 50.0;

  BuildOpsView;
  BuildCrudView;

  // Carrega Hub Database Assincronamente
  TThread.CreateAnonymousThread(procedure
  var
    LName: string; LLat, LLng: Double;
  begin
    if FViewModel.GetHangar(LName, LLat, LLng) then
      TThread.Synchronize(nil, procedure
      begin
        FHubLat := LLat; FHubLng := LLng;
        if Assigned(FEditHangarAddress) then FEditHangarAddress.Text := LName;
      end);
  end).Start;

  rctMenu1.Cursor := crHandPoint;
  rctMenu2.Cursor := crHandPoint;
  rctMenu3.Cursor := crHandPoint;
  btnRefresh.Cursor := crHandPoint;

  lblMenu1.HitTest := False;
  lblMenu2.HitTest := False;
  lblMenu3.HitTest := False;

  SetActiveView(avFleet);
  btnRefreshClick(nil);
end;

procedure TViewDashboard.FormDestroy(Sender: TObject);
begin
  if Assigned(FOpsDrones) then FOpsDrones.Free;
  FWaypoints.Free;
  FViewModel.Free;
  FCards.Free;
end;

procedure TViewDashboard.SetActiveView(AView: TActiveView);
begin
  FActiveView := AView;
  
  // Esconde TUDO primeiro para evitar sobreposição (ghosting)
  ScrollDrones.Visible := False;
  lytOps.Visible := False;
  lytCrud.Visible := False;
  if Assigned(FWebMap) then FWebMap.Visible := False; // Esconde a sub-janela nativa

  case AView of
    avFleet: 
    begin 
      lblTitle.Text := 'Drones Dispon'#237'veis'; 
      btnRefresh.Visible := True;
      ScrollDrones.Visible := True;
      ScrollDrones.BringToFront;
    end;
    avOps:   
    begin 
      lblTitle.Text := 'Rotas & Log'#237'stica'; 
      btnRefresh.Visible := False;
      lytOps.Visible := True;
      lytOps.BringToFront;
      // Repaint apenas se o mapa já estiver carregado e pronto
      if Assigned(FWebMap) then 
      begin
        FWebMap.Visible := True;
        FWebMap.BringToFront;
        FWebMap.Repaint;
      end;
    end;
    avCrud:  
    begin 
      lblTitle.Text := 'Esta'#231#227'o & Gest'#227'o de Frota'; 
      btnRefresh.Visible := False;
      lytCrud.Visible := True;
      lytCrud.BringToFront;
    end;
  end;
  UpdateMenuHighlight(AView);
end;

procedure TViewDashboard.UpdateMenuHighlight(AActive: TActiveView);
begin
  rctMenu1.Fill.Color := SIDEBAR_COLOR_IDLE; lblMenu1.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;
  rctMenu2.Fill.Color := SIDEBAR_COLOR_IDLE; lblMenu2.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;
  rctMenu3.Fill.Color := SIDEBAR_COLOR_IDLE; lblMenu3.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;
  case AActive of
    avFleet: begin rctMenu1.Fill.Color := SIDEBAR_COLOR_ACTIVE; lblMenu1.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE; end;
    avOps:   begin rctMenu2.Fill.Color := SIDEBAR_COLOR_ACTIVE; lblMenu2.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE; end;
    avCrud:  begin rctMenu3.Fill.Color := SIDEBAR_COLOR_ACTIVE; lblMenu3.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE; end;
  end;
end;

procedure TViewDashboard.MenuFleetClick(Sender: TObject); begin SetActiveView(avFleet); end;
procedure TViewDashboard.MenuOpsClick(Sender: TObject);
begin
  SetActiveView(avOps);
  if not Assigned(FViewModel) or not Assigned(FComboDrone) then Exit;
  FComboDrone.Items.Clear;
  FComboDrone.Items.Add('Carregando...');
  FComboDrone.ItemIndex := 0;
  TThread.CreateAnonymousThread(procedure
  var LList: TObjectList<TDroneDTO>;
  begin
    LList := FViewModel.LoadDrones;
    TThread.Synchronize(nil, procedure
    var LDrone: TDroneDTO;
    begin
      FComboDrone.Items.Clear;
      FComboDrone.Items.Add('(Selecione um drone)');
      if not Assigned(LList) then begin FComboDrone.Items[0] := 'Erro ao carregar drones'; Exit; end;
      if Assigned(FOpsDrones) then FOpsDrones.Free;
      FOpsDrones := LList;
      for LDrone in FOpsDrones do FComboDrone.Items.Add(Format('%s - %g Km', [LDrone.name, LDrone.max_range_km]));
      FComboDrone.ItemIndex := 0;
    end);
  end).Start;
end;

procedure TViewDashboard.MenuCrudClick(Sender: TObject); begin SetActiveView(avCrud); end;

// ===========================================================================
// MÓDULO: FROTA
// ===========================================================================

procedure TViewDashboard.btnRefreshClick(Sender: TObject);
var LAni: TAniIndicator;
begin
  ClearDroneCards;
  LAni := TAniIndicator.Create(Self); LAni.Parent := Self; LAni.Align := TAlignLayout.Center; LAni.Enabled := True;
  TThread.CreateAnonymousThread(procedure
  var LLista: TObjectList<TDroneDTO>;
  begin
    LLista := FViewModel.LoadDrones;
    TThread.Synchronize(nil, procedure
    var LDrone: TDroneDTO;
    begin
      LAni.Enabled := False; LAni.Free;
      if Assigned(LLista) then try for LDrone in LLista do BuildDroneCard(LDrone); finally LLista.Free; end;
    end);
  end).Start;
end;

procedure TViewDashboard.ClearDroneCards;
var LCard: TRectangle;
begin
  for LCard in FCards do LCard.Free;
  FCards.Clear;
end;

procedure TViewDashboard.BuildDroneCard(ADrone: TDroneDTO);
var
  LCard: TRectangle;
  LLayoutText: TLayout;
  LLblName, LLblSpec, LInitials, LBadgeLabel: TLabel;
  LShadow: TShadowEffect;
  LImgPlaceholder: TCircle;
  LBtnAction: TCornerButton;
  LBadge: TRoundRect;
begin
  LCard := TRectangle.Create(ScrollDrones); LCard.Parent := ScrollDrones; LCard.Align := TAlignLayout.Top;
  LCard.Height := 80; LCard.Margins.Bottom := 15; LCard.Fill.Color := COLOR_WHITE; LCard.Stroke.Kind := TBrushKind.None;
  LCard.XRadius := 8; LCard.YRadius := 8;

  LShadow := TShadowEffect.Create(LCard); LShadow.Parent := LCard; LShadow.Distance := 4; LShadow.Opacity := 0.08;

  LImgPlaceholder := TCircle.Create(LCard); LImgPlaceholder.Parent := LCard; LImgPlaceholder.Align := TAlignLayout.Left;
  LImgPlaceholder.Width := 60; LImgPlaceholder.Margins.Rect := TRectF.Create(10, 10, 0, 10);
  LImgPlaceholder.Fill.Color := $FFEFF6FF; LImgPlaceholder.Stroke.Kind := TBrushKind.None;

  LInitials := MakeLabel(LImgPlaceholder, Copy(ADrone.name, 1, 2).ToUpper, 20, COLOR_ACCENT, True);
  LInitials.Align := TAlignLayout.Client; LInitials.TextSettings.HorzAlign := TTextAlign.Center;

  if ADrone.image_url <> '' then
    TThread.CreateAnonymousThread(procedure
    var LHTTP: THTTPClient; LStream: TMemoryStream;
    begin
      LHTTP := THTTPClient.Create; LStream := TMemoryStream.Create;
      try
        LHTTP.Get(ADrone.image_url, LStream);
        if LStream.Size > 0 then TThread.Synchronize(nil, procedure
        begin
          LStream.Position := 0; LImgPlaceholder.Fill.Kind := TBrushKind.Bitmap; LImgPlaceholder.Fill.Bitmap.WrapMode := TWrapMode.TileStretch; LImgPlaceholder.Fill.Bitmap.Bitmap.LoadFromStream(LStream); LInitials.Visible := False;
        end);
      finally LStream.Free; LHTTP.Free; end;
    end).Start;

  LBtnAction := MakeButton(LCard, 'Testar Pre'#231'o'); LBtnAction.Align := TAlignLayout.Right; LBtnAction.Width := 130;
  LBtnAction.Margins.Rect := TRectF.Create(0, 20, 15, 20); LBtnAction.TagString := ADrone.id; LBtnAction.OnClick := OnDroneActionClick;

  LLayoutText := TLayout.Create(LCard); LLayoutText.Parent := LCard; LLayoutText.Align := TAlignLayout.Client; LLayoutText.Margins.Left := 20;
  LLblName := MakeLabel(LLayoutText, ADrone.name, 17, COLOR_DARK, True); LLblName.Align := TAlignLayout.Top; LLblName.Height := 35;

  LBadge := TRoundRect.Create(LLblName); LBadge.Parent := LLblName; LBadge.Position.X := 250; LBadge.Position.Y := 5; LBadge.Width := 80; LBadge.Height := 24; LBadge.Stroke.Kind := TBrushKind.None;
  LBadge.Fill.Color := IfThen(SameText(ADrone.status, 'available'), $FFDCFCE7, $FFFEE2E2);
  LBadgeLabel := MakeLabel(LBadge, ADrone.status.ToUpper, 11, IfThen(SameText(ADrone.status, 'available'), $FF166534, $FF991B1B));
  LBadgeLabel.Align := TAlignLayout.Client; LBadgeLabel.TextSettings.HorzAlign := TTextAlign.Center;

  LLblSpec := MakeLabel(LLayoutText, Format('%g Kg | %g Km | %g Km/h', [ADrone.max_payload_kg, ADrone.max_range_km, ADrone.speed_kmh]), 12, COLOR_MUTED);
  LLblSpec.Align := TAlignLayout.Bottom; LLblSpec.Height := 25;

  FCards.Add(LCard);
end;

// ===========================================================================
// MODAL PREÇO
// ===========================================================================

procedure TViewDashboard.ActionModalCloseClick(Sender: TObject);
begin
  if Assigned(FModalPanel) then FreeAndNil(FModalPanel);
  if Assigned(FModalOverlay) then FreeAndNil(FModalOverlay);
end;

procedure TViewDashboard.ActionModalConfirmClick(Sender: TObject);
var LDist: Double; LID: string;
begin
  LID := TCornerButton(Sender).TagString;
  LDist := StrToFloatDef(FModalEditDist.Text, 10.0);
  FModalLblResult.Visible := True; FModalLblResult.Text := 'Calculando...';
  if Assigned(FModalBtnConfirm) then FModalBtnConfirm.Enabled := False;
  TThread.CreateAnonymousThread(procedure
  var LAns: string;
  begin
    LAns := FViewModel.CalcularPreco(LID, LDist);
    TThread.Synchronize(nil, procedure
    begin
      FModalLblResult.Text := LAns; FModalBtnClose.Text := 'Fechar';
      if Assigned(FModalBtnConfirm) then FModalBtnConfirm.Enabled := True;
    end);
  end).Start;
end;

procedure TViewDashboard.ActionModalKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    ActionModalConfirmClick(FModalBtnConfirm);
    if Assigned(FModalEditDist) and FModalEditDist.CanFocus then
      FModalEditDist.SetFocus;
  end;
end;

procedure TViewDashboard.OnDroneActionClick(Sender: TObject);
var LLblTitle, LLblSubtitle: TLabel;
begin
  FModalOverlay := TRectangle.Create(Self); FModalOverlay.Parent := Self; FModalOverlay.Align := TAlignLayout.Contents; FModalOverlay.Fill.Color := $FF000000; FModalOverlay.Opacity := 0.5; FModalOverlay.Stroke.Kind := TBrushKind.None;
  FModalOverlay.OnClick := ActionModalCloseClick;
  FModalPanel := TRectangle.Create(Self); FModalPanel.Parent := Self; FModalPanel.Width := 370; FModalPanel.Height := 240;
  FModalPanel.Position.X := (Self.ClientWidth - FModalPanel.Width) / 2; FModalPanel.Position.Y := (Self.ClientHeight - FModalPanel.Height) / 2;
  FModalPanel.Fill.Color := COLOR_WHITE; FModalPanel.XRadius := 12; FModalPanel.YRadius := 12; FModalPanel.Stroke.Kind := TBrushKind.None;

  LLblTitle := MakeLabel(FModalPanel, 'Simulador de Pre'#231'o', 18, COLOR_DARK, True); LLblTitle.Align := TAlignLayout.Top; LLblTitle.Margins.Top := 20; LLblTitle.Height := 30; LLblTitle.TextSettings.HorzAlign := TTextAlign.Center;
  LLblSubtitle := MakeLabel(FModalPanel, 'Dist'#226'ncia (Km):', 12, COLOR_MUTED); LLblSubtitle.Position.Y := 60; LLblSubtitle.Width := 370; LLblSubtitle.TextSettings.HorzAlign := TTextAlign.Center;

  FModalEditDist := MakeEdit(FModalPanel, 'Ex: 15'); FModalEditDist.Position.X := 60; FModalEditDist.Position.Y := 85; FModalEditDist.Width := 250; FModalEditDist.Height := 40; FModalEditDist.Text := '10'; FModalEditDist.OnKeyDown := ActionModalKeyDown;
  FModalLblResult := MakeLabel(FModalPanel, '', 14, COLOR_DARK, True); FModalLblResult.Position.Y := 140; FModalLblResult.Width := 370; FModalLblResult.TextSettings.HorzAlign := TTextAlign.Center; FModalLblResult.Visible := False;

  FModalBtnConfirm := MakeButton(FModalPanel, 'Calcular'); FModalBtnConfirm.Position.X := 60; FModalBtnConfirm.Position.Y := 190; FModalBtnConfirm.Width := 120; FModalBtnConfirm.TagString := TCornerButton(Sender).TagString; FModalBtnConfirm.OnClick := ActionModalConfirmClick;
  FModalBtnClose := MakeButton(FModalPanel, 'Cancelar'); FModalBtnClose.Position.X := 200; FModalBtnClose.Position.Y := 190; FModalBtnClose.Width := 110; FModalBtnClose.OnClick := ActionModalCloseClick;
  if Assigned(FModalEditDist) and FModalEditDist.CanFocus then
    FModalEditDist.SetFocus;
end;

// ===========================================================================
// OPERAÇÕES / MAPA
// ===========================================================================

procedure TViewDashboard.EnviarRotaAoMapa(const AJsonPontos: string);
begin
  TThread.Synchronize(nil, procedure begin FWebMap.DrawDroneMission(AJsonPontos); end);
end;

procedure TViewDashboard.BuildOpsView;
var
  LPainelEsq, LPainelMapBg: TRectangle;
  LPanelBottom, LZoomLayout: TLayout;
  LLblTitle, LLblOpsWaypointTitle, LLblDroneTitle, LLblHintDrone: TLabel;
  LBtnAdd, LBtnCalc, LBtnClear, LBtnZoomIn, LBtnZoomOut: TCornerButton;
  LSeparator: TRectangle;
  LMapPath: string;
begin
  if not Assigned(lytOps) then Exit;
  if lytOps.ChildrenCount > 0 then Exit; // Prevenir duplicidade

  { --- Fundo solido para isolamento total --- }
  LPainelMapBg := TRectangle.Create(lytOps);
  LPainelMapBg.Parent := lytOps;
  LPainelMapBg.Align := TAlignLayout.Client;
  LPainelMapBg.Fill.Color := COLOR_BG;
  LPainelMapBg.Stroke.Kind := TBrushKind.None;

  { --- Painel esquerdo fixo --- }
  LPainelEsq := TRectangle.Create(lytOps);
  LPainelEsq.Parent := lytOps;
  LPainelEsq.Align := TAlignLayout.Left;
  LPainelEsq.Width := 290;
  LPainelEsq.Fill.Color := COLOR_WHITE;
  LPainelEsq.Stroke.Color := $FFEAECF0;

  { --- WebBrowser / Mapa --- }
  FWebMap := TGenericMap.Create(lytOps);
  FWebMap.Parent := lytOps;
  FWebMap.Align := TAlignLayout.Client;

  { --- Controles de Zoom --- }
  LZoomLayout := TLayout.Create(lytOps);
  LZoomLayout.Parent := lytOps;
  LZoomLayout.Align := TAlignLayout.Right;
  LZoomLayout.Width := 70;
  
  LBtnZoomOut := MakeButton(LZoomLayout, '-');
  LBtnZoomOut.Align := TAlignLayout.Bottom;
  LBtnZoomOut.Height := 45;
  LBtnZoomOut.Margins.Rect := TRectF.Create(10, 0, 15, 25);
  LBtnZoomOut.OnClick := OnBtnZoomOutClick;

  LBtnZoomIn := MakeButton(LZoomLayout, '+');
  LBtnZoomIn.Align := TAlignLayout.Bottom;
  LBtnZoomIn.Height := 45;
  LBtnZoomIn.Margins.Rect := TRectF.Create(10, 0, 15, 10);
  LBtnZoomIn.OnClick := OnBtnZoomInClick;

  { --- Ordem Visual Idêntica ao Design Original --- }
  LLblTitle := MakeLabel(LPainelEsq, 'Rotas e Log'#237'stica', 15, COLOR_DARK, True);
  LLblTitle.Align := TAlignLayout.Top;
  LLblTitle.Margins.Rect := TRectF.Create(20, 16, 0, 10);
  LLblTitle.Height := 30;
  LLblTitle.Position.Y := 0;

  FEditWaypoint := MakeComboEdit(LPainelEsq, 'Endere'#231'o da Parada...');
  FEditWaypoint.Align := TAlignLayout.Top;
  FEditWaypoint.Height := 40;
  FEditWaypoint.Margins.Rect := TRectF.Create(12, 5, 12, 5);
  FEditWaypoint.Position.Y := 40;
  FEditWaypoint.OnChangeTracking := OnWaypointEditChange;
  FEditWaypoint.OnKeyDown := OnWaypointKeyDown;

  FAutocompleteTimer := TTimer.Create(Self);
  FAutocompleteTimer.Interval := 400;
  FAutocompleteTimer.Enabled := False;
  FAutocompleteTimer.OnTimer := OnAutocompleteTimer;

  LLblDroneTitle := MakeLabel(LPainelEsq, 'Aeronave para a Miss'#227'o', 13, COLOR_DARK, True);
  LLblDroneTitle.Align := TAlignLayout.Top;
  LLblDroneTitle.Margins.Rect := TRectF.Create(16, 15, 0, 5);
  LLblDroneTitle.Position.Y := 135;

  FComboDrone := TComboBox.Create(LPainelEsq);
  FComboDrone.Parent := LPainelEsq;
  FComboDrone.Align := TAlignLayout.Top;
  FComboDrone.Height := 38;
  FComboDrone.Margins.Rect := TRectF.Create(12, 0, 12, 5);
  FComboDrone.Position.Y := 140;
  FComboDrone.Items.Add('(Selecione um drone)');
  FComboDrone.ItemIndex := 0;
  FComboDrone.OnChange := OnDroneComboChange;
  FComboDrone.Cursor := crHandPoint;

  LLblHintDrone := MakeLabel(LPainelEsq, 'Acesse o menu para carregar a lista.', 10, COLOR_MUTED);
  LLblHintDrone.Align := TAlignLayout.Top;
  LLblHintDrone.Margins.Rect := TRectF.Create(16, 2, 0, 0);
  LLblHintDrone.Position.Y := 155;

  LLblOpsWaypointTitle := MakeLabel(LPainelEsq, 'Paradas da Miss'#227'o', 14, COLOR_DARK, True);
  LLblOpsWaypointTitle.Align := TAlignLayout.Top;
  LLblOpsWaypointTitle.Margins.Rect := TRectF.Create(16, 15, 0, 5);
  LLblOpsWaypointTitle.Position.Y := 185;

  LBtnAdd := MakeButton(LPainelEsq, '+ Adicionar Parada');
  LBtnAdd.Align := TAlignLayout.Top;
  LBtnAdd.Height := 38;
  LBtnAdd.Margins.Rect := TRectF.Create(12, 5, 12, 10);
  LBtnAdd.Position.Y := 220;
  LBtnAdd.OnClick := OnAddWaypointClick;

  FListBoxWaypoints := TLayout.Create(LPainelEsq);
  FListBoxWaypoints.Parent := LPainelEsq;
  FListBoxWaypoints.Align := TAlignLayout.Top;
  FListBoxWaypoints.Height := 0;
  FListBoxWaypoints.Position.Y := 265;

  LPanelBottom := TLayout.Create(LPainelEsq);
  LPanelBottom.Parent := LPainelEsq;
  LPanelBottom.Align := TAlignLayout.MostBottom;
  LPanelBottom.Height := 120;

  LBtnClear := MakeButton(LPanelBottom, 'Limpar Rota');
  LBtnClear.Align := TAlignLayout.Bottom;
  LBtnClear.Margins.Rect := TRectF.Create(12, 0, 12, 2);
  LBtnClear.OnClick := OnClearRouteClick;

  LBtnCalc := MakeButton(LPanelBottom, 'Calcular Rota');
  LBtnCalc.Align := TAlignLayout.Bottom;
  LBtnCalc.Margins.Rect := TRectF.Create(12, 0, 12, 4);
  LBtnCalc.OnClick := OnCalculateRouteClick;

  FLblMapStatus := MakeLabel(LPanelBottom, 'Pronto.', 10, COLOR_MUTED);
  FLblMapStatus.Align := TAlignLayout.MostBottom;
  FLblMapStatus.Margins.Left := 12;
end;


procedure TViewDashboard.OnWaypointEditChange(Sender: TObject);
begin 
  FAutocompleteTimer.Enabled := False; 
  if FEditWaypoint.Items.IndexOf(FEditWaypoint.Text) >= 0 then Exit;
  if Length(FEditWaypoint.Text) >= 3 then FAutocompleteTimer.Enabled := True; 
end;

procedure TViewDashboard.OnAutocompleteTimer(Sender: TObject);
begin
  FAutocompleteTimer.Enabled := False;
  TMapService.SearchAddressSuggestionsAsync(FEditWaypoint.Text, procedure(ASugg: TArray<string>)
  var I: Integer; 
      LMerged: string;
      LSavedText: string;
      LSavedSel: Integer;
  begin 
    LSavedText := FEditWaypoint.Text;
    LSavedSel := FEditWaypoint.SelStart;
    
    FEditWaypoint.OnChangeTracking := nil;
    try
      FEditWaypoint.Items.Clear; 
      for I := 0 to High(ASugg) do 
      begin
        FEditWaypoint.Items.Add(ASugg[I]);
      end;
      FEditWaypoint.Text := LSavedText;
      FEditWaypoint.SelStart := LSavedSel;
      
      if Length(ASugg) > 0 then
      begin
        FEditWaypoint.DropDown;
        FEditWaypoint.Text := LSavedText;
        FEditWaypoint.SelStart := LSavedSel;
      end;
    finally
      FEditWaypoint.OnChangeTracking := OnWaypointEditChange;
    end;
  end, 
  procedure(E: string) begin end);
end;

procedure TViewDashboard.OnAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem);
begin 
  // No longer needed for ComboEdit
end;

procedure TViewDashboard.OnWaypointKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    OnAddWaypointClick(nil);
    if Assigned(FEditWaypoint) and FEditWaypoint.CanFocus then
      FEditWaypoint.SetFocus;
  end;
end;

procedure TViewDashboard.OnAddWaypointClick(Sender: TObject);
var
  LSearchedText: string;
begin
  LSearchedText := FEditWaypoint.Text.Trim;
  if LSearchedText.IsEmpty then
  begin
    FLblMapStatus.Text := 'Aten'#231#227'o: Digite um endere'#231'o v'#225'lido para adicionar.';
    Exit;
  end;

  if Sender is TCornerButton then
  begin
    TCornerButton(Sender).Enabled := False;
    TCornerButton(Sender).Text := 'Buscando...';
  end;

  FLblMapStatus.Text := 'Buscando endere'#231'o...';
  TMapService.GeocodeAddressAsync(LSearchedText,
    procedure(Lat, Lng: Double)
    begin
      TThread.Synchronize(nil, procedure
      begin
        AddWaypointToMap(LSearchedText, Lat, Lng);
        FEditWaypoint.Text := '';
        FLblMapStatus.Text := 'Parada adicionada: ' + LSearchedText;
        if Sender is TCornerButton then
        begin
          TCornerButton(Sender).Enabled := True;
          TCornerButton(Sender).Text := '+ Adicionar Parada';
        end;
      end);
    end,
    procedure(E: string)
    begin
      TThread.Synchronize(nil, procedure
      begin
        FLblMapStatus.Text := E;
        if Sender is TCornerButton then
        begin
          TCornerButton(Sender).Enabled := True;
          TCornerButton(Sender).Text := '+ Adicionar Parada';
        end;
      end);
    end);
end;

procedure TViewDashboard.AddWaypointToMap(const AAddress: string; ALat, ALng: Double);
var LPoint: TMapPoint; LLbl: TLabel;
begin
  Inc(FWaypointCount); LPoint := TMapPoint.Create(ALat, ALng, AAddress); FWaypoints.Add(LPoint);
  LLbl := MakeLabel(FListBoxWaypoints, Format('%d. %s', [FWaypointCount, AAddress]), 11, COLOR_DARK); LLbl.Align := TAlignLayout.Top; LLbl.Height := 22; FListBoxWaypoints.Height := FListBoxWaypoints.Height + 22;
  RefreshMapRoute;
end;

procedure TViewDashboard.OnClearRouteClick(Sender: TObject);
begin
  FWaypoints.Clear; FWaypointCount := 0; while FListBoxWaypoints.ChildrenCount > 0 do FListBoxWaypoints.Children[0].Free; FListBoxWaypoints.Height := 0;
  if Assigned(FWebMap) then FWebMap.ClearMap;
  FLblMapStatus.Text := 'Rota limpa. Pronto para nova miss'#227'o.';
end;

procedure TViewDashboard.RefreshMapRoute;
var LHub: TMapPoint; LPayload: string;
begin
  LHub := TMapPoint.Create(FHubLat, FHubLng, 'HUB');
  try LPayload := TMapService.GenerateRoutePayload(LHub, FWaypoints, FSelectedDroneRange, 0); finally LHub.Free; end;
  if Assigned(FWebMap) then FWebMap.DrawDroneMission(LPayload);
end;

procedure TViewDashboard.OnCalculateRouteClick(Sender: TObject);
begin
  if FSelectedDroneId.IsEmpty then
  begin
    FLblMapStatus.Text := 'Aten'#231#227'o: Selecione uma aeronave antes de calcular a rota.';
    Exit;
  end;
  if FWaypoints.Count = 0 then
  begin
    FLblMapStatus.Text := 'Aten'#231#227'o: Adicione pelo menos uma parada na miss'#227'o.';
    Exit;
  end;

  if Sender is TCornerButton then
  begin
    TCornerButton(Sender).Enabled := False;
    TCornerButton(Sender).Text := 'Calculando...';
  end;

  FLblMapStatus.Text := 'Calculando rota... aguarde.';
  FViewModel.CalcularRota(FSelectedDroneId, FWaypoints,
    procedure(Resp: string)
    begin
      EnviarRotaAoMapa(Resp);
      TThread.Synchronize(nil, procedure
      begin
        FLblMapStatus.Text := 'Rota calculada e enviada ao mapa.';
        if Sender is TCornerButton then
        begin
          TCornerButton(Sender).Enabled := True;
          TCornerButton(Sender).Text := 'Calcular Rota';
        end;
      end);
    end,
    procedure(E: string)
    begin
      TThread.Synchronize(nil, procedure
      begin
        FLblMapStatus.Text := E;
        if Sender is TCornerButton then
        begin
          TCornerButton(Sender).Enabled := True;
          TCornerButton(Sender).Text := 'Calcular Rota';
        end;
      end);
    end);
end;

procedure TViewDashboard.OnBtnZoomInClick(Sender: TObject);
begin
  if Assigned(FWebMap) then FWebMap.ZoomIn;
end;

procedure TViewDashboard.OnBtnZoomOutClick(Sender: TObject);
begin
  if Assigned(FWebMap) then FWebMap.ZoomOut;
end;

// ===========================================================================
// CRUD
// ===========================================================================

procedure TViewDashboard.BuildCrudView;
var
  LPainelLeft, LPainelCatalogue, LPainelHangar, LMainBg: TRectangle;
  LScroll: TVertScrollBox;
  LInner: TLayout;
  LLbl: TLabel;
  LBtn: TCornerButton;
begin
  if not Assigned(lytCrud) then Exit;
  if lytCrud.ChildrenCount > 0 then Exit; // Prevenir duplicidade

  LMainBg := TRectangle.Create(lytCrud);
  LMainBg.Parent := lytCrud;
  LMainBg.Align := TAlignLayout.Client;
  LMainBg.Fill.Color := COLOR_BG;
  LMainBg.Stroke.Kind := TBrushKind.None;

  LPainelLeft := TRectangle.Create(lytCrud);
  LPainelLeft.Parent := lytCrud;
  LPainelLeft.Align := TAlignLayout.Left;
  LPainelLeft.Width := 350;
  LPainelLeft.Fill.Color := COLOR_WHITE;
  LPainelLeft.Stroke.Color := $FFEAECF0;

  LScroll := TVertScrollBox.Create(LPainelLeft);
  LScroll.Parent := LPainelLeft;
  LScroll.Align := TAlignLayout.Client;

  LInner := TLayout.Create(LScroll);
  LInner.Parent := LScroll;
  LInner.Align := TAlignLayout.Top;
  LInner.Height := 520;

  { --- Ordem Vertical do Cadastro --- }
  LLbl := MakeLabel(LInner, 'Cadastro de Aeronave', 16, COLOR_DARK, True);
  LLbl.Position.Y := 10;
  LLbl.Align := TAlignLayout.Top;
  LLbl.Margins.Rect := TRectF.Create(20, 20, 0, 20);

  FEditCrudName := MakeEdit(LInner, 'Nome do Modelo');
  FEditCrudName.Align := TAlignLayout.Top;
  FEditCrudName.Margins.Rect := TRectF.Create(16, 10, 16, 0);
  FEditCrudName.Position.Y := 40;

  FEditCrudPayload := MakeEdit(LInner, 'Carga M'#225'xima (Kg)');
  FEditCrudPayload.Align := TAlignLayout.Top;
  FEditCrudPayload.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudPayload.Position.Y := 90;

  FEditCrudRange := MakeEdit(LInner, 'Alcance M'#225'ximo (Km)');
  FEditCrudRange.Align := TAlignLayout.Top;
  FEditCrudRange.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudRange.Position.Y := 140;

  FEditCrudBattery := MakeEdit(LInner, 'Bateria (Wh)');
  FEditCrudBattery.Align := TAlignLayout.Top;
  FEditCrudBattery.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudBattery.Position.Y := 190;

  FEditCrudSpeed := MakeEdit(LInner, 'Velocidade (Km/h)');
  FEditCrudSpeed.Align := TAlignLayout.Top;
  FEditCrudSpeed.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudSpeed.Position.Y := 240;

  FEditCrudImageUrl := MakeEdit(LInner, 'URL da Imagem');
  FEditCrudImageUrl.Align := TAlignLayout.Top;
  FEditCrudImageUrl.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudImageUrl.Position.Y := 290;

  FEditCrudStatus := MakeEdit(LInner, 'Status (available/maintenance)');
  FEditCrudStatus.Align := TAlignLayout.Top;
  FEditCrudStatus.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudStatus.Position.Y := 340;

  LBtn := MakeButton(LInner, 'Salvar Drone');
  LBtn.Align := TAlignLayout.Top;
  LBtn.Margins.Rect := TRectF.Create(16, 20, 16, 0);
  LBtn.Position.Y := 400;
  LBtn.OnClick := OnSaveDroneClick;

  FLblCrudStatus := MakeLabel(LInner, '', 11, COLOR_MUTED);
  FLblCrudStatus.Position.Y := 450;
  FLblCrudStatus.Align := TAlignLayout.Top;
  FLblCrudStatus.Margins.Left := 16;

  { --- Catálogo --- }
  LPainelCatalogue := TRectangle.Create(lytCrud);
  LPainelCatalogue.Parent := lytCrud;
  LPainelCatalogue.Align := TAlignLayout.Client;
  LPainelCatalogue.Fill.Color := COLOR_BG;
  LPainelCatalogue.Margins.Left := 8;

  LLbl := MakeLabel(LPainelCatalogue, 'Cat'#225'logo de Modelos Sugeridos', 15, COLOR_DARK, True);
  LLbl.Align := TAlignLayout.Top;
  LLbl.Margins.Rect := TRectF.Create(16, 16, 0, 8);

  LBtn := MakeButton(LPainelCatalogue, 'Buscar Cat'#225'logo');
  LBtn.Align := TAlignLayout.Top;
  LBtn.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  LBtn.OnClick := OnLoadCatalogueClick;

  { --- Hangar --- }
  LPainelHangar := TRectangle.Create(lytCrud);
  LPainelHangar.Parent := lytCrud;
  LPainelHangar.Align := TAlignLayout.Bottom;
  LPainelHangar.Height := 120;
  LPainelHangar.Fill.Color := COLOR_WHITE;
  LPainelHangar.Stroke.Kind := TBrushKind.None;

  LLbl := MakeLabel(LPainelHangar, 'Configura'#231#227'o do Hangar Base', 14, COLOR_DARK, True);
  LLbl.Align := TAlignLayout.Top;
  LLbl.Margins.Rect := TRectF.Create(16, 12, 0, 0);
  LLbl.Position.Y := 10;

  FEditHangarAddress := MakeComboEdit(LPainelHangar, 'Endere'#231'o do CD Base...');
  FEditHangarAddress.Align := TAlignLayout.Top;
  FEditHangarAddress.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditHangarAddress.Position.Y := 40;
  FEditHangarAddress.OnChangeTracking := OnHangarEditChange;
  FEditHangarAddress.OnKeyDown := OnHangarKeyDown;

  FHangarAutocompleteTimer := TTimer.Create(Self);
  FHangarAutocompleteTimer.Interval := 400;
  FHangarAutocompleteTimer.Enabled := False;
  FHangarAutocompleteTimer.OnTimer := OnHangarAutocompleteTimer;

  LBtn := MakeButton(LPainelHangar, 'Atualizar Localiza'#231#227'o');
  LBtn.Align := TAlignLayout.Top;
  LBtn.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  LBtn.Position.Y := 80;
  LBtn.OnClick := OnSaveHangarClick;
end;

procedure TViewDashboard.OnDroneComboChange(Sender: TObject);
var idx: Integer;
begin
  idx := FComboDrone.ItemIndex - 1;
  if (idx < 0) or (FOpsDrones = nil) or (idx >= FOpsDrones.Count) then Exit;
  FSelectedDroneId := FOpsDrones[idx].id; FSelectedDroneRange := FOpsDrones[idx].max_range_km;
end;

procedure TViewDashboard.OnLoadCatalogueClick(Sender: TObject); begin LoadCatalogueAsync; end;
procedure TViewDashboard.LoadCatalogueAsync; begin { Implementação async de catálogo } end;
procedure TViewDashboard.OnSaveDroneClick(Sender: TObject); begin end;
procedure TViewDashboard.ProcessHangarSave(const AAddr: string; ALat, ALng: Double);
begin
  // 1. Atualização Otimista da UI (Executa no Main Thread imediatamente!)
  FHubLat := ALat; 
  FHubLng := ALng;
  if Assigned(FWebMap) then FWebMap.SetCenter(ALat, ALng);
  RefreshMapRoute;

  // 2. Persistência Assíncrona no Backend (Thread paralela)
  TThread.CreateAnonymousThread(procedure
  var
    LSaved: Boolean;
  begin
    try
      LSaved := FViewModel.GravarHangar(AAddr, ALat, ALng);
    except
      LSaved := False; // Falha na conexão ou Timeout
    end;

    // 3. Feedback visual (Sincronizado de volta para a UI)
    TThread.Synchronize(nil, procedure
    begin
      if LSaved then
        ShowMessage('Endere'#231'o do Hub Base atualizado com sucesso no PostgreSQL!')
      else
        ShowMessage('Aviso: O local do Hub foi atualizado no mapa, mas houve falha de conex'#227'o ao gravar no Backend.');
    end);
  end).Start;
end;

procedure TViewDashboard.OnHangarKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    OnSaveHangarClick(nil);
    if Assigned(FEditHangarAddress) and FEditHangarAddress.CanFocus then
      FEditHangarAddress.SetFocus;
  end;
end;

procedure TViewDashboard.OnSaveHangarClick(Sender: TObject);
var LAddr: string;
begin
  LAddr := FEditHangarAddress.Text.Trim;
  if LAddr.IsEmpty then Exit;
  
  TMapService.GeocodeAddressAsync(LAddr,
    procedure(Lat, Lng: Double)
    begin
      ProcessHangarSave(LAddr, Lat, Lng);
    end,
    procedure(E: string)
    begin
      ShowMessage('Local n'#227'o encontrado no mapa global. Tente ser mais espec'#237'fico. Erro: ' + E);
    end
  );
end;

procedure TViewDashboard.OnHangarEditChange(Sender: TObject);
begin 
  FHangarAutocompleteTimer.Enabled := False; 
  if FEditHangarAddress.Items.IndexOf(FEditHangarAddress.Text) >= 0 then Exit;
  if Length(FEditHangarAddress.Text) >= 3 then FHangarAutocompleteTimer.Enabled := True; 
end;

procedure TViewDashboard.OnHangarAutocompleteTimer(Sender: TObject);
begin
  FHangarAutocompleteTimer.Enabled := False;
  TMapService.SearchAddressSuggestionsAsync(FEditHangarAddress.Text, procedure(ASugg: TArray<string>)
  var I: Integer; 
      LMerged: string;
      LSavedText: string;
      LSavedSel: Integer;
  begin 
    LSavedText := FEditHangarAddress.Text;
    LSavedSel := FEditHangarAddress.SelStart;
    
    FEditHangarAddress.OnChangeTracking := nil;
    try
      FEditHangarAddress.Items.Clear; 
      for I := 0 to High(ASugg) do 
      begin
        FEditHangarAddress.Items.Add(ASugg[I]);
      end;
      FEditHangarAddress.Text := LSavedText;
      FEditHangarAddress.SelStart := LSavedSel;

      if Length(ASugg) > 0 then
      begin
        FEditHangarAddress.DropDown;
        FEditHangarAddress.Text := LSavedText;
        FEditHangarAddress.SelStart := LSavedSel;
      end;
    finally
      FEditHangarAddress.OnChangeTracking := OnHangarEditChange;
    end;
  end, 
  procedure(E: string) begin end);
end;

procedure TViewDashboard.OnHangarAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem);
begin 
  // No longer needed for ComboEdit
end;

end.
