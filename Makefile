# Makefile for QED Labyrinth project
# Default Postgres connection URI; override on command line if necessary
DB_URL ?= postgres://postgres@localhost:5432/qed_labyrinth

.PHONY: reset-db
reset-db:
	@echo "Dropping all tables except 'users' …"
	psql $(DB_URL) -v ON_ERROR_STOP=1 -c "DO \$$\$$DECLARE r RECORD; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> 'users') LOOP EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE'; END LOOP; END\$$\$$;"
	@echo "✔ Database reset complete." 