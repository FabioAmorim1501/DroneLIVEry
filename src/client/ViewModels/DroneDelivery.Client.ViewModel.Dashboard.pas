unit DroneDelivery.Client.ViewModel.Dashboard;

interface

uses
  DroneDelivery.Client.Service.API;

type
  TViewModelDashboard = class
  private
    FAPI: TServiceAPI;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadDrones;
  end;

implementation

{ TViewModelDashboard }

constructor TViewModelDashboard.Create;
begin
  FAPI := TServiceAPI.Create;
end;

destructor TViewModelDashboard.Destroy;
begin
  FAPI.Free;
  inherited;
end;

procedure TViewModelDashboard.LoadDrones;
begin
  // Utiliza a API para popular lista e atualizar UI via LiveBindings
  FAPI.GetDrones;
end;

end.
