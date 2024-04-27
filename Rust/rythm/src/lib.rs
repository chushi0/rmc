use godot::prelude::*;

struct Rythm;

#[gdextension]
unsafe impl ExtensionLibrary for Rythm {
    fn on_level_init(_level: InitLevel) {
        ffmpeg_next::init().unwrap();
    }
}

mod beatmap;
mod video;
