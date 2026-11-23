from std.ffi import c_int

comptime SDL_InitFlags = UInt32
comptime SDL_INIT_AUDIO: SDL_InitFlags = 0x00000010
comptime SDL_INIT_VIDEO: SDL_InitFlags = 0x00000020
comptime SDL_INIT_JOYSTICK: SDL_InitFlags = 0x00000200
comptime SDL_INIT_HAPTIC: SDL_InitFlags = 0x00001000
comptime SDL_INIT_GAMEPAD: SDL_InitFlags = 0x00002000
comptime SDL_INIT_EVENTS: SDL_InitFlags = 0x00004000
comptime SDL_INIT_SENSOR: SDL_InitFlags = 0x00008000
comptime SDL_INIT_CAMERA: SDL_InitFlags = 0x00010000

comptime SDL_WindowFlags = UInt64
comptime SDL_WINDOW_FULLSCREEN: SDL_WindowFlags = 0x0000000000000001  # window is in fullscreen mode
comptime SDL_WINDOW_OPENGL: SDL_WindowFlags = 0x0000000000000002  # window usable with OpenGL context
comptime SDL_WINDOW_OCCLUDED: SDL_WindowFlags = 0x0000000000000004  # window is occluded
comptime SDL_WINDOW_HIDDEN: SDL_WindowFlags = 0x0000000000000008  # window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible
comptime SDL_WINDOW_BORDERLESS: SDL_WindowFlags = 0x0000000000000010  # no window decoration
comptime SDL_WINDOW_RESIZABLE: SDL_WindowFlags = 0x0000000000000020  # window can be resized
comptime SDL_WINDOW_MINIMIZED: SDL_WindowFlags = 0x0000000000000040  # window is minimized
comptime SDL_WINDOW_MAXIMIZED: SDL_WindowFlags = 0x0000000000000080  # window is maximized
comptime SDL_WINDOW_MOUSE_GRABBED: SDL_WindowFlags = 0x0000000000000100  # window has grabbed mouse input
comptime SDL_WINDOW_INPUT_FOCUS: SDL_WindowFlags = 0x0000000000000200  # window has input focus
comptime SDL_WINDOW_MOUSE_FOCUS: SDL_WindowFlags = 0x0000000000000400  # window has mouse focus
comptime SDL_WINDOW_EXTERNAL: SDL_WindowFlags = 0x0000000000000800  # window not created by SDL
comptime SDL_WINDOW_MODAL: SDL_WindowFlags = 0x0000000000001000  # window is modal
comptime SDL_WINDOW_HIGH_PIXEL_DENSITY: SDL_WindowFlags = 0x0000000000002000  # window uses high pixel density back buffer if possible
comptime SDL_WINDOW_MOUSE_CAPTURE: SDL_WindowFlags = 0x0000000000004000  # window has mouse captured (unrelated to MOUSE_GRABBED)
comptime SDL_WINDOW_MOUSE_RELATIVE_MODE: SDL_WindowFlags = 0x0000000000008000  # window has relative mode enabled
comptime SDL_WINDOW_ALWAYS_ON_TOP: SDL_WindowFlags = 0x0000000000010000  # window should always be above others
comptime SDL_WINDOW_UTILITY: SDL_WindowFlags = 0x0000000000020000  # window should be treated as a utility window, not showing in the task bar and window list
comptime SDL_WINDOW_TOOLTIP: SDL_WindowFlags = 0x0000000000040000  # window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window
comptime SDL_WINDOW_POPUP_MENU: SDL_WindowFlags = 0x0000000000080000  # window should be treated as a popup menu, requires a parent window
comptime SDL_WINDOW_KEYBOARD_GRABBED: SDL_WindowFlags = 0x0000000000100000  # window has grabbed keyboard input
comptime SDL_WINDOW_FILL_DOCUMENT: SDL_WindowFlags = 0x0000000000200000  # window is in fill-document mode (Emscripten only), since SDL 3.4.0
comptime SDL_WINDOW_VULKAN: SDL_WindowFlags = 0x0000000010000000  # window usable for Vulkan surface
comptime SDL_WINDOW_METAL: SDL_WindowFlags = 0x0000000020000000  # window usable for Metal view
comptime SDL_WINDOW_TRANSPARENT: SDL_WindowFlags = 0x0000000040000000  # window with transparent buffer
comptime SDL_WINDOW_NOT_FOCUSABLE: SDL_WindowFlags = 0x0000000080000000  # window should not be focusable


@fieldwise_init
struct SDL_RendererLogicalPresentation(Equatable, ImplicitlyCopyable):
    var value: c_int
    comptime SDL_LOGICAL_PRESENTATION_DISABLE = SDL_RendererLogicalPresentation(
        0
    )  # There is no logical size in effect
    comptime SDL_LOGICAL_PRESENTATION_STRETCH = SDL_RendererLogicalPresentation(
        1
    )  # The rendered content is stretched to the output resolution
    comptime SDL_LOGICAL_PRESENTATION_LETTERBOX = SDL_RendererLogicalPresentation(
        2
    )  # The rendered content is fit to the largest dimension and the other dimension is letterboxed with the clear color
    comptime SDL_LOGICAL_PRESENTATION_OVERSCAN = SDL_RendererLogicalPresentation(
        3
    )  # The rendered content is fit to the smallest dimension and the other dimension extends beyond the output bounds
    comptime SDL_LOGICAL_PRESENTATION_INTEGER_SCALE = SDL_RendererLogicalPresentation(
        4
    )  # The rendered content is scaled up by integer multiples to fit the output resolution

    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
