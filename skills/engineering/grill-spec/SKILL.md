---
name: grill-spec
description: 在還沒有具體計畫時盤問需求、術語、邊界與驗收條件，出口是第一個最小 vertical slice。Use when requirements are unclear and no concrete plan exists yet — the user has a goal or feature idea but scope, acceptance checks, or domain terms are still fuzzy. Do NOT use when a concrete plan already exists and needs challenging against documented decisions — use grill-with-docs for that.
maintainer: justin.choi
status: stable
---

# Grill Spec

適用前提:還沒有具體計畫。如果已經有一份計畫需要對照 `CONTEXT.md` 與 ADR 挑戰,改用 `/grill-with-docs`。

## Resource Foundation（開始盤問前，先蒐證）

如果待釐清的 backlog 已經累積一段時間（數週而非單一 session）、橫跨多個系統或多個人，先建立跨來源的資源基礎，再開始逐題盤問：

1. 盤點該領域碰得到的每個現有來源：ticket tracker（含完整 parent/child 關係，不只是被點名的那幾張）、team chat 歷史（用關鍵字搜尋，不只是別人隨口提到的那個 channel）、目前的程式碼/設定（用正確的 git ref）、既有文件/筆記。
2. 把每個來源的說法互相對照——這一步經常能在真正開口問之前，就先解掉 backlog 裡的一部分（tracker 寫「未解決」但 chat 裡已經討論過；文件寫「尚未實作」但程式碼其實已經做了）。
3. 把結果寫成一份索引檔，明確區分「已被證據解決」與「真正還open」，每個說法附來源與時間戳。

只把真正還開放的部分交給下面的逐題盤問。這一步成本不低（可能要動用多個系統、甚至委派 sub-agent 盤點），值得投入的情境是 backlog 橫跨多系統/多人且持續累積；如果 tracker/文件本來就維護得很即時，這一步大概只會確認已知的事，成本划不來。也不要讓蒐證變成逃避開口問人的藉口——目的是讓問題更準、更少，不是試圖不問人就解決一切。

（這一步不是獨立通過 `process-vs-work-doctrine` rule 1 的「第二次出現」門檻蓋出來的新技能——單一事件內的延伸做法，直接併入既有技能的流程，是因為它直接改善了既有技能的執行方式，跟蓋一個全新技能是兩回事。）

一次只問一個問題，直到以下內容足夠清楚：

- 目標使用者或操作者是誰
- 成功行為是什麼
- 哪些情境在 scope 內，哪些不在
- 驗收要怎麼看出來
- 是否牽涉既有術語、資料模型、外部系統或 irreversible decision

## Rules

- 如果答案可從 codebase 或文件推得，先自行探索，不要先問人。
- 每個問題都附上建議答案或候選方向。
- 發現語言模糊時，提出一個更精確的 canonical term。
- 若新術語被確認，更新 `CONTEXT.md`。
- 若出現重大 trade-off，評估是否值得新增 ADR。

## Exit Criteria

在開始實作前，至少要能明確說出：

1. 要改變的外部行為
2. 驗收方式
3. 第一個最小 vertical slice 是什麼
