package com.travary.app.widget

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Draws one widget as three layers, so Travi can rise and duck between
 * them (Android widgets can't animate views, only flip between them):
 *
 * - [back]: the trip's linen, and on the large widget the heading; on the
 *   others the postcard too, as Travi rises in front of it.
 * - [travi]: Travi up, the rest clear.
 * - [front]: the postcard on the large widget (he hides behind it), and
 *   always the luggage tag with the count.
 *
 * Every word is live text over the app's raster art, in the app's fonts,
 * laid out like the iOS widget (CountdownViews.swift).
 */
class CountdownWidgetRenderer(
    private val face: CountdownFace,
    private val stage: CountdownStage,
    /** Pixels per point: the stage is in pixels, sizes are shares of it. */
    private val scale: Float,
    /** The launcher's corner radius, in pixels: every layer is clipped to it. */
    private val radius: Float,
) {
    private val width = stage.width.roundToInt().coerceAtLeast(1)
    private val height = stage.height.roundToInt().coerceAtLeast(1)

    fun back(): Bitmap = layer { canvas ->
        drawLinen(canvas)
        heading(canvas)
        if (!stage.traviBehind) drawPostcard(canvas)
    }

    fun travi(): Bitmap? {
        val still = face.travi ?: return null
        val square = stage.travi
        val k = square.width() / still.canvas
        val box = RectF(
            square.left + still.box.left * k, square.top + still.box.top * k,
            square.left + still.box.right * k, square.top + still.box.bottom * k,
        )
        val image = decode(still.file, box.width(), box.height()) ?: return null
        return layer { canvas -> canvas.drawBitmap(image, null, box, imagePaint) }
    }

    fun front(): Bitmap = layer { canvas ->
        if (stage.traviBehind) drawPostcard(canvas)
        drawTag(canvas)
    }

    private fun layer(draw: (Canvas) -> Unit): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.clipPath(Path().apply { addRoundRect(RectF(0f, 0f, stage.width, stage.height), radius, radius, Path.Direction.CW) })
        draw(canvas)
        return bitmap
    }

    /** The woven linen, tiled as behind the app's screens (its 1024-pixel tile at 341 points). */
    private fun drawLinen(canvas: Canvas) {
        canvas.drawColor(LINEN)
        val tileSize = 341.33f * scale
        val tile = decode(face.linen, tileSize, tileSize) ?: return
        val shader = BitmapShader(tile, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT)
        shader.setLocalMatrix(Matrix().apply { setScale(tileSize / tile.width, tileSize / tile.height) })
        canvas.drawRect(0f, 0f, stage.width, stage.height, Paint().apply { this.shader = shader; isFilterBitmap = true })
    }

    private fun heading(canvas: Canvas) {
        val x = stage.headingX ?: return
        val y = stage.headingY ?: return
        val paint = textPaint(fonts.sans, 0.027f * stage.height, tracking = 0.25f)
        canvas.drawText(face.heading, x, y - paint.fontMetrics.ascent, paint)
    }

    /** The whole postcard, deckled edge and all; a landscape one missing, the portrait's picture as a print. */
    private fun drawPostcard(canvas: Canvas) {
        val frame = stage.postcard
        val landscape = if (stage.landscape) decode(face.landscape, frame.width(), frame.height()) else null
        when {
            landscape != null -> canvas.drawBitmap(landscape, null, frame, imagePaint)
            stage.landscape && face.portrait != null -> croppedPrint(canvas, frame)
            !stage.landscape && face.portrait != null ->
                decode(face.portrait, frame.width(), frame.height())?.let { canvas.drawBitmap(it, null, frame, imagePaint) }
                    ?: paperStandIn(canvas, frame)
            else -> paperStandIn(canvas, frame)
        }
    }

    /** The picture from a portrait postcard as a landscape print: its middle, from the upper part of the scene. */
    private fun croppedPrint(canvas: Canvas, frame: RectF) {
        val card = WidgetGeometry.landscapeCard
        val inner = RectF(
            frame.left + frame.width() * card.left, frame.top + frame.height() * card.top,
            frame.left + frame.width() * card.right, frame.top + frame.height() * card.bottom,
        )
        canvas.drawRoundRect(inner, 3 * scale, 3 * scale, shadowPaint(face.paper, 4f))
        val border = 0.03f * inner.width()
        val picture = RectF(inner.left + border, inner.top + border, inner.right - border, inner.bottom - border)
        val w = picture.width() / 0.80f
        val h = w / WidgetGeometry.PORTRAIT_ASPECT
        val image = decode(face.portrait, w, h) ?: return
        canvas.save()
        canvas.clipRect(picture)
        canvas.drawBitmap(image, null, RectF(picture.left - 0.10f * w, picture.top - 0.12f * h, picture.left + 0.9f * w, picture.top + 0.88f * h), imagePaint)
        canvas.restore()
    }

    private fun paperStandIn(canvas: Canvas, frame: RectF) {
        val inset = 6 * scale
        canvas.drawRoundRect(RectF(frame.left + inset, frame.top + inset, frame.right - inset, frame.bottom - inset), 3 * scale, 3 * scale, shadowPaint(face.paper, 5f))
    }

    /** The luggage tag, turned from its eyelet, with the count written on it in the trip's ink. */
    private fun drawTag(canvas: Canvas) {
        val image = stage.tagImage
        canvas.save()
        canvas.rotate(stage.tagDegrees, image.left + WidgetGeometry.EYELET_X * image.width(), image.top + WidgetGeometry.EYELET_Y * image.height())
        val raster = decode(face.tag, image.width(), image.height())
        if (raster != null) {
            canvas.drawBitmap(raster, null, image, imagePaint)
        } else {
            canvas.drawRoundRect(stage.tagCard, 6 * scale, 6 * scale, shadowPaint(face.paper, 5f))
        }
        drawCopy(canvas, stage.copy, stage.tagCard.width())
        canvas.restore()
    }

    /**
     * The words on the tag, sized to its card and fewer on the smaller tags,
     * centred down the card. Like the app's tag, they shrink together when
     * they don't fit, never one alone.
     */
    private fun drawCopy(canvas: Canvas, copy: RectF, cardWidth: Float) {
        var lines = emptyList<Line>()
        for (k in listOf(1f, 0.92f, 0.84f, 0.76f, 0.68f, 0.6f)) {
            lines = copyLines(cardWidth * k, copy.width())
            if (lines.sumOf { it.height.toDouble() } <= copy.height()) break
        }
        val total = lines.sumOf { it.height.toDouble() }.toFloat()
        var y = copy.top + max(0f, (copy.height() - total) / 2)
        for (line in lines) {
            line.draw(canvas, copy.centerX(), y)
            y += line.height
        }
    }

    private fun copyLines(w: Float, maxWidth: Float): List<Line> {
        val lines = mutableListOf<Line>()
        val days = face.days
        if (days != null) {
            when (stage.size) {
                CountdownStage.Size.LARGE -> {
                    lines += eyebrow(face.eyebrow, 0.087f * w, maxWidth)
                    lines += Gap(0.03f * w)
                    lines += number(days, 0.56f * w, maxWidth)
                    lines += Gap(0.02f * w)
                    lines += eyebrow(face.daysLabel, 0.087f * w, maxWidth)
                    lines += Rule(0.06f * w, w)
                    lines += place(0.175f * w, 2, maxWidth)
                    lines += Gap(0.03f * w)
                    lines += line(face.dates, 0.10f * w, maxWidth)
                }
                CountdownStage.Size.MEDIUM -> {
                    lines += number(days, 0.56f * w, maxWidth)
                    lines += Gap(0.02f * w)
                    lines += eyebrow(face.daysLabel, 0.10f * w, maxWidth)
                    lines += Rule(0.055f * w, w)
                    lines += place(0.19f * w, 2, maxWidth)
                    lines += Gap(0.025f * w)
                    lines += line(face.shortDates, 0.115f * w, maxWidth)
                }
                CountdownStage.Size.SMALL -> {
                    lines += number(days, 0.63f * w, maxWidth)
                    lines += Gap(0.02f * w)
                    lines += eyebrow(face.daysLabel, 0.13f * w, maxWidth)
                    lines += Gap(0.07f * w)
                    lines += place(0.21f * w, 2, maxWidth)
                }
            }
        } else {
            if (stage.size == CountdownStage.Size.LARGE) {
                lines += eyebrow(face.eyebrow, 0.087f * w, maxWidth)
                lines += Gap(0.08f * w)
            }
            lines += place(if (stage.size == CountdownStage.Size.SMALL) 0.24f * w else 0.22f * w, 3, maxWidth)
            lines += Gap(0.05f * w)
            lines += line(
                if (stage.size == CountdownStage.Size.LARGE) face.dates else face.shortDates,
                if (stage.size == CountdownStage.Size.SMALL) 0.13f * w else 0.11f * w,
                maxWidth,
            )
        }
        return lines
    }

    private interface Line {
        val height: Float
        fun draw(canvas: Canvas, centreX: Float, top: Float)
    }

    private class Gap(override val height: Float) : Line {
        override fun draw(canvas: Canvas, centreX: Float, top: Float) = Unit
    }

    private inner class Rule(private val space: Float, cardWidth: Float) : Line {
        private val ruleWidth = 0.6f * cardWidth
        private val thickness = max(0.5f * scale, 0.008f * cardWidth)
        override val height = 2 * space + thickness
        override fun draw(canvas: Canvas, centreX: Float, top: Float) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = face.ink; alpha = (0.35f * 255).roundToInt() }
            canvas.drawRect(centreX - ruleWidth / 2, top + space, centreX + ruleWidth / 2, top + space + thickness, paint)
        }
    }

    /** One line, already shrunk to fit; [trim] of its size off the top and bottom of its line box. */
    private inner class TextLine(private val text: String, private val paint: TextPaint, private val trim: Float = 0f) : Line {
        override val height: Float = paint.fontMetrics.let { it.descent - it.ascent } - 2 * trim * paint.textSize
        override fun draw(canvas: Canvas, centreX: Float, top: Float) {
            val textWidth = paint.measureText(text)
            canvas.drawText(text, centreX - textWidth / 2, top - paint.fontMetrics.ascent - trim * paint.textSize, paint)
        }
    }

    /** Up to [maxLines] lines, centred, smaller until no word breaks. */
    private inner class Block(private val layout: StaticLayout) : Line {
        override val height = layout.height.toFloat()
        override fun draw(canvas: Canvas, centreX: Float, top: Float) {
            canvas.save()
            canvas.translate(centreX - layout.width / 2f, top)
            layout.draw(canvas)
            canvas.restore()
        }
    }

    /** The count's line box hugs its figures, as on the app's tag. */
    private fun number(text: String, size: Float, maxWidth: Float) =
        TextLine(text, fitted(text, textPaint(fonts.serif, size, tracking = -0.025f), maxWidth, 0.4f), trim = 0.14f)

    private fun eyebrow(text: String, size: Float, maxWidth: Float) =
        TextLine(text, fitted(text, textPaint(fonts.sans, size, tracking = 0.22f), maxWidth, 0.5f))

    private fun line(text: String, size: Float, maxWidth: Float) =
        TextLine(text, fitted(text, textPaint(fonts.sansMedium, size, tracking = 0f), maxWidth, 0.55f))

    /** The trip's name: on one line if it fits a little smaller, else on up to [maxLines] lines. */
    private fun place(size: Float, maxLines: Int, maxWidth: Float): Line {
        for (k in listOf(1f, 0.9f, 0.8f)) {
            val paint = textPaint(fonts.serif, size * k, tracking = -0.012f)
            if (paint.measureText(face.place) <= maxWidth) return TextLine(face.place, paint)
        }
        val words = face.place.split(Regex("\\s+"))
        var current = size
        while (true) {
            val paint = textPaint(fonts.serif, current, tracking = -0.012f)
            val layout = StaticLayout.Builder.obtain(face.place, 0, face.place.length, paint, maxWidth.roundToInt().coerceAtLeast(1))
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setIncludePad(false)
                .setMaxLines(maxLines)
                .setEllipsize(android.text.TextUtils.TruncateAt.END)
                .build()
            val fits = words.all { paint.measureText(it) <= maxWidth } &&
                (layout.lineCount < maxLines || layout.getEllipsisCount(maxLines - 1) == 0)
            if (fits || current <= size * 0.55f) return Block(layout)
            current -= max(0.5f, size * 0.03f)
        }
    }

    private fun fitted(text: String, paint: TextPaint, maxWidth: Float, minScale: Float): TextPaint {
        val start = paint.textSize
        while (paint.measureText(text) > maxWidth && paint.textSize > start * minScale) {
            paint.textSize = paint.textSize - max(0.5f, start * 0.03f)
        }
        return paint
    }

    private fun textPaint(typeface: Typeface, size: Float, tracking: Float) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        this.typeface = typeface
        textSize = size
        letterSpacing = tracking
        color = face.ink
        isSubpixelText = true
    }

    private fun shadowPaint(colour: Int, blur: Float) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = colour
        setShadowLayer(blur * scale, 0f, 2 * scale, Color.argb(46, 0, 0, 0))
    }

    private val imagePaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

    private val fonts = Fonts(face)

    /** The app's fonts, else the system's serif and sans. */
    private class Fonts(face: CountdownFace) {
        val serif: Typeface = load(face.serif) ?: Typeface.create(Typeface.SERIF, Typeface.BOLD)
        val sans: Typeface = load(face.sans) ?: Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        val sansMedium: Typeface = load(face.sansMedium) ?: Typeface.SANS_SERIF

        companion object {
            private val cache = mutableMapOf<String, Typeface>()

            fun load(file: File?): Typeface? {
                file ?: return null
                return synchronized(cache) {
                    cache[file.path] ?: try {
                        Typeface.createFromFile(file).also { cache[file.path] = it }
                    } catch (_: Exception) {
                        null
                    }
                }
            }
        }
    }

    companion object {
        private val LINEN = Color.rgb(0xEF, 0xE8, 0xDC)

        /** Decoded no larger than needed for [w] × [h] pixels: widgets have a tight memory budget. */
        fun decode(file: File?, w: Float, h: Float): Bitmap? {
            file ?: return null
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(file.path, bounds)
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= w && bounds.outHeight / (sample * 2) >= h) sample *= 2
                BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
            } catch (_: Exception) {
                null
            }
        }

        /** Pixels per point for a widget [wDp] × [hDp], at most about a million pixels a layer. */
        fun scaleFor(wDp: Float, hDp: Float, density: Float): Float =
            min(density, kotlin.math.sqrt(1_000_000f / max(1f, wDp * hDp)))
    }
}
