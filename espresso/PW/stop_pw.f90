!
! Copyright (C) 2001-2003 PWSCF group
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
  USE varie,             ONLY :  order
  USE units,             ONLY :  iunwfc, iunoldwfc, iunoldwfc2, iunigk, iunres
  USE io_files,          ONLY :  prefix
#ifdef __PARA
  USE mp,                ONLY :  mp_barrier, mp_end
#endif  
  !
  IMPLICIT NONE
  !
  LOGICAL, INTENT(IN) :: flag
  LOGICAL             :: exst
  !
  !  ... iunwfc contains wavefunctions and is kept open during
  !  ... the execution - close and save the file
  !
  CLOSE( UNIT = iunwfc, STATUS = 'KEEP' )
  !
  IF ( order > 1 ) &
     CLOSE( UNIT = iunoldwfc, STATUS = 'KEEP' ) 
  !
  IF ( order > 2 ) &
     CLOSE( UNIT = iunoldwfc2, STATUS = 'KEEP' ) 
  !      
  IF ( flag ) THEN
     !
     ! ... all other files must be reopened and removed
     !
     CALL seqopn( iunres, 'restart', 'UNFORMATTED', exst )
     CLOSE( UNIT = iunres, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix )//'.bfgs', 'UNFORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
     CALL seqopn( 4, TRIM( prefix )//'.md', 'FORMATTED', exst )
     CLOSE( UNIT = 4, STATUS = 'DELETE' )
     !
  END IF
  !
  ! ... iunigk is kept open during the execution - close and remove
  !
  CLOSE( UNIT = iunigk, STATUS = 'DELETE' )
  CALL print_clock_pw
  !
  CALL show_memory ()
  !
#ifdef __PARA
  CALL mp_barrier()
  CALL mp_end()
#endif  
  !
#ifdef __T3E
  !
  ! ... set streambuffers off
  !
  CALL set_d_stream( 0 )
#endif
  !
  CALL clean_pw
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
  USE io_global,         ONLY :  stdout
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
  USE io_global,         ONLY :  stdout
  !  
  ! TEMP: compatibility with Car-Parrinello code
  !
  WRITE( stdout, '("what am i doing in cpflush ?")' )
  !
  CALL stop_pw( .FALSE. )
  !
  RETURN
  !
END SUBROUTINE cpflush
