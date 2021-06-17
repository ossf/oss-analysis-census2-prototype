/* This is the 1 year contributor count metric.  This metric is scored as follows
   5 points if 0 contributors in the last year.
   4 points if only 1 contributor in the last year.
   2 points if 2-3 contributors in the last year.
   1 point if the project does not have a repository on github so the number
   of contributors in the last year is unknown.
*/
DROP TABLE IF EXISTS sm_contribs_1yr;
\set metric_value_0 5
\set metric_value_1 4
\set metric_value_2_3 2
\set metric_value_unknown 1 

CREATE TEMP TABLE contrib_count_1yr
AS (
  SELECT
    repo_name,
    COUNT(repo_name) AS contribs
  FROM
    repo_contribs_1yr
  GROUP BY 
    repo_name
);
CREATE INDEX on contrib_count_1yr (lower(repo_name));

CREATE TABLE sm_contribs_1yr
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN r.repo_name IS NULL THEN :metric_value_unknown
          WHEN cc1.contribs IS NULL THEN :metric_value_0
          WHEN cc1.contribs = 1 THEN :metric_value_1
          WHEN cc1.contribs < 4 THEN :metric_value_2_3
          ELSE 0 
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
    LEFT JOIN contrib_count_1yr cc1
      on lower(cc1.repo_name) = lower(r.repo_name)
);
-- ALTER TABLE sm_contribs_1yr ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_contribs_1yr (repo_name);
CREATE INDEX ON sm_contribs_1yr (project);
CREATE INDEX ON sm_contribs_1yr (score);
COMMENT ON TABLE sm_contribs_1yr IS 'Metric for contributors in last year';


