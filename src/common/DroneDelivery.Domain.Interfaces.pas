unit DroneDelivery.Domain.Interfaces;

interface

uses
  System.SysUtils;

type
  // Define interfaces básicas para os repositórios/serviços
  IRepository<T> = interface
    ['{F62E29B1-4A5A-4B6A-91D1-21B0A2AC16C1}']
    function GetById(const AId: string): T;
    function GetAll: TArray<T>;
    procedure Insert(const AEntity: T);
    procedure Update(const AEntity: T);
    procedure Delete(const AId: string);
  end;

  IDrone = interface
    ['{A194A2D2-16BC-4ED5-84EC-FA522DCA5183}']
    function GetId: string;
    function GetName: string;
    function GetPayload: Double;
    function GetSpeed: Double;
    function GetAutonomy: Double;
  end;

implementation

end.
