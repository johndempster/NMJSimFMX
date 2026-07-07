program NMJSim;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  NMJSimMain in 'NMJSimMain.pas' {MainFrm},
  ModalBox in 'ModalBox.pas' {ModalBoxFrm},
  NMJSimModel in 'NMJSimModel.pas' {Model: TDataModule},
  {$IFDEF MACOS} FMX.Platform.Mac in 'FMX.Platform.Mac.pas', {$ENDIF }
  IonsTableUnit in 'IonsTableUnit.pas' {IonsTableFrm};


{$R *.res}

begin
  {$IFDEF MACOS}
  GlobalUseMetal := true ;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.CreateForm(TModalBoxFrm, ModalBoxFrm);
  Application.CreateForm(TModel, Model);
  Application.CreateForm(TIonsTableFrm, IonsTableFrm);
  Application.Run;
end.
