!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE stop_pw( flag )
  !----------------------------------------------------------------------------
  !
  ! ... Close all files and synchronize processes before stopping.
  ! ... Called at the end of the run with flag = .TRUE. (removes 'restart')
  ! ... or during execution with flag = .FALSE. (does not remove 'restart')
  !
  USE io_global,         ONLY :  stdout, ionode
  USE control_flags,     ONLY :  lneb
  USE io_files,          ONLY :  prefix, iunwfc, iunigk, iunres
  USE input_parameters,  ONLY :  deallocate_input_parameters
  USE io_routines,       ONLY :  write_restart
  USE neb_variables,     ONLY :  neb_deallocation
  USE mp,                ONLY :  mp_barrier, mp_end
  !
  IMPLICIT NONE
  !
  LOGICAL, INTENT(IN) :: flag
  LOGICAL             :: exst
  !
  !
  ! ... in case of neb calculation stdout is reconnected to standard output
  !
  IF ( lneb ) stdout = 6
  !
  ! ... iunwfc contains wavefunctions and is kept open during
  ! ... the execution - close and save the file
  !
  CLOSE( UNIT = iunwfc, STATUS = 'KEEP' )
  !      
  IF ( flag .AND. ionode ) THEN
     !
     ! ... all other files must be reopened and removed
     !
     CALL seqopn( iunres, 'restart', 'UNFORMATTED', exst )
     CLOSE( UNIT = iunres, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix ) // '.bfgs', 'UNFORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix ) // '.md', 'FORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix ) // '.para', 'FORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix ) // '.BLOCK', 'FORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
  END IF
  !
  ! ... iunigk is kept open during the execution - close and remove
  !
  CLOSE( UNIT = iunigk, STATUS = 'DELETE' )
  !
  CALL print_clock_pw()
  !
  ! ... NEB specific
  !
  IF ( lneb ) CALL write_restart()
  !
  CALL show_memory()
  !
  CALL mp_barrier()
  !
  CALL mp_end()
  !
#ifdef __T3E
  !
  ! ... set streambuffers off
  !
  CALL set_d_stream( 0 )
#endif
  !
  CALL clean_pw()
  CALL deallocate_input_parameters()
  CALL neb_deallocation()
  !
  IF ( flag ) THEN
     STOP
  ELSE
     STOP 1
  END IF
  !
END SUBROUTINE stop_pw
!
!
!----------------------------------------------------------------------------
SUBROUTINE closefile
  !----------------------------------------------------------------------------
  !
  USE io_global,  ONLY :  stdout
  !
  ! ... Close all files and synchronize processes before stopping
  ! ... Called by "sigcatch" when it receives a signal
  !
  WRITE( stdout,'(5X,"Signal Received, stopping ... ")')
  !
  CALL stop_pw( .FALSE. )
  !
  RETURN
  !
END SUBROUTINE closefile
!
!
!----------------------------------------------------------------------------
SUBROUTINE cpflush
  !----------------------------------------------------------------------------
  !
  ! TEMP: compatibility with Car-Parrinello code
  !
  PRINT *, "what am i doing in cpflush ?"
  !
  CALL stop_pw( .FALSE. )
  !
  RETURN
  !
END SUBROUTINE cpflush
