module jupyter.wire.connection;


import jupyter.wire.message: Message;
import zmqd: Socket;
import std.typecons: Nullable;


ConnectionInfo fileNameToConnectionInfo(in string fileName) @safe {
    import std.file: readText;
    return ConnectionInfo(readText(fileName));
}


struct ConnectionInfo {

    import asdf.serialization: jkey = serializationKeys;

    @jkey("signature_scheme") string signatureScheme;
                              string transport;
    @jkey("stdin_port")       ushort stdinPort;
    @jkey("control_port")     ushort controlPort;
    @jkey("iopub_port")       ushort ioPubPort;
    @jkey("hb_port")          ushort hbPort;
    @jkey("shell_port")       ushort shellPort;
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
    import jupyter.wire.message: MessageHeader;
    import zmqd: Socket, SocketType;
    import std.json: JSONValue;
    import std.concurrency: Tid;

    ConnectionInfo connectionInfo;
    Socket shell, control, stdin, ioPub;
    Tid heartbeatTid;

    static struct Stop{}
    static struct Done{}

    this(ConnectionInfo ci) @safe {
        import zmqd: SocketType;

        this.connectionInfo = ci;

        initSocket(shell,     SocketType.router, ci, ci.shellPort);
        initSocket(control,   SocketType.router, ci, ci.controlPort);
        initSocket(stdin,     SocketType.router, ci, ci.stdinPort);
        initSocket(ioPub,     SocketType.pub,    ci, ci.ioPubPort);

        startHeartbeatLoop;
    }

    ~this() {
        stopHeartbeatLoop;
    }

    private static void initSocket(ref Socket socket, in SocketType socketType, in ConnectionInfo ci, in ushort port) @safe {
        import zmqd: Socket;
        socket = Socket(socketType);
        socket.bind(ci.uri(port));
    }

    void send(ref Socket socket, Message message) @safe {
        sendStrings(socket, message.toStrings(connectionInfo.key));
    }

    void publish(in MessageHeader parentHeader, in string msgType, JSONValue content) @safe {
        import jupyter.wire.message: pubMessage;
        send(ioPub, pubMessage(parentHeader, msgType, content));
    }

    /**
       "Send" stdout output to jupyter notebook
     */
    void stdout(in MessageHeader parentHeader, in string stdout) @safe {
        JSONValue content;
        content["name"] = "stdout";
        content["text"] = stdout;
        publish(parentHeader, "stream", content);
    }

    private void startHeartbeatLoop() @safe {
        import std.concurrency: spawn, thisTid;
        heartbeatTid = () @trusted { return spawn(&heartbeatLoop, thisTid, connectionInfo); }();
    }

    private void stopHeartbeatLoop() @trusted {
        import std.concurrency: send, receiveOnly;
        heartbeatTid.send(Stop());
        receiveOnly!Done;
        heartbeatTid = Tid.init;
    }

    private static void heartbeatLoop(Tid parentTid, ConnectionInfo connectionInfo) @safe {
        import std.concurrency: receiveTimeout, send;
        import std.datetime: msecs;

        auto socket = Socket(SocketType.rep);
        socket.bind(connectionInfo.uri(connectionInfo.hbPort));

        ubyte[1024] buf;

        for(bool stop; !stop;) {
            () @trusted {
                receiveTimeout(
                    10.msecs,
                    (Stop _) {
                        stop = true;
                    },
                );
            }();

            const ret = socket.tryReceive(buf);
            const length = ret[0];
            if(length) socket.send(buf[0 .. length]);
        }

        () @trusted { parentTid.send(Done()); }();
    }
}


/**
   Receive a message on the given zeromq socket without blocking.
   If there are no messages to be received, returns a null message.
 */
Nullable!Message recvRequestMessage(ref Socket socket) @safe {
    import jupyter.wire.connection: recvStrings;
    import jupyter.wire.message: Message;
    import std.typecons: Nullable, nullable;

    const requestStrings = socket.recvStrings;
    if(requestStrings is null) return Nullable!Message();

    return nullable(Message(requestStrings));
}

// The shell and control sockets receive 6 or more strings at time
// See https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol
private string[] recvStrings(ref Socket socket) @safe {
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

// Send multiple strings at once over ZeroMQ
private void sendStrings(ref Socket socket, in string[] lines) @safe {
    foreach(line; lines[0 .. $-1])
        socket.send(line, true /*more*/);
    socket.send(lines[$-1], false /*more*/);
}
