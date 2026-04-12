program DroneDelivery.Client;

uses
  System.StartUpCopy,
  FMX.Forms,
  DroneDelivery.Client.View.Dashboard in 'Views\DroneDelivery.Client.View.Dashboard.pas' {ViewDashboard};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TViewDashboard, ViewDashboard);
  Application.Run;
end.
