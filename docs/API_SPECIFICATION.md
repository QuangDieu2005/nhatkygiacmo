# API Specification â€” há»£p Ä‘á»“ng má»¥c tiÃªu

**Base URL:** `{API_BASE_URL}` trá» tá»›i origin backend, vÃ­ dá»¥ `http://<host>:3000/api`. CÃ¡c response thÃ nh cÃ´ng dÃ¹ng JSON trá»« khi ghi 204. ÄÃ¢y lÃ  Ä‘áº·c táº£ Ä‘á» xuáº¥t theo `DATA_CONTRACT.md`; backend hiá»‡n chÆ°a triá»ƒn khai toÃ n bá»™ há»£p Ä‘á»“ng. KhÃ´ng Ä‘á»“ng nghÄ©a endpoint Ä‘Ã£ Ä‘Æ°á»£c kiá»ƒm thá»­.

## Quy Æ°á»›c báº£o vá»‡

- Auth routes nháº­n HTTPS trong mÃ´i trÆ°á»ng deploy. Dream/sleep cáº§n `Authorization: Bearer <access_token>`.
- Express xÃ¡c minh token vá»›i Supabase Auth (`auth.getUser(token)` nhÆ° middleware hiá»‡n táº¡i). Má»i truy váº¥n dÃ¹ng `req.user.id`; bá» qua/reject `user_id` do body cung cáº¥p. UUID record khÃ´ng Ä‘Æ°á»£c dÃ¹ng thay kiá»ƒm tra owner.
- Response lá»—i chuáº©n: `{ "message": "...", "code": "..." }`. MÃ£ chung: 400 validation, 401 token thiáº¿u/háº¿t háº¡n/khÃ´ng há»£p lá»‡, 403 cáº¥m, 404 khÃ´ng tá»“n táº¡i hoáº·c khÃ´ng thuá»™c user, 409 conflict náº¿u cÃ³, 429 rate limit, 500 lá»—i ná»™i bá»™, 502/503 phá»¥ thuá»™c dá»‹ch vá»¥ upstream.

## Auth

| Method + URL | Body | ThÃ nh cÃ´ng | Auth | Lá»—i dá»± kiáº¿n |
|---|---|---|---|---|
| POST `/auth/register` | `{ "email": string, "password": string, "name": string }` | `201` náº¿u session cÃ³: `{ "user": UserDTO, "session": SessionDTO, "confirmation_required": false }`; `202` náº¿u cáº§n email confirm: `{ "user": UserDTO|null, "session": null, "confirmation_required": true }` | KhÃ´ng | 400 validation, 409 email Ä‘Ã£ dÃ¹ng (hoáº·c 400 tá»« upstream theo chuáº©n hÃ³a), 429, 502/503 |
| POST `/auth/login` | `{ "email": string, "password": string }` | `200 { "user": UserDTO, "session": SessionDTO, "confirmation_required": false }` | KhÃ´ng | 400, 401 thÃ´ng tin sai/chÆ°a xÃ¡c nháº­n (phÃ¢n biá»‡t theo chÃ­nh sÃ¡ch khÃ´ng tiáº¿t lá»™ email tá»“n táº¡i), 429, 502/503 |
| POST `/auth/refresh` | `{ "refresh_token": string }` | `200 { "user": UserDTO, "session": SessionDTO }` (token má»›i; thay toÃ n bá»™ session cÅ©) | KhÃ´ng; refresh token trong body | 400, 401/400 refresh bá»‹ thu há»“i/háº¿t háº¡n, 429, 502/503 |
| POST `/auth/logout` | khÃ´ng cÃ³ | `204` | CÃ³; Bearer access token | 401, 429, 502/503 |
| POST `/auth/forgot-password` **Ä‘á» xuáº¥t má»›i** | `{ "email": string }` | `202 { "message": "Náº¿u Ä‘á»‹a chá»‰ há»£p lá»‡, hÆ°á»›ng dáº«n sáº½ Ä‘Æ°á»£c gá»­i." }` | KhÃ´ng | 400, 429, 502/503; response khÃ´ng tiáº¿t lá»™ email cÃ³ tÃ i khoáº£n |
| POST `/auth/reset-password` **Ä‘á» xuáº¥t má»›i** | `{ "access_token": string, "new_password": string }` hoáº·c code má»™t láº§n Ä‘Ã£ Ä‘á»•i thÃ nh session/token theo flow Supabase Ä‘Æ°á»£c chá»n | `200 { "message": "Máº­t kháº©u Ä‘Ã£ Ä‘Æ°á»£c cáº­p nháº­t." }` | XÃ¡c thá»±c báº±ng recovery credential; flow pháº£i chá»‘t | 400, 401, 429, 502/503 |

`UserDTO` tá»‘i thiá»ƒu: `{ "id": UUID, "email": string, "name": string|null, "avatar_url": string|null, "created_at": timestamp }`. `SessionDTO`: `{ "access_token": string, "refresh_token": string, "token_type": "bearer", "expires_in": number, "expires_at": number|null }`.

**Session null khi Ä‘Äƒng kÃ½:** `202` khÃ´ng pháº£i Ä‘Äƒng nháº­p thÃ nh cÃ´ng. Flutter giá»¯ tráº¡ng thÃ¡i unauthenticated/pending confirmation, hiá»ƒn thá»‹ thÃ´ng bÃ¡o hÆ°á»›ng dáº«n xÃ¡c nháº­n, khÃ´ng lÆ°u token, khÃ´ng vÃ o main shell; ngÆ°á»i dÃ¹ng Ä‘Äƒng nháº­p sau khi xÃ¡c nháº­n. `user` null váº«n pháº£i Ä‘Æ°á»£c xá»­ lÃ½ an toÃ n. Náº¿u `session != null`, coi lÃ  authenticated vÃ  lÆ°u session Ä‘áº§y Ä‘á»§ an toÃ n.

**KhÃ´i phá»¥c session:** Flutter Ä‘á»c session Ä‘Ã£ lÆ°u trong secure storage; náº¿u access token gáº§n/háº¿t háº¡n, gá»i `/auth/refresh` má»™t láº§n cÃ³ khÃ³a Ä‘á»“ng thá»i, thay access + refresh token nguyÃªn tá»­. Náº¿u refresh lá»—i 401, xÃ³a session vÃ  quay vá» unauthenticated. Má»i request nghiá»‡p vá»¥ dÃ¹ng access token má»›i nháº¥t; náº¿u nháº­n 401 do háº¿t háº¡n, refresh má»™t láº§n rá»“i retry tá»‘i Ä‘a má»™t láº§n. KhÃ´ng retry lá»—i 403/validation. LÆ°u token trong SharedPreferences hiá»‡n táº¡i khÃ´ng Ä‘á»§ báº£o vá»‡; chá»n secure storage theo ná»n táº£ng. Web cáº§n lá»±a chá»n riÃªng (BFF/HttpOnly cookie hoáº·c storage threat model Ä‘Æ°á»£c phÃª duyá»‡t), khÃ´ng giáº£ Ä‘á»‹nh plugin native Ã¡p dá»¥ng nhÆ° nhau.

## Dreams CRUD

| Method + URL | Request | Response | Auth | Lá»—i dá»± kiáº¿n |
|---|---|---|---|---|
| GET `/dreams` | query tÃ¹y chá»n: `q` (tÃ¬m title/content), `emotion`, `tag` (khá»›p chÃ­nh xÃ¡c má»™t tag), `from`/`to` (`YYYY-MM-DD`) | `200 [DreamDTO, ...]` â€” JSON array trá»±c tiáº¿p; rá»—ng lÃ  `[]` | CÃ³ | 400 query sai, 401, 429, 500/503 |
| POST `/dreams` | `{ "title": string, "content": string, "emotion": EmotionType.name, "tags": string[], "clarity_score": 1..5, "is_lucid": boolean, "dream_date": "YYYY-MM-DD" }` | `201 DreamDTO` | CÃ³ | 400 validation, 401, 429, 500/503 |
| PATCH `/dreams/:id` | UUID path; toÃ n bá»™ writable fields theo Ä‘á» xuáº¥t (partial semantics cáº§n xÃ¡c nháº­n) | `200 DreamDTO` | CÃ³ | 400 UUID/validation, 401, 404, 429, 500/503 |
| DELETE `/dreams/:id` | UUID path | `204` | CÃ³ | 400 UUID, 401, 404, 429, 500/503 |

`DreamDTO`: Ä‘áº§y Ä‘á»§ `id`, `user_id`, `title`, `content`, `emotion`, `tags`, `clarity_score`, `is_lucid`, `dream_date`, `created_at` theo DATA_CONTRACT. KhÃ´ng cháº¥p nháº­n client ghi `user_id`.

## Sleep records CRUD

| Method + URL | Request | Response | Auth | Lá»—i dá»± kiáº¿n |
|---|---|---|---|---|
| GET `/sleep-records` | query tÃ¹y chá»n `days` (1..3650), `from`, `to` | `200 [SleepRecordDTO, ...]` â€” JSON array trá»±c tiáº¿p; rá»—ng lÃ  `[]` | CÃ³ | 400, 401, 429, 500/503 |
| POST `/sleep-records` | `{ "start_time": ISO-8601 cÃ³ Z/offset, "end_time": ISO-8601 cÃ³ Z/offset, "quality_score": 0..100|null, "deep_sleep_minutes": integer, "light_sleep_minutes": integer, "rem_sleep_minutes": integer, "notes": string|null }` | `201 SleepRecordDTO` | CÃ³ | 400 timestamp sai/thiáº¿u timezone, end khÃ´ng sau start, khoáº£ng >24h, client gá»­i duration hoáº·c constraint khÃ¡c; 401, 429, 500/503 |
| PATCH `/sleep-records/:id` | UUID path; trÆ°á»ng writable Ä‘áº§y Ä‘á»§ (hoáº·c partial sau khi chá»‘t) | `200 SleepRecordDTO` | CÃ³ | 400, 401, 404, 429, 500/503 |
| DELETE `/sleep-records/:id` | UUID path | `204` | CÃ³ | 400 UUID, 401, 404, 429, 500/503 |

`SleepRecordDTO`: `id`, `user_id`, `start_time`, `end_time`, `duration_minutes`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `notes`, `created_at`. Báº£n ghi API lÃ  session Ä‘Ã£ káº¿t thÃºc; `isTracking` khÃ´ng xuáº¥t hiá»‡n.

**Quy táº¯c thá»i gian:** client gá»­i ISO-8601 cÃ³ `Z` hoáº·c UTC offset rÃµ rÃ ng. Express tá»« chá»‘i timestamp invalid/khÃ´ng cÃ³ offset, chuáº©n hÃ³a UTC, yÃªu cáº§u `end_time > start_time`, vÃ  giá»›i háº¡n khoáº£ng ngá»§ tá»‘i Ä‘a 24 giá». Server tÃ­nh `duration_minutes = floor((end_time - start_time) / 60 giÃ¢y)`; khoáº£ng thá»i gian dÆ°Æ¡ng dÆ°á»›i má»™t phÃºt cÃ³ duration 0. Request khÃ´ng chá»©a `duration_minutes`; náº¿u client gá»­i trÆ°á»ng nÃ y, Express reject thay vÃ¬ tin giÃ¡ trá»‹. Response chá»©a duration do server tÃ­nh. PATCH cáº­p nháº­t timestamp pháº£i tÃ­nh láº¡i duration theo cÃ¹ng quy táº¯c. UI hiá»ƒn thá»‹ timestamp theo timezone thiáº¿t bá»‹.\n\nGET á»Ÿ báº£n Ä‘áº§u luÃ´n tráº£ JSON array trá»±c tiáº¿p cho cáº£ hai resource, khÃ´ng dÃ¹ng pagination envelope. CÃ³ thá»ƒ má»Ÿ rá»™ng pagination vá» sau theo contract/version tÆ°Æ¡ng thÃ­ch má»›i (vÃ­ dá»¥ cursor hoáº·c envelope) khi nhu cáº§u tÄƒng; pagination khÃ´ng thuá»™c báº£n Ä‘áº§u.\n\n## Health

| Method + URL | Request | Response | Auth | Lá»—i dá»± kiáº¿n |
|---|---|---|---|---|
| GET `/health` (public, base path `/api`) | none | `200 { "status": "ok", "service": "dream-diary-api", "database": "connected" }` | KhÃ´ng | `503 { "status": "degraded", "database": "unavailable" }` |

## Endpoint hiá»‡n cÃ³ khÃ¡c

`DELETE /api/account/data` hiá»‡n xÃ³a dream/sleep rows cho user sau auth, nhÆ°ng chÆ°a náº±m trong má»¥c tiÃªu CRUD thÃ´ng thÆ°á»ng. Giá»¯ láº¡i trong backend hiá»‡n táº¡i; náº¿u Ä‘Æ°a vÃ o client cáº§n xÃ¡c nháº­n UX, re-authentication, transaction/atomicity vÃ  semantics (khÃ´ng xÃ³a tÃ i khoáº£n Supabase). KhÃ´ng nháº§m vá»›i endpoint xÃ³a account.

## Endpoint vÃ  há»£p Ä‘á»“ng hiá»‡n tráº¡ng cáº§n sá»­a trong bÆ°á»›c triá»ƒn khai

Auth backend tráº£ `{user, session}`; `AuthService` hiá»‡n giáº£ Ä‘á»‹nh `{user, token}`. `ApiClient` chÆ°a gáº¯n JWT. Forgot-password route chÆ°a cÃ³. Dreams backend hiá»‡n dÃ¹ng `tags.ilike` trong free-text query, khÃ´ng tÆ°Æ¡ng thÃ­ch vá»›i PostgreSQL `text[]`; contract má»¥c tiÃªu dÃ¹ng query `tag` khá»›p chÃ­nh xÃ¡c báº±ng array containment, e.g. Supabase query builder `.contains('tags', [tag])` / PostgREST `cs` operator. Free-text `q` tÃ¬m title/content; náº¿u cáº§n substring trÃªn tá»«ng tag thÃ¬ bá»• sung PostgreSQL RPC/function cÃ³ kiá»ƒm soÃ¡t hoáº·c Ä‘á»•i contract, khÃ´ng dÃ¹ng `tags.ilike`. Sleep backend dÃ¹ng `sleep_time/wake_time/quality/note`; id route parse bigint. CÃ¡c Ä‘iá»ƒm nÃ y chÆ°a Ä‘Ã¡p á»©ng spec. Chi tiáº¿t thay Ä‘á»•i DB chá»‰ trong `DATABASE_MIGRATION_PROPOSAL.md`.

## CORS vÃ  URL mÃ´i trÆ°á»ng

- Android Emulator truy cáº­p mÃ¡y host thÆ°á»ng dÃ¹ng `http://10.0.2.2:3000/api`; thiáº¿t bá»‹ tháº­t dÃ¹ng `http://<LAN-IP-host>:3000/api` vÃ  cÃ¹ng máº¡ng/firewall; web/desktop cÃ¹ng host cÃ³ thá»ƒ dÃ¹ng `http://localhost:3000/api`.
- Production dÃ¹ng HTTPS URL triá»ƒn khai. KhÃ´ng nhÃºng private service key trong app.
- `CORS_ORIGIN` pháº£i lÃ  danh sÃ¡ch origin chÃ­nh xÃ¡c, theo mÃ´i trÆ°á»ng; `*` hiá»‡n backend cháº¥p nháº­n má»i origin. CORS khÃ´ng thay tháº¿ auth.
- KhÃ´ng Ä‘á»c file `.env` tháº­t. Root `.gitignore` vÃ  `server/.gitignore` ignore env files vÃ  allowlist `.env.example`; server example keys hiá»‡n cÃ³ tÃªn biáº¿n phÃ¹ há»£p nhÆ°ng config máº«u tá»«ng chá»©a project value cá»¥ thá»ƒ (Ä‘Ã£ Ä‘Æ°á»£c ghi nháº­n á»Ÿ context), pháº£i thay báº±ng placeholder trÆ°á»›c khi commit/chia sáº».
