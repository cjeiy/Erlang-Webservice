-module(rudy).
-export([start/1,init/1,handler/1,request/1,reply/1]).
start_more(0, _)-> ok;
start_more(N, Listen)->
    spawn(rudy,handler,[Listen]),
    start_more(N - 1, Listen).

start(Port) ->
    register(rudy, spawn(fun() ->
				 init(Port) end)).


init(Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opt) of
	{ok, Listen} ->
	    start_more(3,Listen),
	    handler(Listen),
	    gen_tcp:close(Listen),
	    ok;
	{error, Error} ->
	    error
end.



handler(Listen) ->
    case gen_tcp:accept(Listen) of
	{ok, Client} ->
	    request(Client),
	    gen_tcp:close(Client),
	    handler(Listen);
	{error, Error}->
	     error
end.



request(Client)->
    Recv = gen_tcp:recv(Client,0),
    case Recv of
	{ok, Str} ->
	    Request = http:parse_request(Str),
	    Response = reply(Request),
	    gen_tcp:send(Client,Response);
	{error,Error} -> 
	    io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).



reply({{get, URI, _}, _, _}) ->
    timer:sleep(20),
    http:ok("Hello there! I'm a Reply").
