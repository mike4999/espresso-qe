!
!--------------------------------------------------------------------
subroutine dynmatcc(dyncc)
  !--------------------------------------------------------------------
  !
#include "machine.h"
  use allocate
  use pwcom
  use cgcom
  implicit none
  real(kind=DP):: dyncc(3*nat,nmodes)
  !
  integer:: i,j,na,nb,nta,ntb,ir,ig,nt, nu_i,nu_j,mu_i,mu_j
  complex(kind=DP), pointer:: vxc(:), work1(:), gc(:,:)
  complex(kind=DP) :: exc
  real(kind=DP), pointer:: drhocc(:), dyncc1(:,:,:,:)
  real(kind=DP) :: exg
  !
  !
  call setv(3*nat*nmodes,0.d0,dyncc,1)
  !
  do nt=1,ntyp
     if(nlcc(nt)) go to 10
  end do
  return
10 continue
  !
  work1 => psic
  vxc   => aux2
  call mallocate ( dyncc1, 3,nat,3,nat)
  call mallocate ( gc    , nrxx, 3)
  call mallocate ( drhocc, nrxx)
  !
  call v_xc  (rho, rho_core, nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx,          &
       nl, ngm, g, nspin, alat, omega, etxc, vtxc, vxc)
  !
  call cft3(vxc,nr1,nr2,nr3,nrx1,nr2,nr3,-1)
  !
  call setv(3*nat*3*nat,0.d0,dyncc1,1)
  do na=1,nat
     nta=ityp(na)
     if (nlcc(nta)) then
        call drhoc  (ngm,gg,omega,tpiba2,numeric(nta),        &
                     a_nlcc(nta),b_nlcc(nta),alpha_nlcc(nta), &
                     mesh(nta),dx(nta),r(1,nta),rho_atc(1,nta),drhocc)
        do ig=1,ngm
           exg = tpi* ( g(1,ig)*tau(1,na) + &
                        g(2,ig)*tau(2,na) + &
                        g(3,ig)*tau(3,na) )
           exc = cmplx(cos(exg),-sin(exg))*tpiba2
           work1(ig)= drhocc(ig)* exc * conjg(vxc(nl(ig)))
           gc(ig,1) = g(1,ig) * exc * cmplx(0.0,-1.0)
           gc(ig,2) = g(2,ig) * exc * cmplx(0.0,-1.0)
           gc(ig,3) = g(3,ig) * exc * cmplx(0.0,-1.0)
        end do
        do i=1,3
           do j=1,3
              do ig=1,ngm
                 dyncc1(i,na,j,na) = dyncc1(i,na,j,na) -  &
                      real(work1(ig)) * g(i,ig) * g(j,ig)
              end do
           end do
        end do
        do i=1,3
           call dvb_cc  (nlcc,nt,ngm,nr1,nr2,nr3,nrx1, &
                nl,drhocc,dmuxc,gc(1,i),aux3,gc(1,i))
        end do
        do nb=1,nat
           ntb=ityp(nb)
           if (nlcc(ntb)) then
              call drhoc (ngm,gg,omega,tpiba2,numeric(ntb),                &
                          a_nlcc(ntb),b_nlcc(ntb),alpha_nlcc(ntb),         &
                          mesh(ntb),dx(ntb),r(1,ntb),rho_atc(1,ntb),drhocc)
              do ig=1,ngm
                 exg = tpi* ( g(1,ig)*tau(1,nb) + &
                              g(2,ig)*tau(2,nb) + &
                              g(3,ig)*tau(3,nb) )
                 exc = -cmplx(sin(exg),cos(exg))
                 work1(ig) = exc * drhocc(ig)
              end do
              do i=1,3
                 do j=1,3
                    do ig=1,ngm
                       dyncc1(i,na,j,nb) = dyncc1(i,na,j,nb) +      &
                            real( work1(ig)*conjg(gc(ig,i)))*g(j,ig)
                    end do
                 end do
              end do
           end if
        end do
     end if
  end do
  !
  call mfree(gc)
  call mfree(drhocc)
#ifdef PARA
  call reduce(3*nat*3*nat,dyncc1)
#endif
  call DSCAL(3*nat*3*nat,-omega,dyncc1,1)
  !
  ! dyncc1 contains the entire dynamical matrix (core-correction part)
  ! in cartesian coordinates: transform to generic modes
  !
  do nu_i=1,nmodes
     if ( has_equivalent((nu_i-1)/3+1).eq.0 ) then
        do nu_j=1,nmodes
           do mu_i=1,3*nat
              na=(mu_i-1)/3+1
              i = mu_i-3*(na-1)
              do mu_j=1,3*nat
                 nb=(mu_j-1)/3+1
                 j = mu_j-3*(nb-1)
                 dyncc(nu_i,nu_j) = dyncc(nu_i,nu_j) +              &
                      dyncc1(i,na,j,nb)*u(mu_i,nu_i)*u(mu_j,nu_j)
              end do
           end do
        end do
     end if
  end do
  call mfree(dyncc1)
  !
  return
end subroutine dynmatcc
