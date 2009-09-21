!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine allocate_phq
  !-----------------------------------------------------------------------
  !
  ! dynamical allocation of arrays: quantities needed for the linear
  ! response problem
  !

  USE kinds, only : DP
  USE ions_base, ONLY : nat, ntyp => nsp
  USE klist, only : nks
  USE wvfct, ONLY : nbnd, igk, npwx
  USE gvect, ONLY : nrxx, ngm
  USE lsda_mod, ONLY : nspin
  USE noncollin_module, ONLY : noncolin, npol
  USE wavefunctions_module,  ONLY: evc
  USE spin_orb, ONLY : lspinorb
  USE becmod, ONLY: bec_type, becp, allocate_bec_type
  USE uspp, ONLY: okvan, nkb
  USE paw_variables, ONLY : okpaw
  USE uspp_param, ONLY: nhm
  USE ramanm, ONLY: ramtns, lraman

  USE qpoint, ONLY : nksq, eigqts, igkq
  USE phus, ONLY : int1, int1_nc, int2, int2_so, int3, int3_nc, int3_paw, &
                   int4, int4_nc, int5, int5_so, becsumort, dpqq, &
                   dpqq_so, alphasum, alphasum_nc, becsum_nc, &
                   becp1, alphap, alphap_nc
  USE efield_mod, ONLY : zstareu, zstareu0, zstarue0, zstarue0_rec, zstarue
  USE eqv, ONLY : dpsi, evq, vlocq, dmuxc, dvpsi, eprec
  USE units_ph, ONLY : this_pcxpsi_is_on_file, this_dvkb3_is_on_file
  USE dynmat, ONLY : dyn00, dyn, dyn_rec, w2
  USE modes, ONLY : u, ubar, rtau, max_irr_dim, npert, t, tmq, name_rap_mode
  USE control_ph, ONLY : elph, lgamma
  USE el_phon, ONLY : el_ph_mat


  implicit none
  INTEGER :: ik
  !
  !  allocate space for the quantities needed in the phonon program
  !
  if (lgamma) then
     !
     !  q=0  : evq and igkq are pointers to evc and igk
     !
     evq  => evc
     igkq => igk
  else
     !
     !  q!=0 : evq, igkq are allocated and calculated at point k+q
     !
     allocate (evq ( npwx*npol , nbnd))    
     allocate (igkq ( npwx))    
  endif
  !
  allocate (dvpsi ( npwx*npol , nbnd))    
  allocate ( dpsi ( npwx*npol , nbnd))    
  !
  allocate (vlocq ( ngm , ntyp))    
  allocate (dmuxc ( nrxx , nspin , nspin))    
  allocate (eprec ( nbnd, nksq) )
  !
  allocate (eigqts ( nat))    
  allocate (rtau ( 3, 48, nat))    
  allocate (u ( 3 * nat, 3 * nat))    
  allocate (ubar ( 3 * nat))    
  allocate (dyn ( 3 * nat, 3 * nat))    
  allocate (dyn_rec ( 3 * nat, 3 * nat))    
  allocate (dyn00 ( 3 * nat, 3 * nat))    
  allocate (w2 ( 3 * nat))    
  allocate (t (max_irr_dim, max_irr_dim, 48,3 * nat))    
  allocate (tmq (max_irr_dim, max_irr_dim, 3 * nat))    
  allocate (name_rap_mode( 3 * nat))    
  allocate (npert ( 3 * nat))    
  allocate (zstareu (3, 3,  nat))    
  allocate (zstareu0 (3, 3 * nat))    
  allocate (zstarue (3 , nat, 3))    
  allocate (zstarue0 (3 * nat, 3))    
  allocate (zstarue0_rec (3 * nat, 3))    
  name_rap_mode=' '
  zstarue=0.0_DP
  zstareu0=(0.0_DP,0.0_DP)
  zstarue0=(0.0_DP,0.0_DP)
  zstarue0_rec=(0.0_DP,0.0_DP)
  if (okvan) then
     allocate (int1 ( nhm, nhm, 3, nat, nspin))    
     allocate (int2 ( nhm , nhm , 3 , nat , nat))    
     allocate (int3 ( nhm , nhm , max_irr_dim , nat , nspin))    
     if (okpaw) then
        allocate (int3_paw ( nhm , nhm , max_irr_dim , nat , nspin))
        allocate (becsumort ( nhm*(nhm+1)/2 , nat , nspin, 3*nat))
     endif
     allocate (int4 ( nhm * (nhm + 1)/2,  3 , 3 , nat, nspin))    
     allocate (int5 ( nhm * (nhm + 1)/2 , 3 , 3 , nat , nat))    
     allocate (dpqq( nhm, nhm, 3, ntyp))    
     IF (noncolin) THEN
        ALLOCATE(int1_nc( nhm, nhm, 3, nat, nspin))    
        ALLOCATE(int3_nc( nhm, nhm, max_irr_dim , nat , nspin))    
        ALLOCATE(int4_nc( nhm, nhm, 3, 3, nat, nspin))    
        ALLOCATE(becsum_nc( nhm*(nhm+1)/2, nat, npol, npol))    
        ALLOCATE(alphasum_nc( nhm*(nhm+1)/2, 3, nat, npol, npol))    
        IF (lspinorb) THEN
           ALLOCATE(int2_so( nhm, nhm, 3, nat , nat, nspin))    
           ALLOCATE(int5_so( nhm, nhm, 3, 3, nat , nat, nspin))    
           allocate(dpqq_so( nhm, nhm, nspin, 3, ntyp))    
        END IF
     END IF
     allocate (alphasum ( nhm * (nhm + 1)/2 , 3 , nat , nspin))    
     allocate (this_dvkb3_is_on_file(nksq))    
     this_dvkb3_is_on_file(:)=.false.
  endif
  allocate (this_pcxpsi_is_on_file(nksq,3))
  this_pcxpsi_is_on_file(:,:)=.false.

  IF (noncolin) THEN
     ALLOCATE(alphap_nc(nkb, npol, nbnd , 3 , nksq))    
  ELSE
     ALLOCATE( alphap ( nkb , nbnd , 3 , nksq) )    
  END IF

  ALLOCATE (becp1(nksq))
  DO ik=1,nksq
     call allocate_bec_type ( nkb, nbnd, becp1(ik) )
  END DO
  CALL allocate_bec_type ( nkb, nbnd, becp )

  if (elph) allocate (el_ph_mat( nbnd, nbnd, nks, 3*nat))    
  if (lraman) allocate ( ramtns (3, 3, 3, nat) )
  return
end subroutine allocate_phq
