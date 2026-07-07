unit IonsTableUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, SESNumberBox, FMX.Controls.Presentation;

type
  TIonsTableFrm = class(TForm)
    StimulusGrp: TGroupBox;
    edNaExt: TSESNumberBox;
    lbExternal: TLabel;
    StyleBook1: TStyleBook;
    Label1: TLabel;
    edNaInt: TSESNumberBox;
    Label2: TLabel;
    edNaVRev: TSESNumberBox;
    edKExt: TSESNumberBox;
    edKInt: TSESNumberBox;
    edKVRev: TSESNumberBox;
    edCaExt: TSESNumberBox;
    edMgExt: TSESNumberBox;
    bResetToNormal: TButton;
    lbK: TLabel;
    Label4: TLabel;
    lbCa: TLabel;
    lbMg: TLabel;
    bOK: TButton;
    bCancel: TButton;
    procedure FormShow(Sender: TObject);
    procedure bOKClick(Sender: TObject);
    procedure bResetToNormalClick(Sender: TObject);
    procedure edNaExtKeyUp(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edKExtKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IonsTableFrm: TIonsTableFrm;

implementation

{$R *.fmx}

uses NMJSimModel, NMJSimMain ;

procedure TIonsTableFrm.bOKClick(Sender: TObject);
// ---------------------------------------
// OK - Update ion concentrations in model
// ---------------------------------------
begin

    if Model.Na.FinalCOut <> edNaExt.Value then
       begin
       Model.Na.FinalCOut := edNaExt.Value ;
       MainFrm.AddDrugMarker( format( '[Na]=%.1fmM',[Model.Na.FinalCOut]));
       end;

    if Model.K.FinalCOut <> edKExt.Value then
       begin
       Model.K.FinalCOut := edKExt.Value ;
       MainFrm.AddDrugMarker( format( '[K]=%.1fmM',[Model.K.FinalCOut]));
       end;

    if Model.Ca.FinalCOut <> edCaExt.Value then
       begin
       Model.Ca.FinalCOut := edCaExt.Value ;
       MainFrm.AddDrugMarker( format( '[Ca]=%.1fmM',[Model.Ca.FinalCOut]));
       end;

    if Model.Mg.FinalCOut <> edMgExt.Value then
       begin
       Model.Mg.FinalCOut := edMgExt.Value ;
       MainFrm.AddDrugMarker( format( '[Mg]=%.1fmM',[Model.Mg.FinalCOut]));
       end;

end;


procedure TIonsTableFrm.bResetToNormalClick(Sender: TObject);
// ---------------------------------
// Reset ion concentration to normal
// ---------------------------------
begin

    Model.Na.FinalCOut := Model.Na.NormalCOut ;
    if Model.Na.FinalCOut <> edNaExt.Value then
       begin
       MainFrm.AddDrugMarker( format( '[Na]=%.1fmM',[Model.Na.FinalCOut]));
       end;
    edNaExt.Value := Model.Na.FinalCOut ;
    edNaInt.Value := Model.Na.CIn ;
    edNaVRev.Value := Model.Na.VRev ;

    Model.K.FInalCOut := Model.K.NormalCOut ;
    if Model.K.FinalCOut <> edKExt.Value then
       begin
       MainFrm.AddDrugMarker( format( '[K]=%.1fmM',[Model.K.FinalCOut]));
       end;
    edKExt.Value := Model.K.FinalCOut ;
    edKInt.Value := Model.K.CIn ;
    edKVRev.Value := Model.K.VRev ;

    Model.Ca.FinalCOut := Model.Ca.NormalCOut ;
    if Model.Ca.FinalCOut <> edCaExt.Value then
       begin
       MainFrm.AddDrugMarker( format( '[Ca]=%.1fmM',[Model.Ca.FinalCOut]));
       end;
    edCaExt.Value := Model.Ca.FinalCOut ;

    Model.Mg.FinalCOut := Model.Mg.NormalCOut ;
    if Model.Mg.FinalCOut <> edMgExt.Value then
       begin
       MainFrm.AddDrugMarker( format( '[Mg]=%.1fmM',[Model.Mg.FinalCOut]));
       end;
    edMgExt.Value := Model.Mg.FinalCOut ;

end;


procedure TIonsTableFrm.edKExtKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
// -----------
// KExt Key pressed
// -----------
begin

    if Key = 13 then
       begin
       edKInt.Value := Model.K.CIn ;
       edKVRev.Value := Model.rtf * ln( edKExt.Value / edKInt.Value ) ;
       end;

end;


procedure TIonsTableFrm.edNaExtKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
// -----------
// NaExt Key pressed
// -----------
begin

    if Key = 13 then
       begin
       edNaInt.Value := Model.Na.CIn ;
       edNaVRev.Value := Model.rtf * ln( edNaExt.Value / edNaInt.Value ) ;
       end;

end;


procedure TIonsTableFrm.FormShow(Sender: TObject);
// ---------------------------------------
// Initialise controls when form displayed
// ---------------------------------------
begin

    edNaExt.Value := Model.Na.FinalCOut ;
    edNaInt.Value := Model.Na.CIn ;
    edNaVRev.Value := Model.Na.VRev ;

    edKExt.Value := Model.K.FinalCOut ;
    edKInt.Value := Model.K.CIn ;
    edKVRev.Value := Model.K.VRev ;

    edCaExt.Value := Model.Ca.FinalCOut ;
    edMgExt.Value := Model.Mg.FinalCOut ;

end;

end.
