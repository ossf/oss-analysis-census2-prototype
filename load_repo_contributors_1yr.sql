DROP TABLE IF EXISTS repo_contribs_1yr;

CREATE TABLE repo_contribs_1yr
(
  repo_name text NOT NULL,
  author text,
  PRIMARY KEY(repo_name, author)
);
\copy repo_contribs_1yr FROM 'repo_contributors_1yr.csv' CSV HEADER;

