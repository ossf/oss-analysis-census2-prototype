/* This is the project website security metric.  If no website has been
   identified then the project recieves 1 point.  We weight this very low
   because our data sources often fail to identify websites even when 
   they exist. 
*/
DROP TABLE IF EXISTS sm_homepage;
\set metric_value 1
CREATE TABLE sm_homepage
AS (
  SELECT DISTINCT
    p.project,
    p.project_id,
    r.repo_id,
    r.repo_name,
    (CASE WHEN (p.homepage IS NOT NULL OR TRIM(p.homepage) != ''
                OR r.homepage IS NOT NULL OR TRIM(r.homepage) != '') THEN 0
          ELSE :metric_value 
      END) AS score
  FROM projects p
    FULL OUTER JOIN repos r
      ON p.repo_id = r.repo_id
);
-- ALTER TABLE sm_homepage ADD PRIMARY KEY (project_id, repo_id);
CREATE INDEX ON sm_homepage (repo_name);
CREATE INDEX ON sm_homepage (project);
CREATE INDEX ON sm_homepage (score);
COMMENT ON TABLE sm_homepage IS 'Security metric - homepage exists';


