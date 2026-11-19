.PHONY: test app check

test:
	swift test

check:
	./Scripts/check-no-network.sh

app:
	./Scripts/package-app.sh
