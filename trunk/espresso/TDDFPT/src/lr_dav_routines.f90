!!----------------------------------------------------------------------------
module lr_dav_routines
!----------------------------------------------------------------------------
! Created by Xiaochuan Ge (Oct, 2012)
!-----------------------------------------------------------------------
contains

  subroutine lr_dav_cvcouple()
    !-----------------------------------------------------------------------
    !  Created by Xiaochuan Ge (Oct, 2012)
    !-----------------------------------------------------------------------
    !  This subroutine returns num_init couples of occ/virt states to be used
    !  as the initial vectors of lr davidson algorithm

    use kinds,         only : dp
    use wvfct,         only : nbnd, nbndx, et
    use lr_dav_variables, only : vc_couple,num_init,single_pole,energy_dif,&
                                & energy_dif_order, p_nbnd_occ, p_nbnd_virt
    use lr_variables, only : nbnd_total
    use io_global,    only : stdout
    use lr_dav_debug
 
    implicit none
    integer :: ib,ic,iv
    real(dp) :: temp
    
    allocate(energy_dif(p_nbnd_occ*p_nbnd_virt))
    allocate(energy_dif_order(p_nbnd_occ*p_nbnd_virt))

    write(stdout,'(5x,"Calculating the electron-hole pairs for initiating trial vectors ...",/)')

    if(single_pole) then
      write(stdout,'(/5x,"Single Pole Approximation is used to generate the initial vectors",/)')
      write(stdout,'(/5x,"At this moment, this movement is only valid for NC PPs, and ecut_rho=4*ecut_wfc.",/5x, &
            "Please make sure that you are using the correct input",/)')
    endif

    ib=0
    do iv = nbnd-p_nbnd_occ+1, nbnd
      do ic = nbnd+1, nbnd+p_nbnd_virt
        ib = ib+1
        energy_dif(ib)=(et(ic,1)-et(iv,1))
        if(single_pole) then
          temp = calc_inter(iv,ic,iv,ic)
          energy_dif(ib) = energy_dif(ib) + temp
        endif 
      enddo
    enddo

    call xc_sort_array_get_order(energy_dif,p_nbnd_occ*p_nbnd_virt,energy_dif_order)

    do ib=1, p_nbnd_occ*p_nbnd_virt
      iv=energy_dif_order(ib)
      vc_couple(1,ib)=((iv-1)/p_nbnd_virt)+1+(nbnd-p_nbnd_occ)
      vc_couple(2,ib)=mod((iv-1),p_nbnd_virt)+nbnd+1
      write(stdout,'(10x,3(I5,5x),F20.12)') ib,vc_couple(1,ib), vc_couple(2,ib)-nbnd, energy_dif(energy_dif_order(ib))
    enddo

    write(stdout,'(5x,"Finished calculating the cv couples.")')
    RETURN
  END subroutine lr_dav_cvcouple
  !-------------------------------------------------------------------------------

  subroutine lr_dav_alloc_init()
    !---------------------------------------------------------------------
    ! Created by X.Ge in Oct.2012
    !---------------------------------------------------------------------
    ! Allocates and initialises variables for lr_davidson algorithm

    use lr_dav_variables    
    use lr_variables,   only : nbnd_total
    use wvfct,         only : nbnd,npwx
    use klist,             only : nks
    use io_global,     only : stdout

    implicit none

    WRITE(stdout,'(5x,"Num of eigen values=",I15)') num_eign
    WRITE(stdout,'(5x,"Allocating parameters for davidson ...")')

    allocate(vc_couple(2,nbnd*(nbnd_total-nbnd))) ! 1. v  2. c  
    allocate(vec_b(npwx,nbnd,nks,num_basis_max)) ! subspace basises
    allocate(swork(npwx,nbnd,nks))
    allocate(D_vec_b(npwx,nbnd,nks,num_basis_max)) 
    allocate(C_vec_b(npwx,nbnd,nks,num_basis_max)) 
    allocate(M(num_basis_max,num_basis_max))
    allocate(M_shadow_avatar(num_basis_max,num_basis_max))
    allocate(M_C(num_basis_max,num_basis_max))
    allocate(M_D(num_basis_max,num_basis_max))
    allocate(left_M(num_basis_max,num_basis_max))
    allocate(right_M(num_basis_max,num_basis_max))
    allocate(left_full(npwx,nbnd,nks,num_eign))
    allocate(right_full(npwx,nbnd,nks,num_eign))
    allocate(right_res(npwx,nbnd,nks,num_eign))
    allocate(left_res(npwx,nbnd,nks,num_eign))
    allocate(right2(num_eign))
    allocate(left2(num_eign))
    allocate(eign_value(num_basis_max,2))
    allocate(tr_energy(num_basis_max))
    allocate(eign_value_order(num_basis_max))
    allocate(kill_left(num_eign))
    allocate(kill_right(num_eign))
    allocate(ground_state(npwx,nbnd,nks))
    
    allocate(C_right_full(npwx,nbnd,nks,num_eign))
    allocate(D_left_full(npwx,nbnd,nks,num_eign))
    allocate(omegal(num_eign))
    allocate(omegar(num_eign))

    allocate(inner_matrix(num_basis_max,num_basis_max))
    allocate(chi_dav(3,num_eign))
    allocate(total_chi(num_eign))
    allocate(Fx(nbnd,nbnd_total-nbnd))
    allocate(Fy(nbnd,nbnd_total-nbnd))

    lwork=8*num_basis_max
    allocate(work(lwork))

    if ( p_nbnd_occ > nbnd ) p_nbnd_occ = nbnd
    if ( p_nbnd_virt > nbnd_total-nbnd ) p_nbnd_virt = nbnd_total-nbnd

    if ( p_nbnd_occ*p_nbnd_virt .lt. num_init .and. .not. if_random_init) then
      WRITE(stdout,'(/5X,"Initial vectors are forced to be chosen &
               &randomly because no enough particle-hole pairs are available.",/5x, &
               "You may want to try to calculate more virtual states or include more occupied states by changing &
               p_nbnd_occ in the input.",/)')
      if_random_init=.true. ! The only way to set initial state when there's no virtual state.
    endif

    write(stdout,'(5x,"Finished allocating parameters.")')
    return
  end subroutine lr_dav_alloc_init
  !-------------------------------------------------------------------------------

  subroutine lr_dav_set_init()
    !---------------------------------------------------------------------
    ! Created by X.Ge in Jan.2013
    !---------------------------------------------------------------------
    !  This routine use the cvcouple and the dft wavefunction to set the 
    !  initial sub space

    use kinds,         only : dp
    use wvfct,         only : nbnd, npwx, et
    use lr_dav_variables
    use lr_variables,         only : evc0, sevc0 ,revc0, evc0_virt,&
                                   & sevc0_virt, nbnd_total,davidson
    use io_global,    only : stdout
    use wvfct,       only : g2kin,npwx,nbnd,et,npw
    use gvect,                only : gstart
    use lr_dav_debug

    implicit none
    integer :: ib,ia,ipw,ibnd
    real(dp) :: temp,R,R2

    WRITE(stdout,'(5x,"Initiating variables for davidson ...")')
    ! set initial basis
    num_basis=num_init
    vec_b(:,:,:,:) = (0.0D0,0.0D0)

    if (.not. if_random_init) then  ! set the initial basis set to be {|c><v|}
      write(stdout,'(5x,"Lowest energy electron-hole pairs are used as initial vectors ...")')
      CALL lr_dav_cvcouple()
      do ib = 1, num_init, 1
        vec_b(:,vc_couple(1,ib),1,ib)=evc0_virt(:,vc_couple(2,ib)-nbnd,1)
      enddo

    else ! Random initial
      call random_init()
    endif
    num_basis_old=0
    dav_conv=.false.
    dav_iter=0
    call check_orth()
    WRITE(stdout,'(5x,"Finished initiating.")')
  END subroutine  lr_dav_set_init
  !-------------------------------------------------------------------------------

  subroutine one_dav_step()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! Non-Hermitian diagonalization
    ! In one david step, M_C,M_D and M_DC are first constructed; then will be
    ! solved rigorously; then the solution in the subspace left_M() will
    ! be transformed into full space left_full()

    use io_global,            only : ionode, stdout,ionode_id
    use kinds,                only : dp
    use lr_variables,         only : ltammd,&
                                     evc0, sevc0, d0psi
    use wvfct,                only : nbnd, npwx, npw
    use mp,                   only : mp_bcast,mp_barrier                  
    use lr_us
    use lr_dav_variables
    use lr_dav_debug
    use lr_us

    implicit none
    integer :: ik, ip, ibnd,ig, pol_index, ibr, ibl, ieign,ios
    CHARACTER(len=6), EXTERNAL :: int_to_char
    real(dp) :: inner

    call start_clock('one_step')
    write(stdout,'(/7x,"==============================")') 
    write(stdout,'(/7x,"Davidson iteration:",1x,I8)') dav_iter
    write(stdout,'(7x,"num of basis:",I5)') num_basis

    ! Add new matrix elements to the M_C and M_D(in the subspace)(part 1)
    do ibr = 1, num_basis_old
      do ibl = num_basis_old+1, num_basis
        if(.not. ltammd) then
          M_C(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),C_vec_b(1,1,1,ibr))
          M_C(ibr,ibl)=M_C(ibl,ibr)
          M_D(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),D_vec_b(1,1,1,ibr))
          M_D(ibr,ibl)=M_D(ibl,ibr)
        else
          M_C(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),C_vec_b(1,1,1,ibr))
          M_C(ibr,ibl)=M_C(ibl,ibr)
          M_D(ibl,ibr)=M_C(ibl,ibr)
          M_D(ibr,ibl)=M_C(ibl,ibr)
        endif
      enddo
    enddo
     
    ! Calculate new C*vec_b and D*vec_b
    do ibr=num_basis_old+1, num_basis
      if(.not.ltammd) then
        call lr_apply_liouvillian(vec_b(:,:,:,ibr),D_vec_b(:,:,:,ibr),swork(:,:,:),.false.)  ! apply Liouvillian
        call lr_apply_liouvillian(vec_b(:,:,:,ibr),C_vec_b(:,:,:,ibr),swork(:,:,:),.true.)
        call lr_ortho(D_vec_b(:,:,:,ibr), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)  ! Project to virtual space
        call lr_ortho(C_vec_b(:,:,:,ibr), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
      else
        call lr_apply_liouvillian(vec_b(:,:,:,ibr),C_vec_b(:,:,:,ibr),swork(:,:,:),.true.)
        call lr_ortho(C_vec_b(:,:,:,ibr), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
        D_vec_b(:,:,:,ibr)=C_vec_b(:,:,:,ibr)
      endif

    ! add new elements to M_C and M_D (part 2)
      do ibl=ibr,num_basis
        if(.not. ltammd) then
          M_C(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),C_vec_b(1,1,1,ibr))
          if(ibl /= ibr) M_C(ibr,ibl)=M_C(ibl,ibr)
          M_D(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),D_vec_b(1,1,1,ibr))
          if(ibl /= ibr) M_D(ibr,ibl)=M_D(ibl,ibr)
        else
          M_C(ibl,ibr)=lr_dot_us(vec_b(1,1,1,ibl),C_vec_b(1,1,1,ibr))
          if(ibl /= ibr) M_C(ibr,ibl)=M_C(ibl,ibr)
          M_D(ibl,ibr)=M_C(ibl,ibr)
          M_D(ibr,ibl)=M_C(ibl,ibr)
        endif
      enddo
    enddo

#ifdef __MPI
  ! This part is calculated in serial
  if(ionode) then
#endif
    ! M_DC ~= M_D*M_C
      call ZGEMM('N', 'N', num_basis,num_basis,num_basis,(1.0D0,0.0D0),M_D,&
                num_basis_max,M_C,num_basis_max,(0.0D0,0.0D0), M,num_basis_max)
      call check("M_C")
      call check("M_D")
      call check("M")

    ! Solve M_DC
    ! It is dangerous to be "solved", use its shadow avatar in order to protect the original one
    M_shadow_avatar(:,:) = dble(M(:,:))  
    CALL DGEEV( 'V', 'V', num_basis,M_shadow_avatar, num_basis_max,eign_value(1,1), &
            eign_value(1,2), left_M, num_basis_max, right_M, num_basis_max, WORK, lwork, INFO )  
    if(.not. INFO .eq. 0) stop "al_davidson: errors solving the DC in subspace"
 
    ! sort the solution
    do ibr = 1, num_basis
      if(abs(eign_value(ibr,2)) .gt. zero) write(*,'(/5x,"Warning: eigen value is not real:&
                                            &",5x,I5,5x,I5,5x,F20.10,5x,F20.10)')&
                                            & num_basis,ibr,eign_value(ibr,1),eign_value(ibr,2)
    enddo
   
    do ieign=1,num_basis
      tr_energy(ieign)=sqrt(dble(eign_value(ieign,1)))
    enddo

    call xc_sort_array_get_order(tr_energy,num_basis,eign_value_order)
    
    ! print out something
    do ieign =1, min(max(num_eign,5),num_basis)
      write(stdout,'(5x,I5,5x,"Transition energy",I5,2x,":",F30.10)') num_basis,ieign,&
          & tr_energy(eign_value_order(ieign))
    enddo

#ifdef __MPI
  endif
  call mp_barrier()
  call mp_bcast(tr_energy,ionode_id)
  call mp_bcast(eign_value_order,ionode_id)
  call mp_bcast(left_M,ionode_id)
  call mp_bcast(right_M,ionode_id)
#endif

    ! Recover eigenvectors in the whole space
    left_full(:,:,:,:)=0.0d0
    right_full(:,:,:,:)=0.0d0
    do ieign = 1, num_eign
      do ibr = 1, num_basis
        left_full(:,:,1,ieign)=left_full(:,:,1,ieign)+left_M(ibr,eign_value_order(ieign))*vec_b(:,:,1,ibr)
        right_full(:,:,1,ieign)=right_full(:,:,1,ieign)+right_M(ibr,eign_value_order(ieign))*vec_b(:,:,1,ibr)
      enddo
    enddo
    !call check("recover")

    call stop_clock('one_step')
    RETURN
  END subroutine one_dav_step
  !-------------------------------------------------------------------------------

  subroutine xc_sort_array_get_order(array,N,sort_order)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! As it is self-explained by its name
    ! Sort the array by the distance to the reference

    use lr_dav_variables,  only : reference
    implicit none
    integer :: N,ia,ib
    real*8 :: array(N),temp_ele
    integer :: sort_order(N), temp_order

    do ia=1, N
    sort_order(ia)=ia
    enddo

    do ia=N, 2, -1
      do ib=1,ia-1
        if(abs(array(sort_order(ib))-reference)>abs(array(sort_order(ia))-reference)) THEN
          temp_order=sort_order(ia)
          sort_order(ia)=sort_order(ib)
          sort_order(ib)=temp_order
        endif
      enddo
    enddo
    RETURN
  END subroutine xc_sort_array_get_order  
  !-------------------------------------------------------------------------------

  subroutine dav_calc_residue()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! Calculate the residue of appro. eigen vector
    use lr_dav_variables
    use lr_variables,    only : evc0, sevc0
    use kinds,  only : dp
    use io_global, only : stdout
    use wvfct,                only : nbnd, npwx, npw
    use mp,                 only : mp_stop
    use lr_dav_debug
    use lr_us
    
    implicit none
    
    real(dp) :: max_res
    integer :: ieign, flag
    complex(kind=dp) :: temp(npwx,nbnd)

    max_res=0
    kill_left(:)=.false.
    kill_right(:)=.false.
    toadd=2*num_eign

    do ieign = 1, num_eign
      call lr_apply_liouvillian(right_full(:,:,:,ieign),right_res(:,:,:,ieign),swork(:,:,:),.true.) ! Apply lanczos
      call lr_apply_liouvillian(left_full(:,:,:,ieign),left_res(:,:,:,ieign),swork(:,:,:),.false.)
      call lr_ortho(right_res(:,:,:,ieign), evc0(:,:,1), 1,1,sevc0(:,:,1),.true.) ! Project to virtual space
      call lr_ortho(left_res(:,:,:,ieign), evc0(:,:,1), 1,1,sevc0(:,:,1),.true.)
     
      ! The reason of useing this method
      call lr_1to1orth(right_res(1,1,1,ieign),left_full(1,1,1,ieign))
      call lr_1to1orth(left_res(1,1,1,ieign),right_full(1,1,1,ieign))
      ! Instead of this will be explained in the document
      ! right_res(:,:,:,ieign)=right_res(:,:,:,ieign)-sqrt(eign_value(eign_value_order(ieign),1))*left_full(:,:,:,ieign)
      ! left_res(:,:,:,ieign)=left_res(:,:,:,ieign)-sqrt(eign_value(eign_value_order(ieign),1))*right_full(:,:,:,ieign)

      ! Update kill_r/l
      right2(ieign)=lr_dot_us(right_res(1,1,1,ieign),right_res(1,1,1,ieign))
      if (abs(aimag(right2(ieign))) .gt. zero .or. dble(right2(ieign)) .lt. 0.0D0) then
        write(stdout,'(7x,"Warning! Wanging! the residue is weird.")')
      endif
      if( dble(right2(ieign)) .lt. residue_conv_thr ) then
        kill_right(ieign)=.true.
        toadd=toadd-1
      endif
      if( dble(right2(ieign)) .gt. max_res )  max_res = dble(right2(ieign))

      left2(ieign)=lr_dot_us(left_res(1,1,1,ieign),left_res(1,1,1,ieign))
      if (abs(aimag(left2(ieign))) .gt. zero .or. dble(left2(ieign)) .lt. 0.0D0) then
        write(stdout,'(7x,"Warning! Wanging! the residue is weird.")')
      endif
      if( dble(left2(ieign)) .lt. residue_conv_thr ) then
        kill_left(ieign)=.true.
        toadd=toadd-1
      endif
      if( dble(left2(ieign)) .gt. max_res )  max_res = dble(left2(ieign))
      
      write (stdout,'(5x,"residue:",I5,2x,2F15.7)') ieign, dble(right2(ieign)), dble(left2(ieign))
    enddo
 
    write(stdout,'(7x,"Largest residue:",5x,F20.12)') max_res
    if(max_res .lt. residue_conv_thr) dav_conv=.true.

    return
  end subroutine dav_calc_residue
  !-------------------------------------------------------------------------------
    
  subroutine dav_expan_basis()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    use lr_dav_variables
    use lr_variables,    only : evc0, sevc0
    use io_global,       only : stdout
    use lr_dav_debug
    
    implicit none
    integer :: ieign, flag
    real (dp) :: temp

    if(dav_conv) return ! Already converged

    if (precondition) then
      do ieign = 1, num_eign
        if(.not. kill_left(ieign)) then
          call treat_residue(left_res(:,:,1,ieign),ieign)
          call lr_norm(left_res(1,1,1,ieign))
          call lr_ortho(left_res(:,:,:,ieign), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
          call lr_norm(left_res(1,1,1,ieign))
        endif

        if(.not. kill_right(ieign)) then
          call treat_residue(right_res(:,:,1,ieign),ieign)
          call lr_norm(right_res(1,1,1,ieign))
          call lr_ortho(right_res(:,:,:,ieign), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
          call lr_norm(left_res(1,1,1,ieign))
        endif
      enddo
    endif
 
    ! Here mGS are called three times and lr_ortho is called once for increasing 
    ! numerical stability of orthonalization
    call lr_mGS_orth()    ! 1st
    call lr_mGS_orth_pp()
    call lr_mGS_orth()    ! 2nd
    call lr_mGS_orth_pp()
    call lr_mGS_orth()    ! 3rd
    call lr_mGS_orth_pp()

    do ieign = 1, num_eign
      call lr_ortho(right_res(:,:,:,ieign), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
      call lr_ortho(left_res(:,:,:,ieign), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
    enddo

    if(toadd .eq. 0) then
      write(stdout,'("TOADD is zero !!")')
      dav_conv=.true.
      return
    endif
 
    if(num_basis+toadd .gt. num_basis_max) then
      write(stdout,'(/5x,"!!!! We have arrived maximum number of basis. We have to stop &
                   &here, and the result will not be trustable !!!!! ")')  
      dav_conv=.true.
    else
    num_basis_old=num_basis
      ! Expand the basis
      do ieign = 1, num_eign
        if(.not. kill_left(ieign)) then
          num_basis=num_basis+1
          vec_b(:,:,:,num_basis)=left_res(:,:,:,ieign)
        endif
        if(.not. kill_right(ieign)) then
          num_basis=num_basis+1
          vec_b(:,:,:,num_basis)=right_res(:,:,:,ieign)
        endif
      enddo
    endif
    return
    end subroutine dav_expan_basis
  !-------------------------------------------------------------------------------

  subroutine lr_mGS_orth()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! Modified GS algorithm to ortholize the new basis respect to the old basis
    use kinds,                only : dp
    use klist,                only : nks
    use wvfct,                only : npwx,nbnd
    use lr_dav_variables
 
    implicit none
    integer :: ib,ieign,ieign2,ia
    real(dp) :: temp
    
    ! first orthogonalize to old basis
    do ib = 1, num_basis
      do ieign = 1, num_eign
        if (.not. kill_left(ieign)) &
          &call lr_1to1orth(left_res(1,1,1,ieign),vec_b(1,1,1,ib))
        if (.not. kill_right(ieign)) &
          &call lr_1to1orth(right_res(1,1,1,ieign),vec_b(1,1,1,ib))
      enddo
    enddo

    ! orthogonalize between new basis themselves
    do ieign = 1, num_eign
      if (.not. kill_left(ieign) .and. .not. kill_right(ieign)) then
        call lr_1to1orth(left_res(1,1,1,ieign),right_res(1,1,1,ieign))
      endif
      do ieign2 = ieign+1, num_eign
        if (.not. kill_left(ieign2) .and. .not. kill_left(ieign)) &
          call lr_1to1orth(left_res(1,1,1,ieign2),left_res(1,1,1,ieign))
        
        if (.not. kill_left(ieign2) .and. .not. kill_right(ieign)) &
          call lr_1to1orth(left_res(1,1,1,ieign2),right_res(1,1,1,ieign))
        
        if (.not. kill_right(ieign2) .and. .not. kill_left(ieign)) &
          call lr_1to1orth(right_res(1,1,1,ieign2),left_res(1,1,1,ieign))
        
        if (.not. kill_right(ieign2) .and. .not. kill_right(ieign)) &
          call lr_1to1orth(right_res(1,1,1,ieign2),right_res(1,1,1,ieign))
      enddo
    enddo
    return
  end subroutine lr_mGS_orth
  !-------------------------------------------------------------------------------
    
  subroutine lr_mGS_orth_pp()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! After MGS, this pp routine try to exclude duplicate vectors and then
    ! normalize the rest
    use kinds,                only : dp
    use klist,                only : nks
    use wvfct,                only : npwx,nbnd
    use io_global,            only : stdout
    use lr_dav_variables
    use lr_us

    implicit none
    integer :: ieign,ia
    real(dp) :: norm_res
  
    do ieign = 1, num_eign
      if(.not. kill_left(ieign)) then
        norm_res = dble(lr_dot_us(left_res(1,1,1,ieign),left_res(1,1,1,ieign)))
        if(norm_res .lt. residue_conv_thr) then
          kill_left(ieign) = .true.
          write(stdout,'("One residue is eliminated:",5x,E20.12)') norm_res
          toadd=toadd-1
        else
          call lr_norm(left_res(:,:,1,ieign))
        endif
      endif

      if(.not. kill_right(ieign)) then
        norm_res = dble(lr_dot_us(right_res(1,1,1,ieign),right_res(1,1,1,ieign)))
        if(norm_res .lt. residue_conv_thr) then
          kill_right(ieign) = .true.
          write(stdout,'("One residue is eliminated:",5x,E20.12)') norm_res
          toadd=toadd-1
        else
          call lr_norm(right_res(:,:,1,ieign))
        endif
      endif
    enddo
  end subroutine lr_mGS_orth_pp
  !-------------------------------------------------------------------------------

  subroutine lr_norm(vect)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! Normalizes vect, returns vect/sqrt(<vect|svect>)
    
    use kinds,                only : dp
    use klist,                only : nks
    use wvfct,                only : npwx,nbnd
    use lr_us

    implicit none
    complex(dp)  :: vect(npwx,nbnd,nks),svect(npwx,nbnd,nks)
    real(dp) :: temp
 
    temp=dble(lr_dot_us(vect(1,1,1),vect(1,1,1)))
    vect(:,:,:)=vect(:,:,:)/sqrt(temp)

    return
  end subroutine lr_norm
  !-------------------------------------------------------------------------------
 
  subroutine lr_1to1orth(vect1,vect2)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! This routine calculate the components of vect1 which is "vertical" to
    ! vect2
    
    use kinds,                only : dp
    use klist,                only : nks
    use wvfct,                only : npwx,nbnd,npw
    use lr_us
    
    implicit none
    complex(dp)  :: vect1(npwx,nbnd,nks),vect2(npwx,nbnd,nks)
    
    vect1(:,:,1)=vect1(:,:,1)-(lr_dot_us(vect1(1,1,1),vect2(1,1,1))/lr_dot_us(vect2(1,1,1),vect2(1,1,1)))*vect2(:,:,1)
    return
  end subroutine lr_1to1orth
  !-------------------------------------------------------------------------------

  subroutine treat_residue(vect,ieign)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! This routine apply pre-condition to the residue to speed up the
    ! convergence
    use kinds,       only : dp
    use wvfct,       only : g2kin,npwx,nbnd,et,npw
    use lr_dav_variables, only : reference, diag_of_h, tr_energy,eign_value_order,&
                     &turn2planb
    use g_psi_mod
    
    implicit none
    complex(dp)  :: vect(npwx,nbnd)
    integer :: ia,ib,ieign,flag
    real(dp) :: temp,minimum
    
    minimum=0.0001d0
    do ib = 1, nbnd
      do ia = 1, npw
        temp = g2kin(ia)-et(ib,1)-reference
        if( abs(temp) .lt. minimum ) temp = sign(minimum,temp)
        vect(ia,ib) = vect(ia,ib)/temp
      enddo
    enddo
    
    return
  end subroutine treat_residue
  !-------------------------------------------------------------------------------

  subroutine interpret_eign()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! This routine try to interpret physical information from the solution of
    ! casider's equation
    use kinds,                only : dp
    use lr_variables,         only : evc0, sevc0,R, nbnd_total,evc0_virt
    use lr_dav_variables
    use charg_resp,           only : lr_calc_R
    use wvfct,                only : nbnd
    use io_global,            only : stdout,ionode,ionode_id
    use mp,                   only : mp_bcast,mp_barrier                  
    use lr_us
    
    implicit none
    integer :: ieign, ia,ic,iv,ipol
    real(kind=dp), external   :: ddot
    real(dp) :: norm, normx, normy, alpha, shouldbe1,temp
    real(dp) :: C_right_M(num_basis_max),D_left_M(num_basis_max)

    allocate(norm_F(num_eign))

    write(stdout,'(/7x,"================================================================")') 
    write(stdout,'(/7x,"Davidson diagonalization has finished, now print out information of eigen pairs")') 

    call lr_calc_R()
    
    ! Print out Oscilation strength
    write(stdout,'(/,/5x,"K-S Oscillator strengths")')
    WRITE(stdout,'(5x,"occ",1x,"con",8x,"R-x",14x,"R-y",14x,"R-z")')
    do iv=nbnd-p_nbnd_occ+1, nbnd
      do ic=1,p_nbnd_virt
        write(stdout,'(5x,i3,1x,i3,3x,E16.8,2X,E16.8,2X,E16.8)') &
           &iv,ic,dble(R(iv,ic,1)),dble(R(iv,ic,2)),dble(R(iv,ic,3))
      enddo 
    enddo

    ! Analysis of each eigen-state
    do ieign = 1, num_eign
#ifdef __MPI
  ! This part is calculated in serial
  if(ionode) then
#endif
      ia = eign_value_order(ieign)
      write(stdout,'(/7x,"! The",I5,1x,"-th eigen state. The transition&
         & energy is: ", 5x, F12.8)') ieign, tr_energy(ia)
      ! Please see Documentation for the explain of the next four steps
      ! In short it gets the right components of X and Y
      ! Apply C to the right eigen state in order to calculate the right omega
      call dgemv('N',num_basis,num_basis,(1.0D0,0.0D0),dble(M_C),&
           &num_basis_max,right_M(:,ia),1,(0.0D0,0.0D0),C_right_M,1)
      omegar(ieign)=ddot(num_basis,left_M(:,ia),1,left_M(:,ia),1)
      omegar(ieign)=ddot(num_basis,C_right_M,1,left_M(:,ia),1)

      ! Apply D to the lfet eigen state in order to calculate the left omega
      call dgemv('N',num_basis,num_basis,(1.0D0,0.0D0),dble(M_D),&
           &num_basis_max,left_M(:,ia),1,(0.0D0,0.0D0),D_left_M,1)
      omegal(ieign)=ddot(num_basis,right_M(:,ia),1,right_M(:,ia),1)
      omegal(ieign)=ddot(num_basis,D_left_M,1,right_M(:,ia),1)

      if(abs(omegal(ieign)*omegar(ieign)-tr_energy(ia)**2) .gt. zero) then
        write(stdout,'(/5x,"Warning !!! : The interpretation of the eigenstates may have problems.")')
        write(stdout,'(10x,"omegal*omegar = ",F20.12,10x,"omega^2 = ",F20.12)') &
            &omegal(ieign)*omegar(ieign),tr_energy(ia)**2
      endif

      ! scale right_full and left_full in order to make omegar = omegal
      omegar(ieign)=sqrt(dble(omegar(ieign)))
      omegal(ieign)=sqrt(dble(omegal(ieign)))

#ifdef __MPI
  endif
  call mp_barrier()
  call mp_bcast(omegar,ionode_id)
  call mp_bcast(omegal,ionode_id)
#endif

      right_full(:,:,:,ieign)=right_full(:,:,:,ieign)/dble(omegar(ieign))      
      left_full(:,:,:,ieign)=left_full(:,:,:,ieign)/dble(omegal(ieign))      
    
      ! Normalize the vector
      norm=2.0d0*dble(lr_dot_us(right_full(1,1,1,ieign),left_full(1,1,1,ieign)))
      norm=sqrt(abs(norm))

      right_full(:,:,:,ieign)=right_full(:,:,:,ieign)/norm
      left_full(:,:,:,ieign)=left_full(:,:,:,ieign)/norm      
      
      ! Linear transform from L,R back to x,y
      D_left_full(:,:,:,ieign)=(right_full(:,:,:,ieign)+left_full(:,:,:,ieign))/sqrt(2.0d0) !X
      C_right_full(:,:,:,ieign)=(right_full(:,:,:,ieign)-left_full(:,:,:,ieign))/sqrt(2.0d0) !Y

      normx=dble(lr_dot_us(D_left_full(1,1,1,ieign),D_left_full(1,1,1,ieign)))
      normy=-dble(lr_dot_us(C_right_full(1,1,1,ieign),C_right_full(1,1,1,ieign)))
      norm_F(ieign)=normx+normy  !! Actually norm_F should always be one since it was previously normalized
      
      write(stdout,'(/5x,"The two digitals below indicate the importance of doing beyong TDA: ")')
      write(stdout,'(/5x,"Components: X",2x,F12.5,";",4x,"Y",2x,F12.5)') &
               normx/norm_F(ieign),normy/norm_F(ieign)

      call lr_calc_Fxy(ieign)
    
      normx=0
      normy=0
      do iv = nbnd-p_nbnd_occ+1, nbnd
        do ic = 1, p_nbnd_virt
        normx=normx+Fx(iv,ic)*Fx(iv,ic)
        normy=normy-Fy(iv,ic)*Fy(iv,ic)
        enddo
      enddo
      if( normx+normy .lt. 0.0d0 ) then
        normx=-normx
        normy=-normy
      endif

      write (stdout,'(/5x,"In the occ-virt project subspace the total Fxy is:")')
      write(stdout,'(/5x,"X",2x,F12.5,";",4x,"Y",2x,F12.5,4x,"total",2x,F12.5,2x,&
              &"/ ",F12.5)') normx,normy,normx+normy,norm_F(ieign)
      
      do ipol = 1 ,3
        chi_dav(ipol,ieign)=dav_calc_chi("X",ieign,ipol)+dav_calc_chi("Y",ieign,ipol)
        chi_dav(ipol,ieign)=chi_dav(ipol,ieign)*chi_dav(ipol,ieign)*2.0d0/(PI*3)
      enddo

      total_chi(ieign)=chi_dav(1,ieign)+chi_dav(2,ieign)+chi_dav(3,ieign)

      write (stdout,'(/5x,"The Chi_i_i is",5x,"Total",10x,"1",15x,"2",15x,"3")')
      write (stdout,'(/12x,8x,E15.8,3x,E15.8,3x,E15.8,3x,E15.8)') total_chi(ieign),&
           &chi_dav(1,ieign),chi_dav(2,ieign), chi_dav(3,ieign)

     ! Components analysis
      write (stdout,'(/5x,"Now is the components analysis of this transition.")')

      call print_principle_components()

      write (stdout,'(/5x,"Now for all the calculated particle and hole pairs : ")')
      write (stdout,'(/5x,"occ",5x,"virt",7x,"FX",14x,"FY",/)')
      do iv = nbnd-p_nbnd_occ+1, nbnd
        do ic = 1, p_nbnd_virt
          write (stdout,'(3x,I5,I5,5x,E15.8,5x,E15.8)') iv, ic, dble(Fx(iv,ic)), dble(Fy(iv,ic))
        enddo
      enddo
      write(stdout,'(/7x,"**************",/)') 
    enddo

#ifdef __MPI
    if(ionode) then
#endif
      call write_eigenvalues()
      call write_spectrum()
#ifdef __MPI
    endif
#endif
    return
  end subroutine interpret_eign
  !-------------------------------------------------------------------------------

  real(dp) function dav_calc_chi(flag_calc,ieign,ipol)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Feb. 2013
    !-------------------------------------------------------------------------------
    ! This routine calculates the CHi from the igenvector
    use lr_dav_variables
    use lr_variables,    only : d0psi
    use kinds,    only : dp
    use lr_us
  
    implicit none
    character :: flag_calc
    integer :: ieign,ipol

    if( flag_calc .eq. "X" ) then
      dav_calc_chi=lr_dot_us(d0psi(:,:,1,ipol), D_left_full(:,:,1,ieign))
    else if (flag_calc .eq. "Y") then
      dav_calc_chi=lr_dot_us(d0psi(:,:,1,ipol), C_right_full(:,:,1,ieign))
    endif

    return
  end function dav_calc_chi
  !-------------------------------------------------------------------------------

  subroutine write_spectrum()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Feb. 2013
    !-------------------------------------------------------------------------------
    ! write the spectrum to ${prefix}.plot file
   
    use lr_dav_variables
    use io_files,      only : prefix
    use kinds,         only : dp
    use io_global,              only : stdout

    implicit none
    character(len=20) :: filename
    integer :: ieign, nstep, istep
    real(dp) :: frequency
    real(dp), allocatable :: absorption(:,:)
    
    Write(stdout,'(5x,"Now generate the spectrum plot file...")') 

    filename = trim(prefix)  // ".plot"
    OPEN(17,file=filename,status="unknown")

    write(17,'("#",2x,"Energy(Ry)",10x,"total",13x,"X",13x,"Y",13x,"Z")') 
    write(17,'("#  Broadening is: ",5x,F10.7,5x"Ry")') broadening
    
    nstep=(finish-start)/step+1
    allocate(absorption(nstep,5)) ! Column 1: Energy; 2: Toal; 3,4,5: X,Y,Z

    absorption(:,:)=0.0d0
    frequency=start
    istep=1
    do while( .not. istep .gt. nstep )
      absorption(istep,1)=frequency
      do ieign = 1,num_eign
        absorption(istep,2)=absorption(istep,2)+total_chi(ieign)*&
                            &func_broadening(frequency-tr_energy(eign_value_order(ieign)))
        absorption(istep,3)=absorption(istep,3)+chi_dav(1,ieign)*&
                            &func_broadening(frequency-tr_energy(eign_value_order(ieign)))
        absorption(istep,4)=absorption(istep,4)+chi_dav(2,ieign)*&
                            &func_broadening(frequency-tr_energy(eign_value_order(ieign)))
        absorption(istep,5)=absorption(istep,5)+chi_dav(3,ieign)*&
                            &func_broadening(frequency-tr_energy(eign_value_order(ieign)))
      enddo
      write(17,'(5E20.8)') absorption(istep,1),absorption(istep,1)*absorption(istep,2),&
                           absorption(istep,1)*absorption(istep,3),absorption(istep,1)*&
                           absorption(istep,4),absorption(istep,1)*absorption(istep,5)
      istep=istep+1
      frequency=frequency+step
    enddo

    deallocate(absorption)
    close(17)
    return
  end subroutine write_spectrum
  !-------------------------------------------------------------------------------
  
  real(dp) function func_broadening(delta)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Feb. 2013
    !-------------------------------------------------------------------------------
    ! Calculate the broadening with the energy diff
    use kinds,   only : dp
    use lr_dav_variables, only : broadening
    
    implicit none
    real(dp) :: delta
    
    func_broadening = broadening/(delta**2+broadening**2)

    return
  end function func_broadening
  !-------------------------------------------------------------------------------


  subroutine print_principle_components()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Feb. 2013
    !-------------------------------------------------------------------------------
    ! Print out the principle transition
    use lr_dav_variables
    use wvfct,          only : nbnd
    use kinds,          only : dp
    use lr_variables,   only : nbnd_total,R
    use io_global, only : stdout
   
    implicit none
    integer :: iv, ic
    real(dp) :: temp

    write (stdout,'(/5x,"Firt we print out only the principle components.")')
    write (stdout,'(/5x,"occ",5x,"virt",7x,"FX",14x,"FY"/)')
    do iv = nbnd-p_nbnd_occ+1, nbnd
      do ic = 1, p_nbnd_virt
        temp = Fx(iv,ic)*Fx(iv,ic)+Fy(iv,ic)*Fy(iv,ic)
        if(temp .gt. 0.01) then
          write (stdout,'(3x,I5,I5,5x,F10.5,5x,F10.5,5x,F10.5)') iv,ic, dble(Fx(iv,ic)), dble(Fy(iv,ic))
          !write (stdout,'(5x,"R 1,2,3",3F10.5)'), dble(R(iv,ic,1)),dble(R(iv,ic,2)),dble(R(iv,ic,3))
        endif
      enddo
    enddo
  end subroutine print_principle_components
 !-------------------------------------------------------------------------------

  real(dp) function calc_inter(v1,c1,v2,c2)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! calculate the interaction between two electron-hole pairs
    use kinds,         only : DP
    use wvfct,         only : nbnd,et
    use lr_dav_variables
    use lr_variables,         only : evc0, sevc0 ,revc0, evc0_virt
    use wvfct,                only : npwx,wg
    use fft_base,             only : dffts,dfftp
    use uspp,           only : okvan
    use io_global,    only : stdout
    use realus,              only : fft_orbital_gamma, bfft_orbital_gamma
    use wavefunctions_module, only : psic
    use cell_base,              only : omega
    use mp,                   only : mp_stop, mp_barrier

    implicit none
    integer :: v1,c1,v2,c2,ia,ir
    complex(dp) :: wfck(npwx,1)
    complex(dp), allocatable :: dvrss(:),wfcr(:),dvrs(:)
    real(dp) :: w1,temp
    real(kind=dp), external    :: ddot
   
    ALLOCATE( psic(dfftp%nnr) )
    ALLOCATE( dvrss(dffts%nnr) )
    !ALLOCATE( dvrs(dfftp%nnr) )

    if(okvan) then
      write(stdout,'(10x,"At this moment single-pole is not available for USPP !!!",//)')
#ifdef __MPI
      call mp_barrier
      call mp_stop(100)
#endif
      stop 
    endif
    
    w1=wg(v1,1)/omega

    wfck(:,1) = evc0(:,v1,1)

    call fft_orbital_gamma(wfck(:,:),1,1)  ! FFT: v1  -> psic
    dvrss(:) = psic(:)                        ! v1 -> dvrss
    
    wfck(:,1) = evc0_virt(:,c1-nbnd,1)
    call fft_orbital_gamma(wfck(:,:),1,1)  ! FFT: c1 -> psic
    do ir = 1, dffts%nnr
      dvrss(ir) = w1 * dvrss(ir) * psic(ir)         ! drho = 2*v1*c1 -> dvrss
    enddo

    call dv_of_drho(0,dvrss,.false.)       ! calc the potential change 

    wfck(:,1) = evc0(:,v2,1)
    call fft_orbital_gamma(wfck(:,:),1,1)  ! FFT: v2 -> psic
    do ir = 1, dffts%nnr
      psic(ir) = psic(ir) * dvrss(ir)      ! dv*v2 -> psic 
    enddo
    
    call bfft_orbital_gamma(wfck(:,:),1,1)  ! BFFT: dv*v2 -> wfck
   
    calc_inter = wfc_dot(wfck(:,1),evc0_virt(:,c2-nbnd,1))
  
    deallocate(psic)
    deallocate(dvrss)

    return 
   end function calc_inter
  !-------------------------------------------------------------------------------

  real(dp) function wfc_dot(x,y)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! calculate the inner product between two wfcs
    use kinds,          only : dp
    use wvfct,                only : npwx, npw
    use lr_dav_variables 
    use gvect,                only : gstart
    use mp_global,            only : intra_bgrp_comm,mpime
    use mp,                   only : mp_sum, mp_barrier
   
    implicit none
    real(kind=dp), external   :: ddot
    complex(dp) :: x(npwx), y (npwx)
    integer :: i

    wfc_dot=2.D0*ddot(2*npw,x(:),1,y(:),1)
    if(gstart==2) wfc_dot=wfc_dot-dble(x(1))*dble(y(1))

#ifdef __MPI
    call mp_barrier
    call mp_sum(wfc_dot,intra_bgrp_comm)
#endif

    return 
  end function wfc_dot
  !-------------------------------------------------------------------------------
    
  subroutine lr_calc_Fxy(ieign)
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Jan. 2013
    !-------------------------------------------------------------------------------
    ! This routine calculates the Fx and Fy for the ieign-th eigen vector
    use wvfct,   only : nbnd
    use lr_variables,  only : nbnd_total,evc0,sevc0_virt,R
    use lr_dav_variables 
    
    implicit none
    integer :: ic,iv, ieign
    real(dp) :: sum_F
    
    do iv = nbnd-p_nbnd_occ+1, nbnd
      do ic = 1, p_nbnd_virt
        Fx(iv,ic)=wfc_dot(D_left_full(:,iv,1,ieign),sevc0_virt(:,ic,1))/sqrt(norm_F(ieign))
        Fy(iv,ic)=wfc_dot(C_right_full(:,iv,1,ieign),sevc0_virt(:,ic,1))/sqrt(norm_F(ieign))
      enddo
    enddo
  end subroutine lr_calc_Fxy
  !-------------------------------------------------------------------------------

  subroutine random_init()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in May. 2013
    !-------------------------------------------------------------------------------
    ! This routine initiate basis set with radom vectors

    use kinds,          only : dp
    use wvfct,          only : g2kin,npwx,nbnd,et,npw
    use gvect,          only : gstart
    use klist,          only : nks
    use io_global,      only : stdout
    use lr_variables,   only : evc0, sevc0
    use lr_dav_variables

    implicit none
    integer :: ia, ib, ibnd, ipw
    real(dp) :: temp,R,R2
    
    write(stdout,'(5x,"Preconditional random vectors are used as initial vectors ...")')
    do ib = 1, num_init
      do ibnd = 1, nbnd
        do ipw = 1, npw
          call random_number(R)
          call random_number(R2)
          !apply precondition
          temp = g2kin(ipw)-et(ibnd,1)-reference
          if( abs(temp) .lt. 0.001d0 ) temp = sign(0.001d0,temp)
          vec_b(ipw,ibnd,1,ib)=cmplx(R,R2)/temp
        enddo
        if(gstart==2) vec_b(1,ibnd,1,ib)=&
          &cmplx(dble(vec_b(1,ibnd,1,ib)),0.0d0) ! Gamma point wfc must be real at g=0
      enddo
      call lr_norm(vec_b(1,1,1,ib)) ! For increase numerical stability
    enddo

    ! Orthogonalize to occupied states
    do ib = 1, num_init
      call lr_ortho(vec_b(:,:,:,ib), evc0(:,:,1), 1, 1,sevc0(:,:,1),.true.)
      call lr_norm(vec_b(1,1,1,ib))
    enddo

    ! GS orthogonalization, twice for numerical stability
    ! 1st
    do ib = 1, num_init
      call lr_norm(vec_b(1,1,1,ib))
      do ia = ib+1, num_init
        call lr_1to1orth(vec_b(1,1,1,ia),vec_b(1,1,1,ib))
      enddo
    enddo
    ! 2nd
    do ib = 1, num_init
      call lr_norm(vec_b(1,1,1,ib))
      do ia = ib+1, num_init
        call lr_1to1orth(vec_b(1,1,1,ia),vec_b(1,1,1,ib))
      enddo
    enddo

    return
  end subroutine random_init
  !-------------------------------------------------------------------------------

  subroutine write_eigenvalues()
    !-------------------------------------------------------------------------------
    ! Created by X.Ge in Feb. 2013
    !-------------------------------------------------------------------------------
    ! write the eigenvalues and their oscilator strength
   
    use lr_dav_variables
    use io_files,      only : prefix
    use kinds,         only : dp
    use io_global,     only : stdout

    implicit none
    character(len=20) :: filename
    integer :: ieign
    
    Write(stdout,'(5x,"Now generate the eigenvalues list...")') 

    filename = trim(prefix)  // ".eigen"
    OPEN(18,file=filename,status="unknown")
    write(18,'("#",2x,"Energy(Ry)",10x,"total",13x,"X",13x,"Y",13x,"Z")') 
    
    do ieign=1, num_eign
      write(18,'(5E20.8)') tr_energy(eign_value_order(ieign)),total_chi(ieign),&
                           chi_dav(1,ieign),chi_dav(2,ieign),chi_dav(3,ieign)
    enddo

    close(18)
    return
  end subroutine write_eigenvalues
  !-------------------------------------------------------------------------------

END MODULE lr_dav_routines
