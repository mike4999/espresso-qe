# 1 "iotk_base.spp"
! Input/Output Tool Kit (IOTK)
! Copyright (C) 2004,2005 Giovanni Bussi
!
! This library is free software; you can redistribute it and/or
! modify it under the terms of the GNU Lesser General Public
! License as published by the Free Software Foundation; either
! version 2.1 of the License, or (at your option) any later version.
!
! This library is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
! Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public
! License along with this library; if not, write to the Free Software
! Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 2 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_AUXMACROS
#define __IOTK_AUXMACROS

! The macros are defined with -D option or inside iotk_config.h
! The default values are set here
! Maximum rank of an array
#ifndef __IOTK_MAXRANK
#  define __IOTK_MAXRANK 7
#endif
! Minimum value used in iotk_free_unit
#ifndef __IOTK_UNITMIN
#  define __IOTK_UNITMIN 90000
#endif
! Maximum value used in iotk_free_unit
#ifndef __IOTK_UNITMAX
#  define __IOTK_UNITMAX 99999
#endif
! Unit for errors
#ifndef __IOTK_ERROR_UNIT
#  define __IOTK_ERROR_UNIT 0
#endif
! Kind for header in binary files
#ifndef __IOTK_HEADER_KIND
#  define __IOTK_HEADER_KIND selected_int_kind(8)
#endif
! Character (or eventually string) for newline
! It may be adjusted for particular systems
! Unix    achar(10)
! Mac-OS  achar(13)
! Windows ? (now it should be a single byte)
#ifndef __IOTK_NEWLINE
#  define __IOTK_NEWLINE achar(10)
#endif
! Character for EOS
#ifndef __IOTK_EOS
#  define __IOTK_EOS achar(0)
#endif
! These are the default kinds, which depend on the options used
! during the library compilation
! Only default characters are implemented
#define __IOTK_CHARACTER1 iotk_defkind_character
! For logical, integer and real types, the c precompiler
! looks for defined kinds. If no kind is found, the default
! is used as __IOTK_type1
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_LOGICAL1
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_LOGICAL2
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_LOGICAL3
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_LOGICAL4
# 52 "../include/iotk_auxmacros.spp"
#define __IOTK_LOGICAL1 iotk_defkind_LOGICAL
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_INTEGER1
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_INTEGER2
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_INTEGER3
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_INTEGER4
# 52 "../include/iotk_auxmacros.spp"
#define __IOTK_INTEGER1 iotk_defkind_INTEGER
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_REAL1
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_REAL2
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_REAL3
# 50 "../include/iotk_auxmacros.spp"
#ifndef __IOTK_REAL4
# 52 "../include/iotk_auxmacros.spp"
#define __IOTK_REAL1 iotk_defkind_REAL
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 55 "../include/iotk_auxmacros.spp"
#endif
# 58 "../include/iotk_auxmacros.spp"

! Some useful check follow
#if __IOTK_MAXRANK > 7
#  error
#endif
#if __IOTK_MAXRANK < 1
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL5
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL6
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL7
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL8
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL9
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_LOGICAL10
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER5
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER6
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER7
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER8
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER9
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_INTEGER10
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL5
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL6
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL7
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL8
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL9
#  error
#endif
# 68 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL10
#  error
#endif
# 73 "../include/iotk_auxmacros.spp"
#endif

! Complex are treated indentically to reals
! These lines map the definitions.
# 78 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL1
#  define __IOTK_COMPLEX1 __IOTK_REAL1
#else
#  undef __IOTK_COMPLEX1
#endif
# 78 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL2
#  define __IOTK_COMPLEX2 __IOTK_REAL2
#else
#  undef __IOTK_COMPLEX2
#endif
# 78 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL3
#  define __IOTK_COMPLEX3 __IOTK_REAL3
#else
#  undef __IOTK_COMPLEX3
#endif
# 78 "../include/iotk_auxmacros.spp"
#ifdef __IOTK_REAL4
#  define __IOTK_COMPLEX4 __IOTK_REAL4
#else
#  undef __IOTK_COMPLEX4
#endif
# 84 "../include/iotk_auxmacros.spp"


# 30 "iotk_base.spp"

module iotk_base
implicit none
save

! In this module, all names are public
! For this reason, it should not be used directly by the end user.

! This line set the version string
character(9),      parameter :: iotk_version            = "1.0.0test"
integer,                            parameter :: iotk_version_major      = 1
integer,                            parameter :: iotk_version_minor      = 0
integer,                            parameter :: iotk_version_patch      = 0
character(3), parameter :: iotk_file_version       = "1.0"
integer,                            parameter :: iotk_file_version_major = 1
integer,                            parameter :: iotk_file_version_minor = 0

character, parameter :: iotk_newline = __IOTK_NEWLINE
character, parameter :: iotk_eos     = __IOTK_EOS

! Max number of controls
integer, parameter :: iotk_ncontrol = 255 ! (2**8-1)

! Max length for strings
integer, parameter :: iotk_taglenx =  65535 ! (2**16-1)
integer, parameter :: iotk_namlenx =  256
integer, parameter :: iotk_attlenx =  iotk_taglenx - iotk_namlenx - 1 ! for space
integer, parameter :: iotk_vallenx =  32768
integer, parameter :: iotk_linlenx =  4096
integer, parameter :: iotk_fillenx =  1024
integer, parameter :: iotk_linlen  =  128
integer, parameter :: iotk_indent  =    2
integer, parameter :: iotk_maxindent = 12

! These options can be modified runtime
! Margins for unit search
integer :: iotk_unitmin = __IOTK_UNITMIN
integer :: iotk_unitmax = __IOTK_UNITMAX
integer :: iotk_error_unit = __IOTK_ERROR_UNIT
! Size of the buffer for iotk_getline
integer :: iotk_getline_buffer = 1024
! If true, exhausting the error pool causes an overflow warning
logical :: iotk_error_warn_overflow = .false.

! Kind for the header integer (number of digits in (iotk_ncontrol+1)*(iotk_taglenx+1))
integer, parameter :: iotk_header_kind = __IOTK_HEADER_KIND

! Map of controls into XML tags
! control = 1 <       >
! control = 2 </      >
! control = 3 <      />
! control = 4 <!--  -->
! control = 5 <?     ?>
! control = 128 is a special tag for binary files (continuation tag)

! Alphabet
character(26), parameter :: lowalphabet = "abcdefghijklmnopqrstuvwxyz"
character(26), parameter :: upalphabet  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
character(52), parameter :: alphabet    = lowalphabet//upalphabet
character(53), parameter :: alphabet_   = alphabet//"_"
character(10), parameter :: numbers     = "0123456789"

! Rules for names
character(54), parameter :: iotk_namcharfirst = alphabet//"_:"
character(66), parameter :: iotk_namchar      = iotk_namcharfirst//numbers//".-"

! Default kinds, depending on compilers and compilation options for the library source
integer, parameter :: iotk_defkind_character = kind("a")
integer, parameter :: iotk_defkind_logical   = kind(.true.)
integer, parameter :: iotk_defkind_integer   = kind(1)
integer, parameter :: iotk_defkind_real      = kind(1.0)
integer, parameter :: iotk_defkind_complex   = kind(1.0)

! Maximum allowed rank
integer, parameter :: iotk_maxrank      = __IOTK_MAXRANK ! Controlled by cpp
integer, parameter :: iotk_maxrank_hard = 7       ! Controlled by sprep preprocessing

! Internal type dealing with io units
type iotk_unit
  integer                     :: unit  ! fortran unit
  character(iotk_namlenx)     :: root  ! name of the root tag
  logical                     :: skip_root ! if true, root tag is not written automatically
  logical                     :: raw   ! if true, the file is raw data
  integer                     :: level ! the hierarchical level inside the file
  logical                     :: close_at_end ! if true, the file has to be fortran-closed when iotk_close_* is called
  type (iotk_unit),   pointer :: son    ! a pointer to the son in the multi-file model
  type (iotk_unit),   pointer :: parent ! a pointer to the parent in the multi-file model
  type (iotk_unit),   pointer :: next   ! a pointer to the next unit in the linked list
end type iotk_unit

! Special type used to force optional argument labelling.
type iotk_dummytype
  integer :: dummy
end type iotk_dummytype

! Linked list of iotk_unit objects
logical                   :: iotk_units_init = .false.
type (iotk_unit), pointer :: iotk_units

type iotk_error
  character, pointer :: str(:)
end type iotk_error

integer, parameter :: iotk_error_linelength  = 120
integer, parameter :: iotk_error_pool_size   = 100

type(iotk_error) :: iotk_error_pool       (iotk_error_pool_size)
logical          :: iotk_error_pool_used  (iotk_error_pool_size) = .false.
integer          :: iotk_error_pool_order (iotk_error_pool_size) = 0

end module iotk_base
