module xnet

fn split_host_zone(s string) (string, string) {
	// The IPv6 scoped addressing zone identifier starts after the
	// last percent sign.
	mut host := ''
	mut zone := ''
	i := last(s, `%`)
	if i > 0 {
		host, zone = s[..i], s[i + 1..]
	} else {
		host = s
	}
	return host, zone
}
