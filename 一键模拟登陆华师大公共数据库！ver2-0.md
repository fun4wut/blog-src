---
title: 一键模拟登陆华师大公共数据库！ver2.0
date: 2018-05-26 10:07:38
tags:
---
花了我整整一天，终于搞定了，爽到。

花了那么久时间主要原因一个是抓包姿势不对【firefox和chrome的抓包结果不一样让人很绝望啊；一个是工具选择不好【辣鸡jsoup

httpclient还是强啊，自动维持session和cookie的特性着实方便了不少。

目前还有两个待解决的问题，一是验证码要手动输入，二是rsa，pl，ul这几个参数必须首先登陆一次才能拿到（这跟用户名密码绑定的）验证码手动输入的问题不难，图片很好认，用现有的工具很好搞定。第二个就比较困难了，首先我找不到加密脚本的位置orz
``` java
package just4tset4;  
import java.util.*;  
import org.apache.http.HttpResponse;  
import org.apache.http.HttpStatus;  
import org.apache.http.HttpVersion;  
import org.apache.http.NameValuePair;  
import org.apache.http.client.ClientProtocolException;  
import org.apache.http.client.CookieStore;  
import org.apache.http.client.HttpClient;  
import org.apache.http.client.entity.UrlEncodedFormEntity;  
import org.apache.http.client.methods.*;  
import org.apache.http.client.methods.HttpGet;  
import org.apache.http.client.protocol.HttpClientContext;  
import org.apache.http.cookie.Cookie;  
import org.apache.http.impl.client.BasicCookieStore;  
import org.apache.http.impl.client.CloseableHttpClient;  
import org.apache.http.impl.client.HttpClientBuilder;  
import org.apache.http.impl.client.HttpClients;  
import org.apache.http.impl.client.LaxRedirectStrategy;  
import org.apache.http.impl.cookie.BasicClientCookie;  
import org.apache.http.message.BasicHttpResponse;  
import org.apache.http.message.BasicNameValuePair;  
import org.apache.http.protocol.HTTP;  
import org.apache.http.util.EntityUtils;  
import java.io.*;  
import java.util.*;  
import org.jsoup.Connection;    
import org.jsoup.Jsoup;    
import org.jsoup.Connection.Method;    
import org.jsoup.Connection.Response;    
import org.jsoup.nodes.Document;    
import org.jsoup.nodes.Element;  
import org.jsoup.select.Elements;   
public class ECNUTEST {  
    public static String LOGIN_URL = "https://portal1.ecnu.edu.cn/cas/login";//登陆页面，提交页面  
    public static String CODE_URL = "https://portal1.ecnu.edu.cn/cas/code";//验证码页面  
    public static String TARGET_URL = "http://portal.ecnu.edu.cn/neusoftcas.jsp";//目标页面  
    public static String UA = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:52.0) Gecko/20100101 Firefox/52.0";//浏览器标识    
    public static String RSA = "A03D1C4A03E7D45D4A27E911562AA7BA5F3AA7D9CB96A5883CA"//加密过的用户名/密码  
            + "E95766F36AB689F36F226BB954FCD5341FF584B5500F9F9C0B8448B6896DB94D5"  
            + "BB6FC0E9698A57DSDFFSFFFFFFFFFFFFSFGDSDSVDCBCA6F333F73EB9982DE8FC"  
            + "81E7CA0A5327AAD47E588D8F21CB58BAC40A245BE2B36DEF0F61747369041DED879FBF3";  
    public static List<NameValuePair> list=new ArrayList<NameValuePair>();//存放post请求的参数  
    public static CookieStore store = new BasicCookieStore();//存储cookie  
      
    public static void main(String[] args) throws Exception {  
        //初始化浏览器 ,设置标识,建立cookiestore，默认重定向策略为全部请求都跟随重定向（本例中无影响  
        HttpClient client = HttpClientBuilder.create().setUserAgent(UA).setRedirectStrategy(new LaxRedirectStrategy())  
                .setDefaultCookieStore(store).build();    
        HttpGet con1 = new HttpGet(LOGIN_URL);//建立get请求  
        HttpResponse res = client.execute(con1);//发送请求，得到响应  
        Document doc = Jsoup.parse(EntityUtils.toString(res.getEntity()));//将响应实体转为document，利用jsoup解析  
        //下载验证码图片  
        HttpGet pic = new HttpGet(CODE_URL);  
        HttpResponse res2 = client.execute(pic);  
        OutputStream cout = new BufferedOutputStream  
                (new FileOutputStream("C:\\Users\\Simon\\Desktop\\emm\\code.jpg"));  
        res2.getEntity().writeTo(cout);//写入文件输出流  
        cout.close();  
        String cap = OCRUtils.get("C:\\Users\\Simon\\Desktop\\emm\\code.jpg");  
        Elements ele = doc.select("input");  
        for (Element x:ele) {  
            if (x.attr("name").equals("rsa"))  
                x.attr("value",RSA);              
            if (x.attr("name").equals("ul"))   
                x.attr("value","587");  
            if (x.attr("name").equals("pl"))  
                x.attr("value","8");  
            if (x.attr("name").equals("code"))  
                x.attr("value",cap);  
            //排除空值表单属性 ,把该参数放进list里  
            if (x.attr("name").length()>0&&!x.attr("name").equals("autoLogin"))  
                list.add(new BasicNameValuePair(x.attr("name"),x.attr("value")));  
        }  
        HttpPost con3 = new HttpPost(LOGIN_URL);//新建post请求  
        con3.setEntity(new UrlEncodedFormEntity(list));//设置请求体的参数  
        HttpResponse res3 = client.execute(con3);//执行响应  
        //System.out.println(store);  
        //天坑注意！res3响应会重定向到登陆页面，这并不是我们想要的，必须再次创建get请求，目标是TARGET_URL  
        HttpGet con4 =new HttpGet(TARGET_URL);  
        con4.setHeader("Referer",LOGIN_URL);//设置一下请求头，表明一下自己从哪里来  
        HttpResponse res4 = client.execute(con4);  
        System.out.println(res4.getStatusLine().getStatusCode());//返回http状态码  
        System.out.println(EntityUtils.toString(res4.getEntity()));//获取实体的字面值得用EntityUtils类的静态方法  
        System.out.println(store);//查看cookie  
    }  
}
```

---

2018-2-23晚：成功解决验证码问题！，使用tess4j工具即可完成简单验证码的识别！据说还能通过训练强化tesseract的识别能力！太强大了.jpg
```java
package just4tset4;  
import java.awt.image.BufferedImage;  
import java.io.File;  
import javax.imageio.ImageIO;  
  
import net.sourceforge.tess4j.ITesseract;  
import net.sourceforge.tess4j.Tesseract;  
import net.sourceforge.tess4j.util.ImageHelper;  
public class OCRUtils {  
  
    public static String get(String path) throws Exception  {  
        File pic = new File (path);//图片位置  
        //图片二值化，转化为黑白图  
        BufferedImage grayImage = ImageHelper.convertImageToBinary(ImageIO.read(pic));  
        ImageIO.write(grayImage, "jpg", pic);  
          
        ITesseract instance = new Tesseract();//新建实例  
        instance.setLanguage("eng");//选择字库文件（只需要文件名，不需要后缀名）  
        String result = instance.doOCR(pic);//开始识别  
        //天坑注意！result自带两个空格！   
        return result.substring(0,result.length()-2);  
  
    }  
}
```
