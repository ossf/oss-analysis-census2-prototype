DROP TABLE IF EXISTS repo_dependencies;
DROP TABLE IF EXISTS dependencies;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS deps_by_id;

CREATE TABLE repo_dependencies
(
  id int NOT NULL,
  host_name text,
  repo_name text,
  repo_id int NOT NULL,
  man_platform text,
  man_path text,
  git_branch text,
  man_kind text,
  optional text,
  dep_name text,
  dep_reqs text,
  dep_kind text,
  dep_id int,
  PRIMARY KEY(id)
);
CREATE INDEX ON repo_dependencies (dep_name, dep_id);
CREATE INDEX ON repo_dependencies (repo_id);
CREATE INDEX ON repo_dependencies (repo_name, dep_name, dep_id);
CREATE INDEX ON repo_dependencies ((lower(dep_kind)));
\copy repo_dependencies FROM 'libio_data/repository_dependencies-1.0.0-2017-06-15.csv' CSV HEADER;

CREATE TABLE dependencies
(
  id int NOT NULL,
  platform text,
  project text,
  project_id int NOT NULL,
  v_num text,
  v_id int,
  dep_name text,
  dep_platform text,
  dep_kind text,
  dep_optional text,
  dep_reqs text,
  dep_id int,
  PRIMARY KEY(id)
);

CREATE INDEX ON dependencies (dep_name, dep_id);
CREATE INDEX ON dependencies (project_id);
CREATE INDEX ON dependencies (project, dep_name, dep_id);
CREATE INDEX ON dependencies ((lower(dep_kind)));
\copy dependencies FROM 'libio_data/dependencies-1.0.0-2017-06-15.csv' CSV HEADER;

CREATE TABLE projects
(
  project_id int NOT NULL,
  platform text,
  project text,
  created_raw text,
  updated_raw text,
  description text,
  keywords text,
  homepage text,
  licenses text,
  repo_url text,
  v_count int,
  source_rank int,
  release_date_raw text,
  release_number text,
  manager_id text ,
  ddep_project_count int,
  lang text,
  project_status text,
  last_synced_raw text,
  ddep_repo_count int,
  repo_id int,
  PRIMARY KEY(project_id)
);

CREATE INDEX ON projects (repo_id);
CREATE INDEX ON projects (repo_url);
CREATE INDEX ON projects (project);
\copy projects FROM 'libio_data/projects-1.0.0-2017-06-15.csv' CSV HEADER;

CREATE TABLE deps_by_id
AS (
  SELECT DISTINCT
    dep_id,
    REGEXP_REPLACE(REGEXP_REPLACE(lower(dep_name), '\s+$', ''), '^\s+', '') AS dep_name
  FROM (
    SELECT DISTINCT
      dep_id,
      dep_name
    FROM dependencies
    WHERE dep_id IS NOT NULL
    UNION
    SELECT DISTINCT
      dep_id,
      dep_name
    FROM repo_dependencies
    WHERE dep_id IS NOT NULL
    UNION
    SELECT DISTINCT
      project_id AS dep_id,
      project AS dep_name
    FROM projects
  ) AS deps
  ORDER BY dep_id
);

ALTER TABLE deps_by_id ADD PRIMARY KEY (dep_id);
ALTER TABLE deps_by_id ADD COLUMN platform TEXT;
CREATE INDEX ON deps_by_id (dep_name);

UPDATE deps_by_id
  SET
    dep_name = p.project,
    platform = p.platform
  FROM projects p
  WHERE
    dep_id = p.project_id;
