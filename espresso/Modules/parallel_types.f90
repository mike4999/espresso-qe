!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

      MODULE parallel_types
        USE kinds
        IMPLICIT NONE
        PRIVATE
        SAVE


        TYPE processors_grid
          INTEGER :: context  !  Communication handle, grid identification
          INTEGER :: nproc    !  number of processors in the grid
          INTEGER :: my_pe    !  process index (0 ... nproc -1)
          INTEGER :: npx      !  Grid dimensions :  
          INTEGER :: npy      !  (nprows, npcolumns, npplanes)
          INTEGER :: npz      !  
          INTEGER :: mex      !  Processor coordinates:
          INTEGER :: mey      !  (mex, mey, mez)
          INTEGER :: mez      !  0 <= mex < npx-1
                              !  0 <= mey < npy-1
                              !  0 <= mez < npz-1
        END TYPE

! ...   Valid values for data shape
        INTEGER, PARAMETER :: BLOCK_CYCLIC_SHAPE = 1
        INTEGER, PARAMETER :: BLOCK_PARTITION_SHAPE = 2
        INTEGER, PARAMETER :: FREE_PATTERN_SHAPE = 3
        INTEGER, PARAMETER :: REPLICATED_DATA_SHAPE = 4
        INTEGER, PARAMETER :: CYCLIC_SHAPE = 5

!  ----------------------------------------------
!  BEGIN manual
!
!  Given the Array  |a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11|
!  and three processors P0, P1, P2 
!
!  in the BLOCK_PARTITION_SHAPE scheme, the Array is partitioned 
!  as follow
!       P0            P1            P2
!  |a1 a2 a3 a4| |a5 a6 a7 a8| |a9 a10 a11|
!
!  in the BLOCK_CYCLIC_SHAPE scheme the Array is first partitioned 
!  into blocks (i.e. of size 2)  |a1 a2|a3 a4|a5 a6|a7 a8|a9 a10|a11|
!  Then the block are distributed cyclically among P0, P1 and P2
!       P0             P1              P2
!  |a1 a2|a7 a8|  |a3 a4|a9 a10|  |a5 a6|a11|
!
!  in the CYCLIC_SHAPE scheme the Array elements are distributed round robin
!  among P0, P1 and P2
!       P0             P1              P2
!  |a1 a4 a7 a10|  |a2 a5 a8 a11|  |a3 a6 a9|
!
!  ----------------------------------------------
!  END manual



        TYPE descriptor
          INTEGER :: matrix_type     ! = 1, for dense matrices
          TYPE (processors_grid) :: grid ! Communication handle
          INTEGER :: nx     ! rows, number of rows in the global array
          INTEGER :: ny     ! columns, number of columns in the global array
          INTEGER :: nz     ! planes, number of planes in the global array
          INTEGER :: nxblk  ! row_block, if shape = BLOCK_CICLYC_SHAPE,
                            ! this value represent the blocking factor
                            ! used to distribute the rows of the array,
                            ! otherwise this is the size of local block of rows
          INTEGER :: nyblk  ! column_block, same as row_block but for columns
          INTEGER :: nzblk  ! plane_block, same as row_block but for planes
          INTEGER :: nxl    ! local_rows, number of rows in the local array
          INTEGER :: nyl    ! local_columns, number of columns in the local array
          INTEGER :: nzl    ! local_planes, number of planes in the local array
          INTEGER :: ixl    ! irow
          INTEGER :: iyl    ! icolumn
          INTEGER :: izl    ! iplane
          INTEGER :: ipexs  ! row_src_pe, process row over which the first row 
                            ! of the array is distributed
          INTEGER :: ipeys  ! column_src_pe, process column over which the first column
                            ! of the array is distributed
          INTEGER :: ipezs  ! plane_src_pe, process plane over which the first plane
                            ! of the array is distributed
          INTEGER :: ldx    ! local_ld, leading dimension of the local sub-block of the array
          INTEGER :: ldy    ! local_sub_ld, sub-leading dimension of the local sub-block
                            ! of the array
          INTEGER :: ldz    ! 

          INTEGER :: xshape ! row_shape
          INTEGER :: yshape ! column_shape
          INTEGER :: zshape ! plane_shape
        END TYPE
        
        
        TYPE integer_parallel_vector
          TYPE (descriptor), POINTER :: desc
          INTEGER, POINTER :: v(:)
        END TYPE

        TYPE real_parallel_vector
          TYPE (descriptor), POINTER :: desc
          REAL (dbl), POINTER :: v(:)
        END TYPE

        TYPE complex_parallel_vector
          TYPE (descriptor), POINTER :: desc
          COMPLEX (dbl), POINTER :: v(:)
        END TYPE


        TYPE integer_parallel_matrix
          TYPE (descriptor), POINTER :: desc
          INTEGER, POINTER :: m(:,:)
        END TYPE

        TYPE real_parallel_matrix
          TYPE (descriptor), POINTER :: desc
          REAL (dbl), POINTER :: m(:,:)
        END TYPE

        TYPE complex_parallel_matrix
          TYPE (descriptor), POINTER :: desc
          COMPLEX (dbl), POINTER :: m(:,:)
        END TYPE


        TYPE integer_parallel_tensor
          TYPE (descriptor), POINTER :: desc
          INTEGER, POINTER :: t(:,:,:)
        END TYPE

        TYPE real_parallel_tensor
          TYPE (descriptor), POINTER :: desc
          REAL (dbl), POINTER :: t(:,:,:)
        END TYPE

        TYPE complex_parallel_tensor
          TYPE (descriptor), POINTER :: desc
          COMPLEX (dbl), POINTER :: t(:,:,:)
        END TYPE


        PUBLIC :: processors_grid, descriptor, integer_parallel_vector, &
          integer_parallel_matrix, integer_parallel_tensor, &
          real_parallel_vector, real_parallel_matrix, real_parallel_tensor, &
          complex_parallel_vector, complex_parallel_matrix, &
          complex_parallel_tensor, parallel_allocate, parallel_deallocate

        PUBLIC ::  BLOCK_CYCLIC_SHAPE, BLOCK_PARTITION_SHAPE, &
          FREE_PATTERN_SHAPE, REPLICATED_DATA_SHAPE, CYCLIC_SHAPE

        INTERFACE parallel_allocate
          MODULE PROCEDURE allocate_real_vector, allocate_real_matrix, &
            allocate_real_tensor
        END INTERFACE
        INTERFACE parallel_deallocate
          MODULE PROCEDURE deallocate_real_vector, deallocate_real_matrix, &
            deallocate_real_tensor
        END INTERFACE

        INTEGER NUMROC
        EXTERNAL NUMROC

      CONTAINS

        SUBROUTINE allocate_real_vector(v,desc)
          TYPE (real_parallel_vector) :: v
          TYPE (descriptor), POINTER :: desc
          INTEGER :: locr
          locr = NUMROC( desc%nx, desc%nxblk, desc%grid%mex, &
                  desc%ipexs, desc%grid%npx )
          ALLOCATE(v%v(locr))
          v%desc => desc
          RETURN
        END SUBROUTINE
        SUBROUTINE allocate_real_matrix(m,desc)
          TYPE (real_parallel_matrix) :: m
          TYPE (descriptor), POINTER :: desc
          INTEGER :: locr, locc
          locr = desc%ldx
          locc = NUMROC( desc%ny, desc%nyblk, desc%grid%mey, &
                  desc%ipeys, desc%grid%npy )
          ALLOCATE(m%m(locr,locc))
          m%desc => desc
          RETURN
        END SUBROUTINE
        SUBROUTINE allocate_real_tensor(t,desc)
          TYPE (real_parallel_tensor) :: t
          TYPE (descriptor), POINTER :: desc
          INTEGER :: locr, locc, locp
          locr = desc%ldx
          locc = desc%ldy
          locp = NUMROC( desc%nz, desc%nzblk, desc%grid%mez, &
                  desc%ipezs, desc%grid%nproc  )
          ALLOCATE(t%t(locr,locc,locp))
          t%desc => desc
          RETURN
        END SUBROUTINE
        SUBROUTINE deallocate_real_vector(v)
          TYPE (real_parallel_vector) :: v
          DEALLOCATE(v%v)
          NULLIFY(v%desc) 
          RETURN
        END SUBROUTINE
        SUBROUTINE deallocate_real_matrix(m)
          TYPE (real_parallel_matrix) :: m
          DEALLOCATE(m%m)
          NULLIFY(m%desc) 
          RETURN
        END SUBROUTINE
        SUBROUTINE deallocate_real_tensor(t)
          TYPE (real_parallel_tensor) :: t
          DEALLOCATE(t%t)
          NULLIFY(t%desc)
          RETURN
        END SUBROUTINE

      END MODULE
