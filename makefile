# Rerun analysis.
# Must install: make
# You should probably run "nohup make" - this takes a while.

# Must set up PostgreSQL, e.g.:
#~ sudo apt update
#~ sudo apt install postgresql postgresql-contrib
#~ sudo su postgres
#~ createdb census2
#~ createuser --interactive
#~   Enter name of role to add: $(yourusername)
#~   Shall the new role be a superuser? (y/n) y
#~ exit
# Now you can run make

TARGET_DB?=census2
NUM_CPU?=0

all: filtered_runtime_deps_traversed_dependent_counts_labeled.csv

# Not run automatically:
download:
	wget https://zenodo.org/record/833207/files/Libraries.io-open-data-1.0.1.zip

libio_data: Libraries.io-open-data-1.0.1.zip
	unzip Libraries.io-open-data-1.0.1.zip -d libio_data

db.loaded: \
  libio_data/repository_dependencies-1.0.0-2017-06-15.csv \
  libio_data/dependencies-1.0.0-2017-06-15.csv \
  libio_data/projects-1.0.0-2017-06-15.csv \
  load_db.sql load_repos.sql score_repos.sql
	psql -f load_db.sql $(TARGET_DB)
	psql -f load_repos.sql $(TARGET_DB)
	psql -f score_repos.sql $(TARGET_DB)
	touch db.loaded

contributors.loaded: repo_contributors_1yr.csv \
  load_repo_contributors_1yr.sql
	psql -f load_repo_contributors_1yr.sql $(TARGET_DB)
	touch contributors.loaded

security_metrics/sm_contrib_file.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_contrib_file.sql
	psql -f security_metrics/sm_contrib_file.sql $(TARGET_DB)
	touch security_metrics/sm_contrib_file.loaded

security_metrics/sm_contribs_1yr.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_contribs_1yr.sql
	psql -f security_metrics/sm_contribs_1yr.sql $(TARGET_DB)
	touch security_metrics/sm_contribs_1yr.loaded

security_metrics/sm_homepage.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_homepage.sql
	psql -f security_metrics/sm_homepage.sql $(TARGET_DB)
	touch security_metrics/sm_homepage.loaded

security_metrics/sm_last_commit.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_last_commit.sql
	psql -f security_metrics/sm_last_commit.sql $(TARGET_DB)
	touch security_metrics/sm_last_commit.loaded

security_metrics/sm_license.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_license.sql
	psql -f security_metrics/sm_license.sql $(TARGET_DB)
	touch security_metrics/sm_license.loaded

security_metrics/sm_unmaintained.loaded: \
  db.loaded contributors.loaded \
  security_metrics/sm_unmaintained.sql
	psql -f security_metrics/sm_unmaintained.sql $(TARGET_DB)
	touch security_metrics/sm_unmaintained.loaded

security_metrics.loaded: \
  security_metrics/sm_contrib_file.loaded \
  security_metrics/sm_contribs_1yr.loaded \
  security_metrics/sm_homepage.loaded \
  security_metrics/sm_last_commit.loaded \
  security_metrics/sm_license.loaded \
  security_metrics/sm_unmaintained.loaded
	touch security_metrics.loaded

project-full_deps.csv: db.loaded p-full_deps.sql
	psql -f p-full_deps.sql $(TARGET_DB)

project-full_deps_traversed.csv: project-full_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) project-full_deps.csv

project-full_deps_traversed_dependent_counts.csv: \
  project-full_deps_traversed.csv
	python count_all_dependents.py project-full_deps_traversed.csv

project-runtime_deps.csv: db.loaded p-runtime_deps.sql
	psql -f p-runtime_deps.sql $(TARGET_DB)

project-runtime_deps_traversed.csv: project-runtime_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) project-runtime_deps.csv

project-runtime_deps_traversed_dependent_counts.csv: \
  project-runtime_deps_traversed.csv
	python count_all_dependents.py project-runtime_deps_traversed.csv
	psql -f load_p-runtime_counts.sql $(TARGET_DB)

project-runtime_deps_traversed_dependent_counts_labeled.csv: \
  project-runtime_deps_traversed_dependent_counts.csv
	psql -f p-output_labeled_runtime_counts.sql

full_deps.csv: db.loaded full_deps.sql
	psql -f full_deps.sql $(TARGET_DB)

full_deps_traversed: full_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) full_deps.csv
	touch full_deps_traversed

full_deps_traversed_dependent_counts.csv: \
  full_deps_traversed
	python count_all_dependents.py -p $(NUM_CPU) full_deps_traversed
	psql -f load_full_counts.sql $(TARGET_DB)

full_deps_traversed_dependent_counts_labeled.csv: \
  full_deps_traversed_dependent_counts.csv
	psql -f output_labeled_full_counts.sql $(TARGET_DB)

runtime_deps.csv: db.loaded runtime_deps.sql
	psql -f runtime_deps.sql $(TARGET_DB)

runtime_deps_traversed: runtime_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) runtime_deps.csv
	touch runtime_deps_traversed

runtime_deps_traversed_dependent_counts.csv: \
  runtime_deps_traversed
	python count_all_dependents.py -p $(NUM_CPU) runtime_deps_traversed
	psql -f load_runtime_counts.sql $(TARGET_DB)

runtime_deps_traversed_dependent_counts_labeled.csv: \
  runtime_deps_traversed_dependent_counts.csv
	psql -f output_labeled_runtime_counts.sql $(TARGET_DB)

filtered_runtime_deps.csv: db.loaded filtered_runtime_deps.sql
	psql -f filtered_runtime_deps.sql $(TARGET_DB)

filtered_runtime_deps_traversed: filtered_runtime_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) filtered_runtime_deps.csv
	touch filtered_runtime_deps_traversed

filtered_runtime_deps_traversed_dependent_counts.csv: \
  filtered_runtime_deps_traversed
	python count_all_dependents.py -p $(NUM_CPU) filtered_runtime_deps_traversed
	psql -f load_filtered_runtime_counts.sql $(TARGET_DB)

filtered_runtime_deps_traversed_dependent_counts_labeled.csv: \
  filtered_runtime_deps_traversed_dependent_counts.csv
	psql -f output_labeled_filtered_runtime_counts.sql $(TARGET_DB)

filtered_deps.csv: db.loaded filtered_deps.sql
	psql -f filtered_deps.sql $(TARGET_DB)

filtered_deps_traversed: filtered_deps.csv
	python traverse_all_dependencies.py -p $(NUM_CPU) filtered_deps.csv
	touch filtered_deps_traversed

filtered_deps_traversed_dependent_counts.csv: \
  filtered_deps_traversed
	python count_all_dependents.py -p $(NUM_CPU) filtered_deps_traversed
	psql -f load_filtered_counts.sql $(TARGET_DB)

filtered_deps_traversed_dependent_counts_labeled.csv: \
  filtered_deps_traversed_dependent_counts.csv
	psql -f output_labeled_filtered_counts.sql $(TARGET_DB)

test_projects_traversed: \
  traverse_all_dependencies.py test_projects.csv
	python traverse_all_dependencies.py -p 1 test_projects.csv

check: SHELL:=/bin/bash
check: test_projects_traversed
	diff -w <(sort test_projects_traversed-correct.csv) <(gunzip -c test_projects_traversed/000.csv.gz | sort)
	rm -r test_projects_traversed
