//+------------------------------------------------------------------+
//|                                                        tools.mqh |
//|                             Copyright 2020-2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Various helper functions                                         |
//+------------------------------------------------------------------+
namespace WsTools
{
   // Parse HTTP headers (multiline) to an array of key[][0]/value[][1]
   int parseHeaders(const string header, string &retVal[][2])
   {
      string fields[];
      const int n = StringSplit(header, '\n', fields);
    
      ArrayResize(retVal, 0);
    
      for(int i = 0; i < n; i++)
      {
         StringReplace(fields[i], "\t", " ");
         string match[];
         
         if(StringSplit(URL::trim(fields[i]), ':', match) >= 2)
         {
            const int m = ArrayRange(retVal, 0);
            ArrayResize(retVal, m + 1);
            StringToLower(match[0]);  // make key case-insensitive
            retVal[m][0] = match[0];  // NB: if the same header key occured many times, it'll be added many times
            StringTrimLeft(match[1]); // skip leading blank after ':'
            retVal[m][1] = match[1];
            for(int j = 2; j < ArraySize(match); j++)
            {
               retVal[m][1] += ":" + match[j];
            }
         }
      }

      if(StringFind(header, "GET ") == 0)
      {
         const int p = StringFind(header, " HTTP/");
         if(p > 0)
         {
           const int m = ArrayRange(retVal, 0);
           ArrayResize(retVal, m + 1);
           retVal[m][0] = "GET";
           retVal[m][1] = StringSubstr(header, 4, p - 4);
         }
      }

      return ArrayRange(retVal, 0);
   }

   string arrayToHex(const uchar &array[], const int max = -1)
   { 
      string res = "";
      const int count = max == -1 ? ArraySize(array) : fmin(max, ArraySize(array));
      for(int i = 0; i < count; i++)
      {
         res += StringFormat("%.02X ", array[i]);
      }
      if(count < ArraySize(array)) res += "...";
      return res;
   }

   int charCount(const string data, const uchar c)
   {
      int count = 0;
      for(int i = 0; i < StringLen(data); i++)
      {
         if(data[i] == c) count++;
      }
      return count;
   }

   union BYTES4
   {
      uchar chars[4];
      uint  num;
      BYTES4(): num(0) { }
      BYTES4(uint n): num(n) { }
      BYTES4(const string &data) { WsTools::StringToByteArray(data, chars, 0, 4); }
      BYTES4(const uchar &data[], const int offset = 0) { ArrayCopy(chars, data, 0, offset, 4); }
      uchar operator[](int i) { return chars[i]; }
   };

   void pack4(uint number, uchar &data[], const int offset = 0)
   {
      BYTES4 b;
      b.num = MathSwap(number);
      ArrayCopy(data, b.chars, offset);
   }

   uint unpack4(const string data, const int offset = 0)
   {
      BYTES4 b;
      b.chars[0] = (uchar)data[0 + offset];
      b.chars[1] = (uchar)data[1 + offset];
      b.chars[2] = (uchar)data[2 + offset];
      b.chars[3] = (uchar)data[3 + offset];
      return MathSwap(b.num); // TODO: consider redo without swap
   }

   uint unpack4(const uchar &data[], const int offset = 0)
   {
      BYTES4 b;
      b.chars[0] = (uchar)data[0 + offset];
      b.chars[1] = (uchar)data[1 + offset];
      b.chars[2] = (uchar)data[2 + offset];
      b.chars[3] = (uchar)data[3 + offset];
      return MathSwap(b.num); // TODO: consider redo without swap
   }

   union BYTES2
   {
      uchar chars[2];
      ushort  num;
      BYTES2(): num(0) { }
      BYTES2(ushort n): num(n) { }
      uchar operator[](int i) { return chars[i]; }
   };

   void pack2(ushort number, uchar &data[], const int offset = 0)
   {
      BYTES2 b;
      b.num = MathSwap(number);
      ArrayCopy(data, b.chars, offset);
   }

   ushort unpack2(const string data, const int offset = 0)
   {
      BYTES2 b;
      b.chars[0] = (uchar)data[0 + offset];
      b.chars[1] = (uchar)data[1 + offset];
      return MathSwap(b.num);
   }

   ushort unpack2(const uchar &data[], const int offset = 0)
   {
      BYTES2 b;
      b.chars[0] = (uchar)data[0 + offset];
      b.chars[1] = (uchar)data[1 + offset];
      return MathSwap(b.num);
   }

   template<typename T>
   void push(T *&array[], T *ptr)
   {
      const int n = ArraySize(array);
      ArrayResize(array, n + 1);
      array[n] = ptr;
   }

   template<typename T>
   void push(T &array[][2], T key, T value)
   {
      const int n = ArrayRange(array, 0);
      ArrayResize(array, n + 1);
      array[n][0] = key;
      array[n][1] = value;
   }
   
   // NB: StringToCharArray copies to specific part (start/count) of the receiving array (which is confusing)
   // StringToByteArray is intended to copy specific part of the given string
   int StringToByteArray(const string text, uchar &array[], const int start = 0, const int count = -1, const uint cp = CP_ACP)
   {
      if(cp == CP_ACP)
      {
         const int n = count == -1 ? StringLen(text) - start : count;
         ArrayResize(array, n);
         for(int i = 0; i < n; i++)
         {
            array[i] = (uchar)StringGetCharacter(text, i + start);
         }
         return n;
      }
      else
      {
         int n = StringToCharArray((start || count != -1) ?
            StringSubstr(text, start, count) : text, array, 0, -1, cp);
         if(n > 0 && array[n - 1] == 0)
         {
            ArrayResize(array, --n);
         }
         return n;
      }
      return 0;
   }

   string stringify(const uchar &data[], const int limit = -1)
   {
      string result = "";
      const int count = limit == -1 ? ArraySize(data) : MathMin(limit, ArraySize(data));
      StringReserve(result, count);
      for(int i = 0; i < count; i++)
      {
         result += StringFormat("%C", data[i]);
      }
      return result;
   }
};

//+------------------------------------------------------------------+
//| URL components                                                   |
//+------------------------------------------------------------------+
enum URL_PARTS
{
   URL_COMPLETE,
   URL_SCHEME,   // protocol
   URL_USER,     // deprecated/not supported/null
   URL_HOST,
   URL_PORT,
   URL_PATH,
   URL_QUERY,
   URL_FRAGMENT, // not extracted/null
   URL_ENUM_LENGTH
};

//+------------------------------------------------------------------+
//| URL parser                                                       |
//+------------------------------------------------------------------+
class URL
{
public:
   static bool isAlpha(const uchar c)
   {
    	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
   }

   static bool isDigit(const uchar c) 
   {
      return c >= '0' && c <= '9';
   }

   static bool isAlNum(const uchar c)
   {
    	return isAlpha(c) || isDigit(c);
   }
    
   static string encode(const string str)
   {
      string new_str = "";
      uchar c;

      uchar chars[];
      const int len = StringToCharArray(str, chars);
  
      for(int i = 0; i < len; i++)
      {
         c = chars[i];
         if(c == ' ') new_str += "+";
         else if(isAlNum(c) || c == '-' || c == '_' || c == '.' || c == '~') new_str += (string)c;
         else
         {
            new_str += "%" + StringFormat("%%%.2X", c);
         }
      }
      return new_str;
   }

   static uchar hex2value(const uchar hex)
   {
      uint result = hex - '0';
      if(result > 9)
      {
         result = hex - 'A' + 10;
         if(result > 15)
         {
            result = hex - 'a' + 10;
         }
      }
      return (uchar)result;
   }

    // TODO: 2-byte/3-byte encodings support

   static string decode(const string str)
   {
      string ret;
      uchar chars[];
      const int len = StringToCharArray(str, chars);
  
      for(int i = 0; i < len; i++)
      {
         if(chars[i] != '%')
         {
            if(chars[i] == '+')
               ret += " ";
            else
               ret += (string)chars[i];
         }
         else
         {
            ret += (string)(uchar)(hex2value(chars[i + 1]) * 16 + hex2value(chars[i + 2]));
            i += 2;
         }
      }
      return ret;
   }

   static string trim(string &str)
   {
      StringTrimLeft(str);
      StringTrimRight(str);
      return str;
   }

   // scheme://example.com:80/path?query#hash
   static void parse(string url, string &parts[])
   {
      const static string start = "://";
      const static string comma = ":";
      const static string slash = "/";
      const static string question = "?";

      ArrayResize(parts, URL_PARTS::URL_ENUM_LENGTH);
      for(int i = 0; i < URL_PARTS::URL_ENUM_LENGTH; i++)
      {
         parts[i] = NULL;
      }

      parts[0] = url; // TODO: re-assemble url from parts

      int c = 0;
      int p = StringFind(url, start);
      if(p > -1)
      {
         parts[URL_SCHEME] = StringSubstr(url, 0, p);
         p += StringLen(start);
         c = p;
      }
      
      p = StringFind(url, comma, c);
      int path = StringFind(url, slash, c);
      int port = -1;
      if(p > -1 && (p < path || path == -1))
      {
         port = p;
         parts[URL_HOST] = StringSubstr(url, c, p - c);
      }
      
      if(path > -1)
      {
         parts[URL_HOST] = StringSubstr(url, c, (port != -1 ? port : path) - c);
         c = path + 1;
      }
      else
      {
         parts[URL_HOST] = StringSubstr(url, c, (port != -1 ? port : StringLen(url)) - c);
         c = StringLen(url) + 1;
      }
      
      if(port > -1)
      {
         parts[URL_PORT] = StringSubstr(url, port + 1, c - port - 2);
      }
      
      if(path > -1)
      {
         p = StringFind(url, question, path);
         c = p;
         if(p == -1) p = StringLen(url);
         parts[URL_PATH] = StringSubstr(url, path, p - path);
         if(c > -1)
         {
            parts[URL_QUERY] = StringSubstr(url, c + 1);
         }
      }
      else
      {
         parts[URL_PATH] = "/";
      }
   }
};
//+------------------------------------------------------------------+
