!
! Copyright (C) 2001-2005 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine rgd_blk (nr1,nr2,nr3,nat,dyn,q,tau,epsil,zeu,bg,omega,sign)
  !-----------------------------------------------------------------------
  ! compute the rigid-ion (long-range) term for q 
  !
#include "f_defs.h"
  implicit none
  real(kind=8), parameter :: e2=2.d0, pi=3.14159265358979d0, fpi=4.d0*pi
  integer ::  nr1, nr2, nr3    !  FFT grid
  integer ::  nat              ! number of atoms 
  complex(kind=8) :: dyn(3,3,nat,nat) ! dynamical matrix
  real(kind=8) &
       q(3),           &! q-vector
       tau(3,nat),     &! atomic positions
       epsil(3,3),     &! dielectric constant tensor
       zeu(3,3,nat),   &! effective charges tensor
       bg(3,3),        &! reciprocal lattice basis vectors
       omega,          &! unit cell volume
       sign             ! sign=+/-1.0 ==> add/subtract rigid-ion term
  !
  ! local variables
  !
  real(kind=8) zag(3),zbg(3),zcg(3),&! eff. charges  times g-vector
       geg              !  <q+G| epsil | q+G>
  integer :: na,nb,nc, i,j, im, m1, m2, m3
  integer :: nrx1, nrx2, nrx3, nmegax
  integer, parameter :: nrx=16
  real(kind=8), save :: gmega(3,(2*nrx+1)*(2*nrx+1)*(2*nrx+1))
  real(kind=8) :: alph, fac,g1,g2,g3, fnat(3), facgd, arg
  complex(kind=8) :: facg
  !
  ! Check if some dimensions should not be taken into account:
  ! e.g. if nr1=1 and nr2=1, then the G-vectors run along nr3 only.
  ! (useful if system is in vacuum, e.g. 1D or 2D)
  !
  if (nr1.eq.1) then 
     nrx1=0
  else
     nrx1=nrx
  endif
  if (nr2.eq.1) then 
     nrx2=0
  else
     nrx2=nrx
  endif
  if (nr3.eq.1) then 
     nrx3=0
  else
     nrx3=nrx
  endif
  nmegax=(2*nrx1+1)*(2*nrx2+1)*(2*nrx3+1)
  !
  if (abs(sign).ne.1.0) &
       call errore ('rgd_blk',' wrong value for sign ',1)
  !
  fac = sign*e2*fpi/omega
  !
  ! DIAGONAL TERM FIRST (ONLY ONCE, INITIALIZE GMEGA)
  !
!  write (*,*) 'remember to fix Gmega'
!  write (*,*) 'remember to check diagonal-term symmetry'
  alph = 3.0
  im = 0
  do m1 = -nrx1,nrx1
     do m2 = -nrx2,nrx2
        do m3 = -nrx3,nrx3
           im = im + 1
           gmega(1,im) = m1*bg(1,1) + m2*bg(1,2) + m3*bg(1,3)
           gmega(2,im) = m1*bg(2,1) + m2*bg(2,2) + m3*bg(2,3)
           gmega(3,im) = m1*bg(3,1) + m2*bg(3,2) + m3*bg(3,3)
        end do
     end do
  end do
  !
  do na = 1,nat
     do im =1,nmegax
        g1 = gmega(1,im)
        g2 = gmega(2,im)
        g3 = gmega(3,im)
        do i=1,3
           zag(i)=g1*zeu(1,i,na)+g2*zeu(2,i,na)+g3*zeu(3,i,na)
        end do
        !
        geg = (g1*(epsil(1,1)*g1+epsil(1,2)*g2+epsil(1,3)*g3)+      &
               g2*(epsil(2,1)*g1+epsil(2,2)*g2+epsil(2,3)*g3)+      &
               g3*(epsil(3,1)*g1+epsil(3,2)*g2+epsil(3,3)*g3))
        !
        if (geg.gt.0.0) then
           do j=1,3
              fnat(j) = 0.0
           end do
           do nc = 1,nat
              arg = 2*pi* (g1* (tau(1,na)-tau(1,nc))+  &
                           g2* (tau(2,na)-tau(2,nc))+  &
                           g3* (tau(3,na)-tau(3,nc)))
              do j=1,3
                 zcg(j) = g1*zeu(1,j,nc) + g2*zeu(2,j,nc) + g3*zeu(3,j,nc)
                 fnat(j) = fnat(j) + zcg(j)*cos(arg)
              end do
           end do
           facgd = fac*exp(-geg/alph/4.0)/geg
           do i = 1,3
              do j = 1,3
                 dyn(i,j,na,na) = dyn(i,j,na,na) - facgd * zag(i) * fnat(j) 
              end do
           end do
        end if
     end do
  end do
  !
  do na = 1,nat
     do nb = 1,nat
        !
        do im =1,nmegax
           !
           g1 = gmega(1,im) + q(1)
           g2 = gmega(2,im) + q(2)
           g3 = gmega(3,im) + q(3)
           !
           geg = (g1*(epsil(1,1)*g1+epsil(1,2)*g2+epsil(1,3)*g3)+   &
                  g2*(epsil(2,1)*g1+epsil(2,2)*g2+epsil(2,3)*g3)+   &
                  g3*(epsil(3,1)*g1+epsil(3,2)*g2+epsil(3,3)*g3))
           !
           if (geg.gt.0.0) then
              !
              do i=1,3
                 zag(i)=g1*zeu(1,i,na)+g2*zeu(2,i,na)+g3*zeu(3,i,na)
                 zbg(i)=g1*zeu(1,i,nb)+g2*zeu(2,i,nb)+g3*zeu(3,i,nb)
              end do
              !
              arg = 2*pi* (g1 * (tau(1,na)-tau(1,nb))+              &
                           g2 * (tau(2,na)-tau(2,nb))+              &
                           g3 * (tau(3,na)-tau(3,nb)))
              !
              facg = fac * exp(-geg/alph/4.0)/geg *                 &
                   dcmplx(cos(arg),sin(arg))
              do i=1,3
                 do j=1,3 
                    dyn(i,j,na,nb) = dyn(i,j,na,nb) + facg * zag(i) * zbg(j) 
                 end do
              end do
           end if
           !
        end do
     end do
  end do
  return
  !
end subroutine rgd_blk
!
!-----------------------------------------------------------------------
subroutine nonanal(nat, nat_blk, itau_blk, epsil, q, zeu, omega, dyn )
  !-----------------------------------------------------------------------
  !     add the nonanalytical term with macroscopic electric fields
  !
 implicit none
 real(kind=8), parameter :: e2=2.d0, pi=3.14159265358979d0, fpi=4.d0*pi
 integer, intent(in) :: nat, nat_blk, itau_blk(nat)
 !  nat: number of atoms in the cell (in the supercell in the case
 !       of a dyn.mat. constructed in the mass approximation)
 !  nat_blk: number of atoms in the original cell (the same as nat if
 !       we are not using the mass approximation to build a supercell)
 !  itau_blk(na): atom in the original cell corresponding to 
 !                atom na in the supercell
 !
 complex(kind=8), intent(inout) :: dyn(3,3,nat,nat) ! dynamical matrix
 real(kind=8), intent(in) :: q(3),  &! polarization vector
      &       epsil(3,3),     &! dielectric constant tensor
      &       zeu(3,3,nat_blk),   &! effective charges tensor
      &       omega            ! unit cell volume
 !
 ! local variables
 !
 real(kind=8) zag(3),zbg(3),  &! eff. charges  times g-vector
      &       qeq              !  <q| epsil | q>
 integer na,nb,              &! counters on atoms
      &  na_blk,nb_blk,      &! as above for the original cell
      &  i,j                  ! counters on cartesian coordinates
 !
 qeq = (q(1)*(epsil(1,1)*q(1)+epsil(1,2)*q(2)+epsil(1,3)*q(3))+    &
        q(2)*(epsil(2,1)*q(1)+epsil(2,2)*q(2)+epsil(2,3)*q(3))+    &
        q(3)*(epsil(3,1)*q(1)+epsil(3,2)*q(2)+epsil(3,3)*q(3)))
 !
 if(qeq.eq.0.0) return
 !
 do na = 1,nat
    na_blk = itau_blk(na)
    do nb = 1,nat
       nb_blk = itau_blk(nb)
       !
       do i=1,3
          !
          zag(i) = q(1)*zeu(1,i,na_blk) +  q(2)*zeu(2,i,na_blk) + &
                   q(3)*zeu(3,i,na_blk)
          zbg(i) = q(1)*zeu(1,i,nb_blk) +  q(2)*zeu(2,i,nb_blk) + &
                   q(3)*zeu(3,i,nb_blk)
       end do
       !
       do i = 1,3
          do j = 1,3
             dyn(i,j,na,nb) = dyn(i,j,na,nb)+ fpi*e2*zag(i)*zbg(j)/qeq/omega
          end do
       end do
    end do
 end do
 !
 return
end subroutine nonanal
!
!-----------------------------------------------------------------------
subroutine dyndiag (nat,ntyp,amass,ityp,dyn,w2,z)
  !-----------------------------------------------------------------------
  !
  !   diagonalise the dynamical matrix
  !   On output: w2 = energies, z = displacements
  !
 implicit none
 ! input
 integer nat, ntyp, ityp(nat)
 complex(kind=8) dyn(3,3,nat,nat)
 real(kind=8) amass(ntyp)
 ! output
 real(kind=8) w2(3*nat)
 complex(kind=8) z(3*nat,3*nat)
 ! local
 real(kind=8) diff, dif1, difrel
 integer nat3, na, nta, ntb, nb, ipol, jpol, i, j
 complex(kind=8), allocatable :: dyn2(:,:)
 !
 !  fill the two-indices dynamical matrix
 !
 nat3 = 3*nat
 allocate(dyn2 (nat3, nat3))
 !
 do na = 1,nat
    do nb = 1,nat
       do ipol = 1,3
          do jpol = 1,3
             dyn2((na-1)*3+ipol, (nb-1)*3+jpol) = dyn(ipol,jpol,na,nb)
          end do
       end do
    end do
 end do
 !
 !  impose hermiticity
 !
 diff = 0.d0
 difrel=0.d0
 do i = 1,nat3
    dyn2(i,i) = dcmplx(dreal(dyn2(i,i)),0.0)
    do j = 1,i - 1
       dif1 = abs(dyn2(i,j)-conjg(dyn2(j,i)))
       if ( dif1 > diff .and. &
            max ( abs(dyn2(i,j)), abs(dyn2(j,i))) > 1.0d-6) then
          diff = dif1
          difrel=diff / min ( abs(dyn2(i,j)), abs(dyn2(j,i)))
       end if
       dyn2(i,j) = 0.5* (dyn2(i,j)+conjg(dyn2(j,i)))
       dyn2(j,i) = conjg(dyn2(i,j))
    end do
 end do
 if ( diff > 1.d-6 ) write (6,'(5x,"Max |d(i,j)-d*(j,i)| = ",f9.6,/,5x, &
      & "Max |d(i,j)-d*(j,i)|/|d(i,j)|: ",f8.4,"%")') diff, difrel*100
 !
 !  divide by the square root of masses
 !
 do na = 1,nat
    nta = ityp(na)
    do nb = 1,nat
       ntb = ityp(nb)
       do ipol = 1,3
          do jpol = 1,3
             dyn2((na-1)*3+ipol, (nb-1)*3+jpol) = &
                  dyn2((na-1)*3+ipol, (nb-1)*3+jpol) / &
                  sqrt(amass(nta)*amass(ntb))
          end do
       end do
    end do
 end do
 !
 !  diagonalisation
 !
 call cdiagh2(nat3,dyn2,nat3,w2,z)
 !
 deallocate(dyn2)
 !
 !  displacements are eigenvectors divided by sqrt(amass)
 !
 do i = 1,nat3
    do na = 1,nat
       nta = ityp(na)
       do ipol = 1,3
          z((na-1)*3+ipol,i) = z((na-1)*3+ipol,i)/ sqrt(amass(nta))
       end do
    end do
 end do
 !
 return
end subroutine dyndiag
!
!-----------------------------------------------------------------------
subroutine writemodes (nax,nat,q,w2,z,iout)
  !-----------------------------------------------------------------------
  !
  !   write modes on output file in a readable way
  !
 implicit none
 ! input
 integer nax, nat, iout
 real(kind=8) q(3), w2(3*nat)
 complex(kind=8) z(3*nax,3*nat)
 ! local
 integer nat3, na, nta, ipol, i, j
 real(kind=8):: freq(3*nat)
 real(kind=8):: rydthz,rydcm1,cm1thz,znorm
 !
 nat3=3*nat
 !
 !  conversion factors RYD=>THZ, RYD=>1/CM e 1/CM=>THZ
 !
 rydthz = 13.6058*241.796
 rydcm1 = 13.6058*8065.5
 cm1thz = 241.796/8065.5
 !
 !  write frequencies and normalised displacements
 !
 write(iout,'(5x,''diagonalizing the dynamical matrix ...''/)')
 write(iout,'(1x,''q = '',3f12.4)') q
 write(iout,'(1x,74(''*''))')
 do i = 1,nat3
    !
    freq(i)= sqrt(abs(w2(i)))*rydcm1
    if (w2(i).lt.0.0) freq(i) = -freq(i)
    write (iout,9010) i, freq(i)*cm1thz, freq(i)
    znorm = 0.0
    do j=1,nat3
       znorm=znorm+abs(z(j,i))**2
    end do
    znorm = sqrt(znorm)
    do na = 1,nat
       write (iout,9020) (z((na-1)*3+ipol,i)/znorm,ipol=1,3)
    end do
    !
 end do
 write(iout,'(1x,74(''*''))')
 !
 !      if (flvec.ne.' ') then
 !         open (unit=iout,file=flvec,status='unknown',form='unformatted')
 !         write(iout) nat, nat3, (ityp(i),i=1,nat), (q(i),i=1,3)
 !         write(iout) (freq(i),i=1,nat3), ((z(i,j),i=1,nat3),j=1,nat3)
 !         close(iout)
 !      end if
 !
 return
 !
9010 format(5x,'omega(',i2,') =',f15.6,' [THz] =',f15.6,' [cm-1]')
9020 format (1x,'(',3 (f10.6,1x,f10.6,3x),')')
 !
end subroutine writemodes
!
!-----------------------------------------------------------------------
subroutine writemolden(nax,nat,atm,a0,tau,ityp,w2,z,flmol)
  !-----------------------------------------------------------------------
  !
  !   write modes on output file in a molden-friendly way
  !
 implicit none
 ! input
 integer nax, nat, ityp(nat)
 real(kind=8) a0, tau(3,nat), w2(3*nat)
 complex(kind=8) z(3*nax,3*nat)
 character(len=50) flmol
 character(len=3) atm(*)
 ! local
 integer nat3, na, nta, ipol, i, j, iout
 real(kind=8) :: freq(3*nat)
 real(kind=8) :: rydcm1, znorm
 !
 if (flmol.eq.' ') then
    return
 else
    iout=4
    open (unit=iout,file=flmol,status='unknown',form='formatted')
 end if
 nat3=3*nat
 !
 rydcm1 = 13.6058*8065.5
 !
 !  write frequencies and normalised displacements
 !
 write(iout,'(''[Molden Format]'')')
 !
 write(iout,'(''[FREQ]'')')
 do i = 1,nat3
    freq(i)= sqrt(abs(w2(i)))*rydcm1
    if (w2(i).lt.0.0) freq(i) = 0.0
    write (iout,'(f8.2)') freq(i)
 end do
 !
 write(iout,'(''[FR-COORD]'')')
 do na = 1,nat
    write (iout,'(a6,1x,3f15.5)') atm(ityp(na)),  &
         a0*tau(1,na), a0*tau(2,na), a0*tau(3,na)
 end do
 !
 write(iout,'(''[FR-NORM-COORD]'')')
 do i = 1,nat3
    write(iout,'('' vibration'',i6)') i
    znorm = 0.0
    do j=1,nat3
       znorm=znorm+abs(z(j,i))**2
    end do
    znorm = sqrt(znorm)
    do na = 1,nat
       write (iout,'(3f10.5)') (real(z((na-1)*3+ipol,i))/znorm,ipol=1,3)
    end do
 end do
 !
 close(unit=iout)
 !
 return
 !
end subroutine writemolden
!
!-----------------------------------------------------------------------
subroutine cdiagh2 (n,h,ldh,e,v)
  !-----------------------------------------------------------------------
  !
  !   calculates all the eigenvalues and eigenvectors of a complex
  !   hermitean matrix H . On output, the matrix is unchanged
  !
 implicit none
 !
 ! on INPUT
 integer          n,       &! dimension of the matrix to be diagonalized
      &           ldh       ! leading dimension of h, as declared
 ! in the calling pgm unit
 complex(kind=8)  h(ldh,n)  ! matrix to be diagonalized
 !
 ! on OUTPUT
 real(kind=8)     e(n)      ! eigenvalues
 complex(kind=8)  v(ldh,n)  ! eigenvectors (column-wise)
 !
 ! LOCAL variables (LAPACK version)
 !
 integer          lwork,   &! aux. var.
      &           ILAENV,  &! function which gives block size
      &           nb,      &! block size
      &           info      ! flag saying if the exec. of libr. routines was ok
 !
 real(kind=8), allocatable::   rwork(:)
 complex(kind=8), allocatable:: work(:)
 !
 !     check for the block size
 !
 nb = ILAENV( 1, 'ZHETRD', 'U', n, -1, -1, -1 )
 if (nb.lt.1) nb=max(1,n)
 if (nb.eq.1.or.nb.ge.n) then
    lwork=2*n-1
 else
    lwork = (nb+1)*n
 endif
 !
 ! allocate workspace
 !
 call ZCOPY(n*ldh,h,1,v,1)
 allocate(work (lwork))
 allocate(rwork (3*n-2))
 call ZHEEV('V','U',n,v,ldh,e,work,lwork,rwork,info)
 call errore ('cdiagh2','info =/= 0',abs(info))
 ! deallocate workspace
 deallocate(rwork)
 deallocate(work)
 !
 return
end subroutine cdiagh2
