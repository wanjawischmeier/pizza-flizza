package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.annotation.Nullable
import androidx.cardview.widget.CardView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import java.lang.Float.max
import java.lang.Integer.max
import java.lang.Integer.min
import kotlin.math.*

const val CARD_SCALE_EXPANDED = 1.04f

class ShopFragment : CallableFragment() {
    private lateinit var card: CardView
    private var cardMode = 0
    private var maxItems = 5
    private var itemCount = 5
    private var screenCenter = 0f
    private var grabX = 0f
    private var grabY = 0f
    private var cardX = 0f
    private var cardY = 0f


    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_shop, container, false)
    }

    @Nullable
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val displayMetrics = resources.displayMetrics
        screenCenter = displayMetrics.widthPixels.toFloat() / 2
    }

    override fun onShow() {
        if (this::card.isInitialized) {
            card.isVisible = false
        }
    }

    override fun onBottomLayoutGone() {
        Shop.getOrders().addOnCompleteListener { ordersTask ->
            Shop.orders = ordersTask.result ?: return@addOnCompleteListener
            Shop.getItems().addOnCompleteListener { itemsTask ->
                Shop.items = itemsTask.result ?: return@addOnCompleteListener
                loadOrder()
            }
        }
    }

    private fun loadOrder() {
        if (Shop.orders.isEmpty()) {
            return
        }

        val order = Shop.orders.iterator().next()
        val item = order.value.iterator().next()
        val newItems = order.value.toMutableMap()
        newItems.remove(item.key)

        if (newItems.isEmpty()) {
            Shop.orders.remove(order.key)
        } else {
            Shop.orders[order.key] = newItems
        }

        createCard(Shop.items[item.key]?.name ?: return, item.value)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun createCard(item: String, count: Int) {
        if (this::card.isInitialized) {
            removeCard()
        }

        val cardView = layoutInflater.inflate(R.layout.card_shop, view as ViewGroup)

        card = cardView.findViewById(R.id.card)
        card.alpha = 0f
        card.scaleX = 0f
        card.scaleY = 0f
        maxItems = count
        itemCount = maxItems

        card.findViewById<TextView>(R.id.item_count).text = itemCount.toString()
        card.findViewById<TextView>(R.id.item_name).text = item

        (view as ViewGroup).post {
            card.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .withEndAction {
                    cardX = card.x
                    cardY = card.y
                }
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
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

    private fun removeCard() {
        (card.parent.parent as ViewGroup)
            .removeView(card.parent as ConstraintLayout)
    }


    private fun onCardClicked(card: View, event: MotionEvent) {
        grabX = event.rawX
        grabY = event.rawY

        card.animate()
            .scaleX(CARD_SCALE_EXPANDED)
            .scaleY(CARD_SCALE_EXPANDED)
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

            if (itemCount != newItems) {
                card.animate()
                    .scaleX(CARD_SCALE_EXPANDED)
                    .scaleY(CARD_SCALE_EXPANDED)
                    .setDuration(10)
                    .withEndAction {
                        card.animate()
                            .scaleX(1f)
                            .scaleY(1f)
                            .duration = 50
                    }
                    .start()

                itemCount = newItems
            }

            val itemCount = card.findViewById<TextView>(R.id.item_count)
            itemCount.text = this.itemCount.toString()

            val slider = card.findViewById<View>(R.id.progress)
            slider.y = ((maxItems - this.itemCount).toFloat() / maxItems) * card.height

        } else {

            if (cardMode == 0 && diff > screenCenter / 4) {
                cardMode = max(-1, min(1, (diffX * 4  - diffY).roundToInt()))

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
                .withEndAction { loadOrder() }
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