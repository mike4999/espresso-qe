!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"


!-----------------------------------------------------------------------
      subroutine calcmt(fdiag,zmat,fmat)
!-----------------------------------------------------------------------
!
!  constructs fmat=zmat^t.fdiag.zmat
!
      use electrons_base, only: nudx, nspin, nupdwn, iupdwn, nx => nbspx

      implicit none
      integer iss, nss, istart, i, j, k
      real(8) zmat(nudx,nudx,nspin), fmat(nudx,nudx,nspin),        &
   &                fdiag(nx)

      do iss=1,nspin
       nss=nupdwn(iss)
       istart=iupdwn(iss)
       do i=1,nss
        do k=1,nss
         fmat(k,i,iss)=0.0
         do j=1,nss
          fmat(k,i,iss)=fmat(k,i,iss)+                                   &
    &         zmat(j,k,iss)*fdiag(j+istart-1)*zmat(j,i,iss)
         end do
        end do
       end do
      end do

      return
      end subroutine calcmt


!-----------------------------------------------------------------------
      subroutine rotate(z0,c0,bec,c0diag,becdiag)
!-----------------------------------------------------------------------
      use kinds, only: dp
      use cvan
      use electrons_base, only: nudx, nspin, nupdwn, iupdwn, nx => nbspx, n => nbsp
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb, nhsavb=>nkbus, qq
      use gvecw, only: ngw
      use ions_base, only: nas => nax, nsp, na

      implicit none
      integer iss, nss, istart, i, j, k, ni, nj, is, jv, ia, jnl
      real(8) z0(nudx,nudx,nspin)
      real(8) bec(nhsa,n), becdiag(nhsa,n)
      complex(8) c0(ngw,nx), c0diag(ngw,nx)

      c0diag(1:ngw,1:nx)=0.d0
        do iss=1,nspin
         nss=nupdwn(iss)
         istart=iupdwn(iss)
          call MXMA(c0(1,istart),1,2*ngw,z0(1,1,iss),nudx,1,c0diag(1,istart),1,2*ngw,2*ngw,nss,nss)
        end do

        do iss=1,nspin
        nss=nupdwn(iss)
        istart=iupdwn(iss)
        do ni=1,nss
         do is=1,nsp
          do jv=1,nh(is)
           do ia=1,na(is)
            jnl=ish(is)+(jv-1)*na(is)+ia
             becdiag(jnl,ni+istart-1)=0.0
             do nj=1,nss
              becdiag(jnl,ni+istart-1)=becdiag(jnl,ni+istart-1)+        &
     &        CMPLX(z0(ni,nj,iss),0.d0)*bec(jnl,nj+istart-1)
             end do
           end do
          end do
         end do
        end do
        end do
      return
      end subroutine rotate


!-----------------------------------------------------------------------
      subroutine ddiag(nx,n,amat,dval,dvec,iflag)
!-----------------------------------------------------------------------
!
      use parallel_toolkit, only: dspev_drv
      implicit none
      integer nx,n,ndim,iflag,k,i,j
      real(8)   dval(n)
      real(8) amat(nx,n), dvec(nx,n)
      real(8), allocatable::  ap(:)

      ndim=(n*(n+1))/2
      allocate(ap(ndim))
      ap(:)=0.d0

      k=0
      do j=1,n
       do i=1,j
        k=k+1
        ap(k)=amat(i,j)
       end do
      end do

      CALL dspev_drv( 'V', 'U', n, ap, dval, dvec, nx )

      deallocate(ap)

      return
    end subroutine ddiag

!-----------------------------------------------------------------------
      subroutine calcm(fdiag,zmat,fmat)
!-----------------------------------------------------------------------
!
!  constructs fmat=zmat.fdiag.zmat^t
!
      use electrons_base, only: nudx, nspin, nupdwn, iupdwn, nx => nbspx, n => nbsp

      implicit none
      integer iss, nss, istart, i, j, k
      real(8) zmat(nudx,nudx,nspin), fmat(nudx,nudx,nspin),         &
    &   fdiag(nx)

      do iss=1,nspin
       nss=nupdwn(iss)
       istart=iupdwn(iss)
       do i=1,nss
        do k=1,nss
         fmat(k,i,iss)=0.0
         do j=1,nss
          fmat(k,i,iss)=fmat(k,i,iss)+                                  &
    &            zmat(k,j,iss)*fdiag(j+istart-1)*zmat(i,j,iss)
         end do
        end do
       end do
      end do

      return
      end subroutine calcm

    subroutine minparabola(ene0,dene0,ene1,passop,passo,stima)
!this subroutines finds the minimum of a quadratic real function
      
      implicit none
      real(8) ene0,dene0,ene1,passop,passo,stima
      real(8) a,b,c!a*x^2+b*x+c
      
      c=ene0
      b=dene0
      a=(ene1-b*passop-c)/(passop**2.d0)
      
      passo = -b/(2.d0*a)
      if( a.lt.0.d0) then
         if(ene1.lt.ene0) then
            passo=passop
         else 
            passo=0.5*passop
         endif
      endif


      stima=a*passo**2.d0+b*passo+c


      return
    end subroutine minparabola


subroutine pc2(a,beca,b,becb)      
               
! this function applies the operator Pc
            
!    this subroutine applies the Pc operator
!    a input :unperturbed wavefunctions
!    b input :first order wavefunctions
!    b output:b_i =b_i-a_j><a_j|S|b_i>
     
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan 
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use reciprocal_vectors, only: ng0 => gstart
      use mp, only: mp_sum
      use electrons_base, only: n => nbsp, ispin
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb
      use uspp, only :qq
                           
      implicit none        
                           
      complex(8) a(ngw,n), b(ngw,n)
                     
      real(8)    beca(nhsa,n),becb(nhsa,n)
! local variables
      integer is, iv, jv, ia, inl, jnl, i, j,ig
      real(8) sca
      do i=1,n
         do j=1,n
            sca=0.
            if (ng0.eq.2) then
               b(1,i)=0.5d0*(b(1,i)+CONJG(b(1,i)))
            endif
            if(ispin(j) == ispin(i)) then
               do  ig=1,ngw           !loop on g vectors
                  sca=sca+2.d0*DBLE(CONJG(a(ig,j))*b(ig,i)) !2. for real wavefunctions
               enddo
               if (ng0.eq.2) then
                  sca=sca-DBLE(CONJG(a(1,j))*b(1,i))
               endif

               call mp_sum( sca )

               if (nvb.gt.0) then

                  do is=1,nvb
                     do iv=1,nh(is)
                        do jv=1,nh(is)
                           do ia=1,na(is)
                              inl=ish(is)+(iv-1)*na(is)+ia
                              jnl=ish(is)+(jv-1)*na(is)+ia
                              sca=sca+ qq(iv,jv,is)*beca(inl,j)*becb(jnl,i)  
                           end do
                        end do
                     end do
                  end do
               end if

               do ig=1,ngw
                  b(ig,i)=b(ig,i)-sca*a(ig,j)
               enddo
               ! this to prevent numerical errors
               if (ng0.eq.2) then
                  b(1,i)=0.5d0*(b(1,i)+CONJG(b(1,i)))
               endif
            endif
         enddo

      enddo
      return
      end subroutine pc2


      subroutine pcdaga2(a,as ,b )

! this function applies the operator Pc

!    this subroutine applies the Pc^dagerr operator
!    a input :unperturbed wavefunctions
!    b input :first order wavefunctions
!    b output:b_i =b_i - S|a_j><a_j|b_i>

      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use reciprocal_vectors, only: ng0 => gstart
      use mp, only: mp_sum
      use electrons_base, only: n => nbsp, ispin
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb

      implicit none

      complex(8) a(ngw,n), b(ngw,n), as(ngw,n)
      real(8)    beca(nhsa,n),becb(nhsa,n)
      ! local variables
      integer is, iv, jv, ia, inl, jnl, i, j,ig
      real(8) sca
      !
      do i=1,n
         do j=1,n
            sca=0.
            if (ng0.eq.2) then
               b(1,i)=0.5d0*(b(1,i)+CONJG(b(1,i)))
            endif
            if(ispin(i) == ispin(j)) then
               do  ig=1,ngw           !loop on g vectors
                  sca=sca+2.*DBLE(CONJG(a(ig,j))*b(ig,i)) !2. for real weavefunctions
               enddo
               if (ng0.eq.2) then
                  sca=sca-DBLE(CONJG(a(1,j))*b(1,i))
               endif
               call mp_sum(sca)
               do ig=1,ngw
                  b(ig,i)=b(ig,i)-sca*as(ig,j)
               enddo
               ! this to prevent numerical errors
               if (ng0.eq.2) then
                  b(1,i)=0.5d0*(b(1,i)+CONJG(b(1,i)))
               endif
            endif
         enddo
      enddo
      return
      end subroutine pcdaga2

      subroutine set_s_minus1(betae)

! this function calculates the factors for the inverse of the US S matrix

      use kinds, only: dp   
      use cg_module, only: s_minus1
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use reciprocal_vectors, only: ng0 => gstart
      use mp, only: mp_sum, mp_bcast
      use electrons_base, only: n => nbsp, ispin
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb,qq, nhsavb=>nkbus
      use io_global, ONLY: ionode, ionode_id

      implicit none

      complex(DP) :: betae(ngw,nhsa)
     

! local variables
      real(DP),allocatable :: q_matrix(:,:), b_matrix(:,:),c_matrix(:,:)
      integer is, iv, jv, ia, inl, jnl, i, j, k,ig, js, ja
      real(DP) sca, dval(nhsavb)
      integer ipiv(nhsavb),info, lwork
      real(DP) work(nhsavb)

      allocate(q_matrix(nhsavb,nhsavb),b_matrix(nhsavb,nhsavb),c_matrix(nhsavb,nhsavb))
      lwork=nhsavb
!construct q matrix
      q_matrix(:,:) = 0.d0

      do is=1,nvb
         do iv=1,nh(is)
            do jv=1,nh(is)
               do ia=1,na(is)
                    inl=ish(is)+(iv-1)*na(is)+ia
                    jnl=ish(is)+(jv-1)*na(is)+ia
                    q_matrix(inl,jnl)= qq(iv,jv,is)
               enddo
            enddo
         enddo
      enddo

!construct b matrix

      b_matrix(:,:) = 0.d0
      do is=1,nvb
         do ia=1,na(is)
            do iv=1,nh(is)
               do js=1,nvb
                  do ja=1,na(js)
                     do jv=1,nh(js)
                        inl=ish(is)+(iv-1)*na(is)+ia
                        jnl=ish(js)+(jv-1)*na(js)+ja
                        sca=0.d0
                        do  ig=1,ngw           !loop on g vectors
                           sca=sca+2.*DBLE(CONJG(betae(ig,inl))*betae(ig,jnl)) !2. for real weavefunctions
                        enddo
                        if (ng0.eq.2) then
                           sca=sca-DBLE(CONJG(betae(1,inl))*betae(1,jnl))
                        endif
                        call mp_sum(sca)
                        b_matrix(inl,jnl)=sca
                     enddo
                  enddo
               enddo
            enddo
         enddo
      enddo

!calculate -(1+QB)**(-1) * Q
      c_matrix(:,:)=0.d0
      do i=1,nhsavb
         do j=1,nhsavb
            do k=1,nhsavb
                c_matrix(i,j)=c_matrix(i,j) + q_matrix(i,k)*b_matrix(k,j)
            enddo
         enddo
      enddo

      do i=1,nhsavb
         c_matrix(i,i)=c_matrix(i,i)+1.d0
      enddo

      if(ionode) then
        call dgetrf(nhsavb,nhsavb,c_matrix,nhsavb,ipiv,info)
        if(info .ne. 0) write(stdout,*) 'Problem with dgetrf :', info
        call dgetri(nhsavb,c_matrix,nhsavb,ipiv,work,lwork,info)
        if(info .ne. 0) write(stdout,*) 'Problem with dgetrf :', info
      endif
      call mp_bcast(c_matrix, ionode_id)

      s_minus1(:,:)=0.d0

      do i=1,nhsavb
         do j=1,nhsavb
             do k=1,nhsavb
                s_minus1(i,j)=s_minus1(i,j)-c_matrix(i,k)*q_matrix(k,j)
             enddo 
         enddo
      enddo

               
      deallocate(q_matrix,b_matrix,c_matrix)
      return
      end subroutine set_s_minus1

      subroutine set_k_minus1(betae,ema0bg)

! this function calculates the factors for the inverse of the US K  matrix
! it takes care of the preconditioning

      use kinds, only: dp
      use cg_module, only: k_minus1
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use reciprocal_vectors, only: ng0 => gstart
      use mp, only: mp_sum, mp_bcast
      use electrons_base, only: n => nbsp, ispin
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb,qq,nhsavb=>nkbus
      use io_global, ONLY: ionode, ionode_id

      implicit none

      complex(DP) :: betae(ngw,nhsa)
      real(DP)    :: ema0bg(ngw)


! local variables
      real(DP),allocatable :: q_matrix(:,:), b_matrix(:,:),c_matrix(:,:)
      integer is, iv, jv, ia, inl, jnl, i, j, k,ig, js, ja
      real(DP) sca
      integer ipiv(nhsavb),info, lwork
      real(DP) work(nhsavb)

      lwork=nhsavb

      allocate(q_matrix(nhsavb,nhsavb),b_matrix(nhsavb,nhsavb),c_matrix(nhsavb,nhsavb))
!construct q matrix
      q_matrix(:,:) = 0.d0

      do is=1,nvb
         do iv=1,nh(is)
            do jv=1,nh(is)
               do ia=1,na(is)
                    inl=ish(is)+(iv-1)*na(is)+ia
                    jnl=ish(is)+(jv-1)*na(is)+ia
                    q_matrix(inl,jnl)= qq(iv,jv,is)
               enddo
            enddo
         enddo
      enddo

!construct b matrix

      b_matrix(:,:) = 0.d0
      do is=1,nvb
         do ia=1,na(is)
            do iv=1,nh(is)
               do js=1,nvb
                  do ja=1,na(js)
                     do jv=1,nh(js)
                        inl=ish(is)+(iv-1)*na(is)+ia
                        jnl=ish(js)+(jv-1)*na(js)+ja
                        sca=0.d0
                        do  ig=1,ngw           !loop on g vectors
                           sca=sca+2.*DBLE(CONJG(betae(ig,inl))*ema0bg(ig)*betae(ig,jnl)) !2. for real weavefunctions
                        enddo
                        if (ng0.eq.2) then
                           sca=sca-DBLE(CONJG(betae(1,inl))*ema0bg(1)*betae(1,jnl))
                        endif
                        call mp_sum(sca)
                        b_matrix(inl,jnl)=sca
                     enddo
                  enddo
               enddo
            enddo
         enddo
      enddo

!calculate -(1+QB)**(-1) * Q
      c_matrix(:,:)=0.d0
      do i=1,nhsavb
         do j=1,nhsavb
            do k=1,nhsavb
                c_matrix(i,j)=c_matrix(i,j) + q_matrix(i,k)*b_matrix(k,j)
            enddo
         enddo
      enddo

      do i=1,nhsavb
         c_matrix(i,i)=c_matrix(i,i)+1.d0
      enddo

      if(ionode) then
        call dgetrf(nhsavb,nhsavb,c_matrix,nhsavb,ipiv,info)
        if(info .ne. 0) write(stdout,*) 'set_k_minus1 Problem with dgetrf :', info
        call dgetri(nhsavb,c_matrix,nhsavb,ipiv,work,lwork,info)
        if(info .ne. 0) write(stdout,*) 'set_k_minus1 Problem with dgetri :', info
      endif
      call mp_bcast(c_matrix, ionode_id)



      k_minus1(:,:)=0.d0

      do i=1,nhsavb
         do j=1,nhsavb
             do k=1,nhsavb
                k_minus1(i,j)=k_minus1(i,j)-c_matrix(i,k)*q_matrix(k,j)
             enddo
         enddo
      enddo


      deallocate(q_matrix,b_matrix,c_matrix)
      return
      end subroutine set_k_minus1

      subroutine sminus1(c0,bec,betae)
!-----------------------------------------------------------------------
!     input: c0 , bec=<c0|beta>, betae=|beta>
!     computes the matrix phi (with the old positions)
!       where  |phi> = s^{-1}|c0> 

      use kinds, only: dp
      use cg_module, only: s_minus1
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb, nhsavb=>nkbus, qq
      use electrons_base, only: n => nbsp
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use mp, only: mp_sum
!
      implicit none
      complex(dp) c0(ngw,n), betae(ngw,nhsa)
      real(dp)    bec(nhsa,n)
! local variables
      complex(dp), allocatable :: phi(:,:)
      integer is, iv, jv, ia, inl, jnl, i, j, js, ja
      real(dp) qtemp(nhsavb,n) ! automatic array
!

!
      if (nvb.gt.0) then
      allocate(phi(ngw,n))
      phi(1:ngw,1:n) = 0.0d0
         qtemp = 0.0d0
         do is=1,nvb
            do iv=1,nh(is)
               do js=1,nvb
                  do jv=1,nh(js)
                     do ia=1,na(is)
                        do ja=1,na(js)
                          inl=ish(is)+(iv-1)*na(is)+ia
                          jnl=ish(js)+(jv-1)*na(js)+ja
                           do i=1,n
                             qtemp(inl,i) = qtemp(inl,i) +                &
     &                                   s_minus1(inl,jnl)*bec(jnl,i)
                           end do
                        enddo
                     end do
                  end do
               end do
            end do
         end do
!NB nhsavb is the total number of US projectors, it works because the first pseudos are the vanderbilt's ones
         call MXMA                                                     &
     &       (betae,1,2*ngw,qtemp,1,nhsavb,phi,1,2*ngw,2*ngw,nhsavb,n)
!
      do j=1,n
         do i=1,ngw
            c0(i,j)=(phi(i,j)+c0(i,j))
         end do
      end do

      deallocate(phi)
      endif
      return
      end subroutine sminus1
 

      subroutine kminus1(c0,betae,ema0bg)
!-----------------------------------------------------------------------
!     input: c0 , bec=<c0|beta>, betae=|beta>
!     computes the matrix phi (with the old positions)
!       where  |phi> = K^{-1}|c0>

      use kinds, only: dp
      use cg_module, only: k_minus1
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb, nhsavb=>nkbus, qq
      use electrons_base, only: n => nbsp
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use mp, only: mp_sum
      use reciprocal_vectors, only: ng0 => gstart
!
      implicit none
      complex(dp) c0(ngw,n), betae(ngw,nhsa)
      real(dp)    beck(nhsa,n), ema0bg(ngw)
! local variables
      complex(dp), allocatable :: phi(:,:)
      integer is, iv, jv, ia, inl, jnl, i, j, js, ja,ig
      real(dp) qtemp(nhsavb,n) ! automatic array
!


      allocate(phi(ngw,n))
      phi(1:ngw,1:n) = 0.0d0

!calculates beck
      beck(:,:) = 0.d0
      if (nvb.gt.0) then
      
      do is=1,nvb
          do iv=1,nh(is)
             do ia=1,na(is)
                inl=ish(is)+(iv-1)*na(is)+ia
                do i=1,n
                   do ig=1,ngw
                      beck(inl,i)=beck(inl,i)+2.*DBLE(CONJG(betae(ig,inl))*ema0bg(ig)*c0(ig,i))
                   enddo
                    if (ng0.eq.2) then
                         beck(inl,i)=beck(inl,i)-DBLE(CONJG(betae(1,inl))*ema0bg(1)*c0(1,i))
                    endif
                 enddo
             enddo
          enddo
      enddo


      call mp_sum(beck)
!
         qtemp = 0.0d0
         do is=1,nvb
            do iv=1,nh(is)
               do js=1,nvb
                  do jv=1,nh(js)
                     do ia=1,na(is)
                        do ja=1,na(js)
                          inl=ish(is)+(iv-1)*na(is)+ia
                          jnl=ish(js)+(jv-1)*na(js)+ja
                           do i=1,n
                             qtemp(inl,i) = qtemp(inl,i) +                &
     &                                   k_minus1(inl,jnl)*beck(jnl,i)
                           end do
                        enddo
                     end do
                  end do
               end do
            end do
         end do
!NB nhsavb is the total number of US projectors, it works because the first pseudos are the vanderbilt's ones
         call MXMA                                                     &
     &       (betae,1,2*ngw,qtemp,1,nhsavb,phi,1,2*ngw,2*ngw,nhsavb,n)
      end if
!
      do j=1,n
         do ig=1,ngw
            c0(ig,j)=(phi(ig,j)+c0(ig,j))*ema0bg(ig)
         end do
      end do

      deallocate(phi)
      return
     end subroutine kminus1

      SUBROUTINE emass_precond_tpa( ema0bg, tpiba2, emaec )
       use kinds, ONLY : dp
       use gvecw, ONLY : ggp,ngw
       IMPLICIT NONE
       REAL(DP), INTENT(OUT) :: ema0bg(ngw)
       REAL(DP), INTENT(IN) ::  tpiba2, emaec
       INTEGER :: i

       real(DP) :: x

       do i = 1, ngw

          x=0.5d0*tpiba2*ggp(i)/emaec
          ema0bg(i) = 1.d0/(1.d0+(16.d0*x**4)/(27.d0+18.d0*x+12.d0*x**2+8.d0*x**3))
       end do

      RETURN
      END SUBROUTINE emass_precond_tpa

