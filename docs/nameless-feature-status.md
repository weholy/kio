# nameless — статус функций (2026-07-24)

## Liquid Glass (iOS 26 UIGlassEffect)

| Зона | Статус | Как работает |
|------|--------|--------------|
| Сообщения (входящие/исходящие) | **Исправлено** | Скрыт solid wallpaper-fill; `GlassBackgroundView` + `UIGlassEffect(.clear)` |
| Настройки (ItemList blocks) | **Исправлено** | Solid bg → `.clear`, real `UIGlassEffect`, soft separators, radius 26 |
| Context menu (long-press) | **Исправлено** | Убран white blob: clear container + glass `.clear` + tint |
| Серые линии/полоски | **Исправлено** | Soft separators 8% alpha; top stripe hidden |
| Nav / Tab / Input | Есть инфраструктура | `SGLiquidGlassZone` + factory |

## Ghost mode (TGExtra-style)

| Функция | Статус | Где логика |
|---------|--------|------------|
| Master ghost | OK | `applyGhostModeAll` + notification |
| Hide online | OK | `ManagedAccountPresence` |
| Hide typing + statuses | OK | `ManagedLocalInputActivities.shouldSuppressActivity` |
| Hide read receipts | OK | `SynchronizePeerReadState` |
| Hide story views | OK | `ManagedSynchronizeViewStoriesOperations` |
| Send delay 12s | **Проводка** | `ChatControllerLoadDisplayNode.sendMessages` → scheduleTime |

## Appearance / messages

| Функция | Статус |
|---------|--------|
| Music card (cover+title+artist) | **Новый UI** `PeerInfoHeaderNode` |
| Square avatars | **OK** ChatListItem |
| Message transparent / semi | **OK** ChatMessageBubbleBackdrop |
| Message outline | **OK** border on bubble |
| Double-tap edit | OK (SGDoubleTapMessageAction) |
| Local premium | **OK** SGLocalPremium ← enableLocalPremium |
| Unlimited pins | **OK** via SGLocalPremium / unlimitedPinnedChats |
| Disable ads | **OK** ChatHistoryListNode |
| Save protected content | **OK** Message.isCopyProtected |
| Bypass protected | **OK** same path |
| Ghost delay | **OK** send path |

## v6 — 80% wiring pass (2026-07-24)

### Сделано в этом проходе

| Функция | Как |
|---------|-----|
| **Deleted keep + 🗑** | `DeleteMessages` / Interactively mark `isDeleted`, keep local, date badge `🗑` |
| **Ghost master + all activities** | `shouldSuppressActivity` + `ghostModeEnabled` |
| **Always online / read / stories** | уже было; master ghost усиливает |
| **Char counter input** | `ChatTextInputPanelNode` always count when `charCounterInput` |
| **OLED black** | ItemList backgrounds pure black when `oledMode` |
| **Camera HD quality** | `NamelessFeatureRuntime.effectiveOutgoingPhotoQuality` → JPEG paths |
| **Warn before call** | `confirmCalls` \|\| `warnBeforeCall` |
| **Anti-scam links** | `OpenUrl` suspicious heuristic alert |
| **Transparent/outline bubbles** | уже в ChatMessageBubbleBackdrop |

### Отложено (по ответу user: AI/plugins/morph)

- Voice morph full pipeline
- Plugins / Gemini AI
- VirusTotal real API
- Particle overlay full
- foldersAtBottom / newChatList layout
- Fake typing pulse (флаг есть; proactive timer — next)
- truncateLongMessages / showOriginalEdited UI detail
- auto-clean history / anti-spam inbound filter

## Сборка

macOS 26 + Xcode 26.2 + Bazel 8.4.2  
или GitHub Actions (как у тебя).
