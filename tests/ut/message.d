module ut.message;

import unit_threaded;
import jupyter.wire.message;

@("messageheader.non-null.username")
unittest {
  MessageHeader.empty.userName.shouldNotBeNull;
}

@("non-null.username")
unittest {
  auto message = Message(MessageHeader.empty, "dummy-type");
  message.parentHeader.userName.shouldNotBeNull;
  message.header.userName.shouldNotBeNull;
}

@("messageheader.non-null.session")
unittest {
  MessageHeader.empty.session.shouldNotBeNull;
}

@("non-null.session")
unittest {
  auto message = Message(MessageHeader.empty, "dummy-type");
  message.parentHeader.session.shouldNotBeNull;
  message.header.session.shouldNotBeNull;
}

@("copy-username")
unittest {
  auto message = Message(MessageHeader("id", "type", "username"), "dummy-type");
  message.parentHeader.userName.shouldEqual("username");
  message.header.userName.shouldEqual("username");
}

@("serialization")
unittest {
  auto raw = Message(MessageHeader("id", "type", "username"), "dummy-type").toStrings("dummy");
  auto message = Message(raw);
  message.parentHeader.userName.shouldEqual("username");
  message.header.userName.shouldEqual("username");
}

@("receive.non-null.username-and-session")
unittest {
  auto message = Message(
      [
          "<IDS|MSG>",
          "f3ceaa87a37567bf6e6431c75460596f2e8bd609960ccffc1224cc1105debe09",
          `{"msg_id":"7e65fba6-d785-4a0c-95ee-6be99ba8ed17","msg_type":"dummy-type","session":null,"date":"2020-11-15T15:06:37","version":null}`,
          `{"msg_id": "id", "msg_type": "type", "session": null, "date": null, "version": null}`,
          "{}",
          "{}",
      ]
  );
  message.parentHeader.userName.shouldNotBeNull;
  message.header.userName.shouldNotBeNull;
  message.parentHeader.session.shouldNotBeNull;
  message.header.session.shouldNotBeNull;
}
