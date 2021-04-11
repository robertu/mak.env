BUILDDIR=$(shell pwd)
LOGDIR=$(TOPDIR)/logs
RUNDIR=$(TOPDIR)/run
PYDIR=$(TOPDIR)/py
CLJDIR=$(TOPDIR)/clj
NODEDIR=$(TOPDIR)/node
PRJDIR=${TOPDIR}/app
REQ=${PRJDIR}/requirements.txt
APPDIR=$(PRJDIR)/app
LIBDIR=$(PYDIR)/lib
PYTHON=$(PYDIR)/bin/python3
PIP=$(PYDIR)/bin/pip3
UNAME=$(shell uname)
BRANCH=$(shell git branch 2>/dev/null | grep '^*' | colrm 1 2)
PATH=$(CLJDIR)/bin:$(NODEDIR)/bin:$(PYDIR)/bin:/bin:/usr/bin


all:   done.python done.dirs done.gecko done.chrome done.node done.clj done.lein done.preproc

clean:
	rm -rf done.*

distclean: clean
	rm -rf Python-* node-* dist geckodriver* chromedriver* clj-install.sh clojupyter-master

python: done.python

node: done.node

gecko: done.gecko

chrome: done.chrome

lein: done.lein

done.lein: done.clj
	curl -O https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	chmod 755 lein
	mv lein ${CLJDIR}/bin
	${CLJDIR}/bin/lein
	touch $@

clj: done.clj

pyclj: done.pyclj

clj-install.sh:
	curl https://download.clojure.org/install/linux-install-1.10.1.483.sh > clj-install.sh
	touch $@
	chmod +x clj-install.sh

done.clj: clj-install.sh
	@if [ -d ${CLJDIR} ] ; then echo "*** Directory ${CLJDIR} exists. Remove it first.";exit 1;fi
	./clj-install.sh -p ${CLJDIR}
	touch $@

clojupyter-master: done.lein done.python
	wget https://github.com/clojupyter/clojupyter/archive/master.zip
	mv master.zip clojupyter-master.zip
	unzip clojupyter-master.zip
	touch $@

done.pyclj: clojupyter-master
	cd clojupyter-master ; make install
	touch $@

Python-${pythonversion}.tgz:
	curl -O https://www.python.org/ftp/python/${pythonversion}/Python-${pythonversion}.tgz

Python-${pythonversion}: Python-${pythonversion}.tgz
	tar zxf $<
	touch $@

done.python: Python-${pythonversion}
	cd Python-${pythonversion} ; \
	./configure --prefix=$(PYDIR) --enable-optimizations ; \
	make ;\
	make install
	@if [ -x $(PYDIR)/bin/python ] ; then echo "*** Python link already exists. Skipping." ; else ln -s python3 $(PYDIR)/bin/python ; fi
	touch $@

done.pip: done.python
	$(PIP) install wheel
	$(PIP) install --upgrade pip
	touch $@

done.requirements: done.pip
	${PYDIR}/bin/pip3 install jupyterlab
	if [ -f ${REQ} ]; then $(PIP) install -r ${REQ} ;fi
	touch $@

done.preproc: done.requirements
	@for f in `find $(TOPDIR) -name "*.++"`; do  \
		n=`echo $$f | sed "s/.++$$//g"`; \
		echo "$$f => $$n"; \
		if [ -f $$n ] ; then mv $$n $$n.old ; fi; \
		cat $$f \
			| sed "s@++TOPDIR++@$(TOPDIR)@g" \
			| sed "s@++CLJDIR++@$(CLJDIR)@g" \
			| sed "s@++PYDIR++@$(PYDIR)@g" \
			| sed "s@++NODEDIR++@$(NODEDIR)@g" \
			| sed "s@++LIBDIR++@$(LIBDIR)@g" \
			| sed "s@++LOGDIR++@$(LOGDIR)@g" \
			| sed "s@++RUNDIR++@$(RUNDIR)@g" \
			| sed "s@++PRJDIR++@$(PRJDIR)@g" \
			| sed "s@++APPUSER++@$(APPUSER)@g" \
			| sed "s@++APPGROUP++@$(APPGROUP)@g" \
			| sed "s@++DOMAIN++@$(DOMAIN)@g" \
			| sed "s@++APPDIR++@$(APPDIR)@g" \
			| sed "s@++APPPORT++@$(APPPORT)@g" \
			| sed "s@++PYTHON++@$(PYTHON)@g" \
			| sed "s@++VERSION++@$(VERSION)@g" \
			| sed "s@++BRANCH++@$(BRANCH)@g" \
			> $$n ; \
		chmod 755 $$n ; \
	done
	touch $@


geckodriver-v${geckodriver}-linux64.tar.gz:
	wget https://github.com/mozilla/geckodriver/releases/download/v${geckodriver}/geckodriver-v${geckodriver}-linux64.tar.gz

done.gecko: done.python geckodriver-v${geckodriver}-linux64.tar.gz
	tar zxvf geckodriver-v${geckodriver}-linux64.tar.gz
	mv geckodriver $(PYDIR)/bin
	touch $@

chromedriver_linux64.zip:
	wget https://chromedriver.storage.googleapis.com/${chromedriver}/chromedriver_linux64.zip

done.chrome: done.python chromedriver_linux64.zip
	unzip chromedriver_linux64.zip
	mv chromedriver $(PYDIR)/bin
	touch $@

node-v${nodeversion}-linux-x64.tar.xz:
	wget https://nodejs.org/dist/v${nodeversion}/node-v${nodeversion}-linux-x64.tar.xz
	touch $@

node-v${nodeversion}-linux-x64: node-v${nodeversion}-linux-x64.tar.xz
	tar xf $<
	touch $@

done.node: node-v${nodeversion}-linux-x64
	@if [ -d ${NODEDIR} ] ; then echo "*** Directory ${NODEDIR} exists. Remove it first.";exit 1;fi
	cp -r $< ${NODEDIR}
	${NODEDIR}/bin/npm install -g npm
	${NODEDIR}/bin/npm install -g yarn
	touch $@

done.dirs:
	mkdir -p ${LOGDIR}
	mkdir -p ${RUNDIR}
	touch $@
