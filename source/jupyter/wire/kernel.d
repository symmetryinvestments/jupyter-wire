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
        const shellShutdown = maybeHandleRequestMessage(sockets, sockets.shell.recvRequestMessage);
        const controlShutdown = maybeHandleRequestMessage(sockets, sockets.control.recvRequestMessage);
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

bool maybeHandleRequestMessage(ref Sockets sockets, Nullable!Message requestMessage) @safe {
    if(requestMessage.isNull) return false;
    return handleRequestMessage(sockets, requestMessage.get);
}

// returns whether or not to shutdown
bool handleRequestMessage(ref Sockets sockets, Message requestMessage) @safe {
    import jupyter.wire.connection: sendMsg;
    import jupyter.wire.message: statusMessage, pubMessage;

    static int executionCount;

    auto busyMsg = statusMessage(requestMessage.header, "busy");
    sockets.ioPub.sendMsg(busyMsg, sockets.key);

    switch(requestMessage.header.msgType) {

    default:
        return false;

    case "kernel_info_request":
        auto replyMessage = Message(requestMessage, "kernel_info_reply",
                                    `{"protocol_version": "5.3.0", "implementation": "foo", "implementation_version": "0.0.1", "language_info": {"name": "foo", "version": "0.0.1", "mimetype": "footype", "file_extension": ".d"}}`);
        sockets.shell.sendMsg(replyMessage, sockets.key);

        auto idleMsg = statusMessage(requestMessage.header, "idle");
        sockets.ioPub.sendMsg(idleMsg, sockets.key);

        return false;

    case "shutdown_request":
        return true;

    case "execute_request":
        {
            auto msg = pubMessage(requestMessage.header, "execute_input",
                                  `{"execution_count": 1, "code": "lecode"}`);
            sockets.ioPub.sendMsg(msg, sockets.key);
        }

        {
            auto msg = pubMessage(requestMessage.header, "stream",
                                  `{"name": "stdout", "text": "hello world"}`);
            sockets.ioPub.sendMsg(msg, sockets.key);
        }

        {
            auto msg = pubMessage(requestMessage.header, "execute_result",
                                  `{"execution_count": 1, "data": {"text/plain": "result!"}, "metadata": {}}`);
            sockets.ioPub.sendMsg(msg, sockets.key);
        }

        {
            auto replyMessage = Message(requestMessage, "execute_reply",
                                        `{"status": "ok", "execution_count": 1, "user_variables": {}, "payload": [], "user_expressions": {}}`);
            sockets.shell.sendMsg(replyMessage, sockets.key);
        }

        auto idleMsg = statusMessage(requestMessage.header, "idle");
        sockets.ioPub.sendMsg(idleMsg, sockets.key);

        return false;
    }

    assert(0);
}

void maybeHandleHeartbeat(ref Sockets sockets) @safe {
    ubyte[1024] buf;
    const ret = sockets.heartbeat.tryReceive(buf);
    const length = ret[0];
    if(!length) return;
    sockets.heartbeat.send(buf[0 .. length]);
}
