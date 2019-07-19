MODULE Controllers

	USE, INTRINSIC	:: ISO_C_Binding
	USE Functions
	USE Filters
	
	IMPLICIT NONE
	
CONTAINS	
	SUBROUTINE PitchControl(avrSWAP, CntrPar, LocalVar, objInst)
	
		USE DRC_Types, ONLY : ControlParameters, LocalVariables, ObjectInstances
	   
	   ! Local Variables:	
		REAL(C_FLOAT), INTENT(INOUT)	:: avrSWAP(*)	! The swap array, used to pass data to, and receive data from the DLL controller.
		INTEGER(4)						:: K			! Index used for looping through blades.
		
		TYPE(ControlParameters), INTENT(INOUT)	:: CntrPar
		TYPE(LocalVariables),    INTENT(INOUT)	:: LocalVar
		TYPE(ObjectInstances),   INTENT(INOUT)	:: objInst
	
		!..............................................................................................................................
		! Pitch control
		!..............................................................................................................................
		! Set the pitch override to yes
		avrSWAP(55) = 0.0						! Pitch override: 0=yes
		
		IF (LocalVar%PC_State >= 1) THEN
			LocalVar%PC_MaxPitVar = CntrPar%PC_MaxPit
		ELSE
			LocalVar%PC_MaxPitVar = CntrPar%PC_FinePit
		END IF
		
		! Compute the gain scheduling correction factor based on the previously
		! commanded pitch angle for blade 1:
		LocalVar%PC_KP = interp1d(CntrPar%PC_GS_angles, CntrPar%PC_GS_KP, LocalVar%PC_PitComT)
		LocalVar%PC_KI = interp1d(CntrPar%PC_GS_angles, CntrPar%PC_GS_KI, LocalVar%PC_PitComT)
		LocalVar%PC_KD = interp1d(CntrPar%PC_GS_angles, CntrPar%PC_GS_KD, LocalVar%PC_PitComT)
		LocalVar%PC_TF = interp1d(CntrPar%PC_GS_angles, CntrPar%PC_GS_TF, LocalVar%PC_PitComT)
	
		! Compute the current speed error and its integral w.r.t. time; saturate the
		! integral term using the pitch angle limits:
		LocalVar%PC_SpdErr = CntrPar%PC_RefSpd - LocalVar%GenSpeedF					! Speed error
		LocalVar%PC_PwrErr = CntrPar%VS_RtPwr - LocalVar%VS_GenPwr					! Power error
		LocalVar%Y_MErr = LocalVar%Y_M + CntrPar%Y_MErrSet							! Yaw-alignment error
		
		! Compute the pitch commands associated with the proportional and integral
		! gains:
		IF (LocalVar%iStatus == 0) THEN
			LocalVar%PC_PitComT = PIController(LocalVar%PC_SpdErr, LocalVar%PC_KP, LocalVar%PC_KI, CntrPar%PC_FinePit, LocalVar%PC_MaxPitVar, LocalVar%DT, LocalVar%PitCom(1), .TRUE., objInst%instPI)
		ELSE
			LocalVar%PC_PitComT = PIController(LocalVar%PC_SpdErr, LocalVar%PC_KP, LocalVar%PC_KI, CntrPar%PC_FinePit, LocalVar%PC_MaxPitVar, LocalVar%DT, CntrPar%PC_FinePit, .FALSE., objInst%instPI)
		END IF
		
		! Individual pitch control
		IF ((CntrPar%IPC_ControlMode >= 1) .OR. (CntrPar%Y_ControlMode == 2)) THEN
			CALL IPC(CntrPar, LocalVar, objInst)
		ELSE
			LocalVar%IPC_PitComF = 0.0 ! THIS IS AN ARRAY!!
		END IF
        
        ! Fore-aft tower vibration damping control
        IF ((CntrPar%FA_KI > 0.0) .OR. (CntrPar%Y_ControlMode == 2)) THEN
            CALL ForeAftDamping(CntrPar, LocalVar, objInst)
        ELSE
            LocalVar%FA_PitCom = 0.0 ! THIS IS AN ARRAY!!
        END IF
	
		! Combine and saturate all pitch commands:
		DO K = 1,LocalVar%NumBl ! Loop through all blades, add IPC contribution and limit pitch rate
			! PitCom(K) = ratelimit(LocalVar%PC_PitComT_IPC(K), LocalVar%BlPitch(K), PC_MinRat, PC_MaxRat, LocalVar%DT)	! Saturate the overall command of blade K using the pitch rate limit
			LocalVar%PitCom(K) = saturate(LocalVar%PC_PitComT, CntrPar%PC_MinPit, CntrPar%PC_MaxPit)					! Saturate the overall command using the pitch angle limits
			LocalVar%PitCom(K) = LocalVar%PitCom(K) + LocalVar%IPC_PitComF(K) + LocalVar%FA_PitCom(K)
		END DO
		
		! Command the pitch demanded from the last
		! call to the controller (See Appendix A of Bladed User's Guide):
			avrSWAP(42) = LocalVar%PitCom(1)		! Use the command angles of all blades if using individual pitch
			avrSWAP(43) = LocalVar%PitCom(2)		! "
			avrSWAP(44) = LocalVar%PitCom(3)		! "
			avrSWAP(45) = LocalVar%PitCom(1)		! Use the command angle of blade 1 if using collective pitch

	END SUBROUTINE PitchControl
	
	SUBROUTINE VariableSpeedControl(avrSWAP, CntrPar, LocalVar, objInst)
	
		USE DRC_Types, ONLY : ControlParameters, LocalVariables, ObjectInstances
	
		REAL(C_FLOAT), INTENT(INOUT)				:: avrSWAP(*)	! The swap array, used to pass data to, and receive data from, the DLL controller.
	
		TYPE(ControlParameters), INTENT(INOUT)	:: CntrPar
		TYPE(LocalVariables), INTENT(INOUT)	:: LocalVar
		TYPE(ObjectInstances), INTENT(INOUT)	:: objInst
		
		!..............................................................................................................................
		! VARIABLE-SPEED TORQUE CONTROL:
		!..............................................................................................................................
		avrSWAP(35) = 1.0          ! Generator contactor status: 1=main (high speed) variable-speed generator
		avrSWAP(56) = 0.0          ! Torque override: 0=yes
		
		! Filter the HSS (generator) speed measurement:
		! Apply Low-Pass Filter (choice between first- and second-order low-pass filter)
		IF (CntrPar%F_FilterType == 1) THEN
            LocalVar%GenSpeedF = LPFilter(LocalVar%GenSpeed, LocalVar%DT, CntrPar%F_CornerFreq, LocalVar%iStatus, .FALSE., objInst%instLPF)
		ELSEIF (CntrPar%F_FilterType == 2) THEN   
            LocalVar%GenSpeedF = SecLPFilter(LocalVar%GenSpeed, LocalVar%DT, CntrPar%F_CornerFreq, CntrPar%F_Damping, LocalVar%iStatus, .FALSE., objInst%instSecLPF) ! Second-order low-pass filter on generator speed
        END IF
        
		! Compute the generator torque, which depends on which region we are in:
		LocalVar%VS_SpdErrAr = CntrPar%VS_RefSpd - LocalVar%GenSpeedF		! Current speed error - Above-rated PI-control
		LocalVar%VS_SpdErrBr = CntrPar%VS_MinOMSpd - LocalVar%GenSpeedF		! Current speed error - Below-rated PI-control
		IF (LocalVar%VS_State >= 4) THEN
			LocalVar%GenArTq = PIController(LocalVar%VS_SpdErrAr, CntrPar%VS_KP(1), CntrPar%VS_KI(1), CntrPar%VS_MaxOMTq, CntrPar%VS_ArSatTq, LocalVar%DT, CntrPar%VS_ArSatTq, .TRUE., objInst%instPI)
			LocalVar%GenBrTq = PIController(LocalVar%VS_SpdErrBr, CntrPar%VS_KP(1), CntrPar%VS_KI(1), CntrPar%VS_MinTq, CntrPar%VS_MinOMTq, LocalVar%DT, CntrPar%VS_MinOMTq, .TRUE., objInst%instPI)
			IF (LocalVar%VS_State == 4) THEN
				LocalVar%GenTq = CntrPar%VS_RtTq
			ELSEIF (LocalVar%VS_State == 5) THEN
				LocalVar%GenTq = (CntrPar%VS_RtPwr/CntrPar%VS_GenEff)/LocalVar%GenSpeedF
			END IF
		ELSE
			LocalVar%GenArTq = PIController(LocalVar%VS_SpdErrAr, CntrPar%VS_KP(1), CntrPar%VS_KI(1), CntrPar%VS_MaxOMTq, CntrPar%VS_ArSatTq, LocalVar%DT, CntrPar%VS_MaxOMTq, .FALSE., objInst%instPI)
			LocalVar%GenBrTq = PIController(LocalVar%VS_SpdErrBr, CntrPar%VS_KP(1), CntrPar%VS_KI(1), CntrPar%VS_MinTq, CntrPar%VS_MinOMTq, LocalVar%DT, CntrPar%VS_MinOMTq, .FALSE., objInst%instPI)
			IF (LocalVar%VS_State == 3) THEN
				LocalVar%GenTq = LocalVar%GenArTq
			ELSEIF (LocalVar%VS_State == 1) THEN
				LocalVar%GenTq = LocalVar%GenBrTq
			ELSEIF (LocalVar%VS_State == 2) THEN
				LocalVar%GenTq = CntrPar%VS_Rgn2K*LocalVar%GenSpeedF*LocalVar%GenSpeedF
			ELSE
				LocalVar%GenTq = CntrPar%VS_MaxOMTq
			END IF
		END IF
	
		! Saturate the commanded torque using the maximum torque limit:
		LocalVar%GenTq = MIN(LocalVar%GenTq, CntrPar%VS_MaxTq)						! Saturate the command using the maximum torque limit
	
		! Saturate the commanded torque using the torque rate limit:
		IF (LocalVar%iStatus == 0)  LocalVar%VS_LastGenTrq = LocalVar%GenTq				! Initialize the value of LocalVar%VS_LastGenTrq on the first pass only
		LocalVar%GenTq = ratelimit(LocalVar%GenTq, LocalVar%VS_LastGenTrq, -CntrPar%VS_MaxRat, CntrPar%VS_MaxRat, LocalVar%DT)	! Saturate the command using the torque rate limit
	
		! Reset the value of LocalVar%VS_LastGenTrq to the current values:
		LocalVar%VS_LastGenTrq = LocalVar%GenTq
	
		! Set the generator contactor status, avrSWAP(35), to main (high speed)
		! variable-speed generator, the torque override to yes, and command the
		! generator torque (See Appendix A of Bladed User's Guide):
		avrSWAP(47) = LocalVar%VS_LastGenTrq   ! Demanded generator torque
	END SUBROUTINE VariableSpeedControl
	
	SUBROUTINE YawRateControl(avrSWAP, CntrPar, LocalVar, objInst)
	
		USE DRC_Types, ONLY : ControlParameters, LocalVariables, ObjectInstances
	
		REAL(C_FLOAT), INTENT(INOUT)				:: avrSWAP(*)	! The swap array, used to pass data to, and receive data from, the DLL controller.
	
		TYPE(ControlParameters), INTENT(INOUT)	:: CntrPar
		TYPE(LocalVariables), INTENT(INOUT)	:: LocalVar
		TYPE(ObjectInstances), INTENT(INOUT)	:: objInst
		
		!..............................................................................................................................
		! Yaw control
		!..............................................................................................................................
		
		IF (CntrPar%Y_ControlMode == 1) THEN
			avrSWAP(29) = 0									! Yaw control parameter: 0 = yaw rate control
			IF (LocalVar%Time >= LocalVar%Y_YawEndT) THEN											! Check if the turbine is currently yawing
				avrSWAP(48) = 0.0													! Set yaw rate to zero
	
				LocalVar%Y_ErrLPFFast = LPFilter(LocalVar%Y_MErr, LocalVar%DT, CntrPar%Y_omegaLPFast, LocalVar%iStatus, .FALSE., objInst%instLPF)		! Fast low pass filtered yaw error with a frequency of 1
				LocalVar%Y_ErrLPFSlow = LPFilter(LocalVar%Y_MErr, LocalVar%DT, CntrPar%Y_omegaLPSlow, LocalVar%iStatus, .FALSE., objInst%instLPF)		! Slow low pass filtered yaw error with a frequency of 1/60
	
				LocalVar%Y_AccErr = LocalVar%Y_AccErr + LocalVar%DT*SIGN(LocalVar%Y_ErrLPFFast**2, LocalVar%Y_ErrLPFFast)	! Integral of the fast low pass filtered yaw error
	
				IF (ABS(LocalVar%Y_AccErr) >= CntrPar%Y_ErrThresh) THEN								! Check if accumulated error surpasses the threshold
					LocalVar%Y_YawEndT = ABS(LocalVar%Y_ErrLPFSlow/CntrPar%Y_Rate) + LocalVar%Time					! Yaw to compensate for the slow low pass filtered error
				END IF
			ELSE
				avrSWAP(48) = SIGN(CntrPar%Y_Rate, LocalVar%Y_MErr)		! Set yaw rate to predefined yaw rate, the sign of the error is copied to the rate
				LocalVar%Y_ErrLPFFast = LPFilter(LocalVar%Y_MErr, LocalVar%DT, CntrPar%Y_omegaLPFast, LocalVar%iStatus, .TRUE., objInst%instLPF)		! Fast low pass filtered yaw error with a frequency of 1
				LocalVar%Y_ErrLPFSlow = LPFilter(LocalVar%Y_MErr, LocalVar%DT, CntrPar%Y_omegaLPSlow, LocalVar%iStatus, .TRUE., objInst%instLPF)		! Slow low pass filtered yaw error with a frequency of 1/60
				LocalVar%Y_AccErr = 0.0								! "
			END IF
		END IF
	END SUBROUTINE YawRateControl
	
	SUBROUTINE IPC(CntrPar, LocalVar, objInst)
		!-------------------------------------------------------------------------------------------------------------------------------
		! Individual pitch control subroutine
		! Calculates the commanded pitch angles for IPC employed for blade fatigue load reductions at 1P and 2P
        !
		! Variable declaration and initialization
		!------------------------------------------------------------------------------------------------------------------------------
		USE DRC_Types, ONLY : ControlParameters, LocalVariables, ObjectInstances
		
		! Local variables
		REAL(4)					:: PitComIPC(3), PitComIPC_1P(3), PitComIPC_2P(3)
		INTEGER(4)				:: K								    ! Integer used to loop through turbine blades
		REAL(4)					:: axisTilt_1P, axisYaw_1P, axisYawF_1P ! Direct axis and quadrature axis outputted by Coleman transform, 1P
		REAL(4), SAVE			:: IntAxisTilt_1P, IntAxisYaw_1P		! Integral of the direct axis and quadrature axis, 1P
        REAL(4)					:: axisTilt_2P, axisYaw_2P, axisYawF_2P ! Direct axis and quadrature axis outputted by Coleman transform, 1P
		REAL(4), SAVE			:: IntAxisTilt_2P, IntAxisYaw_2P		! Integral of the direct axis and quadrature axis, 1P
		REAL(4)					:: IntAxisYawIPC_1P					    ! IPC contribution with yaw-by-IPC component
		REAL(4)					:: Y_MErrF, Y_MErrF_IPC				    ! Unfiltered and filtered yaw alignment error [rad]
	
		TYPE(ControlParameters), INTENT(INOUT)	:: CntrPar
		TYPE(LocalVariables), INTENT(INOUT)		:: LocalVar
		TYPE(ObjectInstances), INTENT(INOUT)	:: objInst
		
		! Body
		! Initialization
			! Set integrals to be 0 in the first time step
		IF (LocalVar%iStatus==0) THEN
			IntAxisTilt_1P = 0.0
			IntAxisYaw_1P = 0.0
            IntAxisTilt_2P = 0.0
			IntAxisYaw_2P = 0.0
		END IF

		! Pass rootMOOPs through the Coleman transform to get the tilt and yaw moment axis
		CALL ColemanTransform(LocalVar%rootMOOP, LocalVar%Azimuth, NP_1, axisTilt_1P, axisYaw_1P)
        CALL ColemanTransform(LocalVar%rootMOOP, LocalVar%Azimuth, NP_2, axisTilt_2P, axisYaw_2P)
	
		! High-pass filter the MBC yaw component and filter yaw alignment error, and compute the yaw-by-IPC contribution
		IF (CntrPar%Y_ControlMode == 2) THEN
			Y_MErrF = SecLPFilter(LocalVar%Y_MErr, LocalVar%DT, CntrPar%Y_IPC_omegaLP, CntrPar%Y_IPC_zetaLP, LocalVar%iStatus, .FALSE., objInst%instSecLPF)
			Y_MErrF_IPC = PIController(Y_MErrF, CntrPar%Y_IPC_KP(1), CntrPar%Y_IPC_KI(1), -CntrPar%Y_IPC_IntSat, CntrPar%Y_IPC_IntSat, LocalVar%DT, 0.0, .FALSE., objInst%instPI)
		ELSE
			axisYawF_1P = axisYaw_1P
			Y_MErrF = 0.0
			Y_MErrF_IPC = 0.0
		END IF
		
		! Integrate the signal and multiply with the IPC gain
		IF ((CntrPar%IPC_ControlMode >= 1) .AND. (CntrPar%Y_ControlMode /= 2)) THEN
			IntAxisTilt_1P	= IntAxisTilt_1P + LocalVar%DT * CntrPar%IPC_KI(1) * axisTilt_1P
			IntAxisYaw_1P = IntAxisYaw_1P + LocalVar%DT * CntrPar%IPC_KI(1) * axisYawF_1P
			IntAxisTilt_1P = saturate(IntAxisTilt_1P, -CntrPar%IPC_IntSat, CntrPar%IPC_IntSat)
			IntAxisYaw_1P = saturate(IntAxisYaw_1P, -CntrPar%IPC_IntSat, CntrPar%IPC_IntSat)
            
            IF (CntrPar%IPC_ControlMode >= 2) THEN
                IntAxisTilt_2P	= IntAxisTilt_2P + LocalVar%DT * CntrPar%IPC_KI(2) * axisTilt_2P
			    IntAxisYaw_2P = IntAxisYaw_2P + LocalVar%DT * CntrPar%IPC_KI(2) * axisYawF_2P
			    IntAxisTilt_2P = saturate(IntAxisTilt_2P, -CntrPar%IPC_IntSat, CntrPar%IPC_IntSat)
			    IntAxisYaw_2P = saturate(IntAxisYaw_2P, -CntrPar%IPC_IntSat, CntrPar%IPC_IntSat)
            END IF
		ELSE
			IntAxisTilt_1P = 0.0
			IntAxisYaw_1P = 0.0
            IntAxisTilt_2P = 0.0
			IntAxisYaw_2P = 0.0
		END IF
		
		! Add the yaw-by-IPC contribution
		IntAxisYawIPC_1P = IntAxisYaw_1P + Y_MErrF_IPC
	
		! Pass direct and quadrature axis through the inverse Coleman transform to get the commanded pitch angles
		CALL ColemanTransformInverse(IntAxisTilt_1P, IntAxisYawIPC_1P, LocalVar%Azimuth, NP_1, CntrPar%IPC_aziOffset(1), PitComIPC_1P)
        CALL ColemanTransformInverse(IntAxisTilt_2P, IntAxisYaw_2P, LocalVar%Azimuth, NP_2, CntrPar%IPC_aziOffset(2), PitComIPC_2P)
        
		! Sum nP IPC contrubutions and store to LocalVar data type
		DO K = 1,LocalVar%NumBl
            PitComIPC(K) = PitComIPC_1P(K) + PitComIPC_2P(K)
			LocalVar%IPC_PitComF(K) = PitComIPC(K)
		END DO
	END SUBROUTINE IPC
    
    SUBROUTINE ForeAftDamping(CntrPar, LocalVar, objInst)
		!-------------------------------------------------------------------------------------------------------------------------------
		! Fore-aft damping controller, reducing the tower fore-aft vibrations using pitch
		!
		! Variable declaration and initialization
		!------------------------------------------------------------------------------------------------------------------------------
		USE DRC_Types, ONLY : ControlParameters, LocalVariables, ObjectInstances
		
		! Local variables
		INTEGER(4)				:: K								    ! Integer used to loop through turbine blades
	
		TYPE(ControlParameters), INTENT(INOUT)	:: CntrPar
		TYPE(LocalVariables), INTENT(INOUT)		:: LocalVar
		TYPE(ObjectInstances), INTENT(INOUT)	:: objInst
        
		! Body
		LocalVar%FA_AccHPF = HPFilter( LocalVar%FA_Acc, LocalVar%DT, CntrPar%FA_HPF_CornerFreq, LocalVar%iStatus, .FALSE., objInst%instHPF )
        LocalVar%FA_AccHPFI = PIController(LocalVar%FA_AccHPF, 0.0, CntrPar%FA_KI, -CntrPar%FA_IntSat, CntrPar%FA_IntSat, LocalVar%DT, 0.0, .FALSE., objInst%instPI)
        
        ! Store the fore-aft pitch contribution to LocalVar data type
		DO K = 1,LocalVar%NumBl
			LocalVar%FA_PitCom(K) = LocalVar%FA_AccHPFI
		END DO
        
    END SUBROUTINE ForeAftDamping
END MODULE Controllers