!
!-----------------------------------------------------------------------
subroutine read_pseudo (file_pseudo,zed,xmin,rmax,dx,mesh,ndm, &
     r,r2,sqr,dft,lmax,lloc,zval,nlcc,rhoc,vnl,vnlo,vpsloc,rel)
  !-----------------------------------------------------------------------
  !
  use kinds, only : DP
  implicit none
  integer  ::    &
       ndm, &    ! input: the mesh dimensions
       rel, &    ! input: rel=2 for spin-orbit pseudopotential
       mesh,&    ! output: the number of mesh points
       lmax,&    ! output: the maximum angular momentum
       lloc      ! output: the local potential

  real(kind=dp) ::       &
       zed,            & ! input: the atomic charge
       zval,           & ! output: the valence charge
       xmin,dx,        & ! output: the mesh 
       rmax,           & ! output: the maximum mesh value
       r(ndm),r2(ndm), & ! output: the mesh
       sqr(ndm),       & ! output: the square root of the mesh
       vnl(ndm,0:3),   & ! output: the potential in numerical form
       vnlo(ndm,0:3,2),& ! output: the spin-orbit potential 
       vpsloc(ndm),    & ! output: the local pseudopotential
       rhoc(ndm)         ! output: the core charge

  logical :: &
       nlcc    ! output: if true the pseudopotential has nlcc

  character ::   &
       file_pseudo*20, &    ! input: the file with the pseudopotential
       dft*20              ! output: the type of xc

  integer :: &
       ios, i, l, k, ir, iunps, mesh1, &
       nbeta,nlc,nnl   

  real(kind=dp) :: &
       vnloc, a_core, b_core, &
       alfa_core, xmax, &
       cc(2),alpc(2),alc(6,0:3),alps(3,0:3),erf 

  logical :: &
       bhstype, numeric

  real(kind=dp), parameter :: fourpi=4.0_dp*3.141592653589793_dp

  character(len=3)  title_pseudo*70, cdum

  iunps=2
  open(unit=iunps,file=file_pseudo,status='old',form='formatted', &
       err=100, iostat=ios)
100 call errore('read_pseudo','open error on file '//file_pseudo,ios)
  !
  !     reads the starting lines
  !
  read( iunps, '(a)', end=300, err=300, iostat=ios ) dft
  if (dft(1:2).eq.'**') dft='LDA'
  if (dft(1:17).eq.'slater-pz-ggx-ggc') dft='PW'

  read ( iunps, *, err=300, iostat=ios ) cdum,  &
       zval, lmax, nlc, nnl, nlcc,  &
       lloc, bhstype

  if ( nlc.gt.2 .or. nnl.gt.3)  &
       call errore( 'read_pseudo','Wrong nlc or nnl', 1)
  if ( nlc .lt.0 .or. nnl .lt. 0 )  &
       call errore( 'read_pseudo','nlc or nnl < 0 ? ', 1 )
  if ( zval.le.0.0_dp )  &
       call errore( 'read_pseudo','Wrong zval ', 1 )

  !
  !   In numeric pseudopotentials both nlc and nnl are zero.
  !
  numeric = nlc.le.0 .and. nnl.le.0
  if (lloc.eq.-1000) lloc=lmax

  if (.not.numeric) then
     read( iunps, *, err=300, iostat=ios )  &
          ( alpc(i), i=1, 2 ), ( cc(i), i=1,2 )
     if ( abs(cc(1)+cc(2)-1.0_dp).gt.1.0e-6_dp) call errore  &
          ('read_pseudo','wrong pseudopotential coefficients',1)
     do l = 0, lmax
        read ( iunps, *, err=300, iostat=ios ) &
             ( alps(i,l),i=1,3 ), (alc(i,l),i=1,6)
     enddo
     if (nlcc) then
        read( iunps, *, err=300, iostat=ios ) a_core,  &
             b_core, alfa_core
        if (alfa_core.le.0.0_dp)  &
             call errore('readin','nlcc but alfa=0',1)
     endif
     if (cc(2).ne.0.0_dp.and.alpc(2).ne.0.0_dp.and.bhstype) then
        call bachel(alps,alc,1,lmax)
     endif

  endif
  !
  !     read the mesh parameters
  !
  read( iunps, *, err=300, iostat=ios ) zed, xmin, dx, mesh, nbeta
  xmax=(mesh-1)*dx+xmin
  rmax=exp(xmax)/zed
  !
  !    and generate the mesh: this overwrite the mesh defined in the
  !    input parameters
  !
  call do_mesh(rmax,zed,xmin,dx,0,ndm,mesh1,r,r2,sqr)
  if (mesh.ne.mesh1) &
       call errore('read_pseudo','something wrong in mesh',1)
  !
  !    outside this routine all pseudo are numeric: construct vnl and
  !    core charge
  !    
  if (.not.numeric) then
     if (nlcc) then 
        do ir=1, mesh
           rhoc(ir)=(a_core+b_core*r2(ir))*exp(-alfa_core*r2(ir)) &
                *r2(ir)*fourpi
        enddo
     else
        rhoc=0.0_dp
     endif
     do l=0,lmax
        do ir=1,mesh
           vnloc = 0.0_dp
           do k=1,3
              vnloc = vnloc + exp(-alps(k,l)*r2(ir))*  &
                   ( alc(k,l) + r2(ir)*alc(k+3,l) )
           enddo
           !
           !  NB: the factor 2 converts from hartree to rydbergs
           !
           vnl(ir,l) = 2.0_dp*vnloc-2.0_dp*zval/r(ir)*(cc(1)*  &
                erf(r(ir)*sqrt(alpc(1)))                &
                + cc(2)*erf(r(ir)*sqrt(alpc(2))))
        enddo
     enddo
  endif

  if (numeric) then
     !
     !      pseudopotenzials in numerical form
     !
     do l = 0, lmax
        if (rel.lt.2) then
           read( iunps, '(a)', err=300, iostat=ios )
           read( iunps, *, err=300, iostat=ios )  &
                (vnl(ir,l),ir=1,mesh)
        else
           read( iunps, '(a)', err=300, iostat=ios ) cdum
           read( iunps, *, err=300, iostat=ios )  &
                (vnlo(ir,l,1),ir=1,mesh)
           if (l.gt.0) then
              read( iunps, '(a)', err=300, iostat=ios ) cdum
              read( iunps, *, err=300, iostat=ios )  &
                   (vnlo(ir,l,2),ir=1,mesh)
           endif
        endif
     enddo

     if (lloc.eq.-1) then
        read( iunps, '(a)', err=300, iostat=ios )
        read( iunps, *, err=300, iostat=ios ) &
             (vpsloc(ir),ir=1,mesh)
     else
        vpsloc=0.0_dp
     endif
     if(nlcc) then
        read( iunps, *, err=300, iostat=ios )  &
             ( rhoc(ir), ir=1,mesh )
        do ir=1, mesh
           rhoc(ir)=rhoc(ir)*r2(ir)*fourpi
        enddo
     else
        rhoc=0.0_dp
     endif

  endif
300 call errore('read_pseudo','reading pseudofile',abs(ios))
  !
  !   all the components of the nonlocal potential beyond lmax are taken
  !   equal to vnl of lmax
  !
  do l=lmax+1,3
     vnl(:,l)=vnl(:,lmax)
  enddo

  close(iunps)
  return
end subroutine read_pseudo
