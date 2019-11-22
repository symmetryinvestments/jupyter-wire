module jupyter.wire.kernel;

import jupyter.wire.message: Message;

enum protocolVersion = "5.3.0";

/**
   So users don't have to write their own main
 */
mixin template Main(Backend) {
    int main(string[] args) {
        import jupyter.wire.log: log;
        try {
            run!Backend(args);
            return 0;
        } catch(Exception e) {
            log("Error: ", e.msg);
            return 1;
        } catch(Error e) {
            log("FATAL ERROR: ", e.toString);
            return 2;
        }
    }
}

void run(Backend)(in string[] args) {
    import jupyter.wire.kernel: Kernel;
    import std.exception: enforce;

    const exeName = args.length > 0 ? args[0] : "<exeName>";
    enforce(args.length == 2, "Usage: " ~ exeName ~ " <connectionFileName>");

    const connectionFileName = args[1];
    auto backend = Backend();
    auto k = kernel(backend, connectionFileName);
    k.run;
}


struct LanguageInfo {
    string name;
    string version_;
    string fileExtension;
    string mimeType;
}


struct ExecutionResult {
    string result;
    string stdout;
    string mime = "text/plain";
}


struct Stdout {
    string value;
}

alias IoPubMessageSender = void delegate(Message);

ExecutionResult textResult(string result, Stdout stdout = Stdout("")) @safe pure nothrow {
    return ExecutionResult(result, stdout.value, "text/plain");
}

ExecutionResult markdownResult(string result, Stdout stdout = Stdout("")) @safe pure nothrow {
    return ExecutionResult(result, stdout.value, "text/markdown");
}


template isBackend(T) {
    enum isBackend = is(typeof({
        LanguageInfo info = T.init.languageInfo;
        ExecutionResult result = T.init.execute("foo");
    }));
}


auto kernel(Backend, Args...)(Backend backend, auto ref Args args) {
    return Kernel!Backend(backend, args);
}


/**
   Implements a generic Jupyter kernel.
   Parameterised by a `Backend` type that knows how to execute code.

 */
struct Kernel(Backend) if(isBackend!Backend) {

    import jupyter.wire.connection: ConnectionInfo, Sockets;
    import zmqd: Socket;
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
        import std.traits : hasMember;
        import jupyter.wire.log: log;

        log("Jupyter kernel starting with connection info ", connectionInfo);

        this.backend = backend;
        this.sockets = Sockets(connectionInfo);
        static if (hasMember!(Backend, "initialize"))
            this.backend.initialize();
    }

    void run()  {
        import jupyter.wire.connection: recvRequestMessage;
        import std.datetime: msecs;
        import core.thread: Thread;

        for(;!stop;) {
            maybeHandleRequestMessage(sockets.shell.recvRequestMessage);
            maybeHandleRequestMessage(sockets.control.recvRequestMessage);
            () @trusted { Thread.sleep(10.msecs); }();
        }
    }

    void maybeHandleRequestMessage(Nullable!Message requestMessage)  {
        if(requestMessage.isNull) return;

        version(JupyterLogVerbose) {
            import jupyter.wire.log: log;
            log("Received message from the front-end.");
        }

        handleRequestMessage(requestMessage.get);
    }

    void handleRequestMessage(Message requestMessage)  {

        import jupyter.wire.message: statusMessage, pubMessage;
        import jupyter.wire.log: log;
        import std.json : JSONValue, parseJSON;

        version(JupyterLogVerbose) log("Sending busy message to the FE");
        auto busyMsg = statusMessage(requestMessage.header, "busy");
        sockets.send(sockets.ioPub, busyMsg);

        scope(exit) {
            version(JupyterLogVerbose) log("Sending idle message to the FE");
            auto idleMsg = statusMessage(requestMessage.header, "idle");
            sockets.send(sockets.ioPub, idleMsg);
        }

        switch(requestMessage.header.msgType) {

        default: return;

        case "complete_request":
            handleCompleteRequest(requestMessage);
            return;

        case "shutdown_request":
            version(JupyterLogVerbose) log("Told by the FE to shutdown");
            handleShutdown(requestMessage);
            return;

        case "kernel_info_request":
            version(JupyterLogVerbose) log("Asked by the FE to return kernel info");
            handleKernelInfoRequest(requestMessage);
            return;

        case "execute_request":
            version(JupyterLogVerbose) log("Told by the FE to execute code");
            handleExecuteRequest(requestMessage);
            return;

        case "comm_open":
            version(JupyterLogVerbose) log("Told by the FE to open a comm");
            handleCommOpen(requestMessage);
            return;

        case "comm_msg":
            version(JupyterLogVerbose) log("Received a comm msg from the FE");
            handleCommMessage(requestMessage);
            return;

        case "comm_close":
            version(JupyterLogVerbose) log("Told by the FE to close a comm");
            handleCommClose(requestMessage);
            return;
        }

        assert(0);
    }

    void handleCommOpen(Message requestMessage) {
        import jupyter.wire.message: commCloseMessage;
        import std.traits: hasMember;

        bool success = false;
        scope(exit) if (!success) {
                auto msg = commCloseMessage(requestMessage);
                sockets.send(sockets.ioPub, msg);
            }

        static if (hasMember!(typeof(backend), "commOpen")) {
            scope sender = (Message msg){
                    msg.parentHeader = requestMessage.header;
                    sockets.send(sockets.ioPub, msg);
                };
            success = backend.commOpen(requestMessage.content["comm_id"].str,
                                       requestMessage.content["target_name"].str,
                                       requestMessage.metadata["version"].str,
                                       requestMessage.content["data"],
                                       sender);
        }
    }

    void handleCommMessage(Message requestMessage) {
        import std.traits: hasMember;

        static if (hasMember!(typeof(backend), "commMessage")) {
            scope sender = (Message msg){
                    msg.parentHeader = requestMessage.header;
                    sockets.send(sockets.ioPub, msg);
                };
            backend.commMessage(requestMessage.content["comm_id"].str,
                                requestMessage.content["data"],
                                sender);
        }
    }

    void handleCommClose(Message requestMessage) {
        import std.traits: hasMember;

        static if (hasMember!(typeof(backend), "commClose")) {
            scope sender = (Message msg){
                    msg.parentHeader = requestMessage.header;
                    sockets.send(sockets.ioPub, msg);
                };
            backend.commClose(requestMessage.content["comm_id"].str,
                              requestMessage.content["data"],
                              sender);

        }
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
        import std.traits : hasMember;

        JSONValue[string] languageInfo;
        languageInfo["name"] = backend.languageInfo.name;
        languageInfo["version"] = backend.languageInfo.version_;
        languageInfo["file_extension"] = backend.languageInfo.fileExtension;
        static if (hasMember!(LanguageInfo,"mimeType"))
            languageInfo["mimetype"] = backend.languageInfo.mimeType;

        JSONValue kernelInfo;
        kernelInfo["status"] = "ok";
        kernelInfo["protocol_version"] = protocolVersion;
        kernelInfo["implementation"] = "foo";
        kernelInfo["implementation_version"] = "0.0.1";
        kernelInfo["language_info"] = languageInfo;
        static if (hasMember!(Backend, "banner"))
            kernelInfo["banner"] = backend.banner;

        auto replyMessage = Message(requestMessage, "kernel_info_reply", kernelInfo);
        sockets.send(sockets.shell, replyMessage);
    }

    void handleCompleteRequest(Message requestMessage) {
        import jupyter.wire.message: completeMessage;
        import std.traits: hasMember;

        static if (hasMember!(typeof(backend), "complete")) {
            const result = backend.complete(requestMessage.content["code"].str,
                                            requestMessage.content["cursor_pos"].integer);
            auto msg = completeMessage(requestMessage, result);
            sockets.send(sockets.shell, msg);
        }
    }

    void handleExecuteRequest(Message requestMessage)  {
        import jupyter.wire.message: pubMessage;
        import std.json: JSONValue, parseJSON, JSONType;
        import std.conv: text;

        scope(exit) {
            if(requestMessage.content["store_history"].type == JSONType.true_)
            ++executionCount;
        }

        {
            JSONValue content;
            content["execution_count"] = executionCount;
            content["code"] = requestMessage.content["code"];
            auto msg = pubMessage(requestMessage.header, "execute_input", content);
            sockets.send(sockets.ioPub, msg);
        }

        try {

            const result = backend.execute(requestMessage.content["code"].str);
            sockets.stdout(requestMessage.header, result.stdout);

            {
                JSONValue content;
                content["execution_count"] = executionCount;
                content["data"] = JSONValue();
                content["data"][result.mime] = result.result;
                content["metadata"] = parseJSON(`{}`);
                sockets.publish(requestMessage.header, "execute_result", content);
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

        } catch(Exception e) {

            sockets.stdout(requestMessage.header, text("Error: ", e.msg));

            {
                JSONValue content;
                content["status"] = "error";
                content["execution_count"] = executionCount;
                content["ename"] = typeid(e).name;
                content["evalue"] = e.msg;
                content["traceback"] = text(e);

                auto replyMessage = Message(requestMessage, "execute_reply", content);
                sockets.send(sockets.shell, replyMessage);
            }
        }
    }
}
