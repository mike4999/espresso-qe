!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
subroutine lr_setup_dgc
  !-----------------------------------------------------------------------
  ! Allocate and setup all variable needed in the gradient correction case
  !
  !  GGA+LSDA is allowed. AdC (September 1999).
  !  GGA+LSDA+NLCC is allowed. AdC (November 1999).
  !
  ! Modified by Osman Baris Malcioglu (2009)
#include "f_defs.h"

  use pwcom,          only : nspin, ngm, g, nl, e2
  use grid_dimensions,only : nrxx
  USE kinds,          only : DP
  use lr_variables,   only : lr_verbosity
  use funct,          only : dft_is_gradient, gcxc, gcx_spin, gcc_spin, &
                             dgcxc, dgcxc_spin
  !obm -strange- 
  use nlcc_ph,        only : nlcc_any
  use gc_ph,          only : grho,dvxc_rr, dvxc_sr, dvxc_ss, dvxc_s
  use scf,            only : rho,rho_core,rhog_core
  USE io_global,      ONLY : stdout
  implicit none
  integer :: k, is
  real(DP) :: grho2 (2), rh, zeta1, grh2, fac, sx, sc, &
       v1x, v2x, v1c, v2c, vrrx, vsrx, vssx, vrrc, vsrc, vssc, v1xup, &
       v1xdw, v2xup, v2xdw, v1cup, v1cdw, vrrxup, vrrxdw, vrsxup, vrsxdw, &
       vssxup, vssxdw, vrrcup, vrrcdw, vrscup, vrscdw, vrzcup, vrzcdw
  real (DP), parameter :: epsr = 1.0d-6, epsg = 1.0d-10
  If (lr_verbosity > 5) THEN
    WRITE(stdout,'("<lr_setup_dgc>")')
  endif
  if ( .not. dft_is_gradient() ) return
  allocate (dvxc_rr(  nrxx , nspin , nspin))    
  allocate (dvxc_sr(  nrxx , nspin , nspin))    
  allocate (dvxc_ss(  nrxx , nspin , nspin))    
  allocate (dvxc_s (  nrxx , nspin , nspin))    
  allocate (grho   (  3    , nrxx  , nspin))    

  dvxc_rr(:,:,:) = 0.d0
  dvxc_sr(:,:,:) = 0.d0
  dvxc_ss(:,:,:) = 0.d0
  dvxc_s (:,:,:) = 0.d0
  grho   (:,:,:) = 0.d0
  !
  !    add rho_core
  !
  fac = 1.d0 / DBLE (nspin)
  if (nlcc_any) then
     do is = 1, nspin
        rho%of_r (:,is)  = fac * rho_core(:)  + rho%of_r (:,is)
        rho%of_g (:,is) = fac * rhog_core(:) + rho%of_g (:,is)
     enddo
  endif
  do is = 1, nspin
     call gradrho (nrxx, rho%of_g (1, is), ngm, g, nl, grho (1, 1, is) )
  enddo
  do k = 1, nrxx
     grho2 (1) = grho (1, k, 1) **2 + grho (2, k, 1) **2 + grho (3, k, 1) **2
     if (nspin == 1) then
        if (abs (rho%of_r (k, 1) ) > epsr .and. grho2 (1) > epsg) then
           call gcxc (rho%of_r (k, nspin), grho2(1), sx, sc, v1x, v2x, v1c, v2c)
           call dgcxc (rho%of_r (k, nspin), grho2(1), vrrx, vsrx, vssx, vrrc, &
                vsrc, vssc)
           dvxc_rr (k, 1, 1) = e2 * (vrrx + vrrc)
           dvxc_sr (k, 1, 1) = e2 * (vsrx + vsrc)
           dvxc_ss (k, 1, 1) = e2 * (vssx + vssc)
           dvxc_s (k, 1, 1) = e2 * (v2x + v2c)
        endif
     else
        grho2 (2) = grho (1, k, 2) **2 + grho (2, k, 2) **2 + grho (3, &
             k, 2) **2
        rh = rho%of_r (k, 1) + rho%of_r (k, 2)

        grh2 = (grho (1, k, 1) + grho (1, k, 2) ) **2 + (grho (2, k, 1) &
             + grho (2, k, 2) ) **2 + (grho (3, k, 1) + grho (3, k, 2) ) ** 2

        call gcx_spin (rho%of_r (k, 1), rho%of_r (k, 2), grho2 (1), grho2 (2), &
             sx, v1xup, v1xdw, v2xup, v2xdw)

        call dgcxc_spin (rho%of_r (k, 1), rho%of_r (k, 2), grho (1, k, 1), &
             grho (1, k, 2), vrrxup, vrrxdw, vrsxup, vrsxdw, vssxup, vssxdw, &
             vrrcup, vrrcdw, vrscup, vrscdw, vssc, vrzcup, vrzcdw)
        if (rh > epsr) then
           zeta1 = (rho%of_r(k, 1) - rho%of_r(k, 2) ) / rh
           call gcc_spin (rh, zeta1, grh2, sc, v1cup, v1cdw, v2c)
           dvxc_rr (k, 1, 1) = e2 * (vrrxup + vrrcup + vrzcup * &
                (1.d0 - zeta1) / rh)
           dvxc_rr (k, 1, 2) = e2 * (vrrcup - vrzcup * (1.d0 + zeta1) / rh)
           dvxc_rr (k, 2, 1) = e2 * (vrrcdw + vrzcdw * (1.d0 - zeta1) / rh)
           dvxc_rr (k, 2, 2) = e2 * (vrrxdw + vrrcdw - vrzcdw * &
                (1.d0 + zeta1) / rh)
           dvxc_s (k, 1, 1) = e2 * (v2xup + v2c)
           dvxc_s (k, 1, 2) = e2 * v2c
           dvxc_s (k, 2, 1) = e2 * v2c
           dvxc_s (k, 2, 2) = e2 * (v2xdw + v2c)
        else
           dvxc_rr (k, 1, 1) = 0.d0
           dvxc_rr (k, 1, 2) = 0.d0
           dvxc_rr (k, 2, 1) = 0.d0
           dvxc_rr (k, 2, 2) = 0.d0
           dvxc_s (k, 1, 1) = 0.d0
           dvxc_s (k, 1, 2) = 0.d0
           dvxc_s (k, 2, 1) = 0.d0
           dvxc_s (k, 2, 2) = 0.d0
        endif
        dvxc_sr (k, 1, 1) = e2 * (vrsxup + vrscup)
        dvxc_sr (k, 1, 2) = e2 * vrscup
        dvxc_sr (k, 2, 1) = e2 * vrscdw
        dvxc_sr (k, 2, 2) = e2 * (vrsxdw + vrscdw)
        dvxc_ss (k, 1, 1) = e2 * (vssxup + vssc)
        dvxc_ss (k, 1, 2) = e2 * vssc
        dvxc_ss (k, 2, 1) = e2 * vssc
        dvxc_ss (k, 2, 2) = e2 * (vssxdw + vssc)
     endif
  enddo
  if (nlcc_any) then
     do is = 1, nspin
        rho%of_r(:,is)  = rho%of_r(:,is)  - fac * rho_core(:)
        rho%of_g(:,is) = rho%of_g(:,is) - fac * rhog_core(:)
     enddo
  endif

  return
end subroutine lr_setup_dgc
