---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

if MRT.locale ~= "ruRU" and not (VMRT and VMRT.Reminder and VMRT.Reminder.ForceLocale == "ru") then
	return
end

---@class Locale
local LR = AddonDB.LR

LR.OutlinesNone = "Нет"
LR.OutlinesNormal = "КОНТУР"
LR.OutlinesThick = "ТОЛСТЫЙ КОНТУР"
LR.OutlinesMono = "МОНОХРОМНЫЙ КРАЙ"
LR.OutlinesMonoNormal = "МОНОХРОМНЫЙ КРАЙ, КОНТУР"
LR.OutlinesMonoThick = "МОНОХРОМНЫЙ КРАЙ, ТОЛСТЫЙ КОНТУР"

LR.RolesTanks = "Танки"
LR.RolesHeals = "Хилы"
LR.RolesMheals = "МХилы"
LR.RolesMhealsTip = "Мили хилы: Паладин и Монк"
LR.RolesRheals = "РХилы"
LR.RolesRhealsTip = "Ренж хилы"
LR.RolesDps = "ДД"
LR.RolesRdps = "РДД"
LR.RolesMdps = "МДД"

LR.spamType1 = "Спам в чат с отсчетом"
LR.spamType2 = "Спам в чат"
LR.spamType3 = "Отправить одно сообщение"

LR.spamChannel1 = "Сказать"
LR.spamChannel2 = "|cffff4040Крик|r"
LR.spamChannel3 = "|cff76c8ffГруппа|r"
LR.spamChannel4 = "|cffff7f00Рейд|r"
LR.spamChannel5 = "Собственный чат(print)"

LR.Reminders = "Ремайндеры"
LR["Settings"] = "Настройки"
LR["Help"] = "Помощь"
LR.Versions = "Версии"
LR.Trigger = "Триггер "
LR.AddTrigger = "Добавить Триггер"
LR.DeleteTrigger = "Удалить Триггер"
LR.Source = "Источник"
LR.Target = "Цель"
LR.YellowAlertTip = "|cffff0000Длительность ремайндера и длительность активации триггера\nне должна равняться 0 в ремайндере без 'untimed' триггеров\n\nУкажите длительность активации в не untimed триггерах.|r"
LR.EnvironmentalDMGTip = "1 - Падение\n2 - Закончилось дыхание\n3 - Усталость\n4 - Огонь\n5 - Лава\n6 - Слизь"
LR.DifficultyID = "ID Сложности:"
LR.Difficulty = "Сложность:"
LR.EncounterID = "ID Босса:"
LR.CountdownFormat = "Формат отсчета:"
LR.AddTextReplacers = "Шаблон замены текста"
LR["replaceDropDownTip"] = "|cffffffffЭто список доступных шаблонов замены текста.\nВы можете использовать их в |cff55ee55тексте сообщения,\nTTS, спаме в чат, подсветке фрейма, тексте на\nнеймплейте, сообщении для ивента WeakAuras\nи дополнительном условии активации|r.\n\nСодержимое может меняться в зависимости от\nвыбранных триггеров"
LR.WAmsgTip = "Ремайндер будет отправлять ивенты для WeakAuaras.\nАргументы для |cff55ee55WeakAuras.ScanEvents|r разделяються пробелами."
LR.WAmsg = "Event для WeakAuras:"
LR.GlowTip = "\nИмя игрока или |cff55ee55{targetName}|r или |cff55ee55{sourceName}|r\n|cff55ee55{sourceName|cff80ff001|r}|r что-бы уточнить номер триггера"
LR.SpamType = "Тип сообщения:"
LR.SpamChannel = "Канал чата:"
LR.spamMsg = "Сообщение для чата:"
LR.ReverseTip = "Обратить загрузку по именам игроков"
LR.Reverse = "Обратить"
LR.Manually = "Вручную"
LR.ManuallyTip = "Установить вручную ID босса, ID сложности или ID инстанса"
LR.WipePulls = "Очистить Историю"
LR.DungeonHistory = "История подземелий"
LR.RaidHistory = "История рейда"
LR.Duplicated = "Дублированный"
LR.ListNotSentTip = "Не отправлен"
LR.ClearImport = "Вы делаете 'чистый' импорт\n|cffff0000Все старые ремайндеры будут удалены|r"
LR.ForceRemove = "Вы уверены что хотите удалить ВСЕМ ремайндеры из вашей корзины?"
LR.ClearRemove = "Вы уверены что хотите очистить корзину?"
LR.CenterByX = "Центрировать гор."
LR.CenterByY = "Центрировать вер."
LR.EnableHistory = "Записывать историю заклинаний"
LR.EnableHistoryRaid ="История заклинаний боссов в рейде"
LR.EnableHistoryDungeon = "История заклинаний боссов в подземельях"

LR.chkEnableHistory = "Записывать историю пуллов"
LR.chkEnableHistoryTip = "Отвечает за запись истории пуллов для окна быстрой настройки.\nЕсли выключено то события с последнего пулла всеравно будут отображаться.\n|cffff0000***Большее число сохраняемых боев требует больше ресурсов.\n**При выключении записанные пулы удаляются из памяти"
LR.Add = "Добавить"
LR.SendAll = "Отправить все"
LR.Boss = "Босс:"

LR.Name = "Название:"
LR.delayTip = "Показать ремайндер только через X секунд после выполнения всех условий триггеров.\nМожно оставить пустым - мгновенная активация ремайндера\nДля удобства можно использовать минутный формат, прим.: |cff00ff001:30.5|r - сработает через 90.5 секунд\nМожно указать несколько через запятую."
LR.delayTimeTip = "Можно оставить пустым - мгновенная активация триггера\nДля удобства можно использовать минутный формат, прим.: |cff00ff001:30.5|r - сработает через 90.5 секунд\nМожно указать несколько через запятую.\nМожно указать значение |cff00ff00NOTE|r - будет использовано значение {time:x:xx} из шаблона заметки"
LR.delayText = "Показать через:"
LR.duration = "Длительность, с.:"
LR.durationTip = [[Длительность отображения текста/подсветки/спама в чат

Если длительность равна 0 то ремайндер будет untimed,
т.е. будет отображаться пока активны триггеры]]
LR.countdown = "Обратный отсчет:"
LR.msg = "Сообщение на экране:"
LR.sound = "Звук при появлении:"
LR.soundOnHide = "Звук при скрытии:"
LR.voiceCountdown = "Голосовой отсчет:"
LR.AllPlayers = "Все игроки"
LR.notePatternEditTip = "См. Помощь - Загрузка по заметке"

LR.notePattern = "Шаблон заметки:"
LR.save = "Сохранить"
LR.QuickSetup = "Показать историю"

LR.IgnoreTrigger = "Игнорировать триггер\n(использовать только фильтры)"

LR.QS_PhaseRepeat = "Повтор фазы "
LR["QS_1"] = "Журнал боя"
LR["QS_SPELL_CAST_START"] = "Начало каста"
LR["QS_SPELL_CAST_SUCCESS"] = "Каст завершен"
LR["QS_SPELL_AURA_APPLIED"] = "+аура"
LR["QS_SPELL_AURA_REMOVED"] = "-аура"
LR["QS_2"] = "Фаза босса"
LR["QS_3"] = "Пулл босса"
LR["QS_8"] = "Чат"
LR["QS_9"] = "Новый фрейм"
LR["QS_0"] = "Конец файта"

LR["Fight timer"] = "Таймер боя:"
LR["Fight started"] = "Начало боя:"

LR.Always = "Всегда"

LR.SingularExportTip = "Вы можете добавить больше ремайндеров в окно экспорта нажимая на кнопку экспорт"

LR.DeleteSection = "Удалить все незаблокированные в этой секции"
LR.NoName = "Безымянный"
LR.RemoveSection = "Удалить эту секцию\n|cffffffffУдалены будут все незаблокированные ремайндеры"
LR.PersonalDisable = "Отключить этот ремайндер для себя"
LR.PersonalEnable = "Включить этот ремайндер для себя"
LR.UpdatesDisable = "Запретить обновления этого ремайндера"
LR.UpdatesEnable = "Разрешить обновления этого ремайндера"
LR.SoundDisable = "Отключить звук для этого ремайндера"
LR["SoundUpdatesDisable"] = "Запретить обновление звука и tts для этого ремайндера"
LR.Listduplicate ="Дублировать"
LR.Listdelete = "Удалить"
LR.ListdeleteTip = "Удалить\n|cffffffffЗажмите шифт что бы удалить\nремайндер без подтверждения"
LR.ListdExport = "Экспорт"
LR.ListdSend = "Отправить"

LR["Enabled"] = "Включить"
LR["EnabledTip"] = "Включить/выключить ремайндер\nПередаеться при отправке ремайндера\n\nЭта настройка имеет приоритет над настройкой персонального включения/выключения"

LR["Default State"] = "Состояние по умолчанию"
LR["Default StateTip"] = "Влияет на персональное включение/выключение ремайндера\n\nВключен - ремайндер будет включен по умолчанию\nВыключен - ремайндер будет выключен по умолчанию\n\nИспользовать в случае если хотите дать пользователям решать включить или выключить ремайндер но думаете что большинство захочем иметь его выключенным"

LR.DeleteAll = "Удалить все"
LR.ExportAll = "Экспорт все"
LR.Import = "Импорт"
LR.Export = "Экспорт"
LR.ImportTip = "Если нажать с зажатым шифтом тогда произойдет чистая установка. Все старые ремайндеры удаляться."

LR.DisableSound = "Отключить звук"
LR.Font = "Шрифт"
LR.Outline = "Обводка"
LR.Strata = "Слой"
LR.Justify = "Выравнивание"

LR.OutlineChk = "Включить тень"
LR.CenterXTip = "Выровнять фиксатор по горизонтали"
LR.CenterYTip = "Выровнять фиксатор по вертикали"

LR.GlobalCounter = "По умолчанию"
LR.CounterSource = "Для каждого Источника"
LR.CounterDest = "Для каждой Цели"
LR.CounterTriggers = "Наложение триггера"
LR.CounterTriggersPersonal = "Наложение триггера со сбросом"
LR["Global counter for reminder"] = "Общий для этого ремайндера"
LR["Reset in 5 sec"] = "Сброс через 5 сек"

LR["GlobalCounterTip"] = "|cff00ff00По умолчанию|r - Добавляет +1 при каждом срабатывании триггера"
LR["CounterSourceTip"] = "|cff00ff00Для каждого Источника|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждого кастера"
LR["CounterDestTip"] = "|cff00ff00Для каждой Цели|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждой цели"

LR["CounterTriggersTip"] = "|cff00ff00Наложение триггера|r - Добавляет +1 когда триггер активируеться в момент\nкогда все остальные триггеры активны(наложение)"
LR["CounterTriggersPersonalTip"] = "|cff00ff00Наложение триггера со сбросом|r - Добавляет +1 когда триггер активируеться в момент\nкогда все остальные триггеры активны(наложение). Сбрасывает счетчик до 0 когда ремайндер деактивируеться"

LR["CounterGlobalForReminderTip"] = "|cff00ff00Общий для этого ремайндера|r - Добавляет +1 при каждом срабатывании триггера.\nОбщий счетчик с каждым триггером с таким же типом счетчика в этом ремайндере"
LR["CounterResetIn5SecTip"] = "|cff00ff00Сброс через 5 сек|r - Добавляет +1 при каждом срабатывании триггера.\nСбрасывает счетчик до 0 через 5 секунд после каждого срабатывания триггера"

LR.AnyBoss = "Любой босс"
LR.AnyNameplate = "Любой неймплейт"
LR.AnyRaid = "Любой из рейда"
LR.AnyParty = "Любой из группы"

LR.CombatLog = "Журнал боя"
LR.BossPhase = "Фаза босса"
LR.BossPhaseTip = "Информация о фазе босса береться из BigWigs или DBM\nЕсли не указана длительность активации то триггер будет активен до конца фазы"
LR.BossPhaseLabel = "Фаза(Название/номер)"
LR.BossPull = "Пулл босса"
LR.Health = "Здоровье юнита"
LR.HealthTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.ReplacertargetGUID = "GUID"
LR.Mana = "Энергия юнита"
LR.ManaTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.Replacerhealthenergy = "Процент Энергии"
LR.Replacervalueenergy = "Значение Энергии"
LR.BWMsg = "Сообщение BigWigs/DBM"
LR.ReplacerspellNameBWMsg = "Текст сообщения BigWigs/DBM"
LR.BWTimer = "Таймер BigWigs/DBM"
LR.ReplacerspellNameBWTimer = "Текст таймера BigWigs/DBM"
LR.Chat = "Сообщение в чате"
LR.ChatHelp = "Союзники: Группа, Рейд, Шепот\nВраги: Сказать, Крик, Шепот, Эмоция"
LR.BossFrames = "Новый босс фрейм"
LR.Aura = "Аура"
LR.AuraTip = "Если не указана длительность активации то триггер будет активен пока висит аура"
LR.Absorb = "Абсорб юнита"
LR.AbsorbLabel = "Количество абсорба"
LR.AbsorbTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.Replacervalueabsorb = "Количество абсорба"

LR.CurTarget = "Текущая цель"
LR.CurTargetTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"

LR.SpellCD = "Перезарядка способности"
LR.SpellCDTooltip = "Триггер активен пока способность перезаряжеться"
LR.SpellCDTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"

LR.SpellCastDone = "Каст успешно завершен"
LR.SpellCastDoneTooltip = ""
LR.ReplacersourceGUID = "GUID источника"

LR.Widget = "Виджет"
LR.WidgetLabelID = "ID виджета"
LR.WidgetLabelName = "Название виджета"
LR.WidgetTip = "Активен пока присутствует виджет"
LR.ReplacerspellIDwigdet = "ID виджета"
LR.ReplacerspellNamewigdet = "Название виджета"
LR.Replacervaluewigdet = "Значение виджета"

LR.UnitCast = "Юнит кастует"
LR.UnitCastTip = "Отменяеться если юнит перестает кастовать или юнит больше не доступен"

LR.CastStart = "Начало каста"
LR.CastDone = "Каст завершен"
LR.AuraAdd = "+аура"
LR.AuraRem = "-аура"
LR.SpellDamage = "Урон от заклинания"
LR.SpellDamageTick = "Урон от заклинания (тик)"
LR.MeleeDamage = "Урон от мили"
LR.SpellHeal = "Исцеление от заклинания"
LR.SpellHealTick = "Исцеление от заклинания (тик)"
LR.SpellAbsorb = "Поглощение от заклинания"
LR.CLEUEnergize = "Получение ресурса"
LR.CLEUMiss = "Промах заклинания"
LR.Death = "Смерть"
LR.Summon = "Заклинание призыва"
LR.Dispel = "Заклинание рассеивания"
LR.CCBroke = "CC Broke"
LR.EnvDamage = "Урон окружения"
LR.Interrupt = "Прерывание заклинания"

LR["ReplacerextraSpellIDSpellDmg"] = "Количество"
LR["ReplacerextraSpellID"] = "Сбившее заклинание"
LR["MissType"] = "Тип Промаха"
LR.MissTypeLabelTooltip = "Доступные типы промаха:"
LR["ReplacerspellIDSwing"] = "Количество"

LR["event"] = "Событие:"
LR["eventCLEU"] = "Событие журнала боя:"

LR["UnitNameConditions"] = "Можно узазать несколько, разделенных знаком \"|cffffff00;|r\"\nДобавьте \"|cffffff00-|r\" первым символом, чтоб инвртировать список(т.е.\nдля условия будут подходить все имена, кроме тех что в списке)\n\nСм. Помощь - Строчные условия для подробностей"

LR["sourceName"] = "Имя Источника:"
LR["sourceID"] = "ID Источника:"
LR["sourceUnit"] = "Юнит Источника:"
LR["sourceMark"] = "Метка Источника:"

LR["targetName"] = "Имя Цели:"
LR["targetID"] = "ID Цели:"
LR["targetUnit"] = "Юнит Цели:"
LR["targetMark"] = "Метка Цели:"
LR["targetRole"] = "Роль Цели:"

LR["spellID"] = "Spell ID:"
LR["spellName"] = "Название заклинания:"
LR["extraSpellID"] = "Доп. Spell ID:"
LR["extraSpellIDTip"] = "Для Урона/Хила это количество урона\nДля CC Broke это spell id сбившего заклинания\nДля диспела это spell id сдиспеленой способности\nДля прерывания это spell id сбитой способности"
LR["stacks"] = "Стаки:"
LR["numberPercent"] = "Процент:"

LR["pattFind"] = "Шаблон для поиска:"
LR["bwtimeleft"] = "Оставшееся время:"

LR["counter"] = "№ Каста:"
LR["cbehavior"] = "Тип счетчика:"

LR["delayTime"] = "Задержка Активации:"
LR["activeTime"] = "Длительность Активации:"
LR["activeTimeTip"] = "Можно оставить пустым, полезно для сложных условий с несколькими триггерами"

LR["invert"] = "Инвертировать:"
LR["guidunit"] = "Юнит триггера:"
LR["guidunitTip"] = "Используется для подсветок неймплейтов и\nдля опции определения общего юнита для всех триггеров ремайндера."
LR["onlyPlayer"] = "Цель - игрок:"

LR.MultiplyTip2 = "Можно указать несколько через запятую."
LR.MultiplyTip3 = "Доступные синтаксы:"
LR.MultiplyTip4 = "|cffffff00[условие][номер]|r - примеры: |cff00ff00>3|r (все после 3), |cff00ff00<=2|r (первый и второй), |cff00ff00!4|r (все, кроме четвертого), |cff00ff005|r (только пятый)"
LR.MultiplyTip4b = "|cffffff00[условие][номер]|r - примеры: |cff00ff00<50.5|r (меньше 50.5), |cff00ff00>=90|r (больше или равно 90)"
LR.MultiplyTip5 = "|cffffff00[номер в цикле]%[длинна цикла]|r - пример: |cff00ff001%3|r (1,4,7,10,...), |cff00ff002%4|r (2,6,10,14,...)"
LR.MultiplyTip6 = "Если условий несколько (через запятую), то будет выбрано любое успешное."
LR.MultiplyTip7 = "Можно объеденить несколько условий знаком \"|cffffff00+|r\" (запятая так же должна присутствовать) - пример: |cff00ff00>3,+<7|r (больше трех и меньше семи)"
LR.MultiplyTip7b = "Можно объеденить несколько условий знаком \"|cffffff00+|r\" (запятая так же должна присутствовать) - пример: |cff00ff00>70,+<=75|r (больше 70 и меньше или равно 75)"

LR["Send All For This Boss"] = "Отправить (этот босс)"
LR["Export All For This Boss"] = "Экспорт (этот босс)"
LR["Get last update time"] = "Проверить дату обновления"
LR["Clear Removed"] = "Очистить корзину"
LR["Delete All Removed"] = "Удалить для всех"
LR["Deletes reminders from 'removed list' to all raiders"] = "Удаляет ремайндеры из корзины всем в рейде"

LR["NumberCondition"] = "См. Помощь - Цифровые условия для подробностей"
LR["MobIDCondition"] = "См. Помощь - MobID условия для подробностей"

LR["rtimeLeft"] = "Оставшееся Время"
LR["rActiveTime"] = "Активное Время"
LR["rActiveNum"] = "Количество активных Триггеров"
LR["rMinTimeLeft"] = "Минимальное Оставшееся Время"
LR["rTriggerStatus2"] = "Статус Триггера"
LR["rTriggerStatus"] = "Статус Триггера (по uid)"
LR["rAllSourceNames"] = "Все Источники"
LR["rAllTargetNames"] = "Все Цели"
LR["rAllActiveUIDs"] = "Все Активные UID"
LR["rNoteAll"] = "Все Игроки из Шаблона Заметки"
LR["rNoteLeft"] = "Слева от Игрока в Заметке"
LR["rNoteRight"] = "Справа от Игрока в Заметке"
LR["rTriggerActivations"] = "Количество активаций триггера"
LR["rRemActivations"] = "Количество активаций ремайндера"

LR["rsourceName"] = "Имя Источника"
LR["rsourceMark"] = "Метка Источника"
LR["rsourceGUID"] = "GUID Источника"
LR["rtargetName"] = "Имя Цели"
LR["rtargetMark"] = "Метка Цели"
LR["rtargetGUID"] = "GUID цели"
LR["rspellName"] = "Название Заклинания"
LR["rspellID"] = "ID Заклинания"
LR["rextraSpellID"] = "Доп. ID Заклинания"
LR["rstacks"] = "Стаки"
LR["rcounter"] = "Номер каста"
LR["rguid"] = "GUID триггера"
LR["rhealth"] = "Процент Здоровья"
LR["rvalue"] = "Значение Здоровья"
LR["rtext"] = "Текст"
LR["rphase"] = "Фаза"
LR["rauraValA"] = "Значение Подсказки 1"
LR["rauraValB"] = "Значение Подсказки 2"
LR["rauraValC"] = "Значение Подсказки 3"

LR["rspellIcon"] = "Иконка Заклинания"
LR["rclassColor"] = "Цвет Класса"
LR["rspecIcon"] = "Иконка Роли"
LR["rclassColorAndSpecIcon"] = "Иконка Роли и Цвет Класса"
LR["rplayerName"] = "Имя Игрока"
LR["rplayerClass"] = "Класс Игрока"
LR["rplayerSpec"] = "Специализация Игрока"
LR["rPersonalIcon"] = "Иконка персоналки"
LR["rImmuneIcon"] = "Иконка иммуна"
LR["rSprintIcon"] = "Иконка ускорения"
LR["rHealCDIcon"] = "Иконка хил кулдауна"
LR["rRaidCDIcon"] = "Иконка рейд кулдауна"
LR["rExternalCDIcon"] = "Иконка внешнего кулдауна"
LR["rFreedomCDIcon"] = "Иконка фридома"

LR["rsetparam"] = "Установить Переменную"
LR["rmath"] = "Арифметическое выражение"
LR["rnoteline"] = "Строка Заметки"
LR["rnote"] = "Строка заметки с позицией"
LR["rnotepos"] = "Игрок из заметки с позицией"
LR["rmin"] = "Минимальное Значение"
LR["rmax"] = "Максимальное Значение"
LR["rrole"] = "Роль Игрока"
LR["rextraRole"] = "Доп. Роль Игрока"
LR["rsub"] = "Вырезка из строки"
LR["rtrim"] = "Удалить крайние пробелы"

LR["rnum"] = "Выбрать"
LR["rup"] = "ВЕРХНИЙ РЕГИСТР"
LR["rlower"] = "нижний регистр"
LR["rrep"] = "Повторить"
LR["rlen"] = "Ограничить Длину"
LR["rnone"] = "Ничего"
LR["rcondition"] = "Да-Нет Условие"
LR["rfind"] = "Найти"
LR["rreplace"] = "Заменить"
LR["rsetsave"] = "Сохранить"
LR["rsetload"] = "Загрузить"

LR["rtimeLeftTip"] = "|cffffff00{timeLeft|cff00ff00x|r:|cff00ff00y|r}|r\nОставшееся время триггера,\n|cff00ff00x|r - номер триггера (необязательно)\n|cff00ff00y|r - количество десятичных знаков"
LR["rActiveTimeTip"] = "|cffffff00{activeTime|cff00ff00x|r:|cff00ff00y|r}|r\nАктивное время триггера,\n|cff00ff00x|r - номер триггера (необязательно)\n|cff00ff00y|r - количество десятичных знаков"
LR["rActiveNumTip"] = "|cffffff00{activeNum}|r\nКоличество активных триггеров"
LR["rMinTimeLeftTip"] = "|cffffff00{timeMinLeft|cff00ff00x|r:|cff00ff00y|r}|r\nПоказывает минимальное оставшееся время среди активных триггеров или активных статусов внутри триггера\n|cff00ff00x|r - номер триггера (необязательно)\n|cff00ff00y|r - количество десятичных знаков"
LR["rTriggerStatusTip"] = "|cffffff00{status:|cff00ff00x|r:|cff00ff00guid|r}|r\nПоказывает текущий статус guid внутри триггера, |cff00ff00on|r если активен, |cff00ff00off|r иначе\n|cff00ff00x|r - номер триггера\n|cff00ff00guid|r - guid триггера"
LR["rTriggerStatus2Tip"] = "|cffffff00%status|cff00ff00x|r|r\nПоказывает текущий статус триггера, |cff00ff00on|r если активен, |cff00ff00off|r иначе\n|cff00ff00x|r - номер триггера"
LR["rAllSourceNamesTip"] = "|cffffff00%allSourceNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\nПоказывает имена всех источников,\n|cff00ff00x|r - номер триггера (необязательно)\nможно ограничить источники от |cff00ff00num1|r до |cff00ff00num2|r,\n|cff00ff00pat|r = 1 делает имена безцветными, другие значения заменяют имена на самих себя"
LR["rAllTargetNamesTip"] = "|cffffff00%allTargetNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\nПоказывает имена всех целей,\n|cff00ff00x|r - номер триггера (необязательно)\nможно ограничить цели от |cff00ff00num1|r до |cff00ff00num2|r,\n|cff00ff00pat|r = 1 делает имена безцветными, другие значения заменяют имена на самих себя"
LR["rAllActiveUIDsTip"] = "|cffffff00%allActiveUIDs|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r|r\nПоказывает все активные GUID,\nможно ограничить GUID от |cff00ff00num1|r до |cff00ff00num2|r\n|cff00ff00x|r - номер триггера (необязательно)"
LR["rTriggerActivationsTip"] = "|cffffffff|cffffff00{triggerActivations:|cff00ff00x|r}|r\nКоличество активаций триггера\n|cff00ff00x|r - номер триггера"
LR["rRemActivationsTip"] = "|cffffffff|cffffff00{remActivations}|r\nКоличество активаций ремайндера"

LR["rcounterTip"] = "|cffffff00{counter|cff00ff00x|r:|cff00ff00y|r}|r\nТекущий номер каста\n|cff00ff00x|r - номер триггера (необязательно),\n|cff00ff00y|r можно указать для зацикливания счетчика после |cff00ff00y|r кастов.\nПример: {counter:3} - 1, 2, 3, 1, 2, 3, 1, 2, 3..."

LR["rspellIconTip"] = "|cffffff00{spell:|cff00ff00id|r:|cff00ff00size|r}|r\n|cff00ff00id|r - ID заклинания\n|cff00ff00size|r - размер иконки (необязательно)"
LR["rclassColorTip"] = "|cffffff00%classColor |cff00ff00Name|r|r\nОкрашивает |cff00ff00Name|r в цвет класса"
LR["rspecIconTip"] = "|cffffff00%specIcon |cff00ff00Name|r|r\nОтображает иконку роли для |cff00ff00Name|r"
LR["rclassColorAndSpecIconTip"] = "|cffffff00%specIconAndClassColor |cff00ff00Name|r|r\nПоказывает иконку роли и окрашивает |cff00ff00Name|r в цвет класса"

LR["rsetparamTip"] = "|cffffff00{setparam:|cff00ff00key|r:|cff00ff00value|r}|r\nУстанавливает локальную переменную |cff00ff00key|r для текущего ремайндера,\nвы можете вызвать ее позже с {#|cff00ff00key|r}"
LR["rmathTip"] = "|cffffff00{math:|cff00ff00x+y-zf|r}|r\nгде |cff00ff00x y z|r - числа в математическом вычислении,\nоператоры + - * / %(остаток)\nf - режим округления\nf - к меньшему значению\nc - к большему значению\nr - к ближайшему значению"
LR["rnotelineTip"] = "|cffffff00{noteline:|cff00ff00patt|r}|r\nСтрока из заметки, начинающаяся с |cff00ff00patt|r"
LR["rnoteTip"] = "|cffffff00{note:|cff00ff00pos|r:|cff00ff00patt|r}|r\nСлово из строки заметки\n|cff00ff00pos|r - порядковый номер слова в строке\n|cff00ff00patt|r - начало строки для поиска в заметке\n\nПозиции в заметке цикличны\nнапример всего 5 слов в заметке, |cff00ff00pos|r = 7, тогда будет показано 2 слово"
LR["rnoteposTip"] = "|cffffff00{notepos:|cff00ff00y|r:|cff00ff00x|r}|r\nПоказывает игрока из строки заметки, начинающейся с шаблона заметки для текущего ремайндера (должен содержать параметр {pos}, читайте вкладку \"Помощь\" для получения дополнительной информации)\n|cff00ff00y|r - позиция строки в \"блоке заметок\" или позиция игрока в \"строке заметок\",\n|cff00ff00x|r - позиция игрока в строке |cff00ff00y|r для \"блок заметок\".\nЕсли |cff00ff00x|r опущен в \"блоке заметок\", то показывает всю строку"
LR["rminTip"] = "|cffffff00{min:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r - числа\nмогут быть разделены |cff00ff00;|r или |cff00ff00,|r"
LR["rmaxTip"] = "|cffffff00{max:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r - числа\nмогут быть разделены |cff00ff00;|r или |cff00ff00,|r"
LR["rroleTip"] = "|cffffff00{role:|cff00ff00name|r}|r\n|cff00ff00name|r - имя игрока, для которого вы хотите показать роль\nроли: tank, healer, damager, none"
LR["rextraRoleTip"] = "|cffffff00{roleextra:|cff00ff00name|r}|r\n|cff00ff00name|r - имя игрока, для которого вы хотите показать дополнительную роль\nдоп. роли: mdd, rdd, mhealer, rhealer, none"
LR["rsubTip"] = "|cffffff00{sub:|cff00ff00pos1|r:|cff00ff00pos2|r:|cff00ff00text|r}|r\nпоказывает |cff00ff00text|r начиная с pos1 и заканчивая на pos2"
LR["rtrimTip"] = "|cffffff00{trim:|cff00ff00text|r}|r\n|cff00ff00text|r - текст, из которого вы хотите убрать пробелы"

LR["rnumTip"] = "|cffffff00{num:|cff00ff00x|r}|cff00ff00a;b;c;d|r{/num}|r\nВыбирает строку под номером |cff00ff00x|r где |cff00ff00a|r - 1 |cff00ff00b|r - 2 |cff00ff00c|r - 3 |cff00ff00d|r - 4\n\nПример: |cff00ff00{num:%counter2}Лево;Право;Вперед{/num}|r"
LR["rupTip"] = "|cffffff00{up}|cff00ff00string|r{/up}|r\nПоказывает |cff00ff00string|r в ВЕРХНЕМ РЕГИСТРЕ"
LR["rlowerTip"] = "|cffffff00{lower}|cff00ff00STRING|r{/lower}|r\nПоказывает |cff00ff00string|r в нижнем регистре"
LR["rrepTip"] = "|cffffff00{rep:|cff00ff00x|r}|cff00ff00line|r{/rep}|r\nПовторяет |cff00ff00line|r |cff00ff00x|r раз"
LR["rlenTip"] = "|cffffff00{len:|cff00ff00x|r}|cff00ff00line|r{/len}|r\nОграничивает длину |cff00ff00line|r до |cff00ff00x|r символов"
LR["rnoneTip"] = "|cffffff00{0}|cff00ff00line|r{/0}|r\nПоказывает пустую строку"
LR["rconditionTip"] = ("|cffffff00{cond:|cff00ff001<2 AND 1=1|r}|cff00ff00да;нет|r{/cond}|r\nБудет показано как сообщение \"да\", если условия совпадают, или сообщение \"нет\", если они не совпадают.\nПример: |cff00ff00{cond:%targetName=$PN$}solo;soak{/cond}|r\n\nМожно использовать несколько условий (будет выбрано любое успешное)\n|cff00ff00{cond:condition1=condition2;condition3;condition4}да;нет{/cond}|r\n\nДля числовых сравнений можно использовать знаки больше или меньше\nПример: |cff00ff00{cond:%health<20}ДПС;СТОП ДПС{/cond}|r\n\nВы можете использовать несколько условий, разделенных словами |cff00ff00AND|r и |cff00ff00OR|r\nПримеры:\n|cff00ff00{cond:%health<20 OR %health>80}EXECUTE{/cond}|r\n|cff00ff00{cond:%playerClass=shaman AND %playerSpec=restoration}RSHAM;NOT RSHAM{/cond}|r"):gsub("%$PN%$",UnitName("player"))
LR["rfindTip"] = "|cffffff00{find:|cff00ff00patt|r:|cff00ff00text|r}|cff00ff00да;нет|r{/find}|r\nНаходит patt в text. Показывает да или нет в зависимости от того, найдено совпадение или нет"
LR["rreplaceTip"] = "|cffffff00{replace:|cff00ff00x|r:|cff00ff00y|r}|cff00ff00text|r{/replace}|r\nЗаменяет x на y в тексте"
LR["rsetsaveTip"] = "|cffffff00{set:|cff00ff001|r}|cff00ff00text|r{/set}|r\nСохраняет текст под ключом '|cff00ff001|r'"
LR["rsetloadTip"] = "|cffffff00%set|cff00ff001|r|r\nЗагружает текст под ключом, в этом примере ключ '|cff00ff001|r'"

LR.LastPull = "Последний пулл"

LR.copy = "Не скрывать дубликаты"
LR.copyTip = "Если ремайндер активируеться когда уже активен то будет появляться его дубликат"

LR.norewrite = "Не перезаписывать"
LR.norewriteTip = "Если ремайндер активируеться когда уже активен то дубликат не будет перезаписывать первую итерацию"

LR.dynamicdisable = "Откл. динамическое обновление"
LR.dynamicdisableTip = "Динамические замены текстов будут обновлять информацию только в момент появления ремайндера"

LR.isPersonal = "Не отправлять ремайндер"
LR.isPersonalTip = "Сделать ремайндер персональным, его нельзя будет отправить другим игрокам"

LR["AdditionalOptions"] = "Доп. Параметры:"
LR["Show Removed"] = "Показать корзину"

LR.Zone = "Инстанс:"
LR.ZoneID = "ID Инстанса:"
LR.ZoneTip = "Не путать с ID зоны, инстанс это отдельный континент или подземелье/рейд"

LR.searchTip = "Ищет совпадения в имени босса, названии, сообщении, сообщении для чата, text to speech, тексте на неймплейте и загрузке по имени"
LR.search = "Поиск"

LR.BossKilled = "Босс убит"
LR.BossNotKilled = "Босс не убит"

LR["Raid group number"] = "Номер рейдовой группы"

LR["GENERAL"] = "ОБЩЕЕ"
LR["LOAD"] = "ЗАГРУЗКА"
LR["TRIGGERS"] = "ТРИГГЕРЫ"
LR["OTHER"] = "ДРУГОЕ"

LR["doNotLoadOnBosses"] = "Не загружать\nна боссах"

LR["specialTarget"] = "Определенная цель:"
LR["specialTargetTip"] = "Собественный юнит цели. Используется для выбора цели подсветки неймплейта если автовыбор не подходит.\nИмя игрока или любой unitID.\nМожно использовать заменители %source1, %target3 для выбора юнита из определенного триггера.\nМожно использовать опции форматирования"
LR["extraCheck"] = "Доп. условие активации:"

LR.sametargets = "Одинаковая цель триггеров"
LR.sametargetsTip = "Будет показан только если у всех триггеров (если больше их 1) совпадающий юнит"

LR.NameplateGlowTypeDef = "По умолчанию"
LR.NameplateGlowType1 = "Pixel Glow"
LR.NameplateGlowType2 = "Action Button Glow"
LR.NameplateGlowType3 = "Auto Cast Shine"
LR.NameplateGlowType4 = "Proc Glow"

LR["AIM"] = "Прицел"
LR["Solid color"] = "Цельный цвет"
LR["Custom icon above"] = "Иконка сверху"
LR["% HP"] = "% HP"

LR["glowType"] = "Тип свечения:"
LR["glowColor"] = "Цвет свечения:"
LR["glowThick"] = "Толщина свечения:"
LR["glowThickTip"] = "Толщина пиксельной подсветки (по умолчанию 2)"
LR["glowScale"] = "Scale свечения:"
LR["glowScaleTip"] = "Scale свечения (по умолчанию 1)"
LR["glowN"] = "Число свечения:"
LR["glowNTip"] = "Количество частиц пиксельной подсветки или подсветки автокаст (по умолчанию 4 для автокаст и 8 для пиксельной)"
LR["glowImage"] = "Изображение:"
LR.glowImageCustom = "Свое изображение:"

LR["glowOnlyText"] = "Только текст"
LR["glowOnlyTextTip"] = "Показывать только текст, без подсветки"

LR["nameplateGlow"] = "Подсветка неймплейта:"
LR["nameplateGlowTip"] = "Подсвечивает неймплейт по юниту триггера"
LR["UseCustomGlowColor"] = "Cвой цвет подсветки"

LR["On-Nameplate Text:"] = "Текст на неймплейте:"

LR.CurrentTriggerMatch = "Только совпадения с текущим триггером"

LR.SyncAllConfirm = "Вы уверены что хотите отправить все ремайндеры?"

LR.noteIsBlock = "Заметка это блок"
LR.noteIsBlockTip = "Поик по шаблону заметки будет произовидться внутри блока от patStart до patEnd.\nПример:\n\n\npatStart\nМишок Амби\nПауэл Кройфель\nНимб Ловес\npatEnd"

LR["Tip!"] = "Подсказка!"

LR["GeneralBFTip"] = "|cffffffffЗагрузка по боссу/интсансу работает в режиме ИЛИ т.е.\nесли указан и босс и инстанс то достаточно одного\nсовпадения что бы ремайндер загрузился."
LR["LoadBFTip"] = [[|cffffffffЗагрузку можно производить по следующим условиям: Класс, роль, номер группы, ник, по заметке.
Внутри каждого условия должно встречаться хотя бы одно совпадение, т.е. логика ИЛИ.

Например загрузка для классов Воин, Паладин.
    - Если игрок воин или паладин то ремайндер загрузиться.

При использовании нескольких условий загрузки, ремайндер будет
загружен если выполняються все условия, т.е. логика И.

Например загрузка для классов Воин, Паладин и роли Танк.
    - Если игрок воин или паладин и танк то ремайндер загрузиться.
    - Если игрок воин или паладин и не танк то ремайндер не загрузиться.

Cм. вкладку Помощь для информации про загрузку по заметке.]]

LR["TriggerBFTip"] = [[|cffffffffЕсли длительность ремайндера будет равна 0 то он будет считаться untimed
и будет показываться пока выполняються условия активации ремайндера.

Некоторые триггеры могут быть untimed, т.е. не иметь конкретной длительности(если такова не указана).
Примеры:
    - Триггер Фаза босса будет активен пока босс находиться в указаной фазе.
    - Триггер здоровье юнита будет активен пока юнит находиться в указаном диапазоне здоровья.
    - Триггер журнала боя не может быть untimed, поэтому в untimed ремайндерах для
      триггеров журнала боя нужно всегда указывать длительность активации.
]]

LR.Snippets = "Шаблоны"
LR.ShowSnippets = "Показать шаблоны"
LR.SaveCurrent = "Сохранить текущий"

LR.Comment = "Комментарий:"

LR["Last Sync:"] = "Последнее обновление: "
LR["Never"] = "Никогда"
LR["New Update"] = "Новое обновление"
LR["Update last sync time"] = "Обновить дату последнего обновления.\n\nЕсли у получателя дата последнего обновления будет больше или равна вашей то он не получит обновление"
LR["Send to:"] = "Отправить:"
LR["CustomReceiverTip"] = "Отправить WA конкретному игроку"
LR["Import Mode:"] = "Режим импорта:"

LR.DefText = "Обычный текст"
LR.BigText = "Увеличенный текст"
LR.SmallText = "Уменьшенный текст"

LR["Big Font Size"] = "Размер увеличенного текста"
LR["Normal Font Size"] = "Размер обычного текста"
LR["Small Font Size"] = "Размер уменьшенного текста"

LR["10 Player Raid"] = "Рейд на 10 игроков"
LR["10 Player Raid (Heroic)"] = "Рейд на 10 игроков (героический)"
LR["10 Player Raid (Normal)"] = "Рейд на 10 игроков (обычный)"
LR["20 Player Raid"] = "Рейд на 20 игроков"
LR["25 Player Raid"] = "Рейд на 25 игроков"
LR["25 Player Raid (Heroic)"] = "Рейд на 25 игроков (героический)"
LR["25 Player Raid (Normal)"] = "Рейд на 25 игроков (обычный)"
LR["40 Player Raid"] = "Рейд на 40 игроков"
LR["Raid"] = "Рейд"
LR["Raid (Heroic)"] = "Героический рейд"
LR["Raid (Mythic)"] = "Эпохальный рейд"
LR["Raid (Normal)"] = "Обычный рейд"
LR["Raid (Timewalking)"] = "Рейд (путешествие во времени)"
LR["Looking for Raid"] = "Поиск рейда"
LR["Legacy Looking for Raid"] = "Поиск рейда (до патча 5.4)"
LR["Dungeon (Heroic)"] = "Подземелье (героическое)"
LR["Dungeon (Mythic)"] = "Подземелье (эпохальное)"
LR["Dungeon (Mythic+)"] = "Подземелье (М+)"
LR["Dungeon (Normal)"] = "Подземелье (обычное)"
LR["Dungeon (Timewalking)"] = "Подземелье (путешествие во времени)"
LR["Mythic Keystone"] = "Эпохальный ключ"
LR["Scenario (Heroic)"] = "Сценарий (героический)"
LR["Scenario (Normal)"] = "Сценарий (обычный)"
LR["Island Expedition (Heroic)"] = "Островная экспедиция (героическая)"
LR["Island Expedition (Mythic)"] = "Островная экспедиция (эпохальная)"
LR["Island Expedition (Normal)"] = "Островная экспедиция (обычная)"
LR["Island Expeditions (PvP)"] = "Островная экспедиция (PvP)"
LR["Warfront (Heroic)"] = "Фронт (героический)"
LR["Warfront (Normal)"] = "Фронт (обычный)"
LR["Visions of N'Zoth"] = "Видения Н'Зота"
LR["Torghast"] = "Торгаст"
LR["Path of Ascension: Courage"] = "Путь Перерождения: Отвага"
LR["Path of Ascension: Humility"] = "Путь Перерождения: Смирение"
LR["Path of Ascension: Loyalty"] = "Путь Перерождения: Верность"
LR["Path of Ascension: Wisdom"] = "Путь Перерождения: Мудрость"
LR["Normal Party"] = "Группа (обычная)"
LR["Heroic Party"] = "Группа (героическая)"

LR["CUSTOM"] = "CUSTOM"

LR["Now"] = "Сейчас"

LR["Show On Ready Check"] = "Показывать во время проверки готовности"
LR["Dont Show On Mythic"] = "Не показывать в мифике"

LR["Hold shift while opening to show full encounters list"] = "Зажмите shift при открытии для\nпоказа полного списка боссов"

LR["errorLabel1"] = "Ошибка в ремайндере."
LR["errorLabel2"] = "Пожалуйста, отправьте Мишку ошибку ниже."
LR["errorLabel3"] = "Press CTRL + C to copy!"
LR["copiedToClipboard"] = "скопировано!"
LR["Copy error"] = "Скопировать ошибку"

LR["ChooseEncounter"] = "Выберите босса"

LR["Save history between sessions"] = "Сохранять историю между сессиями"
LR["May cause fps spike on end of the boss fight"] = "|cffff0000Может вызвать просадку FPS после боя с боссом|r"

LR["Amount of pulls to save\nper boss and difficulty"] = "Количество пуллов для сохранения\nдля каждого босса и сложности"

LR["Any Click:"] = "Любой клик:"
LR["Normal Click:"] = "Обычный клик:"
LR["Shift Click:"] = "Shift клик:"
LR["Ctrl Click:"] = "Ctrl клик:"
LR["Difficulty:"] = "Сложность:"
LR["Spells Blacklist"] = "Черный список"
LR["Add to blacklist: "] = "Добавить в черный список: "
LR["|cffff8000Shift click to remove from blacklist|r"] = "|cffff8000Shift клик для удаления из черного списка|r"
LR["|cffff8000Shift click to delete|r"] = "|cffff8000Shift клик что-бы удалить|r"
LR["Filters"] = "Фильтры"
LR["Filters ignored because of trigger:"] = "Фильтры игнорируемые из-за триггера:"
LR["|cffff8000Trigger reset|r"] = "|cffff8000Сброс триггера|r"
LR["Use source counters"] = "Использовать счетчики по источнику"

LR["Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"] = "Включить передачу истории для игроков вне рейдового подземелья и принимать историю передающуюся для таких игроков"
LR["History transmission"] = "Включить передачу истории"

LR["Accept Reminders while not in a raid group"] = "Принимать ремайндеры вне рейдовой группы"
LR["Alternative color scheme for reminders list"] = "Альтернативная цветовая схема для списка ремайндеров"
LR["Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"] = "Использование сжатия для хранения больших объемов данных. Возможно исопльзование больших объемов памяти при взаимодействии с окном истории"

LR["Aura not updated"] = "Аура не обновлена"
LR["Aura updated"] = "Аура обновлена"
LR["User didn't respond"] = "Игрок не ответил"

LR.WASyncLineNameTip1 = "Клик на линию для проверки наличия WA у игрока\nПравый клик для открытия конекстного меню"
LR.WASyncLineNameTip2 = "Клик на линию для проверки версии аддона WeakAuras"
LR["Left Click to share"] = "Левый клик для открытия меню отправки"
LR["Right Click to check versions"] = "Правый клик для проверки версии"
LR["Pressing while holding |cff00ff00shift|r will add WA to queue but wont start sending\n\nPressing while holding |cff00ff00alt|r will not update last sync time for current WA(ignoring checkbox)\n\nPressing while holding |cff00ff00ctrl|r will start sending WAs added to queue"] = "Нажатие при зажатом |cff00ff00shift|r добавит WA в очередь но не начнет отправку\n\nНажатие при зажатом |cff00ff00alt|r не обновит дату последнего обновления для текущей WA(игнорирует чекбокс)\n\nНажатие при зажатом |cff00ff00ctrl|r начнет отправку WA добавленных в очередь"

LR["Load Current Note"] = "Загрузить текущую заметку"
LR["Analyze Highlighted Text"] = "Анализировать выделенное"
LR["Analyze All/Highlighted Text"] = "Анализировать все/выделенное"
LR["Send Note"] = "Отправить заметку"
LR["Note is empty. Probably a bug?"] = "Заметка пуста. Возможно это баг?"
LR["Groups:"] = "Группы:"
LR["Replace only in highlighted text"] = "Заменять только в выделенном"
LR["Allow numbers in names"] = "Разрешить цифры в именах"
LR["Allow non letter symbols in names"] = "Разрешить символы в именах"
LR["Non letter symbols are:"] = "Символы это:"
LR["Allow # symbol in names"] = "Разрешить символ # в именах"

LR["Shift click to use default glow color"] = "Shift клик что-бы использовать цвет свечения по умолчанию"
LR["Player names to glow\nMay use many separated by\nspace comma or semicolomn"] = "Имена игроков для свечения\nМожно использовать несколько, разделенные\nпробелом, запятой или точкой с запятой"

LR["For untimed reminders use {timeLeft} text replacer"] = "Для untimed ремайндеров используйте шаблон замены текста {timeLeft}"

LR["Hisory recording disabled"] = "Запись истории отключена"

LR["onlyPlayerTip"] = "Счетчик делает +1 только, если условия триггеров соблюдены (включая условия источника/цели).\nВключите эту опцию, если хотите, чтоб счетчик всегда срабатывал для всех доступных целей, но при этом триггер станет активным только тогда, когда целью будет сам игрок."
LR["invertTip"] = "Инвертирует состояние триггера требуемое\nдля активации ремайндера"

LR["Marked To Send"] = "Отмечено для отправки"
LR["Was ever sent"] = "Была когда либо отправлена"
LR["Updated less then 2 weeks ago"] = "Обновлялась менее 2 недель назад"

LR["send"] = "отправка"
LR["delete"] = "удаление"

LR["rtextNote"] = "Уведомление/иконки"
LR["rtextNoteTip"] = "3 иконки если уведомление содержит только иконку\nв другом случае просто уведомление"

LR["rtextModIcon"]= "Уведомление/иконки с модификатором"
LR["rtextModIcon:X:Y"] = LR["rtextModIcon"]
LR["rtextModIconTip"] = "Тоже самое что и \"Уведомление/иконки\" но с дополнительными настройками\n\n|cffffff00{textModIcon:|cff00ff00X|r:|cff00ff00Y|r:|cff00ff00patt|r}|r\n|cff00ff00X|r - размер иконок\n|cff00ff00Y|r - количество иконок\n|cff00ff00patt|r - условие\nЕсли указано условие то размер и количество иконок применяться только в случае если в уведомлении найдено совпадение по шаблону, можно указывать несколько шаблонов через ;(точку с запятой).\nПример: |cff00ff00{textModIcon:25:4:6442;1022;Personals|r}|r"

LR["Note timers"] = "Таймеры заметки"
LR["Note timers [all]"] = "Таймеры заметки (все)"

LR["rfullLine"] = "Полная строка"
LR["rfullLineClear"] = "Полная строка без {}"
LR["MRTNoteTimersComment"] = "Ремайндер будет показывать сейвы из заметки подобно вашке Kaze MRT Timers.\n\nУстановите загрузку для конкретного инстанса что бы ремайндер не показывался в данжах.\nСовместимо с автоматически сгенерироваными заметками Viserio.\n\nПо дефолту этот шаблон делает ремайндер персональным, т.е. он не будет отправляться другим игрокам."

LR["Send All (This Zone)"] = "Отправить (эта зона)"
LR["Current difficulty:"] = "Текущая сложность:"

LR["ZoneIDTip1"] = "Оставить пустым для игнорирования\nМожно несколько через запятую\nТекущий инстанс: "
LR["ZoneIDTip2"] = "\nID текущего инстанса: "
LR["Current instance"] = "Текущий инстанс"
LR["Current difficulty"] = "Текущая сложность"

LR.OutdatedVersionAnnounce = "Ваша версия %q устарела. Пожалуйста обновитесь до последней версии.\n\nПоследняя версия: %s\nВаша версия: %s"

LR["Text color"] = "Цвет текста"

LR.Alert = "Внимание!"
LR.AlertFieldReq = "Нужно обязательно заполнить это поле для работы триггера"
LR.AlertFieldSome = "Нужно обязательно заполнить одно из указанных полей для работы триггера"

LR.TriggerOptionsGen = "Общие настройки триггеров"
LR.TriggerTipIgnored = "Триггер %s игнорируется"
LR.SpellIDBWTip = "SpellID которое используется аддоном BigWigs/DBM.\nВы можете найти эти spellID на странице босса BW/DBM\nСверху справа в окне найстроки конкретной способности"

LR["No Mark"] = "Без метки"

LR["ActionDelete"] = "удалить ремайндеры"
LR["ActionSend"] = "принять ремайндеры"

LR.msgSize = "Тип сообщения:"

LR.LoadAlert1 = "Не установлены условия загрузки"
LR.LoadAlert2 = "Возможно вам стоит установить загрузку по боссу, зоне или сложности"
LR.tts = "Text To Speech:"
LR.glow = "Подсветка Фрейма:"

LR["Setup trigger"] = "Настройка триггера"

LR["Required fields must be filled:"] = "Обязательные поля должны быть заполнены:"
LR["Any of those fields must be filled:"] = "Любое из этих полей должно быть заполнено:"

LR["Available replacers:"] = "Доступные шаблоны замены текста:"
LR["Detach"] = "Открепить"

LR["BWEnableTip1"] = "Замена модуля босса отключена. \"/reload\" чтоб вернуть изначальное состояние модуля"
LR["BWModName"] = "Название модуля для босса"
LR["BWSelectBoss"] = "Выбрать босса"
LR["BWAddOptions"] = 'Дополнительные параметры'

LR["Update inviters list"] = "Обновить список инвайтеров"

LR.RGList = "RG Список:"
LR.RGConditions = "Условие для списка:"
LR.RGConditionsTip = "|cffffffffМожет принимать несколько значений, достаточно пройти\nпо одному из них что бы ремайндер загрузился.\n|cffffff00x-y|r ренж игроков, если игрок находится в списке между x и y то он прошел\n|cffffff00x%y|r - каждый y, начиная с x\n|cffffff00x/y|r - лист делиться на y частей, условие проходит если игрок в x части\n|cffffff00Rx|r - начинает отсчет с конца|r"
LR.RGOnly = "Только RG игроки"
LR.RGOnlyTip = "Список только из игроков которые находяться в RGDB"

LR.SplitsWrongChar = "Не на том чаре:"
LR.SplitsNotInRaid = "Не в рейде:"
LR.SplitsNotInTheList = "Не в списке:"
LR.SplitsLastImport = "Последний импорт был сделан"
LR.SplitsShouldNotBeInRaid = " не должен быть в рейде:"

LR.AssignmentsListID = "ID списка"
LR.AssignmentsHelpTip = "Приоритет:\nНик > Кастом Условие > Алиас > Спек > Класс > Под Роль(мили/ренж) > Роль > Остальные"
LR.AssignmentsAutoSendTip = "Автоматически отправлять список"
LR.AssignmentsTestTip = "Обычный клик для теста приоритета\nShift клик для теста списка\nAlt клик для теста с игроками из RGDB в первую очередь"
LR.AssignmentsAutoSendEditTip = [=[|cffffffffАвтоматически отправлять список при
проверке готовности или смене зоны.

Текущая зона
|cff55ee55%s %s|r

Текущая группа зон:
|cff55ee55%s %s|r

Текущая родительская зона:
|cff55ee55%s %s|r

Текущий инстанс:
|cff55ee55%s %s|r

Текущая область:
|cff55ee55%s %s|r

To include child zone ids, prefix with 'c', e.g. 'c2022'.
Group Zone IDs must be prefixed with 'g', e.g. 'g277'.
Supports Area IDs from https://wago.tools/db2/AreaTable prefixed with 'a'.
Supports Instance IDs prefixed with 'i'.
Supports Encounter IDs prefixed with 'b', depends on BigWigs]=]
LR.AssignmentsIgnoreValidationTip = "Игнорировать проверку списка перед авто отправкой"
LR["NotTank"] = "Не танк"
LR["Copy trigger"] = "Копировать триггер"
LR["Use TTS files if possible"] = "Использовать TTS файлы если возможно"
LR["Categories to ignore when importing:"] = "Категории игнорируемые при импорте:"
LR.Focus = "Фокус"
LR["Restore"] = "Восстановить"

LR["You are not Raid Leader or Raid Assistant"] = "Вы не лидер или помощник рейда"
LR["Not Raid Leader or Raid Assistant"] = "Не лидер или помощник рейда"
LR.WASyncUpdateSkipTitle = "ВЫ ТОЧНО УВЕРЕНЫ ЧТО ХОТИТЕ ОТКАЗАТЬСЯ ОТ ОБНОВЛЕНИЯ?"
LR.Skip = "Пропустить"
LR.WASNoPermission = "%s пытается отправить WA. %s"

LR.TriggersCount = "Количество триггеров"

LR.WASyncVersionCheck = "Проверить версии"
LR.WASyncWACheck = "Проверить наличие WA"
LR.WASyncWACheckTip = "Срабатывает и для тех у кого нет WA Sync"
LR.WASyncLinkToChat = "Линкануть в чат"
LR.WASyncMarkToSend = "Отметить для отправки"
LR.WASyncUnmarkToSend = "Снять отметку для отправки"
LR.WASyncMarkToSendTip = "Используется для поиска по ключевому слову"
LR.WASyncShowInWA = "Показать в WeakAuras"
LR.WASyncShowInWATip = "Не будет выбирать WA если окно WeakAuras не было открыто хотя бы раз в этой сессии"

LR.WASyncReloadPrompt = "%s просит вас сделать Reload UI"
LR["Ask for Reload UI after import"] = "Запросить Reload UI после импорта"
LR.WASyncKeywordToSendTip = "Шифт клик что-бы запросить версии\nдля всех ВА отмеченных для отправки"

LR.barTicks = "Тики на полосе:"
LR.barTicksTip = "Позиция тиков на полосе\nПример:\n3\n2, 5, 8"
LR.barColor = "Цвет полосы:"
LR.barIcon = "Иконка полосы:"
LR.barIconTip = "Иконка для полосы, используйте 0 для автоматической иконки из триггеров\nиспользуйте spellID для конкретной иконки"
LR.barWidth = "Ширина:"
LR.barHeight = "Высота:"
LR.barTexture = "Текстура:"
LR.barFontTip = "Тень и обводка следуют настройкам текстовых ремайндеров"
LR["Progress Bar"] = "Полоса прогресса"
LR["Small Progress Bar"] = "Маленькая полоса прогресса"
LR["Big Progress Bar"] = "Большая полоса прогресса"

LR["RGASSrefreshTooltip"] = "Сбросить все изменения и обновить список"

LR.hideTextChanged = "Скрыть после\nизменения статуса:"
LR.hideTextChangedTip = "Позволяет сделать ремайндер с заданной длительностью полу-untimed.\n\nРемайндер скроется по завершению длительности или при изменении статуса триггеров."
LR.timeLineDisable = "Не показывать на таймлайне"
LR.durationReverse = "Показать заранее"
LR.durationReverseTip = "Показать сообщение до назначеного времени на заданную длительность (если это возможно)"
LR.TEST = "ТЕСТ"
LR.StartTestFight = "Начать тестовый бой"
LR.OnlyMine = "Только мои"
LR.ImportHistory = "Импорт истории заклинаний"
LR.ExportHistory = "Экспорт истории заклинаний"
LR.FromHistory = "Из истории"
LR.Custom = "Собственное"
LR.CustomSpell = "Собственное заклинание:"
LR.PlayerNames = "Имена игроков"
LR.PlayerNamesTip = "Имена игроков через пробел"
LR.ShowFor = "Показывать для:"
LR.Spell = "Заклинание"
LR.HideMsgCheck = "Скрыть сообщение после использования заклинания\nНе показывать, если заклинание на кд"
LR.AdjustFL = "Масштабировать бой"
LR.CopyPrev = "Скопировать из прошлого сохраненного"
LR.Main = "Основное"
LR["rshortnum"] = "Сокращенное число"
LR["rshortnumTip"] = [[Сокращает числа. Примеры:
15.69 16
156.9 157
1569 1.6K
15690 15.7K
156900 156.9K
1569000 1.6M
15690000 15.7M
156900000 156.9M
1569000000 1.6B
15690000000 15.7B
156900000000 156.9B
1569000000000 1569B
15690000000000 1569B
]]
LR.TimerExcluded = "Включить выравнивание таймера"
LR.TimerExcludedTip = "Учитывать таймер обратного отсчета при выравнивании ремайндера.\n\nВыключите если хотите что-бы текст перестал трястись при обновлении таймера."
LR["QS_20"] = "Старт М+"
LR.StartTestFightTip = "Работает только для ремайндеров с триггером \"Пулл босса\", \"Фаза босса\" и \"Старт М+\""

LR.GlobalTimeScale = "Глобальный масштаб времени"
LR.TimeScaleT1 = "На"
LR.TimeScaleTip1  = "Можно использовать формат времени (5:25)"
LR.TimeScaleT2 = "сек. +  "
LR.TimeScaleT3 = "сек."
LR.TimeScaleTip2 = "Может быть отрицательным"
LR.FilterCasts = "Касты"
LR.FilterAuras = "Ауры"
LR.PresetFilter = "Предустановленный фильтр босса"
LR.RepeatableFilter = "Повторяющиеся заклинания"
LR.RepeatableFilterTip = "Показывать отдельную кнопку ремайндера для каждого заклинания, если исполользуется продвинутое условие счетчика.\nС выключеным фильтром будут показаны только ремайндеры для заклинаний с указанным единственным номером."
LR.Boss2 = "Босс"
LR.AdvancedEdit = "Расширенные настройки"
LR.HideOne = "Скрыть ремайндер"
LR.HideOneTip = "Скрыть этот рамаиндер до смены босса.\n(Будет помещен в меню \"Без категории\")"
LR.CustomDurationLen = "Задать свою длительность"
LR.ChangeColorRng  = "Изменить цвет (случайный)"
LR.ImportAdd = "Добавить в ремайндеры"
LR.AdjustFL = "Масштабировать бой"
LR.MRTOUTDATED = "Модуль |cffffce00%s|r требует |cffffce00Method Raid Tools|r версии |cffff0000%s|r или выше. Пожалуйста, обновите MRT для использования этого модуля.\n\nВы можете сделать это с помощью CurseForge или другого установщика аддонов."
LR.SearchStringTip = "Используйте \"|cff00ff00=|r\" в начале для точного совпадения."
LR["Send All"] = "Отправить все"
LR["Send all lists that have auto send enabled"] = "Отправить все списки с включенной автоотправкой"
LR["Copy list"] = "Копировать список"
LR["Add new"] = "Добавить новый"
LR["Delete list"] = "Удалить список"
LR.ImportTextFromNote = "Скопировать текущий текст из заметки"
LR.DurRevTooltip2 ="Сообщение будет показано за 3 секунды до окончания таймера.\nЕсли эта опция отключена - сообщения будут показаны сразу по истечению таймера."
LR.RemoveBeforeExport = "Удалить текущие ремайндеры"
LR.RemoveBeforeExportTip = "Удалены будут все ремайндеры, которые сейчас отображаются на полоске"
LR.ForEveryPlayer = "Для каждого игрока отдельно"
LR.ForEveryPlayerTip = "Добавить отдельный ремайндер для каждого игрока в строке"
LR.ImportNameAsFilter = "Использовать имена как фильтр"
LR.ImportNameAsFilterTip = "Для заметок вида: заклинание - имя имя имя.\nНовый ремайндер будет создан, но показан только выбранным игрокам"
LR.ImportNoteWordMy = "Использовать только 1 слово после моего имени для сообщения"
LR.ImportNoteLinesMy = "Строки только с моим именем"
LR.ImportFromNote = "Импорт из заметки"
LR.Undo = "Отменить"
LR.UndoTip = "Удалить только что добавленые ремайндеры"
LR.AssignmentsConditionTip = [[|cffffffffname - имя игрока
role1 - основная роль (TANK, HEALER, DAMAGER)
role2 - дополнительная роль (MHEALER, RHEALER, MDD, RDD)
alias - псевдоним игрока
class - класс игрока (WARRIOR, PALADIN и т.д.)
spec - ID специализации игрока (71, 72 и т.д.)

Пример: |cffffd100class == WARRIOR and alias == "Mishok"|r]]
LR.CustomDurationLenMore = "Установите длительность в сек. для %s (только для текущей сессии)"
LR["WASyncSendOG"] = "Отправить (не WASync)"
LR["WASyncSendOGTooltip"] = "Отправить WA используя встроенную технологию MRT. Сработает для игроков без ExRT_Reminder."

LR["Follower Dungeon"] = "Подземелья с соратниками"
LR["Delve"] = "Вылазка"
LR["Quest Party"] = "Групповое задание"
LR["Story Raid"] = "Сюжетный рейд"

LR["rfunit"] = "Игрок по условию"
LR["rfunitTip"] = "|cff00ff00{funit:УСЛОВИЯ:НОМЕР_В_СПИСКЕ}|r - выбрать игрока из рейда/группы, который соответствует условиям. Условия могут быть класс (|cff00ff00priest|r,|cff00ff00mage|r),\nроль (|cff00ff00healer|r,|cff00ff00damager|r), группа (|cff00ff00g2|r,|cff00ff00g5|r). Несколько условий должны быть написаны через запятую, игрок будет добавлен в список, если выполнено любое из условий.\nВы можете использовать символ |cff00ff00+|r перед условием, чтобы сделать его добавочным. Примеры: |cff00ff00{funit:paladin,+damager:2}|r, |cff00ff00{funit:mage,+g2,priest:3}|r\n(маги из группы 2 или жрецы из любой группы будут добавлены в список. Шаблон вернет имя третьего игрока из этого списка)"

LR["Randomize"] = "Randomize"
LR["Current roster"] = "Текущий состав"
LR["Current list"] = "Текущий список"
LR["All specs"] = "Все специализации"
LR["All classes"] = "Все классы"
LR["All roles"] = "Все роли"
LR["All aliases"] = "Все алиасы"

LR["Timeline"] = "Таймлайн"
LR["Assignments"] = "Assignments"

LR["Select boss"] = "Выбрать босса"

LR["Hide message after using a spell"] = "Скрыть сообщение после использования заклинания"
LR["Lines filters"] = "Фильтры строк"
LR["Reminders filters"] = "Фильтры ремайндеров"
LR["Show only reminders for filtered spells"] = "Показывать ремайндеры только для отфильтрованных заклинаний"
LR["New reminders options"] = "Параметры новых ремайндеров"
LR["Use TTS"] = "Использовать TTS"
LR["Icon without spell name"] = "Иконка без названия заклинания"
LR["ExportToNote"] = "Экспорт в заметку"
LR["Send"] = "Отправить"
LR["Start live session"] = "Прямой эфир"
LR["Players will be invited to live session. Everyone who accept will able to add/change/remove reminders. All changes will be in shared profile, don't forget to copy them to any profile if you want to save them."] = "Игроки будут приглашены на прямой эфир. Все, кто примет, смогут добавлять/изменять/удалять ремайндеры."
LR["Live session is on"] = "Прямой эфир включен"
LR["Guild"] = "Гильдия"
LR["Custom roster"] = "Свой состав"
LR["Edit"] = "Изменить"
LR["Edit custom roster"] = "Изменить свой состав"
LR["1 line - 1 player, format: |cff00ff00name   class   role|r"] = "1 строка - 1 игрок, формат: |cff00ff00имя   класс   роль|r"
LR["Add (rewrite current roster)"] = "Добавить (перезаписать текущий состав)"
LR["Add from current raid/group"] = "Добавить из текущей группы"
LR["Clear list"] = "Очистить список"
LR["Edit spells groups"] = "Редактировать группы заклинаний"
LR["Reset to default"] = "Сбросить по умолчанию"
LR["Spell Name"] = "Название заклинания"
LR["Message: "] = "Сообщение: "
LR["Sound: "] = "Звук: "
LR["Glow: "] = "Подсветка: "
LR["TTS: "] = "TTS: "
LR["Phase "] = "Фаза "
LR["Note: "] = "Заметка: "
LR["From start: "] = "С начала боя: "
LR["CD: "] = "КД: "
LR["%s is starting |A:unitframeicon-chromietime:20:20|a live session"] = "%s начинает |A:unitframeicon-chromietime:20:20|a прямой эфир"
LR["Cooldown:"] = "Перезарядка:"
LR["Leave empty for reset to default value"] = "Оставьте пустым для сброса до значения по умолчанию"
LR["Charges:"] = "Заряды:"
LR["Reminder is untimed"] = "Reminder is untimed"
LR["GUID"] = "GUID"
LR["NPC ID"] = "ID нпц"
LR["Spawn Time"] = "Время спавна"
LR["Spawn UNIX Time"] = "UNIX время спавна"
LR["Spawn Index"] = "Индекс спавна"
LR["Revert changes"] = "Отменить изменения"
LR["Revert all changes made during last live session."] = "Отменить все изменения, сделанные во время последнего прямого эфира."
LR["|cff00ff00Live session is ON"] = "|cff00ff00Прямой эфир включен"
LR["|cffff0000Exit live session"] = "|cffff0000Выйти из эфира"
LR["Stop this session"] = "Остановить в этой сессии"
LR["Select color in Color Picker"] = "Выбрать цвет"
LR["Temporarily add custom spell"] = "Временно добавить собственное заклинание"
LR["Round"] = "Округлить"
LR["Group"] = "Группа"
LR["Alias:"] = "Алиас:"
LR["Custom players:"] = "Игроки вручную:"
LR["*(press Enter to save changes)"] = "*(нажмите Enter для сохранения изменений)"
LR["Add custom line(s) at +X seconds"] = "Добавить строку(и) через +X секунд"
LR["Classes:"] = "Классы:"
LR["Players:"] = "Игроки:"
LR["Roles:"] = "Роли:"
LR["Right Click to pin this fight"] = "Правый клик чтобы закрепить этот бой"
LR["Right Click to unpin this fight"] = "Правый клик чтобы открепить этот бой"
LR["Convert Group"] = "Конвертировать\nгруппу"
LR["Profile"] = "Профиль"
LR["Default"] = "По умолчанию"
LR["Use for all characters"] = "Использовать для всех персонажей"
LR["Enter profile name"] = "Введите название профиля"
LR["Delete"] = "Удалить"
LR["Delete profile"] = "Удалить профиль"
LR["Copy into current profile from"] = "Скопировать в текущий профиль из"
LR["WA is different version/changed"] = "WA другой версии/изменена"
LR["Clear list?"] = "Очистить список?"
LR["Other"] = "Другое"
LR["Deleted"] = "Удаленные"
LR["You can't edit reminder simulated from note"] = "Вы не можете редактировать ремайндер, смоделированный из заметки"
LR["Simulate note timers"] = "Симулировать таймеры заметок"
LR["SimNoteTimersTip"] = "Смоделирует ремайндеры из текущей заметки как если бы вы импортировали ремайндеры через \"Импорт из заметки\".\nНастройки галочек в \"Импорт из заметки\" влияют на симуляцию ремайндеров на таймлайне"
LR.DeletedTabTip = "Удаленные ремайндеры храняться в течении 180 дней и могут быть восстановлены в любой момент"
LR["Own Data"] = "Свои данные"
LR["Pixel Glow"] = "Пиксельное свечение"
LR["Autocast Shine"] = "Свечение при автоприменении"
LR["Action Button Glow"] = "Свечение кнопки действия"
LR["Proc Glow"] = "Свечение при активации"
LR["Last basic check:"] = "Последняя проверка наличия:"
LR["seconds ago by"] = "секунд назад от"
LR["Last version check:"] = "Последняя проверка версии:"
LR["Open editor"] = "Открыть редактор"
LR["Edit custom encounter"] = "Изменить свой таймлайн"
LR["Not enough permissions to request reload UI"] = "Недостаточно прав для запроса ReloadUI"
LR["Get DebugLog"] = "Get DebugLog"
LR["Request ReloadUI"] = "Запросить ReloadUI"
LR["Manual Replacement"] = "Ручная замена"
LR["Change names manually"] = "Изменить имена вручную"
LR["Name to find:"] = "Имя для поиска:"
LR["New name:"] = "Новое имя:"
LR["Error"] = "Ошибка"
LR["Custom EH"] = "Custom EH"
LR["Use custom error handler for this WA"] = "Использовать обработчик ошибок из ремайндера для этой WA"
LR["Request WA"] = "Запросить WA"
LR["Player has to be in the same guild to request WA"] = "Игрок должен быть в той же гильдии что и вы, чтобы запросить WA"
LR["%s requests your version of WA %q. Do you want to send it?"] = "%s запрашивает вашу версию WA %q. Хотите отправить?"
LR["Set Load Never"] = "Set Load Never"
LR["Archive and Delete"] = "Archive and Delete"
LR["Last note update was sent by %s at %s"] = "Последнее обновление заметки было отправлено %s в %s"
LR["Hold shift to save and send reminder"] = "Удерживайте Shift чтобы сохранить и отправить ремайндер"

LR["SoundStatus1"] = "Звук работает в нормальном режиме"
LR["SoundStatus2"] = "Звук заблокирован, обновления ремайндера его не перезапишут"
LR["SoundStatus3"] = "Звук отключен"
LR["PersonalStatus1"] = "Сделать ремайндер персональным, чтобы он не отправлялся другим игрокам"
LR["PersonalStatus2"] = "Сделать ремайндер глобальным"
LR.OptPlayersTooltip = "Настройки игроков, к которым используется правило \"Всегда\""
LR["Current spell settings will be lost. Reset to default preset?"] = "Текущие настройки заклинания будут потеряны. Сбросить настройки до стандартных?"

LR.HelpText =
[=[Слэш команды:
    |cffaaaaaa/rem|r или |cffaaaaaa/reminder|r или |cffaaaaaa/rt r|r или |cffaaaaaa/rt rem|r - Открыть окно Reminder
    |cffaaaaaa/rt ra|r - Открыть окно Raid Analyzer
    |cffaaaaaa/was|r или |cffaaaaaa/wasync|r или |cffaaaaaa/rt was|r - Открыть окно WeakAuras Sync

]=] ..
	"|cffffff00||cffRRGGBB|r...|cffffff00||r|r - Весь текст внутри данной конструкции (\"...\" в этом примере) будет окрашен в определенный цвет, где RR,GG,BB - код цвета в шестнадцатеричной система счисления."..
	"|n|n|cffffff00{spell:|r|cff00ff0017|r|cffffff00}|r - Данный пример будет заменен на иконку заклинания со SpellID \"17\" (|T135940:0|t)."..
	"|n|n|cffffff00{rt|cff00ff001|r}|r - Данный пример будет заменен на метку номер 1(звезда)|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t."..
	"|n|n|cffffff00\\n|r - Текст после данной конструкции перенесется на следующую строку" ..
	"|n|nНомера меток: " ..
	"|n1 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t      5 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t" ..
	"|n2 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t      6 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t" ..
	"|n3 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t      7 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t" ..
	"|n4 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t      8 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t" ..
[=[


|cff80ff00Гайд по условиям|r

Цифровые условия - Счетчик, Процент, Стаки
    Цифровые условия не чувствительны к проблем, разделяються запятыми ,
    Операторы:
    |cffffff00!x|r    - исключая x
    |cffffff00>=x|r   - больше или равно x
    |cffffff00>x|r    - больше x
    |cffffff00<=x|r   - меньше или равно x
    |cffffff00<x|r    - меньше x
    |cffffff00=x|r    - равно x
    |cffffff00x%y|r   - каждый y, начиная с x
    |cffffff00+|r     - дополнение предыдущего условия

    Пример условия 1: |cff00ff001, 3, 4|r
    Данный пример сработает на касты 1, 3, 4

    Пример условия 2: |cff00ff00>=2, +!6, +!7|r
    |cffffff00Если в условии есть математические уравнения, то последующие условия
    должны быть дополнены плюсом '+' как в примере|r

    Данный пример подразумевает больше или равно 2 но в то же время исключая 6 и 7,
    сработает на касты 2 3 4 5 8 и т.д.

    Пример условия 3: |cff00ff003%5|r
    Данный пример подразумевает каждый 5й каст начиная с 3, сработает на касты 3, 8, 13, 18 и т.д.


Строчные условия - Имя Источника, Имя Цели
    Строчные условия чувствительны к пробелам, разделяються точкой с запятой ;
    Операторы:
    |cffffff00-|r    - исключая все совпадения

    Пример условия 1: |cff00ff00Дракомандир Сакарет|r
    Данный пример подразумевает что юнит должен быть "Дракомандир Сакарет"

    Пример условия 2: |cff00ff00-Дракомандир Сакарет;Пустое воспоминание|r
    Данный пример исключает "Дракомандир Сакарет" и исключает "Пустое воспоминание"

    Пример условия 3: |cff00ff00Дракомандир Сакарет;Пустое воспоминание|r
    Данный пример подразумевает что юнитом должен быть "Дракомандир Сакарет"
    или "Пустое воспоминание"


MobID условия - ID источника, ID цели
    MobID условия чувствительны к пробелам, разделяються запятыми ,
    Операторы:
    |cffffff00x:y|r   - где x это npcID, а y это spawnIndex

    Пример условия 1: |cff00ff00154131,234156|r
    Данный пример подразумевает что npcID должны быть 154131 или 234156

    Пример условия 2: |cff00ff00154131:1,234156:2|r
    Данный пример подразумевает что npcID должны быть 154131 со spawnIndex 1 или 234156 со spawnIndex 2

|cff80ff00Гайд по типам счетчика|r

    |cff00ff00По умолчанию|r - Добавляет +1 при каждом срабатывании триггера

    |cff00ff00Для каждого Источника|r - Добавляет +1 при каждом срабатывании триггера.
    Отдельный счетчик для каждого кастера

    |cff00ff00Для каждой Цели|r - Добавляет +1 при каждом срабатывании триггера.
    Отдельный счетчик для каждой цели

    |cff00ff00Наложение триггера|r - Добавляет +1 когда триггер активируеться в момент когда все
    остальные триггеры активны

    |cff00ff00Наложение триггера со сбросом|r - Добавляет +1 когда триггер активируеться в момент когда все
    остальные триггеры активны. Сбрасывает счетчик до 0 когда ремайндер деактивируеться

    |cff00ff00Общий для этого ремайндера|r - Добавляет +1 при каждом срабатывании триггера.
    Общий счетчик с каждым триггером с таким же типом счетчика в этом ремайндере

    |cff00ff00Сброс через 5 сек|r - Добавляет +1 при каждом срабатывании триггера.
    Сбрасывает счетчик до 0 через 5 секунд после каждого срабатывания триггера

|cff80ff00Гайд по логике условий загрузки|r

    Загрузку можно производить по следующим условиям: Класс, роль, номер группы, ник, по заметке.
    Внутри каждого условия должно встречаться хотя бы одно совпадение.

    Например загрузка для классов Воин, Паладин.
        - Если игрок воин или паладин то ремайндер загрузиться.

    При использовании нескольких условий загрузки, ремайндер будет
    загружен если выполняються все условия.

    Например загрузка для классов Воин, Паладин и роли Танк.
        - Если игрок воин или паладин и танк то ремайндер загрузиться.
        - Если игрок воин или паладин и не танк то ремайндер не загрузиться.



|cff80ff00Гайд по загрузке по заметке|r

    В секции "Условия загрузки" вы можете указать шаблон заметки.
    По умолчанию ремайндер будет искать строку заметки которая будет начинаться с
    указаного шаблона, ремайндер будет загружен для всех игроков в этой строке.

    Вы можете поставить галочку "|cffffff00Заметка это блок|r" и тогда поиск будет производиться
    внутри блока от patStart до patEnd.

    Пример блока:

        liquidStart
        Мишок Амби
        Пауэл Кройфель
        Нимб Ловес
        liquidEnd

    В случае если дополнительные параметры не указаны(см.ниже) то ремайндер будет
    загружен для всех игроков в блоке.

    Вы можете указать дополнительные параметры для загрузки по шаблону заметки.

    Если перед шаблоном приписать "|cffffff00-|r" то логика загрузки будет инвертирована,
    т.е. ремайндер будет загружен для всех игроков которые не будут найдены по шаблону.

    Так же возможно загружать ремайндер только для конкретных позиций в заметке,
    для этого после шаблона нужно указать специальный параметр |cffffff00{pos:y:x}|r,
    где |cffffff00y|r и |cffffff00x|r это числа означающие позицию игрока для которого должнен загружаться ремайндер.

    При использовании шаблона для конкретной строки |cffffff00y|r означает порядковый номер игрока в строке.

    При использовании шаблона для блока в заметке |cffffff00y|r означает порядковый номер строки
    в блоке, а |cffffff00x|r означает порядковый номер игрока в строке,|cffffff00x|r может быть опущен,
    тогда ремайндер загрузиться для всех игроков в строке |cffffff00y|r.

    В случае если |cffffff00y|r и |cffffff00x|r не указаны (т.е. просто приписка |cffffff00{pos}|r) то
    ремайндер будет загружен для всех игроков найденных по шаблону,
    однако можно будет использовать шаблон замены текста |cffffff00{notepos:y:x}|r,
    который возвращает ник игрока в данной позиции, в других местах в
    ремайндере(например сообщение на экране или tts).

    Без дополнительного параметра |cffffff00{pos}|r использовать данный шаблон замены текста не выйдет.

    Система позиций заметок циклична, т.е.
    если в строке 5 игроков, то 6я позиция будет 1м игроком,
    если строк 8 то 10ая позиция будет в строке 2 и т.д.


    Примеры:

    Шаблон заметки:

        #left

    Заметка:

        #left |cfff48cbaМишоксемпай|r |cffa330c9Фейсмикх|r |cffa330c9Эннуелдх|r |cffaad372Фрираан|r

    Ремайндер будет загружен для всех игроков в
    строке начинающейся с "#left"

    Шаблон заметки:

        -#right

    Заметка:

        #right |cfffff468Кройфель|r |cfffff468Турбоклык|r |cff00ff98Нимбмейн|r |cffffffffФейтясд|r

    Ремайндер будет загружен для всех игроков кроме тех которые
    находятся в строке начинающейся с "#right"

    Шаблон заметки:

        #center {pos:3}

    Заметка:

        #center |cfff48cbaМишоксемпай|r |cffa330c9Фейсмикх|r |cffa330c9Эннуелдх|r |cffaad372Фрираан|r

    Ремайндер будет загружен только для 3го игрока в заметке: |cffa330c9Эннуелдх|r


    Шаблон заметки блока:

        roots

    Заметка:

        rootsStart
        |cffc41e3aРомадесгрип|r
        |cffa330c9Эннуелдх|r
        |cfff48cbaМишоксемпай|r
        |cffc69b6dСквишех|r
        |cffaad372Батькито|r
        rootsEnd

    Ремайндер будет загружен для всех игроков в заметке найденых
    начиная с "rootsStart" и заканчивая "rootsEnd"

    Шаблон заметки блока:

        seeds{pos:2}

    Заметка:

        seedsStart
        |cffc41e3aРомадесгрип|r |cffa330c9Эннуелдх|r |cfff48cbaМишоксемпай|r |cffc69b6dСквишех|r |cffaad372Батькито|r
        |cff00ff98Нимбмейн|r Омежечка |cffffffffФейтясд|r |cfff48cbaЛовес|r
        seedsEnd

    Ремайндер будет загружен для всех игроков во второй
    строке: |cff00ff98Нимбмейн|r Омежечка |cffffffffФейтясд|r |cfff48cbaЛовес|r


    Шаблон заметки блока:

        seeds{pos:2:3}

    Заметка:

        seedsStart
        |cffc41e3aРомадесгрип|r |cffa330c9Эннуелдх|r |cfff48cbaМишоксемпай|r |cffc69b6dСквишех|r |cffaad372Батькито|r
        |cff00ff98Нимбмейн|r Омежечка |cffffffffФейтясд|r |cfff48cbaЛовес|r
        seedsEnd

    Ремайндер будет загружен только для 3го игрока во
    второй строке: Фейтясд

    Шаблон заметки блока:

        seeds{pos:6}

    Заметка:

        seedsStart
        |cffc41e3aРомадесгрип|r |cffa330c9Эннуелдх|r |cfff48cbaМишоксемпай|r |cffc69b6dСквишех|r |cffaad372Батькито|r
        |cff00ff98Нимбмейн|r Омежечка |cffffffffФейтясд|r |cfff48cbaЛовес|r
        seedsEnd

    Ремайндер будет загружен для всех игроков из второй строки
    т.к. цикличный порядок позиций строк в блоке: 1, 2, 1, 2, 1, 2 и т.д.


|cFFC69B6DСоветы от Мишка по использованию аддона!|r

1. Рекомендую ознакомиться с функционалом окна истории.
   - Кликая на разные столбцы вы можете менять настройки ремайндера.
   - Например если вы хотите быстро сделать ремайндер на абилку которую босс применяет
     в течении нескольких фаз при этом количество кастов на каждой фазе зависит от
     таймеров перевода то рекомендую следующее:

    В окне быстрой настройки найти нужный вам каст босса на нужной фазе и нажать на столбец с
    подсказкой "Время с начала фазы" так ремайндер сразу настроиться на таймер выбранной фазы
    и установит задержку(показать через) на выбранную

2. Не рекомендую использовать таймеры |cffff0000BigWigs/DBM|r если вы собираетесь отправлять
   ваши ремайндеры другим рейдерам.
   - В BigWigs и DBM таймеры часто разняться и лучше всего избегать такого способа настройки ремайндера
   - Лучшим вариантом будет настроить ремайндер на основании последнего
     каста босса и сделать отcчет до следующего

3. Делая ремайндер основываясь на фазе босса также нужно быть бдительным
   так как фазы в |cffff0000BigWigs и DBM|r могут отличаться нумерацией или триггерами начала фазы.
   - Ситуация с фазами в боссмодах намного стабильнее чем с таймерами,
     но всеравно стоит опасаться разбежностей
   - Лучшим вариантом будет узнать по какому триггеру в одном из аддонов
     установлена смена фазы(например "Каст завершен" или "+аура")
     и использовать данный триггер как отсчет начала фазы

4. Пункты 2 и 3 не актуальны если у вас в гильдии все используют один и тот же боссмод аддон
]=]
LR.HelpText = LR.HelpText:gsub("\t", "    ") -- \t(tab) may not be printable atleast for some fonts, so replacing it with spaces
