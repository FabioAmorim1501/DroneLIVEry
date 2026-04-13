unit DroneDelivery.Client.View.Dashboard;

{
  View Principal: Centro de Controle DroneLIVEry
  
  MÃ³dulos:
    - Frota de Drones  : Lista paginada de aeronaves com status e simulador de preÃ§o
    - Rotas & LogÃ­stica: Mapa interativo (Leaflet/OSM), geocoding e simulaÃ§Ã£o de bateria
    - EstaÃ§Ã£o & Frota  : CRUD de drones com catÃ¡logo de modelos e configuraÃ§Ã£o do Hangar
  
  PadrÃ£o de NavegaÃ§Ã£o: View-Switch por Layout visibility (sem TTabControl)
  PadrÃ£o de ConcorrÃªncia: TThread.CreateAnonymousThread + TThread.Synchronize
}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.JSON, System.Net.HttpClient, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Effects, FMX.Ani,
  FMX.Edit, FMX.WebBrowser, FMX.ListBox,
  DroneDelivery.DTO.Drones, DroneDelivery.Client.ViewModel.Dashboard,
  DroneDelivery.Client.Service.Maps;

type
  { Enum para identificar a visÃ£o ativa }
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
    procedure lblTitleClick(Sender: TObject);

  private
    { Estado }
    FViewModel: TViewModelDashboard;
    FCards: TList<TRectangle>;
    FActiveView: TActiveView;
    FHubLat, FHubLng: Double;
    FWaypoints: TObjectList<TMapPoint>;
    FSelectedDroneId: string;
    FSelectedDroneRange: Double;

    { Componentes do Modal de PreÃ§o }
    FModalOverlay: TRectangle;
    FModalPanel: TRectangle;
    FModalEditDist: TEdit;
    FModalLblResult: TLabel;
    FModalBtnConfirm, FModalBtnClose: TCornerButton;

    { Componentes da tela de OperaÃ§Ãµes (Mapa) }
    FWebMap: TWebBrowser;
    FEditWaypoint: TEdit;
    FLblMapStatus: TLabel;
    FListBoxWaypoints: TLayout;  // Container scrollÃ¡vel de waypoints adicionados
    FWaypointCount: Integer;
    FComboDrone: TComboBox;      // Seletor de aeronave para a missÃ£o
    FAutocompleteList: TListBox; // Dropdown de sugestÃµes de endereÃ§o
    FAutocompleteTimer: TTimer;  // Debounce de 400ms antes de disparar Nominatim

    { Componentes da tela de CRUD }
    FEditCrudName: TEdit;
    FEditCrudPayload: TEdit;
    FEditCrudRange: TEdit;
    FEditCrudBattery: TEdit;
    FEditCrudSpeed: TEdit;
    FEditCrudImageUrl: TEdit;
    FEditCrudStatus: TEdit;
    FEditHangarAddress: TEdit;
    FLblCrudStatus: TLabel;

    { --- MÃ³dulo: Frota --- }
    procedure BuildDroneCard(ADrone: TDroneDTO);
    procedure ClearDroneCards;
    procedure SetActiveView(AView: TActiveView);
    procedure UpdateMenuHighlight(AActive: TActiveView);

    { --- MÃ³dulo: Modal de PreÃ§o (Frota) --- }
    procedure OnDroneActionClick(Sender: TObject);
    procedure ActionModalCloseClick(Sender: TObject);
    procedure ActionModalConfirmClick(Sender: TObject);
    procedure ActionModalKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);

    { --- MÃ³dulo: OperaÃ§Ãµes / Mapa --- }
    procedure BuildOpsView;
    procedure AddWaypointToMap(const AAddress: string; ALat, ALng: Double);
    procedure RefreshMapRoute;
    procedure OnAddWaypointClick(Sender: TObject);
    procedure OnClearRouteClick(Sender: TObject);
    procedure OnCalculateRouteClick(Sender: TObject);
    procedure OnWaypointEditChange(Sender: TObject);   // Dispara debounce para autocomplete
    procedure OnAutocompleteTimer(Sender: TObject);    // Executado apÃ³s debounce
    procedure OnAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem); // UsuÃ¡rio selecionou sugestÃ£o

    { --- MÃ³dulo: CRUD / EstaÃ§Ã£o --- }
    procedure BuildCrudView;
    procedure LoadCatalogueAsync;
    procedure OnCatalogueModelClick(Sender: TObject);
    procedure OnSaveDroneClick(Sender: TObject);
    procedure OnSaveHangarClick(Sender: TObject);

  public
  end;

var
  ViewDashboard: TViewDashboard;

implementation

{$R *.fmx}

uses
  System.NetEncoding, FMX.Platform;

// ===========================================================================
// HELPERS DE ESTILO (DRY - Design Tokens)
// ===========================================================================

{ Cor de destaque principal da paleta }
const
  COLOR_ACCENT   = $FF3B82F6;  // Azul Royal
  COLOR_SUCCESS  = $FF16A34A;  // Verde
  COLOR_DANGER   = $FFDC2626;  // Vermelho
  COLOR_DARK     = $FF1E293B;  // Slate 800
  COLOR_MUTED    = $FF64748B;  // Slate 500
  COLOR_BG       = $FFF3F4F6;  // Gray 100
  COLOR_WHITE    = $FFFFFFFF;
  SIDEBAR_COLOR_ACTIVE = $FF2B2D42;
  SIDEBAR_COLOR_IDLE   = $FF1E1E2D;
  SIDEBAR_TEXT_ACTIVE  = $FFFFFFFF;
  SIDEBAR_TEXT_IDLE    = $FF94A3B8;

{ Cria um TLabel com fonte customizada sem StyledSettings }
function MakeLabel(AParent: TFmxObject; const AText: string; AFontSize: Single;
  AColor: TAlphaColor; ABold: Boolean = False): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.Font.Size := AFontSize;
  Result.TextSettings.FontColor := AColor;
  if ABold then
    Result.Font.Style := [TFontStyle.fsBold]
  else
    Result.Font.Style := [];
  Result.StyledSettings := Result.StyledSettings -
    [TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor];
  Result.Text := AText;
end;

{ Cria um TEdit simples com placeholder }
function MakeEdit(AParent: TFmxObject; const APrompt: string; AFontSize: Single = 14): TEdit;
begin
  Result := TEdit.Create(AParent);
  Result.Parent := AParent;
  Result.Font.Size := AFontSize;
  Result.TextPrompt := APrompt;
  Result.Text := '';
end;

{ Cria um TCornerButton estilizado }
function MakeButton(AParent: TFmxObject; const AText: string; AColor: TAlphaColor = COLOR_ACCENT): TCornerButton;
begin
  Result := TCornerButton.Create(AParent);
  Result.Parent := AParent;
  Result.Text := AText;
  Result.XRadius := 6;
  Result.YRadius := 6;
end;

// ===========================================================================
// INICIALIZAÃ‡ÃƒO E CICLO DE VIDA
// ===========================================================================

procedure TViewDashboard.FormCreate(Sender: TObject);
begin
  FCards := TList<TRectangle>.Create;
  FViewModel := TViewModelDashboard.Create;
  FWaypoints := TObjectList<TMapPoint>.Create(True);
  FHubLat := -23.5505;  // SP: PadrÃ£o atÃ© o usuÃ¡rio configurar o Hangar
  FHubLng := -46.6333;
  FWaypointCount := 0;
  FSelectedDroneRange := 50.0; // PadrÃ£o seguro

  // ConstrÃ³i as Views dos mÃ³dulos Ops e CRUD (uma Ãºnica vez)
  BuildOpsView;
  BuildCrudView;

  // Inicia na View de Frota com carregamento automÃ¡tico
  SetActiveView(avFleet);
  btnRefreshClick(nil);
end;

procedure TViewDashboard.FormDestroy(Sender: TObject);
begin
  FWaypoints.Free;
  FViewModel.Free;
  FCards.Free;
end;

procedure TViewDashboard.lblTitleClick(Sender: TObject);
begin

end;

// ===========================================================================
// NAVEGAÃ‡ÃƒO ENTRE MÃ“DULOS
// ===========================================================================

procedure TViewDashboard.SetActiveView(AView: TActiveView);
begin
  FActiveView := AView;

  // Controla visibilidade dos painÃ©is
  ScrollDrones.Visible := (AView = avFleet);
  lytOps.Visible       := (AView = avOps);
  lytCrud.Visible      := (AView = avCrud);

  // Atualiza tÃ­tulo do header e visibilidade do btnRefresh
  case AView of
    avFleet:
    begin
      lblTitle.Text := 'Drones DisponÃ­veis';
      btnRefresh.Visible := True;
    end;
    avOps:
    begin
      lblTitle.Text := 'Rotas & LogÃ­stica';
      btnRefresh.Visible := False;
    end;
    avCrud:
    begin
      lblTitle.Text := 'EstaÃ§Ã£o & GestÃ£o de Frota';
      btnRefresh.Visible := False;
    end;
  end;

  UpdateMenuHighlight(AView);
end;

procedure TViewDashboard.UpdateMenuHighlight(AActive: TActiveView);
begin
  // Reseta todos para idle
  rctMenu1.Fill.Color := SIDEBAR_COLOR_IDLE;
  lblMenu1.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;
  rctMenu2.Fill.Color := SIDEBAR_COLOR_IDLE;
  lblMenu2.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;
  rctMenu3.Fill.Color := SIDEBAR_COLOR_IDLE;
  lblMenu3.TextSettings.FontColor := SIDEBAR_TEXT_IDLE;

  // Destaca o ativo
  case AActive of
    avFleet:
    begin
      rctMenu1.Fill.Color := SIDEBAR_COLOR_ACTIVE;
      lblMenu1.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE;
    end;
    avOps:
    begin
      rctMenu2.Fill.Color := SIDEBAR_COLOR_ACTIVE;
      lblMenu2.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE;
    end;
    avCrud:
    begin
      rctMenu3.Fill.Color := SIDEBAR_COLOR_ACTIVE;
      lblMenu3.TextSettings.FontColor := SIDEBAR_TEXT_ACTIVE;
    end;
  end;
end;

procedure TViewDashboard.MenuFleetClick(Sender: TObject);
begin
  SetActiveView(avFleet);
end;

procedure TViewDashboard.MenuOpsClick(Sender: TObject);
begin
  SetActiveView(avOps);

  // Carrega aeronaves no ComboBox assincronamente
  if not Assigned(FViewModel) or not Assigned(FComboDrone) then Exit;
  FComboDrone.Items.Clear;
  FComboDrone.Items.Add('Carregando...');
  FComboDrone.ItemIndex := 0;

  TThread.CreateAnonymousThread(procedure
  var
    LList: TObjectList<TDroneDTO>;
  begin
    LList := FViewModel.LoadDrones;
    TThread.Synchronize(nil, TThreadProcedure(procedure
    var
      LDrone: TDroneDTO;
    begin
      FComboDrone.Items.Clear;
      if not Assigned(LList) then
      begin
        FComboDrone.Items.Add('Erro ao carregar drones');
        FComboDrone.ItemIndex := 0;
        Exit;
      end;
      try
        for LDrone in LList do
          // Formato: "Nome | id | range"
          FComboDrone.Items.Add(
            Format('%s | %g Km', [LDrone.name, LDrone.max_range_km]));
        if FComboDrone.Items.Count > 0 then
          FComboDrone.ItemIndex := 0;
      finally
        LList.Free;
      end;
    end));
  end).Start;
end;

procedure TViewDashboard.MenuCrudClick(Sender: TObject);
begin
  SetActiveView(avCrud);
end;

// ===========================================================================
// MÃ“DULO: FROTA DE DRONES
// ===========================================================================

procedure TViewDashboard.btnRefreshClick(Sender: TObject);
var
  LAni: TAniIndicator;
begin
  ClearDroneCards;

  LAni := TAniIndicator.Create(Self);
  LAni.Parent := Self;
  LAni.Align := TAlignLayout.Center;
  LAni.Width := 50;
  LAni.Height := 50;
  LAni.Enabled := True;

  TThread.CreateAnonymousThread(procedure
  var
    LListaOnline: TObjectList<TDroneDTO>;
  begin
    LListaOnline := FViewModel.LoadDrones;
    TThread.Synchronize(nil, TThreadProcedure(procedure
    var
      LDroneItem: TDroneDTO;
    begin
      LAni.Enabled := False;
      LAni.Free;
      if Assigned(LListaOnline) then
      begin
        try
          for LDroneItem in LListaOnline do
            BuildDroneCard(LDroneItem);
        finally
          LListaOnline.Free;
        end;
      end;
    end));
  end).Start;
end;

procedure TViewDashboard.ClearDroneCards;
var
  LCard: TRectangle;
begin
  for LCard in FCards do
    LCard.Free;
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
  LAnim: TFloatAnimation;
begin
  LCard := TRectangle.Create(ScrollDrones);
  LCard.Parent := ScrollDrones;
  LCard.Align := TAlignLayout.Top;
  LCard.Height := 80;
  LCard.Margins.Bottom := 15;
  LCard.Fill.Color := COLOR_WHITE;
  LCard.Stroke.Kind := TBrushKind.None;
  LCard.XRadius := 8;
  LCard.YRadius := 8;

  LShadow := TShadowEffect.Create(LCard);
  TShadowEffect(LShadow).Parent := LCard;
  TShadowEffect(LShadow).Distance  := 4;
  TShadowEffect(LShadow).Direction := 90;
  TShadowEffect(LShadow).Softness  := 0.3;
  TShadowEffect(LShadow).Opacity   := 0.08;

  // Avatar circular do drone
  LImgPlaceholder := TCircle.Create(LCard);
  LImgPlaceholder.Parent := LCard;
  LImgPlaceholder.Align := TAlignLayout.Left;
  LImgPlaceholder.Width := 60;
  LImgPlaceholder.Margins.Top    := 10;
  LImgPlaceholder.Margins.Bottom := 10;
  LImgPlaceholder.Margins.Left   := 10;
  LImgPlaceholder.Fill.Color := $FFEFF6FF;
  LImgPlaceholder.Stroke.Kind := TBrushKind.None;

  LInitials := MakeLabel(LImgPlaceholder, Copy(ADrone.name, 1, 2).ToUpper, 20, COLOR_ACCENT, True);
  LInitials.Align := TAlignLayout.Client;
  LInitials.TextSettings.HorzAlign := TTextAlign.Center;
  LInitials.TextSettings.VertAlign := TTextAlign.Center;

  // Download assÃ­ncrono da imagem
  if ADrone.image_url <> '' then
    TThread.CreateAnonymousThread(procedure
    var
      LHTTP: THTTPClient;
      LStream: TMemoryStream;
    begin
      LHTTP := THTTPClient.Create;
      LStream := TMemoryStream.Create;
      try
        try
          LHTTP.Get(ADrone.image_url, LStream);
          if LStream.Size > 0 then
            TThread.Synchronize(nil, TThreadProcedure(procedure
            begin
              LStream.Position := 0;
              LImgPlaceholder.Fill.Kind := TBrushKind.Bitmap;
              LImgPlaceholder.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
              LImgPlaceholder.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
              LInitials.Visible := False;
            end));
        except
          // Silencioso: placeholder de iniciais permanece visÃ­vel
        end;
      finally
        LStream.Free;
        LHTTP.Free;
      end;
    end).Start;

  // BotÃ£o de aÃ§Ã£o
  LBtnAction := MakeButton(LCard, 'Testar PreÃ§o');
  LBtnAction.Align := TAlignLayout.Right;
  LBtnAction.Width := 130;
  LBtnAction.Margins.Top := 20;
  LBtnAction.Margins.Bottom := 20;
  LBtnAction.Margins.Right := 15;
  LBtnAction.TagString := ADrone.id;
  LBtnAction.OnClick := OnDroneActionClick;

  // Layout de texto
  LLayoutText := TLayout.Create(LCard);
  LLayoutText.Parent := LCard;
  LLayoutText.Align := TAlignLayout.Client;
  LLayoutText.Margins.Left := 20;

  LLblName := MakeLabel(LLayoutText, ADrone.name, 17, COLOR_DARK, True);
  LLblName.Align := TAlignLayout.Top;
  LLblName.Height := 35;

  // Badge de Status
  LBadge := TRoundRect.Create(LLblName);
  LBadge.Parent := LLblName;
  LBadge.Position.X := 250;
  LBadge.Position.Y := 5;
  LBadge.Width := 80;
  LBadge.Height := 24;
  LBadge.Stroke.Kind := TBrushKind.None;
  if SameText(ADrone.status, 'available') then
    LBadge.Fill.Color := $FFDCFCE7
  else
    LBadge.Fill.Color := $FFFEE2E2;

  LBadgeLabel := MakeLabel(LBadge, ADrone.status.ToUpper, 11,
    IfThen(SameText(ADrone.status, 'available'), $FF166534, $FF991B1B));
  LBadgeLabel.Align := TAlignLayout.Client;
  LBadgeLabel.TextSettings.HorzAlign := TTextAlign.Center;
  LBadgeLabel.TextSettings.VertAlign := TTextAlign.Center;

  LLblSpec := MakeLabel(LLayoutText,
    Format('%g Kg mÃ¡x. carga | Rende %g Km | Velocidade: %g Km/h',
      [ADrone.max_payload_kg, ADrone.max_range_km, ADrone.speed_kmh]),
    12, COLOR_MUTED);
  LLblSpec.Align := TAlignLayout.Bottom;
  LLblSpec.Height := 25;

  // Fade-in escalonado
  LCard.Opacity := 0;
  LAnim := TFloatAnimation.Create(LCard);
  LAnim.Parent := LCard;
  LAnim.PropertyName := 'Opacity';
  LAnim.StartValue := 0;
  LAnim.StopValue := 1;
  LAnim.Duration := 0.3 + (FCards.Count * 0.12);
  LAnim.Enabled := True;

  FCards.Add(LCard);
end;

// ===========================================================================
// MÃ“DULO: MODAL DE PREÃ‡O (Frota)
// ===========================================================================

procedure TViewDashboard.ActionModalCloseClick(Sender: TObject);
begin
  if Assigned(FModalPanel)   then FreeAndNil(FModalPanel);
  if Assigned(FModalOverlay) then FreeAndNil(FModalOverlay);
end;

procedure TViewDashboard.ActionModalConfirmClick(Sender: TObject);
var
  LDistStr: string;
  LDist: Double;
  LBtn: TCornerButton;
  LID: string;
begin
  if not (Sender is TCornerButton) then Exit;

  LBtn := TCornerButton(Sender);
  LID  := LBtn.TagString;
  LDistStr := StringReplace(FModalEditDist.Text, ',', '.', [rfReplaceAll]);
  LDist := StrToFloatDef(LDistStr, 10.0);

  FModalBtnConfirm.Visible := False;
  FModalEditDist.Visible   := False;
  FModalLblResult.Visible  := True;
  FModalLblResult.TextSettings.FontColor := COLOR_MUTED;
  FModalLblResult.Text := 'Calculando...';

  TThread.CreateAnonymousThread(procedure
  var
    LAns: string;
  begin
    LAns := FViewModel.CalcularPreco(LID, LDist);
    TThread.Synchronize(nil, TThreadProcedure(procedure
    begin
      if LAns.Contains('Custo Calculado') then
        FModalLblResult.TextSettings.FontColor := COLOR_SUCCESS
      else
        FModalLblResult.TextSettings.FontColor := COLOR_DANGER;
      FModalLblResult.Text := LAns;
      FModalBtnClose.Text := 'Fechar';
      FModalBtnClose.Position.X := 120;
    end));
  end).Start;
end;

procedure TViewDashboard.ActionModalKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    ActionModalConfirmClick(FModalBtnConfirm);
end;

procedure TViewDashboard.OnDroneActionClick(Sender: TObject);
var
  LBtn: TCornerButton;
  LTagID: string;
  LLblTitle, LLblSubtitle: TLabel;
begin
  if not (Sender is TCornerButton) then Exit;

  LBtn   := TCornerButton(Sender);
  LTagID := LBtn.TagString;

  FModalOverlay := TRectangle.Create(Self);
  FModalOverlay.Parent := Self;
  FModalOverlay.Align := TAlignLayout.Contents;
  FModalOverlay.Fill.Color := $FF000000;
  FModalOverlay.Opacity := 0.5;
  FModalOverlay.Stroke.Kind := TBrushKind.None;

  FModalPanel := TRectangle.Create(Self);
  FModalPanel.Parent := Self;
  FModalPanel.Width := 370;
  FModalPanel.Height := 240;
  FModalPanel.Position.X := 220 + (Self.ClientWidth - 220 - FModalPanel.Width) / 2;
  FModalPanel.Position.Y := (Self.ClientHeight - FModalPanel.Height) / 2;
  FModalPanel.Fill.Color := COLOR_WHITE;
  FModalPanel.Stroke.Kind := TBrushKind.None;
  FModalPanel.XRadius := 12;
  FModalPanel.YRadius := 12;

  LLblTitle := MakeLabel(FModalPanel, 'Simulador de PreÃ§o', 18, COLOR_DARK, True);
  LLblTitle.Align := TAlignLayout.Top;
  LLblTitle.Margins.Top := 20;
  LLblTitle.Height := 30;
  LLblTitle.TextSettings.HorzAlign := TTextAlign.Center;

  LLblSubtitle := MakeLabel(FModalPanel, 'DistÃ¢ncia atÃ© o destino (em Km):', 12, COLOR_MUTED);
  LLblSubtitle.Position.X := 20;
  LLblSubtitle.Position.Y := 60;
  LLblSubtitle.Width := 330;
  LLblSubtitle.Height := 20;
  LLblSubtitle.TextSettings.HorzAlign := TTextAlign.Center;

  FModalEditDist := MakeEdit(FModalPanel, 'Ex: 15', 16);
  FModalEditDist.Position.X := 60;
  FModalEditDist.Position.Y := 85;
  FModalEditDist.Width := 250;
  FModalEditDist.Height := 42;
  FModalEditDist.TextSettings.HorzAlign := TTextAlign.Center;
  FModalEditDist.Text := '10';
  FModalEditDist.OnKeyDown := ActionModalKeyDown;

  FModalLblResult := MakeLabel(FModalPanel, '', 14, COLOR_DANGER, True);
  FModalLblResult.Position.X := 20;
  FModalLblResult.Position.Y := 140;
  FModalLblResult.Width := 330;
  FModalLblResult.Height := 40;
  FModalLblResult.TextSettings.HorzAlign := TTextAlign.Center;
  FModalLblResult.TextSettings.WordWrap := True;
  FModalLblResult.Visible := False;

  FModalBtnConfirm := MakeButton(FModalPanel, 'Calcular');
  FModalBtnConfirm.Position.X := 60;
  FModalBtnConfirm.Position.Y := 190;
  FModalBtnConfirm.Width := 120;
  FModalBtnConfirm.Height := 36;
  FModalBtnConfirm.TagString := LTagID;
  FModalBtnConfirm.OnClick := ActionModalConfirmClick;

  FModalBtnClose := MakeButton(FModalPanel, 'Cancelar');
  FModalBtnClose.Position.X := 200;
  FModalBtnClose.Position.Y := 190;
  FModalBtnClose.Width := 110;
  FModalBtnClose.Height := 36;
  FModalBtnClose.OnClick := ActionModalCloseClick;

  FModalEditDist.SetFocus;
  FModalEditDist.SelectAll;
end;

// ===========================================================================
// MODULO: OPERACOES / MAPA
// ===========================================================================

procedure TViewDashboard.BuildOpsView;
var
  LPainelEsq: TRectangle;
  LLblTitle, LLblDroneTitle, LLblHintDrone: TLabel;
  LBtnAdd, LBtnCalc, LBtnClear: TCornerButton;
begin
  { --- Painel esquerdo fixo de 280px --- }
  LPainelEsq := TRectangle.Create(lytOps);
  LPainelEsq.Parent := lytOps;
  LPainelEsq.Align := TAlignLayout.Left;
  LPainelEsq.Width := 290;
  LPainelEsq.Fill.Color := COLOR_WHITE;
  LPainelEsq.Stroke.Color := $FFEAECF0;

  { --- Titulo --- }
  LLblTitle := MakeLabel(LPainelEsq, 'Paradas da Missao', 15, COLOR_DARK, True);
  LLblTitle.Align := TAlignLayout.Top;
  LLblTitle.Margins.Left := 16;
  LLblTitle.Margins.Top := 16;
  LLblTitle.Height := 30;

  { --- Campo de endereco com autocomplete --- }
  FEditWaypoint := MakeEdit(LPainelEsq, 'Endereco ou Lat, Lon');
  FEditWaypoint.Align := TAlignLayout.Top;
  FEditWaypoint.Height := 40;
  FEditWaypoint.Margins.Left := 12;
  FEditWaypoint.Margins.Right := 12;
  FEditWaypoint.Margins.Top := 8;
  FEditWaypoint.OnChangeTracking := OnWaypointEditChange;

  { --- Dropdown de autocomplete (inicialmente oculto) --- }
  FAutocompleteList := TListBox.Create(LPainelEsq);
  FAutocompleteList.Parent := LPainelEsq;
  FAutocompleteList.Align := TAlignLayout.Top;
  FAutocompleteList.Height := 0; // Oculto ate ter resultados
  FAutocompleteList.Margins.Left := 12;
  FAutocompleteList.Margins.Right := 12;
  FAutocompleteList.ItemHeight := 32;
  FAutocompleteList.ShowScrollBars := False;
  FAutocompleteList.OnItemClick := OnAutocompleteSelect;

  { --- Debounce Timer (400ms) --- }
  FAutocompleteTimer := TTimer.Create(Self);
  FAutocompleteTimer.Interval := 400;
  FAutocompleteTimer.Enabled := False;
  FAutocompleteTimer.OnTimer := OnAutocompleteTimer;

  { --- Botao Adicionar Parada --- }
  LBtnAdd := MakeButton(LPainelEsq, '+ Adicionar Parada');
  LBtnAdd.Align := TAlignLayout.Top;
  LBtnAdd.Height := 38;
  LBtnAdd.Margins.Left := 12;
  LBtnAdd.Margins.Right := 12;
  LBtnAdd.Margins.Top := 6;
  LBtnAdd.OnClick := OnAddWaypointClick;

  { --- Lista das paradas adicionadas --- }
  FListBoxWaypoints := TLayout.Create(LPainelEsq);
  FListBoxWaypoints.Parent := LPainelEsq;
  FListBoxWaypoints.Align := TAlignLayout.Top;
  FListBoxWaypoints.Height := 0;
  FListBoxWaypoints.Margins.Top := 4;

  { --- Separador --- }
  with TRectangle.Create(LPainelEsq) do
  begin
    Parent := LPainelEsq;
    Align := TAlignLayout.Top;
    Height := 1;
    Margins.Top := 8;
    Fill.Color := $FFEAECF0;
    Stroke.Kind := TBrushKind.None;
  end;

  { --- Selecao de Aeronave --- }
  LLblDroneTitle := MakeLabel(LPainelEsq, 'Aeronave para a Missao', 13, COLOR_DARK, True);
  LLblDroneTitle.Align := TAlignLayout.Top;
  LLblDroneTitle.Margins.Left := 16;
  LLblDroneTitle.Margins.Top := 12;
  LLblDroneTitle.Height := 22;

  LLblHintDrone := MakeLabel(LPainelEsq, 'Acesse o menu para carregar a lista.', 10, COLOR_MUTED);
  LLblHintDrone.Align := TAlignLayout.Top;
  LLblHintDrone.Margins.Left := 16;
  LLblHintDrone.Margins.Top := 2;
  LLblHintDrone.Height := 16;

  FComboDrone := TComboBox.Create(LPainelEsq);
  FComboDrone.Parent := LPainelEsq;
  FComboDrone.Align := TAlignLayout.Top;
  FComboDrone.Height := 38;
  FComboDrone.Margins.Left := 12;
  FComboDrone.Margins.Right := 12;
  FComboDrone.Margins.Top := 6;
  FComboDrone.Items.Add('(Selecione um drone)');
  FComboDrone.ItemIndex := 0;

  { --- Status e Acoes no rodape --- }
  FLblMapStatus := MakeLabel(LPainelEsq, 'Pronto.', 11, COLOR_MUTED);
  FLblMapStatus.Align := TAlignLayout.Bottom;
  FLblMapStatus.Height := 28;
  FLblMapStatus.Margins.Left := 12;
  FLblMapStatus.Margins.Bottom := 4;
  FLblMapStatus.TextSettings.WordWrap := True;

  LBtnCalc := MakeButton(LPainelEsq, 'Calcular Rota');
  LBtnCalc.Align := TAlignLayout.Bottom;
  LBtnCalc.Height := 42;
  LBtnCalc.Margins.Left := 12;
  LBtnCalc.Margins.Top := 4;
  LBtnCalc.Margins.Right := 12;
  LBtnCalc.Margins.Bottom := 4;
  LBtnCalc.OnClick := OnCalculateRouteClick;

  LBtnClear := MakeButton(LPainelEsq, 'Limpar Rota');
  LBtnClear.Align := TAlignLayout.Bottom;
  LBtnClear.Height := 34;
  LBtnClear.Margins.Left := 12;
  LBtnClear.Margins.Right := 12;
  LBtnClear.Margins.Bottom := 2;
  LBtnClear.OnClick := OnClearRouteClick;

  { --- WebBrowser: mapa ocupa o restante --- }
  FWebMap := TWebBrowser.Create(lytOps);
  FWebMap.Parent := lytOps;
  FWebMap.Align := TAlignLayout.Client;
  FWebMap.Navigate(ExtractFilePath(ParamStr(0)) + 'assets\mapa.html');
end;

{ Autocomplete: dispara timer a cada tecla }
procedure TViewDashboard.OnWaypointEditChange(Sender: TObject);
begin
  FAutocompleteTimer.Enabled := False;
  FAutocompleteList.Items.Clear;
  FAutocompleteList.Height := 0;
  if Length(FEditWaypoint.Text) >= 3 then
    FAutocompleteTimer.Enabled := True;
end;

{ Autocomplete: timer expirou - consulta Nominatim }
procedure TViewDashboard.OnAutocompleteTimer(Sender: TObject);
var
  LQuery: string;
begin
  FAutocompleteTimer.Enabled := False;
  LQuery := Trim(FEditWaypoint.Text);
  if LQuery = '' then Exit;

  TMapService.SearchAddressSuggestionsAsync(LQuery,
    procedure(ASuggestions: TArray<string>)
    var
      I: Integer;
    begin
      FAutocompleteList.Items.Clear;
      for I := 0 to High(ASuggestions) do
        FAutocompleteList.Items.Add(ASuggestions[I]);
      // Mostra ate 5 sugestoes
      FAutocompleteList.Height := Min(Length(ASuggestions), 5) * 32;
    end,
    procedure(AMsg: string)
    begin
      FAutocompleteList.Height := 0;
    end);
end;

{ Autocomplete: usuario clicou em uma sugestao }
procedure TViewDashboard.OnAutocompleteSelect(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
  if not Assigned(Item) then Exit;
  FEditWaypoint.Text := Item.Text;
  FAutocompleteList.Items.Clear;
  FAutocompleteList.Height := 0;
end;

procedure TViewDashboard.OnAddWaypointClick(Sender: TObject);
var
  LAddr: string;
begin
  LAddr := Trim(FEditWaypoint.Text);
  if LAddr = '' then Exit;

  FLblMapStatus.Text := 'Buscando: ' + LAddr + '...';
  FEditWaypoint.Text := '';

  TMapService.GeocodeAddressAsync(LAddr,
    // OnSuccess
    procedure(ALat, ALng: Double)
    begin
      AddWaypointToMap(LAddr, ALat, ALng);
    end,
    // OnError
    procedure(AMsg: string)
    begin
      FLblMapStatus.Text := 'Erro geocoding: ' + AMsg;
    end);
end;

procedure TViewDashboard.AddWaypointToMap(const AAddress: string; ALat, ALng: Double);
var
  LPoint: TMapPoint;
  LLbl: TLabel;
begin
  Inc(FWaypointCount);
  LPoint := TMapPoint.Create(ALat, ALng, Format('Parada %d: %s', [FWaypointCount, AAddress]));
  FWaypoints.Add(LPoint);

  // Tag visual na lista lateral
  LLbl := MakeLabel(FListBoxWaypoints,
    Format('P %d. %s', [FWaypointCount, AAddress]), 11, COLOR_DARK);
  LLbl.Align := TAlignLayout.Top;
  LLbl.Height := 22;
  LLbl.Margins.Left := 4;
  // Expande o container
  FListBoxWaypoints.Height := FListBoxWaypoints.Height + 24;

  FLblMapStatus.Text := Format('%d parada(s) adicionada(s). Selecione um drone e calcule.', [FWaypointCount]);
  RefreshMapRoute;
end;
procedure TViewDashboard.OnClearRouteClick(Sender: TObject);
begin
  FWaypoints.Clear;
  FWaypointCount := 0;
  FSelectedDroneId := '';
  FSelectedDroneRange := 50.0;

  // Limpa labels da lista
  while FListBoxWaypoints.ChildrenCount > 0 do
    FListBoxWaypoints.Children[0].Free;
  FListBoxWaypoints.Height := 0;

  FLblMapStatus.Text := 'Rota apagada.';

  // Limpa o mapa
  if Assigned(FWebMap) then
    FWebMap.EvaluateJavaScript('drawMission(' + AnsiQuotedStr('[]', #39) + ')');
end;

procedure TViewDashboard.RefreshMapRoute;
var
  LHub: TMapPoint;
  LPayload: string;
begin
  if not Assigned(FWebMap) then Exit;
  LHub := TMapPoint.Create(FHubLat, FHubLng, 'HUB Base');
  try
    LPayload := TMapService.GenerateRoutePayload(LHub, FWaypoints, FSelectedDroneRange, 0);
  finally
    LHub.Free;
  end;
  // Injeta via JS â€” usa AnsiQuotedStr com aspas simples para encapsular o JSON
  FWebMap.EvaluateJavaScript(
    'drawMission(' + AnsiQuotedStr(LPayload, #39) + ')');
end;

procedure TViewDashboard.OnCalculateRouteClick(Sender: TObject);
begin
  if FWaypoints.Count = 0 then
  begin
    FLblMapStatus.Text := 'Adicione ao menos uma parada.';
    Exit;
  end;
  if FSelectedDroneId = '' then
  begin
    FLblMapStatus.Text := 'Selecione uma aeronave.';
    Exit;
  end;
  FLblMapStatus.Text := 'Simulando telemetria...';
  RefreshMapRoute;
  FLblMapStatus.Text := Format('Rota calculada. %d parada(s) + retorno ao HUB.', [FWaypoints.Count]);
end;

// ===========================================================================
// MÃ“DULO: CRUD / ESTAÃ‡ÃƒO
// ===========================================================================
// MODULO: CRUD / ESTACAO
// ===========================================================================

procedure TViewDashboard.BuildCrudView;
var
  LPainelLeft, LPainelCatalogue, LPainelHangar: TRectangle;
  LScrollForm: TVertScrollBox;
  LInner: TLayout;
  LLblSec: TLabel;
  LBtnSaveDrone, LBtnSaveHangar, LBtnLoadCatalogue: TCornerButton;
begin
  { --- Coluna Esquerda: Formulario de Cadastro com Scroll --- }
  LPainelLeft := TRectangle.Create(lytCrud);
  LPainelLeft.Parent := lytCrud;
  LPainelLeft.Align := TAlignLayout.Left;
  LPainelLeft.Width := 400;
  LPainelLeft.Fill.Color := COLOR_WHITE;
  LPainelLeft.Stroke.Kind := TBrushKind.None;

  // TVertScrollBox garante que o formulario nao seja cortado
  LScrollForm := TVertScrollBox.Create(LPainelLeft);
  LScrollForm.Parent := LPainelLeft;
  LScrollForm.Align := TAlignLayout.Client;

  // TLayout interno: Align=Top funciona dentro do ScrollBox
  LInner := TLayout.Create(LScrollForm);
  LInner.Parent := LScrollForm;
  LInner.Align := TAlignLayout.Top;
  LInner.Height := 470;

  LLblSec := MakeLabel(LInner, 'Cadastro de Aeronave', 16, COLOR_DARK, True);
  LLblSec.Align := TAlignLayout.Top;
  LLblSec.Margins.Left := 20;
  LLblSec.Margins.Top := 20;
  LLblSec.Height := 28;

  FEditCrudName := MakeEdit(LInner, 'Nome do Modelo (ex: DJI Agras T10)');
  FEditCrudName.Align := TAlignLayout.Top;
  FEditCrudName.Height := 40;
  FEditCrudName.Margins.Rect := TRectF.Create(16, 10, 16, 0);

  FEditCrudPayload := MakeEdit(LInner, 'Carga Maxima (Kg)');
  FEditCrudPayload.Align := TAlignLayout.Top;
  FEditCrudPayload.Height := 40;
  FEditCrudPayload.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  FEditCrudRange := MakeEdit(LInner, 'Alcance Maximo (Km)');
  FEditCrudRange.Align := TAlignLayout.Top;
  FEditCrudRange.Height := 40;
  FEditCrudRange.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  FEditCrudBattery := MakeEdit(LInner, 'Bateria (Wh)');
  FEditCrudBattery.Align := TAlignLayout.Top;
  FEditCrudBattery.Height := 40;
  FEditCrudBattery.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  FEditCrudSpeed := MakeEdit(LInner, 'Velocidade (Km/h)');
  FEditCrudSpeed.Align := TAlignLayout.Top;
  FEditCrudSpeed.Height := 40;
  FEditCrudSpeed.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  FEditCrudImageUrl := MakeEdit(LInner, 'URL da Imagem');
  FEditCrudImageUrl.Align := TAlignLayout.Top;
  FEditCrudImageUrl.Height := 40;
  FEditCrudImageUrl.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  FEditCrudStatus := MakeEdit(LInner, 'Status (available / maintenance)');
  FEditCrudStatus.Align := TAlignLayout.Top;
  FEditCrudStatus.Height := 40;
  FEditCrudStatus.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  FEditCrudStatus.Text := 'available';

  LBtnSaveDrone := MakeButton(LInner, 'Salvar Drone');
  LBtnSaveDrone.Align := TAlignLayout.Top;
  LBtnSaveDrone.Height := 42;
  LBtnSaveDrone.Margins.Rect := TRectF.Create(16, 14, 16, 0);
  LBtnSaveDrone.OnClick := OnSaveDroneClick;

  FLblCrudStatus := MakeLabel(LInner, '', 12, COLOR_MUTED);
  FLblCrudStatus.Align := TAlignLayout.Top;
  FLblCrudStatus.Height := 24;
  FLblCrudStatus.Margins.Left := 16;
  FLblCrudStatus.Margins.Top := 6;

  { --- Coluna Direita: Catalogo de Modelos --- }
  LPainelCatalogue := TRectangle.Create(lytCrud);
  LPainelCatalogue.Parent := lytCrud;
  LPainelCatalogue.Align := TAlignLayout.Client;
  LPainelCatalogue.Fill.Color := COLOR_BG;
  LPainelCatalogue.Stroke.Kind := TBrushKind.None;
  LPainelCatalogue.Margins.Left := 8;

  LLblSec := MakeLabel(LPainelCatalogue, 'Catalogo de Modelos', 15, COLOR_DARK, True);
  LLblSec.Align := TAlignLayout.Top;
  LLblSec.Margins.Left := 16;
  LLblSec.Margins.Top := 16;
  LLblSec.Height := 26;

  MakeLabel(LPainelCatalogue, 'Clique em um modelo para importar os dados.', 11, COLOR_MUTED);

  LBtnLoadCatalogue := MakeButton(LPainelCatalogue, 'Buscar Catalogo');
  LBtnLoadCatalogue.Align := TAlignLayout.Top;
  LBtnLoadCatalogue.Height := 36;
  LBtnLoadCatalogue.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  LBtnLoadCatalogue.OnClick := OnLoadCatalogueClick;

  { --- Rodape: Configuracao do Hangar / CD Base --- }
  LPainelHangar := TRectangle.Create(lytCrud);
  LPainelHangar.Parent := lytCrud;
  LPainelHangar.Align := TAlignLayout.Bottom;
  LPainelHangar.Height := 130;
  LPainelHangar.Fill.Color := COLOR_WHITE;
  LPainelHangar.Stroke.Kind := TBrushKind.None;

  MakeLabel(LPainelHangar, 'Endereco do Hangar / CD Base', 14, COLOR_DARK, True);

  FEditHangarAddress := MakeEdit(LPainelHangar, 'Ex: Av. Paulista, 1578, Sao Paulo, SP');
  FEditHangarAddress.Align := TAlignLayout.Top;
  FEditHangarAddress.Height := 40;
  FEditHangarAddress.Margins.Rect := TRectF.Create(16, 8, 16, 0);

  LBtnSaveHangar := MakeButton(LPainelHangar, 'Salvar Hangar');
  LBtnSaveHangar.Align := TAlignLayout.Top;
  LBtnSaveHangar.Height := 36;
  LBtnSaveHangar.Margins.Rect := TRectF.Create(16, 8, 16, 0);
  LBtnSaveHangar.OnClick := OnSaveHangarClick;
end;


procedure TViewDashboard.OnLoadCatalogueClick(Sender: TObject);
begin
  LoadCatalogueAsync;
end;

procedure TViewDashboard.LoadCatalogueAsync;
var
  LAni: TAniIndicator;
begin
  LAni := TAniIndicator.Create(lytCrud);
  LAni.Parent := lytCrud;
  LAni.Align := TAlignLayout.Center;
  LAni.Width := 40;
  LAni.Height := 40;
  LAni.Enabled := True;

  TThread.CreateAnonymousThread(procedure
  var
    LHttp: THTTPClient;
    LResp: IHTTPResponse;
    LArr: TJSONArray;
    LObj: TJSONObject;
  begin
    LHttp := THTTPClient.Create;
    try
      try
        LResp := LHttp.Get('http://localhost:9000/drones/catalogue');
        if LResp.StatusCode = 200 then
        begin
          LArr := TJSONObject.ParseJSONValue(LResp.ContentAsString) as TJSONArray;
          if Assigned(LArr) then
          begin
            TThread.Synchronize(nil, TThreadProcedure(procedure
            var
              LItem: TJSONValue;
              LModel: TJSONObject;
              LBtn: TCornerButton;
              LParent: TControl;
            begin
              LAni.Free;
              // Localiza o painel do catÃ¡logo (3o filho de lytCrud)
              LParent := lytCrud.Controls[1] as TControl; // LPainelCatalogue
              // Remove botÃµes antigos (apÃ³s label + btn buscar = 2 filhos)
              while LParent.ControlsCount > 3 do
                LParent.Controls[LParent.ControlsCount - 1].Free;

              for LItem in LArr do
              begin
                LModel := LItem as TJSONObject;
                LBtn := MakeButton(TFmxObject(LParent),
                  Format('%s  (%s)', [LModel.GetValue<string>('model'),
                                     LModel.GetValue<string>('manufacturer')]));
                LBtn.Align := TAlignLayout.Top;
                LBtn.Height := 36;
                LBtn.Margins.Rect := TRectF.Create(16, 4, 16, 0);
                LBtn.TagString := LItem.ToJSON;
                LBtn.OnClick := OnCatalogueModelClick;
              end;
              FLblCrudStatus.Text  := 'CatÃ¡logo carregado com sucesso!';
              FLblCrudStatus.TextSettings.FontColor := COLOR_SUCCESS;
            end));
            LArr.Free;
          end;
        end;
      except
        on E: Exception do
          TThread.Synchronize(nil, TThreadProcedure(procedure begin
            LAni.Free;
            FLblCrudStatus.Text  := 'Falha ao carregar catÃ¡logo: ' + E.Message;
            FLblCrudStatus.TextSettings.FontColor := COLOR_DANGER;
          end));
      end;
    finally
      LHttp.Free;
    end;
  end).Start;
end;

procedure TViewDashboard.OnCatalogueModelClick(Sender: TObject);
var
  LBtn: TCornerButton;
  LModel: TJSONObject;
begin
  if not (Sender is TCornerButton) then Exit;
  LBtn := TCornerButton(Sender);
  LModel := TJSONObject.ParseJSONValue(LBtn.TagString) as TJSONObject;
  if not Assigned(LModel) then Exit;
  try
    FEditCrudName.Text     := LModel.GetValue<string>('model');
    FEditCrudPayload.Text  := LModel.GetValue<string>('max_payload_kg');
    FEditCrudRange.Text    := LModel.GetValue<string>('max_range_km');
    FEditCrudBattery.Text  := LModel.GetValue<string>('battery_wh');
    FEditCrudSpeed.Text    := LModel.GetValue<string>('speed_kmh');
    FEditCrudImageUrl.Text := LModel.GetValue<string>('image_url');
    FEditCrudStatus.Text   := LModel.GetValue<string>('status');
    FLblCrudStatus.Text    := 'Modelo importado. Revise e salve.';
    FLblCrudStatus.TextSettings.FontColor := COLOR_ACCENT;
  finally
    LModel.Free;
  end;
end;

procedure TViewDashboard.OnSaveDroneClick(Sender: TObject);
var
  LJson: TJSONObject;
  LBody: string;
begin
  if Trim(FEditCrudName.Text) = '' then
  begin
    FLblCrudStatus.Text := 'Informe o nome do drone antes de salvar.';
    FLblCrudStatus.TextSettings.FontColor := COLOR_DANGER;
    Exit;
  end;

  LJson := TJSONObject.Create
    .AddPair('name', FEditCrudName.Text)
    .AddPair('max_payload_kg', TJSONNumber.Create(StrToFloatDef(FEditCrudPayload.Text.Replace(',','.'), 0)))
    .AddPair('max_range_km',   TJSONNumber.Create(StrToFloatDef(FEditCrudRange.Text.Replace(',','.'), 0)))
    .AddPair('battery_wh',     TJSONNumber.Create(StrToFloatDef(FEditCrudBattery.Text.Replace(',','.'), 0)))
    .AddPair('speed_kmh',      TJSONNumber.Create(StrToFloatDef(FEditCrudSpeed.Text.Replace(',','.'), 0)))
    .AddPair('image_url',      FEditCrudImageUrl.Text)
    .AddPair('status',         Trim(FEditCrudStatus.Text));

  LBody := LJson.ToJSON;
  LJson.Free;

  FLblCrudStatus.Text := 'Salvando...';
  FLblCrudStatus.TextSettings.FontColor := COLOR_MUTED;

  TThread.CreateAnonymousThread(procedure
  var
    LHttp: THTTPClient;
    LResp: IHTTPResponse;
    LStream: TStringStream;
  begin
    LHttp := THTTPClient.Create;
    LStream := TStringStream.Create(LBody, TEncoding.UTF8);
    try
      try
        LHttp.ContentType := 'application/json';
        LResp := LHttp.Post('http://localhost:9000/drones', LStream);
        TThread.Synchronize(nil, TThreadProcedure(procedure
        begin
          if LResp.StatusCode in [200, 201] then
          begin
            FLblCrudStatus.Text := 'âœ… Drone salvo com sucesso!';
            FLblCrudStatus.TextSettings.FontColor := COLOR_SUCCESS;
          end
          else
          begin
            FLblCrudStatus.Text := 'Erro ' + LResp.StatusCode.ToString + ': ' + LResp.ContentAsString;
            FLblCrudStatus.TextSettings.FontColor := COLOR_DANGER;
          end;
        end));
      except
        on E: Exception do
          TThread.Synchronize(nil, TThreadProcedure(procedure begin
            FLblCrudStatus.Text := 'Falha de conexÃ£o: ' + E.Message;
            FLblCrudStatus.TextSettings.FontColor := COLOR_DANGER;
          end));
      end;
    finally
      LStream.Free;
      LHttp.Free;
    end;
  end).Start;
end;

procedure TViewDashboard.OnSaveHangarClick(Sender: TObject);
var
  LAddr: string;
begin
  LAddr := Trim(FEditHangarAddress.Text);
  if LAddr = '' then Exit;

  FLblCrudStatus.Text := 'Geocodificando endereÃ§o do Hangar...';
  FLblCrudStatus.TextSettings.FontColor := COLOR_MUTED;

  TMapService.GeocodeAddressAsync(LAddr,
    procedure(ALat, ALng: Double)
    begin
      FHubLat := ALat;
      FHubLng := ALng;
      FLblCrudStatus.Text := Format('HUB atualizado: %.4f, %.4f', [ALat, ALng]);
      FLblCrudStatus.TextSettings.FontColor := COLOR_SUCCESS;
    end,
    procedure(AMsg: string)
    begin
      FLblCrudStatus.Text := 'EndereÃ§o nÃ£o encontrado: ' + AMsg;
      FLblCrudStatus.TextSettings.FontColor := COLOR_DANGER;
    end);
end;

end.
