
help nfile -vartype integer -helpfmt txt2html -helptext {
            the number of data files (OPTIONAL)
<p> ( default = 1 )
}

help filepp -vartype character -helpfmt txt2html -helptext {
            file containing the 3D charge (produced by pp.x)
            (AT LEAST filepp(1) REQUIRED)
}
help weight -vartype real -helpfmt txt2html -helptext {
            The quantity to be plotted will be:
            weight(1)*rho(1) + weight(2)*rho(2) + weight(3)*rho(3)+...
            (OPTIONAL)

            BEWARE: atomic coordinates are read from the first file;
            if their number is different for different files,
            the first file must have the largest number of atoms
<p> (  default : weight(1) = 1.0)
}


help iflag -vartype integer -helpfmt txt2html -helptext {
          1 if a 1D plot is required (DEFAULT)
          2 if a 2D plot is required
          3 if a 3D plot is required
          4 if a 2D polar plot on a sphere is required
<p> ( default = 1 )
}

help plot_out -vartype integer -helpfmt txt2html -helptext {
          0   plot the spherical average of the charge density
          1   plot the charge density (DEFAULT)
          2   plot the induced polarization along x
          3   plot the induced polarization along y
          4   plot the induced polarization along z
<p> ( default = 1 )
}

help output_format -vartype integer -helpfmt txt2html -helptext {
         (ignored on 1D plot)

          0  format suitable for gnuplot   (1D) (DEFAULT)
          1  format suitable for contour.x (2D)
          2  format suitable for plotrho   (2D)
          3  format suitable for XCRYSDEN  (1D, 2D, 3D)
          4  format suitable for gOpenMol  (3D)
             (formatted: convert to unformatted *.plt)
          5  format suitable for XCRYSDEN  (3D)
<p> ( default = 0 )
}

set _volume {
  IF iflag = 1
                    REQUIRED:
                e1  3D vector which determines the plotting line
                x0  3D vector, origin of the line
                nx  number of points in the line:
                    rho(i) = rho( x0 + e1 * (i-1)/(nx-1) ), i=1, nx
  
  ELSEIF iflag = 2
                    REQUIRED:
            e1, e2  3D vectors which determine the plotting plane
                    (must be orthogonal)
                x0  3D vector, origin of the plane
            nx, ny  number of points in the plane:
                    rho(i,j) = rho( x0 + e1 * (i-1)/(nx-1)
                                       + e2 * (j-1)/(ny-1) ), i=1,nx ; j=1,ny
  
  ELSEIF iflag = 3
                    OPTIONAL:
        e1, e2, e3  3D vectors which determine the plotting parallelepiped
                    (if present, must be orthogonal)
                x0  3D vector, origin of the parallelepiped
          nx,ny,nz  number of points in the parallelepiped:
                    rho(i,j,k) = rho( x0 + e1 * (i-1)/(nx-1)
                                         + e2 * (j-1)/(ny-1)
                                         + e3 * (k-1)/(nz-1) ),
                                 i = 1, nx ; j = 1, ny ; k = 1, nz
  
                  - If output_format = 3 (XCRYSDEN), the above variables
                    are used to determine the grid to plot. 
                  - If output_format = 5 (XCRYSDEN), the above variables
                    are ignored, the entire FFT grid is written in the
                    XCRYSDEN format - works for any crystal axis (VERY FAST)
                  - If e1, e2, e3, x0 are present, e1 e2 e3 are parallel
                    to xyz and parallel to crystal axis, a subset of the
                    FFT grid that approximately covers the parallelepiped
                    defined by e1, e2, e3, x0, is written (presently only
                    in gopenmol "formatted" file format) - works only
                    if the crystal axis are parallel to xyz
                  - Otherwise, the required 3D grid is generated from the
                    Fourier components (may be VERY slow)
}

set _e {
     3D vectors which determine the plotting line (e1), plane (e1,e2), or 
     parallelepiped (e1, e2, e3)
}
foreach e {e1 e2 e3} {
    help $e -vartype real -helpfmt txt2html -helptext "$_e\n\n$_volume"
}

set _x {
    3D vector, origin of either line (1D plot), plane (2D plot), 
    or parallelepiped (3D plot)
}
help x0 -vartype real -helpfmt txt2html -helptext "$_x\n\n$_volume"

set _n {
    number of points for line (nx), plane (nx,ny), or parallelepiped (nx,ny,nz)
}
foreach n {nx ny nz} {
    help $n -vartype real -helpfmt txt2html -helptext "$_n\n\n$_volume"
}

help radius -vartype real -helpfmt txt2html -helptext {
    radius    Radius of the sphere (alat units), centered at (0,0,0)
    nx, ny    number of points in the polar plane:
                      phi(i)  = 2 pi * (i - 1)/(nx-1), i=1, nx
                      theta(j)=   pi * (j - 1)/(ny-1), j=1, ny
}

help fileout -vartype character -helpfmt txt2html -helptext {  
    name of the file to which the plot is written
<p> ( default = standard output )
}

help epsilon -vartype real -helpfmt txt2html -helptext {
    the dielectric constant for polarization computation
}

  
help filepol -vartype character helpfmt txt2html -helptext {
    name of an output file to which the induced polarization
    is written (in postproc format) for further processing
    (macroscopic average)
}
  
  
help idpol -vartype integer -helpfmt txt2html -helptext {
    = 1 the ionic and electronic dipole moment of the charge
        is computed. 
      
    = 2 only the electronic dipole moment is computed
  
  NB: This option is to be used for an isolated molecule in 
      a box and the molecule must be at the center of the box.
      The code computes the dipole on the Wigner-Seitz cell of
      the Bravais lattice. The 3d box must contain this cell 
      otherwise meaningless numbers are printed.
}


help makov -vartype logical -helpfmt txt2html -helptext {
      Makov-Payne correction for charged supercells (OPTIONAL)

      makov     .true. the 1st and 2d order corrections are
                computed (default: .false.)

                WARNING: - not thoroughly tested
                         - the correction works only for clusters
                         embedded within a cubic supercell
                         - the cluster MUST be CENTRED within the
                         cell, otherwise meaningless results are
                         printed
                         - always check that the printed total charge
                         is the right one
                         - for impurities in bulk crystals the
                         correction should work as well, but the
                         Madelung constant of the considered lattice
                         must be used and the correction has to be
                         divided by the crystal dielectric constant.
                Ref.: G. Makov and M.C. Payne, PRB 51, 4014 (1995).
                Contributed by Giovanni Cantele
}