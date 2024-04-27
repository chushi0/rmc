use anyhow::Result;
use ffmpeg_next::decoder::Video;
use ffmpeg_next::format::context::Input;
use ffmpeg_next::format::{input, Pixel};
use ffmpeg_next::media::Type;
use ffmpeg_next::software::scaling::{context::Context, flag::Flags};
use ffmpeg_next::{frame, Rational};
use godot::prelude::*;
use std::fmt::Debug;
use std::sync::mpsc::{self, Receiver, SyncSender, TryRecvError};
use std::thread::{self, Thread};

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct VideoDecoder {
    decode_thread: Option<Thread>,
    recv_channel: Option<Receiver<VideoFrame>>,
    closed: bool,
}

#[derive(Debug, GodotClass, Default)]
#[class(base=RefCounted)]
pub struct VideoFrame {
    #[var]
    width: u32,
    #[var]
    height: u32,
    bytes: Vec<u8>,
    #[var]
    rate: f32,
}

#[godot_api]
impl VideoDecoder {
    #[func]
    pub fn start_decode_thread(&mut self, path: String) {
        if self.decode_thread.is_some() {
            return;
        }

        let Ok(decode_ctx) = prepare_decode_context(&path).map_err(|e| {
            godot_error!("start_decode_thread error: {e}, path: {path}");
            e
        }) else {
            return;
        };
        let (thread, channel) = start_decode_thread(decode_ctx);
        self.decode_thread = Some(thread);
        self.recv_channel = Some(channel);
    }

    #[func]
    pub fn try_recv_frame(&mut self) -> Gd<VideoFrame> {
        let recv_frame = self
            .recv_channel
            .as_mut()
            .map(|channel| channel.try_recv())
            .unwrap_or(Err(TryRecvError::Empty));
        if let Err(TryRecvError::Disconnected) = recv_frame {
            self.closed = true;
        }

        recv_frame
            .ok()
            .map(|frame| Gd::from_object(frame))
            .unwrap_or_else(Gd::default)
    }

    #[func]
    pub fn is_finish(&self) -> bool {
        self.closed
    }
}

#[godot_api]
impl VideoFrame {
    #[func]
    fn get_bytes(&self) -> PackedByteArray {
        self.bytes.as_slice().into()
    }
}

#[godot_api]
impl IRefCounted for VideoDecoder {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}

#[godot_api]
impl IRefCounted for VideoFrame {
    fn init(_base: Base<RefCounted>) -> Self {
        Default::default()
    }
}

struct DecodeCtx {
    ictx: Input,
    decoder: Video,
    video_stream_index: usize,
    rate: Rational,
}

fn prepare_decode_context(path: &str) -> Result<DecodeCtx> {
    let ictx = input(path).unwrap();

    let input = ictx
        .streams()
        .best(Type::Video)
        .ok_or(ffmpeg_next::Error::StreamNotFound)?;

    let video_stream_index = input.index();

    let context_decoder =
        ffmpeg_next::codec::context::Context::from_parameters(input.parameters())?;
    let codec = context_decoder.decoder();
    let rate = input.rate();
    let decoder = codec.video()?;

    Ok(DecodeCtx {
        ictx,
        decoder,
        video_stream_index,
        rate,
    })
}

fn start_decode_thread(ctx: DecodeCtx) -> (Thread, Receiver<VideoFrame>) {
    let (send, recv) = mpsc::sync_channel(64);

    let thread = thread::spawn(move || {
        if let Err(e) = decode_thread_main(ctx, send) {
            godot_error!("decode thread fail: {e}")
        }
    })
    .thread()
    .clone();

    (thread, recv)
}

fn decode_thread_main(mut ctx: DecodeCtx, send: SyncSender<VideoFrame>) -> Result<()> {
    let mut scaler = Context::get(
        ctx.decoder.format(),
        ctx.decoder.width(),
        ctx.decoder.height(),
        Pixel::RGB24,
        ctx.decoder.width(),
        ctx.decoder.height(),
        Flags::BILINEAR,
    )?;

    let mut frame_index = 0;

    let mut receive_and_process_decoded_frames =
        |decoder: &mut ffmpeg_next::decoder::Video| -> Result<()> {
            let mut decoded = frame::Video::empty();
            while decoder.receive_frame(&mut decoded).is_ok() {
                let mut rgb_frame = frame::Video::empty();
                scaler.run(&decoded, &mut rgb_frame)?;
                send.send(VideoFrame {
                    width: rgb_frame.width(),
                    height: rgb_frame.height(),
                    bytes: rgb_frame.data(0).to_vec(),
                    rate: ctx.rate.numerator() as f32 / ctx.rate.denominator() as f32,
                })?;
                frame_index += 1;
            }
            Ok(())
        };

    for (stream, packet) in ctx.ictx.packets() {
        if stream.index() == ctx.video_stream_index {
            ctx.decoder.send_packet(&packet)?;
            receive_and_process_decoded_frames(&mut ctx.decoder)?;
        }
    }

    ctx.decoder.send_eof()?;
    receive_and_process_decoded_frames(&mut ctx.decoder)?;

    Ok(())
}
