# 選項1：重構 - 甘特圖

> **版本**: v1.0  
> **更新日期**: 2026-01-13  
> **適合轉換**: Google Sheets

---

## 完整開發甘特圖（可視化）

```mermaid
gantt
    title 選項1-重構 6個月開發時程含招聘4週
    dateFormat YYYY-MM-DD
    
    section Phase0 招聘準備
    招聘PHP工程師關鍵           :crit, recruit1, 2026-01-01, 4w
    招聘TechLead                :crit, recruit2, 2026-01-01, 4w
    招聘DevOpsLead              :recruit3, 2026-01-01, 4w
    PM並行需求整理              :active, pm1, 2026-01-01, 4w
    
    section Phase1 需求分析
    PHP代碼深度分析             :crit, analysis1, after recruit1, 2w
    業務邏輯梳理                :analysis2, after analysis1, 1w
    瓶頸識別                    :analysis3, after analysis1, 1w
    
    section Phase2 架構設計
    微服務拆分設計              :crit, design1, after analysis2, 2w
    API規格定義                 :design2, after analysis2, 2w
    數據庫Schema設計            :design3, after analysis2, 2w
    
    section Phase3 後端開發
    UserAuthService             :crit, backend1, after design1, 5w
    LiveService                 :crit, backend2, after design1, 7w
    ChatService                 :backend3, after backend1, 6w
    PaymentService              :backend4, after backend1, 6w
    GameMiddleware              :backend5, after backend1, 5w
    GiftService                 :backend6, after backend1, 4w
    
    section 並行 遊戲服務開發
    遊戲服務架構設計            :game1, after design1, 2w
    遊戲後端開發                :game2, after game1, 8w
    Unity遊戲前端               :game3, after game1, 8w
    
    section 並行 客戶端開發
    iOS基礎架構                 :ios1, after design1, 6w
    iOS功能開發                 :ios2, after ios1, 8w
    Android基礎架構             :android1, after design1, 6w
    Android功能開發             :android2, after android1, 8w
    
    section 並行 基礎設施
    K8s環境搭建                 :infra1, after design1, 4w
    CICD建置                    :infra2, after infra1, 4w
    監控告警系統                :infra3, after infra2, 4w
    
    section Phase4 測試上線
    數據遷移準備                :crit, deploy1, after backend6, 2w
    集成測試                    :deploy2, after backend6, 2w
    壓力測試                    :deploy3, after deploy2, 1w
    灰度10%                     :crit, deploy4, after deploy3, 3d
    灰度50%                     :crit, deploy5, after deploy4, 3d
    灰度100%正式上線            :milestone, deploy6, after deploy5, 1d
```

---

## 關鍵里程碑

```mermaid
gantt
    title 選項1關鍵里程碑
    dateFormat YYYY-MM-DD
    
    section 里程碑
    M0關鍵人員到位              :milestone, m0, 2026-01-29, 0d
    M1PHP分析完成               :milestone, m1, 2026-02-12, 0d
    M2架構設計完成              :milestone, m2, 2026-02-26, 0d
    M3核心服務完成              :milestone, m3, 2026-04-16, 0d
    M4所有服務完成              :milestone, m4, 2026-05-28, 0d
    M5集成測試完成              :milestone, m5, 2026-06-11, 0d
    M6MVP正式上線               :milestone, m6, 2026-06-25, 0d
```

---

## 人力資源投入時間表

```mermaid
gantt
    title 選項1人力資源投入峰值20到26人
    dateFormat YYYY-MM-DD
    
    section PHP分析團隊
    資深PHP工程師1到2人         :php1, 2026-01-29, 8w
    
    section Go後端團隊
    TechLead1人                 :go1, 2026-01-29, 26w
    Go工程師6人                 :go2, 2026-02-12, 24w
    
    section 遊戲服務團隊
    遊戲TechLead1人             :game1, 2026-02-12, 24w
    遊戲後端2到3人              :game2, 2026-02-19, 23w
    Unity工程師2人              :game3, 2026-02-19, 23w
    
    section 客戶端團隊
    iOSTeamLead1人              :ios1, 2026-02-12, 24w
    iOS工程師0到1人             :ios2, 2026-02-19, 23w
    AndroidTeamLead1人          :android1, 2026-02-12, 24w
    Android工程師0到1人         :android2, 2026-02-19, 23w
    
    section 基礎設施團隊
    DevOpsLead1人               :devops1, 2026-01-29, 26w
    DevOps工程師1到2人          :devops2, 2026-02-12, 24w
    QALead1人                   :qa1, 2026-02-19, 23w
    QA工程師0到1人              :qa2, 2026-03-05, 20w
    
    section 設計與管理
    UIUX設計師1到2人            :design1, 2026-02-19, 23w
    專案經理1人                 :pm1, 2026-01-01, 30w
    產品經理0到1人              :pm2, 2026-02-12, 24w
```

---

## 並行開發示意圖

```mermaid
gantt
    title 選項1並行開發後端遊戲客戶端同步進行
    dateFormat YYYY-MM-DD
    
    section 後端微服務
    6個微服務並行開發           :crit, parallel1, 2026-02-26, 18w
    
    section 遊戲服務
    遊戲服務開發獨立            :active, parallel2, 2026-02-26, 18w
    
    section iOS
    iOSApp開發                  :parallel3, 2026-02-26, 18w
    
    section Android
    AndroidApp開發              :parallel4, 2026-02-26, 18w
    
    section DevOps
    CICD加監控                  :parallel5, 2026-02-26, 18w
```

---

**版本**: v1.0  
**更新日期**: 2026-01-13  
**總時程**: 30 週（7.5 個月，含招聘 4 週）  
**關鍵路徑**: 招聘 → PHP 分析 → 架構設計 → 微服務開發 → 測試上線
