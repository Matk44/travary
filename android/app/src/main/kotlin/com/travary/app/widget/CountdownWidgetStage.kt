package com.travary.app.widget

import android.graphics.RectF
import kotlin.math.min

/**
 * Where everything sits on each size of widget, in pixels from its top
 * left. The same numbers draw the iOS widget (CountdownStage.swift) and are
 * explained in docs/COUNTDOWN_WIDGET.md; the rasters' own measurements are
 * Today's (`CountdownGeometry`, `UpcomingTripPostcard`).
 */
object WidgetGeometry {
    /** `common/countdown_postcard` is 1122 × 1402, the card inside a transparent margin. */
    const val PORTRAIT_ASPECT = 1122f / 1402f
    val portraitCard = RectF(0.034f, 0.05f, 0.966f, 0.96f)

    /** `common/trip_postcard` is 1536 × 1024. */
    const val LANDSCAPE_ASPECT = 1.5f
    val landscapeCard = RectF(0.02f, 0.045f, 0.98f, 0.97f)

    /** `common/countdown_luggage_tag` is 1024 × 1536: its card, and the eyelet it hangs from. */
    const val TAG_ASPECT = 1024f / 1536f
    val tagBody = RectF(0.170f, 0.261f, 0.788f, 0.982f)
    const val EYELET_X = 0.593f
    const val EYELET_Y = 0.342f

    /** The words inside the tag's card: clear of the eyelet at the top. */
    const val COPY_SIDE = 0.11f
    const val COPY_TOP = 0.20f
    const val COPY_BOTTOM = 0.06f

    /** A tag card's height for its width. */
    val tagCardRatio: Float get() = tagBody.height() / TAG_ASPECT / tagBody.width()
}

class CountdownStage(
    val size: Size,
    val width: Float,
    val height: Float,
    /** The postcard image (its transparent margin included). */
    val postcard: RectF,
    val landscape: Boolean,
    /** The tag's card, at rest before it's turned. */
    val tagCard: RectF,
    val tagDegrees: Float,
    /** Travi's square when he's up: behind the postcard (large), else rising from the bottom edge. */
    val travi: RectF,
    val traviBehind: Boolean,
    /** The heading's top left (large only). */
    val headingX: Float?,
    val headingY: Float?,
) {
    enum class Size { SMALL, MEDIUM, LARGE }

    /** The whole tag raster round its card, cord and shadow. */
    val tagImage: RectF
        get() {
            val body = WidgetGeometry.tagBody
            val w = tagCard.width() / body.width()
            val h = w / WidgetGeometry.TAG_ASPECT
            val left = tagCard.left - body.left * w
            val top = tagCard.top - body.top * h
            return RectF(left, top, left + w, top + h)
        }

    /** Where the words go inside the tag's card. */
    val copy: RectF
        get() = RectF(
            tagCard.left + tagCard.width() * WidgetGeometry.COPY_SIDE,
            tagCard.top + tagCard.height() * WidgetGeometry.COPY_TOP,
            tagCard.right - tagCard.width() * WidgetGeometry.COPY_SIDE,
            tagCard.bottom - tagCard.height() * WidgetGeometry.COPY_BOTTOM,
        )

    companion object {
        /** The layout for a widget [w] × [h]: wide ones are medium, roomy ones large. */
        fun sizeFor(wDp: Float, hDp: Float): Size = when {
            wDp >= 1.6f * hDp -> Size.MEDIUM
            min(wDp, hDp) < 220f -> Size.SMALL
            else -> Size.LARGE
        }

        fun of(size: Size, w: Float, h: Float): CountdownStage = when (size) {
            Size.LARGE -> large(w, h)
            Size.MEDIUM -> medium(w, h)
            Size.SMALL -> small(w, h)
        }

        /** Today's countdown: the heading over the portrait postcard, the tag on its lower right, Travi behind its top. */
        private fun large(w: Float, h: Float): CountdownStage {
            val card = WidgetGeometry.portraitCard
            val overhang = 0.16f
            var top = 0.155f * h
            val bottom = 0.972f * h
            var imageHeight = (bottom - top) / card.height()
            var imageWidth = imageHeight * WidgetGeometry.PORTRAIT_ASPECT
            val widest = 0.94f * w / (card.width() + overhang)
            if (imageWidth > widest) {
                imageWidth = widest
                imageHeight = imageWidth / WidgetGeometry.PORTRAIT_ASPECT
                top = bottom - imageHeight * card.height()
            }
            val cardWidth = imageWidth * card.width()
            val cardLeft = (w - cardWidth - overhang * imageWidth) / 2
            val imageLeft = cardLeft - card.left * imageWidth
            val imageTop = top - card.top * imageHeight
            val tagWidth = 0.40f * imageWidth
            val tagHeight = tagWidth * WidgetGeometry.tagCardRatio
            val tagRight = cardLeft + cardWidth + overhang * imageWidth
            val tagBottom = 0.966f * h
            val travi = 0.28f * imageWidth
            val traviLeft = imageLeft + 0.88f * imageWidth - travi
            val traviTop = top + 0.22f * travi - travi
            return CountdownStage(
                Size.LARGE, w, h,
                RectF(imageLeft, imageTop, imageLeft + imageWidth, imageTop + imageHeight), false,
                RectF(tagRight - tagWidth, tagBottom - tagHeight, tagRight, tagBottom), 6f,
                RectF(traviLeft, traviTop, traviLeft + travi, traviTop + travi), true,
                cardLeft + 2 * (h / 354f), 0.045f * h,
            )
        }

        /** The Trips tab's postcard: landscape, the tag on its right edge, Travi popping up beside it. */
        private fun medium(w: Float, h: Float): CountdownStage {
            val card = WidgetGeometry.landscapeCard
            val overhang = 0.13f
            val travi = 0.52f * h
            val cardLeft = 0.03f * w
            var imageHeight = 0.9f * h / card.height()
            var imageWidth = imageHeight * WidgetGeometry.LANDSCAPE_ASPECT
            // A taller widget (the 4 × 2 is about 1.6 wide): Travi tucks partly behind the tag so the postcard needn't shrink as much.
            val widest = (w - cardLeft - 0.7f * travi) / (card.width() + overhang)
            if (imageWidth > widest) {
                imageWidth = widest
                imageHeight = imageWidth / WidgetGeometry.LANDSCAPE_ASPECT
            }
            val cardTop = (h - imageHeight * card.height()) / 2
            val imageLeft = cardLeft - card.left * imageWidth
            val imageTop = cardTop - card.top * imageHeight
            val cardRight = cardLeft + imageWidth * card.width()
            val tagWidth = 0.34f * imageWidth
            val tagHeight = tagWidth * WidgetGeometry.tagCardRatio
            val tagRight = cardRight + overhang * imageWidth
            val tagBottom = 0.95f * h
            val traviLeft = w - 0.97f * travi
            val traviTop = h - 0.98f * travi
            return CountdownStage(
                Size.MEDIUM, w, h,
                RectF(imageLeft, imageTop, imageLeft + imageWidth, imageTop + imageHeight), true,
                RectF(tagRight - tagWidth, tagBottom - tagHeight, tagRight, tagBottom), 4f,
                RectF(traviLeft, traviTop, traviLeft + travi, traviTop + travi), false,
                null, null,
            )
        }

        /** The portrait postcard filling the height, the tag over its right side. */
        private fun small(w: Float, h: Float): CountdownStage {
            val card = WidgetGeometry.portraitCard
            // A tall, narrow widget keeps the postcard inside its width.
            val imageHeight = min(0.9f * h / card.height(), 0.82f * w / WidgetGeometry.PORTRAIT_ASPECT)
            val imageWidth = imageHeight * WidgetGeometry.PORTRAIT_ASPECT
            val cardLeft = 0.05f * w
            val cardTop = (h - imageHeight * card.height()) / 2
            val imageLeft = cardLeft - card.left * imageWidth
            val imageTop = cardTop - card.top * imageHeight
            val tagWidth = 0.48f * imageWidth
            val tagHeight = tagWidth * WidgetGeometry.tagCardRatio
            val tagRight = 0.95f * w
            val tagBottom = cardTop + imageHeight * card.height()
            val travi = 0.45f * min(w, h)
            val traviLeft = -0.02f * w
            val traviTop = h - 0.92f * travi
            return CountdownStage(
                Size.SMALL, w, h,
                RectF(imageLeft, imageTop, imageLeft + imageWidth, imageTop + imageHeight), false,
                RectF(tagRight - tagWidth, tagBottom - tagHeight, tagRight, tagBottom), 5f,
                RectF(traviLeft, traviTop, traviLeft + travi, traviTop + travi), false,
                null, null,
            )
        }
    }
}
