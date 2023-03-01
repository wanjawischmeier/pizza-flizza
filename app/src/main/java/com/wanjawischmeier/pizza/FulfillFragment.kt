package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.Nullable
import androidx.cardview.widget.CardView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import java.lang.Float.max
import java.lang.Integer.max
import java.lang.Integer.min
import kotlin.math.*

class FulfillFragment : CallableFragment() {
    lateinit var card: CardView
    private var cardScaleExpanded = 1.04f
    private var cardMode = 0

    private var maxItems = 5
    private var items = 5
    private var screenCenter = 0f
    private var grabX = 0f
    private var grabY = 0f
    var cardX = 0f
    var cardY = 0f


    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_fulfill, container, false)
    }

    @Nullable
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val displayMetrics = resources.displayMetrics
        screenCenter = displayMetrics.widthPixels.toFloat() / 2
    }

    override fun onShow() {
        isTopBubbleVisible = false
        isBottomLayoutVisible = false

        if (this::card.isInitialized) {
            card.isVisible = false
        }
    }

    override fun onBottomLayoutGone() {
        if (!this::card.isInitialized) {
            createCard()
            return
        }

        card.scaleX = 0f
        card.scaleY = 0f
        card.isVisible = true

        card.animate()
            .scaleX(1f)
            .scaleY(1f)
            .duration = 100
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun createCard() {
        val cardView = layoutInflater.inflate(R.layout.fulfill_card, view as ViewGroup)

        card = cardView.findViewById(R.id.card)
        card.scaleX = 0f
        card.scaleY = 0f
        onCardCreated(card)

        (view as ViewGroup).post {
            card.animate()
                .scaleX(1f)
                .scaleY(1f)
                .withEndAction {
                    cardX = card.x
                    cardY = card.y
                }
                .duration = 100
        }

        card.setOnTouchListener(
            View.OnTouchListener { view, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> onCardClicked(view, event)
                    MotionEvent.ACTION_MOVE -> onCardMoved(view, event)
                    MotionEvent.ACTION_UP -> onCardReleased(view, event)
                }

                return@OnTouchListener true
            }
        )
    }


    private fun onCardCreated(card: View) {
        items = maxItems

        card.findViewById<TextView>(R.id.item_count).text = items.toString()
        card.findViewById<TextView>(R.id.item_name).text = getString(R.string.sample_item_name)
    }


    private fun onCardClicked(card: View, event: MotionEvent) {
        grabX = event.rawX
        grabY = event.rawY

        card.animate()
            .scaleX(cardScaleExpanded)
            .scaleY(cardScaleExpanded)
            .duration = 10
    }


    private fun onCardMoved(card: View, event: MotionEvent) {
        val diffX = abs(event.rawX - grabX)
        val rawDiffY = event.rawY - grabY
        val diffY = abs(rawDiffY)
        val diff = max(diffX, diffY)

        if (cardMode == -1) {
            val relative = (event.rawY - cardY) / (card.height)
            val newItems = min(maxItems, max(1, ((1 - relative) * maxItems + 1).roundToInt()))

            if (items != newItems) {
                card.animate()
                    .scaleX(cardScaleExpanded)
                    .scaleY(cardScaleExpanded)
                    .setDuration(10)
                    .withEndAction {
                        card.animate()
                            .scaleX(1f)
                            .scaleY(1f)
                            .duration = 50
                    }
                    .start()

                items = newItems
            }

            val itemCount = card.findViewById<TextView>(R.id.item_count)
            itemCount.text = items.toString()

            val slider = card.findViewById<View>(R.id.progress)
            slider.y = ((maxItems - items).toFloat() / maxItems) * card.height

        } else {

            if (cardMode == 0 && diff > screenCenter / 4) {
                cardMode = if (rawDiffY > 0) -1
                else {
                    max(-1, min(1, (diffX * 4  - diffY).roundToInt()))
                }

                card.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .duration = 50

                if (cardMode == -1) {
                    card.animate()
                        .x(cardX)
                        .y(cardY)
                        .rotation(0f)
                        .duration = 50
                }
            } else {
                card.animate()
                    .x(cardX + (event.rawX - grabX))
                    .y(cardY + (event.rawY - grabY) / 4)
                    .rotation((event.rawX - grabX) / (card.width/20))
                    .duration = 0
            }
        }
    }


    private fun onCardReleased(card: View, event: MotionEvent) {
        val diff = event.rawX - grabX

        if (cardMode == 1 && abs(diff) > screenCenter / 4) {

            val target = if (diff < 0) {
                // Toast.makeText(applicationContext, "left", Toast.LENGTH_SHORT).show()
                cardX - screenCenter * 3
            } else {
                // Toast.makeText(applicationContext, "right", Toast.LENGTH_SHORT).show()
                cardX + screenCenter * 3
            }

            card.animate()
                .x(target)
                .y(event.rawY - card.height / 1.5f)
                .setDuration(200)
                .withEndAction {
                    (card.parent.parent as ViewGroup)
                        .removeView(card.parent as ConstraintLayout)
                    createCard()
                }
        } else {
            card.animate()
                .x(cardX)
                .y(cardY)
                .scaleX(1f)
                .scaleY(1f)
                .rotation(0f)
                .duration = 200
        }

        cardMode = 0
    }
}