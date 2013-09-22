test:
	cutest tests/*_test.rb

tests/%: .PHONY
	cutest $@

.PHONY:
