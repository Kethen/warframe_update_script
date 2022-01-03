OUTPUT_DIR=warframe
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -silent -log:/Defrag.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/CacheDefraggerAsync /Tools/CachePlan.txt
	$WINEEXE Warframe.x64.exe -silent -log:/Preprocess.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/ContentUpdate
)
