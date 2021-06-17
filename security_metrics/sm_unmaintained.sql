/* This is the security metric for a project being unmaintained.
   This comes from a project/repo's status field in the Libraries.io dataset.
   If a project/repo is detected as "Unmaintained" or its repository is
   detected as unmaintained, the project recieves 3 points.
*/
DROP TABLE IF EXISTS sm_unmaintained;
\set metric_value 3
CREATE TABLE sm_unmaintained
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN p.project_status = 'Unmaintained' THEN :metric_value
          WHEN r.repo_status = 'Unmaintained' THEN :metric_value
          ELSE 0
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
);
-- ALTER TABLE sm_unmaintained ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_unmaintained (repo_name);
CREATE INDEX ON sm_unmaintained (project);
CREATE INDEX ON sm_unmaintained (score);
COMMENT ON TABLE sm_unmaintained IS 'Security metric - status "Unmaintained"';


