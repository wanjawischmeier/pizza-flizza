package com.wanjawischmeier.pizza

import kotlin.math.floor
import kotlin.math.min

class ItemSorter(list: List<String>, n: Int) {
    private var minimum = 0
    private var maximum = 0
    private var pointer = 0
    private var listPointer = 0
    private var limit = n
    private var value = ""
    private var sorted = mutableListOf<String>()
    private var cache = mutableMapOf<Pair<String, String>, Boolean>()
    private var input: List<String> = list
    private var key: Pair<String, String>

    init {
        value = input[listPointer]
        maximum = min(input.size, limit)
        pointer = floor(maximum / 2f).toInt()
        key = value to input[pointer]
    }

    private fun loadNextKey(sortedKey: Int) {
        sorted[sortedKey] = value

        listPointer++
        value = input[listPointer]
        minimum = 0
        maximum = min(input.size, limit)
        pointer = floor(maximum / 2f).toInt()
        key = value to input[pointer]

        setComparisonResult(cache[key] ?: return)
    }

    fun getNextComparison(): Pair<String, String> {
        return key
    }

    /*
    if compare(value, list1[pointer], cache):
        max1 = pointer
    else:
        if min1 == pointer:
            min1 = max1
        else:
            min1 = pointer
        if min1 > limit:
            return pointer
    if min1 == max1:
        return min1

    pointer = min1 + floor((max1 - min1) / 2)
     */

    fun setComparisonResult(result: Boolean) {
        cache[key] = result

        if (result) {
            maximum = pointer
        } else {
            minimum = if (minimum == pointer) {
                maximum
            } else {
                pointer
            }

            if (minimum > limit) {
                loadNextKey(pointer)
                return
            }
        }

        if (minimum == maximum) {
            loadNextKey(minimum)
            return
        }

        pointer = minimum + floor((maximum - minimum) / 2f).toInt()
        key = value to input[pointer]
    }
}