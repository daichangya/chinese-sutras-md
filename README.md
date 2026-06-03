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
├── 辞典/                       # 佛教辞典（JSONL 真相源）
├── 知识图谱/                   # 知识图谱（实体/关系 JSONL）
├── 经藏/                       # 汉传经目 Markdown（23 部类）
│   ├── 阿含（小乘根本经典）/
│   │   └── 长阿含经_1卷/
│   │       ├── meta.yaml
│   │       ├── _index/blocks.jsonl
│   │       ├── 原文/第001卷.md # CBETA 繁体原文
│   │       ├── 简体/第001卷.md
│   │       ├── 拼音/第001卷.md
│   │       ├── 白話/第001卷.md
│   │       └── 注釋/第001卷.md
│   └── 般若/ …
└── README.md
```

经目在 `经藏/` 下按 **23 类佛学部类** 分目录（如 `般若`、`法华`、`新编（新增及近现代文献）`）。经目文件夹名为**简体中文**；`原文/` 正文保持繁体。

从旧版「部类直接在仓库根下」迁移：

```bash
# 在 jingxin 仓库
npm run corpus:migrate-nest -- --dry-run
npm run corpus:migrate-nest
```

从旧版英文目录名（`dictionaries`、`knowledge-graph`、`sources/soothill` 等）迁移为中文：

```bash
npm run corpus:migrate-dir-zh -- --dry-run
npm run corpus:migrate-dir-zh
```

### 经目目录名

格式：`{书名}_{作者}_{后缀}`（分段用下划线，均为简体）。

后缀**互斥**，按优先级只取一段：

1. **卷数**：`{N}卷`（例如 `1卷`、`600卷`）。**不再**把 CBETA 经号末尾字母拼在卷数上（旧式 `1卷b` 已废弃）。
2. **消歧段**（仅当经号带字母变体且与同部类下「书名+作者+卷数」冲突时）：
   - 优先 **物理卷号**（大般若 T220 等）：如 `第577卷`、`第579-583卷`（从 XML `cb:juan` 提取）
   - 其次 **会/品名**：如 `第九能断金刚分`（从 XML `cb:div type="hui"` 提取）
   - 再次 **录文语义**（新编文献）：如 `录文二`、`录文三`
   - 兜底 **紧凑经号**：如 `n0073b`、`n1510b`
3. **最后兜底**：完整 `cbeta_id`（如 `T08n0236b`）

**ZW 藏外文献同名冲突**：若 CBETA 在多部 ZW 卷中复用相同 level-m 题名（如各卷《藏外佛教文献》要目），同部类内出现同名时，在 `meta.title` 末尾追加 `（ZW第N卷）`（从 XML `idno type="vol"` 读取），目录仍用 `书名_1卷`。示例：

| cbeta_id | title | 目录名 |
|----------|-------|--------|
| ZW08na047 | `…第一～九辑要目（ZW第8卷）` | `…（ZW第8卷）_1卷` |
| ZW09na054 | `…第一～九辑要目（ZW第9卷）` | `…（ZW第9卷）_1卷` |

`原文/` 标题行仍保留 XML 繁体题名；仅 `meta.title` 与辅助层 MD 首行使用带 ZW 卷标识的简体题名。

示例：《金刚经赞集》系列（ZW09n0073）：

| cbeta_id | 目录名 |
|----------|--------|
| ZW09n0073a | `金刚经赞集_达照_1卷` |
| ZW09n0073b | `金刚经赞集（拟）_达照_录文二` |
| ZW09n0073c | `金刚经赞集（拟）_达照_录文三` |

大般若 **T220 分卷**（T07n0220g–o 等同题 `(第401卷-第600卷)` 冲突组）：

| cbeta_id | 目录后缀（示例） |
|----------|------------------|
| T07n0220h | `…_玄奘_第577卷`（第九能断金刚分） |
| T07n0220i | `…_玄奘_第578卷`（第十般若理趣分） |
| T07n0220j | `…_玄奘_第579-583卷` |

整经索引见 `大般若波罗蜜多经_玄奘_600卷`（`T05n0220`，无正文，仅子目录列表）。

批量重命名（在 jingxin 仓库）：

```bash
npm run corpus:migrate-dept -- --dry-run          # 预览 ~210 处目录变更
npm run corpus:migrate-dept -- --dept 般若        # 仅某部类
npm run corpus:migrate-dept                       # 确认后执行
npm run corpus:import -- --md-only                # 刷新 SQLite 路径
```

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
dir_label: 录文二   # 可选；目录消歧标签（语义优先于 n0073b 式经号）
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

# 部类/目录名迁移（含经目目录消歧重命名）
npm run corpus:migrate-dept -- --dry-run
npm run corpus:migrate-dept
```

环境变量（jingxin）：

- `CORPUS_DIR` — 默认 `chinese-sutras-md`
- `CBETA_XML_DIR` — 默认 `vendor/xml-p5`（生成语料时需要）

## 人工校对白话

1. 编辑 `经藏/{部类}/{经名}/白話/第NNN卷.md`，与 `原文/` 同卷、同段落顺序（空行分段）
2. 在 jingxin 中运行 `npm run corpus:import`

## 许可与来源

正文来源于 [CBETA](https://www.cbeta.org/) 电子佛典；使用前请遵守 CBETA 及相关版权约定。

## 首次推送到 GitHub（分批）

语料体积大（~3GB），**不要用** `git-add-n.sh` 随机分批（会把「删除旧路径」与「新增经藏/」混在同一 commit，且 message 无意义）。

推荐 `push-by-dept.sh`（经目已迁到 `经藏/` 时，会先从索引移除根下旧部类路径，再 `git add 经藏/部类/`）：

```bash
cd chinese-sutras-md
./push-by-dept.sh --dry-run       # 预览：bootstrap → 辞典/知识图谱 → 23 部类
./push-by-dept.sh                 # 全量 push（约 26 次：1 工具 + 2 辅助 + 23 部类）
./push-by-dept.sh --resume        # 中断后续推（跳过 经藏/部类 已在 git 索引中的部类）
./push-by-dept.sh --no-push       # 仅本地 commit，稍后统一 push
./push-by-dept.sh --dept 般若     # 仅推指定部类
```

若终端里仍在循环执行 `git-add-n.sh`，请先 `Ctrl+C` 停止，再运行上述脚本。

日志默认写入 `.push-log.txt`（已 gitignore）。
