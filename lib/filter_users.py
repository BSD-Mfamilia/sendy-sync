#!/usr/bin/env python
import csv, sys

pattern = sys.argv[1]
output = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL, lineterminator='\n')
for line in csv.reader(sys.stdin):
	if any(f.startswith(pattern) for f in line[2:]):
		output.writerow(line[0:2])
