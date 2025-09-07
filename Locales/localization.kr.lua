---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

if MRT.locale ~= "koKR" and not (VMRT and VMRT.Reminder and VMRT.Reminder.ForceLocale == "ko") then
	return
end

---@class Locale
local LR = AddonDB.LR

LR.OutlinesNone = "없음"
LR.OutlinesNormal = "외곽선"
LR.OutlinesThick = "굵은 외곽선"
LR.OutlinesMono = "모노크롬"
LR.OutlinesMonoNormal = "모노크롬, 외곽선"
LR.OutlinesMonoThick = "모노크롬, 굵은 외곽선"

LR.RolesTanks = "탱커"
LR.RolesHeals = "힐러"
LR.RolesMheals = "근접 힐러"
LR.RolesMhealsTip = "근접 힐러: 성기사 및 운무"
LR.RolesRheals = "원거리 힐러"
LR.RolesRhealsTip = "원거리 힐러"
LR.RolesDps = "딜러"
LR.RolesRdps = "원거리 딜러"
LR.RolesMdps = "근접 딜러"

LR.spamType1 = "카운트다운과 함께 채팅 스팸"
LR.spamType2 = "채팅 스팸"
LR.spamType3 = "채팅 단일 스팸"

LR.spamChannel1 = "일반"
LR.spamChannel2 = "|cffff4040외침|r"
LR.spamChannel3 = "|cff76c8ff파티|r"
LR.spamChannel4 = "|cffff7f00공격대|r"
LR.spamChannel5 = "자체 채팅(print)"

LR.Reminders = "리마인더"
LR["Settings"] = "설정"
LR["Help"] = "도움말"
LR.Versions = "버전 체크"
LR.Trigger = "활성 조건 "
LR.AddTrigger = "활성 조건 추가"
LR.DeleteTrigger = "|cffee5555활성 조건 삭제|r"
LR.Source = "소스"
LR.Target = "대상"
LR.YellowAlertTip = "|cffffff00알림 기간과 활성 조건 활성화 시간은\n'시간이 지정되지 않은' 활성 조건이 0이 아니어야 함\n\n시간 지정되지 않은 활성 조건에서 활성화 시간을 지정하세요."
LR.EnvironmentalDMGTip = "1 - 낙사\n2 - 익사\n3 - 피로\n4 - 화염\n5 - 용암\n6 - 점액"
LR.DifficultyID = "난이도 ID:"
LR.Difficulty = "난이도:"
LR.EncounterID = "교전 ID:"
LR.CountdownFormat = "카운트다운 형식:"
LR.AddTextReplacers = "|cff80ff00↑↑ 텍스트 대체자|r"
LR["replaceDropDownTip"] = "|cff80ff00텍스트 대체자의 사용 가능한 목록입니다.\n메시지 텍스트, TTS, 채팅 스팸, 프레임 반짝임,\n이름표 텍스트, WeakAuras 이벤트 메시지 및\n추가 활성화 조건에서 사용할 수 있습니다|r.\n\n선택한 활성 조건에 따라 내용이 변경될 수 있습니다"
LR.WAmsgTip = "화면에 텍스트를 표시하는 대신 WeakAuras 이벤트를 Reminders가 보냅니다.\n|cff55ee55WeakAuras.ScanEvents|r에 대한 인수는 공백으로 구분됩니다."
LR.WAmsg = "WA 이벤트 보내기"
LR.GlowTip = "\n플레이어 이름 또는 |cff55ee55{targetName}|r 또는 |cff55ee55{sourceName}|r\n|cff55ee55{sourceName|cff80ff001|r}|r을 사용하여 활성 조건 번호를 지정합니다"
LR.SpamType = "메시지 유형:"
LR.SpamChannel = "채팅 채널:"
LR.spamMsg = "채팅 메시지:"
LR.ReverseTip = "플레이어 이름을 역순으로 로드"
LR.Reverse = "역순"
LR.Manually = "수동"
LR.ManuallyTip = "보스 ID, 난이도 ID, 인스턴스 ID 수동 설정"
LR.WipePulls = "기록 지우기"
LR.DungeonHistory = "던전 기록"
LR.RaidHistory = "레이드 기록"
LR.Duplicated = "중복됨"
LR.ListNotSentTip = "전송되지 않음"
LR.ClearImport = "데이터를 '지우고' 가져오는 중입니다\n|cffff0000모든 이전 알림이 삭제됩니다|r"
LR.ForceRemove = "모든 알림을 휴지통에서 삭제하시겠습니까?"
LR.ClearRemove = "휴지통을 비우시겠습니까?"
LR.CenterByX = "가로 중심 맞추기"
LR.CenterByY = "세로 중심 맞추기"
LR.EnableHistory = "|cff337AFF[필수]|r풀 기록 활성화"
LR.EnableHistoryRaid ="레이드 보스 주문 기록"
LR.EnableHistoryDungeon = "던전 보스 주문 기록"

LR.chkEnableHistory = "풀 기록 활성화"
LR.chkEnableHistoryTip = "빠른 설정 창을 위한 풀 기록을 저장합니다.\n비활성화 시 마지막 풀 이벤트는 계속 표시됩니다.\n|cffff0000***더 많은 전투를 저장하면 더 많은 리소스가 필요합니다.\n**비활성화 시 기록된 풀은 메모리에서 삭제됩니다."
LR.Add = "추가"
LR.SendAll = "모두 보내기"
LR.Boss = "보스:"

LR.Name = "이름:"
LR.delayTip = "MM:SS.MS - 1:35.5 또는 초 단위 시간\n쉼표로 구분하여 여러 개 입력 가능"
LR.delayTimeTip = "비워 둘 수 있습니다 - 즉시 활성 조건 활성화\n편의상 분 형식을 사용할 수 있습니다, 예: |cff00ff001:30.5|r - 90.5초 후에 작동합니다.\n여러 값을 쉼표로 구분하여 입력할 수 있습니다.\n|cff00ff00NOTE|r 값을 지정할 수 있습니다 - 메모 형식의 {time:x:xx} 값이 사용됩니다."
LR.delayText = "시간(초) :"
LR.duration = "지속 시간(초) :"
LR.durationTip = [[텍스트/반짝임/채팅 스팸의 지속 시간

지속 시간이 '0' 이면 알림이 비시간으로 간주되어
모든 활성 조건이 활성 상태일 때 표시됩니다]]
LR.countdown = "카운트다운:"
LR.msg = "화면 메시지:"
LR.sound = "소리:"
LR.soundOnHide = "숨길 때 소리:"
LR.voiceCountdown = "음성:"
LR.AllPlayers = "전체"
LR.notePatternEditTip = "도움말 참조 - 메모 패턴 로드"

LR.notePattern = "메모 패턴:"
LR.save = "저장"
LR.QuickSetup = "|cff00ffff빠른 설정(풀 기록) 보기|r"

LR.IgnoreTrigger = "활성 조건 무시(필터만 사용)"

LR.QS_PhaseRepeat = "단계 반복"
LR["QS_1"] = "전투 로그"
LR["QS_SPELL_CAST_START"] = "시전 시작"
LR["QS_SPELL_CAST_SUCCESS"] = "시전 성공"
LR["QS_SPELL_AURA_APPLIED"] = "오라 적용"
LR["QS_SPELL_AURA_REMOVED"] = "오라 제거"
LR["QS_2"] = "단계"
LR["QS_3"] = "Pull"
LR["QS_8"] = "채팅"
LR["QS_9"] = "새 프레임"
LR["QS_0"] = "전투 종료"

LR["Fight timer"] = "전투 시간:"
LR["Fight started"] = "전투 시작:"

LR.Always = "항상"

LR.SingularExportTip = "내보내기 창에 더 많은 알림을 추가하려면 내보내기 버튼을 클릭하세요"

LR.DeleteSection = "잠금 해제된 모든 항목을 삭제하시겠습니까"
LR.NoName = "이름 없음"
LR.RemoveSection = "잠금 해제된 모든 알림을 삭제합니다"
LR.PersonalDisable = "자신에게 비활성화"
LR.PersonalEnable = "자신에게 활성화"
LR.UpdatesDisable = "업데이트 비활성화"
LR.UpdatesEnable = "업데이트 활성화"
LR.SoundDisable = "소리 비활성화"
LR["SoundUpdatesDisable"] = "소리 및 TTS 업데이트 비활성화"
LR.Listduplicate = "복제"
LR.Listdelete = "삭제"
LR.ListdeleteTip = "삭제\n|cffffffff확인 없이 삭제하려면 shift 클릭"
LR.ListdExport = "내보내기"
LR.ListdSend = "전송"
LR["Stop this session"] = "이 알림 중지"

LR["Enabled"] = "활성화"
LR["EnabledTip"] = "리마인더 활성화/비활성화\n리마인더 전송 시 전송됩니다\n\n이 설정은 개인 활성화/비활성화 설정보다 우선합니다"

LR["Default State"] = "기본 상태"
LR["Default StateTip"] = "개인 활성화/비활성화 리마인더에 영향을 미칩니다\n\n|cff00ff00활성화|r - 기본적으로 리마인더가 활성화됩니다\n|cff00ff00비활성화|r - 기본적으로 리마인더가 비활성화됩니다"

LR.DeleteAll = "|cffff6666모두 삭제|r"
LR.ExportAll = "모두 내보내기"
LR.Import = "가져오기"
LR.Importwsc = "수락"
LR.Export = "내보내기"
LR.ImportTip = "Shift 클릭하면 클린 설치가 진행됩니다. 모든 이전 리마인더가 삭제됩니다."

LR.DisableSound = "소리 비활성화"
LR.Font = "글꼴"
LR.Outline = "외곽선"
LR.Strata = "계층"
LR.Justify = "정렬"

LR.OutlineChk = "그림자 활성화"
LR.CenterXTip = "수평으로 정렬"
LR.CenterYTip = "수직으로 정렬"

LR.GlobalCounter = "기본값"
LR.CounterSource = "각 소스별"
LR.CounterDest = "각 대상별"
LR.CounterTriggers = "활성 조건 중첩"
LR.CounterTriggersPersonal = "재설정된 활성 조건 중첩"
LR["Global counter for reminder"] = "이 알림의 공통 사항"
LR["Reset in 5 sec"] = "5초 후 재설정"

LR["GlobalCounterTip"] = "|cff00ff00기본값|r - 활성 조건이 활성화될 때마다 +1을 추가합니다"
LR["CounterSourceTip"] = "|cff00ff00각 소스별|r - 활성 조건이 활성화될 때마다 +1을 추가합니다. 각 시전자에 대한 개별 카운터"
LR["CounterDestTip"] = "|cff00ff00각 대상별|r - 활성 조건이 활성화될 때마다 +1을 추가합니다. 각 대상에 대한 개별 카운터"

LR["CounterTriggersTip"] = "|cff00ff00활성 조건 중첩|r - 모든 활성 조건이 활성화된 시간 동안 활성 조건이 활성화되면 +1을 추가합니다(중첩)"
LR["CounterTriggersPersonalTip"] = "|cff00ff00재설정된 활성 조건 중첩|r - 모든 활성 조건이 활성화되어 있는 시간(중첩)에 활성 조건이 활성화되면 +1을 추가합니다. 알림이 비활성화되면 카운터를 0으로 초기화합니다."

LR["CounterGlobalForReminderTip"] = "|cff00ff00이 알림의 공통 사항|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.\n이 알림의 동일한 카운터 유형을 가진 각 활성 조건에 대한 공통 사항입니다"
LR["CounterResetIn5SecTip"] = "|cff00ff005초 후 재설정|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.\n활성 조건이 활성화된 후 5초 후에 카운터를 0으로 재설정합니다"

LR.AnyBoss = "모든 보스"
LR.AnyNameplate = "모든 이름표"
LR.AnyRaid = "모든 레이드 멤버"
LR.AnyParty = "모든 파티 멤버"

LR.CombatLog = "전투 로그"
LR.BossPhase = "단계"
LR.BossPhaseTip = "단계 정보는 BigWigs 또는 DBM에서 가져옵니다\n활성화 지속 시간이 지정되지 않은 경우 활성 조건은 단계가 끝날 때까지 활성화됩니다"
LR.BossPhaseLabel = "단계 (이름/번호)"
LR.BossPull = "Pull"
LR.Health = "유닛 체력"
LR.HealthTip = "활성화 지속 시간이 지정되지 않은 경우 조건이 충족되는 동안 활성 조건은 활성화됩니다"
LR.ReplacertargetGUID = "GUID"
LR.Mana = "유닛 에너지"
LR.ManaTip = "활성화 지속 시간이 지정되지 않은 경우 조건이 충족되는 동안 활성 조건은 활성화됩니다"
LR.Replacerhealthenergy = "에너지 백분율"
LR.Replacervalueenergy = "에너지 값"
LR.BWMsg = "BigWigs/DBM 메시지"
LR.ReplacerspellNameBWMsg = "BigWigs/DBM 메시지 텍스트"
LR.BWTimer = "BigWigs/DBM 타이머"
LR.ReplacerspellNameBWTimer = "BigWigs/DBM 타이머 텍스트"
LR.Chat = "채팅 메시지"
LR.ChatHelp = "아군: 파티, 레이드, 귓속말\n적군: 일반, 외치기, 귓속말, 감정표현"
LR.BossFrames = "새 보스 프레임"
LR.Aura = "오라"
LR.AuraTip = "활성화 지속 시간이 지정되지 않은 경우 오라가 있는 동안 활성 조건은 활성화됩니다"
LR.Absorb = "유닛 흡수"
LR.AbsorbLabel = "흡수량"
LR.AbsorbTip = "활성화 지속 시간이 지정되지 않은 경우 조건이 충족되는 동안 활성 조건은 활성화됩니다"
LR.Replacervalueabsorb = "흡수량"

LR.CurTarget = "현재 대상"
LR.CurTargetTip = "활성화 지속 시간이 지정되지 않은 경우 조건이 충족되는 동안 활성 조건은 활성화됩니다"

LR.SpellCD = "주문 재사용 대기시간"
LR.SpellCDTooltip = "주문이 재사용 대기 중일 때 활성 조건이 활성화됩니다"
LR.SpellCDTip = "활성화 지속 시간이 지정되지 않은 경우 조건이 충족되는 동안 활성 조건은 활성화됩니다"

LR.SpellCastDone = "성공적으로 시전 완료"
LR.SpellCastDoneTooltip = ""
LR.ReplacersourceGUID = "소스 GUID"

LR.Widget = "위젯"
LR.WidgetLabelID = "위젯 ID"
LR.WidgetLabelName = "위젯 이름"
LR.WidgetTip = "위젯이 존재하는 동안 활성화됩니다"
LR.ReplacerspellIDwigdet = "위젯 ID"
LR.ReplacerspellNamewigdet = "위젯 이름"
LR.Replacervaluewigdet = "위젯 값"

LR.UnitCast = "유닛 캐스팅 중"
LR.UnitCastTip = "유닛이 캐스팅을 중지하거나 더 이상 사용할 수 없을 때 취소됩니다"

LR.CastStart = "시전 시작"
LR.CastDone = "시전 완료"
LR.AuraAdd = "+오라"
LR.AuraRem = "-오라"
LR.SpellDamage = "주문 피해"
LR.SpellDamageTick = "주문 피해 (틱)"
LR.MeleeDamage = "근접 피해"
LR.SpellHeal = "주문 치유"
LR.SpellHealTick = "주문 치유 (틱)"
LR.SpellAbsorb = "주문 흡수"
LR.CLEUEnergize = "자원 획득"
LR.CLEUMiss = "주문 빗나감"
LR.Death = "죽음"
LR.Summon = "소환 주문"
LR.Dispel = "해제 주문"
LR.CCBroke = "CC 해제"
LR.EnvDamage = "환경 피해"
LR.Interrupt = "주문 차단"

LR["ReplacerextraSpellIDSpellDmg"] = "총계"
LR["ReplacerextraSpellID"] = "차단된 주문"
LR["MissType"] = "빗나감 유형"
LR.MissTypeLabelTooltip = "사용 가능한 빗나감 유형:"
LR["ReplacerspellIDSwing"] = "총계"

LR["event"] = "이벤트:"
LR["eventCLEU"] = "전투 로그 이벤트:"

LR["UnitNameConditions"] = "여러 개를 지정할 수 있으며, \"|cffffff00;|r\"으로 구분합니다\n목록을 반전시키려면 첫 번째 문자로 \"|cffffff00-|r\"를 추가하세요 (즉,\n조건에 목록에 있는 이름을 제외한 모든 이름이 해당됩니다)"

LR["sourceName"] = "소스 이름:"
LR["sourceID"] = "소스 ID:"
LR["sourceUnit"] = "소스 조건:"
LR["sourceMark"] = "소스 표시:"

LR["targetName"] = "대상 이름:"
LR["targetID"] = "대상 ID:"
LR["targetUnit"] = "대상 조건:"
LR["targetMark"] = "대상 징표:"
LR["targetRole"] = "대상 역할:"

LR["spellID"] = "주문 ID:"
LR["spellName"] = "주문 이름:"
LR["extraSpellID"] = "추가 주문 ID:"
LR["extraSpellIDTip"] = "피해/치유의 경우 피해량\nCC 해제의 경우 차단된 주문의 ID\n해제의 경우 해제된 주문의 ID\n차단의 경우 차단된 주문의 ID"
LR["stacks"] = "중첩:"
LR["numberPercent"] = "퍼센트:"

LR["pattFind"] = "검색 패턴:"
LR["bwtimeleft"] = "남은 시간:"

LR["counter"] = "시전 번호:"
LR["cbehavior"] = "카운터 유형:"

LR["delayTime"] = "활성화 지연 시간:"
LR["activeTime"] = "활성화 지속 시간:"
LR["activeTimeTip"] = "비워 둘 수 있으며 여러 활성 조건이 있는 복잡한 조건에 유용합니다."

LR["invert"] = "반전:"
LR["guidunit"] = "GUID:"
LR["guidunitTip"] = "이름표 반짝임 및\n모든 알림 활성 조건에 대해 공통 유닛을 식별하는 옵션에 사용됩니다."
LR["onlyPlayer"] = "플레이어만:"

LR.MultiplyTip2 = "여러 개를 쉼표로 구분하여 지정할 수 있습니다."
LR.MultiplyTip3 = "사용 가능한 구문:"
LR.MultiplyTip4 = "|cffffff00[조건][번호]|r - 예: |cff00ff00>3|r (3 이후 모두), |cff00ff00<=2|r (첫 번째와 두 번째), |cff00ff00!4|r (넷째 제외 모두), |cff00ff005|r (다섯 번째만)"
LR.MultiplyTip4b = "|cffffff00[조건][번호]|r - 예: |cff00ff00<50.5|r (50.5 이하), |cff00ff00>=90|r (90 이상)"
LR.MultiplyTip5 = "|cffffff00[주기 내 번호]%[주기 길이]|r - 예: |cff00ff001%3|r (1,4,7,10,...), |cff00ff002%4|r (2,6,10,14,...)"
LR.MultiplyTip6 = "여러 조건이 있는 경우 (쉼표로 구분), 성공한 아무 조건이나 선택됩니다."
LR.MultiplyTip7 = "여러 조건을 \"|cffffff00+|r\" 기호로 결합할 수 있습니다 (쉼표도 있어야 함) - 예: |cff00ff00>3,+<7|r (3보다 크고 7보다 작은)"
LR.MultiplyTip7b = "여러 조건을 \"|cffffff00+|r\" 기호로 결합할 수 있습니다 (쉼표도 있어야 함) - 예: |cff00ff00>70,+<=75|r (70보다 크고 75보다 작거나 같은)"

LR["Send All For This Boss"] = "보내기 (이 보스)"
LR["Export All For This Boss"] = "내보내기 (이 보스)"
LR["Get last update time"] = "업데이트 날짜 확인"
LR["Clear Removed"] = "휴지통 비우기"
LR["Delete All Removed"] = "토큰 삭제(공대)"
LR["Deletes reminders from 'removed list' to all raiders"] = "휴지통에서 모든 공대에 대한 알림을 삭제합니다."

LR["NumberCondition"] = "도움말 참조 - 숫자 조건"
LR["MobIDCondition"] = "도움말 참조 - 몹 ID 조건"

LR["rtimeLeft"] = "남은 시간"
LR["rActiveTime"] = "활성 시간"
LR["rActiveNum"] = "활성화된 활성 조건 수"
LR["rMinTimeLeft"] = "최소 남은 시간"
LR["rTriggerStatus2"] = "활성 조건 상태"
LR["rTriggerStatus"] = "활성 조건 상태 (uid별)"
LR["rAllSourceNames"] = "모든 소스"
LR["rAllTargetNames"] = "모든 대상"
LR["rAllActiveUIDs"] = "모든 활성 UID"
LR["rNoteAll"] = "메모 패턴의 모든 플레이어"
LR["rNoteLeft"] = "메모에서 플레이어의 왼쪽"
LR["rNoteRight"] = "메모에서 플레이어의 오른쪽"
LR["rTriggerActivations"] = "활성 조건 활성화 수"
LR["rRemActivations"] = "리마인더 활성화 수"

LR["rsourceName"] = "소스 이름"
LR["rsourceMark"] = "소스 표시"
LR["rsourceGUID"] = "소스 GUID"
LR["rtargetName"] = "대상 이름"
LR["rtargetMark"] = "대상 표시"
LR["rtargetGUID"] = "대상 GUID"
LR["rspellName"] = "주문 이름"
LR["rspellID"] = "주문 ID"
LR["rextraSpellID"] = "추가 주문 ID"
LR["rstacks"] = "중첩"
LR["rcounter"] = "카운터"
LR["rguid"] = "활성 조건 GUID"
LR["rhealth"] = "체력 백분율"
LR["rvalue"] = "체력 값"
LR["rtext"] = "텍스트"
LR["rphase"] = "단계"
LR["rauraValA"] = "오라 값 1"
LR["rauraValB"] = "오라 값 2"
LR["rauraValC"] = "오라 값 3"

LR["rspellIcon"] = "주문 아이콘"
LR["rclassColor"] = "직업 색상"
LR["rspecIcon"] = "역할 아이콘"
LR["rclassColorAndSpecIcon"] = "역할 아이콘 및 직업 색상"
LR["rplayerName"] = "플레이어 이름"
LR["rplayerClass"] = "플레이어 직업"
LR["rplayerSpec"] = "플레이어 전문화"
LR["rPersonalIcon"] = "갠생기 아이콘"
LR["rImmuneIcon"] = "무적기 아이콘"
LR["rSprintIcon"] = "이속 증가 아이콘"
LR["rHealCDIcon"] = "힐업기 쿨다운 아이콘"
LR["rRaidCDIcon"] = "공생기 쿨다운 아이콘"
LR["rExternalCDIcon"] = "외생기 쿨다운 아이콘"
LR["rFreedomCDIcon"] = "발풀기 쿨다운 아이콘"

LR["rsetparam"] = "변수 설정"
LR["rmath"] = "산술 표현식"
LR["rnoteline"] = "메모 줄"
LR["rnote"] = "위치가 있는 메모 줄"
LR["rnotepos"] = "위치가 있는 메모의 플레이어"
LR["rmin"] = "최소 값"
LR["rmax"] = "최대 값"
LR["rrole"] = "플레이어 역할"
LR["rextraRole"] = "추가 플레이어 역할"
LR["rsub"] = "문자열 추출"
LR["rtrim"] = "양쪽 공백 제거"

LR["rnum"] = "선택"
LR["rup"] = "대문자"
LR["rlower"] = "소문자"
LR["rrep"] = "반복"
LR["rlen"] = "길이 제한"
LR["rnone"] = "없음"
LR["rcondition"] = "예-아니오 조건"
LR["rfind"] = "찾기"
LR["rreplace"] = "교체"
LR["rsetsave"] = "저장"
LR["rsetload"] = "로드"

LR["rtimeLeftTip"] = "|cffffff00{timeLeft|cff00ff00x|r:|cff00ff00y|r}|r\n활성 조건의 남은 시간,\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)\n|cff00ff00y|r - 소수점 자릿수"
LR["rActiveTimeTip"] = "|cffffff00{activeTime|cff00ff00x|r:|cff00ff00y|r}|r\n활성 조건의 활성 시간,\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)\n|cff00ff00y|r - 소수점 자릿수"
LR["rActiveNumTip"] = "|cffffff00{activeNum}|r\n활성화된 활성 조건의 수"
LR["rMinTimeLeftTip"] = "|cffffff00{timeMinLeft|cff00ff00x|r:|cff00ff00y|r}|r\n활성화된 활성 조건 또는 활성 조건 내 활성 상태 중 최소 남은 시간을 표시합니다\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)\n|cff00ff00y|r - 소수점 자릿수"
LR["rTriggerStatusTip"] = "|cffffff00{status:|cff00ff00x|r:|cff00ff00guid|r}|r\n활성 조건 내에서 GUID의 현재 상태를 표시합니다, |cff00ff00on|r은 활성 상태, |cff00ff00off|r은 비활성 상태\n|cff00ff00x|r - 활성 조건 번호\n|cff00ff00guid|r - 활성 조건 GUID"
LR["rTriggerStatus2Tip"] = "|cffffff00%status|cff00ff00x|r|r\n활성 조건의 현재 상태를 표시합니다, |cff00ff00on|r은 활성 상태, |cff00ff00off|r은 비활성 상태\n|cff00ff00x|r - 활성 조건 번호"
LR["rAllSourceNamesTip"] = "|cffffff00%allSourceNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\n모든 소스 이름을 표시합니다,\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)\n소스를 |cff00ff00num1|r부터 |cff00ff00num2|r까지 제한할 수 있습니다,\n|cff00ff00pat|r = 1은 이름을 색상 없이 표시하고, 다른 값은 이름을 자체적으로 교체합니다"
LR["rAllTargetNamesTip"] = "|cffffff00%allTargetNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\n모든 대상 이름을 표시합니다,\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)\n대상을 |cff00ff00num1|r부터 |cff00ff00num2|r까지 제한할 수 있습니다,\n|cff00ff00pat|r = 1은 이름을 색상 없이 표시하고, 다른 값은 이름을 자체적으로 교체합니다"
LR["rAllActiveUIDsTip"] = "|cffffff00%allActiveUIDs|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r|r\n모든 활성 GUID를 표시합니다,\nGUID를 |cff00ff00num1|r부터 |cff00ff00num2|r까지 제한할 수 있습니다\n|cff00ff00x|r - 활성 조건 번호 (선택 사항)"
LR["rTriggerActivationsTip"] = "|cffffffff|cffffff00{triggerActivations:|cff00ff00x|r}|r\n활성 조건 활성화 수\n|cff00ff00x|r - 활성 조건 번호"
LR["rRemActivationsTip"] = "|cffffffff|cffffff00{remActivations}|r\n리마인더 활성화 수"

LR["rcounterTip"] = "|cffffff00{counter|cff00ff00x|r:|cff00ff00y|r}|r\n현재 카운터, |cff00ff00x|r - 활성 조건 번호 (선택 사항),\n|cff00ff00y|r는 나누기를 위한 값을 지정할 수 있습니다"

LR["rspellIconTip"] = "|cffffff00{spell:|cff00ff00id|r:|cff00ff00size|r}|r\n|cff00ff00id|r - 주문 ID\n|cff00ff00size|r - 아이콘 크기 (선택 사항)"
LR["rclassColorTip"] = "|cffffff00%classColor |cff00ff00Name|r|r\n|cff00ff00Name|r을 직업 색상으로 칠합니다"
LR["rspecIconTip"] = "|cffffff00%specIcon |cff00ff00Name|r|r\n|cff00ff00Name|r에 대한 역할 아이콘을 표시합니다"
LR["rclassColorAndSpecIconTip"] = "|cffffff00%specIconAndClassColor |cff00ff00Name|r|r\n역할 아이콘을 표시하고 |cff00ff00Name|r을 직업 색상으로 칠합니다"

LR["rsetparamTip"] = "|cffffff00{setparam:|cff00ff00key|r:|cff00ff00value|r}|r\n현재 리마인더에 대해 로컬 변수 |cff00ff00key|r를 설정합니다,\n나중에 {#|cff00ff00key|r}로 호출할 수 있습니다"
LR["rmathTip"] = "|cffffff00{math:|cff00ff00x+y-zf|r}|r\n여기서 |cff00ff00x y z|r는 수학적 계산에서 숫자입니다,\n연산자 + - * / %(나머지)\nf - 반올림 모드\nf - 내림\nc - 올림\nr - 반올림"
LR["rnotelineTip"] = "|cffffff00{noteline:|cff00ff00patt|r}|r\n메모에서 |cff00ff00patt|r로 시작하는 줄"
LR["rnoteTip"] = "|cffffff00{note:|cff00ff00pos|r:|cff00ff00patt|r}|r\n메모 줄에서 단어\n|cff00ff00pos|r - 줄에서 단어의 순서 번호\n|cff00ff00patt|r - 메모에서 검색할 줄의 시작\n\n메모의 위치는 순환됩니다\n예: 총 5개의 위치가 있는 경우, |cff00ff00pos|r = 6이면 |cff00ff00pos|r = 1"
LR["rnoteposTip"] = "|cffffff00{notepos:|cff00ff00y|r:|cff00ff00x|r}|r\n현재 리마인더의 메모 형식에서 시작하는 메모 줄의 플레이어를 표시합니다 (자세한 내용은 \"도움말\" 탭을 참조하세요)\n|cff00ff00y|r - \"메모 블록\"에서 줄의 위치 또는 \"메모 줄\"에서 플레이어의 위치,\n|cff00ff00x|r - \"메모 블록\"의 |cff00ff00y|r 줄에서 플레이어의 위치입니다.\n\"메모 블록\"에서 |cff00ff00x|r가 생략된 경우 전체 줄을 표시합니다"
LR["rminTip"] = "|cffffff00{min:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r - 숫자\n|cff00ff00;|r 또는 |cff00ff00,|r로 구분할 수 있습니다"
LR["rmaxTip"] = "|cffffff00{max:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r - 숫자\n|cff00ff00;|r 또는 |cff00ff00,|r로 구분할 수 있습니다"
LR["rroleTip"] = "|cffffff00{role:|cff00ff00name|r}|r\n|cff00ff00name|r - 역할을 표시할 플레이어 이름\n역할: tank, healer, damager, none"
LR["rextraRoleTip"] = "|cffffff00{roleextra:|cff00ff00name|r}|r\n|cff00ff00name|r - 추가 역할을 표시할 플레이어 이름\n추가 역할: mdd, rdd, mhealer, rhealer, none"
LR["rsubTip"] = "|cffffff00{sub:|cff00ff00pos1|r:|cff00ff00pos2|r:|cff00ff00text|r}|r\n|cff00ff00pos1|r부터 |cff00ff00pos2|r까지의 |cff00ff00text|r를 표시합니다"
LR["rtrimTip"] = "|cffffff00{trim:|cff00ff00text|r}|r\n|cff00ff00text|r - 공백을 제거할 텍스트"

LR["rnumTip"] = "|cffffff00{num:|cff00ff00x|r}|cff00ff00a;b;c;d|r{/num}|r\n|cff00ff00x|r 번호에 해당하는 줄을 선택합니다. |cff00ff00a|r - 1, |cff00ff00b|r - 2, |cff00ff00c|r - 3, |cff00ff00d|r - 4\n\n예: |cff00ff00{num:%counter2}왼쪽;오른쪽;앞으로{/num}|r"
LR["rupTip"] = "|cffffff00{up}|cff00ff00string|r{/up}|r\n|cff00ff00string|r을 대문자로 표시합니다"
LR["rlowerTip"] = "|cffffff00{lower}|cff00ff00STRING|r{/lower}|r\n|cff00ff00string|r을 소문자로 표시합니다"
LR["rrepTip"] = "|cffffff00{rep:|cff00ff00x|r}|cff00ff00line|r{/rep}|r\n|cff00ff00line|r을 |cff00ff00x|r번 반복합니다"
LR["rlenTip"] = "|cffffff00{len:|cff00ff00x|r}|cff00ff00line|r{/len}|r\n|cff00ff00line|r의 길이를 |cff00ff00x|r 문자로 제한합니다"
LR["rnoneTip"] = "|cffffff00{0}|cff00ff00line|r{/0}|r\n빈 줄을 표시합니다"
LR["rconditionTip"] = ("|cffffff00{cond:|cff00ff001<2 AND 1=1|r}|cff00ff00예;아니오|r{/cond}|r\n조건이 일치하면 \"예\" 메시지를, 일치하지 않으면 \"아니오\" 메시지를 표시합니다.\n예: |cff00ff00{cond:%targetName=$PN$}solo;soak{/cond}|r\n\n여러 조건을 사용할 수 있습니다 (어느 하나라도 성공하면 선택됩니다)\n|cff00ff00{cond:condition1=condition2;condition3;condition4}예;아니오{/cond}|r\n\n숫자 비교를 위해서는 크거나 작음 기호를 사용할 수 있습니다\n예: |cff00ff00{cond:%health<20}DPS;STOP DPS{/cond}|r\n\nAND 및 OR 단어로 여러 조건을 연결할 수 있습니다\n예시:\n|cff00ff00{cond:%health<20 OR %health>80}EXECUTE{/cond}|r\n|cff00ff00{cond:%playerClass=shaman AND %playerSpec=restoration}RSHAM;NOT RSHAM{/cond}|r"):gsub("%$PN%$",UnitName("player"))
LR["rfindTip"] = "|cffffff00{find:|cff00ff00patt|r:|cff00ff00text|r}|cff00ff00예;아니오|r{/find}|r\ntext에서 patt를 찾습니다. 일치 여부에 따라 예 또는 아니오를 표시합니다"
LR["rreplaceTip"] = "|cffffff00{replace:|cff00ff00x|r:|cff00ff00y|r}|cff00ff00text|r{/replace}|r\ntext에서 x를 y로 교체합니다"
LR["rsetsaveTip"] = "|cffffff00{set:|cff00ff001|r}|cff00ff00text|r{/set}|r\n텍스트를 '|cff00ff001|r' 키로 저장합니다"
LR["rsetloadTip"] = "|cffffff00%set|cff00ff001|r|r\n이 예에서 키 '|cff00ff001|r'로 저장된 텍스트를 불러옵니다"

LR.LastPull = "마지막 풀"

LR.copy = "중복 숨기지 않기"
LR.copyTip = "알림이 이미 활성화된 경우 중복이 나타납니다"

LR.norewrite = "덮어쓰지 않기"
LR.norewriteTip = "알림이 이미 활성화된 경우 첫 번째 반복을 덮어쓰지 않습니다"

LR.dynamicdisable = "동적 업데이트 비활성화"
LR.dynamicdisableTip = "동적 텍스트 교체는 알림이 나타날 때만 정보를 업데이트합니다"

LR.isPersonal = "리마인더 전송 안 함"
LR.isPersonalTip = "리마인더를 개인용으로 만들며, 다른 플레이어에게 전송할 수 없습니다"

LR["AdditionalOptions"] = "추가 옵션:"
LR["Show Removed"] = "휴지통 보기"

LR.Zone = "인스턴스:"
LR.ZoneID = "인스턴스 ID"
LR.ZoneTip = "지역 ID와 다름, 인스턴스는 개별 대륙 또는 던전/레이드입니다"

LR.searchTip = "보스 이름, 리마인더 이름, 메시지, 채팅 메시지, TTS, 이름표 텍스트, 프레임 반짝임 및 이름별 로드에서 일치하는 항목을 검색합니다. 여러 단어로 검색하려면 `|` 또는 ` or `를 사용할 수 있습니다.\n\n예시: `화염|냉기` 또는 `화염 or 냉기`"

LR.search = "검색"

LR.BossKilled = "보스 처치"
LR.BossNotKilled = "보스 미처치"

LR["Raid group number"] = "레이드 파티 번호"

LR["GENERAL"] = "일반"
LR["LOAD"] = "로드 조건"
LR["TRIGGERS"] = "활성 조건"
LR["OTHER"] = "기타"

LR["doNotLoadOnBosses"] = "보스에서\n로드하지 않기"

LR["specialTarget"] = "GUID 대체:"
LR["specialTargetTip"] = "알림의 기본 GUID를 대체합니다. unitToken 또는 %target/source(활성 조건 번호)를 사용하세요.\n예: |cff55ee55%source1|r 또는 |cff55ee55target|r 또는 |cff55ee55boss3|r"
LR["extraCheck"] = "추가 활성화 조건:"

LR.sametargets = "활성 조건의 동일한 대상"
LR.sametargetsTip = "모든 활성 조건(1개 이상)의 유닛이 동일한 경우에만 표시됨"

LR.NameplateGlowTypeDef = "기본값"
LR.NameplateGlowType1 = "픽셀 반짝임"
LR.NameplateGlowType2 = "동작 버튼 반짝임"
LR.NameplateGlowType3 = "자동시전 빛남"
LR.NameplateGlowType4 = "스킬 발동 반짝임"

LR["AIM"] = "시각적"
LR["Solid color"] = "단색"
LR["Custom icon above"] = "커스텀 아이콘 위"
LR["% HP"] = "% HP"

LR["glowType"] = "반짝임 유형:"
LR["glowColor"] = "반짝임 색상:"
LR["glowThick"] = "반짝임 두께:"
LR["glowThickTip"] = "반짝임 두께 (기본값 2)"
LR["glowScale"] = "반짝임 크기:"
LR["glowScaleTip"] = "반짝임 크기 (기본값 1)"
LR["glowN"] = "반짝임 수:"
LR["glowNTip"] = "반짝임 수, 스킬 발동 반짝임 및 자동시전 빛남의 입자 수,\n% HP에서 표시될 백분율"
LR["glowImage"] = "이미지:"
LR.glowImageCustom = "커스텀 이미지:"

LR["glowOnlyText"] = "텍스트만"
LR["glowOnlyTextTip"] = "반짝임 없이 텍스트만 표시"

LR["nameplateGlow"] = "네임플레이트 반짝임:"
LR["nameplateGlowTip"] = "알림의 GUID로 이름표를 반짝임"
LR["UseCustomGlowColor"] = "커스텀 반짝임 색상 사용"

LR["On-Nameplate Text:"] = "이름표 텍스트:"

LR.CurrentTriggerMatch = "현재 활성 조건과 일치하는 항목만"

LR.SyncAllConfirm = "모든 리마인더를 전송하시겠습니까?"

LR.noteIsBlock = "할당 메모"
LR.noteIsBlockTip = "메모 패턴 검색은 MateStart에서 MateEnd 사이의 블록 내에서 수행됩니다.\n\n예:\nMateStart\n까치킹\n재혁드\n양준수\nMateEnd"

LR["Tip!"] = "팁"
LR["GeneralBFTip"] = "|cffffffff보스/인스턴스 로드는 OR 논리로 작동합니다. 즉,\n보스와 인스턴스가 모두 지정된 경우 하나라도\n일치하면 리마인더가 로드됩니다.\n난이도는 보스로 로드할 때만 확인됩니다"
LR["LoadBFTip"] = [[|cffffffff다음 조건으로 로드를 수행할 수 있습니다: 직업, 역할, 파티 번호, 이름, 메모.
각 조건 내에서 적어도 하나의 일치가 있어야 합니다, 즉 OR 논리입니다.

예: 전사, 성기사 직업 로드.
    - 플레이어가 전사 또는 성기사인 경우 리마인더가 로드됩니다.

여러 로드 조건을 사용할 경우, 리마인더는 모든 조건이 충족되면
로드됩니다, 즉 AND 논리입니다.

예: 전사, 성기사 및 탱커 역할 로드.
    - 플레이어가 전사 또는 성기사이고 탱커인 경우 리마인더가 로드됩니다.
    - 플레이어가 전사 또는 성기사이고 탱커가 아닌 경우 리마인더가 로드되지 않습니다.

메모 로드에 대한 정보는 도움말 탭을 참조하세요.]]

LR["TriggerBFTip"] = [[|cffffffff이 툴팁의 정보는 오직 |cff80ff00고급|r 리마인더에만 해당됩니다.

리마인더 지속 시간이 0인 경우, 시간이 지정되지 않은 것으로 간주되며
리마인더 활성 조건이 충족되는 동안 표시됩니다.

일부 활성 조건은 특정 지속 시간이 없을 수 있습니다 (지정되지 않은 경우).
예:
    - 단계 활성 조건은 보스가 지정된 단계에 있는 동안 활성화됩니다.
    - 유닛 체력 활성 조건은 유닛이 지정된 체력 범위에 있는 동안 활성화됩니다.
    - 전투 로그 활성 조건은 타이밍을 지정할 수 없으므로,
      리마인더에서 전투 로그 활성 조건의 경우 항상 활성화 지속 시간을 지정해야 합니다.
]]

LR.Snippets = "저장소"
LR.ShowSnippets = "|cff00ffff저장소 보기|r"
LR.SaveCurrent = "현재 저장"

LR.Comment = "설명:"

LR["Last Sync:"] = "마지막 동기화: "
LR["Never"] = "없음"
LR["New Update"] = "새 업데이트"
LR["Update last sync time"] = "마지막 동기화 날짜 갱신\n\n수신자의 마지막 업데이트 날짜가\n귀하의 동기화 날짜보다 크거나 같으면 업데이트를 받지 못합니다"
LR["Send to:"] = "수신자:"
LR["CustomReceiverTip"] = "특정 플레이어에게 WA 보내기"
LR["Import Mode:"] = "모드:"

LR.DefText = "보통 텍스트"
LR.BigText = "큰 텍스트"
LR.SmallText = "작은 텍스트"

LR["Big Font Size"] = "큰 알림 메시지 크기"
LR["Normal Font Size"] = "보통 알림 메시지 크기"
LR["Small Font Size"] = "작은 알림 메시지 크기"

LR["10 Player Raid"] = "10인 공격대"
LR["10 Player Raid (Heroic)"] = "10인 공격대 (영웅)"
LR["10 Player Raid (Normal)"] = "10인 공격대 (일반)"
LR["20 Player Raid"] = "20인 공격대"
LR["25 Player Raid"] = "25인 공격대"
LR["25 Player Raid (Heroic)"] = "25인 공격대 (영웅)"
LR["25 Player Raid (Normal)"] = "25인 공격대 (일반)"
LR["40 Player Raid"] = "40인 공격대"
LR["Raid"] = "공격대"
LR["Raid (Heroic)"] = "공격대 (영웅)"
LR["Raid (Mythic)"] = "공격대 (신화)"
LR["Raid (Normal)"] = "공격대 (일반)"
LR["Raid (Timewalking)"] = "공격대 (시간여행)"
LR["Looking for Raid"] = "공격대 찾기"
LR["Legacy Looking for Raid"] = "구 공격대 찾기"
LR["Dungeon (Heroic)"] = "던전 (영웅)"
LR["Dungeon (Mythic)"] = "던전 (신화)"
LR["Dungeon (Mythic+)"] = "던전 (신화+)"
LR["Dungeon (Normal)"] = "던전 (일반)"
LR["Dungeon (Timewalking)"] = "던전 (시간여행)"
LR["Mythic Keystone"] = "신화 쐐기돌"
LR["Scenario (Heroic)"] = "시나리오 (영웅)"
LR["Scenario (Normal)"] = "시나리오 (일반)"
LR["Island Expedition (Heroic)"] = "군도 탐험 (영웅)"
LR["Island Expedition (Mythic)"] = "군도 탐험 (신화)"
LR["Island Expedition (Normal)"] = "군도 탐험 (일반)"
LR["Island Expeditions (PvP)"] = "군도 탐험 (PvP)"
LR["Warfront (Heroic)"] = "격전지 (영웅)"
LR["Warfront (Normal)"] = "격전지 (일반)"
LR["Visions of N'Zoth"] = "느조스의 환영"
LR["Torghast"] = "토르가스트"
LR["Path of Ascension: Courage"] = "승천의 길: 용기"
LR["Path of Ascension: Humility"] = "승천의 길: 겸손"
LR["Path of Ascension: Loyalty"] = "승천의 길: 충성"
LR["Path of Ascension: Wisdom"] = "승천의 길: 지혜"
LR["Normal Party"] = "일반 파티"
LR["Heroic Party"] = "영웅 파티"

LR["CUSTOM"] = "커스텀"

LR["Now"] = "현재"

LR["Show On Ready Check"] = "전투 준비 시 표시"
LR["Dont Show On Mythic"] = "신화 난이도에서 표시하지 않기"

LR["Hold shift while opening to show full encounters list"] = "전체 보스 목록을 보려면\nshift 클릭"

LR["errorLabel1"] = "리마인더에 오류가 있습니다."
LR["errorLabel2"] = "아래 오류를 보내주세요."
LR["errorLabel3"] = "복사하려면 CTRL + C를 누르세요"
LR["copiedToClipboard"] = "복사됨"
LR["Copy error"] = "오류 복사"

LR["ChooseEncounter"] = "보스 선택"

LR["Save history between sessions"] = "|cff337AFF[필수]|r전투 간 빠른 설정(풀 기록) 저장"
LR["May cause fps spike on end of the boss fight"] = "|cffff0000보스 전투 종료 후 FPS 저하를 유발할 수 있습니다|r"

LR["Amount of pulls to save\nper boss and difficulty"] = "각 보스 및 난이도별로 저장할 풀 수"

LR["Any Click:"] = "아무 클릭:"
LR["Normal Click:"] = "일반 클릭:"
LR["Shift Click:"] = "Shift 클릭:"
LR["Ctrl Click:"] = "Ctrl 클릭:"
LR["Difficulty:"] = "난이도:"
LR["Spells Blacklist"] = "블랙리스트"
LR["Add to blacklist: "] = "블랙리스트에 추가: "
LR["|cffff8000Shift click to remove from blacklist|r"] = "|cffff8000Shift 클릭으로 블랙리스트에서 제거|r"
LR["|cffff8000Shift click to delete|r"] = "|cffff8000Shift 클릭으로 삭제|r"
LR["Filters"] = "필터"
LR["Filters ignored because of trigger:"] = "활성 조건으로 인해 무시된 필터:"
LR["|cffff8000Trigger reset|r"] = "|cffff8000활성 조건 리셋|r"
LR["Use source counters"] = "소스 카운터 사용"

LR["Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"] = "레이드 외부의 플레이어에 대한 기록 전송을 활성화하고 해당 플레이어에 대한 기록을 수락합니다"
LR["History transmission"] = "|cff337AFF[필수]|r빠른 설정(풀 기록) 전송 활성화"

LR["Accept Reminders while not in a raid group"] = "레이드 그룹 외부에서도 리마인더 수락"
LR["Alternative color scheme for reminders list"] = "리마인더 목록 대체 색상 적용"
LR["Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"] = "압축을 사용하여 대량의 데이터 저장"

LR["Aura not updated"] = "오라 업데이트 안됨"
LR["Aura updated"] = "오라 업데이트 됨"
LR["User didn't respond"] = "응답하지 않음"

LR.WASyncLineNameTip1 = "WA 보유 확인은 이름 클릭\n버전 확인은 오른쪽 클릭\nWA 채팅 링크는 Shift 클릭"
LR.WASyncLineNameTip2 = "사용자의 WeakAuras 애드온 버전을 확인하려면 줄 이름을 클릭하세요"
LR["Left Click to share"] = "전송 팝업 ▶ |cff8bd6f6왼쪽 클릭|r"
LR["Right Click to check versions"] = "버전 확인 ▶ |cff8bd6f6오른쪽 클릭|r"
LR["Pressing while holding |cff00ff00shift|r will add WA to queue but wont start sending\n\nPressing while holding |cff00ff00alt|r will not update last sync time for current WA(ignoring checkbox)\n\nPressing while holding |cff00ff00ctrl|r will start sending WAs added to queue"] = "|cff00ff00shift|r 클릭하면 WA가 대기열에 추가만 되고 전송 시작 안함\n\n|cff00ff00alt|r 클릭하면 WA의 마지막 동기화 시간이 업데이트되지 않음\n\n|cff00ff00ctrl|r 클릭하면 대기열에 추가된 WA 전송 시작"

LR["Load Current Note"] = "현재 메모 로드"
LR["Analyze Highlighted Text"] = "블록 씌운 텍스트 분석"
LR["Analyze All/Highlighted Text"] = "모든/블록 씌운 텍스트 분석"
LR["Send Note"] = "메모 전송"
LR["Note is empty. Probably a bug?"] = "메모가 비어 있습니다"
LR["Groups:"] = "파티 수:"
LR["Replace only in highlighted text"] = "블록 씌운 텍스트만 교체"
LR["Allow numbers in names"] = "이름에 숫자 허용"
LR["Allow non letter symbols in names"] = "이름에 문자 외 기호 허용"
LR["Non letter symbols are:"] = "문자 외 기호:"
LR["Allow # symbol in names"] = "이름에 # 기호 허용"

LR["Shift click to use default glow color"] = "Shift 클릭으로 기본 반짝임 색상 사용"
LR["Player names to glow\nMay use many separated by\nspace comma or semicolomn"] = "반짝임할 플레이어 이름\n여러 개를 공백, 쉼표 또는 세미콜론으로 구분"

LR["For untimed reminders use {timeLeft} text replacer"] = "시간 지정되지 않은 리마인더에는 {timeLeft} 텍스트 대체자를 사용하세요"

LR["Hisory recording disabled"] = "빠른 설정(풀 기록) 비활성화됨"

LR["onlyPlayerTip"] = "대상이 플레이어인 경우에만 리마인더 표시.\n대상이 플레이어가 아닌 경우에도 카운터는 증가합니다"
LR["invertTip"] = "리마인더를 활성화하는 데 필요한 활성 조건 상태를 반전시킵니다"

LR["Marked To Send"] = "전송으로 표시됨"
LR["Was ever sent"] = "한 번이라도 전송됨"
LR["Updated less then 2 weeks ago"] = "2주 이내에 업데이트됨"

LR["rtextNote"] = "알림/아이콘"
LR["rtextNoteTip"] = "알림에 아이콘만 포함된 경우 3개의 아이콘\n그 외에는 단순히 알림만 표시"

LR["rtextModIcon"]= "알림/아이콘과 수정자"
LR["rtextModIcon:X:Y"] = LR["rtextModIcon"]
LR["rtextModIconTip"] = "알림/아이콘과 동일하지만 추가 설정이 있습니다\n\n|cffffff00{textModIcon:|cff00ff00X|r:|cff00ff00Y|r:|cff00ff00patt|r}|r\n|cff00ff00X|r - 아이콘 크기\n|cff00ff00Y|r - 아이콘 수\n|cff00ff00patt|r - 조건\n조건이 지정된 경우 알림에 패턴이 일치하면 아이콘의 크기와 수가 적용됩니다. 여러 패턴을 세미콜론(;)으로 구분하여 지정할 수 있습니다.\n예: |cff00ff00{textModIcon:25:4:6442;1022;Personals|r}|r"

LR["Note timers"] = "메모 타이머"
LR["Note timers [all]"] = "메모 타이머 (전체)"

LR["rfullLine"] = "전체 줄"
LR["rfullLineClear"] = "전체 줄(괄호 {} 없음)"
LR["MRTNoteTimersComment"] = "Kaze MRT Timers와 유사하게 메모 표시.\n\nViserio의 자동 생성 메모와 호환.\n\n기본 셋팅은 리마인더를 개인용으로 설정하여 다른 플레이어에게 전송되지 않음."

LR["Send All (This Zone)"] = "모두 전송 (이 구역)"
LR["Current difficulty:"] = "현재 난이도:"

LR["ZoneIDTip1"] = "무시하려면 비워두세요\n여러 개를 쉼표로 구분하여 입력할 수 있습니다\n현재 구역: "
LR["ZoneIDTip2"] = "\n현재 구역 ID: "
LR["Current instance"] = "현재 인스턴스"
LR["Current difficulty"] = "현재 난이도"

LR.OutdatedVersionAnnounce = "%q의 버전이 오래되었습니다.\n최신 버전으로 업데이트하세요.\n\n최신 버전: %s\n귀하의 버전: %s"

LR["Text color"] = "텍스트 색상"

LR.Alert = "경고!"
LR.AlertFieldReq = "이 입력란은 반드시 채워야 합니다."
LR.AlertFieldSome = "표시된 항목은 모두 채워야 합니다."

LR.TriggerOptionsGen = "일반 활성 조건 설정"
LR.TriggerTipIgnored = "활성 조건 %s가 무시됨"
LR.SpellIDBWTip = "BigWigs/DBM 애드온에서 사용하는 주문ID. 이 주문ID는 BW/DBM 보스 페이지의 오른쪽 상단에 있는 기능별 검색 상자에서 찾을 수 있습니다."

LR["No Mark"] = "징표 없음"

LR["ActionDelete"] = "리마인더 삭제"
LR["ActionSend"] = "리마인더 전송"

LR.msgSize = "메시지 유형:"

LR.LoadAlert1 = "로드 조건이 설정되지 않음"
LR.LoadAlert2 = "보스, 구역 또는 난이도 조건을 설정할 수 있습니다."
LR.tts = "TTS:"
LR.glow = "반짝임:"

LR["Setup trigger"] = "활성 조건 설정"

LR["Required fields must be filled:"] = "필수 입력란은 반드시 채워야 합니다:"
LR["Any of those fields must be filled:"] = "다음 입력란 중 하나를 채워야 합니다:"

LR["Available replacers:"] = "|cff80ff00사용 가능한 텍스트 대체자:|r"
LR["Detach"] = "분리"

LR["BWEnableTip1"] = "보스 모듈 교체가 비활성화되었습니다. 모듈을 원래 상태로 되돌리려면 \"/reload\"를 입력하세요."
LR["BWModName"] = "보스 모듈 이름"
LR["BWSelectBoss"] = "보스 선택"
LR["BWAddOptions"] = '추가 옵션'

LR["Update inviters list"] = "초대자 목록 업데이트"

LR.RGList = "MT 목록:"
LR.RGConditions = "목록 조건:"
LR.RGConditionsTip = [[|cffffffff여러 값을 입력할 수 있으며, 기본적으로 그 중 하나라도 충족하면 조건을 통과합니다. |cffffff00+|r로 여러 조건을 조합하면, 조건이 누적 적용됩니다.

|cffffff00-|r를 모든 조건 앞에 붙이면 조건이 반전되어, 조건을 충족하지 않을 때 통과로 간주됩니다.

|cffffff00R|r을 조건 앞에 붙이면 리스트의 순서가 반대로 적용되어 확인합니다. 예: R1 - 리스트의 마지막 플레이어, R1/3 - 리스트의 마지막 1/3 구간

|cffffff00x|r - 리스트에서 x번째 플레이어만 조건을 통과합니다
|cffffff00x%y|r - y마다 x번째부터, 예: 2%3 - 2, 5, 8, 11번째 등
|cffffff00x-y|r - x부터 y까지 범위에 속한 플레이어는 조건을 통과합니다. 예: 2-4 - 2, 3, 4번째
|cffffff00x/y|r - 리스트를 y개로 나누고, x번째 구간에 속하면 조건을 통과합니다. 균등하게 나눌 수 없을 경우 앞쪽 구간이 더 많아집니다. 예: 10명을 3구간으로 나누면 4, 3, 3명씩(1-4, 5-7, 8-10)

|cffffff00>=x|r - 플레이어의 위치가 x 이상일 때
|cffffff00>x|r - 플레이어의 위치가 x 초과일 때
|cffffff00<=x|r - 플레이어의 위치가 x 이하일 때
|cffffff00<x|r - 플레이어의 위치가 x 미만일 때
|cffffff00!x|r - 플레이어가 리스트의 x번째가 아닐 때

누적 조건 예시:
|cffffff001/3,+!R6|r - 리스트의 첫 1/3에 속하면서, 끝에서 6번째 플레이어는 제외

누적 조건은 일반 조건과 조합할 수 있습니다. 예시:
|cffffff00R1/3,+!R6,7|r - 리스트의 마지막 1/3에 속한 플레이어 중, 끝에서 6번째는 제외하고, 리스트의 7번째는 포함|r]]
LR.RGOnly = "MT 플레이어만"
LR.RGOnlyTip = "MTDB에 있는 플레이어만 목록에 포함"

LR.SplitsWrongChar = "잘못된 캐릭터:"
LR.SplitsNotInRaid = "공격대에 없음:"
LR.SplitsNotInTheList = "목록에 없음:"
LR.SplitsLastImport = "마지막 가져오기"
LR.SplitsShouldNotBeInRaid = " 공격대에 있으면 안 됨:"

LR.AssignmentsListID = "목록 ID"
LR.AssignmentsHelpTip = "우선순위:\n이름 > 커스텀 조건 > 별칭 > \"캐릭터 DB에 없음\"> 전문화 > 직업 > 하위 역할(근접/원거리) > 역할 > 중첩 목록 > 목록에 없음"
LR.AssignmentsAutoSendTip = "목록 자동 전송"
LR.AssignmentsTestTip = "일반 클릭: 우선순위 테스트\nShift 클릭: 목록 테스트\nAlt 클릭: MTDB의 플레이어를 우선으로 테스트"
LR.AssignmentsAutoSendEditTip = [=[|cffffffff준비 체크 또는 지역 전환 시
자동으로 목록 전송.

현재 지역
|cff55ee55%s %s|r

현재 지역 그룹:
|cff55ee55%s %s|r

현재 상위 지역:
|cff55ee55%s %s|r

현재 인스턴스:
|cff55ee55%s %s|r

현재 구역:
|cff55ee55%s %s|r

하위 지역 ID를 포함하려면 'c' 접두사, 예: 'c2022'.
그룹 지역 ID는 'g' 접두사, 예: 'g277'.
https://wago.tools/db2/AreaTable 구역 ID 'a' 접두사.
인스턴스 ID는 'i' 접두사.
BigWigs에 의존하며, 'b'로 시작하는 Encounter ID 지원]=]
LR.AssignmentsIgnoreValidationTip = "자동 전송 시 목록 유효성 검사 무시"
LR["NotTank"] = "탱커 아님"
LR["Copy trigger"] = "활성 조건 복사"
LR["Use TTS files if possible"] = "가능하면 TTS 파일 사용"
LR["Categories to ignore when importing:"] = "무시할 카테고리:"
LR.Focus = "주시"
LR["Restore"] = "복원하기"

LR["You are not Raid Leader or Raid Assistant"] = "공대장이나 부공이 아닙니다"
LR["Not Raid Leader or Raid Assistant"] = "공대장이나 부공이 아닙니다"
LR.WASyncUpdateSkipTitle = "정말 업데이트를 거절하시겠습니까?"
LR.Skip = "거절"
LR.WASNoPermission = "%s님이 WA를 보내려고 합니다. %s"

LR.TriggersCount = "활성 조건 수"

LR.WASyncVersionCheck = "버전 확인"
LR.WASyncWACheck = "WA 확인"
LR.WASyncWACheckTip = "WA Sync가 없는 사람들에게도 작동"
LR.WASyncLinkToChat = "채팅에 링크"
LR.WASyncMarkToSend = "전송할 항목 표시"
LR.WASyncUnmarkToSend = "전송할 항목 표시 해제"
LR.WASyncMarkToSendTip = "키워드로 검색할 때 사용"
LR.WASyncShowInWA = "WeakAuras에서 보기"
LR.WASyncShowInWATip = "접속 후 WA 창을 한 번도 열지 않았다면 이 옵션을 한번 더 선택해야 해당 WA를 선택해줍니다"

LR.WASyncReloadPrompt = "%s님이 /reload를 요청했습니다"
LR["Ask for Reload UI after import"] = "/reload 요청"
LR.WASyncKeywordToSendTip = "모든 전송 대기 중인 WA 버전을 요청하려면 Shift 클릭"

LR.barTicks = "바 틱:"
LR.barTicksTip = "바의 틱 위치\n예:\n3\n2, 5, 8"
LR.barColor = "바 색상:"
LR.barIcon = "바 아이콘:"
LR.barIconTip = "바 아이콘, 활성 조건에서 자동 아이콘을 사용하려면 0을 사용\n특정 아이콘을 지정하려면 주문ID를 사용"
LR.barWidth = "바 너비:"
LR.barHeight = "바 높이:"
LR.barTexture = "바 텍스처:"
LR.barFontTip = "그림자 및 외곽선은 텍스트 알림 설정을 따릅니다"
LR["Progress Bar"] = "진행형 바"
LR["Small Progress Bar"] = "작은 진행형 바"
LR["Big Progress Bar"] = "큰 진행형 바"

LR["RGASSrefreshTooltip"] = "모든 수정사항을 취소하고 목록 업데이트"

LR.hideTextChanged = "상태 변경 후 숨기기:"
LR.hideTextChangedTip = "지정된 지속시간이 정해지지 않은 알림을 만들 수 있습니다. 지속시간이 종료되거나 활성 조건 상태가 변경되면 알림이 사라집니다."
LR.timeLineDisable = "타임라인에 표시 안 함"
LR.durationReverse = "미리 표시"
LR.durationReverseTip = "선택한 시간보다 X초 전에 메시지를 표시합니다 (X - 지속 시간 길이)"
LR.TEST = "테스트"
LR.OnlyMine = "내 것만"
LR.ImportHistory = "풀 기록 가져오기"
LR.ExportHistory = "풀 기록 내보내기"
LR.FromHistory = "풀 기록"
LR.Custom = "커스텀"
LR.CustomSpell = "커스텀 주문:"
LR.PlayerNames = "플레이어 이름"
LR.PlayerNamesTip = "플레이어 이름을 공백으로 구분하여 입력"
LR.ShowFor = "대상:"
LR.Spell = "주문"
LR.HideMsgCheck = "주문 사용 후 메시지 숨기기\n주문이 재사용 대기 중일 때는 표시하지 않음"
LR.AdjustFL = "전투 길이 조정"
LR.CopyPrev = "마지막으로 저장한 구성 불러오기"
LR.Main = "메인"
LR["rshortnum"] = "숫자 축약"
LR["rshortnumTip"] = [[숫자를 축약합니다. 예시:
15.69 16
156.9 157
1569 1.6천
15690 1.6만
156900 15.7만
1569000 156.9만
15690000 1569만
156900000 1.6억
1569000000 15.7억
15690000000 156.9억
156900000000 1569억
1569000000000 1.6조
15690000000000 15.7조
]]
LR.TimerExcluded = "타이머 정렬 사용"
LR.TimerExcludedTip = "타이머 업데이트 시 텍스트가 흔들리는 것을 방지하려면 비활성화하세요."
LR["QS_20"] = "쐐기돌 시작"
LR.StartTestFightTip = "|cff80ff00\"풀\", \"단계\", \"M+ 시작\", \"전투 로그\"의 시전 시작, 시전 성공, +오라, -오라|r\n이벤트가 있는 알림에만 작동"

LR.GlobalTimeScale = "전역 시간 스케일"
LR.TimeScaleT1 = "~"
LR.TimeScaleTip1 = "시간 형식 가능 (5:25)"
LR.TimeScaleT2 = "~   +"
LR.TimeScaleT3 = "초"
LR.TimeScaleTip2 = "음수 가능"
LR.FilterCasts = "시전"
LR.FilterAuras = "오라"
LR.PresetFilter = "보스 사전 설정 필터"
LR.RepeatableFilter = "반복 주문"
LR.RepeatableFilterTip = "고급 카운터 조건이 사용된 경우 각 주문에 대해 별도의 리마인더 버튼을 표시합니다.\n필터가 꺼져 있을 때는 지정된 숫자가 있는 주문에 대해서만 리마인더가 표시됩니다."
LR.Boss2 = "보스"
LR.AdvancedEdit = "고급 모드에서 편집"
LR.HideOne = "리마인더 숨기기"
LR.HideOneTip = "보스가 변경될 때까지 이 리마인더를 숨깁니다.\n(미분류에 배치됨)"
LR.CustomDurationLen = "커스텀 지속 시간 설정"
LR.ChangeColorRng  = "색상 변경 (랜덤)"
LR.ImportAdd = "알림에 추가"
LR.AdjustFL = "전투 시간 조정"
LR.MRTOUTDATED = "|cffffce00%s|r 모듈은 |cffffce00MRT|r 버전 |cffff0000%s|r 이상이 필요합니다. 이 모듈을 사용하려면 MRT를 업데이트하세요."
LR.SearchStringTip = "문자열 앞에 \"|cff00ff00=|r\"를 사용하여 정확히 일치시키세요."
LR["Send All"] = "모두 전송"
LR["Send all lists that have auto send enabled"] = "자동 전송이 활성화된 모든 목록을 전송합니다"
LR["Copy list"] = "목록 복사"
LR["Add new"] = "새로 추가"
LR["Delete list"] = "목록 삭제"
LR.ImportTextFromNote = "현재 MRT 본 메모 로드"
LR.DurRevTooltip2 = "메시지는 타이머가 종료되기 3초 전에 표시됩니다.\n이 옵션이 비활성화된 경우, 타이머가 종료된 직후에 메시지가 표시됩니다."
LR.RemoveBeforeExport = "현재 알림 제거"
LR.RemoveBeforeExportTip = "타임라인에 현재 표시된 모든 알림이 가져오기 전에 제거됩니다"
LR.ForEveryPlayer = "각각 개별 추가"
LR.ForEveryPlayerTip = "한 줄로 여러 플레이어에 대한 개별 알림을 만듭니다"
LR.ImportNameAsFilter = "이름을 필터로 사용"
LR.ImportNameAsFilterTip = "형식이 '능력 - 이름 이름 이름'인 줄에서 이름을 필터로 하여 새 알림을 추가하고 필터된 플레이어에게만 표시합니다"
LR.ImportNoteWordMy = "내 이름 다음 단어 하나만 메시지로 사용"
LR.ImportNoteLinesMy = "내 이름이 포함된 줄만"
LR.ImportFromNote = "메모로 가져오기"
LR.Undo = "실행 취소"
LR.UndoTip = "최근에 추가된 알림 제거"
LR.AssignmentsConditionTip = [[|cffffffffname - 플레이어 이름
role1 - 주요 역할 (TANK, HEALER, DAMAGER)
role2 - 보조 역할 (MHEALER, RHEALER, MDD, RDD)
alias - 플레이어 별칭
class - 플레이어 직업 (WARRIOR, PALADIN, etc.)
spec - 플레이어 전문화 ID (71, 72, etc.)
group - 플레이어 공대 파티 번호

|cffffd100class == DEMONHUNTER and alias == "트개"|r]]
LR.CustomDurationLenMore = "%s에 대한 지속 시간을 초 단위로 설정합니다."

LR["WASyncSendOG"] = "전송 (WASync 아님)"
LR["WASyncSendOGTooltip"] = "Mate_Tools이 없는 플레이어에게 작동합니다."

LR["Follower Dungeon"] = "추종자 던전"
LR["Delve"] = "구렁"
LR["Quest Party"] = "퀘스트 파티"
LR["Story Raid"] = "스토리 레이드"

LR["rfunit"] = "조건으로 플레이어 선택"
LR["rfunitTip"] = "|cff00ff00{funit:CONDITIONS:INDEX_IN_LIST}|r - 조건을 충족하는 공격대/파티의 플레이어를 선택합니다. 조건에는 직업 (|cff00ff00priest|r,|cff00ff00mage|r), 역할 (|cff00ff00healer|r,|cff00ff00damager|r), 그룹 (|cff00ff00g2|r,|cff00ff00g5|r)이 포함됩니다. 여러 조건은 쉼표로 구분하며, 어느 조건이든 충족하면 플레이어가 목록에 추가됩니다.\n|cff00ff00+|r 기호를 사용하여 추가 조건을 만들 수 있습니다. 예시: |cff00ff00{funit:paladin,+damager:2}|r, |cff00ff00{funit:mage,+g2,priest:3}|r\n(그룹 2의 마법사 또는 모든 그룹의 사제들이 목록에 추가됩니다. 형식은 이 목록에서 세 번째 플레이어의 이름을 반환합니다.)"

LR["Randomize"] = "무작위로 선택"
LR["Current roster"] = "현재 라인업"
LR["Current list"] = "현재 목록"
LR["All specs"] = "모든 전문화"
LR["All classes"] = "모든 직업"
LR["All roles"] = "모든 역할"
LR["All aliases"] = "모든 별칭"

LR["Main"] = "메인"
LR["Reminders"] = "리마인더"
LR["Timeline"] = "타임라인"
LR["Assignments"] = "CD 플랜"

LR["Select boss"] = "보스 선택"

LR["Hide message after using a spell"] = "주문 사용 후 메시지 숨기기"
LR["Lines filters"] = "라인 필터"
LR["Reminders filters"] = "표시 필터"
LR["Show only reminders for filtered spells"] = "필터된 주문 유형만 표시"
LR["New reminders options"] = "신규 알림 설정"
LR["Use TTS"] = "TTS 사용"
LR["Icon without spell name"] = "주문 이름 없는 아이콘"
LR["ExportToNote"] = "메모로 내보내기"
LR["Send"] = "전송"
LR["Start live session"] = "실시간 회의 시작"
LR["Players will be invited to live session. Everyone who accept will able to add/change/remove reminders. All changes will be in shared profile, don't forget to copy them to any profile if you want to save them."] = "플레이어가 실시간 회의에 초대됩니다.\n수락한 사람은 알림을 추가/변경/삭제할 수 있습니다."
LR["Live session is on"] = "실시간 회의 ON"
LR["Guild"] = "길드"
LR["Custom roster"] = "커스텀 라인업"
LR["Edit"] = "편집"
LR["Edit custom roster"] = "커스텀 라인업 편집"
LR["1 line - 1 player, format: |cff00ff00name   class   role|r"] = "1줄 - 1명, 형식: |cff00ff00이름   직업   역할|r"
LR["Add (rewrite current roster)"] = "추가 (현재 명단 덮어쓰기)"
LR["Add from current raid/group"] = "현재 공격대/그룹에서 추가"
LR["Clear list"] = "목록 지우기"
LR["Edit spells groups"] = "주문 그룹 편집"
LR["Reset to default"] = "기본값으로 재설정"
LR["Spell Name"] = "주문 이름"
LR["Message: "] = "메시지: "
LR["Sound: "] = "소리: "
LR["Glow: "] = "반짝임: "
LR["TTS: "] = "TTS: "
LR["Phase "] = "단계 "
LR["Note: "] = "메모: "
LR["From start: "] = "Pull~: "
LR["CD: "] = "CD: "
LR["%s is starting |A:unitframeicon-chromietime:20:20|a live session"] = "%s ◀ |A:unitframeicon-chromietime:20:20|a 실시간 회의를 시작합니다."
LR["Cooldown:"] = "쿨다운:"
LR["Leave empty for reset to default value"] = "기본값으로 재설정하려면 비워두세요"
LR["Charges:"] = "충전:"
LR["Reminder is untimed"] = "시간 지정되지 않음"
LR["GUID"] = "GUID"
LR["NPC ID"] = "NPC ID"
LR["Spawn Time"] = "생성 시간"
LR["Spawn UNIX Time"] = "생성 UNIX 시간"
LR["Spawn Index"] = "생성 인덱스"
LR["Revert changes"] = "변경 사항 취소"
LR["Revert all changes made during last live session."] = "마지막 실시간 회의 동안 변경된 사항을 모두 취소합니다."
LR["|cff00ff00Live session is ON"] = "|cff00ff00실시간 회의 ON"
LR["|cffff0000Exit live session"] = "|cffff0000실시간 회의 종료"
LR["Stop this session"] = "다시 보지 않기"
LR["Select color in Color Picker"] = "색상 선택기에서 색상 선택"
LR["Temporarily add custom spell"] = "커스텀 주문 임시 추가"
LR["Round"] = "소수점 반올림"
LR["Group"] = "파티"
LR["Alias:"] = "별칭:"
LR["Custom players:"] = "커스텀 플레이어:"
LR["*(press Enter to save changes)"] = "*(변경 사항을 저장하려면 Enter)"
LR["Add custom line(s) at +X seconds"] = "+X초마다 커스텀 라인 추가하기"
LR["Classes:"] = "직업:"
LR["Players:"] = "플레이어:"
LR["Roles:"] = "역할:"
LR["Right Click to pin this fight"] = "이 전투를 고정하려면 오른쪽 클릭"
LR["Right Click to unpin this fight"] = "이 전투를 고정 해제하려면 오른쪽 클릭"
LR["Convert Group"] = "그룹 전환"
LR["Profile"] = "|cff00ffff프로필|r"
LR["Default"] = "기본"
LR["Use for all characters"] = "모든 캐릭터에 사용"
LR["Enter profile name"] = "프로필 이름을 입력하세요"
LR["Delete"] = "삭제"
LR["Delete profile"] = "프로필 삭제"
LR["Copy into current profile from"] = "프로필을 현재 프로필로 복사"
LR["WA is different version/changed"] = "WA가 다른 버전/변경됨"
LR["Clear list?"] = "목록을 지우시겠습니까?"
LR["Other"] = "기타"
LR["Deleted"] = "휴지통"
LR["You can't edit reminder simulated from note"] = "MRT 메모에서 시뮬레이션된 알림은 수정할 수 없습니다."
LR["Simulate note timers"] = "MRT 메모 표시"
LR["SimNoteTimersTip"] = "MRT 본 메모와 개인 메모를 시뮬레이션합니다.\n\"메모에서 가져오기\"의 체크박스 설정은 타임라인의 알림 시뮬레이션에 영향을 미칩니다."
LR.DeletedTabTip = "삭제된 알림은 180일 동안 보관되며 언제든 복원할 수 있습니다."
LR["Own Data"] = "소유 데이터"
LR["Pixel Glow"] = "픽셀 반짝임"
LR["Autocast Shine"] = "자동시전 빛남"
LR["Action Button Glow"] = "동작 버튼 반짝임"
LR["Proc Glow"] = "스킬 발동 반짝임"
LR["Last basic check:"] = "마지막 확인:"
LR["seconds ago by"] = "초 전"
LR["Last version check:"] = "마지막 버전 확인:"
LR["Open editor"] = "편집기 열기"
LR["Edit custom encounter"] = "커스텀 교전 편집"
LR["Not enough permissions to request reload UI"] = "Reload UI를 요청할 권한이 없습니다."
LR["Get DebugLog"] = "디버그 로그"
LR["Request ReloadUI"] = "ReloadUI 요청"
LR["Manual Replacement"] = "수동 교체"
LR["Change names manually"] = "수동으로 이름 변경"
LR["Name to find:"] = "찾을 이름:"
LR["New name:"] = "새 이름:"
LR["Error"] = "오류"
LR["Custom EH"] = "EH"
LR["Use custom error handler for this WA"] = "이 WA에 커스텀 오류 핸들러 사용"
LR["Request WA"] = "WA 요청"
LR["Player has to be in the same guild to request WA"] = "플레이어가 같은 길드에 있어야 WA를 요청할 수 있음"
LR["%s requests your version of WA %q. Do you want to send it?"] = "%s가 WA %q 요청합니다. 보내시겠습니까?"
LR["Set Load Never"] = "불러오기 끔"
LR["Archive and Delete"] = "삭제&창고행"
LR["Last note update was sent by %s at %s"] = "마지막 메모 업데이트 %s ▶ %s"
LR["Hold shift to save and send reminder"] = "저장 및 전송은 shift 클릭"

LR["SoundStatus1"] = "소리 활성화"
LR["SoundStatus2"] = "소리 잠금, 알림 업데이트에 영향 받지 않음"
LR["SoundStatus3"] = "소리 비활성화"
LR["PersonalStatus1"] = "개인용으로 설정, 전송되지 않음"
LR["PersonalStatus2"] = "공용으로 설정"
LR["Current spell settings will be lost. Reset to default preset?"] = "현재 주문 설정이 사라집니다. 기본값으로 재설정하시겠습니까?"
LR.OptPlayersTooltip = "알림 전송에 \"|cffffff00항상|r\"이 적용된 플레이어 목록"

LR["Lua error in overwritten BigWigs module '%s': %s"] = "덮어쓴 BigWigs 모듈 '%s'에서 Lua 오류 발생: %s"
LR["Use default TTS Voice"] = "기본 TTS 음성 사용"
LR["Text"] = "메시지"
LR["Text To Speech"] = "TTS"
LR["Raid Frame Glow"] = "프레임 반짝임"
LR["Nameplate Glow"] = "이름표 반짝임"
LR["Bars"] = "바"
LR["Default TTS Voice"] = "기본 TTS 음성"
LR["Alternative TTS Voice"] = "한국어 TTS 음성"
LR["TTS Volume"] = "TTS 음량"
LR["TTS Rate"] = "TTS 속도"

LR["Timeline simulation"] = "타임라인 시뮬레이션"
LR["Start simulation"] = "|cff80ff00시뮬레이션 시작|r"
LR["Cancel simulation"] = "|cff80ff00시뮬레이션 취소|r"
LR["Pause simulation"] = "|cff80ff00시뮬레이션 일시 중지|r"
LR["Resume simulation"] = "|cff80ff00시뮬레이션 재개|r"
LR["Simulation start time"] = "시뮬레이션 시작 시간"
LR["Simulation speed multiplier"] = "시뮬레이션 속도 배율"

LR["ttsOnHide"] = "숨길 때 TTS:"
LR["sound_delayTip"] = "사운드 지연(초)"
LR["sound_delayTip2"] = "사운드 지연(초), 음수 값은 종료 'X' 초 전"

 LR["DataProfileTip1"] = "현재 활성 및 삭제된 알림 세트 포함."
 LR["VisualProfileTip1"] = "앵커, 텍스트/바 모양, TTS 및 반짝임 설정 포함."
 LR["Visual Profile"] = "|cff00ffff비주얼 프로필|r"
 LR["Delete visual profile"] = "비주얼 프로필 삭제"

LR.HelpText =
([=[슬래시 명령어:
    |cffaaaaaa/리마인더|r or |cffaaaaaa/rem|r - |cffff8000Reminder MT|r
    |cffaaaaaa/동기화|r or |cffaaaaaa/was|r - |cFF00FFFFWeakAuras Sync|r
]=] ..
	"|n|n|n|cffffff00||cffRRGGBB|r...|cffffff00||r|r - 이 구조 내의 모든 텍스트 (이 예제에서 \"...\")는 특정 색상으로 색칠됩니다. 여기서 RR, GG, BB는 16진수 색상 코드입니다."..
	"|n|n|cffffff00{spell:|r|cff00ff0017|r|cffffff00}|r - 이 예제는 주문ID가 \"17\"인 주문 아이콘으로 교체됩니다 (|T135940:0|t)."..
	"|n|n|cffffff00{rt|cff00ff001|r}|r - 이 예제는 1번(별) 공격대 아이콘으로 교체됩니다 |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t."..
	"|n|n|cffffff00\\n|r - 이 구조 이후의 텍스트는 다음 줄로 이동합니다" ..
	"|n|n아이콘 번호: " ..
	"|n1 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t      5 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t" ..
	"|n2 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t      6 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t" ..
	"|n3 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t      7 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t" ..
	"|n4 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t      8 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t" ..
[=[


|cff80ff00---- 조건 ----|r

● 숫자 조건 - 카운터, 백분율, 중첩
    숫자 조건은 공백에 민감하지 않으며, 쉼표로 구분됩니다.
    연산자:
    |cffffff00!x|r    - x 제외
    |cffffff00>=x|r   - x 이상
    |cffffff00>x|r    - x 초과
    |cffffff00<=x|r   - x 이하
    |cffffff00<x|r    - x 미만
    |cffffff00=x|r    - x와 같음
    |cffffff00x%y|r   - x부터 시작해 y마다
    |cffffff00+|r     - 이전 조건의 추가

    조건 예시 1: |cff00ff001, 3, 4|r
    이 예시는 1, 3, 4번째 시전에 작동합니다.

    조건 예시 2: |cff00ff00>=2, +!6, +!7|r
    |cffffff00조건에 수학적 연산이 있는 경우, 이후 조건은 예시처럼 '+'로 추가되어야 합니다|r

    이 예시는 2 이상이지만 6과 7을 제외하며, 2, 3, 4, 5, 8번째 시전 등에 작동합니다.

    조건 예시 3: |cff00ff003%5|r
    이 예시는 3부터 시작해 매 5번째 시전에 작동하며, 3, 8, 13, 18번째 시전 등에 작동합니다.


● 문자 조건 - 소스 이름, 대상 이름
    문자 조건은 공백에 민감하며, 세미콜론으로 구분됩니다.
    연산자:
    |cffffff00-|r    - 모든 일치 항목 제외

    조건 예시 1: |cff00ff00비늘사령관 사카레스|r
    이 예시는 유닛이 "비늘사령관 사카레스"이어야 함을 의미합니다.

    조건 예시 2: |cff00ff00-비늘사령관 사카레스;공허한 기억|r
    이 예시는 "비늘사령관 사카레스"와 "공허한 기억"을 제외함을 의미합니다.

    조건 예시 3: |cff00ff00비늘사령관 사카레스;공허한 기억|r
    이 예시는 유닛이 "비늘사령관 사카레스" 또는 "공허한 기억"이어야 함을 의미합니다.


● 몹ID 조건 - 소스 ID, 대상 ID
    MobID 조건은 공백에 민감하며, 쉼표로 구분됩니다.
    연산자:
    |cffffff00x:y|r   - 여기서 x는 npcID, y는 spawnIndex입니다

    조건 예시 1: |cff00ff00154131,234156|r
    이 예시는 npcID가 154131 또는 234156이어야 함을 의미합니다

    조건 예시 2: |cff00ff00154131:1,234156:2|r
    이 예시는 npcID가 154131이고 spawnIndex가 1이거나 234156이고 spawnIndex가 2이어야 함을 의미합니다

|cff80ff00---- 카운터 유형 -----|r

    |cff00ff00기본값|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.

    |cff00ff00각 소스별|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.
    각 시전자에 대한 개별 카운터

    |cff00ff00각 대상별|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.
    각 대상에 대한 개별 카운터

    |cff00ff00활성 조건 중첩|r - 모든 활성 조건이 활성화된 시간 동안 활성 조건이 활성화되면 +1을 추가합니다.

    |cff00ff00재설정된 활성 조건 중첩|r - 모든 활성 조건이 활성화되어 있는 시간(중첩)에 활성 조건이 활성화되면 +1을 추가합니다. 알림이 비활성화되면 카운터를 0으로 초기화합니다.

    |cff00ff00이 알림의 공통 사항|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.
    이 알림의 동일한 카운터 유형을 가진 각 활성 조건에 대한 공통 사항입니다

    |cff00ff005초 후 재설정|r - 활성 조건이 활성화될 때마다 +1을 추가합니다.
    활성 조건이 활성화된 후 5초 후에 카운터를 0으로 재설정합니다.

|cff80ff00---- 로드 조건 논리 ----|r

    로드를 다음 조건으로 수행할 수 있습니다: 직업, 역할, 파티 번호, 이름, 메모.
    각 조건 내에서 적어도 하나의 일치가 있어야 합니다.

    예: 전사, 성기사 직업 로드
        - 플레이어가 전사 또는 성기사인 경우 리마인더가 로드됩니다.

    여러 로드 조건을 사용할 경우, 리마인더는 모든 조건이 충족되면
    로드됩니다.

    예: 전사, 성기사 직업 및 탱커 역할 로드
        - 플레이어가 전사 또는 성기사이고 탱커인 경우 리마인더가 로드됩니다.
        - 플레이어가 전사 또는 성기사이고 탱커가 아닌 경우 리마인더가 로드되지 않습니다.

|cff80ff00---- 메모 로드 ----|r

    "로드 조건" 섹션에서 메모 패턴을 지정할 수 있습니다.
    기본적으로 리마인더는 지정된 패턴으로 시작하는 메모 줄을 검색하며, 해당 줄의 모든 플레이어에 대해 리마인더가 로드됩니다.

    "|cffffff00할당 메모|r" 옵션을 선택하면 검색이 MateStart에서 MateEnd까지의 블록 내에서 수행됩니다.

    블록 예시:
        MateStart
        까치킹
        양준수대장
        재혁드
        MateEnd

    "로드 조건" 섹션에서 메모 패턴을 지정할 수 있습니다.
    기본적으로 리마인더는 지정된 패턴으로 시작하는 메모 줄을 검색하며, 해당 줄의 모든 플레이어에 대해 리마인더가 로드됩니다.

    "할당 메모" 옵션을 선택하면 검색이 MateStart에서 MateEnd까지의 블록 내에서 수행됩니다.
    추가 매개변수가 지정되지 않은 경우(아래 참조) 리마인더는 블록의 모든 플레이어에 대해 로드됩니다.

    메모 패턴 로드에 대해 추가 매개변수를 지정할 수 있습니다.
    패턴 앞에 "|cffffff00-|r"를 붙이면 로드 논리가 반전됩니다.
    즉, 리마인더는 패턴과 일치하지 않는 모든 플레이어에 대해 로드됩니다.

    특정 위치에 대해 리마인더를 로드할 수도 있습니다.
    이를 위해 패턴 뒤에 |cffffff00{pos:y:x}|r 매개변수를 지정합니다.
    여기서 |cffffff00y|r와 |cffffff00x|r는 리마인더가 로드되어야 하는 플레이어의 위치를 나타내는 숫자입니다.
    특정 줄에 대한 패턴을 사용할 때 |cffffff00y|r는 줄 내 플레이어의 순서 번호를 의미합니다.
    할당 메모에 대한 패턴을 사용할 때 |cffffff00y|r는 블록 내 줄의 순서 번호를 의미하며, |cffffff00x|r는 줄 내 플레이어의 순서 번호를 의미합니다. |cffffff00x|r는 생략할 수 있으며, 이 경우 리마인더는 |cffffff00y|r 줄의 모든 플레이어에 대해 로드됩니다.

    |cffffff00y|r와 |cffffff00x|r가 지정되지 않은 경우(즉, 단순히 |cffffff00{pos}|r로만 지정된 경우) 리마인더는 패턴과 일치하는 모든 플레이어에 대해 로드됩니다.
    그러나 |cffffff00{notepos:y:x}|r 텍스트 대체자를 사용하여 다른 위치에서 리마인더 내 플레이어의 이름을 반환할 수 있습니다(예: 화면 메시지 또는 TTS).
    |cffffff00{pos}|r 추가 매개변수가 없으면 이 텍스트 대체자를 사용할 수 없습니다.

    메모 위치 시스템은 순환적입니다.
    즉, 줄에 5명의 플레이어가 있는 경우 6번째 위치는 첫 번째 플레이어가 됩니다.
    줄이 8개인 경우 10번째 위치는 두 번째 줄이 됩니다.

    메모 패턴:
        #left
    메모:
        #left |cfff48cbaPallux|r |cffa330c9Teddy|r |cffc69b6dRalc|r |cffaad372까치킹|r

    # 리마인더는 "#left"로 시작하는 줄의 모든 플레이어에 대해 로드됩니다.

    메모 패턴:
        -#right
    메모:
        #right |cfffff468양준수대장|r |cfffff468Budweise|r |cff00ff98섹쉬뽀또|r |cffffffffJuajin|r

    # 리마인더는 "#right"로 시작하는 줄의 플레이어를 제외한 모든 플레이어에 대해 로드됩니다.

    메모 패턴:
        #center {pos:3}
    메모:
        #center |cfff48cbaPallux|r |cffa330c9Teddy|r |cffc69b6dRalc|r |cffaad372까치킹|r

    # 리마인더는 메모의 세 번째 플레이어에 대해서만 로드됩니다: |cffc69b6dRalc|r

    할당 메모 패턴:
        roots
    메모:
        rootsStart
        |cffc41e3aTroyy|r
        |cffa330c9Teddy|r
        |cfff48cbaPallux|r
        |cffc69b6dRalc|r
        |cffaad372까치킹|r
        rootsEnd

    # 리마인더는 "rootsStart"에서 "rootsEnd"까지의 블록 내 모든 플레이어에 대해 로드됩니다.

    할당 메모 패턴:
        seeds{pos:2}
    메모:
        seedsStart
        |cffc41e3aTroyy|r |cffa330c9Teddy|r |cfff48cbaPallux|r |cffc69b6dRalc|r |cffaad372까치킹|r
        |cff00ff98섹쉬뽀또|r Juajin |cffffffff힐큼이|r |cfff48cba분홍파프리카|r
        seedsEnd

    # 리마인더는 두 번째 줄의 모든 플레이어에 대해 로드됩니다: |cff00ff98섹쉬뽀또|r Juajin |cffffffff힐큼이|r |cfff48cba분홍파프리카|r


    할당 메모 패턴:
        seeds{pos:2:3}
    메모:
        seedsStart
        |cffc41e3aTroyy|r |cffa330c9Teddy|r |cfff48cbaPallux|r |cffc69b6dRalc|r |cffaad372까치킹|r
        |cff00ff98섹쉬뽀또|r Juajin |cffffffff힐큼이|r |cfff48cba분홍파프리카|r
        seedsEnd

    # 리마인더는 두 번째 줄의 세 번째 플레이어에 대해서만 로드됩니다: 힐큼이

    할당 메모 패턴:
        seeds{pos:6}
    메모:
        seedsStart
        |cffc41e3aTroyy|r |cffa330c9Teddy|r |cfff48cbaPallux|r |cffc69b6dRalc|r |cffaad372까치킹|r
        |cff00ff98섹쉬뽀또|r Juajin |cffffffff힐큼이|r |cfff48cba분홍파프리카|r
        seedsEnd

    #리마인더는 두 번째 줄의 모든 플레이어에 대해 로드됩니다.
    블록의 위치 순환 순서로 인해: 1, 2, 1, 2, 1, 2 등.
]=]):gsub("\t", "    ") -- \t(tab) may not be printable atleast for some fonts, so replacing it with spaces

LR["Not in list"] = "목록에 없음"
LR["Not in characters DB"] = "캐릭터 DB에 없음"
LR["Select nested list"] = "중첩 목록 선택"
LR["NotInDBTip"] = "DB에 없는 캐릭터를 위한 특별한 위치를 목록에 설정합니다.\n\nMTOnly 옵션으로 목록을 받아와도 이 캐릭터들은 이 목록에 포함됩니다."
LR["NotInListTip"] = "목록에 없는 캐릭터를 위한 특별한 위치를 목록에 설정합니다.\n\n목록에서 GUID 기준으로 캐릭터를 정렬할 때 유일한 우선순위로 사용할 수 있습니다."

LR["Export for AutoImport"] = "AutoImport로 내보내기"
LR["Show full diffs"] = "전체 차이점 보기"
LR["Please select two auras to compare"] = "비교할 오라 두 개 선택"
LR["Diff is too long, showing first 100000 characters only, full length:"] = "차이점이 너무 길어 처음 100,000자만 표시. 전체 길이:"
LR["Imports have different UIDs, cannot be matched. Try checking full diffs"] = "가져온 항목의 UID가 달라 일치시킬 수 없음. 전체 차이점 보기로 시도"
LR["Error comparing auras: "] = "오라 비교 오류: "
LR["Import has no UID, cannot be matched."] = "가져온 항목에 UID가 없어 일치시킬 수 없음."
LR["Don't check on spell CD"] = "주문 재사용 대기시간에는 확인하지 않음"
LR["%s note is not synced\nSend note?"]  = "%s ◀ 메모 동기화 안됨\n|cffFF6A00MRT 메모|r를 보낼까요?"
LR["Delete Reminders"] = "리마인더 삭제"
LR["Skip Import"] = "가져오기 건너뛰기"

LR["Left click - config"] = "왼쪽 클릭 - 설정"
LR["Shift+Left click - advanced config"] = "Shift+왼쪽 클릭 - 고급 설정"
LR["Right click - remove"] = "오른쪽 클릭 - 제거"
LR["Export History"] = "기록 내보내기"
LR["Import History"] = "기록 가져오기"
LR["Automatically fix server names"] = "서버 이름 자동 수정"
LR["Delete WA"] = "WA 삭제"
LR["Delete %q for %s?"] = "%q의 보유 WA\n'%s'\n삭제하시겠습니까?"
LR["Delete Reminder"] = "리마인더 삭제"
LR["Save data?"] = "데이터를 저장하시겠습니까?"
LR["Reload UI Request"] = "Reload UI 요청"
LR["Reload UI"] = "Reload UI"
LR["Accepting data"] = "데이터 수락"
LR[ [[Trim ignored fields
for compare]] ] = [[비교를 위해
무시된 필드 삭제]]
LR["Update"] = "업데이트"
LR["No parent"] = "부모 없음"
LR["Update(new parent)"] = "업데이트(새 부모)"
LR["Added"] = "추가"
LR["Modified"] = "수정"
LR["There are multiple lists with the same name. Rename the list before deleting it."] = "동일한 이름의 목록이 여러 개 있습니다. 삭제하기 전에 이름을 변경하세요."
LR["Are you sure you want to delete the list |cffffd100%s|r?"] = "|cffffd100%s|r 목록을 삭제하시겠습니까?"
LR["Enter backup name:"] = "백업 이름을 입력하세요:"
LR["List |cffffd100%s|r was updated by |cffffd100%s|r. Do you want to apply changes made by him?"] = "|cffffd100%s|r 목록이 |cffffd100%s|r에 의해 업데이트되었습니다. 해당 사용자가 변경한 내용을 적용하시겠습니까?"
LR["Pass loot for all?"] = "Mate 인원 모든 전리품 자동 포기 활성화"
LR["Auto Push Stopped\n\nSome of your autosend lists are not valid, check chat for details"] = "자동 전송 중지됨\n\n일부 자동 전송 목록이 유효하지 않습니다. 채팅을 확인하세요."
LR["There are name duplications in your lists, fix them before sending"] = "목록에 중복 이름이 있습니다. 전송하기 전에 수정하세요."
LR["Delete from 'removed list'"] = "목록 삭제"
LR["Clean Import"] = "가져오기 삭제"
LR["MRT Version Outdated"] = "MRT 버전이 구버전입니다."
LR["Create new profile"] = "새 프로필 생성"
LR["Create visual profile"] = "비주얼 프로필 생성"
LR["Copy visual profile"] = "비주얼 프로필 복사"
LR["Import error"] = "가져오기 오류"
LR["Reset spell settings"] = "주문 설정 초기화"
LR["'NaN' in import string"] = "가져오기 문자열 'NaN' 오류"
LR["Found 'NaN' in import string, delete 'NaN' from string and import data or cancel import\n|cffff0000IMPORT DATA MAY BE INCOMPLETE"] = "가져오기 문자열을 수정하고 데이터를 가져오거나 가져오기 취소하세요\n|cffff0000가져온 데이터가 불완전할 수 있습니다."
LR["Do you want to always |cffff0000decline|r reminders from |cffff0000%s|r?"] = "|cffff0000%s|r의 리마인더를 항상 |cffff0000거절|하시겠습니까?"
LR["Do you want to always |cff00ff00accept|r reminders from |cff00ff00%s|r?"] = "|cff00ff00%s|r의 리마인더를 항상 |cff00ff00수락|r하시겠습니까?"
LR["Reminder Version Outdated"] = "버전 알림"
LR["WA Requested"] = "WA 요청"
LR["Delete section"] = "섹션 삭제"
LR["Unmodified"] = "수정되지 않음"
LR["No data for added aura, cannot import."] = "추가된 오라에 대한 데이터가 없으므로 가져올 수 없습니다."
LR["Select old WA:"] = "기존 WA 선택:"
LR["Select new WA:"] = "새 WA 선택:"
LR["Tree view"] = "트리 보기"
LR["Group structure"] = "그룹 구조"
LR["No parent found for update, cannot import."] = "업데이트할 부모를 찾을 수 없어 가져올 수 없습니다."
LR["No parent found for import, cannot import."] = "가져올 부모를 찾을 수 없어 가져올 수 없습니다."
