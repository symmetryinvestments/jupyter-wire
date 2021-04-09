module ut.message;

import unit_threaded;
import jupyter.wire.message;


@("deserialise.nullfields")
unittest {
  auto message = Message(
      [
          "<IDS|MSG>",
          "f3ceaa87a37567bf6e6431c75460596f2e8bd609960ccffc1224cc1105debe09",
          `{"msg_id":"7e65fba6-d785-4a0c-95ee-6be99ba8ed17","msg_type":"dummy-type","session":null,"date":"2020-11-15T15:06:37","version":null}`,
          `{}`,
          "{}",
          "{}",
      ]
  );
}


@("serialise.nonullfields")
@safe unittest {
    const message = Message(
        [
          "<IDS|MSG>",
          "f3ceaa87a37567bf6e6431c75460596f2e8bd609960ccffc1224cc1105debe09",
          `{"msg_id": "leid", "msg_type": "dummy-type", "date": "2020-11-15T15:06:37"}`,
          `{"msg_id": "pid", "msg_type": "parent", "date": "2020-11-15T15:06:37"}`,
          "{}",
          "{}",
        ]
    );

    message.toStrings("key").should == [
        "<IDS|MSG>",
        "d2f0f5051d79d72cbaf5c7f53aecf5436e56a8adc8f9c66452f9f299d18ddf77",
        `{"msg_id":"leid","msg_type":"dummy-type","username":"","session":"","date":"2020-11-15T15:06:37","version":""}`,
        `{"msg_id":"pid","msg_type":"parent","username":"","session":"","date":"2020-11-15T15:06:37","version":""}`,
        "{}",
        "{}",
    ];
}


@("copy-username")
@safe unittest {
  auto message = Message(MessageHeader("id", "type", "username"), "dummy-type");
  message.parentHeader.userName.should == "username";
  message.header.userName.should == "username";
}


@("serialization")
@safe unittest {
  auto raw = Message(MessageHeader("id", "type", "username"), "dummy-type").toStrings("dummy");
  auto message = Message(raw);
  message.parentHeader.userName.should == "username";
  message.header.userName.should == "username";
}
