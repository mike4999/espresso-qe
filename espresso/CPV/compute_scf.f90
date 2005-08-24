!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
SUBROUTINE compute_scf( N_in, N_fin, stat  )
  !----------------------------------------------------------------------------
  !
  ! ... this subroutine is the main scf-driver for all "path" calculations
  ! ... ( called by Modules/path_base.f90/born_oppenheimer() subroutine )
  !
  USE kinds,             ONLY : DP
  USE ions_base,         ONLY : nat, sort_tau, tau_srt, ind_srt, ityp, nsp
  USE control_flags,     ONLY : conv_elec, ndr, program_name, nbeg, taurdr, &
                                trane, ampre, nomore
  USE io_files,          ONLY : iunpath, iunexit, outdir, prefix, scradir
  USE io_global,         ONLY : stdout, ionode
  USE path_formats,      ONLY : scf_fmt
  USE path_variables,    ONLY : pos, pes, grad_pes, num_of_images, &
                                dim, suspended_image, frozen
  USE parser,            ONLY : int_to_char
  USE mp_global,         ONLY : mpime, my_pool_id
  USE mp,                ONLY : mp_barrier
  USE check_stop,        ONLY : check_stop_now
  USE cp_restart,        ONLY : check_restartfile
  USE main_module,       ONLY : cpmain
  USE input,             ONLY : modules_setup
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)   :: N_in, N_fin
  LOGICAL, INTENT(OUT)  :: stat
  ! 
  INTEGER                     :: image
  REAL (KIND=DP)              :: tcpu 
  CHARACTER (LEN=256)         :: outdir_saved
  LOGICAL                     :: file_exists, opnd, tstop 
  REAL (KIND=DP), ALLOCATABLE :: tau(:,:)
  REAL (KIND=DP), ALLOCATABLE :: fion(:,:)
  REAL (KIND=DP)              :: etot
  INTEGER                     :: ia, is, isa, ipos
  REAL (KIND=DP), EXTERNAL    :: get_clock
  !
  !
  stat = .TRUE.
  tcpu = 0.D0
  !
  ALLOCATE( tau( 3, nat ), fion( 3, nat ) )
  !
  outdir_saved = outdir
  ! 
  DO image = N_in, N_fin
     !
     IF ( frozen(image) ) CYCLE
     !
     suspended_image = image
     !
     tstop = check_stop_now()
     stat  = .NOT. tstop
     !
     IF( tstop ) RETURN
     !
     outdir = TRIM( outdir_saved ) // "/" // TRIM( prefix ) // "_" // &
              TRIM( int_to_char( image ) ) // "/" 
     !
     scradir = outdir
     !
     tcpu = get_clock( program_name )
     !
     WRITE( UNIT = iunpath, FMT = scf_fmt ) tcpu, image
     !
     ! ... unit stdout is connected to the appropriate file
     !
     IF ( ionode ) THEN
        !
        INQUIRE( UNIT = stdout, OPENED = opnd )
        IF ( opnd ) CLOSE( UNIT = stdout )
        OPEN( UNIT = stdout, FILE = TRIM( outdir ) // 'CP.out', &
              STATUS = 'UNKNOWN', POSITION = 'APPEND' )
        !
     END IF
     !
     ! ... do everything as if position are read from input
     !
     taurdr = .TRUE.
     !
     IF ( check_restartfile( scradir, ndr ) ) THEN
        !
        WRITE( stdout, '(/,2X,"restarting calling readfile",/)' )
        !
       ! nbeg   = 0
       ! nomore = 100
        !
        nbeg   = -1
        nomore = 500
        trane  = .TRUE.
        ampre  = 0.02D0
        !
     ELSE
        !
        WRITE( stdout, '(/,2X,"restarting from scratch",/)' )
        !
        nbeg   = -1
        nomore = 500
        trane  = .TRUE.
        ampre  = 0.02D0
        !
     END IF
     !
     ! ... perform an electronic minimisation using cpmain
     !
     CALL deallocate_modules_var()
     !
     CALL modules_setup()
     !
     DO ia = 1, nat
        !
        tau(:,ia) = pos((3*ia-2):(3*ia),image) 
        !
     END DO
     !
     CALL sort_tau( tau_srt, ind_srt, tau, ityp, nat, nsp )       
     !
     CALL init_run()
     !
     IF ( program_name == 'CP90' ) THEN
        !
        CALL cprmain( tau, fion, etot )
        !
     ELSE IF ( program_name == 'FPMD' ) THEN
        !
        CALL cpmain( tau, fion, etot )
        !
     ELSE
        !
        CALL errore( 'compute_scf ', 'unknown program', 1 )
        !
     END IF
     !
     IF ( ionode ) THEN
        !
        INQUIRE( UNIT = stdout, OPENED = opnd )
        IF ( opnd ) CLOSE( UNIT = stdout )
        !
     END IF
     !
     IF ( .NOT. conv_elec ) THEN
        !
        WRITE( iunpath, '(/,5X,"WARNING :  scf convergence NOT achieved",/)' )
        !   
        stat = .FALSE.
        !
        RETURN
        !
     END IF
     !
     ! ... gradients already in ( hartree / bohr )
     !
     DO ia = 1, nat
        !
        grad_pes(1+(ia-1)*3,image) = - fion(1,ia)
        grad_pes(2+(ia-1)*3,image) = - fion(2,ia)
        grad_pes(3+(ia-1)*3,image) = - fion(3,ia)
        !
     END DO
     !
     ! ... energy already in hartree
     !
     pes(image) = etot
     !
  END DO
  !
  outdir = outdir_saved
  !
  suspended_image = 0
  !
  DEALLOCATE( tau, fion )
  !
  RETURN
  !
END SUBROUTINE compute_scf
