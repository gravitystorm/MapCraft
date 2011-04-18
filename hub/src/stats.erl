-module(stats).
-behaviour(gen_server).

-compile(export_all).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%
%% Interface
%%
incr(Key) ->
	incr(Key, 1).

incr(Key, Val) ->
	gen_server:cast(?MODULE, {update, Key, Val}).

decr(Key) ->
	decr(Key, 1).

decr(Key, Val) ->
	gen_server:cast(?MODULE, {update, Key, -Val}).

set(Key, Value) ->
	gen_server:cast(?MODULE, {set, Key, Value}).

get_next(Key) ->
	{ok, Next} = gen_server:call(?MODULE, {get_next, Key}),
	Next.

dump() ->
	{ok, Dump} = gen_server:call(?MODULE, dump),
	Dump.

pdump() ->
	Dump = dump(),
	{Len, List} = lists:foldl(fun({K, V}, {Max, Cur}) ->
									  S = lists:flatten(io_lib:format("~p", [K])),
									  L = length(S),
									  {lists:max([Max, L]), [[S, V] | Cur]}
							  end, {0, []}, Dump),
	Sorted = lists:sort(List),
	FmtStr = lists:concat(["~-", Len, "s   ~p~n"]),
	[ io:format(FmtStr, Data) || Data <- Sorted],
	ok.

%%
%% gen_server callbacks
%%
init(_Args) ->
	Tab = ets:new(stats, [set, protected]),
	{ok, Tab}.


handle_call({get_next, Key}, _From, Tab) ->
	ensure_key(Tab, Key),
	Next = ets:update_counter(Tab, Key, 1),
	{reply, {ok, Next}, Tab};

handle_call(dump, _From, Tab) ->
	Dump = lists:concat([ets:tab2list(Tab), get_mem_info(), get_sys_info()]),
	{reply, {ok, Dump}, Tab}.


handle_cast({update, Key, Val}, Tab) ->
	ensure_key(Tab, Key),
	ets:update_counter(Tab, Key, Val),
	{noreply, Tab};

handle_cast({set, Key, Value}, Tab) ->
	ensure_key(Tab, Key),
	ets:update_element(Tab, Key, {2, Value}),
	{noreply, Tab}.

handle_info(_Msg, State) ->
	{noreply, State}.

code_change(_, State, _) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.

%%
%% Private
%%
get_mem_info() ->
	[ {{erlang,memory,K}, V} || {K, V} <- erlang:memory() ].

get_sys_info() ->
	[ {{erlang, processes, count}, erlang:system_info(process_count)} ].

%%
%% Implementation
%%
ensure_key(Tab, Key) ->
	case ets:lookup(Tab, Key) of
		[] ->
			ets:insert(Tab, {Key, 0});
		[_Obj] ->
			ok
	end.
