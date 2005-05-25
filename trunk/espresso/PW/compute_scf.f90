!
! Copyright (C) 2003-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
SUBROUTINE compute_scf( N_in, N_fin, stat  )
  !----------------------------------------------------------------------------
  !
  ! ... this subroutine is the main scf-driver for all "path" calculations
  ! ... ( called by Modules/path_base.f90/born_oppenheimer() subroutine )
  !
  ! ... Written by Carlo Sbraccia (2003-2004)
  !
  USE kinds,            ONLY : DP
  USE input_parameters, ONLY : if_pos, sp_pos, startingwfc, startingpot, &
                               diago_thr_init
  USE constants,        ONLY : e2
  USE control_flags,    ONLY : conv_elec, istep, history, wg_set, &
                               alpha0, beta0, ethr, pot_order
  USE check_stop,       ONLY : check_stop_now
  USE vlocal,           ONLY : strf
  USE cell_base,        ONLY : bg, alat
  USE gvect,            ONLY : ngm, g, nr1, nr2, nr3, eigts1, eigts2, eigts3
  USE ions_base,        ONLY : tau, ityp, nat, nsp
  USE basis,            ONLY : startingwfc_ => startingwfc, &
                               startingpot_ => startingpot    
  USE ener,             ONLY : etot
  USE force_mod,        ONLY : force
  USE ions_base,        ONLY : if_pos_ => if_pos
  USE extfield,         ONLY : tefield, forcefield
  USE io_files,         ONLY : prefix, tmp_dir, &
                               iunpath, iunupdate, exit_file, iunexit
  USE path_formats,     ONLY : scf_fmt, scf_fmt_para
  USE path_variables,   ONLY : pos, pes, grad_pes, num_of_images, &
                               dim, suspended_image, istep_path,  &
                               first_last_opt, frozen, write_save
  USE parser,           ONLY : int_to_char
  USE path_variables,   ONLY : tune_load_balance
  USE io_global,        ONLY : stdout, ionode, ionode_id, meta_ionode
  USE mp_global,        ONLY : inter_image_comm, intra_image_comm, &
                               my_image_id, nimage, root
  USE mp,               ONLY : mp_bcast, mp_barrier, mp_sum, mp_min
  !
  IMPLICIT NONE
  !
  ! ... I/O variables
  !
  INTEGER, INTENT(IN)  :: N_in, N_fin
  LOGICAL, INTENT(OUT) :: stat
  !
  ! ... local variables definition
  !
  INTEGER                    :: image, ia, istat
  REAL (KIND=DP)             :: tcpu 
  CHARACTER (LEN=256)        :: tmp_dir_saved
  LOGICAL                    :: file_exists, opnd   
  REAL(KIND=DP), ALLOCATABLE :: tauold(:,:,:)
    ! previous positions of atoms (needed for extrapolation)
  !
  REAL (KIND=DP), EXTERNAL :: get_clock
  !
  !
  istep = istep_path + 1
  istat = 0
  !
  CALL flush_unit( iunpath )
  !
  ALLOCATE( tauold( 3, nat, 3 ) )  
  !
  tmp_dir_saved = tmp_dir
  !
  ! ... vectors pes and grad_pes are initalized to zero for all images on
  ! ... all nodes: this is needed for the final mp_sum()
  !
  IF ( my_image_id == root ) THEN
     !
#if defined(__SGI)
     FORALL( image = N_in : N_fin,   .NOT. frozen(image)   )
#else
     FORALL( image = N_in : N_fin, ( .NOT. frozen(image) ) )
#endif
        !
        pes(image)        = 0.D0
        grad_pes(:,image) = 0.D0
        !
     END FORALL     
     !
  ELSE
     !
     pes(N_in:N_fin)        = 0.D0
     grad_pes(:,N_in:N_fin) = 0.D0
     !   
  END IF
  !
  ! ... only the first cpu initializes the file needed by parallelization 
  ! ... among images
  !
  IF ( meta_ionode ) CALL new_image_init()
  !
  image = N_in + my_image_id
  !
  ! ... all processes are syncronized (needed to have an ordered output)
  !
  CALL mp_barrier()
  ! 
  scf_loop: DO
     !
     ! ... exit if available images are finished
     !
     IF ( image > N_fin ) EXIT scf_loop
     !     
     suspended_image = image
     !
     IF ( check_stop_now( iunpath ) ) THEN
        !   
        istat = 1
        !
        ! ... in case of parallelization on images a stop signal
        ! ... is sent via the "EXIT" file
        !
        IF ( nimage > 1 ) CALL stop_other_images()        
        !
        EXIT scf_loop
        !    
     END IF
     !
     ! ... self-consistency ( for non-frozen images only )
     !
     IF ( .NOT. frozen(image) ) THEN
        !
        tmp_dir = TRIM( tmp_dir_saved ) // TRIM( prefix ) // "_" // &
                  TRIM( int_to_char( image ) ) // "/"
        !
        tcpu = get_clock( 'PWSCF' )
        !
        IF ( nimage > 1 ) THEN
           !
           WRITE( UNIT = iunpath, FMT = scf_fmt_para ) my_image_id, tcpu, image
           !
        ELSE
           !
           WRITE( UNIT = iunpath, FMT = scf_fmt ) tcpu, image
           !
        END IF
        !
        CALL clean_pw( .TRUE. )
        !
        ! ... unit stdout is connected to the appropriate file
        !
        IF ( ionode ) THEN
           !  
           INQUIRE( UNIT = stdout, OPENED = opnd )
           IF ( opnd ) CLOSE( UNIT = stdout )
           OPEN( UNIT = stdout, FILE = TRIM( tmp_dir ) // 'PW.out', &
                 STATUS = 'UNKNOWN', POSITION = 'APPEND' )
           !
        END IF
        !
        IF ( .NOT. ALLOCATED( tau ) )      ALLOCATE( tau( 3, nat ) )
        IF ( .NOT. ALLOCATED( ityp ) )     ALLOCATE( ityp( nat ) )
        IF ( .NOT. ALLOCATED( force ) )    ALLOCATE( force( 3, nat ) )  
        IF ( .NOT. ALLOCATED( if_pos_ ) )  ALLOCATE( if_pos_( 3, nat ) )
        IF ( tefield .AND. .NOT. ALLOCATED( forcefield ) ) &
                                           ALLOCATE( forcefield( 3, nat ) )
        !
        ! ... tau is in alat units ( pos is in bohr )
        !
        tau = RESHAPE( SOURCE = pos(:,image), SHAPE = SHAPE( tau ) ) / alat
        !
        if_pos_(:,:) = if_pos(:,1:nat) 
        ityp(:)      = sp_pos(1:nat)
        !
        ! ... initialization of the scf calculation
        !
        CALL init_run()
        !
        IF ( ionode ) THEN 
           !     
           ! ... the file containing old positions is opened 
           ! ... ( needed for extrapolation )
           !
           CALL seqopn( iunupdate, TRIM( prefix ) // '.update', &
                        'FORMATTED', file_exists ) 
           !
           IF ( file_exists ) THEN
              !
              READ( UNIT = iunupdate, FMT = * ) history
              READ( UNIT = iunupdate, FMT = * ) tauold
              !
           ELSE
              !
              history = 0
              tauold  = 0.D0
              !
              WRITE( UNIT = iunupdate, FMT = * ) history
              WRITE( UNIT = iunupdate, FMT = * ) tauold
              !
           END IF
           !
           CLOSE( UNIT = iunupdate, STATUS = 'KEEP' )
           !
        END IF
        !
        CALL mp_bcast( history, ionode_id, intra_image_comm )
        CALL mp_bcast( tauold,  ionode_id, intra_image_comm )
        !
        IF ( conv_elec .AND. history > 0 ) THEN
           !
           ! ... potential and wavefunctions are extrapolated only if
           ! ... we are starting a new self-consistency (scf on the 
           ! ... previous image was achieved)
           !
           IF ( ionode ) THEN 
              !
              ! ... find the best coefficients for the extrapolation of 
              ! ... the potential
              !
              CALL find_alpha_and_beta( nat, tau, tauold, alpha0, beta0 )        
              !
           END IF
           !
           CALL mp_bcast( alpha0, ionode_id, intra_image_comm )
           CALL mp_bcast( beta0,  ionode_id, intra_image_comm )                
           !
           IF ( pot_order > 0 ) THEN
              !
              ! ... structure factors of the old positions are computed 
              ! ... (needed for the old atomic charge)
              !
              CALL struc_fact( nat, tauold(:,:,1), nsp, ityp, ngm, g, bg, &
                               nr1, nr2, nr3, strf, eigts1, eigts2, eigts3 )
              !
           END IF
           !
           CALL update_pot()
           !
        END IF
        !
        wg_set = .FALSE.
        !
        ! ... self-consistency loop
        !
        CALL electrons()
        !
        ! ... scf convergence is checked
        !
        IF ( .NOT. conv_elec ) THEN
           !   
           istat = 1
           !
           WRITE( UNIT = iunpath, &
                  FMT = '(/,5X,"WARNING :  scf convergence NOT achieved",/)' )
           !
           ! ... in case of parallelization on images a stop signal
           ! ... is sent via the "EXIT" file
           !
           IF ( nimage > 1 ) CALL stop_other_images()
           !
           EXIT scf_loop
           !
        END IF
        !
        ! ... self-consistent forces
        !
        CALL forces()
        !
        ! ... energy is converted from rydberg to hartree
        !
        pes(image) = etot / e2
        !
        ! ... gradients are converted from ( rydberg / bohr ) 
        ! ... to ( hartree / bohr )
        !
        grad_pes(:,image) = - RESHAPE( SOURCE = force, SHAPE = (/ dim /) ) / e2 
        !
        IF ( ionode ) THEN
           !
           ! ... save the previous two steps 
           ! ... ( a total of three ionic steps is saved )
           !
           tauold(:,:,3) = tauold(:,:,2)
           tauold(:,:,2) = tauold(:,:,1)
           tauold(:,:,1) = tau(:,:)              
           !
           history = MIN( 3, ( history + 1 ) )
           !
           CALL seqopn( iunupdate, &
                      & TRIM( prefix ) // '.update', 'FORMATTED', file_exists ) 
           !
           WRITE( UNIT = iunupdate, FMT = * ) history
           WRITE( UNIT = iunupdate, FMT = * ) tauold
           !
           CLOSE( UNIT = iunupdate, STATUS = 'KEEP' )
           !
        END IF
        !
        ! ... the save file is written ( if required )
        !
        IF ( write_save ) CALL punch()
        !
     END IF
     !
     ! ... the new image is obtained (by ionode only)
     !
     CALL get_new_image( image )
     !
     CALL mp_bcast( image, ionode_id, intra_image_comm )
     !        
     ! ... input values are restored at the end of each iteration ( they are
     ! ... modified in init_run )
     !
     startingpot_ = startingpot
     startingwfc_ = startingwfc
     !
     ethr = diago_thr_init
     !
     CALL close_files()
     !
     CALL reset_k_points()
     !
  END DO scf_loop
  !
  DEALLOCATE( tauold )
  !
  tmp_dir = tmp_dir_saved
  !
  IF ( nimage > 1 ) THEN
     !
     ! ... pes and grad_pes are communicated among "image" pools
     !
     CALL mp_sum( pes(N_in:N_fin),        inter_image_comm )
     CALL mp_sum( grad_pes(:,N_in:N_fin), inter_image_comm )
     CALL mp_sum( istat,                  inter_image_comm )
     !
  END IF
  !
  ! ... global status is computed here
  !
  IF ( istat == 0 ) THEN
     !
     stat = .TRUE.
     !
     suspended_image = 0
     !
  ELSE
     !
     stat = .FALSE.
     !
     IF ( nimage > 1 ) THEN
        !
        CALL mp_min( suspended_image, inter_image_comm )
        !
        OPEN(  UNIT = iunexit, FILE = TRIM( exit_file ) )
        CLOSE( UNIT = iunexit, STATUS = 'DELETE' )
        !
     END IF
     !
  END IF
  !
  ! ... after the first call to compute_scf the input values of startingpot
  ! ... and startingwfc are both set to 'file'
  !
  startingpot = 'file'
  startingwfc = 'file'
  startingpot_ = startingpot
  startingwfc_ = startingwfc
  !
  RETURN
  !
  CONTAINS
     !
     ! ... internal procedures
     !
     !-----------------------------------------------------------------------
     SUBROUTINE new_image_init()
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine initializes the file needed for the 
       ! ... parallelization among images
       !
       USE io_files,       ONLY : iunnewimage
       USE path_variables, ONLY : tune_load_balance
       !
       IMPLICIT NONE       
       !
       IF ( nimage == 1 .OR. .NOT. tune_load_balance ) RETURN
       !
       OPEN( UNIT = iunnewimage, FILE = TRIM( tmp_dir_saved ) // &
           & TRIM( prefix ) // '.newimage' , STATUS = 'UNKNOWN' )
       !
       WRITE( iunnewimage, * ) N_in + nimage
       ! 
       CLOSE( UNIT = iunnewimage, STATUS = 'KEEP' )       
       !
       RETURN
       !
     END SUBROUTINE new_image_init
     !
     !-----------------------------------------------------------------------
     SUBROUTINE get_new_image( image )
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine is used to get the new image to work on
       ! ... the "prefix.BLOCK" file is needed to avoid (when present) that 
       ! ... other jobs try to read/write on file "prefix.newimage" 
       !
       USE io_files,       ONLY : iunnewimage, iunblock
       USE io_global,      ONLY : ionode
       USE path_variables, ONLY : tune_load_balance
       !
       IMPLICIT NONE
       !
       INTEGER, INTENT(INOUT) :: image
       INTEGER                :: ioerr
       CHARACTER (LEN=256)    :: filename
       LOGICAL                :: opened, exists
       !
       !
       IF ( .NOT. ionode ) RETURN
       !
       IF ( nimage > 1 ) THEN
          !
          IF ( tune_load_balance ) THEN
             !
             filename = TRIM( tmp_dir_saved ) // TRIM( prefix ) // '.BLOCK'
             !
             open_loop: DO
                !          
                OPEN( UNIT = iunblock, FILE = TRIM( filename ), &
                    & IOSTAT = ioerr, STATUS = 'NEW' )
                !
                IF ( ioerr > 0 ) CYCLE open_loop
                !
                INQUIRE( UNIT = iunnewimage, OPENED = opened )
                !
                IF ( .NOT. opened ) THEN
                   !
                   OPEN( UNIT = iunnewimage, FILE = TRIM( tmp_dir_saved ) // &
                       & TRIM( prefix ) // '.newimage' , STATUS = 'OLD' )
                   !
                   READ( iunnewimage, * ) image
                   !
                   CLOSE( UNIT = iunnewimage, STATUS = 'DELETE' )
                   !
                   OPEN( UNIT = iunnewimage, FILE = TRIM( tmp_dir_saved ) // &
                       & TRIM( prefix ) // '.newimage' , STATUS = 'NEW' )
                   !
                   WRITE( iunnewimage, * ) image + 1
                   ! 
                   CLOSE( UNIT = iunnewimage, STATUS = 'KEEP' )
                   !
                   EXIT open_loop
                   !
                END IF
                !
             END DO open_loop
             !
             CLOSE( UNIT = iunblock, STATUS = 'DELETE' )
             !
          ELSE
             !
             image = image + nimage
             !
          END IF
          !
       ELSE
          !
          image = image + 1
          !
       END IF      
       !
       RETURN
       !
     END SUBROUTINE get_new_image
     !
     !-----------------------------------------------------------------------
     SUBROUTINE stop_other_images()
       !-----------------------------------------------------------------------
       !
       ! ... this subroutine is used to send a stop signal to other images
       ! ... this is done by creating the exit_file on the working directory
       !
       USE io_files,  ONLY : iunexit, exit_file
       USE io_global, ONLY : ionode
       !
       IMPLICIT NONE
       !
       !
       IF ( .NOT. ionode ) RETURN
       !
       OPEN( UNIT = iunexit, FILE = TRIM( exit_file ) )
       CLOSE( UNIT = iunexit, STATUS = 'KEEP' )               
       !
       RETURN       
       !
     END SUBROUTINE stop_other_images
     !
END SUBROUTINE compute_scf
