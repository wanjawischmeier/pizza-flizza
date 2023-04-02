package com.wanjawischmeier.pizza

import android.app.Activity
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.widget.ArrayAdapter
import android.widget.ImageView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import uk.co.deanwild.materialshowcaseview.MaterialShowcaseSequence
import uk.co.deanwild.materialshowcaseview.MaterialShowcaseView


class OrderCard(
    val id: String,
    var name: String,
    var price: Float,
    var count: Long,
    var imageId: Int
)

class OrderGridViewAdapter(
    context: Context,
    private val itemArrayList: ArrayList<OrderCard>,
    private val showcaseSequence: MaterialShowcaseSequence
) : ArrayAdapter<OrderCard>(context, 0, itemArrayList) {

    private var views: HashMap<ConstraintLayout, String> = hashMapOf()

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val itemView = if (convertView == null) {
            LayoutInflater.from(context).inflate(R.layout.card_order, parent, false) as ConstraintLayout
        } else {
            convertView as ConstraintLayout
        }

        val card = getItem(position)!!
        val nameView = itemView.findViewById<TextView>(R.id.order_name)
        val countView = itemView.findViewById<TextView>(R.id.order_count)
        val priceView = itemView.findViewById<TextView>(R.id.order_price)
        val imageView = itemView.findViewById<ImageView>(R.id.order_image)
        val addView = itemView.findViewById<TextView>(R.id.order_add)
        /*
        if (position == 0) {
            showcaseSequence.addSequenceItem(
                MaterialShowcaseView.Builder(context as Activity)
                    .setTarget(itemView)
                    .setDismissText(R.string.tour_accept)
                    .setContentText(R.string.sample_tour_content)
                    .setDelay(context.resources.getInteger(R.integer.tour_delay))
                    .setShapePadding(100)
                    .setDismissOnTouch(true)
                    // .singleUse("TEST5")
                    .build()
            )
        }
         */

        nameView.text = card.name
        countView.text = card.count.toString()
        priceView.text = context.getString(R.string.price_format).format(card.price)
        imageView.setImageResource(card.imageId)

        views[itemView] = card.id
        return itemView
    }

    fun getItemById(id: String): OrderCard? {
        val filteredViews = itemArrayList.filter { item -> item.id == id }
        return if (filteredViews.isEmpty()) null else filteredViews[0]
    }

    fun getItemByView(view: ConstraintLayout): OrderCard? {
        val itemId = views[view]
        return if (itemId == null) null else getItemById(itemId)
    }

    fun contains(id: String): Boolean {
        return getItemById(id) != null
    }
}