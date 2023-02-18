#!/usr/bin/env bash

module_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")";
module_prop="${module_dir}/module.prop"
apk_dir="${module_dir}/system/app/webview"
lib_dir="${module_dir}/system/lib"
lib64_dir="${module_dir}/system/lib64"
apk_path="${apk_dir}/webview.apk"
apktool_dir="/tmp/webviewapktool"
apktool_yml="${apktool_dir}/apktool.yml"
target_dir="/home/kescher/kescherCloud/Shared/Mulch Webview Magisk module/arm64"
[[ "$1" == "test" ]] && target_dir="${module_dir}/modules/arm64"

mkdir -p "${apk_dir}" "${lib_dir}" "${lib64_dir}" || exit 1
wget "https://gitlab.com/divested-mobile/mulch/-/raw/master/prebuilt/arm64/webview.apk?inline=false" -O "${module_dir}/system/app/webview/webview.apk" || exit 1
pids=()
unzip -ojd "${lib_dir}" "${apk_path}" "lib/armeabi-v7a/libwebviewchromium.so" >/dev/null &
pids+=($!)
unzip -ojd "${lib64_dir}" "${apk_path}" "lib/arm64-v8a/libwebviewchromium.so" >/dev/null &
pids+=($!)

retval=0
for pid in "${pids[@]}"; do
	wait "$pid";
	pid_status=$?
	if [[ $pid_status != 0 ]]; then
		retval=1
	fi
done

[[ "${retval}" == 0 ]] || exit 1

apktool d -r -s --force-manifest "${apk_path}" -o /tmp/webviewapktool -f || exit 1

chromium_version="$(grep versionName "${apktool_yml}" | cut -d':' -f2- | cut -d' ' -f2-)"
module_version="$(grep versionCode "${apktool_yml}" | cut -d':' -f2- | cut -d' ' -f2- | cut -d$'\'' -f2)"
echo "New chromium version: ${chromium_version}"
echo "New module version: ${module_version}"
sed -i "s/^version=.*/version=${chromium_version}/" "${module_prop}" || exit 1
sed -i "s/^versionCode=.*/versionCode=${module_version}/" "${module_prop}" || exit 1
rm -rf "${apktool_dir}"

[[ -d "${target_dir}" ]] || exit 1

zip -9r - META-INF system module.prop > "${target_dir}/mulch_webview_arm64_${chromium_version}.zip"
cp "${target_dir}/mulch_webview_arm64_${chromium_version}.zip" "${target_dir}/mulch_webview_arm64_latest.zip"
