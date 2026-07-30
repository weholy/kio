import sys
import os

def patch_file(filepath, old, new, description):
    if not os.path.isfile(filepath):
        print("SKIP: {} not found".format(filepath))
        return False
    with open(filepath, "r") as f:
        content = f.read()
    if old not in content:
        print("SKIP: {} already patched or pattern changed ({})".format(filepath, description))
        return False
    content = content.replace(old, new, 1)
    with open(filepath, "w") as f:
        f.write(content)
    print("OK: {} ({})".format(filepath, description))
    return True

base = "build-system/bazel-rules/rules_apple/apple/internal"

patched = 0

# Patch 1: provisioning_profile.bzl - don't fail when profile_artifact is None
p1 = patch_file(
    os.path.join(base, "partials", "provisioning_profile.bzl"),
    '''    if not profile_artifact:
        fail(
            "\\n".join([
                "ERROR: In {}:".format(str(rule_label)),
                "Building for device, but no provisioning_profile attribute was set.",
            ]),
        )''',
    '''    if not profile_artifact:
        # Patched for CI: allow None provisioning profile
        return struct(
            bundle_files = [],
        )''',
    "provisioning_profile_partial allow None"
)
patched += p1

# Patch 2: codesigning_support.bzl - don't fail when provisioning_profile is None
p2 = patch_file(
    os.path.join(base, "codesigning_support.bzl"),
    '''    if (platform_prerequisites.platform.is_device and
        rule_descriptor.requires_signing_for_device and
        not provisioning_profile):
        fail("The provisioning_profile attribute must be set for device " +
             "builds on this platform (%s)." %
             platform_prerequisites.platform_type)''',
    '''    if (platform_prerequisites.platform.is_device and
        rule_descriptor.requires_signing_for_device and
        not provisioning_profile):
        # Patched for CI: allow missing provisioning profile
        pass''',
    "validate_provisioning_profile allow None"
)
patched += p2

if patched > 0:
    print("Patched {} file(s) successfully".format(patched))
else:
    print("All patches already applied or files not found")
