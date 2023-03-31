package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlin.concurrent.thread

class ItemPreferencesAktivity : AppCompatActivity() {
    private lateinit var layoutLeft: ConstraintLayout
    private lateinit var layoutRight: ConstraintLayout
    private lateinit var itemNameLeft: TextView
    private lateinit var itemNameRight: TextView
    private lateinit var itemImageLeft: ImageView
    private lateinit var itemImageRight: ImageView
    private var currentLeftId = ""
    private var currentRightId = ""
    private var selection = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_item_preferences)
    }

    @SuppressLint("DiscouragedApi")
    override fun onStart() {
        super.onStart()

        layoutLeft = findViewById(R.id.layout_left)
        layoutRight = findViewById(R.id.layout_right)

        itemNameLeft = findViewById(R.id.item_name_left)
        itemNameRight = findViewById(R.id.item_name_right)

        itemImageLeft = findViewById(R.id.item_image_left)
        itemImageRight = findViewById(R.id.item_image_right)

        layoutLeft.setOnClickListener { selection = 1 }
        layoutRight.setOnClickListener  { selection = -1 }

        Shop.getShop(SHOP_ID).continueWith {
            val shop = it.result ?: return@continueWith

            thread {
                var iters = 0

                val sorted = shop.items.keys.toList().subList(0, 10).toSortedSet { leftId: String, rightId: String ->
                    if (leftId == rightId) return@toSortedSet 0

                    if (leftId != currentLeftId) {
                        val imageIdLeft = resources.getIdentifier(leftId, "drawable", packageName)

                        animateSlide(
                            layoutLeft, -1,
                            itemNameLeft, shop.items[leftId]?.name ?: return@toSortedSet 0,
                            itemImageLeft, imageIdLeft
                        )
                        currentLeftId = leftId
                    }

                    if (rightId != currentRightId) {
                        val imageIdRight = resources.getIdentifier(rightId, "drawable", packageName)

                        animateSlide(
                            layoutRight, 1,
                            itemNameRight, shop.items[rightId]?.name ?: return@toSortedSet 0,
                            itemImageRight, imageIdRight
                        )
                        currentRightId = rightId
                    }

                    iters++

                    runBlocking {
                        getSelection()
                    }
                }

                Toast.makeText(this, iters.toString(), Toast.LENGTH_SHORT).show()

                sorted
            }
        }
    }

    /*
    def Nmaxelements(list1, N):
    final_list = []

    for i in range(0, N):
        max1 = 0

        for j in range(len(list1)):
            if list1[j] > max1:
                max1 = list1[j];

        list1.remove(max1);
        final_list.append(max1)

    private fun compare(a: String, b: String): Boolean {
        return
    }

    private fun <T> getNLargest(n: Int, collection: Iterable<T>) {
        val final = listOf<T>()
        val cache = mapOf<Pair<T, T>, Boolean>()

        for (i in 0..n) {
            var max1 = collection.first()

            for (item in collection) {
                if (compare(item, max1)) {
                    max1 = item
                }
            }
        }
    }
     */

    private fun <T : Comparable<T>> top(n: Int, collection: Iterable<T>): List<T> {
        return collection.fold(ArrayList<T>()) { topList, candidate ->
            if (topList.size < n || candidate < topList.last()) {
                // ideally insert at the right place
                topList.add(candidate)
                topList.sort()
                // trim to size
                if (topList.size > n)
                    topList.removeAt(n)
            }
            topList
        }
    }

    private suspend fun getSelection(checkPeriod: Long = 100L): Int {
        val temp = selection
        if (temp != 0) {
            selection = 0
            return temp
        }

        delay(checkPeriod)
        return getSelection(checkPeriod)
    }

    private fun animateSlide(layout: ConstraintLayout, selected: Int, nameView: TextView, name: String, imageView: ImageView, resourceId: Int) {
        val translation = layout.width * selected.toFloat()
        val duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

        layout.animate()
            .translationX(translation)
            .setDuration(duration)
            .withEndAction {
                layout.animate().translationX(0f)

                nameView.text = name
                imageView.setImageResource(
                    if (resourceId == 0) {
                        R.drawable.baeckerkroenung
                    } else {
                        resourceId
                    }
                )
            }
    }
}