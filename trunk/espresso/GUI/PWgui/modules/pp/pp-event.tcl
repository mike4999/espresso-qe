tracevar plot_num w {

    ::tclu::DEBUG "Plot_Num ..."

    switch -exact -- [vartextvalue plot_num] {
	"charge density" -
	"total potential (= V_bare + V_H + V_xc)" -
	"the V_bare + V_H potential" {
	    widget spin_component enable
	    widgetconfigure spin_component -textvalues {
		"total charge/potential"
		"spin up charge/potential"
		"spin down charge/potential"		
	    }
	    groupwidget stm   disable 
	    groupwidget psi2  disable 
	    groupwidget ildos disable
	}

	"STM images" {
	    widget spin_component disable
	    groupwidget stm   enable  
	    groupwidget psi2  disable 
	    groupwidget ildos disable
	}

	"|psi|^2" {
	    widget spin_component disable 
	    groupwidget stm   disable 
	    groupwidget psi2  enable  
	    groupwidget ildos disable
	}
	
	"integrated local density of states (ILDOS)" {
	    widget spin_component disable 
	    groupwidget stm   disable 
	    groupwidget psi2  disable  
	    groupwidget ildos enable
	}
	"the noncolinear magnetization" {
	    widget spin_component enable
	    widgetconfigure spin_component -textvalues {
		"absolute value"
		"x component of the magnetization"
		"y component of the magnetization"
		"z component of the magnetization"
	    }	
	}
	default {
	    widget spin_component disable 
	    groupwidget stm   disable 
	    groupwidget ildos disable
	    groupwidget psi2  disable 
	}	    
    }
}

postprocess {
    varset plot_num -textvalue ""
}