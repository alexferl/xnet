.PHONY: help dev test fmt vet

.DEFAULT: help
help:
	@echo "make dev"
	@echo "       prepare development environment"
	@echo "make test"
	@echo "       run all test files"
	@echo "make fmt"
	@echo "       format code"
	@echo "make vet"
	@echo "       report suspicious code constructs"

dev:
	pre-commit install || echo "You need to install pre-commit first. See: https://pre-commit.com/#install"

test:
	v -stats test *.v

fmt:
	v fmt -w *.v

vet:
	v vet *.v
