#!/usr/bin/env python
import csv, sys

output = csv.writer(sys.stdout, lineterminator='\n')
for line in csv.reader(sys.stdin):
	output.writerow([line[1]])
