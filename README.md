# 神獸紀元：窮奇與守封將軍 v17

使用 **Godot 4.6.3** 匯入 `project.godot`，按 **F5**。主場景為 `HeroBattle.tscn`，畫面左上角應顯示 **BEASTFALL v17**。

更新時關閉舊專案，將 ZIP 解壓到**新資料夾**，從專案管理員重新匯入新的 `project.godot`。請勿只覆蓋舊資料夾後繼續用原來的捷徑。F6 只執行目前場景；如果開著舊的 `Battle.tscn`，會執行 v16.2 而非新玩法。

## 本次可以玩什麼

本版將可操控英雄接入既有窮奇 Boss 戰。弓塔自動削弱翅膀；破翼後，英雄靠近窮奇會自動近戰。守住城牆，將窮奇打到 **15% 血量（180 HP）**，再完成三符陣封印。

| 操作 | 功能 |
|---|---|
| WASD | 英雄移動；斜向不會更快 |
| 滑鼠右鍵點地面 | 移動到目標；WASD 可取消目標 |
| Q | 橫掃：對附近已落地窮奇造成 90 傷害，冷卻 5 秒 |
| E | 站在城牆附近修補 55 血量，冷卻 6 秒 |
| R | 重新開始 |

- 英雄有 180 HP，近身作戰會受傷；倒下後 **10 秒**在城邊復活，復活後短暫無敵。
- 窮奇降至 180 HP 時進入封印階段，暫停攻擊，塔與技能也不會把牠直接擊殺。
- 依序走到發光的 **1 → 2 → 3** 符陣，每個符陣站穩 **1.25 秒**。走錯順序不會啟動；中途離開會清除當前符陣的充能，已完成的符陣保留。
- 三個符陣完成即獲勝。城牆歸零仍會失敗。
- 舊版的 A 射箭、D 俯衝、J 爪擊、F 封印與數字動畫快捷鍵，不適用於新主場景。

## 範圍與限制

英雄使用程式繪製的暫代圖形。本版先驗證英雄支援與封印流程；沿用既有 Boss 測試地圖，尚未加入中央城池、四方獸潮、玩家建塔、完整英雄技能樹、障礙物尋路與守護獸存檔。封印結果目前只存在本局，沒有套用跨關卡加成。原有窮奇切圖拼接痕跡與 Bone2D 末端警告仍存在。

保留 v16.2 的骨架對齊與視窗等比例縮放修正。舊場景 `Battle.tscn` 保留供回歸測試使用。

## 測試

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests_v17.gd
godot --headless --path . --script res://tests/run_tests_v16.gd
godot --headless --path . --script res://tests/run_visual_alignment.gd
# 以下需要圖形顯示環境：
godot --path . --script res://tests/run_window_sizes.gd -- --hero
godot --path . --fixed-fps 60 --script res://tests/run_playthrough_v17.gd
```

`run_playthrough_v17.gd` 保留真實物理與戰鬥運作，以移動輸入、右鍵及 E 操作完成封印，最後以 R 驗證重新開始。測試截圖與 JSON 存在 Godot 的 `user://`；本次驗證副本見 `verification/v17/`。舊 QA 文件為歷史紀錄。
