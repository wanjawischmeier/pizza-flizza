package com.wanjawischmeier.pizza

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ImageView
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout

class OrderModel(
    val id: String,
    var name: String,
    var price: Float,
    var count: Long,
    var imageId: Int
)

class OrderGridViewAdapter(context: Context, private val itemArrayList: ArrayList<OrderModel>) :
    ArrayAdapter<OrderModel>(context, 0, itemArrayList) {

    private var views: HashMap<ConstraintLayout, String> = hashMapOf()

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val itemView = if (convertView == null) {
            LayoutInflater.from(context).inflate(R.layout.card_order, parent, false) as ConstraintLayout
        } else {
            convertView as ConstraintLayout
        }

        val model = getItem(position)!!
        val nameView = itemView.findViewById<TextView>(R.id.order_name)
        val countView = itemView.findViewById<TextView>(R.id.order_count)
        val priceView = itemView.findViewById<TextView>(R.id.order_price)
        val imageView = itemView.findViewById<ImageView>(R.id.order_image)

        nameView.text = model.name
        countView.text = model.count.toString()
        priceView.text = context.getString(R.string.price_format).format(model.price)
        imageView.setImageResource(model.imageId)

        views[itemView] = model.id
        return itemView
    }

    fun getItemById(id: String): OrderModel? {
        val filteredViews = itemArrayList.filter { item -> item.id == id }
        return if (filteredViews.isEmpty()) null else filteredViews[0]
    }

    fun getItemByView(view: ConstraintLayout): OrderModel? {
        val itemId = views[view]
        return if (itemId == null) null else getItemById(itemId)
    }

    fun contains(id: String): Boolean {
        return getItemById(id) != null
    }
}