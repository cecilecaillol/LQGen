#-*- Makefile -*-
## Choose compiler: gfortran,g77,ifort
COMPILER=gfortran
## Choose PDF: native,lhapdf
## LHAPDF package has to be installed separately
PDF = lhapdf
#Choose Analysis: none, default
## default analysis may require FASTJET package, that has to be installed separately (see below)
#ANALYSIS=default
ANALYSIS=2to2
## For static linking uncomment the following
#STATIC= -static
#

ifeq ("$(COMPILER)","gfortran")	
F77= gfortran -fno-automatic 	-ffixed-line-length-none
## -fbounds-check sometimes causes a weird error due to non-lazy evaluation
## of boolean in gfortran.
#FFLAGS= -Wall -Wimplicit-interface -fbounds-check
## For floating point exception trapping  uncomment the following 
#FPE=-ffpe-trap=invalid,zero,overflow,underflow 
## gfortran 4.4.1 optimized with -O3 yields erroneous results
## Use -O2 to be on the safe side
OPT=-O2
## For debugging uncomment the following
endif

ifdef DEBUG
OPT=-O0
endif


ifeq ("$(COMPILER)","g77")
F77= g77 -fno-automatic 
#FFLAGS= -Wall -ffortran-bounds-check
## For floating point exception trapping  uncomment the following 
#FPEOBJ=trapfpe.o
OPT=-O3
## For debugging uncomment the following
#DEBUG= -ggdb -pg
endif


ifeq ("$(COMPILER)","ifort")
F77 = ifort -save  -extend_source
CXX = icpc
LIBS = -limf
#FFLAGS =  -check
## For floating point exception trapping  uncomment the following 
#FPE = -fpe0
OPT = -O3 #-fast
## For debugging uncomment the following
#DEBUG= -debug -g
endif



PWD=$(shell pwd)
WDNAME=$(shell basename $(PWD))
#POWHEGBOXV2=/home/nason/Pheno/POWHEG-BOX-V2/
#POWHEGBOXV2=/disk/data11/ttp/lbuono/codes/POWHEG-BOX-V2
POWHEGBOXV2=$(PWD)/POWHEG-BOX-V2
VPATH= ./:$(POWHEGBOXV2):obj/

INCLUDE0=$(PWD)
INCLUDE2=$(POWHEGBOXV2)/include
FF=$(F77) $(FFLAGS) $(FPE) $(OPT) $(DEBUG) -I$(INCLUDE0) -I$(INCLUDE2)


INCLUDE =$(wildcard $(POWHEGBOXV2)/include/*.h *.h include/*.h)

ifeq ("$(PDF)","lhapdf")
LHAPDF_CONFIG=lhapdf-config
PDFPACK=lhapdf6if.o lhapdf6ifcc.o
FJCXXFLAGS+= $(shell $(LHAPDF_CONFIG) --cxxflags)
LIBSLHAPDF= -Wl,-rpath,$(shell $(LHAPDF_CONFIG) --libdir)  -L$(shell $(LHAPDF_CONFIG) --libdir) -lLHAPDF -lstdc++
ifeq  ("$(STATIC)","-static") 
## If LHAPDF has been compiled with gfortran and you want to link it statically, you have to include
## libgfortran as well. The same holds for libstdc++. 
## One possible solution is to use fastjet, since $(shell $(FASTJET_CONFIG) --libs --plugins ) -lstdc++
## does perform this inclusion. The path has to be set by the user. 
 LIBGFORTRANPATH=/usr/lib/gcc/x86_64-redhat-linux/4.1.2
 LIBSTDCPP=/lib64
 LIBSLHAPDF+=  -L$(LIBGFORTRANPATH)  -lgfortranbegin -lgfortran -L$(LIBSTDCPP) -lstdc++
endif
LIBS+=$(LIBSLHAPDF)
else
PDFPACK=mlmpdfif.o hvqpdfpho.o
endif


FJCXXFLAGS+=$(shell  pythia8-config --cxxflags)
#LIBPYTHIA8=$(shell pythia8-config --ldflags) -ldl -lstdc++ #-llhapdfdummy
LIBPYTHIA8= -Wl,-rpath,$(shell pythia8-config --libdir) -L$(shell pythia8-config --libdir)  -L$(shell pythia8-config --libdir)/archive -lpythia8 -lpythia8lhapdf6 -ldl -lstdc++ #-llhapdfdummy


PWHGANAL=pwhg_analysis-dummy.o pwhg_bookhist.o

ifeq ("$(ANALYSIS)","default")
##To include Fastjet configuration uncomment the following lines. 
#FASTJET_CONFIG=$(shell which fastjet-config)
#LIBSFASTJET += $(shell $(FASTJET_CONFIG) --libs --plugins ) -lstdc++
#FJCXXFLAGS+= $(shell $(FASTJET_CONFIG) --cxxflags)
PWHGANAL=pwhg_analysis.o pwhg_bookhist.o
## Also add required Fastjet drivers to PWHGANAL (examples are reported)
#PWHGANAL+= fastjetsisconewrap.o fastjetktwrap.o fastjetCDFMidPointwrap.o fastjetD0RunIIConewrap.o fastjetfortran.o
endif

ifeq ("$(ANALYSIS)","2to2")
##To include Fastjet configuration uncomment the following lines. 
FASTJET_CONFIG=$(shell which fastjet-config)
LIBSFASTJET += $(shell $(FASTJET_CONFIG) --libs --plugins ) -lstdc++
FJCXXFLAGS+= $(shell $(FASTJET_CONFIG) --cxxflags)
PWHGANAL=pwhg_analysis-2to2.o smearmom.o pwhg_bookhist-multi.o multi_plot.o
## Also add required Fastjet drivers to PWHGANAL (examples are reported)
PWHGANAL+= fastjetfortran.o 
endif

%.o: %.f $(INCLUDE)
	$(FF) -c -o obj/$@ $<

%.o: %.f90 $(INCLUDE)
	$(FF) -c -o obj/$@ $<

%.o: %.c
	$(CC) $(DEBUG) -c -o obj/$@ $^ 

%.o: %.cc
	$(CXX) $(DEBUG) -c -o obj/$@ $^ $(FJCXXFLAGS)
LIBS+=-lz
USER=init_couplings.o init_processes.o Born_phsp.o Born.o virtual.o	\
     real.o $(PWHGANAL)

PWHG=pwhg_main.o pwhg_init.o bbinit.o btilde.o lhefwrite.o		\
	LesHouches.o LesHouchesreg.o gen_Born_phsp.o find_regions.o	\
	test_Sudakov.o pt2maxreg.o sigborn.o gen_real_phsp.o maxrat.o	\
	gen_index.o gen_radiation.o Bornzerodamp.o sigremnants.o	\
	random.o boostrot.o bra_ket_subroutines.o cernroutines.o	\
	init_phys.o powheginput.o pdfcalls.o sigreal.o sigcollremn.o	\
	pwhg_analysis_driver.o checkmomzero.o		\
	setstrongcoupl.o integrator.o newunit.o mwarn.o sigsoftvirt.o	\
	sigcollsoft.o sigvirtual.o reshufflemoms.o  setlocalscales.o \
        validflav.o mint_upb.o  \
	pwhgreweight.o opencount.o ubprojections.o utils.o \
	$(PDFPACK) $(USER) $(FPEOBJ) lhefread.o pwhg_io_interface.o rwl_weightlists.o rwl_setup_param_weights.o

# target to generate LHEF output
pwhg_main:$(PWHG)
	$(FF) $(patsubst %,obj/%,$(PWHG)) $(LIBS) $(LIBSFASTJET) $(STATIC) -o $@

LHEF=lhef_analysis.o boostrot.o random.o cernroutines.o		\
     bra_ket_subroutines.o opencount.o powheginput.o $(PWHGANAL)	\
     lhefread.o pwhg_io_interface.o rwl_weightlists.o newunit.o pwhg_analysis_driver.o $(FPEOBJ)

# target to analyze LHEF output
lhef_analysis:$(LHEF)
	$(FF) $(patsubst %,obj/%,$(LHEF)) $(LIBS) $(LIBSFASTJET) $(STATIC)  -o $@ 


# target to analyze LHEF output
LHEF2TO2=lhef_analysis.o boostrot.o random.o cernroutines.o		\
     bra_ket_subroutines.o opencount.o powheginput.o \
     pwhg_analysis-2to2.o pwhg_bookhist-multi.o	 fastjetfortran.o\
     lhefread.o pwhg_io_interface.o rwl_weightlists.o newunit.o pwhg_analysis_driver.o $(FPEOBJ)

# # target to read event file, shower events with HERWIG + analysis
# HERWIG=main-HERWIG.o setup-HERWIG-lhef.o herwig.o boostrot.o	\
# 	powheginput.o $(PWHGANAL) lhefread.o pwhg_io_interface.o rwl_weightlists.o	\
# 	pdfdummies.o opencount.o $(FPEOBJ) 

# main-HERWIG-lhef: $(HERWIG)
# 	$(FF) $(patsubst %,obj/%,$(HERWIG))  $(LIBSFASTJET)  $(STATIC) -o $@

# # target to read event file, shower events with PYTHIA + analysis
# PYTHIA=main-PYTHIA.o setup-PYTHIA-lhef.o pythia.o boostrot.o powheginput.o		\
# 	$(PWHGANAL) lhefread.o pwhg_io_interface.o rwl_weightlists.o newunit.o pdfdummies.o	\
# 	pwhg_analysis_driver.o random.o cernroutines.o opencount.o	\
# 	$(FPEOBJ)

# main-PYTHIA-lhef: $(PYTHIA)
# 	$(FF) $(patsubst %,obj/%,$(PYTHIA)) $(LIBSFASTJET)  $(STATIC) -o $@

# PYTHIA8=main-PYTHIA8-2to2.o powheginput.o \
# 	$(PWHGANAL) opencount.o pwhg_io_interface.o lhefread.o rwl_weightlists.o newunit.o pdfdummies.o \
# 	random.o cernroutines.o bra_ket_subroutines.o utils.o\
# 	$(FPEOBJ) $(LIBZDUMMY)

# OBJ=obj
# # target to read event file, shower events with PYTHIA8.2 + analysis
# main-PYTHIA82-lhef: $(PYTHIA8) pythia82F77-2to2.o
# 	$(FF) $(patsubst %,$(OBJ)/%,$(PYTHIA8) pythia82F77-2to2.o ) $(LIBSFASTJET) $(LIBPYTHIA8) $(STATIC) $(LIBS) -o $@



gauss: rangauss.o  pwhg_bookhist-multi.o newunit.o  cernroutines.o powheginput.o
	$(FF) $(patsubst %,$(OBJ)/%, rangauss.o  pwhg_bookhist-multi.o  newunit.o  cernroutines.o  powheginput.o  pwhg_io_interface.o ) -lz -o $@ 

# target to cleanup
.PHONY: clean
clean:
	rm -f obj/*.o pwhg_main lhef_analysis main-HERWIG-lhef	\
	main-PYTHIA-lhef

