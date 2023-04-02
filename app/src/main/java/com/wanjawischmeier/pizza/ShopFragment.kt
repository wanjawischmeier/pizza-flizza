package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.*
import android.view.View.OnTouchListener
import android.widget.ProgressBar
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isInvisible
import androidx.core.view.isVisible
import com.google.android.gms.tasks.Task
import java.lang.Float.max
import java.lang.Integer.max
import java.lang.Integer.min
import java.util.Calendar
import kotlin.math.*


const val CARD_SCALE_EXPANDED = 1.04f

class ShopFragment : CallableFragment() {
    private lateinit var main: MainActivity
    private lateinit var lockButton: TextView
    private lateinit var lockProgress: View
    private lateinit var progressBar: ProgressBar
    private lateinit var card: CardView
    private lateinit var openOrders: HashMap<String, HashMap<String, MutableList<Long>>>
    private lateinit var currentOrder: Order
    private var leftOrders = 0
    private var cardMode = 0
    private var maxItems = 5
    private var itemCount = 5
    private var itemId = ""
    private var screenCenter = 0f
    private var grabX = 0f
    private var grabY = 0f
    private var cardX = 0f
    private var cardY = 0f
    private var lockStartTime = 0L

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val displayMetrics = resources.displayMetrics
        screenCenter = displayMetrics.widthPixels.toFloat() / 2
        main = activity as MainActivity

        return inflater.inflate(R.layout.fragment_shop, container, false)
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        lockButton = view.findViewById(R.id.shop_lock_button)
        lockProgress = view.findViewById(R.id.shop_lock_progress)
        progressBar = view.findViewById(R.id.shop_progress_bar)
        lockButton.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    lockProgress.scaleX = 0f
                    lockProgress.scaleY = 0f
                    lockProgress.isVisible = true

                    lockProgress.clearAnimation()
                    lockProgress.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .setDuration(ViewConfiguration.getLongPressTimeout().toLong())
                        .withEndAction {
                            lockButton.animate()
                                .scaleX(0f)
                                .scaleY(0f)
                                .setDuration(resources.getInteger(R.integer.animation_duration_fragment).toLong())
                                .withEndAction {
                                    main.swipeRefreshLayout.isEnabled = true
                                    lockProgress.isVisible = false
                                    lockButton.isVisible = false
                                    lockProgress.scaleX = 1f
                                    lockProgress.scaleY = 1f
                                    lockButton.scaleX = 1f
                                    lockButton.scaleY = 1f

                                    loadOrder()
                                }

                            lockProgress.clearAnimation()
                            lockProgress.animate()
                                .scaleX(0f)
                                .scaleY(0f)
                                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                        }

                    lockStartTime = Calendar.getInstance().timeInMillis

                    true
                }

                MotionEvent.ACTION_UP -> {
                    lockProgress.clearAnimation()
                    lockProgress.animate()
                        .scaleX(0f)
                        .scaleY(0f)
                        .setDuration(resources.getInteger(R.integer.animation_duration_fragment).toLong())
                        .withEndAction {
                            lockProgress.isVisible = false
                        }

                    if (Calendar.getInstance().timeInMillis > lockStartTime + ViewConfiguration.getLongPressTimeout().toLong()) {

                    }

                    false
                }

                else -> true
            }
        }
    }

    override fun onShow(refresh: Boolean): Task<Unit>? {
        topBubbleVisible = false
        bottomLayoutVisible = false

        if (this::card.isInitialized) {
            card.isVisible = false
        }

        openOrders = Shop.getOpenOrders(main.users, SHOP_ID)
        leftOrders = openOrders.size

        if (refresh) {
            loadOrder()
        } else {
            progressBar.isVisible = false
            lockButton.isVisible = openOrders.isNotEmpty()

            if (openOrders.isEmpty()) {
                showEmptyCard(R.string.info_no_open_orders)
            } else {
                removeEmptyCard()
                main.swipeRefreshLayout.isRefreshing = false
                main.swipeRefreshLayout.isEnabled = false
            }
        }

        return null
    }

    private fun loadOrder() {
        if (openOrders.isEmpty()) {
            if (leftOrders > 0) {
                showEmptyCard("$leftOrders order${if (leftOrders > 1) "s" else ""} left")
            } else {
                showEmptyCard(R.string.info_no_open_orders)
            }
            if (progressBar.isVisible) {
                progressBar.animate()
                    .translationY(-progressBar.height.toFloat())
                    .setDuration(resources.getInteger(R.integer.animation_duration_fragment).toLong())
                    .withEndAction {
                        progressBar.isVisible = false
                    }
            }
            return
        }

        removeEmptyCard()

        if (!progressBar.isVisible) {
            progressBar.translationY = -progressBar.height.toFloat()
            progressBar.progress = 0
            progressBar.isVisible = true
            progressBar.animate()
                .translationY(0f)
                .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
        }

        val keys = openOrders.keys
        currentOrder = hashMapOf()
        itemId = keys.iterator().next()
        val name = main.shop.items[itemId]?.name ?: getString(R.string.name_item_unknown)
        itemCount = 0

        for ((id, order) in openOrders) {
            for ((userId, item) in order) {
                if (id == itemId) {
                    currentOrder[userId] = item
                    itemCount += item[ITEM_COUNT].toInt()
                }
            }
        }

        createCard(name, itemCount)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun createCard(name: String, count: Int) {
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
        card.findViewById<TextView>(R.id.item_name).text = name

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
            OnTouchListener { view, event ->
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
        main.swipeRefreshLayout.isEnabled = false

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
        main.swipeRefreshLayout.isEnabled = true

        val diff = event.rawX - grabX

        if (cardMode == 1 && abs(diff) > screenCenter / 1.5f) {
            val progress = progressBar.progress + (1f / openOrders.size) * (100 - progressBar.progress)
            progressBar.setProgress(progress.roundToInt(), true)

            val fulfill = diff > 0
            var itemsLeft = itemCount.toLong()

            val sortedOrder = currentOrder.toSortedMap { a, b ->
                when (main.userId) {
                    // prioritize own order
                    a -> -1
                    b -> 1
                    // proper priorization here
                    else -> {
                        0
                    }
                }
            }

            for ((orderUserId, item) in sortedOrder) {
                if (itemsLeft <= 0) break

                val count = item[ITEM_COUNT]
                val change = min(count, itemsLeft)
                itemsLeft -= change

                if (fulfill) {
                    Shop.fulfillItem(main.users, GROUP_ID, orderUserId, SHOP_ID, main.userId, itemId, change)
                }

                openOrders[itemId]?.remove(orderUserId)

                if (openOrders[itemId]?.size == 0) {
                    openOrders.remove(itemId)
                    if (fulfill) leftOrders--
                }
            }

            val target = if (fulfill) {
                cardX + screenCenter * 3
            } else {
                cardX - screenCenter * 3
            }

            card.animate()
                .x(target)
                .y(event.rawY - card.height / 1.5f)
                .setDuration(resources.getInteger(R.integer.animation_duration_card_out).toLong())
                .withEndAction(this::loadOrder)
        } else {
            card.animate()
                .x(cardX)
                .y(cardY)
                .scaleX(1f)
                .scaleY(1f)
                .rotation(0f)
                .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()
        }

        cardMode = 0
    }
}