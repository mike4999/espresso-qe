!
! Copyright (C) 2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE mp_bands
  !----------------------------------------------------------------------------
  !
  USE mp, ONLY : mp_barrier, mp_bcast, mp_size, mp_rank
  USE command_line_options, ONLY : nband_
  USE parallel_include
  !
  IMPLICIT NONE 
  SAVE
  !
  ! ... Band groups (processors within a pool of bands)
  ! ... Subdivision of pool group, used for parallelization over bands
  !
  INTEGER :: nbgrp       = 1  ! number of band groups
  INTEGER :: nproc_bgrp  = 1  ! number of processors within a band group
  INTEGER :: me_bgrp     = 0  ! index of the processor within a band group
  INTEGER :: root_bgrp   = 0  ! index of the root processor within a band group
  INTEGER :: my_bgrp_id  = 0  ! index of my band group
  INTEGER :: inter_bgrp_comm  = 0  ! inter band group communicator
  INTEGER :: intra_bgrp_comm  = 0  ! intra band group communicator  
  !
  ! ... The following variables not set during initialization but later
  !
  INTEGER :: ibnd_start = 0 ! starting band index
  INTEGER :: ibnd_end = 0   ! ending band index
  !
CONTAINS
  !
  !----------------------------------------------------------------------------
  SUBROUTINE mp_start_bands( parent_comm )
    !---------------------------------------------------------------------------
    !
    ! ... Divide processors (of the "parent_comm" group) into bands pools
    ! ... Requires: nband_, read from command line
    ! ...           parent_comm, typically processors of a k-point pool
    ! ...           (intra_pool_comm)
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: parent_comm
    !
    INTEGER :: parent_nproc = 1, parent_mype = 0, ierr = 0
    !
#if defined (__MPI)
    !
    parent_nproc = mp_size( parent_comm )
    parent_mype  = mp_rank( parent_comm )
    !
    ! ... nband_ must have been previously read from command line argument
    ! ... by a call to routine get_command_line
    !
    nbgrp = nband_
    !
    IF ( nbgrp < 1 .OR. nbgrp > parent_nproc ) CALL errore( 'init_bands', &
                          'invalid number of band groups, out of range', 1 )
    IF ( MOD( parent_nproc, nbgrp ) /= 0 ) CALL errore( 'init_bands', &
        'n. of band groups  must be divisor of parent_nproc', 1 )
    ! 
    ! ... Set number of processors per band group
    !
    nproc_bgrp = parent_nproc / nbgrp
    !
    ! ... set index of band group for this processor   ( 0 : nbgrp - 1 )
    !
    my_bgrp_id = parent_mype / nproc_bgrp
    !
    ! ... set index of processor within the image ( 0 : nproc_image - 1 )
    !
    me_bgrp    = MOD( parent_mype, nproc_bgrp )
    !
    CALL mp_barrier( parent_comm )
    !
    ! ... the intra_bgrp_comm communicator is created
    !
    CALL MPI_COMM_SPLIT( parent_comm, my_bgrp_id, parent_mype, intra_bgrp_comm, ierr )
    !
    IF ( ierr /= 0 ) CALL errore( 'init_bands', &
                     'intra band group communicator initialization', ABS(ierr) )
    !
    CALL mp_barrier( parent_comm )
    !
    ! ... the inter_bgrp_comm communicator is created                     
    !     
    CALL MPI_COMM_SPLIT( parent_comm, me_bgrp, parent_mype, inter_bgrp_comm, ierr )  
    !
    IF ( ierr /= 0 ) CALL errore( 'init_bands', &
                     'inter band group communicator initialization', ABS(ierr) )
    !
#endif
    RETURN
    !
  END SUBROUTINE mp_start_bands
  !
  SUBROUTINE init_index_over_band (comm,nbnd)
    !
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: comm, nbnd

    INTEGER :: npe, myrank, ierror, rest, k

    myrank = mp_rank(comm)
    npe = mp_size(comm)

    rest = mod(nbnd, npe)
    k = int(nbnd/npe)

    IF ( k >= 1) THEN
       IF (rest > myrank) THEN
          ibnd_start = (myrank)*k + (myrank+1)
          ibnd_end  =  (myrank+1)*k + (myrank+1)
       ELSE
          ibnd_start = (myrank)*k + rest + 1
          ibnd_end  =  (myrank+1)*k + rest
       ENDIF
    ELSE
       ibnd_start = 1
       ibnd_end = nbnd
    ENDIF

  END SUBROUTINE init_index_over_band
  !
END MODULE mp_bands
