OUTPUT_DIR=warframe
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

echo stdout and stderr are scrapped since it\'s known to slow down warframe exe, logs can be found at \<wine_prefix\>/drive_c/users/\<name\>/Local\ Settings/Application\ Data/Warframe/Defrag.log and Preprocess.log

(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -silent -log:/Defrag.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/CacheDefraggerAsync /Tools/CachePlan.txt 2> /dev/null > /dev/null
	$WINEEXE Warframe.x64.exe -silent -log:/Preprocess.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/ContentUpdate 2> /dev/null > /dev/null
)
