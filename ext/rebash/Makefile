RUBY_HDRDIR  := $(shell ruby -rrbconfig -e "puts(Config::CONFIG['rubyhdrdir'] || '')")
RUBY_ARCHDIR := $(shell ruby -rrbconfig -e "puts(Config::CONFIG['archdir'] || '')")
RUBY_LIBDIR  := $(shell ruby -rrbconfig -e "puts(Config::CONFIG['libdir'] || '')")
RUBY_LIBRUBY := $(shell ruby -rrbconfig -e "puts(Config::CONFIG['LIBRUBYARG'] || '')")

CPPFLAGS += -I$(RUBY_HDRDIR)
CPPFLAGS += -I$(RUBY_ARCHDIR)

LDFLAGS += -L$(RUBY_ARCHDIR)
LDFLAGS += -L$(RUBY_LIBDIR)
LDFLAGS += $(RUBY_LIBRUBY)
LDFLAGS += -lreadline

all: rebash.so

rebash.so: rebash.o
	gcc -shared $(LDFLAGS) -o rebash.so rebash.o

rebash.o: rebash.c
	gcc -I$(CPPFLAGS) -fPIC -c rebash.c -o rebash.o

