!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
SUBROUTINE print_clock_pw()
   !---------------------------------------------------------------------------
   !
   ! ... this routine prints out the clocks at the end of the run
   ! ... it tries to construct the calling tree of the program.
   !
   USE io_global,     ONLY : stdout
   USE control_flags, ONLY : isolve, imix
   USE force_mod,     ONLY : lforce, lstres
   USE mp_global,     ONLY : mpime, root
   !
   IMPLICIT NONE
   !
   !
   IF ( mpime /= root ) &
      OPEN( UNIT = stdout, FILE = '/dev/null', STATUS = 'UNKNOWN' )
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'PWSCF' )
   CALL print_clock( 'init_run' )
   CALL print_clock( 'electrons' )
   !
   IF ( lforce ) CALL print_clock( 'forces' )
   IF ( lstres ) CALL print_clock( 'stress' )
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'electrons' )
   CALL print_clock( 'c_bands' )
   CALL print_clock( 'sum_band' )
   CALL print_clock( 'v_of_rho' )
   CALL print_clock( 'newd' )
   !
#ifdef DEBUG_NEWD
   WRITE( stdout,*) "nhm*(nhm+1)/2       = ", nhm*(nhm+1)/2, nhm
   WRITE( stdout,*) "nbrx*(nbrx+1)/2*lmaxq = ", nbrx*(nbrx+1)/2*lmaxq, nbrx,lmaxq
   !
   CALL print_clock( 'newd:fftvg' )
   CALL print_clock( 'newd:qvan2' )
   CALL print_clock( 'newd:int1' )
   CALL print_clock( 'newd:int2' )
#endif
   !
   IF ( imix >= 0 ) THEN
      CALL print_clock( 'mix_rho' )
   ELSE
      CALL print_clock( 'mix_pot' )
   END IF
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'c_bands' )
   CALL print_clock( 'init_us_2' )
   CALL print_clock( 'cegterg' )
   CALL print_clock( 'ccgdiagg' )
   CALL print_clock( 'diis' )
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'sum_band' )
   CALL print_clock( 'sumbec' )
   !
   CALL print_clock( 'addusdens' )
   !
#ifdef DEBUG_ADDUSDENS
   CALL print_clock( 'addus:qvan2' )
   CALL print_clock( 'addus:strf' )
   CALL print_clock( 'addus:aux2' )
   CALL print_clock( 'addus:aux' )
#endif
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'wfcrot' )
   CALL print_clock( 'wfcrot1' )
   CALL print_clock( 'cegterg' )
   CALL print_clock( 'ccdiagg' )
   CALL print_clock( 'cdiisg' )
   !
   IF ( isolve == 0 ) THEN
      !
      CALL print_clock( 'h_psi' )
      CALL print_clock( 'g_psi' )
      CALL print_clock( 'overlap' )
      CALL print_clock( 'cdiaghg' )
      CALL print_clock( 'update' )
      CALL print_clock( 'last' )
      !
      WRITE( stdout, * )
      !
      CALL print_clock( 'h_psi' )
      CALL print_clock( 'init' )
      CALL print_clock( 'firstfft' )
      CALL print_clock( 'secondfft' )
      CALL print_clock( 'add_vuspsi' )
      CALL print_clock( 's_psi' )
      !
   ELSE IF ( isolve == 1 ) THEN
      !
      CALL print_clock( 'h_1psi' )
      CALL print_clock( 's_1psi' )
      CALL print_clock( 'cdiaghg' )
      !
      WRITE( stdout, * )
      !
      CALL print_clock( 'h_1psi' )
      CALL print_clock( 'init' )
      CALL print_clock( 'firstfft' )
      CALL print_clock( 'secondfft' )
      CALL print_clock( 'add_vuspsi' )
      !
   ELSE
      !
      CALL print_clock( 'h_psi' )
      CALL print_clock( 's_psi' )
      CALL print_clock( 'g_psi' )
      CALL print_clock( 'cdiaghg' )
      CALL print_clock( 'cgramg1' )
      !
      WRITE( stdout, * )
      !
      CALL print_clock( 'h_psi' )
      CALL print_clock( 'init' )
      CALL print_clock( 'firstfft' )
      CALL print_clock( 'secondfft' )
      CALL print_clock( 'add_vuspsi' )
      !   
   END IF
   !
   WRITE( stdout, * )
   WRITE( stdout, '(5X,"General routines")' )
   !
   CALL print_clock( 'ccalbec' )
   CALL print_clock( 'cft3' )
   CALL print_clock( 'cft3s' )
   CALL print_clock( 'interpolate' )
   CALL print_clock( 'davcio' )
   !    
   WRITE( stdout, * )
   !
#if defined (__PARA)
   WRITE( stdout, '(5X,"Parallel routines")' )
   !
   CALL print_clock( 'reduce' )
   CALL print_clock( 'fft_scatter' )
   CALL print_clock( 'poolreduce' )
#endif
   !
   RETURN
   !
END SUBROUTINE print_clock_pw
