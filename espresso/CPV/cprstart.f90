!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!==============================================================================
!***  Molecular Dynamics using Density-Functional Theory   ****
!***  this is a Car-Parrinello program using Vanderbilt pseudopotentials
!******************************************************************************
!***  based on version 11 of cpv code including ggapw 07/04/99
!***  copyright Alfredo Pasquarello 10/04/1996
!***  parallelized and converted to f90 by Paolo Giannozzi (2000),
!***  using parallel FFT written for PWSCF by Stefano de Gironcoli
!***  PBE added by Michele Lazzeri (2000)
!***  variable-cell dynamics by Andrea Trave (1998-2000)
!***  Makov Payne Correction for charged systems by Filippo De Angelis
!******************************************************************************
!***  appropriate citation for use of this code:
!***  Car-Parrinello method    R. Car and M. Parrinello, PRL 55, 2471 (1985) 
!***  current implementation   A. Pasquarello, K. Laasonen, R. Car, 
!***                           C. Lee, and D. Vanderbilt, PRL 69, 1982 (1992);
!***                           K. Laasonen, A. Pasquarello, R. Car, 
!***                           C. Lee, and D. Vanderbilt, PRB 47, 10142 (1993).
!***  implementation gga       A. Dal Corso, A. Pasquarello, A. Baldereschi,
!***                           and R. Car, PRB 53, 1180 (1996).
!***  implementation Wannier   M. Sharma, Y. Wu and R. Car, Int.J.Quantum.Chem.
!***  function dynamics        95, 821, (2003).
!***
!***  implementation           M. Sharma and R.Car, ???
!***  Electric Field
!***  ensemble-DFT
!***    cf. "Ensemble Density-Functional Theory for Ab Initio Molecular Dynamics
!***        of Metals and Finite-Temperature Insulators"  PRL v.79,nbsp.7 (1997)
!***        nbsp. Marzari, D. Vanderbilt and M.C. Payne
!***  string methods           Yosuke Kanai et al.  J. Chem. Phys., 
!***                           2004, 121, 3359-3367
!***
!******************************************************************************
!***  
!***  f90 version, with dynamical allocation of memory
!***  Variables that do not change during the dynamics are in modules
!***  (with some exceptions) All other variables are passed as arguments
!******************************************************************************
!***
!*** fft : uses machine's own complex fft routines, two real fft at the time
!*** ggen: g's only for positive halfspace (g>)
!*** all routines : keep equal c(g) and [c(-g)]*
!***
!******************************************************************************
!    general variables:
!     delt           = delta t
!     emass          = electron mass (fictitious)
!     dt2bye         = 2*delt/emass
!******************************************************************************
!
!  ==========================================================================
!  ====   units and constants                                            ====
!  ====                                                                  ====
!  ====   1 hartree           = 1 a.u.                                   ====
!  ====   1 bohr radius       = 1 a.u. = 0.529167 Angstrom               ====
!  ====   1 rydberg           = 1/2 a.u.                                 ====
!  ====   1 electron volt     = 1/27.212 a.u.                            ====
!  ====   1 kelvin *k-boltzm. = 1/(27.212*11606) a.u.'='3.2e-6 a.u       ====
!  ====   1 second            = 1/(2.4189)*1.e+17 a.u.                   ====
!  ====   1 proton mass       = 1822.89 a.u.                             ====
!  ====   1 tera              = 1.e+12                                   ====
!  ====   1 pico              = 1.e-12                                   ====
!  ====   1 Volt / meter      = 1/(5.1412*1.e+11) a.u.                   ====
!  ==========================================================================
!
!----------------------------------------------------------------------------
PROGRAM main
  !----------------------------------------------------------------------------
  !
  USE input,         ONLY : read_input_file, iosys_pseudo, iosys
  USE io_global,     ONLY : io_global_start, io_global_getionode
  USE mp_global,     ONLY : mp_global_start
  USE mp,            ONLY : mp_end, mp_start, mp_env
  USE control_flags, ONLY : lneb, lsmd, program_name
  USE environment,   ONLY : environment_start, environment_end
  !
  IMPLICIT NONE
  !
  INTEGER            :: mpime, nproc, gid, ionode_id
  LOGICAL            :: ionode
  INTEGER, PARAMETER :: root = 0
  !
  ! ... program starts here
  !
  ! ... initialize MPI (parallel processing handling)
  !
  CALL mp_start()
  CALL mp_env( nproc, mpime, gid )
  CALL mp_global_start( root, mpime, gid, nproc )
  !
  ! ... mpime = processor number, starting from 0
  ! ... nproc = number of processors
  ! ... gid   = group index
  ! ... root  = index of the root processor
  !
  program_name = 'CP90'
  !
  ! ... initialize input output
  !
  CALL io_global_start( mpime, root )
  CALL io_global_getionode( ionode, ionode_id )
  !
  CALL environment_start( )
  !
  ! ... readin the input file
  !
  CALL read_input_file()
  !
  ! ... copy pseudopotential input parameter into internal variables
  ! ... and read in pseudopotentials and wavefunctions files
  !
  CALL iosys_pseudo()
  !
  ! ... copy-in input parameters from input_parameter module
  !
  CALL iosys()
  !
  ! ... initialize g-vectors, fft grids
  !
  CALL init_dimensions()
  !
  IF ( lneb ) THEN
     !
     CALL neb_loop( 1, program_name )
     !
  ELSE IF ( lsmd ) THEN
     !
     CALL smd_loop( 1 )
     !
  ELSE
     !
     CALL cpr_loop( 1 )
     !
  END IF
  !
  CALL environment_end( )
  !
  CALL mp_end()
  !
  STOP
  !
END PROGRAM main
