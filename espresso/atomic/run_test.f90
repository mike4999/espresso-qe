!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!---------------------------------------------------------------
subroutine run_test
  !
  !   This routine is a driver to the tests of the pseudopotential
  !---------------------------------------------------------------
  !
  use io_global, only : ionode, ionode_id
  use mp,        only : mp_bcast

  use ld1inc
  implicit none

  real(DP) :: oc_old(nwfx)

  integer  &
       n, &  ! counter on wavefunctions
       n1,&  ! counter on mesh points
       ir,&  ! counter on mesh points
       im,&  ! position of the maximum
       nc    ! counter on configurations
  integer :: ios
  character(len=1) :: nch
  real(DP) :: dum

  do n=1,nwf
     oc_old(n)=oc(n)
  enddo

  file_tests = trim(prefix)//'.test'
  if (ionode) &
     open(unit=13, file=file_tests, iostat=ios, err=1111, status='unknown')
1111 call mp_bcast(ios, ionode_id)
     call errore('ld1_setup','opening file_tests',abs(ios))

  do nc=1,nconf
     if (nconf == 1) then
        file_wavefunctions  = trim(prefix)//'.wfc'
        file_wavefunctionsps= trim(prefix)//'ps.wfc'
        file_logder   = trim(prefix)//'.dlog'
        file_logderps = trim(prefix)//'ps.dlog'
     else
        if (nc < 10) then
           write (nch, '(i1)') nc 
        else
           nch='0'
           call errore ('run_test', &
                'results for some configs not written to file',-1)
        endif
        file_wavefunctions  = trim(prefix)//nch//'.wfc'
        file_wavefunctionsps= trim(prefix)//nch//'ps.wfc'
        file_logder   = trim(prefix)//nch//'.dlog'
        file_logderps = trim(prefix)//nch//'ps.dlog'
     endif
     nwfts=nwftsc(nc)
     do n=1,nwf
        oc(n)=oc_old(n)
     enddo
     do n=1,nwfts
        nnts(n)=nntsc(n,nc)
        llts(n)=lltsc(n,nc)
        elts(n)=eltsc(n,nc)
        jjts(n)=jjtsc(n,nc)
        iswts(n)=iswtsc(n,nc)
        octs(n)=octsc(n,nc)
        if (rel==2) jjts(n)=jjtsc(n,nc)
        nstoaets(n)=nstoaec(n,nc)
        oc(nstoaets(n))=octs(n)
     enddo
     call all_electron(.true.)
     if (nc.eq.1) etot0=etot
     !
     !   choose the cut-off radius for the initial estimate of the wavefunctions
     !   find the maximum of the all electron wavefunction
     !
     do n=1,nwfts
        do n1=1,nbeta
           if (els(n1).eq.elts(n).and.rcut(n1).gt.1.e-3_dp) then
              rcutts(n)=rcut(n1)
              rcutusts(n)=rcutus(n1)
              goto 20
           endif
        enddo
        dum=0.0_dp
        im=2
        do ir=1,grid%mesh-1
           dum=abs(psi(ir+1,1,nstoaets(n)))
           if(dum.gt.abs(psi(ir,1,nstoaets(n)))) im=ir+1
        enddo
        if (pseudotype.lt.3) then
           rcutts(n)=grid%r(im)*1.1_dp
           rcutusts(n)=grid%r(im)*1.1_dp
           if (el(nstoaets(n)).eq.'6S') then
              rcutts(n)=grid%r(im)*1.2_dp
              rcutusts(n)=grid%r(im)*1.2_dp
           endif
        else
           if (ll(nstoaets(n)).eq.0) then
              rcutts(n)=grid%r(im)*1.6_dp
              rcutusts(n)=grid%r(im)*1.7_dp
           elseif (ll(nstoaets(n)).eq.1) then
              rcutts(n)=grid%r(im)*1.6_dp
              rcutusts(n)=grid%r(im)*1.7_dp
              if (el(nstoaets(n)).eq.'2P') then
                 rcutts(n)=grid%r(im)*1.7_dp
                 rcutusts(n)=grid%r(im)*1.8_dp
              endif
           elseif (ll(nstoaets(n)).eq.2) then
              rcutts(n)=grid%r(im)*2.0_dp
              rcutusts(n)=grid%r(im)*2.2_dp
              if (el(nstoaets(n)).eq.'3D') then
                 rcutts(n)=grid%r(im)*2.5_dp
                 if (zed>28) then
                    rcutusts(n)=grid%r(im)*3.4_dp
                 else
                    rcutusts(n)=grid%r(im)*3.0_dp
                 endif
              endif
           endif
        endif
20   continue
!     write(6,*) n, rcutts(n), rcutusts(n)
     enddo
     !
     !   and run the pseudopotential test
     !
     call run_pseudo
     !
     if (nc.eq.1) etots0=etots
     !
     !   print results
     !
     call write_resultsps 
     !
     call test_bessel ( )
     !
  enddo
  if (ionode) close (unit = 13)  

  return
end subroutine run_test
