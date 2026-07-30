load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SGLiquidGlassCore",
    module_name = "SGLiquidGlassCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Swiftgram/SGSimpleSettings:SGSimpleSettings",
    ],
    visibility = [
        "//visibility:public",
    ],
)
