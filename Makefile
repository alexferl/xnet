.PHONY: help test fmt vet

.DEFAULT: help
help:
	@echo "make test"
	@echo "       run all test files"
	@echo "make fmt"
	@echo "       format code"
	@echo "make vet"
	@echo "       report suspicious code constructs"

test:
	v -stats test .

fmt:
	v fmt -w .

vet:
	v vet .
