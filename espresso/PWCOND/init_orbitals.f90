!
! Copyright (C) 2003 A. Smogunov
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine init_orbitals (zlen, bd1, bd2, z, nrz, rsph, lsr)
!
! Calculates and allocates some variables describing the nonlocal
! orbitals
!
! input:
!   zlen     -  the length of the unit cell in the z direction
!   bd1, bd2 -  two boundaries of the region under interest
!   z(nrz)   -  mesh in the z direction
!   rsph     -  radii of the spheres
!   lsr      -  1/2/3 if the region is left lead/scat. reg./right lead 
!

  use cond
  use lsda_mod, only: nspin
  use noncollin_module, only : noncolin
  use spin_orb, only: lspinorb
  use ions_base,  only : atm, nat, ityp, tau 
  use uspp_param, only : nbrx, nbeta, lll, betar, tvanp, dion
  use uspp,       only : deeq, deeq_nc, qq, qq_so 
  use atom,       only : r, rab 

  implicit none

  integer :: noins, lnocros, rnocros, nocros, norb, na, nt, ih, ih1,&
             ioins, ilocros, irocros, orbin, orbfin, ib, lsr, nrz,  &
             m, k, ipol, iorb, iorb1, is     
  integer, allocatable :: orbind(:,:), tblm(:,:), cros(:,:), natih(:,:)
  real(kind=DP), parameter :: eps=1.d-8
  real(kind=DP) :: ledge, redge, ledgel, redgel, ledger, redger, &
                   bd1, bd2, zlen, z(nrz+1), rsph(nbrx, npsx)   
  real(kind=DP), allocatable :: taunew(:,:), zpseu(:,:,:)

  complex(kind=DP), allocatable :: zpseu_nc(:,:,:,:)

  allocate ( orbind(nat,nbrx) )
  orbind = -1

!---------------------
! Calculate number of crossing and inside-lying orbitals
!
  noins = 0
  lnocros = 0
  rnocros = 0
  do na = 1, nat
     nt = ityp(na)
     do ib = 1, nbeta(nt)
        ledge = tau(3,na)-rsph(ib,nt)
        ledgel = ledge-zlen
        ledger = ledge+zlen 
        redge = tau(3,na)+rsph(ib,nt)
        redgel = redge-zlen
        redger = redge+zlen
        if (ledge.le.bd1.and.redge.gt.bd2) &
            call errore ('init_cond','Too big atomic spheres',1)
        if (ledge.gt.bd1.and.redge.le.bd2) then  
           noins = noins+2*lll(ib,nt)+1
           orbind(na,ib) = 0

        elseif(ledge.le.bd1.and.redge.gt.bd1) then
           lnocros = lnocros+2*lll(ib,nt)+1
           orbind(na,ib) = 1
           if(ledger.le.bd2.and.redger.gt.bd2) then
             rnocros = rnocros+2*lll(ib,nt)+1
             orbind(na,ib) = 2
           endif 

        elseif(ledger.le.bd2.and.redger.gt.bd2) then
           rnocros = rnocros+2*lll(ib,nt)+1
           orbind(na,ib) = 3


        elseif(ledge.le.bd2.and.redge.gt.bd2) then
           rnocros = rnocros+2*lll(ib,nt)+1
           orbind(na,ib) = 4 
           if(ledgel.le.bd1.and.redgel.gt.bd1) then
             lnocros = lnocros+2*lll(ib,nt)+1
             orbind(na,ib) = 5
           endif

        elseif(ledgel.le.bd1.and.redgel.gt.bd1) then
           lnocros = lnocros+2*lll(ib,nt)+1
           orbind(na,ib) = 6

        endif
     enddo
  enddo
  norb = noins + lnocros + rnocros
  nocros = (lnocros + rnocros)/2 
!------------------------------------

!-----------------------------
! Formation of some orbital arrays
!
  allocate( taunew(4,norb) )
  allocate( tblm(4,norb) )
  allocate( natih(2,norb) )
  allocate( cros(norb, nrz) )
  if (noncolin) then
    allocate(zpseu_nc(2, norb, norb, nspin))
  else
    allocate( zpseu(2, norb, norb) )
  endif

  ilocros = 0
  ioins = ilocros + lnocros 
  irocros = ioins + noins
  
  do na = 1, nat
    nt = ityp(na)
    ih = 0
    do ib = 1, nbeta(nt)
      do m = 1,2*lll(ib,nt) + 1
        ih = ih+1
        if(orbind(na,ib).eq.0) then
          ioins = ioins+1
          natih(1,ioins)=na
          natih(2,ioins)=ih
          tblm(1,ioins) = nt
          tblm(2,ioins) = ib
          tblm(3,ioins) = lll(ib,nt)
          tblm(4,ioins) = m
          do ipol = 1, 3
            taunew(ipol,ioins)=tau(ipol,na)
          enddo
          taunew(4,ioins) = rsph(ib,nt)
        endif
        if(orbind(na,ib).eq.1.or.orbind(na,ib).eq.2) then
          ilocros = ilocros + 1
          natih(1,ilocros)=na
          natih(2,ilocros)=ih
          tblm(1,ilocros) = nt
          tblm(2,ilocros) = ib
          tblm(3,ilocros) = lll(ib,nt)
          tblm(4,ilocros) = m
          do ipol = 1, 3
            taunew(ipol,ilocros)=tau(ipol,na)
          enddo
          taunew(4,ilocros) = rsph(ib,nt)
        endif 
        if(orbind(na,ib).eq.2.or.orbind(na,ib).eq.3) then
          irocros = irocros + 1
          natih(1,irocros)=na
          natih(2,irocros)=ih
          tblm(1,irocros) = nt
          tblm(2,irocros) = ib
          tblm(3,irocros) = lll(ib,nt)
          tblm(4,irocros) = m
          do ipol = 1, 2
            taunew(ipol,irocros)=tau(ipol,na)
          enddo
          taunew(3,irocros) = tau(3,na) + zlen
          taunew(4,irocros) = rsph(ib,nt)
        endif
        if(orbind(na,ib).eq.4.or.orbind(na,ib).eq.5) then
          irocros = irocros + 1
          natih(1,irocros)=na
          natih(2,irocros)=ih
          tblm(1,irocros) = nt
          tblm(2,irocros) = ib
          tblm(3,irocros) = lll(ib,nt)
          tblm(4,irocros) = m
          do ipol = 1, 3
            taunew(ipol,irocros)=tau(ipol,na)
          enddo
          taunew(4,irocros) = rsph(ib,nt)
        endif
        if(orbind(na,ib).eq.5.or.orbind(na,ib).eq.6) then         
          ilocros = ilocros + 1
          natih(1,ilocros)=na
          natih(2,ilocros)=ih
          tblm(1,ilocros) = nt
          tblm(2,ilocros) = ib
          tblm(3,ilocros) = lll(ib,nt)
          tblm(4,ilocros) = m
          do ipol = 1, 2
            taunew(ipol,ilocros)=tau(ipol,na)
          enddo
          taunew(3,ilocros) = tau(3,na) - zlen
          taunew(4,ilocros) = rsph(ib,nt)
        endif
      enddo
    enddo
  enddo

  do iorb = 1, norb
    taunew(3,iorb) = taunew(3,iorb) - bd1
  enddo 
!--------------------------

!-------------------------
! to form the array containing the information does the orbital
! cross the given slab or not.
!
  do iorb=1, norb
    ledge = taunew(3,iorb)-taunew(4,iorb)
    redge = taunew(3,iorb)+taunew(4,iorb)
    do k=1, nrz
      if (ledge.gt.z(k+1).or.redge.lt.z(k)) then
         cros(iorb,k)=0
      else
         cros(iorb,k)=1
      endif
    enddo
  enddo
!----------------------------

!----------------------------
!    To form zpseu
!
  if (noncolin) then
    zpseu_nc=0.d0
  else
    zpseu = 0.d0
  endif

  orbin = 1
  orbfin = lnocros+noins
  do k = 1, 2
   do iorb = orbin, orbfin 
     nt = tblm(1,iorb)
     ib = tblm(2,iorb)
     if(tvanp(nt).or.lspinorb) then
       na = natih(1,iorb)
       ih = natih(2,iorb)
       do iorb1 = orbin, orbfin
         if (na.eq.natih(1,iorb1)) then
           ih1 = natih(2,iorb1)
           if (noncolin) then
             do is=1, nspin
               if(lspinorb) then
                zpseu_nc(1,iorb,iorb1,is)=deeq_nc(ih,ih1,na,is)
                zpseu_nc(2,iorb,iorb1,is)=qq_so(ih,ih1,is,nt)
               else
                zpseu_nc(1,iorb,iorb1,is)=deeq_nc(ih,ih1,na,is)
                zpseu_nc(2,iorb,iorb1,is)=qq(ih,ih1,nt)
               endif
             enddo
           else
             zpseu(1,iorb,iorb1)=deeq(ih,ih1,na,iofspin)
             zpseu(2,iorb,iorb1) = qq(ih,ih1,nt)
           endif  
         endif
       enddo
     else
       if (noncolin) then
         do is = 1, nspin
          zpseu_nc(1,iorb,iorb,is)=dion(ib,ib,nt)
         enddo
       else
         zpseu(1,iorb,iorb)=dion(ib,ib,nt)
       endif
     endif
   enddo
   orbin = lnocros+noins+1
   orbfin = norb
  enddo
!--------------------------

!--------------------------
! Allocation 
!
  if(lsr.eq.1) then
    norbl = norb
    nocrosl = nocros
    noinsl = noins
    if(ikind.eq.1) then
      norbr = norb
      nocrosr = nocros
      noinsr = noins
    endif
    allocate( taunewl(4,norbl) )
    allocate( tblml(4,norbl) )
    allocate( crosl(norbl, nrzl) )
    if (noncolin) then
      allocate(zpseul_nc(2, norbl, norbl, nspin))
    else
      allocate( zpseul(2, norbl, norbl) )
    endif
    taunewl = taunew
    tblml = tblm
    crosl = cros
    if (noncolin) then
      zpseul_nc = zpseu_nc
    else
      zpseul = zpseu
    endif
    rl = r
    rabl = rab
    betarl = betar
    norbf = norbl
  elseif(lsr.eq.2) then
    norbs = norb
    noinss = noins
    allocate( taunews(4,norbs) )
    allocate( tblms(4,norbs) )
    allocate( cross(norbs, nrzs) )
    if (noncolin) then
      allocate(zpseus_nc(2, norbs, norbs, nspin))
    else
      allocate( zpseus(2, norbs, norbs) )
    endif
    taunews = taunew
    tblms = tblm
    cross = cros
    if (noncolin) then
      zpseus_nc = zpseu_nc
    else
      zpseus = zpseu
    endif      
    rs = r
    rabs = rab
    betars = betar
    norbf = max(norbf,norbs)
  elseif(lsr.eq.3) then
    norbr = norb
    nocrosr = nocros
    noinsr = noins
    allocate( taunewr(4,norbr) )
    allocate( tblmr(4,norbr) )
    allocate( crosr(norbr, nrzr) )
    if (noncolin) then
      allocate(zpseur_nc(2, norbr, norbr, nspin))
    else
      allocate( zpseur(2, norbr, norbr) )
    endif
    taunewr = taunew
    tblmr = tblm
    crosr = cros
    if (noncolin) then
      zpseur_nc = zpseu_nc
    else
      zpseur = zpseu
    endif
    rr = r
    rabr = rab
    betarr = betar
    norbf = max(norbf,norbr)
  endif
!---------------------------

  deallocate (orbind)
  deallocate (taunew)
  deallocate (tblm)
  deallocate (natih)
  deallocate (cros)
  if (noncolin) then
    deallocate (zpseu_nc)
  else
    deallocate (zpseu)
  endif
  return
end subroutine init_orbitals


