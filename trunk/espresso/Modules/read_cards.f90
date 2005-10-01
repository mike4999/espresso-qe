!
! Copyright (C) 2002-2003 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!---------------------------------------------------------------------------
MODULE read_cards_module
  !---------------------------------------------------------------------------
  !
  ! ...  This module handles the reading of cards from standard input
  ! ...  Written by Carlo Cavazzoni and modified for "path" implementation
  ! ...  by Carlo Sbraccia
  !
  USE kinds
  USE io_global,         ONLY: stdout 
  USE constants,         ONLY: angstrom_au
  USE parser,            ONLY: field_count, read_line
  USE mp_global,         ONLY: mpime, nproc, group
  USE io_global,         ONLY: ionode, ionode_id
  USE mp,                ONLY: mp_bcast
  !
  USE input_parameters
  !
  IMPLICIT NONE
  !
  SAVE
  !
  PRIVATE
  !
  PUBLIC :: read_cards
  !
  ! ... end of module-scope declarations
  !
  !  ----------------------------------------------
  !
  CONTAINS
     !
     ! ... Read CARDS ....
     !
     ! ... subroutines
     !
     !----------------------------------------------------------------------
     SUBROUTINE card_default_values( prog )
       !----------------------------------------------------------------------
       !
       USE autopilot, ONLY : init_autopilot
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog
       !
       !
       ! ... f_inp is a temporary array to store the occupation numbers
       f_inp = 0.d0   
       ! ... mask that control the printing of selected Kohn-Sham occupied orbitals
       tprnks = .FALSE.       
       ks_path = ' '
       ! ... mask that control the printing of selected Kohn-Sham unoccupied orbitals
       tprnks_empty = .FALSE.
       ! ... Simulation cell from standard input
       trd_ht = .FALSE.
       rd_ht  = 0.0d0
       ! ... DIPOLE
       tdipole_card     = .FALSE.
       ! ... OPTICAL PROPERTIES
       toptical_card    = .FALSE.
       noptical    = 0
       woptical    = 0.1
       boptical    = 0.0
       ! ... Constraints
       nconstr_inp      = 0
       constr_tol_inp   = 0.0d0
       ! ... ionic mass initialization
       atom_mass = 0.0d0
       ! ... dimension of the real space Ewald summation
       iesr_inp = 1
       ! ... KPOINTS
       k_points = 'gamma'
       tk_inp = .FALSE.
       nkstot = 1
       nk1 = 0
       nk2 = 0
       nk3 = 0
       k1 = 0
       k2 = 0
       k3 = 0
       ! ... NEIGHBOURS
       tneighbo   =  .FALSE.
       neighbo_radius =  0.d0
       ! ... Turbo
       tturbo_inp = .FALSE.
       nturbo_inp = 0
       ! ... Grids
       t2dpegrid_inp  = .FALSE.
       ! ... Electronic states
       tf_inp = .false.
       ! ... Hartree planar mean
       tvhmean_inp = .false.
       vhnr_inp    = 0
       vhiunit_inp = 0
       vhrmin_inp  = 0.0d0
       vhrmax_inp  = 0.0d0
       vhasse_inp  = 'K'
       ! ... TCHI
       tchi2_inp  = .FALSE.
       ! ... ION_VELOCITIES
       tavel = .FALSE.
       ! ... SETNFI
       newnfi_card = -1
       tnewnfi_card = .FALSE.
       !
       CALL init_autopilot()
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !----------------------------------------------------------------------
     SUBROUTINE read_cards( prog )
       !----------------------------------------------------------------------
       !
       USE autopilot, ONLY : card_autopilot
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)           :: prog   ! calling program ( FP, PW, CP )
       CHARACTER(LEN=256)         :: input_line
       CHARACTER(LEN=80)          :: card
       CHARACTER(LEN=1), EXTERNAL :: capital
       LOGICAL                    :: tend
       INTEGER                    :: i
       !
       !
       CALL card_default_values( prog )
       !
 100   CALL read_line( input_line, end_of_file=tend )
       !
       IF( tend ) GO TO 120
       IF( input_line == ' ' .OR. input_line(1:1) == '#' ) GO TO 100
       !
       READ (input_line, *) card
       !
       DO i = 1, LEN_TRIM( input_line )
          input_line( i : i ) = capital( input_line( i : i ) )
       END DO
       !
       IF ( TRIM(card) == 'AUTOPILOT' ) THEN
          !
          CALL card_autopilot( input_line )
          !
       ELSE IF ( TRIM(card) == 'ATOMIC_SPECIES' ) THEN
          !
          CALL card_atomic_species( input_line, prog )
          !
       ELSE IF ( TRIM(card) == 'ATOMIC_POSITIONS' ) THEN
          !
          CALL card_atomic_positions( input_line, prog )
          !
       ELSE IF ( TRIM(card) == 'SETNFI' ) THEN
          !
          CALL card_setnfi( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'OPTICAL' ) THEN
          !  
          CALL card_optical( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'CONSTRAINTS' ) THEN
          !
          CALL card_constraints( input_line )
          !
       ELSE IF ( TRIM(card) == 'VHMEAN' ) THEN
          !
          CALL card_vhmean( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'DIPOLE' ) THEN
          !
          CALL card_dipole( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'ESR' ) THEN
          !
          CALL card_esr( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'K_POINTS' ) THEN
          !
          CALL card_kpoints( input_line )
          !
       ELSE IF ( TRIM(card) == 'NEIGHBOURS' ) THEN
          !
          CALL card_neighbours( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'OCCUPATIONS' ) THEN
          !
          CALL card_occupations( input_line )
          !
       ELSE IF ( TRIM(card) == 'CELL_PARAMETERS' ) THEN
          !
          CALL card_cell_parameters( input_line )
          !
       ELSE IF ( TRIM(card) == 'TURBO' ) THEN
          !
          CALL card_turbo( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'ATOMIC_VELOCITIES' ) THEN
          !
          CALL card_ion_velocities( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'KSOUT' ) THEN
          !
          CALL card_ksout( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(a)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'KSOUT_EMPTY' ) THEN
          !
          CALL card_ksout_empty( input_line )
          IF ( ( prog == 'PW' .OR. prog == 'CP' ) .AND. ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//trim(input_line)//' ignored'
          !
       ELSE IF ( TRIM(card) == 'CLIMBING_IMAGES' ) THEN
          !
          CALL card_climbing_images( input_line )

       ELSE IF ( TRIM(card) == 'PLOT_WANNIER' ) THEN
          !
          CALL card_plot_wannier( input_line )

       ELSE
          !
          IF ( ionode ) &
             WRITE( stdout,'(A)') 'Warning: card '//TRIM(input_line)//' ignored'
          !
       END IF
       !
       ! ...     END OF LOOP ... !
       !   
       GOTO 100
       !
120    CONTINUE
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     ! ... Description of the allowed input CARDS for FPMD code
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! ATOMIC_SPECIES
     !
     !   set the atomic species been read and their pseudopotential file
     !
     ! Syntax:
     !
     !    ATOMIC_SPECIE
     !      label(1)    mass(1)    psfile(1)
     !       ...        ...        ...
     !      label(n)    mass(n)    psfile(n)
     !
     ! Example:
     !
     ! ATOMIC_SPECIES
     !  O 16.0d0 O.BLYP.UPF
     !  H 1.00d0 H.fpmd.UPF
     !
     ! Where:
     !
     !      label(i)  ( character(len=4) )  label of the atomic species 
     !      mass(i)   ( real )              atomic mass 
     !                                      ( in u.m.a, carbon mass is 12.0 )
     !      psfile(i) ( character(len=80) ) file name of the pseudopotential
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_atomic_species( input_line, prog )
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       CHARACTER(LEN=2)   :: prog
       INTEGER            :: is, ip
       CHARACTER(LEN=4)   :: lb_pos
       CHARACTER(LEN=256) :: psfile
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_atomic_species  ', ' two occurrence ', 2 )
       END IF
       IF ( ntyp > nsx ) THEN
         CALL errore( ' card_atomic_species ', ' nsp out of range ', ntyp )
       END IF
       !
       DO is = 1, ntyp
          !
          CALL read_line( input_line )
          READ( input_line, * ) lb_pos, atom_mass(is), psfile
          atom_pfile(is) = TRIM( psfile )
          lb_pos         = ADJUSTL( lb_pos )
          atom_label(is) = TRIM( lb_pos )
          !
          IF ( atom_mass(is) <= 0.D0 ) THEN
             CALL errore( ' card_atomic_species ',' invalid  atom_mass ', is )
          END IF
          DO ip = 1, is - 1
             IF ( atom_label(ip) == atom_label(is) ) THEN
                CALL errore( ' card_atomic_species ', &
                           & ' two occurrences of the same atomic label ', is )
             END IF
          END DO
          !
       END DO
       taspc = .TRUE.
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! ATOMIC_POSITIONS
     !
     !   set the atomic positions in the cell
     !
     ! Syntax:
     !
     !   ATOMIC_POSITIONS (units_option)
     !     label(1) tau(1,1) tau(2,1) tau(3,1) mbl(1,1) mbl(2,1) mbl(3,1)
     !     label(2) tau(1,2) tau(2,2) tau(3,2) mbl(1,2) mbl(2,2) mbl(3,2)
     !      ...              ...               ...               ... ...
     !     label(n) tau(1,n) tau(2,n) tau(3,n) mbl(1,3) mbl(2,3) mbl(3,3)
     !
     ! Example:
     !
     ! ATOMIC_POSITIONS (bohr)
     !    O     0.0099    0.0099    0.0000  0 0 0
     !    H     1.8325   -0.2243   -0.0001  1 1 1
     !    H    -0.2243    1.8325    0.0002  1 1 1
     !  
     ! Where:
     !
     !   units_option == crystal   position are given in scaled units
     !   units_option == bohr      position are given in Bohr
     !   units_option == angstrom  position are given in Angstrom
     !   units_option == alat      position are given in units of alat
     !
     !   label(k) ( character(len=4) )  atomic type
     !   tau(:,k) ( real )              coordinates  of the k-th atom
     !   mbl(:,k) ( integer )           mbl(i,k) > 0 the i-th coord. of the 
     !                                  k-th atom is allowed to be moved
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     ! ... routine modified for NEB           ( C.S. 21/10/2003 )
     ! ... routine modified for SMD           ( Y.K. 15/04/2004 )
     ! ... updated manual not yet available
     !
     SUBROUTINE card_atomic_positions( input_line, prog )
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       CHARACTER(LEN=2)   :: prog
       CHARACTER(LEN=4)   :: lb_pos
       INTEGER            :: ia, i, k, is, nfield, index, rep_i
       LOGICAL, EXTERNAL  :: matches
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( full_phs_path_flag ) THEN
          !
          ALLOCATE( pos( 3*natx, num_of_images ) )
          !
          pos = 0.D0
          !
       END IF
       !
       IF ( tread ) THEN
          CALL errore( ' card_atomic_positions  ', ' two occurrence ', 2 )
       END IF
       IF ( .NOT. taspc ) THEN
          CALL errore( ' card_atomic_positions  ', &
                     & ' ATOMIC_SPECIES must be present before ', 2 )
       END IF
       IF ( ntyp > nsx ) THEN
          CALL errore(' card_atomic_positions ', ' nsp out of range ', ntyp )
       END IF
       IF ( nat > natx ) THEN
          CALL errore(' card_atomic_positions ', ' nat out of range ', nat )
       END IF
       !
       if_pos = 1
       !
       sp_pos = 0
       rd_pos = 0.D0
       na_inp = 0
       !
       IF ( matches( "CRYSTAL", input_line ) ) THEN
          atomic_positions = 'crystal'
       ELSE IF ( matches( "BOHR", input_line ) ) THEN
          atomic_positions = 'bohr'
       ELSE IF ( matches( "ANGSTROM", input_line ) ) THEN
          atomic_positions = 'angstrom'
       ELSE IF ( matches( "ALAT", input_line ) ) THEN
          atomic_positions = 'alat'
       ELSE
          IF ( TRIM( ADJUSTL( input_line ) ) /= 'ATOMIC_POSITIONS' ) THEN
             CALL errore( ' read_cards ', &
                        & ' unknow unit option for ATOMIC_POSITION: '&
                        & //input_line, 1 )
          END IF
          IF ( prog == 'FP' ) atomic_positions = 'bohr'
          IF ( prog == 'CP' ) atomic_positions = 'bohr'
          IF ( prog == 'PW' ) atomic_positions = 'alat'
       END IF
       !
       IF ( calculation == 'smd' .AND. prog == 'CP' ) THEN
          !
          rep_loop : DO rep_i = 1, smd_kwnp
             !
             CALL read_line( input_line )
             !
             IF ( matches( "first_image", input_line ) .OR. &
                  matches( "image", input_line )       .OR. &
                  matches( "last_image", input_line) ) THEN
                !
                CALL path_read_images( rep_i )
                !
             ELSE
                CALL errore( ' read_cards ', ' missing or wrong image' // &
                           & ' identifier in ATOMIC_POSITION', 1 )
             ENDIF
             !
          END DO rep_loop
          !
       ELSE IF ( full_phs_path_flag ) THEN
          !
          CALL read_line( input_line )
          !
          IF ( matches( "first_image", input_line ) ) THEN
             !                
             input_images = 1
             !
             CALL path_read_images( input_images )
             !
          ELSE
             !
             CALL errore( ' read_cards ', &
                        & ' first_image missing in ATOMIC_POSITION', 1 )
             !
          END IF      
          !
          read_conf_loop: DO 
             !
             CALL read_line( input_line )
             !
             input_images = input_images + 1             
             !
             IF ( input_images > num_of_images ) &
                CALL errore( ' read_cards ', &
                           & ' too many images in ATOMIC_POSITION', 1 )
             !
             IF ( matches( "intermediate_image", input_line )  ) THEN
                !
                CALL path_read_images( input_images )
                !
             ELSE
                !
                EXIT read_conf_loop
                !
             END IF
             !
          END DO read_conf_loop
          !
          IF ( matches( "last_image", input_line ) ) THEN
             !
             CALL path_read_images( input_images )
             !
          ELSE
             !
             CALL errore( ' read_cards ', &
                        & ' last_image missing in ATOMIC_POSITION', 1 )
             !
          END IF
          !
       ELSE
          !
          DO ia = 1, nat
             !
             CALL read_line( input_line )
             CALL field_count( nfield, input_line )
             !
             IF( sic /= 'none' .AND. nfield /= 8 ) &
               CALL errore(' read_cards ', ' ATOMIC_POSITIONS with sic, 8 columns required ', 1 )
             !
             IF ( nfield == 4 ) THEN
                !     
                READ(input_line,*) lb_pos, ( rd_pos(k,ia), k = 1, 3 )
                !
             ELSE IF ( nfield == 7 ) THEN
                !     
                READ(input_line,*) lb_pos, rd_pos(1,ia), &
                                           rd_pos(2,ia), &
                                           rd_pos(3,ia), &
                                           if_pos(1,ia), &
                                           if_pos(2,ia), &
                                           if_pos(3,ia)
                ! 
             ELSE IF ( nfield == 8 ) THEN
                !
                READ(input_line,*) lb_pos, rd_pos(1,ia), &
                                           rd_pos(2,ia), &
                                           rd_pos(3,ia), &
                                           if_pos(1,ia), &
                                           if_pos(2,ia), &
                                           if_pos(3,ia), &
                                           id_loc(ia)
                !
             ELSE
                !
                CALL errore( ' read_cards ', ' wrong number of columns ' // &
                           & ' in ATOMIC_POSITIONS ', sp_pos(ia) )
                !           
             END IF
             !
             lb_pos = ADJUSTL( lb_pos )
             !
             match_label: DO is = 1, ntyp
                !
                IF ( TRIM(lb_pos) == TRIM( atom_label(is) ) ) THEN
                   !
                   sp_pos(ia) = is
                   EXIT match_label
                   !
                END IF
                !
             END DO match_label
             !
             IF( ( sp_pos(ia) < 1 ) .OR. ( sp_pos(ia) > ntyp ) ) THEN
                !
                CALL errore( ' read_cards ', &
                           & ' wrong index in ATOMIC_POSITIONS ', ia )
                !           
             END IF
             !
             is  =  sp_pos(ia)
             na_inp( is ) = na_inp( is ) + 1
             !
          END DO
          !
       END IF      
       !
       tapos = .TRUE.
       tread = .TRUE.
       !
       RETURN
       !
       CONTAINS
         !
         !-------------------------------------------------------------------
         SUBROUTINE path_read_images( image )
           !-------------------------------------------------------------------
           !
           IMPLICIT NONE
           !
           INTEGER, INTENT(IN) :: image
           !
           !
           DO ia = 1, nat
              !
              index = 3 * ( ia - 1 )
              !
              CALL read_line( input_line )
              CALL field_count( nfield, input_line )
              !
              IF ( nfield == 4 ) THEN
                 !
                 READ( input_line, * ) lb_pos, pos((index+1),image), &
                                               pos((index+2),image), &
                                               pos((index+3),image)
                 !
              ELSE IF ( nfield == 7 ) THEN
                 !
                 IF ( image /= 1 ) THEN
                    !
                    CALL errore( ' read_cards ', &
                               & ' wrong number of columns  in' // &
                               & ' ATOMIC_POSITIONS', sp_pos(ia) )                    
                    !
                 END IF
                 !
                 READ( input_line, * ) lb_pos, pos((index+1),image), &
                                               pos((index+2),image), &
                                               pos((index+3),image), &
                                               if_pos(1,ia), &
                                               if_pos(2,ia), &
                                               if_pos(3,ia)
                 !
              ELSE
                 ! 
                 CALL errore( ' read_cards ', &
                            & ' wrong number of columns  in' // &
                            & ' ATOMIC_POSITIONS', sp_pos(ia) )
                 !           
              END IF
              !
              IF ( image == 1 ) THEN
                 !
                 lb_pos = ADJUSTL( lb_pos )
                 !
                 match_label_path: DO is = 1, ntyp
                    !
                    IF ( TRIM( lb_pos ) == TRIM( atom_label(is) ) ) THEN
                       !
                       sp_pos(ia) = is
                       !
                       EXIT match_label_path
                       !
                    END IF
                    !
                 END DO match_label_path
                 !
                 IF ( ( sp_pos(ia) < 1 ) .OR. ( sp_pos(ia) > ntyp ) ) THEN
                    !     
                    CALL errore( ' read_cards ', &
                               & ' wrong index in ATOMIC_POSITIONS ', ia )
                    !    
                 END IF
                 !
                 is = sp_pos(ia)
                 !
                 na_inp( is ) = na_inp( is ) + 1
                 !
              END IF     
              !
           END DO
           !
           RETURN
           !
         END SUBROUTINE path_read_images
         !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! K_POINTS
     !
     !   use the specified set of k points
     !
     ! Syntax:
     !
     !   K_POINTS (mesh_option)
     !     n
     !     xk(1,1) xk(2,1) xk(3,1) wk(1)
     !     ...     ...     ...     ...
     !     xk(1,n) xk(2,n) xk(3,n) wk(n)
     !
     ! Example:
     !
     ! K_POINTS
     !   10
     !    0.1250000  0.1250000  0.1250000   1.00
     !    0.1250000  0.1250000  0.3750000   3.00
     !    0.1250000  0.1250000  0.6250000   3.00
     !    0.1250000  0.1250000  0.8750000   3.00
     !    0.1250000  0.3750000  0.3750000   3.00
     !    0.1250000  0.3750000  0.6250000   6.00
     !    0.1250000  0.3750000  0.8750000   6.00
     !    0.1250000  0.6250000  0.6250000   3.00
     !    0.3750000  0.3750000  0.3750000   1.00
     !    0.3750000  0.3750000  0.6250000   3.00
     !
     ! Where:
     !
     !   mesh_option == automatic  k points mesh is generated automatically
     !                             with Monkhorst-Pack algorithm
     !   mesh_option == crystal    k points mesh is given in stdin in scaled 
     !                             units
     !   mesh_option == tpiba      k points mesh is given in stdin in units 
     !                             of ( 2 PI / alat )
     !   mesh_option == gamma      only gamma point is used ( default in 
     !                             CPMD simulation )
     !
     !   n       ( integer )  number of k points
     !   xk(:,i) ( real )     coordinates of i-th k point
     !   wk(i)   ( real )     weights of i-th k point
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_kpoints( input_line )
       ! 
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       INTEGER            :: i
       LOGICAL, EXTERNAL  :: matches
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_kpoints ', ' two occurrence ', 2 )
       END IF
       !
       IF ( matches( "AUTOMATIC", input_line ) ) THEN
          !  automatic generation of k-points
          k_points = 'automatic'
       ELSE IF ( matches( "CRYSTAL", input_line ) ) THEN
          !  input k-points are in crystal (reciprocal lattice) axis
          k_points = 'crystal'
       ELSE IF ( matches( "TPIBA", input_line ) ) THEN
          !  input k-points are in 2pi/a units
          k_points = 'tpiba'
       ELSE IF ( matches( "GAMMA", input_line ) ) THEN
          !  Only Gamma (k=0) is used
          k_points = 'gamma'
       ELSE
          !  by default, input k-points are in 2pi/a units
          k_points = 'tpiba'
       END IF
       !
       IF ( k_points == 'automatic' ) THEN
          !
          ! ... automatic generation of k-points
          !
          nkstot = 0
          CALL read_line( input_line )
          READ(input_line, *) nk1, nk2, nk3, k1, k2 ,k3
          IF ( k1 < 0 .OR. k1 > 1 .OR. &
               k2 < 0 .OR. k2 > 1 .OR. &
               k3 < 0 .OR. k3 > 1 ) CALL errore &
                  ('card_kpoints', 'invalid offsets: must be 0 or 1', 1)
          IF ( nk1 <= 0 .OR. nk2 <= 0 .OR. nk3 <= 0 ) CALL errore &
                  ('card_kpoints', 'invalid values for nk1, nk2, nk3', 1)

          !
       ELSE IF ( ( k_points == 'tpiba' ) .OR. ( k_points == 'crystal' ) ) THEN
          !
          ! ... input k-points are in 2pi/a units
          !
          CALL read_line( input_line )
          READ(input_line, *) nkstot
          !
          DO i = 1, nkstot
             CALL read_line( input_line )
             READ(input_line,*) xk(1,i), xk(2,i), xk(3,i), wk(i)
          END DO
          !
       ELSE IF ( k_points == 'gamma' ) THEN
          !
          nkstot = 1
          xk(:,1) = 0.0D0
          wk(1) = 1.0D0
          !
       END IF
       !
       tread  = .TRUE.
       tk_inp = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! SETNFI
     !
     !   Reset the step counter to the specified value
     !
     ! Syntax:
     !
     !  SETNFI
     !     nfi
     !
     ! Example:
     !
     !  SETNFI
     !     100
     !
     ! Where:
     !
     !    nfi (integer) new value for the step counter
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_setnfi( input_line )
       ! 
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_setnfi ', ' two occurrence ', 2 )
       END IF
       CALL read_line( input_line )
       READ(input_line,*) newnfi_card
       tnewnfi_card = .TRUE.
       tread = .TRUE.
       ! 
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! 2DPROCMESH
     !
     !   Distribute the Y and Z FFT dimensions across processors, 
     !   instead of Z dimension only ( default distribution )
     !
     ! Syntax:
     !
     !    2DPROCMESH
     !
     ! Where:
     !
     !    no parameters
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! OCCUPATIONS
     !
     !   use the specified occupation numbers for electronic states.
     !   Note that you should specify 10 values per line maximum!
     !
     ! Syntax (nspin == 1):
     !
     !   OCCUPATIONS
     !      f(1)  ....   ....  f(10) 
     !      f(11) .... f(nbnd)
     !
     ! Syntax (nspin == 2):
     !
     !   OCCUPATIONS
     !      u(1)  ....   ....  u(10) 
     !      u(11) .... u(nbnd)
     !      d(1)  ....   ....  d(10)
     !      d(11) .... d(nbnd)
     !
     ! Example:
     !
     ! OCCUPATIONS
     !  2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
     !  2.0 2.0 2.0 2.0 2.0 1.0 1.0 
     !
     ! Where:
     !
     !      f(:) (real)  these are the occupation numbers 
     !                   for LDA electronic states. 
     !
     !      u(:) (real)  these are the occupation numbers
     !                   for LSD spin == 1 electronic states 
     !      d(:) (real)  these are the occupation numbers
     !                   for LSD spin == 2 electronic states 
     !
     !      Note, maximum 10 values per line!
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_occupations( input_line )
       !
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       INTEGER            :: is, nx10, i, j, nspin0
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_occupations ', ' two occurrence ', 2 )
       END IF
       nspin0=nspin
       if (nspin == 4) nspin0=1
       !
       DO is = 1, nspin0
          !
          nx10 = 10 * INT( nbnd / 10 )
          DO i = 1, nx10, 10
             CALL read_line( input_line )
             READ(input_line,*) ( f_inp(j,is), j = i, ( i + 9 ) )
          END DO
          IF ( MOD( nbnd, 10 ) > 0 ) THEN
             CALL read_line( input_line )
             READ(input_line,*) ( f_inp(j,is), j = ( nx10 + 1 ), nbnd)
          END IF
          !
       END DO
       !
       tf_inp = .TRUE. 
       tread = .TRUE.
       ! 
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! VHMEAN
     !
     !   Calculation of potential average along a given axis
     !
     ! Syntax:
     !
     !   VHMEAN
     !   unit nr rmin rmax asse
     !
     ! Example:
     !
     !   ????
     !
     ! Where:
     !
     !   ????
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_vhmean( input_line )
       ! 
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_vhmean ', ' two occurrence ', 2 )
       END IF
       !  
       tvhmean_inp = .TRUE.
       CALL read_line( input_line )
       READ(input_line,*) &
           vhiunit_inp, vhnr_inp, vhrmin_inp, vhrmax_inp, vhasse_inp
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! OPTICAL
     !
     !  Enable the calculations of optical properties
     !
     ! Syntax:
     !
     !    OPTICAL
     !      woptical noptical boptical
     !
     ! Example:
     !
     !   ???
     !
     ! Where:
     !
     !   woptical (REAL)     frequency maximum in eV
     !   noptical (INTEGER)  number of intervals
     !   boptical (REAL)     electronic temperature (in K)
     !                       to calculate the fermi distribution function
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_optical( input_line )
       ! 
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore(' card_optical ', ' two occurrence ', 2 )
       END IF
       IF ( empty_states_nbnd < 1 ) THEN
          CALL errore( ' card_optical ', &
                     & ' empty states are not computed ', 2 )
       END IF
       toptical_card = .TRUE.
       CALL read_line( input_line )
       READ(input_line, *) woptical, noptical, boptical
       !
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! DIPOLE
     !
     !   calculate polarizability
     !
     ! Syntax:
     !
     !   DIPOLE
     !
     ! Where:
     !
     !    no parameters
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_dipole( input_line )
       ! 
       IMPLICIT NONE
       !
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_dipole ', ' two occurrence ', 2 )
       END IF
       !
       tdipole_card = .TRUE.
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! IESR
     !
     !   use the specified number of neighbour cells for Ewald summations
     !
     ! Syntax:
     !
     !   ESR
     !    iesr
     !
     ! Example:
     !
     !   ESR
     !    3
     !
     ! Where:
     !
     !      iesr (integer)  determines the number of neighbour cells to be
     !                      considered:
     !                        iesr = 1 : nearest-neighbour cells (default)
     !                        iesr = 2 : next-to-nearest-neighbour cells
     !                        and so on
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_esr( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       ! 
       IF ( tread ) THEN
          CALL errore( ' card_esr ', ' two occurrence ', 2 )
       END IF
       CALL read_line( input_line )
       READ(input_line,*) iesr_inp
       !
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! NEIGHBOURS
     !
     !   calculate the neighbours of (and the disance from) each atoms below 
     !   the distance specified by the parameter
     !
     ! Syntax:
     !
     !   NEIGHBOURS
     !      cut_radius
     !
     ! Example:
     !
     !   NEIGHBOURS
     !      4.0
     !
     ! Where:
     !
     !      cut_radius ( real )  radius of the region where atoms are 
     !                           considered as neighbours ( in a.u. )
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_neighbours( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       ! 
       !
       IF ( tread ) THEN
          CALL errore( ' card_neighbours ', ' two occurrence ', 2 )
       END IF
       ! 
       CALL read_line( input_line )
       READ(input_line, *) neighbo_radius
       ! 
       tneighbo = .TRUE.
       tread = .TRUE.
       ! 
       RETURN
       !
     END SUBROUTINE
     !
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! CELL_PARAMETERS
     !
     !   use the specified cell dimensions
     !
     ! Syntax:
     !
     !    CELL_PARAMETERS
     !      HT(1,1) HT(1,2) HT(1,3)
     !      HT(2,1) HT(2,2) HT(2,3)
     !      HT(3,1) HT(3,2) HT(3,3)
     !
     ! Example:
     !
     ! CELL_PARAMETERS
     !    24.50644311    0.00004215   -0.14717844
     !    -0.00211522    8.12850030    1.70624903
     !     0.16447787    0.74511792   23.07395418
     !
     ! Where:
     !
     !      HT(i,j) (real)  cell dimensions ( in a.u. ), 
     !                      note the relation with lattice vectors: 
     !                      HT(1,:) = A1, HT(2,:) = A2, HT(3,:) = A3 
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_cell_parameters( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       INTEGER            :: i, j
       LOGICAL, EXTERNAL  :: matches
       LOGICAL, SAVE      :: tread = .FALSE.
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_cell_parameters ', ' two occurrence ', 2 )
       END IF
       !
       IF ( matches( 'HEXAGONAL', input_line ) ) then
          cell_symmetry = 'hexagonal'
       ELSE
          cell_symmetry = 'cubic'
       END IF
       !
       IF ( matches( "BOHR", input_line ) ) THEN
          cell_units = 'bohr'
       ELSE IF ( matches( "ANGSTROM", input_line ) ) THEN
          cell_units = 'angstrom'
       ELSE
          cell_units = 'alat'
       END IF
       !
       DO i = 1, 3
          CALL read_line( input_line )
          READ(input_line,*) ( rd_ht( i, j ), j = 1, 3 )
       END DO
       ! 
       trd_ht = .TRUE.
       tread  = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! TURBO
     !
     !   allocate space to store electronic states in real space while 
     !   computing charge density, and then reuse the stored state
     !   in the calculation of forces instead of repeating the FFT
     !
     ! Syntax:
     !
     !    TURBO
     !      nturbo
     !
     ! Example:
     !
     !    TURBO
     !      64
     !
     ! Where:
     !
     !      nturbo (integer)  number of states to be stored
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_turbo( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       ! 
       !
       IF ( tread ) THEN
          CALL errore( ' card_turbo ', ' two occurrence ', 2 )
       END IF
       !
       CALL read_line( input_line )
       READ(input_line,*) nturbo_inp
       ! 
       IF( (nturbo_inp < 0) .OR. (nturbo_inp > (nbnd/2)) ) THEN
          CALL errore( ' card_turbo ', ' NTURBO OUT OF RANGE ', nturbo_inp )
       END IF
       !
       tturbo_inp = .TRUE.
       tread = .TRUE.
       ! 
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! ATOMIC_VELOCITIES
     !
     !   read velocities (in atomic units) from standard input
     !
     ! Syntax:
     !
     !   ATOMIC_VELOCITIES
     !     label(1)  Vx(1) Vy(1) Vz(1)
     !     ....
     !     label(n)  Vx(n) Vy(n) Vz(n)
     !
     ! Example:
     !
     !   ???
     !
     ! Where:
     !
     !   label (character(len=4))       atomic label
     !   Vx(:), Vy(:) and Vz(:) (REAL)  x, y and z velocity components of
     !                                  the ions
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_ion_velocities( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       INTEGER            :: ia, k, is, nfield
       LOGICAL, SAVE      :: tread = .FALSE.
       CHARACTER(LEN=4)   :: lb_vel
       !
       !
       IF( tread ) THEN
          CALL errore( ' card_ion_velocities ', ' two occurrence ', 2 )
       END IF
       !
       IF( .NOT. taspc ) THEN
          CALL errore( ' card_ion_velocities ', &
                     & ' ATOMIC_SPECIES must be present before ', 2 )
       END IF
       !
       rd_vel = 0.d0
       sp_vel = 0
       !
       IF ( ion_velocities == 'from_input' ) THEN
          !
          tavel = .TRUE.
          !
          DO ia = 1, nat
             !
             CALL read_line( input_line )
             CALL field_count( nfield, input_line )
             IF ( nfield == 4 ) THEN
                READ(input_line,*) lb_vel, ( rd_vel(k,ia), k = 1, 3 )
             ELSE
                CALL errore( ' iosys ', &
                           & ' wrong entries in ION_VELOCITIES ', ia )
             END IF
             !
             match_label: DO is = 1, ntyp
                IF ( TRIM( lb_vel ) == atom_label(is) ) THEN
                   sp_vel(ia) = is
                   EXIT match_label
                END IF
             END DO match_label
             !
             IF ( sp_vel(ia) < 1 .OR. sp_vel(ia) > ntyp ) THEN
                CALL errore( ' iosys ', ' wrong LABEL in ION_VELOCITIES ', ia )
             END IF
             !
          END DO
          !
       END IF
       !
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     ! CONSTRAINTS
     !
     !   Ionic Constraints
     !
     ! Syntax:
     !
     !    CONSTRAINTS
     !      NCONSTR CONSTR_TOL
     !      CONSTR_TYPE(.) CONSTR(1,.) CONSTR(2,.) ... { CONSTR_TARGET(.) }
     !
     ! Example:
     !
     !    ????
     !
     ! Where:
     !
     !      NCONSTR(INTEGER)    number of constraints
     !
     !      CONSTR_TOL          tolerance for keeping the constraints 
     !                          satisfied
     !
     !      CONSTR_TYPE(.)      type of constrain: 
     !                          1: for fixed distances ( two atom indexes must
     !                             be specified )
     !                          2: for fixed planar angles ( three atom indexes
     !                             must be specified )
     !      
     !      CONSTR(1,.) CONSTR(2,.) ...
     !     
     !                          indices object of the constraint, as 
     !                          they appear in the 'POSITION' CARD
     !
     !      CONSTR_TARGET       target for the constrain ( in the case of 
     !                          planar angles it is the COS of the angle ).
     !                          this variable is optional.
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_constraints( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       INTEGER            :: i, nfield
       LOGICAL, SAVE      :: tread = .FALSE.
       ! 
       ! 
       IF ( tread ) CALL errore( 'card_constraints ', 'two occurrence ', 2 )
       !
       CALL read_line( input_line )
       !
       READ( input_line, * ) nconstr_inp, constr_tol_inp
       !
       IF ( cg_phs_path_flag ) THEN
          !
          ALLOCATE( pos( nconstr_inp, 2 ) )
          !
          pos = 0.D0
          !
          input_images = 2
          !
       END IF
       !
       DO i = 1, nconstr_inp
          !
          CALL read_line( input_line )
          !
          READ( input_line, * ) constr_type_inp(i)
          !
          CALL field_count( nfield, input_line )
          !
          SELECT CASE( constr_type_inp(i) )         
          CASE( 1, 2 )
             !
             IF ( cg_phs_path_flag ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i),    &
                                      constr_inp(2,i),    &
                                      constr_inp(3,i),    &
                                      constr_inp(4,i),    &
                                      pos(i,1),           &
                                      pos(i,2)
                !
             ELSE IF ( nfield == 5 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i), &
                                      constr_inp(3,i), &
                                      constr_inp(4,i)
                !
             ELSE IF ( nfield == 6 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i), &
                                      constr_inp(3,i), &
                                      constr_inp(4,i), &
                                      constr_target(i)
                !
                constr_target_set(i) = .TRUE.
                !
             ELSE
                !
                CALL errore( 'card_constraints ', 'too many fields ', nfield )
                !
             END IF
             !
          CASE( 3 )
             !
             IF ( cg_phs_path_flag ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i),    &
                                      constr_inp(2,i),    &
                                      pos(i,1),           &
                                      pos(i,2)
                !
             ELSE IF ( nfield == 3 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i)
                !
             ELSE IF ( nfield == 4 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i), &
                                      constr_target(i)
                !
                constr_target_set(i) = .TRUE.
                !
             ELSE
                !
                CALL errore( 'card_constraints ', 'too many fields ', nfield )
                !
             END IF
             !
          CASE( 4 )
             !
             IF ( cg_phs_path_flag ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i),    &
                                      constr_inp(2,i),    &
                                      constr_inp(3,i),    &
                                      pos(i,1),           &
                                      pos(i,2)
                !
             ELSE IF ( nfield == 4 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i), &
                                      constr_inp(3,i)
                !
             ELSE IF ( nfield == 5 ) THEN
                !
                READ( input_line, * ) constr_type_inp(i), &
                                      constr_inp(1,i), &
                                      constr_inp(2,i), &
                                      constr_inp(3,i), &
                                      constr_target(i)
                !
                constr_target_set(i) = .TRUE.
                !
             ELSE
                !
                CALL errore( 'card_constraints ', 'too many fields', nfield )
                !
             END IF
             !
          CASE DEFAULT
             !
             READ( input_line, * ) constr_type_inp(i), &
                                   constr_inp(1,i), &
                                   constr_inp(2,i)
             !
          END SELECT
          !
       END DO
       ! 
       tread = .TRUE.
       ! 
       RETURN
       !
     END SUBROUTINE card_constraints
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     ! 
     ! KSOUT
     !
     !   Enable the printing of Kohn Sham states
     !
     ! Syntax ( nspin == 2 ):
     !
     !   KSOUT
     !     nu
     !     iu(1) iu(2) iu(3) .. iu(nu)
     !     nd
     !     id(1) id(2) id(3) .. id(nd)
     !
     ! Syntax ( nspin == 1 ):
     !
     !   KSOUT
     !     ns
     !     is(1) is(2) is(3) .. is(ns)
     !
     ! Example:
     !
     !   ???
     !   
     ! Where:
     !
     !   nu (integer)     number of spin=1 states to be printed 
     !   iu(:) (integer)  indexes of spin=1 states, the state iu(k) 
     !                    is saved to file KS_UP.iu(k)
     !
     !   nd (integer)     number of spin=2 states to be printed 
     !   id(:) (integer)  indexes of spin=2 states, the state id(k) 
     !                    is saved to file KS_DW.id(k)
     !
     !   ns (integer)     number of LDA states to be printed 
     !   is(:) (integer)  indexes of LDA states, the state is(k) 
     !                    is saved to file KS.is(k)
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_ksout( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       INTEGER            :: nks, i, s
       INTEGER            :: is( SIZE( tprnks, 1 ) )
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_ksout ', ' two occurrence ', 2 )
       END IF
       !
       DO s = 1, nspin
          !
          CALL read_line( input_line )
          READ(input_line, *) nks
          !
          IF ( nks > SIZE( tprnks, 1 ) .OR. nks < 1 ) THEN
             CALL errore( ' card_ksout ', &
                        & ' wrong number of states ', 2 )
          END IF
          !
          CALL read_line( input_line )
          READ(input_line, *) ( is( i ), i = 1, nks )
          !
          DO i = 1, nks
             !
             IF ( ( is(i) > SIZE( tprnks, 1 ) ) .OR. ( is(i) < 1 ) ) &
                CALL errore( ' card_ksout ', ' wrong state index ', 2 )
             !   
             tprnks( is( i ), s ) = .TRUE.
             !
          END DO
          !
       END DO
       !
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     ! 
     ! KSOUT_EMPTY
     !
     !   Enable the printing of empty Kohn Sham states
     !
     ! Syntax ( nspin == 2 ):
     !
     !   KSOUT_EMPTY
     !     nu
     !     iu(1) iu(2) iu(3) .. iu(nu)
     !     nd
     !     id(1) id(2) id(3) .. id(nd)
     !
     ! Syntax ( nspin == 1 ):
     !
     !   KSOUT_EMPTY
     !     ns
     !     is(1) is(2) is(3) .. is(ns)
     !
     ! Example:
     !
     !   ???
     !   
     ! Where:
     !
     !   nu (integer)     number of spin=1 empty states to be printed 
     !   iu(:) (integer)  indexes of spin=1 empty states, the state iu(k) 
     !                    is saved to file KS_EMP_UP.iu(k)
     !
     !   nd (integer)     number of spin=2 empty states to be printed 
     !   id(:) (integer)  indexes of spin=2 empty states, the state id(k) 
     !                    is saved to file KS_EMP_DW.id(k)
     !
     !   ns (integer)     number of LDA empty states to be printed 
     !   is(:) (integer)  indexes of LDA empty states, the state is(k) 
     !                    is saved to file KS_EMP.is(k)
     !
     ! Note: the first empty state has index "1" !
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_ksout_empty( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       INTEGER            :: nks, i, s
       INTEGER            :: is( SIZE( tprnks_empty, 1 ) )
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_ksout_empty ', ' two occurrence ', 2 )
       END IF
       !
       DO s = 1, nspin
          !
          CALL read_line( input_line )
          READ(input_line,*) nks
          !
          IF ( ( nks > SIZE( tprnks_empty, 1 ) ) .OR. ( nks < 1 ) ) THEN
             CALL errore( ' card_ksout_empty ', &
                        & ' wrong number of states ', 2 )
          END IF
          !
          CALL read_line( input_line )
          READ(input_line,*) ( is( i ), i = 1, nks )
          !
          DO i = 1, nks
            IF ( ( is(i) > SIZE( tprnks_empty, 1 ) ) .OR. ( is(i) < 1 ) ) &
               CALL errore( ' card_ksout_empty ', ' wrong state index ', 2 )
            tprnks_empty( is( i ), s ) = .TRUE.
          END DO
          !
       END DO
       ! 
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     ! 
     ! CLIMBING_IMAGES
     !
     !   Needed to explicitly specify which images have to climb 
     !
     ! Syntax:
     !
     !   CLIMBING_IMAGES
     !     index1, ..., indexN
     !
     ! Where:
     !
     !   index1, ..., indexN are indices of the images that have to climb
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_climbing_images( input_line )
       !
       USE parser,        ONLY :  int_to_char
       !
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       LOGICAL, EXTERNAL  :: matches
       ! 
       INTEGER            :: i
       CHARACTER (LEN=5)  :: i_char 
       !
       !
       IF ( tread ) THEN
          CALL errore( ' card_climbing_images ', ' two occurrence ', 2 )
       END IF
       !
       IF ( calculation == 'neb' ) THEN
          !
          ALLOCATE( climbing( num_of_images ) )
          !
          climbing = .FALSE.
          !   
          IF ( CI_scheme == 'manual' ) THEN
             !
             CALL read_line( input_line )
             !
             DO i = 1, num_of_images
                !
                i_char = int_to_char( i ) 
                !
                IF ( matches( ' ' // TRIM( i_char ) // ',' , & 
                              ' ' // TRIM( input_line ) // ',' ) ) &
                   climbing(i) = .TRUE.
                !
             END DO
             !
          END IF
          !   
       END IF
       ! 
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE card_climbing_images
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     ! 
     ! PLOT WANNIER
     !
     !   Needed to specify the indices of the wannier functions that
     !   have to be plotted
     !
     ! Syntax:
     !
     !   PLOT_WANNIER
     !     index1, ..., indexN
     !
     ! Where:
     !
     !   index1, ..., indexN are indices of the wannier functions
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_plot_wannier( input_line )
       !
       USE parser, ONLY :  int_to_char
       !
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       LOGICAL, EXTERNAL  :: matches
       ! 
       INTEGER            :: i, ib
       CHARACTER (LEN=5)  :: i_char
       !
       !
       IF ( tread ) &
          CALL errore( 'card_plot_wannier ', 'two occurrence', 2 )
       !
       IF ( nwf > 0 ) THEN
          !
          IF ( nwf > nwf_max ) &
             CALL errore( 'card_plot_wannier ', &
                          'too many wannier functions', 1 )
          !
          CALL read_line( input_line )
          !
          ib = 0
          !
          DO i = 1, nbnd
             !
             i_char = int_to_char( i ) 
             !
             IF ( matches( ' ' // TRIM( i_char ) // ',' , & 
                           ' ' // TRIM( input_line ) // ',' ) ) THEN
                !
                ib = ib + 1
                !
                IF ( ib > nwf ) &
                   CALL errore( 'card_plot_wannier ', 'too many indices', 1 )
                 !
                wannier_index( ib ) = i
                !
             END IF
             !
          END DO
          !   
       END IF
       ! 
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE card_plot_wannier
     !
     !------------------------------------------------------------------------
     !    BEGIN manual
     !----------------------------------------------------------------------
     !
     !
     ! TEMPLATE
     !
     !      This is a template card info section
     !
     ! Syntax:
     !
     !    TEMPLATE
     !     RVALUE IVALUE
     !
     ! Example:
     !
     !    ???
     !
     ! Where:
     !
     !      RVALUE (real)     This is a real value
     !      IVALUE (integer)  This is an integer value
     !
     !----------------------------------------------------------------------
     !    END manual
     !------------------------------------------------------------------------
     !
     SUBROUTINE card_template( input_line )
       ! 
       IMPLICIT NONE
       ! 
       CHARACTER(LEN=256) :: input_line
       LOGICAL, SAVE      :: tread = .FALSE.
       ! 
       !
       IF ( tread ) THEN
          CALL errore( ' card_template ', ' two occurrence ', 2 )
       END IF
       !
       ! ....  CODE HERE
       ! 
       tread = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
END MODULE read_cards_module
