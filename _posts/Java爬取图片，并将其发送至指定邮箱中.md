---
title: ' Java爬取图片，并将其发送至指定邮箱中'
date: 2018-05-26 10:10:51
tags: Java
abstract: Java爬虫简单实例
---

### 代码不精，封装无力。。邮件方面的知识不懂，核心原理照着这位大佬的博客敲的，目前只能发给一个邮箱，只能发文本（html也成），密码会暴露在控制台下。下次更新待修改。

<!--more-->

---

```java
package just4test2;
import java.io.*;
import java.net.*;
import org.jsoup.*;
import org.jsoup.nodes.*;
import org.jsoup.select.*;
public class Downloader {
	private String base;
	public Downloader(String abase) {
		base=abase;
	}
	public void download(String src,String path) throws Exception {
		File fp = new File (path);
		if (!fp.exists())
			fp.mkdirs();
		int pos = src.lastIndexOf('/');
		String filename = src.substring(pos);
		URL url = new URL(src);
		InputStream cin = url.openStream();//开启连接，同时返回输入流对象
		OutputStream cout = new BufferedOutputStream(new FileOutputStream (path+filename));//得到文件输出流对象
		byte[] buffer = cin.readAllBytes();//将文件写入缓冲数组
		cout.write(buffer);//写到文件中
		cin.close();
		cout.close();
	}
	public void downPic(String path) throws Exception{
		//用jsoup获取连接,设置超时防止卡死，模拟浏览器为Chrome
		Connection  con = Jsoup.connect(base).timeout(40000).userAgent("Chrome");
		Document doc = con.get();//得到document对象
        // 查找所有img标签
        Elements imgs = doc.getElementsByTag("img");//根据img标签抓元素，得到一个element元素集elements，很形象
        int j=1;
        for (Element x:imgs) {
        	String imgSrc = x.attr("abs:src");//获取src属性的绝对路径
        	imgSrc = imgSrc.replaceAll("\\s","");//把空白符替换掉
            System.out.printf("正在下载第%d个文件",j++);
        	System.out.print("，地址：");
        	System.out.println(imgSrc);
        	download(imgSrc,path);
        }
	}
    public String getPicURL() throws Exception{
   		String res = "";
    	Connection  con = Jsoup.connect(base);//用jsoup获取连接
   		Document doc = con.get();//发送get请求，得到响应，将该响应解析得到document对象
           // 查找所有img标签
        Elements imgs = doc.getElementsByTag("img");//根据img标签抓元素，得到一个element元素集elements，很形象
        for (Element x:imgs) {
      	String imgSrc = x.attr("abs:src");//获取绝对路径
       	imgSrc = imgSrc.replaceAll("\\s","");//把空白符替换掉
        res += ("<img src=\""+imgSrc+ "\"" + "><br><br><br><br>");//手动添加html标签
        }
        return res;
	}
    public static void main(String[] args)throws Exception {
    	Connection con = Jsoup.connect("https://www.baidu.com/s?wd=emm&pn=10&oq=emm&tn=baiduhome_pg&ie=utf-8&usm=1&rsv_idx=2&rsv_pq=d9987a9100019e58&rsv_t=6182mCdG68LYFKW8uOWnNZtMAxJI2cuJx1Jf1KYoBLNHJq9pOBobv%2FRW3FNBsPfXmgMc").timeout(40000);
    	//con.data("page","2");
    	Document doc = con.get();
    	System.out.println(doc);
    }
}
```
