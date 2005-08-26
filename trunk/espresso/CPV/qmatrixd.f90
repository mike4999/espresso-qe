!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

subroutine qmatrixd(c0, bec0,ctable, gqq, qmat, detq)

! this subroutine computes the inverse of the matrix Q
! Q_ij=<Psi_i^0|e^iG_ipol.r|Psi_j^0>
! and det Q
!respect to vectorial (serial) program I changed ngwx to ngw :-)
!this matrix is symmetric, and we make us of it

!    c0 input: the unperturbed wavefunctions
!    bec0 input: the coefficients <Phi_Rj|Psi_i^0>
!    ctable input: the coorespondence array
!    gqq input: the intqq(r) exp(iG_ipol*r) array
!    qmat output: the inverse q matrix
!    detq output: det Q
   

  use  gvecs
  use gvecw, only: ngw
  use  parameters
  use  constants
  use  cvan
  use  ions_base
  use ions_base, only : nas => nax
  use cell_base, only: a1, a2, a3
  use reciprocal_vectors, only: ng0 => gstart
  use uspp_param, only: nh, nhm
  use uspp, only : nhsa=> nkb
  use electrons_base, only: nx => nbspx, n => nbsp
  

  implicit none

    
  real(kind=8) bec0(nhsa,n)
  complex(kind=8)   gqq(nhm,nhm,nas,nsp)
  complex(kind=8) c0(ngw,nx),  qmat(nx,nx), detq
  integer ctable(ngw,2)

!local variables
  integer ig,ix,jx, iv,jv,is,ia,i,ierr,matz
  complex(kind=8) sca
  real(kind=8) ar(nx,nx),ai(nx,nx),wr(nx),wi(nx),zr(nx,nx), &
       &zi(nx,nx),fv1(nx),fv2(nx),fv3(nx)
  real(kind=8) norm, cost, det
  complex(kind=8) im, qmat2(nx,nx)

  integer ipiv(nx,nx),info
  complex(kind=8) work(nx),cdet
  integer ii!to compute determinant from LU decomposition
  integer ism,isa,inl,jnl
  real(kind=8) nexl!number of exchanged lines in LU decomposition

!  do ix=1,nx
!     do jx=1,nx
!        qmat2(jx,ix)=qmat(jx,ix)
!     enddo
!  enddo
  im=(0.,1.)

  do ix=1,nx
     do jx=1,nx
        qmat(jx,ix)=(0.,0.)
     enddo
  enddo

    

  do ix=1,n
     do jx=ix,n

! first the local part

        sca=(0.,0.)
       
!#ifdef NEC
!        *vdir nodep
!#endif 
        do ig=1,ngw
           if(ctable(ig,1).ne.(ngw+1))then
              if(ctable(ig,1).ge.0) then
                 sca=sca+CONJG(c0(ctable(ig,1),ix))*c0(ig,jx)
              endif
           endif
        enddo

!#ifdef NEC
!        *vdir nodep
!#endif
        do ig=1,ngw
           if(ctable(ig,1).ne.(ngw+1))then
              if(ctable(ig,1).lt. 0) then
                 sca=sca+c0(-ctable(ig,1),ix)*c0(ig,jx)
              endif
           endif
        enddo


!#ifdef NEC
!        *vdir nodep
!#endif
        do ig=ng0,ngw
           if(ctable(ig,2).ne.(ngw+1)) then
              if(ctable(ig,2).lt.0) then
                 sca=sca+c0(-ctable(ig,2),ix)*CONJG(c0(ig,jx))
              endif
           endif
        enddo
!#ifdef NEC
!        *vdir nodep
!#endif
        do ig=ng0,ngw
           if(ctable(ig,2).ne.(ngw+1)) then
              if(ctable(ig,2).ge.0) then
                 sca=sca+CONJG(c0(ctable(ig,2),ix))*conjg(c0(ig,jx))
              endif
           endif
        enddo
#ifdef __PARA
        call reduce(2,sca)
#endif
      
        qmat(ix,jx)=sca
!        write(6,*) ix,jx,sca!ATTENZIONE

!  now the non local vanderbilt part
            
        sca =(0.,0.)
        do is=1,nvb!loop on vanderbilt species
           do ia=1,na(is)!loop on atoms
              do iv=1,nh(is)!loop on projectors
                 do jv=1,nh(is)
                    inl=ish(is)+(iv-1)*na(is)+ia
                    jnl=ish(is)+(jv-1)*na(is)+ia                
                    sca=sca+gqq(iv,jv,ia,is)*bec0(inl,ix)*bec0(jnl,jx)
                 enddo
              enddo
           enddo
        enddo
        qmat(ix,jx)=qmat(ix,jx)+sca
        qmat(jx,ix)=qmat(ix,jx)
       
       
     enddo
  enddo

!the fallowing lines are not more necessary
!  do ix=1,n!ATTENZIONE
!     do jx=ix,n
!        qmat(jx,ix)=0.5*(qmat(ix,jx)+qmat(jx,ix))
!        qmat(ix,jx)=qmat(jx,ix)
!     enddo
!  enddo
 

#ifdef __DEC
!ATTENZIONE
!da aggiustare
  call cgetrf(n,n,qmat,nx,ipiv,info)!ATTENZIONE
  call cgetri(n,qmat,nx,ipiv,work,nx,info)
#endif 

#ifdef __NEC
  call cbgnlu(qmat,nx,n,ipiv,info)
!  write(6,*) 'info cbgnlu :', info!ATTENZIONE
  call cbgndi(qmat,nx,n,ipiv,cdet,det,0,work,info)
!  write(6,*) 'info cbgndi :', info!ATTENZIONE
  detq =cdet*10.**det
#endif 

#if defined(__ORIGIN) || defined(__AIX) || defined(__LINUX)
!LAPACK
  call zgetrf(n,n,qmat,nx,ipiv,info)!ATTENZIONE 
 !  write(6,*) 'info trf', info
  detq=(1.,0.)

!  nexl=0.
!  do ii=1,n
!     if(ipiv(ii,1).ge.1 .and. ipiv(ii,1) .le.n) then
!        if(ipiv(ii,1).ne.ii) nexl = nexl + 0.5
!     endif
!     detq = detq*qmat(ii,ii) 
!  enddo
! write(6,*) 'nexl :', nexl!ATTENZIONE
!  detq=detq*(-1.,0.)**nexl

! ho trovato le righe sottostanti su manuale, vanno bene????
 
  do ii=1,n
     if(ii.ne.ipiv(ii,1)) detq=-detq
  enddo
  do ii=1,n
     detq = detq*qmat(ii,ii)
  enddo


 
  call zgetri(n,qmat,nx,ipiv,work,nx,info)
 !  write(6,*) 'info tri', info
#endif

  



! now qmat is symetrized

  do ix=1,n
     do jx=ix,n
        sca = (0.,0.)
        qmat(jx,ix)=0.5*(qmat(ix,jx)+qmat(jx,ix))
        qmat(ix,jx)=qmat(jx,ix)

!        sca = (0.,0.)
!        do i=1,n
!           sca=sca+qmat(jx,i)*qmat2(i,ix)
!        enddo
!            write(6,*) ix,jx, sca
     enddo
  enddo

!  write(6,*) 'determinante', detq
      
  return
end subroutine qmatrixd

            
   

