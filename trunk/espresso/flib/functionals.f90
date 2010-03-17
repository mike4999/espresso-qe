!
! Copyright (C) 2001-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
subroutine slater (rs, ex, vx)
  !-----------------------------------------------------------------------
  !        Slater exchange with alpha=2/3
  !
  USE kinds
  implicit none
  real(DP) :: rs, ex, vx
  real(DP), parameter  :: f= -0.687247939924714d0, alpha = 2.0d0/3.0d0
  ! f = -9/8*(3/2pi)^(2/3)
  !
  ex = f * alpha / rs
  vx = 4.d0 / 3.d0 * f * alpha / rs
  !
  return
end subroutine slater
!
!-----------------------------------------------------------------------
subroutine slater1(rs, ex, vx)
  !-----------------------------------------------------------------------
  !        Slater exchange with alpha=1, corresponding to -1.374/r_s Ry
  !        used to recover old results
  !
  USE kinds
  implicit none
  real(DP) :: rs, ex, vx
  real(DP), parameter  :: f= -0.687247939924714d0, alpha = 1.0d0
  !
  ex = f * alpha / rs
  vx = 4.d0 / 3.d0 * f * alpha / rs
  !
  return
end subroutine slater1
!
!-----------------------------------------------------------------------
subroutine slater_rxc (rs, ex, vx)
  !-----------------------------------------------------------------------
  !        Slater exchange with alpha=2/3 and Relativistic exchange
  !
  USE kinds
  USE constants, ONLY : pi, c_au
  IMPLICIT none
  real (DP):: rs, ex, vx
  !
  real(DP), PARAMETER :: ZERO=0.D0, ONE=1.D0, PFIVE=.5D0, &
       OPF=1.5D0 !, C014=0.014D0
  real (DP):: trd, ftrd, tftm, a0, alp, z, fz, fzp, vxp, xp, &
       beta, sb, alb, c014
  !
  TRD = ONE/3.d0
  FTRD = 4.d0*TRD
  TFTM = 2**FTRD-2.d0
  A0 = (4.d0/(9.d0*PI))**TRD
  C014= 1.0_DP/a0/c_au
  
  !      X-alpha parameter:
  ALP = 2.d0 * TRD
  
  Z = ZERO
  FZ = ZERO
  FZP = ZERO
  
  VXP = -3.d0*ALP/(2.d0*PI*A0*RS)
  XP = 3.d0*VXP/4.d0
  BETA = C014/RS
  SB = SQRT(1.d0+BETA*BETA)
  ALB = LOG(BETA+SB)
  VXP = VXP * (-PFIVE + OPF * ALB / (BETA*SB))
  XP = XP * (ONE-OPF*((BETA*SB-ALB)/BETA**2)**2)
  !  VXF = 2**TRD*VXP
  !  EXF = 2**TRD*XP
  VX = VXP
  EX = XP
END SUBROUTINE slater_rxc

!
!-----------------------------------------------------------------------
  subroutine slaterKZK (rs, ex, vx, vol)
  !-----------------------------------------------------------------------
  !        Slater exchange with alpha=2/3, Kwee, Zhang and Krakauer KE
  !        correction
  !
  USE kinds
  implicit none
  real(DP) :: rs, ex, vx, dL, vol, ga, pi, a0
  real(DP), parameter  ::  a1 = -2.2037d0, &
              a2 = 0.4710d0, a3 = -0.015d0, ry2h = 0.5d0
  real(DP), parameter  :: f= -0.687247939924714d0, alpha = 2.0d0/3.0d0
  ! f = -9/8*(3/2pi)^(2/3)
  !
  pi = 4.d0 * atan(1.d0)
  a0 = f * alpha * 2.d0

  dL = vol**(1.d0/3.d0)
  ga = 0.5d0 * dL *(3.d0 /pi)**(1.d0/3.d0)
  !
  if ( rs .le. ga) then
   ex = a0 / rs + a1 * rs / dL**2.d0 + a2 * rs**2.d0 / dL**3.d0
   vx = (4.d0 * a0 / rs + 2.d0 * a1 * rs / dL**2.d0 + &
        a2 * rs**2.d0 / dL**3.d0 ) / 3.d0
  else
    ex = a0 / ga + a1 * ga / dL**2.d0 + a2 * ga**2.d0 / dL**3.d0 ! solids
    vx = ex
!   ex = a3 * dL**5.d0 / rs**6.d0     ! molecules
!   vx = 3.d0 * ex  
  endif

  ex = ry2h * ex    ! Ry to Hartree
  vx = ry2h * vx
  !
  return
end subroutine slaterKZK
!
!-----------------------------------------------------------------------
subroutine pz (rs, iflag, ec, vc)
  !-----------------------------------------------------------------------
  !     LDA parameterization from Monte Carlo data
  !     iflag=1: J.P. Perdew and A. Zunger, PRB 23, 5048 (1981)
  !     iflag=2: G. Ortiz and P. Ballone, PRB 50, 1391 (1994)
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  integer :: iflag
  !
  real(DP) :: a (2), b (2), c (2), d (2), gc (2), b1 (2), b2 (2)
  real(DP) :: lnrs, rs12, ox, dox
  !
  data a / 0.0311d0, 0.031091d0 /, b / -0.048d0, -0.046644d0 /, &
       c / 0.0020d0, 0.00419d0 /, d / -0.0116d0, -0.00983d0 /
  data gc / -0.1423d0, -0.103756d0 /, b1 / 1.0529d0, 0.56371d0 /, &
       b2 / 0.3334d0, 0.27358d0 /
  !
  if (rs.lt.1.0d0) then
     ! high density formula
     lnrs = log (rs)
     ec = a (iflag) * lnrs + b (iflag) + c (iflag) * rs * lnrs + d ( &
          iflag) * rs
     vc = a (iflag) * lnrs + (b (iflag) - a (iflag) / 3.d0) + 2.d0 / &
          3.d0 * c (iflag) * rs * lnrs + (2.d0 * d (iflag) - c (iflag) ) &
          / 3.d0 * rs
  else
     ! interpolation formula
     rs12 = sqrt (rs)
     ox = 1.d0 + b1 (iflag) * rs12 + b2 (iflag) * rs
     dox = 1.d0 + 7.d0 / 6.d0 * b1 (iflag) * rs12 + 4.d0 / 3.d0 * &
          b2 (iflag) * rs
     ec = gc (iflag) / ox
     vc = ec * dox / ox
  endif
  !
  return
end subroutine pz
!
!-----------------------------------------------------------------------
subroutine pzKZK (rs, ec, vc, vol)
  !-----------------------------------------------------------------------
  !     LDA parameterization from Monte Carlo data
  !     iflag=1: J.P. Perdew and A. Zunger, PRB 23, 5048 (1981)
  !     iflag=2: G. Ortiz and P. Ballone, PRB 50, 1391 (1994)
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc, ec0 (2), vc0(2), ec0p 
  integer :: iflag, kr
  !
  real(DP) :: a (2), b (2), c (2), d (2), gc (2), b1 (2), b2 (2)
  real(DP) :: lnrs, rs12, ox, dox, lnrsk, rsk
  real(DP) :: a1, grs, g1, g2, g3, g4, dL, vol, gh, gl, grsp
  real(DP) :: f3, f2, f1, f0, pi
  real(DP) :: D1, D2, D3, P1, P2, ry2h
  !
  data a / 0.0311d0, 0.031091d0 /, b / -0.048d0, -0.046644d0 /, &
       c / 0.0020d0, 0.00419d0 /, d / -0.0116d0, -0.00983d0 /
  data gc / -0.1423d0, -0.103756d0 /, b1 / 1.0529d0, 0.56371d0 /, &
       b2 / 0.3334d0, 0.27358d0 /
  data a1 / -2.2037 /, g1 / 0.1182 /, g2 / 1.1656 /, g3 / -5.2884 /, &
       g4 / -1.1233 /
  data ry2h / 0.5d0 /
  !
  iflag = 1
  pi = 4.d0 * atan(1.d0)
  dL = vol**(1.d0/3.d0)
  gh = 0.5d0 * dL / (2.d0 * pi)**(1.d0/3.d0)
  gl = dL * (3.d0 / 2.d0 / pi)**(1.d0/3.d0)

  rsk = gh
  do kr = 1, 2
  lnrsk = log (rsk)
  if (rsk.lt.1.0d0) then
     ! high density formula
    ec0(kr) = a(iflag) *lnrsk + b(iflag) + c(iflag) * rsk * lnrsk + d( &
          iflag) * rsk
    vc0(kr) = a(iflag) * lnrsk + (b(iflag) - a(iflag) / 3.d0) + 2.d0 / &
      3.d0 * c (iflag) * rsk * lnrsk + (2.d0 * d (iflag) - c (iflag) ) &
          / 3.d0 * rsk
  else
     ! interpolation formula
     rs12 = sqrt (rsk)
     ox = 1.d0 + b1 (iflag) * rs12 + b2 (iflag) * rsk
     dox = 1.d0 + 7.d0 / 6.d0 * b1 (iflag) * rs12 + 4.d0 / 3.d0 * &
          b2 (iflag) * rsk
     ec0(kr) = gc (iflag) / ox
     vc0(kr) = ec0(kr) * dox / ox
  endif
  !
   grs  = g1 * rsk * lnrsk + g2 * rsk + g3 * rsk**1.5d0 + g4 * rsk**2.d0
   grsp = g1 * lnrsk + g1 + g2 + 1.5d0 * g3 * rsk**0.5d0 + & 
        2.d0 * g4 * rsk
   ec0(kr)  = ec0(kr) + (-a1 * rsk / dL**2.d0 + grs / dL**3.d0) * ry2h
   vc0(kr)  = vc0(kr) + (-2.d0 * a1 * rsk / dL**2.d0 / 3.d0 + &
           grs / dL**3.d0 -  grsp * rsk / 3.d0 / dL**3.d0) * ry2h
  !
  rsk = rs
  enddo

  lnrs = log (rs)
  if (rs .le. gh) then
   ec = ec0(2)
   vc = vc0(2)
  else
     if ( rs .le. gl) then
        ec0p = 3.d0 * (ec0(1) - vc0(1)) / gh
        P1 = 3.d0 *  ec0(1) - gh * ec0p
        P2 = ec0p
        D1 = gl - gh
        D2 = gl**2.d0 - gh**2.d0
        D3 = gl**3.d0 - gh**3.d0
        f2 = 2.d0 * gl**2.d0 * P2 * D1 + D2 * P1
        f2 = f2 / (-(2.d0*gl*D1)**2.d0 + 4.d0*gl*D1*D2 - D2**2.d0 )
        f3 = - (P2 + 2.d0*D1*f2) / (3.d0 * D2)
        f1 = - (P1 + D2 * f2) / (2.d0 * D1)
        f0 = - gl * (gl * f2 + 2.d0 * f1) / 3.d0
        !
        ec = f3 * rs**3.d0 + f2 * rs**2.d0 + f1 * rs + f0
        vc = f2 * rs**2.d0 / 3.d0 + f1 * 2.d0 * rs / 3.d0 + f0
     else
        ec = 0.d0
        vc = 0.d0
     endif
    endif
  !
  return
end subroutine pzKZK
!
!-----------------------------------------------------------------------
subroutine vwn (rs, ec, vc)
  !-----------------------------------------------------------------------
  !     S.H. Vosko, L. Wilk, and M. Nusair, Can. J. Phys. 58, 1200 (1980)
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  real(DP) :: a, b, c, x0
  parameter (a = 0.0310907d0, b = 3.72744d0, c = 12.9352d0, x0 = -0.10498d0)
  real(DP) :: q, f1, f2, f3, rs12, fx, qx, tx, tt
  !
  q = sqrt (4.d0 * c - b * b)
  f1 = 2.d0 * b / q
  f2 = b * x0 / (x0 * x0 + b * x0 + c)
  f3 = 2.d0 * (2.d0 * x0 + b) / q
  rs12 = sqrt (rs)
  fx = rs + b * rs12 + c
  qx = atan (q / (2.d0 * rs12 + b) )
  ec = a * (log (rs / fx) + f1 * qx - f2 * (log ( (rs12 - x0) **2 / &
       fx) + f3 * qx) )
  tx = 2.d0 * rs12 + b
  tt = tx * tx + q * q
  vc = ec - rs12 * a / 6.d0 * (2.d0 / rs12 - tx / fx - 4.d0 * b / &
       tt - f2 * (2.d0 / (rs12 - x0) - tx / fx - 4.d0 * (2.d0 * x0 + b) &
       / tt) )
  !
  return
end subroutine vwn
!-----------------------------------------------------------------------
subroutine lyp (rs, ec, vc)
  !-----------------------------------------------------------------------
  !     C. Lee, W. Yang, and R.G. Parr, PRB 37, 785 (1988)
  !     LDA part only
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  real(DP) :: a, b, c, d, pi43
  parameter (a = 0.04918d0, b = 0.132d0 * 2.87123400018819108d0)
  ! pi43 = (4pi/3)^(1/3)
  parameter (pi43 = 1.61199195401647d0, c = 0.2533d0 * pi43, d = &
       0.349d0 * pi43)
  real(DP) :: ecrs, ox
  !
  ecrs = b * exp ( - c * rs)
  ox = 1.d0 / (1.d0 + d * rs)
  ec = - a * ox * (1.d0 + ecrs)
  vc = ec - rs / 3.d0 * a * ox * (d * ox + ecrs * (d * ox + c) )
  !
  return
end subroutine lyp
!
!-----------------------------------------------------------------------
subroutine pw (rs, iflag, ec, vc)
  !-----------------------------------------------------------------------
  !     iflag=1: J.P. Perdew and Y. Wang, PRB 45, 13244 (1992)
  !     iflag=2: G. Ortiz and P. Ballone, PRB 50, 1391 (1994)
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  integer :: iflag
  !
  real(DP) :: a, b1, b2, c0, c1, c2, c3, d0, d1
  parameter (a = 0.031091d0, b1 = 7.5957d0, b2 = 3.5876d0, c0 = a, &
       c1 = 0.046644d0, c2 = 0.00664d0, c3 = 0.01043d0, d0 = 0.4335d0, &
       d1 = 1.4408d0)
  real(DP) :: lnrs, rs12, rs32, rs2, om, dom, olog
  real(DP) :: a1 (2), b3 (2), b4 (2)
  data a1 / 0.21370d0, 0.026481d0 /, b3 / 1.6382d0, -0.46647d0 /, &
       b4 / 0.49294d0, 0.13354d0 /
  !
  ! high- and low-density formulae implemented but not used in PW case
  ! (reason: inconsistencies in PBE/PW91 functionals)
  !
  if (rs.lt.1d0.and.iflag.eq.2) then
     ! high density formula
     lnrs = log (rs)
     ec = c0 * lnrs - c1 + c2 * rs * lnrs - c3 * rs
     vc = c0 * lnrs - (c1 + c0 / 3.d0) + 2.d0 / 3.d0 * c2 * rs * &
          lnrs - (2.d0 * c3 + c2) / 3.d0 * rs
  elseif (rs.gt.100.d0.and.iflag.eq.2) then
     ! low density formula
     ec = - d0 / rs + d1 / rs**1.5d0
     vc = - 4.d0 / 3.d0 * d0 / rs + 1.5d0 * d1 / rs**1.5d0
  else
     ! interpolation formula
     rs12 = sqrt (rs)
     rs32 = rs * rs12
     rs2 = rs**2
     om = 2.d0 * a * (b1 * rs12 + b2 * rs + b3 (iflag) * rs32 + b4 ( &
          iflag) * rs2)
     dom = 2.d0 * a * (0.5d0 * b1 * rs12 + b2 * rs + 1.5d0 * b3 ( &
          iflag) * rs32 + 2.d0 * b4 (iflag) * rs2)
     olog = log (1.d0 + 1.0d0 / om)
     ec = - 2.d0 * a * (1.d0 + a1 (iflag) * rs) * olog
     vc = - 2.d0 * a * (1.d0 + 2.d0 / 3.d0 * a1 (iflag) * rs) &
          * olog - 2.d0 / 3.d0 * a * (1.d0 + a1 (iflag) * rs) * dom / &
          (om * (om + 1.d0) )
  endif
  !
  return
end subroutine pw
!
!-----------------------------------------------------------------------
subroutine wigner (rs, ec, vc)
  !-----------------------------------------------------------------------
  !        Wigner correlation
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  real(DP) :: pi34, rho13
  parameter (pi34 = 0.6203504908994d0)
  ! pi34=(3/4pi)^(1/3), rho13=rho^(1/3)
  !
  rho13 = pi34 / rs
  vc = - rho13 * ( (0.943656d0 + 8.8963d0 * rho13) / (1.d0 + &
       12.57d0 * rho13) **2)
  ec = - 0.738d0 * rho13 * (0.959d0 / (1.d0 + 12.57d0 * rho13) )
  !
  return
end subroutine wigner
!
!-----------------------------------------------------------------------
subroutine hl (rs, ec, vc)
  !-----------------------------------------------------------------------
  !     L. Hedin and  B.I. Lundqvist,  J. Phys. C 4, 2064 (1971)
  !
  USE kinds
  implicit none
  real(DP) :: rs, ec, vc
  real(DP) :: a, x
  !
  a = log (1.0d0 + 21.d0 / rs)
  x = rs / 21.0d0
  ec = a + (x**3 * a - x * x) + x / 2.d0 - 1.0d0 / 3.0d0
  ec = - 0.0225d0 * ec
  vc = - 0.0225d0 * a
  !
  return
end subroutine hl
!
!-----------------------------------------------------------------------
subroutine gl (rs, ec, vc)
  !-----------------------------------------------------------------------
  !  O. Gunnarsson and B. I. Lundqvist, PRB 13, 4274 (1976)
  !
  USE kinds
  implicit none
  real(DP) :: rs, vc, ec
  real(DP) :: c, r, x
  parameter (c = 0.0333d0, r = 11.4d0)
  ! c=0.0203, r=15.9 for the paramagnetic case
  !
  x = rs / r
  vc = - c * log (1.d0 + 1.d0 / x)
  ec = - c * ( (1.d0 + x**3) * log (1.d0 + 1.d0 / x) - 1.0d0 / &
       3.0d0 + x * (0.5d0 - x) )
  !
  return
end subroutine gl
!
!-----------------------------------------------------------------------
subroutine becke88 (rho, grho, sx, v1x, v2x)
  !-----------------------------------------------------------------------
  ! Becke exchange: A.D. Becke, PRA 38, 3098 (1988)
  ! only gradient-corrected part, no Slater term included
  !
  USE kinds
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x
  real(DP) :: beta, third, two13
  parameter (beta = 0.0042d0)
  parameter (third = 1.d0 / 3.d0, two13 = 1.259921049894873d0)
  ! two13 = 2^(1/3)
  real(DP) :: rho13, rho43, xs, xs2, sa2b8, shm1, dd, dd2, ee
  !
  rho13 = rho**third
  rho43 = rho13**4
  xs = two13 * sqrt (grho) / rho43
  xs2 = xs * xs
  sa2b8 = sqrt (1.0d0 + xs2)
  shm1 = log (xs + sa2b8)
  dd = 1.0d0 + 6.0d0 * beta * xs * shm1
  dd2 = dd * dd
  ee = 6.0d0 * beta * xs2 / sa2b8 - 1.d0
  sx = two13 * grho / rho43 * ( - beta / dd)
  v1x = - (4.d0 / 3.d0) / two13 * xs2 * beta * rho13 * ee / dd2
  v2x = two13 * beta * (ee-dd) / (rho43 * dd2)
  !
  return
end subroutine becke88
!
!-----------------------------------------------------------------------
subroutine ggax (rho, grho, sx, v1x, v2x)
  !-----------------------------------------------------------------------
  ! Perdew-Wang GGA (PW91), exchange part:
  ! J.P. Perdew et al.,PRB 46, 6671 (1992)
  !
  USE kinds
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x
  real(DP) :: f1, f2, f3, f4, f5
  parameter (f1 = 0.19645d0, f2 = 7.7956d0, f3 = 0.2743d0, f4 = &
       0.1508d0, f5 = 0.004d0)
  real(DP) :: fp1, fp2
  parameter (fp1 = -0.019292021296426d0, fp2 = 0.161620459673995d0)
  ! fp1 = -3/(16 pi)*(3 pi^2)^(-1/3)
  ! fp2 = (1/2)(3 pi^2)**(-1/3)
  real(DP) :: rhom43, s, s2, s3, s4, exps, as, sa2b8, shm1, bs, das, &
       dbs, dls
  !
  rhom43 = rho** ( - 4.d0 / 3.d0)
  s = fp2 * sqrt (grho) * rhom43
  s2 = s * s
  s3 = s2 * s
  s4 = s2 * s2
  exps = f4 * exp ( - 100.d0 * s2)
  as = f3 - exps - f5 * s2
  sa2b8 = sqrt (1.0d0 + f2 * f2 * s2)
  shm1 = log (f2 * s + sa2b8)
  bs = 1.d0 + f1 * s * shm1 + f5 * s4
  das = (200.d0 * exps - 2.d0 * f5) * s
  dbs = f1 * (shm1 + f2 * s / sa2b8) + 4.d0 * f5 * s3
  dls = (das / as - dbs / bs)
  sx = fp1 * grho * rhom43 * as / bs
  v1x = - 4.d0 / 3.d0 * sx / rho * (1.d0 + s * dls)
  v2x = fp1 * rhom43 * as / bs * (2.d0 + s * dls)
  !
  return
end subroutine ggax
!
!-----------------------------------------------------------------------
subroutine perdew86 (rho, grho, sc, v1c, v2c)
  !-----------------------------------------------------------------------
  ! Perdew gradient correction on correlation: PRB 33, 8822 (1986)
  !
  USE kinds
  implicit none
  real(DP) :: rho, grho, sc, v1c, v2c
  real(DP) :: p1, p2, p3, p4, pc1, pc2, pci
  parameter (p1 = 0.023266d0, p2 = 7.389d-6, p3 = 8.723d0, p4 = &
       0.472d0)
  parameter (pc1 = 0.001667d0, pc2 = 0.002568d0, pci = pc1 + pc2)
  real(DP) :: third, pi34
  parameter (third = 1.d0 / 3.d0, pi34 = 0.6203504908994d0)
  ! pi34=(3/4pi)^(1/3)
  real(DP) :: rho13, rho43, rs, rs2, rs3, cna, cnb, cn, drs
  real(DP) :: dcna, dcnb, dcn, phi, ephi
  !
  rho13 = rho**third
  rho43 = rho13**4
  rs = pi34 / rho13
  rs2 = rs * rs
  rs3 = rs * rs2
  cna = pc2 + p1 * rs + p2 * rs2
  cnb = 1.d0 + p3 * rs + p4 * rs2 + 1.d4 * p2 * rs3
  cn = pc1 + cna / cnb
  drs = - third * pi34 / rho43
  dcna = (p1 + 2.d0 * p2 * rs) * drs
  dcnb = (p3 + 2.d0 * p4 * rs + 3.d4 * p2 * rs2) * drs
  dcn = dcna / cnb - cna / (cnb * cnb) * dcnb
  phi = 0.192d0 * pci / cn * sqrt (grho) * rho** ( - 7.d0 / 6.d0)
  ! SdG: in the original paper 1.745*0.11=0.19195 is used
  ephi = exp ( - phi)
  sc = grho / rho43 * cn * ephi
  v1c = sc * ( (1.d0 + phi) * dcn / cn - ( (4.d0 / 3.d0) - (7.d0 / &
       6.d0) * phi) / rho)
  v2c = cn * ephi / rho43 * (2.d0 - phi)
  !
  return
end subroutine perdew86
!
!-----------------------------------------------------------------------
subroutine glyp (rho, grho, sc, v1c, v2c)
  !-----------------------------------------------------------------------
  ! Lee Yang Parr: gradient correction part
  !
  USE kinds
  implicit none
  real(DP) :: rho, grho, sc, v1c, v2c
  real(DP) :: a, b, c, d
  parameter (a = 0.04918d0, b = 0.132d0, c = 0.2533d0, d = 0.349d0)
  real(DP) :: rhom13, rhom43, rhom53, om, xl, ff, dom, dxl
  !
  rhom13 = rho** ( - 1.d0 / 3.d0)
  om = exp ( - c * rhom13) / (1.d0 + d * rhom13)
  xl = 1.d0 + (7.d0 / 3.d0) * (c * rhom13 + d * rhom13 / (1.d0 + d * &
       rhom13) )
  ff = a * b * grho / 24.d0
  rhom53 = rhom13**5
  sc = ff * rhom53 * om * xl
  dom = - om * (c + d+c * d * rhom13) / (1.d0 + d * rhom13)
  dxl = (7.d0 / 3.d0) * (c + d+2.d0 * c * d * rhom13 + c * d * d * &
       rhom13**2) / (1.d0 + d * rhom13) **2
  rhom43 = rhom13**4
  v1c = - ff * rhom43 / 3.d0 * (5.d0 * rhom43 * om * xl + rhom53 * &
       dom * xl + rhom53 * om * dxl)
  v2c = 2.d0 * sc / grho
  !
  return
end subroutine glyp
!
!-----------------------------------------------------------------------
subroutine ggac (rho, grho, sc, v1c, v2c)
  !-----------------------------------------------------------------------
  ! Perdew-Wang GGA (PW91) correlation part
  !
  USE kinds
  implicit none
  real(DP) :: rho, grho, sc, v1c, v2c
  real(DP) :: al, pa, pb, pc, pd, cx, cxc0, cc0
  parameter (al = 0.09d0, pa = 0.023266d0, pb = 7.389d-6, pc = &
       8.723d0, pd = 0.472d0)
  parameter (cx = -0.001667d0, cxc0 = 0.002568d0, cc0 = - cx + cxc0)
  real(DP) :: third, pi34, nu, be, xkf, xks
  parameter (third = 1.d0 / 3.d0, pi34 = 0.6203504908994d0)
  parameter (nu = 15.755920349483144d0, be = nu * cc0)
  parameter (xkf = 1.919158292677513d0, xks = 1.128379167095513d0)
  ! pi34=(3/4pi)^(1/3),  nu=(16/pi)*(3 pi^2)^(1/3)
  ! xkf=(9 pi/4)^(1/3), xks= sqrt(4/pi)
  real(DP) :: kf, ks, rs, rs2, rs3, ec, vc, t, expe, af, bf, y, xy, &
       qy, s1
  real(DP) :: h0, dh0, ddh0, ee, cn, dcn, cna, dcna, cnb, dcnb, h1, &
       dh1, ddh1
  !
  rs = pi34 / rho**third
  rs2 = rs * rs
  rs3 = rs * rs2
  call pw (rs, 1, ec, vc)
  kf = xkf / rs
  ks = xks * sqrt (kf)
  t = sqrt (grho) / (2.d0 * ks * rho)
  expe = exp ( - 2.d0 * al * ec / (be * be) )
  af = 2.d0 * al / be * (1.d0 / (expe-1.d0) )
  bf = expe * (vc - ec)
  y = af * t * t
  xy = (1.d0 + y) / (1.d0 + y + y * y)
  qy = y * y * (2.d0 + y) / (1.d0 + y + y * y) **2
  s1 = 1.d0 + 2.d0 * al / be * t * t * xy
  h0 = be * be / (2.d0 * al) * log (s1)
  dh0 = be * t * t / s1 * ( - 7.d0 / 3.d0 * xy - qy * (af * bf / &
       be-7.d0 / 3.d0) )
  ddh0 = be / (2.d0 * ks * ks * rho) * (xy - qy) / s1
  ee = - 100.d0 * (ks / kf * t) **2
  cna = cxc0 + pa * rs + pb * rs2
  dcna = pa * rs + 2.d0 * pb * rs2
  cnb = 1.d0 + pc * rs + pd * rs2 + 1.d4 * pb * rs3
  dcnb = pc * rs + 2.d0 * pd * rs2 + 3.d4 * pb * rs3
  cn = cna / cnb - cx
  dcn = dcna / cnb - cna * dcnb / (cnb * cnb)
  h1 = nu * (cn - cc0 - 3.d0 / 7.d0 * cx) * t * t * exp (ee)
  dh1 = - third * (h1 * (7.d0 + 8.d0 * ee) + nu * t * t * exp (ee) &
       * dcn)
  ddh1 = 2.d0 * h1 * (1.d0 + ee) * rho / grho
  sc = rho * (h0 + h1)
  v1c = h0 + h1 + dh0 + dh1
  v2c = ddh0 + ddh1
  !
  return
end subroutine ggac
!
!---------------------------------------------------------------
subroutine pbex (rho, grho, iflag, sx, v1x, v2x)
  !---------------------------------------------------------------
  !
  ! PBE exchange (without Slater exchange):
  ! iflag=1  J.P.Perdew, K.Burke, M.Ernzerhof, PRL 77, 3865 (1996)
  ! iflag=2  "revised' PBE: Y. Zhang et al., PRL 80, 890 (1998)
  ! iflag=3  PBEsol: J.P.Perdew et al., PRL 100, 136406 (2008)
  !
  USE kinds
  USE constants, ONLY : pi
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x
  ! input: charge and squared gradient
  ! output: energy
  ! output: potential
  integer :: iflag
  ! local variables
  real(DP) :: kf, agrho, s1, s2, ds, dsg, exunif, fx
  ! (3*pi2*|rho|)^(1/3)
  ! |grho|
  ! |grho|/(2*kf*|rho|)
  ! s^2
  ! n*ds/dn
  ! n*ds/d(gn)
  ! exchange energy LDA part
  ! exchange energy gradient part
  real(DP) :: dxunif, dfx, f1, f2, f3, dfx1
  ! numerical coefficients (NB: c2=(3 pi^2)^(1/3) )
  real(DP) :: third, c1, c2, c5
  parameter (third = 1.d0 / 3.d0, c1 = 0.75d0 / pi , &
       c2 = 3.093667726280136d0, c5 = 4.d0 * third)
  ! parameters of the functional
  real(DP) :: k (3), mu(3)
  data k / 0.804d0, 1.2450D0, 0.804d0 /, &
       mu/ 0.21951d0, 0.21951d0, 0.12345679012345679012d0  /
  !
  agrho = sqrt (grho)
  kf = c2 * rho**third
  dsg = 0.5d0 / kf
  s1 = agrho * dsg / rho
  s2 = s1 * s1
  ds = - c5 * s1
  !
  !   Energy
  !
  f1 = s2 * mu(iflag) / k (iflag)
  f2 = 1.d0 + f1
  f3 = k (iflag) / f2
  fx = k (iflag) - f3
  exunif = - c1 * kf
  sx = exunif * fx
  !
  !   Potential
  !
  dxunif = exunif * third
  dfx1 = f2 * f2
  dfx = 2.d0 * mu(iflag) * s1 / dfx1
  v1x = sx + dxunif * fx + exunif * dfx * ds
  v2x = exunif * dfx * dsg / agrho

  sx = sx * rho
  return
end subroutine pbex
!
!---------------------------------------------------------------
subroutine pbex_vec (rho, grho, iflag, sx, v1x, v2x, length, small)
  !---------------------------------------------------------------
  !
  ! PBE exchange (without Slater exchange):
  ! iflag=1  J.P.Perdew, K.Burke, M.Ernzerhof, PRL 77, 3865 (1996)
  ! iflag=2  "revised' PBE: Y. Zhang et al., PRL 80, 890 (1998)
  ! iflag=3  PBEsol: J.P.Perdew et al., PRL 100, 136406 (2008)
  !
  USE kinds
  USE constants, ONLY : pi
  implicit none
  integer, intent(in)   :: length
  integer, intent(in)   :: iflag
  real(DP), intent(in)  :: small
  real(DP), intent(in)  :: rho(length), grho(length)
  real(DP), intent(out) :: sx(length), v1x(length), v2x(length)
  ! local variables
  integer :: i
  real(DP) :: kf, agrho, s1, dsg, exunif, fx
  ! (3*pi2*|rho|)^(1/3)
  ! |grho|
  ! |grho|/(2*kf*|rho|)
  ! n*ds/d(gn)
  ! exchange energy LDA part
  ! exchange energy gradient part
  real(DP) :: dfx, f1, f2
  ! numerical coefficients (NB: c2=(3 pi^2)^(1/3) )
  real(DP) :: third, c1, c2, c5
  parameter (third = 1.0_dp / 3.0_dp, c1 = 0.75_dp / pi , &
       c2 = 3.093667726280136_dp, c5 = 4.0_dp * third)
  ! parameters of the functional
  real(DP) :: k (3), mu(3)
  data k / 0.804_dp, 1.245_dp, 0.804_dp /, &
       mu/ 0.21951_dp, 0.21951_dp, 0.12345679012345679012_dp  /
  !
  do i=1,length
     if ((rho(i).gt.small).and.(grho(i).gt.small**2)) then
        agrho = sqrt(grho(i))
        kf = c2 * rho(i)**third
        dsg = 0.5_dp / kf
        s1 = agrho * dsg / rho(i)
        !
        !   Energy
        f1 = s1*s1 * mu(iflag) / k(iflag)
        f2 = 1.0_dp / (1.0_dp + f1)
        fx = k(iflag) * (1.0_dp - f2)
        exunif = - c1 * kf
        sx(i) = exunif * fx
        !
        !   Potential
        dfx = 2.0_dp * mu(iflag) * s1 *f2*f2

        v1x(i) = sx(i) + exunif * (third * fx - c5 * dfx * s1)
        v2x(i) = exunif * dfx * dsg / agrho
        sx(i) = sx(i) * rho(i)

     else
        v1x(i) = 0.0_dp
        v2x(i) = 0.0_dp
        sx(i) = 0.0_dp
     end if
  end do

end subroutine pbex_vec
!
!---------------------------------------------------------------
subroutine pbec (rho, grho, iflag, sc, v1c, v2c)
  !---------------------------------------------------------------
  !
  ! PBE correlation (without LDA part)
  ! iflag=1: J.P.Perdew, K.Burke, M.Ernzerhof, PRL 77, 3865 (1996).
  ! iflag=2: J.P.Perdew et al., PRL 100, 136406 (2008).
  !
  USE kinds
  implicit none
  integer, intent(in) :: iflag
  real(DP) :: rho, grho, sc, v1c, v2c
  real(DP) :: ga, be (2)
  parameter (ga = 0.031091d0)
  data be / 0.066725d0, 0.046d0 /
  real(DP) :: third, pi34, xkf, xks
  parameter (third = 1.d0 / 3.d0, pi34 = 0.6203504908994d0)
  parameter (xkf = 1.919158292677513d0, xks = 1.128379167095513d0)
  ! pi34=(3/4pi)^(1/3), xkf=(9 pi/4)^(1/3), xks= sqrt(4/pi)
  real(DP) :: kf, ks, rs, ec, vc, t, expe, af, bf, y, xy, qy
  real(DP) :: s1, h0, dh0, ddh0
  !
  rs = pi34 / rho**third
  call pw (rs, 1, ec, vc)
  kf = xkf / rs
  ks = xks * sqrt (kf)
  t = sqrt (grho) / (2.d0 * ks * rho)
  expe = exp ( - ec / ga)
  af = be(iflag) / ga * (1.d0 / (expe-1.d0) )
  bf = expe * (vc - ec)
  y = af * t * t
  xy = (1.d0 + y) / (1.d0 + y + y * y)
  qy = y * y * (2.d0 + y) / (1.d0 + y + y * y) **2
  s1 = 1.d0 + be(iflag) / ga * t * t * xy
  h0 = ga * log (s1)
  dh0 = be(iflag) * t * t / s1 * ( - 7.d0 / 3.d0 * xy - qy * (af * bf / &
       be(iflag)-7.d0 / 3.d0) )
  ddh0 = be(iflag) / (2.d0 * ks * ks * rho) * (xy - qy) / s1
  sc = rho * h0
  v1c = h0 + dh0
  v2c = ddh0
  !
  return
end subroutine pbec

!     ==================================================================
subroutine hcth(rho,grho,sx,v1x,v2x)
  !     ==================================================================
  !     HCTH/120, JCP 109, p. 6264 (1998)
  !     Parameters set-up after N.L. Doltsisnis & M. Sprik (1999)
  !     Present release: Mauro Boero, Tsukuba, 11/05/2004
  !--------------------------------------------------------------------------
  !     rhoa = rhob = 0.5 * rho
  !     grho is the SQUARE of the gradient of rho! --> gr=sqrt(grho)
  !     sx  : total exchange correlation energy at point r
  !     v1x : d(sx)/drho  (eq. dfdra = dfdrb in original)
  !     v2x : 1/gr*d(sx)/d(gr) (eq. 0.5 * dfdza = 0.5 * dfdzb in original)
  !--------------------------------------------------------------------------
  USE kinds
  USE constants, ONLY: pi
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x

  real(DP), parameter :: o3=1.0d0/3.0d0, o34=4.0d0/3.0d0, fr83=8.d0/3.d0
  real(DP) :: cg0(6), cg1(6), caa(6), cab(6), cx(6)
  real(DP) :: r3q2, r3pi, gr, rho_o3, rho_o34, xa, xa2, ra, rab, &
       dra_drho, drab_drho, g, dg, era1, dera1_dra, erab0, derab0_drab, &
       ex, dex_drho, uaa, uab, ux, ffaa, ffab,  dffaa_drho, dffab_drho,&
       denaa, denab, denx, f83rho, bygr, gaa, gab, gx, taa, tab, txx, &
       dgaa_drho, dgab_drho, dgx_drho, dgaa_dgr, dgab_dgr, dgx_dgr
  !
  r3q2=2.d0**(-o3)
  r3pi=(3.d0/pi)**o3
  !.....coefficients for pw correlation......................................
  cg0(1)= 0.031091d0
  cg0(2)= 0.213700d0
  cg0(3)= 7.595700d0
  cg0(4)= 3.587600d0
  cg0(5)= 1.638200d0
  cg0(6)= 0.492940d0
  cg1(1)= 0.015545d0
  cg1(2)= 0.205480d0
  cg1(3)=14.118900d0
  cg1(4)= 6.197700d0
  cg1(5)= 3.366200d0
  cg1(6)= 0.625170d0
  !......hcth-19-4.....................................
  caa(1)=  0.489508d+00
  caa(2)= -0.260699d+00
  caa(3)=  0.432917d+00
  caa(4)= -0.199247d+01
  caa(5)=  0.248531d+01
  caa(6)=  0.200000d+00
  cab(1)=  0.514730d+00
  cab(2)=  0.692982d+01
  cab(3)= -0.247073d+02
  cab(4)=  0.231098d+02
  cab(5)= -0.113234d+02
  cab(6)=  0.006000d+00
  cx(1) =  0.109163d+01
  cx(2) = -0.747215d+00
  cx(3) =  0.507833d+01
  cx(4) = -0.410746d+01
  cx(5) =  0.117173d+01
  cx(6)=   0.004000d+00
  !...........................................................................
  gr=DSQRT(grho)
  rho_o3=rho**(o3)
  rho_o34=rho**(o34)
  xa=1.25992105d0*gr/rho_o34
  xa2=xa*xa
  ra=0.781592642d0/rho_o3
  rab=r3q2*ra
  dra_drho=-0.260530881d0/rho_o34
  drab_drho=r3q2*dra_drho
  call pwcorr(ra,cg1,g,dg)
  era1=g
  dera1_dra=dg
  call pwcorr(rab,cg0,g,dg)
  erab0=g
  derab0_drab=dg
  ex=-0.75d0*r3pi*rho_o34
  dex_drho=-r3pi*rho_o3
  uaa=caa(6)*xa2
  uaa=uaa/(1.0d0+uaa)
  uab=cab(6)*xa2
  uab=uab/(1.0d0+uab)
  ux=cx(6)*xa2
  ux=ux/(1.0d0+ux)
  ffaa=rho*era1
  ffab=rho*erab0-ffaa
  dffaa_drho=era1+rho*dera1_dra*dra_drho
  dffab_drho=erab0+rho*derab0_drab*drab_drho-dffaa_drho
  ! mb-> i-loop removed
  denaa=1.d0/(1.0d0+caa(6)*xa2)
  denab=1.d0/(1.0d0+cab(6)*xa2)
  denx =1.d0/(1.0d0+cx(6)*xa2)
  f83rho=fr83/rho
  bygr=2.0d0/gr
  gaa=caa(1)+uaa*(caa(2)+uaa*(caa(3)+uaa*(caa(4)+uaa*caa(5))))
  gab=cab(1)+uab*(cab(2)+uab*(cab(3)+uab*(cab(4)+uab*cab(5))))
  gx=cx(1)+ux*(cx(2)+ux*(cx(3)+ux*(cx(4)+ux*cx(5))))
  taa=denaa*uaa*(caa(2)+uaa*(2.d0*caa(3)+uaa &
      *(3.d0*caa(4)+uaa*4.d0*caa(5))))
  tab=denab*uab*(cab(2)+uab*(2.d0*cab(3)+uab &
       *(3.d0*cab(4)+uab*4.d0*cab(5))))
  txx=denx*ux*(cx(2)+ux*(2.d0*cx(3)+ux &
       *(3.d0*cx(4)+ux*4.d0*cx(5))))
  dgaa_drho=-f83rho*taa
  dgab_drho=-f83rho*tab
  dgx_drho=-f83rho*txx
  dgaa_dgr=bygr*taa
  dgab_dgr=bygr*tab
  dgx_dgr=bygr*txx
  ! mb
  sx=ex*gx+ffaa*gaa+ffab*gab
  v1x=dex_drho*gx+ex*dgx_drho &
       +dffaa_drho*gaa+ffaa*dgaa_drho &
       +dffab_drho*gab+ffab*dgab_drho
  v2x=(ex*dgx_dgr+ffaa*dgaa_dgr+ffab*dgab_dgr)/gr
  return
end subroutine hcth
!-------------------------------------------------------------------=
subroutine pwcorr(r,c,g,dg)
  USE kinds
  implicit none
  real(DP) :: r, g, dg, c(6)
  real(DP) :: r12, r32, r2, rb, drb, sb

  r12=dsqrt(r)
  r32=r*r12
  r2=r*r
  rb=c(3)*r12+c(4)*r+c(5)*r32+c(6)*r2
  sb=1.0d0+1.0d0/(2.0d0*c(1)*rb)
  g=-2.0d0*c(1)*(1.0d0+c(2)*r)*dlog(sb)
  drb=c(3)/(2.0d0*r12)+c(4)+1.5d0*c(5)*r12+2.0d0*c(6)*r
  dg=(1.0d0+c(2)*r)*drb/(rb*rb*sb)-2.0d0*c(1)*c(2)*dlog(sb)

  return
end subroutine pwcorr
!-----------------------------------------------------------------------------
!     ==================================================================
subroutine optx(rho,grho,sx,v1x,v2x)
!     OPTX, Handy et al. JCP 116, p. 5411 (2002) and refs. therein
!     Present release: Mauro Boero, Tsukuba, 10/9/2002
!--------------------------------------------------------------------------
!     rhoa = rhob = 0.5 * rho in LDA implementation
!     grho is the SQUARE of the gradient of rho! --> gr=sqrt(grho)
!     sx  : total exchange correlation energy at point r
!     v1x : d(sx)/drho
!     v2x : 1/gr*d(sx)/d(gr)
!--------------------------------------------------------------------------
  use kinds, only: DP
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x

  real(DP), parameter :: small=1.D-30, smal2=1.D-10
!.......coefficients and exponents....................
  real(DP), parameter :: o43=4.0d0/3.0d0, two13=1.259921049894873D0, &
       two53=3.174802103936399D0, gam=0.006D0, a1cx=0.9784571170284421D0,&
       a2=1.43169D0 
  real(DP) :: gr, rho43, xa, gamx2, uden, uu
  !.......OPTX in compact form..........................
  if(rho <= small) then
     sx=0.0D0
     v1x=0.0D0
     v2x=0.0D0
  else
     gr = max(grho,SMAL2)
     rho43=rho**o43
     xa=two13*DSQRT(gr)/rho43
     gamx2=gam*xa*xa
     uden=1.d+00/(1.d+00+gamx2)
     uu=a2*gamx2*gamx2*uden*uden
     uden=rho43*uu*uden
     sx=-rho43*(a1cx+uu)/two13
     v1x=o43*(sx+two53*uden)/rho
     v2x=-two53*uden/gr
  endif
  return
end subroutine optx
!
!---------------------------------------------------------------
subroutine wcx (rho, grho, sx, v1x, v2x)
  !---------------------------------------------------------------
  !
  ! Wu-Cohen exchange (without Slater exchange):
  ! Z. Wu and R. E. Cohen, PRB 73, 235116 (2006)
  !
  USE kinds
  USE constants, ONLY : pi
  implicit none
  real(DP) :: rho, grho, sx, v1x, v2x
  ! input: charge and squared gradient
  ! output: energy
  ! output: potential
  ! local variables
  real(DP) :: kf, agrho, s1, s2, es2, ds, dsg, exunif, fx
  ! (3*pi2*|rho|)^(1/3)
  ! |grho|
  ! |grho|/(2*kf*|rho|)
  ! s^2
  ! n*ds/dn
  ! n*ds/d(gn)
  ! exchange energy LDA part
  ! exchange energy gradient part
  real(DP) :: dxunif, dfx, f1, f2, f3, dfx1, x1, x2, x3, &
              dxds1, dxds2, dxds3
  ! numerical coefficients (NB: c2=(3 pi^2)^(1/3) )
  real(DP) :: third, c1, c2, c5, c6, teneightyone
  parameter (third = 1.d0 / 3.d0, c1 = 0.75d0 / pi , &
       c2 = 3.093667726280136d0, c5 = 4.d0 * third, &
       teneightyone = 0.123456790123d0)
  ! parameters of the functional
  real(DP) :: k, mu, cwc
  parameter (k = 0.804d0, mu = 0.2195149727645171d0, cwc = 0.00793746933516d0) 
  !
  agrho = sqrt (grho)
  kf = c2 * rho**third
  dsg = 0.5d0 / kf
  s1 = agrho * dsg / rho
  s2 = s1 * s1
  es2 = exp(-s2)
  ds = - c5 * s1
  !
  !   Energy
  !
  ! x = 10/81 s^2 + (mu - 10/81) s^2 e^-s^2 + ln (1 + c s^4)
  x1 = teneightyone * s2 
  x2 = (mu - teneightyone) * s2 * es2
  x3 = log(1.d0 + cwc * s2 * s2)
  f1 = (x1 + x2 + x3) / k
  f2 = 1.d0 + f1
  f3 = k / f2
  fx = k - f3
  exunif = - c1 * kf
  sx = exunif * fx
  !
  !   Potential
  !
  dxunif = exunif * third
  dfx1 = f2 * f2
  dxds1 = teneightyone
  dxds2 = (mu - teneightyone) * es2 * (1.d0 - s2)
  dxds3 = 2.d0 * cwc * s2 / (1.d0 + cwc * s2 *s2)
  dfx = 2.d0 * s1 * (dxds1 + dxds2 + dxds3) / dfx1
  v1x = sx + dxunif * fx + exunif * dfx * ds
  v2x = exunif * dfx * dsg / agrho

  sx = sx * rho
  return
end subroutine wcx
!
!-----------------------------------------------------------------------
function dpz (rs, iflg)
  !-----------------------------------------------------------------------
  !  derivative of the correlation potential with respect to local density
  !  Perdew and Zunger parameterization of the Ceperley-Alder functional
  !
  use kinds, only: DP
  USE constants, ONLY: pi, fpi
  !
  implicit none
  !
  real(DP), intent (in) :: rs
  integer, intent(in) :: iflg
  real(DP) :: dpz
  !
  !  local variables
  !  a,b,c,d,gc,b1,b2 are the parameters defining the functional
  !
  real(DP), parameter :: a = 0.0311d0, b = -0.048d0, c = 0.0020d0, &
       d = -0.0116d0, gc = -0.1423d0, b1 = 1.0529d0, b2 = 0.3334d0,&
       a1 = 7.0d0 * b1 / 6.d0, a2 = 4.d0 * b2 / 3.d0
  real(DP) :: x, den, dmx, dmrs
  !
  !
  if (iflg == 1) then
     dmrs = a / rs + 2.d0 / 3.d0 * c * (log (rs) + 1.d0) + &
          (2.d0 * d-c) / 3.d0
  else
     x = sqrt (rs)
     den = 1.d0 + x * (b1 + x * b2)
     dmx = gc * ( (a1 + 2.d0 * a2 * x) * den - 2.d0 * (b1 + 2.d0 * &
          b2 * x) * (1.d0 + x * (a1 + x * a2) ) ) / den**3
     dmrs = 0.5d0 * dmx / x
  endif
  !
  dpz = - fpi * rs**4.d0 / 9.d0 * dmrs
  return
  !
end function dpz
!----------------------------------------------------------------------
!
! HSE (wPBE) stabbing starts HERE
!
! Note, that you can get PBEhole functional,
! M. Ernzerhof, J. Chem. Phys. 109, 3313 (1998),
! from this by just setting OMEGA=0
!
! These are wrappers to the reference implementation
!-----------------------------------------------------------------------
      SUBROUTINE pbexsr_lsd(RHOA,RHOB,GRHOAA,GRHOBB,sx, &
                            V1XA,V2XA,V1XB,V2XB,OMEGA)
!     ==--------------------------------------------------------------==
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER(SMALL=1.D-20)
!     ==--------------------------------------------------------------==
      SXA=0.0D0
      SXB=0.0D0
      V1XA=0.0D0
      V2XA=0.0D0
      V1XB=0.0D0
      V2XB=0.0D0
      IF(ABS(RHOA).GT.SMALL) THEN
        CALL pbexsr(2.D0*RHOA, 4.D0*GRHOAA, SXA, V1XA, V2XA, OMEGA)
      ENDIF
      IF(ABS(RHOB).GT.SMALL) THEN
        CALL pbexsr(2.D0*RHOB, 4.D0*GRHOBB, SXB, V1XB, V2XB, OMEGA)
      ENDIF
      sx = 0.5D0*(SXA+SXB)
      V2XA = 2.D0*V2XA
      V2XB = 2.D0*V2XB          ! I HOPE THIS WORKS JUST LIKE THIS

!     ==--------------------------------------------------------------==
      RETURN
      END SUBROUTINE pbexsr_lsd
!
!-----------------------------------------------------------------------     
      SUBROUTINE pbexsr(RHO,GRHO,sx,V1X,V2X,OMEGA)
!-----------------------------------------------------------------------
!
!      INCLUDE 'cnst.inc'
      use kinds

      IMPLICIT REAL*8 (A-H,O-Z)

      PARAMETER(SMALL=1.D-20,SMAL2=1.D-08)
      PARAMETER(US=0.161620459673995492D0,AX=-0.738558766382022406D0, &
                UM=0.2195149727645171D0,UK=0.8040D0,UL=UM/UK)
      REAL(DP), PARAMETER :: f1 = -1.10783814957303361_DP, alpha = 2.0_DP/3.0_DP
!     ==--------------------------------------------------------------==

!      CALL XC(RHO,EX,EC,VX,VC)
      RS = RHO**(1.0_DP/3.0_DP)
      VX = (4.0_DP/3.0_DP)*f1*alpha*RS

!      AA    = DMAX1(GRHO,SMAL2)
      AA    = GRHO
!      RR    = RHO**(-4.0_DP/3.0_DP)
      RR    = 1.0_DP/(RHO*RS)
      EX    = AX/RR
      S2    = AA*RR*RR*US*US

      S = SQRT(S2)
      IF(S.GT.10.D0) THEN
        S = 10.D0
      ENDIF
      CALL wpbe_analy_erfc_approx_grad(RHO,S,OMEGA,FX,D1X,D2X)
      sx = EX*FX        ! - EX
      DSDN = -4.D0/3.D0*S/RHO
      V1X = VX*FX + (DSDN*D2X+D1X)*EX   ! - VX
      DSDG = US*RR
      V2X = EX*1.D0/SQRT(AA)*DSDG*D2X

! NOTE, here sx is the total energy density,
! not just the gradient correction energy density as e.g. in pbex()
! And the same goes for the potentials V1X, V2X

!     ==--------------------------------------------------------------==
      RETURN
      END SUBROUTINE pbexsr
!
!-----------------------------------------------------------------------
      SUBROUTINE wpbe_analy_erfc_approx_grad(rho,s,omega,Fx_wpbe, &
                      d1rfx,d1sfx)
!--------------------------------------------------------------------
!
!     wPBE Enhancement Factor (erfc approx.,analytical, gradients)
!
!--------------------------------------------------------------------

      Implicit None

      Real*8 rho,s,omega,Fx_wpbe,d1sfx,d1rfx

      Real*8 f12,f13,f14,f18,f23,f43,f32,f72,f34,f94,f1516,f98
      Real*8 pi,pi2,pi_23,srpi
      Real*8 Three_13

      Real*8 ea1,ea2,ea3,ea4,ea5,ea6,ea7,ea8
      Real*8 eb1
      Real*8 A,B,C,D,E
      Real*8 Ha1,Ha2,Ha3,Ha4,Ha5
      Real*8 Fc1,Fc2
      Real*8 EGa1,EGa2,EGa3
      Real*8 EGscut,wcutoff,expfcutoff

      Real*8 xkf, xkfrho
      Real*8 w,w2,w3,w4,w5,w6,w7,w8
      Real*8 d1rw
      Real*8 A2,A3,A4,A12,A32,A52,A72
      Real*8 X
      Real*8 s2,s3,s4,s5,s6

      Real*8 H,F
      Real*8 Hnum,Hden,d1sHnum,d1sHden
      Real*8 d1sH,d1sF
      Real*8 G_a,G_b,EG
      Real*8 d1sG_a,d1sG_b,d1sEG

      Real*8 Hsbw,Hsbw2,Hsbw3,Hsbw4,Hsbw12,Hsbw32,Hsbw52,Hsbw72
      Real*8 DHsbw,DHsbw2,DHsbw3,DHsbw4,DHsbw5
      Real*8 DHsbw12,DHsbw32,DHsbw52,DHsbw72,DHsbw92
      Real*8 d1sHsbw,d1rHsbw
      Real*8 d1sDHsbw,d1rDHsbw
      Real*8 HsbwA94,HsbwA9412
      Real*8 HsbwA942,HsbwA943,HsbwA945
      Real*8 piexperf,expei
      Real*8 piexperfd1,expeid1
      Real*8 d1spiexperf,d1sexpei
      Real*8 d1rpiexperf,d1rexpei
      Real*8 expei1,expei2,expei3,expei4

      Real*8 DHs,DHs2,DHs3,DHs4,DHs72,DHs92,DHsw,DHsw2,DHsw52,DHsw72
      Real*8 d1sDHs,d1rDHsw

      Real*8 np1,np2
      Real*8 d1rnp1,d1rnp2
      Real*8 t1,t2t9,t10,t10d1
      Real*8 f2,f3,f4,f5,f6,f7,f8,f9
      Real*8 f2d1,f3d1,f4d1,f5d1,f6d1,f8d1,f9d1
      Real*8 d1sf2,d1sf3,d1sf4,d1sf5,d1sf6,d1sf7,d1sf8,d1sf9
      Real*8 d1rf2,d1rf3,d1rf4,d1rf5,d1rf6,d1rf7,d1rf8,d1rf9
      Real*8 d1st1,d1rt1
      Real*8 d1st2t9,d1rt2t9
      Real*8 d1st10,d1rt10
      Real*8 d1sterm1,d1rterm1,term1d1
      Real*8 d1sterm2
      Real*8 d1sterm3,d1rterm3
      Real*8 d1sterm4,d1rterm4
      Real*8 d1sterm5,d1rterm5

      Real*8 term1,term2,term3,term4,term5

      Real*8 ax,um,uk,ul
      Real*8 gc1,gc2

      Real*8, external :: qe_erf, qe_erfc
!      Real*8 ei
      Real*8, external :: expint

      Real*8 Zero,One,Two,Three,Four,Five,Six,Seven,Eight,Nine,Ten
      Real*8 Fifteen,Sixteen
      Real*8 r12,r64,r36,r81,r256,r384,r864,r1944,r4374
      Real*8 r20,r25,r27,r48,r120,r128,r144,r288,r324,r512,r729
      Real*8 r30,r32,r75,r243,r2187,r6561,r40,r105,r54,r135
      Real*8 r1215,r15309

      Save Zero,One,Two,Three,Four,Five,Six,Seven,Eight,Nine,Ten
      Data Zero,One,Two,Three,Four,Five,Six,Seven,Eight,Nine,Ten &
        / 0D0,1D0,2D0,3D0,4D0,5D0,6D0,7D0,8D0,9D0,10D0 /
      Save Fifteen,Sixteen
      Data Fifteen,Sixteen / 1.5D1, 1.6D1 /
      Save r36,r64,r81,r256,r384,r864,r1944,r4374
      Data r36,r64,r81,r256,r384,r864,r1944,r4374 &
        / 3.6D1,6.4D1,8.1D1,2.56D2,3.84D2,8.64D2,1.944D3,4.374D3 /
      Save r27,r48,r120,r128,r144,r288,r324,r512,r729
      Data r27,r48,r120,r128,r144,r288,r324,r512,r729 &
        / 2.7D1,4.8D1,1.2D2,1.28D2,1.44D2,2.88D2,3.24D2,5.12D2,7.29D2 /
      Save r20,r32,r243,r2187,r6561,r40
      Data r20,r32,r243,r2187,r6561,r40 &
        / 2.0d1,3.2D1,2.43D2,2.187D3,6.561D3,4.0d1 /
      Save r12,r25,r30,r54,r75,r105,r135,r1215,r15309
      Data r12,r25,r30,r54,r75,r105,r135,r1215,r15309 &
        / 1.2D1,2.5d1,3.0d1,5.4D1,7.5d1,1.05D2,1.35D2,1.215D3,1.5309D4 /

!     General constants

      f12    = 0.5d0
      f13    = One/Three
      f14    = 0.25d0
      f18    = 0.125d0

      f23    = Two * f13
      f43    = Two * f23

      f32    = 1.5d0
      f72    = 3.5d0
      f34    = 0.75d0
      f94    = 2.25d0
      f98    = 1.125d0
      f1516  = Fifteen / Sixteen

      pi     = ACos(-One)
      pi2    = pi*pi
      pi_23  = pi2**f13
      srpi   = sqrt(pi)

      Three_13 = Three**f13

!     Constants from fit

      ea1 = -1.128223946706117d0
      ea2 = 1.452736265762971d0
      ea3 = -1.243162299390327d0
      ea4 = 0.971824836115601d0
      ea5 = -0.568861079687373d0
      ea6 = 0.246880514820192d0
      ea7 = -0.065032363850763d0
      ea8 = 0.008401793031216d0

      eb1 = 1.455915450052607d0

!     Constants for PBE hole

      A      =  1.0161144d0
      B      = -3.7170836d-1
      C      = -7.7215461d-2
      D      =  5.7786348d-1
      E      = -5.1955731d-2
      X      = - Eight/Nine

!     Constants for fit of H(s) (PBE)

      Ha1    = 9.79681d-3
      Ha2    = 4.10834d-2
      Ha3    = 1.87440d-1
      Ha4    = 1.20824d-3
      Ha5    = 3.47188d-2

!     Constants for F(H) (PBE)

      Fc1    = 6.4753871d0
      Fc2    = 4.7965830d-1

!     Constants for polynomial expansion for EG for small s

      EGa1   = -2.628417880d-2
      EGa2   = -7.117647788d-2
      EGa3   =  8.534541323d-2

!     Constants for large x expansion of exp(x)*ei(-x)

      expei1 = 4.03640D0
      expei2 = 1.15198D0
      expei3 = 5.03627D0
      expei4 = 4.19160D0

!     Cutoff criterion below which to use polynomial expansion

      EGscut     = 8.0d-2
      wcutoff    = 1.4D1
      expfcutoff = 7.0D2

!     Calculate prelim variables

      xkf    = (Three*pi2*rho) ** f13
      xkfrho = xkf * rho

      A2 = A*A
      A3 = A2*A
      A4 = A3*A
      A12 = Sqrt(A)
      A32 = A12*A
      A52 = A32*A
      A72 = A52*A

      w      = omega / xkf
      w2    = w * w
      w3    = w2 * w
      w4    = w2 * w2
      w5    = w3 * w2
      w6    = w5 * w
      w7    = w6 * w
      w8    = w7 * w

      d1rw  = -(One/(Three*rho))*w

      X      = - Eight/Nine

      s2     = s*s
      s3     = s2*s
      s4     = s2*s2
      s5     = s4*s
      s6     = s5*s

!     Calculate wPBE enhancement factor

      Hnum    = Ha1*s2 + Ha2*s4
      Hden    = One + Ha3*s4 + Ha4*s5 + Ha5*s6

      H       = Hnum/Hden

      d1sHnum = Two*Ha1*s + Four*Ha2*s3
      d1sHden = Four*Ha3*s3 + Five*Ha4*s4 + Six*Ha5*s5

      d1sH    = (Hden*d1sHnum - Hnum*d1sHden) / (Hden*Hden)

      F      = Fc1*H + Fc2
      d1sF   = Fc1*d1sH

!     Change exponent of Gaussian if we're using the simple approx.

      if(w .gt. wcutoff) then

        eb1 = 2.0d0

      endif

!     Calculate helper variables (should be moved later on...)

      Hsbw = s2*H + eb1*w2
      Hsbw2 = Hsbw*Hsbw
      Hsbw3 = Hsbw2*Hsbw
      Hsbw4 = Hsbw3*Hsbw
      Hsbw12 = Sqrt(Hsbw)
      Hsbw32 = Hsbw12*Hsbw
      Hsbw52 = Hsbw32*Hsbw
      Hsbw72 = Hsbw52*Hsbw

      d1sHsbw  = d1sH*s2 + Two*s*H
      d1rHsbw  = Two*eb1*d1rw*w

      DHsbw = D + s2*H + eb1*w2
      DHsbw2 = DHsbw*DHsbw
      DHsbw3 = DHsbw2*DHsbw
      DHsbw4 = DHsbw3*DHsbw
      DHsbw5 = DHsbw4*DHsbw
      DHsbw12 = Sqrt(DHsbw)
      DHsbw32 = DHsbw12*DHsbw
      DHsbw52 = DHsbw32*DHsbw
      DHsbw72 = DHsbw52*DHsbw
      DHsbw92 = DHsbw72*DHsbw

      HsbwA94   = f94 * Hsbw / A
      HsbwA942  = HsbwA94*HsbwA94
      HsbwA943  = HsbwA942*HsbwA94
      HsbwA945  = HsbwA943*HsbwA942
      HsbwA9412 = Sqrt(HsbwA94)

      DHs    = D + s2*H
      DHs2   = DHs*DHs
      DHs3   = DHs2*DHs
      DHs4   = DHs3*DHs
      DHs72  = DHs3*sqrt(DHs)
      DHs92  = DHs72*DHs

      d1sDHs = Two*s*H + s2*d1sH

      DHsw   = DHs + w2
      DHsw2  = DHsw*DHsw
      DHsw52 = sqrt(DHsw)*DHsw2
      DHsw72 = DHsw52*DHsw

      d1rDHsw = Two*d1rw*w

      if(s .gt. EGscut) then

        G_a    = srpi * (Fifteen*E + Six*C*(One+F*s2)*DHs + &
                         Four*B*(DHs2) + Eight*A*(DHs3))    &
                      * (One / (Sixteen * DHs72))           &
                       - f34*pi*sqrt(A) * exp(f94*H*s2/A) * &
                         (One - qe_erf(f32*s*sqrt(H/A)))

        d1sG_a = (One/r32)*srpi *                           &
                 ((r36*(Two*H + d1sH*s) / (A12*sqrt(H/A)))  &
                  + (One/DHs92) *                           &
                     (-Eight*A*d1sDHs*DHs3 - r105*d1sDHs*E  &
                      -r30*C*d1sDHs*DHs*(One+s2*F)          &
                      +r12*DHs2*(-B*d1sDHs + C*s*(d1sF*s + Two*F)))  &
                  - ((r54*exp(f94*H*s2/A)*srpi*s*(Two*H+d1sH*s)*     &
                     qe_erfc(f32*sqrt(H/A)*s))                         &
                     / A12))

        G_b    = (f1516 * srpi * s2) / DHs72

        d1sG_b = (Fifteen*srpi*s*(Four*DHs - Seven*d1sDHs*s)) &
                 / (r32*DHs92)

        EG     = - (f34*pi + G_a) / G_b

        d1sEG  = (-Four*d1sG_a*G_b + d1sG_b*(Four*G_a + Three*pi)) &
                 / (Four*G_b*G_b)

      else

        EG    = EGa1 + EGa2*s2 + EGa3*s4
        d1sEG = Two*EGa2*s + Four*EGa3*s3

      endif

!    Calculate the terms needed in any case


      term2 =       (DHs2*B + DHs*C + Two*E + DHs*s2*C*F + Two*s2*EG) / &
                    (Two*DHs3)

      d1sterm2 = (-Six*d1sDHs*(EG*s2 + E)                     &
                  + DHs2 * (-d1sDHs*B + s*C*(d1sF*s + Two*F)) &
                  + Two*DHs * (Two*EG*s - d1sDHs*C            &
                  + s2 * (d1sEG - d1sDHs*C*F)))               &
                 / (Two*DHs4)

      term3 = - w  * (Four*DHsw2*B + Six*DHsw*C + Fifteen*E &
                      + Six*DHsw*s2*C*F + Fifteen*s2*EG) /  &
                     (Eight*DHs*DHsw52)

      d1sterm3 = w * (Two*d1sDHs*DHsw * (Four*DHsw2*B         &
                         + Six*DHsw*C + Fifteen*E             &
                         + Three*s2*(Five*EG + Two*DHsw*C*F)) &
                      + DHs * (r75*d1sDHs*(EG*s2 + E)         &
                         + Four*DHsw2*(d1sDHs*B               &
                              - Three*s*C*(d1sF*s + Two*F))   &
                         - Six*DHsw*(-Three*d1sDHs*C          &
                              + s*(Ten*EG + Five*d1sEG*s      &
                                  - Three*d1sDHs*s*C*F))))    &
                 / (Sixteen*DHs2*DHsw72)

      d1rterm3 = (-Two*d1rw*DHsw * (Four*DHsw2*B              &
                         + Six*DHsw*C + Fifteen*E             &
                         + Three*s2*(Five*EG + Two*DHsw*C*F)) &
                      + w * d1rDHsw * (r75*(EG*s2 + E)        &
                         + Two*DHsw*(Two*DHsw*B + Nine*C      &
                                     + Nine*s2*C*F)))         &
                 / (Sixteen*DHs*DHsw72)

      term4 = - w3 * (DHsw*C + Five*E + DHsw*s2*C*F + Five*s2*EG) /  &
                     (Two*DHs2*DHsw52)

      d1sterm4 = (w3 * (Four*d1sDHs*DHsw * (DHsw*C + Five*E   &
                             + s2 * (Five*EG + DHsw*C*F))     &
                        + DHs * (r25*d1sDHs*(EG*s2 + E)       &
                             - Two*DHsw2*s*C*(d1sF*s + Two*F) &
                             + DHsw * (Three*d1sDHs*C + s*(-r20*EG  &
                                   - Ten*d1sEG*s              &
                                   + Three*d1sDHs*s*C*F)))))  &
                 / (Four*DHs3*DHsw72)

      d1rterm4 = (w2 * (-Six*d1rw*DHsw * (DHsw*C + Five*E   &
                             + s2 * (Five*EG + DHsw*C*F))   &
                        + w * d1rDHsw * (r25*(EG*s2 + E) +  &
                             Three*DHsw*C*(One + s2*F))))  &
                 / (Four*DHs2*DHsw72)

      term5 = - w5 * (E + s2*EG) / &
                     (DHs3*DHsw52)

      d1sterm5 = (w5 * (Six*d1sDHs*DHsw*(EG*s2 + E)               &
                        + DHs * (-Two*DHsw*s * (Two*EG + d1sEG*s) &
                             + Five*d1sDHs * (EG*s2 + E))))       &
                 / (Two*DHs4*DHsw72)

      d1rterm5 = (w4 * Five*(EG*s2 + E) * (-Two*d1rw*DHsw   &
                                           + d1rDHsw * w))  &
                 / (Two*DHs3*DHsw72)


      if((s.gt.0.0d0).or.(w.gt.0.0d0)) then

        t10    = (f12)*A*Log(Hsbw / DHsbw)
        t10d1  = f12*A*(One/Hsbw - One/DHsbw)
        d1st10 = d1sHsbw*t10d1
        d1rt10 = d1rHsbw*t10d1

      endif

!     Calculate exp(x)*f(x) depending on size of x

      if(HsbwA94 .lt. expfcutoff) then

        piexperf = pi*Exp(HsbwA94)*qe_erfc(HsbwA9412)
!        expei    = Exp(HsbwA94)*Ei(-HsbwA94)
        expei    = Exp(HsbwA94)*(-expint(1,HsbwA94))

      else

!       print *,rho,s," LARGE HsbwA94"

        piexperf = pi*(One/(srpi*HsbwA9412)          &
                   - One/(Two*Sqrt(pi*HsbwA943))     &
                   + Three/(Four*Sqrt(pi*HsbwA945)))

        expei  = - (One/HsbwA94) *                         &
                   (HsbwA942 + expei1*HsbwA94 + expei2) /  &
                   (HsbwA942 + expei3*HsbwA94 + expei4)

      endif

!     Calculate the derivatives (based on the orig. expression)
!     --> Is this ok? ==> seems to be ok...

      piexperfd1  = - (Three*srpi*sqrt(Hsbw/A))/(Two*Hsbw)  &
                    + (Nine*piexperf)/(Four*A)
      d1spiexperf = d1sHsbw*piexperfd1
      d1rpiexperf = d1rHsbw*piexperfd1

      expeid1  = f14*(Four/Hsbw + (Nine*expei)/A)
      d1sexpei = d1sHsbw*expeid1
      d1rexpei = d1rHsbw*expeid1

      if (w .eq. Zero) then

!       Fall back to original expression for the PBE hole

        t1 = -f12*A*expei
        d1st1 = -f12*A*d1sexpei
        d1rt1 = -f12*A*d1rexpei

!        write(*,*) s, t1, t10, d1st1,d1rt1,d1rt10

        if(s .gt. 0.0D0) then

          term1    = t1 + t10
          d1sterm1 = d1st1 + d1st10
          d1rterm1 = d1rt1 + d1rt10

          Fx_wpbe = X * (term1 + term2)

          d1sfx = X * (d1sterm1 + d1sterm2)
          d1rfx = X * d1rterm1

        else

          Fx_wpbe = 1.0d0

! TODO    This is checked to be true for term1
!         How about the other terms???

          d1sfx   = 0.0d0
          d1rfx   = 0.0d0

        endif


      elseif(w .gt. wcutoff) then

!       Use simple Gaussian approximation for large w

!       print *,rho,s," LARGE w"

        term1 = -f12*A*(expei+log(DHsbw)-log(Hsbw))

        term1d1  = - A/(Two*DHsbw) - f98*expei
        d1sterm1 = d1sHsbw*term1d1
        d1rterm1 = d1rHsbw*term1d1

        Fx_wpbe = X * (term1 + term2 + term3 + term4 + term5)

        d1sfx = X * (d1sterm1 + d1sterm2 + d1sterm3  &
                              + d1sterm4 + d1sterm5)

        d1rfx = X * (d1rterm1 + d1rterm3 + d1rterm4 + d1rterm5)

      else

!       For everything else, use the full blown expression

!       First, we calculate the polynomials for the first term

         np1    = -f32*ea1*A12*w + r27*ea3*w3/(Eight*A12)     &
                  - r243*ea5*w5/(r32*A32) + r2187*ea7*w7/(r128*A52)

        d1rnp1 = - f32*ea1*d1rw*A12 + (r81*ea3*d1rw*w2)/(Eight*A12) &
                 - (r1215*ea5*d1rw*w4)/(r32*A32)                    &
                 + (r15309*ea7*d1rw*w6)/(r128*A52)

        np2 = -A + f94*ea2*w2 - r81*ea4*w4/(Sixteen*A)        &
              + r729*ea6*w6/(r64*A2) - r6561*ea8*w8/(r256*A3)


        d1rnp2 =   f12*(Nine*ea2*d1rw*w)         &
                 - (r81*ea4*d1rw*w3)/(Four*A)    &
                 + (r2187*ea6*d1rw*w5)/(r32*A2)  &
                 - (r6561*ea8*d1rw*w7)/(r32*A3)

!       The first term is

        t1    = f12*(np1*piexperf + np2*expei)
        d1st1 = f12*(d1spiexperf*np1 + d1sexpei*np2)
        d1rt1 = f12*(d1rnp2*expei + d1rpiexperf*np1 +  &
                     d1rexpei*np2 + d1rnp1*piexperf)

!       The factors for the main polynomoal in w and their derivatives

        f2    = (f12)*ea1*srpi*A / DHsbw12
        f2d1  = - ea1*srpi*A / (Four*DHsbw32)
        d1sf2 = d1sHsbw*f2d1
        d1rf2 = d1rHsbw*f2d1

        f3    = (f12)*ea2*A / DHsbw
        f3d1  = - ea2*A / (Two*DHsbw2)
        d1sf3 = d1sHsbw*f3d1
        d1rf3 = d1rHsbw*f3d1

        f4    =  ea3*srpi*(-f98 / Hsbw12     &
                 + f14*A / DHsbw32)
        f4d1  = ea3*srpi*((Nine/(Sixteen*Hsbw32))-   &
                          (Three*A/(Eight*DHsbw52)))
        d1sf4 = d1sHsbw*f4d1
        d1rf4 = d1rHsbw*f4d1

        f5    = ea4*(One/r128) * (-r144*(One/Hsbw)   &
                 + r64*(One/DHsbw2)*A)
        f5d1  = ea4*((f98/Hsbw2)-(A/DHsbw3))
        d1sf5 = d1sHsbw*f5d1
        d1rf5 = d1rHsbw*f5d1

        f6    = ea5*(Three*srpi*(Three*DHsbw52*(Nine*Hsbw-Two*A) &
                 + Four*Hsbw32*A2))                              &
                 / (r32*DHsbw52*Hsbw32*A)
        f6d1  = ea5*srpi*((r27/(r32*Hsbw52))-        &
                    (r81/(r64*Hsbw32*A))-            &
                    ((Fifteen*A)/(Sixteen*DHsbw72)))
        d1sf6 = d1sHsbw*f6d1
        d1rf6 = d1rHsbw*f6d1

        f7    = ea6*(((r32*A)/DHsbw3                 &
                 + (-r36 + (r81*s2*H)/A)/Hsbw2)) / r32
        d1sf7 = ea6*(Three*(r27*d1sH*DHsbw4*Hsbw*s2 +           &
                Eight*d1sHsbw*A*(Three*DHsbw4 - Four*Hsbw3*A) + &
                r54*DHsbw4*s*(Hsbw - d1sHsbw*s)*H))/            &
                (r32*DHsbw4*Hsbw3*A)
        d1rf7 = ea6*d1rHsbw*((f94/Hsbw3)-((Three*A)/DHsbw4)     &
                           -((r81*s2*H)/(Sixteen*Hsbw3*A)))

        f8    = ea7*(-Three*srpi*(-r40*Hsbw52*A3                &
                 +Nine*DHsbw72*(r27*Hsbw2-Six*Hsbw*A+Four*A2))) &
                 / (r128 * DHsbw72*Hsbw52*A2)
        f8d1  = ea7*srpi*((r135/(r64*Hsbw72)) + (r729/(r256*Hsbw32*A2))  &
                         -(r243/(r128*Hsbw52*A))                         &
                         -((r105*A)/(r32*DHsbw92)))
        d1sf8 = d1sHsbw*f8d1
        d1rf8 = d1rHsbw*f8d1

        f9    = (r324*ea6*eb1*DHsbw4*Hsbw*A                      &
                + ea8*(r384*Hsbw3*A3 + DHsbw4*(-r729*Hsbw2       &
                + r324*Hsbw*A - r288*A2))) / (r128*DHsbw4*Hsbw3*A2)
        f9d1  = -((r81*ea6*eb1)/(Sixteen*Hsbw3*A))               &
                + ea8*((r27/(Four*Hsbw4))+(r729/(r128*Hsbw2*A2)) &
                      -(r81/(Sixteen*Hsbw3*A))                   &
                      -((r12*A/DHsbw5)))
        d1sf9 = d1sHsbw*f9d1
        d1rf9 = d1rHsbw*f9d1

        t2t9    = f2*w  + f3*w2 + f4*w3 + f5*w4 + f6*w5          &
                        + f7*w6 + f8*w7 + f9*w8
        d1st2t9 = d1sf2*w + d1sf3*w2 + d1sf4*w3 + d1sf5*w4       &
                          + d1sf6*w5 + d1sf7*w6 + d1sf8*w7       &
                          + d1sf9*w8
        d1rt2t9 = d1rw*f2 + d1rf2*w + Two*d1rw*f3*w   &
                  + d1rf3*w2 + Three*d1rw*f4*w2       &
                  + d1rf4*w3 + Four*d1rw*f5*w3        &
                  + d1rf5*w4 + Five*d1rw*f6*w4        &
                  + d1rf6*w5 + Six*d1rw*f7*w5         &
                  + d1rf7*w6 + Seven*d1rw*f8*w6       &
                  + d1rf8*w7 + Eight*d1rw*f9*w7 + d1rf9*w8

!       The final value of term1 for 0 < omega < wcutoff is:

        term1 = t1 + t2t9 + t10

        d1sterm1 = d1st1 + d1st2t9 + d1st10
        d1rterm1 = d1rt1 + d1rt2t9 + d1rt10

!       The final value for the enhancement factor and its
!       derivatives is:

        Fx_wpbe = X * (term1 + term2 + term3 + term4 + term5)

        d1sfx = X * (d1sterm1 + d1sterm2 + d1sterm3    &
                              + d1sterm4 + d1sterm5)

        d1rfx = X * (d1rterm1 + d1rterm3 + d1rterm4 + d1rterm5)

      endif

      END SUBROUTINE wpbe_analy_erfc_approx_grad
