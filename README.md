# WebSocket library for Meta Trader 5

This repo is copy of library from this source: https://www.mql5.com/en/code/45593 will small adjustments.

All rights belongs to MetaQuotes.

Read more about [this implementation](https://www.mql5.com/en/book/advanced/project/project_websocket_mql5).

## Features
- Simple setup
- No DLL required
- No OpenSSL installation required
- Supports `wss` (secure connection)
- Written in pure MQL5

## How to use

Copy repo to your MT5 folder.
Should be: `<mt5_folder>/MQL5/Include/WebSocket/*.mqh`.

In your Expert Advisor:
```
#include <WebSocket/client.mqh>

const string WS_URL = "ws://127.0.0.1:3331/ws";
const bool isDebug = true;

class WS : public WebSocketClient<Hybi>
{
public:
    WS(const string address, const bool debug = false, const bool useCompression = false)
        : WebSocketClient(address, debug, useCompression) {}

    // Received message from server
    void onMessage(IWebSocketMessage *msg) override
    {
        // Implement your logic
        if (isDebug)
            Print(" > Message from custom WS: ", msg.getString());

        delete msg;
    }
};

WS WebSocket(WS_URL, isDebug, true);

int OnInit()
{
    if (!WebSocket.open())
    {
        Alert(StringFormat(
            "[FAIL] Cannot initialize WebSocket connection.\n"
            "Please, check if [ %s ] had been added to allowed URLs and check Internet connection",
            WS_URL));
        return INIT_FAILED;
    }
    EventSetTimer(5);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    EventKillTimer();
    delete &WebSocket;
}

void OnTimer()
{
    if (!WebSocket.isConnected())
    {
        Print("WS is not connected");
        EventKillTimer();
        return;
    }

    // Use a non-blocking check
    WebSocket.checkMessages(false);

    string data = "{\"event_type\": \"ping\"}";

    if (!WebSocket.send(data))
    {
        if (isDebug)
            Print("Cannot send data via WebSocket. Error: ", GetLastError());
        WebSocket.close();
        EventKillTimer();
    }
}
```

