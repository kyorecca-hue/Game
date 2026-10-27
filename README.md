# 神獸紀元：窮奇 Boss 戰鬥原型 v16.2

使用 Godot 4.6.3 開啟 `project.godot`，按 F5 執行。畫面左上角應顯示 **QIONGQI v16.2**。

更新時請關閉舊專案，將 ZIP 解壓到新資料夾，再從 Godot 專案管理員匯入新的 `project.godot`，避免從舊捷徑開啟其他副本。

本版保留骨架對齊修正，並新增視窗等比例縮放，防止較小視窗裁掉窮奇、城牆與介面。現有切圖拼接痕跡仍存在。

操作：左鍵點擊翅膀或身體攻擊、A 射擊、D 俯衝、J 爪擊、破翼後按住 F 封印、R 重開。這是 Boss 戰鬥原型，尚無完整英雄移動與塔防流程。

驗證結果見 `verification/window-scaling/README.md`。舊版 QA 報告保留作為歷史紀錄。

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests_v16.gd
godot --headless --path . --script res://tests/run_visual_alignment.gd
# 以下需圖形顯示環境：
godot --path . --script res://tests/run_window_sizes.gd
```
