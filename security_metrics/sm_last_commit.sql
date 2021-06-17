/* This is the security metric for whether a project has been commited too in a 
   long time.  This uses the last_pushed_at field in the libraries.io dataset.
   If a project does not have a repo with this data, 1 point is given.
   Points are given for varying times between the last_push_at and updated_at 
   fields (when the data was retreived) accordingly
   1 points > 6 months
   2 points > 1 years
   3 points > 2 years
   4 points > 3 years.  
*/
DROP TABLE IF EXISTS sm_last_commit;
\set metric_value_6m 1
\set metric_value_1y 2
\set metric_value_2y 3
\set metric_value_3y 4
\set metric_value_unknown 1
CREATE TABLE sm_last_commit
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN r.repo_id IS NULL THEN :metric_value_unknown
          WHEN r.last_pushed_at IS NULL THEN 0 /* empty repo */
          WHEN r.updated_at - r.last_pushed_at > '3 years'::interval THEN :metric_value_3y
          WHEN r.updated_at - r.last_pushed_at > '2 years'::interval THEN :metric_value_2y
          WHEN r.updated_at - r.last_pushed_at > '1 year'::interval THEN :metric_value_1y
          WHEN r.updated_at - r.last_pushed_at > '6 months'::interval THEN :metric_value_6m
          ELSE 0
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
);
-- ALTER TABLE sm_last_commit ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_last_commit (repo_name);
CREATE INDEX ON sm_last_commit (project);
CREATE INDEX ON sm_last_commit (score);
COMMENT ON TABLE sm_last_commit IS 'Security metric - last commit time';


