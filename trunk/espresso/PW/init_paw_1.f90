!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine init_paw_1
  !----------------------------------------------------------------------
  !
  !   This routine performs the following tasks:
  !   a) For each non vanderbilt pseudopotential it computes the D and
  !      the betar in the same form of the Vanderbilt pseudopotential.
  !   b) It computes the indices indv which establish the correspondence
  !      nh <-> beta in the atom
  !   c) It computes the indices nhtol which establish the correspondence
  !      nh <-> angular momentum of the beta function
  !   d) It computes the indices nhtom which establish the correspondence
  !      nh <-> magnetic angular momentum of the beta function.
  !   e) It computes the coefficients c_{LM}^{nm} which relates the
  !      spherical harmonics in the Q expansion
  !   f) It computes the radial fourier transform of the Q function on
  !      all the g vectors
  !   g) It computes the q terms which define the S matrix.
  !   h) It fills the interpolation table for the beta functions
  !
#include "machine.h"
!  use pwcom
  USE kinds , only: dp
!  use pseud
  use parameters , only : lqmax , nbrx, lmaxx, ndm
  use brilz , only : omega
  use basis , only : ntyp, nat, ityp
  use constants , only : fpi
  use us , only : nqx, mx , nlx, ap, lpx, lpl, dq
  use paw , only : paw_nhm, paw_nh, paw_lmaxkb, paw_nkb, paw_nl, paw_iltonh, &
       paw_tab, aephi, paw_betar, psphi, paw_indv, paw_nhtom, paw_nhtol, &
       paw_nbeta 
  use atom , only : r, rab, msh
  implicit none
  !
  !     here a few local variables
  !

  integer :: nt, ih, jh, nb, mb, nmb, l, m, ir, iq, is, startq, &
       lastq, ilast,  na, j, n1, n2
  ! various counters
  real(kind=DP), allocatable :: aux (:), aux1 (:), besr (:), qtot (:,:,:)
  ! various work space
  real(kind=DP) :: prefr, pref, q, qi, norm
  ! the prefactor of the q functions
  ! the prefactor of the beta functions
  ! the modulus of g for each shell
  ! q-point grid for interpolation
  real(kind=DP), allocatable :: ylmk0 (:), s(:,:), sinv(:,:)
  ! the spherical harmonics
  real(kind=DP) ::  vll (0:lmaxx),vqint
  ! the denominator in KB case
  ! interpolated value

  real(kind=DP) rc,rs,pow
  call start_clock ('init_paw_1')
  !
  !    Initialization of the variables
  !
!  lmaxp=maxval(lmax)



  paw_nhm = 0
  paw_nh = 0
  paw_lmaxkb = 0
  do nt = 1, ntyp
     do nb = 1, paw_nbeta (nt)
        paw_nh (nt) = paw_nh (nt) + 2 * aephi(nt,nb)%label%l + 1
        paw_lmaxkb = max (paw_lmaxkb,  aephi(nt,nb)%label%l)
     enddo
     if (paw_nh (nt) .gt.paw_nhm) paw_nhm = paw_nh (nt)
  enddo



  allocate (aux ( ndm))    
  allocate (aux1( ndm))    
  allocate (besr( ndm))    
  allocate (ylmk0( (paw_lmaxkb+1) ** 2 ))    
  allocate (paw_nhtol(paw_nhm, ntyp))
  allocate (paw_nhtom(paw_nhm, ntyp))
  allocate (paw_indv(paw_nhm, ntyp))
  allocate (paw_tab(nqx, nbrx, ntyp))
  allocate (paw_nl(0:paw_lmaxkb, ntyp))
  allocate (paw_iltonh(0:paw_lmaxkb,paw_nhm, ntyp))

!  dvan (:,:,:) = 0.d0
!  qq (:,:,:)   = 0.d0
!  qrad(:,:,:,:)= 0.d0
  ap (:,:,:)   = 0.d0

  ! calculate the number of beta functions of the solid
  !
  paw_nkb = 0
  do na = 1, nat
     paw_nkb = paw_nkb + paw_nh (ityp(na))
  enddo

 
  prefr = fpi / omega
  !
  !   For each pseudopotential we initialize the indices nhtol, nhtom,
  !   indv, 
  !
  paw_nl=0
  paw_iltonh=0
  do nt = 1, ntyp
        ih = 1
        do nb = 1, paw_nbeta (nt)
           l = aephi(nt,nb)%label%l
           paw_nl(l,nt) = paw_nl(l,nt) + 1
           paw_iltonh(l,paw_nl(l,nt) ,nt)= nb
            do m = 1, 2 * l + 1
              paw_nhtol (ih, nt) = l
              paw_nhtom (ih, nt) = m
              paw_indv (ih, nt) = nb
              ih = ih + 1
           enddo
        enddo
!        do ih=1,paw_nh(nt)
!           print *,'nhtom',paw_nhtom(ih,nt),ih,nt
!        enddo

  ! Rescale the wavefunctions so that int_0^rc f|psi|^2=1
  ! 
!        rc=2.0d0

        rc=1.6d0
        rs=1.d0/3.d0*rc
!        rs=0.d0
        pow=1.d0
        do j = 1, paw_nbeta (nt)
            do ih=1,msh(nt)
              write(53,*) r(ih,nt),psphi(nt,j)%psi(ih),aephi(nt,j)%psi(ih)
           enddo
           write(53,*)
!
           call step_f(aux,psphi(nt,j)%psi**2,r(:,nt),rs,rc,pow,msh(nt))
           call simpson (msh (nt), aux, rab (1, nt), norm )
           
           psphi(nt,j)%psi = psphi(nt,j)%psi/ sqrt(norm)
           aephi(nt,j)%psi = aephi(nt,j)%psi / sqrt(norm)

           do ih=1,msh(nt)
              write(51,*) r(ih,nt),psphi(nt,j)%psi(ih),aux(ih)
           enddo
           write(51,*)
!           endif
        enddo
        
        !
        !   calculate the overlap matrix
        !

        aux=0.d0
        do l=0,paw_lmaxkb
           allocate (s(paw_nl(l,nt),paw_nl(l,nt)))
           allocate (sinv(paw_nl(l,nt),paw_nl(l,nt)))
           do ih=1,paw_nl(l,nt)
              n1=paw_iltonh(l,ih,nt)
              do jh=1,paw_nl(l,nt)
                 n2=paw_iltonh(l,jh,nt)
                 call step_f(aux,psphi(nt,n1)%psi(1:msh(nt)) * &
                      psphi(nt,n2)%psi(1:msh(nt)),r(:,nt),rs,rc,pow,msh(nt))
                 call simpson (msh (nt), aux, rab (1, nt), s(ih,jh))
              enddo
           enddo
           call invmat (s, sinv,paw_nl(l,nt)) 

!           print *,'s',s
!           print *,'sinv',sinv

           do ih=1,paw_nl(l,nt)
              n1=paw_iltonh(l,ih,nt)
              do jh=1,paw_nl(l,nt)
                 n2=paw_iltonh(l,jh,nt)
                 
                 paw_betar(1:msh(nt),n1,nt)=paw_betar(1:msh(nt),n1,nt)+ &
                      sinv(ih,jh) * psphi(nt,n2)%psi(1:msh(nt))
              enddo
              call step_f(aux, &
                   paw_betar(1:msh(nt),n1,nt),r(:,nt),rs,rc,pow,msh(nt))
              paw_betar(:,n1,nt)=aux
           enddo
           deallocate (sinv)
           deallocate (s)


           do ih=1,paw_nl(l,nt)
              n1=paw_iltonh(l,ih,nt)
              do jh=1,msh(nt)
                 write(50,*) r(jh,nt), paw_betar(jh,n1,nt)
              enddo
              write(50,*)
           enddo
        enddo
     enddo
!
!    Check the orthogonality for projectors
!
!     nt=1
!     n1=paw_iltonh(0,1,1)
!     n2=paw_iltonh(0,2,1)

!     print *,n1,n2,nt
!     aux=paw_betar(:,n1,nt)*psphi(nt,n1)%psi
!     call simpson(msh (nt), aux, rab (1, nt), norm)
!     print *,'11',norm
!     aux=paw_betar(:,n1,nt)*psphi(nt,n2)%psi
!     call simpson(msh (nt), aux, rab (1, nt), norm)
!     print *,'12',norm
!     aux=paw_betar(:,n2,nt)*psphi(nt,n2)%psi
!     call simpson(msh (nt), aux, rab (1, nt), norm)
!     print *,'11',norm

  
  !
  !  compute Clebsch-Gordan coefficients
  !

  call aainit (lmaxx+1 , lqmax, mx, nlx, ap, lpx,lpl)

  !
  !     fill the interpolation table tab
  !
  pref = fpi / sqrt (omega)
  call divide (nqx, startq, lastq)
  paw_tab (:,:,:) = 0.d0
  do nt = 1, ntyp
     do nb = 1, paw_nbeta (nt)
        l = aephi(nt, nb)%label%l
        do iq = startq, lastq
           qi = (iq - 1) * dq
           call sph_bes (msh(nt), r (1, nt), qi, l, besr)
           do ir = 1, msh(nt)
              aux (ir) = paw_betar (ir, nb, nt) * besr (ir) * r (ir, nt)
           enddo
           call simpson (msh (nt), aux, rab (1, nt), vqint)
           paw_tab (iq, nb, nt) = vqint * pref
        enddo
     enddo
  enddo

#ifdef __PARA
  call reduce (nqx * nbrx * ntyp, paw_tab)
#endif
  deallocate (ylmk0)
!  deallocate (qtot)
  deallocate (besr)
  deallocate (aux1)
  deallocate (aux)

  call stop_clock ('init_paw_1')
  return

end subroutine init_paw_1

subroutine step_f(f2,f,r,rs,rc,pow,mesh)

  use kinds , only : dp
 
  implicit none
  integer :: mesh
  real(kind=dp), Intent(out):: f2(mesh)
  real(kind=dp), Intent(in) :: f(mesh), r(mesh)
  real(kind=dp), Intent(in) :: rs,rc,pow

  Integer :: n,i,nrc,nrs
  real(kind=dp) :: rcp, rsp
  
!  print *,'step_f',n,size(f),size(f2),size(r)

  nrc = Count(r(:).le.rc)
  nrs = Count(r(:).le.rs)

  rcp = r(nrc)
  rsp = r(nrs)

!  print *,"nrc etc..",nrc,nrs,rcp, rsp
!  print *,"r",r
      Do i=1,mesh
       If(r(i).Le.rsp) Then
          f2(i) = f(i)
       Else
          If(r(i).Le.rcp) Then
             f2(i)=f(i)* (1.d0-3.d0*((r(i)-rsp)/(rcp-rsp))**2+ &
                  2.d0*((r(i)-rsp)/(rcp-rsp))**3)**pow
          Else
             f2(i)=0.d0
          Endif
       Endif

    End Do

  End subroutine step_f









