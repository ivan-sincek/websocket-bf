# WebSocket BF

Brute force a REST API query through WebSocket. Based on cURL.

Tweak this tool to fit your scenario by modifying HTTP request headers and/or query strings within the script.

Tested on [socket.io](https://socket.io).

Tested on Kali Linux v2021.2 (64-bit).

Made for educational purposes. I hope it will help!

## How to Run

Open your preferred console from [/src/](https://github.com/ivan-sincek/websocket-bf/tree/master/src) and run the commands shown below.

Install required packages:

```fundamental
apt-get -y install bc jq
```

Change file permissions:

```fundamental
chmod +x websocket_bf.sh
```

Run the script:

```fundamental
./websocket_bf.sh
```

## Usage

```fundamental
WebSocket BF v1.9 ( github.com/ivan-sincek/websocket-bf )

--- Single request ---
Usage:   ./websocket_bf.sh -d domain              -p payload                             [-t token            ]
Example: ./websocket_bf.sh -d https://example.com -p '42["verify","{\"otp\":\"1234\"}"]' [-t xxxxx.yyyyy.zzzzz]

--- Brute force ---
Usage:   ./websocket_bf.sh -d domain              -p payload                                     -w wordlist             [-t token            ]
Example: ./websocket_bf.sh -d https://example.com -p '42["verify","{\"otp\":\"<injection/>\"}"]' -w all_numeric_four.txt [-t xxxxx.yyyyy.zzzzz]

DESCRIPTION
    Brute force a REST API query through WebSocket
DOMAIN
    Specify a target domain and protocol
    -d <domain> - https://example.com | https://192.168.1.10 | etc.
PAYLOAD
    Specify a query/payload to brute force
    Make sure to enclose it in single quotes
    Mark the injection point with <injection/>
    -p <payload> - '42["verify","{\"otp\":\"<injection/>\"}"]' | etc.
WORDLIST
    Specify a wordlist to use
    -w <wordlist> - all_numeric_four.txt | etc.
TOKEN
    Specify a token to use
    -t <token> - xxxxx.yyyyy.zzzzz | etc.
```
