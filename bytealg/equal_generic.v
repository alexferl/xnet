module bytealg

// equal reports whether a and b
// are the same length and contain the same bytes.
// A nil argument is equivalent to an empty slice.
//
// Equal is equivalent to bytes.Equal.
// It is provided here for convenience,
// because some packages cannot depend on bytes.
pub fn equal(a []byte, b []byte) bool {
	return a.bytestr() == b.bytestr()
}
