!-----------------------------------------------------------------------
SUBROUTINE lr_restart(iter_restart,rflag)
  !---------------------------------------------------------------------
  ! ... restart the Lanczos recursion
  !---------------------------------------------------------------------
  !
  ! Modified by Osman Baris Malcioglu (2009)
#include "f_defs.h"
  !
  USE io_global,            ONLY : stdout, ionode_id
  USE control_flags,                ONLY : gamma_only
  USE klist,                ONLY : nks, xk
  USE cell_base,            ONLY : tpiba2
  USE gvect,                ONLY : g
  USE io_files,             ONLY : tmp_dir, prefix, diropn, wfc_dir
  USE lr_variables,         ONLY : itermax,evc1, evc1_new, sevc1_new, rho_1_tot , rho_1_tot_im,&
                                   restart, nwordrestart, iunrestart,project,nbnd_total,F,&
                                   bgz_suffix
  USE charg_resp,           ONLY : resonance_condition
  USE wvfct,                ONLY : npw, igk, nbnd, g2kin, npwx
  USE lr_variables,         ONLY : beta_store, gamma_store, zeta_store, norm0!,real_space
  USE becmod,               ONLY : bec_type, becp, calbec
  USE uspp,                 ONLY : vkb, nkb, okvan
  USE io_global,            ONLY : ionode
  USE mp,                   ONLY : mp_bcast
  !use real_beta,            only : ccalbecr_gamma,s_psir,fft_orbital_gamma,bfft_orbital_gamma
  USE realus,               ONLY : real_space, fft_orbital_gamma, initialisation_level, &
                                    bfft_orbital_gamma, calbec_rs_gamma, add_vuspsir_gamma, &
                                    v_loc_psir, s_psir_gamma,igk_k,npw_k, &
                                    real_space_debug
  USE grid_dimensions,      ONLY : dense
  USE lr_variables,         ONLY : lr_verbosity, charge_response, LR_polarization, n_ipol
  USE noncollin_module,     ONLY : nspin_mag


  !
  IMPLICIT NONE
  !
  CHARACTER(len=6), EXTERNAL :: int_to_char
  !
  !integer, intent(in) :: pol
  INTEGER, INTENT(out) :: iter_restart
  LOGICAL, INTENT(out) :: rflag
  !
  ! local variables
  !
  INTEGER :: i,ibnd,ibnd_occ,ibnd_virt,temp
  INTEGER :: ik, ig, ip
  LOGICAL :: exst
  CHARACTER(len=256) :: tempfile, filename,tmp_dir_saved
  INTEGER :: pol_index
  !
  !
  IF (lr_verbosity > 5) THEN
    WRITE(stdout,'("<lr_restart>")')
  ENDIF

  pol_index=1
  IF ( n_ipol /= 1 ) pol_index=LR_polarization

  IF (.not.restart) RETURN
  !
  rflag = .false.
  !
  ! Restarting kintic-energy and ultrasoft
  !
  IF (gamma_only) THEN
     !
     DO ig=1,npwx
        !
        g2kin(ig)=((xk(1,1)+g(1,igk_k(ig,1)))**2 &
                 +(xk(2,1)+g(2,igk_k(ig,1)))**2 &
                 +(xk(3,1)+g(3,igk_k(ig,1)))**2)*tpiba2
        !
     ENDDO
     !
     CALL init_us_2(npw,igk,xk(1,1),vkb)
     !
  ENDIF
  !
  ! Reading Lanczos coefficients
  !
  !
  filename = trim(prefix) // trim(bgz_suffix) // trim(int_to_char(LR_polarization))
  tempfile = trim(tmp_dir) // trim(filename)
  !
  INQUIRE (file = tempfile, exist = exst)
  !
  IF (.not.exst) THEN
     !
     WRITE( stdout,*) "WARNING: " // trim(filename) // " does not exist"
     rflag = .true.
     RETURN
     !
  ENDIF
  !
  !
  !Ionode only reads
  !
  ! Note Ionode file io is done in tmp_dir
  !
#ifdef __PARA
  IF (ionode) THEN
#endif
  !
  ! Read and broadcast beta gamma zeta
  !
  OPEN (158, file = tempfile, form = 'formatted', status = 'old')
  !
  READ(158,*,end=301,err=303) iter_restart
  !
  IF ( iter_restart >= itermax ) iter_restart = itermax
  !
  READ(158,*,end=301,err=303) norm0(pol_index)
  !
  DO i=1,iter_restart
     !
     READ(158,*,end=301,err=303) beta_store(pol_index,i)
     READ(158,*,end=301,err=303) gamma_store(pol_index,i)
     READ(158,*,end=301,err=303) zeta_store (pol_index,:,i)
     !
  ENDDO
  !
  CLOSE(158)
#ifdef __PARA
  ENDIF
  CALL mp_bcast (iter_restart, ionode_id)
  CALL mp_bcast (norm0(pol_index), ionode_id)
  CALL mp_bcast (beta_store(pol_index,:), ionode_id)
  CALL mp_bcast (gamma_store(pol_index,:), ionode_id)
  CALL mp_bcast (zeta_store(pol_index,:,:), ionode_id)
#endif
  !
  !
  ! Read projection
  !
  IF (project) THEN
#ifdef __PARA
  IF (ionode) THEN
#endif
    filename = trim(prefix) // ".projection." // trim(int_to_char(LR_polarization))
    tempfile = trim(tmp_dir) // trim(filename)
    !
    !
    OPEN (158, file = tempfile, form = 'formatted', status = 'unknown')
    !
    READ(158,*,end=301,err=303) temp
    !
    IF (temp /= iter_restart) CALL errore ('lr_restart', 'Iteration mismatch reading projections', 1 )
    !
    READ(158,*,end=301,err=303) temp   !number of filled bands
    !
    IF (temp /= nbnd) CALL errore ('lr_restart', 'NBND mismatch reading projections', 1 )
    !
    READ(158,*,end=301,err=303) temp !total number of bands
    !
    IF (temp /= nbnd_total) CALL errore ('lr_restart', 'Total number of bands mismatch reading projections', 1 )
    !
    DO ibnd_occ=1,nbnd
       DO ibnd_virt=1,(nbnd_total-nbnd)
        READ(158,*,end=301,err=303) F(ibnd_occ,ibnd_virt,pol_index)
       ENDDO
    ENDDO
    !
    CLOSE(158)
#ifdef __PARA
  ENDIF
  CALL mp_bcast (F, ionode_id)
#endif
  ENDIF

  !
  iter_restart = iter_restart + 1
  !
  ! Parallel reads:
  !
  ! Note: Restart files are always in outdir
  !
  !
  ! Reading Lanczos vectors
  !
  nwordrestart = 2 * nbnd * npwx * nks
  !
  CALL diropn ( iunrestart, 'restart_lanczos.'//trim(int_to_char(LR_polarization)), nwordrestart, exst)
  !
  CALL davcio(evc1(:,:,:,1),nwordrestart,iunrestart,1,-1)
  CALL davcio(evc1(:,:,:,2),nwordrestart,iunrestart,2,-1)
  CALL davcio(evc1_new(:,:,:,1),nwordrestart,iunrestart,3,-1)
  CALL davcio(evc1_new(:,:,:,2),nwordrestart,iunrestart,4,-1)
  !
  CLOSE( unit = iunrestart)
  IF (charge_response == 1 ) THEN
     IF (resonance_condition) THEN
         CALL diropn ( iunrestart, 'restart_lanczos-rho_tot.'//trim(int_to_char(LR_polarization)), 2*dense%nrxx, exst)
         CALL davcio(rho_1_tot_im(:,:),2*dense%nrxx*nspin_mag,iunrestart,1,-1)
         CLOSE( unit = iunrestart)
     ELSE
         CALL diropn ( iunrestart, 'restart_lanczos-rho_tot.'//trim(int_to_char(LR_polarization)), 2*dense%nrxx, exst)
         CALL davcio(rho_1_tot(:,:),2*dense%nrxx*nspin_mag,iunrestart,1,-1)
         CLOSE( unit = iunrestart)
       ENDIF
     ENDIF
  !
  ! End of all file i/o for restart
  !
  !
  ! Reinitializing sevc1_new vector
  !
  IF (gamma_only) THEN
     !
     IF ( nkb > 0 .and. okvan ) THEN
      IF (real_space_debug>6) THEN
       DO ibnd=1,nbnd,2
        CALL fft_orbital_gamma(evc1_new(:,:,1,1),ibnd,nbnd)
        CALL calbec_rs_gamma(ibnd,nbnd,becp%r)
        CALL s_psir_gamma(ibnd,nbnd)
        CALL bfft_orbital_gamma(sevc1_new(:,:,1,1),ibnd,nbnd)
       ENDDO
      ELSE
       CALL calbec(npw_k(1),vkb,evc1_new(:,:,1,1),becp)
       !call pw_gemm('Y',nkb,nbnd,npw_k(1),vkb,npwx,evc1_new(1,1,1,1),npwx,rbecp,nkb)
       CALL s_psi(npwx,npw_k(1),nbnd,evc1_new(:,:,1,1),sevc1_new(:,:,1,1))
      ENDIF
     ELSE
      !nkb = 0 not real space
       !
       CALL s_psi(npwx,npw_k(1),nbnd,evc1_new(:,:,1,1),sevc1_new(:,:,1,1))
       !
      !
     ENDIF
     !
     IF ( nkb > 0 .and. okvan ) THEN
      IF (real_space_debug>6) THEN
        DO ibnd=1,nbnd,2
        CALL fft_orbital_gamma(evc1_new(:,:,1,2),ibnd,nbnd)
        CALL calbec_rs_gamma(ibnd,nbnd,becp%r)
        CALL s_psir_gamma(ibnd,nbnd)
        CALL bfft_orbital_gamma(sevc1_new(:,:,1,2),ibnd,nbnd)
       ENDDO
     ELSE
       CALL calbec(npw_k(1),vkb,evc1_new(:,:,1,2),becp%r)
      !call pw_gemm('Y',nkb,nbnd,npw_k(1),vkb,npwx,evc1_new(1,1,1,2),npwx,rbecp,nkb)
       CALL s_psi(npwx,npw_k(1),nbnd,evc1_new(:,:,1,2),sevc1_new(:,:,1,2))
      ENDIF
     ENDIF
     !call s_psi(npwx,npw_k(1),nbnd,evc1_new(:,:,1,2),sevc1_new(:,:,1,2))
     !
  ELSE
     !
     DO ik=1,nks
        !
        IF ( nkb > 0 .and. okvan ) THEN
           CALL init_us_2(npw_k(ik),igk_k(1,ik),xk(1,ik),vkb)
           !call ccalbec(nkb,npwx,npw_k(ik),nbnd,becp,vkb,evc1_new(1,1,ik,1))
           CALL calbec(npw_k(ik), vkb, evc1_new(:,:,ik,1), becp)
        ENDIF
        CALL s_psi(npwx,npw_k(ik),nbnd,evc1_new(:,:,ik,1),sevc1_new(:,:,ik,1))
        !
        IF (nkb > 0) CALL calbec(npw_k(ik), vkb, evc1_new(:,:,ik,2), becp)
        !call ccalbec(nkb,npwx,npw_k(ik),nbnd,becp,vkb,evc1_new(1,1,ik,2))
        CALL s_psi(npwx,npw_k(ik),nbnd,evc1_new(:,:,ik,2),sevc1_new(:,:,ik,2))
        !
     ENDDO
     !
  ENDIF
  !
  !
  RETURN
  301 CALL errore ('restart', 'A File is corrupted, file ended unexpectedly', 1 )
  303 CALL errore ('restart', 'A File is corrupted, error in reading data', 1)
END SUBROUTINE lr_restart
!-----------------------------------------------------------------------
