module jupyter.wire.message;

import std.json: JSONValue;

/**
   A message sent to the kernel.
   See https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol
 */
struct Message {
    import std.json: JSONValue;

    string[] identities;
    MessageHeader header;
    MessageHeader parentHeader;
    // Not using asdf here because it's a pain to construct JSON objects with it
    // and its serialisation doesn't buy anything since both metadata and content
    // are free-form.
    JSONValue metadata;
    JSONValue content;
    string[] extraRawData;

    enum delimiter = "<IDS|MSG>";

    /**
       Constructs the message from the strings sent to the control or shell
       sockets.
     */
    this(in string[] strings) @safe pure {
        import asdf: deserialize;
        import std.json: parseJSON;
        import std.algorithm: countUntil;

        const delimiterIndex = strings.countUntil(delimiter);
        identities = strings[0 .. delimiterIndex].dup;

        // TODO: verify signature
        // hmac is delimiter + 1

        () @trusted {
            header = strings[delimiterIndex + 2].deserialize!MessageHeader;
            parentHeader = strings[delimiterIndex + 3].deserialize!MessageHeader;
        }();

        metadata = parseJSON(strings[delimiterIndex + 4]);
        content = parseJSON(strings[delimiterIndex + 5]);
        extraRawData = strings[delimiterIndex + 6 .. $].dup;
    }

    this(in Message other, in string msgType, JSONValue content) @safe {
        identities = other.identities.dup;
        this(other.header, msgType, content);
    }

    this(in MessageHeader parentHeader, in string msgType) @safe {
        import std.json: parseJSON;
        this(parentHeader, msgType, parseJSON(`{}`));
    }

    this(in MessageHeader parentHeader, in string msgType, JSONValue content) @safe {
        this.header = this.parentHeader = parentHeader;
        this.header.msgType = msgType;
        updateHeader;
        this.content = content;
    }

    /**
       Convert to a format suitable for sending over ZMQ
     */
    string[] toStrings(in string key) @safe {
        return
            identities.dup ~
            delimiter ~
            signature(key) ~
            header.toJsonString ~
            parentHeader.toJsonString ~
            metadata.toJsonString ~
            content.toJsonString ~
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

    private string signature(in string key) @safe {
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
private string toJsonString(MessageHeader header) @safe pure {
    import asdf: serializeToJson;
    return header.msgID is null ? "{}" : () @trusted { return serializeToJson(header); }();
}

private string toJsonString(in JSONValue json) @safe {
    import std.json: JSON_TYPE;
    return json.type == JSON_TYPE.NULL ? `{}` : json.toString;
}


Message statusMessage(MessageHeader header, in string status) @safe {
    import std.json: JSONValue;
    JSONValue content;
    content["execution_state"] = status;
    auto ret = pubMessage(header, "status", content);
    return ret;
}


Message pubMessage(MessageHeader header, in string msgType, JSONValue content) @safe {
    auto ret = Message(header, msgType, content);
    ret.identities = [msgType];
    return ret;
}
