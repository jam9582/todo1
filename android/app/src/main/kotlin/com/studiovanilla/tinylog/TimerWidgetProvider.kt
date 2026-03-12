package com.studiovanilla.tinylog

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

// ─── 위젯 크기 구분 ───────────────────────────────────────────────────────
enum class WidgetSize { SMALL, MEDIUM, LARGE }

class TimerWidgetSmall : BaseTimerWidget(WidgetSize.SMALL)
class TimerWidgetMedium : BaseTimerWidget(WidgetSize.MEDIUM)
class TimerWidgetLarge : BaseTimerWidget(WidgetSize.LARGE)

// ─── 인텐트 액션 상수 ─────────────────────────────────────────────────────
private const val ACTION_START    = "com.studiovanilla.tinylog.WIDGET_START"
private const val ACTION_PAUSE    = "com.studiovanilla.tinylog.WIDGET_PAUSE"
private const val ACTION_RESUME   = "com.studiovanilla.tinylog.WIDGET_RESUME"
private const val ACTION_COMPLETE = "com.studiovanilla.tinylog.WIDGET_COMPLETE"
private const val ACTION_CANCEL   = "com.studiovanilla.tinylog.WIDGET_CANCEL"
private const val ACTION_PREV     = "com.studiovanilla.tinylog.WIDGET_PREV"
private const val ACTION_NEXT     = "com.studiovanilla.tinylog.WIDGET_NEXT"
private const val ACTION_MIDNIGHT = "com.studiovanilla.tinylog.WIDGET_MIDNIGHT"

private const val EXTRA_CATEGORY_INDEX = "category_index"
private const val EXTRA_WIDGET_SIZE    = "widget_size"

// SharedPreferences 파일명
private const val FLUTTER_PREFS  = "FlutterSharedPreferences"
private const val WIDGET_PREFS   = "HomeWidgetPreferences"

// Flutter SharedPreferences 키 (flutter. 접두어 포함)
private const val KEY_START_TIME    = "flutter.timer_start_time"
private const val KEY_ORIG_START    = "flutter.timer_original_start_time"
private const val KEY_ACCUMULATED   = "flutter.timer_accumulated_ms"
private const val KEY_IS_RUNNING    = "flutter.timer_is_running"
private const val KEY_IS_PAUSED     = "flutter.timer_is_paused"
private const val KEY_WIDGET_INTERACTION = "flutter.widget_interaction"

// HomeWidget SharedPreferences 키
private const val WKEY_CATEGORIES   = "widget_categories"
private const val WKEY_TIMER        = "widget_timer"
private const val WKEY_PENDING      = "widget_pending_completion"
private const val WKEY_SMALL_PAGE   = "widget_small_page"
private const val WKEY_MEDIUM_PAGE  = "widget_medium_page"

private val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
private val displayFormat = SimpleDateFormat("a h:mm", Locale.KOREAN)

// 카테고리 배경 drawable (순서 = 통계 화면 색상 순서와 동일)
private val cardBgResIds = intArrayOf(
    R.drawable.widget_card_bg_0,
    R.drawable.widget_card_bg_1,
    R.drawable.widget_card_bg_2,
    R.drawable.widget_card_bg_3,
)

// ─── 공통 베이스 클래스 ───────────────────────────────────────────────────
abstract class BaseTimerWidget(private val size: WidgetSize) : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id, size)
        }
        scheduleMidnightRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val widgetSize = intent.getStringExtra(EXTRA_WIDGET_SIZE)
            ?.let { runCatching { WidgetSize.valueOf(it) }.getOrNull() }
            ?: size

        when (intent.action) {
            ACTION_START    -> handleStart(context, intent.getIntExtra(EXTRA_CATEGORY_INDEX, 0))
            ACTION_PAUSE    -> handlePause(context)
            ACTION_RESUME   -> handleResume(context)
            ACTION_COMPLETE -> handleComplete(context)
            ACTION_CANCEL   -> handleCancel(context)
            ACTION_PREV     -> handlePageChange(context, widgetSize, -1)
            ACTION_NEXT     -> handlePageChange(context, widgetSize, +1)
            ACTION_MIDNIGHT -> {
                refreshAllWidgets(context)
                scheduleMidnightRefresh(context)
            }
        }
    }
}

// ─── 위젯 UI 업데이트 ─────────────────────────────────────────────────────
fun updateWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    size: WidgetSize
) {
    val layoutId = when (size) {
        WidgetSize.SMALL  -> R.layout.widget_small
        WidgetSize.MEDIUM -> R.layout.widget_medium
        WidgetSize.LARGE  -> R.layout.widget_large
    }
    val views = RemoteViews(context.packageName, layoutId)

    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    val timerJson    = widgetPrefs.getString(WKEY_TIMER, null)
    val isTimerActive = timerJson != null &&
            (flutterPrefs.getBoolean(KEY_IS_RUNNING, false) ||
             flutterPrefs.getBoolean(KEY_IS_PAUSED, false))

    if (isTimerActive && timerJson != null) {
        bindMeasuringState(context, views, size, appWidgetId, timerJson, flutterPrefs)
    } else {
        bindNormalState(context, views, size, appWidgetId, widgetPrefs)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

// ─── 일반 상태 (카테고리 카드) ────────────────────────────────────────────
private fun bindNormalState(
    context: Context,
    views: RemoteViews,
    size: WidgetSize,
    appWidgetId: Int,
    prefs: SharedPreferences
) {
    views.setViewVisibility(R.id.normal_state, View.VISIBLE)
    views.setViewVisibility(R.id.measuring_state, View.GONE)

    val categoriesJson = prefs.getString(WKEY_CATEGORIES, "[]") ?: "[]"
    val categories = runCatching { JSONArray(categoriesJson) }.getOrElse { JSONArray() }
    val total = categories.length().coerceAtMost(4)

    // 날짜가 바뀌었으면 todayMinutes를 0으로 표시
    val savedDate = prefs.getString("widget_categories_date", null)
    val todayDate = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val isStaleDate = savedDate != null && savedDate != todayDate
    if (isStaleDate) {
        for (i in 0 until categories.length()) {
            categories.optJSONObject(i)?.put("todayMinutes", 0)
        }
    }

    when (size) {
        WidgetSize.SMALL -> bindSmallNormal(context, views, appWidgetId, categories, total, prefs)
        WidgetSize.MEDIUM -> bindMediumNormal(context, views, appWidgetId, categories, total, prefs)
        WidgetSize.LARGE -> bindLargeNormal(context, views, appWidgetId, categories, total)
    }
}

private fun bindSmallNormal(
    context: Context,
    views: RemoteViews,
    appWidgetId: Int,
    categories: JSONArray,
    total: Int,
    prefs: SharedPreferences
) {
    if (total == 0) return

    val page = prefs.getInt(WKEY_SMALL_PAGE, 0).coerceIn(0, total - 1)
    val cat  = categories.getJSONObject(page)

    views.setTextViewText(R.id.cat_emoji, cat.optString("emoji", ""))
    views.setTextViewText(R.id.cat_name,  cat.optString("name", ""))
    views.setTextViewText(R.id.cat_time,  formatMinutes(cat.optInt("todayMinutes", 0)))

    // 카드 탭 → 타이머 시작
    views.setOnClickPendingIntent(
        R.id.category_card,
        makeStartIntent(context, appWidgetId, page, WidgetSize.SMALL)
    )
    // 화살표
    views.setOnClickPendingIntent(R.id.btn_prev, makeNavIntent(context, appWidgetId, ACTION_PREV, WidgetSize.SMALL))
    views.setOnClickPendingIntent(R.id.btn_next, makeNavIntent(context, appWidgetId, ACTION_NEXT, WidgetSize.SMALL))

    // 도트
    val dotIds = intArrayOf(R.id.dot0, R.id.dot1, R.id.dot2, R.id.dot3)
    for (i in 0 until 4) {
        if (i < total) {
            views.setViewVisibility(dotIds[i], View.VISIBLE)
            views.setTextViewText(dotIds[i], if (i == page) "●" else "○")
            views.setTextColor(dotIds[i], if (i == page) 0xFF5C5652.toInt() else 0xFFB8B3AD.toInt())
        } else {
            views.setViewVisibility(dotIds[i], View.GONE)
        }
    }
}

private fun bindMediumNormal(
    context: Context,
    views: RemoteViews,
    appWidgetId: Int,
    categories: JSONArray,
    total: Int,
    prefs: SharedPreferences
) {
    val pages     = if (total <= 2) 1 else 2
    val page      = prefs.getInt(WKEY_MEDIUM_PAGE, 0).coerceIn(0, pages - 1)
    val cardIds   = intArrayOf(R.id.category_card_0, R.id.category_card_1)
    val emojiIds  = intArrayOf(R.id.cat_emoji_0, R.id.cat_emoji_1)
    val nameIds   = intArrayOf(R.id.cat_name_0,  R.id.cat_name_1)
    val timeIds   = intArrayOf(R.id.cat_time_0,  R.id.cat_time_1)

    for (slot in 0 until 2) {
        val catIndex = page * 2 + slot
        if (catIndex < total) {
            val cat = categories.getJSONObject(catIndex)
            views.setViewVisibility(cardIds[slot], View.VISIBLE)
            views.setTextViewText(emojiIds[slot], cat.optString("emoji", ""))
            views.setTextViewText(nameIds[slot],  cat.optString("name", ""))
            views.setTextViewText(timeIds[slot],  formatMinutes(cat.optInt("todayMinutes", 0)))
            views.setOnClickPendingIntent(
                cardIds[slot],
                makeStartIntent(context, appWidgetId, catIndex, WidgetSize.MEDIUM)
            )
        } else {
            views.setViewVisibility(cardIds[slot], View.INVISIBLE)
        }
    }

    views.setOnClickPendingIntent(R.id.btn_prev, makeNavIntent(context, appWidgetId, ACTION_PREV, WidgetSize.MEDIUM))
    views.setOnClickPendingIntent(R.id.btn_next, makeNavIntent(context, appWidgetId, ACTION_NEXT, WidgetSize.MEDIUM))

    val dotIds = intArrayOf(R.id.dot0, R.id.dot1)
    for (i in 0 until 2) {
        if (i < pages) {
            views.setViewVisibility(dotIds[i], View.VISIBLE)
            views.setTextViewText(dotIds[i], if (i == page) "●" else "○")
            views.setTextColor(dotIds[i], if (i == page) 0xFF5C5652.toInt() else 0xFFB8B3AD.toInt())
        } else {
            views.setViewVisibility(dotIds[i], View.GONE)
        }
    }
}

private fun bindLargeNormal(
    context: Context,
    views: RemoteViews,
    appWidgetId: Int,
    categories: JSONArray,
    total: Int
) {
    val cardIds  = intArrayOf(R.id.category_card_0, R.id.category_card_1, R.id.category_card_2, R.id.category_card_3)
    val emojiIds = intArrayOf(R.id.cat_emoji_0, R.id.cat_emoji_1, R.id.cat_emoji_2, R.id.cat_emoji_3)
    val nameIds  = intArrayOf(R.id.cat_name_0,  R.id.cat_name_1,  R.id.cat_name_2,  R.id.cat_name_3)
    val timeIds  = intArrayOf(R.id.cat_time_0,  R.id.cat_time_1,  R.id.cat_time_2,  R.id.cat_time_3)

    for (i in 0 until 4) {
        if (i < total) {
            val cat = categories.getJSONObject(i)
            views.setViewVisibility(cardIds[i], View.VISIBLE)
            views.setTextViewText(emojiIds[i], cat.optString("emoji", ""))
            views.setTextViewText(nameIds[i],  cat.optString("name", ""))
            views.setTextViewText(timeIds[i],  formatMinutes(cat.optInt("todayMinutes", 0)))
            views.setOnClickPendingIntent(
                cardIds[i],
                makeStartIntent(context, appWidgetId, i, WidgetSize.LARGE)
            )
        } else {
            views.setViewVisibility(cardIds[i], View.INVISIBLE)
        }
    }
}

// ─── 측정 중 상태 ─────────────────────────────────────────────────────────
private fun bindMeasuringState(
    context: Context,
    views: RemoteViews,
    size: WidgetSize,
    appWidgetId: Int,
    timerJson: String,
    flutterPrefs: SharedPreferences
) {
    views.setViewVisibility(R.id.normal_state, View.GONE)
    views.setViewVisibility(R.id.measuring_state, View.VISIBLE)

    val timer     = runCatching { JSONObject(timerJson) }.getOrElse { JSONObject() }
    val colorIndex = timer.optInt("colorIndex", -1)
    val isPaused   = timer.optBoolean("isPaused", false) ||
                     flutterPrefs.getBoolean(KEY_IS_PAUSED, false)

    // 카드 내용
    val emoji = timer.optString("categoryEmoji", "").ifEmpty { "⏱" }
    val name  = timer.optString("categoryName", "").ifEmpty { "측정 중" }
    views.setTextViewText(R.id.timer_emoji, emoji)
    views.setTextViewText(R.id.timer_name,  name)

    // 경과 시간 계산 및 Chronometer/정적 텍스트 설정
    val accumulated = flutterPrefs.getLong(KEY_ACCUMULATED, 0L)
    if (isPaused) {
        // 일시정지: Chronometer 숨기고 정적 텍스트 표시
        views.setViewVisibility(R.id.timer_chronometer, View.GONE)
        views.setViewVisibility(R.id.timer_paused_time, View.VISIBLE)
        views.setTextViewText(R.id.timer_paused_time, formatElapsed(accumulated))
    } else {
        // 측정 중: Chronometer로 실시간 표시
        views.setViewVisibility(R.id.timer_chronometer, View.VISIBLE)
        views.setViewVisibility(R.id.timer_paused_time, View.GONE)
        val startTimeStr = flutterPrefs.getString(KEY_START_TIME, null)
        val runningMs = if (startTimeStr != null) {
            val startMs = runCatching { isoFormat.parse(startTimeStr)!!.time }.getOrElse { System.currentTimeMillis() }
            accumulated + (System.currentTimeMillis() - startMs)
        } else accumulated
        val base = SystemClock.elapsedRealtime() - runningMs
        views.setChronometer(R.id.timer_chronometer, base, null, true)
    }

    // 일시정지/재개 버튼 텍스트
    val pauseResumeText = when (size) {
        WidgetSize.LARGE -> if (isPaused) "▶ 재개" else "|| 일시정지"
        else             -> if (isPaused) "▶"     else "||"
    }
    views.setTextViewText(R.id.btn_pause_resume, pauseResumeText)

    // 버튼 PendingIntent
    val pauseResumeAction = if (isPaused) ACTION_RESUME else ACTION_PAUSE
    views.setOnClickPendingIntent(
        R.id.btn_pause_resume,
        makeActionIntent(context, appWidgetId, pauseResumeAction, size)
    )
    views.setOnClickPendingIntent(
        R.id.btn_complete,
        makeActionIntent(context, appWidgetId, ACTION_COMPLETE, size)
    )
    views.setOnClickPendingIntent(
        R.id.btn_cancel,
        makeActionIntent(context, appWidgetId, ACTION_CANCEL, size)
    )
}

// ─── 타이머 액션 핸들러 ───────────────────────────────────────────────────
private fun handleStart(context: Context, categoryIndex: Int) {
    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    val categoriesJson = widgetPrefs.getString(WKEY_CATEGORIES, "[]") ?: "[]"
    val categories = runCatching { JSONArray(categoriesJson) }.getOrElse { JSONArray() }
    if (categoryIndex >= categories.length()) return

    val cat  = categories.getJSONObject(categoryIndex)
    val now  = System.currentTimeMillis()
    val nowIso = isoFormat.format(Date(now))

    // widget_timer 저장
    val timerData = JSONObject().apply {
        put("categoryId",    cat.optInt("id", -1))
        put("categoryName",  cat.optString("name", ""))
        put("categoryEmoji", cat.optString("emoji", ""))
        put("colorIndex",    cat.optInt("colorIndex", categoryIndex % 4))
        put("originalStartTime", nowIso)
        put("isPaused", false)
    }
    widgetPrefs.edit().putString(WKEY_TIMER, timerData.toString()).apply()

    // Flutter 타이머 상태 기록
    flutterPrefs.edit().apply {
        putString("flutter.timer_start_time",          nowIso)
        putString("flutter.timer_original_start_time", nowIso)
        putLong(  "flutter.timer_accumulated_ms", 0L)
        putBoolean("flutter.timer_is_running", true)
        putBoolean("flutter.timer_is_paused",  false)
        putInt(   "flutter.timer_category_id",    cat.optInt("id", -1))
        putString("flutter.timer_category_name",  cat.optString("name", ""))
        putString("flutter.timer_category_emoji", cat.optString("emoji", ""))
        putBoolean(KEY_WIDGET_INTERACTION, true)
    }.apply()

    refreshAllWidgets(context)
}

private fun handlePause(context: Context) {
    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    val now = System.currentTimeMillis()
    val startTimeStr = flutterPrefs.getString(KEY_START_TIME, null)
    val accumulated  = flutterPrefs.getLong(KEY_ACCUMULATED, 0L)

    val newAccumulated = if (startTimeStr != null) {
        val startMs = runCatching { isoFormat.parse(startTimeStr)!!.time }.getOrElse { now }
        accumulated + (now - startMs)
    } else accumulated

    flutterPrefs.edit().apply {
        remove(KEY_START_TIME)
        putLong(KEY_ACCUMULATED, newAccumulated)
        putBoolean(KEY_IS_RUNNING, false)
        putBoolean(KEY_IS_PAUSED,  true)
        putBoolean(KEY_WIDGET_INTERACTION, true)
    }.apply()

    val timerStr = widgetPrefs.getString(WKEY_TIMER, null)
    if (timerStr != null) {
        val t = runCatching { JSONObject(timerStr) }.getOrElse { JSONObject() }
        t.put("isPaused", true)
        widgetPrefs.edit().putString(WKEY_TIMER, t.toString()).apply()
    }

    refreshAllWidgets(context)
}

private fun handleResume(context: Context) {
    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    val nowIso = isoFormat.format(Date())

    flutterPrefs.edit().apply {
        putString(KEY_START_TIME, nowIso)
        putBoolean(KEY_IS_RUNNING, true)
        putBoolean(KEY_IS_PAUSED,  false)
        putBoolean(KEY_WIDGET_INTERACTION, true)
    }.apply()

    val timerStr = widgetPrefs.getString(WKEY_TIMER, null)
    if (timerStr != null) {
        val t = runCatching { JSONObject(timerStr) }.getOrElse { JSONObject() }
        t.put("isPaused", false)
        widgetPrefs.edit().putString(WKEY_TIMER, t.toString()).apply()
    }

    refreshAllWidgets(context)
}

private fun handleComplete(context: Context) {
    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

    // 경과 시간 계산
    val now = System.currentTimeMillis()
    val startTimeStr = flutterPrefs.getString(KEY_START_TIME, null)
    val accumulated  = flutterPrefs.getLong(KEY_ACCUMULATED, 0L)
    val totalMs = if (startTimeStr != null) {
        val startMs = runCatching { isoFormat.parse(startTimeStr)!!.time }.getOrElse { now }
        accumulated + (now - startMs)
    } else accumulated

    val minutes = (totalMs / 60_000L).toInt()

    // pending completion 저장 (1분 이상인 경우만)
    val timerStr = widgetPrefs.getString(WKEY_TIMER, null)
    if (timerStr != null && minutes > 0) {
        val t = runCatching { JSONObject(timerStr) }.getOrElse { JSONObject() }
        val categoryId = t.optInt("categoryId", -1)
        if (categoryId != -1) {
            val pending = JSONObject().apply {
                put("categoryId", categoryId)
                put("minutes", minutes)
            }
            widgetPrefs.edit().putString(WKEY_PENDING, pending.toString()).apply()
        }
    }

    // 위젯 카테고리 todayMinutes 즉시 반영
    if (timerStr != null && minutes > 0) {
        val t2 = runCatching { JSONObject(timerStr) }.getOrElse { JSONObject() }
        val catId = t2.optInt("categoryId", -1)
        if (catId != -1) {
            val catsJson = widgetPrefs.getString(WKEY_CATEGORIES, "[]") ?: "[]"
            val cats = runCatching { JSONArray(catsJson) }.getOrElse { JSONArray() }
            for (i in 0 until cats.length()) {
                val c = cats.optJSONObject(i) ?: continue
                if (c.optInt("id") == catId) {
                    c.put("todayMinutes", c.optInt("todayMinutes", 0) + minutes)
                    break
                }
            }
            widgetPrefs.edit().putString(WKEY_CATEGORIES, cats.toString()).apply()
        }
    }

    clearTimerState(flutterPrefs, widgetPrefs)
    refreshAllWidgets(context)
}

private fun handleCancel(context: Context) {
    val widgetPrefs  = context.getSharedPreferences(WIDGET_PREFS,  Context.MODE_PRIVATE)
    val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
    clearTimerState(flutterPrefs, widgetPrefs)
    refreshAllWidgets(context)
}

private fun handlePageChange(context: Context, size: WidgetSize, delta: Int) {
    val widgetPrefs    = context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
    val categoriesJson = widgetPrefs.getString(WKEY_CATEGORIES, "[]") ?: "[]"
    val total          = runCatching { JSONArray(categoriesJson).length() }.getOrElse { 0 }

    when (size) {
        WidgetSize.SMALL -> {
            if (total == 0) return
            val current = widgetPrefs.getInt(WKEY_SMALL_PAGE, 0)
            val next = (current + delta + total) % total
            widgetPrefs.edit().putInt(WKEY_SMALL_PAGE, next).apply()
        }
        WidgetSize.MEDIUM -> {
            val pages = if (total <= 2) 1 else 2
            if (pages == 1) return
            val current = widgetPrefs.getInt(WKEY_MEDIUM_PAGE, 0)
            val next = (current + delta + pages) % pages
            widgetPrefs.edit().putInt(WKEY_MEDIUM_PAGE, next).apply()
        }
        WidgetSize.LARGE -> return
    }

    refreshAllWidgets(context)
}

// ─── 공통 유틸 ────────────────────────────────────────────────────────────
private fun clearTimerState(flutterPrefs: SharedPreferences, widgetPrefs: SharedPreferences) {
    flutterPrefs.edit().apply {
        remove("flutter.timer_start_time")
        remove("flutter.timer_original_start_time")
        remove("flutter.timer_accumulated_ms")
        remove("flutter.timer_is_running")
        remove("flutter.timer_is_paused")
        remove("flutter.timer_category_id")
        remove("flutter.timer_category_name")
        remove("flutter.timer_category_emoji")
        putBoolean(KEY_WIDGET_INTERACTION, true)
    }.apply()
    widgetPrefs.edit().remove(WKEY_TIMER).apply()
}

private fun refreshAllWidgets(context: Context) {
    val manager = AppWidgetManager.getInstance(context)
    for ((cls, size) in listOf(
        TimerWidgetSmall::class.java  to WidgetSize.SMALL,
        TimerWidgetMedium::class.java to WidgetSize.MEDIUM,
        TimerWidgetLarge::class.java  to WidgetSize.LARGE,
    )) {
        val ids = manager.getAppWidgetIds(
            android.content.ComponentName(context, cls)
        )
        for (id in ids) updateWidget(context, manager, id, size)
    }
}

private fun makeStartIntent(
    context: Context,
    appWidgetId: Int,
    categoryIndex: Int,
    size: WidgetSize
): PendingIntent {
    val intent = Intent(context, when (size) {
        WidgetSize.SMALL  -> TimerWidgetSmall::class.java
        WidgetSize.MEDIUM -> TimerWidgetMedium::class.java
        WidgetSize.LARGE  -> TimerWidgetLarge::class.java
    }).apply {
        action = ACTION_START
        putExtra(EXTRA_CATEGORY_INDEX, categoryIndex)
        putExtra(EXTRA_WIDGET_SIZE, size.name)
    }
    val requestCode = (appWidgetId and 0xFFFF) * 10 + categoryIndex
    return PendingIntent.getBroadcast(
        context, requestCode, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

private fun makeNavIntent(
    context: Context,
    appWidgetId: Int,
    action: String,
    size: WidgetSize
): PendingIntent {
    val intent = Intent(context, when (size) {
        WidgetSize.SMALL  -> TimerWidgetSmall::class.java
        WidgetSize.MEDIUM -> TimerWidgetMedium::class.java
        WidgetSize.LARGE  -> TimerWidgetLarge::class.java
    }).apply {
        this.action = action
        putExtra(EXTRA_WIDGET_SIZE, size.name)
    }
    val requestCode = (appWidgetId and 0xFFFF) * 10 + action.hashCode() % 10
    return PendingIntent.getBroadcast(
        context, requestCode, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

private fun makeActionIntent(
    context: Context,
    appWidgetId: Int,
    action: String,
    size: WidgetSize
): PendingIntent {
    val intent = Intent(context, when (size) {
        WidgetSize.SMALL  -> TimerWidgetSmall::class.java
        WidgetSize.MEDIUM -> TimerWidgetMedium::class.java
        WidgetSize.LARGE  -> TimerWidgetLarge::class.java
    }).apply {
        this.action = action
        putExtra(EXTRA_WIDGET_SIZE, size.name)
    }
    val requestCode = (appWidgetId and 0xFFFF) * 100 + action.hashCode() % 100
    return PendingIntent.getBroadcast(
        context, requestCode, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

private fun formatMinutes(minutes: Int): String {
    if (minutes <= 0) return "0m"
    val h = minutes / 60
    val m = minutes % 60
    return if (h > 0) "${h}h ${m}m" else "${m}m"
}

private fun formatElapsed(ms: Long): String {
    val totalSec = ms / 1000
    val h = totalSec / 3600
    val m = (totalSec % 3600) / 60
    val s = totalSec % 60
    return if (h > 0) String.format("%d:%02d:%02d", h, m, s)
    else String.format("%d:%02d", m, s)
}

private fun scheduleMidnightRefresh(context: Context) {
    val midnight = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 5) // 자정 직후 5초
        set(Calendar.MILLISECOND, 0)
    }
    val intent = Intent(context, TimerWidgetSmall::class.java).apply {
        action = ACTION_MIDNIGHT
    }
    val pi = PendingIntent.getBroadcast(
        context, 999999, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    am.set(AlarmManager.RTC, midnight.timeInMillis, pi)
}
