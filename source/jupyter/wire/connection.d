module jupyter.wire.connection;


import zmqd: Socket;


ConnectionInfo fileNameToConnectionInfo(in string fileName) @safe {
    import std.file: readText;
    return ConnectionInfo(readText(fileName));
}


struct ConnectionInfo {

    import asdf.serialization : serializationKeys;

    @serializationKeys("signature_scheme") string signatureScheme;
    string transport;
    @serializationKeys("stdin_port") ushort stdinPort;
    @serializationKeys("control_port") ushort controlPort;
    @serializationKeys("iopub_port")ushort ioPubPort;
    @serializationKeys("hb_port") ushort hbPort;
    @serializationKeys("shell_port") ushort shellPort;
    string key;
    string ip;

    this(in string json) @safe pure {
        import asdf: deserialize;
        this = () @trusted { return json.deserialize!ConnectionInfo; }();
    }

    string uri(ushort port) @safe pure const {
        import std.conv: text;
        return text(transport, "://", ip, ":", port);
    }
}


struct Sockets {
    import zmqd: Socket, SocketType;

    Socket shell, control, stdin, ioPub, hb;

    this(in ConnectionInfo ci) @safe {
        import zmqd: SocketType;

        initSocket(shell,   SocketType.router, ci, ci.shellPort);
        initSocket(control, SocketType.router, ci, ci.controlPort);
        initSocket(stdin,   SocketType.router, ci, ci.stdinPort);
        initSocket(ioPub,   SocketType.pub, ci, ci.ioPubPort);
        initSocket(hb,      SocketType.rep, ci, ci.hbPort);
    }

    private static void initSocket(ref Socket socket, in SocketType socketType, in ConnectionInfo ci, in ushort port) @safe {
        import zmqd: Socket;
        socket = Socket(socketType);
        socket.bind(ci.uri(port));
    }
}


// The shell and control sockets receive 6 or more strings at time
// See https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol
string[] recvStrings(ref Socket socket) @safe {
    import zmqd: Frame;

    string[] strings;

    do {
        auto frame = Frame();
        const ret /*size, bool*/ = socket.tryReceive(frame);
        if(!ret[1]) return [];
        strings ~= cast(string) frame.data.idup;
    } while(socket.more);

    return strings;
}

void sendStrings(ref Socket socket, in string[] lines) @safe {
    foreach(line; lines) socket.send(line, true /*more*/);
}
