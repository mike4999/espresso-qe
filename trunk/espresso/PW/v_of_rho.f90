!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------
subroutine v_of_rho (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, &
     nrx3, nrxx, nl, ngm, gstart, nspin, g, gg, alat, omega, &
     ehart, etxc, vtxc, etotefield, charge, v)
  !--------------------------------------------------------------------
  !
  !     This routine computes the Hartree and Exchange and Correlation
  !     potential and energies which corresponds to a given charge density
  !     The XC potential is computed in real space, while the
  !     Hartree potential is computed in reciprocal space.
  !
  !
  USE io_global,  ONLY : stdout
  USE kinds, only: DP
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
       gg (ngm), alat, omega, vtxc, etxc, ehart, charge, etotefield, &
       v (nrxx, nspin)
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
  integer :: is
  !
  call start_clock ('v_of_rho')
  !
  !  calculate exchange-correlation potential
  !
  call v_xc (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
       nl, ngm, g, nspin, alat, omega, etxc, vtxc, v)
  !
  !  calculate hartree potential
  !
  call v_h (rho, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
       nl, ngm, gg, gstart, nspin, alat, omega, ehart, charge, v)
  !
  do is=1,nspin
     call add_efield(rho,v(1,is),etotefield)
  enddo
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
  USE io_global,  ONLY : stdout
  USE kinds, only : DP
  implicit none
  !
  ! input
  !

  integer :: nspin, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, ngm, &
       nl (ngm)
  !  nspin=1 :unpolarized, =2 :spin-polarized
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
  real(kind=DP), parameter :: e2 = 2.d0

  real(kind=DP) :: rhox, arhox, zeta, ex, ec, vx (2), vc (2), rhoneg(2)
  ! rhox: total (valence+pseudocore if present) charge in each point
  ! arhox: abs(rhox)
  ! zeta: spin polarization ( -1 <= zeta <= 1)
  ! ex, ec: local exchange and correlation energies
  ! vx, vc: local exchange and correlation potentials
  ! rhoneg: integral of the negative charge
  integer :: ir, is, ig
  ! counter on mesh points
  ! counter on spin polarizations
  ! counter on G vectors
  !
  !      call start_clock('vxc')
  !
  ! initialization
  !
  etxc = 0.d0
  vtxc = 0.d0
  v(:,:) = 0.d0
  rhoneg(:)=0.d0

  if (nspin == 1) then
     !
     ! spin-unpolarized case
     !
     do ir = 1, nrxx
        rhox = rho (ir, nspin) + rho_core (ir)
        arhox = abs (rhox)
        if (arhox.gt.1.d-30) then
           CALL xc( arhox, ex, ec, vx(1), vc(1) )
           v(ir,nspin) = e2 * (vx(1) + vc(1) )
           etxc = etxc + e2 * (ex + ec) * rhox
           vtxc = vtxc + v(ir,nspin) * rho(ir,nspin)
        endif
        if (rho(ir,nspin) < 0.d0) rhoneg(1) = rhoneg(1) - rho(ir,nspin)
     enddo
  else
     !
     ! spin-polarized case
     !
     do ir = 1, nrxx
        rhox = rho(ir,1) + rho(ir,2) + rho_core(ir)
        arhox = abs(rhox)
        if (arhox.gt.1.d-30) then
           zeta = ( rho(ir,1) - rho(ir,2) ) / arhox
           if (abs(zeta) .gt.1.d0) then
              zeta = sign(1.d0,zeta)
           endif
           call xc_spin (arhox, zeta, ex, ec, vx(1), vx(2), vc(1), vc(2) )
           do is = 1, nspin
              v(ir,is) = e2 * (vx(is) + vc(is) )
           enddo
           etxc = etxc + e2 * (ex + ec) * rhox
           vtxc = vtxc + v(ir,1) * rho(ir,1) + v(ir,2) * rho(ir,2)
        endif
        if (rho(ir,1) < 0.d0) rhoneg(1) = rhoneg(1) - rho(ir,1) 
        if (rho(ir,2) < 0.d0) rhoneg(2) = rhoneg(2) - rho(ir,2) 
     enddo
  endif
#ifdef __PARA
  call reduce (2, rhoneg)
#endif
  rhoneg(:) = rhoneg(:) * omega / (nr1 * nr2 * nr3)
  if (rhoneg(1) > 1.0d-8 .OR. rhoneg(2) > 1.0d-8 ) then
     WRITE( stdout,'(/,4x," negative rho (up, down): ",2e10.3)') rhoneg
  end if
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
!
!--------------------------------------------------------------------
subroutine v_h (rho, nr1, nr2, nr3, nrx1, nrx2, nrx3, &
     nrxx, nl, ngm, gg, gstart, nspin, alat, omega, ehart, charge, v)
  !--------------------------------------------------------------------
  !
  !     Hartree potential VH(r) from n(r)
  !
  USE kinds,  ONLY: DP
  USE gvect, ONLY: nlm
  USE wvfct, ONLY: gamma_only
  implicit none
  !
  !    input
  !
  integer :: nspin, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, ngm, &
       gstart, nl (ngm)
  real(kind=DP) :: rho (nrxx, nspin), gg (ngm), alat, omega
  !
  !    output
  !
  real(kind=DP) :: v (nrxx, nspin), ehart, charge
  !
  !    local variables
  !
  real(kind=DP), parameter  :: fpi = 4.d0 * 3.14159265358979d0, &
                               e2  = 2.d0
  real(kind=DP) :: tpiba2, fac
  real(kind=DP), allocatable ::  aux (:,:), aux1 (:,:)
  integer :: ir, is, ig
  !
  !      call start_clock('vh')
  !
  allocate (aux(2,nrxx), aux1(2,ngm) )
  tpiba2 = (fpi / 2.d0 / alat) **2
  !
  !  copy total rho in aux
  !
  aux(2,:) = 0.d0
  aux(1,:) = rho(:,1)
  if (nspin == 2) aux(1,:) = aux(1,:) + rho(:,2)
  !
  !  bring rho (aux) to G space
  !
  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, -1)
  charge = 0.d0
  if (gstart == 2) charge = omega * aux(1,nl(1))
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
     ehart = ehart + (aux(1,nl(ig))**2 + aux(2,nl(ig))**2) * fac
     aux1(1,ig) = fac * aux(1,nl(ig))
     aux1(2,ig) = fac * aux(2,nl(ig))
  enddo
  if (gamma_only) then
     ehart = ehart * omega
  else
     ehart = ehart * omega / 2.d0
  end if
#ifdef __PARA
  call reduce (1, ehart)
#endif
  aux(:,:) = 0.d0
  do ig = 1, ngm
     aux(1,nl(ig)) = aux1(1,ig)
     aux(2,nl(ig)) = aux1(2,ig)
  enddo
  if (gamma_only) then
     do ig = 1, ngm
        aux(1,nlm(ig)) =   aux1(1,ig)
        aux(2,nlm(ig)) = - aux1(2,ig)
     enddo
  end if
  !
  !      transform hartree potential to real space
  !
  call cft3 (aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
  !
  !      add hartree potential to the xc potential
  !
  do is = 1, nspin
     do ir = 1, nrxx
        v(ir,is) = v(ir,is) + aux(1,ir)
     enddo
  enddo


  deallocate (aux,aux1)
  !
  !      call stop_clock('vh')
  !
  return
end subroutine v_h
