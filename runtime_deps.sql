CREATE TEMP TABLE repo_deps
AS (
  SELECT DISTINCT
    p.project_id,
    rd.repo_id,
    rd.dep_id,
    p.project,
    rd.repo_name,
    rd.dep_name,
    rd.dep_kind
  FROM projects p
  RIGHT JOIN repo_dependencies rd
    ON rd.repo_id = p.repo_id
  LEFT JOIN (
    SELECT DISTINCT
      p.repo_id
    FROM dependencies d
    JOIN projects p
      ON d.project_id = p.project_id
    WHERE
      p.repo_id is NOT NULL
  ) AS prd
    ON prd.repo_id = rd.repo_id
  WHERE prd.repo_id IS NULL
  ORDER BY rd.repo_id, rd.dep_id
);

CREATE TEMP TABLE p_deps
AS (
  SELECT DISTINCT
    d.project_id,
    p.repo_id,
    d.dep_id,
    d.project,
    '' AS repo_name,
    d.dep_name,
    d.dep_kind
  FROM dependencies d
  JOIN projects p
    ON d.project_id = p.project_id
);

-- Whitelist runtime dependency kinds
\copy (SELECT DISTINCT project_id, repo_id, dep_id, project, repo_name, dep_name FROM (SELECT * FROM p_deps UNION SELECT * FROM repo_deps) AS all_deps where lower(dep_kind) SIMILAR TO 'runtime%|%provide%|["provided"]|%compile%|["compile"]|imports|["runtime"]|peer|depends|system|import|["system"]|["import"]|external|["external"]' ORDER BY project_id, repo_id, dep_id) to './runtime_deps.csv' csv header
