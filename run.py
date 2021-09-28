import pandas as pd
import matplotlib.pyplot as plt
import pdb
import sys
import numpy as np
import datetime as dt
import pandas_datareader as pdr

# USAGE:
# python3 run.py DBA 2021-1-1
#
# This will pull data on DBA from Yahoo Finance, from 1-jan-2021 onward.

# df = pdr.get_data_yahoo(sys.argv[1], sys.argv[2])
df = pd.read_csv("DBA.csv", parse_dates=True, index_col='Date')
print(df, 'orig df')

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
        count += 1
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
print(count, total)

exit(0)
print("DONE T1")

df["hh100"] = df['High'].rolling(100).max()
df["ll100"] = df['Low'].rolling(100).min()

print("T2 - Breakout from highest high or lowest low of last 100 days")
upcount = downcount = 0
uptot = downtot = 0
for i in range(101, len(df) - 5):
    prev2 = df.loc[i-2]
    previous = df.loc[i-1]
    row = df.loc[i]
    target = df.loc[i+5]
    diff = target.Close - row.Open
    if previous.High > prev2.hh100:
        upcount+=1
        if diff > 0:
            uptot += diff
        else:
            uptot -= diff
    elif previous.Low < prev2.ll100:
        downcount += 1
        if diff < 0:
            downtot += -diff # negative of negative
        else:
            downtot -= diff

print(upcount, uptot, downcount, downtot)
print("median close", df['Close'].median())
#pdb.set_trace()

print("DONE T2")


# plt.scatter(df['tr'], df['atr10'])
# plt.xlabel('tr', fontsize=14)
# plt.ylabel('atr10', fontsize=14)
# plt.grid(True)
# plt.show()
