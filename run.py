import pandas as pd
import matplotlib.pyplot as plt
import pdb

df = pd.read_csv("DBA.csv")
#df = pd.read_csv("XQQ.TO.csv")

df["SMA50"] = df["Close"].rolling(50).mean()

for i in range(1, len(df)):
    df.loc[i, 'tr'] = max(
        df.loc[i, 'High'] - df.loc[i, 'Low'],
        abs(df.loc[i, 'High'] - df.loc[i-1, 'Close']),
        abs(df.loc[i, 'Low'] - df.loc[i-1, 'Close'])
    )
df['atr10'] = df['tr'].rolling(10).mean()
median_atr = df['atr10'].median()
print(median_atr)

print("Begin T1 - If we cross median ATR10, then do we make money when we go in the direction of the breakout?")
ups = 0
downs = 0
up_profit = up_loss = down_profit = down_loss = 0
up_total = down_total = 0
for i in range(11, len(df)-5):
    previous = df.loc[i-1]
    row = df.loc[i]
    target = df.loc[i+5]
    if previous.atr10 > median_atr:
        if previous.Close > previous.Open:
            ups+=1
            diff = target.Close - row.Open
            up_total += diff
            if diff > 0:
                up_profit+=1
            else:
                up_loss+=1
        else:
            downs+=1
            diff = row.Open - target.Close
            down_total += diff
            if diff > 0:
                down_profit+=1
            else:
                down_loss+=1

print(ups, downs, 'foo', up_profit, up_loss, down_profit, down_loss)
print(up_total, down_total)
print("median close", df['Close'].median())
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
