!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
function wgauss (x, n)  
  !-----------------------------------------------------------------------
  !
  !     this function computes the approximate theta function for the
  !     given order n, at the point x.
  !
  ! --> (n>=0) : Methfessel-Paxton case. See PRB 40, 3616 (1989).
  !
  ! --> (n=-1 ): Cold smearing (Marzari-Vanderbilt). See PRL 82, 3296 (199
  !       1/2*erf(x-1/sqrt(2)) + 1/sqrt(2*pi)*exp(-(x-1/sqrt(2))**2) + 1/2
  !
  ! --> (n=-99): Fermi-Dirac case: 1.0/(1.0+exp(-x)).
  !
  use parameters
  implicit none  
  real(kind=DP) :: wgauss, x  
  ! output: the value of the function
  ! input: the argument of the function
  integer :: n  
  ! input: the order of the function
  !
  !    the local variables
  !

  real(kind=DP) :: a, hp, arg, maxarg, hd, pi, gauss_freq, erf, xp  
  ! the coefficient a_n
  ! the hermitean function
  ! the argument of the exponential
  ! maximum value for the argument of the exponen
  ! the hermitean function
  ! pi
  ! the freq function
  ! the erf function
  ! auxiliary variable (cold smearing)
  integer :: i, ni  
  ! counter on the n indices
  ! counter on 2n
  external gauss_freq, erf  

  parameter (maxarg = 200.d0)  

  pi = 3.14159265358979d0  
  ! Fermi-Dirac smearing
  if (n.eq. - 99) then  
     if (x.lt. - maxarg) then  
        wgauss = 0.d0  
     elseif (x.gt.maxarg) then  
        wgauss = 1.d0  
     else  
        wgauss = 1.0d0 / (1.0 + exp ( - x) )  
     endif
     return  

  endif
  ! Cold smearing
  if (n.eq. - 1) then  
     xp = x - 1.0d0 / sqrt (2.0d0)  
     arg = min (maxarg, xp**2)  
     wgauss = 0.5d0 * erf (xp) + 1.0d0 / sqrt (2.0d0 * pi) * exp ( - &
          arg) + 0.5d0
     return  

  endif
  ! Methfessel-Paxton
  wgauss = gauss_freq (x * sqrt (2.0d0) )  
  if (n.eq.0) return  
  hd = 0.d0  
  arg = min (maxarg, x**2)  
  hp = exp ( - arg)  
  ni = 0  
  a = 1.d0 / sqrt (pi)  
  do i = 1, n  
     hd = 2.0d0 * x * hp - 2.0d0 * float (ni) * hd  
     ni = ni + 1  
     a = - a / (float (i) * 4.0d0)  
     wgauss = wgauss - a * hd  
     hp = 2.0d0 * x * hd-2.0d0 * float (ni) * hp  
     ni = ni + 1  
  enddo
  return  
end function wgauss
