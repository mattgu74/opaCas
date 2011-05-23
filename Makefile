all: cas_test.exe

cas_test.exe: 
	opa cas_test.opack -o cas_test.exe

clean:
	\rm -Rf *.exe _build _tracks *.log