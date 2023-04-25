# sfbootstrap env for fairphone-FP4

VENDOR=fairphone
VENDOR_PRETTY="Fairphone"
DEVICE=FP4
DEVICE_PRETTY="Fairphone 4"
HABUILD_DEVICE=FP4
HOOKS_DEVICE=fairphone-FP4
PORT_ARCH=aarch64
SOC=qcom
PORT_TYPE=hybris
HYBRIS_VER=18.1
ANDROID_MAJOR_VERSION=11
REPO_INIT_URL="https://github.com/Sailfishos-for-the-fairphone-4/android.git"
HYBRIS_PATCHER_SCRIPTS=()
HAL_MAKE_TARGETS=(hybris-hal droidmedia)
HAL_ENV_EXTRA=""
RELEASE=4.5.0.18
TOOLING_RELEASE=$RELEASE
SDK_RELEASE=latest

export VENDOR DEVICE PORT_ARCH RELEASE
