!
!---------------------------------------------------------------------
subroutine read_pseudo (is, iunps, ierr)  
  !---------------------------------------------------------------------
  !
  !   read "is"-th pseudopotential in the Unified Pseudopotential Format
  !   from unit "iunps" - convert and copy to internal PWscf variables
  !   return error code in "ierr" (success: ierr=0)
  !
  ! CP90 modules
  !
  use ncprm, only: qfunc, qfcoef, rinner, qqq, rscore, rucore, r, rab, &
                   lll, nbeta, kkbeta, ifpcor, mesh, nqlc, nqf, &
                   betar, dion
  use dft_mod, only: dft
  use wfc_atomic, only: chi, lchi, nchi
  use ions_base, only: zv
  !
  use pseudo_types
  use read_pseudo_module
  !
  implicit none
  !
  integer :: is, iunps, ierr 
  !
  !     Local variables
  !
  integer :: nb, iexch, icorr, igcx, igcc, exfact
  integer, external :: cpv_dft
  TYPE (pseudo_upf) :: upf
  !
  !
  call read_pseudo_upf(iunps, upf, ierr)
  !
  if (ierr .ne. 0) then
    CALL deallocate_pseudo_upf( upf )
    return
  end if
  !
  zv(is)  = upf%zp
  ! psd (is)= upf%psd
  ! tvanp(is)=upf%tvanp
  if (upf%nlcc) then
     ifpcor(is) = 1
  else
     ifpcor(is) = 0
  end if
  !
  call which_dft (upf%dft, iexch, icorr, igcx, igcc)  
  !
  dft = cpv_dft (iexch, icorr, igcx, igcc)

  !
  mesh(is) = upf%mesh
  if (mesh(is) > mmaxx) call errore('read_pseudo','increase mmaxx',mesh(is))
  !
  nchi(is) = upf%nwfc
  lchi(1:upf%nwfc, is) = upf%lchi(1:upf%nwfc)
  ! oc(1:upf%nwfc, is) = upf%oc(1:upf%nwfc)
  chi(1:upf%mesh, 1:upf%nwfc, is) = upf%chi(1:upf%mesh, 1:upf%nwfc)

  !
  nbeta(is)= upf%nbeta
  kkbeta(is)=0
  do nb=1,upf%nbeta
     kkbeta(is)=max(upf%kkbeta(nb),kkbeta(is))
  end do
  betar(1:upf%mesh, 1:upf%nbeta, is) = upf%beta(1:upf%mesh, 1:upf%nbeta)
  dion(1:upf%nbeta, 1:upf%nbeta, is) = upf%dion(1:upf%nbeta, 1:upf%nbeta)
  !

  ! lmax(is) = upf%lmax
  nqlc(is) = upf%nqlc
  nqf (is) = upf%nqf
  lll(1:upf%nbeta,is) = upf%lll(1:upf%nbeta)
  rinner(1:upf%nqlc,is) = upf%rinner(1:upf%nqlc)
  qqq(1:upf%nbeta,1:upf%nbeta,is) = upf%qqq(1:upf%nbeta,1:upf%nbeta)
  qfunc (1:upf%mesh, 1:upf%nbeta, 1:upf%nbeta, is) = &
       upf%qfunc(1:upf%mesh,1:upf%nbeta,1:upf%nbeta)
  qfcoef(1:upf%nqf, 1:upf%nqlc, 1:upf%nbeta, 1:upf%nbeta, is ) = &
       upf%qfcoef( 1:upf%nqf, 1:upf%nqlc, 1:upf%nbeta, 1:upf%nbeta )

  !
  r  (1:upf%mesh, is) = upf%r  (1:upf%mesh)
  rab(1:upf%mesh, is) = upf%rab(1:upf%mesh)
  !
  if ( upf%nlcc) then
     rscore (1:upf%mesh, is) = upf%rho_atc(1:upf%mesh)
  else
     rscore (:,is) = 0.d0
  end if
  ! rsatom (1:upf%mesh, is) = upf%rho_at (1:upf%mesh)
  ! lloc(is) = 1

  !
  ! compatibility with Vanderbilt format: Vloc => r*Vloc
  rucore(1:upf%mesh, 1,is) = upf%vloc(1:upf%mesh) * upf%r  (1:upf%mesh)
  !

  ! compatibility with old Vanderbilt formats
  call fill_qrl(is)

  !
  CALL deallocate_pseudo_upf( upf )

  return

end subroutine read_pseudo
