# ----------------------------------------------------------------------
#  PROGRAM: PWgui
#  PURPOSE: tries to be a GUI for the PWscf
# ----------------------------------------------------------------------
#  Anton Kokalj
#  Jozef Stefan Institute, Ljubljana, Slovenia
#  INFM DEMOCRITOS National Simulation Center, Trieste, Italy
#  Email: Tone.Kokalj@ijs.si
# ======================================================================
#  Copyright (c) 2003--2004 Anton Kokalj
# ======================================================================
#
#
# This file is distributed under the terms of the GNU General Public
# License. See the file `COPYING' in the root directory of the present
# distribution, or http://www.gnu.org/copyleft/gpl.txt .
#
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT.  IN NO EVENT SHALL ANTON KOKALJ BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

if { [info exists env(PWGUI)] } {
    puts " PWgui GUI: $env(PWGUI)"
    set guib_dir [glob -nocomplain -directory [file join $env(PWGUI) lib] Guib-*]
    if { $guib_dir != "" } {
	set env(GUIB) $guib_dir
    }
    if { [info exists env(GUIB)] } {
	lappend auto_path $env(GUIB)
        puts " GUIB engine: $env(GUIB)\n"
    }
} else {
    puts stderr "   "
    puts stderr "   Please define the PWGUI enviromental variable !!!"
    puts stderr "   PWGUI should point to the package root directory."
    puts stderr "   "
    exit
}

package require Guib 0.2.0
wm withdraw .
bind . <Destroy> ::guib::exitApp

namespace eval ::pwscf {
    variable pwscf
    variable settings

    set pwscf(PWD) [pwd]
}

# define here all pwscf's namespaces ...
namespace eval ::pwscf::edit      {}
namespace eval ::pwscf::menustate {}
namespace eval ::pwscf::view      {}

# load settings file ...
source $env(PWGUI)/pwgui.settings
if { [file exists $env(HOME)/.pwgui/pwgui.settings] } {
    # overwritte default settings by user-settings
    source $env(HOME)/.pwgui/pwgui.settings
}

lappend auto_path [file join $env(PWGUI) src]
source [file join $env(PWGUI) src pwscf.itcl]
