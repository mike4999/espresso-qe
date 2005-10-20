!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!=----------------------------------------------------------------------------=!
MODULE io_files
!=----------------------------------------------------------------------------=!
  !
  USE parameters, ONLY: ntypx
  !
  ! ... The name of the files
  !
  IMPLICIT NONE
  !
  SAVE
  !
  CHARACTER(len=256) :: tmp_dir = './'  ! directory for temporary files
  CHARACTER(len=256) :: wfc_dir = 'undefined'  ! directory for large files on each node, should be kept 'undefined' if not known 
  CHARACTER(len=256) :: prefix  = 'os'  ! prepended to file names
  CHARACTER(len=3)   :: nd_nmbr = '000' ! node number (used only in parallel case)
  CHARACTER(len=256) :: pseudo_dir = './'
  CHARACTER(len=256) :: psfile( ntypx ) = 'UPF'
  CHARACTER(len=256) :: scradir = './'
  CHARACTER(len=256) :: outdir  = './'
  !
  CHARACTER(LEN=256) :: input_drho = ' '   ! name of the file with the input drho
  CHARACTER(LEN=256) :: output_drho = ' '  ! name of the file with the output drho
  !
  CHARACTER(LEN=19) :: band_file = ' '
  CHARACTER(LEN=19) :: tran_file = ' '
  CHARACTER(LEN=14) :: prefixt   = ' '
  CHARACTER(LEN=14) :: prefixl   = ' '
  CHARACTER(LEN=14) :: prefixs   = ' '
  CHARACTER(LEN=14) :: prefixr   = ' '
  CHARACTER(LEN=256) :: save_file = ' '
  CHARACTER(LEN=256) :: fil_loc = ' '      !  file with 2D eigenvectors and eigenvalues
  !
  CHARACTER(LEN=14), PARAMETER :: rho_name      = 'CHARGE_DENSITY'
  CHARACTER(LEN=17), PARAMETER :: rho_name_up   = 'CHARGE_DENSITY.UP'
  CHARACTER(LEN=19), PARAMETER :: rho_name_down = 'CHARGE_DENSITY.DOWN'
  CHARACTER(LEN=14), PARAMETER :: rho_name_avg  = 'CHARGE_AVERAGE'
  !
  CHARACTER(LEN=4 ), PARAMETER :: chifile       = 'CHI2'
  CHARACTER(LEN=7 ), PARAMETER :: dielecfile    = 'EPSILON'
  !
  CHARACTER(LEN=15), PARAMETER :: empty_file    = 'EMPTY_STATES.WF'
  CHARACTER(LEN=5 ), PARAMETER :: crash_file    = 'CRASH'
  CHARACTER(LEN=7 ), PARAMETER :: stop_file     = '.cpstop'
  CHARACTER(LEN=2 ), PARAMETER :: ks_file       = 'KS'
  CHARACTER(LEN=6 ), PARAMETER :: ks_emp_file   = 'KS_EMP'
  CHARACTER(LEN=16), PARAMETER :: sfac_file     = 'STRUCTURE_FACTOR'
  CHARACTER (LEN=256) :: &
    dat_file  = 'os.dat',    &! file containing the enegy profile
    int_file  = 'os.int',    &! file containing the interpolated energy profile
    path_file = 'os.path',   &! file containing informations needed to restart a path simulation
    xyz_file  = 'os.xyz',    &! file containing coordinates of all images in xyz format
    axsf_file = 'os.axsf',   &! file containing coordinates of all images in axsf format
    broy_file = 'os.broyden'  ! file containing broyden's history
  CHARACTER (LEN=261) :: &
    exit_file = "os.EXIT"    ! file required for a soft exit  
  CHARACTER (LEN=11), PARAMETER :: xmlpun = 'restart.xml'
  CHARACTER(LEN=256) :: vib_out_file  = 'vibrations.out', & ! output of phrozen phonon vibrational calculation
                        vib_mass_file = 'mass.vib'         ! isotope masses used for diagonalizing the
                                                      ! ...dynamical matrix
  !
  ! ... The units where various variables are saved
  !
  INTEGER :: rhounit     = 17
  INTEGER :: emptyunit   = 19
  INTEGER :: crashunit   = 15
  INTEGER :: stopunit    = 7
  INTEGER :: ksunit      = 18
  INTEGER :: sfacunit    = 20
  INTEGER :: pseudounit  = 10
  INTEGER :: chiunit     = 20
  INTEGER :: dielecunit  = 20
  INTEGER :: opt_unit    = 20 ! optional unit 
  !
  ! ... units in pwscf
  !
  INTEGER :: iunpun      =  4 ! unit for saving the final results
  INTEGER :: iunwfc      = 10 ! unit with wavefunctions
  INTEGER :: iunat       = 13 ! unit for saving orthogonal atomic wfcs
  INTEGER :: iunocc      = 14 ! unit for saving the atomic n_{ij}
  INTEGER :: iunoldwfc   = 11 ! unit with old wavefunctions
  INTEGER :: iunoldwfc2  = 12 ! as above at step -2
  INTEGER :: iunigk      = 16 ! unit for saving indices
  INTEGER :: iunres      =  1 ! unit for the restart of the run
  INTEGER :: iunbfgs     = 30 ! unit for the bfgs restart file
  !
  INTEGER :: nwordwfc    =  2 ! lenght of record in wavefunction file
  INTEGER :: nwordatwfc  =  2 ! lenght of record in atomic wfc file
  !
  INTEGER :: iunexit     = 26 ! unit for a soft exit  
  INTEGER :: iunupdate   = 27 ! unit for saving old positions (extrapolation)
  INTEGER :: iunnewimage = 28 ! unit for parallelization among images
  INTEGER :: iunblock    = 29 ! as above (blocking file)
  !
  ! ... "path" specific
  !
  INTEGER :: iunpath     =  6 ! unit for string output ( stdout or what else )
  INTEGER :: iunrestart  = 21 ! unit for saving the restart file ( neb_file )
  INTEGER :: iundat      = 22 ! unit for saving the enegy profile
  INTEGER :: iunint      = 23 ! unit for saving the interpolated energy profile
  INTEGER :: iunxyz      = 24 ! unit for saving coordinates ( xyz format )
  INTEGER :: iunaxsf     = 25 ! unit for saving coordinates ( axsf format )
  INTEGER :: iunbroy     = 26 ! unit for saving broyden's history
  !
  ! ... meta-dynamics
  !
  INTEGER :: iunmeta     = 77 ! unit for saving meta-dynamics history
  !
  ! ... Y. Kanai combined smd/cp method
  !
  INTEGER :: smwout      = 20 ! base value to compute index for replica files
  !
  INTEGER :: vib_out     = 20 ! output of phrozen phonon vibrational calculation
  INTEGER :: vib_mass    = 21 ! isotope masses used for the dynamical matrix
  !
  !... finite electric field (Umari)
  !
  INTEGER :: iunefield   = 31 ! unit to store wavefunction for calculatin electric field operator
  !
!=----------------------------------------------------------------------------=!
END MODULE io_files
!=----------------------------------------------------------------------------=!
