install:
	cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DENABLE_MODULES="extras;plugin;shell;m3shapes"
	cmake --build build
	sudo cmake --install build

restart:
	caelestia shell -k
	sleep 2
	caelestia shell -d
