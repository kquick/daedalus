import Map
import Stdlib

import Glyph

def winEncodings = [
  mapEntry (octalTriple 1 0 1) (glyph "A")
, mapEntry (octalTriple 3 0 6) (glyph "AE")
, mapEntry (octalTriple 3 0 1) (glyph "Aacute")
, mapEntry (octalTriple 3 0 2) (glyph "Acircumflex")
, mapEntry (octalTriple 3 0 4) (glyph "Adieresis")
, mapEntry (octalTriple 3 0 0) (glyph "Agrave")
, mapEntry (octalTriple 3 0 5) (glyph "Aring")
, mapEntry (octalTriple 3 0 3) (glyph "Atilde")
, mapEntry (octalTriple 1 0 2) (glyph "B")
, mapEntry (octalTriple 1 0 3) (glyph "C")
, mapEntry (octalTriple 3 0 7) (glyph "Ccedilla")
, mapEntry (octalTriple 1 0 4) (glyph "D")
, mapEntry (octalTriple 1 0 5) (glyph "E")
, mapEntry (octalTriple 3 1 1) (glyph "Eacute")
, mapEntry (octalTriple 3 1 2) (glyph "Ecircumflex")
, mapEntry (octalTriple 3 1 3) (glyph "Edieresis")
, mapEntry (octalTriple 3 1 0) (glyph "Egrave")
, mapEntry (octalTriple 3 2 0) (glyph "Eth")
, mapEntry (octalTriple 2 0 0) (glyph "Euro")
, mapEntry (octalTriple 1 0 6) (glyph "F")
, mapEntry (octalTriple 1 0 7) (glyph "G")
, mapEntry (octalTriple 1 1 0) (glyph "H")
, mapEntry (octalTriple 1 1 1) (glyph "I")
, mapEntry (octalTriple 3 1 5) (glyph "Iacute")
, mapEntry (octalTriple 3 1 6) (glyph "Icircumflex")
, mapEntry (octalTriple 3 1 7) (glyph "Idieresis")
, mapEntry (octalTriple 3 1 4) (glyph "Igrave")
, mapEntry (octalTriple 1 1 2) (glyph "J")
, mapEntry (octalTriple 1 1 3) (glyph "K")
, mapEntry (octalTriple 1 1 4) (glyph "L")
, mapEntry (octalTriple 1 1 5) (glyph "M")
, mapEntry (octalTriple 1 1 6) (glyph "N")
, mapEntry (octalTriple 3 2 1) (glyph "Ntilde")
, mapEntry (octalTriple 1 1 7) (glyph "O")
, mapEntry (octalTriple 2 1 4) (glyph "OE")
, mapEntry (octalTriple 3 2 3) (glyph "Oacute")
, mapEntry (octalTriple 3 2 4) (glyph "Ocircumflex")
, mapEntry (octalTriple 3 2 6) (glyph "Odieresis")
, mapEntry (octalTriple 3 2 2) (glyph "Ograve")
, mapEntry (octalTriple 3 3 0) (glyph "Oslash")
, mapEntry (octalTriple 3 2 5) (glyph "Otilde")
, mapEntry (octalTriple 1 2 0) (glyph "P")
, mapEntry (octalTriple 1 2 1) (glyph "Q")
, mapEntry (octalTriple 1 2 2) (glyph "R")
, mapEntry (octalTriple 1 2 3) (glyph "S")
, mapEntry (octalTriple 2 1 2) (glyph "Scaron")
, mapEntry (octalTriple 1 2 4) (glyph "T")
, mapEntry (octalTriple 3 3 6) (glyph "Thorn")
, mapEntry (octalTriple 1 2 5) (glyph "U")
, mapEntry (octalTriple 3 3 2) (glyph "Uacute")
, mapEntry (octalTriple 3 3 3) (glyph "Ucircumflex")
, mapEntry (octalTriple 3 3 4) (glyph "Udieresis")
, mapEntry (octalTriple 3 3 1) (glyph "Ugrave")
, mapEntry (octalTriple 1 2 6) (glyph "V")
, mapEntry (octalTriple 1 2 7) (glyph "W")
, mapEntry (octalTriple 1 3 0) (glyph "X")
, mapEntry (octalTriple 1 3 1) (glyph "Y")
, mapEntry (octalTriple 3 3 5) (glyph "Yacute")
, mapEntry (octalTriple 2 3 7) (glyph "Ydieresis")
, mapEntry (octalTriple 1 3 2) (glyph "Z")
, mapEntry (octalTriple 2 1 6) (glyph "Zcaron")
, mapEntry (octalTriple 1 4 1) (glyph "a")
, mapEntry (octalTriple 3 4 1) (glyph "aacute")
, mapEntry (octalTriple 3 4 2) (glyph "acircumflex")
, mapEntry (octalTriple 2 6 4) (glyph "acute")
, mapEntry (octalTriple 3 4 4) (glyph "adieresis")
, mapEntry (octalTriple 3 4 6) (glyph "ae")
, mapEntry (octalTriple 3 4 0) (glyph "agrave")
, mapEntry (octalTriple 0 4 6) (glyph "ampersand")
, mapEntry (octalTriple 3 4 5) (glyph "aring")
, mapEntry (octalTriple 1 3 6) (glyph "asciicircum")
, mapEntry (octalTriple 1 7 6) (glyph "asciitilde")
, mapEntry (octalTriple 0 5 2) (glyph "asterisk")
, mapEntry (octalTriple 1 0 0) (glyph "at")
, mapEntry (octalTriple 3 4 3) (glyph "atilde")
, mapEntry (octalTriple 1 4 2) (glyph "b")
, mapEntry (octalTriple 1 3 4) (glyph "backslash")
, mapEntry (octalTriple 1 7 4) (glyph "bar")
, mapEntry (octalTriple 1 7 3) (glyph "braceleft")
, mapEntry (octalTriple 1 7 5) (glyph "braceright")
, mapEntry (octalTriple 1 3 3) (glyph "bracketleft")
, mapEntry (octalTriple 1 3 5) (glyph "bracketright")
, mapEntry (octalTriple 2 4 6) (glyph "brokenbar")
, mapEntry (octalTriple 2 2 5) (glyph "bullet")
, mapEntry (octalTriple 1 4 3) (glyph "c")
, mapEntry (octalTriple 3 4 7) (glyph "ccedilla")
, mapEntry (octalTriple 2 7 0) (glyph "cedilla")
, mapEntry (octalTriple 2 4 2) (glyph "cent")
, mapEntry (octalTriple 2 1 0) (glyph "circumflex")
, mapEntry (octalTriple 0 7 2) (glyph "colon")
, mapEntry (octalTriple 0 5 4) (glyph "comma")
, mapEntry (octalTriple 2 5 1) (glyph "copyright")
, mapEntry (octalTriple 2 4 4) (glyph "currency")
, mapEntry (octalTriple 1 4 4) (glyph "d")
, mapEntry (octalTriple 2 0 6) (glyph "dagger")
, mapEntry (octalTriple 2 0 7) (glyph "daggerdbl")
, mapEntry (octalTriple 2 6 0) (glyph "degree")
, mapEntry (octalTriple 2 5 0) (glyph "dieresis")
, mapEntry (octalTriple 3 6 7) (glyph "divide")
, mapEntry (octalTriple 0 4 4) (glyph "dollar")
, mapEntry (octalTriple 1 4 5) (glyph "e")
, mapEntry (octalTriple 3 5 1) (glyph "eacute")
, mapEntry (octalTriple 3 5 2) (glyph "ecircumflex")
, mapEntry (octalTriple 3 5 3) (glyph "edieresis")
, mapEntry (octalTriple 3 5 0) (glyph "egrave")
, mapEntry (octalTriple 0 7 0) (glyph "eight")
, mapEntry (octalTriple 2 0 5) (glyph "ellipsis")
, mapEntry (octalTriple 2 2 7) (glyph "emdash")
, mapEntry (octalTriple 2 2 6) (glyph "endash")
, mapEntry (octalTriple 0 7 5) (glyph "equal")
, mapEntry (octalTriple 3 6 0) (glyph "eth")
, mapEntry (octalTriple 0 4 1) (glyph "exclam")
, mapEntry (octalTriple 2 4 1) (glyph "exclamdown")
, mapEntry (octalTriple 1 4 6) (glyph "f")
, mapEntry (octalTriple 0 6 5) (glyph "five")
, mapEntry (octalTriple 2 0 3) (glyph "florin")
, mapEntry (octalTriple 0 6 4) (glyph "four")
, mapEntry (octalTriple 1 4 7) (glyph "g")
, mapEntry (octalTriple 3 3 7) (glyph "germandbls")
, mapEntry (octalTriple 1 4 0) (glyph "grave")
, mapEntry (octalTriple 0 7 6) (glyph "greater")
, mapEntry (octalTriple 2 5 3) (glyph "guillemotleft")
, mapEntry (octalTriple 2 7 3) (glyph "guillemotright")
, mapEntry (octalTriple 2 1 3) (glyph "guilsinglleft")
, mapEntry (octalTriple 2 3 3) (glyph "guilsinglright")
, mapEntry (octalTriple 1 5 0) (glyph "h")
, mapEntry (octalTriple 0 5 5) (glyph "hyphen")
, mapEntry (octalTriple 1 5 1) (glyph "i")
, mapEntry (octalTriple 3 5 5) (glyph "iacute")
, mapEntry (octalTriple 3 5 6) (glyph "icircumflex")
, mapEntry (octalTriple 3 5 7) (glyph "idieresis")
, mapEntry (octalTriple 3 5 4) (glyph "igrave")
, mapEntry (octalTriple 1 5 2) (glyph "j")
, mapEntry (octalTriple 1 5 3) (glyph "k")
, mapEntry (octalTriple 1 5 4) (glyph "l")
, mapEntry (octalTriple 0 7 4) (glyph "less")
, mapEntry (octalTriple 2 5 4) (glyph "logicalnot")
, mapEntry (octalTriple 1 5 5) (glyph "m")
, mapEntry (octalTriple 2 5 7) (glyph "macron")
, mapEntry (octalTriple 2 6 5) (glyph "mu")
, mapEntry (octalTriple 3 2 7) (glyph "multiply")
, mapEntry (octalTriple 1 5 6) (glyph "n")
, mapEntry (octalTriple 0 7 1) (glyph "nine")
, mapEntry (octalTriple 3 6 1) (glyph "ntilde")
, mapEntry (octalTriple 0 4 3) (glyph "numbersign")
, mapEntry (octalTriple 1 5 7) (glyph "o")
, mapEntry (octalTriple 3 6 3) (glyph "oacute")
, mapEntry (octalTriple 3 6 4) (glyph "ocircumflex")
, mapEntry (octalTriple 3 6 6) (glyph "odieresis")
, mapEntry (octalTriple 2 3 4) (glyph "oe")
, mapEntry (octalTriple 3 6 2) (glyph "ograve")
, mapEntry (octalTriple 0 6 1) (glyph "one")
, mapEntry (octalTriple 2 7 5) (glyph "onehalf")
, mapEntry (octalTriple 2 7 4) (glyph "onequarter")
, mapEntry (octalTriple 2 7 1) (glyph "onesuperior")
, mapEntry (octalTriple 2 5 2) (glyph "ordfeminine")
, mapEntry (octalTriple 2 7 2) (glyph "ordmasculine")
, mapEntry (octalTriple 3 7 0) (glyph "oslash")
, mapEntry (octalTriple 3 6 5) (glyph "otilde")
, mapEntry (octalTriple 1 6 0) (glyph "p")
, mapEntry (octalTriple 2 6 6) (glyph "paragraph")
, mapEntry (octalTriple 0 5 0) (glyph "parenleft")
, mapEntry (octalTriple 0 5 1) (glyph "parenright")
, mapEntry (octalTriple 0 4 5) (glyph "percent")
, mapEntry (octalTriple 0 5 6) (glyph "period")
, mapEntry (octalTriple 2 6 7) (glyph "periodcentered")
, mapEntry (octalTriple 2 1 1) (glyph "perthousand")
, mapEntry (octalTriple 0 5 3) (glyph "plus")
, mapEntry (octalTriple 2 6 1) (glyph "plusminus")
, mapEntry (octalTriple 1 6 1) (glyph "q")
, mapEntry (octalTriple 0 7 7) (glyph "question")
, mapEntry (octalTriple 2 7 7) (glyph "questiondown")
, mapEntry (octalTriple 0 4 2) (glyph "quotedbl")
, mapEntry (octalTriple 2 0 4) (glyph "quotedblbase")
, mapEntry (octalTriple 2 2 3) (glyph "quotedblleft")
, mapEntry (octalTriple 2 2 4) (glyph "quotedblright")
, mapEntry (octalTriple 2 2 1) (glyph "quoteleft")
, mapEntry (octalTriple 2 2 2) (glyph "quoteright")
, mapEntry (octalTriple 2 0 2) (glyph "quotesinglbase")
, mapEntry (octalTriple 0 4 7) (glyph "quotesingle")
, mapEntry (octalTriple 1 6 2) (glyph "r")
, mapEntry (octalTriple 2 5 6) (glyph "registered")
, mapEntry (octalTriple 1 6 3) (glyph "s")
, mapEntry (octalTriple 2 3 2) (glyph "scaron")
, mapEntry (octalTriple 2 4 7) (glyph "section")
, mapEntry (octalTriple 0 7 3) (glyph "semicolon")
, mapEntry (octalTriple 0 6 7) (glyph "seven")
, mapEntry (octalTriple 0 6 6) (glyph "six")
, mapEntry (octalTriple 0 5 7) (glyph "slash")
, mapEntry (octalTriple 0 4 0) (glyph "space")
, mapEntry (octalTriple 2 4 3) (glyph "sterling")
, mapEntry (octalTriple 1 6 4) (glyph "t")
, mapEntry (octalTriple 3 7 6) (glyph "thorn")
, mapEntry (octalTriple 0 6 3) (glyph "three")
, mapEntry (octalTriple 2 7 6) (glyph "threequarters")
, mapEntry (octalTriple 2 6 3) (glyph "threesuperior")
, mapEntry (octalTriple 2 3 0) (glyph "tilde")
, mapEntry (octalTriple 2 3 1) (glyph "trademark")
, mapEntry (octalTriple 0 6 2) (glyph "two")
, mapEntry (octalTriple 2 6 2) (glyph "twosuperior")
, mapEntry (octalTriple 1 6 5) (glyph "u")
, mapEntry (octalTriple 3 7 2) (glyph "uacute")
, mapEntry (octalTriple 3 7 3) (glyph "ucircumflex")
, mapEntry (octalTriple 3 7 4) (glyph "udieresis")
, mapEntry (octalTriple 3 7 1) (glyph "ugrave")
, mapEntry (octalTriple 1 3 7) (glyph "underscore")
, mapEntry (octalTriple 1 6 6) (glyph "v")
, mapEntry (octalTriple 1 6 7) (glyph "w")
, mapEntry (octalTriple 1 7 0) (glyph "x")
, mapEntry (octalTriple 1 7 1) (glyph "y")
, mapEntry (octalTriple 3 7 5) (glyph "yacute")
, mapEntry (octalTriple 3 7 7) (glyph "ydieresis")
, mapEntry (octalTriple 2 4 5) (glyph "yen")
, mapEntry (octalTriple 1 7 2) (glyph "z")
, mapEntry (octalTriple 2 3 6) (glyph "zcaron")
, mapEntry (octalTriple 0 6 0) (glyph "zero")
]

def WinEncoding : [ uint 8 -> glyph ] = ListToMap winEncodings
