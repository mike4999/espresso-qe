!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------
subroutine v_of_rho (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, &
     nrx3, nrxx, nl, ngm, gstart, nspin, g, gg, alat, omega, &
     ehart, etxc, vtxc, charge, v)
  !--------------------------------------------------------------------
  !
  !     This routine computes the Hartree and Exchange and Correlation
  !     potential and energies which corresponds to a given charge density
  !     The XC potential is computed in real space, while the
  !     Hartree potential is computed in reciprocal space.
  !
  !
#include "machine.h"
  use parameters
  use gamma, only: nlm
  implicit none
  !
  !    first the dummy variables
  !

  integer :: nspin, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, ngm, nl (ngm),&
       gstart
  ! input: 1=lda, 2=lsda
  ! input: the FFT indices
  ! input: the true array dimensions
  ! input: the total dimension
  ! input: the number of G vectors
  ! input: correspondence G <-> FFT
  ! input: first nonzero G-vector

  real(kind=DP) :: rho (nrxx, nspin), rho_core (nrxx), g (3, ngm), &
       gg (ngm), alat, omega, vtxc, etxc, ehart, charge, v (nrxx, nspin)
  ! input: the valence charge
  ! input: the core charge
  ! input: the G vectors
  ! input: the norm of G vector
  ! input: the length of the cell
  ! input: the volume of the cell
  ! output: the integral V_xc * rho
  ! output: the E_xc energy
  ! output: the hartree energy
  ! output: the integral of the charge
  ! output: the H+xc_up  potential
  !
  real(kind=DP), parameter  :: fpi = 4.d0 * 3.14159265358979d0, &
                               e2  = 2.d0
  !
  !    and the local variables
  !

  real(kind=DP) :: tpiba2, fac
  ! the measure unit in reciprocal space
  ! a multiplicative factors
  real(kind=DP), allocatable ::  aux (:,:), aux1 (:,:)
  ! used to do the fft
  ! auxiliary variable for the potential

  integer :: ir, is, ig
  ! counter on mesh points
  ! counter on spin polarizations
  ! counter on G vectors

  call start_clock ('v_of_rho')
  !
  !  calculate exchange-correlation potential
  !
  call v_xc (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
       nl, ngm, g, nspin, alat, omega, etxc, vtxc, v)
  !
  allocate (aux(2,nrxx),aux1(2,ngm) )
  tpiba2 = (fpi / 2.d0 / alat) **2
  !
  !  copy total rho in aux
  !
  call setv (nrxx, 0.d0, aux (2, 1), 2)
  call DCOPY (nrxx, rho (1, 1), 1, aux (1, 1), 2)
  if (nspin.eq.2) call DAXPY (nrxx, 1.0d0, rho (1, 2), 1, aux (1, 1), 2)
  !
  !  bring rho (aux) to G space
  !

  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
  charge = 0.d0
  if (gg (1) .lt.1.0d-8) charge = omega * aux (1, nl (1) )
#ifdef __PARA
  call reduce (1, charge)
#endif
  !
  !      calculate hartree potential in G-space (NB: V(G=0)=0 )
  !
  ehart = 0.d0
  aux1(:,:) = 0.d0
  do ig = gstart, ngm
     fac = e2 * fpi / (tpiba2 * gg (ig) )
     ehart = ehart + (aux(1, nl(ig))**2 + aux(2,nl(ig))**2) * fac
     aux1 (1, ig) = fac * aux (1, nl (ig) )
     aux1 (2, ig) = fac * aux (2, nl (ig) )
  enddo
  ehart = ehart * omega
#ifdef __PARA
  call reduce (1, ehart)
#endif
  aux(:,:) = 0.d0
  do ig = 1, ngm
     aux (1, nl (ig) ) = aux1 (1, ig)
     aux (2, nl (ig) ) = aux1 (2, ig)
     aux (1, nlm(ig) ) = aux1 (1, ig)
     aux (2, nlm(ig) ) =-aux1 (2, ig)
  enddo
  !
  !      transform hartree potential to real space
  !
  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
  !
  !      add hartree potential to the xc potential
  !
  do is = 1, nspin
     do ir = 1, nrxx
        v (ir, is) = v (ir, is) + aux (1, ir)
     enddo
  enddo

  deallocate (aux,aux1)

  call stop_clock ('v_of_rho')
  return
end subroutine v_of_rho
!
!--------------------------------------------------------------------
subroutine v_xc (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
     nrxx, nl, ngm, g, nspin, alat, omega, etxc, vtxc, v)
  !--------------------------------------------------------------------
  !
  !     Exchange-Correlation potential Vxc(r) from n(r)
  !
#include "machine.h"
  use parameters, only : DP
  use gamma, only: nlm
  implicit none
  !
  ! input
  !

  integer :: nspin, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, ngm, &
       nl(ngm)

  ! nspin=1 :unpolarized, =2 :spin-polarized
  ! the FFT indices
  ! the true FFT array dimensions
  ! the total dimension
  ! the number of G vectors
  ! correspondence G <-> FFT
  real(kind=DP) :: rho (nrxx, nspin), rho_core (nrxx), g (3, ngm), &
       alat, omega
  ! the valence charge
  ! the core charge
  ! the G vectors
  ! the length of the cell
  ! the volume of the cell
  !
  ! output
  !
  real(kind=DP) :: v (nrxx, nspin), vtxc, etxc
  ! V_xc potential
  ! integral V_xc * rho
  ! E_xc energy
  !
  !    local variables
  !
  ! the square of the e charge
  real(kind=DP) :: e2
  parameter (e2 = 2.d0)

  real(kind=DP) :: rhox, arhox, zeta, ex, ec, vx (2), vc (2)
  ! the total charge in each point
  ! the absolute value of the charge
  ! the absolute value of the charge
  ! local exchange energy
  ! local correlation energy
  ! local exchange potential
  ! local correlation potential
  integer :: ir, is, ig, neg (3)
  ! counter on mesh points
  ! counter on spin polarizations
  ! counter on G vectors
  ! number of points with wrong zeta/cha
  !
  !
  !      call start_clock('vxc')
  !
  ! initialization
  !
  etxc = 0.d0
  vtxc = 0.d0

  call setv (nspin * nrxx, 0.d0, v, 1)
  if (nspin.eq.1) then
     !
     ! spin-unpolarized case
     !
     do ir = 1, nrxx
        rhox = rho (ir, nspin) + rho_core (ir)
        arhox = abs (rhox)
        if (arhox.gt.1.d-30) then
           call xc (arhox, ex, ec, vx, vc)
           v (ir, nspin) = e2 * (vx (1) + vc (1) )
           etxc = etxc + e2 * (ex + ec) * rhox
           vtxc = vtxc + v (ir, nspin) * rho (ir, nspin)
        endif
     enddo
  else
     !
     ! spin-polarized case
     !
     neg (1) = 0
     neg (2) = 0
     neg (3) = 0
     do ir = 1, nrxx
        rhox = rho (ir, 1) + rho (ir, 2) + rho_core (ir)
        arhox = abs (rhox)
        if (arhox.gt.1.d-30) then
           zeta = (rho (ir, 1) - rho (ir, 2) ) / arhox
           if (abs (zeta) .gt.1.d0) then
              neg (3) = neg (3) + 1
              zeta = sign (1.d0, zeta)
           endif
           if (rho (ir, 1) .lt.0.d0) neg (1) = neg (1) + 1
           if (rho (ir, 2) .lt.0.d0) neg (2) = neg (2) + 1
           call xc_spin (arhox, zeta, ex, ec, vx (1), vx (2), vc (1), vc (2) )
           do is = 1, nspin
              v (ir, is) = e2 * (vx (is) + vc (is) )
           enddo
           etxc = etxc + e2 * (ex + ec) * rhox
           vtxc = vtxc + v (ir, 1) * rho (ir, 1) + v (ir, 2) * rho (ir, 2)
        endif
     enddo
#ifdef __PARA
     call ireduce (3, neg)
#endif
     if (neg(3).gt.0) write (6,'(/,4x," npt with |zeta| > 1: ",i8, &
          &  ", npt tot ",i8, ",",f10.2, " %" )') neg(3), &
          &  nr1*nr2*nr3, float(neg(3)*100) / real(nr1*nr2*nr3)
     if (neg(1).gt.0) write (6,'(/,4x," npt with rhoup < 0: ",i8, &
          &  ", npt tot ",i8, ",",f10.2, " %" )') neg(1), &
          &  nr1*nr2*nr3, float(neg(1)*100) / real(nr1*nr2*nr3)
     if (neg(2).gt.0) write (6,'(/,4x," npt with rhodw < 0: ",i8, &
          &  ", npt tot ",i8, ",",f10.2, " %" )') neg(2), &
          &  nr1*nr2*nr3, float(neg(2)*100) / real(nr1 * nr2 * nr3)
  endif
  !
  ! energy terms, local-density contribution
  !
  vtxc = omega * vtxc / (nr1 * nr2 * nr3)
  etxc = omega * etxc / (nr1 * nr2 * nr3)
  !
  ! add gradient corrections (if any)
  !
  call gradcorr (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
       nrxx, nl, ngm, g, alat, omega, nspin, etxc, vtxc, v)
#ifdef __PARA
  call reduce (1, vtxc)
  call reduce (1, etxc)
#endif
  !      call stop_clock('vxc')
  !
  return
end subroutine v_xc

