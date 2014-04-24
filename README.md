apkcal（apk中方法数统计工具）
===================================

### 1、工具用途？
	对Android APK包中的如下类型进行统计：
	1）、class：类数
	2）、field：字段数
	3）、method：方法数
	4）、string：字符串数


### 2、统计的目的？
	因为在Android Dex File Format中，这些东西都有一个65536大小的限制；即：单个dex文件中，方法数量（等）不能超过这个数值。


### 3、如何配置？	
#### 1）、配置ADT的platform-tools和tools环境变量

#### 2）、下载工具，解压后放到一个目录，并保证脚本可执行，比如：
```shell
	cp -r apkcal ~/Document/Tool/apkcal
	chmod -R 0755 ~/Document/Tool/apkcal/
```	

#### 3）、为apkcal.sh建立软链接：
```shell
	cd /usr/local/bin
	ln -s ~/Document/Tool/apkcal/apkcal.sh apkcal
```	

#### 4）、切换到任意目录，apkcal命令已可用	


### 4、如何使用？
#### 1）、查看帮助
```shell
	apkcal -h
```
以上命令将输出：
	用法：
	apkcal type=[type] deep=[deep] your_apk_path "your_package_list"

	  type：统计类型，可选：[class|field|method|string]
	  deep：是否进行package深度扫描统计，可选：[0|1] 默认：0

	例：
	apkcal type=method ../tieba.apk "com.baidu.tieba.frs com.baidu.tieba.pb"

#### 2）、统计tiebaAll.apk文件中"com.baidu.tieba.account"包下的方法数
```shell
	apkcal type=method tiebaAll/tiebaAll.apk "com.baidu.tieba.account"
```
以上命令将输出：
	开始进行apk文件中【 method 数】的统计...
	创建临时目录成功...
	解压apk文件并提取dex文件成功...
	反编译dex文件成功...

	  com.baidu.tieba.account 	: 872

	删除临时目录成功，统计完成！

#### 3）、深度统计tiebaAll.apk文件中"com.baidu.tieba.account"包下的方法数
```shell
	apkcal type=method deep=1 tiebaAll/tiebaAll.apk "com.baidu.tieba.account"
```
以上命令将输出：
	开始进行apk文件中【 method 数】的统计...
	创建临时目录成功...
	解压apk文件并提取dex文件成功...
	反编译dex文件成功...

	  com/baidu/tieba/account 			: 872
	  com/baidu/tieba/account/appeal 	: 126
	  com/baidu/tieba/account/forbid 	: 144

	删除临时目录成功，统计完成！

#### 4）、同时统计多个包，包名之间用空格分开即可
```shell
	apkcal type=method tiebaAll/tiebaAll.apk "com.baidu.tieba.account com.baidu.tieba.frs com.baidu.tieba.pb"
```

#### 5）、统计class的数量
```shell
	apkcal type=class deep=1 tiebaAll/tiebaAll.apk "com.baidu.tieba.account"
```

#### 6）、不输入包名的情况下，则会对整个apk中所有的package进行深度遍历
```shell
	apkcal type=class deep=1 tiebaAll/tiebaAll.apk
```
注意！！！：机器性能不好，请别轻易这样玩儿，尤其是apk中package数量特别多的情况。

### 5、意见反馈
	Author：zhaoxianlie
	Blog：http://www.baidufe.com

