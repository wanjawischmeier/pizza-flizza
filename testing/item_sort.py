from random import sample
from math import floor
from matplotlib import pyplot as plt
from functools import cmp_to_key
from heapq import nsmallest
import numpy as np

def compare(a: int, b: int, cache: dict[tuple[int, int], bool] = {}, f = False) -> bool:
    global comparisons

    key = (a, b)
    if key in cache:
        # print("using cache")
        return cache[key]
    else:
        comparisons += 1
    if f:
        res = input(f"[{comparisons}]: ({a} > {b})\t>>> ") == "y"
    else:
        res = a > b
    cache[key] = res
    return res

def count_comparisons(func):
    def wrapper(*args):
        global comparisons
        comparisons = 0
        result = func(*args)
        # print(f"{comparisons} comparisons")
        return result, comparisons
    
    return wrapper

@count_comparisons
def NmaxElements0(list1: list[int], n: int) -> list[int]:
    copy = list1.copy()
    final_list = []

    for i in range(0, n):
        max1 = 0

        for item in copy:
            if compare(item, max1):
                max1 = item

        copy.remove(max1)
        final_list.append(max1)

    return final_list

@count_comparisons
def NmaxElements1(list1: list[int], n: int) -> list[int]:
    def cmp(a: int, b: int) -> bool:
        global comparisons
        comparisons += 1
        if a < b:
            return 1
        else:
            return -1
    
    return nsmallest(n, list1, cmp_to_key(cmp))

@count_comparisons
def approximateLargest(list1: list[int], n: int, f, max_iterations = 100) -> list[int]:
    final = [list1[0]]
    cache = {}

    for value in list1[1:]:
        index = f(value, final, cache, n, max_iterations)
        # index = approximateIndex2(value, final, n, max_iterations)
        final.insert(index, value)

    return final[0:n]

def approximateIndex(value: int, list1: list[int], cache: dict[tuple[int, int], bool], limit: int, iterations: int) -> int:
    """
    if len(list1) >= limit:
        if not compare(value, list1[limit -1], cache):
            print("skipped")
            return limit + 1
    """
    min1 = 0
    max1 = min(len(list1), limit)
    pointer = max1 - 1 # floor(max1 / 2)

    for i in range(iterations):
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

    return pointer

def approximateIndex2(value: int, list1: list[int], _, limit: int, iterations: int) -> int:
    start = 0

    if len(list1) - 1 >= limit:
        end = limit
    else:
        end = len(list1) - 1

    if not compare(value, list1[end]):
        return end + 1

    for i in range(iterations):
        if start == end:
            return start

        pointer = start + floor((end - start) / 2)
        if pointer >= limit:
            return end + 1

        if compare(value, list1[pointer]):
            end = pointer
        else:
            start = pointer
    
    return pointer


# top3 = NmaxElements0(numbers, 3)
# print(top3)
# print(approximateIndex(5, [3, 1], 10))
max_iterations = 10
noise_samples = 10
n = 10
k = 50
numbers = sample(range(k), k)
numbers = [8, 10, 12, 0, 2, 9, 11, 4, 5, 7, 3, 6, 13, 1]
# k = len(numbers)
print(numbers)

sorted0, c0o = NmaxElements0(numbers, n)
print(sorted0, c0o)

sorted1, c1o = approximateLargest(numbers, n, approximateIndex, max_iterations)
fo = c0o / c1o
error = 0
for i in range(n):
    error += abs(sorted0[i] - sorted1[i])

print(sorted1, c1o, error)

den = k
cos = np.zeros(den)
c0s = np.zeros(den)
c1s = np.zeros(den)
errors0 = np.zeros(den)
errors1 = np.zeros(den)

for i in range(noise_samples):
    numbers = sample(range(k), k)

    for r in range(1, k):
        part = numbers[:r]
        lim = min(n, r) -1
        sortedo, co = NmaxElements1(part, lim)
        sorted0, c0 = approximateLargest(part, lim, approximateIndex, max_iterations)
        sorted1, c1 = approximateLargest(part, lim, approximateIndex2, max_iterations)
        cos[r] = co
        c0s[r] += c0 / noise_samples
        c1s[r] += c1 / noise_samples

        error = 0
        for i in range(lim):
            error += abs(sortedo[i] - sorted0[i])
        errors0[r] += error / noise_samples

        error = 0
        for i in range(lim):
            error += abs(sortedo[i] - sorted1[i])
        errors1[r] += error / noise_samples
        
for i in range(3, 7):
    print(f"{i}:\ts={round(c0s[i] * 100) / 100} | e={round(errors0[i] * 100) / 100}")

plt.xlim([1, den - 1])
plt.plot(cos, label="cos")
plt.plot(c0s, label="c0s")
# plt.plot(c1s, label="c1s")
plt.plot(errors0, label="errors0")
# plt.plot(errors1, label="errors1")
plt.legend()
plt.show()
