# Core Infrastructure Initiative Census 2 Prototype

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

The "Core Infrastructure Initiative (CII) Census 2 Prototype"
is a prototype for a new and larger process for identifying
the most important open source software (OSS), and from them,
identifying the "highest security risk" OSS among the most
important OSS.

For more information about this prototype, see
"Core Infrastructure Initiative (CII) Open Source Software Census II Strategy"
by David A. Wheeler and Jason N. Dossett, IDA Document D-8777.
That document describes the overall approach.
To determine the feasibility of this approach, we developed this prototype
that did some basic dependency analysis, computed a simple risk indicator,
and then reported the combination.  When developing this prototype,
we identified approaches that enabled the analysis to scale to the
millions of repositories and projects necessary.
In developing this prototype we found that
there are subtleties in versioning that must be carefully handled to
produce accurate results; this protype does not (yet) implement the
proposed changes to handle this.

This prototype primarily uses the
[dataset provided by Libraries.io](https://libraries.io/data);
we gratefully acknowledge their work.
We also used data from Google's BigQuery
[githubarchive monthly dataset](https://bigquery.cloud.google.com/dataset/githubarchive:month).

## Installation

You must install make and PostgreSQL.
On Ubuntu, do the following:

~~~sh
sudo apt update
sudo apt install postgresql postgresql-contrib make
sudo su postgres
createdb census2
createuser --interactive # Enter name of role to add: $(yourusername) ; say "y" for superuser
exit
~~~

You must then download the libraries.io dataset:

~~~sh
make download
make libio_data
~~~

## Usage

To run the analysis, simply run "make"; by default this will use
all but one of the processors on your system.

However, it takes a while, so you should probably run:

> nohup make &

You can set the environment variable NUM_CPU to set the
number of processors to use.  You can also set
TARGET_DB to set the database (by default, "census2").

This will produce various files, including the final result, the file
"filtered_runtime_deps_traversed_dependent_counts_labeled.csv"
which reports the ordered list of OSS packages that are most
depended upon by other package and repositories
(which is our proxy for importance), only for runtime
dependencies.

Some other files it produces:

* filtered_runtime_deps.csv - all direct dependencies for the filtered projects (from libraries.io dataset)
* filtered_runtime_deps_traversed/ - NUM_CPU gzipped .csv files containing all transitive dependencies

To calculate security risks, see the file "sm_score-NOTES".
It describes how to run the Google BigQuery query to get the
one-year contributor data.  You export that data to a .csv file
and place it in your directory as repo_contributors_1yr.csv.
Then run "make security_metrics.loaded" to calculate security risk scores.
Once that is done, you can use the queries described in "sm_score-NOTES" to
see the security risk scores, in particular, to sort the
"most important" packages (in each package manager) by risk score.

## License

All material is released under the [MIT license](./LICENSE).
All material that is not executable, including all text when not executed,
is also released under the
[Creative Commons Attribution 3.0 International (CC BY 3.0) license](https://creativecommons.org/licenses/by/3.0/) or later.
In SPDX terms, everything here is licensed under MIT;
if it's not executable, including the text when extracted from code, it's
"(MIT OR CC-BY-3.0+)".
