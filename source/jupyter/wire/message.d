module jupyter.wire.message;

/**
   A message sent to the kernel.
   See https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol
 */
struct Message {
    string[] identities;
    MessageHeader header;
    MessageHeader parentHeader;
    string metadataJsonStr = "{}";
    string contentJsonStr = "{}";
    string[] extraRawData;

    enum delimiter = "<IDS|MSG>";

    /**
       Constructs the message from the strings sent to the control or shell
       sockets.
     */
    this(in string[] strings) @safe pure {
        import asdf: deserialize;
        import std.algorithm: countUntil;

        const delimiterIndex = strings.countUntil(delimiter);
        identities = strings[0 .. delimiterIndex].dup;

        // hmac is delimiter + 1

        () @trusted {
            header = strings[delimiterIndex + 2].deserialize!MessageHeader;
            parentHeader = strings[delimiterIndex + 3].deserialize!MessageHeader;
        }();

        metadataJsonStr = strings[delimiterIndex + 4];
        contentJsonStr = strings[delimiterIndex + 5];
        extraRawData = strings[delimiterIndex + 6 .. $].dup;
    }

    /**
       Convert to a format suitable for sending over ZMQ
     */
    string[] toStrings(in string key) @safe pure const {
        import asdf: serializeToJson;

        string[] ret;

        ret ~= identities;
        ret ~= delimiter;
        ret ~= signature(key);
        ret ~= header.toJsonString;
        ret ~= parentHeader.toJsonString;
        ret ~= metadataJsonStr;
        ret ~= contentJsonStr;
        ret ~= extraRawData;

        return ret;
    }

    /**
       Update header with a random uuid and setting the timestamp
     */
    void updateHeader() @safe {
        import std.datetime: DateTime, Clock;
        import std.uuid: randomUUID;

        header.date = (cast(DateTime)Clock.currTime).toISOExtString;
        header.msgID = randomUUID.toString;
    }

    private string signature(in string key) @safe pure const {
        import std.digest.hmac: hmac;
        import std.digest.sha: SHA256;
        import std.string: representation;
        import std.array : appender;
        import std.conv : toChars;

        auto mac = hmac!SHA256(key.representation);
        foreach(w; [header.toJsonString, parentHeader.toJsonString, metadataJsonStr, contentJsonStr])
            mac.put(w.representation);

        ubyte[32] us = mac.finish;
        auto cs = appender!string;
        cs.reserve(64);

        foreach(u; us[]) {
            if (u <= 0xf) cs.put('0');
            cs.put(toChars!16(cast(uint) u));
        }

        return cs.data;
    }

}


struct MessageHeader {
    import asdf: serializationKeys;

    @serializationKeys("msg_id") string msgID;
    @serializationKeys("msg_type") string msgType;
    @serializationKeys("username") string userName;
    string session;
    string date;
    @serializationKeys("version") string protocolVersion;
}

string toJsonString(MessageHeader header) @trusted pure {
    import asdf: serializeToJson;
    return header.msgID is null ? "{}" : serializeToJson(header);
}


Message statusMessage(MessageHeader header, in string status) @safe {
    Message ret;
    ret.parentHeader = ret.header = header;
    ret.identities = ["status"];
    ret.header.msgType = "status";
    ret.contentJsonStr = `{"execution_state": "` ~ status ~ `"}`;
    ret.updateHeader;

    return ret;
}
