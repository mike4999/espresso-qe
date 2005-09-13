!
! Copyright (C) 2001-2005 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
SUBROUTINE chdens
  !-----------------------------------------------------------------------
  !      Writes the charge density (or potential, or polarisation)
  !      into a file format suitable for plotting
  !-----------------------------------------------------------------------
  !
  !      DESCRIPTION of the INPUT: see file INPUT_PP in Docs/
  !
#include "f_defs.h"
  USE io_global,  ONLY : stdout
  USE parameters, ONLY : ntypx
  USE constants,  ONLY :  pi, fpi
  USE cell_base
  USE ions_base,  ONLY : nat, ityp, atm, ntyp => nsp, tau, zv
  USE char
  USE lsda_mod,   ONLY: nspin
  USE gvect
  USE gsmooth
  USE scf, ONLY: rho
  USE wavefunctions_module,  ONLY: psic
  USE io_files, ONLY: nd_nmbr

  implicit none
  integer, parameter :: nfilemax = 7
  ! maximum number of files with charge

  integer :: ounit, iflag, ios, ipol, nfile, ifile, nx, ny, nz, &
       na, ir, i, j, ig, output_format, plot_num

  real(DP) :: e1(3), e2(3), e3(3), x0 (3), radius, m1, m2, m3, &
       weight (nfilemax), epsilon

  character (len=256) :: fileout, filepol, filename (nfilemax)

  real(DP) :: celldms (6), gcutmsa, duals, ecuts, zvs(ntypx), ats(3,3)
  real(DP), allocatable :: taus (:,:), rhor(:)
  integer :: ibravs, nrx1sa, nrx2sa, nrx3sa, nr1sa, nr2sa, nr3sa, &
       ntyps, nats
  integer, allocatable :: ityps (:)
  character (len=3) :: atms(ntypx)
  character (len=256) :: filepp(nfilemax)
  real(DP) :: rhodum, rhotot
  complex(DP), allocatable:: rhog (:)
  ! rho or polarization in G space
  logical :: fast3d

  namelist /plot/  &
       nfile, filepp, weight, iflag, e1, e2, e3, nx, ny, nz, x0, &
       output_format, fileout, epsilon, filepol

  !
  !   set the DEFAULT values
  !
  nfile         = 1
  filepp(1)     = 'tmp.pp'
  weight(1)     = 1.0d0
  iflag         = 1
  radius        = 1.0d0
  output_format = 0
  fileout       = ' '
  epsilon       = 1.0d0
  filepol       = ' '
  e1(:)         = 0.d0
  e2(:)         = 0.d0
  e3(:)         = 0.d0
  x0(:)         = 0.d0
  nx            = 0
  ny            = 0
  nz            = 0
  !
  !    read and check input data
  !
  ! reading the namelist 'plot'
  !
  read (5, plot, iostat = ios)
  !
  if (ios /= 0) then
     call infomsg ('chdens', 'namelist plot not found or not valid', -1 )
     return
  end if
  !
  ! check for number of files
  !
  if (nfile.le.0.or.nfile.gt.nfilemax) &
       call errore ('chdens ', 'nfile is wrong ', 1)

  ! check for iflag

  if (iflag <= 1) then

     ! 1D plot : check variables

     if (e1(1)**2 + e1(2)**2 + e1(3)**2 < 1d-6) &
         call errore ('chdens', 'missing e1 vector', 1)
     if (nx <= 0 )   call errore ('chdens', 'wrong nx', 1)

  else if (iflag == 2) then

     ! 2D plot : check variables

     if (e1(1)**2 + e1(2)**2 + e1(3)**2 <  1d-6 .or. &
         e2(1)**2 + e2(2)**2 + e2(3)**2 <  1d-6)     &
         call errore ('chdens', 'missing e1/e2 vectors', 1)
     if (e1(1)*e2(1) + e1(2)*e2(2) + e1(3)*e2(3) > 1d-6) &
         call errore ('chdens', 'e1 and e2 are not orthogonal', 1)
     if (nx <= 0 .or. ny <= 0 )   call errore ('chdens', 'wrong nx/ny', 2)

  else if (iflag == 3) then

     ! 3D plot : check variables

     if ( e1(1)*e2(1) + e1(2)*e2(2) + e1(3)*e2(3) > 1d-6 .or. &
          e1(1)*e3(1) + e1(2)*e3(2) + e1(3)*e3(3) > 1d-6 .or. &
          e2(1)*e3(1) + e2(2)*e3(2) + e2(3)*e3(3) > 1d-6 )    &
         call errore ('chdens', 'e1, e2, e3 are not orthogonal', 1)

     if ((iflag.eq.3) .and.(output_format < 3 .or. output_format > 6)) &
        call errore ('chdens', 'incompatible iflag/output_format', 1)
     if ((iflag.ne.3) .and. ((output_format == 5) .or. (output_format == 6))) &
        call errore ('chdens', 'output_format=5/6, iflag<>3', 1)

  else if (iflag  == 4) then

     if (nx <= 0 .or. ny <= 0 )   call errore ('chdens', 'wrong nx/ny', 4)

  else

     call errore ('chdens', 'iflag not implemented', 1)

  endif

  !
  ! Read the header and allocate objects
  !

  call read_io_header(filepp (1), title, nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                nat, ntyp, ibrav, celldm, at, gcutm, dual, ecutwfc, plot_num )
  !
  ! ... see comment above
  !
  allocate(tau (3, nat))
  allocate(ityp(nat))
  allocate(rhor(nrx1*nrx2*nrx3))
  !
  alat = celldm (1)
  tpiba = 2.d0 * pi / alat
  tpiba2 = tpiba**2
  doublegrid = dual.gt.4.0d0
  if (doublegrid) then
     gcutms = 4.d0 * ecutwfc / tpiba2
  else
     gcutms = gcutm
  endif

  nspin = 1
  if (ibrav.gt.0) then
    call latgen (ibrav, celldm, at(1,1), at(1,2), at(1,3), omega )
    at = at / alat !  bring at in units of alat
  end if

  call recips (at(1,1), at(1,2), at(1,3), bg(1,1), bg(1,2), bg(1,3) )
  call volume (alat, at(1,1), at(1,2), at(1,3), omega)

  call set_fft_dim

  call allocate_fft
  !
  ! Read first file
  !
  call plot_io (filepp (1), title, nrx1, nrx2, nrx3, nr1, nr2, nr3, &
                nat, ntyp, ibrav, celldm, at, gcutm, dual, ecutwfc, &
                plot_num, atm, ityp, zv, tau, rho(1,1), -1)
  !
  rhor (:) = weight (1) * rho (:,1)
  !
  ! Read following files (if any), verify consistency
  ! Note that only rho is read; all other quantities are discarded
  !
  do ifile = 2, nfile
     allocate  (taus( 3 , nat))    
     allocate  (ityps( nat))    
     !
     call plot_io (filepp (ifile), title, nrx1sa, nrx2sa, nrx3sa, &
          nr1sa, nr2sa, nr3sa, nats, ntyps, ibravs, celldms, ats, gcutmsa, &
          duals, ecuts, plot_num, atms, ityps, zvs, taus, rho(1,1), - 1)
     !
     deallocate (ityps)
     deallocate (taus)
     !
     if (nats.gt.nat) call errore ('chdens', 'wrong file order? ', 1)
     if (nrx1.ne.nrx1sa.or.nrx2.ne.nrx2sa) call &
          errore ('chdens', 'incompatible nrx1 or nrx2', 1)
     if (nr1.ne.nr1sa.or.nr2.ne.nr2sa.or.nr3.ne.nr3sa) call &
          errore ('chdens', 'incompatible nr1 or nr2 or nr3', 1)
     if (ibravs.ne.ibrav) call errore ('chdens', 'incompatible ibrav', 1)
     if (gcutmsa.ne.gcutm.or.duals.ne.dual.or.ecuts.ne.ecutwfc ) &
          call errore ('chdens', 'incompatible gcutm or dual or ecut', 1)
     do i = 1, 6
        if (abs( celldm (i)-celldms (i) ) .gt. 1.0e-7 ) call errore &
             ('chdens', 'incompatible celldm', 1)
     enddo
     !
     rhor (:) = rhor (:) + weight (ifile) * rho (:,1)
  enddo

  !
  ! open output file, i.e., "fileout"
  !
  if (fileout /= ' ') then
     ounit = 1
     open (unit=ounit, file=fileout, form='formatted', status='unknown')
     WRITE( stdout, '(5x,"Writing data on file ",a)') fileout
  else
     ounit = 6
  endif

  !
  !    At this point we start the calculations, first we normalize the 
  !    vectors defining the plotting region. 
  !    If these vectors have 0 length, replace them with crystal axis
  !

  m1 = sqrt (e1 (1)**2 + e1 (2)**2 + e1 (3)**2)
  if (abs(m1) < 1.d-6) then
     e1 (:) = at(:,1)
     m1 = sqrt (e1 (1)**2 + e1 (2)**2 + e1 (3)**2)
  end if
  e1 (:) = e1 (:) / m1
  !
  m2 = sqrt (e2 (1)**2 + e2 (2)**2 + e2 (3)**2)
  if (abs(m2) < 1.d-6) then
     e2 (:) = at(:,2)
     m2 = sqrt (e2 (1)**2 + e2 (2)**2 + e2 (3)**2)
  end if
  e2 (:) = e2 (:) / m2
  !
  m3 = sqrt (e3 (1)**2 + e3 (2)**2 + e3 (3)**2)
  if (abs(m3) < 1.d-6) then
     e3 (:) = at(:,3)
     m3 = sqrt (e3 (1)**2 + e3 (2)**2 + e3 (3)**2)
  end if
  e3 (:) = e3 (:) / m3
  !
  !    and rebuild G-vectors in reciprocal space
  !
  call ggen
  !
  !    here we compute the fourier component of the quantity to plot
  !
  psic(:) = CMPLX (rhor(:), 0.d0)
  call cft3 (psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
  !
  !    we store the fourier components in the array rhog
  !

  allocate (rhog( ngm))    
  do ig = 1, ngm
     rhog (ig) = psic (nl (ig) )
  enddo
  !
  !     And now the plot (rhog in G-space, rhor in real space)
  !
  if (iflag <= 1) then

     call plot_1d (nx, m1, x0, e1, ngm, g, rhog, alat, iflag, ounit)

  elseif (iflag == 2) then

     call plot_2d (nx, ny, m1, m2, x0, e1, e2, ngm, g, rhog, alat, &
          at, nat, tau, atm, ityp, output_format, ounit)
     if (output_format == 2) then
        write (ounit, '(i4)') nat
        write (ounit, '(3f8.4,i3)') ( (tau(ipol,na), ipol=1,3), 1, na=1,nat)
        write (ounit, '(f10.6)') celldm (1)
        write (ounit, '(3(3f12.6/))') at
     endif

  elseif (iflag == 3) then

     if (output_format == 4) then

        ! gopenmol wants the coordinates in a separate file

        if (fileout /= ' ') then
           open (unit = ounit+1, file = trim(fileout)//'.xyz', &
                form = 'formatted', status = 'unknown')
           WRITE( stdout, '(5x,"Writing coordinates on file ",a)') &
                trim(fileout)//'.xyz'
        else
           open (unit = ounit+1, file = 'coord.xyz', &
                form = 'formatted', status = 'unknown')
           WRITE( stdout, '("Writing coordinates on file coord.xyz")')
        end if
     endif

     ! are vectors defining the plotting region aligned along xyz ?

     fast3d = ( e1(2) == 0.d0  .and.  e1(3) == 0.d0) .and. &
              ( e2(1) == 0.d0  .and.  e2(3) == 0.d0) .and. &
              ( e3(1) == 0.d0  .and.  e3(2) == 0.d0) 

     ! are crystal axis aligned along xyz ?

     fast3d = fast3d .and. &
          ( at(2,1) == 0.d0  .and.  at(3,1) == 0.d0) .and. &
          ( at(1,2) == 0.d0  .and.  at(3,2) == 0.d0) .and. &
          ( at(1,3) == 0.d0  .and.  at(2,3) == 0.d0) 

     if (output_format == 5) then
        !
        ! XCRYSDEN FORMAT
        !
        call xsf_struct (alat, at, nat, tau, atm, ityp, ounit)
        call xsf_fast_datagrid_3d &
             (rhor, nr1, nr2, nr3, nrx1, nrx2, nrx3, at, alat, ounit)

     elseif (output_format == 6 ) then
        !
        ! GAUSSIAN CUBE FORMAT
        call write_cubefile (alat, at, bg, nat, tau, atm, ityp, rhor, &
             nrx1, nrx2, nrx3, ounit)

     else
        !
        ! GOPENMOL FORMAT
        !
        if (fast3d) then

           call plot_fast (celldm (1), at, nat, tau, atm, ityp, &
                nrx1, nrx2, nrx3, nr1, nr2, nr3, rhor, &
                bg, m1, m2, m3, x0, e1, e2, e3, output_format, ounit, &
                rhotot)
        else
           if (nx<=0 .or. ny <=0 .or. nz <=0) &
               call errore("chdens","nx,ny,nz, required",1)

           call plot_3d (celldm (1), at, nat, tau, atm, ityp, ngm, g, rhog, &
                nx, ny, nz, m1, m2, m3, x0, e1, e2, e3, output_format, ounit, &
                rhotot)
        end if
     end if

  elseif (iflag == 4) then
     radius = radius / alat
     call plot_2ds (nx, ny, radius, ngm, g, rhog, output_format, ounit)
  else

     call errore ('chdens', 'wrong iflag', 1)

  endif
 
  deallocate(rhor)
  deallocate(rhog)
  deallocate(tau)
  deallocate(ityp)
  
end SUBROUTINE chdens
!
!-----------------------------------------------------------------------
subroutine plot_1d (nx, m1, x0, e, ngm, g, rhog, alat, iflag, ounit)
  !-----------------------------------------------------------------------
  !
  USE kinds, only : DP
  use constants, only:  pi
  implicit none
  integer :: nx, ngm, iflag, ounit
  ! number of points along the line
  ! number of G vectors
  ! type of plot
  ! output unit

  real(DP) :: e (3), x0 (3), m1, alat, g (3, ngm)
  ! vector defining the line
  ! origin of the line
  ! modulus of e
  ! lattice parameter
  ! G-vectors

  complex(DP) :: rhog (ngm)
  ! rho or polarization in G space
  integer :: i, ig
  real(DP) :: rhomin, rhomax, rhoint, rhoim, xi, yi, zi, deltax, arg, gr
  ! minimum value of the charge
  ! maximum value of the charge
  ! integrated charge
  ! integrated imaginary charge
  ! coordinates of a 3D point
  ! steps along the line
  ! the argument of the exponential
  ! |G|*|r|

  complex(DP) :: rho0g, carica (nx)

  deltax = m1 / (nx - 1)
  carica(:) = (0.d0,0.d0)
  if (iflag == 1) then
     do i = 1, nx
        xi = x0 (1) + (i - 1) * deltax * e (1)
        yi = x0 (2) + (i - 1) * deltax * e (2)
        zi = x0 (3) + (i - 1) * deltax * e (3)
        !
        !     for each point we compute the charge from the Fourier components
        !
        do ig = 1, ngm
           !
           !     NB: G are in 2pi/alat units, r are in alat units
           !
           arg = 2.d0 * pi * ( xi*g(1,ig) + yi*g(2,ig) + zi*g(3,ig) )
           carica(i) = carica(i) + rhog (ig) * CMPLX(cos(arg),sin(arg))
        enddo
     enddo
  else if (iflag == 0) then
     !
     !     spherically averaged charge: rho0(|r|) = int rho(r) dOmega
     !     rho0(r) = 4pi \sum_G rho(G) j_0(|G||r|)
     !
     !     G =0 term
     do i = 1, nx
        carica (i) = 4.d0 * pi * rhog (1)
     enddo
     !     G!=0 terms
     do ig = 2, ngm
        arg = 2.d0 * pi * ( x0(1)*g(1,ig) + x0(2)*g(2,ig) + x0(3)*g(3,ig) )
        !     This displaces the origin into x0
        rho0g = rhog (ig) * CMPLX(cos(arg),sin(arg))
        !     r =0 term
        carica (1) = carica (1) + 4.d0 * pi * rho0g
        !     r!=0 terms
        do i = 2, nx
           gr = 2.d0 * pi * sqrt(g(1,ig)**2 + g(2,ig)**2 + g(3,ig)**2) * &
                       (i-1) * deltax
           carica (i) = carica (i) + 4.d0 * pi * rho0g * sin (gr) / gr
        enddo

     enddo
  else
     call errore ('plot_1d', ' bad type of plot', 1)
  endif
  !
  !    Here we check the value of the resulting charge
  !
  rhomin =  1.0d10
  rhomax = -1.0d10

  rhoim = 0.d0
  do i = 1, nx
     rhomin = min (rhomin,  DBLE (carica (i) ) )
     rhomax = max (rhomax,  DBLE (carica (i) ) )
     rhoim = rhoim + abs (AIMAG (carica (i) ) )
  enddo

  rhoim = rhoim / nx
  print '(5x,"Min, Max, imaginary charge: ",3f12.6)', rhomin, rhomax, rhoim
  !
  !       we print the charge on output
  !
  if (iflag == 1) then
     do i = 1, nx
        write (ounit, '(2f20.10)') deltax*DBLE(i-1), DBLE(carica(i))
     enddo
  else
     rhoint = 0.d0
     do i = 1, nx
        !
        !       simple trapezoidal rule: rhoint=int carica(i) r^2(i) dr
        !
        rhoint = rhoint + DBLE(carica(i)) * (i-1)**2 * (deltax*alat)**3 
        write (ounit, '(3f20.10)') deltax*DBLE(i-1), DBLE(carica(i)), rhoint
     enddo

  endif

  return

end subroutine plot_1d
!
!-----------------------------------------------------------------------
subroutine plot_2d (nx, ny, m1, m2, x0, e1, e2, ngm, g, rhog, alat, &
     at, nat, tau, atm, ityp, output_format, ounit)
  !-----------------------------------------------------------------------
  !
  USE kinds, only : DP
  use constants, only : pi
  implicit none
  integer :: nx, ny, ngm, nat, ityp (nat), output_format, ounit
  ! number of points along x
  ! number of points along y
  ! number of G vectors
  ! number of atoms
  ! types of atoms
  ! output unit
  ! output format
  character(len=3) :: atm(*) ! atomic symbols
  real(DP) :: e1(3), e2(3), x0(3), m1, m2, g(3,ngm), alat, &
       tau(3,nat), at(3,3)
  ! vectors e1, e2 defining the plane
  ! origin
  ! modulus of e1
  ! modulus of e2
  ! G-vectors

  complex(DP) :: rhog (ngm)
  ! rho or polarization in G space
  integer :: i, j, ig

  real(DP) :: rhomin, rhomax, rhoim, deltax, deltay
  ! minimum value of the charge
  ! maximum value of the charge
  ! integrated imaginary charge
  ! steps along e1
  ! steps along e2
  complex(DP), allocatable :: eigx (:), eigy (:), carica(:,:)

  allocate (eigx(  nx))    
  allocate (eigy(  ny))    
  allocate (carica( nx , ny))    

  deltax = m1 / (nx - 1)
  deltay = m2 / (ny - 1)

  carica(:,:) = (0.d0,0.d0)
  do ig = 1, ngm
     !
     ! eigx=exp(iG*e1+iGx0), eigy=(iG*e2)
     ! These factors are calculated and stored in order to save CPU time
     !
     do i = 1, nx
        eigx (i) = exp ( (0.d0, 1.d0) * 2.d0 * pi * ( (i - 1) * deltax * &
             (e1(1) * g(1,ig) + e1(2) * g(2,ig) + e1(3) * g(3,ig) ) + &
             (x0 (1) * g(1,ig) + x0 (2) * g(2,ig) + x0 (3) * g(3,ig) ) ) )
     enddo
     do j = 1, ny
        eigy (j) = exp ( (0.d0, 1.d0) * 2.d0 * pi * (j - 1) * deltay * &
             (e2(1) * g(1,ig) + e2(2) * g(2,ig) + e2(3) * g(3,ig) ) )
     enddo
     do j = 1, ny
        do i = 1, nx
           carica (i, j) = carica (i, j) + rhog (ig) * eigx (i) * eigy (j)
        enddo
     enddo
  enddo
  !
  !    Here we check the value of the resulting charge
  !
  rhomin =  1.0d10
  rhomax = -1.0d10

  rhoim = 0.d0
  do i = 1, nx
     do j = 1, ny
        rhomin = min (rhomin,  DBLE (carica (i, j) ) )
        rhomax = max (rhomax,  DBLE (carica (i, j) ) )
        rhoim = rhoim + abs (AIMAG (carica (i, j) ) )
     enddo

  enddo

  rhoim = rhoim / nx / ny
  print '(5x,"Min, Max, imaginary charge: ",3f12.6)', rhomin, rhomax, rhoim
  print '(5x,"Output format: ",i3)', output_format

  !
  !     and we print the charge on output
  !
  if (output_format == 0) then
     !
     !     gnuplot format
     !
     !         write(ounit,'(2i6)') nx,ny
     do i = 1, nx
        write (ounit, '(e25.14)') (  DBLE(carica(i,j)), j = 1, ny )
        write (ounit, * )
     enddo
  elseif (output_format == 1) then
     !
     !     contour.x format
     !
     write (ounit, '(3i5,2e25.14)') nx, ny, 1, deltax, deltay
     write (ounit, '(4e25.14)') ( (  DBLE(carica(i,j)), j = 1, ny ), i = 1, nx )
  elseif (output_format == 2) then
     !
     !     plotrho format
     !
     write (ounit, '(2i4)') nx - 1, ny - 1
     write (ounit, '(8f8.4)') (deltax * (i - 1) , i = 1, nx)
     write (ounit, '(8f8.4)') (deltay * (j - 1) , j = 1, ny)
     write (ounit, '(6e12.4)') ( (  DBLE(carica(i,j)), i = 1, nx ), j = 1, ny )
     write (ounit, '(3f8.4)') x0
     write (ounit, '(3f8.4)') (m1 * e1 (i) , i = 1, 3)
     write (ounit, '(3f8.4)') (m2 * e2 (i) , i = 1, 3)

  elseif (output_format == 3) then
     !
     ! XCRYSDEN's XSF format
     !
     call xsf_struct (alat, at, nat, tau, atm, ityp, ounit)
     call xsf_datagrid_2d (carica, nx, ny, m1, m2, x0, e1, e2, alat, ounit)
  else
     call errore('plot_2d', 'wrong output_format', 1)
  endif

  deallocate (carica)
  deallocate (eigy)
  deallocate (eigx)
  return
end subroutine plot_2d
!
!-----------------------------------------------------------------------
subroutine plot_2ds (nx, ny, x0, ngm, g, rhog, output_format, ounit)
  !-----------------------------------------------------------------------
  USE kinds, only : DP
  use constants, only:  pi
  !
  implicit none
  integer :: nx, ny, ngm, ounit, output_format
  ! number of points along x
  ! number of points along y
  ! number of G vectors
  ! output unit

  real(DP) :: x0, g (3, ngm)
  ! radius of the sphere
  ! G-vectors

  complex(DP) :: rhog (ngm)
  ! rho or polarization in G space
  integer :: i, j, ig

  real(DP), allocatable :: r (:,:,:)
  real(DP) :: theta, phi, rhomin, rhomax, rhoim, deltax, deltay
  ! the point in space
  ! the position on the sphere
  ! minimum value of the charge
  ! maximum value of the charge
  ! integrated imaginary charge
  ! steps along e1
  ! steps along e2
  complex(DP), allocatable :: carica (:,:)
  complex(DP) :: eig

  allocate (carica( nx , ny))    
  allocate (r (3, nx , ny))    

  deltax = 2.d0 * pi / (nx - 1)

  deltay = pi / (ny - 1)

  carica(:,:) = (0.d0,0.d0)
  do j = 1, ny
     do i = 1, nx
        phi = (i - 1) * deltax
        theta = (j - 1) * deltay
        r (1, i, j) = x0 * sin (theta) * cos (phi)
        r (2, i, j) = x0 * sin (theta) * sin (phi)
        r (3, i, j) = x0 * cos (theta)
     enddo
  enddo
  do ig = 1, ngm
     !
     ! eigx=exp(iG*e1+iGx0), eigy=(iG*e2)
     ! These factors are calculated and stored in order to save CPU time
     !
     do j = 1, ny
        do i = 1, nx
           eig = exp ( (0.d0,1.d0) * 2.d0 * pi * &
               ( r(1,i,j)*g(1,ig) + r(2,i,j)*g(2,ig) + r(3,i,j)*g(3,ig) ) )
           carica (i, j) = carica (i, j) + rhog (ig) * eig
        enddo
     enddo
  enddo
  !
  !    Here we check the value of the resulting charge
  !
  rhomin =  1.0d10
  rhomax = -1.0d10

  rhoim = 0.d0
  do i = 1, nx
     do j = 1, ny
        rhomin = min (rhomin,  DBLE (carica (i, j) ) )
        rhomax = max (rhomax,  DBLE (carica (i, j) ) )
        rhoim = rhoim + abs (AIMAG (carica (i, j) ) )
     enddo

  enddo

  rhoim = rhoim / nx / ny
  print '(5x,"Min, Max, imaginary charge: ",3f12.6)', rhomin, rhomax, rhoim
  !
  !     and we print the charge on output
  !
  if (output_format.eq.0) then
     !
     !     gnuplot format
     !
     write (ounit, '(2i8)') nx, ny
     do i = 1, nx
        write (ounit, '(e25.14)') (  DBLE(carica(i,j)), j = 1, ny )
     enddo
  elseif (output_format.eq.1) then
     !
     !     contour.x format
     !
     write (ounit, '(3i5,2e25.14)') nx, ny, 1, deltax, deltay
     write (ounit, '(4e25.14)') ( (  DBLE(carica(i,j)), j = 1, ny ), i = 1, nx )
  else
     call errore ('plot_2ds', 'not implemented plot', 1)

  endif
  deallocate (carica)
  deallocate (r)
  return

end subroutine plot_2ds
!
!-----------------------------------------------------------------------
subroutine plot_3d (alat, at, nat, tau, atm, ityp, ngm, g, rhog, &
     nx, ny, nz, m1, m2, m3, x0, e1, e2, e3, output_format, ounit, &
     rhotot)
  !-----------------------------------------------------------------------
  !
  USE kinds, only : DP
  use constants, only:  pi 
  implicit none
  integer :: nat, ityp (nat), ngm, nx, ny, nz, output_format, ounit
  ! number of atoms
  ! type of atoms
  ! number of G vectors
  ! number of points along x, y, z
  ! output format
  ! output unit
  character(len=3) :: atm(*)

  real(DP) :: alat, tau(3,nat), at(3,3), g(3,ngm), x0(3), &
                   e1(3), e2(3), e3(3), m1, m2, m3
  ! lattice parameter
  ! atomic positions
  ! lattice vectors
  ! G-vectors
  ! origin
  ! vectors e1,e2,e3 defining the parallelepiped
  ! moduli of e1,e2,e3

  complex(DP) :: rhog (ngm)
  ! rho or polarization in G space
  integer :: i, j, k, ig

  real(DP) :: rhomin, rhomax, rhotot, rhoabs, deltax, deltay, deltaz
  ! min, max value of the charge, total charge, total absolute charge
  ! steps along e1, e2, e3
  complex(DP), allocatable :: eigx (:), eigy (:), eigz (:)
  real(DP), allocatable :: carica (:,:,:)
  real(DP) :: omega
  integer :: ipol, na

  allocate (eigx(  nx))    
  allocate (eigy(  ny))    
  allocate (eigz(  nz))    
  allocate (carica( nx , ny , nz))    

  deltax = m1 / nx 
  deltay = m2 / ny 
  deltaz = m3 / nz 

  carica = 0.d0
  do ig = 1, ngm
     !
     ! eigx=exp(iG*e1+iGx0), eigy=exp(iG*e2), eigz=exp(iG*e3)
     ! These factors are calculated and stored in order to save CPU time
     !
     do i = 1, nx
        eigx (i) = exp( (0.d0,1.d0) * 2.d0 * pi * ( (i-1) * deltax * &
             (e1(1)*g(1,ig)+e1(2)*g(2,ig)+e1(3)*g(3,ig)) + &
             ( x0(1)*g(1,ig)+ x0(2)*g(2,ig)+ x0(3)*g(3,ig)) ) )
     enddo
     do j = 1, ny
        eigy (j) = exp( (0.d0,1.d0) * 2.d0 * pi * (j-1) * deltay * &
             (e2(1)*g(1,ig)+e2(2)*g(2,ig)+e2(3)*g(3,ig)) )
     enddo
     do k = 1, nz
        eigz (k) = exp( (0.d0,1.d0) * 2.d0 * pi * (k-1) * deltaz * &
             (e3(1)*g(1,ig)+e3(2)*g(2,ig)+e3(3)*g(3,ig)) )
     enddo
     do k = 1, nz
        do j = 1, ny
           do i = 1, nx
              carica (i, j, k) = carica (i, j, k) + &
                    DBLE (rhog (ig) * eigz (k) * eigy (j) * eigx (i) )
           enddo
        enddo
     enddo

  enddo
  !
  !    Here we check the value of the resulting charge
  !

  call volume(alat,e1(1),e2(1),e3(1),omega)

  rhomin = MAX ( MINVAL (carica), 1.d-10 )
  rhomax = MAXVAL (carica)
  rhotot = SUM (carica(:,:,:)) * omega * deltax * deltay * deltaz
  rhoabs = SUM (ABS(carica(:,:,:))) * omega * deltax * deltay * deltaz

  print '(/5x,"Min, Max, Total, Abs charge: ",2f10.6,2x, 2f10.4)',&
     rhomin, rhomax, rhotot, rhoabs

  if (output_format == 4) then
     !
     ! "gOpenMol" file
     !

     call write_openmol_file (alat, at, nat, tau, atm, ityp, x0, &
          m1, m2, m3, nx, ny, nz, rhomax, carica, ounit)
  else
     ! user has calculated for very long, be nice and write some output even
     ! if the output_format is wrong; use XSF format as default

     !
     ! XCRYSDEN's XSF format
     !
     call xsf_struct      (alat, at, nat, tau, atm, ityp, ounit)
     call xsf_datagrid_3d &
          (carica, nx, ny, nz, m1, m2, m3, x0, e1, e2, e3, alat, ounit)
  endif

  deallocate (carica)
  deallocate (eigz)
  deallocate (eigy)
  deallocate (eigx)
  return
end subroutine plot_3d
!
!-----------------------------------------------------------------------
subroutine plot_fast (alat, at, nat, tau, atm, ityp,&
     nrx1, nrx2, nrx3, nr1, nr2, nr3, rho, bg, m1, m2, m3, &
     x0, e1, e2, e3, output_format, ounit, rhotot)
  !-----------------------------------------------------------------------
  !
  USE io_global,  ONLY : stdout
  USE kinds, only : DP
  implicit none
  integer :: nat, ityp(nat), nrx1, nrx2, nrx3, nr1, nr2, nr3, &
       output_format, ounit
  character(len=3) :: atm(*)

  real(DP) :: alat, tau (3, nat), at (3, 3), rho(nrx1,nrx2,nrx3), &
       bg (3, 3), e1(3), e2(3), e3(3), x0 (3), m1, m2, m3

  integer :: nx, ny, nz, nx0, ny0, nz0, nx1, ny1, nz1, i, j, k, i1, j1, k1
  real(DP) :: rhomin, rhomax, rhotot, rhoabs
  real(DP), allocatable :: carica (:,:,:)
  real(DP) :: deltax, deltay, deltaz
  real(DP) :: omega
  integer :: ipol, na

  ! find FFT grid point closer to X0 (origin of the parallelepiped)
  ! (add 1 because r=0 correspond to n=1)

  nx0 = nint ( (x0(1)*bg(1,1) + x0(2)*bg(2,1) + x0(3)*bg(3,1) )*nr1) + 1
  ny0 = nint ( (x0(1)*bg(1,2) + x0(2)*bg(2,2) + x0(3)*bg(3,2) )*nr2) + 1
  nz0 = nint ( (x0(1)*bg(1,3) + x0(2)*bg(2,3) + x0(3)*bg(3,3) )*nr3) + 1
  !
  if ( e1(2) .ne. 0.d0  .or.  e1(3) .ne. 0.d0 .or. &
       e2(1) .ne. 0.d0  .or.  e2(3) .ne. 0.d0 .or. &
       e3(1) .ne. 0.d0  .or.  e3(2) .ne. 0.d0 )   &
       call errore ('plot_fast','need vectors along x,y,z',1)

  ! find FFT grid points closer to X0 + e1, X0 + e2, X0 + e3
  ! (the opposite vertex of the parallelepiped)

  nx1 = nint ( ((x0(1)+m1)*bg(1,1)+x0(2)*bg(2,1)+x0(3)*bg(3,1) )*nr1)
  ny1 = nint ( (x0(1)*bg(1,2)+(x0(2)+m2)*bg(2,2)+x0(3)*bg(3,2) )*nr2)
  nz1 = nint ( (x0(1)*bg(1,3)+x0(2)*bg(2,3)+(x0(3)+m3)*bg(3,3) )*nr3)

  nx = nx1 - nx0 + 1
  ny = ny1 - ny0 + 1
  nz = nz1 - nz0 + 1

  allocate ( carica(nx, ny, nz) )    

  carica = 0.d0
  do k = nz0, nz1
     k1 = mod(k, nr3)
     if (k1.le.0) k1 = k1 + nr3
     do j = ny0, ny1
        j1 = mod(j, nr2)
        if (j1.le.0) j1 = j1 + nr2
        do i = nx0, nx1
           i1 = mod(i, nr1)
           if (i1.le.0) i1 = i1 + nr1
           carica (i-nx0+1, j-ny0+1, k-nz0+1) = rho(i1, j1, k1)
        enddo
     enddo
  enddo
  !
  ! recalculate m1, m2, m3 (the sides of the parallelepiped divided by alat)
  ! consistent with the FFT grid
  !
  WRITE( stdout,'(5x,"Requested parallelepiped sides : ",3f8.4)') m1, m2,m3
  m1 = nx * sqrt (at(1, 1) **2 + at(2, 1) **2 + at(3, 1) **2) / nr1
  m2 = ny * sqrt (at(1, 2) **2 + at(2, 2) **2 + at(3, 2) **2) / nr2
  m3 = nz * sqrt (at(1, 3) **2 + at(2, 3) **2 + at(3, 3) **2) / nr3
  WRITE( stdout,'(5x,"Redefined parallelepiped sides : ",3f8.4)') m1, m2,m3
  !
  ! recalculate x0 (the origin of the parallelepiped)
  ! consistent with the FFT grid
  !
  WRITE( stdout,'(5x,"Requested parallelepiped origin: ",3f8.4)') x0
  x0(1)=(nx0-1)*at(1,1)/ nr1 +(ny0-1)*at(1,2)/ nr2 +(nz0-1)*at(1,3)/ nr3
  x0(2)=(nx0-1)*at(2,1)/ nr1 +(ny0-1)*at(2,2)/ nr2 +(nz0-1)*at(2,3)/ nr3
  x0(3)=(nx0-1)*at(3,1)/ nr1 +(ny0-1)*at(3,2)/ nr2 +(nz0-1)*at(3,3)/ nr3
  WRITE( stdout,'(5x,"Redefined parallelepiped origin: ",3f8.4)') x0

  deltax = m1/nx 
  deltay = m2/ny 
  deltaz = m3/nz 
  !
  !    Here we check the value of the resulting charge
  !
  call volume(alat,at(1,1),at(1,2),at(1,3),omega)

  rhomin = MAX ( MINVAL (carica), 1.d-10 )
  rhomax = MAXVAL (carica)
  rhotot = SUM (carica(:,:,:)) * omega * deltax * deltay * deltaz
  rhoabs = SUM (ABS(carica(:,:,:))) * omega * deltax * deltay * deltaz

  print '(/5x,"Min, Max, Total, Abs charge: ",4f10.6)', rhomin, &
       rhomax, rhotot, rhoabs

  if (output_format == 4) then
     !
     !     "gopenmol" file
     !
     call write_openmol_file (alat, at, nat, tau, atm, ityp, x0, &
          m1, m2, m3, nx, ny, nz, rhomax, carica, ounit)
  else
     !
     ! write XSF format
     !
     call xsf_struct (alat, at, nat, tau, atm, ityp, ounit)
     call xsf_datagrid_3d (carica, nx, ny, nz, m1, m2, m3, x0, &
          e1, e2, e3, alat, ounit)
  endif
  !
  deallocate (carica)
  return

end subroutine plot_fast
!
!-----------------------------------------------------------------------
subroutine write_openmol_file (alat, at, nat, tau, atm, ityp, x0, &
     m1, m2, m3, nx, ny, nz, rhomax, carica, ounit)
  !-----------------------------------------------------------------------
  USE io_global,  ONLY : stdout
  USE kinds, only : DP
  implicit none
  integer :: nat, ityp (nat), nx, ny, nz, ounit
  real(DP) :: alat, tau (3, nat), at (3, 3), rhomax, x0 (3), &
       m1, m2, m3, carica (nx, ny, nz)
  character(len=3) :: atm(*)
  !
  integer, parameter :: MAXATOMS = 999
  real, parameter :: bohr = 0.529177
  integer :: natoms
  character(len=2) type (MAXATOMS)
  integer :: n1, n2, n3, na, i
  real(DP) :: atoms (3, MAXATOMS), r (3), x, y, z
  real(DP) :: sidex, sidey, sidez
  !
  !   sides of the parallelepiped in A
  !
  sidex = m1 * alat * bohr
  sidey = m2 * alat * bohr
  sidez = m3 * alat * bohr

  ! really bad algorithm to  generate (hopefully) all atoms
  ! that are inside the visualization box

  natoms = 0
  do n1 = - 3, + 3
     do n2 = - 3, + 3
        do n3 = - 3, + 3
           do i = 1, 3
              r (i) = n1 * at (i, 1) + n2 * at (i, 2) + n3 * at (i, 3)
           enddo
           do na = 1, nat
              ! x,y,z are in A
              x = (tau (1, na) + r (1) - x0 (1) ) * alat * bohr
              y = (tau (2, na) + r (2) - x0 (2) ) * alat * bohr
              z = (tau (3, na) + r (3) - x0 (3) ) * alat * bohr
              if ( x.gt.0d0 .and. x.lt.sidex .and. &
                   y.gt.0d0 .and. y.lt.sidey .and. &
                   z.gt.0d0 .and. z.lt.sidez) then
                 natoms = natoms + 1
                 if (natoms.gt.MAXATOMS) then
                    print '(" MAXATOMS (",i4,") Exceeded, " &
                         &       ,"Truncating " )', MAXATOMS
                    natoms = MAXATOMS
                    goto 10
                 endif
                 !
                 atoms (1, natoms) = x
                 atoms (2, natoms) = y
                 atoms (3, natoms) = z
                 !
                 type(natoms)=atm(ityp(na))
              endif
           enddo
        enddo
     enddo

  enddo

10 WRITE( stdout,'(5x,"Found ",i4," atoms in the box")') natoms
  write(ounit,'("  3 2")')
  write(ounit,'(3i5)') nz,ny,nx
  write(ounit,'(6f10.4)') 0.0,sidez,0.0,sidey,0.0,sidex
  do n3=1,nz
     do n2 = 1, ny
        do n1 = 1, nx
           write (ounit, '(f20.10)') carica (n1, n2, n3)
        enddo
     enddo
  enddo
  !
  ! gopenmol needs atomic positions in a separate file
  !
  write(ounit+1,'(i4)') natoms
  write(ounit+1,'(2x,a2,3f9.4)') (type(na),( atoms(i,na), i=1,3 ), na=1,natoms )
  !
  return
end subroutine write_openmol_file
