!
! Copyright (C) 2001-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
SUBROUTINE stop_run( flag )
  !----------------------------------------------------------------------------
  !
  ! ... Close all files and synchronize processes before stopping.
  ! ... Called at the end of the run with flag = .TRUE. (removes 'restart')
  ! ... or during execution with flag = .FALSE. (does not remove 'restart')
  !
  USE io_global,          ONLY : ionode
  USE mp_global,          ONLY : nimage
  USE environment,        ONLY : environment_end
  USE control_flags,      ONLY : lpath, twfcollect, lconstrain, &
                                 lcoarsegrained, io_level, llondon
  USE io_files,           ONLY : iunwfc, iunigk, iunefield, iunefieldm,&
                                 iunefieldp, iuntmp
  USE buffers,            ONLY : close_buffer
  USE path_variables,     ONLY : path_deallocation
  USE path_io_routines,   ONLY : io_path_stop
  USE london_module,      ONLY : dealloca_london
  USE constraints_module, ONLY : deallocate_constraint
  USE metadyn_vars,       ONLY : deallocate_metadyn_vars
  USE input_parameters,   ONLY : deallocate_input_parameters
  USE mp,                 ONLY : mp_barrier, mp_end
  USE bp,                 ONLY : lelfield
  !
  IMPLICIT NONE
  !
  LOGICAL, INTENT(IN) :: flag
  LOGICAL             :: exst, opnd
  !
  !
  CALL environment_end( 'PWSCF' )
  !
#if defined (EXX)
  IF ( lpath .or. nimage > 1 ) THEN
#else
  IF ( lpath ) THEN
#endif
     !
     CALL io_path_stop()
     !
  ELSE
     !
     ! ... here we write all the data required to restart
     !
     CALL punch( 'all' )
     !
  END IF
  !
  ! ... iunwfc contains wavefunctions and is kept open during
  ! ... the execution - close the file and save it (or delete it 
  ! ... if the wavefunctions are already stored in the .save file)
  !
  IF ( flag .AND. ( io_level < 0 .OR. twfcollect ) ) THEN
     !
     call close_buffer ( iunwfc, 'DELETE' )
     !
  ELSE
     !
     call close_buffer ( iunwfc, 'KEEP' )
     !
  END IF
  !      
  IF (flag .and. .not. lpath) THEN
     CALL seqopn( iuntmp, 'restart', 'UNFORMATTED', exst )
     CLOSE( UNIT = iuntmp, STATUS = 'DELETE' )
  ENDIF

  IF ( flag .AND. ionode ) THEN
     !
     ! ... all other files must be reopened and removed
     !
     CALL seqopn( iuntmp, 'update', 'FORMATTED', exst )
     CLOSE( UNIT = iuntmp, STATUS = 'DELETE' )
     !
     CALL seqopn( iuntmp, 'para', 'FORMATTED', exst )
     CLOSE( UNIT = iuntmp, STATUS = 'DELETE' )
     !
     CALL seqopn( iuntmp, 'BLOCK', 'FORMATTED', exst )
     CLOSE( UNIT = iuntmp, STATUS = 'DELETE' )
     !
  END IF
  !
  ! ... close unit for electric field if needed
  !
  IF ( lelfield ) THEN
     !
     INQUIRE( UNIT = iunefield, OPENED = opnd )
     IF ( opnd ) CLOSE( UNIT = iunefield, STATUS = 'KEEP' )
     !
     INQUIRE( UNIT = iunefieldm, OPENED = opnd )
     IF ( opnd ) CLOSE( UNIT = iunefieldm, STATUS = 'KEEP' )
     !
     INQUIRE( UNIT = iunefieldp, OPENED = opnd )
     IF ( opnd ) CLOSE( UNIT = iunefieldp, STATUS = 'KEEP' )
     !
  END IF
  !
  ! ... iunigk is kept open during the execution - close and remove
  !
  INQUIRE( UNIT = iunigk, OPENED = opnd )
  !
  IF ( opnd ) CLOSE( UNIT = iunigk, STATUS = 'DELETE' )
  !
  CALL print_clock_pw()
  !
  CALL mp_barrier()
  !
  CALL mp_end()
  !
  CALL clean_pw( .TRUE. )
  !
  CALL deallocate_bp_efield()
  !
  CALL deallocate_input_parameters () 
  !
  IF ( llondon ) CALL dealloca_london()
  !
  IF ( lconstrain ) CALL deallocate_constraint()
  !
  IF ( lcoarsegrained ) CALL deallocate_metadyn_vars()
  !
  IF ( lpath ) CALL path_deallocation()
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
!
!----------------------------------------------------------------------------
SUBROUTINE closefile()
  !----------------------------------------------------------------------------
  !
  USE io_global,  ONLY :  stdout
  !
  ! ... Close all files and synchronize processes before stopping
  ! ... Called by "sigcatch" when it receives a signal
  !
  WRITE( stdout,'(5X,"Signal Received, stopping ... ")')
  !
  CALL stop_run( .FALSE. )
  !
  RETURN
  !
END SUBROUTINE closefile
