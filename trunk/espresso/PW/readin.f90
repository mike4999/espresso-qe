!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine readpp (pseudo_dir, pseudop)  
  !-----------------------------------------------------------------------
  !
  !    Read pseudopotentials
  !
#include "machine.h"
  use pwcom  
  ! input
  character :: pseudo_dir * 50  
  ! the directory containing pseudo files
  character (len=30) :: pseudop (npsx)  
  ! the name of pseudo files
  ! local
  character :: file_pseudo * 80  
  ! file name complete with path
  integer :: iunps, isupf, l, nt, ios, pseudo_type
  external pseudo_type
  !
  iunps = 4  
  l = len_trim (pseudo_dir)  
  do nt = 1, ntyp  
     ! add / if needed
     if (pseudo_dir (l:l) .ne.'/') then  
        file_pseudo = pseudo_dir (1:l) //'/'//pseudop (nt)  
     else  
        file_pseudo = pseudo_dir (1:l) //pseudop (nt)  

     endif
     !   The new pseudopotential UPF format is detected via the presence
     !   of the keyword 'begin_header' at the start of the file

     open (unit = iunps, file = file_pseudo, status = 'old', form = &
          'formatted', iostat = ios)

     call read_pseudo (nt, iunps, isupf)  
     if (isupf /= 0) then  
        rewind (unit = iunps)  
        !
        !     The type of the pseudopotential is determined by the file name:
        !    *.vdb or *.van  Vanderbilt US pseudopotential code  pseudo_type=1
        !    *.RRKJ3         Andrea's   US new code              pseudo_type=2
        !    none of the above: PWSCF norm-conserving format     pseudo_type=0
        !
        if (pseudo_type (pseudop (nt) ) .eq.1 &
             .or.pseudo_type (pseudop (nt) ) .eq.2) then
           !
           !    The vanderbilt pseudopotential is always in numeric form
           !
           numeric (nt) = .true.  
           open (unit = iunps, file = file_pseudo, status = 'old', &
                form = 'formatted', iostat = ios)

           call error ('readin', 'file '//file_pseudo (1:len_trim ( &
                file_pseudo) ) //' not found', ios)
           !
           !    newpseudo distinguishes beteween US pseudopotentials
           !    produced by Vanderbilt code and those produced 
           !    by Andrea's atomic code.
           !
           if (pseudo_type (pseudop (nt) ) .eq.1) then  
              newpseudo (nt) = .false.  
              tvanp (nt) = .true.  
              call readvan (nt, iunps)  
           endif
           if (pseudo_type (pseudop (nt) ) .eq.2) then  
              newpseudo (nt) = .true.  
              ! tvanp is read inside readnewvan
              call readnewvan (nt, iunps)  
           endif
           close (iunps)  
        else  
           tvanp (nt) = .false.  
           newpseudo (nt) = .false.  
           open (unit = iunps, file = file_pseudo, status = 'old', &
                err = 350, iostat = ios)
350        call error ('readin', &
          'file '//file_pseudo (1:len_trim(file_pseudo) ) //' not found', ios)
           ! numeric is read inside read_ncpp
           call read_ncpp (nt, iunps)  
           close (iunps)  
        endif
     else  
        ! UPF is always numeric
        numeric (nt) = .true.  
        ! UPF is RRKJ3-like
        newpseudo (nt) = .true.  
        close (iunps)  
     endif

  enddo
  return  
end subroutine readpp
!-----------------------------------------------------------------------
integer function pseudo_type (pseudop)  
  !-----------------------------------------------------------------------
  implicit none  
  character (len=*) :: pseudop  
  integer :: l  
  !
  l = len_trim (pseudop)  
  pseudo_type = 0  
  if (pseudop (l - 3:l) .eq.'.vdb'.or.pseudop (l - 3:l) .eq.'.van') &
       pseudo_type = 1
  if (l > 5) then
     if (pseudop (l - 5:l) .eq.'.RRKJ3') pseudo_type = 2  
  end if
  !
  return  

end function pseudo_type

