module xnet

import bytealg

// IP address manipulations
//
// IPv4 addresses are 4 bytes; IPv6 addresses are 16 bytes.
// An IPv4 address can be converted to an IPv6 address by
// adding a canonical prefix (10 zeros, 2 0xFFs).
// This library accepts either size of byte slice but always
// returns 16-byte addresses.

// IP address lengths (bytes).
const (
	ipv4_len = 4
	ipv6_len = 16
)

// An IP is a single IP address, a slice of bytes.
// Functions in this package accept either 4-byte (IPv4)
// or 16-byte (IPv6) slices as input.
//
// Note that in this documentation, referring to an
// IP address as an IPv4 address or an IPv6 address
// is a semantic property of the address, not just the
// length of the byte slice: a 16-byte slice can still
// be an IPv4 address.
pub type IP = []u8

// An IPMask is a bitmask that can be used to manipulate
// IP addresses for IP addressing and routing.
//
// See type IPNet and func parse_cidr for details.
pub type IPMask = []u8

// An IPNet represents an IP network.
pub struct IPNet {
	ip   IP     // network number
	mask IPMask // network mask
}

// ipv4 returns the IP address (in 16-byte form) of the
// IPv4 address a.b.c.d.
pub fn ipv4(a u8, b u8, c u8, d u8) IP {
	mut p := IP([]u8{len: ipv6_len})
	copy(mut p, v4_in_v6_prefix)
	p[12] = a
	p[13] = b
	p[14] = c
	p[15] = d
	return p
}

const v4_in_v6_prefix = [u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff]

// ipv4_mask returns the IP mask (in 4-byte form) of the
// IPv4 mask a.b.c.d.
pub fn ipv4_mask(a u8, b u8, c u8, d u8) IPMask {
	mut p := IPMask([]u8{len: ipv4_len})
	p[0] = a
	p[1] = b
	p[2] = c
	p[3] = d
	return p
}

const (
	ip_nil = IP([]u8{})
	ip_mask_nil = IPMask([]u8{})
)

// cidr_mask returns an ipmask consisting of 'ones' 1 bits
// followed by 0s up to a total length of 'bits' bits.
// For a mask of this form, cidr_mask is the inverse of ipmask.size.
pub fn cidr_mask(ones int, bits int) IPMask {
	if bits != 8 * ipv4_len && bits != 8 * ipv6_len {
		return ip_mask_nil
	}
	if ones < 0 || ones > bits {
		return ip_mask_nil
	}
	l := bits / 8
	mut m := IPMask([]u8{len: l})
	mut n := u32(ones)
	for i := 0; i < l; i++ {
		if n >= 8 {
			m[i] = 0xff
			n -= 8
			continue
		}
		m[i] = ~u8(0xff >> n) & 0xff
		n = 0
	}
	return m
}

// Well-known IPv4 addresses
const (
	ipv4_bcast     = ipv4(255, 255, 255, 255) // limited broadcast
	ipv4_allsys    = ipv4(224, 0, 0, 1) // all systems
	ipv4_allrouter = ipv4(224, 0, 0, 2) // all routers
	ipv4_zero      = ipv4(0, 0, 0, 0) // all zeros
)

// Well-known IPv6 addresses
const (
	ipv6_zero                   = IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	ipv6_unspecified            = IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	ipv6_loopback               = IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
	ipv6_interfacelocalallnodes = IP([u8(0xff), 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01])
	ipv6_linklocalallnodes      = IP([u8(0xff), 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01])
	ipv6_linklocalallrouters    = IP([u8(0xff), 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x02])
)

// is_unspecified reports whether ip is an unspecified address, either
// the IPv4 address "0.0.0.0" or the IPv6 address "::".
pub fn (ip IP) is_unspecified() bool {
	return ip.equal(ipv4_zero) || ip.equal(ipv6_unspecified)
}

// is_loopback reports whether ip is a loopback address.
pub fn (ip IP) is_loopback() bool {
	ip4 := ip.to4()
	if ip4.len > 0 {
		return ip4[0] == 127
	}
	return ip.equal(ipv6_loopback)
}

// is_private reports whether ip is a private address, according to
// RFC 1918 (IPv4 addresses) and RFC 4193 (IPv6 addresses).
pub fn (ip IP) is_private() bool {
	ip4 := ip.to4()
	if ip4.len > 0 {
		// Following RFC 1918, Section 3. Private Address Space which says:
		//   The Internet Assigned Numbers Authority (IANA) has reserved the
		//   following three blocks of the IP address space for private internets:
		//     10.0.0.0        -   10.255.255.255  (10/8 prefix)
		//     172.16.0.0      -   172.31.255.255  (172.16/12 prefix)
		//     192.168.0.0     -   192.168.255.255 (192.168/16 prefix)
		return ip4[0] == 10 || (ip4[0] == 172 && ip4[1] & 0xf0 == 16)
			|| (ip4[0] == 192 && ip4[1] == 168)
	}
	// Following RFC 4193, Section 8. IANA Considerations which says:
	//   The IANA has assigned the FC00::/7 prefix to "Unique Local Unicast".
	return ip.len == ipv6_len && ip[0] & 0xfe == 0xfc
}

// is_multicast reports whether ip is a multicast address.
pub fn (ip IP) is_multicast() bool {
	ip4 := ip.to4()
	if ip4.len > 0 {
		return ip4[0] & 0xf0 == 0xe0
	}
	return ip.len == ipv6_len && ip[0] == 0xff
}

// is_interface_local_multicast reports whether ip is
// an interface-local multicast address.
pub fn (ip IP) is_interface_local_multicast() bool {
	return ip.len == ipv6_len && ip[0] == 0xff && ip[1] & 0x0f == 0x01
}

// is_link_local_multicast reports whether ip is a link-local
// multicast address.
pub fn (ip IP) is_link_local_multicast() bool {
	ip4 := ip.to4()
	if ip4.len > 0 {
		return ip4[0] == 224 && ip4[1] == 0 && ip4[2] == 0
	}
	return ip.len == ipv6_len && ip[0] == 0xff && ip[1] & 0x0f == 0x02
}

// is_link_local_unicast reports whether ip is a link-local
// unicast address.
pub fn (ip IP) is_link_local_unicast() bool {
	ip4 := ip.to4()
	if ip4.len > 0 {
		return ip4[0] == 169 && ip4[1] == 254
	}
	return ip.len == ipv6_len && ip[0] == 0xfe && ip[1] & 0xc0 == 0x80
}

// is_global_unicast reports whether ip is a global unicast
// address.
//
// The identification of global unicast addresses uses address type
// identification as defined in RFC 1122, RFC 4632 and RFC 4291 with
// the exception of IPv4 directed broadcast addresses.
// It returns true even if ip is in IPv4 private address space or
// local IPv6 unicast address space.
pub fn (ip IP) is_global_unicast() bool {
	return (ip.len == ipv4_len || ip.len == ipv6_len) && !ip.equal(ipv4_bcast)
		&& !ip.is_unspecified() && !ip.is_loopback() && !ip.is_multicast()
		&& !ip.is_link_local_unicast()
}

// Is ip all zeros?
fn is_zeros(ip IP) bool {
	for i := 0; i < ip.len; i++ {
		if ip[i] != 0 {
			return false
		}
	}
	return true
}

// to4 converts the IPv4 address ip to a 4-byte representation.
// If ip is not an IPv4 address, to4 returns ip_nil.
pub fn (ip IP) to4() IP {
	if ip.len == ipv4_len {
		return ip
	}
	if ip.len == ipv6_len && is_zeros(ip[0..10]) && ip[10] == 0xff && ip[11] == 0xff {
		return ip[12..16]
	}
	return ip_nil
}

// to16 converts the IP address ip to a 16-byte representation.
// If ip is not an IP address (it is the wrong length), to16 returns ip_nil.
pub fn (ip IP) to16() IP {
	if ip.len == ipv4_len {
		return ipv4(ip[0], ip[1], ip[2], ip[3])
	}
	if ip.len == ipv6_len {
		return ip
	}
	return ip_nil
}

// Default route masks for IPv4.
const (
	class_a_mask = ipv4_mask(0xff, 0, 0, 0)
	class_b_mask = ipv4_mask(0xff, 0xff, 0, 0)
	class_c_mask = ipv4_mask(0xff, 0xff, 0xff, 0)
)

// default_mask returns the default IP mask for the IP address
// Only IPv4 addresses have default masks; default_mask returns
// ip_mask_nil if ip is not a valid IPv4 address.
pub fn (ip IP) default_mask() IPMask {
	ip4 := ip.to4()
	if ip4.len == 0 {
		return ip_mask_nil
	}
	match true {
		ip[0] < 0x80 {
			return class_a_mask
		}
		ip[0] < 0xC0 {
			return class_b_mask
		}
		else {
			return class_c_mask
		}
	}
}

fn all_ff(b []u8) bool {
	for c in b {
		if c != 0xff {
			return false
		}
	}
	return true
}

// mask returns the result of masking the IP address ip with mask.
pub fn (mut ip IP) mask(mut mask IPMask) IP {
	if mask.len == ipv6_len && ip.len == ipv4_len && all_ff(mask[..12]) {
		mask = mask[12..]
	}
	if mask.len == ipv4_len && ip.len == ipv6_len
		&& bytealg.equal(ip[..12], [u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff]) {
		ip = ip[12..]
	}
	n := ip.len
	if n != mask.len {
		return ip_nil
	}
	mut out := IP([]u8{len: n})
	for i := 0; i < n; i++ {
		out[i] = ip[i] & mask[i]
	}
	return out
}

// ubtoa encodes the string form of the integer v to dst[start..] and
// returns the number of bytes written to dst. The caller must ensure
// that dst has sufficient length.
fn ubtoa(mut dst []u8, start int, v u8) int {
	if v < 10 {
		dst[start] = v + `0`
		return 1
	} else if v < 100 {
		dst[start + 1] = v % 10 + `0`
		dst[start] = v / 10 + `0`
		return 2
	}

	dst[start + 2] = v % 10 + `0`
	dst[start + 1] = (v / 10) % 10 + `0`
	dst[start] = v / 100 + `0`
	return 3
}

// string returns the string form of the IP address
// It returns one of 4 forms:
//   - '<nil>', if ip has length 0
//   - dotted decimal ("192.0.2.1"), if ip is an IPv4 or IP4-mapped IPv6 address
//   - IPv6 ("2001:db8::1"), if ip is a valid IPv6 address
//   - the hexadecimal form of ip, without punctuation, if no other cases apply
pub fn (ip IP) string() string {
	mut p := ip

	if ip.len == 0 {
		return '<nil>'
	}

	// If IPv4, use dotted notation.
	p4 := p.to4()
	if p4.len == ipv4_len {
		max_ipv4_string_len := '255.255.255.255'.len
		mut b := []u8{len: max_ipv4_string_len}

		mut n := ubtoa(mut b, 0, p4[0])
		b[n] = `.`
		n++

		n += ubtoa(mut b, n, p4[1])
		b[n] = `.`
		n++

		n += ubtoa(mut b, n, p4[2])
		b[n] = `.`
		n++

		n += ubtoa(mut b, n, p4[3])
		return b[..n].bytestr()
	}
	if p.len != ipv6_len {
		return '?' + hex_string(ip)
	}

	// Find longest run of zeros.
	mut e0 := -1
	mut e1 := -1
	for i := 0; i < ipv6_len; i += 2 {
		mut j := i
		for j < ipv6_len && p[j] == 0 && p[j + 1] == 0 {
			j += 2
		}
		if j > i && j - i > e1 - e0 {
			e0 = i
			e1 = j
			i = j
		}
	}
	// The symbol "::" MUST NOT be used to shorten just one 16 bit 0 field.
	if e1 - e0 <= 2 {
		e0 = -1
		e1 = -1
	}

	max_len := 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'.len
	mut b := []u8{len: 0, cap: max_len}

	// Print with ipv6_len :: in place of run of zeros
	for i := 0; i < ipv6_len; i += 2 {
		if i == e0 {
			b << `:`
			b << `:`
			i = e1
			if i >= ipv6_len {
				break
			}
		} else if i > 0 {
			b << `:`
		}
		b = append_hex(mut b, (u32(p[i]) << 8) | u32(p[i + 1]))
	}
	return b.bytestr()
}

fn hex_string(b []u8) string {
	mut s := []u8{len: b.len * 2}
	for i, tn in b {
		s[i * 2], s[i * 2 + 1] = hex_digit[tn >> 4], hex_digit[tn & 0xf]
	}
	return s.bytestr()
}

// ip_empty_string is like string except that it returns
// an empty string when ip is unset.
fn ip_empty_string(ip IP) string {
	if ip.len == 0 {
		return ''
	}
	return ip.string()
}

// equal reports whether ip and x are the same IP address.
// An IPv4 address and that same address in IPv6 form are
// considered to be equal.
pub fn (ip IP) equal(x IP) bool {
	if ip.len == x.len {
		return bytealg.equal(ip, x)
	}
	if ip.len == ipv4_len && x.len == ipv6_len {
		return bytealg.equal(x[0..12], v4_in_v6_prefix) && bytealg.equal(ip, x[12..])
	}
	if ip.len == ipv6_len && x.len == ipv4_len {
		return bytealg.equal(ip[0..12], v4_in_v6_prefix) && bytealg.equal(ip[12..], x)
	}
	return false
}

fn (ip IP) match_addr_family(x IP) bool {
	return (ip.to4().len > 0 && x.to4().len > 0)
		|| (ip.to16().len > 0 && ip.to4().len == 0 && x.to16().len > 0 && x.to4().len == 0)
}

// If mask is a sequence of 1 bits followed by 0 bits,
// return the number of 1 bits.
fn simple_mask_length(mut mask IPMask) int {
	mut n := 0
	for i, v in mask {
		mut k := v
		if k == 0xff {
			n += 8
			continue
		}
		// found non-ff byte
		// count 1 bits
		for int(k) & 0x80 != 0 {
			n++
			k <<= 1
		}
		// rest must be 0 bits
		if k != 0 {
			return -1
		}
		ii := i
		for j := ii + 1; j < mask.len; j++ {
			if mask[j] != 0 {
				return -1
			}
		}
		break
	}
	return n
}

// size returns the number of leading ones and total bits in the mask.
// If the mask is not in the canonical form--ones followed by zeros--then
// size returns 0, 0.
pub fn (mut m IPMask) size() (int, int) {
	ones, bits := simple_mask_length(mut m), m.len * 8
	if ones == -1 {
		return 0, 0
	}
	return ones, bits
}

// string returns the hexadecimal form of m, with no punctuation.
pub fn (m IPMask) string() string {
	if m.len == 0 {
		return ''
	}
	return hex_string(m)
}

fn network_number_and_mask(n IPNet) (IP, IPMask) {
	mut ip := n.ip.to4()
	if ip.len == 0 {
		ip = n.ip
		if ip.len != ipv6_len {
			return ip_nil, ip_mask_nil
		}
	}
	mut m := n.mask
	match m.len {
		ipv4_len {
			if ip.len != ipv4_len {
				return ip_nil, ip_mask_nil
			}
		}
		ipv6_len {
			if ip.len == ipv4_len {
				m = m[12..]
			}
		}
		else {
			return ip_nil, ip_mask_nil
		}
	}
	return ip, m
}

// contains reports whether the network includes ip.
pub fn (n IPNet) contains(ip IP) bool {
	mut ip_ := ip
	nn, m := network_number_and_mask(n)
	x := ip_.to4()
	if x.len > 0 {
		ip_ = x
	}
	l := ip_.len
	if l != nn.len {
		return false
	}
	for i := 0; i < l; i++ {
		if nn[i] & m[i] != ip_[i] & m[i] {
			return false
		}
	}
	return true
}

// network returns the address's network name, 'ip+net'.
pub fn (n IPNet) network() string {
	return 'ip+net'
}

// uitoa converts val to a decimal string.
fn uitoa(v int) string {
	mut val := v
	if val == 0 { // avoid string allocation
		return '0'
	}
	mut buf := []u8{len: 20} // big enough for 64bit value base 10
	mut i := buf.len - 1
	for val >= 10 {
		q := val / 10
		buf[i] = u8(`0` + val - q * 10)
		i--
		val = q
	}
	// val < 10
	buf[i] = u8(`0` + val)
	return buf[i..].bytestr()
}

// string returns the CIDR notation of n like "192.0.2.0/24"
// or "2001:db8::/48" as defined in RFC 4632 and RFC 4291.
// If the mask is not in the canonical form, it returns the
// string which consists of an IP address, followed by a slash
// character and a mask expressed as hexadecimal form with no
// punctuation like "198.51.100.0/c000ff00".
pub fn (n IPNet) string() string {
	nn, mut m := network_number_and_mask(n)
	if nn.len == 0 || m.len == 0 {
		return ''
	}
	l := simple_mask_length(mut m)
	if l == -1 {
		return nn.string() + '/' + m.string()
	}
	return nn.string() + '/' + uitoa(l)
}

// parse_ipv4 parses s as a literal IPv4 address described in RFC 791.
fn parse_ipv4(str string) IP {
	mut s := str
	mut p := []u8{len: ipv4_len}
	for i := 0; i < ipv4_len; i++ {
		if s.len == 0 {
			// Missing octets.
			return ip_nil
		}
		if i > 0 {
			if s[0] != `.` {
				return ip_nil
			}
			s = s[1..]
		}
		n, c, ok := dtoi(s)
		if !ok || n > 0xFF {
			return ip_nil
		}
		if c > 1 && s[0] == `0` {
			// Reject non-zero components with leading zeroes.
			return ip_nil
		}
		s = s[c..]
		p[i] = u8(n)
	}
	if s.len != 0 {
		return ip_nil
	}
	return ipv4(p[0], p[1], p[2], p[3])
}

// parse_ipv6_zone parses s as a literal IPv6 address and its associated zone
// identifier which is described in RFC 4007.
fn parse_ipv6_zone(s string) (IP, string) {
	ss, zone := split_host_zone(s)
	return parse_ipv6(ss), zone
}

// parse_ipv6 parses s as a literal IPv6 address described in RFC 4291
// and RFC 5952.
fn parse_ipv6(str string) IP {
	mut s := str
	mut ip := IP([]u8{len: ipv6_len})
	mut ellipsis := -1 // position of ellipsis in ip

	// Might have leading ellipsis
	if s.len >= 2 && s[0] == `:` && s[1] == `:` {
		ellipsis = 0
		s = s[2..]
		// Might be only ellipsis
		if s.len == 0 {
			return ip
		}
	}

	// Loop, parsing hex numbers followed by colon.
	mut i := 0
	for i < ipv6_len {
		// Hex number.
		n, c, ok := xtoi(s)
		if !ok || n > 0xFFFF {
			return ip_nil
		}

		// If followed by dot, might be in trailing IPv4.
		if c < s.len && s[c] == `.` {
			if ellipsis < 0 && i != ipv6_len - ipv4_len {
				// Not the right place.
				return ip_nil
			}
			if i + ipv4_len > ipv6_len {
				// Not enough room.
				return ip_nil
			}
			ip4 := parse_ipv4(s)
			if ip4.len == 0 {
				return ip_nil
			}
			ip[i] = ip4[12]
			ip[i + 1] = ip4[13]
			ip[i + 2] = ip4[14]
			ip[i + 3] = ip4[15]
			s = ''
			i += ipv4_len
			break
		}

		// Save this 16-bit chunk.
		ip[i] = u8(n >> 8)
		ip[i + 1] = u8(n)
		i += 2

		// Stop at end of string.
		s = s[c..]
		if s.len == 0 {
			break
		}

		// Otherwise must be followed by colon and more.
		if s[0] != `:` || s.len == 1 {
			return ip_nil
		}
		s = s[1..]

		// Look for ellipsis.
		if s[0] == `:` {
			if ellipsis >= 0 { // already have one
				return ip_nil
			}
			ellipsis = i
			s = s[1..]
			if s.len == 0 { // can be at end
				break
			}
		}
	}

	// Must have used entire string.
	if s.len != 0 {
		return ip_nil
	}

	// If didn't parse enough, expand ellipsis.
	if i < ipv6_len {
		if ellipsis < 0 {
			return ip_nil
		}
		n := ipv6_len - i
		for j := i - 1; j >= ellipsis; j-- {
			ip[j + n] = ip[j]
		}
		for j := ellipsis + n - 1; j >= ellipsis; j-- {
			ip[j] = 0
		}
	} else if ellipsis >= 0 {
		// Ellipsis must represent at least one 0 group.
		return ip_nil
	}

	return ip
}

// parse_ip parses s as an IP address, returning the result.
// The string s can be in IPv4 dotted decimal ("192.0.2.1"), IPv6
// ("2001:db8::68"), or IPv4-mapped IPv6 ("::ffff:192.0.2.1") form.
// If s is not a valid textual representation of an IP address,
// ParseIP returns ip_nil.
pub fn parse_ip(s string) IP {
	for i := 0; i < s.len; i++ {
		match s[i] {
			`.` {
				return parse_ipv4(s)
			}
			`:` {
				return parse_ipv6(s)
			}
			else {
				continue
			}
		}
	}
	return ip_nil
}

// parse_ipzone parses s as an IP address, return it and its associated zone
// identifier (IPv6 only).
fn parse_ipzone(s string) (IP, string) {
	for i := 0; i < s.len; i++ {
		match s[i] {
			`.` {
				return parse_ipv4(s), ''
			}
			`:` {
				return parse_ipv6_zone(s)
			}
			else {
				continue
			}
		}
	}
	return ip_nil, ''
}

// parse_cidr parses s as a CIDR notation IP address and prefix length,
// like "192.0.2.0/24" or "2001:db8::/32", as defined in
// RFC 4632 and RFC 4291.
//
// It returns the IP address and the network implied by the IP and
// prefix length.
// For example, ParseCIDR("192.0.2.1/24") returns the IP address
// 192.0.2.1 and the network 192.0.2.0/24.
pub fn parse_cidr(s string) (IP, IPNet, ParseError) {
	i := s.index_u8(`/`)
	if i < 0 {
		return ip_nil, IPNet{}, ParseError{'CIDR address', s}
	}
	addr, mask := s[..i], s[i + 1..]
	mut iplen := ipv4_len
	mut ip := parse_ipv4(addr)
	if ip.len == 0 {
		iplen = ipv6_len
		ip = parse_ipv6(addr)
	}
	n, j, ok := dtoi(mask)
	if ip.len == 0 || !ok || j != mask.len || n < 0 || n > 8 * iplen {
		return ip_nil, IPNet{}, ParseError{'CIDR address', s}
	}
	mut m := cidr_mask(n, 8 * iplen)
	return ip, IPNet{ip.mask(mut m), m}, ParseError{}
}
