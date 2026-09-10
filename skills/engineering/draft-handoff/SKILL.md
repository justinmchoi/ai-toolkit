---
name: draft-handoff
description: Hand a drafted artifact to the user through the clipboard, with post-copy verification and on-demand re-copy, so the user can review it and paste it into a destination the agent must not or cannot write to directly (a review-gated personal vault such as Obsidian, a web form, another application). Trigger phrases include "copy for me", "幫我複製", "pbcopy", "過目再貼". Do NOT use when the agent can write the content into the target repo directly, or for multi-file transfers.
maintainer: justin.choi
status: stable
---

# Draft Handoff（草稿剪貼簿交接）

定位：剪貼簿是 review gate 的實作。使用者過目後親手貼上，agent 永不直寫目的地。檔案是 source of truth，剪貼簿只是通道。

## Trigger

**Use this skill when:**

- 起草的內容要進 agent 不該直寫的地方：過 human review gate 的個人 vault（Obsidian）、網頁表單、其他 app
- 使用者說「copy for me」「幫我複製」「pbcopy」「過目再貼」
- 使用者回報「貼出來不是那份」（剪貼簿被蓋，走重灌流程）

**Do not use when:**

- 內容的目的地是 agent 可以直接寫入的 repo（直接寫檔）
- 一次要搬多個檔案（用檔案交付，不用剪貼簿）

## 流程

1. **落檔**：草稿寫進 session scratchpad 的獨立檔案（不用 `/tmp`），檔名固定；之後所有重灌都用同一份，永不憑記憶重打。
2. **對外檢查**：目的地會被使用者以外的人看到時，先套用對外文稿規則再複製。
3. **複製**：macOS 用 `pbcopy < <file>`；Windows 用 `clip < <file>` 或 PowerShell `Set-Clipboard`。
4. **驗證**（每次複製後立即做，並回報使用者）：首行、末行、行數三項，macOS 用 `pbpaste | head -1`、`pbpaste | tail -1`、`pbpaste | wc -l`。任一項對不上：停下、重灌、重驗，不猜原因不硬貼。
5. **防蓋提醒**：告訴使用者現在就貼，中間不要選取或複製任何文字。多數環境選取即覆蓋剪貼簿。
6. **重灌**：使用者回報被蓋掉時，從同一個 scratchpad 檔案重新複製並重新驗證。

## 為什麼是這個形狀

- 剪貼簿在複製與貼上之間會被靜默覆蓋（選取複製、其他 app 寫入）。驗證讓事故十秒可發現，重灌讓修復零成本。
- 「過目再貼」把人的眼睛留在迴路裡。這是本 skill 存在的理由，不是它的限制：目的地有 review gate 時，繞過剪貼簿改為直寫就是繞過 gate。
