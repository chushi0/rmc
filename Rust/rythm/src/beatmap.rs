use anyhow::{anyhow, Result};
use godot::{
    engine::{
        file_access::ModeFlags, global::Error, AudioStream, AudioStreamMp3, AudioStreamOggVorbis,
        AudioStreamWav, DirAccess, FileAccess, Image, ZipReader,
    },
    obj::NewGd,
    prelude::*,
};
use num_traits::cast::ToPrimitive;
use osu_file_parser::{events::Event, hitobjects::HitObject, Decimal, OsuFile, Position};
use std::{fmt::Display, path::PathBuf, str::FromStr};

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct OszFile {
    #[var]
    path: GString, // osz文件路径
    #[var]
    beatmaps: Array<Gd<Beatmap>>, // 谱面
}

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct Beatmap {
    #[var]
    audio: GString, // 音频
    #[var]
    background: GString, // 背景图
    #[var]
    video: GString, // 背景视频

    #[var]
    preview_time: i32,

    #[var]
    name: GString,
    #[var]
    title: GString,

    #[var]
    objects: Array<Gd<BeatmapObject>>, // 物件
    #[var]
    timings: Array<Gd<BeatmapTiming>>, // 时间
}

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct BeatmapObject {
    #[var]
    position: f32, // 位置
    #[var]
    time: u32, // 时间，单位毫秒
}

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct BeatmapTiming {
    #[var]
    time: u32, // 开始时间
    #[var]
    kiai_mode: bool, // KiAi模式
    slide_speed: f32, // 滑条速度（乘以 100 后可得到该速度下每拍内滑条会经过多少OSU像素）
    #[var]
    mspb: u32, // 每拍多少毫秒
}

#[godot_api]
impl OszFile {
    #[func]
    pub fn import_file(file: GString) -> GString {
        let mut reader = ZipReader::new_gd();
        if reader.open(file.clone()) != Error::OK {
            godot_error!("import file fail: {file}");
            return GString::new();
        }

        let file = file.to_string().replace('\\', "/");
        let mut name: &str = &file;
        if let Some(index) = name.rfind('/') {
            name = &name[index + 1..];
        }
        if let Some(index) = name.rfind('.') {
            name = &name[..index];
        }

        let path = if FileAccess::file_exists(format!("user://osz/{name}").to_godot()) {
            let mut index = 2;
            while FileAccess::file_exists(format!("user://osz/{name} ({index})").to_godot()) {
                index += 1;
            }
            format!("user://osz/{name} ({index})")
        } else {
            format!("user://osz/{name}")
        };

        for rfile in reader.get_files().as_slice() {
            let wfile = format!("{path}/{rfile}");
            if DirAccess::make_dir_recursive_absolute(
                wfile[..wfile.rfind('/').unwrap()].to_string().to_godot(),
            ) != Error::OK
            {
                godot_error!("mkdir error");
            }

            let Some(mut access) = FileAccess::open(wfile.to_godot(), ModeFlags::WRITE) else {
                godot_error!("open write path fail");
                return GString::new();
            };
            let data = reader.read_file(rfile.clone());
            access.store_buffer(data);
        }

        path.to_godot()
    }

    #[func]
    pub fn parse_file(&mut self, path: GString) -> bool {
        self.path = path.clone();
        self.beatmaps.clear();

        let files = DirAccess::get_files_at(path);
        for file in files.as_slice() {
            let rfile: String = file.into();
            if !rfile.to_lowercase().ends_with(".osu") {
                continue;
            }

            let beatmap = match self.parse_beatmap(file) {
                Ok(beatmap) => beatmap,
                Err(err) => {
                    godot_error!("parse file error: {err}");
                    continue;
                }
            };
            self.beatmaps.push(Gd::from_object(beatmap));
        }

        true
    }

    fn get_absolute_file(&self, file: impl Display) -> Result<String> {
        DirAccess::open(self.path.clone())
            .map(|access| access.get_current_dir_ex().done().to_string())
            .map(|path| format!("{}/{}", path, file))
            .ok_or_else(|| {
                godot_warn!("open file fail: {}/{}", self.path, file);
                anyhow!("open file fail: {}", file)
            })
    }

    fn read_file(&self, file: impl Display) -> Result<PackedByteArray> {
        let path = self.get_absolute_file(file)?.to_godot();
        if !FileAccess::file_exists(path.clone()) {
            return Err(anyhow!("file not found"));
        }
        Ok(FileAccess::get_file_as_bytes(path.to_godot()))
    }

    #[func]
    pub fn read_image(&self, path: String) -> Gd<Image> {
        let content = self.read_file(&path).unwrap_or_default();

        let mut image = Image::new_gd();

        let lower_filename = path.to_string().to_lowercase();
        if lower_filename.ends_with(".jpg") || lower_filename.ends_with(".jpeg") {
            image.load_jpg_from_buffer(content);
        } else if lower_filename.ends_with(".png") {
            image.load_png_from_buffer(content);
        } else if lower_filename.ends_with(".tga") {
            image.load_tga_from_buffer(content);
        } else if lower_filename.ends_with(".bmp") {
            image.load_bmp_from_buffer(content);
        }

        image
    }

    #[func]
    pub fn read_audio(&self, path: String) -> Gd<AudioStream> {
        let content = self.read_file(&path).unwrap_or_default();

        let mut audio = AudioStream::new_gd();

        let lower_filename = path.to_string().to_lowercase();
        if lower_filename.ends_with(".mp3") {
            let mut codec = AudioStreamMp3::new_gd();
            codec.set_data(content);
            audio = codec.upcast();
        } else if lower_filename.ends_with(".wav") {
            let mut codec = AudioStreamWav::new_gd();
            codec.set_data(content);
            audio = codec.upcast();
        } else if lower_filename.ends_with(".ogg") {
            let codec = AudioStreamOggVorbis::load_from_buffer(content).unwrap_or_default();
            audio = codec.upcast();
        }

        audio
    }

    fn parse_beatmap(&mut self, file: &GString) -> Result<Beatmap> {
        let path = self.get_absolute_file(file)?;
        let osu_data = FileAccess::get_file_as_string(path.to_godot()).to_string();
        let osu_file = OsuFile::from_str(&osu_data)?;

        Beatmap::new(osu_file)
    }
}

impl Beatmap {
    fn new(osu_file: OsuFile) -> Result<Self> {
        let difficulty = osu_file.difficulty.unwrap_or_default();
        let base_slider_multipler: osu_file_parser::osu_file::types::Decimal =
            difficulty.slider_multiplier.unwrap().into();
        let base_slider_multipler = base_slider_multipler
            .get()
            .clone()
            .left()
            .unwrap_or_default()
            .to_f32()
            .unwrap_or_default();

        let general = osu_file.general.unwrap_or_default();

        let mut timings: Vec<BeatmapTiming> = Vec::new();

        osu_file
            .timing_points
            .unwrap_or_default()
            .0
            .into_iter()
            .for_each(|timing| {
                let mut slide_speed = timings
                    .last()
                    .map(|timing| timing.slide_speed)
                    .unwrap_or(base_slider_multipler);
                let mut mspb = timings.last().map(|timing| timing.mspb).unwrap_or(1000);

                if timing.uninherited() {
                    mspb = (60000.0
                        / timing
                            .calc_bpm()
                            .map(|bpm| bpm.to_f32().unwrap_or(60.0))
                            .unwrap_or(60.0)) as u32;
                } else {
                    slide_speed = base_slider_multipler
                        * timing
                            .calc_slider_velocity_multiplier()
                            .map(|speed| speed.to_f32().unwrap_or(1.0))
                            .unwrap_or(1.0);
                }

                let beatmap_timing = BeatmapTiming {
                    time: timing
                        .time()
                        .get()
                        .clone()
                        .left()
                        .unwrap_or_default()
                        .to_u32()
                        .unwrap_or_default(),
                    kiai_mode: timing
                        .effects()
                        .map(|effect| effect.kiai_time_enabled())
                        .unwrap_or_default(),
                    slide_speed,
                    mspb,
                };

                timings.push(beatmap_timing);
            });

        let objects: Vec<BeatmapObject> = osu_file
            .hitobjects
            .unwrap_or_default()
            .0
            .into_iter()
            .flat_map(|object| BeatmapObject::flat(&timings, object))
            .collect();

        let audio =
            Into::<PathBuf>::into(general.audio_filename.ok_or(anyhow!("audio not found"))?)
                .to_str()
                .ok_or(anyhow!("to_str error"))?
                .to_string()
                .into_godot();

        let meta_data = osu_file.metadata.unwrap_or_default();
        let name = meta_data
            .version
            .map(|v| String::from(v).to_godot())
            .unwrap_or_default();
        let title = meta_data
            .title_unicode
            .map(|v| String::from(v).to_godot())
            .unwrap_or_default();

        let mut background = String::new();
        let mut video = String::new();

        for event in osu_file.events.unwrap_or_default().0 {
            match event {
                Event::Background(b) => {
                    background = b
                        .file_name
                        .get()
                        .to_str()
                        .map(|path| path.to_string())
                        .unwrap_or_default();
                }
                Event::Video(v) => {
                    video = v
                        .file_name
                        .get()
                        .to_str()
                        .map(|path| path.to_string())
                        .unwrap_or_default();
                }
                _ => (),
            }
        }

        // osu 文件中，背景图片和视频文件名会带双引号，将他去掉
        if background.starts_with("\"") && background.ends_with("\"") {
            background = background[1..background.len() - 1]
                .to_string()
                .replace("\"", "");
        }
        if video.starts_with("\"") && video.ends_with("\"") {
            video = video[1..video.len() - 1].to_string().replace("\"", "");
        }

        let background = background.to_godot();
        let video = video.to_godot();

        let preview_time = general.preview_time.map(|t| t.into()).unwrap_or_default();

        let timings = {
            let mut array = Array::new();
            for timing in timings {
                array.push(Gd::from_object(timing));
            }
            array
        };
        let objects = {
            let mut array = Array::new();
            for object in objects {
                array.push(Gd::from_object(object));
            }
            array
        };

        Ok(Beatmap {
            preview_time,
            name,
            title,
            audio,
            background,
            video,
            objects,
            timings,
        })
    }
}

impl BeatmapObject {
    fn new(position: f32, time: u32) -> BeatmapObject {
        // position
        // OSU的x坐标范围：0 ~ 512
        // 需要将其转换为 0 ~ 180 范围（对应半圆），其中90对应水平方向
        let position = position / 512.0 * 180.0;
        Self { position, time }
    }

    fn flat(timings: &[BeatmapTiming], object: HitObject) -> Vec<BeatmapObject> {
        fn from_osu_position(position: Position) -> (f32, f32) {
            (
                position
                    .x
                    .get()
                    .clone()
                    .left()
                    .unwrap_or_default()
                    .to_f32()
                    .unwrap_or_default(),
                position
                    .y
                    .get()
                    .clone()
                    .left()
                    .unwrap_or_default()
                    .to_f32()
                    .unwrap_or_default(),
            )
        }

        fn from_osu_decimal(decimal: Decimal) -> u32 {
            decimal
                .get()
                .clone()
                .left()
                .unwrap_or_default()
                .to_u32()
                .unwrap_or_default()
        }

        fn compute_slide_end_time(
            timings: &[BeatmapTiming],
            start_time: u32,
            slide_length: u32,
        ) -> u32 {
            let mut remain_length = slide_length;
            for i in 0..timings.len() {
                let timing_start_time = timings[i].time.max(start_time);
                let end_time = if i + 1 == timings.len() {
                    u32::MAX
                } else {
                    timings[i + 1].time
                };
                if end_time < start_time || end_time <= timing_start_time {
                    continue;
                }
                let slide_speed = timings[i].slide_speed;
                let mspb = timings[i].mspb as f32;
                let max_go_distance =
                    (end_time - timing_start_time) as f32 * slide_speed * 100.0 / mspb;
                if max_go_distance > remain_length as f32 {
                    return (remain_length as f32 / slide_speed / 100.0 * mspb) as u32
                        + timing_start_time;
                }

                remain_length -= max_go_distance as u32
            }

            unreachable!()
        }

        match object.obj_params {
            osu_file_parser::hitobjects::HitObjectParams::HitCircle => vec![BeatmapObject::new(
                from_osu_position(object.position).0,
                from_osu_decimal(object.time),
            )],
            osu_file_parser::hitobjects::HitObjectParams::Slider(params) => {
                let start_time = from_osu_decimal(object.time);
                let length = from_osu_decimal(params.length);
                let end_time = compute_slide_end_time(timings, start_time, length);
                let duration = end_time - start_time;

                let points: Vec<_> = vec![from_osu_position(object.position)]
                    .into_iter()
                    .chain(
                        params
                            .curve_points
                            .into_iter()
                            .map(|point| from_osu_position(point.0)),
                    )
                    .collect();

                let mut result = Vec::new();
                let mut time = start_time;
                result.push(BeatmapObject::new(points.first().unwrap().0, time));
                for i in 0..params.slides {
                    time += duration;
                    if i % 2 == 0 {
                        result.push(BeatmapObject::new(points.last().unwrap().0, time))
                    } else {
                        result.push(BeatmapObject::new(points.first().unwrap().0, time))
                    }
                }
                result
            }
            osu_file_parser::hitobjects::HitObjectParams::Spinner { end_time } => {
                let mut start_time = from_osu_decimal(object.time);
                let end_time = from_osu_decimal(end_time);

                let mut result = Vec::new();

                let mut angle = 0.0;
                while start_time < end_time {
                    result.push(BeatmapObject {
                        position: angle,
                        time: start_time,
                    });
                    start_time += 100;
                    angle += 5.0;
                }

                result
            }
            osu_file_parser::hitobjects::HitObjectParams::OsuManiaHold { end_time } => {
                let mut start_time = from_osu_decimal(object.time);
                let end_time = from_osu_decimal(end_time);

                let mut result = Vec::new();

                let position = from_osu_position(object.position);
                while start_time < end_time {
                    result.push(BeatmapObject::new(position.0, start_time));
                    start_time += 100;
                }

                result
            }
            _ => unreachable!(),
        }
    }
}

#[godot_api]
impl IRefCounted for OszFile {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}

#[godot_api]
impl IRefCounted for Beatmap {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}

#[godot_api]
impl IRefCounted for BeatmapObject {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}

#[godot_api]
impl IRefCounted for BeatmapTiming {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}
