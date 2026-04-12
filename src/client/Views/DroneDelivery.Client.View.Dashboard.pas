unit DroneDelivery.Client.View.Dashboard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  DroneDelivery.Client.ViewModel.Dashboard;

type
  TViewDashboard = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FViewModel: TViewModelDashboard;
  public
    { Public declarations }
  end;

var
  ViewDashboard: TViewDashboard;

implementation

{$R *.fmx}

procedure TViewDashboard.FormCreate(Sender: TObject);
begin
  FViewModel := TViewModelDashboard.Create;
  // FViewModel.LoadDrones;
end;

end.
