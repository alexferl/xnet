module bytealg

// equal reports whether a and b
// are the same length and contain the same bytes.
pub fn equal(a []u8, b []u8) bool {
	return a.bytestr() == b.bytestr()
}
