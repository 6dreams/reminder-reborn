local GlobalAddonName, ExRT = ...

if ExRT.locale ~= "ruRU" and not (VExRT and VExRT.Reminder and VExRT.Reminder.forceRUlocale) then
	return
end

ExRT.LR = {}
local LR = ExRT.LR

LR.OutlinesNone = "Нет"
LR.OutlinesNormal = "КОНТУР"
LR.OutlinesThick = "ТОЛСТЫЙ КОНТУР"
LR.OutlinesMono = "МОНОХРОМНЫЙ КРАЙ"
LR.OutlinesMonoNormal = "МОНОХРОМНЫЙ КРАЙ, КОНТУР"
LR.OutlinesMonoThick = "МОНОХРОМНЫЙ КРАЙ, ТОЛСТЫЙ КОНТУР"

LR.EventsSCC = "Каст завершен"
LR.EventsSCS = "Начало каста"
LR.EventsBossPhase = "Фаза босса BigWigs/DBM"
LR.EventsBossStart = "Пулл босса"
LR.EventsBossHp = "%хп босса"
LR.EventsBossMana = "%энергии босса"
LR.EventsBWMsg = "Сообщение BigWigs/DBM"
LR.EventsBWTimer = "Таймер BigWigs/DBM"
LR.EventsBWTimerText = "Таймер BW/DBM по тексту"
LR.EventsSAA = "+аура"
LR.EventsSAR = "-аура"
LR.EventsSAAS = "+аура [персональная]"
LR.EventsSARS = "-аура [персональная]"

LR.Castse21 = "каждый 2 [1,3]"
LR.Castse22 = "каждый 2 [2,4]"
LR.Castse31 = "каждый 3 [1,4,7]"
LR.Castse32 = "каждый 3 [2,5,8]"
LR.Castse33 = "каждый 3 [3,6,9]"
LR.Castse41 = "каждый 4 [1,5,9,13]"
LR.Castse42 = "каждый 4 [2,6,10,14]"
LR.Castse43 = "каждый 4 [3,7,11,15]"
LR.Castse44 = "каждый 4 [4,8,12,16]"

LR.Conditionstarget = "Текущая цель"
LR.Conditionsfocus = "Фокус"
LR.Conditionsnomark = "Без метки"

LR.RolesTanks = "Танки"
LR.RolesHeals = "Хилы"
LR.RolesMheals = "МХилы"
LR.RolesMhealsTip = "Мили хилы: Паладин и Монк"
LR.RolesRheals = "РХилы"
LR.RolesRhealsTip = "Ренж хилы"
LR.RolesDps = "ДД"
LR.RolesRdps = "РДД"
LR.RolesMdps = "МДД"

LR.DiffsAny = "Все"
LR.DiffsHeroic = "Героик"
LR.DiffsMythic = "Мифик"
LR.Diffsn10 = "10 Обычный"
LR.Diffsn25 = "25 Обычный"
LR.Diffsh10 = "10 Героический"
LR.Diffsh25 = "25 Героический"

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
LR.YellowAlertTip = "Длительность ремайндера и длительность активации триггера \nне должна равняться 0 в ремайндере без 'untimed' триггеров"
LR.EnvironmentalDMGTip = "1 - Падение\n2 - Закончилось дыхание\n3 - Усталость\n4 - Огонь\n5 - Лава\n6 - Слизь"
LR.DifficultyID = "ID Сложности подземелья"
LR.EncounterID = "ID Босса:"
LR.CountdownFormat = "Формат отсчета:"
LR.AddTextReplacers = "Шаблон замены текста"
LR.CustomEventTip = "Ремайндер будет отправлять ивенты для WeakAuaras вместо отображения текста на экране.\nАргументы для WeakAuras.ScanEvents разделяються пробелами."
LR.CustomEvent = "Отправить WA ивент"
LR.GlowTip = "\nИмя игрока или |cffff0000{targetName}|r или |cffff0000{sourceName}|r\n|cffff0000{sourceName|cff80ff001|r}|r что-бы уточнить номер триггера"
LR.SpamType = "Тип сообщения:"
LR.SpamChannel = "Канал чата:"
LR.SpamMessage = "Сообщение для чата:"
LR.ReverseTip = "Обратить загрузку по именам игроков"
LR.Reverse = "Обратить"
LR.Manually = "Вручную"
LR.ManuallyTip = "Установить вручную ID босса, ID сложности, ID зоны или номер каста для ремайндеров старого типа"
LR.WipePulls = "Очистить Историю"
LR.DungeonHistory = "История подземелий"
LR.RaidHistory = "История рейда"
LR.Duplicated = "Дублированный"
LR.ListNotSendedTip = "Не отправлен"
LR.ClearImport = "Вы делаете 'чистый' импорт\n|cffff0000Все старые ремайндеры будут удалены|r"
LR.ForceRemove = "Вы уверены что хотите удалить ВСЕМ ремайндеры из вашей корзины?"
LR.ClearRemove = "Вы уверены что хотите очистить корзину?"
LR.CenterByX = "Центрировать гор."
LR.CenterByY = "Центрировать вер."
LR.EnableHistory = "Записывать историю заклинаний"
LR.EnableHistoryRaid ="История заклинаний боссов в рейде"
LR.EnableHistoryDungeon = "История заклинаний боссов в подземельях"

LR.chkEnableHistory = "Записывать историю пуллов"
LR.chkEnableHistoryTip = "Отвечает за запись истории пуллов для окна быстрой настройки.\nЕсли выключено то события с последнего пулла всеравно будут отображаться. \n|cffff0000***Большее число сохраняемых боев требует больше ресурсов.\n**При выключении записанные пулы удаляются из памяти"
LR.Add = "Добавить"
LR.SendAll = "Отправить все"
LR.Boss = "Босс: "
LR.Any = "Другое"
LR.AnyAlways = "Другой (всегда)"

LR.Name = "Название:"
LR.CastNumber = "№ каста:"
LR.Event = "Событие:"
LR.TimerText = "Текст таймера:"
LR.GlobalCounter = "Глобальный счетчик"
LR.GlobalCounterTip = "Используется номер каста с начала файта независимо от того, кто кастит"
LR.delayTip = "MM:SS.MS - 1:35.5 или просто время в секундах\nМожно несколько, через запятую"
LR.commaTip = "Можно несколько, через запятую"
LR.delayText = "Показать через:"
LR.duration = "Длительность, с.:"
LR.durationTip = "Длительность отображения текста/подсветки/спама в чат\nЕсли длительность 0 то ремайндер будет отображаться пока активны триггеры"
LR.countdown = "Обратный отсчет"
LR.msg = "Сообщение на экране:"
LR.condition = "Условия:"
LR.sound = "Звук:"
LR.voiceCountdown = "Голосовой отсчет:"
LR.AllPlayers = "Все игроки"
LR.notePatternEditTip = [[Начало строки заметки, все игроки из этой строки будут выбраны для отображения. Пример: "|cff00ff001. |r"
Если перед началом шаблона написать '-' то ремайндер будет загружаться для всех кого НЕТ в строке заметки. Пример "|cff00ff00-1. |r
]]
LR.notePattern = "Шаблон заметки:"
LR.save = "Сохранить"
LR.QuickSetup = "Показать историю"

LR.QuickSetupTimerFromPull = "Время с пулла"
LR.QuickSetupSec = "Секунд: "
LR.QuickSetupTimerFromPhase = "Время с начала фазы"
LR.QuickSetupTimerFromEvent = "Время с предыдущего такого же события"

LR.QuickSetupAddAurasEvents = "Показать события аур"
LR.QuickSetupAddAllEvents = "Показать все события (игнорировать выбранное)"

LR.QuickSetupChoosTipStartTimer = "\nНачало боя: "
LR.QuickSetupChoosTipPullTimer = "\nВремя пула: "
LR.QuickSetupChoosTipDiff = "\nСложность: "

LR.QS_Phase = "Фаза босса"
LR.QS_PhaseRepeat = "Повтор фазы "
LR.QS_SCC = "Начало каста"
LR.QS_SCS = "Каст завершен"
LR.QS_SAA = "+аура"
LR.QS_SAR = "-аура"

LR.Always = "Всегда"
LR.All = "Все"

LR.PhaseNumber = "Номер фазы:"
LR.BossHpLess = "меньше %хп босса:"
LR.BossManaLess = "больше %энергии босса:"
LR.TimerTimeLeft = "Ост. время таймера:"

LR.SingularExportTip = "Вы можете добавить больше ремайндеров в окно экспорта нажимая на кнопку экспорт"

LR.DeleteSection = "Удалить все незаблокированные в этой секции"
LR.NoName = "Безымянный"
LR.ReminderRemoveSection = "Удалить эту секцию\nУдалены будут все незаблокированные ремайндеры"
LR.ReminderPersonalDisable = "Отключить этот ремайндер для себя"
LR.ReminderPersonalEnable = "Включить этот ремайндер для себя"
LR.ReminderUpdatesDisable = "Запретить обновления этого ремайндера"
LR.ReminderUpdatesEnable = "Разрешить обновления этого ремайндера"
LR.ReminderSoundDisable = "Отключить звук для этого ремайндера"
LR.ReminderSoundEnable = "Включить звук для этого ремайндера"
LR.Listchk = "В выключенном состоянии ремайндер не будет показан.\nНастройка влияет только для вас, не передается при отправке"
LR.Listchk_lock = "Заблокировать\nЛюбые обновления от других игроков будут проигнорированы для этого ремайндера"
LR.Listedit = "Ред."
LR.Listduplicate ="Дублировать"
LR.Listdelete = "Удалить"
LR.ListdeleteTip = "Удалить\n|cffffffffЗажмите шифт что бы удалить ремайднер без подтверждения и поместить его в корзину"
LR.ListdExport = "Экспорт"
LR.ListdSend = "Отправить"

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

LR.ReminderGlobalCounter = "По умолчанию"
LR.ReminderCounterSource = "Для каждого Источника"
LR.ReminderCounterDest = "Для каждой Цели"
LR.ReminderCounterTriggers = "Наложение триггера"
LR.ReminderCounterTriggersPersonal = "Наложение триггера со сбросом"
LR["Global counter for reminder"] = "Общий для этого ремайндера"
LR["Reset in 5 sec"] = "Сброс через 5 сек"

LR["ReminderGlobalCounterTip"] = "|cff00ff00По умолчанию|r - Добавляет +1 при каждом срабатывании триггера"
LR["ReminderCounterSourceTip"] = "|cff00ff00Для каждого Источника|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждого кастера"
LR["ReminderCounterDestTip"] = "|cff00ff00Для каждой Цели|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждой цели"

LR["ReminderCounterTriggersTip"] = "|cff00ff00Наложение триггера|r - Добавляет +1 когда триггер активируеться в момент \nкогда все остальные триггеры активны(наложение)"
LR["ReminderCounterTriggersPersonalTip"] = "|cff00ff00Наложение триггера со сбросом|r - Добавляет +1 когда триггер активируеться в момент \nкогда все остальные триггеры активны(наложение). Сбрасывает счетчик до 0 когда ремайндер деактивируеться"

LR["ReminderCounterGlobalForReminderTip"] = "|cff00ff00Общий для этого ремайндера|r - Добавляет +1 при каждом срабатывании триггера. \nОбщий счетчик с каждым триггером с таким же типом счетчика в этом ремайндере"
LR["ReminderCounterResetIn5SecTip"] = "|cff00ff00Сброс через 5 сек|r - Добавляет +1 при каждом срабатывании триггера. \nСбрасывает счетчик до 0 через 5 секунд после каждого срабатывания триггера"

LR.ReminderAnyBoss = "Любой босс"
LR.ReminderAnyNameplate = "Любой неймплейт"
LR.ReminderAnyRaid = "Любой из группы"
LR.ReminderAnyParty = "Любой из рейда"

LR.ReminderCombatLog = "Журнал боя"
LR.ReminderBossPhase = "Фаза босса"
LR.ReminderBossPhaseTip = "Информация о фазе босса береться из BigWigs или DBM\nЕсли не указана длительность активации то триггер будет активен до конца фазы"
LR.ReminderBossPhaseLabel = "Фаза(Название/номер)"
LR.ReminderBossPull = "Пулл босса"
LR.ReminderHealth = "Здоровье юнита"
LR.ReminderHealthTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.ReminderReplacertargetGUID = "GUID"
LR.ReminderMana = "Энергия юнита"
LR.ReminderManaTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.ReminderReplacerhealthenergy = "Процент Энергии"
LR.ReminderReplacervalueenergy = "Значение Энергии"
LR.ReminderBWMsg = "Сообщение BigWigs/DBM"
LR.ReminderReplacerspellNameBWMsg = "Текст сообщения BigWigs/DBM"
LR.ReminderBWTimer = "Таймер BigWigs/DBM"
LR.ReminderReplacerspellNameBWTimer = "Текст таймера BigWigs/DBM"
LR.ReminderChat = "Сообщение в чате"
LR.ReminderChatHelp = "Союзники: Группа, Рейд, Шепот\nВраги: Сказать, Крик, Шепот, Эмоция"
LR.ReminderBossFrames = "Новый босс фрейм"
LR.ReminderAura = "Аура"
LR.ReminderAuraTip = "Если не указана длительность активации то триггер будет активен пока висит аура"
LR.ReminderAbsorb = "Абсорб юнита"
LR.ReminderAbsorbLabel = "Количество абсорба"
LR.ReminderAbsorbTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"
LR.ReminderReplacervalueabsorb = "Количество абсорба"

LR.ReminderCurTarget = "Текущая цель"
LR.ReminderCurTargetTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"

LR.ReminderSpellCD = "Перезарядка способности"
LR.ReminderSpellCDTooltip = "Триггер активен пока способность перезаряжеться"
LR.ReminderSpellCDTip = "Если не указана длительность активации то триггер будет активен пока выполняються условия"

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

LR.ReminderCastStart = "Начало каста"
LR.ReminderCastDone = "Каст завершен"
LR.ReminderAuraAdd = "+аура"
LR.ReminderAuraRem = "-аура"
LR.ReminderSpellDamage = "Урон от заклинания"
LR.ReminderSpellDamageTick = "Периодический урон"
LR.ReminderMeleeDamage = "Мили урон"
LR.ReminderSpellHeal = "Исцеление"
LR.ReminderSpellHealTick = "Периодечское исцеление"
LR.ReminderSpellAbsorb = "Абсорб"
LR.ReminderCLEUEnergize = "Energize"
LR.ReminderCLEUMiss = "Промах"
LR.ReminderDeath = "Смерть"
LR.ReminderSummon = "Призыв"
LR.ReminderDispel = "Диспел"
LR.ReminderCCBroke = "CC Broke"
LR.ReminderEnvDamage = "Окружающая среда"
LR.ReminderInterrupt = "Прерывание"

LR["ReminderReplacerextraSpellIDSpellDmg"] = "Количество"
LR["ReminderReplacerextraSpellID"] = "Сбившее заклинание"
LR["ReminderMissType"] = "Тип Промаха"
LR["ReminderReplacerspellIDSwing"] = "Количество"

LR["event"] = "Advanced Событие:"
LR["eventCLEU"] = "Событие журнала боя:"

LR["sourceName"] = "Имя Источника:"
LR["sourceID"] = "ID Источника:"
LR["sourceUnit"] = "Условие для Источника:"
LR["sourceMark"] = "Метка Источника:"

LR["targetName"] = "Имя Цели:"
LR["targetID"] = "ID Цели:"
LR["targetUnit"] = "Условие для Цели:"
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

LR["invert"] = ""
LR["guidunit"] = "GUID:"
LR["onlyPlayer"] = "Только Игрок:"


LR["Send All For This Boss"] = "Отправить (этот босс)"
LR["Export All For This Boss"] = "Экспорт (этот босс)"
LR["Get last update time"] = "Проверить дату обновления"
LR["Clear Removed"] = "Очистить корзину"
LR["Delete All Removed"] = "Удалить для всех"
LR["Deletes reminders from 'removed list to all raiders'"] = "Удаляет ремайндеры из корзины всем в рейде"

LR["NumberCondition"] = "См. Помощь - Цифровые условия"
LR["StringCondition"] = "См. Помощь - Строчные условия"
LR["UnitIDCondition"] = "См. Помощь - UnitID условия"

LR["rsourceName"] = "Имя Источника"
LR["rsourceMark"] = "Метка Источника"
LR["rsourceGUID"] = "GUID Источника"
LR["rtargetName"] = "Имя Цели"
LR["rtargetMark"] = "Метка Цели"
LR["rtargetGUID"] = "GUID Цели"
LR["rspellName"] = "Название заклинания"
LR["rspellID"] = "Spell ID"
LR["rextraSpellID"] = "Доп. Spell ID"
LR["rstacks"] = "Stacks"
LR["rsourceGUID"] = "GUID Источника"
LR["rtargetGUID"] = "GUID Цели"
LR["rcounter"] = "Счетчик"
LR["rguid"] = "GUID"
LR["rhealth"] = "Процент здоровья"
LR["rvalue"] = "Значение здоровья"
LR["rtimeLeft"] = "Оставшееся время"
LR["rtext"] = "Текст сообщения"
LR["rphase"] = "Фаза"
LR["rauraValA"] = "Значение подсказки 1"
LR["rauraValB"] = "Значение подсказки 2"
LR["rauraValC"] = "Значение подсказки 3"

LR["rmath"] = "Математика"
LR["rmathTip"] = "|cffffffff|cffffff00{math:|cff00ff00x+y-zf|r}|r\nгде x y z это цифры в математическм расчете, \nоператоры + - * / %(остаток от деления)\nf - режим округления \nf - к меньшему \nc - к большему \nr - к ближайшему"
LR["rnoteline"] = "Строка заметки"
LR["rnotelineTip"] = "|cffffffff|cffffff00{noteline:|cff00ff00patt|r}|r\nгде patt это шаблон поиска в заметке"
LR["rnote"] = "Строка заметки с позицией"
LR["rnoteTip"] = "|cffffffff|cffffff00{note:|cff00ff00pos|r:|cff00ff00patt|r}|r\nгде pos это номер слова после шаблона patt это шаблон поиска в заметке"
LR["rmin"] = "Минимальное значение"
LR["rminTip"] = "|cffffffff|cffffff00{min:|cff00ff00x;y;z,c,v,b|r}|r\nгде x y z c v b это числа, можно разделять как ; так и ,"
LR["rmax"] = "Максимальное значение"
LR["rmaxTip"] = "|cffffffff|cffffff00{max:|cff00ff00x;y;z,c,v,b|r}|r\nгде x y z c v b это числа, можно разделять как ; так и ,"
LR["rrole"] = "Роль игрока"
LR["rroleTip"] = "|cffffffff|cffffff00{role:|cff00ff00name|r}|r\nгде name это имя игрока роль которого нужно узнать"
LR["rextraRole"] = "Допроль игрока"
LR["rextraRoleTip"] = "|cffffffff|cffffff00{roleextra:|cff00ff00name|r}|r\nгде name это имя игрока допроль которого нужно узнать"
LR["rsub"] = "Обрезать текст"
LR["rsubTip"] = "|cffffffff|cffffff00{sub:|cff00ff00pos1|r:|cff00ff00pos2|r:|cff00ff00text|r}|r\nпоказывает text начиная с pos1 и заканчивая pos2"
LR["rtrim"] = "Убрать пробелы"
LR["rtrimTip"] = "|cffffffff|cffffff00{trim:|cff00ff00text|r}|r\nгде text это текст в котором нужно убрать пробелы"

LR["rnum"] = "Выбрать"
LR["rnumTip"] = "|cffffffff|cffffff00 {num:|cff00ff00x|r}|cff00ff00a;b;c;d|r{/num}|r \nВыбирает строку под номером x где a - 1 b - 2 c - 3 d - 4"
LR["rup"] = "ВЕРХНИЙ РЕГИСТР"
LR["rupTip"] = "|cffffffff|cffffff00 {up}|cff00ff00string|r{/up}|r \nВозвращает строку с БОЛЬШИМИ БУКВАМИ"
LR["rlower"] = "нижний регистр"
LR["rlowerTip"] = "|cffffffff|cffffff00 {lower}|cff00ff00STRING|r{/lower}|r \nВозвращает строку с маленькими буквами"
LR["rrep"] = "Повтор"
LR["rrepTip"] = "|cffffffff|cffffff00 {rep:|cff00ff00x|r}|cff00ff00line|r{/rep}|r \nПовторяет line x раз"
LR["rlen"] = "Ограничить длину"
LR["rlenTip"] = "|cffffffff|cffffff00 {len:|cff00ff00x|r}|cff00ff00line|r{/len}|r \nОграничивает длину line до x символов"
LR["rnone"] = "Ничего"
LR["rnoneTip"] = "|cffffffff|cffffff00 {0}|cff00ff00line|r{/0}|r \nВозвращает пустую строку"
LR["rcondition"] = "Условие"
LR["rconditionTip"] = "|cffffffff|cffffff00 {cond:|cff00ff001<2 AND 1=1|r}|cff00ff00yes;no|r{/cond}|r \nВозвращает yes или no в зависимости от условия"
LR["rfind"] = "Поиск"
LR["rfindTip"] = "|cffffffff|cffffff00 {find:|cff00ff00patt|r:|cff00ff00text|r}|cff00ff00yes;no|r{/find}|r \nИщет patt в text. Возвращает yes или no в зависимости от того найдено ли совпадение"
LR["rreplace"] = "Заменить"
LR["rreplaceTip"] = "|cffffffff|cffffff00 {replace:|cff00ff00x|r:|cff00ff00y|r}|cff00ff00text|r{/replace}|r \nЗаменить x на y в text"
LR["rsetsave"] = "Сохранить"
LR["rsetsaveTip"] = "|cffffffff|cffffff00 {set:|cff00ff001|r}|cff00ff00text|r{/set}|r \nСохраняет text по ключу '1'"
LR["rsetload"] = "Загрузить"
LR["rsetloadTip"] = "|cffffffff|cffffff00 %set|cff00ff001|r|r \nЗагружает текст по ключу, ключ в примере это '1'"

LR["rspellIcon"] = "Иконка заклинания"
LR["rspellIconTip"] = "|cffffffff|cffffff00{spell:|cff00ff00id|r:|cff00ff00size|r}|r\nгде id это id способности, \nsize это размер иконки, \nесли размер не указан то размер подстраиваеться под размер шрифта"
LR["rclassColor"] = "Цвет класса"
LR["rclassColorTip"] = "|cffffffff|cffffff00%classColor |cff00ff00Name|r|r \nОкрашивает Name в цвет класса"
LR["rspecIcon"] = "Иконка роли"
LR["rspecIconTip"] = "|cffffffff|cffffff00%specIcon |cff00ff00Name|r|r \nПоказывает иконку роли Name"
LR["rclassColorAndSpecIcon"] = "Иконка роли и цвет класса"
LR["rclassColorAndSpecIconTip"] = "|cffffffff|cffffff00%specIconAndClassColor |cff00ff00Name|r|r\nПоказывает иконку роли и окрашивает ник в цвет класса"
LR["rplayerName"] = "Имя игрока"
LR["rplayerClass"] = "Класс игрока"
LR["rplayerSpec"] = "Спек игрока"
LR["rPersonalIcon"] = "Иконка персоналки"
LR["rImmuneIcon"] = "Иконка иммуна"
LR["rSprintIcon"] = "Иконка ускорения"
LR["rHealCDIcon"] = "Иконка хил кулдауна"
LR["rRaidCDIcon"] = "Иконка рейд кулдауна"
LR["rNoteLeft"] = "Слева от игрока в заметке"
LR["rNoteRight"] = "Справа от игрока в заметке"
LR["rNoteAll"] = "Все игроки из шаблона заметки"
LR["rCounter"] = "Счетчик"

LR["rTimeLeft"] = "Оставшееся время"
LR["rTimeLeftTip"] = "|cffffffff|cffffff00{timeLeft|cff00ff00x|r:|cff00ff00y|r}|r\nОставшееся время триггера, \nx - номер триггера(можно не указывать)\ny - количество цифр после точки"
LR["rActiveTime"] = "Активное время"
LR["rActiveTimeTip"] = "|cffffffff|cffffff00{activeTime|cff00ff00x|r:|cff00ff00y|r}|r\nАктивное время триггера,\nx - номер триггера(можно не указывать)\ny - количество цифр после точки"
LR["rActiveNum"] = "Количество активных триггеров"
LR["rActiveNumTip"] = "|cffffffff|cffffff00{activeNum}|r\nКоличество активных триггеров"
LR["rMinTimeLeft"] = "Минимальное оставшееся время"
LR["rMinTimeLeftTip"] = "|cffffffff|cffffff00{timeMinLeft|cff00ff00x|r:|cff00ff00y|r}|r\nПоказывает наименьшее оставшееся время из \nактивных триггеров или активных статусов внутри триггера\nx - номер триггера(можно не указывать)\ny - количество цифр после точки"
LR["rTriggerStatus"] = "Статус триггера"
LR["rTriggerStatusTip"] = "|cffffffff|cffffff00{status:|cff00ff00triggerNum|r:|cff00ff00uid|r}|r\nгде triggerNum это номер триггера в ремайндере, \nuid это UID или GUID ремайндера"
LR["rAllSourceNames"] = "Имена Всех Источников"
LR["rAllSourceNamesTip"] = "|cffffffff|cffffff00%allSourceNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00customPattern|r|r \nПоказывает имена всех источников,\nx - номер триггера(можно не указывать) \nможно ограничить источниками с num1 по num2, \ncustomPattern = 1 делает ники безцветными, \nдругие значения заменяют ники на себя"
LR["rAllTargetNames"] = "Имена Всех Целей"
LR["rAllTargetNamesTip"] = "|cffffffff|cffffff00%allTargetNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00customPattern|r|r\nПоказывает имена всех целей,\nx - номер триггера(можно не указывать) \nможно ограничить цели с num1 по num2, \ncustomPattern = 1 делает ники безцветными, \nдругие значения заменяют ники на себя"
LR["rAllActiveUIDs"] = "Все активные UID"
LR["rAllActiveUIDsTip"] = "|cffffffff|cffffff00%allActiveUIDs|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r|r\nПоказывает все активные UID, \nможно ограничить UID с num1 по num2"

LR.LastPull = "Последний пулл"

LR.copy = "Не скрывать дубликаты"
LR.copyTip = "Только для advanced\nЕсли ремайндер активируеться когда уже активен \nто будет появляться его дубликат"

LR.norewrite = "Не перезаписывать"
LR.norewriteTip = "Только для advanced\nЕсли ремайндер активируеться когда уже активен \nто дубликат не будет перезаписывать \nпервую итерацию"

LR.dynamicdisable = "Откл. динамическое обновление"
LR.dynamicdisableTip = "Только для advanced\nДинамические замены текстов будут обновлять \nинформацию только в момент появления ремайндера"

LR.isPersonal = "Не отправлять ремайндер"
LR.isPersonalTip = "Сделать ремайндер персональным, \nего нельзя будет отправить другим игрокам"

LR["AdditionalOptions"] = "Доп. Параметры:"
LR["Show Removed"] = "Показать корзину"

LR.Zone = "Зона:"
LR.ZoneID = "ID Зоны:"

LR.searchTip = "Ищет совпадения в названии, \nсообщении, сообщении для чата, \ntext to speech,\nтексте на неймплейте"

LR["rsetparam"] = "Установить значение"
LR["rsetparamTip"] = "|cffffffff|cffffff00{setparam:|cff00ff00key|r:|cff00ff00value|r}|r \nУстановить локальное значение по ключу key для текущего \nремайндера, посже можно вызвать его через {#key}"

LR.BossKilled = "Босс убит"
LR.BossNotKilled = "Босс не убит"

LR["Raid group number"] = "Номер рейдовой группы"

LR["GENERAL"] = "ОБЩЕЕ"
LR["TEXT, GLOW AND SOUNDS"] = "ТЕКСТ, ПОДСВЕТКА И ЗВУКИ"
LR["LOAD CONDITIONS"] = "УСЛОВИЯ ЗАГРУЗКИ"
LR["TRIGGERS"] = "ТРИГГЕРЫ"

LR["doNotLoadOnBosses"] = "Не загружать \nна боссах:"

LR["specialTarget"] = "Заменить GUID:"
LR["specialTargetTip"] = "Заменяет основной GUID ремайндера. Используйте \nunitToken или target/source(номер триггера).\nНапример source1 или target"
LR["extraCheck"] = "Дополнительное условие:"

LR["NameplateGlowTypeDef"] = "По умолчанию"
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
LR["glowScale"] = "Scale свечения:"
LR["glowN"] = "Число свечения:"
LR["glowNTip"] = "Число свечения, количество частиц в Pixel Glow и Auto Cast Shine,\nв % HP процент на котором будет отображаться отметка "
LR["glowImage"] = "Изображение:"
LR.glowImageCustom = "Свое изображение:"

LR["glowOnlyText"] = "Только текст"
LR["glowOnlyTextTip"] = "Показывать только текст, без подсветки"

LR["GlowNameplate"] = "Подсветка неймплейта:"
LR["GlowNameplateTip"] = "Подсвечивает неймплейт по GUID ремайндера"
LR["UseCustomGlowColor"] = "Cвой цвет подсветки"

LR["On-Nameplate Text:"] = "Текст на неймплейте:"

LR.CurrentTriggerMatch = "Только совпадения с текущим триггером"




LR.HelpText =
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


UnitID условия - ID источника, ID цели
    UnitID условия чувствительны к пробелам, разделяються запятыми ,
    Операторы:
    |cffffff00x:y|r   - где x это npcID, а y это spawnIndex

    Пример условия 1: |cff00ff00154131,234156|r
    Данный пример подразумевает что npcID должны быть 154131 или 234156

    Пример условия 2: |cff00ff00154131:1,234156:2|r
    Данный пример подразумевает что npcID должны быть 154131 со spawnIndex 1 или 234156 со spawnIndex 2

|cff80ff00Гайд по типам счетчика|r

|cff00ff00По умолчанию|r - Добавляет +1 при каждом срабатывании триггера
|cff00ff00Для каждого Источника|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждого кастера
|cff00ff00Для каждой Цели|r - Добавляет +1 при каждом срабатывании триггера. Отдельный счетчик для каждой цели

|cff00ff00Наложение триггера|r - Добавляет +1 когда триггер активируеться в момент когда все
остальные триггеры активны
|cff00ff00Наложение триггера со сбросом|r - Добавляет +1 когда триггер активируеться в момент когда все
остальные триггеры активны. Сбрасывает счетчик до 0 когда ремайндер деактивируеться

|cff00ff00Общий для этого ремайндера|r - Добавляет +1 при каждом срабатывании триггера.
Общий счетчик с каждым триггером с таким же типом счетчика в этом ремайндере
|cff00ff00Сброс через 5 сек|r - Добавляет +1 при каждом срабатывании триггера.
Сбрасывает счетчик до 0 через 5 секунд после каждого срабатывания триггера



|cFFC69B6DСоветы от Мишка по использованию аддона!|r

1. Рекомендую ознакомиться с функционалом окна быстрой настройки.
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
