# 選項2：逐步替換 - 甘特圖

> **版本**: v1.0  
> **更新日期**: 2026-01-13  
> **適合轉換**: Google Sheets

---

## 完整開發甘特圖（可視化）

```mermaid
gantt
    title 選項2-逐步替換 7個月開發時程含招聘4週
    dateFormat YYYY-MM-DD
    
    section Phase0 招聘準備
    招聘PHP工程師最關鍵         :crit, recruit1, 2026-01-01, 4w
    招聘TechLead                :crit, recruit2, 2026-01-01, 4w
    招聘DevOpsLead              :recruit3, 2026-01-01, 4w
    PM並行需求整理              :active, pm1, 2026-01-01, 4w
    
    section Phase1 瓶頸分析
    慢查詢分析                  :crit, bottleneck1, after recruit1, 1w
    高CPU內存模組識別           :crit, bottleneck2, after recruit1, 1w
    模組依賴關係分析            :crit, bottleneck3, after bottleneck1, 1w
    瓶頸分析報告                :crit, bottleneck4, after bottleneck2, 3d
    
    section Phase2 優先級排序
    模組優先級排序              :crit, priority1, after bottleneck4, 1w
    並行架構設計                :priority2, after bottleneck4, 1w
    流量切換方案設計            :priority3, after bottleneck4, 1w
    
    section Phase3 PHP系統維護
    PHP系統持續維護             :active, php1, after priority1, 25w
    
    section Phase3 模組替換Batch1
    優先模組開發高CPU           :crit, batch1_dev, after priority1, 5w
    Batch1測試                  :batch1_test, after batch1_dev, 1w
    Batch1灰度上線              :crit, batch1_deploy, after batch1_test, 1w
    
    section Phase3 模組替換Batch2
    次優先模組開發慢查詢        :crit, batch2_dev, after batch1_deploy, 5w
    Batch2測試                  :batch2_test, after batch2_dev, 1w
    Batch2灰度上線              :crit, batch2_deploy, after batch2_test, 1w
    
    section Phase3 模組替換Batch3
    核心業務模組開發            :crit, batch3_dev, after batch2_deploy, 5w
    Batch3測試                  :batch3_test, after batch3_dev, 1w
    Batch3灰度上線              :crit, batch3_deploy, after batch3_test, 1w
    
    section Phase3 模組替換Batch4
    剩餘模組開發                :batch4_dev, after batch3_deploy, 3w
    Batch4測試                  :batch4_test, after batch4_dev, 1w
    Batch4灰度上線              :batch4_deploy, after batch4_test, 1w
    
    section 並行 遊戲服務開發
    遊戲服務架構設計            :game1, after priority1, 4w
    遊戲後端開發                :game2, after game1, 8w
    Unity遊戲前端               :game3, after game1, 8w
    
    section 並行 客戶端開發
    iOS逐步適配新API            :ios1, after priority1, 20w
    Android逐步適配新API        :android1, after priority1, 20w
    
    section 並行 基礎設施
    雙系統運維PHPGoGo          :active, infra1, after priority1, 25w
    CICD建置                    :infra2, after priority1, 4w
    雙系統監控告警              :infra3, after infra2, 4w
    
    section Phase4 測試上線
    PHP系統下線                 :milestone, deploy1, after batch4_deploy, 1d
    Go系統100%流量              :crit, deploy2, after deploy1, 1w
    全量回歸測試                :deploy3, after deploy1, 2w
    性能優化                    :deploy4, after deploy3, 1w
    監控觀察                    :deploy5, after deploy4, 1w
```

---

## 流量切換時程（逐步遷移）

```mermaid
gantt
    title 選項2流量切換進度PHP到Go
    dateFormat YYYY-MM-DD
    
    section 流量分配
    100%PHP 0%Go                :php100, 2026-01-29, 10w
    80%PHP 20%Go Batch1         :php80, after php100, 7w
    60%PHP 40%Go Batch2         :php60, after php80, 7w
    30%PHP 70%Go Batch3         :php30, after php60, 7w
    5%PHP 95%Go Batch4          :php5, after php30, 4w
    0%PHP 100%Go PHP下線        :milestone, php0, after php5, 1d
```

---

## 關鍵里程碑

```mermaid
gantt
    title 選項2關鍵里程碑
    dateFormat YYYY-MM-DD
    
    section 里程碑
    M0PHP工程師到位             :milestone, m0, 2026-01-29, 0d
    M1瓶頸分析完成              :milestone, m1, 2026-02-12, 0d
    M2優先級排序完成            :milestone, m2, 2026-02-19, 0d
    M3Batch1完成                :milestone, m3, 2026-04-09, 0d
    M4Batch2完成                :milestone, m4, 2026-05-28, 0d
    M5Batch3完成                :milestone, m5, 2026-07-16, 0d
    M6所有模組完成              :milestone, m6, 2026-08-13, 0d
    M7PHP下線                   :milestone, m7, 2026-08-20, 0d
    M8MVP上線                   :milestone, m8, 2026-09-03, 0d
```

---

## 人力資源投入時間表

```mermaid
gantt
    title 選項2人力資源投入峰值22到28人
    dateFormat YYYY-MM-DD
    
    section PHP維護團隊
    資深PHP工程師1人            :crit, php1, 2026-01-29, 28w
    PHP維護工程師1到2人         :php2, 2026-02-05, 27w
    
    section Go後端團隊
    TechLead1人                 :go1, 2026-01-29, 32w
    Go工程師6人                 :go2, 2026-02-19, 30w
    
    section 遊戲服務團隊
    遊戲TechLead1人             :game1, 2026-02-19, 30w
    遊戲後端2到3人              :game2, 2026-03-05, 29w
    Unity工程師2人              :game3, 2026-03-05, 29w
    
    section 客戶端團隊
    iOSTeamLead1人              :ios1, 2026-02-19, 30w
    iOS工程師0到1人             :ios2, 2026-03-05, 29w
    AndroidTeamLead1人          :android1, 2026-02-19, 30w
    Android工程師0到1人         :android2, 2026-03-05, 29w
    
    section 基礎設施團隊
    DevOpsLead1人               :devops1, 2026-01-29, 32w
    DevOps工程師2到3人          :devops2, 2026-02-19, 30w
    QALead1人                   :qa1, 2026-02-19, 30w
    QA工程師0到1人              :qa2, 2026-03-05, 29w
    
    section 設計與管理
    UIUX設計師1到2人            :design1, 2026-03-05, 29w
    專案經理1人                 :pm1, 2026-01-01, 36w
    產品經理0到1人              :pm2, 2026-02-19, 30w
```

---

## 雙系統並行示意圖

```mermaid
gantt
    title 選項2雙系統並行期PHP維護加Go開發
    dateFormat YYYY-MM-DD
    
    section PHP系統
    PHP持續維護舊系統           :active, old1, 2026-02-19, 26w
    
    section Go系統
    Go模組逐步開發新系統        :crit, new1, 2026-02-19, 26w
    
    section 雙系統運維
    流量切換與監控              :crit, both1, 2026-02-19, 26w
```

---

**版本**: v1.0  
**更新日期**: 2026-01-13  
**總時程**: 36 週（8 個月，含招聘 4 週）  
**關鍵路徑**: 招聘 PHP → 瓶頸分析 → 優先級排序 → 逐批替換 → PHP 下線  
**特點**: 雙系統並行，風險最低
