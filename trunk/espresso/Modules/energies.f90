!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

      MODULE energies

        USE kinds
        IMPLICIT NONE
        SAVE

        TYPE dft_energy_type
          REAL(dbl)  :: ETOT
          REAL(dbl)  :: EKIN
          REAL(dbl)  :: EMKIN
          REAL(dbl)  :: EHT
          REAL(dbl)  :: EHTE
          REAL(dbl)  :: EHTI
          REAL(dbl)  :: EPSEU
          REAL(dbl)  :: ENL
          REAL(dbl)  :: ENT
          REAL(dbl)  :: EXC
          REAL(dbl)  :: VXC
          REAL(dbl)  :: ESELF
          REAL(dbl)  :: ESR
          REAL(dbl)  :: EVDW
          REAL(dbl)  :: EBAND
        END TYPE

        REAL(dbl)  :: EHTE = 0.0_dbl
        REAL(dbl)  :: EHTI = 0.0_dbl
        REAL(dbl)  :: EHT = 0.0_dbl
        REAL(dbl)  :: EKIN = 0.0_dbl
        REAL(dbl)  :: ESELF = 0.0_dbl
        REAL(dbl)  :: EVDW = 0.0_dbl
        REAL(dbl)  :: EPSEU = 0.0_dbl
        REAL(dbl)  :: ENT = 0.0_dbl
        REAL(dbl)  :: ETOT = 0.0_dbl
        REAL(dbl)  :: ENL = 0.0_dbl
        REAL(dbl)  :: ESR = 0.0_dbl
        REAL(dbl)  :: EXC = 0.0_dbl
        REAL(dbl)  :: VXC = 0.0_dbl
        REAL(dbl)  :: EBAND = 0.0_dbl


      CONTAINS

! ---------------------------------------------------------------------------- !

        SUBROUTINE total_energy(edft, omega, eexc, vvxc, eh, eps, nnr)
          TYPE (dft_energy_type) :: edft
          REAL(dbl), INTENT(IN) :: OMEGA, EEXC, VVXC
          REAL(dbl) :: VXC
          COMPLEX(dbl), INTENT(IN) :: EH, EPS
          INTEGER, INTENT(IN) :: nnr 

          eself = edft%eself
          ent   = edft%ent
          enl   = edft%enl
          evdw  = edft%evdw
          esr   = edft%esr
          ekin  = edft%ekin

          EXC   = EEXC * omega / REAL(NNR)
          VXC   = VVXC * omega / REAL(NNR)
          edft%exc  = exc
          edft%vxc  = vxc

          EHT   = REAL(eh) + esr - eself
          edft%eht  = eht
          ehte = edft%ehte
          ehti = edft%ehti

          EPSEU = REAL(eps)
          edft%epseu = epseu

          ETOT  = EKIN + EHT + EPSEU + ENL + EXC + EVDW - ENT
          edft%etot = etot

          RETURN
        END SUBROUTINE total_energy

! ---------------------------------------------------------------------------- !

        SUBROUTINE eig_total_energy(ei)
          IMPLICIT NONE
          REAL(dbl), INTENT(IN) :: ei(:)
          INTEGER :: i
          REAL(dbl) etot_band, EII
          eband = 0.0d0
          do i = 1, SIZE(ei)
            eband = eband + ei(i) * 2.0d0 
          end do
          EII = ehti + ESR - ESELF
          etot_band = eband - ehte + (exc-vxc) + eii
          write(6,200) etot_band, eband, ehte, (exc-vxc), eii
 200      FORMAT(' *** TOTAL ENERGY : ',F14.8,/ &
                ,'     eband        : ',F14.8,/ &
                ,'     eh           : ',F14.8,/ &
                ,'     xc           : ',F14.8,/ &
                ,'     eii          : ',F14.8)
          RETURN
        END SUBROUTINE

! ---------------------------------------------------------------------------- !

        SUBROUTINE print_energies( edft )
          TYPE (dft_energy_type), OPTIONAL, INTENT(IN) :: edft
          IF( PRESENT ( edft ) ) THEN
            WRITE(6,1) edft%ETOT, edft%EKIN, edft%EHT, edft%ESELF, edft%ESR, &
              edft%EPSEU, edft%ENL, edft%EXC, edft%EVDW, edft%emkin
          ELSE
            WRITE(6,1) ETOT, EKIN, EHT, ESELF, ESR, EPSEU, ENL, EXC, EVDW
          END IF
1         FORMAT(/,/,6X,'                TOTAL ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'              KINETIC ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'        ELECTROSTATIC ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'        ESELF                = ',F18.10,' A.U.'/ &
                    ,6X,'        ESR                  = ',F18.10,' A.U.'/ &
                    ,6X,'      PSEUDOPOTENTIAL ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'  N-L PSEUDOPOTENTIAL ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,' EXCHANGE-CORRELATION ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'        VAN DER WAALS ENERGY = ',F18.10,' A.U.'/ &
                    ,6X,'        EMASS KINETIC ENERGY = ',F18.10,' A.U.'/,/)
          RETURN
        END SUBROUTINE print_energies

! ---------------------------------------------------------------------------- !

        SUBROUTINE debug_energies( edft )
          TYPE (dft_energy_type), OPTIONAL, INTENT(IN) :: edft
          IF( PRESENT ( edft ) ) THEN
            WRITE(6,2) edft%ETOT, edft%EKIN, edft%EHT, edft%ESELF, edft%ESR, &
              edft%EPSEU, edft%ENL, edft%EXC, edft%VXC, edft%EVDW, edft%EHTE, &
              edft%EHTI, edft%ENT, edft%EBAND, (edft%EXC-edft%VXC), &
              (edft%EHTI+edft%ESR-edft%ESELF), &
              edft%EBAND-edft%EHTE+(edft%EXC-edft%VXC)+(edft%EHTI+edft%ESR-edft%ESELF)
          ELSE
            WRITE(6,2) ETOT, EKIN, EHT, ESELF, ESR, EPSEU, ENL, EXC, VXC, &
              EVDW, EHTE, EHTI, ENT, EBAND, (EXC-VXC), (EHTI+ESR-ESELF), &
              EBAND-EHTE+(EXC-VXC)+(EHTI+ESR-ESELF)
          END IF
2         FORMAT(/,/ &
            ,6X,' ETOT .... = ',F18.10,/ &
            ,6X,' EKIN .... = ',F18.10,/ &
            ,6X,' EHT ..... = ',F18.10,/ &
            ,6X,' ESELF ... = ',F18.10,/ &
            ,6X,' ESR ..... = ',F18.10,/ &
            ,6X,' EPSEU ... = ',F18.10,/ &
            ,6X,' ENL ..... = ',F18.10,/ &
            ,6X,' EXC ..... = ',F18.10,/ &
            ,6X,' VXC ..... = ',F18.10,/ &
            ,6X,' EVDW .... = ',F18.10,/ &
            ,6X,' EHTE .... = ',F18.10,/ &
            ,6X,' EHTI .... = ',F18.10,/ &
            ,6X,' ENT ..... = ',F18.10,/ &
            ,6X,' EBAND ... = ',F18.10,/ &
            ,6X,' EXC-VXC ............................. = ',F18.10,/ &
            ,6X,' EHTI+ESR-ESELF ...................... = ',F18.10,/ &
            ,6X,' EBAND-EHTE+(EXC-VXC)+(EHTI+ESR-ESELF) = ',F18.10)
          RETURN
        END SUBROUTINE debug_energies


      END MODULE Energies
