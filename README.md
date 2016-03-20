# gfwlist2dnsmasq.lua
## 参考gfwlist2dnsmasq.py，实现可直接在openwrt上运行的lua版本

###脚本逻辑流程：

1. 检查是否存在完整版wget，不存在则通过opkg安装
2. 请求github上的gfwlist.txt
3. 在脚本所在目录生成dnsmasq_list.conf
4. 重新加载dnsmasq

------
ps：/etc/init.d/dnsmasq里面已修改过，把生成的dnsmasq_list.conf拷贝到conf-dir里面
如 gfwlist2dnsmasq.lua 所在目录为/root, 则在/etc/init.d/dnsmasq 里面的 
dnsmasq函数结束处加入 `cp -f /root/dnsmasq_list.conf /var/etc/dnsmasq.d/`

######参考项目
[1]: [gfwlist2dnsmasq python版](https://github.com/cokebar/gfwlist2dnsmasq)
