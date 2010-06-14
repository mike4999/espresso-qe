!
! Copyright (C) 2009 A. Smogunov 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
MODULE realus_scatt
!
! Some extra subroutines to the module realus 
! needed for the scattering problem 
!
 INTEGER,  ALLOCATABLE :: orig_or_copy(:,:) 

 CONTAINS

 SUBROUTINE realus_scatt_0()
!
! Calculates orig_or_copy array 
!
   USE constants,        ONLY : pi
   USE ions_base,        ONLY : nat, tau, ityp
   USE cell_base,        ONLY : at, bg 
   USE realus
   USE gvect,            ONLY : nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx
   USE uspp,             ONLY : okvan
   USE uspp_param,       ONLY : upf
   USE mp_global,        ONLY : me_pool
   USE fft_base,         ONLY : dfftp

   IMPLICIT NONE

   INTEGER  :: ia, ir, mbia, roughestimate, idx0, idx, i, j, k, i_lr, ipol
   REAL(DP) :: mbr, mbx, mby, mbz, dmbx, dmby, dmbz, distsq
   REAL(DP) :: inv_nr1, inv_nr2, inv_nr3, boxradsq_ia, posi(3)

   IF ( .NOT. okvan ) RETURN

   CALL qpointlist()

!--   Finds roughestimate
   mbr = MAXVAL( boxrad(:) )
   mbx = mbr*SQRT( bg(1,1)**2 + bg(1,2)**2 + bg(1,3)**2 )
   mby = mbr*SQRT( bg(2,1)**2 + bg(2,2)**2 + bg(2,3)**2 )
   mbz = mbr*SQRT( bg(3,1)**2 + bg(3,2)**2 + bg(3,3)**2 )
   dmbx = 2*ANINT( mbx*nrx1 ) + 2
   dmby = 2*ANINT( mby*nrx2 ) + 2
   dmbz = 2*ANINT( mbz*nrx3 ) + 2
   roughestimate = ANINT( DBLE( dmbx*dmby*dmbz ) * pi / 6.D0 )
!--

   IF (ALLOCATED(orig_or_copy)) DEALLOCATE( orig_or_copy )
   ALLOCATE( orig_or_copy( roughestimate, nat ) )

#if defined (__PARA)
   idx0 = nrx1*nrx2 * SUM ( dfftp%npp(1:me_pool) )
#else
   idx0 = 0
#endif

   inv_nr1 = 1.D0 / DBLE( nr1 )
   inv_nr2 = 1.D0 / DBLE( nr2 )
   inv_nr3 = 1.D0 / DBLE( nr3 )

   DO ia = 1, nat
       IF ( .NOT. upf(ityp(ia))%tvanp ) CYCLE
       mbia = 0
       boxradsq_ia = boxrad(ityp(ia))**2
       DO ir = 1, nrxx
         idx   = idx0 + ir - 1
         k     = idx / (nrx1*nrx2)
         idx   = idx - (nrx1*nrx2)*k
         j     = idx / nrx1
         idx   = idx - nrx1*j
         i     = idx
         DO ipol = 1, 3
           posi(ipol) = DBLE( i )*inv_nr1*at(ipol,1) + &
                        DBLE( j )*inv_nr2*at(ipol,2) + &
                        DBLE( k )*inv_nr3*at(ipol,3)
         END DO
         posi(:) = posi(:) - tau(:,ia)
         CALL cryst_to_cart( 1, posi, bg, -1 )
         IF ( abs(ANINT(posi(3))).gt.1.d-6 ) THEN
           i_lr = 0
         ELSE
           i_lr = 1
         END IF
         posi(:) = posi(:) - ANINT( posi(:) )
         CALL cryst_to_cart( 1, posi, at, 1 )
         distsq = posi(1)**2 + posi(2)**2 + posi(3)**2
         IF ( distsq < boxradsq_ia ) THEN
            mbia = mbia + 1
            orig_or_copy(mbia,ia) = i_lr
         END IF
       END DO
   END DO

   RETURN
 END SUBROUTINE realus_scatt_0

 SUBROUTINE realus_scatt_1(becsum_orig)
!
! Augments the charge and spin densities.
!
   USE ions_base,        ONLY : nat, ityp
   USE lsda_mod,         ONLY : nspin
   USE scf,              ONLY : rho
   USE realus          
   USE uspp,             ONLY : okvan, becsum
   USE uspp_param,       ONLY : upf, nhm, nh
   USE noncollin_module, ONLY : noncolin
   USE spin_orb,         ONLY : domag

   IMPLICIT NONE

   INTEGER  :: ia, nt, ir, irb, ih, jh, ijh, is, nspin0, mbia, nhnt, iqs
   REAL(DP) :: becsum_orig(nhm*(nhm+1)/2,nat,nspin)

   IF (.NOT.okvan) RETURN

   nspin0 = nspin
   IF (noncolin.AND..NOT.domag) nspin0 = 1
   DO is = 1, nspin0
     iqs = 0
     DO ia = 1, nat
        mbia = maxbox(ia)
        IF ( mbia == 0 ) CYCLE
        nt = ityp(ia)
        IF ( .NOT. upf(nt)%tvanp ) CYCLE
        nhnt = nh(nt)
        ijh = 0
        DO ih = 1, nhnt
           DO jh = ih, nhnt
              ijh = ijh + 1
              DO ir = 1, mbia
                 irb = box(ir,ia)
                 iqs = iqs + 1
                 if(orig_or_copy(ir,ia).eq.1) then
                  rho%of_r(irb,is) = rho%of_r(irb,is) + qsave(iqs)*becsum_orig(ijh,ia,is)
                 else
                  rho%of_r(irb,is) = rho%of_r(irb,is) + qsave(iqs)*becsum(ijh,ia,is)
                 endif
              ENDDO
           ENDDO
        ENDDO
     ENDDO
   ENDDO
   RETURN
 END SUBROUTINE realus_scatt_1

END MODULE realus_scatt

