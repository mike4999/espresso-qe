!
! Copyright (C) 2003 A. Smogunov 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine compbs_2(nocros, norbnow, n2d, ntot, amat, bmat, &
                    vec, kval, llapack)
!
! This subroutine reduces amat, bmat into amt, bmt
! excluding inside lying orbitals and solves GEP:
!   A X = c B X
! using either LAPACK routine or the routines in GEP.f
!
#include "f_defs.h"
  USE kinds, only : DP
  implicit none  

  integer :: n2d,     & ! 2D dimension
             noins,   & ! interior orbitals
             nocros,  & ! crossing orbitals
             norbnow, & ! total number of orbitals
             ntot       ! ntot = 2*(n2d+nocros) 
  integer :: info, ishift, i, j, k, l
  integer, allocatable :: ipiv(:)
  logical :: llapack
  complex(kind=DP) :: amat(2*n2d+norbnow, 2*n2d+norbnow),  &
                      bmat(2*n2d+norbnow, 2*n2d+norbnow),  &
                      vec(2*n2d+norbnow, ntot), kval(ntot) 
  complex(kind=DP), allocatable :: amt(:,:), bmt(:,:),  &
                      auxa(:), auxb(:), auxc(:),    &
                      hmat(:,:), hmt(:,:), vecaux(:,:)

  noins = norbnow-2*nocros

  allocate( bmt( ntot, ntot ) )
  allocate( amt( ntot, ntot ) )
  allocate( auxa( nocros ) )
  allocate( auxb( nocros ) )
  allocate( auxc( noins ) )
  allocate( hmat( noins, noins ) )
  allocate( hmt( noins, noins ) )
  allocate( vecaux( ntot, ntot ) )
  allocate( ipiv( noins ) )
     

!
! To interchange inside and right crossing orbitals in a and b
!
!     rows 
  do j=1, 2*n2d+norbnow
    do i=1, nocros
      auxa(i)=amat(2*n2d+nocros+noins+i,j)
      auxb(i)=bmat(2*n2d+nocros+noins+i,j)
    enddo
    do i=noins,1,-1
      ishift=i+nocros
      amat(2*n2d+nocros+ishift,j)=amat(2*n2d+nocros+i,j)
      bmat(2*n2d+nocros+ishift,j)=bmat(2*n2d+nocros+i,j)
    enddo
    do i=1,nocros
      amat(2*n2d+nocros+i,j)=auxa(i)
      bmat(2*n2d+nocros+i,j)=auxb(i)
    enddo
  enddo                        
!     columns
  do j=1, 2*n2d+norbnow
    do i=1, nocros
      auxa(i)=amat(j,2*n2d+nocros+noins+i)
      auxb(i)=bmat(j,2*n2d+nocros+noins+i)
    enddo
    do i=noins,1,-1
      ishift=i+nocros
      amat(j,2*n2d+nocros+ishift)=amat(j,2*n2d+nocros+i)
      bmat(j,2*n2d+nocros+ishift)=bmat(j,2*n2d+nocros+i)
    enddo
    do i=1,nocros
      amat(j,2*n2d+nocros+i)=auxa(i)
      bmat(j,2*n2d+nocros+i)=auxb(i)
    enddo
  enddo                       

!
! Set up hmat and unit matrix hmt 
!
  hmt=(0.d0,0.d0)
  do i=1, noins
    do j=1, noins
      hmat(i,j)=amat(ntot+i,ntot+j)
    enddo
  enddo
  do i=1, noins
    hmt(i,i)=(1.d0,0.d0)
  enddo      

!
!     To invert hmt=hmat^{-1}
!
  if (noins.gt.0)                                            &
       call ZGESV(noins,noins,hmat,noins,ipiv,hmt,noins,info)  

!
!  Set up new matrices amt, bmt 
!
  vecaux=(0.d0,0.d0)
  do i=1, noins
    do j=1, ntot
      do l=1, noins
        vecaux(i,j)=vecaux(i,j)+hmt(i,l)*amat(ntot+l,j)  
      enddo
    enddo
  enddo
  do i=1, ntot
    do j=1, ntot
      amt(i,j)=amat(i,j)
      bmt(i,j)=bmat(i,j)
      do l=1, noins
        amt(i,j)=amt(i,j)-amat(i,ntot+l)*vecaux(l,j)  
        bmt(i,j)=bmt(i,j)-bmat(i,ntot+l)*vecaux(l,j) 
      enddo
    enddo
  enddo 

!
! To solve GEP with matrices amt, bmt
!
  if (llapack) then
!       LAPACK expert driver
     call gep_x(ntot,amt,bmt,kval,vecaux)
  else
!       GEP algorithm
     call gep_gep(ntot,amt,bmt,kval,vecaux)     
  endif
!ccccccc

!
! Forming (2*n2d+norbnow, ntot) matrix of eigenvectors
! cooficients, storing them in vec  
!
  vec=(0.d0,0.d0)

  do j=1, ntot
    do i=1, ntot
      vec(i,j)=vecaux(i,j)
    enddo
  enddo

  do j=1, ntot 
    auxc=(0.d0,0.d0)
    do i=1, noins
      do k=1, ntot
        auxc(i)=auxc(i)+amat(ntot+i,k)*vecaux(k,j)
      enddo
    enddo
    do i=1, noins
      do k=1, noins 
        vec(ntot+i,j)=vec(ntot+i,j)-hmt(i,k)*auxc(k)
      enddo
    enddo
  enddo

!
! To interchange back inside and right crossing orbitals in a, b
! (to have a right order of orbitals again)

!     rows
  do j=1, 2*n2d+norbnow
    do i=1, nocros
      auxa(i)=amat(2*n2d+nocros+i,j)
      auxb(i)=bmat(2*n2d+nocros+i,j)
    enddo
    do i=1,noins
      ishift=i+nocros
      amat(2*n2d+nocros+i,j)=amat(2*n2d+nocros+ishift,j)
      bmat(2*n2d+nocros+i,j)=bmat(2*n2d+nocros+ishift,j)
    enddo
    do i=1,nocros
      amat(2*n2d+nocros+noins+i,j)=auxa(i)
      bmat(2*n2d+nocros+noins+i,j)=auxb(i)
    enddo
  enddo
!     columns
  do j=1, 2*n2d+norbnow
    do i=1, nocros
      auxa(i)=amat(j,2*n2d+nocros+i)
      auxb(i)=bmat(j,2*n2d+nocros+i)
    enddo
    do i=1,noins
      ishift=i+nocros
      amat(j,2*n2d+nocros+i)=amat(j,2*n2d+nocros+ishift)
      bmat(j,2*n2d+nocros+i)=bmat(j,2*n2d+nocros+ishift)
    enddo
    do i=1,nocros
      amat(j,2*n2d+nocros+noins+i)=auxa(i)
      bmat(j,2*n2d+nocros+noins+i)=auxb(i)
    enddo
  enddo
!ccccccc                           

!
! To interchange back inside and right crossing orbitals
! in eigenvector components 
!     
  do j=1, ntot
    do i=1, nocros
      auxa(i)=vec(2*n2d+nocros+i,j)
      auxb(i)=vec(2*n2d+nocros+i,j)
    enddo
    do i=1,noins
      ishift=i+nocros
      vec(2*n2d+nocros+i,j)=vec(2*n2d+nocros+ishift,j)
      vec(2*n2d+nocros+i,j)=vec(2*n2d+nocros+ishift,j)
    enddo
    do i=1,nocros
      vec(2*n2d+nocros+noins+i,j)=auxa(i)
      vec(2*n2d+nocros+noins+i,j)=auxb(i)
    enddo
  enddo                 

  deallocate(hmat)
  deallocate(hmt)
  deallocate(auxa)
  deallocate(auxb)  
  deallocate(auxc)
  deallocate(vecaux)
  deallocate(amt)
  deallocate(bmt)
  deallocate(ipiv)

  return
end subroutine compbs_2 
