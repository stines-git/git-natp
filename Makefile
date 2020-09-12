PREFIX ?= /usr/local

.PHONY: install
install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -t $(DESTDIR)$(PREFIX)/bin/ git-natp git-natp-parse git-natp-create git-natp-compare

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-parse
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-create
	rm -f $(DESTDIR)$(PREFIX)/bin/git-natp-compare

.PHONY: test
test:
	./test/run.sh
