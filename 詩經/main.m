(* ::Package:: *)

(* ::Chapter:: *)
(*Settings*)


SetDirectory@NotebookDirectory[];


(* ::Chapter:: *)
(*Functions*)


MapMonitor = ResourceFunction["DynamicMap"];


(* ::Chapter:: *)
(*Chapters*)


Block[
	{format, getTitle, chapters},
	If[FileExistsQ@"Chapter.CSV", Return[Nothing]];
	format[link_, chapter_, contant_] := Block[
		{},
		If[!StringContainsQ[link, "book-of-poetry"], Return[Nothing]];
		If[chapter == "\:8a69\:7d93", Return[Nothing]];
		Cases[contant,
			XMLElement["a", {__, "href" -> h_}, {c_}] :> <|
				"chapter" -> StringJoin["\:8a69\:7d93|", chapter, "|", c],
				"routing" -> StringJoin[StringTake[link, ;; -3], StringSplit[h, "/"][[2]]],
				"url" -> "https://ctext.org/" <> h
			|>,
			Infinity
		]
	];
	getTitle[chapter_Association] := Cases[
		Import[chapter["url"], {"HTML", "XMLObject"}],
		XMLElement["a", {"shape" -> "rect", "class" -> "popup", "href" -> h_}, {c_}] :> <|
			"Chapter" -> StringJoin[chapter["chapter"], "|", c],
			"Routing" -> StringJoin[chapter["routing"], "/", StringSplit[h, "/"][[2]]],
			"Token" -> "ctp:" <> StringTake[h, ;; -4]
		|>,
		Infinity
	];
	chapters = Flatten@Cases[
		Import["https://ctext.org/book-of-poetry/zh", {"HTML", "XMLObject"}],
		XMLElement[
			"span",
			{"class" -> "menuitem container"},
			{
				XMLElement["a", {__, "href" -> link_}, {chapter_}],
				__,
				XMLElement["span", {"class" -> "subcontents"}, contant_]
			}
		] :> format[link, chapter, contant],
		Infinity
	];
	Export["Chapter.CSV", Dataset@Flatten[MapMonitor[getTitle, chapters][[2]]]]
];


(* ::Chapter:: *)
(*Content*)


Block[
	{$wait = 0.5, askS, askT, read},
	If[FileExistsQ@"data.json", Return[Nothing]];
	askS[url_String] := Check[
		Pause@RandomReal[$wait];
		Import["https://api.ctext.org/gettext?if=zh&remap=gb&urn=" <> url, "RawJSON"],
		askS[url]
	];
	askT[url_String] := Check[
		Pause@RandomReal[$wait];
		Import["https://api.ctext.org/gettext?if=zh&urn=" <> url, "RawJSON"],
		askT[url]
	];
	read[record_Association] := <|
		"Chapter" -> record@"Chapter",
		"Traditional" -> askT[record@"Token"]["fulltext"],
		"Simplified" -> askS[record@"Token"]["fulltext"]
	|>;
	data = MapMonitor[read, chapters][[2]];
	Export["data.json", Dataset@data, "RawJSON"]
];
