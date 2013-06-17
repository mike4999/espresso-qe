!
! Copyright (C) 2004-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------

PROGRAM lr_dav_main
  !---------------------------------------------------------------------
  ! Xiaochuan Ge, SISSA, 2013
  !---------------------------------------------------------------------
  ! ... overall driver routine for applying davidson algorithm
  ! ... to the matrix of equations coming from tddft
  !---------------------------------------------------------------------

  USE io_global,             ONLY : stdout
  USE kinds,                 ONLY : dp
  USE lr_variables,          ONLY : restart, restart_step,&
       evc1,n_ipol, d0psi, &
       no_hxc, nbnd_total, &
       revc0, lr_io_level, code,davidson
  USE io_files,              ONLY : nd_nmbr
  USE global_version,        ONLY : version_number
  USE ions_base,             ONLY : tau,nat,atm,ityp
  USE environment,           ONLY: environment_start
  USE mp_global,             ONLY : nimage, mp_startup, init_index_over_band, inter_bgrp_comm

  USE wvfct,                 ONLY : nbnd
  USE wavefunctions_module,  ONLY : psic
  USE control_flags,         ONLY : tddfpt
  USE check_stop,            ONLY : check_stop_now, check_stop_init
  USE funct,                 ONLY : dft_is_hybrid

  use lr_dav_routines
  use lr_dav_variables
  use lr_dav_debug

  !Debugging
  USE lr_variables, ONLY: check_all_bands_gamma, check_density_gamma,check_vector_gamma
  !
  IMPLICIT NONE
  INTEGER            :: ibnd_occ,ibnd_virt,ibnd
  LOGICAL            :: rflag, nomsg

#ifdef __MPI
  CALL mp_startup ( )
#endif
  tddfpt=.TRUE. !Let the phonon routines know that they are doing tddfpt.
  davidson=.true. ! To tell the code that we are using davidson method
  CALL environment_start ( code )
  CALL start_clock('lr_dav_main')

  !   Reading input file and PWSCF xml, some initialisation
  CALL lr_readin ( )
  CALL check_stop_init()

  CALL lr_init_nfo() !Initialisation of degauss/openshell related stuff

  n_ipol = 3 ! Davidson automaticly calculates all three polarizations
  CALL lr_alloc_init()   ! Allocate and zero lr variables

  !   Now print some preamble info about the run to stdout
  CALL lr_print_preamble()

  !   Read in ground state wavefunctions
  CALL lr_read_wf()
  !
  CALL init_index_over_band(inter_bgrp_comm,nbnd)

  !   Set up initial response orbitals
  CALL lr_solve_e()
  DEALLOCATE( psic )

  call lr_dav_alloc_init() ! allocate for davidson algorithm
  CALL lr_dav_set_init()
  
  !   Set up initial stuff for derivatives
  CALL lr_dv_setup()

  !   Davidson loop
  if (precondition) write(stdout,'(/5x,"Precondition is used in the algorithm,")')
  do while (.not. dav_conv .and. dav_iter .lt. max_iter)
    dav_iter=dav_iter+1
      if(if_check_orth) call check_orth()
      ! In one david step, M_C,M_D and M_CD are first constructed;then will be
        ! solved rigorously; then the solution in the subspace left_sub() will
        ! be transformed into full space left_full()
      call one_dav_step()
      call dav_calc_residue()
      call dav_expan_basis()
  enddo
  ! call check_hermitian()
  ! Extract physical meaning from the solution
  call interpret_eign()
  ! The check_orth at the end may take quite a lot of time in the case of 
  ! USPP because we didn't store the S* vector basis. Turn this step on only
  ! in cases of debugging
  ! call check_orth() 

  !   Deallocate pw variables
  CALL clean_pw( .false. )
  WRITE(stdout,'(5x,"Finished linear response calculation...")')
  CALL stop_clock('lr_dav_main')
  CALL print_clock_lr()
  CALL stop_lr( .false. )

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !Additional small-time subroutines
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
CONTAINS
  SUBROUTINE lr_print_preamble()

    USE lr_variables, ONLY : no_hxc, itermax
    USE uspp,         ONLY : okvan
    USE funct,        only : dft_is_hybrid

    IMPLICIT NONE

!    WRITE( stdout, '(/5x,"----------------------------------------")' )
!    WRITE( stdout, '(/5x,"")' )
!    WRITE( stdout, '(/5x,"Please cite this project as:  ")' )
!    WRITE( stdout, '(/5x,"O.B. Malcioglu, R. Gebauer, D. Rocca, S. Baroni,")' )
!    WRITE( stdout, '(/5x,"""turboTDDFT – a code for the simulation of molecular")' )
!    WRITE( stdout, '(/5x,"spectra using the Liouville-Lanczos approach to")' )
!    WRITE( stdout, '(/5x,"time-dependent density-functional perturbation theory""")' )
!    WRITE( stdout, '(/5x,"CPC, 182, 1744 (2011)")' )
!    WRITE( stdout, '(/5x,"----------------------------------------")' )
    !
    WRITE( stdout, '(/5x,"----------------------------------------")' )
    WRITE( stdout, '(/5x,"Welcome using turbo-davidson. For this moment you can report bugs to",/5x, &
                    & "Xiaochuan Ge: xiaochuan.ge@sissa.it",/5x, &
                    & "We appreciate a lot your help to make us improve.")' )
    WRITE( stdout, '(/5x,"----------------------------------------",/)' )
    IF(okvan) WRITE( stdout, '(/5x,"Ultrasoft (Vanderbilt) Pseudopotentials")' )

    IF (no_hxc)  THEN
       WRITE(stdout,'(5x,"No Hartree/Exchange/Correlation")')
    ELSEIF (dft_is_hybrid()) THEN
       WRITE(stdout, '(/5x,"Use of exact-exchange enabled. Note the EXX correction to the [H,X]", &
            &/5x,"commutator is NOT included hence the f-sum rule will be violated.")')
    ENDIF
  END SUBROUTINE lr_print_preamble

END PROGRAM lr_dav_main
!-----------------------------------------------------------------------
