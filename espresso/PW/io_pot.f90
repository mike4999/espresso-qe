!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "machine.h"
!
!----------------------------------------------------------------------------
SUBROUTINE io_pot( iop, filename, pot, nc )
  !----------------------------------------------------------------------------
  !
  ! ... This routine reads ( iop = - 1 ) or write ( iop = + 1 ) the
  ! ... potential in real space onto a file
  !
  USE kinds,        ONLY : DP
  USE gvect,        ONLY : nrxx, nrx1, nrx2, nrx3
  USE mp_global,    ONLY : inter_pool_comm, me_pool, &
                           root_pool, me_image, root_image, my_image_id
  USE mp,           ONLY : mp_bcast
  !
  IMPLICIT NONE
  !
  INTEGER           :: iop, nc, ic
    ! option: write if + 1,  read if - 1
    ! number of components and index for them
  CHARACTER (LEN=*) :: filename
  REAL(KIND=DP)     :: pot(nrxx,nc)
  LOGICAL           :: exst
#if defined (__PARA)
  REAL(KIND=DP), ALLOCATABLE :: allv(:,:)
#endif
  !
  ! 
#if defined (__PARA)
  !
  ! ... parallel case
  !
  IF ( me_pool == root_pool ) ALLOCATE( allv( nrx1*nrx2*nrx3, nc ) )
  !
  ! ... On writing: gather the potential on the first node of each pool
  !
  IF ( iop == 1 ) THEN
     !
     DO ic = 1, nc
        !
        CALL gather( pot(1,ic), allv(1,ic) )
        !
     END DO
     !
  END IF
  !
  IF ( me_image == root_image ) THEN
     !
     ! ... Only the first node of the first pool reads or writes the file
     !
     CALL seqopn( 4, filename, 'UNFORMATTED', exst )
     !
     IF ( iop == 1 ) THEN
        !
        WRITE( 4, err = 10 ) allv
        !   
     ELSE
        !
        READ( 4, err = 20 ) allv
        !
     END IF
     !
     CLOSE( UNIT = 4 )
     !
  END IF
  !
  ! ... On reading: copy the potential on the first node  of all pools
  ! ...             scatter the potential on all nodes of each pool
  !
  IF ( iop == - 1 ) THEN
     !
     IF ( me_pool == root_pool ) &
        CALL mp_bcast( allv, root_pool, inter_pool_comm(my_image_id) )
     !
     DO ic = 1, nc
        !        
        CALL scatter( allv(1,ic), pot(1,ic) )
        !
     END DO
     !
  END IF
  !
  IF ( me_pool == root_pool ) DEALLOCATE( allv )
  !
#else
  !
  ! ... serial case
  !
  CALL seqopn( 4, filename, 'UNFORMATTED', exst )
  !  
  IF ( iop == 1 ) THEN
     !
     WRITE( 4, err = 10 ) pot
     !
  ELSE
     !
     READ( 4, err = 20 ) pot
     !
  END IF
  !
  CLOSE( UNIT = 4 )
  !
#endif
  !
  RETURN
  !
10 CALL errore( 'io_pot', 'error writing ' // filename, 1 )
20 CALL errore( 'io_pot', 'error reading ' // filename, 2 )
  !
END SUBROUTINE io_pot
