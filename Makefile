PREFIX ?= /usr/local

.PHONEY: install
install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -t $(DESTDIR)$(PREFIX)/bin/ git-natp git-natp-parse git-natp-create git-natp-compare

.PHONEY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-parse
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-create
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-compare

.PHONEY: test
test:
	./test/run.sh
