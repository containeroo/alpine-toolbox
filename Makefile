.PHONY: patch minor major tag

# Find the latest tag (default to 0.0.0 if none found)
LATEST_TAG := $(shell git tag --list 'v*' --sort=-v:refname | head -n 1)
VERSION := $(shell echo $(LATEST_TAG) | sed 's/^v//' || echo "0.0.0")

patch: ## Create a new patch release (x.y.Z+1)
	@NEW_VERSION=$$(echo "$(VERSION)" | awk -F. '{printf "%d.%d.%d", $$1, $$2, $$3+1}') && \
	git tag "v$${NEW_VERSION}" && \
	echo "Tagged v$${NEW_VERSION}"

minor: ## Create a new minor release (x.Y+1.0)
	@NEW_VERSION=$$(echo "$(VERSION)" | awk -F. '{printf "%d.%d.0", $$1, $$2+1}') && \
	git tag "v$${NEW_VERSION}" && \
	echo "Tagged v$${NEW_VERSION}"

major: ## Create a new major release (X+1.0.0)
	@NEW_VERSION=$$(echo "$(VERSION)" | awk -F. '{printf "%d.0.0", $$1+1}') && \
	git tag "v$${NEW_VERSION}" && \
	echo "Tagged v$${NEW_VERSION}"

tag: ## Show latest tag
	@echo "Latest version: $(LATEST_TAG)"

push: ## Push tags to remote
	git push --tags

