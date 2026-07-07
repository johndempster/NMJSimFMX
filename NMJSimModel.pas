unit NMJSimModel;
// ===================================================
// Neuromuscular junction electrophysiology simulation
// ===================================================
// 29.05.26

interface

uses
  System.SysUtils, System.Classes, math, windows ;

const
    MaxDrugs = 100 ;
    MixingRate = 2000.0 ;
    Const _NB_OF_STATE_VARIABLES_ = 4;
type

  TDrug = record
          Name : String ;
          ShortName : String ;
          FinalBathConcentration : single ;
          BathConcentration : single ;
          DrugListMaxPowerOfTen : Integer ;
          EC50_NrvGNa : Single ;
          EC50_MusGNa : Single ;
          EC50_GK : Single ;
          EC50_GAch : Single ;
          EC50_AchE : Single ;
          Antagonist : Boolean ;
          end ;

TIon = record
     CIn : Single ;
     NormalCIn : Single ;
     COut : Single ;
     NormalCOut : Single ;
     FinalCOut : Single ;
     New : Single ;
     G : Single ;
     GMAX : Single ;
     VRev : single ;
     I : Single ;
     m : single ;
     n : single ;
     h : single ;
     end ;

TReceptor = record
     Active : Single ;
     C : Single ;          // Closed state fraction
     O : Single ;          // Open state fraction
     D : Single ;          // Desensitised fraction
     OtoC : Single ;       // Open - close rate
     CtoO : Single ;       // Closed to open rate
     OtoD : Single ;       // Open to desensitised rate
     DtoO : Single ;       // Desentitised to open rate
     New : Single ;
     G : Single ;
     GMAX : Single ;
     VRev : single ;
     I : Single ;
     end ;


TStimulus = record
          On : Boolean ;
          Start : single ;
          Amplitude : single ;
          Duration : single ;
          I : single ;
          NumStimDone : Integer ;
          end ;

    TRate = record
          m : single ;
          n : single ;
          h : single ;
          end ;

TEPC = record
     G : single ;
     I : single ;
     Vrev : single ;
     Gevoked : single ;
     qc : single ; { Quantal content }
     QSize : single ;{ Conductance) of quantal unit }
     QSD : single ; { Standard deviation of quantal unit }
     QRan : single ; { Random variable used by gaussian random no. function }
     TauOpen : single ;   // EPC channel opening time
     TauClose : single ;  // EPC channel closing time
     Active : Boolean ;   // EPC event in progress
     tStart : Single ;    // Time of transmitter release from nerve ending
     end ;


  TModel = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }

      Temperature : single ;
      rtf : single ;
      Length : single ;
      Radius : single ;
      Area : single ;
      cm : single ;
      c : single ;
      Noise : single ;
      Na : TIon ;
      K : TIon ;
      Cl : TIon ;
      Ca : TIon ;
      Mg : TIon ;
      AchR : TReceptor ;
      DAP : TDrug ;
      TTX : TDrug ;
      LIG : TDrug ;
      Stim : TStimulus ;
      Vm : Single ;
      VmResting : Single ;
      Im : Single ;
      AChR_G : single ; // Ach ion channel conductance


      EPC : TEPC ;        // Nerve-evoked endplate current record
      MEPC : TEPC ;       // Spontaneous miniature endplate current

      t : double ;
      dt : double ;

    Drugs : Array[0..MaxDrugs-1] of TDrug ;    // Drug properties array
    NumDrugs : Integer ;                     // No. of drugs available
    NrvGNa_Available : Single ;                // Fraction nerve Na conductance unblocked
    MusGNa_Available : Single ;                // Fraction muscle Na conductance unblocked
    GK_Available : Single ;                 // Fraction K Channels unblocked
    GAchR_Available : Single ;              // Fraction posts-synaptic acetylchinoceptors available
    AChR_Available : single ;
    AChR_Active : single ;                  // Fraction of AChR receptors activated
    AchE_Available : Single ;               // Fraction Acetylcholineestare active.
    GCaL_Available : Single ;                 // Fraction Ca Channels unblocked
    NaClosedStateR : single ;         // Prolong Na channel closed state


    NerveStimulusOn : Boolean ;      // TRUE = nerve stimulus on
    NerveStimulus : TStimulus ;      // Stimulus parameters
    MuscleStimulus : TStimulus ;      // Stimulus parameters
    MuscleStimulusOn : Boolean ;     // TRUE = muscle stimulus on
    InitialiseSimulation : Boolean ;  // TRUE = Initialisation of simulation required

    procedure Initialise ;
    procedure UpdateIonConcentrations ;
    procedure UpdateDrugConcentrations ;
    procedure DoSimulation ;
    procedure StimulateNerve ;
    procedure StimulateMuscle( Amplitude : single ; Duration : Single ) ;
    function binomial( pIn, n : Single ) : Single ;
    function GaussianRandom( GSet : Single ) : Single ;
    function gammln( xx : Single ) : Single  ;

  end ;

var
  Model: TModel;

implementation


{$R *.dfm}


{%CLASSGROUP 'Vcl.Controls.TControl'}

procedure TModel.Initialise ;
// ----------------------------
// Initialise neuron simulation
// ----------------------------
var
    i : Integer ;
begin

     // Initialise all EC50's to inneffective
     for I := 0 to High(Drugs) do
         begin
         Drugs[i].EC50_NrvGNa := 1E3 ;
         Drugs[i].EC50_MusGNa := 1E3 ;
         Drugs[i].EC50_GK := 1E3 ;
         Drugs[i].EC50_GAch := 1E3 ;
         Drugs[i].EC50_AChE := 1E3 ;
         end;

     NumDrugs := 0 ;

     Drugs[NumDrugs].Name := 'Tubocurarine' ;
     Drugs[NumDrugs].ShortName := 'TUB' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_GAch := 3E-7 ;
     Drugs[NumDrugs].Antagonist := True ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -5 ;
     Inc(NumDrugs) ;

     Drugs[NumDrugs].Name := 'Neostigmine' ;
     Drugs[NumDrugs].ShortName := 'NEO' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_AChE := 2E-7 ;
     Drugs[NumDrugs].Antagonist := True ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -5 ;
     Inc(NumDrugs) ;

     Drugs[NumDrugs].Name := 'Suxamethonium' ;
     Drugs[NumDrugs].ShortName := 'SUX' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_GAch := 1E-5 ;
     Drugs[NumDrugs].Antagonist := False ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -4 ;
     Inc(NumDrugs) ;

     Drugs[NumDrugs].Name := 'Tetrodotoxin' ;
     Drugs[NumDrugs].ShortName := 'TTX' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_NrvGNa := 1E-7 ;
     Drugs[NumDrugs].EC50_MusGNa := 1E-7 ;
     Drugs[NumDrugs].Antagonist := True ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -4 ;
     Inc(NumDrugs) ;

     Drugs[NumDrugs].Name := '3,4-diaminopyridine' ;
     Drugs[NumDrugs].ShortName := 'DAP' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_GK := 1E-6 ;
     Drugs[NumDrugs].Antagonist := True ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -4 ;
     Inc(NumDrugs) ;

     Drugs[NumDrugs].Name := 'Mu-Conotoxin' ;
     Drugs[NumDrugs].ShortName := 'uCTX' ;
     Drugs[NumDrugs].FinalBathConcentration := 0.0 ;
     Drugs[NumDrugs].BathConcentration := 0.0 ;
     Drugs[NumDrugs].EC50_MusGNa := 2.5E-7 ;
     Drugs[NumDrugs].Antagonist := True ;
     Drugs[NumDrugs].DrugListMaxPowerOfTen := -4 ;
     Inc(NumDrugs) ;

//     dt := 2E-5 ;
     t := 0. ;
     { Simulation time step }
     dt := 1E-5 ;
     Noise := 5E-10 ;

     Vm := -0.09 ;
     VmResting := Vm ;

     { Define constant simulation parameters }
     Temperature := 20.0 ;
     rtf := 0.02354*(Temperature + 273.0)/273.0 ;
     Length := 50.0*1E-4 ;  { cm }
     Radius := 20.0*1E-4 ; { cm }
     Area := 2.*PI*Radius*Length ;
     Cm := 1E-6 ; {* Specific membrane capacity F/cm2 }
     C := Cm*Area ;

     { Define initial drug/ion concentrations }
     Na.Cin := 12. ;                  { Internal [Na] mM }
     Na.Cout := 145. ;
     Na.FinalCout := Na.Cout ;
     Na.NormalCOut := Na.Cout ;
     Na.GMax := 0.12*Area ; { Max. Na conductance }
     Na.VRev := rtf * ln( Na.Cout / Na.Cin ) ;

     K.Cin := 140. ;         { Internal [K] mM }
     K.Cout := 5. ;
     K.FinalCout := K.Cout ;
     K.NormalCOut := K.COut ;
     K.VRev := rtf * ln( K.Cout / K.Cin ) ;
     K.GMax := 0.036*Area ; { Max. K conductance }

     Cl.Cout := 110.0 ;
     Cl.NormalCOut := Cl.COut ;
     Cl.Cin := 4.0 ;

     Cl.GMax := 0.005*Area ;    { Chloride conductance }
     { Note. Internal Cl concentration passively determined by potassium reversal membrane potential. }
     Cl.Cin := Cl.Cout / exp(-K.Vrev/rtf) ;
     Cl.VRev := -rtf * ln( Cl.Cout / Cl.Cin ) ;

     Ca.Cout := 2.0 ;
     Ca.FinalCout := Ca.COut ;
     Ca.NormalCOut := Ca.COut ;
     Ca.Cin := 0.1 ;

     Mg.Cout := 1. ;
     Mg.FinalCout := Mg.COut ;
     Mg.NormalCOut := Mg.COut ;
     Mg.CIn := 1.0 ;

     // Clear injected current into muscle
     MuscleStimulus.Start := -1.0 ;
     MuscleStimulus.Amplitude := -2E-9 ;
     MuscleStimulus.Duration := 1E-3 ;
     MuscleStimulusOn := False ;
     Stim.I := 0.0 ;

     // Clear nerve stimulus
     NerveStimulus.Start := -1.0 ;
     NerveStimulus.Amplitude := -2E-9 ;
     NerveStimulus.Duration := 1E-3 ;
     NerveStimulusOn := False ;

     // Clear endplate and miniature endplate current
     EPC.Active := False ;
     EPC.I := 0.0 ;
     MEPC.Active := False ;
     MEPC.I := 0.0 ;

    // Channels and receptor fractions available or active
    NrvGNa_Available := 1.0 ;
    MusGNa_Available := 1.0 ;
    GK_Available := 1.0 ;
    GAchR_Available := 1.0 ;
    AChR_Available := 1.0 ;
    AChR_Active := 0.0 ;
    AchE_Available := 1.0 ;
    AchR.O:= 0.0 ;
    AchR.C := 1.0 ;
    AchR.D := 0.0 ;
    AchR.Active := 0.0 ;

     InitialiseSimulation := True ;

end ;


procedure TModel.UpdateIonConcentrations ;
// ---------------------------------
// Update ion concentrations in bath
// ---------------------------------
var
       dConc : Single ;
begin

    dConc := (Na.FinalCout - Na.Cout)*MixingRate*dt ;
    Na.Cout := Na.Cout + dConc ;
    Na.VRev := rtf * ln( Na.Cout / Na.Cin ) ;

    dConc := (K.FinalCout - K.Cout)*MixingRate*dt ;
    K.Cout := K.Cout + dConc ;
    K.VRev := rtf * ln( K.Cout / K.Cin ) ;

    dConc := (Ca.FinalCout - Ca.Cout)*MixingRate*dt ;
    Ca.Cout := Ca.Cout + dConc ;
    Ca.VRev := rtf * ln( Ca.Cout / Ca.Cin ) ;

    dConc := (Mg.FinalCout - Mg.Cout)*MixingRate*dt ;
    Mg.Cout := Mg.Cout + dConc ;
    Mg.VRev := rtf * ln( Mg.Cout / Ca.Cin ) ;

    Cl.Cin := Cl.Cout / exp(-K.Vrev/rtf) ;
    Cl.VRev := -rtf * ln( Cl.Cout / Cl.Cin ) ;

    end ;

procedure TModel.UpdateDrugConcentrations ;
// ---------------------------------
// Update drug concentrations in bath
// ---------------------------------
var
       Sum,dConc,Occupancy,Efficacy,ec50 : Single ;
       i : Integer ;
begin

    // Update drug bath concentrations
    for i := 0 to NumDrugs-1 do
         begin
         dConc := (Drugs[i].FinalBathConcentration - Drugs[i].BathConcentration)*MixingRate*dt ;
         Drugs[i].BathConcentration := Drugs[i].BathConcentration + dConc ;
         end ;

    // Fraction of nerve Na channels unblocked
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        Sum := Sum + (Drugs[i].BathConcentration/Drugs[i].EC50_NrvGNa) ;
        end ;
    NrvGNa_Available := 1.0 / (1.0 + Sum ) ;

    // Fraction of muscle Na channels unblocked
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        Sum := Sum + (Drugs[i].BathConcentration/Drugs[i].EC50_MusGNa) ;
        end ;
    MusGNa_Available := 1.0 / (1.0 + Sum ) ;


    // Fraction of K channels unblocked
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        Sum := Sum + (Drugs[i].BathConcentration/Drugs[i].EC50_GK) ;
        end ;
    GK_Available := 1.0 / (1.0 + Sum ) ;

    // Fraction of acetylcholinesterase unblocked
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        Sum := Sum + (Drugs[i].BathConcentration/Drugs[i].EC50_AchE) ;
        end ;
    AchE_Available := 1.0 / (1.0 + Sum ) ;

    // Fraction of post-synaptic nicotinic acetylcholine receptors unblocked
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        // Potency of competitive blockers of nicotinic cholinoeptors decreased (ec50 increased)
        // when cholinesterase enzymes in synaptic cleft are inhibited
        ec50 := Drugs[i].EC50_GAch*(1.0 + 4.0*(1.0-AchE_Available)) ;
        Sum := Sum + Power(Drugs[i].BathConcentration/ec50,2.0) ;
        end ;
    GAchR_Available := 1.0 / (1.0 + Sum ) ;

    // Fraction of post-synaptic nicotinic acetylcholine receptors active
    Sum := 0.0 ;
    for i := 0 to NumDrugs-1 do
        begin
        // Potency of competitive blockers of nicotinic cholinoeptors decreased (ec50 increased)
        // when cholinesterase enzymes in synaptic cleft are inhibited
        Sum := Sum + Power(Drugs[i].BathConcentration/Drugs[i].EC50_GAch,2.0) ;
        end ;
    Occupancy := Sum / ( 1. + Sum ) ;

    Efficacy := 0.0 ;
    for i := 0 to NumDrugs-1 do if not Drugs[i].Antagonist then
        begin
        Efficacy := Efficacy + Power(Drugs[i].BathConcentration/Drugs[i].EC50_GAch,2.0) ;
        end ;
    Efficacy := Efficacy / ( Sum + 0.001 ) ;
    AChR.Active :=  Efficacy*Occupancy ;

    end ;


procedure TModel.DoSimulation ;
{ --------------------------------------
  Run Post-synaptic muscle nmj & action potential simulation
  --------------------------------------}
type
    TRate = record
          m : single ;
          n : single ;
          h : single ;
          end ;
var
   Alpha,Beta : TRate ;
   dm,dn,dh,dv,mInf,hInf : single ;
   dOpen,dClosed,dDesensitised : single ;
   nquanta,r,ClosingRate,p,ec50,x : single ;
   MEPCAverageRate,KVRevNormal : single ;
begin

    { Nerve stimulus }
    if NerveStimulusOn then
       begin

       if not EPC.Active then
          begin

//        Miniature endplate current amplitude
//        Reduced when receptors blocked by cholinergic antagonists (GAchR_Available)
//        Inhibition of cholinesterase enzyme in synaptic cleft increases amount of released Ach and size of quantal current.
//        MEPC amplitude inhibuted by proportion of ACh channels in desensitised state (ACH.D) when Ach agonist present

          epc.QSize := 1.5E-8*( 1.0 + 0.2*(1.0-AchE_Available) )*GAchR_Available*(1.0 - AChR.D) ;
          epc.QSD := epc.QSize*0.05 ;

          // Normal endplate channel closing rate
          ClosingRate := 1.0/1.5E-3 ;
          // Inhibition of cholinesterase decreases closing rate (max. factor of 4 }
          // Inhibition of K channels prolongs duration of transmitter release from nerve terminal
          // modelled here by an effective change in closing rate
          ClosingRate := ClosingRate / ( 1.0 + 3.0*(1.0-AchE_AVailable) + 3.0*(1.0-GK_Available) ) ;
          EPC.TauOpen := 1E-4 ;
          EPC.TauClose := 1.0 /ClosingRate ;

       { Nerve Stimulation }

          //  Probability of release, dependent upon 3rd power of Ca/Mg ratio
          //  and increased by prolongation of nerve terminal action potential by K channel block
          r := (1.0 + 2.0*(1.0-GK_AVailable)) * (Ca.COut/ Max(Mg.Cout,0.1)) ;
          p := Power(r,3)/(1.0 + Power(r,3)) ;

         { No. of quanta available for release Normally 75, doubled by block of presyaptic K channels }
          nquanta := 75.0* (2.0 - GK_AVailable) ;

         { Nerve A.P. conduction fails if Na < 20mM or K > 20mM  }
          if (Na.Cout < 20.0) or (K.Cout >= 20.0) or (NrvGNa_Available < 0.3) then nquanta := 0.0 ;

         { Quantal content for this stimulus }
          EPC.QC := binomial( p, nquanta ) ;
          EPC.Gevoked := (EPC.QC*EPC.QSize) + (GaussianRandom(EPC.QRan)*EPC.QSD*sqrt(Max(EPC.QC,1.0))) ;

          EPC.tStart := NerveStimulus.Start ;
          EPC.Active := True ;

          end ;

       epc.G := epc.Gevoked * (1.0 - exp( -(t-EPC.tStart)/epc.TauOpen))*exp( -(t-EPC.tStart)/EPC.TauClose) * (1.0 - AchR.D) ;
       epc.I := epc.G * ( Vm - epc.VRev ) {* AchR.h} ;

       // Re-enable stimulus at end of EPC
       if (t - EPC.tStart) > (EPC.TauClose*5.0) then
          begin
          NerveStimulusOn := False ;
          NerveStimulus.Start := -1.0 ;
          EPC.Active := False ;
          epc.I := 0.0 ;
          end ;

       end ;

//    Spontaneous miniature endplate currents
//    ---------------------------------------

      // MEPCs are released randomly with rate proportional to nerve resting potential(approximated by normal K.VRev) and Ca concentration
      KVRevNormal := rtf * ln( K.NormalCout / K.Cin ) ;
      MEPCAverageRate := (500.0*Ca.COut)/ ( 1.0 + exp( -(K.VRev - (-0.05))/0.01)) ;
      if (not MEPC.Active) and (Random() <= (dt*MEPCAverageRate)) then
         begin
          MEPC.QSize := 1.5E-8*( 1.0 + 0.2*(1.0-AchE_Available) )*GAchR_Available ;
          MEPC.QSD := MEPC.QSize*0.05 ;
          ClosingRate := 1.0/1.5E-3 ;
          ClosingRate := ClosingRate / ( 1.0 + 3.0*(1.0-AchE_AVailable) ) ;
          MEPC.TauOpen := 1E-4 ;
          MEPC.TauClose := 1.0 /ClosingRate ;
          MEPC.tStart := t ;
          MEPC.Active := True ;
          end ;

      // Calculate MEPC conductance and current
      // Note. MEPC amplitude inhibuted by proportion of ACh channels in desensitised state (ACH.D) when Ach agonist present

      if MEPC.Active then
         begin
         MEPC.G := MEPC.QSize * (1.0 - exp( -(t-MEPC.tStart)/MEPC.TauOpen))*exp( -(t-MEPC.tStart)/MEPC.TauClose) * (1.0 - AchR.D) ;
         MEPC.I := MEPC.G * ( Vm - epc.VRev )  ;
         if (t - MEPC.tStart) > (MEPC.TauClose*4.0) then
            begin
            MEPC.Active := False ;
            MEPC.I := 0.0 ;
            end;
         end ;

      { Direct muscle stimulation }
      if MuscleStimulusOn then
         begin
         Stim.I := MuscleStimulus.Amplitude ;
         if t > MuscleStimulus.Start + MuscleStimulus.Duration then MuscleStimulusOn := False ;
         end
      else Stim.I := 0. ;

      { Na current }

      { Na Activation parameter (m) }

      if abs( -Vm - 0.050 ) > 1E-4 then
         begin
         Alpha.m := 1E5*( -Vm - 0.050)/( exp((-Vm - 0.050)/0.01) -1.0) ;
         end
      else
         begin
         Alpha.m := 5.0*( 1.0/( exp((1E-4)/0.01) -1.0) + 1.0/( exp((-1E-4)/0.01) -1.0) ) ;
         end ;

      Beta.m := 4E3*exp( -(Vm + 0.06)/0.018 ) ;
      if InitialiseSimulation then Na.m := Alpha.m / ( Alpha.m + Beta.m ) ;
      dm := ( Alpha.m*(1.0 - Na.m) - Beta.m*Na.m )*dt ;
      Na.m := Na.m + dm ;

      { Na Inactivation parameter (h) }

      Alpha.h := 70.0*exp( -(Vm + 0.06)/0.02) ;
      Beta.h := 1E3/( exp((-Vm - 0.03)/0.01) + 1.0) ;
      if InitialiseSimulation then Na.h := Alpha.h / ( Alpha.h + Beta.h ) ;
      dh := ( Alpha.h*(1.0 - Na.h) - Beta.h*Na.h )*dt ;
      Na.h := Na.h + dh ;

      { Na conductance & current }

      Na.G := Power( Na.m, 3.0 )*Na.h*Na.GMax*MusGNa_Available ;
      Na.I := Na.G*( Vm - NA.VRev ) ;

      { Potassium current }

       { K Activation parameter (n) }

      if abs(-Vm - 0.05) > 1E-4  then
         begin
         Alpha.n := 1E4*(-Vm - 0.05)/( exp((-Vm - 0.05)/0.01) -1.0) ;
         end
      else
         begin
         Alpha.n := 0.5*( 1.0/( exp(1E-2) -1.0) -1.0/( exp(-1E-2) -1.0) );
         end ;

      Beta.n := 125.0*exp( (-Vm - 0.06)/0.08 ) ;
      if InitialiseSimulation then K.n := Alpha.n / ( Alpha.n + Beta.n ) ;

      dn := ( Alpha.n*(1.0 - K.n) - Beta.n*K.n )*dt ;
      K.n := K.n + dn ;
      K.G := Power(K.n, 4.0)*K.gMax*GK_Available ;
      K.I := K.g * (Vm - K.VRev ) ;

       { Leak current (chloride) }

       Cl.I := Cl.GMAX * (Vm - Cl.VRev ) ;

       { Acetylcholine channel current }

       { Opening of Ach channels Closed <> Open > Desensitised }

       AchR.CtoO := AchR.Active*20.0 ;
       if AchR.Active > 1E-3 then AchR.OtoC := 20.0
                             else AchR.OtoC := 100.0 ;
       AchR.OtoD := 10.0 ;
       AchR.DtoO := 10.0 ;

       dOpen := AchR.C*AchR.CtoO - AchR.O*(AchR.OtoC + AchR.OtoD) ;
       dClosed := AchR.O*AchR.OtoC - AchR.C*AchR.CtoO ;
       dDesensitised := AchR.O*AchR.OtoD - AchR.D*AchR.DtoO ;

       AChR.C := Max(Min(AchR.C + dClosed*dt,1.0),0.0);
       AChR.D := Max(Min(AchR.D + dDesensitised*dt,1.0),0.0);
       AchR.O := 1.0 - AchR.C - achR.D ;

       { ACh current }
       AchR.GMax := 300.0*1.5E-8  ;
       AchR.G := AchR.GMax * AchR.O ;
       AchR.I := AchR.g * (Vm - AchR.VRev ) ;

       { Compute muscle cell membrane current (summation of all ionic currents) }

       Im := Na.I + K.I + Cl.I - Stim.I + EPC.I + MEPC.I + AchR.I + (random - 0.5)*Noise ;

       { Compute change in membrane potential }

       dV := ( -Im ) * dt/C ;
       Vm := Vm + dv ;

       t := t + dt ;
       InitialiseSimulation := False ;

end;


procedure TModel.StimulateNerve ;
// ---------------------------
// Stimulate presynapti nerve.
// ---------------------------
begin
    NerveStimulus.Start := t ;
    NerveStimulus.Duration := 1E-2 ; // limits stimulus rate to 100 Hz max.
    NerveStimulusOn := True ;
end;


procedure TModel.StimulateMuscle( Amplitude : single ; Duration : Single ) ;
// -------------------------------------
// Stimulate muscle by injecting current
// -------------------------------------
begin
    MuscleStimulus.Start := t ;
    MuscleStimulus.Amplitude := Amplitude ;
    MuscleStimulus.Duration := Duration ; // limits stimulus rate to 100 Hz max.
    MuscleStimulusOn := True ;
end;


function TModel.binomial( pIn, n : Single ) : Single ;
{ --------------------------------------------
  Binomial random number generator
  Returns a number from the distribution B(pIn,n)
  where pIn = probability, n = number of items
  (Base on Numerical Recipes code)
  --------------------------------------------}
var
   p,mean,r,em,g,t,oldg,pc,pclog,y,plog,sq,zz : Single ;
   i : LongInt ;
   quit : Boolean ;
begin

	if pIn > 0.5 then p := 1. - pIn
                     else p := pIn ;

	mean := n*p ;
	if n <= 25.  then
     begin
	   r := 0. ;
	   for i := 1 to Trunc(n) do if random < p then r := r + 1. ;
     end
	else if mean < 1. then
     begin
	   g := exp(-mean) ;
	   t := 1. ;
	   r := 0. ;
	   while( (r<n) and (t<g) ) do
        begin
		    t := t*random ;
		    r := r + 1. ;
        end ;
     end
	else
     begin
	   oldg := gammln(n+1. ) ;
	   pc := 1. - p ;
	   plog := ln(p) ;
	   pclog := ln(pc) ;
	   sq := sqrt(2.*mean*pc) ;

	   quit := False ;
	   while ( not quit ) do
           begin
           { Make sure TAN(infinity) is not calculated }
           repeat zz := random until (Abs(zz-0.5)>0.001) ;
           y := tan(zz*Pi) ;
	         em := sq*y + mean ;
	         if (em >= 0. ) and (em < n+1. ) then
              begin
		          em := Int(em) ;
		          t := 1.2*sq*(1.+y*y)*exp(oldg-gammln(em+1. ) -
     		      gammln(n-em+1. ) + em*plog + (n-em)*pclog) ;
		          if( random <= t ) then quit := True ;
              end ;
              end ;
     r := em ;
     end ;

	if ( p <> pIn ) then r := n - r ;
	binomial := r ;
  end ;


function TModel.GaussianRandom( GSet : Single ) : Single ;
var
        v1,v2,r,fac : Single ;
begin
	if GSet = 1. then begin
            repeat
	          v1 := 2.*random - 1. ;
	          v2 := 2.*random - 1. ;
	          r := v1*v1 + v2*v2 ;
                  until r < 1. ;
	    fac := sqrt( -2.*ln(r)/r);
	    gset := v1*fac ;
	    GaussianRandom := v2*fac ;
            end
	else begin
             GaussianRandom := gset ;
             gset := 1. ;
             end ;
	end ;


function TModel.Gammln( xx : Single ) : Single ;
var
   stp,x,tmp,ser : Double ;
   cof : Array[1..7] of Double ;
   i : LongInt ;
begin
	cof[1] := 76.18009173 ;
	cof[2] := -86.50532033 ;
	cof[3] := 24.01409822 ;
	cof[4] := -1.231739516 ;
	cof[5] := 0.120858003E-2 ;
	cof[6] := -0.536382E-5 ;
	stp := 2.50662827465 ;

	x := (xx - 1. ) ;
	tmp := x + 5.5 ;
	tmp := ( x + 0.5)*ln(tmp) - tmp;
	ser := 1. ;
	for i := 1 to 6 do begin
	    x := x + 1. ;
	    ser := ser + cof[i]/x ;
	    end ;
	tmp := tmp + ln(stp*ser) ;
	gammln := tmp ;
        end ;


end.
