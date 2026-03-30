---
name: cloudkit-media-sync
description: 使用可复用的 CloudKit 媒体同步设计骨架实现：基于 recordName/fileID 的媒体主键、CKAsset 上传与下载、可选 blocked/可见性字段、分页查询（CKQueryOperation.Cursor），以及（可选）通过 cloudkit:// 自定义 SDWebImage Loader 接管图片加载并规避注册顺序坑。
---

# CloudKit 媒体同步骨架（通用）

## 适用范围
当你要在 Swift iOS/macOS 项目中实现“媒体（图片/视频等）在 CloudKit 存储 + 客户端按主键拉取 + 支持分页查询与本地缓存”时，使用本 Skill。

本 Skill 默认输出“通用代码结构/模块化接口”，避免写死业务 recordType/recordKey；你只需要在“配置清单”里替换字段与命名规则即可复用到其他项目。

## 配置清单（新项目必须先补齐）
1. 记录类型（recordType）
   - `imageRecordTypeName`：图片 recordType（如 `Images`）
   - `videoRecordTypeName`：视频资源 recordType（如 `Video`）
   - `indexRecordTypeName`（可选）：从业务 sourceId 映射到视频 recordName（如 `VideoIndex`）
2. 关键字段（recordKey）
   - 图片
     - `imageAssetKey`：CKAsset 字段 key
     - `imageBlockedKey`（可选）：可见性/blocked 字段 key（0 表示可见）
     - `imageStableIDKey`（可选）：媒体稳定 ID 字段 key（若你不完全依赖 recordName）
   - 视频
     - `videoAssetKey`：CKAsset 字段 key
     - `videoStableIDKey`（如 sourceId/localIdentifier）：用于判断已存在或创建索引
     - `videoBlockedKey`（可选）：可见性/blocked 字段 key
3. 主键命名规则
   - `recordName` 的生成方式（包含时间戳/用户命名空间/分隔符策略）
   - 媒体主键是使用 `recordName` 还是使用额外字段（建议主键统一用 `recordName`）
4. 数据库存储域
   - publicCloudDatabase 还是 privateCloudDatabase（或两者分别存不同媒体/数据）
5. 本地缓存策略
   - 视频：缓存到 `cachesDirectory` 下的子目录（文件名 = `recordName + .ext`）
   - 图片：两种策略二选一
     - 让 UI 框架处理缓存（推荐可选 SDWebImage 集成）
     - 或你自己实现内存/磁盘缓存并在下载后写入

## 通用模块化设计（建议实现这些接口）

### 1) CloudKit 数据库适配器（必需）
目标：把 CloudKit 的 `find/save/delete/query` 统一成一套接口，便于后续复用与测试。

建议接口：
- `find(recordName: String) -> CKRecord?`
- `save(record: CKRecord) -> String?`（返回成功 recordName）
- `delete(recordName: String) -> Bool/CKRecord.ID?`
- `query(type: String, predicate: NSPredicate, sort: [NSSortDescriptor], cursor: CKQueryOperation.Cursor?, pageCount: Int) -> ([CKRecord], CKQueryOperation.Cursor?)`

关键要求：
- cursor 不为 nil 时使用 `CKQueryOperation(cursor:)`
- 回调最好进入主线程（如果你的调用方是 UI）

### 2) record schema（建议集中管理）
目标：把 recordType 与 recordKey 集中放在单一位置（枚举/struct/配置文件），避免散落字符串。

建议：
- 用一个 `CloudSchema` 类型收敛 recordTypeName 与各 recordKey
- 用一个 `MediaID` 类型统一业务主键（内部最终映射到 recordName）

### 3) 媒体上传器（CKAsset 上传，必需）

图片上传骨架（通用流程）：
1. 生成 `recordName`（或使用外部稳定 ID 映射到 recordName）
2. 创建 `CKRecord(recordType: imageRecordTypeName, recordID: CKRecord.ID(recordName: ...))`
3. 写入 `CKAsset(fileURL:)` 到 `imageAssetKey`
4. 写入可选字段：blocked/width/height/useFor/location 等
5. `database.save(record)`

视频上传骨架（通用流程）：
1. 导出/准备媒体文件本地 URL（来源可以是本地文件/生成文件/PHAsset 导出）
2. 创建 `CKRecord`，写入 `CKAsset(fileURL:)` 到 `videoAssetKey`
3. 写入可选字段：stableID/sourceId/blocked 等
4. 保存并返回 `videoRecordName`

可选：video index（解决“sourceId -> video recordName”的快速定位）
1. 如果启用 `indexRecordTypeName`：先查询或直接创建映射 record
2. 映射 record 内保存 `sourceId` 与 `videoRecordName`
3. UI/列表页只依赖 `videoRecordName` 或 sourceId，通过 index 获取

### 4) 媒体下载器

视频下载 + 缓存骨架：
1. 若本地缓存存在：直接返回本地 `fileURL`
2. 若不存在：
   - `find(videoRecordName)`
   - 取 `videoAssetKey` 中的 `CKAsset`
   - 校验 `asset.fileURL` 为 fileURL 且文件存在
   - copy 到缓存目录并返回

图片下载骨架（两种实现路径）：
- 路径 A：自己实现（下载 record -> 取 CKAsset -> 转 UIImage -> 写缓存/回调）
- 路径 B：交给图片框架（推荐，详见可选 SDWebImage 集成）

关键一致性（建议强制）：
- blocked/可见性检查放在拿到 record 之后、真正构建 UIImage/文件之前
- 返回空/null 由上层决定占位图与重试

### 5) 分页查询（CKQueryOperation.Cursor）
通用要求：
- predicate/sort 每一页保持一致
- cursor 从上一页 query completion 里获得，并在下一次传入
- pageCount/resultsLimit 需要与 UI 翻页或“加载更多”策略一致

## 可选集成：SDWebImage 的 cloudkit:// 自定义 Loader（仅当你的项目使用 SDWebImage）

### A) URL 约定（建议）
- scheme：`cloudkit`
- host：`image`
- query：
  - `recordName=<percentEncodedRecordName>`

例如：`cloudkit://image?recordName=<encoded>`

### B) Loader 的责任边界（推荐）
- `canRequestImage(for:)`：仅当 URL scheme/host 匹配时才返回 true
- `requestImage(...)`：
  1. 解析 recordName
  2. `database.find(recordName)`
  3. 检查 blocked（若有）
  4. 取 CKAsset -> 转 UIImage
  5. 回调给 SD（缩放/多尺寸缓存交给 SD 的 transformer/context）

### C) 注册时机/优先级（必读，强制写进你新项目）
1. 确保在任何可能首次触发 `SDWebImageManager.shared` 之前完成：
   - `SDImageLoadersManager.shared.loaders = [SDWebImageDownloader.shared, CloudKitLoader()]`
   - `SDWebImageManager.defaultImageLoader = SDImageLoadersManager.shared`
2. loader 数组顺序可能影响命中优先级（你的项目实现可能使用 reverseObjectEnumerator 之类逻辑）
3. 若没在正确时机注册，`cloudkit://` 可能被当成普通网络 URL，导致失败

## 自检清单（通用）
- 上传后，recordName 是否被稳定保存并能在新设备/新进程查到？
- 下载时：CKAsset.fileURL 是否可用（fileURL 存在且存在于本地）？
- blocked 字段：blocked 值类型与语义是否一致（例如 `0/1` or `true/false`）？
- 分页：cursor 透传是否正确，predicate/sort 是否一致？
- （可选）SDWebImage：`cloudkit://` 是否走了自定义 loader（而不是默认 HTTP loader）？

## 你在请求帮助时应提供的输入
1. 你要同步的媒体类型：`image` / `video` / `both`
2. recordTypeName 与关键字段 key（或允许我按你现有 schema 给建议）
3. recordName/fileID 生成规则（或现有规则）
4. public/private 数据库选择
5. 你是否使用 SDWebImage（若是：说明你希望缩放由 SD transformer 做，还是由 loader 自己做）

