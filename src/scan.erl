-module(scan).
-compile(export_all).
-include_lib("xmerl/include/xmerl.hrl").

head([]) -> [];
head(L) -> hd(L).
content(Element) -> Element#xmlElement.content.
elements(#xmlElement{} = List) -> [ A || A = #xmlElement{} <- content(List) ];
elements(List) -> [ A || A = #xmlElement{} <- List ].
first_child(X) when is_list(X) -> first_child(hd(X));
first_child(X) -> elements((head(elements(content(X))))#xmlElement.content).

name(Doc)       -> xmerl_xpath:string("//div[@class='persons-browse-primary-name']/span/text()", Doc).
title(Doc)      -> xmerl_xpath:string("//div[@class='persons-browse-primary-title']/span/text()", Doc).
id(Doc)         -> xmerl_xpath:string("//span[@class='persons-browse-names-link']/a/text()", Doc).
works(Doc)      -> xmerl_xpath:string("//span[@class='persons-browse-names-link']/ol/node()", Doc).
volumes(Doc)    -> xmerl_xpath:string("//li[@class='browse-persons-work-title']/text()", Doc).
work_title(Doc) -> xmerl_xpath:string("//li[@class='browse-persons-work-title']/a/span/text()", Doc).
work_id(Doc)    -> xmerl_xpath:string("//li[@class='browse-persons-work-title']/a/@href", Doc).
work_title2(D)  -> xmerl_xpath:string("//li/a/span/text()", D).
work_id2(D)     -> [hd(lists:reverse(xmerl_xpath:string("//li/a/text()", D)))].

value([]) -> [];
value([#xmlAttribute{value=V}]) -> [_,P]=string:tokens(V,"="),P;
value([_,#xmlText{value=V}]) ->
    E = lists:flatten([ try list_to_integer(X) catch _:_ -> [] end || X <- string:tokens(V,"[]")]),
    try [A] = E, A catch _:_ -> E end;
value([#xmlText{value=V}]) -> V.

tbrc_authors(File) ->
    {Xml,_} = xmerl_scan:file(File, [{encoding, "utf-8"}]),
    Authors = elements(Xml),
    Res = [ { cat, value(id(A)),
                   "",%unicode:characters_to_list(value(title(A))),
                   value(name(A)),
                      [ { pub, '',
                           value(volumes(X)),
                           value(work_title(X)),
                           '',
                           "",
                           [ { ver, list_to_atom(value(work_id(X))), [] } ] } || X <- elements(works(A)) ]}
       || A <- Authors ],
    file:write_file("meta-index.erl",unicode:characters_to_binary(io_lib:format("~tp",[Res]))),
    Res.

tbrc_plain(File) ->
    {Xml,_} = xmerl_scan:file(File, [{encoding, "utf-8"}]),
    Authors = elements(Xml),
    Res = [ { pub, '',
                  0,
                  value(work_title2(A)),
                  '',
                  "",
                  [ { ver, list_to_atom(value(work_id2(A))), [] } ] } || A <- Authors ],
    file:write_file("meta-plain.erl",unicode:characters_to_binary(io_lib:format("~tp",[Res]))),
    Res.
