# pdf2xcassets
## instruction
写这个工具的目的是为了更高效率使用PDF资源,降低手动操作的错误率.主要功能 批量把 pdf 转成 xcassest
现在有的小伙伴可能已经支持 目前做的好一点的做是这样设计和工程代码在不同的分支.
如果新加一个图片资源做法大约是这样:
 1. 设计师提交到svn分支
 2. 研发人员更新资源
 3. 研发人员拖到xcassets中
这样操作我个人感觉还有很麻烦的,很容易出错了.用这个工具设计师在出PDF资源后 直接生成研究人员人的xcassets 提交到分支,开发人员更新就可以得到最新资源,这个工具主要是给设计师用的.

目录结构说明:

./bin 编译好的可执行文件

./pdfConvertXcassets 主要代码

./sample 例子pdf 文件

## How to use
![这里写图片描述](http://img.blog.csdn.net/20160320120843970)

设置输入 和输出path 点开始就可以了

<font color=red>注意:pdf文件目录名中不可以包括.pdf</font> 

感觉好用的欢迎标星支持一下.



## Contact

- [我的博客 http://wangchengak.gitcafe.io/](http://wangchengak.gitcafe.io/)
- 微信号: a287971051

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.


