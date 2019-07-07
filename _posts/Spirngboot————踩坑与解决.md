---
title: Spirngboot————踩坑与解决
date: 2019-05-11 15:53:10
tags:
 - Java
 - Spring-boot
 - docker
 - 数据库
---
## 前言

数据库的大作业原本是想用Springboot + PostgreSQL + Redis + Docker 做的，顺便学习一下后端知识。

非常不幸的，踩了不少坑，也很难找到中文的解决办法，最后靠着伟大的StackOverflow 和 国外的热情网友们才解决了问题。

如果你在学习Spring-Boot的路上凑巧遇上了同样的问题，希望这篇文章能对你有所帮助XD

<!-- more -->

## JPA

### 使用PGSQL枚举类

**安装依赖**

```xml
<dependency>
    <groupId>com.vladmihalcea</groupId>
    <artifactId>hibernate-types-52</artifactId>
    <version>2.4.3</version>
</dependency>
```

**定义内部枚举类**

```java
    public enum UserRole {
        admin("管理员"), student("学生");
        private String userRole;

        UserRole(String s) {
            userRole = s;
        }
    }
```

**使用注解**

```java
@TypeDef(name = "pgsql_enum", typeClass = PostgreSQLEnumType.class) // 定义PG枚举类
public class User {
    //...
    @Column
    @Enumerated(EnumType.STRING)
    @Type(type = "pgsql_enum")// 使用PG枚举类
    private UserRole permission;
    //...
}
```


### 报错: detached entity passed to persist

- 检查ID生成策略
- 如果使用了 `ManyToOne` 或 `ManyToMany`注解,请注意须将维护端的`casade`设置为`{CascadeType.MERGE}`

## Docker

> 推荐这篇Docker入门的gitbook，非常的全
>
> https://yeasy.gitbooks.io/docker_practice/

### 容器中的springboot无法连接到数据库

这是因为localhost无法被正确解析，正确做法是在`application.(yml|properties)`的`spring.datasource.url`，将值改为 `jdbc:postgresql://${数据库的service名}:5432/postgres`

这样才会解析到正确的localhost.

###  针对环境进行不同的配置

经过上述的修改，我们发现，虽然容器内的springboot能正确的连接到数据库了，但是为了开发的方便，一般调试是在宿主机上进行的。所以，我们需要写两套配置，一套用于开发，一套用于生产环境

```
src/main/resources/
├── application-base.yml
├── application-dev.yml
├── application-prod.yml
└── application.yml
```

> 配置文件结构如上
>
> base是基础配置文件，dev和prod对base进行include后写入url，顶层文件选定激活的配置

- application-base.yml

  ```yml
  spring:
    datasource:
      platform: postgres
      username: postgres
      password: ******
      driver-class-name: org.postgresql.Driver
    jpa:
      show-sql: true
      hibernate:
        ddl-auto: update
  
  server:
    port: 8090
  ```

- application-dev.yml

  ```yml
  spring:
    profiles:
      include: base
    datasource:
      url: jdbc:postgresql://localhost:5432/postgres
  
  ```

- application-prod.yml

  ```yml
  spring:
    profiles:
      include: base
    datasource:
      url: jdbc:postgresql://database:5432/postgres
  ```

- application.yml

  ```yml
  spring:
    profiles:
      active: dev
  ```

这样我们就拥有了两套配置，默认是开发环境。

为了让docker上采用生产环境，我们修改`Dockerfile`文件

```dockerfile
FROM openjdk:8
COPY target/xxxxx.jar app.jar
VOLUME /tmp
ENTRYPOINT ["java","-jar","/app.jar","--spring.profiles.active=prod"]
```

> 在entrypoint上加入新的参数制定profiles即可

### 使用Docker-compose组合各个容器

传统的docker容器打开方式是单个单个开的，需要互连的容器要使用`--link`参数，这样是不利于维护的，我们需要将这些容器用一个文件统一组织起来。方法就是使用[**docker-compose**](https://yeasy.gitbooks.io/docker_practice/compose/)

使用方法非常简单，写好配置文件之后只需`docker-compose up`即可一键启动所有服务

```yml
version: "3"
services:
  database:
    image: postgres
    container_name: pg-db
    environment:
      - POSTGRES_PASSWORD=****
    ports:
      - 5432:5432
    volumes: # 可持久化数据
      - pgdata:/var/lib/postgresql/data

  web:
    build: .
    container_name: spring-boot
    depends_on:
      - database
    ports:
      - 8090:8090

volumes:
  pgdata:

```

> 一个普通的spring-boot项目的docker配置
>
> 拥有两个服务，数据库和web

