exclude="ck\\.fs|pl\\.fs|sysmd5\\.zip|sd_after|install-recovery\\.sh|install_recovery\\.sh|recovery-from-boot\\.p|recovery_rootcheck|vendor/nvdata|vendor/nvcfg|vendor/persist|vendor/protect|vendor/euclid"
if [ "$#" -eq 3 ];then
pushd $3 2>&1 > /dev/null;
fi
if [ "$2" = "deep" ]; then
md5=`toybox find $1 -type f | sed 's/system_root\///g'| toybox grep -Ev $exclude | toybox sort | toybox xargs toybox md5sum | toybox md5sum | toybox cut -b  -32 `
else
md5=`toybox find $1 -type f | sed 's/system_root\///g' | toybox xargs toybox ls -l --color=never | toybox grep -Ev $exclude | awk '{
print $5,$9}' | toybox sort | toybox md5sum | toybox cut -b -32`
fi
build_time=`cat system/build.prop  | toybox grep utc| toybox cut -b  19-`
echo "$build_time,$md5";

if [ "$#" -eq 3 ];then
popd 2>&1 > /dev/null;
fi
