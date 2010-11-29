!
! Copyright (C) 2002-2008 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!==============================================================================
!***  Molecular Dynamics using Density-Functional Theory                   ****
!***  this is the main routine driver for Car-Parrinello simulations       ****
!******************************************************************************
!***  See the documentation coming with the Quantum ESPRESSO distribution  ****
!***  for credits, references, appropriate citation of this code           ****
!******************************************************************************
!
!----------------------------------------------------------------------------
PROGRAM main
  !----------------------------------------------------------------------------
  !
  USE input,         ONLY : read_input_file, iosys_pseudo, iosys
  USE mp_global,     ONLY : mp_startup
  USE io_global,     ONLY : ionode
  USE control_flags, ONLY : lneb, lsmd, program_name
  USE environment,   ONLY : environment_start
  USE check_stop,    ONLY : check_stop_init
  !
  IMPLICIT NONE
  !
  ! ... program starts here
  !
  program_name = 'CP'
  !
  ! ... initialize MPI (parallel processing handling)
  !
  CALL mp_startup ( )
  !
  ! ... start the environment
  !
  CALL environment_start( program_name )
  !
  ! reset IO nodes
  ! (do this to make each "image head node" an ionode)
  ! KNK_nimage
  ! if (nimage.gt.1) CALL io_global_start( me_image, root_image )
  !
  ! reading plugin arguments
  IF(ionode) CALL plugin_arguments()
  !
  ! ... readin the input file
  !
  CALL read_input_file()
  !
  ! ... read in pseudopotentials files and then
  ! ... copy pseudopotential parameters into internal variables
  !
  CALL iosys_pseudo()
  !
  ! ... copy-in input parameters from input_parameter module
  !
  CALL iosys()
  !
  ! call to void routine for user define / plugin patches initializations
  !
  CALL plugin_initialization()
  !
  !
  CALL check_stop_init()
  !
  IF ( lneb ) THEN
     !
     !!!CALL neb_loop( )
     CALL errore ( 'cpr_main', 'NEB no longer implemented', 1)
     !
  ELSE IF ( lsmd ) THEN
     !
     CALL errore ( 'cpr_main', 'SMD no longer implemented', 1)
     !
  ELSE
     !
     CALL cpr_loop( 1 )
     !
  END IF
  !
  CALL stop_run( .TRUE. )
  !
  STOP
  !
END PROGRAM main
