OUTPUT_DIR=warframe
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -silent -log:/Repair.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/CacheRepair
	$WINEEXE Warframe.x64.exe -silent -log:/Preprocess.log -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 -applet:/EE/Types/Framework/ContentUpdate
)
