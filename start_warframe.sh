OUTPUT_DIR=warframe
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

echo starting warframe
(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -fullscreen:1 -graphicsDriver:dx11 -cluster:public -language:en -deferred:0
)
