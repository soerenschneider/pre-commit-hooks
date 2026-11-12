pre-commit-init:
	pre-commit install
	pre-commit install --hook-type commit-msg

test:
	./tests/conventional-commit_test.sh
