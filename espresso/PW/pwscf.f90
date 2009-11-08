!
! Copyright (C) 2001-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
PROGRAM pwscf
  !----------------------------------------------------------------------------
  !
  ! ... Plane Wave Self-Consistent Field code 
  !
  USE io_global,        ONLY : stdout, ionode
  USE parameters,       ONLY : ntypx, npk, lmaxx
  USE noncollin_module, ONLY : noncolin
  USE control_flags,    ONLY : conv_elec, conv_ions, lpath, lmetadyn, &
                               gamma_only, use_task_groups, ortho_para
  USE environment,      ONLY: environment_start
  USE ions_base,        ONLY : tau
  USE path_variables,   ONLY : conv_path
  USE check_stop,       ONLY : check_stop_init
  USE path_base,        ONLY : initialize_path, search_mep
  USE metadyn_base,     ONLY : metadyn_init
  USE path_io_routines, ONLY : io_path_start, path_summary
  USE mp_global,        ONLY : nimage, mp_startup
  !
  IMPLICIT NONE
  !
  !
#ifdef __PARA
  CALL mp_startup ( use_task_groups, ortho_para )
#endif
  CALL environment_start ( 'PWSCF' )
  !
  IF ( ionode ) THEN
     !
#if defined (EXX)
     WRITE( UNIT = stdout, &
         & FMT = '(/,5X,"!!! EXPERIMENTAL VERSION WITH EXACT EXCHANGE !!!")' )
#endif
     IF ( gamma_only ) WRITE( UNIT = stdout, &
         & FMT = '(/,5X,"gamma-point specific algorithms are used")' )
  !
     WRITE( unit = stdout, FMT = 9010 ) &
         ntypx, npk, lmaxx
     !
  END IF   
  !
  CALL iosys()
  !
  CALL check_stop_init()
  !
  IF ( lpath ) THEN
     !
     CALL io_path_start()
     !
     CALL initialize_path()
     !
     CALL path_summary()
     !
     CALL search_mep()
     !
     CALL stop_run( conv_path )
     !
  ELSE
     !
     IF ( lmetadyn ) THEN
        !
        ! ... meta-dynamics
        !
        CALL metadyn_init( 'PW', tau )
        !
        CALL setup ()
        CALL init_run()
        !
        CALL metadyn()
        !
     ELSE
        !
#if defined (EXX)
        if(nimage>1) CALL io_path_start()
        CALL exx_loop()
#else
        !
        CALL setup ()
        CALL init_run()
        !
        main_loop: DO
           !
           ! ... electronic self-consistentcy
           !
           CALL electrons()
           !
           IF ( .NOT. conv_elec ) CALL stop_run( conv_elec )
           !
           ! ... if requested ions are moved
           !
           CALL ions()
           !
           ! ... exit condition (ionic convergence) is checked here
           !
           IF ( conv_ions ) EXIT main_loop
           !
           ! ... the ionic part of the hamiltonian is reinitialized
           !
           CALL hinit1()
           !
        END DO main_loop
        !
#endif
        !
     END IF
     !
     CALL stop_run( conv_ions )
     !
  END IF      
  !
  STOP
  !
9010 FORMAT( /,5X,'Current dimensions of program PWSCF are:', &
           & /,5X,'Max number of different atomic species (ntypx) = ',I2,&
           & /,5X,'Max number of k-points (npk) = ',I6,&
           & /,5X,'Max angular momentum in pseudopotentials (lmaxx) = ',i2)
  !
END PROGRAM pwscf
