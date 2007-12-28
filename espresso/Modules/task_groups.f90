!
! Copyright (C) 2002-2004 PWSCF-FPMD-CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------
! Contributed by C. Bekas, October 2005
! Revised by C. Cavazzoni
!--------------------------------------------

MODULE task_groups

   USE kinds,      ONLY: DP

   IMPLICIT NONE
   SAVE


CONTAINS


!========================================================================================
! ADDED SUBROUTINEs FOR TASK GROUP PARALLIZATION
! C. Bekas, IBM Research, Zurich
!        - GROUPS: Define and initialize Task Groups
!        - tg_ivfftw: Inverse FFT driver for Task Groups
!=======================================================================================


!-----------------------------------------------------------------------
!      SUBROUTINE GROUPS (added by C. Bekas)
!      Define groups for task group parallilization
!-----------------------------------------------------------------------

SUBROUTINE task_groups_init( dffts )

   USE parallel_include
   !
   USE mp_global,      ONLY : me_pool, nproc_pool, intra_pool_comm
   USE mp_global,      ONLY : NOGRP, NPGRP, ogrp_comm, pgrp_comm  
   USE mp_global,      ONLY : nolist, nplist
   USE mp,             ONLY : mp_bcast
   USE io_global,      only : stdout
   USE fft_types,      only : fft_dlay_descriptor

   ! T.G. 
   ! NPGRP:      Number of processors per group
   ! NOGRP:      Number of group

   IMPLICIT NONE 

   TYPE(fft_dlay_descriptor), INTENT(INOUT) :: dffts

   !----------------------------------
   !Local Variables declaration
   !----------------------------------

   INTEGER  :: MSGLEN, I, J, N1, IPOS, WORLD, NEWGROUP
   INTEGER  :: IERR
   INTEGER  :: itsk, ntsk, color, key
   INTEGER  :: num_planes, num_sticks
   INTEGER  :: nnrsx_vec ( nproc_pool )
   INTEGER  :: pgroup( nproc_pool )
   INTEGER  :: strd

   !
   WRITE( stdout, 100 ) nogrp, npgrp

100 FORMAT( /,3X,'Task Groups are in use',/,3X,'groups and procs/group : ',I5,I5 )

   !--------------------------------------------------------------
   !SUBDIVIDE THE PROCESSORS IN GROUPS
   !
   !THE NUMBER OF GROUPS HAS TO BE A DIVISOR OF THE NUMBER
   !OF PROCESSORS
   !--------------------------------------------------------------

   IF( MOD( nproc_pool, nogrp ) /= 0 ) &
      CALL errore( " groups ", " nogrp should be a divisor of nproc_pool ", 1 )
   !
   DO i = 1, nproc_pool
      pgroup( i ) = i - 1
   ENDDO
   !
   !--------------------------------------
   !LIST OF PROCESSORS IN MY ORBITAL GROUP
   !--------------------------------------
   !
   !  processors in these group have contiguous indexes
   !
   N1 = ( me_pool / NOGRP ) * NOGRP - 1
   DO i = 1, nogrp
      nolist( I ) = pgroup( N1 + I + 1 )
      IF( me_pool == nolist( I ) ) ipos = i - 1
   ENDDO

   !-----------------------------------------
   !LIST OF PROCESSORS IN MY PLANE WAVE GROUP
   !-----------------------------------------
   !
   DO I = 1, npgrp
      nplist( I ) = pgroup( ipos + ( i - 1 ) * nogrp + 1 )
   ENDDO

   !-----------------
   !SET UP THE GROUPS
   !-----------------
   !

   !---------------------------------------
   !CREATE ORBITAL GROUPS
   !---------------------------------------
   !
#if defined __MPI
   color = me_pool / nogrp
   key   = MOD( me_pool , nogrp )
   CALL MPI_COMM_SPLIT( intra_pool_comm, color, key, ogrp_comm, ierr )
   if( ierr /= 0 ) &
      CALL errore( ' task_groups_init ', ' creating ogrp_comm ', ABS(ierr) )
   CALL MPI_COMM_RANK( ogrp_comm, itsk, IERR )
   CALL MPI_COMM_SIZE( ogrp_comm, ntsk, IERR )
   IF( nogrp /= ntsk ) CALL errore( ' task_groups_init ', ' ogrp_comm size ', ntsk )
   DO i = 1, nogrp
      IF( me_pool == nolist( i ) ) THEN
         IF( (i-1) /= itsk ) CALL errore( ' task_groups_init ', ' ogrp_comm rank ', itsk )
      END IF
   END DO
#endif

   !---------------------------------------
   !CREATE PLANEWAVE GROUPS
   !---------------------------------------
   !
#if defined __MPI
   color = MOD( me_pool , nogrp )
   key   = me_pool / nogrp
   CALL MPI_COMM_SPLIT( intra_pool_comm, color, key, pgrp_comm, ierr )
   if( ierr /= 0 ) &
      CALL errore( ' task_groups_init ', ' creating pgrp_comm ', ABS(ierr) )
   CALL MPI_COMM_RANK( pgrp_comm, itsk, IERR )
   CALL MPI_COMM_SIZE( pgrp_comm, ntsk, IERR )
   IF( npgrp /= ntsk ) CALL errore( ' task_groups_init ', ' pgrp_comm size ', ntsk )
   DO i = 1, npgrp
      IF( me_pool == nplist( i ) ) THEN
         IF( (i-1) /= itsk ) CALL errore( ' task_groups_init ', ' pgrp_comm rank ', itsk )
      END IF
   END DO
#endif


   !Find maximum chunk of local data concerning coefficients of eigenfunctions in g-space

#if defined __MPI
   CALL MPI_Allgather( dffts%nnr, 1, MPI_INTEGER, nnrsx_vec, 1, MPI_INTEGER, intra_pool_comm, IERR)
   strd = MAXVAL( nnrsx_vec( 1:nproc_pool ) )
#else
   strd = dffts%nnr 
#endif

   IF( strd /= dffts%nnrx ) CALL errore( ' task_groups_init ', ' inconsistent nnrx ', 1 )

   !-------------------------------------------------------------------------------------
   !C. Bekas...TASK GROUP RELATED. FFT DATA STRUCTURES ARE ALREADY DEFINED ABOVE
   !-------------------------------------------------------------------------------------
   !dfft%nsw(me) holds the number of z-sticks for the current processor per wave-function
   !We can either send these in the group with an mpi_allgather...or put the
   !in the PSIS vector (in special positions) and send them with them.
   !Otherwise we can do this once at the beginning, before the loop.
   !we choose to do the latter one.
   !-------------------------------------------------------------------------------------
   !
   ALLOCATE( dffts%tg_nsw(nproc_pool))
   ALLOCATE( dffts%tg_npp(nproc_pool))

   num_sticks = 0
   num_planes = 0
   DO i = 1, nogrp
      num_sticks = num_sticks + dffts%nsw( nolist(i) + 1 )
      num_planes = num_planes + dffts%npp( nolist(i) + 1 )
   ENDDO

#if defined __MPI
   CALL MPI_ALLGATHER(num_sticks, 1, MPI_INTEGER, dffts%tg_nsw(1), 1, MPI_INTEGER, intra_pool_comm, IERR)
   CALL MPI_ALLGATHER(num_planes, 1, MPI_INTEGER, dffts%tg_npp(1), 1, MPI_INTEGER, intra_pool_comm, IERR)
#else
   dffts%tg_nsw(1) = num_sticks
   dffts%tg_npp(1) = num_planes
#endif

   dffts%use_task_groups = .TRUE.

   RETURN

   END SUBROUTINE task_groups_init


END MODULE task_groups
