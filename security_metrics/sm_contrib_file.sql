/* This is the security metric for a project having a contributing file detected
   by Libraries.io and included in their dataset.
   If contributing_name is null (no repo), 'f' or empty, the 1 point is added.
*/
DROP TABLE IF EXISTS sm_contrib_file;
\set metric_value 1
CREATE TABLE sm_contrib_file
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN r.contributing_name is NULL THEN :metric_value
          WHEN lower(r.contributing_name) like 'f|' THEN :metric_value
          ELSE 0
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
);
-- ALTER TABLE sm_contrib_file ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_contrib_file (repo_name);
CREATE INDEX ON sm_contrib_file (project);
CREATE INDEX ON sm_contrib_file (score);
COMMENT ON TABLE sm_contrib_file IS 'Security metric - contributing file';


