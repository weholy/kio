load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

sgdeps = [
    "//Swiftgram/SGSimpleSettings:SGSimpleSettings",
    "//Swiftgram/SGLiquidGlassCore:SGLiquidGlassCore",
    "//submodules/TelegramUI/Components/GlassBackgroundComponent:GlassBackgroundComponent",
    "//submodules/ComponentFlow:ComponentFlow",
]

swift_library(
    name = "ChatMessageBackground",
    module_name = "ChatMessageBackground",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = sgdeps + [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
    	"//submodules/Display:Display",
    	"//submodules/TelegramPresentationData:TelegramPresentationData",
    	"//submodules/WallpaperBackgroundNode:WallpaperBackgroundNode",
    ],
    visibility = [
        "//visibility:public",
    ],
)
