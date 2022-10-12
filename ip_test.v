module xnet

struct ParseIPTest {
	have string
	want IP
}

const parse_ip_tests = [
	ParseIPTest{'127.0.1.2', ipv4(127, 0, 1, 2)},
	ParseIPTest{'127.0.0.1', ipv4(127, 0, 0, 1)},
	ParseIPTest{'::ffff:127.1.2.3', ipv4(127, 1, 2, 3)},
	ParseIPTest{'::ffff:7f01:0203', ipv4(127, 1, 2, 3)},
	ParseIPTest{'0:0:0:0:0000:ffff:127.1.2.3', ipv4(127, 1, 2, 3)},
	ParseIPTest{'0:0:0:0:000000:ffff:127.1.2.3', ipv4(127, 1, 2, 3)},
	ParseIPTest{'0:0:0:0::ffff:127.1.2.3', ipv4(127, 1, 2, 3)},
	ParseIPTest{'2001:4860:0:2001::68', IP([u8(0x20), 0x01, 0x48, 0x60, 0, 0, 0x20, 0x01, 0, 0,
		0, 0, 0, 0, 0x00, 0x68])},
	ParseIPTest{'2001:4860:0000:2001:0000:0000:0000:0068', IP([u8(0x20), 0x01, 0x48, 0x60, 0, 0,
		0x20, 0x01, 0, 0, 0, 0, 0, 0, 0x00, 0x68])},
	ParseIPTest{'-0.0.0.0', ip_nil},
	ParseIPTest{'0.-1.0.0', ip_nil},
	ParseIPTest{'0.0.-2.0', ip_nil},
	ParseIPTest{'0.0.0.-3', ip_nil},
	ParseIPTest{'127.0.0.256', ip_nil},
	ParseIPTest{'abc', ip_nil},
	ParseIPTest{'123:', ip_nil},
	ParseIPTest{'fe80::1%lo0', ip_nil},
	ParseIPTest{'fe80::1%911', ip_nil},
	ParseIPTest{'', ip_nil},
	ParseIPTest{'a1:a2:a3:a4::b1:b2:b3:b4', ip_nil},
	ParseIPTest{'127.001.002.003', ip_nil},
	ParseIPTest{'::ffff:127.001.002.003', ip_nil},
	ParseIPTest{'123.000.000.000', ip_nil},
	ParseIPTest{'1.2..4', ip_nil},
	ParseIPTest{'0123.0.0.1', ip_nil},
]

fn test_parse_ip() {
	for t in parse_ip_tests {
		assert parse_ip(t.have) == t.want
	}
}

struct IPStringTest {
	have IP     // see RFC 791 and RFC 4291
	want string // see RFC 791, RFC 4291 and RFC 5952
}

const ip_string_tests = [
	// IPv4 address
	IPStringTest{ipv4(192, 0, 2, 1), '192.0.2.1'},
	IPStringTest{ipv4(0, 0, 0, 0), '0.0.0.0'}
	// IPv4-mapped IPv6 address
	IPStringTest{IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff, 192, 0, 2, 1]), '192.0.2.1'},
	IPStringTest{IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff, 0, 0, 0, 0]), '0.0.0.0'}
	// IPv6 address
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0, 0x1, 0x23, 0, 0x12, 0, 0x1]), '2001:db8::123:12:1'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x1]), '2001:db8::1'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0x1, 0, 0, 0, 0x1, 0, 0, 0, 0x1]), '2001:db8:0:1:0:1:0:1'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0x1, 0, 0, 0, 0x1, 0, 0, 0, 0x1, 0, 0]), '2001:db8:1:0:1:0:1:0'},
	IPStringTest{IP([u8(0x20), 0x1, 0, 0, 0, 0, 0, 0, 0, 0x1, 0, 0, 0, 0, 0, 0x1]), '2001::1:0:0:1'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0x1, 0, 0, 0, 0, 0, 0]), '2001:db8:0:0:1::'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0x1, 0, 0, 0, 0, 0, 0x1]), '2001:db8::1:0:0:1'},
	IPStringTest{IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0xa, 0, 0xb, 0, 0xc, 0, 0xd]), '2001:db8::a:b:c:d'},
	IPStringTest{ipv6_unspecified, '::'},
	IPStringTest{ip_nil, '<nil>'}
	// Opaque byte sequence
	IPStringTest{IP([u8(0x01), 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef]), '?0123456789abcdef'},
]

fn test_ip_string() {
	for t in ip_string_tests {
		assert t.have.string() == t.want
	}
}

struct IPMaskTest {
	want IP
mut:
	mask IPMask
	have IP
}

const ip_mask_tests = [
	IPMaskTest{ipv4(192, 168, 1, 0), ipv4_mask(255, 255, 255, 128), ipv4(192, 168, 1,
		127)},
	IPMaskTest{ipv4(192, 168, 1, 64), IPMask(parse_ip('255.255.255.192')), ipv4(192, 168,
		1, 127)},
	IPMaskTest{ipv4(192, 168, 1, 96), IPMask(parse_ip('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffe0')), ipv4(192,
		168, 1, 127)},
	IPMaskTest{ipv4(192, 0, 1, 0), ipv4_mask(255, 0, 255, 0), ipv4(192, 168, 1, 127)},
	IPMaskTest{parse_ip('2001:d80::'), IPMask(parse_ip('ffff:ff80::')), parse_ip('2001:db8::1')},
	IPMaskTest{parse_ip('2000:d08::'), IPMask(parse_ip('f0f0:0f0f::')), parse_ip('2001:db8::1')},
]

fn test_ip_mask() {
	for mut t in ip_mask_tests {
		have := t.have.mask(mut t.mask)
		assert have.len != 0
		assert t.want.equal(have)
	}
}

struct IPMaskTestString {
	have IPMask
	want string
}

const ip_mask_string_tests = [
	IPMaskTestString{ipv4_mask(255, 255, 255, 240), 'fffffff0'},
	IPMaskTestString{ipv4_mask(255, 0, 128, 0), 'ff008000'},
	IPMaskTestString{IPMask(parse_ip('ffff:ff80::')), 'ffffff80000000000000000000000000'},
	IPMaskTestString{IPMask(parse_ip('ef00:ff80::cafe:0')), 'ef00ff800000000000000000cafe0000'},
	IPMaskTestString{ip_mask_nil, '<nil>'},
]

fn test_ip_mask_string() {
	for t in ip_mask_string_tests {
		assert t.have.string() == t.want
	}
}

struct ParseCIDRTest {
	have string
	ip   IP
	net  IPNet
	err  ParseError
}

const parse_cidr_tests = [
	ParseCIDRTest{'135.104.0.0/32', ipv4(135, 104, 0, 0), IPNet{ipv4(135, 104, 0, 0), ipv4_mask(255,
		255, 255, 255)}, ParseError{}},
	ParseCIDRTest{'0.0.0.0/24', ipv4(0, 0, 0, 0), IPNet{ipv4(0, 0, 0, 0), ipv4_mask(255,
		255, 255, 0)}, ParseError{}},
	ParseCIDRTest{'135.104.0.0/24', ipv4(135, 104, 0, 0), IPNet{ipv4(135, 104, 0, 0), ipv4_mask(255,
		255, 255, 0)}, ParseError{}},
	ParseCIDRTest{'135.104.0.1/32', ipv4(135, 104, 0, 1), IPNet{ipv4(135, 104, 0, 1), ipv4_mask(255,
		255, 255, 255)}, ParseError{}},
	ParseCIDRTest{'135.104.0.1/24', ipv4(135, 104, 0, 1), IPNet{ipv4(135, 104, 0, 0), ipv4_mask(255,
		255, 255, 0)}, ParseError{}},
	ParseCIDRTest{'::1/128', parse_ip('::1'), IPNet{parse_ip('::1'), IPMask(parse_ip('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/127', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/65', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff:ffff:ffff:8000::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/64', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff:ffff:ffff::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/63', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff:ffff:fffe::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/33', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff:8000::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/32', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2345::'), IPMask(parse_ip('ffff:ffff::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2344::/31', parse_ip('abcd:2344::'), IPNet{parse_ip('abcd:2344::'), IPMask(parse_ip('ffff:fffe::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2300::/24', parse_ip('abcd:2300::'), IPNet{parse_ip('abcd:2300::'), IPMask(parse_ip('ffff:ff00::'))}, ParseError{}},
	ParseCIDRTest{'abcd:2345::/24', parse_ip('abcd:2345::'), IPNet{parse_ip('abcd:2300::'), IPMask(parse_ip('ffff:ff00::'))}, ParseError{}},
	ParseCIDRTest{'2001:DB8::/48', parse_ip('2001:DB8::'), IPNet{parse_ip('2001:DB8::'), IPMask(parse_ip('ffff:ffff:ffff::'))}, ParseError{}},
	ParseCIDRTest{'2001:DB8::1/48', parse_ip('2001:DB8::1'), IPNet{parse_ip('2001:DB8::'), IPMask(parse_ip('ffff:ffff:ffff::'))}, ParseError{}},
	ParseCIDRTest{'192.168.1.1/255.255.255.0', ip_nil, IPNet{}, ParseError{'CIDR address', '192.168.1.1/255.255.255.0'}},
	ParseCIDRTest{'192.168.1.1/35', ip_nil, IPNet{}, ParseError{'CIDR address', '192.168.1.1/35'}},
	ParseCIDRTest{'2001:db8::1/-1', ip_nil, IPNet{}, ParseError{'CIDR address', '2001:db8::1/-1'}},
	ParseCIDRTest{'2001:db8::1/-0', ip_nil, IPNet{}, ParseError{'CIDR address', '2001:db8::1/-0'}},
	ParseCIDRTest{'-0.0.0.0/32', ip_nil, IPNet{}, ParseError{'CIDR address', '-0.0.0.0/32'}},
	ParseCIDRTest{'0.-1.0.0/32', ip_nil, IPNet{}, ParseError{'CIDR address', '0.-1.0.0/32'}},
	ParseCIDRTest{'0.0.-2.0/32', ip_nil, IPNet{}, ParseError{'CIDR address', '0.0.-2.0/32'}},
	ParseCIDRTest{'0.0.0.-3/32', ip_nil, IPNet{}, ParseError{'CIDR address', '0.0.0.-3/32'}},
	ParseCIDRTest{'0.0.0.0/-0', ip_nil, IPNet{}, ParseError{'CIDR address', '0.0.0.0/-0'}},
	ParseCIDRTest{'127.000.000.001/32', ip_nil, IPNet{}, ParseError{'CIDR address', '127.000.000.001/32'}},
	ParseCIDRTest{'', ip_nil, IPNet{}, ParseError{'CIDR address', ''}},
]

fn test_parse_cidr() {
	for t in parse_cidr_tests {
		ip, net, err := parse_cidr(t.have)
		assert err == t.err
		if err == ParseError{} {
			assert t.ip.equal(ip) || t.net.ip.equal(net.ip) || net.mask == t.net.mask
		}
	}
}

struct IPNetContainsTest {
	ip  IP
	net IPNet
	ok  bool
}

const ip_net_contains_tests = [
	IPNetContainsTest{ipv4(172, 16, 1, 1), IPNet{ipv4(172, 16, 0, 0), cidr_mask(12, 32)}, true},
	IPNetContainsTest{ipv4(172, 24, 0, 1), IPNet{ipv4(172, 16, 0, 0), cidr_mask(13, 32)}, false},
	IPNetContainsTest{ipv4(192, 168, 0, 3), IPNet{ipv4(192, 168, 0, 0), ipv4_mask(0, 0,
		255, 252)}, true},
	IPNetContainsTest{ipv4(192, 168, 0, 4), IPNet{ipv4(192, 168, 0, 0), ipv4_mask(0, 255,
		0, 252)}, false},
	IPNetContainsTest{parse_ip('2001:db8:1:2::1'), IPNet{parse_ip('2001:db8:1::'), cidr_mask(47,
		128)}, true},
	IPNetContainsTest{parse_ip('2001:db8:1:2::1'), IPNet{parse_ip('2001:db8:2::'), cidr_mask(47,
		128)}, false},
	IPNetContainsTest{parse_ip('2001:db8:1:2::1'), IPNet{parse_ip('2001:db8:1::'), IPMask(parse_ip('ffff:0:ffff::'))}, true},
	IPNetContainsTest{parse_ip('2001:db8:1:2::1'), IPNet{parse_ip('2001:db8:1::'), IPMask(parse_ip('0:0:0:ffff::'))}, false},
]

fn test_ip_net_contains() {
	for t in ip_net_contains_tests {
		ok := t.net.contains(t.ip)
		assert ok == t.ok
	}
}

struct IPNetStringTest {
	have IPNet
	want string
}

const ip_net_string_tests = [
	IPNetStringTest{IPNet{ipv4(192, 168, 1, 0), cidr_mask(26, 32)}, '192.168.1.0/26'},
	IPNetStringTest{IPNet{ipv4(192, 168, 1, 0), ipv4_mask(255, 0, 255, 0)}, '192.168.1.0/ff00ff00'},
	IPNetStringTest{IPNet{parse_ip('2001:db8::'), cidr_mask(55, 128)}, '2001:db8::/55'},
	IPNetStringTest{IPNet{parse_ip('2001:db8::'), IPMask(parse_ip('8000:f123:0:cafe::'))}, '2001:db8::/8000f1230000cafe0000000000000000'},
]

fn test_ip_net_string() {
	for t in ip_net_string_tests {
		assert t.have.string() == t.want
	}
}

struct CIDRMaskTest {
	ones int
	bits int
	want IPMask
}

const cidr_mask_tests = [
	CIDRMaskTest{0, 32, ipv4_mask(0, 0, 0, 0)},
	CIDRMaskTest{12, 32, ipv4_mask(255, 240, 0, 0)},
	CIDRMaskTest{24, 32, ipv4_mask(255, 255, 255, 0)},
	CIDRMaskTest{32, 32, ipv4_mask(255, 255, 255, 255)},
	CIDRMaskTest{0, 128, IPMask([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])},
	CIDRMaskTest{4, 128, IPMask([u8(0xf0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])},
	CIDRMaskTest{48, 128, IPMask([u8(0xff), 0xff, 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0])},
	CIDRMaskTest{128, 128, IPMask([u8(0xff), 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff])},
	CIDRMaskTest{33, 32, ip_mask_nil},
	CIDRMaskTest{32, 33, ip_mask_nil},
	CIDRMaskTest{-1, 128, ip_mask_nil},
	CIDRMaskTest{128, -1, ip_mask_nil},
]

fn test_cidr_mask() {
	for t in cidr_mask_tests {
		assert cidr_mask(t.ones, t.bits) == t.want
	}
}

const (
	v4addr         = IP([u8(192), 168, 0, 1])
	v4mappedv6addr = IP([u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xff, 0xff, 192, 168, 0, 1])
	v6addr         = IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0, 0x1, 0x23, 0, 0x12, 0, 0x1])
	v4mask         = IPMask([u8(255), 255, 255, 0])
	v4mappedv6mask = IPMask([u8(0xff), 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 255, 255, 255, 0])
	v6mask         = IPMask([u8(0xff), 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0, 0,
		0, 0, 0])
	badaddr        = IP([u8(192), 168, 0])
	badmask        = IPMask([u8(255), 255, 0])
	v4maskzero     = IPMask([u8(0), 0, 0, 0])
)

struct NetworkNumberAndMaskTest {
	have IPNet
	want IPNet
}

const network_number_and_mask_tests = [
	NetworkNumberAndMaskTest{IPNet{v4addr, v4mask}, IPNet{v4addr, v4mask}},
	NetworkNumberAndMaskTest{IPNet{v4addr, v4mappedv6mask}, IPNet{v4addr, v4mask}},
	NetworkNumberAndMaskTest{IPNet{v4mappedv6addr, v4mappedv6mask}, IPNet{v4addr, v4mask}},
	NetworkNumberAndMaskTest{IPNet{v4mappedv6addr, v6mask}, IPNet{v4addr, v4maskzero}},
	NetworkNumberAndMaskTest{IPNet{v4addr, v6mask}, IPNet{v4addr, v4maskzero}},
	NetworkNumberAndMaskTest{IPNet{v6addr, v6mask}, IPNet{v6addr, v6mask}},
	NetworkNumberAndMaskTest{IPNet{v6addr, v4mappedv6mask}, IPNet{v6addr, v4mappedv6mask}},
	NetworkNumberAndMaskTest{IPNet{v6addr, v4mask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{v4addr, badmask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{v4mappedv6addr, badmask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{v6addr, badmask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{badaddr, v4mask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{badaddr, v4mappedv6mask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{badaddr, v6mask}, IPNet{}},
	NetworkNumberAndMaskTest{IPNet{badaddr, badmask}, IPNet{}},
]

fn test_network_number_and_mask() {
	for t in network_number_and_mask_tests {
		ip, m := network_number_and_mask(t.have)
		assert IPNet{ip, m} == t.want
	}
}

struct IPAddrFamilyTest {
	have IP
	af4  bool
	af6  bool
}

const ip_addr_family_tests = [
	IPAddrFamilyTest{ipv4_bcast, true, false},
	IPAddrFamilyTest{ipv4_allsys, true, false},
	IPAddrFamilyTest{ipv4_allrouter, true, false},
	IPAddrFamilyTest{ipv4_zero, true, false},
	IPAddrFamilyTest{ipv4(127, 0, 0, 1), true, false},
	IPAddrFamilyTest{ipv4(240, 0, 0, 1), true, false},
	IPAddrFamilyTest{ipv6_unspecified, false, true},
	IPAddrFamilyTest{ipv6_loopback, false, true},
	IPAddrFamilyTest{ipv6_interfacelocalallnodes, false, true},
	IPAddrFamilyTest{ipv6_linklocalallnodes, false, true},
	IPAddrFamilyTest{ipv6_linklocalallrouters, false, true},
	IPAddrFamilyTest{parse_ip('ff05::a:b:c:d'), false, true},
	IPAddrFamilyTest{parse_ip('fe80::1:2:3:4'), false, true},
	IPAddrFamilyTest{parse_ip('2001:db8::123:12:1'), false, true},
]

fn test_ip_addr_family() {
	for t in ip_addr_family_tests {
		af := t.have.to4().len
		assert t.have.to4().len > 0 == t.af4
		assert t.have.len == ipv6_len && t.have.to4().len == 0 == t.af6
	}
}

struct IPAddrScopeTest {
	scope string
	have  IP
	ok    bool
}

const ip_addr_scope_tests = [
	IPAddrScopeTest{'is_unspecified', ipv4_zero, true},
	IPAddrScopeTest{'is_unspecified', ipv4(127, 0, 0, 1), false},
	IPAddrScopeTest{'is_unspecified', ipv6_unspecified, true},
	IPAddrScopeTest{'is_unspecified', ipv6_interfacelocalallnodes, false},
	IPAddrScopeTest{'is_unspecified', ip_nil, false},
	IPAddrScopeTest{'is_loopback', ipv4(127, 0, 0, 1), true},
	IPAddrScopeTest{'is_loopback', ipv4(127, 255, 255, 254), true},
	IPAddrScopeTest{'is_loopback', ipv4(128, 1, 2, 3), false},
	IPAddrScopeTest{'is_loopback', ipv6_loopback, true},
	IPAddrScopeTest{'is_loopback', ipv6_linklocalallrouters, false},
	IPAddrScopeTest{'is_loopback', ip_nil, false},
	IPAddrScopeTest{'is_multicast', ipv4(224, 0, 0, 0), true},
	IPAddrScopeTest{'is_multicast', ipv4(239, 0, 0, 0), true},
	IPAddrScopeTest{'is_multicast', ipv4(240, 0, 0, 0), false},
	IPAddrScopeTest{'is_multicast', ipv6_linklocalallnodes, true},
	IPAddrScopeTest{'is_multicast', IP([u8(0xff), 0x05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0]), true},
	IPAddrScopeTest{'is_multicast', IP([u8(0xfe), 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0]), false},
	IPAddrScopeTest{'is_multicast', ip_nil, false},
	IPAddrScopeTest{'is_interface_local_multicast', ipv4(224, 0, 0, 0), false},
	IPAddrScopeTest{'is_interface_local_multicast', ipv4(0xff, 0x01, 0, 0), false},
	IPAddrScopeTest{'is_interface_local_multicast', ipv6_interfacelocalallnodes, true},
	IPAddrScopeTest{'is_interface_local_multicast', ip_nil, false},
	IPAddrScopeTest{'is_link_local_multicast', ipv4(224, 0, 0, 0), true},
	IPAddrScopeTest{'is_link_local_multicast', ipv4(239, 0, 0, 0), false},
	IPAddrScopeTest{'is_link_local_multicast', ipv4(0xff, 0x02, 0, 0), false},
	IPAddrScopeTest{'is_link_local_multicast', ipv6_interfacelocalallnodes, false},
	IPAddrScopeTest{'is_link_local_multicast', ip_nil, false},
	IPAddrScopeTest{'is_link_local_unicast', ipv4(169, 254, 0, 0), true},
	IPAddrScopeTest{'is_link_local_unicast', ipv4(169, 255, 0, 0), false},
	IPAddrScopeTest{'is_link_local_unicast', ipv4(0xfe, 0x80, 0, 0), false},
	IPAddrScopeTest{'is_link_local_unicast', IP([u8(0xfe), 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0]), true},
	IPAddrScopeTest{'is_link_local_unicast', IP([u8(0xfe), 0xc0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0]), false},
	IPAddrScopeTest{'is_link_local_unicast', ip_nil, false},
	IPAddrScopeTest{'is_global_unicast', ipv4(240, 0, 0, 0), true},
	IPAddrScopeTest{'is_global_unicast', ipv4(232, 0, 0, 0), false},
	IPAddrScopeTest{'is_global_unicast', ipv4(169, 254, 0, 0), false},
	IPAddrScopeTest{'is_global_unicast', ipv4_bcast, false},
	IPAddrScopeTest{'is_global_unicast', IP([u8(0x20), 0x1, 0xd, 0xb8, 0, 0, 0, 0, 0, 0, 0x1, 0x23,
		0, 0x12, 0, 0x1]), true},
	IPAddrScopeTest{'is_global_unicast', IP([u8(0xfe), 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0]), false},
	IPAddrScopeTest{'is_global_unicast', IP([u8(0xff), 0x05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0]), false},
	IPAddrScopeTest{'is_global_unicast', ip_nil, false},
	IPAddrScopeTest{'is_private', ip_nil, false},
	IPAddrScopeTest{'is_private', ipv4(1, 1, 1, 1), false},
	IPAddrScopeTest{'is_private', ipv4(9, 255, 255, 255), false},
	IPAddrScopeTest{'is_private', ipv4(10, 0, 0, 0), true},
	IPAddrScopeTest{'is_private', ipv4(10, 255, 255, 255), true},
	IPAddrScopeTest{'is_private', ipv4(11, 0, 0, 0), false},
	IPAddrScopeTest{'is_private', ipv4(172, 15, 255, 255), false},
	IPAddrScopeTest{'is_private', ipv4(172, 16, 0, 0), true},
	IPAddrScopeTest{'is_private', ipv4(172, 16, 255, 255), true},
	IPAddrScopeTest{'is_private', ipv4(172, 23, 18, 255), true},
	IPAddrScopeTest{'is_private', ipv4(172, 31, 255, 255), true},
	IPAddrScopeTest{'is_private', ipv4(172, 31, 0, 0), true},
	IPAddrScopeTest{'is_private', ipv4(172, 32, 0, 0), false},
	IPAddrScopeTest{'is_private', ipv4(192, 167, 255, 255), false},
	IPAddrScopeTest{'is_private', ipv4(192, 168, 0, 0), true},
	IPAddrScopeTest{'is_private', ipv4(192, 168, 255, 255), true},
	IPAddrScopeTest{'is_private', ipv4(192, 169, 0, 0), false},
	IPAddrScopeTest{'is_private', IP([u8(0xfb), 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]), false},
	IPAddrScopeTest{'is_private', IP([u8(0xfc), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), true},
	IPAddrScopeTest{'is_private', IP([u8(0xfc), 0xff, 0x12, 0, 0, 0, 0, 0x44, 0, 0, 0, 0, 0, 0,
		0, 0]), true},
	IPAddrScopeTest{'is_private', IP([u8(0xfd), 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]), true},
	IPAddrScopeTest{'is_private', IP([u8(0xfe), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), false},
]

fn test_ip_addr_scope() {
	for t in ip_addr_scope_tests {
		match t.scope {
			'is_unspecified' {
				assert t.have.is_unspecified() == t.ok
			}
			'is_loopback' {
				assert t.have.is_loopback() == t.ok
			}
			'is_multicast' {
				assert t.have.is_multicast() == t.ok
			}
			'is_interface_local_multicast' {
				assert t.have.is_interface_local_multicast() == t.ok
			}
			'is_link_local_multicast' {
				assert t.have.is_link_local_multicast() == t.ok
			}
			'is_link_local_unicast' {
				assert t.have.is_link_local_unicast() == t.ok
			}
			'is_global_unicast' {
				assert t.have.is_global_unicast() == t.ok
			}
			'is_private' {
				assert t.have.is_private() == t.ok
			}
			else {
				panic('unknown scope')
			}
		}
	}
}
