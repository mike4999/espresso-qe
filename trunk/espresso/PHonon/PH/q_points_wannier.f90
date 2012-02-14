!
! Copyright (C) 2001-2007 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!------------------------------------------------
SUBROUTINE q_points_wannier ( )
!----------========------------------------------

  USE kinds, only : dp
  USE io_global,  ONLY :  stdout, ionode
  USE mp_global, ONLY : me_pool, root_pool
  USE disp,  ONLY : nqmax, nq1, nq2, nq3, x_q, nqs
  USE output, ONLY : fildyn
  USE control_ph, ONLY : dvscf_dir
  USE el_phon, ONLY : wan_index_dyn
  USE dfile_autoname, ONLY : dfile_get_qlist
  USE dfile_star, ONLY : dvscf_star

  implicit none

  integer :: i, iq, ierr, iudyn = 26,idum,jdum
  integer :: iq_unit
  logical :: exist_gamma, check, skip_equivalence=.FALSE.
  logical :: exst
  logical, external :: check_q_points_sym
  real(DP), allocatable, dimension(:) :: wq

  INTEGER, EXTERNAL :: find_free_unit

  !
  !  calculate the Monkhorst-Pack grid
  !

  if( nq1 <= 0 .or. nq2 <= 0 .or. nq3 <= 0 ) &
       call errore('q_points','nq1 or nq2 or nq3 <= 0',1)

  nqs=nq1*nq2*nq3

  allocate (x_q(3,nqmax))
  allocate(wan_index_dyn(nqs))

!  !here read q_points
  CALL dfile_get_qlist(x_q, nqs, dvscf_star%basename, dvscf_star%directory)
!  IF (ionode) inquire (file =TRIM(dvscf_dir)//'Q_POINTS.D', exist = exst)
!  if(.not.exst) call errore('q_points_wannier','Q_POINTS.D not existing in dvscf_dir ',1)

!  iq_unit = find_free_unit()
!  OPEN (unit = iq_unit, file = trim(dvscf_dir)//'Q_POINTS.D', status = 'unknown')
!  rewind(iq_unit) 
  
!  do i=1,nqs
!     read(iq_unit,*) x_q(1,i), x_q(2,i), x_q(3,i), idum, wan_index_dyn(i)
!  enddo

  close(iq_unit)
  !
  ! Check if the Gamma point is one of the points and put
  ! 
  exist_gamma = .false.
  do iq = 1, nqs
     if ( abs(x_q(1,iq)) .lt. 1.0e-10_dp .and. &
          abs(x_q(2,iq)) .lt. 1.0e-10_dp .and. &
          abs(x_q(3,iq)) .lt. 1.0e-10_dp ) then
        exist_gamma = .true.
        if (iq .ne. 1) then
           call errore('q_points_wannier','first q in Q_POINTS.D must be Gamma',1)
        end if
     end if
  end do
  !
  ! Write the q points in the output
  !
  write(stdout, '(//5x,"Dynamical matrices for (", 3(i2,","),") &
           & uniform grid of q-points")') nq1, nq2, nq3
  write(stdout, '(5x,"(",i4,"q-points):")') nqs
  write(stdout, '(5x,"  N         xq(1)         xq(2)         xq(3) " )')
  do iq = 1, nqs
     write(stdout, '(5x,i3, 3f14.9)') iq, x_q(1,iq), x_q(2,iq), x_q(3,iq)
  end do
  !
  IF ( .NOT. exist_gamma) &
     CALL errore('q_points','Gamma is not a q point',1)

  !
  ! ... write the information on the grid of q-points to file
  !
  IF (ionode) THEN
     OPEN (unit=iudyn, file=TRIM(fildyn)//'0', status='unknown', iostat=ierr)
     IF ( ierr > 0 ) CALL errore ('phonon','cannot open file ' &
          & // TRIM(fildyn) // '0', ierr)
     WRITE (iudyn, '(3i4)' ) nq1, nq2, nq3
     WRITE (iudyn, '( i4)' ) nqs
     DO  iq = 1, nqs
        WRITE (iudyn, '(3e24.15)') x_q(1,iq), x_q(2,iq), x_q(3,iq)
     END DO
     CLOSE (unit=iudyn)
  END IF
  return
end subroutine q_points_wannier
!
