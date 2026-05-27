unit DroneDelivery.Server.Provider.Connection;

interface

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.ConsoleUI.Wait,
  Data.DB, FireDAC.Comp.Client, System.SysUtils, FireDAC.DApt, System.IniFiles, System.IOUtils;

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
var
  LIniFile: TIniFile;
  LIniPath: string;
  LParams: TFDPhysPGConnectionDefParams;
  LRetryCount: Integer;
begin
  if not Assigned(FConnection) then
  begin
    LIniPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'config.ini');
    if not TFile.Exists(LIniPath) then
      raise Exception.Create('Arquivo de configuração (config.ini) no encontrado! Copie de config.ini.example na raiz e coloque na pasta bin.');

    LIniFile := TIniFile.Create(LIniPath);
    try
      FConnection := TFDConnection.Create(nil);
      FConnection.Params.Clear;
      FConnection.DriverName := 'PG';
      
      // Conexão Forte e Tipada com base na Wiki da Embarcadero (Casting The Connection) - Sem utilizar "with"
      LParams := FConnection.Params as TFDPhysPGConnectionDefParams;
      LParams.Database := LIniFile.ReadString('Database', 'Database', 'dronedelivery_db');
      LParams.UserName := LIniFile.ReadString('Database', 'User', 'postgres');
      LParams.Password := LIniFile.ReadString('Database', 'Password', '');
      LParams.Server := LIniFile.ReadString('Database', 'Host', 'localhost');
      LParams.Port := StrToIntDef(LIniFile.ReadString('Database', 'Port', '5432'), 5432);
      
      FConnection.LoginPrompt := False;
      FConnection.ResourceOptions.AutoReconnect := True;
      
      {$IFDEF DEBUG}
      // Log de conferência bruta para o console
      Writeln('------------------------------------------------');
      Writeln('  Testando as Credenciais do banco lidas do INI ');
      Writeln('  User_Name: [' + LIniFile.ReadString('Database', 'User', '') + ']');
      Writeln('  Password:  [***REDACTED***]');
      Writeln('------------------------------------------------');
      {$ENDIF}

    finally
      LIniFile.Free;
    end;
    
    // Force connection to ensure it's alive before returning, with 3 retries
    for LRetryCount := 1 to 3 do
    begin
      try
        FConnection.Connected := True;
        Break;
      except
        if LRetryCount = 3 then raise;
        Sleep(1000);
      end;
    end;
  end;
  
  if not FConnection.Connected then
  begin
    try FConnection.Connected := True; except end;
  end;
  
  Result := FConnection;
end;

end.
