!
! Copyright (C) 2001-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
PROGRAM pwscf
  !----------------------------------------------------------------------------
  !
  ! ... Main program calling one instance of Plane Wave Self-Consistent Field code
  !
  USE environment,       ONLY : environment_start, environment_end
  USE io_global,         ONLY : ionode, ionode_id, stdout
  USE mp_global,         ONLY : mp_startup
  USE read_input,        ONLY : read_input_file
  USE command_line_options, ONLY: input_file_
  !
  IMPLICIT NONE
  !
  !
  CALL mp_startup ( )
  CALL environment_start ( 'PWSCF' )
  !
  CALL read_input_file ('PW', input_file_ )
  !
  ! ... Perform actual calculation
  !
  CALL run_pwscf  ( )
  !
  STOP
  !
END PROGRAM pwscf
