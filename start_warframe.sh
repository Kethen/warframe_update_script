OUTPUT_DIR=warframe
if [ -z "$WINEEXE" ]
then
	WINEEXE=wine
fi

echo stdout and stderr are scrapped since it\'s known to slow down warframe exe
(
	cd "$OUTPUT_DIR"
	$WINEEXE Warframe.x64.exe -fullscreen:1 -graphicsDriver:dx11 -cluster:public -language:en -deferred:0 2> /dev/null > /dev/null
)
