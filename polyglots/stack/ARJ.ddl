{-|
  Name: ARJ
  Description: This file contains a Daedalus description of the contents of
  a ARJ file for Talos to generate.  Use `Match [...]` to force Talos to
  produce a specific ARJ file.
  Maintainer     : Cole Schlesinger <coles@galois.com>
  Stability      : provisional
-}

def ARJContents = Match [
0x60, 0xea, 0x2b, 0x00, 0x22, 0x0b, 0x01, 0x0b, 0x10, 0x00, 0x02, 0x03, 0x03, 0x5d, 0xfb, 0x50,
0x0c, 0x5d, 0xfb, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x72, 0x6a, 0x2e, 0x61, 0x72, 0x6a, 0x00, 0x00, 0xf3,
0xd2, 0xf8, 0x3b, 0x00, 0x00, 0x60, 0xea, 0x37, 0x00, 0x2e, 0x0b, 0x01, 0x0b, 0x10, 0x00, 0x00,
0x0c, 0x0c, 0x5d, 0xfb, 0x50, 0x03, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0xbd, 0xa9, 0x9d,
0x90, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x5d, 0xfb, 0x50, 0xfb,
0x5c, 0xfb, 0x50, 0x00, 0x00, 0x00, 0x00, 0x61, 0x72, 0x6a, 0x2e, 0x74, 0x78, 0x74, 0x00, 0x00,
0x01, 0xae, 0x16, 0xd5, 0x00, 0x00, 0x41, 0x52, 0x4a, 0x60, 0xea, 0x00, 0x00,   
]
