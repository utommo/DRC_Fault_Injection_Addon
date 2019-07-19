MODULE FDI

    USE, INTRINSIC	:: ISO_C_Binding
    
    IMPLICIT NONE

CONTAINS
    ! Thomas: Function which reads all the parameters from the FAULTS.IN file
	SUBROUTINE ReadFaultParameterFile(FaultPar)
		USE Fault_Types, ONLY : FaultParameters

		INTEGER(4), PARAMETER :: NoFaultParameters = 100
		TYPE(FaultParameters), INTENT(INOUT) :: FaultPar

		OPEN(unit=NoFaultParameters, file='FAULTS.IN', status='old', action='read')
		READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
        READ(NoFaultParameters,*) FaultPar%EnableAll
        READ(NoFaultParameters,*) FaultPar%FDI_Log
		READ(NoFaultParameters,*) FaultPar%F_BL1Type
		READ(NoFaultParameters,*) FaultPar%F_BL2Type
        READ(NoFaultParameters,*) FaultPar%F_BL3Type
        READ(NoFaultParameters,*) FaultPar%F_BP1Type
		READ(NoFaultParameters,*) FaultPar%F_BP2Type
        READ(NoFaultParameters,*) FaultPar%F_BP3Type
        READ(NoFaultParameters,*) FaultPar%F_OGType
        READ(NoFaultParameters,*) FaultPar%F_ORType
        READ(NoFaultParameters,*) FaultPar%F_AzType
		READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
		! Settings for blade load sensor 1 (blade 1)
		READ(NoFaultParameters,*) FaultPar%F_BL1Stime
		READ(NoFaultParameters,*) FaultPar%F_BL1Etime
		READ(NoFaultParameters,*) FaultPar%F_BL1Add
		READ(NoFaultParameters,*) FaultPar%F_BL1Mul
		READ(NoFaultParameters,*) FaultPar%F_BL1Drift
		READ(NoFaultParameters,*) FaultPar%F_BL1Cons
		READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN 
		!Settings for blade load sensor 2 (blade 2)
		READ(NoFaultParameters,*) FaultPar%F_BL2Stime
		READ(NoFaultParameters,*) FaultPar%F_BL2Etime
		READ(NoFaultParameters,*) FaultPar%F_BL2Add
		READ(NoFaultParameters,*) FaultPar%F_BL2Mul
		READ(NoFaultParameters,*) FaultPar%F_BL2Drift
		READ(NoFaultParameters,*) FaultPar%F_BL2Cons
		READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
		! Settings for blade load sensor 3 (blade 3)
		READ(NoFaultParameters,*) FaultPar%F_BL3Stime
		READ(NoFaultParameters,*) FaultPar%F_BL3Etime
		READ(NoFaultParameters,*) FaultPar%F_BL3Add
		READ(NoFaultParameters,*) FaultPar%F_BL3Mul
		READ(NoFaultParameters,*) FaultPar%F_BL3Drift
		READ(NoFaultParameters,*) FaultPar%F_BL3Cons
		READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
		! Settings for blade load sensor 3 (blade 3)
		READ(NoFaultParameters,*) FaultPar%F_BP1Stime
		READ(NoFaultParameters,*) FaultPar%F_BP1Etime
		READ(NoFaultParameters,*) FaultPar%F_BP1Add
		READ(NoFaultParameters,*) FaultPar%F_BP1Mul
		READ(NoFaultParameters,*) FaultPar%F_BP1Drift
        READ(NoFaultParameters,*) FaultPar%F_BP1Cons
        READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
		! Settings for blade load sensor 3 (blade 3)
		READ(NoFaultParameters,*) FaultPar%F_BP2Stime
		READ(NoFaultParameters,*) FaultPar%F_BP2Etime
		READ(NoFaultParameters,*) FaultPar%F_BP2Add
		READ(NoFaultParameters,*) FaultPar%F_BP2Mul
		READ(NoFaultParameters,*) FaultPar%F_BP2Drift
        READ(NoFaultParameters,*) FaultPar%F_BP2Cons
        READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
		! Settings for blade load sensor 3 (blade 3)
		READ(NoFaultParameters,*) FaultPar%F_BP3Stime
		READ(NoFaultParameters,*) FaultPar%F_BP3Etime
		READ(NoFaultParameters,*) FaultPar%F_BP3Add
		READ(NoFaultParameters,*) FaultPar%F_BP3Mul
		READ(NoFaultParameters,*) FaultPar%F_BP3Drift
        READ(NoFaultParameters,*) FaultPar%F_BP3Cons		
        READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
        ! Rotor Speed Sensor Faults
        READ(NoFaultParameters,*) FaultPar%F_ORStime
        READ(NoFaultParameters,*) FaultPar%F_OREtime
        READ(NoFaultParameters,*) FaultPar%F_ORAdd
        READ(NoFaultParameters,*) FaultPar%F_ORMul
        READ(NoFaultParameters,*) FaultPar%F_ORDrift
        READ(NoFaultParameters,*) FaultPar%F_ORCons
        READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
        ! Generator Speed Sensor Faults
        READ(NoFaultParameters,*) FaultPar%F_OGStime
        READ(NoFaultParameters,*) FaultPar%F_OGEtime
        READ(NoFaultParameters,*) FaultPar%F_OGAdd
        READ(NoFaultParameters,*) FaultPar%F_OGMul
        READ(NoFaultParameters,*) FaultPar%F_OGDrift
        READ(NoFaultParameters,*) FaultPar%F_OGCons
        READ(NoFaultParameters,*)						!Skipping the "info" line in the FAULTS.IN
        ! Azimuth Angle Sensor Fault
        READ(NoFaultParameters,*) FaultPar%F_AzStime
        READ(NoFaultParameters,*) FaultPar%F_AzEtime
        READ(NoFaultParameters,*) FaultPar%F_AzAdd
        READ(NoFaultParameters,*) FaultPar%F_AzMul
        READ(NoFaultParameters,*) FaultPar%F_AzDrift
        READ(NoFaultParameters,*) FaultPar%F_AzCons

		CLOSE(NoFaultParameters)
    END SUBROUTINE ReadFaultParameterFile
    
    SUBROUTINE FaultInjection(LocalVar, FaultPar, FaultVar)
        USE DRC_Types,   ONLY : LocalVariables
        USE Fault_Types, ONLY : FaultParameters, FaultVariables ! Thomas: Added FaultParameters
	   
		TYPE(FaultParameters), INTENT(INOUT)	:: FaultPar		! Thomas
		TYPE(FaultVariables),  INTENT(INOUT)	:: FaultVar		! Thomas
		TYPE(LocalVariables),  INTENT(INOUT)	:: LocalVar
        
        ! Thomas: Modifying the measurement by some value (Possible way of introducing the fault at time t) Tags: fault, faults
		!	LocalVar%rootMOOP(1)
		!	LocalVar%rootMOOP(2)
		!	LocalVar%rootMOOP(3)
		!	LocalVar%time
        !
        !   LocalVar%GenSpeed
        !   LocalVar%RotSpeed
        !   LocalVar%GenTqMeas
        !   LocalVar%BlPitch(1)
        !   LocalVar%BlPitch(2)
        !   LocalVar%BlPitch(3)
        !   LocalVar%Azimuth
        !
		!	FaultPar are the values found within FAULTS.IN
        !	FaultVar are interval variablesb (for the fault system)        

        IF(FaultPar%F_BL1Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BL1Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BL1Type == 1) THEN
                LocalVar%rootMOOP(1) = LocalVar%rootMOOP(1) + FaultPar%F_BL1Add
            END IF

            IF(FaultPar%F_BL1Type == 2) THEN
                LocalVar%rootMOOP(1) = LocalVar%rootMOOP(1)*FaultPar%F_BL1Mul
            END IF

            IF(FaultPar%F_BL1Type == 3) THEN
                FaultVar%F_BL1drift = FaultVar%F_BL1drift + FaultPar%F_BL1Drift*LocalVar%rootMOOP(1)
                LocalVar%rootMOOP(1) = LocalVar%rootMOOP(1) + FaultVar%F_BL1drift
            END IF

            IF(FaultPar%F_BL1Type == 4) THEN
                LocalVar%rootMOOP(1) = FaultPar%F_BL1Cons
            END IF
        END IF
        !Fault BL 2
        IF(FaultPar%F_BL2Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BL2Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BL2Type == 1) THEN
                LocalVar%rootMOOP(2) = LocalVar%rootMOOP(2) + FaultPar%F_BL2Add
            END IF

            IF(FaultPar%F_BL2Type == 2) THEN
                LocalVar%rootMOOP(2) = LocalVar%rootMOOP(2)*FaultPar%F_BL2Mul
            END IF

            IF(FaultPar%F_BL2Type == 3) THEN
                FaultVar%F_BL2drift = FaultVar%F_BL2drift + FaultPar%F_BL2Drift*LocalVar%rootMOOP(2)
                LocalVar%rootMOOP(2) = LocalVar%rootMOOP(2) + FaultVar%F_BL2drift
            END IF

            IF(FaultPar%F_BL2Type == 4) THEN
                LocalVar%rootMOOP(2) = FaultPar%F_BL2Cons
            END IF
        END IF
        !Fault BL3
        IF(FaultPar%F_BL3Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BL3Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BL3Type == 1) THEN
                LocalVar%rootMOOP(3) = LocalVar%rootMOOP(3) + FaultPar%F_BL3Add
            END IF

            IF(FaultPar%F_BL3Type == 2) THEN
                LocalVar%rootMOOP(3) = LocalVar%rootMOOP(3)*FaultPar%F_BL3Mul
            END IF

            IF(FaultPar%F_BL3Type == 3) THEN
                FaultVar%F_BL3drift = FaultVar%F_BL3drift + FaultPar%F_BL3Drift*LocalVar%rootMOOP(3)
                LocalVar%rootMOOP(3) = LocalVar%rootMOOP(3) + FaultVar%F_BL3drift
            END IF

            IF(FaultPar%F_BL3Type == 4) THEN
                LocalVar%rootMOOP(3) = FaultPar%F_BL3Cons
            END IF
        END IF
        !Fault BP1
        IF(FaultPar%F_BP1Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BP1Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BP1Type == 1) THEN
                LocalVar%BlPitch(1) = LocalVar%BlPitch(1) + FaultPar%F_BP1Add
            END IF

            IF(FaultPar%F_BP1Type == 2) THEN
                LocalVar%BlPitch(1) = LocalVar%BlPitch(1)*FaultPar%F_BP1Mul
            END IF

            IF(FaultPar%F_BP1Type == 3) THEN
                FaultVar%F_BP1drift = FaultVar%F_BP1drift + FaultPar%F_BP1Drift*LocalVar%BlPitch(1)
                LocalVar%BlPitch(1) = LocalVar%BlPitch(1) + FaultVar%F_BP1drift
            END IF

            IF(FaultPar%F_BP1Type == 4) THEN
                LocalVar%BlPitch(1) = FaultPar%F_BP1Cons
            END IF
        END IF
        !Fault BP2
        IF(FaultPar%F_BP2Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BP2Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BP2Type == 1) THEN
                LocalVar%BlPitch(2) = LocalVar%BlPitch(2) + FaultPar%F_BP2Add
            END IF

            IF(FaultPar%F_BP2Type == 2) THEN
                LocalVar%BlPitch(2) = LocalVar%BlPitch(2)*FaultPar%F_BP2Mul
            END IF

            IF(FaultPar%F_BP2Type == 3) THEN
                FaultVar%F_BP2drift = FaultVar%F_BP2drift + FaultPar%F_BP2Drift*LocalVar%BlPitch(2)
                LocalVar%BlPitch(2) = LocalVar%BlPitch(2) + FaultVar%F_BP2drift
            END IF

            IF(FaultPar%F_BP2Type == 4) THEN
                LocalVar%BlPitch(2) = FaultPar%F_BP2Cons
            END IF
        END IF
        !Fault BP3
        IF(FaultPar%F_BP3Stime < LocalVar%time .and. LocalVar%time < FaultPar%F_BP3Etime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_BP3Type == 1) THEN
                LocalVar%BlPitch(3) = LocalVar%BlPitch(3) + FaultPar%F_BP3Add
            END IF

            IF(FaultPar%F_BP3Type == 2) THEN
                LocalVar%BlPitch(3) = LocalVar%BlPitch(3)*FaultPar%F_BP3Mul
            END IF

            IF(FaultPar%F_BP3Type == 3) THEN
                FaultVar%F_BP3drift = FaultVar%F_BP3drift + FaultPar%F_BP3Drift*LocalVar%BlPitch(3)
                LocalVar%BlPitch(3) = LocalVar%BlPitch(3) + FaultVar%F_BP3drift
            END IF

            IF(FaultPar%F_BP3Type == 4) THEN
                LocalVar%BlPitch(3) = FaultPar%F_BP3Cons
            END IF
        END IF
        !Fault OR
        IF(FaultPar%F_ORStime < LocalVar%time .and. LocalVar%time < FaultPar%F_OREtime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_ORType == 1) THEN
                LocalVar%RotSpeed = LocalVar%RotSpeed + FaultPar%F_ORAdd
            END IF

            IF(FaultPar%F_ORType == 2) THEN
                LocalVar%RotSpeed = LocalVar%RotSpeed*FaultPar%F_ORMul
            END IF

            IF(FaultPar%F_ORType == 3) THEN
                FaultVar%F_ORdrift = FaultVar%F_ORdrift + FaultPar%F_ORDrift*LocalVar%RotSpeed
                LocalVar%RotSpeed = LocalVar%RotSpeed + FaultVar%F_ORdrift
            END IF

            IF(FaultPar%F_ORType == 4) THEN
                LocalVar%RotSpeed = FaultPar%F_ORCons
            END IF
        END IF
        !Fault OG
        IF(FaultPar%F_OGStime < LocalVar%time .and. LocalVar%time < FaultPar%F_OGEtime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_OGType == 1) THEN
                LocalVar%GenSpeed = LocalVar%GenSpeed + FaultPar%F_OGAdd
            END IF

            IF(FaultPar%F_OGType == 2) THEN
                LocalVar%GenSpeed = LocalVar%GenSpeed*FaultPar%F_OGMul
            END IF

            IF(FaultPar%F_OGType == 3) THEN
                FaultVar%F_OGdrift = FaultVar%F_OGdrift + FaultPar%F_OGDrift*LocalVar%GenSpeed
                LocalVar%GenSpeed = LocalVar%GenSpeed + FaultVar%F_OGdrift
            END IF

            IF(FaultPar%F_OGType == 4) THEN
                LocalVar%GenSpeed = FaultPar%F_OGCons
            END IF
        END IF
        !Fault Azimuth
        IF(FaultPar%F_AzStime < LocalVar%time .and. LocalVar%time < FaultPar%F_AzEtime .and. FaultPar%EnableAll == 1) THEN
            IF(FaultPar%F_AzType == 1) THEN
                LocalVar%Azimuth = LocalVar%Azimuth + FaultPar%F_AzAdd
            END IF

            IF(FaultPar%F_AzType == 2) THEN
                LocalVar%Azimuth = LocalVar%Azimuth*FaultPar%F_AzMul
            END IF

            IF(FaultPar%F_AzType == 3) THEN
                FaultVar%F_Azdrift = FaultVar%F_Azdrift + FaultPar%F_AzDrift*LocalVar%Azimuth
                LocalVar%Azimuth = LocalVar%Azimuth + FaultVar%F_Azdrift
            END IF

            IF(FaultPar%F_AzType == 4) THEN
                LocalVar%Azimuth = FaultPar%F_AzCons
            END IF
        END IF
    END SUBROUTINE FaultInjection
    
    SUBROUTINE FDIDebug(LocalVar, CntrPar, FaultVar, FaultPar)
		USE, INTRINSIC	:: ISO_C_Binding
        USE DRC_Types, ONLY : LocalVariables, ControlParameters
        USE Fault_Types, ONLY : FaultParameters, FaultVariables ! Thomas: Added FaultParameters
		
		IMPLICIT NONE
	
		TYPE(ControlParameters), INTENT(IN)		:: CntrPar
        TYPE(LocalVariables), INTENT(IN)		:: LocalVar
        TYPE(FaultParameters), INTENT(INOUT)	:: FaultPar		! Thomas
		TYPE(FaultVariables),  INTENT(INOUT)	:: FaultVar		! Thomas
	
		CHARACTER(1), PARAMETER						:: Tab = CHAR(9)						! The tab character.
		CHARACTER(25), PARAMETER					:: FmtDat = "(F8.3,99('"//Tab//"',ES10.3E2,:))	"	! The format of the debugging data
        
		IF (LocalVar%iStatus == 0)  THEN  ! .TRUE. if we're on the first call to the DLL
			IF (FaultPar%FDI_Log == 1) THEN
				OPEN(unit=110, FILE='FDIDEBUG.dbg')
				WRITE (110,'(A)')	'Time'//Tab//'PtchC1'//Tab//'PtchC2'//Tab//'PtchC3'//Tab//'rootMOOP1'//Tab//'rootMOOP2'//Tab//'rootMOOP3'//Tab//'RotSpeed'//Tab//'GenSpeed'//Tab//'Azimuth'
				!               	 Time (sec),  PtchC1 (rad),  PtchC2 (rad),  PtchC3 (rad),  rootMOOP1 (Nm),   rootMOOP2 (Nm),   rootMOOP3 (Nm), RotSpeed rad/s, GenSpeed rad/s, Azimuth deg
			END IF
		ELSE
			IF (FaultPar%FDI_Log == 1) THEN
				WRITE (110,FmtDat)		LocalVar%Time, LocalVar%BlPitch, LocalVar%rootMOOP, LocalVar%RotSpeed, LocalVar%GenSpeed, LocalVar%Azimuth
			END IF
		END IF

	END SUBROUTINE FDIDebug

END MODULE FDI