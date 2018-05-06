current_dir := $(shell pwd)

build:
	docker build -t nine_digits .

run:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -p 4000:4000 -it nine_digits mix run --no-halt

tests:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -p 4000:4000 -it -e MIX_ENV=test nine_digits mix test --force

docs:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -p 4000:4000 -it -e MIX_ENV=test nine_digits mix docss
