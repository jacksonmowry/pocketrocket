module main

import rand

struct Table {
	name        string
	db          string
	primary_key string
	rows        int
	cols        int
	indexes     int
	size        f64
	protected   bool
	last_update f64
}

fn rand_table() Table {
	return Table{
		name: rand.string(7)
		db: rand.string(7)
		primary_key: rand.string(4)
		rows: rand.u32() % 100 + 1
		cols: rand.u32() % 100 + 1
		indexes: 1
		size: rand.f64() * 50
		protected: rand.u32() % 2 == 1
		last_update: rand.f64() * 2
	}
}
