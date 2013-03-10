/*
  Copyright (C) 2003-2007 Quantum ESPRESSO group
  This file is distributed under the terms of the
  GNU General Public License. See the file `License'
  in the root directory of the present distribution,
  or http://www.gnu.org/copyleft/gpl.txt .
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <time.h>
#include "c_defs.h"
#include <unistd.h>
int check_writable_dir(const char *filename) {
    struct stat sb;
    /* lstat follows symlinks */
    if (lstat(filename, &sb) == -1) {
      fprintf( stderr , "chk dir fail: directory '%s' not created\n", filename ) ;
      return -3; /* does not exist */
      /* note: this happens also if looking for "dir/" when there is a file called "dir" */
    }
    if ( (sb.st_mode & S_IFMT) != S_IFDIR) {
      fprintf( stderr , "chk dir fail: file '%s' exists but is NOT a directory\n", filename ) ;
      return -2; /* not a directory */
    }
    /* if ( ! (sb.st_mode & S_IWUSR) )        return -4; /* not writeble by owner */
    /* return 0 if I can read, write and execute (enter) this directory, -1 otherwise
       note: we do not actually need R_OK in Quantum-ESPRESSO;
             W_OK is definitely needed, about X_OK I'm not sure */
    if ( access(filename, W_OK|R_OK|X_OK ) ) {
      fprintf( stderr , "chk dir fail: insufficient permissions to access '%s'\n", filename ) ;
      return -1; /* no permissions  */
    }
    
    return 0;
}  /* check_writable_dir */

static void fatal ( const char * msg )
{

   fprintf( stderr , "fatal: %s" , *msg ? msg : "Oops!" ) ;
   exit( -1 ) ;

} /* fatal */


static void * xcmalloc ( size_t size )
{

  register void * ptr = malloc( size ) ;

  if ( ptr == NULL )
    fatal( "c_mkdir: virtual memory exhausted" ) ;
  else
    memset( ptr , 0 , size ) ;

  return ptr ;

} /* xcmalloc */


int F77_FUNC_(c_mkdir_int,C_MKDIR_INT)( const int * dirname , const int * length )
{

   int i, retval = -1 ;

   mode_t mode = 0777 ;

   char * ldir = ( char * ) xcmalloc( (*length) + 1 ) ;

   for( i = 0; i < * length; i++ ) ldir[ i ] = (char)dirname[ i ];

   ldir[*length] = '\0' ;	/* memset() in xcmalloc() already do this */

   retval = mkdir( ldir , mode ) ;

   if ( retval == -1 && errno != EEXIST ) {
     fprintf( stderr , "mkdir fail: [%d] %s\n" , errno , strerror( errno ) ) ;
     retval = 1 ;
     }
   free( ldir ) ;
   /* double check that the directory is a directory and has the good permissions */
   if ( check_writable_dir(ldir) < 0) retval = 1;  
   return retval ;

} /* end of c_mkdir */

int c_mkdir_safe( const char * dirname )
{
   int i, retval = -1 ;

   mode_t mode = 0777 ;
   retval = mkdir( dirname , mode ) ;

   if ( retval == -1  && errno != EEXIST ) {
     fprintf( stderr , "mkdir fail: [%d] %s\n" , errno , strerror( errno ) ) ;
     retval = 1 ;
     }
   /* double check that the directory is a directory and has the good permissions */
   if ( check_writable_dir(dirname) < 0) retval = 1;  
   return retval ;
}

int F77_FUNC_(c_chdir_int,C_CHDIR_INT)( const int * dirname , const int * length )
{

   int i, retval = -1 ;

   char * ldir = ( char * ) xcmalloc( (*length) + 1 ) ;

   for( i = 0; i < * length; i++ ) ldir[ i ] = (char)dirname[ i ];

   ldir[*length] = '\0' ;       /* memset() in xcmalloc() already do this */

   retval = chdir( ldir ) ;

   if ( retval == -1  && errno != EEXIST ) {
     fprintf( stderr , "chdir fail: [%d] %s\n" , errno , strerror( errno ) ) ;
     }
   else {
     retval = 0 ;
     }


   free( ldir ) ;

   return retval ;

} /* end of c_chdir */

/* c_rename: call from fortran as
   ios = c_remame ( integer old-file-name(:), integer old-file-name, &
                    integer new-file-name(:), integer new-file-name )
   renames file old-file-name into new-file-name (don't try this on open files!)
   ios should return 0 if everything is ok, -1 otherwise.
   Written by PG by imitating "c_mkdir" without really understanding it */

int F77_FUNC_(c_rename_int,C_RENAME_INT)( const int * oldname, const int * oldlength ,
                                  const int * newname, const int * newlength )
{

   int i, retval = -1 ;

   char * oldname_ = ( char * ) xcmalloc( (*oldlength) + 1 ) ;
   char * newname_ = ( char * ) xcmalloc( (*newlength) + 1 ) ;

   for( i = 0; i < * oldlength; i++ ) oldname_[ i ] = (char)oldname[ i ];
   for( i = 0; i < * newlength; i++ ) newname_[ i ] = (char)newname[ i ];

   oldname_[*oldlength] = '\0' ;
   newname_[*newlength] = '\0' ;

   retval = rename( oldname_, newname_ ) ;

   if ( retval == -1 )
     fprintf( stderr , "mv fail: [%d] %s\n" , errno , strerror( errno ) ) ;

   free( oldname_ ) ;
   free( newname_ ) ;

   return retval ;

} /* c_rename */

int F77_FUNC_(c_link_int,C_LINK_INT)( const int * oldname, const int * oldlength ,
                                  const int * newname, const int * newlength )
{

   int i, retval = -1 ;

   char * oldname_ = ( char * ) xcmalloc( (*oldlength) + 1 ) ;
   char * newname_ = ( char * ) xcmalloc( (*newlength) + 1 ) ;

   for( i = 0; i < * oldlength; i++ ) oldname_[ i ] = (char)oldname[ i ];
   for( i = 0; i < * newlength; i++ ) newname_[ i ] = (char)newname[ i ];

   oldname_[*oldlength] = '\0' ;
   newname_[*newlength] = '\0' ;

   retval = symlink( oldname_, newname_ ) ;

   if ( retval == -1 )
     fprintf( stderr , "ln fail: [%d] %s\n" , errno , strerror( errno ) ) ;

   free( oldname_ ) ;
   free( newname_ ) ;

   return retval ;

} /* c_link */

/* EOF */
