!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
program pwscf
  !-----------------------------------------------------------------------
  !
  !     Plane Wave Self-Consistent Field
  !
  use pwcom
  use io
  use global_version
  implicit none
  character(len=9) :: code = 'PWSCF'
  external date_and_tim
  ! use ".false." to disable all clocks except the total cpu time clock
  ! use ".true."  to enable clocks
  !      call init_clocks(.false.)

  call init_clocks (.true.)
  call start_clock ('PWSCF')
  gamma_only =.true.
  call startup (nd_nmbr, code, version_number)
  call init_run
  istep = 0
  do while (istep.lt.nstep)
     istep = istep + 1
     call electrons
     if (.not.conv_elec) call stop_pw (conv_elec)
     call ions
     if (conv_ions) goto 10
     call hinit1

  enddo

10 call punch

  call stop_pw (conv_ions)
  stop
end program pwscf


