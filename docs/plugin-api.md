# Megram Plugin API

> **Версия:** 1.0
> **Рантайм:** JavaScriptCore (системный, входит в iOS)
> **Расширения:** `.plugin`, `.mgplugin`, `.js`, `.mjs`

---

## Содержание

1. [Что такое плагин](#1-что-такое-плагин)
2. [Заголовок и метаданные](#2-заголовок-и-метаданные)
3. [Установка и валидация](#3-установка-и-валидация)
4. [Жизненный цикл](#4-жизненный-цикл)
5. [Справочник API](#5-справочник-api)
6. [Хуки](#6-хуки)
7. [Строки настроек](#7-строки-настроек)
8. [Уведомления](#8-уведомления)
9. [Примеры](#9-примеры)
10. [Ограничения](#10-ограничения)

---

## 1. Что такое плагин

Плагин — обычный текстовый файл с JavaScript. Расширение ни на что не влияет, кроме того, как
файл выглядит в Файлах: **все поддерживаемые расширения исполняются одним и тем же рантаймом**.

| Расширение | Рантайм |
|---|---|
| `.plugin` | JavaScript |
| `.mgplugin` | JavaScript |
| `.js` | JavaScript |
| `.mjs` | JavaScript |
| `.py` | **не исполняется** — импортёр объяснит, что Python-рантайма нет |

Почему JavaScript: `JavaScriptCore` встроен в iOS, легален в App Store, ничего не весит и не
требует ни отдельной сборки, ни увеличения размера приложения. CPython пришлось бы вшивать
(~30 МБ) — и именно поэтому `.py` принимается импортёром только для того, чтобы выдать понятное
сообщение вместо молчаливого отказа.

Каждый плагин работает **в собственной виртуальной машине**: упавший, зациклившийся или текущий
памятью плагин не достаёт до объектов соседа. Весь код плагина выполняется в главном потоке —
сетевые ответы и таймеры возвращаются в него же.

```javascript
// @name        Мой плагин
// @version     1.0
// @description Делает что-то полезное

mg.on("onAppStart", function () {
    mg.toast("Привет!");
});
```

---

## 2. Заголовок и метаданные

Метаданные — это ведущие строки-комментарии в начале файла. Принимаются оба маркера: `//` и `#`.
Заголовок заканчивается на первой строке настоящего кода.

| Ключ | Обязательно | Описание |
|---|---|---|
| `@name` | ✅ | Отображаемое название |
| `@version` | рекомендуется | Например `1.0.3` |
| `@author` | нет | Имя автора |
| `@description` | нет | Одна строка, показывается под названием в списке |
| `@icon` | нет | `data:image/png;base64,…` или голый base64 |

Длинное описание — в блоке `@readme_start` … `@readme_end`, поддерживает HTML:

```javascript
// @readme_start
// <h2>Мой плагин</h2>
// <p>Подробное описание.</p>
// @readme_end
```

**Идентификатор плагина** выводится из имени файла, а не из `@name`: `Мой Plugin v2.js` →
`plugin_v2`. Так переименование в заголовке не сиротит сохранённые настройки.

---

## 3. Установка и валидация

Два пути:

1. **Настройки → nameless → Плагины → «+»** — открывается системный проводник (Файлы, iCloud,
   «На iPhone»).
2. **Тап по файлу в чате** — `.plugin`, `.mgplugin`, `.js`, `.mjs`.

Перед записью на диск файл проверяется:

| Проверка | ✅ | ⚠️ | ❌ |
|---|---|---|---|
| Метаданные | есть `@name` | — | `@name` отсутствует |
| Megram API | код обращается к `mg.` / `wg.` | не обращается — возможно, это не плагин | — |
| Синтаксис | скобки и кавычки сбалансированы | — | текст ошибки |
| Рантайм | `.js`-совместимое расширение | — | `.py` |

Переустановка того же плагина заменяет его на месте (по идентификатору), не оставляя старую копию.

---

## 4. Жизненный цикл

Плагин исполняется целиком один раз при загрузке — на старте приложения, после установки и после
включения тумблера. Всё, что нужно сделать при запуске, делается прямо в теле файла или в хуке
`onAppStart`.

```javascript
(function () {
    "use strict";

    mg.on("onAppStart", function () { /* приложение запустилось */ });
    mg.on("onAppBackground", function () { /* сохранить состояние */ });
})();
```

Выключение или удаление плагина уничтожает его контекст: таймеры отменяются, подписки на хуки
пропадают. Отдельный `on_unload` не нужен — но состояние, которое надо пережить перезапуск,
сохраняйте в `mg.setStorage` по ходу дела, а не «на выходе».

---

## 5. Справочник API

Всё доступно через глобальный объект `mg`. Глобальный `wg` — тот же самый объект, чтобы плагины,
написанные для Whitegram, работали без правок.

### Интерфейс

```javascript
mg.log(text)                      // в лог клиента
mg.toast(text)                    // всплывающая плашка
mg.alert(message)                 // диалог с OK
mg.alert(title, message, cb)      // с заголовком и колбэком
mg.haptic(style)                  // "light" | "medium" | "heavy" | "success" | "warning" | "error"
mg.vibrate(style)                 // синоним mg.haptic
mg.copy(text)
mg.getClipboard()                 // → String
mg.isDarkMode()                   // → Boolean
mg.screenSize()                   // → {width, height}
mg.openURL(url)
```

### Хранилище

Изолировано по плагину: два плагина с одинаковым ключом не видят данные друг друга. Значения —
строки, для объектов используйте `JSON.stringify`.

```javascript
mg.setStorage(key, value)
mg.getStorage(key)                // → String | null
mg.removeStorage(key)
mg.clearStorage()
mg.dataDirectory()                // → путь к своей папке для файлов
```

### Сеть

```javascript
mg.fetch(url, callback)                     // GET;  callback(error, text)
mg.post(url, body, callback)                // POST; тело отправляется как application/json
mg.request(url, method, body, callback)     // произвольный метод
```

`error` — `null` при успехе, иначе строка. Колбэк всегда вызывается в главном потоке.

### Telegram

```javascript
mg.getCurrentChat()               // → peerId открытого чата или ""
mg.getAccountId()                 // → peerId активного аккаунта
mg.openChat(peerId)
```

### Экраны

```javascript
mg.pushWebView(title, html)       // HTML плагина
mg.pushWebViewURL(title, url)
```

### Хуки

```javascript
mg.on(hookName, callback)
mg.off(hookName)                  // снимает все колбэки хука
mg.emit(hookName, payload)        // вызвать собственный хук
```

### Таймеры и консоль

```javascript
setTimeout(fn, ms)   setInterval(fn, ms)
clearTimeout(id)     clearInterval(id)
console.log(...)     // уходит в тот же лог, что и mg.log
```

---

## 6. Хуки

| Хук | Аргумент | Когда |
|---|---|---|
| `onAppStart` | — | Плагин загружен и приложение запущено |
| `onAppForeground` | — | Приложение вышло на передний план |
| `onAppBackground` | — | Приложение ушло в фон |
| `onMessageReceive` | `message` | Пришло сообщение |
| `onMessageSend` | `message` | Отправлено сообщение |
| `onChatOpen` | `peerId` | Открыт чат |
| `onChatClose` | `peerId` | Закрыт чат |
| `onNotificationTap` | `{id}` | Тап по уведомлению **этого** плагина |
| `onThemeChange` | `themeName` | Сменилась тема |

Объект `message`:

```javascript
{
    peerId, messageId, text,
    isOutgoing, senderId, senderName, chatName,
    date, mediaType, isMuted, accountId
}
```

---

## 7. Строки настроек

Плагин может добавить свои строки на страницу настроек. Тап по строке вызывает указанный хук —
это же имя вы передаёте в `mg.on`.

```javascript
mg.addSettingsRow({
    id: "my_toggle",
    title: enabled ? "🟢 Включено" : "🔴 Выключено",
    subtitle: "Тап — переключить",
    hookName: "onMyToggle"
});

mg.on("onMyToggle", function () {
    enabled = !enabled;
    mg.setStorage("enabled", enabled ? "1" : "");
    mg.addSettingsRow({ /* тот же id — строка обновится на месте */ });
});

mg.removeSettingsRow("my_toggle");
```

Повторный `addSettingsRow` с тем же `id` обновляет строку, не переставляя её.

---

## 8. Уведомления

```javascript
mg.notifications.requestPermission(function (granted) { /* Boolean */ });

mg.notifications.schedule({
    id: "unique_id",
    title: "Заголовок",
    subtitle: "Подзаголовок",
    body: "Текст",
    delay: 1,          // секунды; iOS не принимает меньше 1 (и меньше 60 для повторяющихся)
    repeating: false,
    sound: true,
    badge: 0
});

mg.notifications.cancel(id);
mg.notifications.cancelAll();          // только свои уведомления
mg.notifications.list(callback);       // callback([{id, title, body}])
mg.notifications.status(callback);     // "authorized" | "denied" | "notDetermined" | …
mg.notify(title, body, delay);         // короткая форма schedule
```

Плагин видит и отменяет только собственные уведомления.

---

## 9. Примеры

### Минимальный

```javascript
// @name        Привет
// @version     1.0
// @description Здоровается при запуске

mg.on("onAppStart", function () {
    mg.toast("Привет от плагина!");
});
```

### Настройка с переключателем

```javascript
// @name        Тихий режим
// @version     1.0
// @description Тумблер в настройках, состояние переживает перезапуск

(function () {
    "use strict";

    var enabled = mg.getStorage("enabled") === "1";

    function render() {
        mg.addSettingsRow({
            id: "quiet_toggle",
            title: enabled ? "🔕 Тихий режим включён" : "🔔 Тихий режим выключен",
            subtitle: "Тап — переключить",
            hookName: "onQuietToggle"
        });
    }

    mg.on("onQuietToggle", function () {
        enabled = !enabled;
        mg.setStorage("enabled", enabled ? "1" : "");
        render();
        mg.toast(enabled ? "Включено" : "Выключено");
    });

    render();
})();
```

### Сеть

```javascript
// @name        Курс валют
// @version     1.0
// @description Показывает курс USD по тапу в настройках

(function () {
    "use strict";

    mg.addSettingsRow({
        id: "rates",
        title: "💱 Курс USD",
        subtitle: "Тап — обновить",
        hookName: "onRates"
    });

    mg.on("onRates", function () {
        mg.fetch("https://api.exchangerate-api.com/v4/latest/USD", function (error, data) {
            if (error) {
                mg.toast("Ошибка: " + error);
                return;
            }
            try {
                var rates = JSON.parse(data).rates;
                mg.alert("Курс USD", "1 USD = " + rates.RUB + " RUB");
            } catch (e) {
                mg.toast("Не удалось разобрать ответ");
            }
        });
    });
})();
```

Полноценный пример со состоянием, фильтрами и дедупликацией — встроенный плагин уведомлений,
`Swiftgram/MGPluginKit/Sources/MGBuiltinPlugins.swift`.

---

## 10. Ограничения

- **Один поток.** Весь код плагина исполняется в главном потоке. Долгий цикл подвесит интерфейс —
  тяжёлое разбивайте на `setTimeout`.
- **Нет DOM, нет `fetch()` из браузера, нет `require`/`import`.** Только то, что перечислено выше,
  плюс стандартный JavaScript (`JSON`, `Math`, `Date`, `RegExp`, классы, стрелочные функции).
- **Файловая система** — только собственная папка через `mg.dataDirectory()`.
- **Уведомления приходят, пока приложение живо в памяти.** После полного выгрузки iOS не будит
  плагин: `onMessageReceive` не вызовется.
- **Функции ввода** (`setInputText`, `getInputText`, `sendMessage`) объявлены в API, но пока
  возвращают пустоту — доступ к полю ввода открытого чата подключается отдельно. Плагин,
  написанный под них, ведёт себя как при закрытом чате, а не ломается.

---

*Megram Plugin SDK 1.0*
