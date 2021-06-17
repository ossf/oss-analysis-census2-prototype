# This program counts dependents for dependency files of the form:
# 'project_id','repo_id', 'dep_id', 'project', 'repo_name', 'dep_name'
import csv
from collections import defaultdict, OrderedDict
import gzip
from multiprocessing import cpu_count, Pool
from operator import itemgetter
from optparse import OptionParser
import os
import sys
import time

def count_dependencies(filename):
    print("Counting dependents from %s" % filename)
    sys.stdout.flush()
    with gzip.open(filename) as f:
        # counts is the dict of dependency counts
        counts = defaultdict(int)

        reader = csv.reader(f)
        # Skip Headers
        next(reader)
        # Fill in the dependencies from file
        for r in reader:
            if r[2]:
                try:
                    dep = int(r[2])
                except ValueError:
                    dep = r[2]
            else:
                dep = r[5]
            counts[dep] += 1

    return counts


if __name__ == "__main__":

    parser = OptionParser('\n./%prog TRAVERSED_DEPENDENCIES')

    parser.add_option('-p', '--processors', dest="num_cpus", default=1,
            help=("Number of processors to use; default is 1.\n"
                  "For all processors set to 0"))

    options, args = parser.parse_args()

    if len(args) < 1:
        parser.print_help()
        exit()
    else:
        outroot = args[0]

    num_cpus = int(options.num_cpus)

    if num_cpus < 0:
        raise ValueError('Number of processors must be >= 0: %d'
                         % num_cpus)

    available_cpus = cpu_count()-1  # Leave 1 CPU for system overhead
    if num_cpus == 0 or num_cpus > available_cpus:
        num_cpus = available_cpus

    t0 = time.time()

    if not os.path.exists(outroot):
        raise ValueError('No such file or directory: %s' % outroot)

    if os.path.isfile(outroot):
        print("Counting dependents from %s" % outroot)
        sys.stdout.flush()
        if not '.csv.gz' == outroot[-7:]:
            raise ValueError('Please use a file ending in .csv')
        outname = outroot[:-7] + '_dependent_counts.csv'
        counts = count_dependencies(outroot)
    else:
        counts = defaultdict(int)
        print("Counting dependents from files in %s" % outroot)
        outname = outroot + '_dependent_counts.csv'
        # Count the dependencies, lets do it in parallel and then
        # combine afterwards
        pool = Pool(num_cpus)
        mp_results = list()
        for f in os.listdir(outroot):
            filename = os.path.join(outroot,f)
            if filename[-7:] == '.csv.gz':
                arg_tup = (filename,)
                x = pool.apply_async(count_dependencies, arg_tup)
                mp_results.append(x)
        for i, x in enumerate(mp_results):
            try:
                counts_local = x.get()
                for k,v in counts_local.iteritems():
                    counts[k]+=v
            except Exception, e:
                tr = traceback.format_exc()
                print "PERROR:  %s\n%s" % (e, tr)
                continue
        pool.close()
        pool.join()


    counts_ordered = OrderedDict(sorted(counts.iteritems(), key=itemgetter(1),
                                        reverse=True))
    # This is used for empty columns in our output,
    # lets minimize string creation
    e = ''
    with open(outname, 'wb') as countfile:
        countwriter = csv.writer(countfile)
        countwriter.writerow(['count','dep_id', 'dep_name'])
        for dep, count in counts_ordered.iteritems():
            if isinstance(dep,int):
                countwriter.writerow([count,dep,e])
            else:
                countwriter.writerow([count,e,dep])
    print('Finished in %0.3fs' % (time.time()-t0))
