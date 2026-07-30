# nameless — каталог функций и переключателей

Сгенерировано по клону репозитория `kreadwrite/nameless` на коммите `5e8f95aedc1bb2075b228cebbba091e20f8730d6`.

## Как пользоваться каталогом

- `Fxxx` — уникальная логическая функция/тумблер. Один номер может отображаться в новом и legacy-экране настроек.
- `Axxx` — отдельный экран, действие, ссылка, слайдер или селектор, то есть не обычный Boolean-тумблер.
- Номера постоянные: после удаления номер не переиспользуется.
- Для полного удаления функции нужно убрать не только строку тумблера, но и сохранённую настройку, обработчик, точки применения, отдельные экраны, документацию и дублирующий legacy-вход, если он есть.
- Основной новый каталог: `Swiftgram/SGSettingsUI/Sources/NamelessFeaturesController.swift`.
- Legacy-каталог: `LuxGram/LuxSettingsUI/Sources/LuxGramSettingsController.swift`.
- В основном разделе F001–F171 учтены также отдельные экраны и скрытые/динамические Boolean-переключатели; некоторые UI-строки используют внутреннее инвертированное имя, поэтому ниже приведено пользовательское название функции.

## F — уникальные функции и тумблеры (171 пункт)

### Внешний вид, интерфейс и сообщения

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F001 | Квадратные аватары | `squareAvatars` | Новый каталог |
| F002 | Новый список чатов (карточки) | `newChatList` | Новый каталог |
| F003 | Компактный список чатов | `compactChatList` | Новый каталог |
| F004 | Закрепление чатов без лимита | `unlimitedPinnedChats` | Новый каталог |
| F005 | Надпись «Чаты» в списке | `chatListTitle` | Новый каталог |
| F006 | Кнопка поиска в списке чатов | `searchButtonInChatList` | Новый каталог |
| F007 | Премиум-статус в шапке | `premiumStatusInHeader` | Новый каталог |
| F008 | Папки снизу | `foldersAtBottom` | Новый каталог |
| F009 | ОЗУ под часами | `ramUsageUnderClock` | Новый каталог |
| F010 | Скрыть номер в настройках | `hidePhoneInSettings` | Новый и legacy-каталог |
| F011 | Скрыть «Все чаты» | `allChatsHidden` | Новый и legacy-каталог |
| F012 | Скрыть истории | `hideStories` | Новый и legacy-каталог |
| F013 | Новый вид заголовка чата | `newChatHeader` | Новый каталог |
| F014 | Новый вид переключения аккаунтов | `newAccountSwitcher` | Новый каталог |
| F015 | Блюр вместо Liquid Glass | `blurInsteadGlass` | Новый каталог |
| F016 | OLED-режим, чёрный фон | `oledMode` | Новый каталог |
| F017 | Широкие посты в каналах | `wideChannelPosts` | Новый каталог |
| F018 | Обводка сообщений | `messageOutline` | Новый каталог |
| F019 | Прозрачные сообщения | `messageTransparent` | Новый каталог |
| F020 | Полупрозрачные сообщения | `messageSemiTransparent` | Новый каталог |
| F021 | Размытие сообщений | `messageBlurEffect` | Новый каталог |
| F022 | Компактное превью сообщений | `compactMessagePreview` | Новый каталог |
| F023 | Подписи вкладок | `showTabNames` | Новый и legacy-каталог |
| F024 | Круглые вкладки без текста | `roundTabs` | Новый каталог |
| F025 | Скрыть нижний таббар | `hideTabBar` | Новый и legacy-каталог |
| F026 | Свайп-опции чатов | `disableChatSwipeOptions` | Новый каталог |
| F027 | Кнопка записи голосовых | `hideRecordingButton` | Новый каталог; значение инвертировано |
| F028 | Отправка по Return | `sendWithReturnKey` | Новый каталог |
| F029 | Секунды в метке времени сообщений | `secondsInMessages` / `showSeconds` | Новый каталог; legacy-дубль |
| F030 | Скрыть реакции | `hideReactions` | Новый каталог |
| F031 | Эффект удаления сообщений | `disableSnapDeletionEffect` | Новый каталог; значение инвертировано |
| F032 | Вкладка эмодзи первой | `forceEmojiTab` | Новый каталог |
| F033 | Стандартные эмодзи первыми | `defaultEmojisFirst` | Новый каталог |
| F034 | Сохранять историю редактирования | `saveEditHistory` | Новый и legacy-каталог |
| F035 | Локальное редактирование сообщений | `enableLocalMessageEditing` | Новый и legacy-каталог |
| F036 | Сокращать длинные сообщения | `truncateLongMessages` | Новый каталог |
| F037 | Сохранять историю чатов | `saveChatHistory` | Новый каталог |
| F038 | Одноразовые медиа в галерею | `saveOnceMedia` | Новый каталог |
| F039 | Не включать следующее голосовое автоматически | `noAutoNextVoice` | Новый каталог |
| F040 | Полупрозрачность, когда пользователя упомянули | `semiTransparentWhenMentioned` | Новый каталог |
| F041 | Счётчик символов при вводе | `charCounterInput` | Новый каталог |
| F042 | Счётчик символов в чате | `charCounterInChat` | Новый каталог |
| F043 | Двойной тап для редактирования | `doubleTapToEdit` | Новый каталог |
| F044 | Кнопка «Наверх» | `scrollToTopButtonEnabled` | Новый и legacy-каталог |
| F045 | Скролл к следующему каналу | `disableScrollToNextChannel2` / `disableScrollToNextChannel` | Новый каталог; значение инвертировано |
| F046 | Показывать оригинал изменений | `showOriginalEdited` | Новый каталог |

### Liquid Glass

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F047 | Liquid Glass — мастер | `liquidGlassEnabled` | Новый и legacy-каталог |
| F048 | Анимация фейда при включении | `namelessLiquidGlassFadeAnimation` | Новый каталог |
| F049 | Liquid Glass для входящих сообщений | `namelessLiquidGlassMessages` | Новый и legacy-каталог |
| F050 | Liquid Glass для исходящих сообщений | `namelessLiquidGlassOutgoingMessages` | Новый каталог |
| F051 | Liquid Glass для настроек | `namelessLiquidGlassSettings` | Новый и legacy-каталог |
| F052 | Liquid Glass для профиля | `namelessLiquidGlassProfile` | Новый и legacy-каталог |
| F053 | Liquid Glass для подарков в профиле | `namelessLiquidGlassProfileGifts` | Новый и legacy-каталог |
| F054 | Liquid Glass для inline-кнопок ботов | `namelessLiquidGlassInlineButtons` | Новый и legacy-каталог |
| F055 | Liquid Glass для всплывающих окон | `namelessLiquidGlassPopup` | Новый каталог |
| F056 | Liquid Glass для контекстного меню | `namelessLiquidGlassContextMenu` | Новый каталог |
| F057 | Liquid Glass для панели поиска | `namelessLiquidGlassSearch` | Новый каталог |
| F058 | Тонирование Liquid Glass | `namelessLiquidGlassTinting` | Новый и legacy-каталог |

### Камера, медиа и профиль

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F059 | Телескоп, то есть зум камеры | `enableTelescope` | Новый и legacy-каталог |
| F060 | Задняя камера по умолчанию | `cameraDefaultBack` | Новый каталог |
| F061 | Микрофон устройства | `cameraUseDeviceMicrophone` | Новый каталог |
| F062 | Отправлять фото в HD | `cameraSendHDPhoto` | Новый каталог |
| F063 | Запоминать последнюю камеру | `cameraRememberLast` | Новый каталог |
| F064 | Статичный зум при записи | `cameraStaticZoom` | Новый каталог |
| F065 | Всегда отправлять в HD | `cameraAlwaysSendHD` | Новый каталог |
| F066 | Видео преобразовать в кружок или голосовое | `enableVideoToCircleOrVoice` | Новый и legacy-каталог |
| F067 | Блюр обложки трека | `musicAlbumBlur` | Новый каталог |
| F068 | Эффект в плеере | `musicPlayerEffect` | Новый каталог |
| F069 | Видео-обои чата | `namelessVideoBackgroundEnabled` | Новый и legacy-каталог |
| F070 | Цветной фон профиля | `profileColorBackground` | Новый каталог |
| F071 | Блюр аватара в профиле | `profileAvatarBlur` | Новый каталог |
| F072 | Минимальный блюр аватара | `profileAvatarBlurMinimal` | Новый каталог; зависит от F071 |
| F073 | Тонирование блюра аватара | `profileAvatarBlurTinting` | Новый каталог; зависит от F071 |
| F074 | Иконки приложения Telegram | `telegramAppIcons` | Новый каталог |
| F075 | Кастомные иконки настроек | `customSettingsIcons` | Новый каталог |
| F076 | Эффект частиц | `particleEffectEnabled` | Новый каталог |
| F077 | Предупреждение перед звонком | `confirmCalls` / `warnBeforeCall` | Новый и legacy-каталог |

### Режим призрака и приватность

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F078 | Режим призрака — мастер | `ghostModeEnabled` | Новый каталог |
| F079 | Всегда онлайн | `ghostModeAlwaysOnline` | Новый каталог |
| F080 | Скрыть онлайн-статус | `disableOnlineStatus` | Новый и legacy-каталог |
| F081 | Скрыть статус «печатает» | `disableTypingStatus` | Новый и legacy-каталог |
| F082 | Скрыть запись голосового | `disableVCMessageRecordingStatus` | Новый и legacy-каталог |
| F083 | Скрыть загрузку файлов | `disableUploadingFileStatus` | Новый и legacy-каталог |
| F084 | Скрыть отправку фото | `disableUploadingPhotoStatus` | Новый и legacy-каталог |
| F085 | Скрыть отправку видео | `disableUploadingVideoStatus` | Новый и legacy-каталог |
| F086 | Скрыть запись видео | `disableRecordingVideoStatus` | Новый и legacy-каталог |
| F087 | Скрыть выбор локации | `disableChoosingLocationStatus` | Новый и legacy-каталог |
| F088 | Скрыть выбор контакта | `disableChoosingContactStatus` | Новый и legacy-каталог |
| F089 | Скрыть статус игры | `disablePlayingGameStatus` | Новый и legacy-каталог |
| F090 | Скрыть запись кружка | `disableRecordingRoundVideoStatus` | Новый и legacy-каталог |
| F091 | Скрыть отправку кружка | `disableUploadingRoundVideoStatus` | Новый и legacy-каталог |
| F092 | Скрыть говорение в групповом звонке | `disableSpeakingInGroupCallStatus` | Новый и legacy-каталог |
| F093 | Скрыть выбор стикера | `disableChoosingStickerStatus` | Новый и legacy-каталог |
| F094 | Скрыть эмодзи-взаимодействие | `disableEmojiInteractionStatus` | Новый и legacy-каталог |
| F095 | Скрыть эмодзи-подтверждение | `disableEmojiAcknowledgementStatus` | Новый и legacy-каталог |
| F096 | Скрыть просмотр видео или кружка | `ghostModeHideVideoWatch` | Новый каталог |
| F097 | Скрыть прочтение сообщений | `disableMessageReadReceipt` | Новый и legacy-каталог |
| F098 | Скрыть просмотр сторис | `disableStoryReadReceipt` | Новый и legacy-каталог |
| F099 | Задержка отправки 12 секунд | `ghostModeMessageSendDelaySeconds` | Новый и legacy-каталог; Boolean включает значение 12 |
| F100 | Fake typing | `ghostModeFakeTyping` | Новый каталог |
| F101 | Анти-спам входящих | `ghostModeAntiSpam` | Новый каталог |
| F102 | Автоочистка истории | `ghostModeAutoCleanHistory` | Новый каталог |
| F103 | История онлайна собеседников | `enableOnlineStatusRecording` | Новый и legacy-каталог |
| F104 | Подмена геолокации | `fakeLocationEnabled` | Новый и legacy-каталог |
| F105 | Обход защищённого контента | `bypassProtectedContent` | Новый каталог |
| F106 | Убрать спойлеры везде | `removeSpoilersEverywhere` | Новый каталог |
| F107 | Защита от мошенников | `antiScamEnabled` | Новый каталог |
| F108 | Отключить рекламу | `disableAllAds` | Новый и legacy-каталог |
| F109 | Сохранять защищённый контент | `enableSavingProtectedContent` | Новый и legacy-каталог |
| F110 | Сохранять самоуничтожающиеся сообщения | `enableSavingSelfDestructingMessages` | Новый и legacy-каталог |
| F111 | Скрыть детекцию скриншотов | `disableScreenshotDetection` | Новый и legacy-каталог |
| F112 | Не размывать секретный чат при скриншоте | `disableSecretChatBlurOnScreenshot` | Новый и legacy-каталог |
| F113 | Скрыть спонсора прокси | `hideProxySponsor` | Новый и legacy-каталог |

### Информация и отображение профиля

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F114 | Показывать ID и DC в профиле | `showProfileId` | Новый и legacy-каталог |
| F115 | Полные просмотры вместо сокращённых | `showFullViews` | Новый каталог |
| F116 | Скрыть номер телефона | `hidePhoneNumber` | Новый каталог |
| F117 | Показывать дату создания чата или канала | `showCreationDate` | Новый каталог |
| F118 | Визуальный юзернейм | `visualUsername` | Новый каталог |
| F119 | Показывать взаимность контактов | `showIfMutualContacts` | Новый каталог |
| F120 | Показывать дату регистрации аккаунта | `showRegistrationDate` / `showRegDate` | Новый и legacy-каталог |
| F121 | Показывать DC | `showDC` | Новый и legacy-каталог |
| F122 | Полные числа вместо компактных | `disableCompactNumbers` | Новый и legacy-каталог; значение в новом UI инвертировано |

### Контекстное меню, локальные функции и сторис

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F123 | Пункт «Сохранить в облако» | `contextShowSaveToCloud` | Новый каталог |
| F124 | Пункт «Скрыть имя пересылки» | `contextShowHideForwardName` | Новый каталог |
| F125 | Пункт «Выбрать от пользователя» | `contextShowSelectFromUser` | Новый каталог |
| F126 | Пункт «Ограничить» | `contextShowRestrict` | Новый каталог |
| F127 | Пункт «Пожаловаться» | `contextShowReport` | Новый каталог |
| F128 | Пункт «Ответить» | `contextShowReply` | Новый каталог |
| F129 | Пункт «Закрепить» | `contextShowPin` | Новый каталог |
| F130 | Пункт «Сохранить медиа» | `contextShowSaveMedia` | Новый каталог |
| F131 | Пункт «Ответы на сообщение» | `contextShowMessageReplies` | Новый каталог |
| F132 | Пункт JSON | `contextShowJson` | Новый каталог |
| F133 | Локальный премиум | `enableLocalPremium` | Новый и legacy-каталог |
| F134 | Кнопка «Перевести» всегда видима | `quickTranslateButton` | Новый и legacy-каталог |
| F135 | Zalgo-фильтр | `disableZalgoText` | Новый и legacy-каталог |
| F136 | Ускорение отправки | `uploadSpeedBoost` | Новый и legacy-каталог |
| F137 | Безлимитные избранные стикеры | `unlimitedFavoriteStickers` | Новый и legacy-каталог |
| F138 | Временные метки на стикерах | `stickerTimestamp` | Новый каталог |
| F139 | Отправлять большие фото | `sendLargePhotos` | Новый каталог |
| F140 | Скрыть свайп для записи сторис | `disableSwipeToRecordStory` | Новый каталог |
| F141 | Предупреждать при открытии сторис | `warnOnStoriesOpen` | Новый каталог |
| F142 | Stealth-режим сторис | `storyStealthMode` | Новый каталог; показывается при доступности |
| F143 | Показывать «Переслать в историю» | `showRepostToStoryV2` | Новый каталог |
| F144 | Использовать системный шэринг | `forceSystemSharing` | Новый каталог |
| F145 | Скачивание эмодзи | `emojiDownloaderEnabled` | Новый и legacy-каталог |
| F146 | Свайп для PiP-видео | `videoPIPSwipeDirection` | Новый каталог |
| F147 | Использовать встроенный микрофон | `forceBuiltInMic` | Новый каталог |

### Legacy-функции, которых нет отдельным тумблером в новом каталоге

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F148 | Сохранять удалённые сообщения | `showDeletedMessages` | Legacy-каталог |
| F149 | Сохранять медиа удалённых сообщений | `saveDeletedMessagesMedia` | Legacy-каталог |
| F150 | Сохранять реакции удалённых сообщений | `saveDeletedMessagesReactions` | Legacy-каталог |
| F151 | Сохранять удалённые сообщения для ботов | `saveDeletedMessagesForBots` | Legacy-каталог |
| F152 | Сохранять удалённые каналы | `keepRemovedChannels` | Legacy-каталог |
| F153 | Скрыть загрузку сообщений голосового чата | `disableVCMessageUploadingStatus` | Legacy-каталог |
| F154 | Разрешить чувствительный контент 18+ | `sensitiveContentEnabled` | Legacy-каталог; серверная настройка Telegram |
| F155 | Экспорт чатов | `chatExportEnabled` | Legacy-каталог |
| F156 | Локальный баланс звёзд | `feelRichEnabled` | Legacy-каталог |
| F157 | Показывать ID подарка | `giftIdEnabled` | Legacy-каталог |
| F158 | Фейковый профиль | `fakeProfileEnabled` | Legacy-каталог; отдельный экран настроек |
| F159 | Замена шрифта | `enableFontReplacement` | Legacy-каталог; отдельный экран настроек |
| F160 | Смена голоса | `voiceMorpherEnabled` | Legacy-каталог; отдельный экран/пресет |

### Дополнительные тумблеры на отдельных экранах

| ID | Функция | Ключ/обработчик | Где отображается |
|---|---|---|---|
| F161 | Premium-бейдж фейкового профиля | `fakeProfilePremium` | `FakeProfileSettingsController` |
| F162 | Верифицированный бейдж фейкового профиля | `fakeProfileVerified` | `FakeProfileSettingsController` |
| F163 | Scam-бейдж фейкового профиля | `fakeProfileScam` | `FakeProfileSettingsController` |
| F164 | Fake-бейдж фейкового профиля | `fakeProfileFake` | `FakeProfileSettingsController` |
| F165 | Support-бейдж фейкового профиля | `fakeProfileSupport` | `FakeProfileSettingsController` |
| F166 | Bot-бейдж фейкового профиля | `fakeProfileBot` | `FakeProfileSettingsController` |
| F167 | Пароль для чатов | `ProtectedChatsStore.isEnabled` | `ProtectedChatsSettingsController` |
| F168 | Использовать пароль Telegram для защищённых чатов | `ProtectedChatsStore.useDevicePasscode` | `ProtectedChatsSettingsController` |
| F169 | Двойное дно | `doubleBottomEnabled` | `DoubleBottomSettingsController` |
| F170 | Включить/выключить установленный плагин | `PluginInfo.enabled` | Динамические строки `PluginListController` |
| F171 | Глобальная система плагинов | `pluginSystemEnabled` | Сохранённый флаг; отдельного обычного тумблера в найденном каталоге нет |

## A — прочие функциональные элементы

Эти элементы не являются обычными Boolean-тумблерами, но тоже относятся к функциям приложения и нужны для полного удаления связанной возможности.

| ID | Элемент | Что делает | Где |
|---|---|---|---|
| A001 | Интенсивность Liquid Glass | Слайдер `liquidGlassIntensity` | Новый каталог |
| A002 | Качество JPEG камеры | Слайдер `cameraJpegQuality` | Новый каталог |
| A003 | Скорость частиц | Слайдер `particleEffectSpeed` | Новый каталог |
| A004 | Плотность частиц | Слайдер `particleEffectDensity` | Новый каталог |
| A005 | Насыщенность цветов аккаунтов | Слайдер `accountColorsSaturation` | Новый каталог |
| A006 | Размер стикеров | Слайдер `stickerSize` | Новый каталог и legacy-дубль |
| A007 | Качество исходящих фото | Слайдер `outgoingPhotoQuality` | Новый каталог |
| A008 | Стиль автоформатирования | Селектор `autoFormatMode` | Новый каталог |
| A009 | Ускорение загрузки | Селектор `downloadSpeedBoost` | Новый каталог |
| A010 | История онлайна | Переход на `NamelessOnlineHistoryController` | Новый каталог |
| A011 | Список сохранённых удалённых сообщений | Переход на `SavedDeletedMessagesListController` | Legacy-каталог |
| A012 | Исключения для отправки read receipts | Переход на список исключений | Legacy-каталог |
| A013 | Органайзер таббара | Переход на настройку вкладок | Legacy-каталог |
| A014 | Обложка профиля | Переход на `ProfileCoverController` | Legacy-каталог |
| A015 | Настройки фейкового профиля | Переход на `FakeProfileSettingsController` | Legacy-каталог |
| A016 | Выбор шрифта | Переход на `FontReplacementPickerController` | Legacy-каталог |
| A017 | Импорт обычного TTF-шрифта | Переход на импорт файла | Legacy-каталог |
| A018 | Выбор жирного шрифта | Переход на picker жирного шрифта | Legacy-каталог |
| A019 | Импорт жирного TTF-шрифта | Переход на импорт жирного файла | Legacy-каталог |
| A020 | Выбор/замена видео-обоев | Переход на picker видео | Legacy-каталог |
| A021 | Удаление видео-обоев | Удаляет сохранённое видео | Legacy-каталог |
| A022 | Настройка суммы локальных звёзд | Переход на `FeelRichAmountController` | Legacy-каталог |
| A023 | Пресет смены голоса | Переход на picker пресета | Legacy-каталог |
| A024 | Выбор фейковой геолокации | Переход на `FakeLocationPickerController` | Legacy-каталог |
| A025 | Задержка отправки | Слайдер задержки | Legacy-каталог |
| A026 | Размер заменяемого шрифта | Слайдер `fontReplacementSizeMultiplier` | Legacy-каталог |
| A027 | Очистить сохранённые удалённые сообщения | Деструктивное действие | Legacy-каталог |
| A028 | Отметить всё прочитанным локально | Действие | Legacy-каталог |
| A029 | Отметить всё прочитанным на сервере | Действие | Legacy-каталог |
| A030 | Откатить nameless-настройки | Восстановление rollback-снимка | Legacy-каталог |
| A031 | Экспорт настроек в JSON | Экспорт | Новый каталог |
| A032 | Импорт настроек из JSON | Импорт | Новый каталог |
| A033 | Сохранить настройки в Keychain | Сохранение настроек | Новый каталог |
| A034 | Сбросить настройки nameless | Деструктивный сброс | Новый каталог |
| A035 | Поиск настроек | Поиск по каталогу с переходом к категории | Новый каталог |
| A036 | Канал nameless | Внешняя ссылка | `NamelessAboutController` |
| A037 | Разработчик | Внешняя ссылка | `NamelessAboutController` |
| A038 | Stiven VPN | Внешняя ссылка | `NamelessAboutController` |
| A039 | Защищённые чаты — добавить чат | Добавление чата в список | `ProtectedChatsSettingsController` |
| A040 | Защищённые чаты — установить отдельный пароль | Passcode setup | `ProtectedChatsSettingsController` |
| A041 | Защищённые чаты — удалить чат из списка | Действие удаления | `ProtectedChatsSettingsController` |
| A042 | Двойное дно — настройка секретного пароля | Passcode setup | `DoubleBottomSettingsController` |
| A043 | Установка плагина | Импорт `.plugin`, `.js`, `.mjs`, `.cjs` | `PluginListController` |
| A044 | Установка tweak | Импорт `.deb`/`.dylib` | `PluginListController` |
| A045 | Настройки плагина | Открывает настройки конкретного плагина | `PluginListController` |
| A046 | Удаление плагина | Удаляет установленный плагин | `PluginListController` |
| A047 | Удаление tweak | Удаляет установленный tweak | `PluginListController` |
| A048 | Настройки имени/профиля фейкового профиля | Текстовые поля | `FakeProfileSettingsController` |
| A049 | Настройки бейджей фейкового профиля | Шесть отдельных Boolean-пунктов F161–F166 | `FakeProfileSettingsController` |

## Важные дубли

- F010, F011, F012, F023, F025, F029, F034, F035, F044, F047, F049–F054, F058, F059, F066, F069, F077, F080–F098, F103–F114, F120–F121, F133–F137 отображаются более чем в одном экране или имеют legacy-дубль.
- F158, F159 и F160 открывают отдельные контроллеры. Для полного удаления нужно удалять и переход, и сам контроллер/модуль, и точки применения.
- F170 динамический: отдельный тумблер создаётся для каждого установленного плагина.
- F171 сохранён в настройках и используется раннером плагинов, но в найденных основных каталогах отдельной строки `toggle` для него нет.

## Результат клонирования

Клон находится в `Projects/nameless`. Исходный remote:

`https://github.com/kreadwrite/nameless.git`

Исходный код не изменялся. В репозитории добавлен только этот каталог функций.
