!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
!
!-----------------------------------------------------------------------
SUBROUTINE scatter( f_in, f_out )
  !-----------------------------------------------------------------------
  !
  ! ... scatters data from the first processor of every pool
  !
  ! ... REAL*8 f_in  = gathered variable (nrx1*nrx2*nrx3)
  ! ... REAL*8 f_out = distributed variable (nxx)
  !
#if defined (__PARA)
  !
  USE pfft,   ONLY : ncplane, npp, nxx 
  USE para,   ONLY : me, MPI_COMM_POOL, nprocp
  USE mp,     ONLY : mp_barrier
  USE kinds,  ONLY : DP
  !
  IMPLICIT NONE
  !
  INCLUDE 'mpif.h'    
  REAL (KIND=DP) :: f_in( * ), f_out(nxx)
  INTEGER :: root, proc, info, displs(nprocp), sendcount(nprocp)
  !
  !
  root = 0
  !
  CALL start_clock( 'scatter' )
  !
  DO proc = 1, nprocp
     !
     sendcount(proc) = ncplane * npp(proc)
     !
     IF ( proc == 1 ) THEN
        !
        displs(proc) = 0
        !
     ELSE
        !
        displs(proc) = displs(proc-1) + sendcount(proc-1)
        !
     END IF
     !
  END DO
  !
  CALL mp_barrier( MPI_COMM_POOL )
  !  
  CALL MPI_scatterv( f_in, sendcount, displs, MPI_REAL8, f_out, &
                     sendcount(me), MPI_REAL8, root, MPI_COMM_POOL, info )
  !
  CALL errore( 'scatter', 'info<>0', info )
  !
  IF ( sendcount(me) /= nxx ) f_out(sendcount(me)+1:nxx) = 0.D0
  !
  CALL stop_clock( 'scatter' )
  !
#endif
  !
  RETURN
  !
END SUBROUTINE scatter
