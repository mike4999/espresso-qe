!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file 'License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------------
program fhi2upf  
  !---------------------------------------------------------------------
  !
  !     Convert a pseudopotential written in the Fritz-Haber format
  !     (numerical format) to unified pseudopotential format
  !     Restrictions:
  !     - no core corrections
  !     - no semicore states
  !     Adapted from the converter written by Andrea Ferretti 
  !
  implicit none
  character(len=75) filein, fileout
  logical exst
  integer :: i,j
#ifdef ABSOFT
#define iargc  iargc_
#define getarg getarg_
#endif
  integer, external :: iargc
  !
  i = iargc ()  
  if (i.eq.0) then  
5    print '(''  input PP file in FHI format > '',$)'  
     read (5, '(a)', end = 20, err = 20) filein
     exst=filein.ne.' '
     if (.not. exst) go to 5  
     inquire (file=filein,exist=exst)
     if(.not.exst) go to 5
  elseif (i.eq.1) then  
#ifdef __T3E
     call pxfgetarg (1, filein, i, j)  
#else
     call getarg (1, filein)  
#endif
  else  
     print '(''   usage: fhi2upf  [input file] '')'  
     stop  
  endif

  open (unit = 1, file = filein, status = 'old', form = 'formatted')
  call read_fhi(1)
  close (1)

  ! convert variables read from FHI format into those needed
  ! by the upf format - add missing quantities

  call convert_fhi

  fileout=trim(filein)//'.UPF'
  print '(''Output PP file in UPF format :  '',a)', fileout

  open(unit=2,file=fileout,status='unknown',form='formatted')
  call write_upf(2)
  close (unit=2)

stop
20 call errore ('fhi2upf', 'Reading pseudo file name ', 1)

end program fhi2upf

module fhi
  !
  ! All variables read from FHI file format
  !

  type angular_comp
     real(kind=8), pointer     :: pot(:)
     real(kind=8), pointer     :: wfc(:)
     real(kind=8), pointer     :: grid(:)
     real(kind=8)              :: amesh
     integer             :: nmesh
     integer             :: lcomp
  end type angular_comp

  !------------------------------

  real(kind=8) :: Zval           ! valence charge
  integer      :: lmax_          ! max l-component used

  type (angular_comp), pointer :: comp(:)  ! PP numerical info
                                           ! (wfc, grid, potentials...)
  !------------------------------

end module fhi
! 
!     ----------------------------------------------------------
subroutine read_fhi(iunps)
  !     ----------------------------------------------------------
  ! 
  use fhi
  implicit none
  integer, parameter    :: Nl=7  ! max number of l-components
  integer :: iunps
  !
  
  integer               :: l, i, idum, mesh

  ! Starting file reading

  read(iunps,*) Zval, lmax_
  lmax_ = lmax_ - 1

  if (lmax_+1 > Nl) then
     call errore('read_fhi','too many l-components',1)
  end if

  do i=1,10
     read(iunps,*)     ! skipping 11 lines 
  end do

  allocate( comp(0:lmax_) )

  do l=0,lmax_
     comp(l)%lcomp = l
     read(iunps,*) comp(l)%nmesh, comp(l)%amesh
     if ( l > 0) then
        if (comp(l)%nmesh /= comp(0)%nmesh .or.   &
            comp(l)%amesh /= comp(0)%amesh )      then
           call errore('read_fhi','different radial grids not allowed',i)
        end if
     end if
     mesh = comp(l)%nmesh
     allocate( comp(l)%wfc(mesh),            &      ! wave-functions
               comp(l)%pot(mesh),            &      ! potentials
               comp(l)%grid(mesh)            )      ! real space radial grid
     ! read the above quantities
     do i=1,mesh
        read(iunps,*) idum, comp(l)%grid(i),   &
                            comp(l)%wfc(i),    &
                            comp(l)%pot(i)       
     end do
  end do
  
  !     ----------------------------------------------------------
  write (6,'(a)') 'Pseudopotential successfully read'
  !     ----------------------------------------------------------
  !
  return
100 call errore ('read_fhi', 'Reading pseudo file', 100 )  

end subroutine read_fhi

!     ----------------------------------------------------------
subroutine convert_fhi
  !     ----------------------------------------------------------
  !
  use fhi
  use upf
  implicit none
  real(kind=8), parameter :: rmax = 10.0
  real(kind=8), allocatable :: aux(:)
  real(kind=8) :: vll
  character (len=20):: dft  
  integer :: lloc, kkbeta
  integer :: l, i, ir, iv
  !
  print '("Atom name > ",$)'
  read (5,'(a)') psd
  print '("l local > ",$)'
  read (5,*) lloc
  print '("DFT > ",$)'
  read (5,'(a)') dft

  write(generated, '("Generated using Fritz-Haber code")')
  write(date_author,'("Author: unknown    Generation date: as well")')
  comment = 'Info: automatically converted from FHI format'
  ! reasonable assumption
  rel = 1
  rcloc = 0.0
  nwfs  = lmax_+1
  allocate( els(nwfs), oc(nwfs), epseu(nwfs))
  allocate(lchi(nwfs), nns(nwfs) )
  allocate(rcut (nwfs), rcutus (nwfs))
  do i=1, nwfs
     print '("Wavefunction # ",i1,": label, occupancy > ",$)', i
     read (5,*) els(i), oc(i)
     nns (i)  = 0
     lchi(i)  = i-1
     rcut(i)  = 0.0
     rcutus(i)= 0.0
     epseu(i) = 0.0
  end do

  pseudotype = 'NC'
  nlcc = .false.
  zp   = Zval
  etotps = 0.0
  ecutrho=0.0
  ecutwfc=0.0
  if ( lmax_ == lloc) then
     lmax = lmax_-1
  else
     lmax = lmax_
  end if
  nbeta= lmax_
  mesh = comp(0)%nmesh
  ntwfc= nwfs
  allocate( elsw(ntwfc), ocw(ntwfc), lchiw(ntwfc) )
  do i=1, nwfs
     lchiw(i) = lchi(i)
     ocw(i)   = oc(i)
     elsw(i)  = els(i)
  end do
  call which_dft(dft, iexch, icorr, igcx, igcc)

  allocate(rab(mesh))
  allocate(  r(mesh))
  r = comp(0)%grid
  rab = r * log( comp(0)%amesh )

!  allocate (rho_atc(mesh))

  allocate (vloc0(mesh))
  ! the factor 2 converts from Hartree to Rydberg
  vloc0 = 2.d0*comp(lloc)%pot

  if (nbeta > 0) then

     allocate(ikk2(nbeta), lll(nbeta))
     kkbeta=mesh
     do ir = 1,mesh
        if ( r(ir) > rmax ) then
           kkbeta=ir
           exit
        end if
     end do
     ikk2(:) = kkbeta
     allocate(aux(kkbeta))
     allocate(betar(mesh,nbeta))
     allocate(qfunc(mesh,nbeta,nbeta))
     allocate(dion(nbeta,nbeta))
     allocate(qqq (nbeta,nbeta))
     qfunc(:,:,:)=0.0d0
     dion(:,:) =0.d0
     qqq(:,:)  =0.d0
     iv=0
     do i=1,nwfs
        l=lchi(i)
        if (l.ne.lloc) then
           iv=iv+1
           lll(iv)=l
           do ir=1,kkbeta
              ! FHI potentials are in Hartree 
              betar(ir,iv) = 2.d0 * comp(l)%wfc(ir) * &
                   ( comp(l)%pot(ir) - comp(lloc)%pot(ir) )
              aux(ir) = comp(l)%wfc(ir) * betar(ir,iv)
           end do
           call simpson(kkbeta,aux,rab,vll)
           dion(iv,iv) = 1.0d0/vll
        end if
     enddo

  end if

  allocate (rho_at(mesh))
  rho_at = 0.d0
  do i=1,nwfs
     l=lchi(i)
     rho_at = rho_at + ocw(i) * comp(l)%wfc ** 2
  end do
  
  allocate (chi(mesh,ntwfc))
  do i=1,ntwfc
     chi(:,i) = comp(i-1)%wfc(:)
  end do
  !     ----------------------------------------------------------
  write (6,'(a)') 'Pseudopotential successfully converted'
  !     ----------------------------------------------------------
  return
end subroutine convert_fhi
