import pandas as pd
import matplotlib.pyplot as plt
import pdb
import sys
import numpy as np
import datetime as dt
import pandas_datareader as pdr
import random

# USAGE:
# python3 run.py DBA 2021-1-1
#
# This will pull data on DBA from Yahoo Finance, from 1-jan-2021 onward.

#df = pdr.get_data_yahoo(sys.argv[1], sys.argv[2])
df = pd.read_csv(sys.argv[1], parse_dates=True, index_col='Date')

print("Basic dollar-cost-averaging")
leftover = tot_bought = tot_spent = 0
for _, row in df.iterrows():
    if 10 != random.randint(1, 10):
        continue
    close = row['Close']
    spendable = 50 + leftover
    bought = int(spendable / close)
    tot_bought += bought
    spent = bought * close
    tot_spent += spent
    leftover = spendable - spent

print(leftover, tot_bought, tot_spent, " average price bought=", tot_spent / tot_bought, " median price of security=", df['Close'].median())
print("DONE dollar-cost-averaging")

df["SMA50"] = df["Close"].rolling(50).mean()
df["sma14"] = df["Close"].rolling(14).mean()

high_low = df['High'] - df['Low']
high_close = np.abs(df['High'] - df['Close'].shift(1))
low_close = np.abs(df['Low'] - df['Close'].shift(1))
ranges = pd.concat([high_low, high_close, low_close], axis=1)
df['tr'] = np.max(ranges, axis=1)

df['atr10'] = df['tr'].rolling(10).mean()
median_atr = df['atr10'].median()
print(median_atr)

print("Begin T1 - If we cross median ATR10, then do we make money when we go in the direction of the breakout?")
# Pandas will apply this function on every row.  It's set up to be embarassingly parallel.
def t1(x):
    diff = x.targetclose - x.open
    res = [None, None]
    if x.prevatr10 > median_atr:
        if x.prevclose - x.prevopen:
            res = [1, diff]
        else:
            res = [-1, -diff]
    return pd.Series({"buy/sell": res[0], "p/l": res[1]})

# We set up a dataframe that has all the information for a calculation all in one row.
# This is what helps the function above run on each row independently, which allows for
# Pandas to run that code on this data in a SIMD fashion over multiple CPU cores at the
# same time.  Independent computation rocks!
df3 = pd.DataFrame({})
df3['prevatr10'] = df['atr10'].shift(1)
df3['prevopen'] = df['Open'].shift(1)
df3['prevclose'] = df['Close'].shift(1)
df3['open'] = df['Open']
df3['close'] = df['Close']
df3['targetclose'] = df['Close'].shift(-5)
t1 = df3.apply(t1, axis=1)
t1.to_csv("t1.csv")
print("DONE T1")

df["hh100"] = df['High'].rolling(100).max()
df["ll100"] = df['Low'].rolling(100).min()

plt.plot(df.index, df['Close'], linestyle='solid')
plt.plot(df.index, df['hh100'], color='blue')
plt.plot(df.index, df['ll100'], color='red')
plt.show()

print("T2 - Breakout from highest high or lowest low of last 100 days")
def t2(x):
    diff = x.tclose - x.open
    res = [0, 0]
    if x.prevh > x.prev2hh:
        res = [1, diff]
    elif x.prevl < x.prev2ll:
        res = [-1, -diff]
    return pd.Series({
        "b/s": res[0],
        "p/l": res[1],
        "total": res[0] * res[1]
    })

df4 = pd.DataFrame({})
df4['tclose'] = df['Close'].shift(-5)
df4['open'] = df['Open']
df4['prev2hh'] = df['hh100'].shift(2)
df4['prevh'] = df['High'].shift(1)
df4['prev2ll'] = df['ll100'].shift(2)
df4['prevl'] = df['Low'].shift(1)
t1 = df4.apply(t2, axis=1)
t1.to_csv("t2.csv")
print("median open", df4['open'].median())
#pdb.set_trace()

print("DONE T2")


# plt.scatter(df['tr'], df['atr10'])
# plt.xlabel('tr', fontsize=14)
# plt.ylabel('atr10', fontsize=14)
# plt.grid(True)
# plt.show()
