#!/usr/bin/env bash

package_name="com.catchingnow.icebox"
admin_component="com.catchingnow.icebox/.receiver.DPMReceiver"
app_name="冰箱 Ice Box "

echo
echo
echo "欢迎使用${app_name}设备管理员激活脚本"
echo
echo "操作步骤："
echo "1. 确保手机上已安装${app_name}，删除屏幕锁"
echo "2. 打开手机上的开发者选项，「USB 调试」，连接电脑"
echo "3. 索尼手机取出 SIM 卡，MIUI 开启「USB 调试（安全设置）」，关闭「MIUI 优化」"
echo "4. 在系统设置中，删掉所有的帐号，如小米帐号、华为帐号等（之后可以登录回来）"
echo
echo "操作完成后，回车以继续…"

read

if [[ "$OSTYPE" == "darwin"* ]]; then
	cd ./mac
else
	cd ./linux
fi

adb_cmd="./platform-tools/adb"

# 连接手机
test_adb() {
	adb_test_result=$(${adb_cmd} devices)
	if [[ "${adb_test_result/devices/d}" == *"device"* ]]; then
		echo "设备连接成功…"
	else
		echo "设备连接失败，请在手机上开启并允许「USB 调试」，按回车以重试"
		read
		test_adb
	fi
}

test_adb

# 删除帐号、账户等
${adb_cmd} push ./dpmpro /data/local/tmp/dpmpro >/dev/null 2>&1
dpm_pro_cmd="${adb_cmd} shell CLASSPATH=/data/local/tmp/dpmpro app_process /system/bin com.android.commands.dpm.Dpm "

echo "正在执行账户帐号预清理…"
${dpm_pro_cmd} remove-all-users >/dev/null 2>&1
${dpm_pro_cmd} remove-all-accounts >/dev/null 2>&1

# 设置管理员
set_owner() {
	echo "正在设置设备管理员…"
	dpm_result=$(${adb_cmd} shell dpm set-device-owner ${admin_component} 2>&1)

    lower_case_result=$(echo ${dpm_result} | tr [A-Z] [a-z])
	if [[ "$lower_case_result" == *"success"* ]]; then
		echo "设置成功"
        echo
        echo "无论手机重启或升级，持续有效"
		echo "如需卸载${app_name}，请务必先全部解冻，再在其设置中选择卸载"
		echo "其他问题请参考文档："
		echo "http://t.cn/E5QwyJN"
        echo
		exit
	elif [[ "$lower_case_result" == *"accounts on the device"* ]]; then
		echo
		echo "设置失败"
		echo
		echo "设备上还有帐号未删除，如华为帐号、小米帐号、Google 帐号等"
		echo "请在系统设置内手动删除后，按回车以重试"
		read
		set_owner
	elif [[ "$lower_case_result" == *"users on the device"* ]]; then
		echo
		echo "设置失败"
		echo
		echo "设备上还存在一些用户没有移除"
		echo "请删除或关闭所有多用户/访客模式/应用双开后，按回车以重试"
		read
		set_owner
	elif [[ "$lower_case_result" == *"MANAGE_DEVICE_ADMINS"* ]]; then
		echo
		echo "设置失败"
		echo
		echo "MIUI 用户请在系统设置- 开发者设置里，开启「USB 调试（安全设置）」，关闭「MIUI 优化」"
		echo "按回车以重试"
		read
		set_owner
	elif [[ "$lower_case_result" == *"already set"* ]]; then
		echo
		echo "设置失败"
		echo
		echo "您已设置其他 App 为设备管理员，一台设备上只能有一个管理员"
		echo "请移除其他管理员，并按回车以重试"
		read
		set_owner
    else
        echo
        echo "设置失败，未知错误"
        echo
        echo "错误详情："
        echo
        echo ${dpm_result}
	fi
}

set_owner