# DRC_Fault_Injection_Addon 
The above is an extension to the Open Source Controller developed by TU-Delft (https://github.com/TUDelft-DataDrivenControl/DRC_Fortran)




The extension is able to inject faults to the following sensors: Rotor speed, Generator Speed, Azimuth angle, i-th pitch angle and i-th blade load sensor.

Each fault can take the form of the following types: An additive fault, multiplicative fault, drift or constant value.

The current implementation is sub-optimal, however, it sufficiently injects the desired faults into the control loop.
Optimizations may be made down the line. A more efficient implementation could be written by abstracting the injection into a function, where structs containing a given fault's information could be passed to it.

The two main components of the extension is the `FDI.f90` and the `FDI_Types.f90`. Where the former is responsible for reading the `FAULTS.in` file and injecting the faults based on the specified parameters.

If the main DRC is updated, the fault injection extension can be integrated simply by adding the following two lines to the `DISCON.f90`:
~~~~
CALL ReadFaultParameterFile(FaultPar)
CALL FaultInjection(LocalVar, FaultPar, FaultVar)
~~~~
Between the `SetParameters(...)` and `CALL StateMachine(...)` function calls.

The Fault Injection Extension was created for use during my MSc thesis, due needing an IPC with fault injection capabilities to use with FAST.
Thanks to S.P Mulders for the guidance regarding the modification, and also for the developing the main controller in the first place.

Below is some information from the main DRC repository. Please remember to cite his paper if used for a publication.

# Information from the ReadMe (from the orignal repository)

### DRC_Fortran wind turbine baseline controller
The Delft Research Controller (DRC) baseline wind turbine controller, uses the Bladed-style DISCON interface used by, e.g., OpenFAST, Bladed (versions 4.5 or earlier) and HAWC2.

### Introduction
The Delft Research Controller (DRC) provides an open, modular and fully adaptable baseline wind turbine controller to the scientific community. New control implementations can be added to the existing baseline controller, and in this way, convenient assessments of the proposed algorithms is possible. Because of the open character and modular set-up, scientists are able to collaborate and contribute in making continuous improvements to the code. The DRC is being developed in Fortran and uses the Bladed-style DISCON controller interface. The compiled controller is configured by a single control settings parameter file, and can work with any wind turbine model and simulation software using the DISCON interface. Baseline parameter files are supplied for the NREL 5-MW and DTU 10-MW reference wind turbines.

### Referencing
When you use the DRC in any publication, please cite the following paper:
* Mulders, S.P. and van Wingerden, J.W. "Delft Research Controller: an open-source and community-driven wind turbine baseline controller." Journal of Physics: Conference Series. Vol. 1037. No. 3. IOP Publishing, 2018. [Link to the paper](https://iopscience.iop.org/article/10.1088/1742-6596/1037/3/032009/meta)
