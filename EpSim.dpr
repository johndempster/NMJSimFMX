program EpSim;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  EpSimMain in 'EpSimMain.pas' {MainFrm},
  ModalBox in 'ModalBox.pas' {ModalBoxFrm},
  EPSimModel in 'EPSimModel.pas' {Model: TDataModule}
  {$IFDEF MACOS} ,FMX.Platform.Mac in 'FMX.Platform.Mac.pas' {$ENDIF};


{$R *.res}

begin
  {$IFDEF MACOS}
  GlobalUseMetal := true ;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.CreateForm(TModalBoxFrm, ModalBoxFrm);
  Application.CreateForm(TModel, Model);
  Application.Run;
end.
