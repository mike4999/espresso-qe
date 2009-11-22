!
! Copyright (C) 2002-2005 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
! written by Carlo Cavazzoni

!-----------------------------------------------------------------------

   SUBROUTINE writefile_cp                                         &
     &     ( h,hold,nfi,c0,cm,taus,tausm,vels,velsm,acc,           &
     &       lambda,lambdam,xnhe0,xnhem,vnhe,xnhp0,xnhpm,vnhp,nhpcl,nhpdim,ekincm,&
     &       xnhh0,xnhhm,vnhh,velh, fion, tps, mat_z, occ_f, rho )
!-----------------------------------------------------------------------
!
      USE kinds,            ONLY: DP
      USE ions_base,        ONLY: nsp, na, cdmi, taui
      USE cell_base,        ONLY: s_to_r
      USE cp_restart,       ONLY: cp_writefile
      USE cp_interfaces,    ONLY: set_evtot, set_eitot
      USE electrons_base,   ONLY: nspin, nbnd, nbsp, iupdwn, nupdwn
      USE electrons_module, ONLY: ei
      USE io_files,         ONLY: tmp_dir
      USE ensemble_dft,     ONLY: tens
      USE mp,               ONLY: mp_bcast
      USE mp_global,        ONLY: root_image, intra_image_comm
      USE control_flags,    ONLY: tksw, ndw
!
      implicit none
      integer, INTENT(IN) ::  nfi
      REAL(DP), INTENT(IN) :: h(3,3), hold(3,3)
      complex(DP), INTENT(IN) :: c0(:,:), cm(:,:)
      REAL(DP), INTENT(IN) :: tausm(:,:), taus(:,:), fion(:,:)
      REAL(DP), INTENT(IN) :: vels(:,:), velsm(:,:)
      REAL(DP), INTENT(IN) :: acc(:), lambda(:,:,:), lambdam(:,:,:)
      REAL(DP), INTENT(IN) :: xnhe0, xnhem, vnhe, ekincm
      REAL(DP), INTENT(IN) :: xnhp0(:), xnhpm(:), vnhp(:)
      integer,      INTENT(in) :: nhpcl, nhpdim
      REAL(DP), INTENT(IN) :: xnhh0(3,3),xnhhm(3,3),vnhh(3,3),velh(3,3)
      REAL(DP), INTENT(in) :: tps
      REAL(DP), INTENT(in) :: rho(:,:)
      REAL(DP), INTENT(in) :: occ_f(:)
      REAL(DP), INTENT(in) :: mat_z(:,:,:)

      REAL(DP) :: ht(3,3), htm(3,3), htvel(3,3), gvel(3,3)
      INTEGER  :: nk = 1, ispin, i, ib
      REAL(DP) :: xk(3,1) = 0.0d0, wk(1) = 2.0d0
      REAL(DP) :: htm1(3,3), omega
      COMPLEX(DP), ALLOCATABLE :: ctot(:,:)
      REAL(DP),    ALLOCATABLE :: eitot(:,:)
      INTEGER  :: nupdwn_tot( 2 ), iupdwn_tot( 2 )


      if ( ndw < 1 ) then
         !
         ! Do not write restart file if the unit number 
         ! is negative, this is used mainly for benchmarks and tests
         !
         return
         !
      end if

      ht     = TRANSPOSE( h ) 
      htm    = TRANSPOSE( hold ) 
      htvel  = TRANSPOSE( velh ) 
      gvel   = 0.0d0
      
      nupdwn_tot = nupdwn 
      iupdwn_tot(1) = iupdwn(1)
      iupdwn_tot(2) = nupdwn(1) + 1
      !
      ALLOCATE( eitot( nupdwn_tot(1), nspin ) )
      !
      CALL set_eitot( eitot )
      !
      IF( tksw ) THEN
         !
         ALLOCATE( ctot( SIZE( c0, 1 ), nupdwn_tot(1) * nspin ) )
         !
         CALL set_evtot( c0, ctot, lambda, iupdwn_tot, nupdwn_tot )
         !
      END IF
      !
      !  Sincronize lambdas, whose replicas could diverge on
      !  different processors
      !
      IF( tens ) THEN
        !
        CALL cp_writefile( ndw, tmp_dir, .TRUE., nfi, tps, acc, nk, xk, wk,   &
          ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui, cdmi , taus,        &
          vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl,nhpdim, occ_f , &
          occ_f , lambda, lambdam, xnhe0, xnhem, vnhe, ekincm, ei,            &
          rho, c0, cm, ctot, iupdwn, nupdwn, iupdwn, nupdwn, mat_z = mat_z  )
        !
      ELSE
        ! 
        CALL cp_writefile( ndw, tmp_dir, .TRUE., nfi, tps, acc, nk, xk, wk,  &
             ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui, cdmi , taus,    &
             vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl,nhpdim, occ_f,&
             occ_f , lambda, lambdam, xnhe0, xnhem, vnhe, ekincm, eitot,     &
             rho, c0, cm, ctot, iupdwn, nupdwn, iupdwn_tot, nupdwn_tot )
        !
      END IF

      DEALLOCATE( eitot )
      !
      IF( tksw ) DEALLOCATE( ctot )

      return
      end subroutine writefile_cp

!-----------------------------------------------------------------------
      subroutine readfile_cp                                        &
     &     ( flag, h,hold,nfi,c0,cm,taus,tausm,vels,velsm,acc,    &
     &       lambda,lambdam,xnhe0,xnhem,vnhe,xnhp0,xnhpm,vnhp,nhpcl,nhpdim,ekincm,&
     &       xnhh0,xnhhm,vnhh,velh,&
     &       fion, tps, mat_z, occ_f )
!-----------------------------------------------------------------------
!
! read from file and distribute data calculated in preceding iterations
!
      USE kinds,          ONLY : DP
      USE io_files,       ONLY : tmp_dir
      USE electrons_base, ONLY : nbnd, nbsp, nspin, nupdwn, iupdwn, keep_occ
      USE gvecw,          ONLY : ngw, ngwt
      USE ions_base,      ONLY : nsp, na, cdmi, taui
      USE cp_restart,     ONLY : cp_readfile, cp_read_cell, cp_read_wfc
      USE ensemble_dft,   ONLY : tens
      USE autopilot,      ONLY : event_step, event_index, max_event_step
      USE cp_autopilot,   ONLY : employ_rules
      USE control_flags,  ONLY : ndr
!
      implicit none
      INTEGER, INTENT(in) :: flag
      integer ::  nfi
      REAL(DP) :: h(3,3), hold(3,3)
      complex(DP) :: c0(:,:), cm(:,:)
      REAL(DP) :: tausm(:,:),taus(:,:), fion(:,:)
      REAL(DP) :: vels(:,:), velsm(:,:)
      REAL(DP) :: acc(:),lambda(:,:,:), lambdam(:,:,:)
      REAL(DP) :: xnhe0,xnhem,vnhe
      REAL(DP) :: xnhp0(:), xnhpm(:), vnhp(:)
      integer, INTENT(inout) :: nhpcl,nhpdim
      REAL(DP) :: ekincm
      REAL(DP) :: xnhh0(3,3),xnhhm(3,3),vnhh(3,3),velh(3,3)
      REAL(DP), INTENT(OUT) :: tps
      REAL(DP), INTENT(INOUT) :: mat_z(:,:,:), occ_f(:)
      !
      REAL(DP) :: ht(3,3), htm(3,3), htvel(3,3), gvel(3,3)
      integer :: nk = 1, ispin, i, ib
      REAL(DP) :: xk(3,1) = 0.0d0, wk(1) = 2.0d0
      REAL(DP), ALLOCATABLE :: occ_ ( : )
      REAL(DP) :: htm1(3,3), b1(3) , b2(3), b3(3), omega
        
      LOGICAL::lopen

      IF( flag == -1 ) THEN
        CALL cp_read_cell( ndr, tmp_dir, .TRUE., ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh )
        h     = TRANSPOSE( ht )
        hold  = TRANSPOSE( htm )
        velh  = TRANSPOSE( htvel )
        RETURN
      ELSE IF ( flag == 0 ) THEN
        DO ispin = 1, nspin
          CALL cp_read_wfc( ndr, tmp_dir, 1, 1, ispin, nspin, c2 = cm(:,:), tag = 'm' )
        END DO
        RETURN
      END IF

      ALLOCATE( occ_ ( SIZE( occ_f ) ) )

      IF( tens ) THEN
         CALL cp_readfile( ndr, tmp_dir, .TRUE., nfi, tps, acc, nk, xk, wk, &
                ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui, cdmi, taus, &
                vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl,nhpdim,occ_ , &
                occ_ , lambda, lambdam, b1, b2, b3, &
                xnhe0, xnhem, vnhe, ekincm, c0, cm, mat_z = mat_z )
      ELSE
         CALL cp_readfile( ndr, tmp_dir, .TRUE., nfi, tps, acc, nk, xk, wk, &
                ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui, cdmi, taus, &
                vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl,nhpdim,occ_ , &
                occ_ , lambda, lambdam, b1, b2, b3, &
                xnhe0, xnhem, vnhe, ekincm, c0, cm )
      END IF

      ! AutoPilot (Dynamic Rules) Implementation
      event_index = 1

      do while (event_step(event_index) <= nfi)
         ! Assuming that the remaining dynamic parm values are set correctly by reading 
         ! the the restart file.
         ! if this is not true, employ rules as events are updated right here as:
         call employ_rules()
         event_index = event_index + 1
         if(  event_index > max_event_step ) then
            CALL errore( ' readfile ' , ' maximum events exceeded for dynamic rules ' , 1 )
         end if
      enddo
      
      IF( .NOT. keep_occ ) THEN
         occ_f( : ) = occ_ ( : )
      END IF

      DEALLOCATE( occ_ )

      return
      end subroutine readfile_cp


!------------------------------------------------------------------------------!
   SUBROUTINE set_eitot_x( eitot )
!------------------------------------------------------------------------------!
      USE kinds,            ONLY: DP
      USE electrons_base,   ONLY: nupdwn, nspin
      USE electrons_module, ONLY: ei
      !
      IMPLICIT NONE
      !
      REAL(DP), INTENT(OUT) :: eitot(:,:)
      !
      INTEGER :: n
      !
      eitot = 0.0d0
      !
      eitot( 1:nupdwn(1), 1 ) = ei( 1:nupdwn(1), 1 )
      IF( nspin == 2 ) eitot( 1:nupdwn(2), 2 ) = ei( 1:nupdwn(2), 2 )
      !  
      RETURN
   END SUBROUTINE set_eitot_x


!------------------------------------------------------------------------------!
   SUBROUTINE set_evtot_x( c0, ctot, lambda, iupdwn_tot, nupdwn_tot )
!------------------------------------------------------------------------------!
      USE kinds,             ONLY: DP
      USE electrons_base,    ONLY: nupdwn, nspin, iupdwn, nudx
      USE electrons_module,  ONLY: ei
      USE cp_interfaces,     ONLY: crot
      USE cp_main_variables, ONLY: collect_lambda, descla
      !
      IMPLICIT NONE
      !
      COMPLEX(DP), INTENT(IN)  :: c0(:,:)
      COMPLEX(DP), INTENT(OUT) :: ctot(:,:)
      REAL(DP),    INTENT(IN)  :: lambda(:,:,:)
      INTEGER,     INTENT(IN)  :: iupdwn_tot(2), nupdwn_tot(2)
      !
      REAL(DP),    ALLOCATABLE :: eitmp(:)
      REAL(DP),    ALLOCATABLE :: lambda_repl(:,:)
      !
      ALLOCATE( eitmp( nudx ) )
      ALLOCATE( lambda_repl( nudx, nudx ) )
      !
      ctot = 0.0d0
      !
      CALL collect_lambda( lambda_repl, lambda(:,:,1), descla(:,1) )
      !
      CALL crot( ctot, c0, SIZE( c0, 1 ), nupdwn(1), iupdwn_tot(1), iupdwn(1), lambda_repl, nudx, eitmp )
      !
      IF( nspin == 2 ) THEN
         CALL collect_lambda( lambda_repl, lambda(:,:,2), descla(:,2) )
         CALL crot( ctot, c0, SIZE( c0, 1 ), nupdwn(2), iupdwn_tot(2), iupdwn(2), lambda_repl, nudx, eitmp )
      END IF
      !
      DEALLOCATE( lambda_repl )
      !
      DEALLOCATE( eitmp )
      !
      RETURN

   END SUBROUTINE set_evtot_x
