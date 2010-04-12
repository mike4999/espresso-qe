!
! Copyright (C) 2001-2006 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
!OBM
! 160608 reduce clocks removed
SUBROUTINE print_clock_lr()
   !---------------------------------------------------------------------------
   !
   ! ... this routine prints out the clocks at the end of the run
   ! ... it tries to construct the calling tree of the program.
   !
   ! Modified by Osman Baris Malcioglu (2009)

   USE io_global,        ONLY : stdout
   USE mp_global,        ONLY : mpime, root
   USE realus,           ONLY : real_space,real_space_debug
   USE lr_variables,     ONLY : charge_response
   !
   IMPLICIT NONE
   !
   !
   IF ( mpime /= root ) &
      OPEN( UNIT = stdout, FILE = '/dev/null', STATUS = 'UNKNOWN' )
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'lr_main' )
   !
   CALL print_clock( 'lr_solve_e' )
   !
   CALL print_clock( 'one_step' )
   !
   WRITE( stdout, * )
   !
   CALL print_clock('lr_apply')
   CALL print_clock('lr_apply_int')
   CALL print_clock('lr_apply_no')
   !
   WRITE( stdout, * )
   !
   CALL print_clock( 'lr_apply' )
   CALL print_clock( 'h_psi' )
   CALL print_clock( 'lr_calc_dens' )
   CALL print_clock( 'lr_addusdens' )
   CALL print_clock( 'lr_dv' )
   CALL print_clock( 'lr_ortho' )
   CALL print_clock( 'interaction' )
   CALL print_clock( 'lr_dot' )
   !
   WRITE( stdout, * )
   WRITE( stdout, '(5X,"US routines")' )
   !
   CALL print_clock( 's_psi' )
   CALL print_clock( 'lr_sm1_psi' )
   !
   !WRITE( stdout, * )
   !WRITE( stdout, '(5X,"OBM DEBUG")' )
   !CALL print_clock( 'lrcd-lp1' )
   !CALL print_clock( 'lrcd-us' )
   !CALL print_clock( 'lrcd_sp' )
   !CALL print_clock( 'lrcd_usdens' )
   !
   IF (real_space_debug>0) then
    WRITE( stdout, '(5X,"US routines, RS")' )
    CALL print_clock ( 'realus' )
    CALL print_clock ( 'betapointlist' )
    CALL print_clock ( 'calbec_rs' )
    CALL print_clock ( 's_psir' )
    CALL print_clock ( 'add_vuspsir' )
    CALL print_clock ( 'fft_orbital' )
    CALL print_clock ( 'bfft_orbital' )
    CALL print_clock ( 'v_loc_psir' )
   ENDIF
   !
   WRITE( stdout, * )
   WRITE( stdout, '(5X,"General routines")' )
   !
   CALL print_clock( 'calbec' )
   CALL print_clock( 'cft3' )
   CALL print_clock( 'cft3s' )
   CALL print_clock( 'interpolate' )
   CALL print_clock( 'davcio' )
   CALL print_clock( 'newq' )
   CALL print_clock ( 'addusdens' )
   !
   !
   WRITE( stdout, * )
   !
#if defined (__PARA)
   WRITE( stdout, '(5X,"Parallel routines")' )
   !
   !CALL print_clock( 'reduce' )
   CALL print_clock( 'fft_scatter' )
   !CALL print_clock( 'poolreduce' )
   call print_clock ('mp_sum')
    WRITE( stdout, * )
#endif
   !
   CALL print_clock( 'post-processing' )
   RETURN
   !
END SUBROUTINE print_clock_lr
