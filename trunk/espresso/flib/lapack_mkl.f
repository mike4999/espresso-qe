      SUBROUTINE DLAE2( A, B, C, RT1, RT2 )
*
*  -- LAPACK AUXILIARY ROUTINE (VERSION 1.1) --
*     UNIV. OF TENNESSEE, UNIV. OF CALIFORNIA BERKELEY, NAG LTD.,
*     COURANT INSTITUTE, ARGONNE NATIONAL LAB, AND RICE UNIVERSITY
*     OCTOBER 31, 1992
*
*     .. SCALAR ARGUMENTS ..
      DOUBLE PRECISION   A, B, C, RT1, RT2
*     ..
*
*  PURPOSE
*  =======
*
*  DLAE2  COMPUTES THE EIGENVALUES OF A 2-BY-2 SYMMETRIC MATRIX
*     [  A   B  ]
*     [  B   C  ].
*  ON RETURN, RT1 IS THE EIGENVALUE OF LARGER ABSOLUTE VALUE, AND RT2
*  IS THE EIGENVALUE OF SMALLER ABSOLUTE VALUE.
*
*  ARGUMENTS
*  =========
*
*  A       (INPUT) DOUBLE PRECISION
*          THE (1,1) ENTRY OF THE 2-BY-2 MATRIX.
*
*  B       (INPUT) DOUBLE PRECISION
*          THE (1,2) AND (2,1) ENTRIES OF THE 2-BY-2 MATRIX.
*
*  C       (INPUT) DOUBLE PRECISION
*          THE (2,2) ENTRY OF THE 2-BY-2 MATRIX.
*
*  RT1     (OUTPUT) DOUBLE PRECISION
*          THE EIGENVALUE OF LARGER ABSOLUTE VALUE.
*
*  RT2     (OUTPUT) DOUBLE PRECISION
*          THE EIGENVALUE OF SMALLER ABSOLUTE VALUE.
*
*  FURTHER DETAILS
*  ===============
*
*  RT1 IS ACCURATE TO A FEW ULPS BARRING OVER/UNDERFLOW.
*
*  RT2 MAY BE INACCURATE IF THERE IS MASSIVE CANCELLATION IN THE
*  DETERMINANT A*C-B*B; HIGHER PRECISION OR CORRECTLY ROUNDED OR
*  CORRECTLY TRUNCATED ARITHMETIC WOULD BE NEEDED TO COMPUTE RT2
*  ACCURATELY IN ALL CASES.
*
*  OVERFLOW IS POSSIBLE ONLY IF RT1 IS WITHIN A FACTOR OF 5 OF OVERFLOW.
*  UNDERFLOW IS HARMLESS IF THE INPUT DATA IS 0 OR EXCEEDS
*     UNDERFLOW_THRESHOLD / MACHEPS.
*
* =====================================================================
*
*     .. PARAMETERS ..
      DOUBLE PRECISION   ONE
      PARAMETER          ( ONE = 1.0D0 )
      DOUBLE PRECISION   TWO
      PARAMETER          ( TWO = 2.0D0 )
      DOUBLE PRECISION   ZERO
      PARAMETER          ( ZERO = 0.0D0 )
      DOUBLE PRECISION   HALF
      PARAMETER          ( HALF = 0.5D0 )
*     ..
*     .. LOCAL SCALARS ..
      DOUBLE PRECISION   AB, ACMN, ACMX, ADF, DF, RT, SM, TB
*     ..
*     .. INTRINSIC FUNCTIONS ..
      INTRINSIC          ABS, SQRT
*     ..
*     .. EXECUTABLE STATEMENTS ..
*
*     COMPUTE THE EIGENVALUES
*
      SM = A + C
      DF = A - C
      ADF = ABS( DF )
      TB = B + B
      AB = ABS( TB )
      IF( ABS( A ).GT.ABS( C ) ) THEN
         ACMX = A
         ACMN = C
      ELSE
         ACMX = C
         ACMN = A
      END IF
      IF( ADF.GT.AB ) THEN
         RT = ADF*SQRT( ONE+( AB / ADF )**2 )
      ELSE IF( ADF.LT.AB ) THEN
         RT = AB*SQRT( ONE+( ADF / AB )**2 )
      ELSE
*
*        INCLUDES CASE AB=ADF=0
*
         RT = AB*SQRT( TWO )
      END IF
      IF( SM.LT.ZERO ) THEN
         RT1 = HALF*( SM-RT )
*
*        ORDER OF EXECUTION IMPORTANT.
*        TO GET FULLY ACCURATE SMALLER EIGENVALUE,
*        NEXT LINE NEEDS TO BE EXECUTED IN HIGHER PRECISION.
*
         RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
      ELSE IF( SM.GT.ZERO ) THEN
         RT1 = HALF*( SM+RT )
*
*        ORDER OF EXECUTION IMPORTANT.
*        TO GET FULLY ACCURATE SMALLER EIGENVALUE,
*        NEXT LINE NEEDS TO BE EXECUTED IN HIGHER PRECISION.
*
         RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
      ELSE
*
*        INCLUDES CASE RT1 = RT2 = 0
*
         RT1 = HALF*RT
         RT2 = -HALF*RT
      END IF
      RETURN
*
*     END OF DLAE2
*
      END
      SUBROUTINE DLAEV2( A, B, C, RT1, RT2, CS1, SN1 )
*
*  -- LAPACK AUXILIARY ROUTINE (VERSION 1.1) --
*     UNIV. OF TENNESSEE, UNIV. OF CALIFORNIA BERKELEY, NAG LTD.,
*     COURANT INSTITUTE, ARGONNE NATIONAL LAB, AND RICE UNIVERSITY
*     OCTOBER 31, 1992
*
*     .. SCALAR ARGUMENTS ..
      DOUBLE PRECISION   A, B, C, CS1, RT1, RT2, SN1
*     ..
*
*  PURPOSE
*  =======
*
*  DLAEV2 COMPUTES THE EIGENDECOMPOSITION OF A 2-BY-2 SYMMETRIC MATRIX
*     [  A   B  ]
*     [  B   C  ].
*  ON RETURN, RT1 IS THE EIGENVALUE OF LARGER ABSOLUTE VALUE, RT2 IS THE
*  EIGENVALUE OF SMALLER ABSOLUTE VALUE, AND (CS1,SN1) IS THE UNIT RIGHT
*  EIGENVECTOR FOR RT1, GIVING THE DECOMPOSITION
*
*     [ CS1  SN1 ] [  A   B  ] [ CS1 -SN1 ]  =  [ RT1  0  ]
*     [-SN1  CS1 ] [  B   C  ] [ SN1  CS1 ]     [  0  RT2 ].
*
*  ARGUMENTS
*  =========
*
*  A       (INPUT) DOUBLE PRECISION
*          THE (1,1) ENTRY OF THE 2-BY-2 MATRIX.
*
*  B       (INPUT) DOUBLE PRECISION
*          THE (1,2) ENTRY AND THE CONJUGATE OF THE (2,1) ENTRY OF THE
*          2-BY-2 MATRIX.
*
*  C       (INPUT) DOUBLE PRECISION
*          THE (2,2) ENTRY OF THE 2-BY-2 MATRIX.
*
*  RT1     (OUTPUT) DOUBLE PRECISION
*          THE EIGENVALUE OF LARGER ABSOLUTE VALUE.
*
*  RT2     (OUTPUT) DOUBLE PRECISION
*          THE EIGENVALUE OF SMALLER ABSOLUTE VALUE.
*
*  CS1     (OUTPUT) DOUBLE PRECISION
*  SN1     (OUTPUT) DOUBLE PRECISION
*          THE VECTOR (CS1, SN1) IS A UNIT RIGHT EIGENVECTOR FOR RT1.
*
*  FURTHER DETAILS
*  ===============
*
*  RT1 IS ACCURATE TO A FEW ULPS BARRING OVER/UNDERFLOW.
*
*  RT2 MAY BE INACCURATE IF THERE IS MASSIVE CANCELLATION IN THE
*  DETERMINANT A*C-B*B; HIGHER PRECISION OR CORRECTLY ROUNDED OR
*  CORRECTLY TRUNCATED ARITHMETIC WOULD BE NEEDED TO COMPUTE RT2
*  ACCURATELY IN ALL CASES.
*
*  CS1 AND SN1 ARE ACCURATE TO A FEW ULPS BARRING OVER/UNDERFLOW.
*
*  OVERFLOW IS POSSIBLE ONLY IF RT1 IS WITHIN A FACTOR OF 5 OF OVERFLOW.
*  UNDERFLOW IS HARMLESS IF THE INPUT DATA IS 0 OR EXCEEDS
*     UNDERFLOW_THRESHOLD / MACHEPS.
*
* =====================================================================
*
*     .. PARAMETERS ..
      DOUBLE PRECISION   ONE
      PARAMETER          ( ONE = 1.0D0 )
      DOUBLE PRECISION   TWO
      PARAMETER          ( TWO = 2.0D0 )
      DOUBLE PRECISION   ZERO
      PARAMETER          ( ZERO = 0.0D0 )
      DOUBLE PRECISION   HALF
      PARAMETER          ( HALF = 0.5D0 )
*     ..
*     .. LOCAL SCALARS ..
      INTEGER            SGN1, SGN2
      DOUBLE PRECISION   AB, ACMN, ACMX, ACS, ADF, CS, CT, DF, RT, SM,
     $                   TB, TN
*     ..
*     .. INTRINSIC FUNCTIONS ..
      INTRINSIC          ABS, SQRT
*     ..
*     .. EXECUTABLE STATEMENTS ..
*
*     COMPUTE THE EIGENVALUES
*
      SM = A + C
      DF = A - C
      ADF = ABS( DF )
      TB = B + B
      AB = ABS( TB )
      IF( ABS( A ).GT.ABS( C ) ) THEN
         ACMX = A
         ACMN = C
      ELSE
         ACMX = C
         ACMN = A
      END IF
      IF( ADF.GT.AB ) THEN
         RT = ADF*SQRT( ONE+( AB / ADF )**2 )
      ELSE IF( ADF.LT.AB ) THEN
         RT = AB*SQRT( ONE+( ADF / AB )**2 )
      ELSE
*
*        INCLUDES CASE AB=ADF=0
*
         RT = AB*SQRT( TWO )
      END IF
      IF( SM.LT.ZERO ) THEN
         RT1 = HALF*( SM-RT )
         SGN1 = -1
*
*        ORDER OF EXECUTION IMPORTANT.
*        TO GET FULLY ACCURATE SMALLER EIGENVALUE,
*        NEXT LINE NEEDS TO BE EXECUTED IN HIGHER PRECISION.
*
         RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
      ELSE IF( SM.GT.ZERO ) THEN
         RT1 = HALF*( SM+RT )
         SGN1 = 1
*
*        ORDER OF EXECUTION IMPORTANT.
*        TO GET FULLY ACCURATE SMALLER EIGENVALUE,
*        NEXT LINE NEEDS TO BE EXECUTED IN HIGHER PRECISION.
*
         RT2 = ( ACMX / RT1 )*ACMN - ( B / RT1 )*B
      ELSE
*
*        INCLUDES CASE RT1 = RT2 = 0
*
         RT1 = HALF*RT
         RT2 = -HALF*RT
         SGN1 = 1
      END IF
*
*     COMPUTE THE EIGENVECTOR
*
      IF( DF.GE.ZERO ) THEN
         CS = DF + RT
         SGN2 = 1
      ELSE
         CS = DF - RT
         SGN2 = -1
      END IF
      ACS = ABS( CS )
      IF( ACS.GT.AB ) THEN
         CT = -TB / CS
         SN1 = ONE / SQRT( ONE+CT*CT )
         CS1 = CT*SN1
      ELSE
         IF( AB.EQ.ZERO ) THEN
            CS1 = ONE
            SN1 = ZERO
         ELSE
            TN = -CS / TB
            CS1 = ONE / SQRT( ONE+TN*TN )
            SN1 = TN*CS1
         END IF
      END IF
      IF( SGN1.EQ.SGN2 ) THEN
         TN = CS1
         CS1 = -SN1
         SN1 = TN
      END IF
      RETURN
*
*     END OF DLAEV2
*
      END

      INTEGER FUNCTION ILAENV ()
      ILAENV=64
      RETURN
      END

