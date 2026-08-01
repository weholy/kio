load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MGLocalGifts",
    module_name = "MGLocalGifts",
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
