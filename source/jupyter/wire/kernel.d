module jupyter.wire.kernel;


/**
   So users don't have to write their own main
 */
mixin template Main(Backend) {
    int main(string[] args) {
        try {
            import jupyter.wire.kernel: Kernel;
            const connectionFileName = args[1];
            auto backend = Backend();
            auto kernel = Kernel!Backend(backend, connectionFileName);
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

struct ExecutionResult {
    string result;
    string stdout;
}

template isBackend(T) {
    enum isBackend = is(typeof({
        LanguageInfo info = T.init.languageInfo;
        ExecutionResult result = T.init.execute("foo");
    }));
}

/**
   Implements a generic Jupyter kernel.
   Parameterised by a `Backend` type that knows how to execute code.

 */
struct Kernel(Backend) if(isBackend!Backend) {

    import jupyter.wire.connection: ConnectionInfo, Sockets;
    import jupyter.wire.message: Message;
    import std.typecons: Nullable;

    private Backend backend;
    private Sockets sockets;
    private int executionCount = 1;
    private bool stop;

    this(Backend backend, in string connectionFileName)  {
        import jupyter.wire.connection: fileNameToConnectionInfo;
        this(backend, fileNameToConnectionInfo(connectionFileName));
    }

    this(Backend backend, ConnectionInfo connectionInfo)  {
        this.backend = backend;
        this.sockets = Sockets(connectionInfo);
    }

    void run()  {
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

    void maybeHandleHeartbeat(ref Sockets sockets)  {
        ubyte[1024] buf;
        const ret = sockets.heartbeat.tryReceive(buf);
        const length = ret[0];
        if(!length) return;
        sockets.heartbeat.send(buf[0 .. length]);
    }

    void maybeHandleRequestMessage(Nullable!Message requestMessage)  {
        if(requestMessage.isNull) return;
        handleRequestMessage(requestMessage.get);
    }

    // returns whether or not to shutdown
    void handleRequestMessage(Message requestMessage)  {

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


    void handleShutdown(Message requestMessage)  {
        // TODO: restart
        // The content of the request is just {"restart": bool} so we reuse it
        // for the reply.
        auto replyMessage = Message(requestMessage, "shutdown_reply", requestMessage.content);
        sockets.send(sockets.control, replyMessage);
        stop = true;
    }

    void handleKernelInfoRequest(Message requestMessage)  {
        import std.json: JSONValue;

        JSONValue kernelInfo;
        kernelInfo["status"] = "ok";
        kernelInfo["protocol_version"] = "5.3.0";
        kernelInfo["implementation"] = "foo";
        kernelInfo["implementation_version"] = "0.0.1";
        kernelInfo["language_info"] = JSONValue();
        kernelInfo["language_info"]["name"] = backend.languageInfo.name;
        kernelInfo["language_info"]["version"] = backend.languageInfo.version_;
        kernelInfo["language_info"]["file_extension"] = backend.languageInfo.fileExtension;
        kernelInfo["language_info"]["mimetype"] = "";

        auto replyMessage = Message(requestMessage, "kernel_info_reply", kernelInfo);
        sockets.send(sockets.shell, replyMessage);
    }

    void handleExecuteRequest(Message requestMessage)  {
        import jupyter.wire.message: pubMessage;
        import std.json: JSONValue, parseJSON, JSON_TYPE;

        scope(exit) {
            if(requestMessage.content["store_history"].type == JSON_TYPE.true_)
            ++executionCount;
        }

        {
            JSONValue content;
            content["execution_count"] = executionCount;
            content["code"] = requestMessage.content["code"];
            auto msg = pubMessage(requestMessage.header, "execute_input", content);
            sockets.send(sockets.ioPub, msg);
        }

        const result = backend.execute(requestMessage.content["code"].str);

        {
            JSONValue content;
            content["name"] = "stdout";
            content["text"] = result.stdout;
            auto msg = pubMessage(requestMessage.header, "stream", content);
            sockets.send(sockets.ioPub, msg);
        }

        {
            JSONValue content;
            content["execution_count"] = executionCount;
            content["data"] = JSONValue();
            content["data"]["text/plain"] = result.result;
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
