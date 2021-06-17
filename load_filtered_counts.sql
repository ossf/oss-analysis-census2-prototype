DROP TABLE IF EXISTS filtered_counts;

CREATE TABLE filtered_counts
(
  ID serial,
  dep_count int,
  dep_id int,
  dep_name text,
  platform text,
  PRIMARY KEY(id)
);

CREATE INDEX ON filtered_counts (dep_count);
CREATE INDEX ON filtered_counts (dep_id, dep_name);

\copy filtered_counts(dep_count, dep_id, dep_name) FROM 'filtered_deps_traversed_dependent_counts.csv' CSV HEADER;

UPDATE filtered_counts c
SET
  dep_name = d.dep_name,
  platform = d.platform
FROM deps_by_id d
WHERE
  c.dep_id = d.dep_id;
