!-----------------------------------------------------------------------
SUBROUTINE lr_apply_liouvillian( evc1, evc1_new, sevc1_new, interaction )
  !---------------------------------------------------------------------
  ! ... applies linear response operator to response wavefunctions
  ! OBM: or to be more exact this function is responsible for calculating L.q(i) and (L^T).p(i)
  ! where q is evc1 and return partial qdash(i+1) and pdash(i+1) in evc1_new . Ultrasoft additions are
  ! handled here...
  ! interaction=.true. corresponds to eq.(32)
  ! interaction=.false. corresponds to eq.(33)
  ! in Ralph Gebauer, Brent Walker  J. Chem. Phys., 127, 164106 (2007)
  !---------------------------------------------------------------------
  !
  ! Modified by Osman Baris Malcioglu in 2009
#include "f_defs.h"
  !
  USE ions_base,            ONLY : ityp, nat, ntyp=>nsp
  USE cell_base,            ONLY : tpiba2
  USE fft_base,             ONLY : dffts
  USE fft_interfaces,       ONLY : fwfft
  USE gvecs,              ONLY : nls, nlsm
  USE gvect,                ONLY : nl, ngm, gstart, g, gg
  USE grid_dimensions,      ONLY : dense
  USE io_global,            ONLY : stdout
  USE kinds,                ONLY : dp
  USE klist,                ONLY : nks, xk
  USE lr_variables,         ONLY : evc0, revc0, rho_1, lr_verbosity, ltammd, size_evc, no_hxc
  USE realus,               ONLY : igk_k,npw_k
  USE lsda_mod,             ONLY : nspin
  USE uspp,                 ONLY : vkb, nkb, okvan
  USE uspp_param,           ONLY : nhm, nh
  USE wavefunctions_module, ONLY : psic
  USE wvfct,                ONLY : nbnd, npwx, igk, g2kin, et
  USE control_flags,        ONLY : gamma_only
  USE realus,               ONLY : real_space, fft_orbital_gamma, initialisation_level, &
                                   bfft_orbital_gamma, calbec_rs_gamma, add_vuspsir_gamma, &
                                   v_loc_psir, s_psir_gamma, real_space_debug, &
                                   betasave, box_beta, maxbox_beta,newq_r
  USE lr_variables,   ONLY : lr_verbosity
  USE io_global,      ONLY : stdout
  USE dfunct,         ONLY : newq
  USE control_flags,  ONLY : tqr


  !
  IMPLICIT NONE
  !
  COMPLEX(kind=dp),INTENT(in)  :: evc1(npwx,nbnd,nks)
  COMPLEX(kind=dp),INTENT(out) :: evc1_new(npwx,nbnd,nks), sevc1_new(npwx,nbnd,nks)
  LOGICAL, INTENT(in) :: interaction
  !
  !   Local variables
  !
  INTEGER :: ir, ibnd, ik, ig, ia, mbia
  INTEGER :: ijkb0, na, nt, ih, jh, ikb, jkb, iqs,jqs
  real(kind=dp), ALLOCATABLE :: dvrs(:,:), dvrss(:)
  COMPLEX(kind=dp), ALLOCATABLE :: dvrs_temp(:,:) !OBM This waste of memory was already there in lr_dv_of_drho
  real(kind=dp), ALLOCATABLE :: d_deeq(:,:,:,:)
  COMPLEX(kind=dp), ALLOCATABLE :: spsi1(:,:)
  COMPLEX(kind=dp) :: fp, fm
  REAL(DP), ALLOCATABLE, DIMENSION(:) :: w1, w2
  !
  IF (lr_verbosity > 5) THEN
    WRITE(stdout,'("<lr_apply_liouvillian>")')
  ENDIF
  !

  CALL start_clock('lr_apply')
  IF (interaction) CALL start_clock('lr_apply_int')
  IF (.not.interaction) CALL start_clock('lr_apply_no')
  !
  ALLOCATE( d_deeq(nhm, nhm, nat, nspin) )
  d_deeq(:,:,:,:)=0.0d0
  ALLOCATE( spsi1(npwx, nbnd) )
  spsi1(:,:)=(0.0d0,0.0d0)
  !
  IF( interaction ) THEN !If true, the full L is calculated
     ALLOCATE( dvrs(dense%nrxx, nspin) )
     ALLOCATE( dvrss(dffts%nnr) )
     dvrs(:,:)=0.0d0
     dvrss(:)=0.0d0
     !
     CALL lr_calc_dens( evc1, .false. )
     !
     IF (no_hxc) THEN
     !OBM no_hxc controls the hartree excange correlation addition, if true, they are not added
      dvrs(:,1)=0.0d0
      CALL interpolate (dvrs(:,1),dvrss,-1)
     ELSE
       dvrs(:,1)=rho_1(:,1)
       !
       !call lr_dv_of_drho(dvrs)
       ALLOCATE( dvrs_temp(dense%nrxx, nspin) )
       dvrs_temp=cmplx(dvrs,0.0d0)         !OBM: This memory copy was hidden in lr_dv_of_drho, can it be avoided?
       DEALLOCATE ( dvrs )
       CALL dv_of_drho(0,dvrs_temp,.false.)
       ALLOCATE ( dvrs(dense%nrxx, nspin) ) !SJB Worth getting rid of this memory bottle neck for the moment.
       dvrs=dble(dvrs_temp)
       DEALLOCATE(dvrs_temp)
       !
       IF ( okvan )  THEN
        IF ( tqr ) THEN
         CALL newq_r(dvrs,d_deeq,.true.)
        ELSE
         ALLOCATE( psic(dense%nrxx) )
         psic(:)=(0.0d0,0.0d0)
         CALL newq(dvrs,d_deeq,.true.)
         DEALLOCATE( psic )
        ENDIF
       ENDIF
       CALL add_paw_to_deeq(d_deeq)
       !
       CALL interpolate (dvrs(:,1),dvrss,-1)
     ENDIF
     !
  ENDIF
  !
  ALLOCATE ( psic (dense%nrxx) )
  IF( gamma_only ) THEN
     !
     CALL lr_apply_liouvillian_gamma()
     !
  ELSE
     !
     CALL lr_apply_liouvillian_k()
     !
  ENDIF
  DEALLOCATE ( psic )
  !
  IF ( interaction .and. (.not.ltammd) ) THEN
     !
     !   Normal interaction
     !
     WRITE(stdout,'(5X,"lr_apply_liouvillian: applying interaction: normal")')
     !
     !   Here evc1_new contains the interaction
     !
     !OBM, blas
     !sevc1_new=sevc1_new+(1.0d0,0.0d0)*evc1_new
     CALL zaxpy(size_evc,cmplx(1.0d0,0.0d0,kind=dp),evc1_new(:,:,:),1,sevc1_new(:,:,:),1)
     !
     !
  ELSEIF ( interaction .and. ltammd ) THEN
     !
     !   Tamm-dancoff interaction
     !
     WRITE(stdout,'(5X,"lr_apply_liouvillian: applying interaction: tamm-dancoff")')
     !
     !   Here evc1_new contains the interaction
     !
     !OBM, blas
     !sevc1_new=sevc1_new+(0.50d0,0.0d0)*evc1_new
     CALL zaxpy(size_evc,cmplx(0.5d0,0.0d0,kind=dp),evc1_new(:,:,:),1,sevc1_new(:,:,:),1)
     !
     !
  ELSE
     !
     !   Non interacting
     !
     WRITE(stdout,'(5X,"lr_apply_liouvillian: not applying interaction")')
     !
  ENDIF
  !
  IF (gstart == 2 .and. gamma_only ) sevc1_new(1,:,:)=cmplx(real(sevc1_new(1,:,:),dp),0.0d0,dp)
  ! (OBM: Why there is this check?)
  IF(gstart==2 .and. gamma_only) THEN
     !
     DO ik=1,nks
        !
        DO ibnd=1,nbnd
           !
           !
           IF (abs(aimag(sevc1_new(1,ibnd,ik)))>1.0d-12) THEN
              !
              CALL errore(' lr_apply_liouvillian ',&
                   'Imaginary part of G=0 '// &
                   'component does not equal zero',1)
              !
           ENDIF
           !
        ENDDO
        !
     ENDDO
     !
  ENDIF
  !
  DO ik=1,nks
     !
     CALL sm1_psi(.false.,ik,npwx,npw_k(ik),nbnd,sevc1_new(1,1,ik),evc1_new(1,1,ik))
     !
  ENDDO
  !
  IF (allocated(dvrs)) DEALLOCATE(dvrs)
  IF (allocated(dvrss)) DEALLOCATE(dvrss)
  DEALLOCATE(d_deeq)
  DEALLOCATE(spsi1)
  !
9000 FORMAT(/5x,'lr_apply_liouvillian: ibnd=',1X,i2,1X,'sevc1_new(G=0)[',i1,']',2(1x,e12.5)/)
  !
  CALL stop_clock('lr_apply')
  IF (interaction) CALL stop_clock('lr_apply_int')
  IF (.not.interaction) CALL stop_clock('lr_apply_no')
  !
  RETURN
  !
CONTAINS
  !
  SUBROUTINE lr_apply_liouvillian_gamma()
    !
    !use becmod,              only : bec_type,becp
    USE lr_variables,        ONLY : becp1
    !
    real(kind=dp), ALLOCATABLE :: becp2(:,:)
    !
    IF ( nkb > 0 .and. okvan ) THEN
       !
       ALLOCATE(becp2(nkb,nbnd))
       becp2(:,:)=0.0d0
       !
    ENDIF
    !
    !    Now apply to the ground state wavefunctions
    !    and convert to real space
    !
    IF ( interaction ) THEN
       !
       CALL start_clock('interaction')

       IF (nkb > 0 .and. okvan) THEN
          ! calculation of becp2
          becp2(:,:) = 0.0d0
          !
          ijkb0 = 0
          !
          DO nt = 1, ntyp
             !
             DO na = 1, nat
                !
                IF ( ityp(na) == nt ) THEN
                   !
                   DO ibnd = 1, nbnd
                      !
                      DO jh = 1, nh(nt)
                         !
                         jkb = ijkb0 + jh
                         !
                         DO ih = 1, nh(nt)
                            !
                            ikb = ijkb0 + ih
                            becp2(ikb, ibnd) = becp2(ikb, ibnd) + &
                                 d_deeq(ih,jh,na,1) * becp1(jkb,ibnd)
                            !
                         ENDDO
                         !
                      ENDDO
                      !
                   ENDDO
                   !
                   ijkb0 = ijkb0 + nh(nt)
                   !
                ENDIF
                !
             ENDDO
             !
          ENDDO
          !end: calculation of becp2
       ENDIF
       !
       !   evc1_new is used as a container for the interaction
       !
       evc1_new(:,:,:)=(0.0d0,0.0d0)
       !
       DO ibnd=1,nbnd,2
          !
          !   Product with the potential vrs = (vltot+vr)
          ! revc0 is on smooth grid. psic is used upto smooth grid
          DO ir=1,dffts%nnr
             !
             psic(ir)=revc0(ir,ibnd,1)*cmplx(dvrss(ir),0.0d0,dp)
             !
          ENDDO

          !
          !print *,"1"
          IF (real_space_debug > 7 .and. okvan .and. nkb > 0) THEN
          !THE REAL SPACE PART (modified from s_psi)
                  !print *, "lr_apply_liouvillian:Experimental interaction part not using vkb"
                  !fac = sqrt(omega)
                  !
                  ijkb0 = 0
                  iqs = 0
                  jqs = 0
                  !
                  DO nt = 1, ntyp
                  !
                    DO ia = 1, nat
                      !
                      IF ( ityp(ia) == nt ) THEN
                        !
                        mbia = maxbox_beta(ia)
                        !print *, "mbia=",mbia
                        ALLOCATE( w1(nh(nt)),  w2(nh(nt)) )
                        w1 = 0.D0
                        w2 = 0.D0
                        !
                        DO ih = 1, nh(nt)
                        !
                          DO jh = 1, nh(nt)
                          !
                          jkb = ijkb0 + jh
                          w1(ih) = w1(ih) + becp2(jkb, ibnd)
                          IF ( ibnd+1 <= nbnd ) w2(ih) = w2(ih) + becp2(jkb, ibnd+1)
                          !
                          ENDDO
                        !
                        ENDDO
                        !
                        !w1 = w1 * fac
                        !w2 = w2 * fac
                        ijkb0 = ijkb0 + nh(nt)
                        !
                        DO ih = 1, nh(nt)
                          !
                          DO ir = 1, mbia
                          !
                           iqs = jqs + ir
                           psic( box_beta(ir,ia) ) = psic(  box_beta(ir,ia) ) + betasave(ia,ih,ir)*cmplx( w1(ih), w2(ih) )
                          !
                          ENDDO
                        !
                        jqs = iqs
                        !
                        ENDDO
                        !
                      DEALLOCATE( w1, w2 )
                        !
                      ENDIF
                    !
                    ENDDO
                  !
                  ENDDO

          ENDIF
          !print *,"2"
          !
          !   Back to reciprocal space This part is equivalent to bfft_orbital_gamma
          !
          CALL bfft_orbital_gamma (evc1_new(:,:,1), ibnd, nbnd,.false.)
          !print *,"3"
       ENDDO
       !
       !
       IF( nkb > 0 .and. okvan .and. real_space_debug <= 7) THEN
         !The non real_space part
          CALL dgemm( 'N', 'N', 2*npw_k(1), nbnd, nkb, 1.d0, vkb, &
               2*npwx, becp2, nkb, 1.d0, evc1_new, 2*npwx )
          !print *, "lr_apply_liouvillian:interaction part using vkb"
          !
       ENDIF
       CALL stop_clock('interaction')
       !
    ENDIF
    !
    !   Call h_psi on evc1 such that h.evc1 = sevc1_new
    !
    CALL h_psi(npwx,npw_k(1),nbnd,evc1(1,1,1),sevc1_new(1,1,1))
    !
    ! spsi1 = s*evc1
    !
    IF (real_space_debug > 9 ) THEN
        DO ibnd=1,nbnd,2
         CALL fft_orbital_gamma(evc1(:,:,1),ibnd,nbnd)
         CALL s_psir_gamma(ibnd,nbnd)
         CALL bfft_orbital_gamma(spsi1,ibnd,nbnd)
        ENDDO
    ELSE
       CALL s_psi(npwx,npw_k(1),nbnd,evc1(1,1,1),spsi1)
    ENDIF
    !
    !   Subtract the eigenvalues
    !
    DO ibnd=1,nbnd
       !
       CALL zaxpy(npw_k(1), cmplx(-et(ibnd,1),0.0d0,dp), spsi1(:,ibnd), 1, sevc1_new(:,ibnd,1), 1)
       !
    ENDDO
    !
    IF( nkb > 0 .and. okvan ) DEALLOCATE(becp2)
    !
    RETURN
    !
  END SUBROUTINE lr_apply_liouvillian_gamma
  !
  SUBROUTINE lr_apply_liouvillian_k()
    !
    !use becmod,              only : becp
    USE lr_variables,        ONLY : becp1_c
    !
    COMPLEX(kind=dp), ALLOCATABLE :: becp2(:,:)
    !
    IF( nkb > 0 .and. okvan ) THEN
       !
       ALLOCATE(becp2(nkb,nbnd))
       becp2(:,:)=(0.0d0,0.0d0)
       !
    ENDIF
    !
    !   Now apply to the ground state wavefunctions
    !   and  convert to real space
    !
    IF ( interaction ) THEN
       !
       CALL start_clock('interaction')
       !
       !   evc1_new is used as a container for the interaction
       !
       evc1_new(:,:,:)=(0.0d0,0.0d0)
       !
       DO ik=1,nks
          !
          DO ibnd=1,nbnd
             !
             !   Product with the potential vrs = (vltot+vr)
             !
             DO ir=1,dffts%nnr
                !
                psic(ir)=revc0(ir,ibnd,ik)*cmplx(dvrss(ir),0.0d0,dp)
                !
             ENDDO
             !
             !   Back to reciprocal space
             !
             CALL fwfft ('Wave', psic, dffts)
             !
             DO ig=1,npw_k(ik)
                !
                evc1_new(ig,ibnd,ik)=psic(nls(igk_k(ig,ik)))
                !
             ENDDO
             !
          ENDDO
          !
       ENDDO
       !
       CALL stop_clock('interaction')
       !
       IF ( nkb > 0 .and. okvan ) THEN
          !
          DO ik=1,nks
             !
             CALL init_us_2(npw_k(ik),igk_k(1,ik),xk(1,ik),vkb)
             !
             becp2(:,:) = 0.0d0
             !
             ijkb0 = 0
             !
             DO nt = 1, ntyp
                !
                DO na = 1, nat
                   !
                   IF ( ityp(na) == nt ) THEN
                      !
                      DO ibnd = 1, nbnd
                         !
                         DO jh = 1, nh(nt)
                            !
                            jkb = ijkb0 + jh
                            !
                            DO ih = 1, nh(nt)
                               !
                               ikb = ijkb0 + ih
                               becp2(ikb, ibnd) = becp2(ikb, ibnd) + &
                                    d_deeq(ih,jh,na,1) * becp1_c(jkb,ibnd,ik)
                                !
                            ENDDO
                            !
                         ENDDO
                         !
                      ENDDO
                      !
                      ijkb0 = ijkb0 + nh(nt)
                      !
                   ENDIF
                   !
                ENDDO
                !
             ENDDO
             !
             !evc1_new(ik) = evc1_new(ik) + vkb*becp2(ik)
             CALL zgemm( 'N', 'N', npw_k(ik), nbnd, nkb, (1.d0,0.d0), vkb, &
                  npwx, becp2, nkb, (1.d0,0.d0), evc1_new(:,:,ik), npwx )
             !
          ENDDO
          !
       ENDIF
       !
    ENDIF
    !
    !   Call h_psi on evc1
    !   h_psi uses arrays igk and npw, so restore those
    !
    DO ik=1,nks
       !
       CALL init_us_2(npw_k(ik),igk_k(1,ik),xk(1,ik),vkb)
       !
       DO ig=1,npw_k(ik)
          !
          g2kin(ig)=((xk(1,ik)+g(1,igk_k(ig,ik)))**2 &
               +(xk(2,ik)+g(2,igk_k(ig,ik)))**2 &
               +(xk(3,ik)+g(3,igk_k(ig,ik)))**2)*tpiba2
          !
       ENDDO
       !
       igk(:)=igk_k(:,ik)
       !
       CALL h_psi(npwx,npw_k(ik),nbnd,evc1(1,1,ik),sevc1_new(1,1,ik))
       !
       CALL s_psi(npwx,npw_k(ik),nbnd,evc1(1,1,ik),spsi1)
       !
       !   Subtract the eigenvalues
       !
       DO ibnd=1,nbnd
          !
          DO ig=1,npw_k(ik)
             !
             sevc1_new(ig,ibnd,ik)=sevc1_new(ig,ibnd,ik) &
                  -cmplx(et(ibnd,ik),0.0d0,dp)*spsi1(ig,ibnd)
             !
          ENDDO
          !
       ENDDO
       !
    ENDDO ! end k loop
    !
    IF( nkb > 0 .and. okvan ) DEALLOCATE(becp2)
    !
    RETURN
  END SUBROUTINE lr_apply_liouvillian_k
  !
END SUBROUTINE lr_apply_liouvillian
!-----------------------------------------------------------------------
