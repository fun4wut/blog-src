---
title: pyqt踩坑实录
date: 2018-11-17 22:17:08
tags: Python
toc: true
categories: 经验分享
---
## 如何创建一个可编辑的QLabel（双击编辑，回车保存）
1. 建立一个MyLabel类继承QWidget

2. 布局中添加两个组件label(继承自QLabel) 和 edit(继承自QLineEdit)

3. [重要] **设置label显示，edit隐藏**

4. 重写  `mouseDoubleClick` 方法，使label隐藏，edit显示

5. 为完成编写操作设置回调（槽函数）。当editingFinished信号发出时触发该槽函数

6. 坑点：组件创建完需立即加入layout中，否则会炸

7. Sample
```py
class SingleBuddyLabel(QWidget):
    def __init__(self,text):
        super().__init__()
        self.layout = QHBoxLayout(self)
        self.label = QLabel(text)
        self.edit = QLineEdit()
        self.layout.addWidget(self.label)
        self.layout.addWidget(self.edit)

        self.label.show()
        self.edit.hide()
        def save_edit():
            #TODO:
        self.edit.editingFinished.connect(save_edit)

    def mouseDoubleClickEvent(self,event):
        self.label.hide()
        self.edit.show()
        self.edit.setFocus()

```
<!--more-->

## 如何刷新组件
*前提： 该组件必须处在layout中*

1. 通过位置定位该元素【一般是将要更新的widget单独放在layout中】
```py
widget = layout.itemAt(i).widget()
```

2. 先将其从layout中删去，然后再删去该widget
```py
layout.removeWidget(widget)
widget.deleteLater()
```

3. 重新获得新的widget，加入到layout中
```py
widget = render()
layout.addWidget(widget)
```

4. 坑点：**widget不要用成员变量，否则会崩**


## 如何多线程定时刷新UI
1. 建立一个线程类继承自QThread

2. 重写run方法，里面放定时的代码
```py
class MyThread(QThread):
    trigger = pyqtSignal()
    def __init__(self):
        super().__init__()

    def run(self):
        while True:
            time.sleep(15)#线程阻塞15秒
            self.trigger.emit()#阻塞过后发送信号
```
3. 新建一个MyThread实例作为所需更新类的成员变量
```py
class Try(QWidget):
    def __init__(self):
        super().__init__()
        self.layout = QHBoxLayout(self)
        lis = EventList()
        self.layout.addWidget(lis)
        self.timeThread = MyThread()
        self.timeThread.trigger.connect(self.update)#设置槽函数
        self.timeThread.start()

    def update(self):
        #更新UI的代码放这里
```

4. 坑点：**pyqtSignal创建必须在__init__方法之前**


## 其他TIPS/集锦

### 设置居中
`label.setAlignment(Qt.AlignCenter)`

### 一步给组件设置layout
`layout = QHBoxLayout(widget)`

### QLabel自适应文字
`label.adjustSize()`
