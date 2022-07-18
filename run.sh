set -e
# set -x

GRADLE_ARG=""
GRADLE_CMD=""
BUILD_TYPE="Debug"
# BUILD_TYPE="Release"

key="$1"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -f|--flavor)
    FLAVOR="$2"
    shift # past argument
    shift # past value
  ;;
  -b|--build)
    BUILD_TYPE="$2"
    shift # past argument
    shift # past value
  ;;
  -g|--gradlearg)
    GRADLE_ARG="$2"
    shift # past argument
    shift # past value
  ;;
  *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
  ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

[[ ! -z "$ANDROID_SERIAL" ]] && DEVICE="-s $ANDROID_SERIAL"

ADB="adb $DEVICE"

ADB_DEVICE_AVAILABLE="false"
$ADB get-state 1>/dev/null 2>&1 && ADB_DEVICE_AVAILABLE="true"
echo "ADB_DEVICE_AVAILABLE $ADB_DEVICE_AVAILABLE"

if [[ $ADB_DEVICE_AVAILABLE == "true" ]] ; then
  GRADLE_CMD="install"
else
  BUILD_TYPE=""
  GRADLE_CMD="assemble"
fi

PKG=$(cat app/build.gradle | grep applicationId | awk '{print $2}' | sed -e 's/^"//' -e 's/"$//')

BUILD_PATH='app/build'
[[ ! -z "${getDevBuildPath}" ]] && eval "$getDevBuildPath" && BUILD_PATH=$(getDevBuildPath)/app;

FLAVOR=$FLAVOR_CAP
BUILD_ARGS=$GRADLE_CMD$FLAVOR$BUILD_TYPE

CMD="./gradlew $GRADLE_ARG $BUILD_ARGS $SPLIT_APK"
echo "build cmd --> $CMD"
$CMD

# cd $BUILD_PATH/outputs/apk
# echo "apks available at $(pwd)"
# find . -name *.apk | xargs ls -lah
# cd - > /dev/null

if [[ $ADB_DEVICE_AVAILABLE == "true" ]] ; then
  $ADB shell am force-stop $PKG
  START_ARGS=$($ADB shell "cmd package resolve-activity --brief $PKG" | tail -n 1);
  $ADB shell am start -n $START_ARGS -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
  # $ADB shell am start-foreground-service --user 0 -n $PKG/.AMService --es "action" "start_audio"
  # ./log.sh -p $PKG -c
fi
