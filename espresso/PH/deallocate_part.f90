!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------
subroutine deallocate_part()
!----------===============-------------------------

  use phcom

  if (allocated(comp_irr)) deallocate (comp_irr)    
  if (allocated(ifat)) deallocate (ifat)    
  if (allocated(done_irr)) deallocate (done_irr)    
  if (allocated(list)) deallocate (list)    
  if (allocated(atomo)) deallocate (atomo)    


  return
end subroutine deallocate_part
