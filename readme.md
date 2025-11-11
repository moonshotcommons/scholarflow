## 部署

iota client publish

## 交互
### 设置环境变量
```
export packageId=0x03b549cb1a44bab280f1355a85f1d3752df30abf76c445e56cc92fd06237c177
export admCap=0x1bc831c6da3707f3ab66d931c30187a496f8c9ca9145d3b1f6763504ef4f55f4
export upgradeCap=0xf9aa2c583f47e47aee41e5de31c2e9392511e96824cfb96d251df71838bfb3a8
export student=0x236ef939015c668d329c59e8a12661cf21841b0a052548f9cc855f391b6b3f67
export grant=0x5a4548b74d9535ddc2ee76bfa0c08fe0c3f6b4e62bb448e2530105ac544376fc
export newPackageId=0x5cca6896e028727d1f6224d6c4414db35ffcac0450656d901a9b3c9dbef1a60d
export thirdPackageId=0xff3e58d1813820926e491ef64dd420578a2a2b812d7bbd34dae93c874570fe06
export registry=0xee397ddb300d9f69e59894ff5c02a75996b683a070f40546b7f5fbd4fd0e5ffc
export grantV2=0xb07d3958cc093029a78861093de306cf077d3fb7aab9eb62cae4450d5634a814
```

### mint

iota client call --package $packageId --module grant --function mint --args $student 666 $admCap

### 升级

1. toml 文件采用如下配置:

```toml
[package]
name = "scholarflow"
edition = "2024" # edition = "legacy" to use legacy (pre-2024) Move
# 指定合约首次部署的地址
published-at = "0x03b549cb1a44bab280f1355a85f1d3752df30abf76c445e56cc92fd06237c177"

[addresses]
# 该地址为0地址
scholarflow = "0x0"
```

2. 执行升级命令: `iota client upgrade --upgrade-capability $upgradeCap`

### 注册

iota client call \
 --package $thirdPackageId \
 --module registry \
 --function create \
 --args $admCap

### 调用新 mint_return_id、index_grant 函数

iota client ptb \
--assign admCap @0x1bc831c6da3707f3ab66d931c30187a496f8c9ca9145d3b1f6763504ef4f55f4 \
--assign upgradeCap @0xf9aa2c583f47e47aee41e5de31c2e9392511e96824cfb96d251df71838bfb3a8 \
--assign student @0x236ef939015c668d329c59e8a12661cf21841b0a052548f9cc855f391b6b3f67 \
--assign thirdPackageId @0xff3e58d1813820926e491ef64dd420578a2a2b812d7bbd34dae93c874570fe06 \
--assign registry @0xee397ddb300d9f69e59894ff5c02a75996b683a070f40546b7f5fbd4fd0e5ffc \
--move-call thirdPackageId::grant::mint_return_id student 888 admCap \
--assign minted_id \
--move-call thirdPackageId::registry::index_grant registry student minted_id admCap
