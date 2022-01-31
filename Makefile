all: tools

# docker
docker-build:
	docker build --no-cache -t edin.iwslt2021.v4 .
docker-save:
	docker save edin.iwslt2021.v4 > edin.iwslt2021.v4.tar

# install tools
tools: tools/marian-dev

tools/marian-dev:
	git clone https://github.com/marian-nmt/marian-dev.git $@
	mkdir -p $@/build && cd $@/build && cmake .. -DBUILD_ARCH=haswell -DUSE_STATIC_LIBS=on -DCMAKE_BUILD_TYPE=Release -DCOMPILE_SERVER=on -DCOMPILE_CPU=on && make -j 16 && rm -rf src/ local/

.PHONY: all tools
