DROP TABLE IF EXISTS repos_to_keep;
DROP TABLE IF EXISTS c1;
DROP TABLE IF EXISTS c2;
DROP TABLE IF EXISTS c3;
DROP TABLE IF EXISTS c4;
DROP TABLE IF EXISTS c5;
DROP TABLE IF EXISTS c6;
DROP TABLE IF EXISTS c7;
DROP TABLE IF EXISTS scores;

CREATE TABLE repos_to_keep
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN projects p
      ON r.repo_id = p.repo_id
  WHERE stars >50
    OR watchers >50
    OR fork_count > 20
    OR contributors > 50
    OR p.project_id IS NOT NULL
);
ALTER TABLE repos_to_keep ADD PRIMARY KEY (repo_id);
CREATE INDEX ON repos_to_keep (repo_name);
COMMENT ON TABLE repos_to_keep IS 'Definitively Significant Repositories';

CREATE TABLE c1
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE r.fork_count <2
    AND r.watchers <=5
    AND r.stars <=10
    AND rtk.repo_id IS NULL
);
ALTER TABLE c1 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c1 (repo_name);
COMMENT ON TABLE c1 IS 'Possible insignificant repos by watchers, stars, & forks (pessimistic)';

CREATE TABLE c2
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE r.fork_count =0
    AND r.watchers <=2
    AND r.stars <=2
    AND rtk.repo_id IS NULL
);
ALTER TABLE c2 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c2 (repo_name);
COMMENT ON TABLE c2 IS 'Possible insignificant repos by watchers, stars, fork (conservative)';

CREATE TABLE c3
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE r.open_issues_count < 3
    AND rtk.repo_id IS NULL
);
ALTER TABLE c3 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c3 (repo_name);
COMMENT ON TABLE c3 IS 'Possible insignificant repos - few open issues';

CREATE TABLE c4
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE r.homepage IS NULL
    AND rtk.repo_id IS NULL
);
ALTER TABLE c4 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c4 (repo_name);
COMMENT ON TABLE c4 IS 'Possible insignificant repos - no homepage';

CREATE TABLE c5
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    JOIN repos_to_keep rtk
      ON r.fork_source = rtk.repo_name
    LEFT JOIN repos_to_keep rtk2
      ON rtk2.repo_id = r.repo_id
  WHERE rtk2.repo_id IS NULL
);
ALTER TABLE c5 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c5 (repo_name);
COMMENT ON TABLE c5 IS 'Possible insignificant repos - fork of a project';

CREATE TABLE c6
AS (
  SELECT DISTINCT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE r.last_pushed_at - r.created_at < '6 months'::interval
    AND age(r.last_pushed_at) > '1 year'::interval
    AND rtk.repo_id IS NULL
);
ALTER TABLE c6 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c6 (repo_name);
COMMENT ON TABLE c6 IS 'Possible insignificant repos - possible homework';

CREATE TABLE c7
AS (
  SELECT
    r.repo_id,
    r.repo_name
  FROM repos r
    LEFT JOIN repos_to_keep rtk
      ON rtk.repo_id = r.repo_id
  WHERE license IS NULL
    AND license_name IS NULL
    AND rtk.repo_id IS NULL
);
ALTER TABLE c7 ADD PRIMARY KEY (repo_id);
CREATE INDEX ON c7 (repo_name);
COMMENT ON TABLE c7 IS 'Possible insignificant repos - no license';

CREATE TABLE scores
AS (
  SELECT
    r.repo_id,
    r.repo_name,
    (CASE WHEN c1.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c1s,
    (CASE WHEN c2.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c2s,
    (CASE WHEN c3.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c3s,
    (CASE WHEN c4.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c4s,
    (CASE WHEN c5.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c5s,
    (CASE WHEN c6.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c6s,
    (CASE WHEN c7.repo_id IS NOT NULL THEN 1 ELSE 0 END) AS c7s
  FROM repos r
    FULL OUTER JOIN c1
      ON c1.repo_id = r.repo_id
    FULL OUTER JOIN c2
      ON c2.repo_id = r.repo_id
    FULL OUTER JOIN c3
      ON c3.repo_id = r.repo_id
    FULL OUTER JOIN c4
      ON c4.repo_id = r.repo_id
    FULL OUTER JOIN c5
      ON c5.repo_id = r.repo_id
    FULL OUTER JOIN c6
      ON c6.repo_id = r.repo_id
    FULL OUTER JOIN c7
      ON c7.repo_id = r.repo_id
);
ALTER TABLE scores ADD PRIMARY KEY (repo_id);
COMMENT ON TABLE scores IS 'Significance scores for repositories';
CREATE INDEX ON scores (repo_name);
CREATE INDEX ON scores (c1s);
CREATE INDEX ON scores (c2s);
CREATE INDEX ON scores (c3s);
CREATE INDEX ON scores (c4s);
CREATE INDEX ON scores (c5s);
CREATE INDEX ON scores (c6s);
CREATE INDEX ON scores (c7s);
