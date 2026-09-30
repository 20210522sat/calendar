[README.md](https://github.com/user-attachments/files/32837175/README.md)
# 共用行事曆（GitHub Pages + Supabase）

這個資料夾有三個檔案：

| 檔案 | 用途 |
|---|---|
| `index.html` | 行事曆網頁本體，要上傳到 GitHub |
| `supabase-setup.sql` | 在 Supabase 建立資料表、權限和即時同步 |
| `README.md` | 這份說明 |

---

## 第一步：建立 Supabase 資料庫

1. 到 <https://supabase.com> 登入，按 **New project** 建立專案（地區選 **Northeast Asia (Tokyo)** 或 **Southeast Asia (Singapore)** 比較快），設定一組資料庫密碼後等它建立完成。
2. 左側選 **SQL Editor** → **New query**，把 `supabase-setup.sql` 的內容全部貼上，按 **Run**。看到 `Success` 就完成了。
3. 左側選 **Project Settings**（齒輪）→ **API**（新版介面叫 **API Keys** / **Data API**），複製兩個值：
   - **Project URL**：像 `https://abcdefgh.supabase.co`
   - **anon public key**：一長串 `eyJ...` 開頭的字；新版介面也可能叫 **publishable key**，以 `sb_publishable_` 開頭。兩種都可以用。

> ⚠️ 不要複製 **service_role** 或 **secret** key，那把金鑰有完整權限，不能放在網頁裡。

## 第二步：把金鑰填進 index.html

用任何文字編輯器打開 `index.html`，找到最上方這段，換成你剛才複製的值：

```js
window.CALENDAR_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi..."
};
```

存檔。可以先直接用瀏覽器打開這個檔案測試，左上角出現「已連線」就代表設定正確。

## 第三步：放到 GitHub Pages

1. 到 <https://github.com> 按右上角 **＋** → **New repository**，取個名字（例如 `calendar`），選 **Public**，按 **Create repository**。
2. 在新的 repository 頁面按 **uploading an existing file**，把 `index.html` 拖進去，按 **Commit changes**。
3. 到 repository 的 **Settings** → 左側 **Pages**：
   - Source 選 **Deploy from a branch**
   - Branch 選 **main**、資料夾選 **/ (root)**，按 **Save**
4. 等一到兩分鐘，重新整理 Pages 頁面，上方會出現網址：
   `https://你的帳號.github.io/calendar/`

把這個網址傳給同事，大家打開就是同一份行事曆，任何人新增、打勾或刪除，其他人的畫面會在一兩秒內自動更新。

之後要修改網頁，只要在 GitHub 上重新上傳 `index.html` 就會自動更新。

---

## 安全性說明（請一定要看）

目前的設定是 **「拿到網址的人都可以查看和修改」**，不需要登入。這對辦公室內部的共用白板很方便，但要注意：

- 網址流出去，外人也能看到和修改內容，所以不要放個資、密碼或機密資訊。
- 網頁裡的 anon key 本來就是設計給前端公開使用的，真正控制權限的是資料庫的 RLS 規則。
- 誤刪的東西 14 天內都能在「垃圾桶」還原；但如果有人故意用「永久刪除」，就救不回來。可以到 Supabase 的 **Database → Backups** 確認備份設定。

如果之後需要「只有同事能看」，可以改成用 Supabase Auth 登入（例如 email 登入），再把 RLS 規則限制為已登入的使用者。

## 常見問題

**左上角顯示「尚未設定 Supabase」**
`index.html` 裡的 `SUPABASE_URL` 或 `SUPABASE_ANON_KEY` 還沒改，或是引號不見了。

**顯示「讀取資料失敗」**
通常是 SQL 還沒執行，或執行到一半出錯。回到 SQL Editor 再執行一次 `supabase-setup.sql`（重複執行不會出問題）。

**別人改了，我的畫面沒有更新**
確認 SQL 最後「即時同步」那段有成功執行；也可以到 Supabase 的 **Database → Publications** → `supabase_realtime`，確認 `todos` 和 `memos` 都有打開。切換回分頁時網頁也會自動重新讀取一次。

**免費方案夠用嗎？**
這種規模的行事曆用 Supabase 免費方案就綽綽有餘。要注意免費專案如果連續 7 天完全沒有人使用會被暫停，到後台按一下就能恢復，資料不會不見。
