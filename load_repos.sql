DROP TABLE IF EXISTS repos;

CREATE TABLE repos
(
  repo_id int NOT NULL,
  host_type text,
  repo_name text,
  description text,
  is_fork text,
  created_at timestamp,
  updated_at timestamp,
  last_pushed_at timestamp,
  homepage text,
  repo_size int,
  stars int DEFAULT 0,
  lang text,
  issues_enabled text,
  wiki_enabled text,
  pags_enabled text,
  fork_count int DEFAULT 0,
  mirror_url text,
  open_issues_count int DEFAULT 0,
  default_branch text,
  watchers int DEFAULT 0,
  uuid text,
  fork_source text,
  license text,
  contributors int DEFAULT 0,
  readme_name text,
  changelog_name text,
  contributing_name text,
  license_name text,
  CoC_name text,
  sec_model_name text,
  sec_audit_name text,
  repo_status text,
  last_synced_raw text,
  source_rank int,
  display_name text,
  scm_type text,
  pr_enabled_raw text,
  logo_url text,
  keywords text,
  mistake text,
  PRIMARY KEY(repo_id)
);

CREATE INDEX ON repos (repo_name);
CREATE INDEX ON repos (is_fork);
CREATE INDEX ON repos (stars);
CREATE INDEX ON repos (watchers);
CREATE INDEX ON repos (contributors);
CREATE INDEX ON repos (open_issues_count);
CREATE INDEX ON repos (fork_count);
CREATE INDEX ON repos (homepage);
CREATE INDEX ON repos (license);
CREATE INDEX ON repos (license_name);
CREATE INDEX ON repos (created_at);
CREATE INDEX ON repos (updated_at);
CREATE INDEX ON repos (last_pushed_at);

\copy repos FROM 'libio_data/repositories-1.0.0-2017-06-15.csv' CSV HEADER;

update repos set license = null where license = '';
update repos set license_name = null where license_name = '';
