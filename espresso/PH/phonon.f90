!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
PROGRAM phonon
  !-----------------------------------------------------------------------
  !
  ! ... This is the main driver of the phonon program. It controls
  ! ... the initialization routines and the self-consistent cycle.
  ! ... At the end of the self-consistent run the dynamical matrix is
  ! ... computed. In the case q=0 the dielectric constant and the effective
  ! ... charges are computed.
  !
  USE kinds,           ONLY : DP
  USE io_global,       ONLY : stdout, ionode, ionode_id
  USE wvfct,           ONLY : gamma_only
  USE klist,           ONLY : xk, wk, xqq, degauss, nks
  USE relax,           ONLY : restart_bfgs
  USE basis,           ONLY : startingwfc, startingpot, startingconfig
  USE force_mod,       ONLY : force
  USE io_files,        ONLY : prefix, nd_nmbr
  USE mp,              ONLY : mp_bcast
  USE ions_base,       ONLY : nat
  USE lsda_mod,        ONLY : nspin
  USE gvect,           ONLY : nrx1, nrx2, nrx3
  USE parser,          ONLY : int_to_char
  USE control_flags,   ONLY : iswitch,  restart, lphonon, tr2, &
                              mixing_beta, lscf, david, isolve, modenum
  USE qpoint,          ONLY : xq, nksq
  USE disp,            ONLY : nqs, x_q
  USE control_ph,      ONLY : ldisp, lnscf, lgamma, convt, epsil, trans, &
                              elph, zue, recover, maxirr, irr0
  USE output,          ONLY : fildyn, fildrho
  USE units_ph,        ONLY : iudrho, lrdrho
  USE parser,          ONLY : delete_if_present
  USE mp_global,       ONLY : me_pool, root_pool
  USE global_version,  ONLY : version_number
  !
  IMPLICIT NONE
  !
  INTEGER :: iq, iq_start, iustat, ierr
  INTEGER :: nks_start
    ! number of initial k points
  REAL(KIND = DP), ALLOCATABLE :: wk_start(:)
    ! initial weight of k points
  REAL(KIND = DP), ALLOCATABLE :: xk_start(:,:)
    ! initial coordinates of k points
  LOGICAL :: exst
  CHARACTER (LEN=9)   :: code = 'PHONON'
  CHARACTER (LEN=256) :: auxdyn
  CHARACTER (LEN=256) :: filname, filint
  !
  EXTERNAL date_and_tim
  !
  !
  CALL init_clocks( .TRUE. )
  !
  CALL start_clock( 'PHONON' )
  !
  gamma_only = .FALSE.
  !
  CALL startup( nd_nmbr, code, version_number )
  !
  WRITE( stdout, '(/5x,"Ultrasoft (Vanderbilt) Pseudopotentials")' )
  !
  ! ... and begin with the initialization part
  !
  CALL phq_readin()
  !
  ! ... Checking the status of the calculation
  !
  iustat = 98
  !
  IF ( ionode ) THEN
     !
     filname = TRIM( prefix ) // '.stat'
     !
     CALL seqopn( iustat, filname, 'FORMATTED', exst )
     !
     IF ( exst ) THEN
        !
        READ( UNIT = iustat, FMT = *, IOSTAT = ierr ) iq_start
        !
        IF ( ierr /= 0 ) THEN
           !
           iq_start = 1
           !
        ELSE IF ( iq_start > 0 ) THEN
           !
           WRITE( UNIT = stdout, FMT = "(/,5X,'starting from an old run')")
           !
           WRITE( UNIT = stdout, &
                  FMT = "(5X,'Doing now the calculation ', &
                           & 'for q point nr ',I3)" ) iq_start
           !
        ELSE
           !
           iq_start = 1          
           !   
        END IF
        !
     ELSE
        !
        iq_start = 1
        !
     END IF
     !
     CLOSE( UNIT = iustat, STATUS = 'KEEP' )
     !
  END IF
  !   
  CALL mp_bcast( iq_start, ionode_id )
  !
  IF ( ldisp ) THEN
     !
     ! ... Calculate the q-points for the dispersion
     !
     CALL q_points()
     !
     ! ... Store the name of the matdyn file in auxdyn
     !
     auxdyn = fildyn
     !
     ! ... Save the starting k points 
     !
     nks_start = nks
     !
     IF ( .NOT. ALLOCATED( xk_start ) ) ALLOCATE( xk_start( 3, nks_start ) )
     IF ( .NOT. ALLOCATED( wk_start ) ) ALLOCATE( wk_start( nks_start ) )
     !
     xk_start(:,1:nks_start) = xk(:,1:nks_start)
     wk_start(1:nks_start)   = wk(1:nks_start)
     !
     ! ... do always a non-scf calculation
     !
     lnscf = .TRUE.
     !
  ELSE
     !
     nqs = 1
     !
  END IF
  !
  IF ( lnscf ) CALL start_clock( 'PWSCF' )
  !
  DO iq = iq_start, nqs
     !
     IF ( ionode ) THEN
        !
        CALL seqopn( iustat, filname, 'FORMATTED', exst )
        !
        REWIND( iustat )
        !
        WRITE( iustat, * ) iq
        !
        CLOSE( UNIT = iustat, STATUS = 'KEEP' )
        !
     END IF
     !
     IF ( ldisp ) THEN
        !
        ! ... set the name for the output file
        !
        fildyn = TRIM( auxdyn ) // TRIM( int_to_char( iq ) )
        !
        ! ... set the q point
        !
        xqq(1:3) = x_q(1:3,iq)
        xq(1:3)  = x_q(1:3,iq)
        !
        lgamma = ( xqq(1) == 0.D0 .AND. xqq(2) == 0.D0 .AND. xqq(3) == 0.D0 )
        !
        ! ... in the case of an insulator one has to calculate 
        ! ... the dielectric constant and the Born eff. charges
        !
        IF ( lgamma .AND. degauss == 0.D0 ) THEN
           !
           epsil = .TRUE.
           zue   = .TRUE.
           !
        END IF
        !
        ! ... for q != 0 no calculation of the dielectric tensor 
        ! ...           and Born eff. charges
        !
        IF ( .NOT. lgamma ) THEN
           !
           epsil = .FALSE.
           zue   = .FALSE.
           !
        END IF
        !
        CALL mp_bcast( epsil,  ionode_id )
        CALL mp_bcast( zue,    ionode_id )
        CALL mp_bcast( lgamma, ionode_id )
        !
        nks = nks_start
        !
        xk(:,1:nks_start) = xk_start(:,1:nks_start)
        wk(1:nks_start)   = wk_start(1:nks_start)
        !
     END IF
     !
     ! ... In the case of q != 0, we make first an non selfconsistent run
     !
     IF ( lnscf .OR. ( modenum == 0 .AND. .NOT. lgamma .AND. lnscf ) ) THEN
        !
        WRITE( stdout, '(/,5X,"Calculation of q = ",3F8.4)') xqq
        !
        CALL clean_pw( .FALSE. )
        !
        CALL close_files()
        !
        ! ... Setting the values for the nscf run
        !
        lphonon        = .TRUE.
        lscf           = .FALSE.
        restart        = .FALSE.
        restart_bfgs   = .FALSE.
        startingconfig = 'input'
        startingpot    = 'file'
        startingwfc    = 'atomic'
        !
        ! ... tr2 is set to a default value of 1.D-8
        !
        tr2 = 1.D-8
        !
        IF ( .NOT. ALLOCATED( force ) ) ALLOCATE( force( 3, nat ) )
        !
        ! ... Set the value for davidson diagonalization
        !
        IF ( isolve == 0 )  david = 4
        !
        CALL init_run()
        !
        CALL electrons()
        !
        CALL sum_band()
        !
        CALL close_files()
        !
     END IF
     !
     ! ... Setting nksq
     !
     IF ( lgamma ) THEN
        !
        nksq = nks
        !
     ELSE
        !
        nksq = nks / 2
        !
     END IF
     !
     ! ... Calculation of the dispersion: do all modes 
     !
     maxirr = 0
     !
     CALL allocate_phq()
     CALL phq_setup()
     CALL phq_recover()
     CALL phq_summary()
     !
     CALL openfilq()
     !
     CALL phq_init()
     CALL show_memory()
     !
     CALL print_clock( 'PHONON' )
     !
     IF ( trans .AND. .NOT. recover ) CALL dynmat0()
     !
     IF ( epsil .AND. irr0 <=  0 ) THEN
        !
        WRITE( stdout, '(/,5X,"Electric Fields Calculation")' )
        CALL solve_e()
        WRITE( stdout, '(/,5X,"End of electric fields calculation")' )
        !
        IF ( convt ) THEN
           !
           ! ... calculate the dielectric tensor epsilon
           !
           CALL dielec()
           !
           ! ... calculate the effective charges Z(E,Us) (E=scf,Us=bare)
           !
           CALL zstar_eu()
           !
           IF ( fildrho /= ' ' ) CALL punch_plot_e()
           !
           ! close the file with drho_E
           !
           IF (fildrho.NE.' ') THEN
              CLOSE (unit = iudrho, status = 'keep')
              !
              ! open the file with drho_u
              !
              iudrho = 23
              lrdrho = 2 * nrx1 * nrx2 * nrx3 * nspin

              IF ( me_pool == root_pool ) THEN

                 filint = TRIM(fildrho)//".u"
                 CALL diropn (iudrho, filint, lrdrho, exst)

              END IF

           END IF
           !
        ELSE
           !
           CALL stop_ph( .FALSE. )
           !
        END IF
        !
     END IF
     !
     IF ( trans ) THEN
        !
        CALL phqscf()
        CALL dynmatrix()
        !
        IF ( fildrho /= ' ' ) CALL punch_plot_ph()
        !
     END IF
     !
     IF ( elph ) THEN
        !
        IF ( .NOT. trans ) THEN
           ! 
           CALL dvanqq()
           CALL elphon()
           !
        END IF
        !
        CALL elphsum()
        !
     END IF
     !
     ! ... cleanup of the variables
     !
     CALL clean_pw( .FALSE. )
     CALL deallocate_phq()
     !
     ! ... Close the files
     !
     CALL close_phq( .TRUE. )
     !
  END DO
  !
  IF ( ionode ) CALL delete_if_present( filname )
  !
  IF ( ALLOCATED( xk_start ) ) DEALLOCATE( xk_start )
  IF ( ALLOCATED( wk_start ) ) DEALLOCATE( wk_start )
  !
  IF ( lnscf ) CALL print_clock_pw()
  !
  CALL stop_ph( .TRUE. )
  !
  STOP
  !
END PROGRAM phonon
