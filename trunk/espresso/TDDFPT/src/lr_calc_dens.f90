!-----------------------------------------------------------------------
SUBROUTINE lr_calc_dens( evc1, response_calc )
  !---------------------------------------------------------------------
  ! ... calculates response charge density from linear response
  ! ... orbitals and ground state orbitals
  !---------------------------------------------------------------------
  !
  ! Modified by Osman Baris Malcioglu in 2009
  !
  ! Input : evc1 (qdash etc)
  ! Output: rho_1 (=2*sum_v (revc0_v(r) . revc1_v(r,w) )
  !  where v:valance state index, r denotes a transformation t
  !
  ! In case of US PP, becsum is also calculated here
  ! In case of charge response calculation, the rho_tot is calculated here
  !
  USE ions_base,              ONLY : ityp, nat, ntyp=>nsp
  USE cell_base,              ONLY : omega
  USE ener,                   ONLY : ef
  USE gvecs,                  ONLY : nls, nlsm, doublegrid
  USE fft_base,               ONLY : dffts, dfftp
  USE fft_interfaces,         ONLY : invfft
  USE io_global,              ONLY : stdout
  USE kinds,                  ONLY : dp
  USE klist,                  ONLY : nks,xk,wk
  USE lr_variables,           ONLY : evc0,revc0,rho_1,lr_verbosity,&
                                     & charge_response, itermax,&
                                     & cube_save, rho_1_tot&
                                     &,rho_1_tot_im, LR_iteration,&
                                     & LR_polarization, project,&
                                     & evc0_virt, F,nbnd_total,&
                                     & n_ipol, becp1_virt 
  USE lsda_mod,               ONLY : current_spin, isk
  USE wavefunctions_module,   ONLY : psic
  USE wvfct,                  ONLY : nbnd, et, wg, npwx, npw
  USE control_flags,          ONLY : gamma_only
  USE uspp,                   ONLY : vkb, nkb, okvan, qq, becsum
  USE uspp_param,             ONLY : upf, nh
  USE io_global,              ONLY : ionode, stdout
  USE io_files,               ONLY : tmp_dir, prefix
  USE mp,                     ONLY : mp_sum
  USE mp_global,              ONLY : inter_pool_comm, intra_pool_comm,&
                                     & nproc 
  USE realus,                 ONLY : igk_k,npw_k, addusdens_r
  USE charg_resp,             ONLY : w_T, lr_dump_rho_tot_cube,&
                                     & lr_dump_rho_tot_xyzd, &
                                     & lr_dump_rho_tot_xcrys,&
                                     & resonance_condition, epsil
  USE noncollin_module,       ONLY : nspin_mag
  USE control_flags,          ONLY : tqr
  USE becmod,                 ONLY : becp
  USE constants,              ONLY : eps12
  !
  IMPLICIT NONE
  !
  CHARACTER(len=6), EXTERNAL   :: int_to_char
  !
  COMPLEX(kind=dp), INTENT(in) :: evc1(npwx,nbnd,nks)
  LOGICAL, INTENT(in)          :: response_calc
  !
  ! functions
  REAL(kind=dp) :: ddot
  !
  ! local variables
  INTEGER       :: ir, ik, ibnd, jbnd, ig, ijkb0, np, na
  INTEGER       :: ijh,ih,jh,ikb,jkb ,ispin 
  INTEGER       :: i, j, k, l
  REAL(kind=dp) :: w1, w2, scal
  REAL(kind=dp) :: rho_sum 
  !
  ! These are temporary buffers for the response 
  REAL(kind=dp), ALLOCATABLE :: rho_sum_resp_x(:), rho_sum_resp_y(:),&
                              & rho_sum_resp_z(:)  
  !
  CHARACTER(len=256) :: tempfile, filename
  !
  !OBM DEBUG
  COMPLEX(kind=dp),EXTERNAL :: lr_dot
  !
  IF (lr_verbosity > 5) THEN
     WRITE(stdout,'("<lr_calc_dens>")')
  ENDIF
  !
  CALL start_clock('lr_calc_dens')
  !
  !
  ALLOCATE( psic(dfftp%nnr) )
  psic(:)    = (0.0d0,0.0d0)
  rho_1(:,:) =  0.0d0
  !
  IF(gamma_only) THEN
     CALL lr_calc_dens_gamma()
  ELSE
     CALL lr_calc_dens_k()
  ENDIF
  !
  ! If a double grid is used, interpolate onto the fine grid
  !
  IF ( doublegrid ) CALL interpolate(rho_1,rho_1,1)
  !
  ! Here we add the Ultrasoft contribution to the charge density
  ! response. 
  !
  IF(okvan) THEN
     !
     IF (tqr) THEN
        CALL addusdens_r(rho_1,.FALSE.)
     ELSE
        CALL addusdens(rho_1)
     ENDIF
  ENDIF
  !
  ! The psic workspace can present a memory bottleneck
  DEALLOCATE ( psic )
  !
#ifdef __MPI
  CALL mp_sum(rho_1, inter_pool_comm)
#endif
  !
  ! check response charge density sums to 0
  !
  IF (lr_verbosity > 0) THEN
     ! 
     DO ispin = 1, nspin_mag
        !
        rho_sum=0.0d0
        rho_sum=SUM(rho_1(:,ispin))
        !
#ifdef __MPI
        CALL mp_sum(rho_sum, intra_pool_comm )
#endif
        !
        rho_sum = rho_sum * omega / (dfftp%nr1*dfftp%nr2*dfftp%nr3)
        !
        IF (ABS(rho_sum) > eps12) THEN
           !
           IF (tqr) THEN
              !
              WRITE(stdout,'(5X, "lr_calc_dens: Charge drift due to &
                   &real space implementation = " ,1X,e12.5)') rho_sum
              !
           ELSE
              !
              WRITE(stdout,'(5X,"lr_calc_dens: ****** response &
                   &charge density does not sum to zero")')
              !
              WRITE(stdout,'(5X,"lr_calc_dens: ****** response &
                   &charge density =",1X,e12.5)') rho_sum
              !
              WRITE(stdout,'(5X,"lr_calc_dens: ****** response &
                   &charge density, US part =",1X,e12.5)') scal
              !
           ENDIF
           !
        ENDIF
        !
     ENDDO
     !
  ENDIF
  !
  IF (charge_response == 2 .AND. LR_iteration /=0) THEN
     !
     ALLOCATE( rho_sum_resp_x( dfftp%nr1 ) )
     ALLOCATE( rho_sum_resp_y( dfftp%nr2 ) )
     ALLOCATE( rho_sum_resp_z( dfftp%nr3 ) )
     !
     rho_sum_resp_x = 0.D0
     rho_sum_resp_y = 0.D0
     rho_sum_resp_z = 0.D0
     !
     DO ir=1,dfftp%nnr
        !
        i=cube_save(ir,1)+1
        j=cube_save(ir,2)+1
        k=cube_save(ir,3)+1
        !
        rho_sum_resp_x(i)=rho_sum_resp_x(i)+rho_1(ir,1)
        rho_sum_resp_y(j)=rho_sum_resp_y(j)+rho_1(ir,1)
        rho_sum_resp_z(k)=rho_sum_resp_z(k)+rho_1(ir,1)
        !
     ENDDO
     !
#ifdef __MPI
     CALL mp_sum(rho_sum_resp_x, intra_pool_comm)
     CALL mp_sum(rho_sum_resp_y, intra_pool_comm)
     CALL mp_sum(rho_sum_resp_z, intra_pool_comm)
     IF (ionode) THEN
#endif
        WRITE(stdout,'(5X,"Dumping plane sums of densities for &
             &iteration ",I4)') LR_iteration
        !
        filename = TRIM(prefix) // ".density_x"
        tempfile = TRIM(tmp_dir) // TRIM(filename)
        !
        OPEN (158, file = tempfile, form = 'formatted', status = &
             &'unknown', position = 'append') 
        !
        DO i=1,dfftp%nr1
           WRITE(158,*) rho_sum_resp_x(i)
        ENDDO
        !
        CLOSE(158)
        !
        filename = TRIM(prefix) // ".density_y"
        tempfile = TRIM(tmp_dir) // TRIM(filename)
        !
        OPEN (158, file = tempfile, form = 'formatted', status = &
             &'unknown', position = 'append')
        !
        DO i=1,dfftp%nr2
           WRITE(158,*) rho_sum_resp_y(i)
        ENDDO
        !
        CLOSE(158)
        !
        filename = TRIM(prefix) // ".density_z"
        tempfile = TRIM(tmp_dir) // TRIM(filename)
        !
        OPEN (158, file = tempfile, form = 'formatted', status = &
             &'unknown', position = 'append')
        !
        DO i=1,dfftp%nr3
           WRITE(158,*) rho_sum_resp_z(i)
        ENDDO
        !
        CLOSE(158)
        !
#ifdef __MPI
     ENDIF
#endif
     !
     DEALLOCATE( rho_sum_resp_x )
     DEALLOCATE( rho_sum_resp_y )
     DEALLOCATE( rho_sum_resp_z )
     !
  ENDIF
  IF (charge_response == 1 .AND. response_calc) THEN
    IF (LR_iteration < itermax) WRITE(stdout,'(5x,"Calculating total &
         &response charge density")')
    ! the charge response, it is actually equivalent to an element of
    ! V^T . phi_v where V^T is the is the transpose of the Krylov
    ! subspace generated by the Lanczos algorithm. The total charge
    ! density can be written as,
    !
    ! \sum_(lanczos iterations) (V^T.phi_v) . w_T
    !
    ! Where w_T is the corresponding eigenvector from the solution of,
    !
    ! (w-L)e_1 = w_T
    !
    ! notice that rho_1 is already reduced across pools above, so no
    ! parallelization is necessary 
    !
    ! the lr_calc_dens corresponds to q of x only in even iterations
    !
    IF (resonance_condition) THEN
       !
       ! Singular matrix, the broadening term dominates, phi' has
       ! strong imaginary component 
       !
       ! Using BLAS here would result in cmplx(rho_1(:,1),0.0d0 ,dp)
       ! being copied into a NEW array due to the call being to an
       !  F77 funtion. 
       !
       rho_1_tot_im(1:dfftp%nnr,:) = rho_1_tot_im(1:dfftp%nnr,:) &
            & +  w_T(LR_iteration) * cmplx(rho_1(1:dfftp%nnr,:),0.0d0,dp) 
       !
    ELSE
       !
       ! Not at resonance.
       ! The imaginary part is neglected, these are the non-absorbing
       !  oscillations
       !
       rho_1_tot(1:dfftp%nnr,:) = rho_1_tot(1:dfftp%nnr,:) &
            & +  dble( w_T(LR_iteration) ) * rho_1(1:dfftp%nnr,:)
       
    ENDIF
    !
 ENDIF
 !
 !
 CALL stop_clock('lr_calc_dens')
 RETURN
 !
CONTAINS
  !
  SUBROUTINE lr_calc_dens_gamma
    !
    ! Gamma_only case.
    !
    USE becmod,              ONLY : bec_type, becp, calbec
    USE lr_variables,        ONLY : becp1, tg_revc0
    USE io_global,           ONLY : stdout
    USE realus,              ONLY : real_space, fft_orbital_gamma,&
                                    & initialisation_level,&
                                    & bfft_orbital_gamma,&
                                    & calbec_rs_gamma,&
                                    & add_vuspsir_gamma, v_loc_psir,&
                                    & real_space_debug 
    USE realus,              ONLY : tg_psic
    USE mp_global,           ONLY : me_bgrp, me_pool
    USE fft_base,            ONLY : dffts, tg_gather
    USE wvfct,               ONLY : igk
    !
    LOGICAL :: use_tg
    INTEGER :: v_siz, incr, ioff, idx
    REAL(DP),    ALLOCATABLE :: tg_rho(:)
    !
    use_tg=dffts%have_task_groups
    incr = 2
    !
    IF( dffts%have_task_groups ) THEN
       !
       v_siz =  dffts%tg_nnr * dffts%nogrp
       !
       incr = 2 * dffts%nogrp
       !
       ALLOCATE( tg_rho( v_siz ) )
       tg_rho= 0.0_DP
       !
    ENDIF
    !
    DO ibnd=1,nbnd,incr
       CALL fft_orbital_gamma(evc1(:,:,1),ibnd,nbnd)
       !
       ! FFT: evc1 -> psic
       !
       IF(dffts%have_task_groups) THEN
          !
          ! Now the first proc of the group holds the first two bands
          ! of the 2*dffts%nogrp bands that we are processing at the same time,
          ! the second proc. holds the third and fourth band
          ! and so on
          !
          ! Compute the proper factor for each band
          !
          DO idx = 1, dffts%nogrp
             IF( dffts%nolist( idx ) == me_pool ) EXIT
          END DO
          !
          ! Remember two bands are packed in a single array :
          ! proc 0 has bands ibnd   and ibnd+1
          ! proc 1 has bands ibnd+2 and ibnd+3
          ! ....
          !
          idx = 2 * idx - 1
          !
          IF( idx + ibnd - 1 < nbnd ) THEN
             w1 = wg( idx + ibnd - 1, 1) / omega
             w2 = wg( idx + ibnd    , 1) / omega
          ELSE IF( idx + ibnd - 1 == nbnd ) THEN
             w1 = wg( idx + ibnd - 1, 1) / omega
             w2 = w1
          ELSE
             w1 = 0.0d0
             w2 = w1
          END IF
          !
          DO ir=1,dffts%tg_npp( me_pool + 1 ) * dffts%nr1x * dffts%nr2x
             tg_rho(ir)=tg_rho(ir) &
                  +2.0d0*(w1*real(tg_revc0(ir,ibnd,1),dp)*real(tg_psic(ir),dp)&
                  +w2*aimag(tg_revc0(ir,ibnd,1))*aimag(tg_psic(ir)))
          ENDDO
       else
          !
          ! Set weights of the two real bands now in psic
          !
          w1=wg(ibnd,1)/omega
          !
          IF(ibnd<nbnd) THEN
             w2=wg(ibnd+1,1)/omega
          ELSE
             w2=w1
          ENDIF
          !
          ! (n'(r,w)=2*sum_v (psi_v(r) . q_v(r,w))
          ! where psi are the ground state valance orbitals
          ! and q_v are the standard batch representation (rotated)
          ! response orbitals
          ! Here, since the ith iteration is the best approximation we
          ! have for the most dominant eigenvalues/vectors, an estimate
          ! for the response charge density can be calculated. This is
          ! in no way the final response charge density.  
          !
          ! The loop is over real space points.
          !
          DO ir=1,dffts%nnr
             rho_1(ir,1)=rho_1(ir,1) &
                  +2.0d0*(w1*real(revc0(ir,ibnd,1),dp)*real(psic(ir),dp)&
                  +w2*aimag(revc0(ir,ibnd,1))*aimag(psic(ir)))
          ENDDO
          !
          ! OBM - psic now contains the response functions in real space.
          ! Eagerly putting all the real space stuff at this point. 
          !
          ! Notice that betapointlist() is called in lr_readin at the
          ! very start 
          !
          IF ( real_space_debug > 6 .AND. okvan) THEN
             ! The rbecp term
             CALL calbec_rs_gamma(ibnd,nbnd,becp%r)
             !
          ENDIF
          !
          ! End of real space stuff
          !
       endif
    ENDDO
    IF(dffts%have_task_groups) THEN
       !
       ! reduce the group charge
       !
       CALL mp_sum( tg_rho, gid = dffts%ogrp_comm )
       !
       ioff = 0
       DO idx = 1, dffts%nogrp
          IF( me_pool == dffts%nolist( idx ) ) EXIT
          ioff = ioff + dffts%nr1x * dffts%nr2x * dffts%npp( dffts%nolist( idx ) + 1 )
       END DO
       !
       ! copy the charge back to the processor location
       !
       DO ir = 1, dffts%nnr
          rho_1(ir,1) = rho_1(ir,1) + tg_rho(ir+ioff)
       END DO
       !
    ENDIF
    !
    ! If we have a US pseudopotential we compute here the becsum
    ! term. 
    ! This corresponds to the right hand side of the formula (36) in
    ! the ultrasoft paper. 
    !
    ! Be careful about calling lr_calc_dens, as it modifies this
    ! globally.
    !
    IF ( okvan ) THEN
       !
       scal = 0.0d0
       becsum(:,:,:) = 0.0d0
       !
       IF ( real_space_debug <= 6) THEN 
          ! In real space, the value is calculated above
          CALL calbec(npw_k(1), vkb, evc1(:,:,1), becp)
          !
       ENDIF
       !
       CALL start_clock( 'becsum' )
       !
       DO ibnd = 1, nbnd
          !
          scal = 0.0d0
          w1 = wg(ibnd,1)
          ijkb0 = 0
          !
          DO np = 1, ntyp
             !
             IF ( upf(np)%tvanp ) THEN
                !
                DO na = 1, nat
                   !
                   IF ( ityp(na) == np ) THEN
                      !
                      ijh = 1
                      !
                      DO ih = 1, nh(np)
                         !
                         ikb = ijkb0 + ih
                         !
                         becsum(ijh,na,current_spin) = &
                              becsum(ijh,na,current_spin) + &
                              2.d0 * w1 * becp%r(ikb,ibnd) *&
                              & becp1(ikb,ibnd)
                         !
                         scal = scal + qq(ih,ih,np) *1.d0 *&
                              &  becp%r(ikb,ibnd) * becp1(ikb,ibnd)
                         !
                         ijh = ijh + 1
                         !
                         DO jh = ( ih + 1 ), nh(np)
                            !
                            jkb = ijkb0 + jh
                            !
                            becsum(ijh,na,current_spin) = &
                                 becsum(ijh,na,current_spin) + &
                                 w1 * 2.D0 * (becp1(ikb,ibnd) * &
                                 &becp%r(jkb,ibnd) + & 
                                 becp1(jkb,ibnd) * becp%r(ikb,ibnd))
                            !
                            scal = scal + qq(ih,jh,np) * 1.d0 *&
                                 & (becp%r(ikb,ibnd) * &
                                 &becp1(jkb, ibnd) + &
                                 &becp%r(jkb,ibnd) * becp1(ikb,ibnd))
                            !
                            ijh = ijh + 1
                            !
                         ENDDO
                         !
                      ENDDO
                      !
                      ijkb0 = ijkb0 + nh(np)
                      !
                   ENDIF
                   !
                ENDDO
                !
             ELSE
                !
                DO na = 1, nat
                   !
                   IF ( ityp(na) == np ) ijkb0 = ijkb0 + nh(np)
                   !
                ENDDO
                !
             ENDIF
             !
          ENDDO
          !
       ENDDO
       !
       CALL stop_clock( 'becsum' )
       !
    ENDIF
    !
    IF( dffts%have_task_groups ) THEN
       DEALLOCATE( tg_rho )
    END IF
    !   
    RETURN
    !
  END SUBROUTINE lr_calc_dens_gamma
!-----------------------------------------------------------------------
  SUBROUTINE lr_calc_dens_k
    !
    USE becmod,              ONLY : bec_type, becp, calbec
    USE lr_variables,        ONLY : becp1_c
    !
    DO ik=1,nks
       DO ibnd=1,nbnd
          psic(:)=(0.0d0,0.0d0)
          DO ig=1,npw_k(ik)
             psic(nls(igk_k(ig,ik)))=evc1(ig,ibnd,ik)
          ENDDO
          !
          CALL invfft ('Wave', psic, dffts)
          !
          w1=wg(ibnd,ik)/omega
          !
          ! loop over real space points
          DO ir=1,dffts%nnr
             rho_1(ir,:)=rho_1(ir,:) &
                  +2.0d0*w1*real(conjg(revc0(ir,ibnd,ik))*psic(ir),dp)
          ENDDO
          !
       ENDDO
    ENDDO
    !
    ! ... If we have a US pseudopotential we compute here the becsum term
    !
    IF ( okvan ) THEN
       !
       DO ik =1,nks
          !
          CALL init_us_2(npw_k(ik),igk_k(1,ik),xk(1,ik),vkb)
          !
          scal = 0.0d0
          becsum(:,:,:) = 0.0d0
          !
          IF ( nkb > 0 .and. okvan ) THEN
             ! call ccalbec(nkb,npwx,npw_k(ik),nbnd,becp,vkb,evc1)
             CALL calbec(npw_k(ik),vkb,evc1(:,:,ik),becp)
          ENDIF
          !
          CALL start_clock( 'becsum' )
          !
          DO ibnd = 1, nbnd
             scal = 0.0d0
             !
             w1 = wg(ibnd,ik)
             ijkb0 = 0
             !
             DO np = 1, ntyp
                !
                IF ( upf(np)%tvanp ) THEN
                   !
                   DO na = 1, nat
                      !
                      IF ( ityp(na) == np ) THEN
                         !
                         ijh = 1
                         !
                         DO ih = 1, nh(np)
                            !
                            ikb = ijkb0 + ih
                            !
                            becsum(ijh,na,current_spin) = &
                                 becsum(ijh,na,current_spin) + &
                                 2.d0 * w1 * &
                                 &DBLE(CONJG(becp%k(ikb,ibnd)) *&
                                 & becp1_c(ikb,ibnd,ik)) 
                            !
                            scal = scal + qq(ih,ih,np) * 1.d0 *&
                                 &  DBLE(CONJG(becp%k(ikb,ibnd)) *&
                                 & becp1_c(ikb,ibnd,ik))
                            !
                            ijh = ijh + 1
                            !
                            DO jh = ( ih + 1 ), nh(np)
                               !
                               jkb = ijkb0 + jh
                               !
                               becsum(ijh,na,current_spin) = &
                                    becsum(ijh,na,current_spin) + &
                                    w1 * 2.d0 * DBLE(&
                                    & CONJG(becp1_c(ikb,ibnd,ik)) *&
                                    & becp%k(jkb,ibnd) + &
                                    becp1_c(jkb,ibnd,ik) *&
                                    & CONJG(becp%k(ikb,ibnd)))
                               !
                               scal = scal + qq(ih,jh,np) * 1.d0 * &
                                    & DBLE(CONJG(becp%k(ikb,ibnd)) *&
                                    & becp1_c(jkb,ibnd,ik)+&
                                    & becp%k(jkb,ibnd) * &
                                    & CONJG(becp1_c(ikb,ibnd,ik)))
                               !
                               ijh = ijh + 1
                               !
                            ENDDO
                            !
                         ENDDO
                         !
                         ijkb0 = ijkb0 + nh(np)
                         !
                      ENDIF
                      !
                   ENDDO
                   !
                ELSE
                   !
                   DO na = 1, nat
                      !
                      IF ( ityp(na) == np ) ijkb0 = ijkb0 + nh(np)
                      !
                   ENDDO
                   !
                ENDIF
                !
             ENDDO
             !
          ENDDO
          !
          CALL stop_clock( 'becsum' )
          !
       ENDDO
       !
    ENDIF
    !
    RETURN
    !
  END SUBROUTINE lr_calc_dens_k
!--------------------------------------------------------------------
END SUBROUTINE lr_calc_dens
!--------------------------------------------------------------------

