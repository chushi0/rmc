@echo Cleaning Build Cache
@REM @cargo clean

@echo Building Windows debug dll
@cargo build
@echo Building Windows release dll
@cargo build --release

@echo Building Android arm64-v8a release dll
@wsl bash -l -c "sh build.sh"

@echo ALL BUILD DONE