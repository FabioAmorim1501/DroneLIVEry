unit DroneDelivery.Server.Provider.Connection;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.ConsoleUI.Wait,
  Data.DB, FireDAC.Comp.Client, System.SysUtils;

type
  TProviderConnection = class
  private
    class var FConnection: TFDConnection;
  public
    class function GetInstance: TFDConnection;
    class procedure DestroyInstance;
  end;

implementation

{ TProviderConnection }

class procedure TProviderConnection.DestroyInstance;
begin
  if Assigned(FConnection) then
    FConnection.Free;
end;

class function TProviderConnection.GetInstance: TFDConnection;
begin
  if not Assigned(FConnection) then
  begin
    FConnection := TFDConnection.Create(nil);
    FConnection.Params.DriverID := 'PG';
    FConnection.Params.Database := 'dronedelivery_db';
    FConnection.Params.UserName := 'postgres';
    FConnection.Params.Password := 'admin';
    FConnection.Params.Add('Server=localhost');
    FConnection.Params.Add('Port=5432');
    FConnection.LoginPrompt := False;
    // FConnection.Connected := True;
  end;
  Result := FConnection;
end;

end.
