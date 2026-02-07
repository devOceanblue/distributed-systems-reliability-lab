SHELL := /bin/bash

up-local:
	docker compose -f docker-compose.local.yml up -d

down-local:
	docker compose -f docker-compose.local.yml down

up-aws:
	LAB_PROFILE=aws docker compose -f docker-compose.local.yml -f docker-compose.aws.override.yml up -d app-placeholder

down-aws:
	LAB_PROFILE=aws docker compose -f docker-compose.local.yml -f docker-compose.aws.override.yml down

verify-phases:
	./scripts/verify/phase0.sh
	./scripts/verify/B-0303.sh
	./scripts/verify/B-0314.sh
	./scripts/verify/B-0315.sh
	./scripts/verify/B-0325.sh
	./scripts/verify/B-0326.sh
	./scripts/verify/B-0327.sh
	./scripts/verify/B-0328.sh
	./scripts/verify/B-0329.sh
	./scripts/verify/phase1-runtime.sh
	./scripts/verify/phase1.sh
	./scripts/verify/phase2.sh
	./scripts/verify/phase3.sh
	./scripts/verify/phase4.sh
	./scripts/verify/phase5.sh
