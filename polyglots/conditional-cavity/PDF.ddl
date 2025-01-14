{-|
  Name: PDF

  Description: This file contains a Daedalus description Java's conditional
  cavity characteristics.

  Maintainer     : Cole Schlesinger <coles@galois.com>
  Stability      : provisional
-}

-- We use an unreferenced string object to create a cavity in PDF.
-- Constraints: cavity cannot contain unescaped unbalanced parentheses.

def PDFCavityStartDelimiter = Match "9999 0 obj ("
def PDFCavityEndDelimiter   = Match ") endobj"

def PDFContent = Match [
 0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x33,  0x0a, 0x25, 0xc2, 0xb5, 0xc2, 0xb6, 0x0a, 0x0a,
 0x31, 0x20, 0x30, 0x20, 0x6f, 0x62, 0x6a, 0x0a,  0x3c, 0x3c, 0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f,
 0x43, 0x61, 0x74, 0x61, 0x6c, 0x6f, 0x67, 0x2f,  0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20,
 0x30, 0x20, 0x52, 0x3e, 0x3e, 0x0a, 0x65, 0x6e,  0x64, 0x6f, 0x62, 0x6a, 0x0a, 0x0a, 0x32, 0x20,
 0x30, 0x20, 0x6f, 0x62, 0x6a, 0x0a, 0x3c, 0x3c,  0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f, 0x50, 0x61,
 0x67, 0x65, 0x73, 0x2f, 0x43, 0x6f, 0x75, 0x6e,  0x74, 0x20, 0x31, 0x2f, 0x4b, 0x69, 0x64, 0x73,
 0x5b, 0x33, 0x20, 0x30, 0x20, 0x52, 0x5d, 0x3e,  0x3e, 0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a,
 0x0a, 0x0a, 0x33, 0x20, 0x30, 0x20, 0x6f, 0x62,  0x6a, 0x0a, 0x3c, 0x3c, 0x2f, 0x54, 0x79, 0x70,
 0x65, 0x2f, 0x50, 0x61, 0x67, 0x65, 0x2f, 0x43,  0x6f, 0x6e, 0x74, 0x65, 0x6e, 0x74, 0x73, 0x20,
 0x34, 0x20, 0x30, 0x20, 0x52, 0x2f, 0x50, 0x61,  0x72, 0x65, 0x6e, 0x74, 0x20, 0x32, 0x20, 0x30,
 0x20, 0x52, 0x2f, 0x52, 0x65, 0x73, 0x6f, 0x75,  0x72, 0x63, 0x65, 0x73, 0x3c, 0x3c, 0x2f, 0x46,
 0x6f, 0x6e, 0x74, 0x3c, 0x3c, 0x2f, 0x46, 0x3c,  0x3c, 0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f, 0x46,
 0x6f, 0x6e, 0x74, 0x2f, 0x53, 0x75, 0x62, 0x74,  0x79, 0x70, 0x65, 0x2f, 0x54, 0x79, 0x70, 0x65,
 0x31, 0x2f, 0x42, 0x61, 0x73, 0x65, 0x46, 0x6f,  0x6e, 0x74, 0x2f, 0x41, 0x72, 0x69, 0x61, 0x6c,
 0x3e, 0x3e, 0x3e, 0x3e, 0x3e, 0x3e, 0x3e, 0x3e,  0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a, 0x0a,
 0x0a, 0x34, 0x20, 0x30, 0x20, 0x6f, 0x62, 0x6a,  0x0a, 0x3c, 0x3c, 0x2f, 0x4c, 0x65, 0x6e, 0x67,
 0x74, 0x68, 0x20, 0x33, 0x31, 0x3e, 0x3e, 0x0a,  0x73, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x0a, 0x42,
 0x54, 0x2f, 0x46, 0x20, 0x32, 0x37, 0x30, 0x20,  0x54, 0x66, 0x20, 0x33, 0x30, 0x20, 0x33, 0x30,
 0x30, 0x20, 0x54, 0x64, 0x28, 0x50, 0x44, 0x46,  0x29, 0x27, 0x20, 0x45, 0x54, 0x0a, 0x0a, 0x65,
 0x6e, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6d,  0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a, 0x0a,
 0x0a, 0x78, 0x72, 0x65, 0x66, 0x0a, 0x30, 0x20,  0x35, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
 0x30, 0x30, 0x30, 0x30, 0x20, 0x36, 0x35, 0x35,  0x33, 0x36, 0x20, 0x66, 0x20, 0x0a, 0x30, 0x30,
 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x36,  0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6e,
 0x20, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,  0x30, 0x30, 0x36, 0x32, 0x20, 0x30, 0x30, 0x30,
 0x30, 0x30, 0x20, 0x6e, 0x20, 0x0a, 0x30, 0x30,  0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x31, 0x34,
 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6e,  0x20, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
 0x30, 0x32, 0x34, 0x31, 0x20, 0x30, 0x30, 0x30,  0x30, 0x30, 0x20, 0x6e, 0x20, 0x0a, 0x0a, 0x74,
 0x72, 0x61, 0x69, 0x6c, 0x65, 0x72, 0x0a, 0x3c,  0x3c, 0x2f, 0x53, 0x69, 0x7a, 0x65, 0x20, 0x35,
 0x2f, 0x52, 0x6f, 0x6f, 0x74, 0x20, 0x31, 0x20,  0x30, 0x20, 0x52, 0x3e, 0x3e, 0x0a, 0x73, 0x74,
 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0a,  0x33, 0x32, 0x31, 0x0a, 0x25, 0x25, 0x45, 0x4f,
 0x46, 0x0a,               
]
