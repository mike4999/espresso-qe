!
! Copyright (C) 2002-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
SUBROUTINE stres_hub ( sigmah )
   !----------------------------------------------------------------------
   !
   ! This routines computes the Hubbard contribution to the internal stress
   ! tensor. It gives in output the array sigmah(i,j) which corresponds to
   ! the quantity -(1/\Omega)dE_{h}/d\epsilon_{i,j}
   !
   USE kinds,     ONLY : DP
   USE ions_base, ONLY : nat, ityp
   USE cell_base, ONLY : omega, at, bg
   USE ldaU,      ONLY : hubbard_lmax, hubbard_l, is_hubbard, &
                         lda_plus_u_kind, U_projection
   USE scf,       ONLY : v
   USE lsda_mod,  ONLY : nspin
   USE symme,     ONLY : symmatrix
   USE io_files,  ONLY : prefix
   USE io_global, ONLY : stdout, ionode
   !
   IMPLICIT NONE
   !
   REAL (DP) :: sigmah(3,3)        ! output: the Hubbard stresses

   INTEGER :: ipol, jpol, na, nt, is, m1,m2
   INTEGER :: ldim
   REAL (DP), ALLOCATABLE :: dns(:,:,:,:)
   !       dns(ldim,ldim,nspin,nat), ! the derivative of the atomic occupations
   !
   CALL start_clock( 'stres_hub' )
   !
   IF (U_projection .NE. "atomic") CALL errore("stres_hub", &
                   " stress for this U_projection_type not implemented",1)
   IF (lda_plus_u_kind.eq.1) CALL errore("stres_hub", &
                   " stress in full LDA+U scheme is not yet implemented",1)

   sigmah(:,:) = 0.d0

   ldim = 2 * Hubbard_lmax + 1
   ALLOCATE (dns(ldim,ldim,nspin,nat))
   dns(:,:,:,:) = 0.d0

#ifdef DEBUG
   DO na=1,nat
      DO is=1,nspin
         nt = ityp(na)
         IF ( is_hubbard(nt) ) THEN
            WRITE( stdout,'(a,2i3)') 'NS(NA,IS) ', na,is
            DO m1=1,ldim
               WRITE( stdout,'(7f10.4)') (v%ns(m1,m2,is,na),m2=1,ldim)
            END DO
         END IF
      END DO
   END DO
#endif
!
!  NB: both ipol and jpol must run from 1 to 3 because this stress 
!      contribution is not in general symmetric when computed only 
!      from k-points in the irreducible wedge of the BZ. 
!      It is (must be) symmetric after symmetrization but this requires 
!      the full stress tensor not only its upper triangular part.
!
   DO ipol = 1,3
      DO jpol = 1,3
         CALL dndepsilon(dns,ldim,ipol,jpol)
         DO na = 1,nat                 
            nt = ityp(na)
            IF ( is_hubbard(nt) ) THEN
               DO is = 1,nspin
#ifdef DEBUG
                  WRITE( stdout,'(a,4i3)') 'DNS(IPOL,JPOL,NA,IS) ', ipol,jpol,na,is
                  WRITE( stdout,'(5f10.4)') ((dns(m1,m2,is,na),m2=1,5),m1=1,5)
#endif
                  DO m2 = 1, 2 * Hubbard_l(nt) + 1
                     DO m1 = 1, 2 * Hubbard_l(nt) + 1
                        sigmah(ipol,jpol) = sigmah(ipol,jpol) - &
                           v%ns(m2,m1,is,na) * dns(m1,m2,is,na) / omega
                     END DO
                  END DO
               END DO
            END IF
         END DO
      END DO
   END DO
   IF (nspin.EQ.1) sigmah(:,:) = 2.d0 * sigmah(:,:)

   CALL symmatrix ( sigmah )
!
! Impose symmetry s(i,j) = s(j,i) to the stress tensor
! it should NOT be needed, let's do it for safety.
!
   DO ipol = 1,3
      DO jpol = ipol,3
         if ( abs( sigmah(ipol,jpol)-sigmah(jpol,ipol) )  > 1.d-6 ) then
             write (stdout,'(2i3,2f12.7)') ipol,jpol,sigmah(ipol,jpol), &
                                                     sigmah(jpol,ipol)
            call errore('stres_hub',' non-symmetric stress contribution',1)
         end if
         sigmah(ipol,jpol) = 0.5d0* ( sigmah(ipol,jpol) + sigmah(jpol,ipol) )
         sigmah(jpol,ipol) = sigmah(ipol,jpol)
      END DO
   END DO
   
   DEALLOCATE (dns)
   !
   CALL stop_clock( 'stres_hub' )
   !
   RETURN
END  SUBROUTINE stres_hub
!
!-----------------------------------------------------------------------
SUBROUTINE dndepsilon ( dns,ldim,ipol,jpol )
   !-----------------------------------------------------------------------
   ! This routine computes the derivative of the ns atomic occupations with
   ! respect to the strain epsilon(ipol,jpol) used to obtain the hubbard
   ! contribution to the internal stres tensor.
   !
   USE kinds,                ONLY : DP
   USE wavefunctions_module, ONLY : evc
   USE ions_base,            ONLY : nat, ityp
   USE control_flags,        ONLY : gamma_only   
   USE klist,                ONLY : nks, xk, ngk
   USE ldaU,                 ONLY : wfcU, nwfcU, offsetU, Hubbard_l, &
                                    is_hubbard, oatwfc, swfcatom, copy_U_wfc
   USE lsda_mod,             ONLY : lsda, nspin, current_spin, isk
   USE wvfct,                ONLY : nbnd, npwx, npw, igk, wg
   USE uspp,                 ONLY : nkb, vkb
   USE becmod,               ONLY : bec_type, becp, calbec, &
                                    allocate_bec_type, deallocate_bec_type
   USE io_files,             ONLY : iunigk, nwordwfc, iunwfc, &
                                    iunat, iunhub, nwordwfcU, nwordatwfc
   USE buffers,              ONLY : get_buffer
   USE mp_global,            ONLY : inter_pool_comm
   USE mp,                   ONLY : mp_sum

   IMPLICIT NONE
   !
   ! I/O variables first
   !
   INTEGER :: ipol, jpol, ldim
   REAL (DP) :: dns(ldim,ldim,nspin,nat)
   !
   ! local variable
   !
   INTEGER :: ik,    & ! counter on k points
              ibnd,  & !    "    "  bands
              is,    & !    "    "  spins
              na, nt, m1, m2

   COMPLEX (DP), ALLOCATABLE :: spsi(:,:)
   type (bec_type) :: proj, dproj
   !
   !
   ALLOCATE ( spsi(npwx,nbnd) )
   call allocate_bec_type ( nwfcU,nbnd, proj)
   call allocate_bec_type ( nwfcU,nbnd, dproj )
   call allocate_bec_type ( nkb,nbnd, becp )
   !
   ! D_Sl for l=1 and l=2 are already initialized, for l=0 D_S0 is 1
   !
   ! Offset of atomic wavefunctions initialized in setup and stored in oatwfc
  
   dns(:,:,:,:) = 0.d0
   !
   !    we start a loop on k points
   !
   IF (nks > 1) REWIND (iunigk)

   DO ik = 1, nks
      IF (lsda) current_spin = isk(ik)
      IF (nks > 1) READ (iunigk) igk
      npw = ngk(ik)
      !
      ! now we need the first derivative of proj with respect to
      ! epsilon(ipol,jpol)
      !
      CALL get_buffer (evc, nwordwfc, iunwfc, ik)
      CALL init_us_2 (npw,igk,xk(1,ik),vkb)
      CALL calbec( npw, vkb, evc, becp )
      CALL s_psi  (npwx, npw, nbnd, evc, spsi )
! read atomic wfc - swfcatom is used as work space
      CALL get_buffer (swfcatom, nwordatwfc, iunat, ik)
!!!
      call copy_U_wfc ( )
!!!  
      IF ( gamma_only ) THEN
         CALL dprojdepsilon_gamma (wfcU, spsi, ipol, jpol, dproj%r)
      ELSE
         CALL dprojdepsilon_k (wfcU, spsi, ik, ipol, jpol, dproj%k)
      END IF
      CALL get_buffer (wfcU, nwordwfcU, iunhub, ik)
      CALL calbec ( npw, wfcU, evc, proj)
      !
      ! compute the derivative of the occupation numbers (quantities dn(m1,m2))
      ! of the atomic orbitals. They are real quantities as well as n(m1,m2)
      !
      DO na = 1,nat
         nt = ityp(na)
         IF ( is_hubbard(nt) ) THEN        
            DO m1 = 1, 2 * Hubbard_l(nt) + 1
               DO m2 = m1, 2 * Hubbard_l(nt) + 1
                  IF ( gamma_only ) THEN
                     DO ibnd = 1,nbnd
                        dns(m1,m2,current_spin,na) = &
                           dns(m1,m2,current_spin,na) + wg(ibnd,ik) *&
                                   ( proj%r(offsetU(na)+m1,ibnd) *      &
                                    dproj%r(offsetU(na)+m2,ibnd) +      &
                                    dproj%r(offsetU(na)+m1,ibnd) *      &
                                     proj%r(offsetU(na)+m2,ibnd))
                     END DO
                  ELSE
                     DO ibnd = 1,nbnd
                        dns(m1,m2,current_spin,na) = &
                           dns(m1,m2,current_spin,na) + wg(ibnd,ik) *&
                               DBLE(proj%k(offsetU(na)+m1,ibnd) *      &
                              CONJG(dproj%k(offsetU(na)+m2,ibnd) ) +    &
                                    dproj%k(offsetU(na)+m1,ibnd)*       &
                              CONJG(proj%k(offsetU(na)+m2,ibnd) ) )
                     END DO
                  END IF
               END DO
            END DO
         END IF
      END DO
   END DO                 ! on k-points
   !
   CALL mp_sum( dns, inter_pool_comm )
   !
   ! In nspin.eq.1 k-point weight wg is normalized to 2 el/band 
   ! in the whole BZ but we are interested in dns of one spin component
   !
   IF (nspin.EQ.1) dns = 0.5d0 * dns
   !
   ! impose hermiticity of dn_{m1,m2}
   !
   DO na = 1,nat
      nt = ityp(na)
      DO is = 1,nspin
         DO m1 = 1, 2 * Hubbard_l(nt) + 1
            DO m2 = m1+1, 2 * Hubbard_l(nt) + 1
               dns(m2,m1,is,na) = dns(m1,m2,is,na)
            END DO
         END DO
      END DO
   END DO

   DEALLOCATE ( spsi )
   call deallocate_bec_type (proj)
   call deallocate_bec_type (dproj)
   call deallocate_bec_type (becp)
   RETURN
END SUBROUTINE dndepsilon
!
!-----------------------------------------------------------------------
SUBROUTINE dprojdepsilon_k ( wfcU, spsi, ik, ipol, jpol, dproj )
   !-----------------------------------------------------------------------
   !
   ! This routine computes the first derivative of the projection
   ! <\fi^{at}_{I,m1}|S|\psi_{k,v,s}> with respect to the strain epsilon(i,j)
   ! (we remember that ns_{I,s,m1,m2} = \sum_{k,v}
   ! f_{kv} <\fi^{at}_{I,m1}|S|\psi_{k,v,s}><\psi_{k,v,s}|S|\fi^{at}_{I,m2}>)
   !
   USE kinds,                ONLY : DP
   USE cell_base,            ONLY : tpiba
   USE ions_base,            ONLY : nat, ntyp => nsp, ityp
   USE gvect,                ONLY : g
   USE klist,                ONLY : nks, xk
   USE ldaU,                 ONLY : hubbard_l, is_hubbard, nwfcU
   USE lsda_mod,             ONLY : lsda, nspin, current_spin, isk
   USE wvfct,                ONLY : nbnd, npwx, npw, igk, wg
   USE uspp,                 ONLY : nkb, vkb, qq
   USE uspp_param,           ONLY : upf, nhm, nh
   USE wavefunctions_module, ONLY : evc
   USE becmod,               ONLY : bec_type, becp, calbec
   USE mp_global,            ONLY : intra_bgrp_comm
   USE mp,                   ONLY : mp_sum

   IMPLICIT NONE
   !
   ! I/O variables first
   !
   INTEGER, INTENT(IN) :: ik, ipol, jpol
   COMPLEX (DP), INTENT(IN)  :: &
           wfcU(npwx,nwfcU), &! the atomic wfc
           spsi(npwx,nbnd)          ! S|evc>
   COMPLEX (DP), INTENT(OUT) :: &
           dproj(nwfcU,nbnd)     ! the derivative of the projection
   !
   INTEGER :: i, ig, ijkb0, na, ibnd, iwf, nt, ih,jh
   REAL (DP) :: xyz(3,3), q, a1, a2
   REAL (DP), PARAMETER :: eps=1.0d-8
   COMPLEX (DP), EXTERNAL :: zdotc
   COMPLEX (DP), ALLOCATABLE :: &
           dwfc(:,:), aux(:,:), dbeta(:,:), aux1(:,:), &
           betapsi(:,:), dbetapsi(:,:), wfatbeta(:,:), wfatdbeta(:,:)

   !       dwfc(npwx,nwfcU),   ! the derivative of the atomic d wfc
   !       aux(npwx,nwfcU),    ! auxiliary array
   !       dbeta(npwx,nkb),       ! the derivative of the beta function
   !       aux1(npwx,nkb),        ! auxiliary array
   !       betapsi(nhm,nbnd),     ! <beta|evc>
   !       dbetapsi(nhm,nbnd),    ! <dbeta|evc>
   !       wfatbeta(nwfcU,nhm),! <wfc|beta>
   !       wfatdbeta(nwfcU,nhm)! <wfc|dbeta>

   REAL (DP), ALLOCATABLE :: gk(:,:), qm1(:)
   !       gk(3,npwx),
   !       qm1(npwx)
   !
   ! xyz are the three unit vectors in the x,y,z directions
   xyz(:,:) = 0.d0
   DO i=1,3
      xyz(i,i) = 1.d0
   END DO

   dproj(:,:) = (0.d0,0.d0)
   !
   ! At first the derivatives of the atomic wfcs: we compute the term
   ! <d\fi^{at}_{I,m1}/d\epsilon(ipol,jpol)|S|\psi_{k,v,s}>
   !
   ALLOCATE ( qm1(npwx), gk(3,npwx) )
   ALLOCATE ( dwfc(npwx,nwfcU), aux(npwx,nwfcU) )

   ! here the derivative of the Bessel function
   CALL gen_at_dj (ik,nwfcU,is_hubbard,hubbard_l,dwfc)
   ! and here the derivative of the spherical harmonic
   CALL gen_at_dy (ik,nwfcU,is_hubbard,hubbard_l,xyz(1,ipol),aux)

   DO ig = 1,npw
      gk(1,ig) = (xk(1,ik)+g(1,igk(ig)))*tpiba
      gk(2,ig) = (xk(2,ik)+g(2,igk(ig)))*tpiba
      gk(3,ig) = (xk(3,ik)+g(3,igk(ig)))*tpiba
      q = SQRT(gk(1,ig)**2+gk(2,ig)**2+gk(3,ig)**2)
      IF (q.GT.eps) THEN
         qm1(ig)=1.d0/q
      ELSE
         qm1(ig)=0.d0
      END IF
      a1 = -gk(jpol,ig)
      a2 = -gk(ipol,ig)*gk(jpol,ig)*qm1(ig)
      DO iwf = 1,nwfcU
         dwfc(ig,iwf) = aux(ig,iwf)*a1 + dwfc(ig,iwf)*a2
      END DO
   END DO
   IF (ipol.EQ.jpol) dwfc(1:npw,:) = dwfc(1:npw,:) - wfcU(1:npw,:)*0.5d0

   CALL calbec ( npw, dwfc, spsi, dproj )

   DEALLOCATE ( dwfc, aux )
   !
   ! Now the derivatives of the beta functions: we compute the term
   ! <\fi^{at}_{I,m1}|dS/d\epsilon(ipol,jpol)|\psi_{k,v,s}>
   !
   ALLOCATE (dbeta(npwx,nkb), aux1(npwx,nkb), &
             dbetapsi(nhm,nbnd), betapsi(nhm,nbnd), wfatbeta(nwfcU,nhm), &
             wfatdbeta(nwfcU,nhm) )

   ! here the derivative of the Bessel function
   CALL gen_us_dj (ik,dbeta)
   ! and here the derivative of the spherical harmonic
   CALL gen_us_dy (ik,xyz(1,ipol),aux1)

   ijkb0 = 0
   DO nt=1,ntyp
      DO na=1,nat
         IF ( ityp(na) .EQ. nt ) THEN
            DO ih=1,nh(nt)
               ijkb0 = ijkb0 + 1
               ! now we compute the true dbeta function
               DO ig = 1,npw
                  dbeta(ig,ijkb0) = - aux1(ig,ijkb0)*gk(jpol,ig) - &
                        dbeta(ig,ijkb0) * gk(ipol,ig) * gk(jpol,ig) * qm1(ig)
                  IF (ipol.EQ.jpol) &
                     dbeta(ig,ijkb0) = dbeta(ig,ijkb0) - vkb(ig,ijkb0)*0.5d0
               END DO
               DO ibnd = 1,nbnd
                  betapsi(ih,ibnd)= becp%k(ijkb0,ibnd)
                  dbetapsi(ih,ibnd)= zdotc(npw,dbeta(1,ijkb0),1,evc(1,ibnd),1)
               END DO
               DO iwf=1,nwfcU
                  wfatbeta(iwf,ih) = zdotc(npw,wfcU(1,iwf),1,vkb(1,ijkb0),1)
                  wfatdbeta(iwf,ih)= zdotc(npw,wfcU(1,iwf),1,dbeta(1,ijkb0),1)
               END DO
            END DO
            !
            CALL mp_sum( dbetapsi, intra_bgrp_comm )
            CALL mp_sum( wfatbeta, intra_bgrp_comm )
            CALL mp_sum( wfatdbeta, intra_bgrp_comm )
            !
            DO ibnd = 1,nbnd
               DO ih=1,nh(nt)
                  DO jh = 1,nh(nt)
                     DO iwf=1,nwfcU
                        dproj(iwf,ibnd) = dproj(iwf,ibnd) +               &
                                          qq(ih,jh,nt) *                  &
                               ( wfatdbeta(iwf,ih)*betapsi(jh,ibnd) +     &
                                 wfatbeta(iwf,ih)*dbetapsi(jh,ibnd) )
                     END DO
                  END DO
               END DO
            END DO
         END IF
      END DO
   END DO


   DEALLOCATE (dbeta, aux1, dbetapsi, betapsi, wfatbeta, wfatdbeta )
   DEALLOCATE ( qm1, gk )

   RETURN
END SUBROUTINE dprojdepsilon_k
!
!-----------------------------------------------------------------------
SUBROUTINE dprojdepsilon_gamma ( wfcU, spsi, ipol, jpol, dproj )
   !-----------------------------------------------------------------------
   !
   ! This routine computes the first derivative of the projection
   ! <\fi^{at}_{I,m1}|S|\psi_{k,v,s}> with respect to the strain epsilon(i,j)
   ! (we remember that ns_{I,s,m1,m2} = \sum_{k,v}
   ! f_{kv} <\fi^{at}_{I,m1}|S|\psi_{k,v,s}><\psi_{k,v,s}|S|\fi^{at}_{I,m2}>)
   !
   USE kinds,                ONLY : DP
   USE cell_base,            ONLY : tpiba
   USE ions_base,            ONLY : nat, ntyp => nsp, ityp
   USE gvect,                ONLY : g, gstart
   USE klist,                ONLY : nks, xk
   USE ldaU,                 ONLY : is_hubbard, hubbard_l, nwfcU
   USE lsda_mod,             ONLY : lsda, nspin, current_spin, isk
   USE wvfct,                ONLY : nbnd, npwx, npw, igk, wg
   USE uspp,                 ONLY : nkb, vkb, qq
   USE uspp_param,           ONLY : upf, nhm, nh
   USE wavefunctions_module, ONLY : evc
   USE becmod,               ONLY : bec_type, becp, calbec
   USE mp_global,            ONLY : intra_bgrp_comm
   USE mp,                   ONLY : mp_sum

   IMPLICIT NONE
   !
   ! I/O variables first
   !
   INTEGER, INTENT(IN) :: ipol, jpol
   COMPLEX (DP), INTENT(IN)  :: &
           wfcU(npwx,nwfcU), &! the atomic wfc
           spsi(npwx,nbnd)          ! S|evc>
   REAL (DP), INTENT(OUT) :: &
           dproj(nwfcU,nbnd)     ! the derivative of the projection
   !
   INTEGER :: ik=1, i, ig, ijkb0, na, ibnd, iwf, nt, ih,jh
   REAL (DP) :: xyz(3,3), q, a1, a2
   REAL (DP), PARAMETER :: eps=1.0d-8
   REAL (DP), EXTERNAL :: ddot
   COMPLEX (DP), ALLOCATABLE :: &
           dwfc(:,:), aux(:,:), dbeta(:,:), aux1(:,:)
   !       dwfc(npwx,nwfcU),   ! the derivative of the atomic d wfc
   !       aux(npwx,nwfcU),    ! auxiliary array
   !       dbeta(npwx,nkb),       ! the derivative of the beta function
   !       aux1(npwx,nkb),        ! auxiliary array
   REAL (DP), ALLOCATABLE :: &
           betapsi(:,:), dbetapsi(:,:), wfatbeta(:,:), wfatdbeta(:,:)
   !       betapsi(nhm,nbnd),     ! <beta|evc>
   !       dbetapsi(nhm,nbnd),    ! <dbeta|evc>
   !       wfatbeta(nwfcU,nhm),! <wfc|beta>
   !       wfatdbeta(nwfcU,nhm)! <wfc|dbeta>

   REAL (DP), ALLOCATABLE :: gk(:,:), qm1(:)
   !       gk(3,npwx),
   !       qm1(npwx)
   !
   ! xyz are the three unit vectors in the x,y,z directions
   xyz(:,:) = 0.d0
   DO i=1,3
      xyz(i,i) = 1.d0
   END DO

   dproj(:,:) = 0.d0
   !
   ! At first the derivatives of the atomic wfcs: we compute the term
   ! <d\fi^{at}_{I,m1}/d\epsilon(ipol,jpol)|S|\psi_{k,v,s}>
   !
   ALLOCATE ( qm1(npwx), gk(3,npwx) )
   ALLOCATE ( dwfc(npwx,nwfcU), aux(npwx,nwfcU) )

   ! here the derivative of the Bessel function
   CALL gen_at_dj (ik,nwfcU,is_hubbard,hubbard_l,dwfc)
   ! and here the derivative of the spherical harmonic
   CALL gen_at_dy (ik,nwfcU,is_hubbard,hubbard_l,xyz(1,ipol),aux)

   DO ig = 1,npw
      gk(1,ig) = (xk(1,ik)+g(1,igk(ig)))*tpiba
      gk(2,ig) = (xk(2,ik)+g(2,igk(ig)))*tpiba
      gk(3,ig) = (xk(3,ik)+g(3,igk(ig)))*tpiba
      q = SQRT(gk(1,ig)**2+gk(2,ig)**2+gk(3,ig)**2)
      IF (q.GT.eps) THEN
         qm1(ig)=1.d0/q
      ELSE
         qm1(ig)=0.d0
      END IF
      a1 = -gk(jpol,ig)
      a2 = -gk(ipol,ig)*gk(jpol,ig)*qm1(ig)
      DO iwf = 1,nwfcU
         dwfc(ig,iwf) = aux(ig,iwf)*a1 + dwfc(ig,iwf)*a2
      END DO
   END DO
   IF (ipol.EQ.jpol) dwfc(1:npw,:) = dwfc(1:npw,:) - wfcU(1:npw,:)*0.5d0

   CALL calbec ( npw, dwfc, spsi, dproj )

   DEALLOCATE ( dwfc, aux )
   !
   ! Now the derivatives of the beta functions: we compute the term
   ! <\fi^{at}_{I,m1}|dS/d\epsilon(ipol,jpol)|\psi_{k,v,s}>
   !
   ALLOCATE (dbeta(npwx,nkb), aux1(npwx,nkb), &
             dbetapsi(nhm,nbnd), betapsi(nhm,nbnd), &
             wfatbeta(nwfcU,nhm), wfatdbeta(nwfcU,nhm) )

   ! here the derivative of the Bessel function
   CALL gen_us_dj (ik,dbeta)
   ! and here the derivative of the spherical harmonic
   CALL gen_us_dy (ik,xyz(1,ipol),aux1)

   ijkb0 = 0
   DO nt=1,ntyp
      DO na=1,nat
         IF ( ityp(na) .EQ. nt ) THEN
            DO ih=1,nh(nt)
               ijkb0 = ijkb0 + 1
               ! now we compute the true dbeta function
               DO ig = 1,npw
                  dbeta(ig,ijkb0) = - aux1(ig,ijkb0)*gk(jpol,ig) - &
                        dbeta(ig,ijkb0) * gk(ipol,ig) * gk(jpol,ig) * qm1(ig)
                  IF (ipol.EQ.jpol) &
                     dbeta(ig,ijkb0) = dbeta(ig,ijkb0) - vkb(ig,ijkb0)*0.5d0
               END DO
               DO ibnd = 1,nbnd
                  betapsi(ih,ibnd)= becp%r(ijkb0,ibnd)
                  dbetapsi(ih,ibnd) = 2.0_dp * &
                      ddot(2*npw,dbeta(1,ijkb0),1,evc(1,ibnd),1)
                  IF ( gstart == 2 ) dbetapsi(ih,ibnd) = &
                        dbetapsi(ih,ibnd) - dbeta(1,ijkb0)*evc(1,ibnd)
               END DO
               DO iwf=1,nwfcU
                  wfatbeta(iwf,ih) = 2.0_dp * &
                    ddot(2*npw,wfcU(1,iwf),1,vkb(1,ijkb0),1)
                  IF ( gstart == 2 ) wfatbeta(iwf,ih) = &
                      wfatbeta(iwf,ih) - wfcU(1,iwf)*vkb(1,ijkb0)
                  wfatdbeta(iwf,ih)= 2.0_dp * &
                    ddot(2*npw,wfcU(1,iwf),1,dbeta(1,ijkb0),1)
                  IF ( gstart == 2 ) wfatdbeta(iwf,ih) = &
                      wfatdbeta(iwf,ih) - wfcU(1,iwf)*dbeta(1,ijkb0)
               END DO
            END DO
            !
            CALL mp_sum( dbetapsi, intra_bgrp_comm )
            CALL mp_sum( wfatbeta, intra_bgrp_comm )
            CALL mp_sum( wfatdbeta, intra_bgrp_comm )
            !
            DO ibnd = 1,nbnd
               DO ih=1,nh(nt)
                  DO jh = 1,nh(nt)
                     DO iwf=1,nwfcU
                        dproj(iwf,ibnd) = dproj(iwf,ibnd) +               &
                                          qq(ih,jh,nt) *                  &
                               ( wfatdbeta(iwf,ih)*betapsi(jh,ibnd) +     &
                                 wfatbeta(iwf,ih)*dbetapsi(jh,ibnd) )
                     END DO
                  END DO
               END DO
            END DO
         END IF
      END DO
   END DO

   DEALLOCATE (dbeta, aux1, dbetapsi, betapsi, wfatbeta, wfatdbeta )
   DEALLOCATE ( qm1, gk )

   RETURN
END SUBROUTINE dprojdepsilon_gamma
