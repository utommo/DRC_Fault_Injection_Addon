! This module contains basic functions
MODULE Functions

USE Constants
IMPLICIT NONE

CONTAINS
	!-------------------------------------------------------------------------------------------------------------------------------
	! Saturates inputValue. Makes sure it is not smaller than minValue and not larger than maxValue
	REAL FUNCTION saturate(inputValue, minValue, maxValue)
	!

		IMPLICIT NONE

		REAL(4), INTENT(IN)		:: inputValue
		REAL(4), INTENT(IN)		:: minValue
		REAL(4), INTENT(IN)		:: maxValue

		saturate = MIN(MAX(inputValue,minValue), maxValue)

	END FUNCTION saturate
	!-------------------------------------------------------------------------------------------------------------------------------
	! Saturates inputValue. Makes sure it is not smaller than minValue and not larger than maxValue
	REAL FUNCTION ratelimit(inputSignal, inputSignalPrev, minRate, maxRate, DT)
	!
		IMPLICIT NONE

		REAL(4), INTENT(IN)		:: inputSignal
		REAL(4), INTENT(IN)		:: inputSignalPrev
		REAL(4), INTENT(IN)		:: minRate
		REAL(4), INTENT(IN)		:: maxRate
		REAL(4), INTENT(IN)		:: DT
		
		! Local variables
		REAL(4)					:: rate

		rate = (inputSignal - inputSignalPrev)/DT						! Signal rate (unsaturated)
		rate = saturate(rate, minRate, maxRate)					! Saturate the signal rate
		ratelimit = inputSignalPrev + rate*DT						! Saturate the overall command using the rate limit

	END FUNCTION ratelimit
	!-------------------------------------------------------------------------------------------------------------------------------
	! PI controller, with output saturation
	REAL FUNCTION PIController(error, kp, ki, minValue, maxValue, DT, I0, reset, inst)
	!
		IMPLICIT NONE

		! Inputs
		REAL(4), INTENT(IN)			:: error
		REAL(4), INTENT(IN)			:: kp
		REAL(4), INTENT(IN)			:: ki
		REAL(4), INTENT(IN)			:: minValue
		REAL(4), INTENT(IN)			:: maxValue
		REAL(4), INTENT(IN)			:: DT
		INTEGER(4), INTENT(INOUT)	:: inst
		REAL(4), INTENT(IN)			:: I0
		LOGICAL, INTENT(IN)			:: reset
		
		! Local
		INTEGER(4)						:: i											! Counter for making arrays
		REAL(4)							:: PTerm										! Proportional term
		REAL(4), DIMENSION(99), SAVE	:: ITerm = (/ (real(9999.9), i = 1,99) /)		! Integral term, current.
		REAL(4), DIMENSION(99), SAVE	:: ITermLast = (/ (real(9999.9), i = 1,99) /)	! Integral term, the last time this controller was called. Supports 99 separate instances.
		INTEGER(4), DIMENSION(99), SAVE	:: FirstCall = (/ (1, i=1,99) /)				! First call of this function?
		
		! Initialize persistent variables/arrays, and set inital condition for integrator term
		IF ((FirstCall(inst) == 1) .OR. reset) THEN
			ITerm(inst) = I0
			ITermLast(inst) = I0
			
			FirstCall(inst) = 0
			PIController = I0
		ELSE
			PTerm = kp*error
			ITerm(inst) = ITerm(inst) + DT*ki*error
			ITerm(inst) = saturate(ITerm(inst), minValue, maxValue)
			PIController = PTerm + ITerm(inst)
			PIController = saturate(PIController, minValue, maxValue)
		
			ITermLast(inst) = ITerm(inst)
		END IF
		inst = inst + 1
		
	END FUNCTION PIController
	!-------------------------------------------------------------------------------------------------------------------------------
	! interp1 1-D interpolation (table lookup), xData and yData should be monotonically increasing
	REAL FUNCTION interp1d(xData, yData, xq)
	!
		IMPLICIT NONE
			! Inputs
		REAL(4), DIMENSION(:), INTENT(IN)		:: xData		! Provided x data (vector), to be interpolated
		REAL(4), DIMENSION(:), INTENT(IN)		:: yData		! Provided y data (vector), to be interpolated
		REAL(4), INTENT(IN)						:: xq			! x-value for which the y value has to be interpolated
		INTEGER(4)								:: I			! Iteration index
		
		IF (xq <= MINVAL(xData)) THEN
			interp1d = yData(1)
		ELSEIF (xq >= MAXVAL(xData)) THEN
			interp1d = yData(SIZE(xData))
		ELSE
			DO I = 1, SIZE(xData)
				IF (xq <= xData(I)) THEN
					interp1d = yData(I-1) + (yData(I) - yData(I-1))/(xData(I) - xData(I-1))*(xq - xData(I-1))
					EXIT
				ELSE
					CONTINUE
				END IF
			END DO
		END IF
		
	END FUNCTION interp1d
	!-------------------------------------------------------------------------------------------------------------------------------
	! DF controller, with output saturation
	REAL FUNCTION DFController(error, Kd, Tf, DT, inst)
	!
		IMPLICIT NONE

			! Inputs
		REAL(4), INTENT(IN)		:: error
		REAL(4), INTENT(IN)		:: kd
		REAL(4), INTENT(IN)		:: tf
		REAL(4), INTENT(IN)		:: DT
		INTEGER(4), INTENT(IN)	:: inst
		
			! Local
		REAL(4)							:: B									! 
		INTEGER(4)						:: i									! Counter for making arrays
		REAL(4), DIMENSION(99), SAVE	:: errorLast = (/ (0, i=1,99) /)		! 
		REAL(4), DIMENSION(99), SAVE	:: DFControllerLast = (/ (0, i=1,99) /)	! 
		INTEGER(4), DIMENSION(99), SAVE	:: FirstCall = (/ (1, i=1,99) /)		! First call of this function?
		
			! Initialize persistent variables/arrays, and set inital condition for integrator term
		! IF (FirstCall(inst) == 1) THEN
			! FirstCall(inst) = 0
		! END IF
		
		B = 2.0/DT
		DFController = (Kd*B)/(B*Tf+1.0)*error - (Kd*B)/(B*Tf+1.0)*errorLast(inst) - (1.0-B*Tf)/(B*Tf+1.0)*DFControllerLast(inst)

		errorLast(inst) = error
		DFControllerLast(inst) = DFController
	END FUNCTION DFController
	!-------------------------------------------------------------------------------------------------------------------------------
	! State machines, determines the state of the wind turbine to determine the corresponding control actions
	! States:
	! - VS/PC_State = 0, Error state, for debugging purposes (VS) / No pitch control active, pitch constant at fine-pitch (PC)
	! - VS_State = 1, Region 1(.5) operation, torque control to keep the rotor at cut-in speed towards the Cp-max operational curve
	! - VS_State = 2, Region 2, operation, maximum rotor power efficiency (Cp-max) tracking, keep TSR constant at a fixed fine-pitch angle
	! - VS_State = 3, Region 2.5, transition between below and above-rated operating conditions (near-rated region) using PI torque control
	! - VS_State = 4 + PC_State = 1, above-rated operation using pitch control (constant torque mode)
	! - VS_State = 5 + PC_State = 2, above-rated operation using pitch and torque control (constant power mode)
	SUBROUTINE StateMachine(CntrPar, LocalVar)
		USE DRC_Types, ONLY : LocalVariables, ControlParameters
		IMPLICIT NONE
    
			! Inputs
		TYPE(ControlParameters), INTENT(IN)		:: CntrPar
		TYPE(LocalVariables), INTENT(INOUT)		:: LocalVar
		
			! Local
			! Pitch control state machine
		IF (LocalVar%iStatus == 0) THEN
			IF (LocalVar%PitCom(1) >= CntrPar%VS_Rgn3Pitch) THEN ! We are in region 3
				IF (CntrPar%VS_ControlMode == 1) THEN ! Constant power tracking
					LocalVar%VS_State = 5
					LocalVar%PC_State = 2
				ELSE ! Constant torque tracking
					LocalVar%VS_State = 4
					LocalVar%PC_State = 1
				END IF
			ELSE
				LocalVar%VS_State = 2
				LocalVar%PC_State = 0
			END IF
		ELSE
			IF ((CntrPar%VS_ControlMode == 0) .AND. (LocalVar%GenTq >= CntrPar%PC_RtTq99)) THEN
				LocalVar%PC_State = 1
			ELSEIF ((CntrPar%VS_ControlMode == 1) .AND. (LocalVar%GenArTq >= CntrPar%VS_ArSatTq*0.99)) THEN
				LocalVar%PC_State = 2
			ELSE
				LocalVar%PC_State = 0
			END IF
			
				! Torque control state machine
			IF (LocalVar%PC_PitComT >= CntrPar%VS_Rgn3Pitch) THEN ! We are in region 3 ! 
				IF (CntrPar%VS_ControlMode == 1) THEN ! Constant power tracking
					LocalVar%VS_State = 5
				ELSE ! Constant torque tracking
					LocalVar%VS_State = 4
				END IF
			ELSE
				IF (LocalVar%GenArTq >= CntrPar%VS_MaxOMTq*1.01) THEN ! We are in region 2 1/2 - active PI torque control
					LocalVar%VS_State = 3
				ELSEIF (LocalVar%GenBrTq <= CntrPar%VS_MinOMTq*0.99) THEN ! We are in region 1 1/2
					LocalVar%VS_State = 1
				ELSEIF (LocalVar%GenSpeedF < CntrPar%VS_RefSpd)  THEN ! We are in region 2 - optimal torque is proportional to the square of the generator speed
					LocalVar%VS_State = 2
				ELSE ! Error state, for debugging purposes
					LocalVar%VS_State = 0
				END IF
			END IF
		END IF
	END SUBROUTINE StateMachine
	!-------------------------------------------------------------------------------------------------------------------------------
	SUBROUTINE Debug(LocalVar, CntrPar, avrSWAP, RootName, size_avcOUTNAME)
		USE, INTRINSIC	:: ISO_C_Binding
		USE DRC_Types, ONLY : LocalVariables, ControlParameters
		
		IMPLICIT NONE
	
		TYPE(ControlParameters), INTENT(IN)		:: CntrPar
		TYPE(LocalVariables), INTENT(IN)		:: LocalVar
	
		INTEGER(4), INTENT(IN)						:: size_avcOUTNAME
		INTEGER(4)									:: I				! Generic index.
		CHARACTER(1), PARAMETER						:: Tab = CHAR(9)						! The tab character.
		CHARACTER(25), PARAMETER					:: FmtDat = "(F8.3,99('"//Tab//"',ES10.3E2,:))	"	! The format of the debugging data
		INTEGER(4), PARAMETER						:: UnDb = 85		! I/O unit for the debugging information
		INTEGER(4), PARAMETER						:: UnDb2 = 86		! I/O unit for the debugging information, avrSWAP
		REAL(C_FLOAT), INTENT(INOUT)				:: avrSWAP(*)	! The swap array, used to pass data to, and receive data from, the DLL controller.
		CHARACTER(size_avcOUTNAME-1), INTENT(IN)	:: RootName		! a Fortran version of the input C string (not considered an array here)    [subtract 1 for the C null-character]
		
		!..............................................................................................................................
		! Initializing debug file
		!..............................................................................................................................
		IF (LocalVar%iStatus == 0)  THEN  ! .TRUE. if we're on the first call to the DLL
		! If we're debugging, open the debug file and write the header:
			IF (CntrPar%LoggingLevel > 0) THEN
				OPEN(unit=UnDb, FILE='DEBUG.dbg')
				WRITE (UnDb,'(A)')	'Time'//Tab//'PtchC1'//Tab//'PtchC2'//Tab//'PtchC3'//Tab//'rootMOOP1'//Tab//'rootMOOP2'//Tab//'rootMOOP3'//Tab//'BlPitch1C'//Tab//'BlPitch2C'//Tab//'BlPitch3C'
				!               	 Time (sec),  PtchC1 (rad),  PtchC2 (rad),  PtchC3 (rad),  rootMOOP1 (Nm),   rootMOOP2 (Nm),   rootMOOP3 (Nm),   BlPitch1C (deg)   BlPitch2C (deg),  BlPitch3C (deg)
			END IF
			
			IF (CntrPar%LoggingLevel > 1) THEN
                OPEN(unit=UnDb2, FILE='DEBUG.dbg2')
				WRITE (UnDb2,'(A)')	'Time'//Tab//'rootMOOP1'//Tab//'rootMOOP2'//Tab//'rootMOOP3'//Tab//'BlPitch1'//Tab//'BlPitch2'//Tab//'BlPitch3'
				!					 Time (sec),  rootMOOP1 (Nm),   rootMOOP2 (Nm),   rootMOOP3 (Nm),  BlPitch1 (deg)  BlPitch2 (deg),    BlPitch3 (deg)
			END IF
		ELSE
			! Output debugging information if requested:
			IF (CntrPar%LoggingLevel > 0) THEN
				! Thomas: Added a rootMOOP log output, removed unecessary stuff
				WRITE (UnDb,FmtDat)		LocalVar%Time, LocalVar%PitCom, LocalVar%rootMOOP, avrSWAP(42:44)
			END IF
			
			IF (CntrPar%LoggingLevel > 1) THEN
				WRITE (UnDb2,FmtDat)	LocalVar%Time, avrSWAP(30:32), avrSWAP(4), avrSWAP(33), avrSWAP(34)
			END IF
		END IF

	END SUBROUTINE Debug
	!-------------------------------------------------------------------------------------------------------------------------------
	!The Coleman or d-q axis transformation transforms the root out of plane bending moments of each turbine blade
	!to a direct axis and a quadrature axis
	SUBROUTINE ColemanTransform(rootMOOP, aziAngle, nHarmonic, axTOut, axYOut)
	!...............................................................................................................................

		IMPLICIT NONE

			! Inputs

		REAL(4), INTENT(IN)		:: rootMOOP(3)						! Root out of plane bending moments of each blade
		REAL(4), INTENT(IN)		:: aziAngle							! Rotor azimuth angle
        INTEGER(4), INTENT(IN)  :: nHarmonic                        ! The harmonic number, nP

			! Outputs

		REAL(4), INTENT(OUT)	:: axTOut, axYOut				! Direct axis and quadrature axis outputted by this transform

			! Local

		REAL(4), PARAMETER		:: phi2 = 2.0/3.0*PI				! Phase difference from first to second blade
		REAL(4), PARAMETER		:: phi3 = 4.0/3.0*PI				! Phase difference from first to third blade

			! Body

		axTOut	= 2.0/3.0 * (cos(nHarmonic*(aziAngle))*rootMOOP(1) + cos(nHarmonic*(aziAngle+phi2))*rootMOOP(2) + cos(nHarmonic*(aziAngle+phi3))*rootMOOP(3))
		axYOut  = 2.0/3.0 * (sin(nHarmonic*(aziAngle))*rootMOOP(1) + sin(nHarmonic*(aziAngle+phi2))*rootMOOP(2) + sin(nHarmonic*(aziAngle+phi3))*rootMOOP(3))
		
	END SUBROUTINE ColemanTransform
	!-------------------------------------------------------------------------------------------------------------------------------
	!The inverse Coleman or d-q axis transformation transforms the direct axis and quadrature axis
	!back to root out of plane bending moments of each turbine blade
	SUBROUTINE ColemanTransformInverse(axTIn, axYIn, aziAngle, nHarmonic, aziOffset, PitComIPC)
	!...............................................................................................................................

		IMPLICIT NONE

			! Inputs

		REAL(4), INTENT(IN)		:: axTIn, axYIn			! Direct axis and quadrature axis
		REAL(4), INTENT(IN)		:: aziAngle						! Rotor azimuth angle
		REAL(4), INTENT(IN)		:: aziOffset					! Phase shift added to the azimuth angle
        INTEGER(4), INTENT(IN)  :: nHarmonic					! The harmonic number, nP

			! Outputs

		REAL(4), INTENT(OUT)	:: PitComIPC(3)					! Root out of plane bending moments of each blade

			! Local

		REAL(4), PARAMETER		:: phi2 = 2.0/3.0*PI				! Phase difference from first to second blade
		REAL(4), PARAMETER		:: phi3 = 4.0/3.0*PI				! Phase difference from first to third blade

			! Body

		PitComIPC(1) = cos(nHarmonic*(aziAngle+aziOffset))*axTIn + sin(nHarmonic*(aziAngle+aziOffset))*axYIn
		PitComIPC(2) = cos(nHarmonic*(aziAngle+aziOffset+phi2))*axTIn + sin(nHarmonic*(aziAngle+aziOffset+phi2))*axYIn
		PitComIPC(3) = cos(nHarmonic*(aziAngle+aziOffset+phi3))*axTIn + sin(nHarmonic*(aziAngle+aziOffset+phi3))*axYIn

	END SUBROUTINE ColemanTransformInverse
	!-------------------------------------------------------------------------------------------------------------------------------
	!Paremeterized Cp(lambda) function for a fixed pitch angle. Circumvents the need of importing a look-up table
	REAL FUNCTION CPfunction(CP, lambda)
		IMPLICIT NONE
		
		! Inputs
		REAL(4), INTENT(IN) :: CP(4)    ! Parameters defining the parameterizable Cp(lambda) function
		REAL(4), INTENT(IN) :: lambda    ! Estimated or measured tip-speed ratio input
        
		CPfunction = exp(-CP(1)/lambda)*(CP(2)/lambda-CP(3))+CP(4)*lambda
		CPfunction = saturate(CPfunction, 0.001, 1.0)
		
	END FUNCTION CPfunction
	!-------------------------------------------------------------------------------------------------------------------------------
	!Function for computing the aerodynamic torque, divided by the effective rotor torque of the turbine, for use in wind speed estimation
	REAL FUNCTION AeroDynTorque(LocalVar, CntrPar)
		USE DRC_Types, ONLY : LocalVariables, ControlParameters
		IMPLICIT NONE
    
			! Inputs
		TYPE(ControlParameters), INTENT(IN) :: CntrPar
		TYPE(LocalVariables), INTENT(IN) :: LocalVar
			
			! Local
		REAL(4) :: RotorArea
		REAL(4) :: Cp
        REAL(4) :: Lambda
		
		RotorArea = PI*CntrPar%WE_BladeRadius**2
		Lambda = LocalVar%RotSpeed*CntrPar%WE_BladeRadius/LocalVar%WE_Vw
		Cp = CPfunction(CntrPar%WE_CP, Lambda)
		
		AeroDynTorque = 0.5*(CntrPar%WE_RhoAir*RotorArea)*(LocalVar%WE_Vw**3/LocalVar%RotSpeed)*Cp
		AeroDynTorque = MAX(AeroDynTorque, 0.0)
		
	END FUNCTION AeroDynTorque
	!-------------------------------------------------------------------------------------------------------------------------------
	SUBROUTINE WindSpeedEstimator(LocalVar, CntrPar)
		USE DRC_Types, ONLY : LocalVariables, ControlParameters
		IMPLICIT NONE
    
        ! Inputs
		TYPE(ControlParameters), INTENT(IN) :: CntrPar
		TYPE(LocalVariables), INTENT(INOUT) :: LocalVar	
		
        ! Body
        LocalVar%WE_VwIdot = CntrPar%WE_Gamma/CntrPar%WE_Jtot*(LocalVar%VS_LastGenTrq*CntrPar%WE_GearboxRatio - AeroDynTorque(LocalVar, CntrPar))
        
        LocalVar%WE_VwI = LocalVar%WE_VwI + LocalVar%WE_VwIdot*LocalVar%DT
        LocalVar%WE_Vw = LocalVar%WE_VwI + CntrPar%WE_Gamma*LocalVar%RotSpeed
        
	END SUBROUTINE WindSpeedEstimator
	!-------------------------------------------------------------------------------------------------------------------------------
END MODULE Functions
