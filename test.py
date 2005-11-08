#!/usr/bin/env python2.4

"""
Run all tests:

    ./test.py 

Or a specific suite (search, parsing, stats)

    ./test.py parsing 

$Id$
"""

from test import StatsTests, SearchTests, PubmedMedlineTests, OvidMedlineTests
from unittest import TestSuite, TextTestRunner, makeSuite
from sys import argv

# determine if we should all or just one 
tests = [ 'stats', 'parsing', 'search' ]
if len(argv) == 2: 
    tests = [argv[1]]

# add appropriate tests 
suite = TestSuite()
if 'stats' in tests:
    suite.addTest(makeSuite(StatsTests, 'test'))

if 'search' in tests:
    suite.addTest(makeSuite(SearchTests, 'test'))

if 'parsing' in tests:
    suite.addTest(makeSuite(PubmedMedlineTests, 'test'))
    suite.addTest(makeSuite(OvidMedlineTests, 'test'))

# run 'em 
runner = TextTestRunner(verbosity=2)
runner.run(suite)

# clean up .pyc files
import os
os.system('\\rm canary/*.pyc')
os.system('\\rm test/*.pyc')
