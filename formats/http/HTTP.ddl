-- HTTP 1.1
-- Reference: https://datatracker.ietf.org/doc/html/rfc9112#appendix-A

import Utils
import Lexemes
import URI

-- ENTRY
def HTTP_request = HTTP_message HTTP_request_line

-- ENTRY
def HTTP_status  = HTTP_message HTTP_status_line

def HTTP_message StartLine =
  block
    start = StartLine
    CRLF
    fields = Many { $$ = HTTP_field_line; CRLF }
    CRLF
    let ty = HTTP_body_type fields
    body = HTTP_message_body ty

-- The types of HTTP message bodies.
def HTTP_body_type_u =
  union
    -- The body is transfer-encoded 'chunked'
    chunked: { }
    -- The body is a byte sequence of the specified length
    normal_len: uint 64
    -- The body is of indeterminate length and should be consumed until
    -- the connection is closed (i.e. until the input is exhausted)
    read_all: { }

-- Given a list of fields (headers), determine the message body type:
--
-- If the Transfer-Encoding header is present and includes 'chunked'
-- as its last entry, the body type is chunked and should be parsed
-- accordingly. If the Transfer-Encoding header is absent and the
-- Content-Length header is present, then the body should be treated as
-- an octet sequence of length specified by Content-Length. Otherwise
-- the body is of indeterminate length.
--
-- NOTE: for responses, a missing explicitly-specified length and
-- a missing last 'chunked' entry in the encoding list indicates
-- that the length is obtained by receiving all octets until the
-- connection is closed. This does not account for that case yet, and
-- will need to account for it once we support parsing responses. (See
-- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.8)
def HTTP_body_type (fields : [HTTP_field_line]): HTTP_body_type_u =
  block
    -- If neither Content-Length nor Transfer-Encoding is present, the
    -- length is assumed to be exactly zero, thus the initialization for
    -- this loop starts with normal_len.
    for (result = {| normal_len = 0 |}; f in fields)
      case f: HTTP_field_line of
        Header _ -> ^ result

        Content_Length h ->
          case result of
            -- Chunked encoding takes precedence over Content-Length, so
            -- only store the length in the result if we haven't already
            -- found a chunked encoding header.
            --
            -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.4.1
            chunked _ -> ^ result

            -- The read_all case means we found a Transfer-Encoding
            -- header that didn't have 'chunked' as its last entry, in
            -- which case we are required to consume all of the data
            -- found after the request headers and will ignore the
            -- Content-Length header.
            --
            -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.4.2
            read_all -> ^ result

            -- If a valid Content-Length header field is present without
            -- Transfer-Encoding, its decimal value defines the expected
            -- message body length in octets.
            --
            -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.6
            normal_len _ -> ^ {| normal_len = h.value |}

        Transfer_Encoding h ->
          block
            if h.chunked
              then ^ {| chunked |}
              -- Otherwise, if Transfer-Encoding is specified and
              -- 'chunked' is not its last entry, then the message
              -- length is indeterminate.
              --
              -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.7
              else ^ {| read_all |}

def HTTP_message_chunked_s =
  struct
    chunks: [BodyChunk]
    trailer_fields: [HTTP_field_line]

def HTTP_message_body_u =
  union
    -- The chunks parsed from the body.
    chunked: HTTP_message_chunked_s

    -- The array of bytes containing the body.
    bytes: [uint 8]

    -- The stream containing the body.
    remaining: stream

-- Parse an HTTP message body based on the specified body type. See
-- BodyChunk for relevant ABNF.
def HTTP_message_body (ty: HTTP_body_type_u): HTTP_message_body_u =
  case ty of
    chunked ->
      block
        -- content chunks:
        let chunks = Many BodyChunk

        -- last-chunk:
        Many (1..) $['0']; CRLF

        -- trailer fields:
        let trailer_fields = Many { $$ = HTTP_field_line; CRLF }

        -- Final required CRLF
        CRLF

        ^ {| chunked = { chunks = chunks, trailer_fields = trailer_fields } |}

    normal_len len ->
      block
        let body = Many len $any
        ^ {| bytes = body |}

    read_all ->
      block
        let s = GetStream
        ^ {| remaining = s |}

-- Parse a single chunk in a message body that has Transfer-Encoding:
-- chunked.
--
-- Relevant ABNF for chunked encoding:
--
-- chunked-body   = *chunk
--                  last-chunk
--                  trailer-section
--                  CRLF
--
-- chunk          = chunk-size [ chunk-ext ] CRLF
--                  chunk-data CRLF
-- chunk-size     = 1*HEXDIG
-- last-chunk     = 1*("0") [ chunk-ext ] CRLF
--
-- chunk-data     = 1*OCTET ; a sequence of chunk-size octets
-- chunk-ext      = *( BWS ";" BWS chunk-ext-name
--                     [ BWS "=" BWS chunk-ext-val ] )
--
-- chunk-ext-name = token
-- chunk-ext-val  = token / quoted-string
def BodyChunk =
  block
    size = ChunkSize
    extensions = Many ChunkExtension
    CRLF

    -- We forbid zero-sized chunks here because parsing the last chunk
    -- is slightly different and is done above in HTTP_message_body. The
    -- zero-sized last chunk also ends in a CRLF, but the difference
    -- between a zero-sized last chunk and a preceding chunk is that the
    -- last chunk has an optional list of headers in between the size
    -- and the CRLF.
    size > 0 is true

    contents = Many size $any
    CRLF

-- Parse a chunk extension.
--
-- https://www.rfc-editor.org/rfc/rfc9112#section-7.1.1
def ChunkExtension =
  block
    HTTP_OWS
    $[';']
    HTTP_OWS
    name = HTTP_token
    value =
      Optional block
        HTTP_OWS
        $['=']
        HTTP_OWS
        First
          Token = HTTP_token
          QuotedString = HTTP_quoted_string

-- Parse a chunked body chunk size.
def ChunkSize = HexNumber

def HTTP_version =
  block
    Match "HTTP/"
    major = DigitNum
    $['.']
    minor = DigitNum

def HTTP_status_line =
  block
    version = HTTP_version
    $sp
    status_code = Many 3 DigitNum
    $sp
    reason = Many $[ $htab | $sp | $vchar | $obs_text ]

def HTTP_request_line =
  block
    method = HTTP_method
    $sp
    target = HTTP_request_target
    $sp
    version = HTTP_version

def HTTP_request_target =
  First
    AbsoluteURI = URI_absolute_URI        -- old style and for proxies
    Origin      = HTTP_origin_form        -- normal request

    -- NOTE: should the following two cases be factored out and used
    -- only when the request method is the appropriate method?
    Authority   = HTTP_authority_form     -- only in CONNECT
    Asterisk    = @$['*']                 -- only in OPTIONS

def HTTP_authority_form =
  block
    host  = URI_host
    $[':']
    port  = Many DigitNum

def HTTP_origin_form =
  block
    path  = Many (1..) { $['/']; URI_segment }
    query = Optional { $['?']; URI_query }

def HTTP_method =
  First
    GET     = @Match "GET"
    HEAD    = @Match "HEAD"
    POST    = @Match "POST"
    PUT     = @Match "PUT"
    DELETE  = @Match "DELETE"
    CONNECT = @Match "CONNECT"
    OPTIONS = @Match "OPTIONS"
    TRACE   = @Match "TRACE"

--------------------------------------------------------------------------------
-- Field (Header) parsing
--------------------------------------------------------------------------------

def Field_name =
  block
    -- Header names must start with an ASCII letter and can include
    -- letters, digits, or '-' characters.
    let head = CaseInsensitiveAlpha
    let tail = Many
                 First
                   CaseInsensitiveAlpha
                   $['-']
                   $digit

    build (emitArray (emit builder head) tail)

-- Given a parser P and a separator parser Sep, parse and return a
-- sequence of one or more instances of P separated by Sep.
def SepBy1 P Sep =
  block
    let a = many (buf = emit builder P) { Sep; let next = P; emit buf next }
    build a

-- ABNF:
-- Transfer-Encoding = [ transfer-coding *( OWS "," OWS transfer-coding ) ]
def Transfer_Encoding_List =
  SepBy1 Transfer_coding_entry { HTTP_OWS; $[',']; HTTP_OWS }

-- ABNF:
-- transfer-coding    = token *( OWS ";" OWS transfer-parameter )
def Transfer_coding_entry =
  block
    -- Coding names are case-insensitive, despite the ABNF using 'token'
    -- as is used elsewhere, so we use the case-insensitive normalizing
    -- token parser here instead.
    --
    -- https://www.rfc-editor.org/rfc/rfc9112#section-7-2
    type = HTTP_token_ci
    params = Many
      block
        HTTP_OWS
        $[';']
        HTTP_OWS
        Transfer_parameter

-- ABNF:
-- transfer-parameter = token BWS "=" BWS ( token / quoted-string )
def Transfer_parameter =
  block
    name = HTTP_token
    HTTP_OWS
    $['=']
    HTTP_OWS
    value = First
      Token = HTTP_token
      QuotedString = HTTP_quoted_string

-- Parse an HTTP header. We specifically parse Content-Length and
-- Transfer-Encoding for use elsewhere in the parser; all other headers
-- are represented as Header { ... }.
def HTTP_field_line =
  block
    let field_name = Field_name
    $[':']
    HTTP_OWS

    First
      Transfer_Encoding =
        block
          (field_name == "transfer-encoding") is true
          commit

          let encodings = Transfer_Encoding_List
          let last = Last encodings

          chunked = (last.type == "chunked")

          -- The spec says we should only treat the body as chunked if
          -- 'chunked' is last in the encoding list. Remove it from the
          -- encoding list since we're going to decode the chunks.
          --
          -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.4.1
          -- https://www.rfc-editor.org/rfc/rfc9112#section-7.1.1-3
          -- https://www.rfc-editor.org/rfc/rfc9112#section-7.1.2-3
          encodings = if chunked
                        then Init encodings
                        else encodings

      -- NOTE: the HTTP specification says that there is no upper limit
      -- on the value of Content-Length. We limit it to 64 bits here out
      -- of practicality.
      Content_Length =
        block
          (field_name == "content-length") is true
          commit
          -- NOTE: the specification permits all header values to be
          -- either tokens or quoted strings. This handles both. The
          -- specification also states that a Content-Length header is
          -- valid if it is a comma-separated list of numbers, all of
          -- which take the same value. We also handle that case here.
          --
          -- https://www.rfc-editor.org/rfc/rfc9110#section-5.5-12
          -- https://www.rfc-editor.org/rfc/rfc9112#section-6.3-2.5
          value =
            block
              let n1 = MaybeQuoted PositiveNum64
              let rest = Many { HTTP_OWS; $[',']; HTTP_OWS; MaybeQuoted PositiveNum64 }
              for (result = n1; val in rest)
                block
                  (val == n1) is true
                  ^ n1

      Header =
        block
          name = field_name
          let cur = GetStream
          let field_len = HTTP_field_content
          value = bytesOfStream (Take field_len cur)
          SetStream (Drop field_len cur)

def Last a =
  Index a (length a - 1)

def Init a =
  block
    let l = length a
    let result = for (b = builder; i, e in a)
      block
        if i < l - 1
          then emit b e
          else b
    build result

def HTTP_field_content =
  many (count = 0)
    block
      let n = HTTP_OWS
      $http_field_vchar
      count + n + 1

--------------------------------------------------------------------------------
-- Field Values
--------------------------------------------------------------------------------

def Quoted P = { $dquote; $$ = P; $dquote }

def HTTP_quoted_string = Quoted HTTP_string

def HTTP_string =
  Many ( $[$htab | $sp | 0x21 | 0x23 .. 0x5B | 0x5D .. 0x7E | $obs_text]
      <| HTTP_quoted_pair
       )

def MaybeQuoted P =
  First
    Quoted P
    P

def HTTP_quoted_pair =
  block
    $['\\']
    $[ $htab | $sp | $vchar | $obs_text ]

def HTTP_comment =
  block
    $['(']
    Many ( @ $[ $htab | $sp | 0x21 .. 0x27 | 0x2A .. 0x5B | 0x5D .. 0x7E
                                                               | $obs_text ]
        <| @HTTP_quoted_pair
        <| HTTP_comment
         )
    $[')']
    Accept

def $http_ctext = $htab | $sp | 0x21 .. 0x27 | 0x2A .. 0x5

--------------------------------------------------------------------------------
-- HTTP Lexical Considerations
--------------------------------------------------------------------------------

-- Returns how many white spaces were skipped
def HTTP_OWS   = Count $[ $sp | $htab]

-- Token parsers
def HTTP_token = Many (1..) $http_tchar

-- Parse a token, but normalize its alphabetic characters to lowercase.
def HTTP_token_ci =
  Many (1..)
    First
      $http_tchar_noalpha
      CaseInsensitiveAlpha

-- Utilities to help parse header names case-insensitively while also
-- normalizing them to lowercase so we can check for specific headers in
-- the parser.
def LowerCaseAlpha = $['a' .. 'z']

def UpperCaseAlphaToLower =
  block
    let l = $['A' .. 'Z']
    ^ l + ('a' - 'A')

def CaseInsensitiveAlpha =
  First
    LowerCaseAlpha
    UpperCaseAlphaToLower

def $http_field_vchar = $vchar | $obs_text

def $http_tchar = $http_tchar_noalpha | $alpha

def $http_tchar_noalpha =
  '!'  | '#' | '$' | '%' | '&' | '\'' | '*' | '+' | '-' | '.' |
   '^' | '_' | '`' | '|' | '~' | $digit
