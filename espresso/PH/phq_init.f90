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
SUBROUTINE phq_init()
  !----------------------------------------------------------------------------
  !
  !     This subroutine computes the quantities necessary to describe the
  !     local and nonlocal pseudopotential in the phononq program.
  !     In detail it computes:
  !     0) initialize the structure factors
  !     a0) compute rhocore for each atomic-type if needed for nlcc
  !     a) The local potential at G-G'. Needed for the part of the dynamic
  !        matrix independent of deltapsi.
  !     b) The local potential at q+G-G'. Needed for the second
  !        second part of the dynamical matrix.
  !     c) The D coefficients for the US pseudopotential or the E_l parame
  !        of the KB pseudo. In the US case it prepares also the integrals
  !        qrad and qradq which are needed for computing Q_nm(G) and
  !        Q_nm(q+G)
  !     d) The functions vkb(k+G) needed for the part of the dynamical mat
  !        independent of deltapsi.
  !     e) The becp functions for the k points
  !     e') The derivative of the becp term with respect to a displacement
  !     f) The functions vkb(k+q+G), needed for the linear sysetm and the
  !        second part of the dynamical matrix.
  !
  !
  USE constants,            ONLY : eps8
  USE io_global,            ONLY : stdout
  USE io_files,             ONLY : iunigk
  USE pwcom
  USE wavefunctions_module, ONLY : evc
  USE kinds,           ONLY : DP
  USE phcom
  !
  IMPLICIT NONE
  !
  ! ... local variables
  !
  INTEGER :: nt, ik, ikq, ipol, ibnd, ikk, na, ig
    ! counter on atom types
    ! counter on k points
    ! counter on k+q points
    ! counter on polarizations
    ! counter on bands
    ! index for wavefunctions at k
    ! counter on atoms
    ! counter on G vectors
  REAL(KIND=DP) :: arg
    ! the argument of the phase
  COMPLEX(KIND=DP), ALLOCATABLE :: aux1(:,:)
    ! used to compute alphap
  !
  !
  CALL start_clock( 'phq_init' )
  !
  ALLOCATE( aux1( npwx, nbnd ) )    
  !
  ! ... initialize structure factor array
  !
  CALL struc_fact( nat, tau, ntyp, ityp, ngm, g, bg, nr1, nr2, nr3, &
                   strf, eigts1, eigts2, eigts3 )
  !                 
  DO na = 1, nat
     !
     arg = ( xq(1) * tau(1,na) + &
             xq(2) * tau(2,na) + &
             xq(3) * tau(3,na) ) * tpi
     !        
     eigqts(na) = CMPLX( COS( arg ), - SIN( arg ) )
     !
  END DO
  !
  ! ... a0) compute rhocore for each atomic-type if needed for nlcc
  !
  IF ( nlcc_any ) CALL set_drhoc( xq )
  !
  ! ... a) the fourier components of the local potential for each |G|
  !
  CALL init_vloc()
  !
  ! ... b) the fourier components of the local potential at q+G
  !
  vlocq(:,:) = 0.D0
  !
  DO nt = 1, ntyp
     !
     CALL setlocq( xq, lloc(nt), lmax(nt), numeric(nt), mesh(nt),    &
                   msh(nt), rab(1,nt), r(1,nt), vnl(1,lloc(nt),nt),  &
                   cc(1,nt), alpc(1,nt), nlc(nt), nnl(nt), zp(nt),   &
                   aps(1,0,nt), alps(1,0,nt), tpiba2, ngm, g, omega, &
                   vlocq(1,nt) )
     !
  END DO
  !
  ! ... c) the parameters defining the pseudopotential
  !
  ! ... for the analytic potentials we need to convert in a radial mesh
  !
  CALL convert_to_num( ntyp, numeric, ndmx, mesh, r, lmaxx, lmax, &
                       lloc, nnl, aps, alps, vnl )
  !
  ! ... then we compute the denominators of the KB types, or the
  ! ... parameters which define the non-local pseudopotential and
  ! ... which are independent of the k point for the US case
  !
  CALL init_us_1()
  !
  IF ( nksq > 1 ) REWIND( iunigk )
  !
  DO ik = 1, nksq
     !
     IF ( lgamma ) THEN
        ikk  = ik
        ikq  = ik
     ELSE
        ikk = 2 * ik - 1
        ikq = ikk + 1
     END IF
     !
     IF ( lsda ) current_spin = isk( ikk )
     !
     ! ... g2kin is used here as work space
     !
     CALL gk_sort( xk(1,ikk), ngm, g, ( ecutwfc / tpiba2 ), npw, igk, g2kin )
     !
     ! ... if there is only one k-point evc, evq, npw, igk stay in memory
     !
     IF ( nksq > 1 ) WRITE( iunigk ) npw, igk
     !
     IF ( lgamma ) THEN
        !
        npwq = npw
        !
     ELSE   
        !
        CALL gk_sort( xk(1,ikq), ngm, g, ( ecutwfc / tpiba2 ), &
                      npwq, igkq, g2kin )
        !
        IF ( nksq > 1 ) WRITE( iunigk ) npwq, igkq
        !
        IF ( ABS( xq(1) - ( xk(1,ikq) - xk(1,ikk) ) ) > eps8 .OR. &
             ABS( xq(2) - ( xk(2,ikq) - xk(2,ikk) ) ) > eps8 .OR. &
             ABS( xq(3) - ( xk(3,ikq) - xk(3,ikk) ) ) > eps8 ) THEN
           WRITE( stdout, * ) ikk, ikq, nksq
           WRITE( stdout, * ) ( xq(ipol),     ipol = 1, 3)
           WRITE( stdout, * ) ( xk(ipol,ikq), ipol = 1, 3)
           WRITE( stdout, * ) ( xk(ipol,ikk), ipol = 1, 3)
           CALL errore( 'phq_init', 'wrong order of k points', 1 )
        END IF
        !
     END IF
     !
     ! ... d) The functions vkb(k+G)
     !
     CALL init_us_2( npw, igk, xk(1,ikk), vkb )
     !
     ! ... read the wavefunctions at k
     !
     CALL davcio( evc, lrwfc, iuwfc, ikk, -1 )
     !
     ! ... e) we compute the becp terms which are used in the rest of
     ! ...    the code
     !
     CALL ccalbec( nkb, npwx, npw, nbnd, becp1(1,1,ik), vkb, evc )
     !
     ! ... e') we compute the derivative of the becp term with respect to an
     !         atomic displacement
     !
     DO ipol = 1, 3
        DO ibnd = 1, nbnd
           DO ig = 1, npw
              aux1(ig,ibnd) = evc(ig,ibnd) * tpiba * ( 0.D0, 1.D0 ) * & 
                              ( xk(ipol,ikk) + g(ipol,igk(ig)) )
           END DO
        END DO
        CALL ccalbec( nkb, npwx, npw, nbnd, alphap(1,1,ipol,ik), vkb, aux1 )
     END DO
     !
     ! ... if there is only one k-point the k+q wavefunctions are 
     ! ... read once here
     !
     IF ( nksq == 1 .AND. .NOT. lgamma ) &
        CALL davcio( evq, lrwfc, iuwfc, ikq, -1 )
     !
  END DO
  !
  DEALLOCATE( aux1 )
  !
  CALL newd()
  CALL dvanqq()
  CALL drho()
  !
  IF ( ( epsil .OR. zue ) .AND. okvan ) &
     CALL compute_qdipol()
  !
  CALL stop_clock( 'phq_init' )
  !
  RETURN
  !
END SUBROUTINE phq_init
