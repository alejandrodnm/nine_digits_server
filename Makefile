current_dir := $(shell pwd)

build:
	docker build -t nine_digits .

run:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -p 4000:4000 -it nine_digits mix run --no-halt

tests:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=test nine_digits mix test

lint:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=test nine_digits mix do credo, format --check-formatted

coverage:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=test nine_digits mix coveralls

coverage-html:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=test nine_digits mix coveralls.html

type-check:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=dev nine_digits mix dialyzer

docs:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it -e MIX_ENV=dev nine_digits mix docs

clean:
	docker rmi nine_digits

release:
	docker run --rm --name nine_digits -v $(current_dir):/opt/nine_digits -it nine_digits mix release
