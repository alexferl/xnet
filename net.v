module xnet

// A ParseError is the error type of literal network address parsers.
pub struct ParseError {
	// type is the type of string that was expected, such as
	// "IP address", "CIDR address".
	@type string
	// text is the malformed text string.
	text string
}

fn (e ParseError) error() string {
	return 'invalid ' + e.@type + ': ' + e.text
}
