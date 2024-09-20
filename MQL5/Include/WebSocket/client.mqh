//+------------------------------------------------------------------+
//|                                                       client.mqh |
//|                             Copyright 2020-2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "tools.mqh";
#include "frame.mqh";
#include "message.mqh";
#include "transport.mqh"
#include "protocol.mqh"

//+------------------------------------------------------------------+
//| Main WebSocket API for client applications                       |
//+------------------------------------------------------------------+
template<typename T>
class WebSocketClient: public IWebSocketObserver
{
protected:
   IWebSocketTransport *socket;
   IWebSocketConnection *connection;
   IWebSocketMessage *messages[];

   string scheme;
   string host;
   string port;
   string origin;
   string url;

   bool compression;
   bool isDebug;

   int timeOut;

public:
   WebSocketClient(const string address, const bool enableDebug = false, const bool useCompression = false)
   {
      string parts[];
      URL::parse(address, parts);

      url = address;
      compression = useCompression;
      isDebug = enableDebug;
      timeOut = 5000;

      scheme = parts[URL_SCHEME];
      if(scheme != "ws" && scheme != "wss")
      {
        Print("WebSocket invalid url scheme: ", scheme);
        scheme = "ws";
      }

      host = parts[URL_HOST];
      port = parts[URL_PORT];

      origin = (scheme == "wss" ? "https://" : "http://") + host;
   }

   ~WebSocketClient()
   {
      if(socket) delete socket;
      if(connection) delete connection;
      if(ArraySize(messages))
      {
        if (isDebug)
          PrintFormat("Deleting %d messages left unhandled", ArraySize(messages));
        for(int i = 0; i < ArraySize(messages); i++)
        {
          delete messages[i];
        }
      }
   }

   bool isConnected() const
   {
      return socket && socket.isConnected();
   }

   void setTimeOut(const int ms)
   {
      timeOut = fabs(ms);
   }

   int getTimeOut() const
   {
      return timeOut;
   }

   //+------------------------------------------------------------------+
   //| Default event handlers: to redefine them - create a derived class|
   //+------------------------------------------------------------------+

   void onDisconnect() override
   {
      if(isDebug)
        Print(" > Disconnected ", url);
   }

   void onConnected() override
   {
      if(isDebug)
        Print(" > Connected ", url);
   }

   void onMessage(IWebSocketMessage *msg) override
   {
      // Message can be binary, logging as string is just for informing you
      if (isDebug)
        Print(" > Message from WS: ", msg.getString());

      delete msg;
   }

   //+------------------------------------------------------------------+
   //| Main public methods                                              |
   //+------------------------------------------------------------------+
   bool open(const string customHeaders = NULL)
   {
      uint _port = (uint)StringToInteger(port);
      if(_port == 0)
      {
         if(scheme == "ws") _port = 80;
         else _port = 443;
      }

      socket = MqlWebSocketTransport::create(scheme, host, _port, timeOut);
      if(!socket || !socket.isConnected())
      {
         return false;
      }

      connection = new T(&this, socket, compression);
      return connection.handshake(url, host, origin, customHeaders);
   }

   bool send(const string str)
   {
      return connection ? connection.sendString(str) : false;
   }

   bool send(const uchar &data[])
   {
      return connection ? connection.sendData(data) : false;
   }

   bool sendMessage(IWebSocketMessage *msg)
   {
      return connection ? connection.sendMessage(msg) : false;
   }

   bool sendFrame(IWebSocketFrame *frame)
   {
      return connection ? connection.sendFrame(frame) : false;
   }

   void checkMessages(const bool blocking = true)
   {
      if (connection == NULL)
        return;

      uint stop = GetTickCount() + (blocking ? timeOut : 1);
      while (ArraySize(messages) == 0 && GetTickCount() < stop && isConnected())
      {
         // all frames are collected into corresponding messages (onMessage)
         // except for control frames, which are already processed and discarded
         if (!connection.checkMessages())
         {
            Sleep(100);
         }
      }
   }

   IWebSocketMessage *readMessage(const bool blocking = true)
   {
      if(ArraySize(messages) == 0) checkMessages(blocking);

      if(ArraySize(messages) > 0)
      {
         IWebSocketMessage *top = messages[0];
         ArrayRemove(messages, 0, 1);
         return top;
      }
      return NULL;
   }

   void close()
   {
      if(isConnected())
      {
         if(connection)
         {
            connection.disconnect(); // this closes socket internally after server ack
            delete connection;
            connection = NULL;
         }
         if(socket)
         {
            delete socket;
            socket = NULL;
         }
      }
   }
};
//+------------------------------------------------------------------+
