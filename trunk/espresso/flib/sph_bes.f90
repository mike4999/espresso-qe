!
! Copyright (C) 2001-2004 ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------
subroutine sph_bes (msh, r, q, l, jl)
  !--------------------------------------------------------------------
  !
  ! ... input:
  ! ...   msh     = number of grid points points
  ! ...   r(1:msh)= radial grid
  ! ...   q       = q
  ! ...   l       = angular momentum (-1 <= l <= 6)
  ! ... output:
  ! ...   jl(1:msh) = j_l(q*r(i))  (j_l = spherical bessel function)
  !
  use kinds, only: DP
  USE constants, ONLY : eps14
  !
  implicit none
  !
  integer :: msh, l
  real(DP) :: r (msh), q, jl (msh)
  !
  ! xseries = convergence radius of the series for small x of j_l(x)
  real(DP) :: x, xseries = 0.01_dp
  integer :: ir, ir0
  integer, external:: semifact
  !
#if defined (__MASS)
  real(DP) :: qr(msh), sin_qr(msh), cos_qr(msh)
#endif
  !
  if (abs (q) < eps14) then
     if (l == -1) then
        call errore ('sph_bes', 'j_{-1}(0) ?!?', 1)
     elseif (l == 0) then
        jl(:) = 1.d0
     else
        jl(:) = 0.d0
     endif
     return
  end if 

  if (l == - 1) then
     if (abs (q * r (1) ) < eps14) then
        call errore ('sph_bes', 'j_{-1}(0) ?!?', 2)
     end if

#if defined (__MASS)

        qr = q * r
        call vcos( cos_qr, qr, msh)
        jl(ir0:) = cos_qr(ir0:) / ( q * r(ir0:) )

#else

        jl (ir0:) = cos (q * r (ir0:) ) / (q * r (ir0:) )

#endif

      return
  end if

  ! series expansion for small values of the argument

  ir0 = 1
  do ir = 1, msh
     if ( abs (q * r (ir) ) > xseries ) then
        ir0 = ir
        exit
     end if
  end do

  do ir = 1, ir0 - 1
     x = q * r (ir)
     jl (ir) = x**l/semifact(2*l+1) * &
                ( 1.0_dp - x**2/1.0_dp/2.0_dp/(2.0_dp*l+3) * &
                ( 1.0_dp - x**2/2.0_dp/2.0_dp/(2.0_dp*l+5) * &
                ( 1.0_dp - x**2/3.0_dp/2.0_dp/(2.0_dp*l+7) * &
                ( 1.0_dp - x**2/4.0_dp/2.0_dp/(2.0_dp*l+9) ) ) ) )
  end do
        
  if (l == 0) then

#if defined (__MASS)

     qr = q * r
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = sin_qr(ir0:) / (q * r (ir0:) )

#else

     jl (ir0:) = sin (q * r (ir0:) ) / (q * r (ir0:) )

#endif

  elseif (l == 1) then

#if defined (__MASS)

     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = ( sin_qr(ir0:) / (q * r (ir0:) ) - &
                   cos_qr(ir0:) ) / (q * r (ir0:) )

#else

     jl (ir0:) = (sin (q * r (ir0:) ) / (q * r (ir0:) ) - &
                  cos (q * r (ir0:) ) ) / (q * r (ir0:) )

#endif

  elseif (l == 2) then

#if defined (__MASS)

     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = ( (3.d0 / (q*r(ir0:)) - (q*r(ir0:)) ) * sin_qr(ir0: ) - &
                    3.d0 * cos_qr(ir0:) ) / (q*r(ir0:))**2

#else

     jl (ir0:) = ( (3.d0 / (q*r(ir0:)) - (q*r(ir0:)) ) * sin (q*r(ir0:)) - &
                    3.d0 * cos (q*r(ir0:)) ) / (q*r(ir0:))**2

#endif

  elseif (l == 3) then

#if defined (__MASS)

     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = (sin_qr (ir0:) * &
                  (15.d0 / (q*r(ir0:)) - 6.d0 * (q*r(ir0:)) ) + &
                  cos_qr (ir0:) * ( (q*r(ir0:))**2 - 15.d0) ) / &
                  (q*r(ir0:))**3

#else

     jl (ir0:) = (sin (q*r(ir0:)) * &
                  (15.d0 / (q*r(ir0:)) - 6.d0 * (q*r(ir0:)) ) + &
                  cos (q*r(ir0:)) * ( (q*r(ir0:))**2 - 15.d0) ) / &
                  (q*r(ir0:)) **3

#endif

  elseif (l == 4) then

#if defined (__MASS)

     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = (sin_qr (ir0:) * &
                  (105.d0 - 45.d0 * (q*r(ir0:))**2 + (q*r(ir0:))**4) + &
                  cos_qr (ir0:) * &
                  (10.d0 * (q*r(ir0:))**3 - 105.d0 * (q*r(ir0:))) ) / &
                    (q*r(ir0:))**5

#else

     jl (ir0:) = (sin (q*r(ir0:)) * &
                  (105.d0 - 45.d0 * (q*r(ir0:))**2 + (q*r(ir0:))**4) + &
                  cos (q*r(ir0:)) * &
                  (10.d0 * (q*r(ir0:))**3 - 105.d0 * (q*r(ir0:))) ) / &
                     (q*r(ir0:))**5
#endif

  elseif (l == 5) then

#if defined (__MASS)
     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = (-cos_qr(ir0:) - &
                  (945.d0*cos_qr(ir0:)) / (q*r(ir0:)) ** 4 + &
                  (105.d0*cos_qr(ir0:)) / (q*r(ir0:)) ** 2 + &
                  (945.d0*sin_qr(ir0:)) / (q*r(ir0:)) ** 5 - &
                  (420.d0*sin_qr(ir0:)) / (q*r(ir0:)) ** 3 + &
                  ( 15.d0*sin_qr(ir0:)) / (q*r(ir0:)) ) / (q*r(ir0:))
#else
     jl (ir0:) = (-cos(q*r(ir0:)) - &
                  (945.d0*cos(q*r(ir0:))) / (q*r(ir0:)) ** 4 + &
                  (105.d0*cos(q*r(ir0:))) / (q*r(ir0:)) ** 2 + &
                  (945.d0*sin(q*r(ir0:))) / (q*r(ir0:)) ** 5 - &
                  (420.d0*sin(q*r(ir0:))) / (q*r(ir0:)) ** 3 + &
                  ( 15.d0*sin(q*r(ir0:))) / (q*r(ir0:)) ) / (q*r(ir0:))
#endif

  elseif (l == 6) then

#if defined (__MASS)

     qr = q * r
     call vcos( cos_qr, qr, msh)
     call vsin( sin_qr, qr, msh)
     jl (ir0:) = ((-10395.d0*cos_qr(ir0:)) / (q*r(ir0:))**5 + &
                  (  1260.d0*cos_qr(ir0:)) / (q*r(ir0:))**3 - &
                  (    21.d0*cos_qr(ir0:)) / (q*r(ir0:))    - &
                             sin_qr(ir0:)                   + &
                  ( 10395.d0*sin_qr(ir0:)) / (q*r(ir0:))**6 - &
                  (  4725.d0*sin_qr(ir0:)) / (q*r(ir0:))**4 + &
                  (   210.d0*sin_qr(ir0:)) / (q*r(ir0:))**2 ) / (q*r(ir0:))
#else

     jl (ir0:) = ((-10395.d0*cos(q*r(ir0:))) / (q*r(ir0:))**5 + &
                  (  1260.d0*cos(q*r(ir0:))) / (q*r(ir0:))**3 - &
                  (    21.d0*cos(q*r(ir0:))) / (q*r(ir0:))    - &
                             sin(q*r(ir0:))                   + &
                  ( 10395.d0*sin(q*r(ir0:))) / (q*r(ir0:))**6 - &
                  (  4725.d0*sin(q*r(ir0:))) / (q*r(ir0:))**4 + &
                  (   210.d0*sin(q*r(ir0:))) / (q*r(ir0:))**2 ) / (q*r(ir0:))
#endif

  else

     call errore ('sph_bes', 'not implemented', abs(l))

  endif

  !
  return
end subroutine sph_bes
