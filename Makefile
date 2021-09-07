build:
	$(RM) -rf dist
	mkdir -p dist
	echo "# Do not edit! Auto generated" > dist/lib
	echo >> dist/lib
	cat src/lib.bash >> dist/lib
	cp src/settings dist
	cp src/libbuild.bash dist/libbuild
	cd dist && bash libbuild
	$(RM) dist/libbuild
	tar cvz dist > dist.tgz

clean:
	$(RM) -rf dist
	$(RM) -rf dist.tgz
