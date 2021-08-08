#!/usr/bin/env node

import sqlFormatter from "@sqltools/formatter";
import * as fs from "fs";

console.log(sqlFormatter.format(fs.readFileSync(process.stdin.fd, 'utf-8')))
