from std.ffi import *
from SDL_flags import *
from std.time import sleep


# opaque struct
@fieldwise_init
struct SDL_Renderer(RegisterPassable):
    ...


@fieldwise_init
struct SDL_Window(RegisterPassable, Writable):
    ...


def print_SDL_error(SDL: OwnedDLHandle, caller: String) raises:
    var SDL_GetError = SDL.get_function[Pointer[c_char, MutUntrackedOrigin]](
        "SDL_GetError"
    )
    var err = SDL_GetError()
    var cerr = CStringSpan(unsafe_from_ptr=err)
    var serr = StringSpan(unsafe_from_utf8=cerr)
    print(t"{caller}: {serr}")


# try putting all this in a struct
def main() raises:
    var SDL = OwnedDLHandle("libSDL3.so.0")
    var SDL_GetVersion = SDL.get_function[Int]("SDL_GetVersion")

    var SDL_Init = SDL.get_function[Bool]("SDL_Init")
    # SDL_Init(SDL_InitFlags)
    var init_flags: SDL_InitFlags = SDL_INIT_AUDIO | SDL_INIT_VIDEO
    if SDL_Init(init_flags):
        print("SDL Initiated.")
    else:
        print_SDL_error(SDL, "SDL_Init")
    var SDL_Quit = SDL.get_function[NoneType]("SDL_Quit")
    # SDL_Quit()
    # SDL writes an error to a buffer when something goes wrong. run this to get a pointer to it
    # SDL_GetError()

    # CStringSpan(unsafe_from_ptr=TheErrorPointer)
    # StringSpan(unsafe_from_utf8=TheCStringPointer)
    # SDL will trash the string so copy it into a variable to keep it

    var title = "TEST window"
    var win_flags: SDL_WindowFlags = (
        SDL_WINDOW_RESIZABLE | SDL_WINDOW_BORDERLESS | SDL_WINDOW_ALWAYS_ON_TOP
    )
    var SDL_CreateWindow = SDL.get_function[
        OpaquePointer[mut=True, MutUntrackedOrigin]
    ]("SDL_CreateWindow")
    # SDL_Window * SDL_CreateWindow(const char *title, int w, int h, SDL_WindowFlags flags);
    var win = SDL_CreateWindow(
        title.as_c_string_span().ptr(), 50, 50, win_flags
    )
    print_SDL_error(SDL, "SDL_CreateWindow")

    var SDL_GetRenderDriver = SDL.get_function[CStringSpan[ImmUntrackedOrigin]](
        "SDL_GetRenderDriver"
    )
    # const char * SDL_GetRenderDriver(int index);
    var SDL_GetNumRenderDrivers = SDL.get_function[c_int](
        "SDL_GetNumRenderDrivers"
    )
    for a in range(SDL_GetNumRenderDrivers()):
        print(StringSpan(unsafe_from_utf8=SDL_GetRenderDriver(a)))

    var SDL_CreateRenderer = SDL.get_function[
        OpaquePointer[mut=True, MutUntrackedOrigin]
    ]("SDL_CreateRenderer")
    # SDL_Renderer * SDL_CreateRenderer(SDL_Window *window, const char *name);
    var ren_name = ""
    var ren = SDL_CreateRenderer(win, ren_name.as_c_string_span().ptr())
    print_SDL_error(SDL, "SDL_CreateRenderer")

    var SDL_CreateWindowAndRenderer = SDL.get_function[Bool](
        "SDL_CreateWindowAndRenderer"
    )
    # SDL_CreateWindowAndRenderer(const char *title, int width, int height, SDL_WindowFlags window_flags, SDL_Window **window, SDL_Renderer **renderer)
    var SDL_SetRenderLogicalPresentation = SDL.get_function[Bool](
        "SDL_SetRenderLogicalPresentation"
    )
    # SDL_SetRenderLogicalPresentation(SDL_Renderer *renderer, int w, int h, SDL_RendererLogicalPresentation mode)
    if SDL_SetRenderLogicalPresentation(
        ren,
        50,
        50,
        SDL_RendererLogicalPresentation.SDL_LOGICAL_PRESENTATION_DISABLE,
    ):
        print("Presentation sent.")
    else:
        print_SDL_error(SDL, "SDL_SetRenderLogicalPresentation")
    # CStringSpan(unsafe_from_ptr=TheErrorPointer)
    # StringSpan(unsafe_from_utf8=TheCStringPointer)

    sleep(10)

    var SDL_DestroyRenderer = SDL.get_function[NoneType]("SDL_DestroyRenderer")
    # SDL_DestroyRenderer(SDL_Renderer *renderer)
    var SDL_DestroyWindow = SDL.get_function[NoneType]("SDL_DestroyWindow")
    # SDL_DestroyWindow(SDL_Window *window)

    var SDL_SetRenderDrawColor = SDL.get_function[Bool](
        "SDL_SetRenderDrawColor"
    )
    # SDL_SetRenderDrawColor(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
    var SDL_RenderClear = SDL.get_function[Bool]("SDL_RenderClear")
    # SDL_RenderClear(SDL_Renderer *renderer);
    var SDL_RenderFillRect = SDL.get_function[Bool]("SDL_RenderFillRect")
    # SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_FRect *rect);
    var SDL_RenderFillRects = SDL.get_function[Bool]("SDL_RenderFillRects")
    # SDL_RenderFillRects(SDL_Renderer *renderer, const SDL_FRect *rects, int count);
    var SDL_RenderPresent = SDL.get_function[Bool]("SDL_RenderPresent")
    # SDL_RenderPresent(SDL_Renderer *renderer);

    var SDL_PollEvent = SDL.get_function[Bool]("SDL_PollEvent")
    # SDL_PollEvent(SDL_Event *event);
    var SDL_GetKeyboardState = SDL.get_function[Bool]("SDL_GetKeyboardState")
    # const bool * SDL_GetKeyboardState(int *numkeys);
    # immutable pointer?

    var SDL_OpenAudioDeviceStream = SDL.get_function[NoneType](
        "SDL_OpenAudioDeviceStream"
    )
    # SDL_AudioStream * SDL_OpenAudioDeviceStream(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec, SDL_AudioStreamCallback callback, void *userdata);
    var SDL_ResumeAudioStreamDevice = SDL.get_function[Bool](
        "SDL_ResumeAudioStreamDevice"
    )
    # SDL_ResumeAudioStreamDevice(SDL_AudioStream *stream);
    var SDL_GetAudioStreamQueued = SDL.get_function[c_int](
        "SDL_GetAudioStreamQueued"
    )
    # SDL_GetAudioStreamQueued(SDL_AudioStream *stream);
    var SDL_PutAudioStreamData = SDL.get_function[Bool](
        "SDL_PutAudioStreamData"
    )
    # SDL_PutAudioStreamData(SDL_AudioStream *stream, const void *buf, int len);
    var SDL_ClearAudioStream = SDL.get_function[Bool]("SDL_ClearAudioStream")
    # SDL_ClearAudioStream(SDL_AudioStream *stream);
    var SDL_DestroyAudioStream = SDL.get_function[NoneType](
        "SDL_DestroyAudioStream"
    )
    # SDL_DestroyAudioStream(SDL_AudioStream *stream);
