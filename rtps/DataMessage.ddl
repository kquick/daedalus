-- Definition of DDS messages, based on the DDSI-RTPS spec.
import Stdlib

-- TODO: account for endianness encoding modes
def Octet = UInt8

def OctetArray2 = Many 2 Octet

def OctetArray3 = Many 3 Octet

-- type aliases to match terms in spec:
def UShort = Uint16

def Short = Int16

def ULong = Uint32

def Long = Int32

-- Sec. 8.3.3 The Overall strucutre of an RTPS Message: the overall
-- structure of an RTPS Message consists of a fixed-size leading RTPS
-- Header followed by a variable number of RTPS Submessage
-- parts. Fig. 8.8:
-- DBG:
def Message PayloadData = {
-- def Message = {
  header = Header;
-- DBG:
  submessages = Many (Submessage PayloadData);
--  submessages = Many Submessage;
--  subm0 = Submessage PayloadData;
  END
}

-- Sec. 8.3.3.1 Header Structure. Table 8.14:
def Header = {
  protocol = Protocol;
  version = ProtocolVersion;
  vendorId = VendorId;
  guidPrefix = GuidPrefix;
}

-- Sec. 8.3.3.1.1 protocol: value is set to PROTOCOL_RTPS
def Protocol = ProtocolRTPS

-- Sec. 8.3.3.1.2 version:
def ProtocolVersion = {
  major = Octet;
  mintor = Octet;
}

def VendorId = Many 2 Octet

def ProtocolRTPS = Match "RTPS" 

def GuidPrefix = Many 12 Octet

-- DBG:
def Submessage PayloadData = {
-- def Submessage = {
  subHeader = SubmessageHeader;
  elt = Choose1 {
    { Guard (subHeader.submessageLength > 0);
      $$ = Chunk
        (subHeader.submessageLength as uint 64)
-- DBG:
        (SubmessageElement PayloadData subHeader.flags);
      (Many Octet);
    };
    { Guard (subHeader.submessageLength == 0);
      $$ = SubmessageElement PayloadData subHeader.flags;
      Many Octet; -- TODO: this is maybe too sloppy
    };
  }
}

-- Sec 8.3.3.2 Submessage structure: Table 8.15:
def SubmessageHeader = {
  submessageId = SubmessageId;
  flags = SubmessageFlags submessageId;
  submessageLength = UShort; 
}

-- Sec 8.3.3.2.1 SubmessageId: a SubmessageKind (Sec 9.4.5.1.1)
def SubmessageId = Choose1{
  pad = @Match1 0x01;
  acknack = @Match1 0x06;
  heartbeat = @Match1 0x07;
  gap = @Match1 0x08;
  infoTs = @Match1 0x09;
  infoSrc = @Match1 0x0c;
  infoReplyIP4 = @Match1 0x0d;
  infoDst = @Match1 0x0e;
  infoReply = @Match1 0x0f;
  nackFrag = @Match1 0x12;
  heartbeatFrag = @Match1 0x13;
  data = @Match1 0x015;
  dataFrag = @Match1 0x16;
}

def NthBit n fs = {
  ^((fs .&. (1 << n)) != 0);
}

-- SubmessageFlags:

def SubmessageFlags (subId: SubmessageId) = { 
  @flagBits = UInt8;
  endiannessFlag = NthBit 0 flagBits;
  subFlags = Choose1 {
    ackNackFlags = {
      subId is acknack;
      finalFlag = NthBit 1 flagBits;
    };
    dataFlags = {
      subId is data;
      inlineQosFlag = NthBit 1 flagBits;
      dataFlag = NthBit 2 flagBits;
      keyFlag = NthBit 3 flagBits;
      Guard (!(dataFlag && keyFlag)); -- invalid combo

      nonStandardPayloadFlag = NthBit 4 flagBits;
    };
    dataFragFlags = {
      subId is dataFrag;
      inlineQosFlag = NthBit 1 flagBits;
      keyFlag = NthBit 2 flagBits;
      nonStandardPayloadFlag = NthBit 3 flagBits;
    };
    gapFlags = {
      subId is gap;
      groupInfoFlag = NthBit 1 flagBits;
    };
    heartBeatFlags = {
      subId is heartbeat;
      finalFlag = NthBit 1 flagBits;
      livelinessFlag = NthBit 2 flagBits;
      groupInfoFlag = NthBit 3 flagBits;
    };
    heartBeatFragFlags = {
      subId is heartbeatFrag;
    };
    infoDstFlags = {
      subId is infoDst;
    };
    infoReplyFlags = {
      subId is infoReply;
      multicastFlag = NthBit 1 flagBits;
    };
    infoSourceFlags = {
      subId is infoSrc;
    };
    infoTimestampFlags = {
      subId is infoTs;
      invalidateFlag = NthBit 1 flagBits;
    };
    padFlags = {
      subId is pad;
    };
    nackFragFlags = {
      subId is acknack;
    };
    infoReplyIP4Flags = {
      subId is infoReplyIP4;
      multicastFlag = NthBit 1 flagBits;
    };
  }
}

def QosParams f = Choose1 {
  hasQos = {
    Guard f;
    ParameterList;
  };
  noQos = Guard (!f);
}

def SubmessageElement PayloadData (flags: SubmessageFlags) = Choose1 {
  ackNackElt = {
    @ackNackFlags = flags.subFlags is ackNackFlags;
    readerId = EntityId;
    writerId = EntityId;
    readerSNState = SequenceNumberSet;
    count = Count;
  };
  dataElt = {
    @dFlags = flags.subFlags is dataFlags;
    Match [0x00, 0x00]; -- extra flags for future compatibility
    octetsToInlineQos = UShort; 

    Chunk (octetsToInlineQos as uint 64) {
      readerId = EntityId;
      writerId = EntityId;
    };

    writerSN = SequenceNumber;
    Guard (writerSN > 0);

    inlineQos = QosParams dFlags.inlineQosFlag;
    serializedPayload = Choose1 {
      hasData = {
        Guard dFlags.dataFlag;
        SerializedPayload PayloadData inlineQos;
      };
      hasKey = Guard dFlags.keyFlag;
      noPayload = Guard (!(dFlags.dataFlag || dFlags.keyFlag));
    };
  };
  dataFragElt = {
    @fragFlags = flags.subFlags is dataFragFlags;
    Match [0x00, 0x00]; -- extraFlags
    octetsToInlineQos = UShort;

    Chunk (octetsToInlineQos as uint 64) {
    };

    readerId = EntityId;
    writerId = EntityId;

    writerSN = SequenceNumber;
    Guard (writerSN > 0);

    fragmentStartingNum = FragmentNumber;
    Guard (0 < fragmentStartingNum);
    
    fragmentsInSubmessage = UShort;
    Guard (fragmentStartingNum <= (fragmentsInSubmessage as uint 32));

    fragmentSize = UShort;
    Guard (fragmentSize <= 64000);

    sampleSize = ULong;
    Guard (fragmentSize as uint 32 < sampleSize); 

    inlineQos = QosParams fragFlags.inlineQosFlag;

    serializedPayload = Choose1 {
      hasData = {
        Guard (!(fragFlags.keyFlag));
        Chunk
          ((fragmentsInSubmessage * fragmentSize) as uint 64)
          (Many
            ((fragmentsInSubmessage as uint 32 -
              fragmentStartingNum) as uint 64)
            (SerializedPayload PayloadData inlineQos));
      };
      hasKey = Guard fragFlags.keyFlag;
    };
  };
  gapElt = {
    @gapFlags0 = flags.subFlags is gapFlags;
    readerId = EntityId;
    writerId = EntityId;

    gapStart = SequenceNumber;
    Guard (gapStart > 0);

    gapList = SequenceNumberSet;

    -- WARNING: layout of these is not defined at PSM level. This is a
    -- guess.
    Choose1 {
      hasGpInfo = {
        Guard (gapFlags0.groupInfoFlag);

        gapStartGSN = SequenceNumber;
        Guard (gapStartGSN > 0);

        gapEndGSN = SequenceNumber;
        Guard (gapEndGSN >= gapStartGSN - 1);
      };
      noGpInfo = Guard (!(gapFlags0.groupInfoFlag));
    }
  };
  heartBeatElt = {
    @hbFlags = flags.subFlags is heartBeatFlags;
    readerId = EntityId;
    writerId = EntityId;

    firstSN = SequenceNumber;
    Guard (firstSN > 0);

    lastSN = SequenceNumber;
    Guard (lastSN >= firstSN - 1);
    count = Count;

    -- WARNING: layout of these is not defined at PSM level. This is a
    -- guess, based on Table 8.38.
    Choose1 {
      hasGpInfo = {
        Guard (hbFlags.groupInfoFlag);

        currentGSN = SequenceNumber;

        firstGSN = SequenceNumber;
        Guard (firstGSN > 0);
        Guard (currentGSN >= firstGSN);

        lastGSN = SequenceNumber;
        Guard (lastGSN >= firstGSN - 1);
        Guard (currentGSN >= lastGSN);

        writerSet = GroupDigest;
        secureWriterSet = GroupDigest;
      };
      noGpInfo = Guard (!(hbFlags.groupInfoFlag));
    }
  };
  heartBeatFragElt = {
    @hbFragFlags = flags.subFlags is heartBeatFragFlags;
    readerId = EntityId;
    writerId = EntityId;

    writerSN = SequenceNumber;
    Guard (writerSN > 0);
    
    lastFragmentNum = FragmentNumber;
    Guard (lastFragmentNum > 0);

    count = Count;
  };
  infoDstElt = {
    @infoDstFlags0 = flags.subFlags is infoDstFlags;
    guidPrefix = GuidPrefix;
  };
  infoReplyElt = {
    @replyFlags0 = flags.subFlags is infoReplyFlags;
    unicastLocatorList = LocatorList;
    multicastLocatorList = Choose1 {
      hasLocs = {
        Guard replyFlags0.multicastFlag;
        LocatorList;
      };
      noLocs = Guard (!(replyFlags0.multicastFlag));
    };
  };
  infoSourceElt = {
    @infoSourceFlags0 = flags.subFlags is infoSourceFlags;
    ULong; -- unused
    version = ProtocolVersion;
    vendorId = VendorId;
    guidPrefix = GuidPrefix;
  };
  timestampElt = {
    @tsFlags0 = flags.subFlags is infoTimestampFlags;
    Choose1 {
      hasTs = {
        Guard (!(tsFlags0.invalidateFlag));
        Time;
      };
      noTs = Guard (tsFlags0.invalidateFlag);
    }
  };
  padElt = {
    @padFlags = flags.subFlags is padFlags;
    Many Octet;
  };
  nackFragElt = {
    @nackFlags = flags.subFlags is nackFragFlags;
    readerId = EntityId;
    writerId = EntityId;
    writerSN = SequenceNumber;
    fragmentNumberState = FragmentNumberSet;
    count = Count;
  };
  infoReplyIP4Elt = {
    @replyIP4Flags0 = flags.subFlags is infoReplyIP4Flags;
    unicastLocator = LocatorUDPv4;
    multicastLocator = LocatorUDPv4;
  }
}

def EntityId = {
  entityKey = OctetArray3;
  entityKind = Octet;
}

-- Sec 9.3.2 Mapping of the Types that Appear Within Submessages...
def SequenceNumber = Int64

def SequenceNumberSet = {
  bitmapBase = SequenceNumber;
  numBits = ULong;
  Many ((numBits + 31)/32 - 1 as uint 64) ULong;
}

def GroupDigest = Many 4 Octet

-- Sec 9.4.2.11 ParameterList:

-- Sec 9.6.2.2.2 ParameterID values: Table 9.13:
def ParameterIdT = Choose1 {
    pidPad = @Match [0x00, 0x00];
    pidSentinel = @Match [0x00, 0x01];
    pidUserData = @Match [0x00, 0x2c]; 
    pidTopicName = @Match [0x00, 0x05];
    pidTypeName = @Match [0x00, 0x07];
    pidGroupData = @Match [0x00, 0x2d];
    pidTopicData = @Match [0x00, 0x2e];
    pidDurability = @Match [0x00, 0x1d];
    pidDurabilityService = @Match [0x00, 0x1e];
    pidDeadline = @Match [0x00, 0x23];
    pidLatencyBudget = @Match [0x00, 0x27];
    pidLiveliness = @Match [0x00, 0x1b];
    pidReliability = @Match [0x00, 0x1a];
    pidLifespan = @Match [0x00, 0x2b];
    pidDestinationOrder = @Match [0x00, 0x25];
    pidHistory = @Match [0x00, 0x40];
    pidResourceLimits = @Match [0x00, 0x41];
    pidOwnership = @Match [0x00, 0x1f];
    pidOwnershipStrength = @Match [0x00, 0x06];
    pidPresentation = @Match [0x00, 0x21];
    pidPartition = @Match [0x00, 0x29];
    pidTimeBasedFilter = @Match [0x00, 0x04];
    pidTransportPriority = @Match [0x00, 0x49];
    pidDomainId = @Match [0x00, 0x0f];
    pidDomainTag = @Match [0x40, 0x14];
    pidProtocolVersion = @Match [0x00, 0x15];
    pidVendorid = @Match [0x00, 0x16];
    pidUnicastLocator = @Match [0x00, 0x2f];
    pidMulticastLocator = @Match [0x00, 0x30];
    pidDefaultUnicastLocator = @Match [0x00, 0x31];
    pidDefaultMulticastLocator = @Match [0x00, 0x48];
    pidMetatrafficUnicastLocator = @Match [0x00, 0x32];
    pidMetatrafficMulticastLocator = @Match [0x00, 0x33];
    pidExpectsInlineQos = @Match [0x00, 0x43];
    pidParticipantManualLivelinessCount = @Match [0x00, 0x34];
    pidParticipantLeaseDuration = @Match [0x00, 0x02];
    pidContentFilterProperty = @Match [0x00, 0x35];
    pidParticipantGuid = @Match [0x00, 0x50];
    pidGroupGuid = @Match [0x00, 0x52];
    pidBuiltinEndpointSet = @Match [0x00, 0x58];
    pidBuiltinEndpointQos = @Match [0x00, 0x77];
    pidPropertyList = @Match [0x00, 0x59];
    pidTypeMaxSizeSerialized = @Match [0x00, 0x60];
    pidEntityName = @Match [0x00, 0x62];
    pidEndpointGuid = @Match [0x00, 0x5a];
}

-- Table 9.13:
def ParameterIdValues pid = Choose1 {
  padVal = Many Octet;
  -- sentinel: not allowed
  userDataVal = UserDataQosPolicy;
  topicNameVal = String256;
  typeNameVal = String256;
  groupDataVal = GroupDataQosPolicy;
  topicDataVal = TopicDataQosPolicy;
  durabilityVal = DurabilityQosPolicy;
  durabilityServiceVal = DurabilityServiceQosPolicy;
  deadlineVal = DeadlineQosPolicy;
  latencyBudgetVal = LatencyBudgetQosPolicy;
  livelinessVal = LivenessQosPolicy;
  reliabilityVal = ReliabilityQosPolicy;
  lifespanVal = LifespanQosPolicy;
  destinationOrderVal = DestinationOrderQosPolicy;
  historyVal = HistoryQosPolicy;
  resourceLimitsVal = ResourceLimitsQosPolicy;
  ownershipVal = OwnershipQosPolicy;
  ownershipStrengthVal = OwnershipStrengthQosPolicy;
  presentationVal = PresentationQosPolicy;
  partitionVal = PartitionQosPolicy;
  timeBasedFilterVal = TimeBasedFilterQosPolicy;
  transportPriorityVal = TransportPriorityQosPolicy;
  domainIdVal = DomainId;
  domainTagVal = String256;
  protocolVersionVal = ProtocolVersion;
  vendorIdVal = VendorId;
  unicastLocator = Locator;
  multicastLocator = Locator;
  defaultUnicastLocator = Locator;
  multicastLocator = Locator;
  metatrafficUnicastLocator = Locator;
  metatrafficMulticastLocator = Locator;
  expectsInlineQos = Boolean;
  participantManualLivelinessCountVal = Count;
  participantLeaseDurationVal = Duration;
  contentFilterPropertyVal = ContentFilterProperty;
  participantGUIDVal = GUIDT;
  groupGUIDVal = GUIDT;
  builtinEndpointSetVal = BuiltinEndpointSetT;
  buildtinEndpointQosVal = BuiltinEndpointQosT;
  propertyListVal = Many PropertyT;
  typeMaxSizeSerializedVal = ULong;
  entityNameVal = EntityName;
  endpointGuidVal = GUIDT;
}

-- relaxed definition. Refine as needed.
def UserDataQosPolicy = Many Octet

def BndString n = {
  @len = ULong;
  Guard (len <= n);
  $$ = Many (len as uint 64) Octet;
  Match1 0x00;
}

def String256 = BndString 256

-- relaxed definition. Refine as needed.
def GroupDataQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def TopicDataQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def DurabilityQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def DurabilityServiceQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def DeadlineQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def LatencyBudgetQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def LivenessQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def ReliabilityQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def LifespanQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def DestinationOrderQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def HistoryQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def ResourceLimitsQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def OwnershipQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def OwnershipStrengthQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def PresentationQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def PartitionQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def TimeBasedFilterQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def TransportPriorityQosPolicy = Many Octet

-- relaxed definition. Refine as needed.
def DomainId = ULong

def Locator = {
  kind = Long;
  port = ULong;
  address = Many 16 Octet;
}

def LocatorList = {
  numLocators = ULong;
  Many (numLocators as uint 64) Locator;
}

def LocatorUDPv4 = {
  address = ULong;
  port = ULong;
}

def Count = Long

def Duration = {
  seconds = Long;
  fraction = ULong;
}

def ContentFilterProperty = {
  contentFilteredTopicName = String256;
  relatedTopicName = String256;
  filterClassName = String256;
  filterExpression = String;
  expressionParameters = Many String;
}

def Time = {
  seconds = ULong;
  fraction = ULong;
}

def GUIDT = {
  guidPrefix = GuidPrefix;
  entityId = EntityId;
}

-- relaxed definition. Refine as needed.
def BuiltinEndpointSetT = Many Octet

-- relaxed definition. Refine as needed.
def BuiltinEndpointQosT = Many Octet

-- relaxed definition. Refine as needed.
def PropertyT = Many Octet

def EntityName = String

def Parameter = {
  @parameterId = ParameterIdT;
  Guard (parameterId != {| pidSentinel = {} |});

  @len = UShort;
  Guard (len % 4 == 0);

  Chunk (len as uint 64) (ParameterIdValues parameterId);
}

def Sentinel = {
  @pId = ParameterIdT;
  pId is pidSentinel;
  UShort;
}

def ParameterList = {
  $$ = Many Parameter;
  Sentinel;
}

-- Sec 10 Serialized Payload Representation:
def SerializedPayload PayloadData qos = {
  payloadHeader = SerializedPayloadHeader;
  data = PayloadData qos;
}

def SerializedPayloadHeader = {
  representationIdentifier = Choose1 {
    -- Table 10.3:
    userDefinedTopicData = Choose1 {
      cdrBe = @Match [0x00, 0x00];
      cdrLe = @Match [0x00, 0x01];
      plCdrBE = @Match [0x00, 0x02];
      plCdrLE = @Match [0x00, 0x03];
      cdr2Be = @Match [0x00, 0x10];
      cdr2LE = @Match [0x00, 0x11];
      plCdr2Be = @Match [0x00, 0x12];
      plCdr2LE = @Match [0x00, 0x03];
      dCdrBe = @Match [0x00, 0x14];
      dCdrLe = @Match [0x00, 0x15];
      xml = @Match [0x00, 0x04];
    };
  };
  representationOptions = OctetArray2;
}

-- Sec 9.3.2:
def FragmentNumber = ULong

-- Sec 9.4.2.8:
def FragmentNumberSet = {
  bitmapBase = FragmentNumber;
  numBits = ULong;
  bitmap = Many ((numBits + 31)/32 - 1 as uint 64) Long;
}