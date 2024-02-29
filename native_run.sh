sh 01_prepare.sh mt7981-ax3000.config
cd immortalwrt-mt798x
make -j8
cd bin/targets/mediatek/mt7981
7z a -mx=9 ../../../../../mt7981.7z immortalwrt-mediatek-mt7981*squashfs*
