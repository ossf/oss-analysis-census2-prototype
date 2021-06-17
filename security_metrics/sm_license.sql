/* This is the security metric for a project having a license as detected by
   Libraries.io and included in their dataset.
   If no license is detected the project recieves 1 point.
*/
DROP TABLE IF EXISTS sm_license;
\set metric_value 1
CREATE TABLE sm_license
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN p.licenses is NOT NULL THEN 0
          WHEN r.license is NOT NULL THEN 0
          ELSE :metric_value
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
);
-- ALTER TABLE sm_license ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_license (repo_name);
CREATE INDEX ON sm_license (project);
CREATE INDEX ON sm_license (score);
COMMENT ON TABLE sm_license IS 'Security metric - license detected';


