program DroneDelivery.Client;

uses
  System.StartUpCopy,
  FMX.Forms,
  DroneDelivery.Client.ViewModel.Dashboard in 'ViewModels\DroneDelivery.Client.ViewModel.Dashboard.pas',
  DroneDelivery.Client.Service.API in 'Services\DroneDelivery.Client.Service.API.pas',
  DroneDelivery.Client.Service.Maps in 'Services\DroneDelivery.Client.Service.Maps.pas',
  DroneDelivery.Client.View.Dashboard in 'Views\DroneDelivery.Client.View.Dashboard.pas' {ViewDashboard};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TViewDashboard, ViewDashboard);
  Application.Run;
end.
