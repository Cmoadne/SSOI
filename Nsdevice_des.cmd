*----------------------------------------------------------------------*
Device SSOI {
*----------------------------------------------------------------------*
    File
    {
        * Input Files
        Grid			= "6_SSOI_device_final_fps.tdr"
        Piezo		= "6_SSOI_device_final_fps.tdr"
        Parameters	= "parameters.par"
        
        * Output Files
        Current		= "@plot@"
        Plot			= "@tdrdat@"
    }

    Electrode 
    {
        { Name = "Gate_Contact"			Voltage = 0. }
#	    { Name = "Gate_Contact"			Voltage = 0.	Workfunction = 5.5 }
        { Name = "Drain_Contact"		Voltage = 0. 	DistResist=1e-9 }
        { Name = "Source_Contact"		Voltage = 0.	DistResist=1e-9 }
        { Name = "Substrate_Contact"	Voltage = 0. }
    }

Physics 
{
	Fermi
    eMultiValley(MLDA kpDOS -Density)
    EffectiveIntrinsicDensity( BandGapNarrowing( OldSlotBoom ) )
    Mobility 
    (
        Enormal( RPS InterfaceCharge(SurfaceName="S1") )
    #     Enormal( RPS  )
        ThinLayer(IALMob(AutoOrientation) MinAngle=(0,0))
        HighFieldSaturation(GradQuasiFermi)
    )
    Recombination ( SRH(DopingDep) Auger Band2Band ( Model = Hurkx ) )

    Piezo
    (
        Model
        (
            Mobility
            (
                eSubBand(Doping EffectiveMass Scattering(MLDA) AutoOrientation RelChDir110)
                eSaturationFactor = 0.2
            )
            DeformationPotential(ekp hkp minimum)
            DOS(eMass hMass)
            )
    )
}

Physics(Region="SiFilm") { eQuantumPotential(AutoOrientation Density) }

Physics ( Material = "Platinum" ) 
{
	MetalWorkfunction ( Workfunction = 4.4 )	# eV
}


   Plot {
    eDensity hDensity eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
    Potential Electricfield/Vector Doping SpaceCharge
    eMobility hMobility eVelocity/Vector hVelocity/Vector
    DonorConcentration Acceptorconcentration
    BandGap Affinity BandGapNarrowing EffectiveBandGap EffectiveIntrinsicDensity
    ConductionBand ValenceBand
    eQuasiFermi hQuasiFermi eGradQuasiFermi/Vector hGradQuasiFermi/Vector
    eEparallel hEparallel eTemperature hTemperature 
    SRH Auger Avalanche TotalTrapConcentration
    eBand2BandGeneration hBand2BandGeneration Band2BandGeneration
    eLifetime hLifetime
    *  eTrappedCharge hTrappedCharge


    eMobilityStressFactorXX eMobilityStressFactorYY eMobilityStressFactorZZ
    eMobilityStressFactorYZ eMobilityStressFactorXZ eMobilityStressFactorXY
    hMobilityStressFactorXX hMobilityStressFactorYY hMobilityStressFactorZZ
    hMobilityStressFactorYZ hMobilityStressFactorXZ hMobilityStressFactorXY
    StressXX StressYY StressZZ StressXY StressYZ StressXZ
    
    eTensorMobilityFactorXX eTensorMobilityFactorYY eTensorMobilityFactorZZ
    hTensorMobilityFactorXX hTensorMobilityFactorYY hTensorMobilityFactorZZ

    eQuantumPotential

    xMoleFraction
    LayerThickness NearestInterfaceOrientation
    "EparallelToInterface"/Vector
    "NormalToInterface"/Vector
}

*----------------------------------------------------------------------*
} *- End of Device{}
*----------------------------------------------------------------------*

File
{
   Output= "@log@"
   ACExtract="@acplot@"
}

System 
{
   SSOI trans (Gate_Contact = g1	Drain_Contact = d1		Source_Contact = s1		Substrate_Contact = b1)
   Vsource_pset vg ( g1 0 ) { dc = 0 }
   Vsource_pset vd ( d1 0 ) { dc = 0 }
   Vsource_pset vs ( s1 0 ) { dc = 0 }
   Vsource_pset vb ( b1 0 ) { dc = 0 }
#if @Rfb@ != 0
   Resistor_pset Rfb ( g1 d1 ) { resistance = @Rfb@ }
#endif
}

Plot {
*--Carrier density and currents, etc.
   eDensity hDensity
   TotalCurrent/Vector eCurrent/Vector hCurrent/Vector
   eMobility hMobility
   eVelocity hVelocity
   eQuasiFermi hQuasiFermi

*--Temperature 
   eTemperature 
   * hTemperature Temperature

*--Fields and charges
   ElectricField/Vector Potential SpaceCharge

*--Doping Profiles
   Doping DonorConcentration AcceptorConcentration

*--Generation/Recombination
   SRH Auger
   AvalancheGeneration eAvalancheGeneration hAvalancheGeneration

*--Driving forces
   eGradQuasiFermi/Vector hGradQuasiFermi/Vector
   eEparallel hEparalllel

*--Band structure/Composition
   BandGap 
   * BandGapNarrowing
   Affinity
   ConductionBand ValenceBand
   xMoleFraction

*--Traps
   eTrappedCharge  hTrappedCharge
   eGapStatesRecombination hGapStatesRecombination

*--Heat generation
   * TotalHeat eJouleHeat hJouleHeat RecombinationHeat

*--Stress
   Stress	StressXX	StressYY	StressZZ
}

Math 
{
    CoordinateSystem { UCS }

#    MVMLDAcontrols( Load = "SiGe_des.kpBand" )
*   MVMLDAcontrols( Load = "SiGe_des.kpBand" )
    -CheckUndefinedModels
    Surface "S1" ( MaterialInterface="HfO2/Oxide")
#   ThinLayer( Mirror = ( None Min None ) )
    AutoOrientationSmoothingDistance = -1
    GeometricDistances   
    Extrapolate
    Derivative
    Method=ILS
    wallclock
    RhsMin = 1e-12
    Iterations=15
    ExitOnFailure
    Number_of_Threads = 12  
    StressMobilityDependence = TensorFactor
}

Solve{
*- Initial Solution
   NewCurrentFile="Init_"
   Coupled(Iterations=100 LineSearchDamping=1e-4) { Poisson eQuantumPotential }
   Coupled(Iterations=100) { Poisson Electron eQuantumPotential }

*- Ramp drain to Vd, gate to VgMin
   Quasistationary(
      InitialStep= 5e-3 Increment= 1.4
      MinStep= 1e-6 MaxStep= 0.05
      Goal{ Parameter= vg.dc Voltage= @Vgmin@ }
      Goal{ Parameter= vd.dc Voltage= @Vd@ }
      Goal{ Parameter= vb.dc Voltage= @Vd@ }
   ){ Coupled { Poisson Electron eQuantumPotential} }



*- AC analysis: Ramp Gate to Vgmax 
   NewCurrentFile=""
   Quasistationary(
      InitialStep= 5e-3 Increment= 1.2
      MinStep= 1e-7 MaxStep= 0.02
      DoZero
      Goal{ Parameter= vg.dc Voltage=@Vgmax@ }
   ){ ACCoupled( 
        StartFrequency= 1e8 EndFrequency= 1e12
		* NumberOfPoints= points_Per_Decade*number_Of_Decades + 1
        NumberOfPoints= @<nPerDecade*4+1>@ Decade
        Node(g1 d1 s1 b1) Exclude(vg vd vs vb) 
        ACCompute( Time=(Range=(0 1) Intervals= 20) )
      ){ Poisson Electron eQuantumPotential}
	   CurrentPlot( Time=(Range=(0 1) Intervals= 20) ) 
   }
}

