!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file 'License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
#include "f_defs.h"
!---------------------------------------------------------------------
program uspp2upf
  !---------------------------------------------------------------------
  !
  !     Convert a pseudopotential written in Vanderbilt format
  !     (unformatted) to unified pseudopotential format
  !
  implicit none
  character(len=75) filein, fileout
  logical exst
  integer :: i,ilen,ierr
  integer, external :: iargc  
  !
  i = iargc ()  
  if (i.eq.0) then  
5    print '(''  Input PP file in unformatted Vanderbilt format > '',$)'  
     read (5, '(a)', end = 20, err = 20) filein
     exst=filein.ne.' '
     if (.not. exst) go to 5  
     inquire (file=filein,exist=exst)
     if(.not.exst) go to 5
  elseif (i.eq.1) then  
     call getarg(1, filein)  
  else  
     print '(''   usage: uspp2upf  [input file] '')'  
     stop
  end if

  open(unit=1,file=filein,status='old',form='unformatted')
  call read_uspp(1)
  close (unit=1)

  ! convert variables read from Vanderbilt format into those needed
  ! by the upf format - add missing quantities

  call convert_uspp

  fileout=trim(filein)//'.UPF'
  print '(''Output PP file in UPF format :  '',a)', fileout

  open(unit=2,file=fileout,status='unknown',form='formatted')
  call write_upf(2)
  close (unit=2)

  stop
20 call errore ('uspp2upf', 'Reading pseudo file name ', 1)
end program uspp2upf

