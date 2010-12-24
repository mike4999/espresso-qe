!
! Copyright (C) 2005-2010 Quantum ESPRESSO groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
      subroutine dforce_meta (c,ca,df,da, psi,iss1,iss2,fi,fip)
!-----------------------------------------------------------------------
!computes: the generalized force df=cmplx(dfr,dfi) acting on the i-th
!          electron state at the gamma point of the brillouin zone
!          represented by the vector c=cmplx(cr,ci)
!
!          contribution from metaGGA
      use kinds, only: dp
      use gvect,     only : g
      use gvecs,                  only : ngms, nlsm, nls
      use gvecw,                  only : ngw
      use smooth_grid_dimensions, only : nrxxs
      use cell_base,              only : tpiba2
      USE metagga,                ONLY : kedtaus
      USE fft_interfaces,         ONLY : fwfft, invfft
      USE fft_base,               ONLY: dffts
!
      implicit none
!
      complex(dp) c(ngw), ca(ngw), df(ngw), da(ngw),psi(nrxxs)
      integer iss1, iss2
      real(dp) fi, fip
! local variables
      integer ir,ig, ipol !metagga
      complex(dp) fp,fm,ci
!
!
      ci=(0.0d0,1.0d0)
!
         do ipol = 1, 3
            psi(:)=(0.d0,0.d0)
            do ig=1,ngw
               psi(nls(ig))=g(ipol,ig)* (ci*c(ig) - ca(ig))
               psi(nlsm(ig))=g(ipol,ig)* (CONJG(ci*c(ig) + ca(ig)))
            end do
            call invfft('Wave',psi,dffts )
!           on smooth grids--> grids for charge density
            do ir=1, nrxxs
               psi(ir) = CMPLX (kedtaus(ir,iss1)*DBLE(psi(ir)), &
                                kedtaus(ir,iss2)*AIMAG(psi(ir)),kind=DP)
            end do
            call fwfft('Wave',psi, dffts )
            do ig=1,ngw
               fp= (psi(nls(ig)) + psi(nlsm(ig)))
               fm= (psi(nls(ig)) - psi(nlsm(ig)))
               df(ig)= df(ig) - ci*fi*tpiba2*g(ipol,ig) * &
                       CMPLX(DBLE(fp), AIMAG(fm),kind=DP)
               da(ig)= da(ig) - ci*fip*tpiba2*g(ipol,ig)* &
                       CMPLX(AIMAG(fp),-DBLE(fm),kind=DP)
            end do
         end do

!
      return
    end subroutine dforce_meta
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
      subroutine kedtauofr_meta (c, psi, nlsi, psis, nlsis )
!-----------------------------------------------------------------------
!
      use kinds, only: dp
      use control_flags, only: tpre
      use gvecs
      use gvecw, only: ngw
      use gvect, only: g
      use gvect, only: nl, nlm
      use grid_dimensions, only: nr1, nr2, nr3, nr1x, nr2x, nr3x, nrxx
      use cell_base
      use smooth_grid_dimensions, only: nrxxs
      use electrons_base, only: nx => nbspx, n => nbsp, f, ispin, nspin
      use constants, only: pi, fpi
!
      use cdvan
      use dener
      use metagga, ONLY : kedtaur, kedtaus, kedtaug, crosstaus, gradwfc, &
                          dkedtaus
      USE fft_interfaces, ONLY: fwfft, invfft
      USE fft_base,       ONLY: dffts, dfftp
      
      implicit none

      integer, intent(in) :: nlsi, nlsis
      complex(dp) :: c(ngw,nx)
      complex(dp) :: psi( nlsi ), psis( nlsis )

! local variables
      integer iss, isup, isdw, iss1, iss2, ios, i, ir, ig
      integer ipol, ix,iy, ipol2xy(3,3)
      real(dp) sa1, sa2
      complex(dp) ci,fp,fm
!
      psi( : ) = (0.d0,0.d0)
!
      ci=(0.0d0,1.0d0)
      kedtaur(:,:)=0.d0
      kedtaus(:,:)=0.d0
      kedtaug(:,:)=(0.d0,0.d0)
      if(tpre) crosstaus(:,:,:)=0.d0

!
!    
!    warning! trhor and thdyn are not compatible yet!   
!
!     important: if n is odd then nx must be .ge.n+1 and c(*,n+1)=0.
! 
      if (mod(n,2).ne.0) then
         c(1:ngw,n+1)=(0.d0,0.d0)
      endif
         !
      do i=1,n,2
         iss1=ispin(i)
         sa1=f(i)/omega
         if (i.ne.n) then
            iss2=ispin(i+1)
            sa2=f(i+1)/omega
         else
            iss2=iss1
            sa2=0.0d0
         end if

         do ipol = 1, 3
            psis( : ) = (0.d0,0.d0)
            do ig=1,ngw
               psis(nls(ig))=tpiba*g(ipol,ig)* (ci*c(ig,i) - c(ig,i+1))
               psis(nlsm(ig))=tpiba*g(ipol,ig)*CONJG(ci*c(ig,i)+c(ig,i+1))
            end do
                  ! gradient of wfc in real space
            call invfft('Wave',psis, dffts )
            !           on smooth grids--> grids for charge density
            do ir=1, nrxxs
               kedtaus(ir,iss1)=kedtaus(ir,iss1)+0.5d0*sa1*DBLE(psis(ir))**2
               kedtaus(ir,iss2)=kedtaus(ir,iss2)+0.5d0*sa2*AIMAG(psis(ir))**2
            end do
            if(tpre) then
               do ir=1, nrxxs
                  gradwfc(ir,ipol)=psis(ir)
               end do
            end if
         end do
         if(tpre) then
            ipol=1
            do ix=1,3
               do iy=1,ix
                  ipol2xy(ix,iy)=ipol
                  ipol2xy(iy,ix)=ipol
                  do ir=1,nrxxs
                     crosstaus(ir,ipol,iss1) = crosstaus(ir,ipol,iss1) +&
                          sa1*DBLE(gradwfc(ir,ix))*DBLE(gradwfc(ir,iy))
                     crosstaus(ir,ipol,iss2) = crosstaus(ir,ipol,iss2) +&
                          sa2*AIMAG(gradwfc(ir,ix))*AIMAG(gradwfc(ir,iy))
                  end do
                  ipol=ipol+1
               end do
            end do
         end if

            !        d kedtaug / d h
         if(tpre) then
            do iss=1,nspin
               do ix=1,3
                  do iy=1,3
                     do ir=1,nrxxs
                        dkedtaus(ir,ix,iy,iss)=-kedtaus(ir,iss)*ainv(iy,ix)&
                             -crosstaus(ir,ipol2xy(1,ix),iss)*ainv(iy,1)&
                             -crosstaus(ir,ipol2xy(2,ix),iss)*ainv(iy,2)&
                             -crosstaus(ir,ipol2xy(3,ix),iss)*ainv(iy,3)
                     end do
                  end do
               end do
            end do
         end if  !end metagga
         !
      end do
!     kinetic energy density (kedtau) in g-space (kedtaug)
      if(nspin.eq.1)then
         iss=1

         psis(1:nrxxs)=CMPLX(kedtaus(1:nrxxs,iss),0.d0,kind=DP)
         call fwfft('Smooth',psis, dffts )
         kedtaug(1:ngms,iss)=psis(nls(1:ngms))

      else
         isup=1
         isdw=2

         psis(1:nrxxs)=CMPLX(kedtaus(1:nrxxs,isup),kedtaus(1:nrxxs,isdw),kind=DP)
         call fwfft('Smooth',psis, dffts )
         do ig=1,ngms
            fp= psis(nls(ig)) + psis(nlsm(ig))
            fm= psis(nls(ig)) - psis(nlsm(ig))
            kedtaug(ig,isup)=0.5d0*CMPLX( DBLE(fp),AIMAG(fm),kind=DP)
            kedtaug(ig,isdw)=0.5d0*CMPLX(AIMAG(fp),-DBLE(fm),kind=DP)
         end do

      endif
!
      if(nspin.eq.1) then
!     ==================================================================
!     case nspin=1
!     ------------------------------------------------------------------
         iss=1

         psi( : ) = (0.d0,0.d0)
         psi(nlm(1:ngms))=CONJG(kedtaug(1:ngms,iss))
         psi(nl(1:ngms)) =      kedtaug(1:ngms,iss)
         call invfft('Dense',psi, dfftp )
         kedtaur(1:nrxx,iss)=DBLE(psi(1:nrxx))

      else 
!     ==================================================================
!     case nspin=2
!     ------------------------------------------------------------------
         isup=1
         isdw=2

         psi( : ) = (0.d0,0.d0)

         do ig=1,ngms
            psi(nlm(ig))=CONJG(kedtaug(ig,isup))+ci*conjg(kedtaug(ig,isdw))
            psi(nl(ig)) =kedtaug(ig,isup)+ci*kedtaug(ig,isdw)
         end do
         call invfft('Dense',psi, dfftp )
         kedtaur(1:nrxx,isup)= DBLE(psi(1:nrxx))
         kedtaur(1:nrxx,isdw)=AIMAG(psi(1:nrxx))

      endif

!
      return
    end subroutine kedtauofr_meta
!
!
!-----------------------------------------------------------------------
      subroutine vofrho_meta (v, vs)
!-----------------------------------------------------------------------
!     computes: the one-particle potential v in real space,
!               the total energy etot,
!               the forces fion acting on the ions,
!               the derivative of total energy to cell parameters h
!     rhor input : electronic charge on dense real space grid
!                  (plus core charge if present)
!     rhog input : electronic charge in g space (up to density cutoff)
!     rhos input : electronic charge on smooth real space grid
!     rhor output: total potential on dense real space grid
!     rhos output: total potential on smooth real space grid
!
      use kinds, only: dp
      use control_flags, only: iprint, iprsta, thdyn, tpre, tfor, tprnfor
      use io_global, only: stdout
      use ions_base, only: nas => nax, nsp, na, nat
      use gvecs
      use gvect, only: ngm, nl, nlm
      use cell_base, only: omega
      use cell_base, only: a1, a2, a3, tpiba2
      use grid_dimensions, only: nr1, nr2, nr3, nr1x, nr2x, nr3x, nrxx
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, nrxxs
      use electrons_base, only: nspin
      use constants, only: pi, fpi
      use energies, only: etot, eself, enl, ekin, epseu, esr, eht, exc
      use local_pseudo, only: vps, rhops
      use core
      use gvecb
      use dener
!      use derho
      use mp,      ONLY : mp_sum
      use mp_global, ONLY : intra_image_comm
      use metagga, ONLY : kedtaur, kedtaug, kedtaus, dkedtaus
      USE fft_interfaces, ONLY: fwfft, invfft
      USE fft_base,       ONLY: dffts, dfftp
!
      implicit none
!
      integer iss, isup, isdw, ig, ir,i,j,k,is, ia
      real(dp) dkedxc(3,3) !metagga
      complex(dp)  fp, fm, ci
      complex(dp)  v(nrxx), vs(nrxxs)
!
      ci=(0.d0,1.d0)

      v(:)=(0.d0,0.d0)
!
!     ===================================================================
!      calculation exchange and correlation energy and potential
!     -------------------------------------------------------------------
!      if (nlcc.gt.0) call add_cc(rhoc,rhog,rhor)
!
#ifdef VARIABLECELL
!      call exch_corr_h(nspin,rhog,rhor,exc,dxc)
#else
!      call exch_corr(nspin,rhog,rhor,exc)
#endif
!
!     rhor contains the xc potential in r-space
!
!     ===================================================================
!     fourier transform of xc potential to g-space (dense grid)
!     -------------------------------------------------------------------
!
      if(nspin.eq.1) then
         iss=1
         do ir=1,nrxx
            v(ir)=CMPLX(kedtaur(ir,iss),0.0d0,kind=DP)
         end do
         call fwfft('Dense',v, dfftp )
         !
         do ig=1,ngm
            kedtaug(ig,iss)=v(nl(ig))
         end do
      else
         isup=1
         isdw=2

         v(1:nrxx)=CMPLX(kedtaur(1:nrxx,isup),kedtaur(1:nrxx,isdw),kind=DP)
         call fwfft('Dense',v, dfftp )
         do ig=1,ngm
            fp=v(nl(ig))+v(nlm(ig))
            fm=v(nl(ig))-v(nlm(ig))
            kedtaug(ig,isup)=0.5d0*CMPLX( DBLE(fp),AIMAG(fm),kind=DP)
            kedtaug(ig,isdw)=0.5d0*CMPLX(AIMAG(fp),-DBLE(fm),kind=DP)
         end do

      endif
!
      vs(:) = (0.d0,0.d0)
      if(nspin.eq.1)then
         iss=1
         do ig=1,ngms
            vs(nlsm(ig))=CONJG(kedtaug(ig,iss))
            vs(nls(ig))=kedtaug(ig,iss)
         end do
!
         call invfft('Smooth',vs, dffts )
!
         kedtaus(1:nrxxs,iss)=DBLE(vs(1:nrxxs))
      else
         isup=1
         isdw=2
         do ig=1,ngms
            vs(nls(ig))=kedtaug(ig,isup)+ci*kedtaug(ig,isdw)
            vs(nlsm(ig))=CONJG(kedtaug(ig,isup)) +ci*conjg(kedtaug(ig,isdw))
         end do
         call invfft('Smooth',vs, dffts )
         kedtaus(1:nrxxs,isup)= DBLE(vs(1:nrxxs))
         kedtaus(1:nrxxs,isdw)=AIMAG(vs(1:nrxxs))
      endif
      !calculate dkedxc in real space on smooth grids  !metagga
      if(tpre) then
         do iss=1,nspin
            do j=1,3
               do i=1,3
                  dkedxc(i,j)=0.d0
                  do ir=1,nrxxs
                     !2.d0 : because kedtau = 0.5d0 d_Exc/d_kedtau
                      dkedxc(i,j)= dkedxc(i,j)+kedtaus(ir,iss)*2.d0*&
                           dkedtaus(ir,i,j,iss)
                   end do
                end do
             end do
          end do
#ifdef PARA
          call mp_sum( dkedxc, intra_image_comm )
#endif
          do j=1,3
             do i=1,3
                dxc(i,j) = dxc(i,j) + omega/(nr1s*nr2s*nr3s)*dkedxc(i,j)
             end do
          end do
       end if        
       return
     end subroutine vofrho_meta
!-----------------------------------------------------------------------
