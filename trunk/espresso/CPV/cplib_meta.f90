!
! Copyright (C) 2005 FPMD-CPV groups
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
!	contribution from metaGGA
      use reciprocal_vectors
      use gvecs
      use gvecw,                  only : ngw
      use smooth_grid_dimensions, only : nr1s, nr2s, nr3s, &
                                         nr1sx, nr2sx, nr3sx, nnrs => nnrsx
      use cell_base,              only : tpiba2
      USE metagga,                ONLY : kedtaus
!
      implicit none
!
      complex(kind=8) c(ngw), ca(ngw), df(ngw), da(ngw),psi(nnrs)
      integer iss1, iss2
      real(kind=8) fi, fip
! local variables
      integer ir,ig, ipol !metagga
      complex(kind=8) fp,fm,ci
!
!
      ci=(0.0,1.0)
!
         do ipol = 1, 3
	    psi(:)=(0.d0,0.d0)
            do ig=1,ngw
               psi(nps(ig))=gx(ipol,ig)* (ci*c(ig) - ca(ig))
               psi(nms(ig))=gx(ipol,ig)* (conjg(ci*c(ig) + ca(ig)))
            end do
            call ivfftw(psi,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!           on smooth grids--> grids for charge density
            do ir=1, nnrs
               psi(ir) = cmplx(kedtaus(ir,iss1)*real(psi(ir)), &
                    kedtaus(ir,iss2)*aimag(psi(ir)))
            end do
            call fwfftw(psi,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
            do ig=1,ngw
               fp= (psi(nps(ig)) + psi(nms(ig)))
               fm= (psi(nps(ig)) - psi(nms(ig)))
               df(ig)= df(ig) - ci*fi*tpiba2*gx(ipol,ig)*cmplx(real(fp), aimag(fm))
               da(ig)= da(ig) - ci*fip*tpiba2*gx(ipol,ig)*cmplx(aimag(fp),-real(fm))
            end do
         end do

!
      return
    end subroutine dforce_meta
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
      subroutine kedtauofr_meta (c, psi, psis)
!-----------------------------------------------------------------------
!
      use control_flags, only: tpre
      use gvecs
      use gvecw, only: ngw
      use reciprocal_vectors, only: gx
      use recvecs_indexes, only: np, nm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use cell_base
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use electrons_base, only: nx => nbspx, n => nbsp, f, ispin => fspin, nspin
      use constants, only: pi, fpi
!
      use cdvan
      use dener
      use metagga, ONLY : kedtaur, kedtaus, kedtaug, crosstaus, gradwfc, &
                          dkedtaus
      
      implicit none

! local variables
      integer iss, isup, isdw, iss1, iss2, ios, i, ir, ig
      integer ipol, ix,iy, ipol2xy(3,3)
      real(kind=8) sa1, sa2
      complex(kind=8) ci,fp,fm,c(ngw,nx)
      complex(kind=8) psi(nnr), psis(nnrsx)
!
!
      ci=(0.0,1.0)
      psi(:)=(0.d0,0.d0);
      psis(:)=(0.d0,0.d0);
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
         c(1:ngw,n+1)=(0.,0.)
      endif
         !
      do i=1,n,2
         psis(:) = (0,0)
         iss1=ispin(i)
         sa1=f(i)/omega
         if (i.ne.n) then
            iss2=ispin(i+1)
            sa2=f(i+1)/omega
         else
            iss2=iss1
            sa2=0.0
         end if

         do ipol = 1, 3
            psis(:)=(0.d0,0.d0)
            do ig=1,ngw
               psis(nps(ig))=tpiba*gx(ipol,ig)* (ci*c(ig,i) - c(ig,i+1))
               psis(nms(ig))=tpiba*gx(ipol,ig)*conjg(ci*c(ig,i)+c(ig,i+1))
            end do
                  ! gradient of wfc in real space
            call ivfftw(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
            !           on smooth grids--> grids for charge density
            do ir=1, nnrsx
               kedtaus(ir,iss1)=kedtaus(ir,iss1)+0.5d0*sa1*real(psis(ir))**2
               kedtaus(ir,iss2)=kedtaus(ir,iss2)+0.5d0*sa2*aimag(psis(ir))**2
            end do
            if(tpre) then
               do ir=1, nnrsx
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
                  do ir=1,nnrsx
                     crosstaus(ir,ipol,iss1) = crosstaus(ir,ipol,iss1) +&
                          sa1*real(gradwfc(ir,ix))*real(gradwfc(ir,iy))
                     crosstaus(ir,ipol,iss2) = crosstaus(ir,ipol,iss2) +&
                          sa2*aimag(gradwfc(ir,ix))*aimag(gradwfc(ir,iy))
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
                     do ir=1,nnrsx
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

         psis(1:nnrsx)=cmplx(kedtaus(1:nnrsx,iss),0.)
         call fwffts(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
         kedtaug(1:ngs,iss)=psis(nps(1:ngs))

      else
         isup=1
         isdw=2

         psis(1:nnrsx)=cmplx(kedtaus(1:nnrsx,isup),kedtaus(1:nnrsx,isdw))
         call fwffts(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
         do ig=1,ngs
            fp= psis(nps(ig)) + psis(nms(ig))
            fm= psis(nps(ig)) - psis(nms(ig))
            kedtaug(ig,isup)=0.5*cmplx( real(fp),aimag(fm))
            kedtaug(ig,isdw)=0.5*cmplx(aimag(fp),-real(fm))
         end do

      endif
!
      if(nspin.eq.1) then
!     ==================================================================
!     case nspin=1
!     ------------------------------------------------------------------
         iss=1

         psi(:) = (0.d0,0.d0)
         psi(nm(1:ngs))=conjg(kedtaug(1:ngs,iss))
         psi(np(1:ngs))=      kedtaug(1:ngs,iss)
         call invfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         kedtaur(1:nnr,iss)=real(psi(1:nnr))

      else 
!     ==================================================================
!     case nspin=2
!     ------------------------------------------------------------------
         isup=1
         isdw=2

         psi(:) = (0.d0,0.d0)
         do ig=1,ngs
            psi(nm(ig))=conjg(kedtaug(ig,isup))+ci*conjg(kedtaug(ig,isdw))
            psi(np(ig))=kedtaug(ig,isup)+ci*kedtaug(ig,isdw)
         end do
         call invfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         kedtaur(1:nnr,isup)= real(psi(1:nnr))
         kedtaur(1:nnr,isdw)=aimag(psi(1:nnr))

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
      use control_flags, only: iprint, tvlocw, iprsta, thdyn, tpre, tfor, tprnfor
      use io_global, only: stdout
      use parameters, only: natx, nsx
      use ions_base, only: nas => nax, nsp, na, nat
      use gvecs
      use gvecp, only: ng => ngm
      use cell_base, only: omega
      use cell_base, only: a1, a2, a3, tpiba2
      use reciprocal_vectors, only: gstart, g
      use recvecs_indexes, only: np, nm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrs => nnrsx
      use electrons_base, only: nspin
      use constants, only: pi, fpi
      use energies, only: etot, eself, enl, ekin, epseu, esr, eht, exc
      use local_pseudo, only: vps, rhops
      use core
      use gvecb
      use dener
      use derho
      use mp,      ONLY : mp_sum
      use metagga, ONLY : kedtaur, kedtaug, kedtaus, dkedtaus
!
      implicit none
!
      integer iss, isup, isdw, ig, ir,i,j,k,is, ia
      real(kind=8) dkedxc(3,3) !metagga
      complex(kind=8)  fp, fm, ci
      complex(kind=8)  v(nnr), vs(nnrs)
!
      ci=(0.,1.)

      v(:)=(0.d0,0.d0)
!
!     ===================================================================
!      calculation exchange and correlation energy and potential
!     -------------------------------------------------------------------
!      if (nlcc.gt.0) call add_cc(rhoc,rhog,rhor)
!
#ifdef PARA
!      call my_mpi_barrier
#endif
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
         do ir=1,nnr
            v(ir)=cmplx(kedtaur(ir,iss),0.0)
         end do
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         !
         do ig=1,ng
            kedtaug(ig,iss)=v(np(ig))
         end do
      else
         isup=1
         isdw=2

         v(1:nnr)=cmplx(kedtaur(1:nnr,isup),kedtaur(1:nnr,isdw))
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ig=1,ng
            fp=v(np(ig))+v(nm(ig))
            fm=v(np(ig))-v(nm(ig))
            kedtaug(ig,isup)=0.5*cmplx( real(fp),aimag(fm))
            kedtaug(ig,isdw)=0.5*cmplx(aimag(fp),-real(fm))
         end do

      endif
!
      vs(:) = (0.d0,0.d0)
      if(nspin.eq.1)then
         iss=1
         do ig=1,ngs
            vs(nms(ig))=conjg(kedtaug(ig,iss))
            vs(nps(ig))=kedtaug(ig,iss)
         end do
!
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!
         kedtaus(1:nnrs,iss)=real(vs(1:nnrs))
      else
         isup=1
         isdw=2
         do ig=1,ngs
            vs(nps(ig))=kedtaug(ig,isup)+ci*kedtaug(ig,isdw)
            vs(nms(ig))=conjg(kedtaug(ig,isup)) +ci*conjg(kedtaug(ig,isdw))
         end do
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
         kedtaus(1:nnrs,isup)= real(vs(1:nnrs))
         kedtaus(1:nnrs,isdw)=aimag(vs(1:nnrs))
      endif
      !calculate dkedxc in real space on smooth grids  !metagga
      if(tpre) then
         do iss=1,nspin
            do j=1,3
               do i=1,3
                  dkedxc(i,j)=0.d0
                  do ir=1,nnrs
                     !2.d0 : because kedtau = 0.5d0 d_Exc/d_kedtau
                      dkedxc(i,j)= dkedxc(i,j)+kedtaus(ir,iss)*2.d0*&
                           dkedtaus(ir,i,j,iss)
                   end do
                end do
             end do
          end do
#ifdef PARA
          call reduce(9,dkedxc)
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
