!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------

subroutine gather (f_in, f_out)  
  !-----------------------------------------------------------------------
  ! gathers nprocp distributed data on the first processor of every pool
  !
  ! REAL*8 f_in = distributed variable (nxx)
  ! REAL*8 f_out= gathered variable (nrx1*nrx2*nrx3)
  !
#ifdef PARA
#include "machine.h"
  use para
  use parameters, only : DP
  implicit none  

  real (8) :: f_in (nxx), f_out ( * )  
  include 'mpif.h'  


  integer :: root, proc, info, displs (nprocp), recvcount (nprocp)  
  root = 0  
  call start_clock ('gather')  
  do proc = 1, nprocp  
     recvcount (proc) = ncplane * npp (proc)  
     if (proc.eq.1) then  
        displs (proc) = 0  
     else  
        displs (proc) = displs (proc - 1) + recvcount (proc - 1)  
     endif

  enddo
  call mpi_barrier (MPI_COMM_POOL, info)  

  call mpi_gatherv (f_in, recvcount (me), MPI_REAL8, f_out, &
       recvcount, displs, MPI_REAL8, root, MPI_COMM_POOL, info)
  call error ('gather', 'info<>0', info)  
  call stop_clock ('gather')  
#endif
  return  
end subroutine gather
