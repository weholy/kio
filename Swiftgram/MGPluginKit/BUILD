load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MGPluginKit",
    module_name = "MGPluginKit",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Swiftgram/SGLogging:SGLogging",
        "//Swiftgram/SGSimpleSettings:SGSimpleSettings",
    ],
    visibility = [
        "//visibility:public",
    ],
)
