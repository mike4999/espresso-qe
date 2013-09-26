!
! Copyright (C) 2001-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!

!
#include "f_defs.h"


module wannier_gw
  USE kinds, ONLY: DP
  
  SAVE
  LOGICAL :: l_head!if true calculates the head of the symmetrized dielectric matrix -1
  INTEGER :: n_gauss!number of frequency steps for head calculation
  REAL(kind=DP) :: omega_gauss!period for frequency calculation
  INTEGER :: grid_type!0 GL -T,T 2 GL 0 T 3 Equally spaced 0 Omega
  INTEGER :: nsteps_lanczos!number of lanczos steps
    !options for grid_freq=5
  INTEGER :: second_grid_n!sub spacing for second grid
  INTEGER :: second_grid_i!max regular step using the second grid
  LOGICAL :: l_scissor!if true displaces occupied manifold of scissor
  REAL(kind=DP) :: scissor!see above

end module wannier_gw

!
!-----------------------------------------------------------------------
subroutine solve_head
  !-----------------------------------------------------------------------
  !
  !calculates the head and wings of the dielectric matrix
  !
  USE ions_base,             ONLY : nat
  USE io_global,             ONLY : stdout, ionode,ionode_id
  USE io_files,              ONLY : diropn,prefix, iunigk
  use pwcom
  USE check_stop,            ONLY : max_seconds
  USE wavefunctions_module,  ONLY : evc
  USE kinds,                 ONLY : DP
  USE becmod,                ONLY : becp,calbec
  USE uspp_param,            ONLY : nhm
  use phcom
  USE wannier_gw,            ONLY : n_gauss, omega_gauss, grid_type, nsteps_lanczos,second_grid_n,second_grid_i,&
                                      &l_scissor,scissor
  USE control_ph,            ONLY : tr2_ph
  USE gvect,                 ONLY : ig_l2g
  USE mp,           ONLY : mp_sum, mp_barrier, mp_bcast
  USE mp_world, ONLY : world_comm
  USE uspp,                 ONLY : nkb, vkb
!  USE symme, ONLY: s
  USE mp_global,             ONLY : inter_pool_comm, intra_pool_comm
  USE symme, only : crys_to_cart, symmatrix
  USE mp_wave, ONLY : mergewf,splitwf
  USE mp_global, ONLY : mpime, nproc, intra_pool_comm
  USE fft_base,             ONLY : dfftp, dffts
  USE fft_interfaces,       ONLY : fwfft, invfft
  USE buffers,               ONLY : get_buffer
  USE constants,            ONLY : rytoev

  implicit none

  INTEGER, EXTERNAL :: find_free_unit

  real(DP) ::  thresh, anorm, averlt, dr2
  ! thresh: convergence threshold
  ! anorm : the norm of the error
  ! averlt: average number of iterations
  ! dr2   : self-consistency error
 
 

 
  complex(DP) , allocatable ::    ps (:,:)

  complex(DP), EXTERNAL :: ZDOTC      ! the scalar product function

  logical :: conv_root, exst
  ! conv_root: true if linear system is converged

  integer :: kter, iter0, ipol,jpol, ibnd, jbnd, iter, lter, &
       ik, ig, irr, ir, is, nrec, ios
  ! counters
  integer :: ltaver, lintercall

  real(DP) :: tcpu, get_clock
  ! timing variables

  
  ! the name of the file with the mixing potential

  external ch_psi_all, cg_psi

  REAL(kind=DP), ALLOCATABLE :: head(:,:),head_tmp(:)
  COMPLEX(kind=DP) :: sca, sca2
  REAL(kind=DP), ALLOCATABLE :: x(:),w(:), freqs(:)
  COMPLEX(kind=DP), ALLOCATABLE :: e_head(:,:)!wing of symmetric dielectric matrix (for G of local processor)
  COMPLEX(kind=DP), ALLOCATABLE :: e_head_g(:),e_head_g_tmp(:,:,:)
  COMPLEX(kind=DP), ALLOCATABLE :: e_head_pol(:,:,:)
  INTEGER :: i, j,k,iun
  REAL(kind=DP) :: ww, weight
  COMPLEX(kind=DP), ALLOCATABLE :: tmp_g(:)
  COMPLEX(kind=DP), ALLOCATABLE :: psi_v(:,:), prod(:)
  COMPLEX(kind=DP), ALLOCATABLE :: pola_charge(:,:,:,:)
  COMPLEX(kind=DP), ALLOCATABLE :: dpsi_ipol(:,:,:)
  REAL(kind=DP), ALLOCATABLE :: epsilon_g(:,:,:)
  INTEGER :: i_start,idumm,idumm1,idumm2,idumm3,ii
  REAL(kind=DP) :: rdumm
  COMPLEX(kind=DP), ALLOCATABLE :: d(:,:),f(:,:),omat(:,:,:)
  INTEGER :: iv, info
  COMPLEX(kind=DP), ALLOCATABLE :: z_dl(:),z_d(:),z_du(:),z_b(:)
  COMPLEX(kind=DP) :: csca, csca1
  COMPLEX(kind=DP), ALLOCATABLE :: t_out(:,:,:), psi_tmp(:)
  INTEGER :: n
  INTEGER :: npwx_g

  write(stdout,*) 'Routine solve_head'
  call flush_unit(stdout)

  if(grid_type==5) then
     n=n_gauss
     n_gauss=n+second_grid_n*(1+second_grid_i*2)
  endif

  allocate(e_head(npw,n_gauss+1))
  allocate(e_head_pol(ngm,n_gauss+1,3))
  e_head(:,:) =(0.d0,0.d0)  
  allocate(x(2*n_gauss+1),w(2*n_gauss+1), freqs(n_gauss+1))
  allocate(head(n_gauss+1,3),head_tmp(n_gauss+1))
  head(:,:)=0.d0
  allocate(psi_v(dffts%nnr, nbnd), prod(dfftp%nnr))
  allocate (tmp_g(ngm))
  allocate( pola_charge(dfftp%nnr,nspin,3,n_gauss+1))
  allocate(epsilon_g(3,3,n_gauss+1))
  allocate(psi_tmp(npwx))




  epsilon_g(:,:,:)=0.d0
  e_head_pol(:,:,:)=0.d0
  pola_charge(:,:,:,:)=0.d0
!setup Gauss Legendre frequency grid
!IT'S OF CAPITAL IMPORTANCE TO NULLIFY THE FOLLOWING ARRAYS
  x(:)=0.d0
  w(:)=0.d0
  if(grid_type==0) then
     call legzo(n_gauss*2+1,x,w)
     freqs(1:n_gauss+1)=-x(n_gauss+1:2*n_gauss+1)*omega_gauss
  else if(grid_type==2) then
     call legzo(n_gauss,x,w)
     freqs(1) = 0.d0
     freqs(2:n_gauss+1)=(1.d0-x(1:n_gauss))*omega_gauss/2.d0
  else if(grid_type==3) then!equally spaced grid
     freqs(1) = 0.d0
     do i=1,n_gauss
        freqs(1+i)=omega_gauss*dble(i)/dble(n_gauss)
     enddo
  else  if(grid_type==4) then!equally spaced grid shifted of 1/2
     freqs(1) = 0.d0
     do i=1,n_gauss
        freqs(i+1)=(omega_gauss/dble(n_gauss))*dble(i)-(0.5d0*omega_gauss/dble(n_gauss))
     enddo
  else!equally spaced grid more dense at -1 , 0 and 1
     freqs(1)=0.d0
          
     ii=2
     do i=1,second_grid_n
        freqs(ii)=(omega_gauss/dble(2*second_grid_n*n))*dble(i)-0.5d0*omega_gauss/dble(2*second_grid_n*n)
        ii=ii+1
     enddo
     do j=1,second_grid_i
        do i=1,second_grid_n
           freqs(ii)=(omega_gauss/dble(2*second_grid_n*n))*dble(i+second_grid_n+2*second_grid_n*(j-1))&
      &-0.5d0*omega_gauss/dble(2*second_grid_n*n)
           ii=ii+1
        enddo
        freqs(ii)=omega_gauss/dble(n)*dble(j)
        ii=ii+1
        do i=1,second_grid_n
           freqs(ii)=(omega_gauss/dble(2*second_grid_n*n))*dble(i+2*second_grid_n*j)&
    &-0.5d0*omega_gauss/dble(2*second_grid_n*n)
           ii=ii+1
        enddo
     enddo
     do i=second_grid_i+1,n
        freqs(ii)=omega_gauss/dble(n)*dble(i)
        ii=ii+1
     enddo
     

!     freqs(1)=0.d0
!     do i=1,10
!        freqs(i+1)=(omega_gauss/dble(10*n))*dble(i)-0.5d0*omega_gauss/dble(10*n)
!     enddo
!     freqs(11+1)=omega_gauss/dble(n)
!     do i=1,5
!        freqs(i+12)=(omega_gauss/dble(10*n))*dble(i)+ omega_gauss/dble(n)-0.5d0*omega_gauss/dble(10*n)
!     enddo
!     do i=2,n
!        freqs(16+i)=(omega_gauss/dble(n))*dble(i)
!     enddo

  endif
  do i=1,n_gauss+1
     write(stdout,*) 'Freq',i,freqs(i)
  enddo
  CALL flush_unit( stdout )
  
  deallocate(x,w)
  head(:,:)=0.d0





  !if (lsda) call errore ('solve_head', ' LSDA not implemented', 1)

  call start_clock ('solve_head')
 
 
 
  allocate (ps  (nbnd,nbnd))    
  ps (:,:) = (0.d0, 0.d0)
 
  
 
  IF (ionode .AND. fildrho /= ' ') THEN
     INQUIRE (UNIT = iudrho, OPENED = exst)
     IF (exst) CLOSE (UNIT = iudrho, STATUS='keep')
     CALL DIROPN (iudrho, TRIM(fildrho)//'.E', lrdrho, exst)
  end if
  !

  !
  ! if q=0 for a metal: allocate and compute local DOS at Ef
  !
  if (degauss.ne.0.d0.or..not.lgamma) call errore ('solve_e', &
       'called in the wrong case', 1)
  !

  !
  !   only one iteration is required
  !

  if(.not.l_scissor) scissor=0.d0

!loop on k points
  if (nksq.gt.1) rewind (unit = iunigk)
  do ik=1, nksq
     allocate (dpsi_ipol(npwx,nbnd_occ(ik),3))
     allocate(t_out(npwx,nsteps_lanczos,nbnd_occ(ik)))
     write(stdout,*) 'ik:', ik
     call flush_unit(stdout)
     weight = wk (ik)
     ww = fpi * weight / omega

     if (lsda) current_spin = isk (ik)
     if (nksq.gt.1) then
        read (iunigk, err = 100, iostat = ios) npw, igk
100     call errore ('solve_head', 'reading igk', abs (ios) )
     endif
     !
     ! reads unperturbed wavefuctions psi_k in G_space, for all bands
     !
    ! if (nksq.gt.1) call davcio (evc, lrwfc, iuwfc, ik, - 1)
    if (nksq.gt.1)  call get_buffer(evc, lrwfc, iuwfc, ik)
     npwq = npw
     call init_us_2 (npw, igk, xk (1, ik), vkb)

     !trasform valence wavefunctions to real space
     do ibnd=1,nbnd
        psi_v(:,ibnd) = ( 0.D0, 0.D0 )
        psi_v(nls(igk(1:npw)),ibnd) = evc(1:npw,ibnd)
        CALL invfft ('Wave',  psi_v(:,ibnd), dffts)
     enddo


     !
     ! compute the kinetic energy
     !
     do ig = 1, npwq
        g2kin (ig) = ( (xk (1,ik ) + g (1,igk (ig)) ) **2 + &
             (xk (2,ik ) + g (2,igk (ig)) ) **2 + &
             (xk (3,ik ) + g (3,igk (ig)) ) **2 ) * tpiba2
     enddo
     !
     dpsi_ipol(:,:,:)=(0.d0,0.d0)


!loop on carthesian directions
     do ipol = 1,3
        write(stdout,*) 'ipol:', ipol
        call flush_unit(stdout)
        !
        ! computes/reads P_c^+ x psi_kpoint into dvpsi array
        !

        do jpol=1,3
         
           call dvpsi_e (ik, jpol)
        
          !
        ! Orthogonalize dvpsi to valence states: ps = <evc|dvpsi>
        !
           CALL ZGEMM( 'C', 'N', nbnd_occ (ik), nbnd_occ (ik), npw, &
                (1.d0,0.d0), evc(1,1), npwx, dvpsi(1,1), npwx, (0.d0,0.d0), &
                ps(1,1), nbnd )
#ifdef __PARA
           !call reduce (2 * nbnd * nbnd_occ (ik), ps)
           call mp_sum(ps(1:nbnd_occ (ik),1:nbnd_occ (ik)))
#endif
        ! dpsi is used as work space to store S|evc>
        !
           !CALL ccalbec (nkb, npwx, npw, nbnd_occ(ik), becp, vkb, evc)
           CALL calbec(npw,vkb,evc,becp,nbnd_occ(ik))
           CALL s_psi (npwx, npw, nbnd_occ(ik), evc, dpsi)
           !
        
        ! |dvpsi> = - (|dvpsi> - S|evc><evc|dvpsi>)
        ! note the change of sign!
           !
           CALL ZGEMM( 'N', 'N', npw, nbnd_occ(ik), nbnd_occ(ik), &
                (1.d0,0.d0), dpsi(1,1), npwx, ps(1,1), nbnd, (-1.d0,0.d0), &
                dvpsi(1,1), npwx )
!create lanczos chain for dvpsi
           dpsi_ipol(1:npw,1:nbnd_occ(ik),jpol)=dvpsi(1:npw,1:nbnd_occ(ik))
        enddo
        dvpsi(1:npw,1:nbnd_occ(ik))=dpsi_ipol(1:npw,1:nbnd_occ(ik),ipol)


        allocate(d(nsteps_lanczos,nbnd_occ(ik)),f(nsteps_lanczos,nbnd_occ(ik)))
        allocate(omat(nsteps_lanczos,3,nbnd_occ(ik)))
        write(stdout,*) 'before lanczos_state_k'
     



        call lanczos_state_k(ik,nbnd_occ(ik), nsteps_lanczos ,dvpsi,d,f,omat,dpsi_ipol,t_out)
        write(stdout,*) 'after lanczos_state_k'
!loop on frequency
        allocate(z_dl(nsteps_lanczos-1),z_d(nsteps_lanczos),z_du(nsteps_lanczos-1),z_b(nsteps_lanczos))
        do i=1,n_gauss+1
!loop on valence states
           do iv=1,nbnd_occ(ik)
!invert Hamiltonian
              z_dl(1:nsteps_lanczos-1)=conjg(f(1:nsteps_lanczos-1,iv))
              z_du(1:nsteps_lanczos-1)=f(1:nsteps_lanczos-1,iv)
              z_d(1:nsteps_lanczos)=d(1:nsteps_lanczos,iv)+dcmplx(-et(iv,ik)-scissor/rytoev,freqs(i))
              z_b(:)=(0.d0,0.d0)
              z_b(1)=dble(omat(1,ipol,iv))
              call zgtsv(nsteps_lanczos,1,z_dl,z_d,z_du,z_b,nsteps_lanczos,info)
              if(info/=0) then
                 write(stdout,*) 'problems with ZGTSV'
                 call flush_unit(stdout)
                 stop
              endif
              do jpol=1,3
!multiply with overlap factors
                 call zgemm('T','N',1,1,nsteps_lanczos,(1.d0,0.d0),omat(:,jpol,iv),nsteps_lanczos&
     &,z_b,nsteps_lanczos,(0.d0,0.d0),csca,1)
!update epsilon array NO SYMMETRIES for the moment
                 epsilon_g(jpol,ipol,i)=epsilon_g(jpol,ipol,i)+4.d0*ww*dble(csca)
              enddo
!update part for wing calculation 
              call zgemm('N','N',npw,1,nsteps_lanczos,(1.d0,0.d0),t_out(:,:,iv),npwx,z_b,nsteps_lanczos,&
                   &(0.d0,0.d0),psi_tmp,npwx) 
!fourier trasform
              prod(:) = ( 0.D0, 0.D0 )
              prod(nls(igk(1:npw))) = psi_tmp(1:npw)
              CALL invfft ('Wave', prod, dffts)
           

!      product dpsi * psi_v
              prod(1:dffts%nnr)=conjg(prod(1:dffts%nnr))*psi_v(1:dffts%nnr,iv)
              if(doublegrid) then
                 call cinterpolate(prod,prod,1)
              endif

!US part STLL TO BE ADDED!!
              pola_charge(1:dffts%nnr,1,ipol,i)=pola_charge(1:dffts%nnr,1,ipol,i)-prod(1:dffts%nnr)*ww


           enddo
        enddo
        deallocate(z_dl,z_d,z_du,z_b)
        deallocate(d,f,omat)
     enddo
     deallocate(dpsi_ipol)
     deallocate(t_out)
  enddo

!print out results



!
!      symmetrize
!

  do i=1,n_gauss+1
     WRITE( stdout,'(/,10x,"Unsymmetrized in crystal axis ",/)')
     WRITE( stdout,'(10x,"(",3f15.5," )")') ((epsilon_g(ipol,jpol,i),&
          &                                ipol=1,3),jpol=1,3)

  !   call symtns (epsilon_g(:,:,i), nsym, s)
  !
  !    pass to cartesian axis
  !
     WRITE( stdout,'(/,10x,"Symmetrized in crystal axis ",/)')
     WRITE( stdout,'(10x,"(",3f15.5," )")') ((epsilon_g(ipol,jpol,i),&
       &                                ipol=1,3),jpol=1,3)
  !   call trntns (epsilon_g(:,:,i), at, bg, 1)

     call crys_to_cart ( epsilon_g(:,:,i) )
     call symmatrix ( epsilon_g(:,:,i))
  !
  ! add the diagonal part
  !
!  do ipol = 1, 3
!     epsilon (ipol, ipol) = epsilon (ipol, ipol) + 1.d0
!  enddo
  !
  !  and print the result
  !
     WRITE( stdout, '(/,10x,"Dielectric constant in cartesian axis ",/)')
  
     WRITE( stdout, '(10x,"(",3f18.9," )")') ((epsilon_g(ipol,jpol,i), ipol=1,3), jpol=1,3)

     head(i,1)=epsilon_g(1,1,i)
     head(i,2)=epsilon_g(2,2,i)
     head(i,3)=epsilon_g(3,3,i)


#ifdef __PARA
     call mp_sum ( pola_charge(:,:,:,i) , inter_pool_comm )
     call psyme (pola_charge(:,:,:,i))
#else
     call syme (pola_charge(:,:,:,i))
#endif
     
     do ipol=1,3
        CALL fwfft ('Dense',  pola_charge(1:dfftp%nnr,1,ipol,i), dfftp)
        tmp_g(:)=(0.d0,0.d0)
        !tmp_g(gstart:npw)=pola_charge(nl(igk(gstart:ngm)),1,ipol,i)
        tmp_g(gstart:ngm)=pola_charge(nl(gstart:ngm),1,ipol,i) 
        sca=(0.d0,0.d0)
        do ig=1,ngm
           sca=sca+conjg(tmp_g(ig))*tmp_g(ig)
        enddo
        call mp_sum(sca)
        write(stdout,*) 'POLA SCA', sca,ngm
!loop on frequency
        do ig=gstart,ngm
           e_head_pol(ig,i,ipol)=-4.d0*tmp_g(ig)
        enddo
     enddo
       

!TD writes on files

     if(ionode) then
        
        write(stdout,*) 'HEAD:',freqs(i),head(i,1),head(i,2),head(i,3)
        
        write(stdout,*) 'E_HEAD :', i
        write(stdout,*) i,e_head_pol(2,i,1)
        write(stdout,*) i,e_head_pol(2,i,2)
        write(stdout,*) i,e_head_pol(2,i,3)
        
     endif

     call flush_unit(stdout)


  enddo

!writes on file head

  if(ionode) then
     iun =  find_free_unit()
     open( unit= iun, file=trim(prefix)//'.head', status='unknown',form='unformatted')
     write(iun) n_gauss
     write(iun) omega_gauss
     write(iun) freqs(1:n_gauss+1)
     write(iun) head(1:n_gauss+1,1)
     write(iun) head(1:n_gauss+1,2)
     write(iun) head(1:n_gauss+1,3)
     close(iun)
  endif


!writes on file wings

!collect data
 
  


!calculate total number of G for wave function
  npwx_g=ngm
  call mp_sum(npwx_g)
  allocate(e_head_g(ngm_g))

  if(ionode) then
     iun =  find_free_unit()
     open( unit= iun, file=trim(prefix)//'.e_head', status='unknown',form='unformatted')
     write(iun) n_gauss
     write(iun) omega_gauss
     write(iun) freqs(1:n_gauss+1)
     write(iun) npwx_g
   endif

   call mp_barrier( world_comm )


   do ipol=1,3
      do i=1,n_gauss+1
         e_head_g(:)=(0.d0,0.d0)
         

         call mergewf(e_head_pol(:,i,ipol),e_head_g ,ngm,ig_l2g,mpime,nproc,ionode_id,intra_pool_comm)
         if(ionode) then
           ! do ig=1,npwx_g
               write(iun) e_head_g(1:npwx_g)
           ! enddo
         endif
      enddo
   enddo
   call mp_barrier( world_comm )
   write(stdout,*) 'ATT02'
  if(ionode) close(iun)

 ! if(ionode) then
 !    open( unit= iun, file=trim(prefix)//'.e_head', status='old',position='rewind',form='unformatted')
 !    read(iun) idumm
 !    read(iun) rdumm
 !    read(iun) head_tmp(1:n_gauss+1)
 !    read(iun) idumm
 !    allocate(e_head_g_tmp(n_gauss+1,npwx_g,3))
 !    do ipol=1,3
 !       do ii=1,n_gauss+1
 !          do ig=1,npwx_g
 !             read(iun) e_head_g_tmp(ii,ig,ipol)
 !          enddo
 !       enddo
 !    enddo
     
 !    rewind(iun)
 !    write(iun) n_gauss
 !    write(iun) omega_gauss
 !    write(iun) freqs(1:n_gauss+1)
 !    write(iun) npwx_g
 !    do ipol=1,3
 !       do ig=1,npwx_g
 !          write(iun) e_head_g_tmp(1:n_gauss+1,ig,ipol)
 !       enddo
 !    enddo
     close(iun)
 
 !    deallocate(e_head_g_tmp)
 ! endif
 

  call mp_barrier( world_comm )
  write(stdout,*) 'ATT1'
  
  deallocate(e_head_g)
  deallocate(psi_tmp)
  deallocate(prod)
  
  deallocate (ps)
  deallocate(psi_v)
  deallocate(pola_charge)
  
    

  deallocate(head,head_tmp,freqs)
  deallocate(e_head, tmp_g)
  deallocate(epsilon_g)
  deallocate(e_head_pol)
  

   call mp_barrier( world_comm )
   write(stdout,*) 'ATT2'

  call stop_clock ('solve_head')
  return
end subroutine solve_head

