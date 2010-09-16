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
  USE control_flags,    ONLY : conv_elec, lpath, gamma_only, lscf
  USE control_flags,    ONLY : conv_ions, istep, nstep, restart, lmd, lbfgs
  USE force_mod,        ONLY : lforce, lstres
  USE environment,      ONLY : environment_start
  USE check_stop,       ONLY : check_stop_init
  USE mp_global,        ONLY : mp_startup
#if defined(__MS2)
  USE ms2,              ONLY : MS2_enabled,                 &
                               ms2_initialization,    &
                               set_positions, return_forces
#endif
  !
  IMPLICIT NONE
  !
  !
#ifdef __PARA
  CALL mp_startup ( )
#endif
  CALL environment_start ( 'PWSCF' )
  !
  IF ( ionode ) THEN
     !
#if defined (EXX)
     WRITE( UNIT = stdout, &
         & FMT = '(/,5X,"EXPERIMENTAL VERSION WITH EXACT EXCHANGE")' )
#endif
     WRITE( unit = stdout, FMT = 9010 ) &
         ntypx, npk, lmaxx
     !
  END IF   
  !
  CALL iosys()
  !
  IF ( gamma_only ) WRITE( UNIT = stdout, &
     & FMT = '(/,5X,"gamma-point specific algorithms are used")' )
  !
  CALL check_stop_init()
  !
#if defined(__MS2)
  CALL ms2_initialization()
#endif
  !
  CALL setup ()
  !
#if defined(__MS2)
  CALL set_positions()
#endif
  !
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
!  CALL ions()
  !
  CALL start_clock( 'ions' )
  !
  conv_ions = .TRUE.
  !
  ! ... recover from a previous run, if appropriate
  !
  IF ( restart .AND. lscf ) CALL restart_in_ions()
  !
  IF ( lforce ) CALL forces()
  !
  IF ( lstres ) CALL stress()
  !
  IF ( lmd .OR. lbfgs ) THEN
     !
     ! ... first we move the ions
     !
     CALL move_ions()
     !
     ! ... then we save restart information for the new configuration
     !
     IF ( istep < nstep .AND. .NOT. conv_ions ) THEN
        !
        CALL punch( 'config' )
        !
        CALL save_in_ions()
        !
     END IF
     !
  END IF
  !
  CALL stop_clock( 'ions' )
  !
     !
#if defined(__MS2)
     CALL return_forces()
#endif
     !
     ! ... exit condition (ionic convergence) is checked here
     !
     IF ( conv_ions ) EXIT main_loop
     !
     ! ... the ionic part of the hamiltonian is reinitialized
     !
#if defined(__MS2)
     CALL set_positions()
#endif
     CALL hinit1()
     !
  END DO main_loop
  !
  CALL stop_run( conv_ions )
  !
  !  END IF      
  !
  STOP
  !
9010 FORMAT( /,5X,'Current dimensions of program PWSCF are:', &
           & /,5X,'Max number of different atomic species (ntypx) = ',I2,&
           & /,5X,'Max number of k-points (npk) = ',I6,&
           & /,5X,'Max angular momentum in pseudopotentials (lmaxx) = ',i2)
  !
END PROGRAM pwscf
