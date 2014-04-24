#!/bin/bash

# 得到命令行的所有参数
tool_name="$0"
the_type=$1
deep_scan=$2
apk_path=$3
pkg_list=$4

# 检查是否需要深度扫描
flag=`echo $deep_scan | grep "^deep=1"`
if [ "$flag" == "" ];then
    deep_scan=0
    apk_path=$2
    pkg_list=$3
else
    # 提取深度扫描package的标示，0 | 1
    deep_scan=${deep_scan//deep=/}
fi

# 检验参数的合法性，必须指定apk的路径
if [ x"$apk_path" == x ] || [ ! -f "$apk_path" ] || [ x"$the_type" == x ] || [ "$1" == "-h" ] ;then
    echo -e "\n\t用法："
    echo -e "\tapkcal type=[type] deep=[deep] your_apk_path \"your_package_list\"\n"
    echo -e "\t  type：统计类型，可选：[class|field|method|string]"
    echo -e "\t  deep：是否进行package深度扫描统计，可选：[0|1] 默认：0"
    echo -e "\n\t例："
    echo -e "\tapkcal type=method ../tieba.apk \"com.baidu.tieba.frs com.baidu.tieba.pb\"\n"
    exit 1;
fi

#从参数 type=* 中提取统计类型：method | field | type | string
the_type=${the_type//type=/}

# 打印调试信息
echo "开始进行apk文件中【 "$the_type" 数】的统计..."

# 得到工具的原始目录
prog=$tool_name
while [ -h "${prog}" ]; do
    newProg=`/bin/ls -ld "${prog}"`
    newProg=`expr "${newProg}" : ".* -> \(.*\)$"`
    if expr "x${newProg}" : 'x/' >/dev/null; then
        prog="${newProg}"
    else
        progdir=`dirname "${prog}"`
        prog="${progdir}/${newProg}"
    fi
done

# 这就是工具的目录了
tool_dir=`dirname "${prog}"`

# 以此得到两个jar文件的完整路径
baksmali_jarfile=$tool_dir/baksmali-2.0.3.jar
smali_jarfile=$tool_dir/smali-2.0.3.jar

# 下面要做的事情是：在当前目录下创建临时文件夹，将目标apk文件拷贝进来并解压
# 创建一个临时目录，来解压这个apk文件
rm -rf apk_temp
mkdir apk_temp
cp $apk_path apk_temp/
cd apk_temp
# package list dir path
classes_dex_path="`pwd`/classes.dex"
classes_dir_path="`pwd`/classes_dir"

echo "创建临时目录成功..."

# 获得apk的名称
apk_name="$(basename *.apk)"

# 重命名为zip
mv $apk_name $apk.zip

# 解压apk，得到classes.dex包
unzip -x $APK_NAME.zip > /dev/null
echo "解压apk文件并提取dex文件成功..."

# 在当前目录下，就可以得到classes.dex文件了
# 接下来要做的事情就是：
# 1、使用baksmali将classes.dex中的class导出（smali文件）
java -jar $baksmali_jarfile -o $classes_dir_path classes.dex
echo -e "反编译dex文件成功...\n"


# 直接统计apk中的数据：classes.dex
# 使用方法： cal_apk classes.dex method
function cal_apk() {
    local cal_type dex;
    dex=$1;
    cal_type=$2;

    # 对type进行修正
    if [ "$cal_type" == "class" ];then
        cal_type="class_defs_size"
    else
        cal_type=$cal_type"_ids_size"
    fi

    # 从dex文件中统计
    the_num=`dexdump -f $dex | grep $cal_type`
    # 为了得到纯数字部分，咱们吧不相干的东西删掉
    the_num=${the_num//$cal_type/}
    the_num=${the_num//:/}
    the_num=`echo $the_num | sed -e 's/\(^ *\)//' -e 's/\( *$\)//'`
    echo -e "  all \t: $the_num"
    # 删除临时文件
    rm -rf $dex
}

# 按照package维度进行统计
# 用smali对各个package进行转换：smali to dex
# 使用方法： cal_package com.baidu.tieba method
function cal_package() {
    local cal_type pkg_item;
    pkg_item=$1;
    cal_type=$2;

    # 对type进行修正
    if [ "$cal_type" == "class" ];then
        cal_type="class_defs_size"
    else
        cal_type=$cal_type"_ids_size"
    fi

    target_pkg_name=$pkg_item
    # 将.替换成/得到路径，比如：com.baidu.tieba.pb替换为com/baidu/tieba/pb
    target_pkg_path="${pkg_item//.//}"

    if [ -d "$target_pkg_path" ];then
        # 编译得到以包名命名的dex文件，如：com.baidu.tieba.pb.dex
        java -jar $smali_jarfile $target_pkg_path/ -o $target_pkg_name.dex

        # 从dex文件中统计
        the_num=`dexdump -f $target_pkg_name.dex | grep $cal_type`
        # 为了得到纯数字部分，咱们吧不相干的东西删掉
        the_num=${the_num//$cal_type/}
        the_num=${the_num//:/}
        the_num=`echo $the_num | sed -e 's/\(^ *\)//' -e 's/\( *$\)//'`
        echo -e "  $target_pkg_name \t: $the_num"
        # 删除临时文件
        rm -rf $target_pkg_name.dex
    else
        echo -e "  $target_pkg_name \t: 包不存在"
    fi
}

# 遍历整个文件夹
# 使用方法：scan_package ~/dirname
function scan_package() {
    local root_dir package_name cur_dir parent_dir;
    cd $1;
    cur_dir=`pwd`;
    root_dir=$2;
    if [ x"$root_dir" == x ];then
        root_dir="$cur_dir";
    fi

    # 要的就是这个相对路径
    package_name=${cur_dir//$root_dir/}
    if [ x"$package_name" != x ];then
        package_name="$package_name/"
    fi
 
    # 遍历所有子目录
    for dir in `ls $cur_dir` ; do
        # 如果是目录，则说明是一个package，对当前package下的内容进行统计
        if [ -d $dir ] && [ "$dir" != "android" ]; then
            flag=0;
            # 过滤重复的
            for pkg_item in $pkg_list ;do
                if [ "$pkg_item" == "$package_name$the_dir" ];then
                    flag=1;
                    break;
                fi
            done

            # 包名累加
            if [ $flag == 0 ];then
                the_dir=`echo $package_name$dir | sed -e 's/\(^\/\)//'`
                # 得到package完整路径
                pkg_list="$pkg_list $the_dir";
            fi

            cd $dir;
            # 递归遍历下一级子目录
            scan_package $cur_dir/$dir $root_dir;
            cd ..;
        fi
    done
}


# 没有输入package list的情况下，就深度遍历apk中的所有包
if [ "$pkg_list" == "" ] ;then
    cal_apk $classes_dex_path "$the_type"
else
    # 如果是指定了package list，则判断是否需要进行深度遍历
    if [ $deep_scan == 1 ];then
        # 先把package list缓存起来，对这个list中的每一个package进行深度遍历
        tmp_pkg_list=$pkg_list
        pkg_list=""
        for pkg_item in $tmp_pkg_list ;do
            target_pkg_path="${pkg_item//.//}"
            pkg_list="$pkg_list $target_pkg_path"
            scan_package $classes_dir_path/$target_pkg_path $classes_dir_path/
        done
    fi

    # 进入package list目录，按照package维度进行统计
    cd $classes_dir_path
    for pkg_item in $pkg_list ;do
        cal_package $pkg_item "$the_type"
    done
fi

# 删除临时目录，结束
cd ../../ && rm -rf apk_temp
echo -e "\n删除临时目录成功，统计完成！"