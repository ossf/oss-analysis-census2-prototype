# This program traverses dependencies for dependency files of the form:
# 'project_id','repo_id', 'dep_id', 'project', 'repo_name', 'dep_name'
import csv
from optparse import OptionParser
from multiprocessing import cpu_count, Pool
import os
from collections import OrderedDict
import gzip
import sys
import traceback
import tempfile
from subprocess import Popen, PIPE
from shutil import rmtree
import time

def load_dependencies(filename):
    with open(filename) as f:
        reader = csv.reader(f)
        # Skip Headers
        next(reader)

         # d is the dict of dependencies
        d = OrderedDict()
        # Fill in the direct dependencies from file
        for r in reader:
            if r[0]: # There is a project_id
              key = int(r[0])
            else: # use the repo_name to id project
              key = r[4]
            if key not in d:
                d[key] = list()
            if r[2]:
                try:
                    dep = int(r[2])
                except ValueError:
                    dep = r[2]
                d[key].append(dep)
            else:
                d[key].append(r[5])
    return d

def output_progress(project):
    print('Traversed project %s' % project)

def output_traversed(project, dependencies, writer):
    e = ''
    for dep in sorted(dependencies):
        if isinstance(project,int):
            if isinstance(dep,int):
                writer.writerow([project, e, dep, e, e, e])
            else:
                writer.writerow([project, e, e, e, e, dep])
        else:
            if isinstance(dep,int):
                writer.writerow([e, e, dep, e, project, e])
            else:
                writer.writerow([e, e, e, e, project, dep])

def add_dependencies(dependencies, p_id, done):
    for dep in dependencies[p_id]:
        if dep in done:
            continue
        else:
            done.add(dep)
            # Right now lets not deal with repos matching dependency
            # names.
            if isinstance(dep, int) and dep in dependencies:
                add_dependencies(dependencies, dep ,done)

def traverse_subset(dependencies, process, outroot, start=None, end=None):
    if start is None:
        start = 0
    if end is None:
        end = len(dependencies)
    i = 0
    output = os.path.join(outroot,('%03d.csv.gz' % (process)))
    csvfile = gzip.open(output, 'wb')
    writer = csv.writer(csvfile)
    writer.writerow(['project_id','repo_id', 'dep_id',
                     'project', 'repo_name', 'dep_name'])
    for p, deps in dependencies.iteritems():
        if i < start:
            i+=1
            continue
        if i >= end:
            break
        done = set([p])
        add_dependencies(dependencies, p, done)
        done.discard(p)
        i += 1
        output_traversed(p ,done, writer)
        output_progress(p)
    csvfile.close()
    return 0

def traverse_dependencies(dependencies, num_cpus, outroot):
    num_projects = len(dependencies)

    if num_projects < num_cpus:
        # p3 - Projects per process
        p3 = 1
        num_cpus = num_projects
    else:
        p3 = int(num_projects/num_cpus)

    print('Traversing deps for %d projects with %d cpus'
          % (num_projects, num_cpus))

    pool = Pool(num_cpus)

    mp_results = list()

    for i in xrange(num_cpus):
        arg_tup = (dependencies, i, outroot)
        kwargs = {'start':i*p3, 'end':(i+1)*p3}
        if i == num_cpus-1:
            kwargs['end'] = None
        x = pool.apply_async(traverse_subset, arg_tup, kwargs)

        mp_results.append(x)

    for i, x in enumerate(mp_results):
        try:
            #print "!!!!!", get_open_fds()
            x.get()
        except Exception, e:
            #print "PERROR:  %s:  %s" % (fullfnames[i], e)
            tr = traceback.format_exc()
            print "PERROR:  %s\n%s" % (e, tr)
            continue

    pool.close()
    pool.join()

if __name__ == "__main__":

    sys.setrecursionlimit(10000)
    parser = OptionParser('\n./%prog DEPENDENCY_FILE.csv')

    parser.add_option('-p', '--processors', dest="num_cpus", default=1,
            help=("Number of processors to use; default is 1.\n"
                  "For all processors set to 0"))

    options, args = parser.parse_args()

    if len(args) < 1:
        parser.print_help()
        exit()
    else:
        filename = args[0]

    if not '.csv' == filename[-4:]:
        raise ValueError('Please use a file ending in .csv')

    if not os.path.isfile(filename):
        raise ValueError('No such file exists: %s' % filename)

    num_cpus = int(options.num_cpus)

    if num_cpus < 0:
        raise ValueError('Number of processors must be >= 0: %d'
                         % num_cpus)

    available_cpus = cpu_count()-1  # Leave 1 CPU for system overhead
    if num_cpus == 0 or num_cpus > available_cpus:
        num_cpus = available_cpus

    t0 = time.time()
    dependencies = load_dependencies(filename)

    outroot = filename[:-4] + '_traversed'

    if os.path.exists(outroot):
        raise ValueError('The projected output path: %s exists.\n'
                         'Please remove or rename the file/folder '
                         'and run again'
                         % outroot)
    os.mkdir(outroot)

    traverse_dependencies(dependencies, num_cpus, outroot)

    print('Finished in %0.3fs' % (time.time()-t0))
