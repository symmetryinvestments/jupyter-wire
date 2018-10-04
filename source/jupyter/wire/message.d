module jupyter.wire.message;

import asdf: Asdf;

/**
   A message sent to the kernel.
   See https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol
 */
struct Message {
    import asdf: Asdf;

    string[] identities;
    MessageHeader header;
    MessageHeader parentHeader;
    Asdf metadata;
    Asdf content;
    string[] extraRawData;

    enum delimiter = "<IDS|MSG>";

    /**
       Constructs the message from the strings sent to the control or shell
       sockets.
     */
    this(in string[] strings) @safe pure {
        import asdf: deserialize, parseJson;
        import std.algorithm: countUntil;

        const delimiterIndex = strings.countUntil(delimiter);
        identities = strings[0 .. delimiterIndex].dup;

        // TODO: verify signature
        // hmac is delimiter + 1

        () @trusted {
            header = strings[delimiterIndex + 2].deserialize!MessageHeader;
            parentHeader = strings[delimiterIndex + 3].deserialize!MessageHeader;
        }();

        metadata = () @trusted { return parseJson(strings[delimiterIndex + 4]); }();
        content = () @trusted { return parseJson(strings[delimiterIndex + 5]); }();
        extraRawData = strings[delimiterIndex + 6 .. $].dup;
    }

    this(in Message other, in string msgType, in string contentJsonStr = `{}`) @safe {
        import asdf: parseJson;
        this(other, msgType, () @trusted { return parseJson(contentJsonStr); }());
    }

    this(in Message other, in string msgType, Asdf content) @safe {
        identities = other.identities.dup;
        this(other.header, msgType, content);
    }

    this(in MessageHeader parentHeader, in string msgType) @safe {
        import asdf: parseJson;
        this(parentHeader, msgType, () @trusted { return parseJson(`{}`); }());
    }

    this(in MessageHeader parentHeader, in string msgType, Asdf content) @safe {
        this.header = this.parentHeader = parentHeader;
        this.header.msgType = msgType;
        updateHeader;
        this.content = content;
    }

    /**
       Convert to a format suitable for sending over ZMQ
     */
    string[] toStrings(in string key) /*@safe*/ @trusted /*pure*/ {
        import asdf: serializeToJson, parseJson;

        return
            identities.dup ~
            delimiter ~
            signature(key) ~
            header.toJsonString ~
            parentHeader.toJsonString ~
            toJsonString(metadata) ~
            toJsonString(content) ~
            extraRawData;
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

    private string signature(in string key) @safe pure {
        import std.digest.hmac: hmac;
        import std.digest.sha: SHA256;
        import std.string: representation;
        import std.array : appender;
        import std.conv : toChars;

        auto mac = hmac!SHA256(key.representation);

        foreach(w; [header.toJsonString, parentHeader.toJsonString, toJsonString(metadata), toJsonString(content)])
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


    private static string toJsonString(ref Asdf asdf) @trusted pure {
        import std.conv: to;
        return asdf == Asdf.init ? `{}` : asdf.to!string;
    }
}


struct MessageHeader {
    import asdf: key = serializationKeys;

    @key("msg_id")   string msgID;
    @key("msg_type") string msgType;
    @key("username") string userName;
                     string session;
                     string date;
    @key("version")  string protocolVersion;
}

// can't be made a member function because `serializetoJson(this)` doesn't compile
private string toJsonString(MessageHeader header) @trusted pure {
    import asdf: serializeToJson;
    return header.msgID is null ? "{}" : serializeToJson(header);
}


Message statusMessage(MessageHeader header, in string status) @trusted {
    auto ret = pubMessage(header, "status", `{"execution_state": "` ~ status ~ `"}`);
    return ret;
}


Message pubMessage(MessageHeader header, in string msgType, in string contentJsonStr = `{}`) @safe {
    import asdf: parseJson;
    auto content = () @trusted { return parseJson(contentJsonStr); }();
    return pubMessage(header, msgType, content);
}


Message pubMessage(MessageHeader header, in string msgType, Asdf content) @safe {
    auto ret = Message(header, msgType, content);
    ret.identities = [msgType];
    return ret;
}
