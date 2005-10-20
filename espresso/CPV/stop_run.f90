!
! Copyright (C) 2001-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE stop_run( flag )
  !----------------------------------------------------------------------------
  !
  ! ... Close all files and synchronize processes before stopping.
  !
  USE io_global,          ONLY : stdout, ionode
  USE control_flags,      ONLY : lpath, lneb, lsmd, lconstrain, &
                                 lcoarsegrained
  USE io_files,           ONLY : prefix
  USE environment,        ONLY : environment_end
  USE path_variables,     ONLY : path_deallocation
  USE path_io_routines,   ONLY : io_path_stop
  USE constraints_module, ONLY : deallocate_constraint
  USE coarsegrained_vars, ONLY : deallocate_coarsegrained_vars
  USE mp,                 ONLY : mp_barrier, mp_end
  !
  IMPLICIT NONE
  !
  LOGICAL, INTENT(IN) :: flag
  LOGICAL             :: exst
  !
  !
  CALL environment_end()
  !
  IF ( lpath ) CALL io_path_stop()
  !
#ifdef __T3E
  !
  ! ... set streambuffers off
  !
  CALL set_d_stream( 0 )
  !
#endif
  !
  CALL deallocate_modules_var()
  !
  IF ( lconstrain ) CALL deallocate_constraint()
  !
  IF ( lcoarsegrained ) CALL deallocate_coarsegrained_vars()
  !
  IF ( lneb ) THEN
     !
     CALL path_deallocation( 'neb' )
     !
  ELSE IF ( lsmd ) THEN
     !
     CALL path_deallocation( 'smd' )
     !
  END IF
  !
  CALL mp_barrier()
  !
  CALL mp_end()
  !
  IF ( flag ) THEN
     !
     STOP
     !
  ELSE
     !
     STOP 1
     !
  END IF
  !
END SUBROUTINE stop_run
