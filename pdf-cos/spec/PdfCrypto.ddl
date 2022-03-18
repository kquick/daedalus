import PdfDecl 
import PdfValue 
import PdfXRef 
import Debug

-- Encryption dictionary (Table 20 in S7.6.1) 
def EncryptionDict (enc : TrailerDictEncrypt) = { 
  Trace "enc1";
  @edict = (ResolveValRef enc.eref) is dict; 
  Trace "enc2";
  id0 = enc.id0; 
  Trace "enc3";

  encFilter = (Lookup "Filter" edict) is name; 
  Trace "enc4";
  encFilter == "Standard" is true; -- Other modes unsupported 
  Trace "enc5";

  encSubFilter = Optional ((Lookup "SubFilter" edict) is name); 
  Trace "enc6";

  encV = LookupNat "V" edict; 
  Trace "enc7";

  -- Fields for the Standard security handler (Table 21, S7.6.3.2)
  encR = LookupNat "R" edict; 
  Trace "enc8";
  encR == 3 || (encV == 4 && encR == 4) || (encV == 5 && encR == 6) is true; -- Other modes unsupported 
  Trace "enc9";

  encO = (Lookup "O" edict) is string; 
  Trace "enc10";
  encU = (Lookup "U" edict) is string;

  encOE = Optional ((Lookup "OE" edict) is string);
  encUE = Optional ((Lookup "UE" edict) is string);

  Trace "enc11";

  encP = { 
    @v = (Lookup "P" edict) is number; 
  Trace "enc12";
    ^ v.num;
  }; 

  ciph = ChooseCiph edict encV; 
  Trace "enc2";
} 

def ChooseCiph edict v = Choose1 { 
  v2RC4 = { 
    v == 2 is true; 
    @len = LookupNat "Length" edict; 
    len == 128 is true; 
  }; 
  v4RC4 = { 
    v == 4 is true;
    @stmFname = V4stmFname edict; 
    stmFname == "V2" is true;
  }; 
  v4AES = { 
    v == 4 is true;
    @stmFname = V4stmFname edict; 
    stmFname == "AESV2" is true;
  };
  v5AES = { 
    v == 5 is true;
    @stmFname = V4stmFname edict; 
    stmFname == "AESV3" is true;
  }; 
}

def V4stmFname (edict : [ [uint 8] -> Value ])= {
  @stmF = (Lookup "StmF" edict) is name; 
  @strF = (Lookup "StrF" edict) is name;       
  @cf = (Lookup "CF" edict) is dict; 
  
  -- Lookup stream filter 
  @stmFdict = (Lookup stmF cf) is dict; 
  @stmFname = (Lookup "CFM" stmFdict) is name; 
  @stmFLen = LookupNat "Length" stmFdict; 

  -- Lookup string filter 
  @strFdict = (Lookup strF cf) is dict; 
  @strFname = (Lookup "CFM" strFdict) is name; 
  @strFLen = LookupNat "Length" strFdict; 

  ^ stmFname; 
} 

def MakeContext (t : TrailerDict) =
  case t.encrypt of
    just enc -> {| encryption = EncryptionDict enc |}
    nothing  -> {| noencryption |}


