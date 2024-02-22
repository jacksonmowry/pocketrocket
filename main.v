module main

import db.sqlite
import vweb
import time
import rand
import arrays
import os

struct App {
	vweb.Context
mut:
	db sqlite.DB
}

fn main() {
	rand.seed([u32(3223878742), 1732001562])
	mut app := App{
		db: sqlite.connect('index.db')!
	}

	app.db.exec('CREATE TABLE if not exists users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    date_joined DATE,
    is_active BOOLEAN DEFAULT true
);')!

	app.serve_static('/output.css', 'output.css')
	app.serve_static('/htmx.min.js', 'htmx.min.js')
	vweb.run(app, 8081)
}

@['/']
pub fn (mut app App) index() vweb.Result {
	cur_date := time.now().custom_format('ddd MMM Do YYYY')
	cur_time := time.now().clean12()
	databases := rand.u32() % 10 + 1
	tables := rand.u32() % 30 + databases
	db_size := arrays.sum[f64](app.db.exec('SELECT * FROM dbstat') or { panic(err) }.map(it.vals[9].f64())) or {
		panic(err)
	}
	lambdas := rand.u32() % 50 + 1
	invocations := rand.f32() * 40
	disk_usage := rand.f32() * 100

	all_tables := app.all_tables()

	mut rows := []Table{}
	for name in all_tables {
		rows << app.table_info(name)
	}

	return $vweb.html()
}

fn (mut app App) all_tables() []string {
	rows := app.db.exec("SELECT name FROM sqlite_master WHERE type='table';") or { panic(err) }
	return rows.map(it.vals[0])
}

fn (mut app App) table_info(table_name string) Table {
	mut rows := app.db.exec_param('SELECT name, type, sql FROM sqlite_master WHERE name = ?',
		table_name) or { panic(err) }

	rows = app.db.exec('PRAGMA database_list;') or { panic(err) }
	db_name := if rows[0].vals[2] == '' { 'in memory' } else { rows[0].vals[1] }

	rows = app.db.exec('PRAGMA table_info(${table_name})') or { panic(err) }

	column_count := rows.len
	primary_key := rows.filter(it.vals[5] == '1')[0].vals[1]

	rows = app.db.exec('SELECT COUNT(*) FROM ${table_name}') or { panic(err) }
	row_count := rows[0].vals[0].int()

	rows = app.db.exec("SELECT count(*) FROM sqlite_master WHERE type='index' AND tbl_name='${table_name}';") or {
		panic(err)
	}

	indexes := rows[0].vals[0].int()

	rows = app.db.exec('SELECT * FROM dbstat') or { panic(err) }

	table_size := arrays.sum[int](rows.filter(it.vals[0].contains(table_name)).map(it.vals[9].int())) or {
		panic(err)
	}

	return Table{
		name: table_name
		db: db_name
		primary_key: primary_key
		rows: row_count
		cols: column_count
		indexes: indexes
		size: f64(table_size) / 1000
		protected: false
		last_update: 4.2
	}
}
