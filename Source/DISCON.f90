!=======================================================================
! SUBROUTINE DISCON(avrSWAP, from_SC, to_SC, aviFAIL, accINFILE, avcOUTNAME, avcMSG) BIND (C, NAME='DISCON')
SUBROUTINE DISCON(avrSWAP, aviFAIL, accINFILE, avcOUTNAME, avcMSG) BIND (C, NAME='DISCON')
! DO NOT REMOVE or MODIFY LINES starting with "!DEC$" or "!GCC$"
! !DEC$ specifies attributes for IVF and !GCC$ specifies attributes for gfortran
!DEC$ ATTRIBUTES DLLEXPORT :: DISCON

USE, INTRINSIC	:: ISO_C_Binding
USE				:: DRC_Types
USE				:: ReadSetParameters
USE				:: Controllers
USE             :: Constants

! Thomas: Fault Diagnosis/Injection Add-on
USE				:: FDI			!Thomas
USE 			:: Fault_Types  !Thomas

IMPLICIT NONE
#ifndef IMPLICIT_DLLEXPORT
!GCC$ ATTRIBUTES DLLEXPORT :: DISCON
#endif

!------------------------------------------------------------------------------------------------------------------------------
! Variable declaration and initialization
!------------------------------------------------------------------------------------------------------------------------------

! Passed Variables:
!REAL(C_FLOAT), INTENT(IN)		:: from_SC(*)			! DATA from the supercontroller
!REAL(C_FLOAT), INTENT(INOUT)	:: to_SC(*)				! DATA to the supercontroller

REAL(C_FLOAT), INTENT(INOUT)			:: avrSWAP(*)						! The swap array, used to pass data to, and receive data from, the DLL controller.
INTEGER(C_INT), INTENT(INOUT)			:: aviFAIL							! A flag used to indicate the success of this DLL call set as follows: 0 if the DLL call was successful, >0 if the DLL call was successful but cMessage should be issued as a warning messsage, <0 if the DLL call was unsuccessful or for any other reason the simulation is to be stopped at this point with cMessage as the error message.
CHARACTER(KIND=C_CHAR), INTENT(IN)		:: accINFILE(NINT(avrSWAP(50)))		! The name of the parameter input file
CHARACTER(KIND=C_CHAR), INTENT(IN)		:: avcOUTNAME(NINT(avrSWAP(51)))	! OUTNAME (Simulation RootName)
CHARACTER(KIND=C_CHAR), INTENT(INOUT)	:: avcMSG(NINT(avrSWAP(49)))		! MESSAGE (Message from DLL to simulation code [ErrMsg])  The message which will be displayed by the calling program if aviFAIL <> 0.
CHARACTER(SIZE(avcOUTNAME)-1)			:: RootName							! a Fortran version of the input C string (not considered an array here)    [subtract 1 for the C null-character]
CHARACTER(SIZE(avcMSG)-1)				:: ErrMsg							! a Fortran version of the C string argument (not considered an array here) [subtract 1 for the C null-character]

TYPE(ControlParameters), SAVE			:: CntrPar
TYPE(LocalVariables), SAVE				:: LocalVar
TYPE(ObjectInstances), SAVE				:: objInst

! Thomas: Fault Diagnosis/Injection Add-on
TYPE(FaultParameters),SAVE				:: FaultPar							! Thomas: Setting up the FaultParameters in FaultPar
TYPE(FaultVariables),SAVE				:: FaultVar							! Thomas: Setting up the FaultParameters in FaultPar

!------------------------------------------------------------------------------------------------------------------------------
! Main control calculations
!------------------------------------------------------------------------------------------------------------------------------
! Read avrSWAP array into derived types/variables
CALL ReadAvrSWAP(avrSWAP, LocalVar)
CALL SetParameters(avrSWAP, aviFAIL, ErrMsg, SIZE(avcMSG), CntrPar, LocalVar, objInst)

! Thomas: Fault Diagnosis/Injection Add-on
! Start
CALL ReadFaultParameterFile(FaultPar)
CALL FaultInjection(LocalVar, FaultPar, FaultVar)
! End

IF ((LocalVar%iStatus >= 0) .AND. (aviFAIL >= 0))  THEN  ! Only compute control calculations if no error has occurred and we are not on the last time step
	CALL StateMachine(CntrPar, LocalVar)
    CALL WindSpeedEstimator(LocalVar, CntrPar)
	CALL VariableSpeedControl(avrSWAP, CntrPar, LocalVar, objInst)
	CALL PitchControl(avrSWAP, CntrPar, LocalVar, objInst)
	CALL YawRateControl(avrSWAP, CntrPar, LocalVar, objInst)

	CALL Debug(LocalVar, CntrPar, avrSWAP, RootName, SIZE(avcOUTNAME))
	!Thomas
	CALL FDIDebug(LocalVar, CntrPar, FaultVar, FaultPar)
END IF

avcMSG = TRANSFER(TRIM(ErrMsg)//C_NULL_CHAR, avcMSG, SIZE(avcMSG))
RETURN
END SUBROUTINE DISCON
