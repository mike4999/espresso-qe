!
! Copyright (C) 2003 A. Smogunov 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
! Generalized to spinor wavefunctions and spin-orbit Oct. 2004 (ADC).
!
#include "f_defs.h"
!
SUBROUTINE poten(vppot,nrz,z) 
!
! This subroutine computes the 2D Fourier components of the
! local potential in each slab.
!
  USE pwcom
  USE noncollin_module, ONLY : noncolin, npol
  USE cond
  USE mp,               ONLY : mp_bcast
  USE io_global,        ONLY : ionode_id 

  IMPLICIT NONE

  INTEGER ::                                                & 
             i, j, ij, ijx, k, n, p, il, ik, kstart, klast, &
             ix, jx, kx, ir, ir1, ixy, nrz, info
  INTEGER :: iis, jjs, is(4), js(4), ispin, nspin_eff
  INTEGER, ALLOCATABLE :: ipiv(:) 

  REAL(kind=DP), PARAMETER :: eps = 1.d-8
  REAL(kind=DP) :: arg, bet, z(nrz+1), zlen
  REAL(kind=DP), ALLOCATABLE :: gz(:), allv(:), auxr(:)

  COMPLEX(kind=DP), PARAMETER :: cim = (0.d0,1.d0)
  COMPLEX(kind=DP) :: caux, vppot(nrz,nrx*nry,npol,npol)
  COMPLEX(kind=DP), ALLOCATABLE :: aux(:), amat(:,:), amat0(:,:)
  COMPLEX(kind=DP), ALLOCATABLE :: vppot0(:,:,:,:)

  CALL start_clock('poten')
  ALLOCATE( ipiv( nrz ) )
  ALLOCATE( gz( nrz ) )
  ALLOCATE( aux( nrx1*nrx2*nrx3 ) )
  ALLOCATE( auxr( nrxx ) )
  ALLOCATE( amat( nrz, nrz ) )
  ALLOCATE( amat0( nrz, nrz ) )


  zlen = at(3,3)

!
!  Compute the Gz vectors in the z direction
!
  DO k = 1, nrz
     il = k-1
     IF (il.GT.nrz/2) il = il-nrz
     gz(k) = il*bg(3,3)
  ENDDO
!
! set up the matrix for the linear system
!
DO n=1,nrz
   DO p=1,nrz
      arg=gz(n)*z(p)*tpi
      bet=gz(n)*(z(p+1)-z(p))*tpi
      IF (ABS(gz(n)).GT.eps) THEN
        caux=cim*(CMPLX(COS(bet),-SIN(bet))-(1.d0,0.d0))  &
                                    /zlen/gz(n)/tpi
      ELSE
        caux=(z(p+1)-z(p))/zlen
      ENDIF
      amat0(n,p)=CMPLX(COS(arg),-SIN(arg))*caux
   ENDDO
ENDDO
IF (noncolin) THEN
   nspin_eff=4
   ij=0
   DO iis=1,2
      DO jjs=1,2
         ij=ij+1
         is(ij)=iis
         js(ij)=jjs
      ENDDO
   ENDDO
ELSE
   nspin_eff=1
   is(1)=1
   js(1)=1
ENDIF
!
!     To form local potential on the real space mesh
!
!
#ifdef __PARA
  allocate ( allv(nrx1*nrx2*nrx3) )
#endif

vppot = 0.d0
DO ispin=1,nspin_eff
   IF (noncolin) THEN
      IF (ispin==1) THEN
         auxr(:) = vltot(:)+vr(:,1)
      ELSE
         auxr(:) = vr(:,ispin)
      ENDIF
   ELSE
      auxr(:) = vltot(:) + vr(:,iofspin) 
   ENDIF
!
! To collect the potential from different CPUs
!
#ifdef __PARA
  call gather( auxr, allv )
  CALL mp_bcast( allv, ionode_id )
  aux = CMPLX(allv)
#else
  aux = CMPLX(auxr)
#endif
!
! To find FFT of the local potential
!
#ifdef __PARA
!
!  This FFT is needed to make a non-parallel FFT in the parallel case
!
  CALL cft3sp(aux,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
#else
  CALL cft3(aux,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
#endif

  DO i = 1, nrx
    IF(i.GT.nrx/2+1) THEN
        ix = nr1-(nrx-i) 
    ELSE
        ix = i
    ENDIF
    DO j = 1, nry
      IF(j.GT.nry/2+1) THEN
         jx = nr2-(nry-j)
      ELSE
         jx = j
      ENDIF 
      ij = i+(j-1)*nrx
      ijx = ix+(jx-1)*nrx1 

      DO k = 1, nrz
        il = k-1
        IF (il.GT.nrz/2) il = il-nrz
        IF(il.LE.nr3/2.AND.il.GE.-(nr3-1)/2) THEN

         IF(k.GT.nrz/2+1) THEN 
            kx = nr3-(nrz-k)  
         ELSE
            kx = k
         ENDIF 
         vppot(k, ij, is(ispin), js(ispin)) = aux(ijx+(kx-1)*nrx1*nrx2)

        ENDIF
      ENDDO
    ENDDO
  ENDDO
!
! solve the linear system
!
  amat=amat0
  CALL ZGESV(nrz, nrx*nry, amat, nrz, ipiv, vppot(1,1,is(ispin),js(ispin)),&
                                             nrz, info)
  CALL errore ('poten','info different from zero',ABS(info))
ENDDO

IF (noncolin) THEN
   ALLOCATE( vppot0(nrz, nrx * nry, npol, npol) )
   vppot0=vppot
   vppot(:,:,1,1)=vppot0(:,:,1,1)+vppot0(:,:,2,2)
   vppot(:,:,1,2)=vppot0(:,:,1,2)-(0.d0,1.d0)*vppot0(:,:,2,1)
   vppot(:,:,2,1)=vppot0(:,:,1,2)+(0.d0,1.d0)*vppot0(:,:,2,1)
   vppot(:,:,2,2)=vppot0(:,:,1,1)-vppot0(:,:,2,2)
   DEALLOCATE( vppot0 )
ENDIF

!  do p = 1, nrz
!    write(6,'(i5,2f12.6)') p, real(vppot(p,1,1,1)), imag(vppot(p,1,1,1))
!  enddo
!  stop

  DEALLOCATE(ipiv) 
  DEALLOCATE(gz) 
  DEALLOCATE(aux) 
  DEALLOCATE(auxr) 
  DEALLOCATE(amat) 
  DEALLOCATE(amat0) 
#ifdef __PARA
  deallocate(allv)
#endif

  CALL stop_clock('poten')

  RETURN
END SUBROUTINE poten
