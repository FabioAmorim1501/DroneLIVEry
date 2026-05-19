program DroneDelivery.Client;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  DroneDelivery.Client.ViewModel.Dashboard in 'ViewModels\DroneDelivery.Client.ViewModel.Dashboard.pas',
  DroneDelivery.Client.Service.API in 'Services\DroneDelivery.Client.Service.API.pas',
  DroneDelivery.Client.Service.Maps in 'Services\DroneDelivery.Client.Service.Maps.pas',
  DroneDelivery.Client.Component.Map in 'Components\DroneDelivery.Client.Component.Map.pas',
  DroneDelivery.Client.View.Dashboard in 'Views\DroneDelivery.Client.View.Dashboard.pas' {ViewDashboard};

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TViewDashboard, ViewDashboard);
  Application.Run;
end.
