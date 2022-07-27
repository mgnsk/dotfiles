#!/usr/bin/env node

import sqlFormatter from "@sqltools/formatter";
import * as fs from "fs";

let args = process.argv.slice(2);
if (args.length != 1) {
  throw "Usage: sql_format <file>";
}
let file = args[0];

let data = fs.readFileSync(file, "utf8");

let result = sqlFormatter.format(data, {
  language: "sql",
  indent: " ".repeat(4),
  linesBetweenQueries: 2,
});

fs.writeFileSync(file, result);
