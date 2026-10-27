# 窮奇 Boss v15 — Godot 4 戰鬥原型

## 內容
以 v14 專案為基礎，保留分層 Bone2D 與六組動畫。新增可重複的自動攻擊循環、俯衝及爪擊冷卻、攻擊事件紀錄、投射物弱點優先判定、封印/死亡/城牆失敗測試，以及 headless 自動測試腳本。

## 使用
1. Godot 4 開啟 `project.godot`。
2. F6 執行 `Battle.tscn` 或 F5 執行主場景。
3. A 發射、D 俯衝、J 爪擊、按住 F 封印、R 重置。
4. 自動 Boss 攻擊每 3 秒嘗試一次（冷卻與狀態限制生效）。

## 自動測試
在專案根目錄執行：
`godot --headless --path . --script res://tests/run_tests.gd`

測試腳本會輸出 PASS/FAIL 與 `user://v15_test_results.json`，測試內容：初始值、投射物弱點優先、單次傷害、破翼落地、封印、俯衝命中及單次傷害、Boss 死亡、城牆失敗。

## 注意
目前沒有實際執行 Godot 引擎測試，GDScript 與場景相容性未經引擎確認；自動測試為可執行的測試規格，不是已通過的測試結果。美術仍為原型分層素材。請在 Godot 4.3+ 中執行測試並回報錯誤。
