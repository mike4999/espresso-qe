!##############################################################################!
!#                                                                            #!
!#                                                                            #!
!#   This is the main one of a set of Fortran 90 files designed to compute    #!
!#   the electrical polarization in a crystaline solid.                       #!
!#                                                                            #!
!#                                                                            #!
!#   AUTHORS                                                                  #!
!#   ~~~~~~~                                                                  #!
!#   This set of subprograms is based on code written in an early Fortran     #!
!#   77 version of PWSCF by Alessio Filippetti. These were later ported       #!
!#   into another version by Lixin He. Oswaldo Dieguez, in collaboration      #!
!#   with Lixin He and Jeff Neaton, ported these routines into Fortran 90     #!
!#   version 1.2.1 of PWSCF. He, Dieguez, and Neaton were working at the      #!
!#   time in David Vanderbilt's group at Rutgers, The State University of     #!
!#   New Jersey, USA.                                                         #!
!#                                                                            #!
!#                                                                            #!
!#   LIST OF FILES                                                            #!
!#   ~~~~~~~~~~~~~                                                            #!
!#   The complete list of files added to the PWSCF distribution is:           #!
!#   * ../PW/bp_bess.f                                                        #!
!#   * ../PW/bp_calc_btq.f90                                                  #!
!#   * ../PW/bp_c_phase.f90                                                   #!
!#   * ../PW/bp_dbess.f                                                       #!
!#   * ../PW/bp_qvan3.f90                                                     #!
!#   * ../PW/bp_radin.f                                                       #!
!#   * ../PW/bp_strings.f90                                                   #!
!#   * ../PW/bp_ylm_q.f                                                       #!
!#   * ../PW/bp_zgedi.f                                                       #!
!#   * ../PW/bp_zgefa.f                                                       #!
!#                                                                            #!
!#   The PWSCF files that needed (minor) modifications were:                  #!
!#   * ../PW/electrons.f90                                                    #!
!#   * ../PW/input.f90                                                        #!
!#   * ../PW/pwcom.f90                                                        #!
!#   * ../PW/setup.f90                                                        #!
!#                                                                            #!
!#                                                                            #!
!#   BRIEF SUMMARY OF THE METHODOLOGY                                         #!
!#   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                         #!
!#   The spontaneous polarization has two contibutions, electronic            #!
!#   and ionic. With these additional routines, PWSCF will output both.       #!
!#                                                                            #!
!#   The ionic contribution is relatively trivial to compute, requiring       #!
!#   knowledge only of the atomic positions and core charges. The new         #!
!#   subroutines focus mainly on evaluating the electronic contribution,      #!
!#   computed as a Berry phase, i.e., a global phase property that can        #!
!#   be computed from inner products of Bloch states at neighboring           #!
!#   points in k-space.                                                       #!
!#                                                                            #!
!#   The standard procedure would be for the user to first perform a          #!
!#   self-consistent (sc) calculation to obtain a converged charge density.   #!
!#   With well-converged sc charge density, the user would then run one       #!
!#   or more non-self consistent (or "band structure") calculations,          #!
!#   using the same main code, but with a flag to ask for the polarization.   #!
!#   Each such run would calculate the projection of the polarization         #!
!#   onto one of the three primitive reciprocal lattice vectors. In           #!
!#   cases of high symmetry (e.g. a tetragonal ferroelectric phase), one      #!
!#   such run would suffice. In the general case of low symmetry, the         #!
!#   user would have to submit up to three jobs to compute the three          #!
!#   components of polarization, and would have to obtain the total           #!
!#   polarization "by hand" by summing these contributions.                   #!
!#                                                                            #!
!#   Accurate calculation of the electronic or "Berry-phase" polarization     #!
!#   requires overlaps between wavefunctions along fairly dense lines (or     #!
!#   "strings") in k-space in the direction of the primitive G-vector for     #!
!#   which one is calculating the projection of the polarization. The         #!
!#   code would use a higher-density k-mesh in this direction, and a          #!
!#   standard-density mesh in the two other directions. See below for         #!
!#   details.                                                                 #!
!#                                                                            #!
!#                                                                            #!
!#   FUNCTIONALITY/COMPATIBILITY                                              #!
!#   ~~~~~~~~~~~~~~~~~~~~~~~~~~~                                              #!
!#   * Berry phases for a given G-vector.                                     #!
!#                                                                            #!
!#   * Contribution to the polarization (in relevant units) for a given       #!
!#     G-vector.                                                              #!
!#                                                                            #!
!#   * Spin-polarized systems supported.                                      #!
!#                                                                            #!
!#   * Ultrasoft and norm-conserving pseudopotentials supported.              #!
!#                                                                            #!
!#   * The value of the "polarization quantum" and the ionic contribution     #!
!#     to the polarization are reported.                                      #!
!#                                                                            #!
!#                                                                            #!
!#   NEW INPUT PARAMETERS                                                     #!
!#   ~~~~~~~~~~~~~~~~~~~~                                                     #!
!#   * lberry (.TRUE. or .FALSE.)                                             #!
!#     Tells PWSCF that a Berry phase calcultion is desired.                  #!
!#                                                                            #!
!#   * gdir (1, 2, or 3)                                                      #!
!#     Specifies the direction of the k-point strings in reciprocal space.    #!
!#     '1' refers to the first reciprocal lattice vector, '2' to the          #!
!#     second, and '3' to the third.                                          #!
!#                                                                            #!
!#   * nppstr (integer)                                                       #!
!#     Specifies the number of k-points to be calculated along each           #!
!#     symmetry-reduced string.                                               #!
!#                                                                            #!
!#                                                                            #!
!#   EXPLANATION OF K-POINT MESH                                              #!
!#   ~~~~~~~~~~~~~~~~~~~~~~~~~~~                                              #!
!#   If gdir=1, the program takes the standard input specification of the     #!
!#   k-point mesh (nk1 x nk2 x nk3) and stops if the k-points in dimension    #!
!#   1 are not equally spaced or if its number is not equal to nppstr,        #!
!#   working with a mesh of dimensions (nppstr x nk2 x nk3).  That is, for    #!
!#   each point of the (nk2 x nk3) two-dimensional mesh, it works with a      #!
!#   string of nppstr k-points extending in the third direction.  Symmetry    #!
!#   will be used to reduce the number of strings (and assign them weights)   #!
!#   if possible.  Of course, if gdir=2 or 3, the variables nk2 or nk3 will   #!
!#   be overridden instead, and the strings constructed in those              #!
!#   directions, respectively.                                                #!
!#                                                                            #!
!#                                                                            #!
!#   BIBLIOGRAPHY                                                             #!
!#   ~~~~~~~~~~~~                                                             #!
!#   The theory behind this implementation is described in:                   #!
!#   [1] R D King-Smith and D Vanderbilt, "Theory of polarization of          #!
!#       crystaline solids", Phys Rev B 47, 1651 (1993).                      #!
!#                                                                            #!
!#   Other relevant sources of information are:                               #!
!#   [2] D Vanderbilt and R D King-Smith, "Electronic polarization in the     #!
!#       ultrasoft pseudopotential formalism", internal report (1998),        #!
!#   [3] D Vanderbilt, "Berry phase theory of proper piezoelectric            #!
!#       response", J Phys Chem Solids 61, 147 (2000).                        #!
!#                                                                            #!
!#                                                                            #!
!#                                              dieguez@physics.rutgers.edu   #!
!#                                                             09 June 2003   #!
!#                                                                            #!
!#                                                                            #!
!##############################################################################!



!======================================================================!

SUBROUTINE c_phase

!----------------------------------------------------------------------!

!   Geometric phase calculation along a strip of nppstr k-points
!   averaged over a 2D grid of nkort k-points ortogonal to nppstr 

#include "machine.h"

!  --- Make use of the module with common information ---
   USE kinds, ONLY: DP
   USE parameters, ONLY: nbrx
   USE io_global,        ONLY : stdout
   USE io_files, ONLY: iunwfc, nwordwfc
   USE basis, ONLY: nat, ntyp, ityp, tau, zv, atm
   USE cell_base, ONLY: at, alat, tpiba, omega, tpiba2
   USE constants, ONLY: pi, tpi
   USE gvect, ONLY: ngm, nr1, nr2, nr3, nrx1, nrx2, nrx3, ecutwfc, &
        g, gcutm
   USE us, ONLY: lqx, nhm, nkb, vkb, nh
   USE lsda_mod, ONLY: nspin
   USE klist, ONLY: nelec, degauss, nks, xk, wk
   USE wvfct, ONLY: npwx, npw, nbnd
   USE wavefunctions_module,    ONLY : evc
   USE bp, ONLY: gdir, nppstr
!  --- Avoid implicit definitions ---
   IMPLICIT NONE

!  --- Internal definitions ---
   INTEGER :: i
   INTEGER :: igk1(npwx)
   INTEGER :: igk0(npwx)
   INTEGER :: ik
   INTEGER :: ind1
   INTEGER :: info
   INTEGER :: is
   INTEGER :: istring
   INTEGER :: iv
   INTEGER :: ivpt(nbnd)
   INTEGER :: j
   INTEGER :: jkb
   INTEGER :: jkb_bp
   INTEGER :: jkb1
   INTEGER :: job
   INTEGER :: jv
   INTEGER :: kindex
   INTEGER :: kort
   INTEGER :: kpar
   INTEGER :: kpoint
   INTEGER :: kstart
   INTEGER :: mb
   INTEGER :: mk1
   INTEGER :: mk2
   INTEGER :: mk3
   INTEGER , ALLOCATABLE :: mod_elec(:)
   INTEGER :: mod_elec_dw
   INTEGER :: mod_elec_tot
   INTEGER :: mod_elec_up
   INTEGER :: mod_ion(nat)
   INTEGER :: mod_ion_dw
   INTEGER :: mod_ion_tot
   INTEGER :: mod_ion_up
   INTEGER :: mod_tot
   INTEGER :: n1
   INTEGER :: n2
   INTEGER :: n3
   INTEGER :: na
   INTEGER :: nb
   INTEGER :: ng
   INTEGER :: nhjkb
   INTEGER :: nhjkbm
   INTEGER :: nkbtona(nkb)
   INTEGER :: nkbtonh(nkb)
   INTEGER :: nkort
   INTEGER :: np
   INTEGER :: npw1
   INTEGER :: npw0
   INTEGER :: nstring
   INTEGER :: nt
   LOGICAL :: lodd
   REAL(dp) :: dk(3)
   REAL(dp) :: dkmod
   REAL(dp) :: el_loc
   REAL(dp) :: eps
   REAL(dp) :: fac
   REAL(dp) :: g2kin_bp(npwx)
   REAL(dp) :: gpar(3)
   REAL(dp) :: gtr(3)
   REAL(dp) :: gvec
   REAL(dp) :: ln(-nr1:nr1,-nr2:nr2,-nr3:nr3)
   REAL(dp), ALLOCATABLE :: loc_k(:)
   REAL(dp) , ALLOCATABLE :: pdl_elec(:)
   REAL(dp) :: pdl_elec_dw
   REAL(dp) :: pdl_elec_tot
   REAL(dp) :: pdl_elec_up
   REAL(dp) :: pdl_ion(nat)
   REAL(dp) :: pdl_ion_dw
   REAL(dp) :: pdl_ion_tot
   REAL(dp) :: pdl_ion_up
   REAL(dp) :: pdl_tot
   REAL(dp) , ALLOCATABLE :: phik(:)
   REAL(dp) :: phidw
   REAL(dp) :: phiup
   REAL(dp) :: rmod
   REAL(dp) :: qrad_dk(nbrx,nbrx,lqx,ntyp)
   REAL(dp) :: upol(3)
   REAL(dp) :: weight
   REAL(dp), ALLOCATABLE :: wstring(:)
   REAL(dp) :: ylm_dk(lqx*lqx)
   REAL(dp) :: zeta_mod
   COMPLEX(dp) :: aux(ngm)
   COMPLEX(dp) :: aux0(ngm)
   COMPLEX(dp) :: becp0(nkb,nbnd)
   COMPLEX(dp) :: becp_bp(nkb,nbnd)
   COMPLEX(dp) :: cdet(2)
   COMPLEX(dp) :: cdwork(nbnd)
   COMPLEX(dp) :: cave
   COMPLEX(dp) :: cave_dw
   COMPLEX(dp) :: cave_up
   COMPLEX(dp) , ALLOCATABLE :: cphik(:)
   COMPLEX(dp) :: det
   COMPLEX(dp) :: dtheta
   COMPLEX(dp) :: mat(nbnd,nbnd)
   COMPLEX(dp) :: pref
   COMPLEX(dp) :: psi(npwx,nbnd)
   COMPLEX(dp) :: q_dk(nhm,nhm,ntyp)
   COMPLEX(dp) :: struc(nat)
   COMPLEX(dp) :: theta0
   COMPLEX(dp) :: ZDOTC
   COMPLEX(dp) :: zeta


!  -------------------------------------------------------------------------   !
!                               INITIALIZATIONS
!  -------------------------------------------------------------------------   !

!  --- Write header ---
   WRITE( stdout,"(/,/,/,15X,50('='))")
   WRITE( stdout,"(28X,'POLARIZATION CALCULATION')")
   WRITE( stdout,"(25X,'!!! NOT THOROUGHLY TESTED !!!')")
   WRITE( stdout,"(15X,50('-'),/)")

!  --- Check that we are working with an insulator with no empty bands ---
   IF ((degauss > 0.01) .OR. (nbnd /= nelec/2)) CALL errore('c_phase', &
                'Polarization only for insulators and no empty bands',1)

!  --- Define a small number ---
   eps=1.0E-6_dp

!  --- Recalculate FFT correspondence (see ggen.f90) ---
   DO ng=1,ngm
      mk1=nint(g(1,ng)*at(1,1)+g(2,ng)*at(2,1)+g(3,ng)*at(3,1))
      mk2=nint(g(1,ng)*at(1,2)+g(2,ng)*at(2,2)+g(3,ng)*at(3,2))
      mk3=nint(g(1,ng)*at(1,3)+g(2,ng)*at(2,3)+g(3,ng)*at(3,3))
      ln(mk1,mk2,mk3) = ng
   END DO

!  --- Initialize arrays ---
   jkb_bp=0
   DO nt=1,ntyp
      DO na=1,nat
         IF (ityp(na).eq.nt) THEN
            DO i=1, nh(nt)
               jkb_bp=jkb_bp+1
               nkbtona(jkb_bp) = na
               nkbtonh(jkb_bp) = i
            END DO
         END IF
      END DO
   END DO
    
!  --- Get the number of strings ---
   nstring=nks/nppstr
   nkort=nstring/(nspin)

!  --- Allocate memory for arrays ---
   ALLOCATE(phik(nstring))
   ALLOCATE(loc_k(nstring))
   ALLOCATE(cphik(nstring))
   ALLOCATE(wstring(nstring))
   ALLOCATE(pdl_elec(nstring))
   ALLOCATE(mod_elec(nstring))


!  -------------------------------------------------------------------------   !
!           electronic polarization: set values for k-points strings           !
!  -------------------------------------------------------------------------   !

!  --- Find vector along strings ---
   gpar(1)=xk(1,nppstr)-xk(1,1)
   gpar(2)=xk(2,nppstr)-xk(2,1)
   gpar(3)=xk(3,nppstr)-xk(3,1)
   gvec=dsqrt(gpar(1)**2+gpar(2)**2+gpar(3)**2)*tpiba

!  --- Find vector between consecutive points in strings ---
   dk(1)=xk(1,2)-xk(1,1)
   dk(2)=xk(2,2)-xk(2,1) 
   dk(3)=xk(3,2)-xk(3,1)
   dkmod=SQRT(dk(1)**2+dk(2)**2+dk(3)**2)*tpiba
   IF (ABS(dkmod-gvec/(nppstr-1)) > eps) & 
     CALL errore('c_phase','Wrong k-strings?',1)

!  --- Check that k-points form strings ---
   DO i=1,nspin*nkort
      DO j=2,nppstr
         kindex=j+(i-1)*nppstr
         IF (ABS(xk(1,kindex)-xk(1,kindex-1)-dk(1)) > eps) &
            CALL errore('c_phase','Wrong k-strings?',1)
         IF (ABS(xk(2,kindex)-xk(2,kindex-1)-dk(2)) > eps) &
            CALL errore('c_phase','Wrong k-strings?',1)
         IF (ABS(xk(3,kindex)-xk(3,kindex-1)-dk(3)) > eps) &
            CALL errore('c_phase','Wrong k-strings?',1)
         IF (ABS(wk(kindex)-wk(kindex-1)) > eps) &
            CALL errore('c_phase','Wrong k-strings weights?',1)
      END DO
   END DO


!  -------------------------------------------------------------------------   !
!                   electronic polarization: weight strings                    !
!  -------------------------------------------------------------------------   !

!  --- Calculate string weights, normalizing to 1 (no spin) or 1+1 (spin) ---
   DO is=1,nspin
      weight=0.0_dp
      DO kort=1,nkort
         istring=kort+(is-1)*nkort
         wstring(istring)=wk(nppstr*istring)
         weight=weight+wstring(istring)
      END DO
      DO kort=1,nkort
         istring=kort+(is-1)*nkort
         wstring(istring)=wstring(istring)/weight
      END DO
   END DO


!  -------------------------------------------------------------------------   !
!                  electronic polarization: structure factor                   !
!  -------------------------------------------------------------------------   !

!  --- Calculate structure factor e^{-i dk*R} ---
   DO na=1,nat
      fac=(dk(1)*tau(1,na)+dk(2)*tau(2,na)+dk(3)*tau(3,na))*tpi 
      struc(na)=CMPLX(cos(fac),-sin(fac))
   END DO


!  -------------------------------------------------------------------------   !
!                     electronic polarization: form factor                     !
!  -------------------------------------------------------------------------   !

!  --- Calculate Bessel transform of Q_ij(|r|) at dk [Q_ij^L(|r|)] ---
   CALL calc_btq(dkmod,qrad_dk,0)

!  --- Calculate the q-space real spherical harmonics at dk [Y_LM] --- 
   CALL ylm_q(lqx*lqx,dk,dkmod,ylm_dk)

!  --- Form factor: 4 pi sum_LM c_ij^LM Y_LM(Omega) Q_ij^L(|r|) ---
   q_dk(:,:,:) = (0.d0, 0.d0)
   DO np =1, ntyp
      DO iv = 1, nh(np)
         DO jv = iv, nh(np)
            call qvan3(iv,jv,np,pref,ylm_dk,qrad_dk)
            q_dk(iv,jv,np) = omega*pref
            q_dk(jv,iv,np) = omega*pref
         ENDDO
      ENDDO
   ENDDO


!  -------------------------------------------------------------------------   !
!                   electronic polarization: strings phases                    !
!  -------------------------------------------------------------------------   !

   el_loc   = 0.d0
   kpoint=0

!  --- Start loop over spin ---
   DO is=1,nspin 
       
!     --- Start loop over orthogonal k-points ---
      DO kort=1,nkort

!        --- Index for this string ---
         istring=kort+(is-1)*nkort

!        --- Initialize expectation value of the phase operator ---
         zeta=(1.d0,0.d0)
         zeta_mod = 1.d0

!        --- Start loop over parallel k-points ---
         DO kpar = 1,nppstr

!           --- Set index of k-point ---
            kpoint = kpoint + 1

!           --- Calculate dot products between wavefunctions and betas ---
            IF (kpar /= 1) THEN

!              --- Dot wavefunctions and betas for PREVIOUS k-point ---
               CALL gk_sort(xk(1,kpoint-1),ngm,g,ecutwfc/tpiba2, &
                            npw0,igk0,g2kin_bp) 
               CALL davcio(psi,nwordwfc,iunwfc,kpoint-1,-1)
               CALL init_us_2 (npw0,igk0,xk(1,kpoint-1),vkb)
               CALL ccalbec(nkb, npwx, npw, nbnd, becp0, vkb, psi)

!              --- Dot wavefunctions and betas for CURRENT k-point ---
               IF (kpar /= nppstr) THEN
                  CALL gk_sort(xk(1,kpoint),ngm,g,ecutwfc/tpiba2, &
                               npw1,igk1,g2kin_bp)        
                  CALL davcio(evc,nwordwfc,iunwfc,kpoint,-1)
                  CALL init_us_2 (npw1,igk1,xk(1,kpoint),vkb)
                  CALL ccalbec(nkb,npwx,npw,nbnd,becp_bp,vkb,evc)
               ELSE
                  kstart = kpoint-nppstr+1
                  CALL gk_sort(xk(1,kstart),ngm,g,ecutwfc/tpiba2, &
                               npw1,igk1,g2kin_bp)  
                  CALL davcio(evc,nwordwfc,iunwfc,kstart,-1)
                  CALL init_us_2 (npw1,igk1,xk(1,kstart),vkb)
                  CALL ccalbec(nkb,npwx,npw,nbnd,becp_bp,vkb,evc)
               ENDIF

!              --- Matrix elements calculation ---
               mat(:,:) = (0.d0, 0.d0)
               DO nb=1,nbnd
                  DO mb=1,nbnd
                     aux(:) = (0.d0, 0.d0)
                     aux0(:)= (0.d0, 0.d0)
                     DO ik=1,npw0
                        aux0(igk0(ik))=psi(ik,nb)
                     END DO    
                     DO ik=1,npw1
                        IF (kpar /= nppstr) THEN
                           aux(igk1(ik))=evc(ik,mb)
                        ELSE
!                          --- If k'=k+G_o, the relation psi_k+G_o (G-G_o) ---
!                          --- = psi_k(G) is used, gpar=G_o, gtr = G-G_o ---
                           gtr(1)=g(1,igk1(ik))-gpar(1)
                           gtr(2)=g(2,igk1(ik))-gpar(2) 
                           gtr(3)=g(3,igk1(ik))-gpar(3) 
!                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
!                          --- and the position ng in the ngm array ---
                           IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
                              n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
                                     +gtr(3)*at(3,1))
                              n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
                                     +gtr(3)*at(3,2))
                              n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
                                     +gtr(3)*at(3,3))
                              ng=ln(n1,n2,n3) 
                              IF ((ABS(g(1,ng)-gtr(1)) > eps) .OR. &
                                  (ABS(g(2,ng)-gtr(2)) > eps) .OR. &
                                  (ABS(g(3,ng)-gtr(3)) > eps)) THEN
                                 WRITE( stdout,*) ' error: translated G=', &
                                      gtr(1),gtr(2),gtr(3), &
                                      ' with crystal coordinates',n1,n2,n3, &
                                      ' corresponds to ng=',ng,' but G(ng)=', &
                                      g(1,ng),g(2,ng),g(3,ng)
                                 WRITE( stdout,*) ' probably because G_par is NOT', &
                                            ' a reciprocal lattice vector '
                                 WRITE( stdout,*) ' Possible choices as smallest ', &
                                            ' G_par:'
                                 DO i=1,50
                                    WRITE( stdout,*) ' i=',i,'   G=', &
                                         g(1,i),g(2,i),g(3,i)
                                 ENDDO
                                 STOP
                              ENDIF
                           ELSE 
                              WRITE( stdout,*) ' |gtr| > gcutm  for gtr=', &
                                   gtr(1),gtr(2),gtr(3) 
                              STOP
                           END IF
                           aux(ng)=evc(ik,mb)
                        ENDIF
                     END DO
                     mat(nb,mb) = ZDOTC (ngm,aux0,1,aux,1)
                  end do
               end do
#ifdef __PARA
               call reduce(2*nbnd*nbnd,mat)
#endif
               DO nb=1,nbnd
                  DO mb=1,nbnd
!                    --- Calculate the augmented part: ij=KB projectors, ---
!                    --- R=atom index: SUM_{ijR} q(ijR) <u_nk|beta_iR>   ---
!                    --- <beta_jR|u_mk'> e^i(k-k')*R =                   ---
!                    --- also <u_nk|beta_iR>=<psi_nk|beta_iR> = becp^*   ---
                     pref = (0.d0,0.d0)
                     DO jkb=1,nkb
                        nhjkb = nkbtonh(jkb)
                        na = nkbtona(jkb)
                        np = ityp(na)
                        nhjkbm = nh(np)
                        jkb1 = jkb - nhjkb
                        DO j = 1,nhjkbm
                           pref = pref+conjg(becp0(jkb,nb))*becp_bp(jkb1+j,mb) &
                                  *q_dk(nhjkb,j,np)*struc(na)
                        ENDDO
                     ENDDO
                     mat(nb,mb) = mat(nb,mb) + pref
                  ENDDO
               ENDDO

!              --- Calculate matrix determinant ---
               CALL zgefa(mat,nbnd,nbnd,ivpt,info)
               CALL errore('c_phase','error in zgefa',abs(info))
               job=10
               CALL zgedi(mat,nbnd,nbnd,ivpt,cdet,cdwork,job)
               det=cdet(1)*10.d0**cdet(2)

!              --- Multiply by the already calculated determinants ---
               zeta=zeta*det

!           --- End of dot products between wavefunctions and betas ---
            ENDIF

!        --- End loop over parallel k-points ---
         END DO 

!        --- Calculate the phase for this string ---
         phik(istring)=DIMAG(LOG(zeta))
         cphik(istring)=COS(phik(istring))*(1.0_dp,0.0_dp) &
                     +SIN(phik(istring))*(0.0_dp,1.0_dp)

!        --- Calculate the localization for current kort ---
         zeta_mod=DREAL(conjg(zeta)*zeta)
         loc_k(istring)= - (nppstr-1) / gvec**2 / nbnd *log(zeta_mod)

!     --- End loop over orthogonal k-points ---
      END DO

!  --- End loop over spin ---
   END DO


!  -------------------------------------------------------------------------   !
!                    electronic polarization: phase average                    !
!  -------------------------------------------------------------------------   !

!  --- Initializations ---
   cave_up=(0.0_dp,0.0_dp)
   cave_dw=(0.0_dp,0.0_dp)

!  --- Start loop over spins ---
   DO is=1,nspin

!  --- Initialize average of phases as complex numbers ---
      cave=(0.0_dp,0.0_dp)

!     --- Start loop over strings with same spin ---
      DO kort=1,nkort

!        --- Calculate string index ---
         istring=kort+(is-1)*nkort

!        --- Average phases as complex numbers ---
         cave=cave+wstring(istring)*cphik(istring)

!     --- End loop over strings with same spin ---
      END DO

!     --- Get the angle corresponding to the complex numbers average ---
      theta0=atan2(DIMAG(cave),DREAL(cave))

!     --- Assign this angle to the corresponding spin phase average ---
      IF (nspin == 1) THEN
         phiup=theta0
         phidw=theta0
      ELSE IF (nspin == 2) THEN
         IF (is == 1) THEN
            phiup=theta0
         ELSE IF (is == 2) THEN
            phidw=theta0
         END IF
      END IF

!     --- Put the phases in an around theta0 ---
      cphik(istring)=cphik(istring)/cave
      dtheta=atan2(DIMAG(cphik(istring)),DREAL(cphik(istring)))
      phik(istring)=theta0+dtheta

!  --- End loop over spins
   END DO


!  -------------------------------------------------------------------------   !
!                     electronic polarization: remap phases                    !
!  -------------------------------------------------------------------------   !

!  --- Remap string phases to interval [-0.5,0.5) ---
   pdl_elec=phik/(2.0_dp*pi)
   mod_elec=1

!  --- Remap spin average phases to interval [-0.5,0.5) ---
   pdl_elec_up=phiup/(2.0_dp*pi)
   mod_elec_up=1
   pdl_elec_dw=phidw/(2.0_dp*pi)
   mod_elec_dw=1

!  --- Depending on nspin, remap total phase to [-1,1) or [-0.5,0.5) ---
   pdl_elec_tot=pdl_elec_up+pdl_elec_dw
   IF (nspin == 1) THEN
      pdl_elec_tot=pdl_elec_tot-2.0_dp*NINT(pdl_elec_tot/2.0_dp)
      mod_elec_tot=2
   ELSE IF (nspin == 2) THEN
      pdl_elec_tot=pdl_elec_tot-1.0_dp*NINT(pdl_elec_tot/1.0_dp)
      mod_elec_tot=1
   END IF


!  -------------------------------------------------------------------------   !
!                              ionic polarization                              !
!  -------------------------------------------------------------------------   !

!  --- Look for ions with odd number of charges ---
   mod_ion=2
   lodd=.FALSE.
   DO na=1,nat
      IF (MOD(NINT(zv(ityp(na))),2) == 1) THEN
         mod_ion(na)=1
         lodd=.TRUE.
      END IF
   END DO

!  --- Calculate ionic polarization phase for every ion ---
   pdl_ion=0.0_dp
   DO na=1,nat
      DO i=1,3
         pdl_ion(na)=pdl_ion(na)+zv(ityp(na))*tau(i,na)*gpar(i)
      ENDDO
      IF (mod_ion(na) == 1) THEN
         pdl_ion(na)=pdl_ion(na)-1.0_dp*nint(pdl_ion(na)/1.0_dp)
      ELSE IF (mod_ion(na) == 2) THEN
         pdl_ion(na)=pdl_ion(na)-2.0_dp*nint(pdl_ion(na)/2.0_dp)
      END IF
   ENDDO

!  --- Add up the phases modulo 2 iff the ionic charges are even numbers ---
   pdl_ion_tot=SUM(pdl_ion(1:nat))
   IF (lodd) THEN
      pdl_ion_tot=pdl_ion_tot-1.d0*nint(pdl_ion_tot/1.d0)
      mod_ion_tot=1
   ELSE
      pdl_ion_tot=pdl_ion_tot-2.d0*nint(pdl_ion_tot/2.d0)
      mod_ion_tot=2
   END IF


!  -------------------------------------------------------------------------   !
!                              total polarization                              !
!  -------------------------------------------------------------------------   !

!  --- Add electronic and ionic contributions to total phase ---
   pdl_tot=pdl_elec_tot+pdl_ion_tot
   IF ((.NOT.lodd).AND.(nspin == 1)) THEN
      mod_tot=2
   ELSE
      mod_tot=1
   END IF


!  -------------------------------------------------------------------------   !
!                           write output information                           !
!  -------------------------------------------------------------------------   !

!  --- Information about the k-points string used ---
   WRITE( stdout,"(/,21X,'K-POINTS STRINGS USED IN CALCULATIONS')")
   WRITE( stdout,"(21X,37('~'),/)")
   WRITE( stdout,"(7X,'G-vector along string (2 pi/a):',3F9.5)") &
           gpar(1),gpar(2),gpar(3)
   WRITE( stdout,"(7X,'Modulus of the vector (1/bohr):',F9.5)") &
           gvec
   WRITE( stdout,"(7X,'Number of k-points per string:',I4)") nppstr
   WRITE( stdout,"(7X,'Number of different strings  :',I4)") nkort

!  --- Information about ionic polarization phases ---
   WRITE( stdout,"(2/,31X,'IONIC POLARIZATION')")
   WRITE( stdout,"(31X,18('~'),/)")
   WRITE( stdout,"(8X,'Note: (mod 1) means that the phases (angles ranging from' &
           & /,8X,'-pi to pi) have been mapped to the interval [-1/2,+1/2) by',&
           & /,8X,'dividing by 2*pi; (mod 2) refers to the interval [-1,+1)',&
           & /)")
   WRITE( stdout,"(2X,76('='))")
   WRITE( stdout,"(4X,'Ion',4X,'Species',4X,'Charge',14X, &
           & 'Position',16X,'Phase')")
   WRITE( stdout,"(2X,76('-'))")
   DO na=1,nat
      WRITE( stdout,"(3X,I3,8X,A2,F12.3,5X,3F8.4,F12.5,' (mod ',I1,')')") &
           & na,atm(ityp(na)),zv(ityp(na)), &
           & tau(1,na),tau(2,na),tau(3,na),pdl_ion(na),mod_ion(na)
   END DO
   WRITE( stdout,"(2X,76('-'))")
   WRITE( stdout,"(47X,'IONIC PHASE: ',F9.5,' (mod ',I1,')')") pdl_ion_tot,mod_ion_tot
   WRITE( stdout,"(2X,76('='))")

!  --- Information about electronic polarization phases ---
   WRITE( stdout,"(2/,28X,'ELECTRONIC POLARIZATION')")
   WRITE( stdout,"(28X,23('~'),/)")
   WRITE( stdout,"(8X,'Note: (mod 1) means that the phases (angles ranging from' &
           & /,8X,'-pi to pi) have been mapped to the interval [-1/2,+1/2) by',&
           & /,8X,'dividing by 2*pi; (mod 2) refers to the interval [-1,+1)',&
           & /)")
   WRITE( stdout,"(2X,76('='))")
   WRITE( stdout,"(3X,'Spin',4X,'String',5X,'Weight',6X, &
            &  'First k-point in string',9X,'Phase')")
   WRITE( stdout,"(2X,76('-'))")
   DO istring=1,nstring/nspin
      ind1=1+(istring-1)*nppstr
      WRITE( stdout,"(3X,' up ',3X,I5,F14.6,4X,3(F8.4),F12.5,' (mod ',I1,')')") &
          &  istring,wstring(istring), &
          &  xk(1,ind1),xk(2,ind1),xk(3,ind1),pdl_elec(istring),mod_elec(istring)
   END DO
   WRITE( stdout,"(2X,76('-'))")
!  --- Treat unpolarized/polarized spin cases ---
   IF (nspin == 1) THEN
!     --- In unpolarized spin, just copy again the same data ---
      DO istring=1,nstring
         ind1=1+(istring-1)*nppstr
         WRITE( stdout,"(3X,'down',3X,I5,F14.6,4X,3(F8.4),F12.5,' (mod ',I1,')')") &
              istring,wstring(istring), xk(1,ind1),xk(2,ind1),xk(3,ind1), &
              pdl_elec(istring),mod_elec(istring)
      END DO
   ELSE IF (nspin == 2) THEN
!     --- If there is spin polarization, write information for new strings ---
      DO istring=nstring/2+1,nstring
         ind1=1+(istring-1)*nppstr
         WRITE( stdout,"(3X,'down',3X,I4,F15.6,4X,3(F8.4),F12.5,' (mod ',I1,')')") &
           &    istring,wstring(istring), xk(1,ind1),xk(2,ind1),xk(3,ind1), &
           &    pdl_elec(istring),mod_elec(istring)
      END DO
   END IF
   WRITE( stdout,"(2X,76('-'))")
   WRITE( stdout,"(40X,'Average phase (up): ',F9.5,' (mod ',I1,')')") & 
        pdl_elec_up,mod_elec_up
   WRITE( stdout,"(38X,'Average phase (down): ',F9.5,' (mod ',I1,')')")& 
        pdl_elec_dw,mod_elec_dw
   WRITE( stdout,"(42X,'ELECTRONIC PHASE: ',F9.5,' (mod ',I1,')')") & 
        pdl_elec_tot,mod_elec_tot
   WRITE( stdout,"(2X,76('='))")

!  --- Information about total phase ---
   WRITE( stdout,"(2/,31X,'SUMMARY OF PHASES')")
   WRITE( stdout,"(31X,17('~'),/)")
   WRITE( stdout,"(26X,'Ionic Phase:',F9.5,' (mod ',I1,')')") &
        pdl_ion_tot,mod_ion_tot
   WRITE( stdout,"(21X,'Electronic Phase:',F9.5,' (mod ',I1,')')") &
        pdl_elec_tot,mod_elec_tot
   WRITE( stdout,"(26X,'TOTAL PHASE:',F9.5,' (mod ',I1,')')") &
        pdl_tot,mod_tot

!  --- Information about the value of polarization ---
   WRITE( stdout,"(2/,29X,'VALUES OF POLARIZATION')")
   WRITE( stdout,"(29X,22('~'),/)")
   WRITE( stdout,"( &
      &   8X,'The calculation of phases done along the direction of vector ',I1, &
      &   /,8X,'of the reciprocal lattice gives the following contribution to', &
      &   /,8X,'the polarization vector (in different units, and being Omega', &
      &   /,8X,'the volume of the unit cell):')") &
          gdir
!  --- Calculate direction of polarization and modulus of lattice vector ---
   rmod=SQRT(at(1,gdir)*at(1,gdir)+at(2,gdir)*at(2,gdir) &
            +at(3,gdir)*at(3,gdir))
   upol(:)=at(:,gdir)/rmod
   rmod=alat*rmod
!  --- Give polarization in units of (e/Omega).bohr ---
   fac=rmod
   WRITE( stdout,"(/,11X,'P = ',F11.7,'  (mod ',F11.7,')  (e/Omega).bohr')") &
        fac*pdl_tot,fac*dble(mod_tot)
!  --- Give polarization in units of e.bohr ---
   fac=rmod/omega
   WRITE( stdout,"(/,11X,'P = ',F11.7,'  (mod ',F11.7,')  e/bohr^2')") &
        fac*pdl_tot,fac*dble(mod_tot)
!  --- Give polarization in SI units (C/m^2) ---
   fac=(rmod/omega)*(1.60097E-19_dp/5.29177E-11_dp**2)
   WRITE( stdout,"(/,11X,'P = ',F11.7,'  (mod ',F11.7,')  C/m^2')") &
        fac*pdl_tot,fac*dble(mod_tot)
!  --- Write polarization direction ---
   WRITE( stdout,"(/,8X,'The polarization direction is:  ( ', &
       &  F7.5,' , ',F7.5,' , ',F7.5,' )'))") upol(1),upol(2),upol(3)

!  --- End of information relative to polarization calculation ---
   WRITE( stdout,"(/,/,15X,50('=')/,/)")


!  -------------------------------------------------------------------------   !
!                                  finalization                                !
!  -------------------------------------------------------------------------   !

!  --- Free memory ---
   DEALLOCATE(pdl_elec)
   DEALLOCATE(mod_elec)
   DEALLOCATE(wstring)
   DEALLOCATE(loc_k)
   DEALLOCATE(phik)
   DEALLOCATE(cphik)


!------------------------------------------------------------------------------!

END SUBROUTINE c_phase

!==============================================================================!
