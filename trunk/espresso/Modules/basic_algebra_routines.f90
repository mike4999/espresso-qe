!
! Copyright (C) 2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#undef __NOBLAS
!
!----------------------------------------------------------------------------
MODULE basic_algebra_routines
  !----------------------------------------------------------------------------
  !
  ! ... Written by Carlo Sbraccia ( 16/12/2003 )
  !
  ! ... This module contains a limited number of functions and operators
  ! ... for vectorial algebra. Wherever possible the appropriate BLAS routine
  ! ... ( always the double precision version ) is used.
  ! ... If BLAS are not available compile this module with the -D__NOBLAS
  ! ... precompiler option.
  !
  ! ... List of public methods :
  !
  !  x .dot. y		implements the dot product between vectors ( <x|y> )
  !  norm( x )		computes the norm of a vector ( SQRT(<x|x>) )
  !  A .times. x	implements the matrix-vector multiplication ( A|x> )
  !  x .times. A	implements the vector-matrix multiplication ( <x|A )
  !  matrix( x, y )	implements the vector-vector multiplication ( |x><y| )
  !  identity( N )	the identity matrix in dimension N
  !
  !
  USE kinds,  ONLY : DP
  !
  IMPLICIT NONE
  !
  INTERFACE OPERATOR( .dot. )
     !
     MODULE PROCEDURE internal_dot_product
     !
  END INTERFACE
  !  
  INTERFACE OPERATOR( .times. )
     !
     MODULE PROCEDURE matrix_times_vector, vector_times_matrix
     !
  END INTERFACE
  !
  CONTAINS
     !
     !-----------------------------------------------------------------------
     FUNCTION internal_dot_product( input_vector1, input_vector2 )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       REAL (KIND=DP), INTENT(IN) :: input_vector1(:), input_vector2(:)
       REAL (KIND=DP)             :: internal_dot_product
#if defined (__NOBLAS)              
       !
       !
       internal_dot_product = DOT_PRODUCT( input_vector1, input_vector2 )
#else
       REAL (KIND=DP)             :: DDOT
       EXTERNAL                      DDOT
       !
       !
       internal_dot_product = DDOT( SIZE( input_vector1 ), &
                                    input_vector1, 1, input_vector2, 1 )
#endif
       !
     END FUNCTION internal_dot_product
     !
     !     
     !----------------------------------------------------------------------- 
     FUNCTION norm( input_vector )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       REAL (KIND=DP), INTENT(IN) :: input_vector(:)
       REAL (KIND=DP)             :: norm
#if  defined (__NOBLAS)       
       !
       !
       norm = SQRT( input_vector .dot. input_vector )
#else
       REAL (KIND=DP)             :: DNRM2
       EXTERNAL                      DNRM2   
       !
       !
       norm = DNRM2( SIZE( input_vector ), input_vector, 1 )
#endif
       !
     END FUNCTION norm
     !
     !
     !-----------------------------------------------------------------------
     FUNCTION matrix_times_vector( input_matrix , input_vector )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       REAL (KIND=DP), INTENT(IN) :: input_vector(:)
       REAL (KIND=DP), INTENT(IN) :: input_matrix(:,:)
       REAL (KIND=DP)             :: matrix_times_vector(SIZE( input_vector ))
       INTEGER                    :: dim
#if defined (__NOBLAS)
       INTEGER                    :: i
#endif       
       !
       !
       dim = SIZE( input_vector )
       !
#if defined (__NOBLAS)              
       DO i = 1, dim
          !
          matrix_times_vector(i) = input_matrix(i,:) .dot. input_vector(:)
          !
       END DO
#else
       CALL DGEMV( 'N', dim, dim, 1.D0, input_matrix, dim, &
                   input_vector, 1, 0.D0, matrix_times_vector, 1 )       
#endif
       !
     END FUNCTION  matrix_times_vector
     !
     !
     !-----------------------------------------------------------------------
     FUNCTION vector_times_matrix( input_vector , input_matrix )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       REAL (KIND=DP), INTENT(IN) :: input_vector(:)
       REAL (KIND=DP), INTENT(IN) :: input_matrix(:,:)
       REAL (KIND=DP)             :: vector_times_matrix(SIZE( input_vector ))
       INTEGER                    :: dim
#if defined (__NOBLAS)
       INTEGER                    :: i
#endif       
       !
       !
       dim = SIZE( input_vector )
       !
#if defined (__NOBLAS)              
       DO i = 1, dim
          !
          vector_times_matrix(i) = input_vector(:) .dot. input_matrix(:,i)
          !
       END DO
#else
       CALL DGEMV( 'T', dim, dim, 1.D0, input_matrix, dim, &
                   input_vector, 1, 0.D0, vector_times_matrix, 1 )       
#endif
       !
     END FUNCTION vector_times_matrix
     !
     !
     !-----------------------------------------------------------------------
     FUNCTION matrix( input_vector1 , input_vector2 )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       REAL (KIND=DP), INTENT(IN) :: input_vector1(:), input_vector2(:)
       REAL (KIND=DP)             :: matrix(SIZE( input_vector1 ),&
                                            SIZE( input_vector2 ))
       INTEGER                    :: dim1, dim2
#if defined (__NOBLAS)
       INTEGER                    :: i, j
#endif
       !
       !
       dim1 = SIZE( input_vector1 )
       dim2 = SIZE( input_vector2 )
       !
#if defined (__NOBLAS)              
       DO i = 1, dim1
          !
          DO j = 1, dim2
             !
             matrix(i,j) = input_vector1(i) * input_vector2(j)
             !
          END DO
          !
       END DO      
#else
       !
       matrix = 0.D0
       !
       CALL DGER( dim1, dim2, 1.D0, input_vector1, &
                  1, input_vector2, 1, matrix, dim1 )
#endif
       !
     END FUNCTION matrix
     !
     !
     !-----------------------------------------------------------------------
     FUNCTION identity( dim )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       INTEGER, INTENT(IN) :: dim
       REAL(KIND=DP)       :: identity(dim,dim)
       INTEGER             :: i
       !
       !
       identity = 0.D0
       !
       DO i = 1, dim
          !
          identity(i,i) = 1.D0
          !
       END DO
       !
     END FUNCTION identity
     !    
END MODULE basic_algebra_routines
