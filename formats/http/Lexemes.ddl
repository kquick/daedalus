-- See: https://www.rfc-editor.org/rfc/rfc5234#appendix-B.1

def $alpha 	= 0x41 .. 0x5A | 0x61 .. 0x7A | 'A' .. 'Z' | 'a' .. 'z'
def $digit 	= '0' .. '9'
def $hexdig	= $digit | 'A' .. 'F' | 'a' .. 'f'

def $dquote	= '"'
def $sp		= 0x32
def $vchar      = 0x21 .. 0x7E
def $obs_text   = 0x80 .. 0xFF
def $octet      = $any

def $htab       = 0x09
def $ctl   	= 0x00 .. 0x1f | 0x7F
def $cr	   	= 0x0D
def $lf	   	= 0x0A
def CRLF   	= @{ $cr; $lf }


-- Convert a known textual base 10 digit to its numeric value
def Decimal x = x - '0' : uint 8

-- Base 10 digit, in its numerical value (e.g., '1' -> 1)
def DigitNum = Decimal $digit

-- Base 16 digit, in its numerical value (e.g., 'b' -> 11)
def HexDigNum =
  First
    DigitNum
    10 + $['a' .. 'f'] - 'a'
    10 + $['A' .. 'F'] - 'A'
