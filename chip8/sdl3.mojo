from std.ffi import *
from SDL_flags import *
from std.time import sleep

comptime SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK = 0xFFFFFFFF
comptime NULL = OptionalPointer[c_int, MutUntrackedOrigin](None)
comptime SDL_Renderer = OpaquePointer[mut=True, MutUntrackedOrigin]
comptime SDL_Window = OpaquePointer[mut=True, MutUntrackedOrigin]
comptime SDL_AudioStream = OpaquePointer[mut=True, MutUntrackedOrigin]
comptime SDL_AudioDeviceID = UInt32


@fieldwise_init
struct SDL_FRect:
    var x: c_float
    var y: c_float
    var w: c_float
    var h: c_float


@fieldwise_init
struct SDL_AudioSpec(Defaultable):
    var format: SDL_AudioFormat
    var channels: c_int
    var freq: c_int


struct SDL_Event:
    ...


struct SDL3:
    var lib: OwnedDLHandle
    var window: SDL_Window
    var renderer: SDL_Renderer
    var audio_stream: SDL_AudioStream

    def __init__(
        out self,
        init_flags: SDL_InitFlags,
        w: Int,
        h: Int,
        win_flags: SDL_WindowFlags,
        devid: SDL_AudioDeviceID,
        spec: SDL_AudioSpec,
        var title: Optional[String] = None,
    ) raises:
        self.lib = OwnedDLHandle("libSDL3.so.0")
        Self.initialize(self.lib, init_flags)
        self.window = self.create_window(self.lib, w, h, win_flags, title)
        self.renderer = self.create_renderer(self.lib, self.window)
        self.audio_stream = self.open_audio_device_stream(self.lib, devid, spec)

    def __deinit__(deinit self):
        try:
            self.destroy_renderer()
            self.destroy_window()
            self.destroy_audio_stream()
            self.quit()
        except e:
            print(e)

    @staticmethod
    def initialize(lib: OwnedDLHandle, flags: SDL_InitFlags) raises:
        """`SDL_Init(SDL_InitFlags)`"""
        var SDL_Init = lib.get_function[Bool]("SDL_Init")
        if SDL_Init(flags):
            print("SDL Initialized.")
        else:
            raise Error(Self.get_error(lib, "SDL_Init"))

    @staticmethod
    def create_window(
        lib: OwnedDLHandle,
        w: Int,
        h: Int,
        flags: SDL_WindowFlags,
        var title: Optional[String] = None,
    ) raises -> SDL_Window:
        """`SDL_Window * SDL_CreateWindow(const char *title, int w, int h, SDL_WindowFlags flags)`
        """

        var SDL_CreateWindow = lib.get_function[Optional[SDL_Window]](
            "SDL_CreateWindow"
        )
        var window: Optional[SDL_Window]
        if title:
            window = SDL_CreateWindow(
                title.value().as_c_string_span().ptr(),
                c_int(w),
                c_int(h),
                flags,
            )
            print(t"Window Created with title {title}")
        else:
            window = SDL_CreateWindow(NULL, c_int(w), c_int(h), flags)
            print(t"Window Created with title {title}")
        if not window:
            raise Error(Self.get_error(lib, "SDL_CreateWindow"))
        return window.value()

    @staticmethod
    def create_renderer(
        lib: OwnedDLHandle,
        window: SDL_Window,
        var name: Optional[String] = None,
    ) raises -> SDL_Renderer:
        """`SDL_Renderer * SDL_CreateRenderer(SDL_Window *window, const char *name)`
        You can pass in a `name` argument to specify which graphics API to use; Dont.
        """
        var SDL_CreateRenderer = lib.get_function[Optional[SDL_Renderer]](
            "SDL_CreateRenderer"
        )
        var renderer: Optional[SDL_Renderer]
        if name:
            renderer = SDL_CreateRenderer(
                window, name.value().as_c_string_span().ptr()
            )
        else:
            renderer = SDL_CreateRenderer(window, NULL)
            print(t"Renderer Created using {name}.")
        if not renderer:
            raise Error(Self.get_error(lib, "SDL_CreateRenderer"))
        return renderer.value()

    @staticmethod
    def open_audio_device_stream(
        lib: OwnedDLHandle,
        devid: SDL_AudioDeviceID,
        spec: SDL_AudioSpec,
    ) raises -> SDL_AudioStream:
        """`SDL_AudioStream * SDL_OpenAudioDeviceStream(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec, SDL_AudioStreamCallback callback, void *userdata)`
        """
        var SDL_OpenAudioDeviceStream = lib.get_function[SDL_AudioStream](
            "SDL_OpenAudioDeviceStream"
        )
        var audio_stream: Optional[SDL_AudioStream] = SDL_OpenAudioDeviceStream(
            devid,
            NULL,
            NULL,
            NULL,
        )
        if not audio_stream:
            raise Error(Self.get_error(lib, "SDL_OpenAudioDeviceStream"))
        return audio_stream.value()

    @staticmethod
    def get_error(lib: OwnedDLHandle, caller: String) raises -> String:
        """Print SDL Error as `caller: error`"""
        var SDL_GetError = lib.get_function[
            Pointer[c_char, MutUntrackedOrigin]
        ]("SDL_GetError")

        var err = SDL_GetError()
        var cerr = CStringSpan(unsafe_from_ptr=err)
        var serr = StringSpan(unsafe_from_utf8=cerr)
        return String(t"{caller}: {serr}")

    def get_version(self) raises -> Int:
        var SDL_GetVersion = self.lib.get_function[Int]("SDL_GetVersion")
        return SDL_GetVersion()

    def quit(self) raises:
        var SDL_Quit = self.lib.get_function[NoneType]("SDL_Quit")
        SDL_Quit()

    def get_render_driver(
        self, index: Int
    ) raises -> StringSpan[ImmUntrackedOrigin]:
        """`const char * SDL_GetRenderDriver(int index)`"""
        var SDL_GetRenderDriver = self.lib.get_function[
            CStringSpan[ImmUntrackedOrigin]
        ]("SDL_GetRenderDriver")
        return StringSpan(unsafe_from_utf8=SDL_GetRenderDriver(index))

    def get_num_render_drivers(self) raises -> c_int:
        var SDL_GetNumRenderDrivers = self.lib.get_function[c_int](
            "SDL_GetNumRenderDrivers"
        )
        return SDL_GetNumRenderDrivers()

    def set_render_logical_presentation(
        self,
        w: Int,
        h: Int,
        mode: SDL_RendererLogicalPresentation,
    ) raises -> Bool:
        """`SDL_SetRenderLogicalPresentation(SDL_Renderer *renderer, int w, int h, SDL_RendererLogicalPresentation mode)`
        """

        var SDL_SetRenderLogicalPresentation = self.lib.get_function[Bool](
            "SDL_SetRenderLogicalPresentation"
        )
        var out = SDL_SetRenderLogicalPresentation(
            self.renderer, c_int(w), c_int(h), mode
        )
        if not out:
            raise Error(
                Self.get_error(self.lib, "SDL_SetRenderLogicalPresentation")
            )
        else:
            return out

    def destroy_renderer(self) raises:
        """`SDL_DestroyRenderer(SDL_Renderer *renderer)`"""
        var SDL_DestroyRenderer = self.lib.get_function[NoneType](
            "SDL_DestroyRenderer"
        )
        SDL_DestroyRenderer(self.renderer)

    def destroy_window(self) raises:
        """`SDL_DestroyWindow(SDL_Window *window)`"""
        var SDL_DestroyWindow = self.lib.get_function[NoneType](
            "SDL_DestroyWindow"
        )
        SDL_DestroyWindow(self.window)

    def set_render_draw_color(
        self,
        r: UInt8,
        g: UInt8,
        b: UInt8,
        a: UInt8,
    ) raises -> Bool:
        """`SDL_SetRenderDrawColor(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a)`
        """
        var SDL_SetRenderDrawColor = self.lib.get_function[Bool](
            "SDL_SetRenderDrawColor"
        )
        var out = SDL_SetRenderDrawColor(self.renderer, r, g, b, a)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_SetRenderDrawColor"))
        else:
            return out

    def render_clear(self) raises -> Bool:
        """`SDL_RenderClear(SDL_Renderer *renderer)`"""
        var SDL_RenderClear = self.lib.get_function[Bool]("SDL_RenderClear")
        var out = SDL_RenderClear(self.renderer)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_RenderClear"))
        else:
            return out

    def render_fill_rect(self, rect: SDL_FRect) raises -> Bool:
        """`SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_FRect *rect)`
        """
        var SDL_RenderFillRect = self.lib.get_function[Bool](
            "SDL_RenderFillRect"
        )
        var out = SDL_RenderFillRect(self.renderer, Pointer(to=rect))
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_RenderFillRect"))
        else:
            return out

    def render_fill_rects(self, rect: SDL_FRect, count: Int) raises -> Bool:
        """`SDL_RenderFillRects(SDL_Renderer *renderer, const SDL_FRect *rects, int count)`
        """
        var SDL_RenderFillRects = self.lib.get_function[Bool](
            "SDL_RenderFillRects"
        )
        var out = SDL_RenderFillRects(
            self.renderer, Pointer(to=rect), c_int(count)
        )
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_RenderFillRects"))
        else:
            return out

    def render_present(self) raises -> Bool:
        """`SDL_RenderPresent(SDL_Renderer *renderer)`"""
        var SDL_RenderPresent = self.lib.get_function[Bool]("SDL_RenderPresent")
        var out = SDL_RenderPresent(self.renderer)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_RenderPresent"))
        else:
            return out

    def poll_event(self, event: SDL_Event) raises -> Bool:
        """`SDL_PollEvent(SDL_Event *event)`"""
        var SDL_PollEvent = self.lib.get_function[Bool]("SDL_PollEvent")
        var out = SDL_PollEvent(Pointer(to=event))
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_PollEvent"))
        else:
            return out

    def get_keyboard_state(self, num_keys: Int) raises -> Bool:
        """`const bool * SDL_GetKeyboardState(int *numkeys)`"""
        var SDL_GetKeyboardState = self.lib.get_function[Bool](
            "SDL_GetKeyboardState"
        )
        # immutable pointer?
        var out = SDL_GetKeyboardState(num_keys)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_GetKeyboardState"))
        else:
            return out

    def get_audio_playback_devices(
        self,
    ) raises -> Span[SDL_AudioDeviceID, MutUntrackedOrigin]:
        # SDL_AudioDeviceID * SDL_GetAudioPlaybackDevices(int *count);
        comptime CAPACITY = 256
        var SDL_GetAudioPlaybackDevices = self.lib.get_function[
            Span[SDL_AudioDeviceID, MutUntrackedOrigin]
        ]("SDL_GetAudioPlaybackDevices")

        var out = SDL_GetAudioPlaybackDevices(NULL)

        return out

    def get_audio_device_format(
        self,
        devid: SDL_AudioDeviceID,
        mut spec: SDL_AudioSpec,
        sample_frames: Optional[Int] = None,
    ) raises -> Bool:
        # bool SDL_GetAudioDeviceFormat(SDL_AudioDeviceID devid, SDL_AudioSpec *spec, int *sample_frames);
        var SDL_GetAudioDeviceFormat = self.lib.get_function[Bool](
            "SDL_GetAudioDeviceFormat"
        )
        var out = SDL_GetAudioDeviceFormat(
            devid,
            Pointer(to=spec),
            NULL,
            # , Pointer(to=sample_frames)
        )
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_GetAudioDeviceFormat"))
        else:
            return out

    def resume_audio_stream_device(self) raises -> Bool:
        """`SDL_ResumeAudioStreamDevice(SDL_AudioStream *stream)`"""
        var SDL_ResumeAudioStreamDevice = self.lib.get_function[Bool](
            "SDL_ResumeAudioStreamDevice"
        )
        var out = SDL_ResumeAudioStreamDevice(self.audio_stream)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_ResumeAudioStreamDevice"))
        else:
            return out

    def get_audio_stream_queued(self) raises -> Int32:
        """`SDL_GetAudioStreamQueued(SDL_AudioStream *stream)`"""
        var SDL_GetAudioStreamQueued = self.lib.get_function[c_int](
            "SDL_GetAudioStreamQueued"
        )
        return SDL_GetAudioStreamQueued(self.audio_stream)

    def put_audio_stream_data(self) raises -> Bool:
        """`SDL_PutAudioStreamData(SDL_AudioStream *stream, const void *buf, int len)`
        """
        var SDL_PutAudioStreamData = self.lib.get_function[Bool](
            "SDL_PutAudioStreamData"
        )
        # TODO: figure out args here
        var out = SDL_PutAudioStreamData(self.audio_stream)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_PutAudioStreamData"))
        else:
            return out

    def clear_audio_stream(self) raises -> Bool:
        """`SDL_ClearAudioStream(SDL_AudioStream *stream)`"""
        var SDL_ClearAudioStream = self.lib.get_function[Bool](
            "SDL_ClearAudioStream"
        )
        var out = SDL_ClearAudioStream(self.audio_stream)
        if not out:
            raise Error(Self.get_error(self.lib, "SDL_ClearAudioStream"))
        else:
            return out

    def destroy_audio_stream(self) raises:
        """`SDL_DestroyAudioStream(SDL_AudioStream *stream)`"""
        var SDL_DestroyAudioStream = self.lib.get_function[NoneType](
            "SDL_DestroyAudioStream"
        )
        SDL_DestroyAudioStream(self.audio_stream)


# try putting all this in a struct
def main() raises:
    var init_flags = SDL_INIT_AUDIO | SDL_INIT_VIDEO

    var title = "TEST window"

    var win_flags: SDL_WindowFlags = (
        SDL_WINDOW_RESIZABLE | SDL_WINDOW_BORDERLESS | SDL_WINDOW_ALWAYS_ON_TOP
    )
    # var mode = SDL_RendererLogicalPresentation.SDL_LOGICAL_PRESENTATION_DISABLE

    var buf = SDL_AudioSpec()
    var s = SDL3(
        init_flags,
        50,
        50,
        win_flags,
        SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK,
        buf,
        title,
    )
    _ = s.get_audio_playback_devices()
    print("SDL_AudioSpec Initialized")
    _ = s.get_audio_device_format(0xFFFFFFFF, buf)
    print("Wrote to buffer.")
    print(
        t"format:{buf.format.value}\nchannels:{buf.channels}\nfrequency:{buf.freq}"
    )
