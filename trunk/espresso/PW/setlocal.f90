!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine setlocal
  !----------------------------------------------------------------------
  !
  !    This routine computes the local potential in real space vltot(ir)
  !
  USE kinds,     ONLY : DP
  USE constants, ONLY : eps8
  USE ions_base, ONLY : zv, ntyp => nsp
  USE cell_base, ONLY : omega
  USE extfield,  ONLY : tefield, dipfield, etotefield
  USE gvect,     ONLY : igtongl, gg
  USE scf,       ONLY : rho, v_of_0, vltot
  USE vlocal,    ONLY : strf, vloc
  USE fft_base,  ONLY : dfftp
  USE fft_interfaces,ONLY : invfft
  USE gvect,     ONLY : nl, nlm, ngm
  USE control_flags, ONLY : gamma_only
  USE mp_global, ONLY : intra_pool_comm
  USE mp,        ONLY : mp_sum
  USE martyna_tuckerman, ONLY : wg_corr_loc, do_comp_mt
  USE esm,       ONLY : esm_local, esm_bc, do_comp_esm

  !
  implicit none
  complex(DP), allocatable :: aux (:), v_corr(:)
  ! auxiliary variable
  integer :: nt, ng
  ! counter on atom types
  ! counter on g vectors
  !
  allocate (aux( dfftp%nnr))    
  aux(:)=(0.d0,0.d0)
  !
  if (do_comp_mt) then
     allocate(v_corr(ngm))
     call wg_corr_loc(omega,ntyp,ngm,zv,strf,v_corr)
     aux(nl(:)) = v_corr(:)
     deallocate(v_corr)
  end if
  !
  do nt = 1, ntyp
     do ng = 1, ngm
        aux (nl(ng))=aux(nl(ng)) + vloc (igtongl (ng), nt) * strf (ng, nt)
     enddo
  enddo
  if (gamma_only) then
     do ng = 1, ngm
        aux (nlm(ng)) = CONJG(aux (nl(ng)))
     enddo
  end if
  !
  IF ( do_comp_esm .and. ( esm_bc .ne. 'pbc' ) ) THEN
     !
     ! ... Perform ESM correction to local potential
     !
     CALL esm_local ( aux )
  ENDIF
  !
  ! ... v_of_0 is (Vloc)(G=0)
  !
  v_of_0=0.0_DP
  if (gg(1) < eps8) v_of_0 = DBLE ( aux (nl(1)) )
  call mp_sum( v_of_0, intra_pool_comm )
  !
  ! ... aux = potential in G-space . FFT to real space
  !
  CALL invfft ('Dense', aux, dfftp)
  !
  vltot (:) =  DBLE (aux (:) )
  !
  ! ... If required add an electric field to the local potential 
  !
  if ( tefield .and. ( .not. dipfield ) )  &
     call add_efield(vltot,etotefield,rho%of_r,.true.)
  !
  deallocate(aux)
  !
  return
end subroutine setlocal

