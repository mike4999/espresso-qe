!
! Copyright (C) 2002-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
#include "machine.h"
#undef DEBUG
!-----------------------------------------------------------------------
subroutine mix_rho (rhout, rhoin, nsout, nsin, alphamix, dr2, iter, &
                    n_iter, filename, conv)
  !-----------------------------------------------------------------------
  !
  ! Modified Broyden's method for charge density mixing
  !             d.d. johnson prb 38, 12807 (1988)
  ! On output: the mixed density is in rhoin, rhout is UNCHANGED
  !
  use parameters, only : DP
  use pwcom
  !
  !   First the I/O variable
  !
  character (len=42) ::  &
                filename     !  (in) I/O filename for mixing history
                             !  if absent everything is kept in memory
  integer ::    &
                iter,       &!  (in)  counter of the number of iterations
                n_iter       !  (in)  numb. of iterations used in mixing

  real (kind=DP) :: &
                rhout(nrxx,nspin), &! (in) the "out" density; (out) rhout-rhoin
                rhoin(nrxx,nspin), &! (in) the "in" density; (out) the new dens.
                nsout(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat), &!
                nsin(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat),  &!
                alphamix,          &! (in) mixing factor
                dr2                 ! (out) the estimated errr on the energy

  logical ::    &
                conv        ! (out) if true the convergence has been reached
  !
  integer, parameter :: &
                maxmix =25  ! max number of iterations for charge mixing

  !
  !   Here the local variables
  !
  integer ::    &
                iunmix,    &! I/O unit number of charge density file
                iunmix2,   &! I/O unit number of ns file
                iunit,     &! counter on I/O unit numbers
                iter_used, &! actual number of iterations used
                ipos,      &! index of the present iteration
                inext,     &! index of the next iteration
                i, j,      &! counters on number of iterations
                is,        &! counter on spin component
                ig,        &! counter on G-vectors
                iwork(maxmix),&! dummy array used as output by libr. routines
                info        ! flag saying if the exec. of libr. routines was ok

  complex (kind=DP), allocatable :: rhocin(:,:), rhocout(:,:), &
                rhoinsave(:), rhoutsave(:), &
                nsinsave(:,:,:,:),  nsoutsave(:,:,:,:)
  complex (kind=DP), allocatable, save :: df(:,:), dv(:,:), &
                                      df_ns(:,:,:,:,:), dv_ns(:,:,:,:,:)
                ! rhocin(ngm0,nspin)
                ! rhocout(ngm0,nspin)
                ! rhoinsave(ngm0*nspin): work space
                ! rhoutsave(ngm0*nspin): work space
                ! df(ngm0*nspin,n_iter): information from preceding iterations
                ! dv(ngm0*nspin,n_iter):    "  "       "     "        "  "
                ! df_ns(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat,n_iter):idem
                ! dv_ns(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat,n_iter):idem

  integer :: ldim

  real (kind=DP) :: betamix(maxmix,maxmix), gamma0, work(maxmix), dehar

  logical ::    &
                saveonfile, &! save intermediate steps on file "filename"
                opnd,       &! if true the file is already opened
                exst         ! if true the file exists

  real (kind=DP), external :: rho_dot_product, ns_dot_product, fn_dehar

  call start_clock('mix_rho')

  if (iter < 1) call errore('mix_rho','iter is wrong',1)
  if (n_iter > maxmix) call errore('mix_rho','n_iter too big',1)
  if (lda_plus_u) ldim = 2 * Hubbard_lmax + 1

  saveonfile=filename.ne.' '

!  call DAXPY(nrxx*nspin,-1.d0,rhoin,1,rhout,1)

  allocate(rhocin(ngm0,nspin), rhocout(ngm0,nspin))
  !
  ! psic is used as work space - must be already allocated !
  !
  do is=1,nspin
     psic(:) = DCMPLX (rhoin(:,is), 0.d0)
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
     do ig=1,ngm0
        rhocin(ig,is) = psic(nl(ig))
     end do
     psic(:) = DCMPLX (rhout(:,is), 0.d0)
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
     do ig=1,ngm0
        rhocout(ig,is) = psic(nl(ig)) - rhocin(ig,is)
     end do
  end do
  if (lda_plus_u) nsout(:,:,:,:) = nsout(:,:,:,:) - nsin(:,:,:,:)

  dr2=rho_dot_product(rhocout,rhocout) + ns_dot_product(nsout,nsout)
  conv = (dr2 < tr2)
  dehar = fn_dehar(rhocout)
#ifdef DEBUG
!  if (lda_plus_u) write (6,*) ' ns_dr2 =', ns_dot_product(nsout,nsout)
  if (conv) then
     write (6,100) dr2, rho_dot_product(rhocout,rhocout) + &
                        ns_dot_product(nsout,nsout)
     write (6,'(" dehar =",f15.8)') dehar
  end if
#endif

  if (saveonfile) then
     do iunit=99,1,-1
        inquire(unit=iunit,opened=opnd)
        iunmix=iunit
        if (.not.opnd) go to 10
     end do
     call errore('mix_rho','free unit not found?!?',1)
10   continue
     if (lda_plus_u) then
        do iunit=iunmix-1,1,-1
           inquire(unit=iunit,opened=opnd)
           iunmix2=iunit
           if (.not.opnd) go to 20
        end do
        call errore('mix_rho','second free unit not found?!?',1)
20      continue
     end if
     if (conv) then
        call diropn (iunmix, filename, 2*ngm0*nspin, exst)
        close (unit=iunmix, status='delete')
        if (lda_plus_u) then
           call diropn (iunmix2, trim(filename)//'.ns',ldim*ldim*nspin*nat, exst)
           close (unit=iunmix2, status='delete')
        end if
        deallocate (rhocin, rhocout)
        call stop_clock('mix_rho')
        return
     end if

     call diropn(iunmix,filename,2*ngm0*nspin,exst)
     if (lda_plus_u) call diropn (iunmix2, trim(filename)//'.ns',ldim*ldim*nspin*nat, exst)

     if (iter > 1 .and. .not.exst) then
        call errore('mix_rho','file not found, restarting',-1)
        iter=1
     end if
     allocate (df(ngm0*nspin,n_iter), dv(ngm0*nspin,n_iter))
     if (lda_plus_u) &
        allocate (df_ns(ldim,ldim,nspin,nat,n_iter), &
                  dv_ns(ldim,ldim,nspin,nat,n_iter))
  else
     if (iter == 1) then
        allocate (df(ngm0*nspin,n_iter), dv(ngm0*nspin,n_iter))
        if (lda_plus_u) &
           allocate (df_ns(ldim,ldim,nspin,nat,n_iter),&
                     dv_ns(ldim,ldim,nspin,nat,n_iter))
     end if
     if (conv) then
        if (lda_plus_u) deallocate(df_ns, dv_ns)
        deallocate (df, dv)
        deallocate (rhocin, rhocout)
        call stop_clock('mix_rho')
        return
     end if
     allocate (rhoinsave(ngm0*nspin), rhoutsave(ngm0*nspin))
     if (lda_plus_u) &
        allocate(nsinsave (ldim,ldim,nspin,nat), &
                 nsoutsave(ldim,ldim,nspin,nat))
  end if
  !
  ! copy only the high frequency Fourier component into rhoin
  !                                                (NB: rhout=rhout-rhoin)
  !
  call DCOPY(nrxx*nspin,rhout,1,rhoin,1)
  do is=1,nspin
     psic(:) = (0.d0, 0.d0)
     do ig=1,ngm0
        psic(nl(ig)) = rhocin(ig,is)+rhocout(ig,is)
     end do
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
     call DAXPY(nrxx,-1.d0,psic,2,rhoin(1,is),1)
  end do
  !
  ! iter_used = iter-1  if iter <= n_iter
  ! iter_used = n_iter  if iter >  n_iter
  !
  iter_used=min(iter-1,n_iter)
  !
  ! ipos is the position in which results from the present iteration
  ! are stored. ipos=iter-1 until ipos=n_iter, then back to 1,2,...
  !
  ipos =iter-1-((iter-2)/n_iter)*n_iter
  !
  if (iter > 1) then
     if (saveonfile) then
        call davcio(df(1,ipos),2*ngm0*nspin,iunmix,1,-1)
        call davcio(dv(1,ipos),2*ngm0*nspin,iunmix,2,-1)
        if (lda_plus_u) then
           call davcio(df_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,1,-1)
           call davcio(dv_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,2,-1)
        end if
     end if
        call DAXPY(2*ngm0*nspin,-1.d0,rhocout,1,df(1,ipos),1)
        call DAXPY(2*ngm0*nspin,-1.d0,rhocin ,1,dv(1,ipos),1)
!        norm = sqrt(rho_dot_product(df(1,ipos),df(1,ipos)) + &
!                    ns_dot_product(df_ns(1,1,1,1,ipos),df_ns(1,1,1,1,ipos)) )
!        call DSCAL (2*ngm0*nspin,-1.d0/norm,df(1,ipos),1)
!        call DSCAL (2*ngm0*nspin,-1.d0/norm,dv(1,ipos),1)
     if (lda_plus_u) then
        call DAXPY(ldim*ldim*nspin*nat,-1.d0,nsout,1,df_ns(1,1,1,1,ipos),1)
        call DAXPY(ldim*ldim*nspin*nat,-1.d0,nsin ,1,dv_ns(1,1,1,1,ipos),1)
     end if
  end if
  !
  if (saveonfile) then
     do i=1,iter_used
        if (i.ne.ipos) then
           call davcio(df(1,i),2*ngm0*nspin,iunmix,2*i+1,-1)
           call davcio(dv(1,i),2*ngm0*nspin,iunmix,2*i+2,-1)
           if (lda_plus_u) then
              call davcio(df_ns(1,1,1,1,i),ldim*ldim*nspin*nat,iunmix2,2*i+1,-1)
              call davcio(dv_ns(1,1,1,1,i),ldim*ldim*nspin*nat,iunmix2,2*i+2,-1)
           end if
        end if
     end do
     call davcio(rhocout,2*ngm0*nspin,iunmix,1,1)
     call davcio(rhocin ,2*ngm0*nspin,iunmix,2,1)
     if (iter > 1) then
        call davcio(df(1,ipos),2*ngm0*nspin,iunmix,2*ipos+1,1)
        call davcio(dv(1,ipos),2*ngm0*nspin,iunmix,2*ipos+2,1)
     end if
     if (lda_plus_u) then
        call davcio(nsout,ldim*ldim*nspin*nat,iunmix2,1,1)
        call davcio(nsin ,ldim*ldim*nspin*nat,iunmix2,2,1)
        if (iter > 1) then
           call davcio(df_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,2*ipos+1,1)
           call davcio(dv_ns(1,1,1,1,ipos),ldim*ldim*nspin*nat,iunmix2,2*ipos+2,1)
        end if
     end if
  else
     call DCOPY(2*ngm0*nspin,rhocin ,1,rhoinsave,1)
     call DCOPY(2*ngm0*nspin,rhocout,1,rhoutsave,1)
     if (lda_plus_u) then
        call DCOPY(ldim*ldim*nspin*nat,nsin ,1,nsinsave ,1)
        call DCOPY(ldim*ldim*nspin*nat,nsout,1,nsoutsave,1)
     end if
  end if
  !
  do i=1,iter_used
     do j=i,iter_used
        betamix(i,j) = rho_dot_product(df(1,j),df(1,i)) + &
                       ns_dot_product(df_ns(1,1,1,1,j),df_ns(1,1,1,1,i))
     end do
  end do
  !
  call DSYTRF ('U',iter_used,betamix,maxmix,iwork,work,maxmix,info)
  call errore('broyden','factorization',info)
  call DSYTRI ('U',iter_used,betamix,maxmix,iwork,work,info)
  call errore('broyden','DSYTRI',info)
  !
  do i=1,iter_used
     do j=i+1,iter_used
        betamix(j,i)=betamix(i,j)
     end do
  end do
  !
  do i=1,iter_used
     work(i) = rho_dot_product(df(1,i),rhocout) + &
               ns_dot_product(df_ns(1,1,1,1,i),nsout)
  end do
  !
  do i=1,iter_used
     gamma0=0.d0
     do j=1,iter_used
        gamma0 = gamma0 + betamix(j,i)*work(j)
     end do

     call DAXPY(2*ngm0*nspin,-gamma0,dv(1,i),1,rhocin,1)
     call DAXPY(2*ngm0*nspin,-gamma0,df(1,i),1,rhocout,1)
     if (lda_plus_u) then
        call DAXPY(ldim*ldim*nspin*nat,-gamma0,dv_ns(1,1,1,1,i),1,nsin(1,1,1,1) ,1)
        call DAXPY(ldim*ldim*nspin*nat,-gamma0,df_ns(1,1,1,1,i),1,nsout(1,1,1,1),1)
     end if
  end do
  !
#ifdef DEBUG
  write (6,100) dr2, rho_dot_product(rhocout,rhocout) + &
                     ns_dot_product(nsout,nsout)
  write (6,'(" dehar =",f15.8)') dehar
#endif
100  format (' dr2 =',1pe15.1, ' internal_best_dr2= ', 1pe15.1)

  ! - auxiliary vectors dv and df not needed anymore
  if (saveonfile) then
     if (lda_plus_u) then
        close(iunmix2,status='keep')
        deallocate (df_ns, dv_ns)
     end if
     close(iunmix,status='keep')
     deallocate (df, dv)
  else
     inext=iter-((iter-1)/n_iter)*n_iter
     if (lda_plus_u) then
        call DCOPY(ldim*ldim*nspin*nat,nsoutsave,1,df_ns(1,1,1,1,inext),1)
        call DCOPY(ldim*ldim*nspin*nat,nsinsave ,1,dv_ns(1,1,1,1,inext),1)
        deallocate (nsinsave, nsoutsave)
     end if
     call DCOPY(2*ngm0*nspin,rhoutsave,1,df(1,inext),1)
     call DCOPY(2*ngm0*nspin,rhoinsave,1,dv(1,inext),1)
     deallocate (rhoinsave, rhoutsave)
  end if

  ! - preconditioning the new search direction (if imix.gt.0)

  if (imix == 1) then
     call approx_screening(rhocout)
  else if (imix == 2) then
     call approx_screening2(rhocout,rhocin)
  end if

  ! - set new trial density

  call DAXPY(2*ngm0*nspin,alphamix,rhocout,1,rhocin,1)

  do is=1,nspin
     psic(:) = (0.d0,0.d0)
     do ig=1,ngm0
        psic(nl(ig)) = rhocin(ig,is)
     end do
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
     call DAXPY(nrxx,1.d0,psic,2,rhoin(1,is),1)
  end do
  if (lda_plus_u) call DAXPY(ldim*ldim*nspin*nat,alphamix,nsout,1,nsin,1)

  ! - clean up

  deallocate(rhocout)
  deallocate(rhocin)
  call stop_clock('mix_rho')

  return
end subroutine mix_rho

!
!--------------------------------------------------------------------
function rho_dot_product (rho1,rho2)
  !--------------------------------------------------------------------
  ! this function evaluates the dot product between two input densities
  !
  use parameters, only : DP
  use pwcom
  !
  ! I/O variables
  !
  real (kind=DP) :: rho_dot_product ! (out) the function value

  complex (kind=DP) :: rho1(ngm0,nspin), rho2(ngm0,nspin) ! (in) the two densities

  !
  ! and the local variables
  !
  real (kind=DP) :: fac   ! a multiplicative factors

  integer  :: is, ig

  rho_dot_product = 0.d0
  if (nspin.eq.1) then
     is=1
     do ig = gstart,ngm0
        fac = e2*fpi / (tpiba2*gg(ig))
        rho_dot_product = rho_dot_product +  fac * &
                          DREAL(conjg(rho1(ig,is))*rho2(ig,is))
     end do
  else
     do ig = gstart,ngm0
        fac = e2*fpi / (tpiba2*gg(ig))
        rho_dot_product = rho_dot_product +  fac * &
                          DREAL(conjg(rho1(ig,1)+rho1(ig,2))* &
                                     (rho2(ig,1)+rho2(ig,2)))
     end do
     fac = e2*fpi / (tpi**2)  ! lambda=1 a.u.
     do ig = 1,ngm0
        rho_dot_product = rho_dot_product +  fac * &
                          DREAL(conjg(rho1(ig,1)-rho1(ig,2))* &
                                     (rho2(ig,1)-rho2(ig,2)))
     end do
  end if

  rho_dot_product = rho_dot_product * omega / 2.d0
#ifdef __PARA
  call reduce(1,rho_dot_product)
#endif

  return
end function rho_dot_product

!
!--------------------------------------------------------------------
function ns_dot_product (ns1,ns2)
  !--------------------------------------------------------------------
  ! this function evaluates the dot product between two input densities
  !
  use parameters, only : DP
  use pwcom
  !
  ! I/O variables
  !
  real (kind=DP) :: ns_dot_product ! (out) the function value

  real (kind=DP) :: ns1(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat), &
                    ns2(2*Hubbard_lmax+1,2*Hubbard_lmax+1,nspin,nat) 
                    ! (in) the two ns 
  !
  ! and the local variables
  !
  real (kind=DP) :: sum
  integer  :: na, nt, is, m1, m2

  ns_dot_product = 0.d0
  if (.not. lda_plus_u ) return

  do na = 1, nat
     nt = ityp (na)
     if (Hubbard_U(nt).ne.0.d0 .or. Hubbard_alpha(nt).ne.0.d0) then
        sum =0.d0
        do is = 1,nspin
           do m1 = 1, 2 * Hubbard_l(nt) + 1
              do m2 = m1, 2 * Hubbard_l(nt) + 1
                 sum = sum + ns1(m1,m2,is,na)*ns2(m2,m1,is,na)
              enddo
           enddo
        end do
        ns_dot_product = ns_dot_product + 0.5d0*Hubbard_U(nt) * sum
     endif
  end do
  if (nspin.eq.1) ns_dot_product = 2.d0 * ns_dot_product

  return
end function ns_dot_product

!--------------------------------------------------------------------
function fn_dehar (drho)
  !--------------------------------------------------------------------
  ! this function evaluates the residual hartree energy of drho
  !
  use parameters, only : DP
  use pwcom
  !
  ! I/O variables
  !
  real (kind=DP) :: fn_dehar ! (out) the function value

  complex (kind=DP) :: drho(ngm0,nspin) ! (in) the density difference

  !
  ! and the local variables
  !
  real (kind=DP) :: fac   ! a multiplicative factors

  integer  :: is, ig

  fn_dehar = 0.d0
  if (nspin == 1) then
     is=1
     do ig = gstart,ngm0
        fac = e2*fpi / (tpiba2*gg(ig))
        fn_dehar = fn_dehar +  fac * abs(drho(ig,is))**2
     end do
  else
     do ig = gstart,ngm0
        fac = e2*fpi / (tpiba2*gg(ig))
        fn_dehar = fn_dehar +  fac * abs(drho(ig,1)+drho(ig,2))**2
     end do
  end if

  fn_dehar = fn_dehar * omega / 2.d0

#ifdef __PARA
  call reduce(1,fn_dehar)
#endif

  return
end function fn_dehar

!--------------------------------------------------------------------
subroutine approx_screening (drho)
  !--------------------------------------------------------------------
  ! apply an average TF preconditioning to drho
  !
  use parameters, only : DP
  use pwcom
  !
  ! I/O
  !
  complex (kind=DP) drho(ngm0,nspin) ! (in/out)
  !
  ! and the local variables
  !
  real (kind=DP) :: rrho, rmag, rs, agg0

  integer :: is, ig

  rs = (3.d0*omega/fpi/nelec)**(1.d0/3.d0)
  agg0 = (12.d0/pi)**(2.d0/3.d0)/tpiba2/rs

#ifdef DEBUG
  write (6,'(a,f12.6,a,f12.6)') ' avg rs  =', rs, ' avg rho =', nelec/omega
#endif

  if (nspin == 1) then
     is = 1
     do ig = 1,ngm0
        drho(ig,is) =  drho(ig,is) * gg(ig)/(gg(ig)+agg0)
     end do
  else
     do ig = 1,ngm0
        rrho = (drho(ig,1) + drho(ig,2)) * gg(ig)/(gg(ig)+agg0)
        rmag = (drho(ig,1) - drho(ig,2))
        drho(ig,1) =  0.5d0 * (rrho + rmag)
        drho(ig,2) =  0.5d0 * (rrho - rmag)
     end do
  end if

  return
end subroutine approx_screening

!
!--------------------------------------------------------------------
  subroutine approx_screening2 (drho,rhobest)
  !--------------------------------------------------------------------
  ! apply a local-density dependent TF preconditioning to drho
  !
  use parameters, only : DP
  use pwcom
  !
  ! I/O
  !
  !
  complex (kind=DP) ::  drho(ngm0,nspin), rhobest(ngm0,nspin)
  !
  !    and the local variables
  !
  integer :: mmx
  parameter (mmx=12)
  integer :: iwork(mmx),i,j,m,info, nspin_save
  real (kind=DP) :: rs, min_rs, max_rs, avg_rsm1, target, &
                    dr2_best, ccc, cbest, l2smooth
  real (kind=DP) :: aa(mmx,mmx), invaa(mmx,mmx), bb(mmx), work(mmx), &
                    vec(mmx),agg0
  complex (kind=DP) :: rrho, rmag

  complex (kind=DP), allocatable :: v(:,:), w(:,:), dv(:), &
                                vbest(:), wbest(:)
  ! v(ngm0,mmx), w(ngm0,mmx), dv(ngm0), vbest(ngm0), wbest(ngm0)
  real (kind=DP), allocatable :: alpha(:)
  ! alpha(nrxx)

  integer :: is, ir, ig

  real (kind=DP), external :: rho_dot_product

  if (nspin == 2) then
     do ig=1,ngm0
        rrho       = drho(ig,1) + drho(ig,2)
        rmag       = drho(ig,1) - drho(ig,2)
        drho(ig,1) = rrho
        drho(ig,2) = rmag
     end do
  end if

  nspin_save = nspin
  nspin = 1
  is = 1
  target = 0.d0

!  write (6,*) ' eccoci qua '

  if (gg(1) < 1.d-8) drho(1,is) = (0.d0,0.d0)

  allocate (alpha(nrxx), v(ngm0,mmx), w(ngm0,mmx), &
            dv(ngm0), vbest(ngm0), wbest(ngm0))

  v(:,:) = (0.d0,0.d0)
  w(:,:) = (0.d0,0.d0)
  dv(:) = (0.d0,0.d0)
  vbest(:)= (0.d0,0.d0)
  wbest(:)= (0.d0,0.d0)

  !
  ! - calculate alpha from density smoothed with a lambda=0 a.u.
  !
  l2smooth = 0.d0
  psic(:) = (0.d0,0.d0)
  if (nspin == 1) then
     do ig=1,ngm0
        psic(nl(ig)) = rhobest(ig,1) * exp(-0.5*l2smooth*tpiba2*gg(ig))
     end do
  else
     do ig=1,ngm0
        psic(nl(ig)) =(rhobest(ig,1) + rhobest(ig,2)) &
                                    * exp(-0.5*l2smooth*tpiba2*gg(ig))
     end do
  end if
  call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
  alpha(:) = real(psic(:))

  min_rs = (3.d0*omega/fpi/nelec)**(1.d0/3.d0)
  max_rs = min_rs
  avg_rsm1 = 0.d0

  do ir=1,nrxx

     alpha(ir)=abs(alpha(ir))
     rs = (3.d0/fpi/alpha(ir))**(1.d0/3.d0)

     min_rs = min(min_rs,rs)
     avg_rsm1 =avg_rsm1 + 1.d0/rs
     max_rs = max(max_rs,rs)

     alpha(ir) = rs

  end do

#ifdef __PARA
  call reduce  (1, avg_rsm1)
  call extreme (min_rs, -1)
  call extreme (max_rs, +1)
#endif

  call DSCAL(nrxx, 3.d0*(tpi/3.d0)**(5.d0/3.d0), alpha, 1)

  avg_rsm1 = (nr1*nr2*nr3)/avg_rsm1
  rs = (3.d0*omega/fpi/nelec)**(1.d0/3.d0)
  agg0 = (12.d0/pi)**(2.d0/3.d0)/tpiba2/avg_rsm1
#ifdef DEBUG
  write (6,'(a,5f12.6)') ' min/avgm1/max rs  =', min_rs,avg_rsm1,max_rs,rs
#endif

  !
  ! - calculate deltaV and the first correction vector
  !
  psic(:) = (0.d0,0.d0)
  do ig=1,ngm0
     psic(nl(ig)) = drho(ig,is)
  end do
  call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
  do ir=1,nrxx
    psic(ir) = psic(ir) * alpha(ir)
  end do
  call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
  do ig=1,ngm0
     dv(ig) = psic(nl(ig))*gg(ig)*tpiba2
     v(ig,1)= psic(nl(ig))*gg(ig)/(gg(ig)+agg0)
  end do
  m=1
  ccc = rho_dot_product(dv,dv)
  aa(:,:) = 0.d0
  bb(:) = 0.d0

3 continue
  !
  ! - generate the vector w
  !
  do ig=1,ngm0
     w(ig,m) = gg(ig)*tpiba2*v(ig,m)
  end do
  psic(:) = (0.d0,0.d0)
  do ig=1,ngm0
     psic(nl(ig)) = v(ig,m)
  end do
  call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
  do ir=1,nrxx
     psic(ir) = psic(ir)*fpi*e2/alpha(ir)
  end do
  call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
  do ig=1,ngm0
     w(ig,m) = w(ig,m) + psic(nl(ig))
  end do

  !
  ! - build the linear system
  !
  do i=1,m
     aa(i,m) = rho_dot_product(w(1,i),w(1,m))
     aa(m,i) = aa(i,m)
  end do
  bb(m) = rho_dot_product(w(1,m),dv)

  !
  ! - solve it -> vec
  !
  call DCOPY (mmx*mmx,aa,1,invaa,1)
  call DSYTRF ('U',m,invaa,mmx,iwork,work,mmx,info)
  call errore('BROYDEN','factorization',info)
  call DSYTRI ('U',m,invaa,mmx,iwork,work,info)
  call errore('broyden','DSYTRI',info)
  !
  do i=1,m
     do j=i+1,m
        invaa(j,i)=invaa(i,j)
     end do
  end do
  do i=1,m
     vec(i) = 0.d0
     do j=1,m
        vec(i) = vec(i) + invaa(i,j)*bb(j)
     end do
  end do
  ! -
  vbest(:) = (0.d0,0.d0)
  wbest(:) = dv(:)
  do i=1,m
     call DAXPY(2*ngm0, vec(i), v(1,i),1, vbest,1)
     call DAXPY(2*ngm0,-vec(i), w(1,i),1, wbest,1)
  end do

  cbest = ccc
  do i=1,m
     cbest = cbest - bb(i)*vec(i)
  end do

  dr2_best= rho_dot_product(wbest,wbest)
  if (target == 0.d0) target = 1.d-6 * dr2_best
!  write (6,*) m, dr2_best, cbest

  if (dr2_best < target) then
!     write(6,*) ' last', dr2_best/target * 1.d-6
     psic(:) = (0.d0,0.d0)
     do ig=1,ngm0
        psic(nl(ig)) = vbest(ig)
     end do
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,+1)
     do ir=1,nrxx
        psic(ir) = psic(ir)/alpha(ir)
     end do
     call cft3(psic,nr1,nr2,nr3,nrx1,nrx2,nrx3,-1)
     do ig=1,ngm0
        drho(ig,is) = psic(nl(ig))
     end do
     nspin = nspin_save
     if (nspin == 2) then
        do ig=1,ngm0
           rrho = drho(ig,1)
           rmag = drho(ig,2)
           drho(ig,1) = 0.5d0 * ( rrho + rmag )
           drho(ig,2) = 0.5d0 * ( rrho - rmag )
        end do
     end if
     deallocate (alpha, v, w, dv, vbest, wbest)
     return
  else if (m >= mmx) then
!     write (6,*) m, dr2_best, cbest
     m=1
     do ig=1,ngm0
        v(ig,m)=vbest(ig)
     end do
     aa(:,:) = 0.d0
     bb(:) = 0.d0
     go to 3
  end if

  m = m + 1
  do ig=1,ngm0
     v(ig,m)=wbest(ig)/(gg(ig)+agg0)
  end do

  go to 3

end subroutine approx_screening2
