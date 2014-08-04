!
! Copyright (C) 2014 Federico Zadra
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
MODULE space_group
USE kinds, ONLY: DP
   IMPLICIT NONE

   SAVE
   PRIVATE

   PUBLIC sym_brav, find_equivalent_tau

   CONTAINS
   SUBROUTINE sym_brav(space_group_number,sym_n,ibrav)
   
   !Sym_brav ->   
   !input    spacegroup number
   !output   sym_n = number of symmetries 
   !         ibrav = bravais lattice number 

      INTEGER, INTENT(IN) :: space_group_number
      INTEGER, INTENT(OUT) :: sym_n,ibrav
      
      simmetria: SELECT CASE (space_group_number)
      !Triclinic 1-2
      CASE (1)
         sym_n=1
         ibrav=14
      CASE (2)
         sym_n=2
         ibrav=14
      !Monoclinic 3-15
      CASE (3) !P2
         sym_n=2
         ibrav=12
      CASE (4) !P2(1)
         sym_n=2
         ibrav=12
      CASE (5) !C2
         sym_n=2
         ibrav=13
      CASE (6) !PM
         sym_n=2
         ibrav=12
      CASE (7) !Pc
         sym_n=2
         ibrav=12
      CASE (8) !Cm
         sym_n=2
         ibrav=13
      CASE (9) !Cc
         sym_n=2
         ibrav=13
      CASE (10) !P2/m
         sym_n=4
         ibrav=12
      CASE (11) !P2(1)/m
         sym_n=4
         ibrav=12
      CASE (12) !C2/m
         sym_n=4
         ibrav=13
      CASE (13) !P2/c
         sym_n=4
         ibrav=12
      CASE (14) !P2(1)/c
         sym_n=4
         ibrav=12
      CASE (15) !C2/c
         sym_n=4
         ibrav=13
      !Orthorhombic
      CASE (16) !P222
         sym_n=4
         ibrav=8
      CASE (17) !P222(1)
         sym_n=4
         ibrav=8
      CASE (18) !P2(1)2(1)2
         sym_n=4
         ibrav=8
      CASE (19) !P2(1)2(1)2(1)
         sym_n=4
         ibrav=8
      CASE (20) !C222(1)
         sym_n=4
         ibrav=9
      CASE (21) !C222
         sym_n=4
         ibrav=9
      CASE (22) !F222
         sym_n=4
         ibrav=10
      CASE (23) !I222
         sym_n=4
         ibrav=11
      CASE (24) !I2(1)2(1)2(1)
         sym_n=4
         ibrav=11
      CASE (25) !Pmm2
         sym_n=4
         ibrav=8
      CASE (26) !Pmc2(1)
         sym_n=4
         ibrav=8
      CASE (27) !Pcc2
         sym_n=4
         ibrav=8
      CASE (28) !Pma2
         sym_n=4
         ibrav=8
      CASE (29) !Pca2(1)
         sym_n=4
         ibrav=8
      CASE (30) !Pnc2
         sym_n=4
         ibrav=8
      CASE (31) !Pmn2(1)
         sym_n=4
         ibrav=8
      CASE (32) !Pba2
         sym_n=4
         ibrav=8
      CASE (33) !Pna2(1)
         sym_n=4
         ibrav=8
      CASE (34) !Pnn2
         sym_n=4
         ibrav=8
      CASE (35) !Cmm2
         sym_n=4
         ibrav=9
      CASE (36) !Cmc2(1)
         sym_n=4
         ibrav=9
      CASE (37) !Ccc2
         sym_n=4
         ibrav=9
      CASE (38) !Amm2
         sym_n=4
         ibrav=91
      CASE (39) !Abm2
         sym_n=4
         ibrav=91
      CASE (40) !Ama2
         sym_n=4
         ibrav=91
      CASE (41) !Aba2
         sym_n=4
         ibrav=91
      CASE (42) !Fmm2
         sym_n=4
         ibrav=10
      CASE (43) !Fdd2
         sym_n=4
         ibrav=10
      CASE (44) !Imm2
         sym_n=4
         ibrav=11
      CASE (45) !Iba2
         sym_n=4
         ibrav=11
      CASE (46) !Ima2
         sym_n=4
         ibrav=11
      CASE (47) !Pmmm
         sym_n=8
         ibrav=8
      CASE (48) !Pnnn
         sym_n=8
         ibrav=8
      CASE (49) !Pccm
         sym_n=8
         ibrav=8
      CASE (50) !Pban
         sym_n=8
         ibrav=8
      CASE (51) !Pmma
         sym_n=8
         ibrav=8
      CASE (52) !Pnna
         sym_n=8
         ibrav=8
      CASE (53) !Pmna
         sym_n=8
         ibrav=8
      CASE (54) !Pcca
         sym_n=8
         ibrav=8
      CASE (55) !Pbam
         sym_n=8
         ibrav=8
      CASE (56) !Pccn
         sym_n=8
         ibrav=8
      CASE (57) !Pbcm
         sym_n=8
         ibrav=8
      CASE (58) !Pnnm
         sym_n=8
         ibrav=8
      CASE (59) !Pmmn
         sym_n=8
         ibrav=8
      CASE (60) !Pbcn
         sym_n=8
         ibrav=8
      CASE (61) !Pbca
         sym_n=8
         ibrav=8
      CASE (62) !Pnma
         sym_n=8
         ibrav=8
      CASE (63) !Cmcm
         sym_n=8
         ibrav=9
      CASE (64) !Cmca
         sym_n=8
         ibrav=9
      CASE (65) !Cmmm
         sym_n=8
         ibrav=9
      CASE (66) !Cccm
         sym_n=8
         ibrav=9
      CASE (67) !Cmma
         sym_n=8
         ibrav=9
      CASE (68) !Ccca
         sym_n=8
         ibrav=9
      CASE (69) !Fmmm
         sym_n=8
         ibrav=10
      CASE (70) !Fddd
         sym_n=8
         ibrav=10
      CASE (71) !Immm
         sym_n=8
         ibrav=11
      CASE (72) !Ibam
         sym_n=8
         ibrav=11
      CASE (73) !Ibca
         sym_n=8
         ibrav=11
      CASE (74) !Imma
         sym_n=8
         ibrav=11
      !Tetragonal
      CASE (75) !P4
         sym_n=4
         ibrav=6
      CASE (76) !P4(1)
         sym_n=4
         ibrav=6
      CASE (77) !P4(2)
         sym_n=4
         ibrav=6
      CASE (78) !P4(3)
         sym_n=4
         ibrav=6
      CASE (79) !I4
         sym_n=4
         ibrav=7
      CASE (80) !I4(1)
         sym_n=4
         ibrav=7
      CASE (81) !P-4
         sym_n=4
         ibrav=6
      CASE (82) !I-4
         sym_n=4
         ibrav=7
      CASE (83) !P4/m
         sym_n=8
         ibrav=6
      CASE (84) !P4(2)/m
         sym_n=8
         ibrav=6
      CASE (85) !P4/n
         sym_n=8
         ibrav=6
      CASE (86) !P4(2)/n
         sym_n=8
         ibrav=6
      CASE (87) !I4/m
         sym_n=8
         ibrav=7
      CASE (88) !I4(1)/a
         sym_n=8
         ibrav=7
      CASE (89) !P422
         sym_n=8
         ibrav=6
      CASE (90) !P42(1)2
         sym_n=8
         ibrav=6
      CASE (91) !P4(1)22
         sym_n=8
         ibrav=6
      CASE (92) !P4(1)2(1)2
         sym_n=8
         ibrav=6
      CASE (93) !P4(2)22
         sym_n=8
         ibrav=6
      CASE (94) !P4(2)2(1)2
         sym_n=8
         ibrav=6
      CASE (95) !P4(3)22
         sym_n=8
         ibrav=6
      CASE (96) !P4(3)2(1)2
         sym_n=8
         ibrav=6
      CASE (97) !I422
         sym_n=8
         ibrav=7
      CASE (98) !I4(1)22
         sym_n=8
         ibrav=7
      CASE (99) !P4mm
         sym_n=8
         ibrav=6
      CASE (100) !P4bm
         sym_n=8
         ibrav=6
      CASE (101) !P4(2)cm
         sym_n=8
         ibrav=6
      CASE (102) !P4(2)nm
         sym_n=8
         ibrav=6
      CASE (103) !P4cc
         sym_n=8
         ibrav=6
      CASE (104) !P4nc
         sym_n=8
         ibrav=6
      CASE (105) !P4(2)mc
         sym_n=8
         ibrav=6
      CASE (106) !P4(2)bc
         sym_n=8
         ibrav=6
      CASE (107) !I4mm
         sym_n=8
         ibrav=7
      CASE (108) !I4cm
         sym_n=8
         ibrav=7
      CASE (109) !I4(!)md
         sym_n=8
         ibrav=7
      CASE (110) !I4(1)cd
         sym_n=8
         ibrav=7
      CASE (111) !P-42m
         sym_n=8
         ibrav=6
      CASE (112) !P-42c
         sym_n=8
         ibrav=6
      CASE (113) !P-42(1)m
         sym_n=8
         ibrav=6
      CASE (114) !P-42(1)c
         sym_n=8
         ibrav=6
      CASE (115) !P-4m2
         sym_n=8
         ibrav=6
      CASE (116) !P-4c2
         sym_n=8
         ibrav=6
      CASE (117) !P-4b2
         sym_n=8
         ibrav=6
      CASE (118) !P-4n2
         sym_n=8
         ibrav=6
      CASE (119) !I-4m2
         sym_n=8
         ibrav=7
      CASE (120) !I-4c2
         sym_n=8
         ibrav=7
      CASE (121) !I-42m
         sym_n=8
         ibrav=7
      CASE (122) !I-42d
         sym_n=8
         ibrav=7
      CASE (123) !P4/mmm
         sym_n=16
         ibrav=6
      CASE (124) !P4/mcc
         sym_n=16
         ibrav=6
      CASE (125) !P4/nbm
         sym_n=16
         ibrav=6
      CASE (126) !P4/nnc
         sym_n=16
         ibrav=6
      CASE (127) !P4/mbm
         sym_n=16
         ibrav=6
      CASE (128) !P4/mnc
         sym_n=16
         ibrav=6
      CASE (129) !P4/nmm
         sym_n=16
         ibrav=6
      CASE (130) !P4/ncc
         sym_n=16
         ibrav=6
      CASE (131) !P4(2)/mmc
         sym_n=16
         ibrav=6
      CASE (132) !P4(2)/mcm
         sym_n=16
         ibrav=6
      CASE (133) !P4(2)nbc
         sym_n=16
         ibrav=6
      CASE (134) !P4(2)/nnm
         sym_n=16
         ibrav=6
      CASE (135) !P4(2)/mbc
         sym_n=16
         ibrav=6
      CASE (136) !P4(2)/mnm
         sym_n=16
         ibrav=6
      CASE (137) !P4(2)/nmc
         sym_n=16
         ibrav=6
      CASE (138) !P4(2)/ncm
         sym_n=16
         ibrav=6
      CASE (139) !I4/mmm
         sym_n=16
         ibrav=7
      CASE (140) !I4/mcm
         sym_n=16
         ibrav=7
      CASE (141) !I4(1)/amd
         sym_n=16
         ibrav=7
      CASE (142) !I4(1)/acd
         sym_n=16
         ibrav=7
      ! Trigonal
      CASE (143) !P3
         sym_n=3
         ibrav=4
      CASE (144)
         sym_n=3
         ibrav=4
      CASE (145)
         sym_n=3
         ibrav=4
      CASE (146) !R3
         sym_n=3
         ibrav=5
      CASE (147)
         sym_n=6
         ibrav=4
      CASE (148) !R-3
         sym_n=6
         ibrav=5
      CASE (149)
         sym_n=6
         ibrav=4
      CASE (150) 
         sym_n=6
         ibrav=4
      CASE (151)
         sym_n=6
         ibrav=4
      CASE (152)
         sym_n=6
         ibrav=4
      CASE (153)
         sym_n=6
         ibrav=4
      CASE (154)
         sym_n=6
         ibrav=4
      CASE (155) !R32
         sym_n=6
         ibrav=5
      CASE (156)
         sym_n=6
         ibrav=4
      CASE (157) 
         sym_n=6
         ibrav=4
      CASE (158)
         sym_n=6
         ibrav=4
      CASE (159)
         sym_n=6
         ibrav=4
      CASE (160) !R3m
         sym_n=6
         ibrav=5
      CASE (161) !R3c
         sym_n=6
         ibrav=5
      CASE (162)
         sym_n=12
         ibrav=4
      CASE (163)
         sym_n=12
         ibrav=4
      CASE (164)
         sym_n=12
         ibrav=4
      CASE (165)
         sym_n=12
         ibrav=4
      CASE (166) !R-3m
         sym_n=12
         ibrav=5
      CASE (167) !R-3c
         sym_n=12
         ibrav=5
      ! Exagonal
      CASE (168)
         sym_n=6
         ibrav=4
      CASE (169)
         sym_n=6
         ibrav=4
      CASE (170)
         sym_n=6
         ibrav=4
      CASE (171)
         sym_n=6
         ibrav=4
      CASE (172)
         sym_n=6
         ibrav=4
      CASE (173)
         sym_n=6
         ibrav=4
      CASE (174)
         sym_n=6
         ibrav=4
      CASE (175)
         sym_n=12
         ibrav=4
      CASE (176)
         sym_n=12
         ibrav=4
      CASE (177)
         sym_n=12
         ibrav=4
      CASE (178)
         sym_n=12
         ibrav=4
      CASE (179)
         sym_n=12
         ibrav=4
      CASE (180)
         sym_n=12
         ibrav=4
      CASE (181)
         sym_n=12
         ibrav=4
      CASE (182)
         sym_n=12
         ibrav=4
      CASE (183)
         sym_n=12
         ibrav=4
      CASE (184)
         sym_n=12
         ibrav=4
      CASE (185)
         sym_n=12
         ibrav=4
      CASE (186)
         sym_n=12
         ibrav=4
      CASE (187)
         sym_n=12
         ibrav=4
      CASE (188)
         sym_n=12
         ibrav=4
      CASE (189)
         sym_n=12
         ibrav=4
      CASE (190)
         sym_n=12
         ibrav=4
      CASE (191)
         sym_n=24
         ibrav=4
      CASE (192)
         sym_n=24
         ibrav=4
      CASE (193)
         sym_n=24
         ibrav=4
      CASE (194)
         sym_n=24
         ibrav=4
      !Cubic
      CASE (195)
         sym_n=12
         ibrav=1
      CASE (196)
         sym_n=12
         ibrav=2
      CASE (197)
         sym_n=12
         ibrav=3
      CASE (198)
         sym_n=12
         ibrav=1
      CASE (199)
         sym_n=12
         ibrav=3
      CASE (200)
         sym_n=24
         ibrav=1
      CASE (201)
         sym_n=24
         ibrav=1
      CASE (202)
         sym_n=24
         ibrav=2
      CASE (203)
         sym_n=24
         ibrav=2
      CASE (204)
         sym_n=24
         ibrav=3
      CASE (205)
         sym_n=24
         ibrav=1
      CASE (206)
         sym_n=24
         ibrav=3
      CASE (207)
         sym_n=24
         ibrav=1
      CASE (208)
         sym_n=24
         ibrav=1
      CASE (209)
         sym_n=24
         ibrav=2
      CASE (210)
         sym_n=24
         ibrav=2
      CASE (211)
         sym_n=24
         ibrav=3
      CASE (212)
         sym_n=24
         ibrav=1
      CASE (213)
         sym_n=24
         ibrav=1
      CASE (214)
         sym_n=24
         ibrav=3
      CASE (215)
         sym_n=24
         ibrav=1
      CASE (216)
         sym_n=24
         ibrav=2
      CASE (217)
         sym_n=24
         ibrav=3
      CASE (218)
         sym_n=24
         ibrav=1
      CASE (219)
         sym_n=24
         ibrav=2
      CASE (220)
         sym_n=24
         ibrav=3
      CASE (221)
         sym_n=48
         ibrav=1
      CASE (222)
         sym_n=48
         ibrav=1
      CASE (223)
         sym_n=48
         ibrav=1
      CASE (224)
         sym_n=48
         ibrav=1
      CASE (225)
         sym_n=48
         ibrav=2
      CASE (226)
         sym_n=48
         ibrav=2
      CASE (227)
         sym_n=48
         ibrav=2
      CASE (228)
         sym_n=48
         ibrav=2
      CASE (229)
         sym_n=48
         ibrav=3
      CASE (230)
         sym_n=48
         ibrav=3
      END SELECT simmetria
      RETURN
   END SUBROUTINE sym_brav

   SUBROUTINE find_equivalent_tau(space_group_number,inco,outco,i,unique)
      
   !sel_grup ->   input   space_group_number
   !         inco input coordinate
   !         i element index
   !      output outco coordinates

      INTEGER, INTENT(IN) :: space_group_number,i
      REAL(DP),dimension(:,:), INTENT(IN) :: inco
      REAL(DP),dimension(:,:,:), INTENT(OUT) :: outco
      character(LEN=1), INTENT(IN) :: unique

      INTEGER :: k,j
      simmetria: SELECT CASE (space_group_number)
      !*****************************************
      !Triclinic 1-2
      CASE (1)
         DO k=1,3
            outco(i,1,k)=inco(i,k)
         END DO
      CASE (2)
         DO k=1,3
            outco(i,1,k)=inco(i,k)
            outco(i,2,k)=-inco(i,k)
         END DO
      !*****************************************
      !Monoclinic 3-15
      CASE (3)
         !x,y,z
         !-x,y,-z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         END IF
      CASE (4)
         !x,y,z
         !-X,Y+1/2,-Z 
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=inco(i,2)+1.0/2.0
         outco(i,2,3)=-inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         END IF

      CASE (5)
         !X,Y,Z identita
         !-X,Y,-Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2         
         IF (unique=='b') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         END IF
      CASE (6)
         !ID
         !x,-y,z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         
         IF (unique=='b') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         END IF
      CASE (7)
         !ID
         !x,-y,1/2+z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=1.0/2.0+inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=1.0/2.0+inco(i,2)
         outco(i,2,3)=-inco(i,3)         
         END IF
      CASE (8)
         !symmetry= X,Y,Z
         !symmetry= X,-Y,Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2

         IF (unique=='b') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         END IF

         IF (unique=='c') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         END IF
      CASE (9)
         !symmetry= X,Y,Z
         !symmetry= X,-Y,1/2+Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2

         IF (unique=='b') THEN
            outco(i,2,1)=inco(i,1)
            outco(i,2,2)=-inco(i,2)
            outco(i,2,3)=inco(i,3)+1.0/2.0
         END IF
         
         IF (unique=='c') THEN
            outco(i,2,1)=inco(i,1)
            outco(i,2,2)=inco(i,2)+1.0/2.0
            outco(i,2,3)=-inco(i,3)
         END IF
      CASE (10)
         !symmetry= X,Y,Z
         !symmetry= X,-Y,Z
         !symmetry= -X,Y,-Z
         !symmetry= -X,-Y,-Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF

         IF (unique=='c') THEN
         !S=2
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF
      CASE (11)
         !symmetry= X,Y,Z
         !symmetry= -X,1/2+Y,-Z
         !symmetry= -X,-Y,-Z
         !symmetry= X,1/2-Y,Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=1.0/2.0+inco(i,2)
         outco(i,2,3)=-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=1.0/2.0-inco(i,2)
         outco(i,4,3)=inco(i,3)
         END IF
         
         IF (unique=='c') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=1.0/2.0+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=inco(i,2)
         outco(i,4,3)=1.0/2.0-inco(i,3)
         END IF
      CASE (12)
         !symmetry= X,Y,Z
         !symmetry= X,-Y,Z
         !symmetry= -X,Y,-Z
         !symmetry= -X,-Y,-Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         
         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF
         
         IF (unique=='c') THEN
         outco(i,2,1)=inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF
      CASE (13)
         !symmetry= X,Y,Z
         !symmetry= -X,Y,1/2-Z
         !symmetry= -X,-Y,-Z
         !symmetry= X,-Y,1/2+Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=1.0/2.0-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=1.0/2.0+inco(i,3)
         END IF
         
         IF (unique=='c') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=1.0/2.0-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=1.0/2.0+inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF
      CASE (14)
         !symmetry= X,Y,Z
         !symmetry= -X,-Y,-Z
         !symmetry= -X,1/2+Y,1/2-Z
         !symmetry= X,1/2-Y,1/2+Z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO

         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=1.0/2.0+inco(i,2)
         outco(i,3,3)=1.0/2.0-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=1.0/2.0-inco(i,2)
         outco(i,4,3)=1.0/2.0+inco(i,3)
         END IF

         IF (unique=='c') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=1.0/2.0-inco(i,2)
         outco(i,3,3)=1.0/2.0+inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=1.0/2.0+inco(i,2)
         outco(i,4,3)=1.0/2.0-inco(i,3)
         END IF
      CASE (15)
         !symmetry= X,Y,Z
         !symmetry= -X,Y,1/2-Z 
         !symmetry= -X,-Y,-Z
         !symmetry= X,-Y,1/2+Z 
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         
         IF (unique=='b') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=inco(i,2)
         outco(i,2,3)=1.0/2.0-inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=3
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=1.0/2.0+inco(i,3)
         END IF

         IF (unique=='c') THEN
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=1.0/2.0-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=3
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=1.0/2.0+inco(i,2)
         outco(i,4,3)=-inco(i,3)
         END IF

      !*****************************************
      !Orthorhombic 16-74
      CASE (16) !P222
         !symmetry= X,Y,Z
         !symmetry= -X,-Y,Z
         !symmetry= -X,Y,-Z
         !symmetry= X,-Y,-Z 
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      CASE (17) !P222(1)
         !symmetry= X,Y,Z
         !symmetry= -X,-Y,1/2+Z
         !symmetry= -X,Y,1/2-Z
         !symmetry= X,-Y,-Z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=1.0/2.0+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=1.0/2.0-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      CASE (18) !P2(1)2(1)2
         !symmetry= X,Y,Z
         !symmetry= -X,-Y,Z
         !symmetry= 1/2-X,1/2+Y,-Z
         !symmetry= 1/2+X,1/2-Y,-Z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=1.0/2.0-inco(i,1)
         outco(i,3,2)=1.0/2.0+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=1.0/2.0+inco(i,1)
         outco(i,4,2)=1.0/2.0-inco(i,2)
         outco(i,4,3)=-inco(i,3)

      CASE (19) !P2(1)2(1)2(1)
         !symmetry= X,Y,Z
         !symmetry= 1/2-X,-Y,1/2+Z
         !symmetry= -X,1/2+Y,1/2-Z
         !symmetry= 1/2+X,1/2-Y,-Z 

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=1.0/2.0-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=1.0/2.0+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=1.0/2.0+inco(i,2)
         outco(i,3,3)=1.0/2.0-inco(i,3)
         !S=4
         outco(i,4,1)=1.0/2.0+inco(i,1)
         outco(i,4,2)=1.0/2.0-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      CASE (20) !C222(1)

         ! symmetry= X,Y,Z
         !symmetry= -X,-Y,1/2+Z
         !symmetry= -X,Y,1/2-Z
         !symmetry= X,-Y,-Z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=1.0/2.0+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=1.0/2.0-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      
      CASE (21) !C222
         !symmetry= X,Y,Z
         !symmetry= -X,-Y,Z
         !symmetry= -X,Y,-Z
         !symmetry= X,-Y,-Z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         

      CASE (22) !F222
         ! symmetry= X,Y,Z
         !symmetry= -X,-Y,Z
         !symmetry= -X,Y,-Z
         !symmetry= X,-Y,-Z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      CASE (23) !I222
         !id
         !-x,-y,z
         !x,,y,-z
         !x,-y,-z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
      CASE (24) !I2(1)2(1)2(1)
         !id
         !-x+1/2,-y,z+1/2
         !-x,1/2+y,1/2-z
         !x+1/2,-y+1/2,-z
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         
      CASE (25) !Pmm2
         !id
         !-x,-y,z
         !+x,-y,+z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)
      
      CASE (26) !Pmc2(1)
         !id
         !-x,-y,z+1/2
         !+x,-y,+z+1/2
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (27) !Pcc2
         !id
         !-x,-y,z
         !+x,-y,+z+1/2
         !-x,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (28) !Pma2
         !id
         !-x,-y,z
         !1/2+x,-y,z
         !1/2-x,y,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (29) !Pca2(1)
         !id
         !-x,-y,z+1/2
         !1/2+x,-y,z
         !1/2-x,y,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (30) !Pnc2
         !id
         !-x,-y,z
         !+x,1/2-y,z+1/2
         !-x,y+1/2,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (31) !Pmn2(1)
         !id
         !1/2-x,-y,z+1/2
         !1/2+x,-y,z+1/2
         !-x,y,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)
      
      CASE (32) !Pba2
         !id
         !-x,-y,z
         !1/2+x,1/2-y,z
         !1/2-x,1/2+y,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
      
      CASE (33) !Pna2(1)
         !id
         !-x,-y,z+1/2
         !1/2+x,1/2-y,z
         !1/2-x,1/2+y,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (34) !Pnn2
         !id
         !-x,-y,z
         !1/2+x,1/2-y,1/2+z
         !1/2-x,1/2+y,1/2+z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (35) !Cmm2
         !id
         !-x,-y,z
         !+x,-y,z
         !-x,+y,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (36) !Cmc2(1)
         !id
         !-x,-y,z+1/2
         !+x,-y,z+1/2
         !-x,+y,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)
      
      CASE (37) !Ccc2
         !id
         !-x,-y,z
         !+x,-y,z+1/2
         !-x,+y,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (38) !Amm2
         !id
         !-x,-y,z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (39) !Abm2
         !id
         !-x,-y,z
         !x,-y+1/2,z
         !-x,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)

      CASE (40) !Ama2
         !id
         !-x,-y,z
         !x+1/2,-y,z
         !-x+1/2,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (41) !Aba2
         !id
         !-x,-y,z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)

      CASE (42) !Fmm2
         !id
         !-x,-y,z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (43) !Fdd2
         !id
         !-x,-y,z
         !x+1/4,-y+1/4,z+1/4
         !-x+1/4,y+1/4,z+1/4

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/4.0
         outco(i,3,2)=-inco(i,2)+1.0/4.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/4.0
         outco(i,4,2)=+inco(i,2)+1.0/4.0
         outco(i,4,3)=+inco(i,3)+1.0/4.0

      CASE (44) !Imm2
         !id
         !-x,-y,z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (45) !Iba2
         !id
         !-x,-y,z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)+1.0/2.0
         outco(i,4,3)=+inco(i,3)

      CASE (46) !Ima2
         !id
         !-x,-y,z
         !x+1/2,-y,z
         !-x+1/2,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,1)+1.0/2.0
         outco(i,3,2)=-inco(i,2)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)+1.0/2.0
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=+inco(i,3)

      CASE (47) !Pmmm
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x,-y,-z
         !x,y,-z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (48) !Pnnn
         
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x+1/2,-y+1/2,-z+1/2
         !x+1/2,y+1/2,-z+1/2
         !x+1/2,-y+/2,z+1/2
         !-x+1/2,y+1/2,z+1/2
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-x+1/2,+y,-z+1/2
         !+x,-y+1/2,-z+1/2
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !x+1/2,-y,z+1/2
         !-x,y+1/2,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (49) !Pccm
         !id
         !-x,-y,z
         !-x,+y,-z+1/2
         !+x,-y,-z+1/2
         !-x,-y,-z
         !x,y,-z
         !x,-y,z+1/2
         !-x,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (50) !Pban
         
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x+1/2,-y+1/2,-z
         !x+1/2,y+1/2,-z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-x+1/2,+y,-z
         !+x,-y+1/2,-z
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !x+1/2,-y,z
         !-x,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)
         END IF

      CASE (51) !Pmma
         !id
         !-x+1/2,-y,z
         !-x,+y,-z
         !+x+1/2,-y,-z
         !-x,-y,-z
         !x+1/2,y,-z
         !x,-y,z
         !-x+1/2,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (52) !Pnna
         !id
         !-x+1/2,-y,z
         !-x+1/2,+y+1/2,-z+1/2
         !+x,-y+1/2,-z+1/2
         !-x,-y,-z
         !x+1/2,y,-z
         !x+1/2,-y+1/2,z+1/2
         !-x,y+1/2,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (53) !Pmna
         !id
         !-x+1/2,-y,z+1/2
         !-x+1/2,+y,-z+1/2
         !+x,-y,-z
         !-x,-y,-z
         !x+1/2,y,-z+1/2
         !x+1/2,-y,z+1/2
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (54) !Pcca
         !id
         !-x+1/2,-y,z
         !-x,+y,-z+1/2
         !+x+1/2,-y,-z+1/2
         !-x,-y,-z
         !x+1/2,y,-z
         !x,-y,z+1/2
         !-x+1/2,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (55) !Pbam
         !id
         !-x,-y,z
         !-x+1/2,+y+1/2,-z
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x,y,-z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (56) !Pccn
         !id
         !-x+1/2,-y+1/2,z
         !-x,+y+1/2,-z+1/2
         !+x+1/2,-y,-z+1/2
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !x,-y+1/2,z+1/2
         !-x+1/2,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (57) !Pbcm
         !id
         !-x,-y,z+1/2
         !-x,+y+1/2,-z+1/2
         !+x,-y+1/2,-z
         !-x,-y,-z
         !x,y,-z+1/2
         !x,-y+1/2,z+1/2
         !-x,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (58) !Pnnm
         !id
         !-x,-y,z
         !-x+1/2,+y+1/2,-z+1/2
         !+x+1/2,-y+1/2,-z+1/2
         !-x,-y,-z
         !x,y,-z
         !x+1/2,-y+1/2,z+1/2
         !-x+1/2,y+1/2,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (59) !Pmmn

         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-x+1/2,+y+1/2,-z
         !+x+1/2,-y+1/2,-z
         !-x+1/2,-y+1/2,-z
         !x+1/2,y+1/2,-z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-x,+y+1/2,-z
         !+x+1/2,-y,-z
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !x,-y+1/2,z
         !-x+1/2,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)         
         END IF

      CASE (60) !Pbcn
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-x,+y,-z+1/2
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x+1/2,y+1/2,-z+1/2
         !x,-y,z+1/2
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (61) !Pbca
         !id
         !-x+1/2,-y,z+1/2
         !-x,+y+1/2,-z+1/2
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x+1/2,y,-z+1/2
         !x,-y+1/2,z+1/2
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (62) !Pnma
         !id
         !-x+1/2,-y,z+1/2
         !-x,+y+1/2,-z
         !+x+1/2,-y+1/2,-z+1/2
         !-x,-y,-z
         !x+1/2,y,-z+1/2
         !x,-y+1/2,z
         !-x+1/2,y+1/2,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0
      
      CASE (63) !Cmcm
         !id
         !-x,-y,z+1/2
         !-x,+y,-z+1/2
         !+x,-y,-z
         !-x,-y,-z
         !x,y,-z+1/2
         !x,-y,z+1/2
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (64) !Cmca
         !id
         !-x,-y+1/2,z+1/2
         !-x,+y,-z+1/2
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x+1/2,y+1/2,-z+1/2
         !x,-y,z+1/2
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (65) !Cmmm
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x,-y,-z
         !x,y,-z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (66) !Cccm
         !id
         !-x,-y,z
         !-x,+y,-z+1/2
         !+x,-y,-z+1/2
         !-x,-y,-z
         !x,y,-z
         !x,-y,z+1/2
         !-x,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (67) !Cmma
         !id
         !-x,-y+1/2,z
         !-x,+y,-z+1/2
         !+x,-y,-z
         !-x,-y,-z
         !x,y+1/2,-z
         !x,-y+1/2,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (68) !Ccca
         
         IF (unique=='1') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-x,+y,-z
         !+x+1/2,-y+1/2,-z
         !-x,-y+1/2,-z+1/2
         !x+1/2,y,-z+1/2
         !x,-y+1/2,z+1/2
         !-x+1/2,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-x,+y,-z
         !+x+1/2,-y,-z+1/2
         !-x,-y,-z
         !x+1/2,y,-z
         !x,-y+,z+1/2
         !-x+1/2,y,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)+1.0/2.0      
         END IF

      CASE (69) !Fmmm
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x,-y,-z
         !x,y,-z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (70) !Fddd

         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x+1/4,-y+1/4,-z+1/4
         !x+1/4,y+1/4,-z+1/4
         !x+1/4,-y+1/4,z+1/4
         !-x+1/4,y+1/4,z+1/4

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/4.0
         outco(i,5,2)=-inco(i,2)+1.0/4.0
         outco(i,5,3)=-inco(i,3)+1.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/4.0
         outco(i,6,2)=+inco(i,2)+1.0/4.0
         outco(i,6,3)=-inco(i,3)+1.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/4.0
         outco(i,7,2)=-inco(i,2)+1.0/4.0
         outco(i,7,3)=+inco(i,3)+1.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/4.0
         outco(i,8,2)=+inco(i,2)+1.0/4.0
         outco(i,8,3)=+inco(i,3)+1.0/4.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x+3/4,-y+3/4,z
         !-x+3/4,+y,-z+3/4
         !+x,-y+3/4,-z+3/4
         !-x,-y,-z
         !x+3/4,y+3/4,-z
         !x+3/4,-y,z+3/4
         !-x,y+3/4,z+3/4

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+3.0/4.0
         outco(i,2,2)=-inco(i,2)+3.0/4.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+3.0/4.0
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)+3.0/4.0
         outco(i,4,3)=-inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+3.0/4.0
         outco(i,6,2)=+inco(i,2)+3.0/4.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+3.0/4.0
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)+3.0/4.0
         outco(i,8,3)=+inco(i,3)+3.0/4.0
         END IF

      CASE (71) !Immm
         !id
         !-x,-y,z
         !-x,+y,-z
         !+x,-y,-z
         !-x,-y,-z
         !x,y,-z
         !x,-y,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      CASE (72) !Ibam
         !id
         !-x,-y,z
         !-x+1/2,+y+1/2,-z
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x,y,-z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)+1.0/2.0
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (73) !Ibca
         !id
         !-x+1/2,-y,z+1/2
         !-x,+y+1/2,-z+1/2
         !+x+1/2,-y+1/2,-z
         !-x,-y,-z
         !x+1/2,y,-z+1/2
         !x,-y+1/2,z+1/2
         !-x+1/2,y+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+1.0/2.0
         outco(i,8,2)=+inco(i,2)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (74) !Imma
         !id
         !-x,-y+1/2,z
         !-x,+y+1/2,-z
         !+x,-y,-z
         !-x,-y,-z
         !x,y+1/2,-z
         !x,-y+1/2,z
         !-x,y,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=+inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,1)
         outco(i,7,2)=-inco(i,2)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)
         outco(i,8,2)=+inco(i,2)
         outco(i,8,3)=+inco(i,3)

      !*****************************************
      !Tetragonal 75-142

      CASE (75) !P4
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)

      CASE (76) !P4(1)
         !id
         !-x,-y,z+1/2
         !-y,x,z+1/4
         !y,-x,z+3/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0

      CASE (77) !P4(2)
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0

      CASE (78) !P4(3)
         !id
         !-x,-y,z+1/2
         !-y,x,z+3/4
         !y,-x,z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/4.0

      CASE (79) !I4
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)

      CASE (80) !I4(1)
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-y,x+1/2,z+1/4
         !y+1/2,-x,z+3/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0

      CASE (81) !P-4
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)

      CASE (82) !I-4
         !id
         !-x,-y,z
         !+y,-x,-z
         !-y,x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)

      CASE (83) !P4/m
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (84) !P(2)/m
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z+1/2
         !-y,x-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (85) !P4/n

         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y+1/2,x+1/2,z
         !y+1/2,-x+1/2,z
         !-x+1/2,-y+1/2,-z
         !x+1/2,y+1/2,-z
         !y,-x,-z
         !-y,x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-y+1/2,x,z
         !y,-x+1/2,z
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !y+1/2,-x,-z
         !-y,x+1/2,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)
         END IF

      CASE (86) !P4(2)/n
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y+1/2,x+1/2,z+1/2
         !y+1/2,-x+1/2,z+1/2
         !-x+1/2,-y+1/2,-z+1/2
         !x+1/2,y+1/2,-z+1/2
         !y,-x,-z
         !-y,x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-y,x+1/2,z+1/2
         !y+1/2,-x,z+1/2
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !y,-x+1/2,-z+1/2
         !-y+1/2,x,-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         END IF

      CASE (87) !I4/m
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=-inco(i,3)
      
      CASE (88) !I4(1)/a
         IF (unique=='1') THEN
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-y,x+1/2,z+1/4
         !y+1/2,-x,z+3/4
         !-x,-y+1/2,-z+1/4
         !x+1/2,y,-z+3/4
         !y,-x,-z
         !-y+1/2,x+1/2,-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+3.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y,z+1/2
         !-y+3/4,x+1/4,z+1/4
         !y+3/4,-x+3/4,z+3/4
         !-x,-y,-z
         !x+1/2,y,-z+1/2
         !y+1/4,-x+3/4,-z+3/4
         !-y+1/4,x+1/4,-z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)+3.0/4.0
         outco(i,3,2)=+inco(i,1)+1.0/4.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+3.0/4.0
         outco(i,4,2)=-inco(i,1)+3.0/4.0
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/4.0
         outco(i,7,2)=-inco(i,1)+3.0/4.0
         outco(i,7,3)=-inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/4.0
         outco(i,8,2)=+inco(i,1)+1.0/4.0
         outco(i,8,3)=-inco(i,3)+1.0/4.0
         END IF

      CASE (89) !P422
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !-x,+y,-z
         !x,-y,-z
         !y,x,-z
         !-y,-x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (90) !P42(1)2
         !id
         !-x,-y,z
         !-y+1/2,x+1/2,z
         !y+1/2,-x+1/2,z
         !-x+1/2,+y+1/2,-z
         !x+1/2,-y+1/2,-z
         !y,x,-z
         !-y,-x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (91) !P4(1)22
         !id
         !-x,-y,z+1/2
         !-y,x,z+1/4
         !y,-x,z+3/4
         !-x,+y,-z
         !x,-y,-z+1/2
         !y,x,-z+3/4
         !-y,-x-z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/4.0
      
      CASE (92) !P4(1)2(1)2
         !id
         !-x,-y,z+1/2
         !-y+1/2,x+1/2,z+1/4
         !y+1/2,-x+1/2,z+3/4
         !-x+1/2,+y+1/2,-z+1/4
         !x+1/2,-y+1/2,-z+3/4
         !y,x,-z
         !-y,-x-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+3.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (93) !P4(2)22
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         !-x,+y,-z
         !x,-y,-z
         !y,x,-z+1/2
         !-y,-x-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
      
      CASE (94) !P4(2)2(1)2
         !id
         !-x,-y,z
         !-y+1/2,x+1/2,z+1/2
         !y+1/2,-x+1/2,z+1/2
         !-x+1/2,+y+1/2,-z+1/2
         !x+1/2,-y+1/2,-z+1/2
         !y,x,-z
         !-y,-x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (95) !P4(3)22
         !id
         !-x,-y,z+1/2
         !-y,x,z+3/4
         !y,-x,z+1/4
         !-x,+y,-z
         !x,-y,-z+1/2
         !y,x,-z+1/4
         !-y,-x-z+3/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+3.0/4.0

      CASE (96) !P4(3)2(1)2
         !id
         !-x,-y,z+1/2
         !-y,x,z+1/4
         !y,-x,z+3/4
         !-x,+y,-z
         !x,-y,-z+1/2
         !y,x,-z+3/4
         !-y,-x-z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+3.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (97) !I422
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !-x,+y,-z
         !x,-y,-z
         !y,x,-z
         !-y,-x-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (98) !I4(1)22
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-y,x,z+1/4
         !y,-x,z+3/4
         !-x,+y,-z
         !x,-y,-z+1/2
         !y,x,-z+3/4
         !-y,-x-z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+3.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (99) !P4mm
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x,-y,+z
         !-x,+y,+z
         !-y,-x,+z
         !y,x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (100) !P4bm
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x+1/2,-y+1/2,+z
         !-x+1/2,+y+1/2,+z
         !-y+1/2,-x+1/2,+z
         !y+1/2,x+1/2,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (101) !P4(2)cm
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         !+x,-y,+z+1/2
         !-x,+y,+z+1/2
         !-y,-x,+z
         !y,x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (102) !P4(2)nm
         !id
         !-x,-y,z
         !-y+1/2,x+1/2,z+1/2
         !y+1/2,-x+1/2,z+1/2
         !+x+1/2,-y+1/2,+z+1/2
         !-x+1/2,+y+1/2,+z+1/2
         !-y,-x,+z
         !y,x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (103) !P4cc
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x,-y,+z+1/2
         !-x,+y,+z+1/2
         !-y,-x,+z+1/2
         !y,x,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (104) !P4nc
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x+1/2,-y+1/2,+z+1/2
         !-x+1/2,+y+1/2,+z+1/2
         !-y+1/2,-x+1/2,+z+1/2
         !y+1/2,x+1/2,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (105) !P4(2)mc
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         !+x,-y,+z
         !-x,+y,+z
         !-y,-x,+z+1/2
         !y,x,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (106) !P4(2)bc
         !id
         !-x,-y,z
         !-y,x,z+1/2
         !y,-x,z+1/2
         !+x+1/2,-y+1/2,+z
         !-x+1/2,+y+1/2,+z+1/2
         !-y+1/2,-x+1/2,+z+1/2
         !y+1/2,x+1/2,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (107) !I4mm
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x,-y,+z
         !-x,+y,+z
         !-y,-x,+z
         !y,x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (108) !I4cm
         !id
         !-x,-y,z
         !-y,x,z
         !y,-x,z
         !+x+1/2,-y+1/2,+z
         !-x+1/2,+y+1/2,+z
         !-y+1/2,-x+1/2,+z
         !y+1/2,x+1/2,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (109) !I4(1)md
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-y,x+1/2,z+1/4
         !y+1/2,-x,z+3/4
         !+x,-y,+z
         !-x+1/2,+y+1/2,+z+1/2
         !-y,-x+1/2,+z+1/2
         !y+1/2,x,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/4.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+3.0/4.0

      CASE (110) !I4(1)cd
         !id
         !-x+1/2,-y+1/2,z+1/2
         !-y,x+1/2,z+1/4
         !y+1/2,-x,z+3/4
         !+x,-y,+z+1/2
         !-x+1/2,+y+1/2,+z
         !-y,-x+1/2,+z+3/4
         !y+1/2,x,z+1/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+1.0/4.0

      CASE (111) !P-42m
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !-x,+y,-z
         !+x,-y,-z
         !-y,-x,+z
         !y,x,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (112) !P-42c
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !-x,+y,-z+1/2
         !+x,-y,-z+1/2
         !-y,-x,+z+1/2
         !y,x,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (113) !P-42(1)m
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !-x+1/2,+y+1/2,-z
         !+x+1/2,-y+1/2,-z
         !-y+1/2,-x+1/2,+z
         !y+1/2,x+1/2,z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=+inco(i,3)

      CASE (114) !P-42(1)c
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !-x+1/2,+y+1/2,-z+1/2
         !+x+1/2,-y+1/2,-z+1/2
         !-y+1/2,-x+1/2,+z+1/2
         !y+1/2,x+1/2,z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)+1.0/2.0
         outco(i,8,3)=+inco(i,3)+1.0/2.0

      CASE (115) !P-4m2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x,-y,+z
         !-x,+y,+z
         !+y,+x,-z
         !-y,-x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (116) !P-4c2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x,-y,+z+1/2
         !-x,+y,+z+1/2
         !+y,+x,-z+1/2
         !-y,-x,-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (117) !P-4b2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x+1/2,-y+1/2,+z
         !-x+1/2,+y+1/2,+z
         !+y+1/2,+x+1/2,-z
         !-y+1/2,-x+1/2,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)

      CASE (118) !P-4n2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x+1/2,-y+1/2,+z+1/2
         !-x+1/2,+y+1/2,+z+1/2
         !+y+1/2,+x+1/2,-z+1/2
         !-y+1/2,-x+1/2,-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)+1.0/2.0
         outco(i,5,2)=-inco(i,2)+1.0/2.0
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=+inco(i,2)+1.0/2.0
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (119) !I-4m2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x,-y,+z
         !-x,+y,+z
         !+y,+x,-z
         !-y,-x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)

      CASE (120) !I-4c2
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x,-y,+z+1/2
         !-x,+y,+z+1/2
         !+y,+x,-z+1/2
         !-y,-x,-z+1/2
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0

      CASE (121) !I-42m
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !+x,-y,+z
         !-x,+y,+z
         !+y,+x,-z
         !-y,-x,-z
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)

      CASE (122) !I-42d
         !id
         !-x,-y,z
         !y,-x,-z
         !-y,+x,-z
         !-x+1/2,+y,-z+3/4
         !+x+1/2,-y,-z+3/4
         !-y+1/2,-x,+z+3/4
         !+y+1/2,+x,+z+3/4
         
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+3.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+3.0/4.0
         !S=7
         outco(i,7,1)=-inco(i,2)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=+inco(i,2)+1.0/2.0
         outco(i,8,2)=+inco(i,1)
         outco(i,8,3)=+inco(i,3)+3.0/4.0

      CASE (123) !P4/mmm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)

      CASE (124) !P4/mcc
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z+1/2
         !+x,-y,-z+1/2
         !+y,+x,-z+1/2
         !-y,-x,-z+1/2
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z+1/2
         !-x,y,z+1/2
         !-y,-x,z+1/2
         !y,x,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0

      CASE (125) !P4/nbm
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x+1/2,-y+1/2,-z
         !x+1/2,y+1/2,-z
         !y+1/2,-x+1/2,-z
         !-y+1/2,x+1/2,-z
         !x+1/2,-y+1/2,z
         !-x+1/2,y+1/2,z
         !-y+1/2,-x+1/2,z
         !y+1/2,x+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)+1.0/2.0
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x+1/2,-y+1/2,z
         !-y+1/2,+x,+z
         !+y,-x+1/2,+z
         !-x+1/2,+y,-z
         !+x,-y+1/2,-z
         !+y,+x,-z
         !-y+1/2,-x+1/2,-z
         !-x,-y,-z
         !x+1/2,y+1/2,-z
         !y+1/2,-x,-z
         !-y,x+1/2,-z
         !x+1/2,-y,z
         !-x,y+1/2,z
         !-y,-x,z
         !y+1/2,x+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         END IF

      CASE (126) !P4/nnc
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x+1/2,-y+1/2,-z+1/2
         !x+1/2,y+1/2,-z+1/2
         !y+1/2,-x+1/2,-z+1/2
         !-y+1/2,x+1/2,-z+1/2
         !x+1/2,-y+1/2,z+1/2
         !-x+1/2,y+1/2,z+1/2
         !-y+1/2,-x+1/2,z+1/2
         !y+1/2,x+1/2,z+1/2

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)+1.0/2.0
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (127) !P4/mbm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)

      CASE (128) !P4/mnc
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0

      CASE (129)
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y+1/2,+x+1/2,+z
         !+y+1/2,-x+1/2,+z
         !-x+1/2,+y+1/2,-z
         !+x+1/2,-y+1/2,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x+1/2,-y+1/2,-z
         !x+1/2,y+1/2,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y+1/2,-x+1/2,z
         !y+1/2,x+1/2,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         END IF

      CASE (130) !P4/ncc
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF
      
         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (131) !P4(2)/mmc
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0

      CASE (132) !P4(2)mcm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)

      CASE (133) !P4(2)/nbc
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (134) !P4(2)/nnm
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         END IF

      CASE (135) !P4(2)/mbc
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/2.0
         outco(i,8,2)=-inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0

      CASE (136) !P4(2)mnm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)+1.0/2.0
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)

      CASE (137) !P4(2)/nmc
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (138) !P4(2)/ncm
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)+1.0/2.0
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         END IF
         
         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/2.0
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)+1.0/2.0
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)+1.0/2.0
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         END IF

      CASE (139) !I4/mmm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)

      CASE (140) !I4/mcm
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=+inco(i,1)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=+inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)+1.0/2.0

      CASE (141) !I4(1)amd
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+3.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+1.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/4.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)+3.0/4.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/4.0
         outco(i,3,2)=+inco(i,1)+3.0/4.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/4.0
         outco(i,4,2)=-inco(i,1)+1.0/4.0
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/4.0
         outco(i,7,2)=+inco(i,1)+3.0/4.0
         outco(i,7,3)=-inco(i,3)+1.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/4.0
         outco(i,8,2)=-inco(i,1)+1.0/4.0
         outco(i,8,3)=-inco(i,3)+3.0/4.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)+3.0/4.0
         outco(i,11,2)=-inco(i,1)+1.0/4.0
         outco(i,11,3)=-inco(i,3)+3.0/4.0
         !S=12
         outco(i,12,1)=-inco(i,2)+3.0/4.0
         outco(i,12,2)=+inco(i,1)+3.0/4.0
         outco(i,12,3)=-inco(i,3)+1.0/4.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)
         !S=15
         outco(i,15,1)=-inco(i,2)+3.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=+inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=+inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         END IF

      CASE (142) !I4(1)/acd
         IF (unique=='1') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)
         outco(i,3,2)=+inco(i,1)+1.0/2.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/2.0
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/4.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)+1.0/2.0
         outco(i,6,3)=-inco(i,3)+3.0/4.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/2.0
         outco(i,7,2)=+inco(i,1)+1.0/2.0
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,2)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)+1.0/2.0
         outco(i,9,3)=-inco(i,3)+1.0/4.0
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)+3.0/4.0
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=-inco(i,1)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=+inco(i,1)+1.0/2.0
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=+inco(i,3)+1.0/4.0
         !S=16
         outco(i,16,1)=+inco(i,2)
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+3.0/4.0
         END IF

         IF (unique=='2') THEN
         !id
         !-x,-y,z
         !-y,+x,+z
         !+y,-x,+z
         !-x,+y,-z
         !+x,-y,-z
         !+y,+x,-z
         !-y,-x,-z
         !-x,-y,-z
         !x,y,-z
         !y,-x,-z
         !-y,x,-z
         !x,-y,z
         !-x,y,z
         !-y,-x,z
         !y,x,z

         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,2)+1.0/4.0
         outco(i,3,2)=+inco(i,1)+3.0/4.0
         outco(i,3,3)=+inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=+inco(i,2)+1.0/4.0
         outco(i,4,2)=-inco(i,1)+1.0/4.0
         outco(i,4,3)=+inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=-inco(i,1)+1.0/2.0
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)+1.0/4.0
         outco(i,7,2)=+inco(i,1)+3.0/4.0
         outco(i,7,3)=-inco(i,3)+3.0/4.0
         !S=8
         outco(i,8,1)=-inco(i,2)+1.0/4.0
         outco(i,8,2)=-inco(i,1)+1.0/4.0
         outco(i,8,3)=-inco(i,3)+1.0/4.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)+1.0/2.0
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)+3.0/4.0
         outco(i,11,2)=-inco(i,1)+1.0/4.0
         outco(i,11,3)=-inco(i,3)+3.0/4.0
         !S=12
         outco(i,12,1)=-inco(i,2)+3.0/4.0
         outco(i,12,2)=+inco(i,1)+3.0/4.0
         outco(i,12,3)=-inco(i,3)+1.0/4.0
         !S=13
         outco(i,13,1)=+inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=+inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=+inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=-inco(i,2)+3.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=+inco(i,3)+1.0/4.0
         !S=16
         outco(i,16,1)=+inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=+inco(i,3)+3.0/4.0
         END IF

      !*****************************************
      !Trigonal 143-167
      
      CASE (143) !P3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)

      CASE (144) !P3(1)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0

      CASE (145) !P3(2)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0

      CASE (146) !R3
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=+inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=inco(i,3)
         outco(i,3,3)=+inco(i,1)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         END IF

      CASE (147) !P-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=-inco(i,3)
      CASE (148) !R-3
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=+inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=inco(i,3)
         outco(i,3,3)=+inco(i,1)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,3)
         outco(i,5,2)=-inco(i,1)
         outco(i,5,3)=-inco(i,2)
         !S=6
         outco(i,6,1)=-inco(i,2)
         outco(i,6,2)=-inco(i,3)
         outco(i,6,3)=-inco(i,1)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=-inco(i,3)
         END IF
      CASE (149) !P312
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=-inco(i,3)

      CASE (150) !P321
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)

      CASE (151) !P3(1)12
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=-inco(i,3)+2.0/3.0
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/3.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=-inco(i,3)

      CASE (152) !P3(1)21
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)+2.0/3.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/3.0

      CASE (153) !P3(2)12
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=-inco(i,3)+1.0/3.0
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+2.0/3.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=-inco(i,3)
      
      CASE (154) !P3(2)21
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)+inco(i,1)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/3.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)+2.0/3.0

      CASE (155) !R32
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=inco(i,2)
         !S=3
         outco(i,3,1)=inco(i,2)
         outco(i,3,2)=inco(i,3)
         outco(i,3,3)=inco(i,1)
         !S=4
         outco(i,4,1)=-inco(i,3)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,1)
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=-inco(i,1)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,3)
         outco(i,6,3)=-inco(i,2)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         END IF

      CASE (156) !P3m1
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !s=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)
         outco(i,6,2)=inco(i,1)-inco(i,2)
         outco(i,6,3)=+inco(i,3)

      CASE (157) !P31m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=+inco(i,3)

      CASE (158) !P3c1
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !s=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)-inco(i,1)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)
         outco(i,6,2)=inco(i,1)-inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0

      CASE (159) !P31c
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0

      CASE (160) !R3m
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=+inco(i,3)
         outco(i,3,3)=+inco(i,1)
         !S=4
         outco(i,4,1)=inco(i,3)
         outco(i,4,2)=inco(i,2)
         outco(i,4,3)=inco(i,1)
         !S=5
         outco(i,5,1)=inco(i,2)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)
         outco(i,6,2)=inco(i,3)
         outco(i,6,3)=inco(i,2)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=+inco(i,3)
         END IF
         
      CASE (161) !R3c
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=+inco(i,3)
         outco(i,3,3)=+inco(i,1)
         !S=4
         outco(i,4,1)=inco(i,3)+1.0/2.0
         outco(i,4,2)=inco(i,2)+1.0/2.0
         outco(i,4,3)=inco(i,1)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,2)+1.0/2.0
         outco(i,5,2)=inco(i,1)+1.0/2.0
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)+1.0/2.0
         outco(i,6,2)=inco(i,3)+1.0/2.0
         outco(i,6,3)=inco(i,2)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         END IF

      CASE (162) !P-31m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,2)
         outco(i,10,2)=+inco(i,1)
         outco(i,10,3)=+inco(i,3)
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)
      
      CASE (163) !P-31c
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,2)
         outco(i,4,2)=-inco(i,1)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,1)+inco(i,2)
         outco(i,5,2)=+inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)
         outco(i,6,2)=+inco(i,1)-inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,2)
         outco(i,10,2)=+inco(i,1)
         outco(i,10,3)=+inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)+1.0/2.0

      CASE (164) !P-3m1
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=+inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=+inco(i,3)

      CASE (165) !P-3c1
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=+inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=+inco(i,3)+1.0/2.0

      CASE (166) !R-3m
         IF (unique=='1') THEN
         !Rhombohedral
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=+inco(i,3)
         outco(i,3,3)=+inco(i,1)
         !S=4
         outco(i,4,1)=-inco(i,3)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,1)
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=-inco(i,1)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,3)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=-inco(i,2)
         outco(i,9,2)=-inco(i,3)
         outco(i,9,3)=-inco(i,1)
         !S=10
         outco(i,10,1)=inco(i,3)
         outco(i,10,2)=inco(i,2)
         outco(i,10,3)=inco(i,1)
         !S=11
         outco(i,11,1)=+inco(i,2)
         outco(i,11,2)=+inco(i,1)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,3)
         outco(i,12,3)=+inco(i,2)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=+inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=+inco(i,3)
         END IF

      CASE (167) !R-3c
         IF (unique=='1') THEN
         !Rhombohedral
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=inco(i,3)
         outco(i,2,2)=inco(i,1)
         outco(i,2,3)=inco(i,2)
         !S=3
         outco(i,3,1)=+inco(i,2)
         outco(i,3,2)=+inco(i,3)
         outco(i,3,3)=+inco(i,1)
         !S=4
         outco(i,4,1)=-inco(i,3)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,1)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,2)+1.0/2.0
         outco(i,5,2)=-inco(i,1)+1.0/2.0
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+1.0/2.0
         outco(i,6,2)=-inco(i,3)+1.0/2.0
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=-inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=-inco(i,2)
         outco(i,9,2)=-inco(i,3)
         outco(i,9,3)=-inco(i,1)
         !S=10
         outco(i,10,1)=inco(i,3)+1.0/2.0
         outco(i,10,2)=inco(i,2)+1.0/2.0
         outco(i,10,3)=inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=+inco(i,2)+1.0/2.0
         outco(i,11,2)=+inco(i,1)+1.0/2.0
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)+1.0/2.0
         outco(i,12,2)=+inco(i,3)+1.0/2.0
         outco(i,12,3)=+inco(i,2)+1.0/2.0
         END IF
   
         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,2)
         outco(i,4,2)=+inco(i,1)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,1)-inco(i,2)
         outco(i,5,2)=-inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)
         outco(i,6,2)=-inco(i,1)+inco(i,2)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=+inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=+inco(i,3)+1.0/2.0
         END IF

      !*****************************************
      !Exagonal 168-194
      CASE (168) !P6
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)

      CASE (169) !P6(1)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+5.0/6.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/6.0

      CASE (170) !P6(5)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/6.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+5.0/6.0

      CASE (171) !P6(2)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+2.0/3.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/3.0

      CASE (172) !P6(4)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/3.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+2.0/3.0

      CASE (173) !P6(3)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/2.0

      CASE (174) !P-6
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=+inco(i,1)-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+inco(i,2)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,3)

      CASE (175) !P6/m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,2)
         outco(i,11,2)=+inco(i,1)-inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,1)+inco(i,2)
         outco(i,12,2)=-inco(i,1)
         outco(i,12,3)=-inco(i,3)
      
      CASE (176) !P6(3)/m
                  DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,1)
         outco(i,7,2)=-inco(i,2)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,2)
         outco(i,8,2)=-inco(i,1)+inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)-inco(i,2)
         outco(i,9,2)=inco(i,1)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=+inco(i,1)
         outco(i,10,2)=+inco(i,2)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,2)
         outco(i,11,2)=+inco(i,1)-inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,1)+inco(i,2)
         outco(i,12,2)=-inco(i,1)
         outco(i,12,3)=-inco(i,3)+1.0/2.0

      CASE (177) !P622
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)

      CASE (178) !P(1)22
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+5.0/6.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/6.0
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/3.0
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+2.0/3.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+5.0/6.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+1.0/6.0

      CASE (179) !P6(5)22
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/6.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+5.0/6.0
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)+2.0/3.0
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+1.0/3.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+1.0/6.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+5.0/6.0

      CASE (180) !P6(2)22
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+2.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+1.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+2.0/3.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/3.0
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)+2.0/3.0
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+1.0/3.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+2.0/3.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+1.0/3.0

      CASE (181) !P6(4)22
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)+1.0/3.0
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)+2.0/3.0
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/3.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+2.0/3.0
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/3.0
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+2.0/3.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+1.0/3.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+2.0/3.0

      CASE (182) !6(3)22
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=inco(i,2)
         outco(i,7,2)=inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+1.0/2.0

      CASE (183) !P6mm
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)

      CASE (184) !P6cc
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)+1.0/2.0
      
      CASE (185) !P6(3)cm
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)

      CASE (186) !P(3)mc
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=+inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=+inco(i,3)+1.0/2.0

      CASE (187) !P-6m2
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=+inco(i,1)-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+inco(i,2)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)
      
      CASE (188) !P-6c2
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=+inco(i,1)-inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+inco(i,2)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,2)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=+inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,1)+inco(i,2)
         outco(i,8,2)=inco(i,2)
         outco(i,8,3)=inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,1)
         outco(i,9,2)=inco(i,1)-inco(i,2)
         outco(i,9,3)=inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=+inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)

      CASE (189) !P-62m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=+inco(i,1)-inco(i,2)
         outco(i,5,3)=-inco(i,3)
         !S=6
         outco(i,6,1)=-inco(i,1)+inco(i,2)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=inco(i,3)
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=inco(i,3)

      CASE (190) !P-62c
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=+inco(i,1)
         outco(i,4,2)=+inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=-inco(i,2)
         outco(i,5,2)=+inco(i,1)-inco(i,2)
         outco(i,5,3)=-inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=-inco(i,1)+inco(i,2)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=inco(i,2)
         outco(i,10,2)=inco(i,1)
         outco(i,10,3)=inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,1)-inco(i,2)
         outco(i,11,2)=-inco(i,2)
         outco(i,11,3)=inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,1)
         outco(i,12,2)=-inco(i,1)+inco(i,2)
         outco(i,12,3)=inco(i,3)+1.0/2.0

      CASE (191) !P6/mmm
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=inco(i,2)
         outco(i,14,2)=-inco(i,1)+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=+inco(i,1)-inco(i,2)
         outco(i,15,2)=+inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=-inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,2)
         outco(i,17,2)=+inco(i,1)-inco(i,2)
         outco(i,17,3)=-inco(i,3)
         !S=18
         outco(i,18,1)=-inco(i,1)+inco(i,2)
         outco(i,18,2)=-inco(i,1)
         outco(i,18,3)=-inco(i,3)
         !S=19
         outco(i,19,1)=-inco(i,2)
         outco(i,19,2)=-inco(i,1)
         outco(i,19,3)=+inco(i,3)
         !S=20
         outco(i,20,1)=-inco(i,1)+inco(i,2)
         outco(i,20,2)=+inco(i,2)
         outco(i,20,3)=+inco(i,3)
         !S=21
         outco(i,21,1)=inco(i,1)
         outco(i,21,2)=+inco(i,1)-inco(i,2)
         outco(i,21,3)=+inco(i,3)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=inco(i,1)
         outco(i,22,3)=inco(i,3)
         !S=23
         outco(i,23,1)=inco(i,1)-inco(i,2)
         outco(i,23,2)=-inco(i,2)
         outco(i,23,3)=inco(i,3)
         !S=24
         outco(i,24,1)=-inco(i,1)
         outco(i,24,2)=-inco(i,1)+inco(i,2)
         outco(i,24,3)=+inco(i,3)

      CASE (192) !P6/mmc
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=+inco(i,3)
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=+inco(i,3)
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=+inco(i,3)
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=inco(i,2)
         outco(i,14,2)=-inco(i,1)+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=+inco(i,1)-inco(i,2)
         outco(i,15,2)=+inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=-inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,2)
         outco(i,17,2)=+inco(i,1)-inco(i,2)
         outco(i,17,3)=-inco(i,3)
         !S=18
         outco(i,18,1)=-inco(i,1)+inco(i,2)
         outco(i,18,2)=-inco(i,1)
         outco(i,18,3)=-inco(i,3)
         !S=19
         outco(i,19,1)=-inco(i,2)
         outco(i,19,2)=-inco(i,1)
         outco(i,19,3)=+inco(i,3)+1.0/2.0
         !S=20
         outco(i,20,1)=-inco(i,1)+inco(i,2)
         outco(i,20,2)=+inco(i,2)
         outco(i,20,3)=+inco(i,3)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,1)
         outco(i,21,2)=+inco(i,1)-inco(i,2)
         outco(i,21,3)=+inco(i,3)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=inco(i,1)
         outco(i,22,3)=inco(i,3)+1.0/2.0
         !S=23
         outco(i,23,1)=inco(i,1)-inco(i,2)
         outco(i,23,2)=-inco(i,2)
         outco(i,23,3)=inco(i,3)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,1)
         outco(i,24,2)=-inco(i,1)+inco(i,2)
         outco(i,24,3)=+inco(i,3)+1.0/2.0

      CASE (193) !P6(3)/mcm
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)+1.0/2.0
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)+1.0/2.0
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)+1.0/2.0
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)
         !S=12
         outco(i,12,1)=inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=inco(i,2)
         outco(i,14,2)=-inco(i,1)+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=+inco(i,1)-inco(i,2)
         outco(i,15,2)=+inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=-inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=-inco(i,2)
         outco(i,17,2)=+inco(i,1)-inco(i,2)
         outco(i,17,3)=-inco(i,3)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+inco(i,2)
         outco(i,18,2)=-inco(i,1)
         outco(i,18,3)=-inco(i,3)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,2)
         outco(i,19,2)=-inco(i,1)
         outco(i,19,3)=+inco(i,3)+1.0/2.0
         !S=20
         outco(i,20,1)=-inco(i,1)+inco(i,2)
         outco(i,20,2)=+inco(i,2)
         outco(i,20,3)=+inco(i,3)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,1)
         outco(i,21,2)=+inco(i,1)-inco(i,2)
         outco(i,21,3)=+inco(i,3)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=inco(i,1)
         outco(i,22,3)=inco(i,3)
         !S=23
         outco(i,23,1)=inco(i,1)-inco(i,2)
         outco(i,23,2)=-inco(i,2)
         outco(i,23,3)=inco(i,3)
         !S=24
         outco(i,24,1)=-inco(i,1)
         outco(i,24,2)=-inco(i,1)+inco(i,2)
         outco(i,24,3)=+inco(i,3)

      CASE (194)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,2)
         outco(i,2,2)=inco(i,1)-inco(i,2)
         outco(i,2,3)=+inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+inco(i,2)
         outco(i,3,2)=-inco(i,1)
         outco(i,3,3)=+inco(i,3)
         !S=4
         outco(i,4,1)=-inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=+inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=+inco(i,2)
         outco(i,5,2)=-inco(i,1)+inco(i,2)
         outco(i,5,3)=+inco(i,3)+1.0/2.0
         !S=6
         outco(i,6,1)=+inco(i,1)-inco(i,2)
         outco(i,6,2)=+inco(i,1)
         outco(i,6,3)=+inco(i,3)+1.0/2.0
         !S=7
         outco(i,7,1)=+inco(i,2)
         outco(i,7,2)=+inco(i,1)
         outco(i,7,3)=-inco(i,3)
         !S=8
         outco(i,8,1)=+inco(i,1)-inco(i,2)
         outco(i,8,2)=-inco(i,2)
         outco(i,8,3)=-inco(i,3)
         !S=9
         outco(i,9,1)=-inco(i,1)
         outco(i,9,2)=-inco(i,1)+inco(i,2)
         outco(i,9,3)=-inco(i,3)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=-inco(i,1)
         outco(i,10,3)=-inco(i,3)+1.0/2.0
         !S=11
         outco(i,11,1)=-inco(i,1)+inco(i,2)
         outco(i,11,2)=+inco(i,2)
         outco(i,11,3)=-inco(i,3)+1.0/2.0
         !S=12
         outco(i,12,1)=inco(i,1)
         outco(i,12,2)=+inco(i,1)-inco(i,2)
         outco(i,12,3)=-inco(i,3)+1.0/2.0
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=inco(i,2)
         outco(i,14,2)=-inco(i,1)+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=+inco(i,1)-inco(i,2)
         outco(i,15,2)=+inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=+inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=-inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=-inco(i,2)
         outco(i,17,2)=+inco(i,1)-inco(i,2)
         outco(i,17,3)=-inco(i,3)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+inco(i,2)
         outco(i,18,2)=-inco(i,1)
         outco(i,18,3)=-inco(i,3)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,2)
         outco(i,19,2)=-inco(i,1)
         outco(i,19,3)=+inco(i,3)
         !S=20
         outco(i,20,1)=-inco(i,1)+inco(i,2)
         outco(i,20,2)=+inco(i,2)
         outco(i,20,3)=+inco(i,3)
         !S=21
         outco(i,21,1)=inco(i,1)
         outco(i,21,2)=+inco(i,1)-inco(i,2)
         outco(i,21,3)=+inco(i,3)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=inco(i,1)
         outco(i,22,3)=inco(i,3)+1.0/2.0
         !S=23
         outco(i,23,1)=inco(i,1)-inco(i,2)
         outco(i,23,2)=-inco(i,2)
         outco(i,23,3)=inco(i,3)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,1)
         outco(i,24,2)=-inco(i,1)+inco(i,2)
         outco(i,24,3)=+inco(i,3)+1.0/2.0
      !*****************************************
      !Cubic 195-230
      CASE (195) !P23
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)

      CASE (196) !F23
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
      
      CASE (197) !I23
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)

      CASE (198) !P2(1)3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0

      CASE (199) !I2(1)3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0

      CASE (200) !Pm-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,1)
         outco(i,15,2)=-inco(i,2)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)
         outco(i,18,2)=+inco(i,1)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=+inco(i,3)
         outco(i,19,2)=+inco(i,1)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,3)
         outco(i,20,2)=-inco(i,1)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=-inco(i,3)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,2)
         outco(i,23,2)=inco(i,3)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=+inco(i,2)
         outco(i,24,2)=+inco(i,3)
         outco(i,24,3)=-inco(i,1)

      CASE(201) !Pn-3
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)+1.0/2.0
         outco(i,13,2)=-inco(i,2)+1.0/2.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,1)+1.0/2.0
         outco(i,15,2)=-inco(i,2)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,1)+1.0/2.0
         outco(i,16,2)=+inco(i,2)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=-inco(i,3)+1.0/2.0
         outco(i,17,2)=-inco(i,1)+1.0/2.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,3)+1.0/2.0
         outco(i,18,2)=+inco(i,1)+1.0/2.0
         outco(i,18,3)=+inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/2.0
         outco(i,19,2)=+inco(i,1)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,3)+1.0/2.0
         outco(i,20,2)=-inco(i,1)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=-inco(i,2)+1.0/2.0
         outco(i,21,2)=-inco(i,3)+1.0/2.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,2)+1.0/2.0
         outco(i,22,2)=-inco(i,3)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,2)+1.0/2.0
         outco(i,23,2)=inco(i,3)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/2.0
         outco(i,24,2)=+inco(i,3)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)+1.0/2.0
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,1)+1.0/2.0
         outco(i,15,2)=-inco(i,2)
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,1)
         outco(i,16,2)=+inco(i,2)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)
         outco(i,18,2)=+inco(i,1)+1.0/2.0
         outco(i,18,3)=+inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/2.0
         outco(i,19,2)=+inco(i,1)+1.0/2.0
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,3)+1.0/2.0
         outco(i,20,2)=-inco(i,1)
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)+1.0/2.0
         outco(i,22,2)=-inco(i,3)
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,2)
         outco(i,23,2)=inco(i,3)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/2.0
         outco(i,24,2)=+inco(i,3)+1.0/2.0
         outco(i,24,3)=-inco(i,1)
         END IF

      CASE (202) !Fm-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,1)
         outco(i,15,2)=-inco(i,2)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)
         outco(i,18,2)=+inco(i,1)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=+inco(i,3)
         outco(i,19,2)=+inco(i,1)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,3)
         outco(i,20,2)=-inco(i,1)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=-inco(i,3)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,2)
         outco(i,23,2)=inco(i,3)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=+inco(i,2)
         outco(i,24,2)=+inco(i,3)
         outco(i,24,3)=-inco(i,1)

      CASE (203) !Fd-3
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)+1.0/4.0
         outco(i,13,2)=-inco(i,2)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+1.0/4.0
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/4.0
         outco(i,14,2)=+inco(i,2)+1.0/4.0
         outco(i,14,3)=-inco(i,3)+1.0/4.0
         !S=15
         outco(i,15,1)=inco(i,1)+1.0/4.0
         outco(i,15,2)=-inco(i,2)+1.0/4.0
         outco(i,15,3)=inco(i,3)+1.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,1)+1.0/4.0
         outco(i,16,2)=+inco(i,2)+1.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=-inco(i,3)+1.0/4.0
         outco(i,17,2)=-inco(i,1)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+1.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,3)+1.0/4.0
         outco(i,18,2)=+inco(i,1)+1.0/4.0
         outco(i,18,3)=+inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/4.0
         outco(i,19,2)=+inco(i,1)+1.0/4.0
         outco(i,19,3)=-inco(i,2)+1.0/4.0
         !S=20
         outco(i,20,1)=inco(i,3)+1.0/4.0
         outco(i,20,2)=-inco(i,1)+1.0/4.0
         outco(i,20,3)=inco(i,2)+1.0/4.0
         !S=21
         outco(i,21,1)=-inco(i,2)+1.0/4.0
         outco(i,21,2)=-inco(i,3)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+1.0/4.0
         !S=22
         outco(i,22,1)=inco(i,2)+1.0/4.0
         outco(i,22,2)=-inco(i,3)+1.0/4.0
         outco(i,22,3)=inco(i,1)+1.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,2)+1.0/4.0
         outco(i,23,2)=inco(i,3)+1.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/4.0
         outco(i,24,2)=+inco(i,3)+1.0/4.0
         outco(i,24,3)=-inco(i,1)+1.0/4.0
         END IF
         
         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+3.0/4.0
         outco(i,2,2)=-inco(i,2)+3.0/4.0
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+3.0/4.0
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)+3.0/4.0
         outco(i,4,3)=-inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)+3.0/4.0
         outco(i,6,3)=-inco(i,2)+3.0/4.0
         !S=7
         outco(i,7,1)=-inco(i,3)+3.0/4.0
         outco(i,7,2)=-inco(i,1)+3.0/4.0
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)+3.0/4.0
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)+3.0/4.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+3.0/4.0
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)+3.0/4.0
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)+3.0/4.0
         outco(i,11,3)=-inco(i,1)+3.0/4.0
         !S=12
         outco(i,12,1)=-inco(i,2)+3.0/4.0
         outco(i,12,2)=-inco(i,3)+3.0/4.0
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/4.0
         outco(i,14,2)=+inco(i,2)+1.0/4.0
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,1)+1.0/4.0
         outco(i,15,2)=-inco(i,2)
         outco(i,15,3)=inco(i,3)+1.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,1)
         outco(i,16,2)=+inco(i,2)+1.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)
         outco(i,18,2)=+inco(i,1)+1.0/4.0
         outco(i,18,3)=+inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/4.0
         outco(i,19,2)=+inco(i,1)+1.0/4.0
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,3)+1.0/4.0
         outco(i,20,2)=-inco(i,1)
         outco(i,20,3)=inco(i,2)+1.0/4.0
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)+1.0/4.0
         outco(i,22,2)=-inco(i,3)
         outco(i,22,3)=inco(i,1)+1.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,2)
         outco(i,23,2)=inco(i,3)+1.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/4.0
         outco(i,24,2)=+inco(i,3)+1.0/4.0
         outco(i,24,3)=-inco(i,1)
         END IF

      CASE (204) !Im-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,1)
         outco(i,15,2)=-inco(i,2)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,1)
         outco(i,16,2)=+inco(i,2)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)
         outco(i,18,2)=+inco(i,1)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=+inco(i,3)
         outco(i,19,2)=+inco(i,1)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,3)
         outco(i,20,2)=-inco(i,1)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=-inco(i,3)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,2)
         outco(i,23,2)=inco(i,3)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=+inco(i,2)
         outco(i,24,2)=+inco(i,3)
         outco(i,24,3)=-inco(i,1)

      CASE (205) !Pa-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,1)
         outco(i,15,2)=-inco(i,2)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,1)+1.0/2.0
         outco(i,16,2)=+inco(i,2)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)+1.0/2.0
         outco(i,18,2)=+inco(i,1)+1.0/2.0
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/2.0
         outco(i,19,2)=+inco(i,1)
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,3)
         outco(i,20,2)=-inco(i,1)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=-inco(i,3)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,2)+1.0/2.0
         outco(i,23,2)=inco(i,3)+1.0/2.0
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/2.0
         outco(i,24,2)=+inco(i,3)
         outco(i,24,3)=-inco(i,1)+1.0/2.0

      CASE (206) !Ia-3
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=-inco(i,1)
         outco(i,13,2)=-inco(i,2)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=+inco(i,1)+1.0/2.0
         outco(i,14,2)=+inco(i,2)
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,1)
         outco(i,15,2)=-inco(i,2)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,1)+1.0/2.0
         outco(i,16,2)=+inco(i,2)+1.0/2.0
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=-inco(i,3)
         outco(i,17,2)=-inco(i,1)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,3)+1.0/2.0
         outco(i,18,2)=+inco(i,1)+1.0/2.0
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=+inco(i,3)+1.0/2.0
         outco(i,19,2)=+inco(i,1)
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,3)
         outco(i,20,2)=-inco(i,1)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=-inco(i,2)
         outco(i,21,2)=-inco(i,3)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,2)
         outco(i,22,2)=-inco(i,3)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,2)+1.0/2.0
         outco(i,23,2)=inco(i,3)+1.0/2.0
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=+inco(i,2)+1.0/2.0
         outco(i,24,2)=+inco(i,3)
         outco(i,24,3)=-inco(i,1)+1.0/2.0

      CASE (207) !P432
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)

      CASE (208) !P4(2)32
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=+inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=+inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0

      CASE (209) !F432
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)

      CASE (210) !F4(1)32
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+3.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/4.0
         outco(i,14,2)=-inco(i,1)+1.0/4.0
         outco(i,14,3)=-inco(i,3)+1.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+3.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+3.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+3.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=+inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/4.0
         outco(i,19,2)=-inco(i,3)+1.0/4.0
         outco(i,19,3)=-inco(i,2)+1.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+3.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+3.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+3.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+3.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/4.0
         outco(i,24,2)=-inco(i,2)+1.0/4.0
         outco(i,24,3)=-inco(i,1)+1.0/4.0

      CASE (211) !I432
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=+inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=+inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)

      CASE (212) !P4(3)32
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/4.0
         outco(i,13,2)=inco(i,1)+3.0/4.0
         outco(i,13,3)=-inco(i,3)+3.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/4.0
         outco(i,14,2)=-inco(i,1)+1.0/4.0
         outco(i,14,3)=-inco(i,3)+1.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+3.0/4.0
         outco(i,15,2)=-inco(i,1)+3.0/4.0
         outco(i,15,3)=inco(i,3)+1.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+1.0/4.0
         outco(i,16,3)=+inco(i,3)+3.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/4.0
         outco(i,17,2)=+inco(i,3)+3.0/4.0
         outco(i,17,3)=-inco(i,2)+3.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+3.0/4.0
         outco(i,18,2)=+inco(i,3)+1.0/4.0
         outco(i,18,3)=+inco(i,2)+3.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/4.0
         outco(i,19,2)=-inco(i,3)+1.0/4.0
         outco(i,19,3)=-inco(i,2)+1.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+3.0/4.0
         outco(i,20,2)=-inco(i,3)+3.0/4.0
         outco(i,20,3)=inco(i,2)+1.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/4.0
         outco(i,21,2)=inco(i,2)+3.0/4.0
         outco(i,21,3)=-inco(i,1)+3.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+3.0/4.0
         outco(i,22,2)=-inco(i,2)+3.0/4.0
         outco(i,22,3)=inco(i,1)+1.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+3.0/4.0
         outco(i,23,2)=inco(i,2)+1.0/4.0
         outco(i,23,3)=inco(i,1)+3.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/4.0
         outco(i,24,2)=-inco(i,2)+1.0/4.0
         outco(i,24,3)=-inco(i,1)+1.0/4.0

      CASE (213) !P4(1)32
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+1.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+3.0/4.0
         outco(i,14,2)=-inco(i,1)+3.0/4.0
         outco(i,14,3)=-inco(i,3)+3.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+1.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=+inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+3.0/4.0
         outco(i,19,2)=-inco(i,3)+3.0/4.0
         outco(i,19,3)=-inco(i,2)+3.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+1.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+1.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+1.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+3.0/4.0
         outco(i,24,2)=-inco(i,2)+3.0/4.0
         outco(i,24,3)=-inco(i,1)+3.0/4.0

      CASE (214) !I4(1)32
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+1.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+3.0/4.0
         outco(i,14,2)=-inco(i,1)+3.0/4.0
         outco(i,14,3)=-inco(i,3)+3.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=+inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+1.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=+inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+3.0/4.0
         outco(i,19,2)=-inco(i,3)+3.0/4.0
         outco(i,19,3)=-inco(i,2)+3.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+1.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+1.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+1.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+3.0/4.0
         outco(i,24,2)=-inco(i,2)+3.0/4.0
         outco(i,24,3)=-inco(i,1)+3.0/4.0

      CASE (215) !P-43m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=-inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=-inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=-inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=-inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=-inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=inco(i,1)

      CASE (216) !F-43m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=-inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=-inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=-inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=-inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=-inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=inco(i,1)

      CASE (217) !I-43m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=-inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=-inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=-inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=-inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=-inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=-inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=inco(i,1)

      CASE (218) !P-43n
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=-inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=-inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=-inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=-inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=-inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=-inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=inco(i,1)+1.0/2.0

      CASE (219) !F-43c
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=-inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=-inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=-inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=-inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=-inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=-inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=inco(i,1)+1.0/2.0

      CASE (220) !I-43d
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=inco(i,3)+1.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/4.0
         outco(i,14,2)=-inco(i,1)+3.0/4.0
         outco(i,14,3)=inco(i,3)+3.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+3.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=-inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=-inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=inco(i,2)+1.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+3.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=-inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/4.0
         outco(i,19,2)=-inco(i,3)+3.0/4.0
         outco(i,19,3)=inco(i,2)+3.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+3.0/4.0
         outco(i,20,2)=-inco(i,3)+1.0/4.0
         outco(i,20,3)=-inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=inco(i,1)+1.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+3.0/4.0
         outco(i,22,2)=-inco(i,2)+1.0/4.0
         outco(i,22,3)=-inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+3.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=-inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/4.0
         outco(i,24,2)=-inco(i,2)+3.0/4.0
         outco(i,24,3)=inco(i,1)+3.0/4.0

      CASE (221) !Pm-3m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)

      CASE (222) !Pn-3n
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)+1.0/2.0
         outco(i,25,2)=-inco(i,2)+1.0/2.0
         outco(i,25,3)=-inco(i,3)+1.0/2.0
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/2.0
         outco(i,26,2)=inco(i,2)+1.0/2.0
         outco(i,26,3)=-inco(i,3)+1.0/2.0
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/2.0
         outco(i,27,2)=-inco(i,2)+1.0/2.0
         outco(i,27,3)=inco(i,3)+1.0/2.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/2.0
         outco(i,28,2)=inco(i,2)+1.0/2.0
         outco(i,28,3)=inco(i,3)+1.0/2.0
         !S=29
         outco(i,29,1)=-inco(i,3)+1.0/2.0
         outco(i,29,2)=-inco(i,1)+1.0/2.0
         outco(i,29,3)=-inco(i,2)+1.0/2.0
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/2.0
         outco(i,30,2)=inco(i,1)+1.0/2.0
         outco(i,30,3)=inco(i,2)+1.0/2.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/2.0
         outco(i,31,2)=inco(i,1)+1.0/2.0
         outco(i,31,3)=-inco(i,2)+1.0/2.0
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/2.0
         outco(i,32,2)=-inco(i,1)+1.0/2.0
         outco(i,32,3)=inco(i,2)+1.0/2.0
         !S=33
         outco(i,33,1)=-inco(i,2)+1.0/2.0
         outco(i,33,2)=-inco(i,3)+1.0/2.0
         outco(i,33,3)=-inco(i,1)+1.0/2.0
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/2.0
         outco(i,34,2)=-inco(i,3)+1.0/2.0
         outco(i,34,3)=inco(i,1)+1.0/2.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/2.0
         outco(i,35,2)=inco(i,3)+1.0/2.0
         outco(i,35,3)=inco(i,1)+1.0/2.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/2.0
         outco(i,36,2)=inco(i,3)+1.0/2.0
         outco(i,36,3)=-inco(i,1)+1.0/2.0
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/2.0
         outco(i,37,2)=-inco(i,1)+1.0/2.0
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)+1.0/2.0
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)+1.0/2.0
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)+1.0/2.0
         outco(i,40,3)=-inco(i,3)+1.0/2.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/2.0
         outco(i,41,2)=-inco(i,3)+1.0/2.0
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)+1.0/2.0
         outco(i,42,3)=-inco(i,2)+1.0/2.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)+1.0/2.0
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)+1.0/2.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/2.0
         outco(i,45,2)=-inco(i,2)+1.0/2.0
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)+1.0/2.0
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)+1.0/2.0
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)+1.0/2.0
         outco(i,47,3)=-inco(i,1)+1.0/2.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/2.0
         outco(i,26,2)=inco(i,2)+1.0/2.0
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/2.0
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)+1.0/2.0
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)+1.0/2.0
         outco(i,28,3)=inco(i,3)+1.0/2.0
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)+1.0/2.0
         outco(i,30,3)=inco(i,2)+1.0/2.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/2.0
         outco(i,31,2)=inco(i,1)+1.0/2.0
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/2.0
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)+1.0/2.0
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/2.0
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)+1.0/2.0
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)+1.0/2.0
         outco(i,35,3)=inco(i,1)+1.0/2.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/2.0
         outco(i,36,2)=inco(i,3)+1.0/2.0
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0
         END IF

      CASE (223) !Pm-3n
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/2.0
         outco(i,37,2)=-inco(i,1)+1.0/2.0
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)+1.0/2.0
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)+1.0/2.0
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)+1.0/2.0
         outco(i,40,3)=-inco(i,3)+1.0/2.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/2.0
         outco(i,41,2)=-inco(i,3)+1.0/2.0
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)+1.0/2.0
         outco(i,42,3)=-inco(i,2)+1.0/2.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)+1.0/2.0
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)+1.0/2.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/2.0
         outco(i,45,2)=-inco(i,2)+1.0/2.0
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)+1.0/2.0
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)+1.0/2.0
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)+1.0/2.0
         outco(i,47,3)=-inco(i,1)+1.0/2.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0

      CASE (224) !Pn-3m
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         !S=25
         outco(i,25,1)=-inco(i,1)+1.0/2.0
         outco(i,25,2)=-inco(i,2)+1.0/2.0
         outco(i,25,3)=-inco(i,3)+1.0/2.0
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/2.0
         outco(i,26,2)=inco(i,2)+1.0/2.0
         outco(i,26,3)=-inco(i,3)+1.0/2.0
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/2.0
         outco(i,27,2)=-inco(i,2)+1.0/2.0
         outco(i,27,3)=inco(i,3)+1.0/2.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/2.0
         outco(i,28,2)=inco(i,2)+1.0/2.0
         outco(i,28,3)=inco(i,3)+1.0/2.0
         !S=29
         outco(i,29,1)=-inco(i,3)+1.0/2.0
         outco(i,29,2)=-inco(i,1)+1.0/2.0
         outco(i,29,3)=-inco(i,2)+1.0/2.0
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/2.0
         outco(i,30,2)=inco(i,1)+1.0/2.0
         outco(i,30,3)=inco(i,2)+1.0/2.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/2.0
         outco(i,31,2)=inco(i,1)+1.0/2.0
         outco(i,31,3)=-inco(i,2)+1.0/2.0
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/2.0
         outco(i,32,2)=-inco(i,1)+1.0/2.0
         outco(i,32,3)=inco(i,2)+1.0/2.0
         !S=33
         outco(i,33,1)=-inco(i,2)+1.0/2.0
         outco(i,33,2)=-inco(i,3)+1.0/2.0
         outco(i,33,3)=-inco(i,1)+1.0/2.0
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/2.0
         outco(i,34,2)=-inco(i,3)+1.0/2.0
         outco(i,34,3)=inco(i,1)+1.0/2.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/2.0
         outco(i,35,2)=inco(i,3)+1.0/2.0
         outco(i,35,3)=inco(i,1)+1.0/2.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/2.0
         outco(i,36,2)=inco(i,3)+1.0/2.0
         outco(i,36,3)=-inco(i,1)+1.0/2.0
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/2.0
         outco(i,26,2)=inco(i,2)+1.0/2.0
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/2.0
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)+1.0/2.0
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)+1.0/2.0
         outco(i,28,3)=inco(i,3)+1.0/2.0
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)+1.0/2.0
         outco(i,30,3)=inco(i,2)+1.0/2.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/2.0
         outco(i,31,2)=inco(i,1)+1.0/2.0
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/2.0
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)+1.0/2.0
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/2.0
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)+1.0/2.0
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)+1.0/2.0
         outco(i,35,3)=inco(i,1)+1.0/2.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/2.0
         outco(i,36,2)=inco(i,3)+1.0/2.0
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/2.0
         outco(i,37,2)=-inco(i,1)+1.0/2.0
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)+1.0/2.0
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)+1.0/2.0
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)+1.0/2.0
         outco(i,40,3)=-inco(i,3)+1.0/2.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/2.0
         outco(i,41,2)=-inco(i,3)+1.0/2.0
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)+1.0/2.0
         outco(i,42,3)=-inco(i,2)+1.0/2.0
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)+1.0/2.0
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)+1.0/2.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/2.0
         outco(i,45,2)=-inco(i,2)+1.0/2.0
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)+1.0/2.0
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)+1.0/2.0
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)+1.0/2.0
         outco(i,47,3)=-inco(i,1)+1.0/2.0
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)
         END IF

      CASE (225) !Fm-3m
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)

      CASE (226) !Fm-3c
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)+1.0/2.0
         outco(i,13,2)=inco(i,1)+1.0/2.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/2.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)+1.0/2.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+1.0/2.0
         outco(i,16,3)=inco(i,3)+1.0/2.0
         !S=17
         outco(i,17,1)=+inco(i,1)+1.0/2.0
         outco(i,17,2)=+inco(i,3)+1.0/2.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+1.0/2.0
         outco(i,18,3)=inco(i,2)+1.0/2.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/2.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)+1.0/2.0
         !S=21
         outco(i,21,1)=inco(i,3)+1.0/2.0
         outco(i,21,2)=inco(i,2)+1.0/2.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/2.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)+1.0/2.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+1.0/2.0
         outco(i,23,3)=inco(i,1)+1.0/2.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/2.0
         outco(i,37,2)=-inco(i,1)+1.0/2.0
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)+1.0/2.0
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)+1.0/2.0
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)+1.0/2.0
         outco(i,40,3)=-inco(i,3)+1.0/2.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/2.0
         outco(i,41,2)=-inco(i,3)+1.0/2.0
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)+1.0/2.0
         outco(i,42,3)=-inco(i,2)+1.0/2.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)+1.0/2.0
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)+1.0/2.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/2.0
         outco(i,45,2)=-inco(i,2)+1.0/2.0
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)+1.0/2.0
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)+1.0/2.0
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)+1.0/2.0
         outco(i,47,3)=-inco(i,1)+1.0/2.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0

      CASE (227) !Fd-3m
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+3.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/4.0
         outco(i,14,2)=-inco(i,1)+1.0/4.0
         outco(i,14,3)=-inco(i,3)+1.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+3.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+3.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+3.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/4.0
         outco(i,19,2)=-inco(i,3)+1.0/4.0
         outco(i,19,3)=-inco(i,2)+1.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+3.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+3.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+3.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+3.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/4.0
         outco(i,24,2)=-inco(i,2)+1.0/4.0
         outco(i,24,3)=-inco(i,1)+1.0/4.0
         !S=25
         outco(i,25,1)=-inco(i,1)+1.0/4.0
         outco(i,25,2)=-inco(i,2)+1.0/4.0
         outco(i,25,3)=-inco(i,3)+1.0/4.0
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/4.0
         outco(i,26,2)=inco(i,2)+3.0/4.0
         outco(i,26,3)=-inco(i,3)+3.0/4.0
         !S=27
         outco(i,27,1)=inco(i,1)+3.0/4.0
         outco(i,27,2)=-inco(i,2)+3.0/4.0
         outco(i,27,3)=inco(i,3)+1.0/4.0
         !S=28
         outco(i,28,1)=-inco(i,1)+3.0/4.0
         outco(i,28,2)=inco(i,2)+1.0/4.0
         outco(i,28,3)=inco(i,3)+3.0/4.0
         !S=29
         outco(i,29,1)=-inco(i,3)+1.0/4.0
         outco(i,29,2)=-inco(i,1)+1.0/4.0
         outco(i,29,3)=-inco(i,2)+1.0/4.0
         !S=30
         outco(i,30,1)=-inco(i,3)+3.0/4.0
         outco(i,30,2)=inco(i,1)+1.0/4.0
         outco(i,30,3)=inco(i,2)+3.0/4.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/4.0
         outco(i,31,2)=inco(i,1)+3.0/4.0
         outco(i,31,3)=-inco(i,2)+3.0/4.0
         !S=32
         outco(i,32,1)=inco(i,3)+3.0/4.0
         outco(i,32,2)=-inco(i,1)+3.0/4.0
         outco(i,32,3)=inco(i,2)+1.0/4.0
         !S=33
         outco(i,33,1)=-inco(i,2)+1.0/4.0
         outco(i,33,2)=-inco(i,3)+1.0/4.0
         outco(i,33,3)=-inco(i,1)+1.0/4.0
         !S=34
         outco(i,34,1)=inco(i,2)+3.0/4.0
         outco(i,34,2)=-inco(i,3)+3.0/4.0
         outco(i,34,3)=inco(i,1)+1.0/4.0
         !S=35
         outco(i,35,1)=-inco(i,2)+3.0/4.0
         outco(i,35,2)=inco(i,3)+1.0/4.0
         outco(i,35,3)=inco(i,1)+3.0/4.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/4.0
         outco(i,36,2)=inco(i,3)+3.0/4.0
         outco(i,36,3)=-inco(i,1)+3.0/4.0
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/2.0
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)+1.0/2.0
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)+1.0/2.0
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/2.0
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)+1.0/2.0
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)+1.0/2.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/2.0
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)+1.0/2.0
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)+1.0/2.0
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+3.0/4.0
         outco(i,2,2)=-inco(i,2)+1.0/4.0
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/4.0
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+3.0/4.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+3.0/4.0
         outco(i,4,3)=-inco(i,3)+1.0/4.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+3.0/4.0
         outco(i,6,3)=-inco(i,2)+1.0/4.0
         !S=7
         outco(i,7,1)=-inco(i,3)+3.0/4.0
         outco(i,7,2)=-inco(i,1)+1.0/4.0
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/4.0
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+3.0/4.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/4.0
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+3.0/4.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+3.0/4.0
         outco(i,11,3)=-inco(i,1)+1.0/4.0
         !S=12
         outco(i,12,1)=-inco(i,2)+3.0/4.0
         outco(i,12,2)=-inco(i,3)+1.0/4.0
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+1.0/2.0
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/2.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/2.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+1.0/2.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/2.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+1.0/2.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+1.0/2.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+1.0/2.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/2.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/4.0
         outco(i,26,2)=inco(i,2)+3.0/4.0
         outco(i,26,3)=-inco(i,3)+1.0/2.0
         !S=27
         outco(i,27,1)=inco(i,1)+3.0/4.0
         outco(i,27,2)=-inco(i,2)+1.0/2.0
         outco(i,27,3)=inco(i,3)+1.0/4.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/2.0
         outco(i,28,2)=inco(i,2)+1.0/4.0
         outco(i,28,3)=inco(i,3)+3.0/4.0
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/2.0
         outco(i,30,2)=inco(i,1)+1.0/4.0
         outco(i,30,3)=inco(i,2)+3.0/4.0
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/4.0
         outco(i,31,2)=inco(i,1)+3.0/4.0
         outco(i,31,3)=-inco(i,2)+1.0/2.0
         !S=32
         outco(i,32,1)=inco(i,3)+3.0/4.0
         outco(i,32,2)=-inco(i,1)+1.0/2.0
         outco(i,32,3)=inco(i,2)+1.0/4.0
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)+3.0/4.0
         outco(i,34,2)=-inco(i,3)+1.0/2.0
         outco(i,34,3)=inco(i,1)+1.0/4.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/2.0
         outco(i,35,2)=inco(i,3)+1.0/4.0
         outco(i,35,3)=inco(i,1)+3.0/4.0
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/4.0
         outco(i,36,2)=inco(i,3)+3.0/4.0
         outco(i,36,3)=-inco(i,1)+1.0/2.0
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/4.0
         outco(i,37,2)=-inco(i,1)+3.0/4.0
         outco(i,37,3)=inco(i,3)+1.0/2.0
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)+3.0/4.0
         outco(i,39,2)=inco(i,1)+1.0/2.0
         outco(i,39,3)=-inco(i,3)+1.0/4.0
         !S=40
         outco(i,40,1)=inco(i,2)+1.0/2.0
         outco(i,40,2)=-inco(i,1)+1.0/4.0
         outco(i,40,3)=-inco(i,3)+3.0/4.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/4.0
         outco(i,41,2)=-inco(i,3)+3.0/4.0
         outco(i,41,3)=+inco(i,2)+1.0/2.0
         !S=42
         outco(i,42,1)=inco(i,1)+1.0/2.0
         outco(i,42,2)=-inco(i,3)+1.0/4.0
         outco(i,42,3)=-inco(i,2)+3.0/4.0
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)+3.0/4.0
         outco(i,44,2)=+inco(i,3)+1.0/2.0
         outco(i,44,3)=-inco(i,2)+1.0/4.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/4.0
         outco(i,45,2)=-inco(i,2)+3.0/4.0
         outco(i,45,3)=+inco(i,1)+1.0/2.0
         !S=46
         outco(i,46,1)=-inco(i,3)+3.0/4.0
         outco(i,46,2)=inco(i,2)+1.0/2.0
         outco(i,46,3)=-inco(i,1)+1.0/4.0
         !S=47
         outco(i,47,1)=inco(i,3)+1.0/2.0
         outco(i,47,2)=-inco(i,2)+1.0/4.0
         outco(i,47,3)=-inco(i,1)+3.0/4.0
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)
         END IF

      CASE (228) !Fd-3c
         IF (unique=='1') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)+1.0/2.0
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+1.0/2.0
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)+1.0/2.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)+1.0/2.0
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)+1.0/2.0
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)+1.0/2.0
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+1.0/2.0
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)+1.0/2.0
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)+1.0/2.0
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+3.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/4.0
         outco(i,14,2)=-inco(i,1)+1.0/4.0
         outco(i,14,3)=-inco(i,3)+1.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+3.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+3.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+3.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+3.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/4.0
         outco(i,19,2)=-inco(i,3)+1.0/4.0
         outco(i,19,3)=-inco(i,2)+1.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+3.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+3.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+3.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+3.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/4.0
         outco(i,24,2)=-inco(i,2)+1.0/4.0
         outco(i,24,3)=-inco(i,1)+1.0/4.0
         !S=25
         outco(i,25,1)=-inco(i,1)+3.0/4.0
         outco(i,25,2)=-inco(i,2)+3.0/4.0
         outco(i,25,3)=-inco(i,3)+3.0/4.0
         !S=26
         outco(i,26,1)=inco(i,1)+3.0/4.0
         outco(i,26,2)=inco(i,2)+1.0/4.0
         outco(i,26,3)=-inco(i,3)+1.0/4.0
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/4.0
         outco(i,27,2)=-inco(i,2)+1.0/4.0
         outco(i,27,3)=inco(i,3)+3.0/4.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/4.0
         outco(i,28,2)=inco(i,2)+3.0/4.0
         outco(i,28,3)=inco(i,3)+1.0/4.0
         !S=29
         outco(i,29,1)=-inco(i,3)+3.0/4.0
         outco(i,29,2)=-inco(i,1)+3.0/4.0
         outco(i,29,3)=-inco(i,2)+3.0/4.0
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/4.0
         outco(i,30,2)=inco(i,1)+3.0/4.0
         outco(i,30,3)=inco(i,2)+1.0/4.0
         !S=31
         outco(i,31,1)=inco(i,3)+3.0/4.0
         outco(i,31,2)=inco(i,1)+1.0/4.0
         outco(i,31,3)=-inco(i,2)+1.0/4.0
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/4.0
         outco(i,32,2)=-inco(i,1)+1.0/4.0
         outco(i,32,3)=inco(i,2)+3.0/4.0
         !S=33
         outco(i,33,1)=-inco(i,2)+3.0/4.0
         outco(i,33,2)=-inco(i,3)+3.0/4.0
         outco(i,33,3)=-inco(i,1)+3.0/4.0
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/4.0
         outco(i,34,2)=-inco(i,3)+1.0/4.0
         outco(i,34,3)=inco(i,1)+3.0/4.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/4.0
         outco(i,35,2)=inco(i,3)+3.0/4.0
         outco(i,35,3)=inco(i,1)+1.0/4.0
         !S=36
         outco(i,36,1)=inco(i,2)+3.0/4.0
         outco(i,36,2)=inco(i,3)+1.0/4.0
         outco(i,36,3)=-inco(i,1)+1.0/4.0
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)+1.0/2.0
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)+1.0/2.0
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)+1.0/2.0
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)+1.0/2.0
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)+1.0/2.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)+1.0/2.0
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)+1.0/2.0
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)+1.0/2.0
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)+1.0/2.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0
         END IF

         IF (unique=='2') THEN
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/4.0
         outco(i,2,2)=-inco(i,2)+3.0/4.0
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)+3.0/4.0
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/4.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/4.0
         outco(i,4,3)=-inco(i,3)+3.0/4.0
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/4.0
         outco(i,6,3)=-inco(i,2)+3.0/4.0
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/4.0
         outco(i,7,2)=-inco(i,1)+3.0/4.0
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)+3.0/4.0
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/4.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)+3.0/4.0
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/4.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/4.0
         outco(i,11,3)=-inco(i,1)+3.0/4.0
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/4.0
         outco(i,12,2)=-inco(i,3)+3.0/4.0
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)+1.0/2.0
         outco(i,14,2)=-inco(i,1)+1.0/2.0
         outco(i,14,3)=-inco(i,3)+1.0/2.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+1.0/2.0
         outco(i,19,2)=-inco(i,3)+1.0/2.0
         outco(i,19,3)=-inco(i,2)+1.0/2.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+1.0/2.0
         outco(i,24,2)=-inco(i,2)+1.0/2.0
         outco(i,24,3)=-inco(i,1)+1.0/2.0
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)+3.0/4.0
         outco(i,26,2)=inco(i,2)+1.0/4.0
         outco(i,26,3)=-inco(i,3)+1.0/2.0
         !S=27
         outco(i,27,1)=inco(i,1)+1.0/4.0
         outco(i,27,2)=-inco(i,2)+1.0/2.0
         outco(i,27,3)=inco(i,3)+3.0/4.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/2.0
         outco(i,28,2)=inco(i,2)+3.0/4.0
         outco(i,28,3)=inco(i,3)+1.0/4.0
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/2.0
         outco(i,30,2)=inco(i,1)+3.0/4.0
         outco(i,30,3)=inco(i,2)+1.0/4.0
         !S=31
         outco(i,31,1)=inco(i,3)+3.0/4.0
         outco(i,31,2)=inco(i,1)+1.0/4.0
         outco(i,31,3)=-inco(i,2)+1.0/2.0
         !S=32
         outco(i,32,1)=inco(i,3)+1.0/4.0
         outco(i,32,2)=-inco(i,1)+1.0/2.0
         outco(i,32,3)=inco(i,2)+3.0/4.0
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)+1.0/4.0
         outco(i,34,2)=-inco(i,3)+1.0/2.0
         outco(i,34,3)=inco(i,1)+3.0/4.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/2.0
         outco(i,35,2)=inco(i,3)+3.0/4.0
         outco(i,35,3)=inco(i,1)+1.0/4.0
         !S=36
         outco(i,36,1)=inco(i,2)+3.0/4.0
         outco(i,36,2)=inco(i,3)+1.0/4.0
         outco(i,36,3)=-inco(i,1)+1.0/2.0
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/4.0
         outco(i,37,2)=-inco(i,1)+3.0/4.0
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/2.0
         outco(i,38,2)=inco(i,1)+1.0/2.0
         outco(i,38,3)=inco(i,3)+1.0/2.0
         !S=39
         outco(i,39,1)=-inco(i,2)+3.0/4.0
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)+1.0/4.0
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)+1.0/4.0
         outco(i,40,3)=-inco(i,3)+3.0/4.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/4.0
         outco(i,41,2)=-inco(i,3)+3.0/4.0
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)+1.0/4.0
         outco(i,42,3)=-inco(i,2)+3.0/4.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/2.0
         outco(i,43,2)=inco(i,3)+1.0/2.0
         outco(i,43,3)=inco(i,2)+1.0/2.0
         !S=44
         outco(i,44,1)=-inco(i,1)+3.0/4.0
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)+1.0/4.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/4.0
         outco(i,45,2)=-inco(i,2)+3.0/4.0
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)+3.0/4.0
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)+1.0/4.0
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)+1.0/4.0
         outco(i,47,3)=-inco(i,1)+3.0/4.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/2.0
         outco(i,48,2)=inco(i,2)+1.0/2.0
         outco(i,48,3)=inco(i,1)+1.0/2.0
         END IF

      CASE (229)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)
         outco(i,3,3)=-inco(i,3)
         !S=4
         outco(i,4,1)=inco(i,1)
         outco(i,4,2)=-inco(i,2)
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)
         outco(i,6,2)=-inco(i,1)
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)
         outco(i,8,3)=-inco(i,2)
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)
         outco(i,10,3)=-inco(i,1)
         !S=11
         outco(i,11,1)=inco(i,2)
         outco(i,11,2)=-inco(i,3)
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)
         !S=13
         outco(i,13,1)=inco(i,2)
         outco(i,13,2)=inco(i,1)
         outco(i,13,3)=-inco(i,3)
         !S=14
         outco(i,14,1)=-inco(i,2)
         outco(i,14,2)=-inco(i,1)
         outco(i,14,3)=-inco(i,3)
         !S=15
         outco(i,15,1)=inco(i,2)
         outco(i,15,2)=-inco(i,1)
         outco(i,15,3)=inco(i,3)
         !S=16
         outco(i,16,1)=-inco(i,2)
         outco(i,16,2)=+inco(i,1)
         outco(i,16,3)=inco(i,3)
         !S=17
         outco(i,17,1)=+inco(i,1)
         outco(i,17,2)=+inco(i,3)
         outco(i,17,3)=-inco(i,2)
         !S=18
         outco(i,18,1)=-inco(i,1)
         outco(i,18,2)=+inco(i,3)
         outco(i,18,3)=inco(i,2)
         !S=19
         outco(i,19,1)=-inco(i,1)
         outco(i,19,2)=-inco(i,3)
         outco(i,19,3)=-inco(i,2)
         !S=20
         outco(i,20,1)=inco(i,1)
         outco(i,20,2)=-inco(i,3)
         outco(i,20,3)=inco(i,2)
         !S=21
         outco(i,21,1)=inco(i,3)
         outco(i,21,2)=inco(i,2)
         outco(i,21,3)=-inco(i,1)
         !S=22
         outco(i,22,1)=inco(i,3)
         outco(i,22,2)=-inco(i,2)
         outco(i,22,3)=inco(i,1)
         !S=23
         outco(i,23,1)=-inco(i,3)
         outco(i,23,2)=inco(i,2)
         outco(i,23,3)=inco(i,1)
         !S=24
         outco(i,24,1)=-inco(i,3)
         outco(i,24,2)=-inco(i,2)
         outco(i,24,3)=-inco(i,1)
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)
         outco(i,27,3)=inco(i,3)
         !S=28
         outco(i,28,1)=-inco(i,1)
         outco(i,28,2)=inco(i,2)
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)
         outco(i,30,2)=inco(i,1)
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)
         outco(i,32,3)=inco(i,2)
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)
         outco(i,34,3)=inco(i,1)
         !S=35
         outco(i,35,1)=-inco(i,2)
         outco(i,35,2)=inco(i,3)
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)
         !S=37
         outco(i,37,1)=-inco(i,2)
         outco(i,37,2)=-inco(i,1)
         outco(i,37,3)=inco(i,3)
         !S=38
         outco(i,38,1)=inco(i,2)
         outco(i,38,2)=inco(i,1)
         outco(i,38,3)=inco(i,3)
         !S=39
         outco(i,39,1)=-inco(i,2)
         outco(i,39,2)=inco(i,1)
         outco(i,39,3)=-inco(i,3)
         !S=40
         outco(i,40,1)=inco(i,2)
         outco(i,40,2)=-inco(i,1)
         outco(i,40,3)=-inco(i,3)
         !S=41
         outco(i,41,1)=-inco(i,1)
         outco(i,41,2)=-inco(i,3)
         outco(i,41,3)=+inco(i,2)
         !S=42
         outco(i,42,1)=inco(i,1)
         outco(i,42,2)=-inco(i,3)
         outco(i,42,3)=-inco(i,2)
         !S=43
         outco(i,43,1)=inco(i,1)
         outco(i,43,2)=inco(i,3)
         outco(i,43,3)=inco(i,2)
         !S=44
         outco(i,44,1)=-inco(i,1)
         outco(i,44,2)=+inco(i,3)
         outco(i,44,3)=-inco(i,2)
         !S=45
         outco(i,45,1)=-inco(i,3)
         outco(i,45,2)=-inco(i,2)
         outco(i,45,3)=+inco(i,1)
         !S=46
         outco(i,46,1)=-inco(i,3)
         outco(i,46,2)=inco(i,2)
         outco(i,46,3)=-inco(i,1)
         !S=47
         outco(i,47,1)=inco(i,3)
         outco(i,47,2)=-inco(i,2)
         outco(i,47,3)=-inco(i,1)
         !S=48
         outco(i,48,1)=inco(i,3)
         outco(i,48,2)=inco(i,2)
         outco(i,48,3)=inco(i,1)

      CASE (230)
         DO k=1,3
         outco(i,1,k)=inco(i,k)
         END DO
         !S=2
         outco(i,2,1)=-inco(i,1)+1.0/2.0
         outco(i,2,2)=-inco(i,2)
         outco(i,2,3)=inco(i,3)+1.0/2.0
         !S=3
         outco(i,3,1)=-inco(i,1)
         outco(i,3,2)=inco(i,2)+1.0/2.0
         outco(i,3,3)=-inco(i,3)+1.0/2.0
         !S=4
         outco(i,4,1)=inco(i,1)+1.0/2.0
         outco(i,4,2)=-inco(i,2)+1.0/2.0
         outco(i,4,3)=-inco(i,3)
         !S=5
         outco(i,5,1)=inco(i,3)
         outco(i,5,2)=inco(i,1)
         outco(i,5,3)=inco(i,2)
         !S=6
         outco(i,6,1)=inco(i,3)+1.0/2.0
         outco(i,6,2)=-inco(i,1)+1.0/2.0
         outco(i,6,3)=-inco(i,2)
         !S=7
         outco(i,7,1)=-inco(i,3)+1.0/2.0
         outco(i,7,2)=-inco(i,1)
         outco(i,7,3)=inco(i,2)+1.0/2.0
         !S=8
         outco(i,8,1)=-inco(i,3)
         outco(i,8,2)=inco(i,1)+1.0/2.0
         outco(i,8,3)=-inco(i,2)+1.0/2.0
         !S=9
         outco(i,9,1)=inco(i,2)
         outco(i,9,2)=inco(i,3)
         outco(i,9,3)=inco(i,1)
         !S=10
         outco(i,10,1)=-inco(i,2)
         outco(i,10,2)=inco(i,3)+1.0/2.0
         outco(i,10,3)=-inco(i,1)+1.0/2.0
         !S=11
         outco(i,11,1)=inco(i,2)+1.0/2.0
         outco(i,11,2)=-inco(i,3)+1.0/2.0
         outco(i,11,3)=-inco(i,1)
         !S=12
         outco(i,12,1)=-inco(i,2)+1.0/2.0
         outco(i,12,2)=-inco(i,3)
         outco(i,12,3)=inco(i,1)+1.0/2.0
         !S=13
         outco(i,13,1)=inco(i,2)+3.0/4.0
         outco(i,13,2)=inco(i,1)+1.0/4.0
         outco(i,13,3)=-inco(i,3)+1.0/4.0
         !S=14
         outco(i,14,1)=-inco(i,2)+3.0/4.0
         outco(i,14,2)=-inco(i,1)+3.0/4.0
         outco(i,14,3)=-inco(i,3)+3.0/4.0
         !S=15
         outco(i,15,1)=inco(i,2)+1.0/4.0
         outco(i,15,2)=-inco(i,1)+1.0/4.0
         outco(i,15,3)=inco(i,3)+3.0/4.0
         !S=16
         outco(i,16,1)=-inco(i,2)+1.0/4.0
         outco(i,16,2)=+inco(i,1)+3.0/4.0
         outco(i,16,3)=inco(i,3)+1.0/4.0
         !S=17
         outco(i,17,1)=+inco(i,1)+3.0/4.0
         outco(i,17,2)=+inco(i,3)+1.0/4.0
         outco(i,17,3)=-inco(i,2)+1.0/4.0
         !S=18
         outco(i,18,1)=-inco(i,1)+1.0/4.0
         outco(i,18,2)=+inco(i,3)+3.0/4.0
         outco(i,18,3)=inco(i,2)+1.0/4.0
         !S=19
         outco(i,19,1)=-inco(i,1)+3.0/4.0
         outco(i,19,2)=-inco(i,3)+3.0/4.0
         outco(i,19,3)=-inco(i,2)+3.0/4.0
         !S=20
         outco(i,20,1)=inco(i,1)+1.0/4.0
         outco(i,20,2)=-inco(i,3)+1.0/4.0
         outco(i,20,3)=inco(i,2)+3.0/4.0
         !S=21
         outco(i,21,1)=inco(i,3)+3.0/4.0
         outco(i,21,2)=inco(i,2)+1.0/4.0
         outco(i,21,3)=-inco(i,1)+1.0/4.0
         !S=22
         outco(i,22,1)=inco(i,3)+1.0/4.0
         outco(i,22,2)=-inco(i,2)+1.0/4.0
         outco(i,22,3)=inco(i,1)+3.0/4.0
         !S=23
         outco(i,23,1)=-inco(i,3)+1.0/4.0
         outco(i,23,2)=inco(i,2)+3.0/4.0
         outco(i,23,3)=inco(i,1)+1.0/4.0
         !S=24
         outco(i,24,1)=-inco(i,3)+3.0/4.0
         outco(i,24,2)=-inco(i,2)+3.0/4.0
         outco(i,24,3)=-inco(i,1)+3.0/4.0
         !S=25
         outco(i,25,1)=-inco(i,1)
         outco(i,25,2)=-inco(i,2)
         outco(i,25,3)=-inco(i,3)
         !S=26
         outco(i,26,1)=inco(i,1)+1.0/2.0
         outco(i,26,2)=inco(i,2)
         outco(i,26,3)=-inco(i,3)+1.0/2.0
         !S=27
         outco(i,27,1)=inco(i,1)
         outco(i,27,2)=-inco(i,2)+1.0/2.0
         outco(i,27,3)=inco(i,3)+1.0/2.0
         !S=28
         outco(i,28,1)=-inco(i,1)+1.0/2.0
         outco(i,28,2)=inco(i,2)+1.0/2.0
         outco(i,28,3)=inco(i,3)
         !S=29
         outco(i,29,1)=-inco(i,3)
         outco(i,29,2)=-inco(i,1)
         outco(i,29,3)=-inco(i,2)
         !S=30
         outco(i,30,1)=-inco(i,3)+1.0/2.0
         outco(i,30,2)=inco(i,1)+1.0/2.0
         outco(i,30,3)=inco(i,2)
         !S=31
         outco(i,31,1)=inco(i,3)+1.0/2.0
         outco(i,31,2)=inco(i,1)
         outco(i,31,3)=-inco(i,2)+1.0/2.0
         !S=32
         outco(i,32,1)=inco(i,3)
         outco(i,32,2)=-inco(i,1)+1.0/2.0
         outco(i,32,3)=inco(i,2)+1.0/2.0
         !S=33
         outco(i,33,1)=-inco(i,2)
         outco(i,33,2)=-inco(i,3)
         outco(i,33,3)=-inco(i,1)
         !S=34
         outco(i,34,1)=inco(i,2)
         outco(i,34,2)=-inco(i,3)+1.0/2.0
         outco(i,34,3)=inco(i,1)+1.0/2.0
         !S=35
         outco(i,35,1)=-inco(i,2)+1.0/2.0
         outco(i,35,2)=inco(i,3)+1.0/2.0
         outco(i,35,3)=inco(i,1)
         !S=36
         outco(i,36,1)=inco(i,2)+1.0/2.0
         outco(i,36,2)=inco(i,3)
         outco(i,36,3)=-inco(i,1)+1.0/2.0
         !S=37
         outco(i,37,1)=-inco(i,2)+1.0/4.0
         outco(i,37,2)=-inco(i,1)+3.0/4.0
         outco(i,37,3)=inco(i,3)+3.0/4.0
         !S=38
         outco(i,38,1)=inco(i,2)+1.0/4.0
         outco(i,38,2)=inco(i,1)+1.0/4.0
         outco(i,38,3)=inco(i,3)+1.0/4.0
         !S=39
         outco(i,39,1)=-inco(i,2)+3.0/4.0
         outco(i,39,2)=inco(i,1)+3.0/4.0
         outco(i,39,3)=-inco(i,3)+1.0/4.0
         !S=40
         outco(i,40,1)=inco(i,2)+3.0/4.0
         outco(i,40,2)=-inco(i,1)+1.0/4.0
         outco(i,40,3)=-inco(i,3)+3.0/4.0
         !S=41
         outco(i,41,1)=-inco(i,1)+1.0/4.0
         outco(i,41,2)=-inco(i,3)+3.0/4.0
         outco(i,41,3)=+inco(i,2)+3.0/4.0
         !S=42
         outco(i,42,1)=inco(i,1)+3.0/4.0
         outco(i,42,2)=-inco(i,3)+1.0/4.0
         outco(i,42,3)=-inco(i,2)+3.0/4.0
         !S=43
         outco(i,43,1)=inco(i,1)+1.0/4.0
         outco(i,43,2)=inco(i,3)+1.0/4.0
         outco(i,43,3)=inco(i,2)+1.0/4.0
         !S=44
         outco(i,44,1)=-inco(i,1)+3.0/4.0
         outco(i,44,2)=+inco(i,3)+3.0/4.0
         outco(i,44,3)=-inco(i,2)+1.0/4.0
         !S=45
         outco(i,45,1)=-inco(i,3)+1.0/4.0
         outco(i,45,2)=-inco(i,2)+3.0/4.0
         outco(i,45,3)=+inco(i,1)+3.0/4.0
         !S=46
         outco(i,46,1)=-inco(i,3)+3.0/4.0
         outco(i,46,2)=inco(i,2)+3.0/4.0
         outco(i,46,3)=-inco(i,1)+1.0/4.0
         !S=47
         outco(i,47,1)=inco(i,3)+3.0/4.0
         outco(i,47,2)=-inco(i,2)+1.0/4.0
         outco(i,47,3)=-inco(i,1)+3.0/4.0
         !S=48
         outco(i,48,1)=inco(i,3)+1.0/4.0
         outco(i,48,2)=inco(i,2)+1.0/4.0
         outco(i,48,3)=inco(i,1)+1.0/4.0
      END SELECT simmetria   
      RETURN
   END SUBROUTINE find_equivalent_tau
END MODULE
