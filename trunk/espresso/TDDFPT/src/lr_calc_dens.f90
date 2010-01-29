!-----------------------------------------------------------------------
subroutine lr_calc_dens( evc1 )
  !---------------------------------------------------------------------
  ! ... calculates response charge density from linear response 
  ! ... orbitals and ground state orbitals
  !---------------------------------------------------------------------
  !
  ! OBM :
  ! 050608 Modified for calbec interface in v4.0 (w evcx->evcx(:,:,ik or 1)
  !        gamma_only correction         
  !        tvanp --> upf%tvanp
  ! 160608 reduce --> mp_sum
  ! 010708 Real space implementation (gamma_point_only)
  !
  ! Input : evc1 (qdash etc) Output: rho_1 (=2*sum_v (revc0_v(r) . revc1_v(r,w)  v:valance state index, r denotes a transformation to real space)
  ! in case of uspps becsum is also calculated here
  ! in case of charge response calculation, the rho_tot is calculated here

#include "f_defs.h"
  !
  use ions_base,                    only : ityp,nat,ntyp=>nsp
  use cell_base,                    only : omega
  use ener,                     only : ef
  use gsmooth,                  only : nr1s,nr2s,nr3s,nrx1s,nrx2s,&
       nrx3s,nrxxs,nls,nlsm,doublegrid
  use gvect,                    only : nrxx,gstart,nr1,nr2,nr3
  use io_global,                only : stdout
  use kinds,                    only : dp
  use klist,                    only : nks,xk,wk
  use lr_variables,             only : evc0,revc0,rho_1,lr_verbosity, &
                                       charge_response, itermax,&
                                       cube_save, rho_1_tot, &
                                       LR_iteration, LR_polarization
  use lsda_mod,                 only : current_spin, isk
  use wavefunctions_module,     only : psic
  use wvfct,                    only : nbnd,et,wg,npwx,npw
  use control_flags,            only : gamma_only
  use uspp,                     only : vkb,nkb,okvan,qq,becsum
  use uspp_param,               only : upf, nh
  USE io_global,                ONLY : ionode, stdout
  use io_files,                 only : tmp_dir, prefix
  use mp,                       only : mp_sum
  use mp_global,                ONLY : inter_pool_comm, intra_pool_comm,nproc
  use realus,                   only : igk_k,npw_k,addusdens_r
  use charg_resp,               only : w_T, lr_dump_rho_tot_cube,lr_dump_rho_tot_xyzd,lr_dump_rho_tot_xcrys
  USE noncollin_module,     ONLY : nspin_mag
  use control_flags,         only : tqr
  !
  implicit none
  !
  character(len=6), external :: int_to_char
  !
  complex(kind=dp) :: evc1(npwx,nbnd,nks)
  !
  ! functions
  real(kind=dp) :: ddot 
  !
  ! local variables
  integer :: ir,ik,ibnd,jbnd,ig,ijkb0,np,na,ijh,ih,jh,ikb,jkb,ispin
  integer :: i, j, k, l 
  real(kind=dp) :: w1,w2,scal
  real(kind=dp) :: rho_sum
  real(kind=dp), allocatable :: rho_sum_resp_x(:),rho_sum_resp_y(:),rho_sum_resp_z(:) ! These are temporary buffers for response charge storage
  complex(kind=dp), allocatable :: spsi(:,:)
  !
  character(len=256) :: tempfile, filename
  !
  !OBM DEBUG
  complex(kind=dp),external :: lr_dot

  If (lr_verbosity > 5) THEN
    WRITE(stdout,'("<lr_calc_dens>")')
  endif
  !
  call start_clock('lr_calc_dens')
  !
  allocate(spsi(npwx,nbnd))
  spsi(:,:)=(0.0d0,0.0d0)
  !
  psic(:)=(0.0d0,0.0d0)
  rho_1(:,:)=0.0d0
  !
  !print *, "norm of evc1 read lr_calc_dens ", lr_dot(evc1(1,1,1),evc1(1,1,1))
  if(gamma_only) then
     call lr_calc_dens_gamma()
  else
     call lr_calc_dens_k()
  endif
  !print *, "rho_1 after lr_calc_dens calculates",SUM(rho_1) 
  !print *, "norm of evc1 after lr_calc_dens calculates", lr_dot(evc1(1,1,1),evc1(1,1,1))
  
  !
  ! ... If a double grid is used, interpolate onto the fine grid
  !
  if ( doublegrid ) call interpolate(rho_1,rho_1,1)
  !
  ! ... Here we add the Ultrasoft contribution to the charge
  !
  !IF ( okvan ) CALL lr_addusdens(rho_1)
  !print *, "rho_1 before addusdens",SUM(rho_1) 
  if (tqr) then
   CALL addusdens_r(rho_1,.false.)
  else
   CALL addusdens(rho_1) 
  endif
  !
  !print *, "rho_1 after addusdens",SUM(rho_1) 
#ifdef __PARA
  !call poolreduce(nrxx,rho_1)
  call mp_sum(rho_1, inter_pool_comm)
#endif
  !
  ! check response charge density sums to 0
if (lr_verbosity > 0) then
  
  do ispin = 1, nspin_mag
   rho_sum=0.0d0
   do ir=1,nrxx
     rho_sum=rho_sum+rho_1(ir,ispin)
   enddo
   !
#ifdef __PARA
   call mp_sum(rho_sum, intra_pool_comm )
#endif
   !
   rho_sum=rho_sum*omega/(nr1*nr2*nr3)
   !
   if(abs(rho_sum)>1.0d-12) then
     write(stdout,'(5X,"lr_calc_dens: ****** response charge density does not sum to zero")')
     !
     write(stdout,'(5X,"lr_calc_dens: ****** response charge density =",1X,e12.5)')&
          rho_sum
     !
     write(stdout,'(5X,"lr_calc_dens: ****** response charge density, US part =",1X,e12.5)')&
          scal
     !     call errore(' lr_calc_dens ','Linear response charge density '// &
     !          & 'does not sum to zero',1)
   endif
  enddo
  !
endif
   IF (charge_response == 1 .and. LR_iteration /=0) then
     !
     ALLOCATE( rho_sum_resp_x( nr1 ) )
     ALLOCATE( rho_sum_resp_y( nr2 ) )
     ALLOCATE( rho_sum_resp_z( nr3 ) )
     !
     rho_sum_resp_x = 0.D0
     rho_sum_resp_y = 0.D0
     rho_sum_resp_z = 0.D0
     !
     DO ir=1,nrxx
        !
        i=cube_save(ir,1)+1
        j=cube_save(ir,2)+1
        k=cube_save(ir,3)+1
        !
        rho_sum_resp_x(i)=rho_sum_resp_x(i)+rho_1(ir,1)
        rho_sum_resp_y(j)=rho_sum_resp_y(j)+rho_1(ir,1)
        rho_sum_resp_z(k)=rho_sum_resp_z(k)+rho_1(ir,1)
        !
     END DO
     !
#ifdef __PARA
     call mp_sum(rho_sum_resp_x, intra_pool_comm)
     call mp_sum(rho_sum_resp_y, intra_pool_comm)
     call mp_sum(rho_sum_resp_z, intra_pool_comm)
     if (ionode) then
#endif
     write(stdout,'(5X,"Dumping plane sums of densities for iteration ",I4)') LR_iteration
     !
     filename = trim(prefix) // ".density_x" 
     tempfile = trim(tmp_dir) // trim(filename)
     !
     open (158, file = tempfile, form = 'formatted', status = 'unknown', position = 'append')
     !
     do i=1,nr1
        write(158,*) rho_sum_resp_x(i)
     end do
     !
     close(158)
     !
     filename = trim(prefix) // ".density_y"
     tempfile = trim(tmp_dir) // trim(filename)
     !
     open (158, file = tempfile, form = 'formatted', status = 'unknown', position = 'append')
     !
     do i=1,nr2
        write(158,*) rho_sum_resp_y(i)
     end do
     !
     close(158)
     !
     filename = trim(prefix) // ".density_z"
     tempfile = trim(tmp_dir) // trim(filename)
     !
     open (158, file = tempfile, form = 'formatted', status = 'unknown', position = 'append')
     !
     do i=1,nr3
        write(158,*) rho_sum_resp_z(i)
     end do
     !
     close(158)
     !
#ifdef __PARA
     end if
#endif
     !
     DEALLOCATE( rho_sum_resp_x )
     DEALLOCATE( rho_sum_resp_y )
     DEALLOCATE( rho_sum_resp_z )
     !
  END IF
  IF (charge_response == 2 .and. LR_iteration /= 0) then
    ! although rho_1 is intended to be an estimate for
    ! the charge response, it is actually equivalent to an element of
    ! V^T . phi_v where V^T is the is the transpose of the Krylov subspace generated 
    ! by the Lanczos algorithm. The total charge density can be written
    ! as 
    ! \sum_(lanczos iterations) (V^T.phi_v) . w_T
    ! Where w_T is the corresponding eigenvector from the solution of
    ! (w-L)e_1 = w_T
    !
    ! notice that rho_1 is already reduced across pools above, so no parallelization is necessary
    !
    DO ir=1,nrxx
     rho_1_tot(ir,:)=rho_1_tot(ir,:)+rho_1(ir,:)*w_T(LR_iteration)
    enddo
    !if (LR_iteration == 1) then 
    !   call lr_dump_rho_tot_xyzd(rho_1(:),"first-rho1")
    !   call lr_dump_rho_tot_cube(rho_1(:),"first-rho1")
    !endif
    !if (LR_iteration == itermax) call lr_dump_rho_tot_cube(rho_1(:),"last--rho1")
  !
  ENDIF
  !
  deallocate(spsi)
  !
  call stop_clock('lr_calc_dens')
  !
  return
  !
contains
  !
  subroutine lr_calc_dens_gamma
    !
    use becmod,              only : bec_type, becp, calbec
    use lr_variables,        only : becp1   !,real_space
    !use real_beta,           only : ccalbecr_gamma, fft_orbital_gamma
    USE io_global,           ONLY : stdout
    USE realus,              ONLY : real_space, fft_orbital_gamma, initialisation_level, &
                           bfft_orbital_gamma, calbec_rs_gamma, add_vuspsir_gamma, v_loc_psir,&
                           real_space_debug

    !
      
    do ibnd=1,nbnd,2
!      psic(:) =(0.0d0,0.0d0)
!      if(ibnd<nbnd) then
!         do ig=1,npw_k(1)
!            !
!            psic(nls(igk_k(ig,1)))=evc1(ig,ibnd,1)+&
!                 (0.0d0,1.0d0)*evc1(ig,ibnd+1,1)
!            psic(nlsm(igk_k(ig,1)))=conjg(evc1(ig,ibnd,1)-&
!                 (0.0d0,1.0d0)*evc1(ig,ibnd+1,1))
!            !
!         enddo
!      else
!         do ig=1,npw_k(1)
!            !
!            psic(nls(igk_k(ig,1)))=evc1(ig,ibnd,1)
!            psic(nlsm(igk_k(ig,1)))=conjg(evc1(ig,ibnd,1))
!            !
!         enddo
!      endif
!      !
!      call cft3s(psic,nr1s,nr2s,nr3s,nrx1s,nrx2s,nrx3s,2)
       call fft_orbital_gamma(evc1(:,:,1),ibnd,nbnd)
       !
       w1=wg(ibnd,1)/omega
       !
       if(ibnd<nbnd) then
          w2=wg(ibnd+1,1)/omega
       else
          w2=w1
       endif
       ! OBM:
       ! (n'(r,w)=2*sum_v (psi_v(r) . q_v(r,w)) 
       ! where psi are the ground state valance orbitals
       ! and q_v are the standart batch representation (rotated) 
       ! response orbitals
       ! Here, since the ith iteration is the best approximate we have
       ! for the most dominant eigenvalues/vectors, an estimate for the response
       ! charge density can be calculated. This is in no way the final
       ! response charge density. 
       ! the loop is over real space points. 
       do ir=1,nrxxs
          rho_1(ir,:)=rho_1(ir,:) &
               +2.0d0*(w1*real(revc0(ir,ibnd,1),dp)*real(psic(ir),dp)&
               +w2*aimag(revc0(ir,ibnd,1))*aimag(psic(ir)))
       enddo
       ! 
       ! OBM - psic now contains the response functions at 
       ! real space, eagerly putting all the real space stuff at this point.
       ! notice that betapointlist() is called in lr_readin at the very start
       IF ( real_space_debug > 6 .and. okvan) then
        ! The rbecp term
        call calbec_rs_gamma(ibnd,nbnd,becp%r)
       endif 
       ! End of real space stuff 
    enddo
    !
    ! ... If we have a US pseudopotential we compute here the becsum term
    !
    IF ( okvan ) then
       !
       scal = 0.0d0
       becsum(:,:,:) = 0.0d0
       !
       IF ( real_space_debug <= 6) then !in real space, the value is calculated above
          !call pw_gemm('Y',nkb,nbnd,npw_k(1),vkb,npwx,evc1,npwx,rbecp,nkb)
          call calbec(npw_k(1), vkb, evc1(:,:,1), becp)
       endif
       !
       call start_clock( 'becsum' )
       !
       do ibnd = 1, nbnd
          scal = 0.0d0
          !
          w1 = wg(ibnd,1)
          ijkb0 = 0
          !
          do np = 1, ntyp
             !
             if ( upf(np)%tvanp ) then
                !
                do na = 1, nat
                   !
                   if ( ityp(na) == np ) then
                      !
                      ijh = 1
                      !
                      do ih = 1, nh(np)
                         !
                         ikb = ijkb0 + ih
                         ! 
                         becsum(ijh,na,current_spin) = &
                              becsum(ijh,na,current_spin) + &
                              2.d0 * w1 * becp%r(ikb,ibnd) * becp1(ikb,ibnd)
                         scal = scal + qq(ih,ih,np) *1.d0 *  becp%r(ikb,ibnd) * becp1(ikb,ibnd)
                         !
                         ijh = ijh + 1
                         !
                         do jh = ( ih + 1 ), nh(np)
                            !
                            jkb = ijkb0 + jh
                            !
                            becsum(ijh,na,current_spin) = &
                                 becsum(ijh,na,current_spin) + &
                                 w1 * 2.D0 * (becp1(ikb,ibnd) * becp%r(jkb,ibnd) + &
                                 becp1(jkb,ibnd) * becp%r(ikb,ibnd))
                            scal = scal + qq(ih,jh,np) *1.d0  * (becp%r(ikb,ibnd) * becp1(jkb,ibnd)+&
                                 becp%r(jkb,ibnd) * becp1(ikb,ibnd))
                            !
                            ijh = ijh + 1
                            !
                         end do
                         !
                      end do
                      !
                      ijkb0 = ijkb0 + nh(np)
                      !
                   end if
                   !
                end do
                !
             else
                !
                do na = 1, nat
                   !
                   if ( ityp(na) == np ) ijkb0 = ijkb0 + nh(np)
                   !
                end do
                !
             end if
             !
          end do
          !
           ! OBM debug
           !write(stdout,'(5X,"lr_calc_dens: ibnd,scal=",1X,i3,1X,e12.5)')&
           !     ibnd,scal
       end do
       !
       call stop_clock( 'becsum' )
       !
    endif
    !
    return
    !
  end subroutine lr_calc_dens_gamma
  !-----------------------------------------------------------------------
  subroutine lr_calc_dens_k
    !
    use becmod,              only : bec_type, becp, calbec
    use lr_variables,        only : becp1_c
    !
    do ik=1,nks
       do ibnd=1,nbnd
          psic(:)=(0.0d0,0.0d0)
          do ig=1,npw_k(ik)
             psic(nls(igk_k(ig,ik)))=evc1(ig,ibnd,ik)
          enddo
          !
          call cft3s(psic,nr1s,nr2s,nr3s,nrx1s,nrx2s,nrx3s,2)
          !
          w1=wg(ibnd,ik)/omega
          !
          ! loop over real space points
          do ir=1,nrxxs
             rho_1(ir,:)=rho_1(ir,:) &
                  +2.0d0*w1*real(conjg(revc0(ir,ibnd,ik))*psic(ir),dp)
          enddo
          !
       enddo
    enddo
    !
    ! ... If we have a US pseudopotential we compute here the becsum term
    !
    IF ( okvan ) then
       !
       do ik =1,nks
          !
          call init_us_2(npw_k(ik),igk_k(1,ik),xk(1,ik),vkb)
          !
          scal = 0.0d0
          becsum(:,:,:) = 0.0d0
          !
          IF ( nkb > 0 .and. okvan ) then
             ! call ccalbec(nkb,npwx,npw_k(ik),nbnd,becp,vkb,evc1) 
             call calbec(npw_k(ik),vkb,evc1(:,:,ik),becp)
          endif
          !
          call start_clock( 'becsum' )
          !
          do ibnd = 1, nbnd
             scal = 0.0d0
             !
             w1 = wg(ibnd,ik)
             ijkb0 = 0
             !
             do np = 1, ntyp
                !
                if ( upf(np)%tvanp ) then
                   !
                   do na = 1, nat
                      !
                      if ( ityp(na) == np ) then
                         !
                         ijh = 1
                         !
                         do ih = 1, nh(np)
                            !
                            ikb = ijkb0 + ih
                            !
                            becsum(ijh,na,current_spin) = &
                                 becsum(ijh,na,current_spin) + &
                                 2.d0 * w1 * real(conjg(becp%k(ikb,ibnd)) * becp1_c(ikb,ibnd,ik))
                            scal = scal + qq(ih,ih,np) *1.d0 *  real(conjg(becp%k(ikb,ibnd)) * becp1_c(ikb,ibnd,ik))
                            !
                            ijh = ijh + 1
                            !
                            do jh = ( ih + 1 ), nh(np)
                               !
                               jkb = ijkb0 + jh
                               !
                               becsum(ijh,na,current_spin) = &
                                    becsum(ijh,na,current_spin) + &
                                    w1 * 2.d0 * real(conjg(becp1_c(ikb,ibnd,ik)) * becp%k(jkb,ibnd) + &
                                    becp1_c(jkb,ibnd,ik) * conjg(becp%k(ikb,ibnd)))
                               scal = scal + qq(ih,jh,np) *1.d0  * real(conjg(becp%k(ikb,ibnd)) * becp1_c(jkb,ibnd,ik)+&
                                    becp%k(jkb,ibnd) * conjg(becp1_c(ikb,ibnd,ik)))
                               !
                               ijh = ijh + 1
                               !
                            end do
                            !
                         end do
                         !
                         ijkb0 = ijkb0 + nh(np)
                         !
                      end if
                      !
                   end do
                   !
                else
                   !
                   do na = 1, nat
                      !
                      if ( ityp(na) == np ) ijkb0 = ijkb0 + nh(np)
                      !
                   end do
                   !
                end if
                !
             end do
             !
             ! write(stdout,'(5X,"lr_calc_dens: ibnd,scal=",1X,i3,1X,e12.5)')&
             !      ibnd,scal
          end do
          call stop_clock( 'becsum' )
          !
       enddo
       !
    endif
    !
    return
    !
  end subroutine lr_calc_dens_k
  !-----------------------------------------------------------------------
end subroutine lr_calc_dens
!-----------------------------------------------------------------------
