\copy (SELECT id, dep_count, platform, left(dep_name,30) AS dep_name FROM p_runtime_counts ORDER BY id) to './project-runtime_deps_traversed_dependent_counts_labeled.csv' csv header
