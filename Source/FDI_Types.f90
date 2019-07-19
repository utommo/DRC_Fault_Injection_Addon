MODULE Fault_Types

IMPLICIT NONE

! Thomas: Adding a container for all the variables related to the fault add-on
TYPE, PUBLIC :: FaultParameters
	! Settings parameters for the faults
    REAL(4)								:: EnableAll
    REAL(4)                             :: FDI_Log
	REAL(4)								:: F_BL1Type
	REAL(4)								:: F_BL2Type
	REAL(4)								:: F_BL3Type
	REAL(4)								:: F_BP1Type
	REAL(4)								:: F_BP2Type
	REAL(4)								:: F_BP3Type
	REAL(4)								:: F_OGType
	REAL(4)								:: F_ORType
	REAL(4)								:: F_AzType
	! BLRBM 1 fault parameters
	REAL(4)								:: F_BL1Stime
	REAL(4)								:: F_BL1Etime
	REAL(4)								:: F_BL1Add
	REAL(4)								:: F_BL1Mul
	REAL(4)								:: F_BL1Drift
	REAL(4)								:: F_BL1Cons
	! BLRBM 2 fault parameters
	REAL(4)								:: F_BL2Stime
	REAL(4)								:: F_BL2Etime
	REAL(4)								:: F_BL2Add
	REAL(4)								:: F_BL2Mul
	REAL(4)								:: F_BL2Drift
	REAL(4)								:: F_BL2Cons
	! BLRBM 3 fault parameters
	REAL(4)								:: F_BL3Stime
	REAL(4)								:: F_BL3Etime
	REAL(4)								:: F_BL3Add
	REAL(4)								:: F_BL3Mul
	REAL(4)								:: F_BL3Drift
	REAL(4)								:: F_BL3Cons
	! Blade 1 Pitch Sensor Faults
	REAL(4)								:: F_BP1Stime
	REAL(4)								:: F_BP1Etime
	REAL(4)								:: F_BP1Add
	REAL(4)								:: F_BP1Mul
	REAL(4)								:: F_BP1Drift
	REAL(4)								:: F_BP1Cons
	! Blade 2 Pitch Sensor Faults
	REAL(4)								:: F_BP2Stime
	REAL(4)								:: F_BP2Etime
	REAL(4)								:: F_BP2Add
	REAL(4)								:: F_BP2Mul
	REAL(4)								:: F_BP2Drift
	REAL(4)								:: F_BP2Cons
	! Blade 3 Pitch Sensor Faults
	REAL(4)								:: F_BP3Stime
	REAL(4)								:: F_BP3Etime
	REAL(4)								:: F_BP3Add
	REAL(4)								:: F_BP3Mul
	REAL(4)								:: F_BP3Drift
	REAL(4)								:: F_BP3Cons
	! Rotor Speed Sensor Faults
	REAL(4)								:: F_ORStime
	REAL(4)								:: F_OREtime
	REAL(4)								:: F_ORAdd
	REAL(4)								:: F_ORMul
	REAL(4)								:: F_ORDrift
	REAL(4)								:: F_ORCons
	! Generator Speed Sensor Faults
	REAL(4)								:: F_OGStime
	REAL(4)								:: F_OGEtime
	REAL(4)								:: F_OGAdd
	REAL(4)								:: F_OGMul
	REAL(4)								:: F_OGDrift
	REAL(4)								:: F_OGCons
	! Azimuth Angle Sensor Fault
	REAL(4)								:: F_AzStime
	REAL(4)								:: F_AzEtime
	REAL(4)								:: F_AzAdd
	REAL(4)								:: F_AzMul
	REAL(4)								:: F_AzDrift
	REAL(4)								:: F_AzCons
	
END TYPE FaultParameters

TYPE, PUBLIC :: FaultVariables
	REAL(4)								:: drift						! Thomas: drift for a fault
	REAL(4)								:: F_BL1Drift
	REAL(4)								:: F_BL2Drift
	REAL(4)								:: F_BL3Drift
	REAL(4)								:: F_BP1Drift
	REAL(4)								:: F_BP2Drift
	REAL(4)								:: F_BP3Drift
	REAL(4)								:: F_ORDrift
	REAL(4)								:: F_AzDrift
	REAL(4)								:: F_OGDrift
	REAL(4)								:: CPC_Angle
END TYPE FaultVariables

END MODULE Fault_Types