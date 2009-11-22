!
! Copyright (C) 2002-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
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
  USE control_flags,     ONLY : conv_elec, ndr, nbeg, taurdr, &
                                trane, ampre, nomore, tfor, isave
  USE cp_main_variables, ONLY : nfi
  USE io_files,          ONLY : iunpath, iunexit, tmp_dir, prefix
  USE io_global,         ONLY : stdout, ionode
  USE path_formats,      ONLY : scf_fmt
  USE path_variables,    ONLY : pos, pes, grad_pes, num_of_images, &
                                dim1, pending_image, frozen
  USE check_stop,        ONLY : check_stop_now
  USE xml_io_base,       ONLY : check_restartfile
  USE input,             ONLY : modules_setup
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)   :: N_in, N_fin
  LOGICAL, INTENT(OUT)  :: stat
  ! 
  INTEGER               :: image
  REAL(DP)              :: tcpu 
  CHARACTER(LEN=256)    :: tmp_dir_saved
  LOGICAL               :: opnd
  REAL(DP), ALLOCATABLE :: tau(:,:)
  REAL(DP), ALLOCATABLE :: fion(:,:)
  REAL(DP)              :: etot
  !
  CHARACTER(LEN=6), EXTERNAL :: int_to_char
  REAL(DP),         EXTERNAL :: get_clock
  !
  !
  stat = .TRUE.
  tcpu = 0.D0
  !
  ALLOCATE( tau( 3, nat ), fion( 3, nat ) )
  !
  tmp_dir_saved  = tmp_dir
  ! 
  DO image = N_in, N_fin
     !
     IF ( frozen(image) ) CYCLE
     !
     pending_image = image
     !
     IF ( check_stop_now() ) THEN
        !
        stat = .FALSE.
        !
        RETURN
        !
     END IF
     !
     tmp_dir = TRIM ( tmp_dir_saved ) // "/" // TRIM( prefix ) // "_" // &
               TRIM( int_to_char( image ) ) // "/"
     !
     tcpu = get_clock( 'CP' )
     !
     WRITE( UNIT = iunpath, FMT = scf_fmt ) tcpu, image
     !
     ! ... unit stdout is connected to the appropriate file
     !
     IF ( ionode ) THEN
        !
        INQUIRE( UNIT = stdout, OPENED = opnd )
        IF ( opnd ) CLOSE( UNIT = stdout )
        OPEN( UNIT = stdout, FILE = TRIM( tmp_dir ) // 'CP.out', &
              STATUS = 'UNKNOWN', POSITION = 'APPEND' )
        !
     END IF
     !
     CALL deallocate_modules_var()
     !
     CALL modules_setup()
     !
     tau = RESHAPE( pos(:,image), SHAPE( tau ) )
     !
     CALL sort_tau( tau_srt, ind_srt, tau, ityp, nat, nsp )
     !
     taurdr = .TRUE.
     nfi    = 0
     tfor   = .FALSE.
     !
     IF ( check_restartfile( tmp_dir, ndr ) ) THEN
        !
        WRITE( stdout, '(/,2X,"restarting from file",/)' )
        !
        nbeg   = 0
        nomore = 2000
        trane  = .FALSE.
        ampre  = 0.0D0
        !
     ELSE
        !
        WRITE( stdout, '(/,2X,"restarting from scratch",/)' )
        !
        nbeg   = -1
        nomore = 5000
        trane  = .TRUE.
        ampre  = 0.02D0
        !
     END IF
     !
     isave = nomore
     !
     ! ... perform an electronic minimisation using CP
     !
     CALL init_run()
     !
     CALL cprmain( tau, fion, etot )
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
     grad_pes(:,image) = - RESHAPE( fion, (/ dim1 /) )
     !
     ! ... energy already in hartree
     !
     pes(image) = etot
     !
  END DO
  !
  tmp_dir = tmp_dir_saved
  !
  pending_image = 0
  !
  DEALLOCATE( tau, fion )
  !
  RETURN
  !
END SUBROUTINE compute_scf
