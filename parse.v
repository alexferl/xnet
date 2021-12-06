module xnet

// Bigger than we need, not too big to worry about overflow
const big = 0xFFFFFF

// Decimal to integer.
// Returns number, characters consumed, success.
fn dtoi(s string) (int, int, bool) {
	mut n := 0
	mut i := 0
	for i = 0; i < s.len && `0` <= s[i] && s[i] <= `9`; i++ {
		n = n * 10 + int(s[i] - `0`)
		if n >= xnet.big {
			return xnet.big, i, false
		}
	}
	if i == 0 {
		return 0, 0, false
	}
	return n, i, true
}

// Hexadecimal to integer.
// Returns number, characters consumed, success.
fn xtoi(s string) (int, int, bool) {
	mut n := 0
	mut i := 0
	for i = 0; i < s.len; i++ {
		if `0` <= s[i] && s[i] <= `9` {
			n *= 16
			n += int(s[i] - `0`)
		} else if `a` <= s[i] && s[i] <= `f` {
			n *= 16
			n += int(s[i] - `a`) + 10
		} else if `A` <= s[i] && s[i] <= `F` {
			n *= 16
			n += int(s[i] - `A`) + 10
		} else {
			break
		}
		if n >= xnet.big {
			return 0, i, false
		}
	}
	if i == 0 {
		return 0, i, false
	}
	return n, i, true
}

// Index of rightmost occurrence of b in s.
fn last(s string, b byte) int {
	mut j := s.len
	for i := j - 1; i >= 0; i-- {
		if s[i] == b {
			break
		}
	}
	return j
}
