module jupyter.wire.kernel;


import jupyter.wire.message: Message;
import jupyter.wire.connection: ConnectionInfo, Sockets;
import zmqd: Socket;
import std.typecons: Nullable;

/**
   So users don't have to write their own main
 */
mixin template Main() {
    int main(string[] args) {
        try {
            import jupyter.wire.kernel: run;
            const connectionFileName = args[1];
            run(connectionFileName);
            return 0;
        } catch(Exception e) {
            import std.stdio: stderr;
            stderr.writeln("Error: ", e.msg);
            return 1;
        } catch(Error e) {
            import std.stdio: stderr;
            stderr.writeln("FATAL ERROR: ", e);
            return 2;
        }
    }

}

/**
   The "real main"
 */
void run(in string connectionFileName) @safe {
    import jupyter.wire.connection: fileNameToConnectionInfo;
    import std.datetime: msecs;
    import core.thread: Thread;

    const connectionInfo = fileNameToConnectionInfo(connectionFileName);
    auto sockets = Sockets(connectionInfo);

    for(bool stop; !stop;) {
        maybeHandleHeartbeat(sockets);
        const shellShutdown = maybeHandleRequestMessage(connectionInfo, sockets, sockets.shell.recvRequestMessage);
        const controlShutdown = maybeHandleRequestMessage(connectionInfo, sockets, sockets.control.recvRequestMessage);
        stop = shellShutdown || controlShutdown;
        () @trusted { Thread.sleep(10.msecs); }();
    }
}

Nullable!Message recvRequestMessage(ref Socket socket) @safe {
    import jupyter.wire.connection: recvStrings;
    import jupyter.wire.message: Message;
    import std.typecons: Nullable, nullable;

    const requestStrings = socket.recvStrings;
    if(requestStrings is null) return Nullable!Message();

    return nullable(Message(requestStrings));
}

bool maybeHandleRequestMessage(in ConnectionInfo connectionInfo, ref Sockets sockets, Nullable!Message requestMessage) @safe {
    if(requestMessage.isNull) return false;
    return handleRequestMessage(connectionInfo, sockets, requestMessage.get);
}

bool handleRequestMessage(in ConnectionInfo connectionInfo, ref Sockets sockets, Message requestMessage) @safe {
    import jupyter.wire.connection: sendStrings;
    import jupyter.wire.message: statusMessage;

    int executionCount;

    auto busyMsg = statusMessage(requestMessage.header, "busy");
    sockets.ioPub.sendStrings(busyMsg.toStrings(connectionInfo.key));

    switch(requestMessage.header.msgType) {
    default: {}
    case "kernel_info_request":
        auto replyMessage = requestMessage;
        replyMessage.parentHeader = replyMessage.header;
        replyMessage.header.msgType = "kernel_info_reply";
        replyMessage.contentJsonStr = `{"protocol_version": "5.3.0", "implementation": "foo", "implementation_version": "0.0.1", "language_info": {"name": "foo", "version": "0.0.1", "mimetype": "footype", "file_extension": ".d"}}`;
        replyMessage.updateHeader;
        sockets.shell.sendStrings(replyMessage.toStrings(connectionInfo.key));

        auto idleMsg = statusMessage(requestMessage.header, "idle");
        sockets.ioPub.sendStrings(idleMsg.toStrings(connectionInfo.key));

        return false;

    case "shutdown_request":
        return true;

    case "execute_request":
        auto replyMessage = requestMessage;
        replyMessage.parentHeader = replyMessage.header;
        replyMessage.header.msgType = "execute_reply";
        replyMessage.contentJsonStr = `{"execution_count": 1, "status": "ok"}`;
        sockets.shell.sendStrings(replyMessage.toStrings(connectionInfo.key));

        auto pubMessage = statusMessage(requestMessage.header, "execute_result");
        pubMessage.contentJsonStr = `{"execution_count": 1, "data": {"text/plain": "lefooislebarislefoo"}, "metadata": {}, "status": "ok"}`;
        sockets.ioPub.sendStrings(pubMessage.toStrings(connectionInfo.key));

        auto idleMsg = statusMessage(requestMessage.header, "idle");
        sockets.ioPub.sendStrings(idleMsg.toStrings(connectionInfo.key));

        return false;
    }

    //return false /*shutdown*/;
    assert(0);
}

void maybeHandleHeartbeat(ref Sockets sockets) @safe {
    ubyte[1024] buf;
    const ret = sockets.heartbeat.tryReceive(buf);
    const length = ret[0];
    if(!length) return;
    sockets.heartbeat.send(buf[0 .. length]);
}
