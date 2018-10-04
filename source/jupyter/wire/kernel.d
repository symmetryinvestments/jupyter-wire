module jupyter.wire.kernel;


import jupyter.wire.message: Message;
import jupyter.wire.connection: ConnectionInfo, Sockets;
import zmqd: Socket;
import std.typecons: Nullable;


/**
   So users don't have to write their own main
 */
mixin template Main(LanguageInfo languageInfo) {
    int main(string[] args) {
        try {
            import jupyter.wire.kernel: Kernel;
            const connectionFileName = args[1];
            auto kernel = Kernel(languageInfo, connectionFileName);
            kernel.run;
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


struct LanguageInfo {
    string name;
    string version_;
    string fileExtension;
}


struct Kernel {

    import jupyter.wire.connection: ConnectionInfo, Sockets;

    private LanguageInfo languageInfo;
    private Sockets sockets;
    private int executionCount = 1;
    private bool stop;

    this(LanguageInfo languageInfo, in string connectionFileName) @safe {
        import jupyter.wire.connection: fileNameToConnectionInfo;
        this(languageInfo, fileNameToConnectionInfo(connectionFileName));
    }

    this(LanguageInfo languageInfo, ConnectionInfo connectionInfo) @safe {
        this.languageInfo = languageInfo;
        this.sockets = Sockets(connectionInfo);
    }

    void run() @safe {
        import jupyter.wire.connection: recvRequestMessage;
        import std.datetime: msecs;
        import core.thread: Thread;

        for(;!stop;) {
            maybeHandleHeartbeat(sockets);
            maybeHandleRequestMessage(sockets.shell.recvRequestMessage);
            maybeHandleRequestMessage(sockets.control.recvRequestMessage);
            () @trusted { Thread.sleep(10.msecs); }();
        }
    }

    void maybeHandleHeartbeat(ref Sockets sockets) @safe {
        ubyte[1024] buf;
        const ret = sockets.heartbeat.tryReceive(buf);
        const length = ret[0];
        if(!length) return;
        sockets.heartbeat.send(buf[0 .. length]);
    }

    void maybeHandleRequestMessage(Nullable!Message requestMessage) @safe {
        if(requestMessage.isNull) return;
        handleRequestMessage(requestMessage.get);
    }

    // returns whether or not to shutdown
    void handleRequestMessage(Message requestMessage) @safe {

        import jupyter.wire.message: statusMessage, pubMessage;
        import std.json : JSONValue, parseJSON;

        auto busyMsg = statusMessage(requestMessage.header, "busy");
        sockets.send(sockets.ioPub, busyMsg);

        scope(exit) {
            auto idleMsg = statusMessage(requestMessage.header, "idle");
            sockets.send(sockets.ioPub, idleMsg);
        }

        switch(requestMessage.header.msgType) {

        default: return;

        case "shutdown_request":
            handleShutdown(requestMessage);
            return;

        case "kernel_info_request":
            handleKernelInfoRequest(requestMessage);
            return;

        case "execute_request":
            handleExecuteRequest(requestMessage);
            return;
        }

        assert(0);
    }


    void handleShutdown(Message requestMessage) @safe {
        // TODO: restart
        // The content of the request is just {"restart": bool} so we reuse it
        // for the reply.
        auto replyMessage = Message(requestMessage, "shutdown_reply", requestMessage.content);
        sockets.send(sockets.control, replyMessage);
        stop = true;
    }

    void handleKernelInfoRequest(Message requestMessage) @safe {
        import std.json: JSONValue;

        JSONValue kernelInfo;
        kernelInfo["status"] = "ok";
        kernelInfo["protocol_version"] = "5.3.0";
        kernelInfo["implementation"] = "foo";
        kernelInfo["implementation_version"] = "0.0.1";
        kernelInfo["language_info"] = JSONValue();
        kernelInfo["language_info"]["name"] = languageInfo.name;
        kernelInfo["language_info"]["version"] = languageInfo.version_;
        kernelInfo["language_info"]["file_extension"] = languageInfo.fileExtension;
        kernelInfo["language_info"]["mimetype"] = "";

        auto replyMessage = Message(requestMessage, "kernel_info_reply", kernelInfo);
        sockets.send(sockets.shell, replyMessage);
    }

    void handleExecuteRequest(Message requestMessage) @safe {
        import jupyter.wire.message: pubMessage;
        import std.json: JSONValue, parseJSON;

        scope(exit) ++executionCount;

        {
            JSONValue content;
            content["execution_count"] = executionCount;
            content["code"] = requestMessage.content["code"];
            auto msg = pubMessage(requestMessage.header, "execute_input", content);
            sockets.send(sockets.ioPub, msg);
        }

        {
            JSONValue content;
            content["name"] = "stdout";
            content["text"] = "this is the json stdout";
            auto msg = pubMessage(requestMessage.header, "stream", content);
            sockets.send(sockets.ioPub, msg);
        }

        {
            JSONValue content;
            content["execution_count"] = executionCount;
            content["data"] = JSONValue();
            content["data"]["text/plain"] = "this is the json result";
            content["metadata"] = parseJSON(`{}`);
            auto msg = pubMessage(requestMessage.header, "execute_result", content);
            sockets.send(sockets.ioPub, msg);
        }

        {
            JSONValue content;
            content["status"] = "ok";
            content["execution_count"] = executionCount;
            content["user_variables"] = parseJSON(`{}`);
            content["user_expressions"] = parseJSON(`{}`);
            content["payload"] = parseJSON(`[]`);
            auto replyMessage = Message(requestMessage, "execute_reply", content);
            sockets.send(sockets.shell, replyMessage);
        }
    }
}
