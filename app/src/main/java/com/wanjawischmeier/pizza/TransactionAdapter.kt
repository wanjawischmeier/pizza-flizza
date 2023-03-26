package com.wanjawischmeier.pizza

import android.content.Context
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isGone
import androidx.core.view.isVisible
import java.text.SimpleDateFormat


enum class TransactionType {
    OPEN, FULFILLED_BY_USER, TO_BE_PAID
}

class TransactionCard(
    val ids: Pair<String, String>,
    var transactionType: TransactionType,
    var name: String,
    var order: Order
)

class TransactionListViewAdapter(context: Context, private val main: MainActivity, private val itemArrayList: ArrayList<TransactionCard>) :
    ArrayAdapter<TransactionCard>(context, 0, itemArrayList) {

    private var views: HashMap<ConstraintLayout, Pair<String, String>> = hashMapOf()

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val itemView = if (convertView == null) {
            LayoutInflater.from(context).inflate(R.layout.card_transactions, parent, false) as ConstraintLayout
        } else {
            // undo transforms applied by animation
            convertView.alpha = 1f
            convertView.translationY = 0f
            convertView as ConstraintLayout
        }

        val card = getItem(position)!!

        var date = 0L
        var total = 0f
        var content = ""

        for ((itemId, itemInfo) in card.order.toSortedMap()) {
            val item = main.shop.items[itemId]
            val name = item?.name ?: context.getString(R.string.name_item_unknown)
            val count = itemInfo[ITEM_COUNT]

            // get latest change
            if (itemInfo[ITEM_TIME] > date) {
                date = itemInfo[ITEM_TIME]
            }

            total += (item?.price ?: 0f) * itemInfo[ITEM_COUNT]
            content += "- ${count}x ${name}\n"
        }

        val nameView = itemView.findViewById<TextView>(R.id.transaction_name)
        val dateView = itemView.findViewById<TextView>(R.id.transaction_date)
        val priceView = itemView.findViewById<TextView>(R.id.transaction_price_text)
        val contentView = itemView.findViewById<TextView>(R.id.transaction_content)
        val button = itemView.findViewById<Button>(R.id.transaction_button)
        val statusOutline = itemView.findViewById<View>(R.id.transaction_status_ring)

        val dateFormatter = SimpleDateFormat("dd.MM.yy HH:mm", SimpleDateFormat.getAvailableLocales()[0])

        var name = card.name
        var textId = R.string.transaction_paid
        var backgroundColorId = R.color.cream
        var textColorId = R.color.white

        val outlineId = when (card.transactionType) {
            TransactionType.OPEN -> {
                name = context.resources.getString(R.string.your_order)
                textId = R.string.transaction_clear
                backgroundColorId = R.color.gray_light
                textColorId = R.color.white

                R.drawable.order_open_outline
            }
            TransactionType.TO_BE_PAID -> {
                R.drawable.order_to_pay_outline
            }
            TransactionType.FULFILLED_BY_USER -> 0
        }

        if (card.transactionType == TransactionType.TO_BE_PAID) {
            button.isGone = true
        } else {
            button.text = context.getString(textId)
            button.backgroundTintList = ColorStateList.valueOf(context.resources.getColor(backgroundColorId, context.theme))
            button.setTextColor(context.resources.getColor(textColorId, context.theme))
        }

        if (outlineId != 0) {
            statusOutline.setBackgroundResource(outlineId)
            statusOutline.isVisible = true
        } else {
            statusOutline.isVisible = false
        }

        nameView.text = name
        dateView.text = dateFormatter.format(date)
        priceView.text = context.getString(R.string.price_format).format(total)
        contentView.text = content.trim()

        views[itemView] = card.ids
        return itemView
    }

    fun getItemByIds(ids: Pair<String, String>): TransactionCard? {
        val filteredItems = itemArrayList.filter { item -> item.ids == ids }
        return if (filteredItems.isEmpty()) null else filteredItems[0]
    }

    fun getViewByIds(ids: Pair<String, String>): ConstraintLayout? {
        val filteredViews = views.filter { item -> item.value == ids }
        return if (filteredViews.isEmpty()) null
        else filteredViews.keys.iterator().next()
    }

    fun getIdsByView(view: ConstraintLayout): Pair<String, String>? {
        return views[view]
    }

    fun contains(ids: Pair<String, String>): Boolean {
        return getItemByIds(ids) != null
    }

    fun remove(ids: Pair<String, String>) {
        val position = getPosition(getItemByIds(ids) ?: return)
        var item = itemArrayList[position]
        var view = getViewByIds(item.ids) ?: return
        val translation = -view.height.toFloat() - context.resources.getDimension(R.dimen.card_distance)

        view.animate()
            .alpha(0f)
            .translationY(translation)
            .setDuration(context.resources.getInteger(R.integer.animation_duration_card_out).toLong())
            .withEndAction {
                notifyDataSetChanged()
            }

        views.remove(view)
        itemArrayList.remove(item)

        for (i in position until itemArrayList.size) {
            item = itemArrayList[i]
            view = getViewByIds(item.ids) ?: continue
            view.animate()
                .translationY(translation)
                .duration = context.resources.getInteger(R.integer.animation_duration_card_out).toLong()
        }
    }
}