install:
	cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
	cmake --build build
	sudo cmake --install build

restart:
	caelestia shell -k
	sleep 2
	caelestia shell -d
