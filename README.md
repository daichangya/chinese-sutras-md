# Chinese Sutras Markdown Corpus (Corpus V3)

本仓库为 **jingxin** 及同类项目的佛经 Markdown 语料库：按部类 / 经名 / 卷组织，人类可读；段落身份（`canonical_id`、`start_ref` 等）由 `_index/blocks.jsonl` 侧车维护，**不在 Markdown 正文中**。

约 **4,994** 部经，含 `原文/`（繁体）、`简体/`、`拼音/`、`白話/`、`注釋/` 等子目录。

## 在 jingxin 中使用

```bash
git clone git@github.com:daichangya/jingxin.git
cd jingxin
git clone git@github.com:daichangya/chinese-sutras-md.git chinese-sutras-md
npm install
npm run db:migrate
npm run corpus:import
npm run dev
```

默认语料路径为 `chinese-sutras-md/`（可用环境变量 `CORPUS_DIR` 覆盖）。

## 目录结构

```text
chinese-sutras-md/              # 本仓库根 = 语料根
├── 阿含（小乘根本经典）/
│   └── 长阿含经_1卷/
│       ├── meta.yaml
│       ├── _index/blocks.jsonl
│       ├── 原文/第001卷.md     # CBETA 繁体原文
│       ├── 简体/第001卷.md
│       ├── 拼音/第001卷.md
│       ├── 白話/第001卷.md
│       └── 注釋/第001卷.md
└── README.md
```

经目按 **23 类佛学部类** 分顶层目录（如 `般若`、`法华`、`新编（新增及近现代文献）`）。经目文件夹名为**简体中文**（`书名_作者_N卷`）；`原文/` 正文保持繁体。

`slug` 不在 MD 中；阅读站点 URL 默认使用 `cbeta_id` 小写（如 `t08n0251`），可在 `meta.yaml` 用 `slug` 覆盖。

### 繁简约定

| 位置 | 繁简 |
|------|------|
| 经目目录名、`meta.yaml` 的 title / translator | 简体 |
| `白話/`、`注释/`、`简体/` | 简体 |
| `原文/` 卷正文 | 繁体（CBETA 保真） |

### meta.yaml 示例

```yaml
cbeta_id: T08n0251
title: 般若波罗蜜多心经
translator: 玄奘
category: 般若
source_xml:
  - T/T08/T08n0251.xml
```

`zaijia` 块（可选）记录 CBETA 在家目录主题层级，供检索展示。

## 生成与维护（在 jingxin 仓库中执行）

语料生成、导入 SQLite、审计等命令均在 [jingxin](https://github.com/daichangya/jingxin) 项目中：

```bash
# 从 CBETA XML 生成/更新语料（需 vendor/xml-p5）
npm run corpus:gen
npm run corpus:gen -- --resume

# 导入 SQLite（VPS 仅需语料 + _index，无需 XML）
npm run corpus:import
npm run corpus:import -- --md-only

# 繁简 / 拼音
npm run corpus:t2s
npm run corpus:pinyin
npm run corpus:pinyin -- --script simplified

# 统计与审计
npm run corpus:stats
npm run corpus:audit-zaijia-all
```

环境变量（jingxin）：

- `CORPUS_DIR` — 默认 `chinese-sutras-md`
- `CBETA_XML_DIR` — 默认 `vendor/xml-p5`（生成语料时需要）

## 人工校对白话

1. 编辑 `{部类}/{经名}/白話/第NNN卷.md`，与 `原文/` 同卷、同段落顺序（空行分段）
2. 在 jingxin 中运行 `npm run corpus:import`

## 许可与来源

正文来源于 [CBETA](https://www.cbeta.org/) 电子佛典；使用前请遵守 CBETA 及相关版权约定。

## 首次推送到 GitHub（分批）

语料体积大（~3GB），建议按部类分批 push：

```bash
cd chinese-sutras-md
./push-by-dept.sh              # 全量：README + 23 部类，约 24 次 push
./push-by-dept.sh --resume       # 中断后续推（跳过已有 commit）
./push-by-dept.sh --dept 般若    # 仅推指定部类
./push-by-dept.sh --dry-run      # 预览计划
```

日志默认写入 `.push-log.txt`（已 gitignore）。
