!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine rhod2vkb(dyn0)
  !----------------------------------------------------------------------
  !
  !  calculate the electronic term: <psi|V''|psi>  of the dynamical matrix
  !
#include "machine.h"
  use allocate
  use pwcom
  use rbecmod
  use cgcom
  !
  implicit none
  real(kind=DP) :: dyn0(3*nat,3*nat)
  !
  integer :: i, ih, ibnd, na, nt, nu_i,nu_j,mu_i,mu_j, ir, ng, jkb, kpoint, &
       ipol, jpol, ijpol
  real(kind=DP) :: weight, fac, gtau
  real(kind=DP), pointer :: dynloc(:,:), dynkb(:,:)
  complex(kind=DP), pointer :: dvkb(:,:)
  real (kind=DP), pointer ::becp1(:,:,:), becp2(:,:,:)
  !
  call start_clock('rhod2vkb')
  !
  ! contribution from local potential
  !
  call mallocate ( dynloc, 3*nat, nmodes)
  call setv(3*nat*nmodes,0.d0,dynloc,1)
  do ir = 1,nrxx
     psic(ir) = rho(ir,current_spin)
  end do
  call cft3(psic,nr1,nr2,nr3,nrx1,nr2,nr3,-1)
  do nu_i = 1,nmodes
     if (has_equivalent( (nu_i-1)/3+1).eq.1 ) go to 10
     do na = 1, nat
        mu_i = 3*(na-1)
        if ( u(mu_i+1,nu_i) .eq. 0.0  .and.   &
             u(mu_i+2,nu_i) .eq. 0.0  .and.   &
             u(mu_i+3,nu_i) .eq. 0.0        ) go to 11
        do nu_j = 1,nmodes
           if ( u(mu_i+1,nu_j) .eq. 0.0  .and. &
                u(mu_i+2,nu_j) .eq. 0.0  .and. &
                u(mu_i+3,nu_j) .eq. 0.0        ) go to 12
           do ng = 1,ngm
              gtau = tpi * ( g(1,ng)*tau(1,na) + &
                             g(2,ng)*tau(2,na) + &
                             g(3,ng)*tau(3,na)   )
              fac = omega * vloc(igtongl(ng),ityp(na)) * tpiba2 *   &
                        (  real(psic(nl(ng)))*cos(gtau) -  &
                          DIMAG(psic(nl(ng)))*sin(gtau)   )
              dynloc(nu_i,nu_j) = dynloc(nu_i,nu_j) + fac *         &
                   ( g(1,ng) * u(mu_i+1,nu_i) +                     &
                     g(2,ng) * u(mu_i+2,nu_i) +                     &
                     g(3,ng) * u(mu_i+3,nu_i)   ) *                 &
                   ( g(1,ng) * u(mu_i+1,nu_j) +                     &
                     g(2,ng) * u(mu_i+2,nu_j) +                     &
                     g(3,ng) * u(mu_i+3,nu_j)   )
           end do
12         continue
        end do
11      continue
     end do
10   continue
  end do
#define GAMMA
#ifdef GAMMA
  call DSCAL(3*nat*nmodes,2.d0,dynloc,1)
#endif
#ifdef PARA
  call reduce(3*nat*nmodes,dynloc)
#endif
  !
  !   contribution from nonlocal (Kleinman-Bylander) potential
  !
  call mallocate (dynkb,3*nat,3*nat)
  dynkb=0.d0
  call mallocate ( dvkb, npwx, nkb)
  call mallocate ( becp1, nkb, nbnd, 3)
  call mallocate ( becp2, nkb, nbnd, 6)
  !
  do kpoint = 1,nks
     ! the sum has four terms which can be reduced to two (note factor 2 in weight):
     !
     ! sum_G sum_G' sum_j sum_l [ psi_j*(G) V_na,l(G)(-iGu_ipol) V^*_na,l(G')( iG'u_jpol) psi_j(G')
     ! sum_G sum_G' sum_j sum_l [ psi_j*(G) V_na,l(G)  V^*_na,l(G') ( iG'u_ipol)( iG'u_jpol) psi_j(G')
     !
     weight = 2.0*wk(kpoint)
     call gk_sort(xk(1,kpoint),ngm,g,ecutwfc/tpiba2,npw,igk,psic)
     if (nks.gt.1) call davcio(evc,lrwfc,iuwfc,kpoint,-1)
     !
     call pw_gemm ('Y', nkb, nbnd, npw, vkb, npwx, evc, npwx, becp, nkb)
     !
     !  becp(j,n) = sum_G [ V_n*(G) psi_j(G) ]   n=(na,l)
     !
     do ipol = 1, 3
        do jkb = 1, nkb
           do i = 1,npw
              dvkb(i,jkb) = vkb(i,jkb) * cmplx(0.d0,-tpiba) * g(ipol,igk(i))
           end do
        end do
        !
        call pw_gemm ('Y', nkb, nbnd, npw, dvkb, npwx, evc, npwx, &
             becp1(1,1,ipol), nkb)
        !
        !  becp1(j,n,ipol) = sum_G [ V_n*(G) (iG_ipol) psi_j(G) ]
        !
     end do
     ijpol=0
     do ipol = 1, 3
        do jpol = ipol, 3
           do jkb = 1, nkb
              do i = 1,npw
                 dvkb(i,jkb) = vkb(i,jkb) * tpiba2 * g(ipol,igk(i))* g(jpol,igk(i))
              end do
           end do
           !
           ijpol=ijpol+1
           call pw_gemm ('Y', nkb, nbnd, npw, dvkb, npwx, evc, npwx, &
             becp2(1,1,ijpol), nkb)
           !
           !  becp2(j,n,ijpol) = sum_G [ V_n*(G) (-iG_ipol) (iG_jpol)  psi_j(G) ]
           !
        end do
     end do
     !
     jkb = 0
     do nt = 1, ntyp
        do na =1, nat
           if (ityp(na).eq.nt) then
              if (has_equivalent(na).eq.1 ) go to 20
              ijpol = 0
              do ipol = 1, 3
                 nu_i = 3*(na-1) + ipol
                 do jpol = ipol, 3
                    nu_j = 3*(na-1) + jpol
                    ijpol = ijpol + 1
                    do ibnd=1,nbnd
                       do ih=1,nh(nt)
                          dynkb(nu_i,nu_j) = dynkb(nu_i,nu_j) + &
                               (-becp1(jkb+ih,ibnd,ipol)*becp1(jkb+ih,ibnd,jpol) &
                                +becp2(jkb+ih,ibnd,ijpol)*becp(jkb+ih,ibnd) )    &
                               * dvan(ih,ih,nt) * weight
                       end do
                    end do
                 end do
                 do jpol = 1, ipol-1
                    nu_j = 3*(na-1) + jpol
                    dynkb(nu_i,nu_j) = dynkb(nu_j,nu_i)
                 end do
              end do
20            continue
              jkb = jkb + nh(nt)
           end if
        end do
     end do
  end do
  !
  call mfree ( becp2)
  call mfree ( becp1)
  call mfree ( dvkb)
  !
  call setv(3*nat*nmodes,0.d0,dyn0,1)
  !
  do nu_i = 1,nmodes
     if (has_equivalent( (nu_i-1)/3+1).eq.0 ) then
        do nu_j=1,nmodes
           do mu_i=1,3*nat
              do mu_j=1,3*nat
                 dyn0(nu_i,nu_j) = dyn0(nu_i,nu_j) + dynkb(mu_i,mu_j)*u(mu_i,nu_i)*u(mu_j,nu_j)
              end do
           end do
        end do
        do nu_j=1,nmodes
           dyn0(nu_i,nu_j) = dyn0(nu_i,nu_j) + dynloc(nu_i,nu_j)
        end do
     end if
  end do
  call mfree(dynkb)
  call mfree(dynloc)
  !
  call stop_clock('rhod2vkb')
  !
  return
end subroutine rhod2vkb
