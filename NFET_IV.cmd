

Device SSOI 
{

    File 
    {
        * Input files:
        Grid		= "6_SSOI_device_final_fps.tdr"
        Piezo		= "6_SSOI_device_final_fps.tdr"
        Parameter	= "parameters.par"
        
        * Output files:
        Plot	= "SSOI_IdVg_des.tdr"
        Current	= "SSOI_IdVg_des.plt"
#	    Output	= "SSOI_IdVg_des.log"
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
#        AreaFactor=1
        Fermi
        eMultiValley(MLDA kpDOS -Density)
        EffectiveIntrinsicDensity( BandGapNarrowing( OldSlotBoom ) )
        Mobility 
        (
            Enormal( RPS InterfaceCharge(SurfaceName="S1") )
#           Enormal( RPS  )
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
        MetalWorkfunction ( Workfunction = 4.5 )	# eV
    }

    Plot 
    {
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
*       eTrappedCharge hTrappedCharge


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

File 
{ 
	Output	= "SSOI_IdVg_des.log"
#	ACExtract = "SSOI_CV_des.acplot"
}


System 
{
	SSOI	trans ( Gate_Contact = g1	Drain_Contact = d1		Source_Contact = s1		Substrate_Contact = b1 )
	Vsource_pset vg1 (g1 0) {dc = 0.}
	Vsource_pset vd1 (d1 0) {dc = 0.}
	Vsource_pset vs1 (s1 0) {dc = 0.}
	Vsource_pset vb1 (b1 0) {dc = 0.}
}

Solve
{
	*- Initial Solution:
    Coupled(Iterations=100 LineSearchDamping=1e-4) { Poisson eQuantumPotential }
    Coupled(Iterations=100) { Poisson Electron eQuantumPotential }

    #-- Ramp gate to 1.2
    Quasistationary( 
        InitialStep= 1e-2 Increment= 1.25 
        MinStep= 1e-8 MaxStep= 0.5 
        Goal { Parameter = vg1.dc Voltage= 1.2 }
    ){ Coupled { Poisson Electron eQuantumPotential } }

    #-- Ramp drain to VdLin
    Quasistationary( 
        InitialStep= 1e-2 Increment= 1.25 
        MinStep= 1e-8 MaxStep= 0.5 
        Goal { Parameter = vd1.dc Voltage= 0.05 }
    ){ Coupled { Poisson Electron eQuantumPotential } }
    Save ( FilePrefix= "IdVg_VdLin" )

    #-- Ramp drain to VdSat
    Quasistationary( 
        InitialStep= 1e-2 Increment= 1.25 
        MinStep= 1e-8 MaxStep= 0.5 
        Goal { Parameter = vd1.dc Voltage= 0.75 }
    ){ Coupled { Poisson Electron eQuantumPotential } }
    Save ( FilePrefix= "IdVg_VdSat" )

    #-- Vg sweep for Vd=VdLin
    NewCurrentFile= "IdVg_VdLin_" 
    Load ( FilePrefix= "IdVg_VdLin" )
    Quasistationary( 
        DoZero 
        InitialStep= 1e-3 Increment= 1.2 
        MinStep= 1e-15 MaxStep= 0.02 
        Goal { Parameter = vg1.dc Voltage= -1.0 } 
    ){ Coupled { Poisson Electron eQuantumPotential } }

    #-- Vg sweep for Vd=VdSat
    NewCurrentFile= "IdVg_VdSat_" 
    Load ( FilePrefix= "IdVg_VdSat" )
    Quasistationary( 
        DoZero 
        InitialStep= 1e-3 Increment= 1.2 
        MinStep= 1e-15 MaxStep= 0.02 
        Goal { Parameter = vg1.dc Voltage= -1.0}
   ){ Coupled { Poisson Electron eQuantumPotential } }

}