//#property copyright "Copyright 2021-2023, FX SCALPER X"

#property copyright "© 2021-2023 FX Scalper X | All Rights Reserved."
#property description "www.fxscalperx.com"

#include <CheckLicense.mqh>
#include <Controls\BmpButton.mqh>

#define ID "fx-scalper:-"
#define ID1 "fx-scalper:P-"
#define IDX "fx-scalper:B-"
#define BgColor C'41,41,50'
#define PanelBoarderColor clrBlack

#resource "\\Images\\Fx Scalper Logo.bmp"

string FxScalperLogo = "::Images\\Fx Scalper Logo.bmp";

CBmpButton TheLogo;

enum autolot
{
   Aggressive = 0,
   Standard = 1,
   Moderate = 2,
   Passive = 3,
   Conservative = 4,
   Serenity = 5
};

//--- Input Variables ---//
extern bool  Use_AutoLot  = true;
input  autolot Risk_Mode  = 0;
extern bool Use_Spread  = False;                // Use spread
extern double TradeSize = 0.01;                 // Trade LotSize
extern bool  Use_LotMultiplier = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
extern int TradeStopEquity = 0;                 // Stop Trading When Equity Falls Below This Value
input int Trade_Slippage = 5;                   // Tolerable Slippage for the Trade
input int ProfitGoal = 54;                      // Profit Goal
input int ProfitIncrement = 9;                  // Profit Increment
input int ATR_Period = 20;                      // ATR Period
input double ATRMultiplier = 3.0;               // ATR Multiplier
input bool LastCycle = false;                   // Set to true to Stop Trading After The Last Trade Closes
input int MagicNumber = 77777777;               // Magic Number
input bool MobileAlert = false;                 // Set to true for Mobile Alerts (Need to Have Metatrader Mobile)
input int DailyAlertHour = 4;                   // Hour in Server Time for Daily Alert (It will just say if it's still active)
input int Alert_A = 25;                         // Send a Mobile Alert When Equity Went Below % of Balance [0-100]
input int Alert_B = 35;                         // Send a Mobile Alert When Equity Went Below % of Balance [0-100]
input int Alert_C = 45;                         // Send a Mobile Alert When Equity Went Below % of Balance [0-100]
string comment_order      = " FX SCALPER X";

extern bool    UseTrailing       = true;
extern int     BuyTrailingStart  = 10;
extern int     BuyTrailBy        = 10;
extern int     BuyTrailingStep   = 10;
extern int     SellTrailingStart = 10;
extern int     SellTrailBy       = 10;
extern int     SellTrailingStep  = 10;

//ORI
int EquityGoal = 1000000;                   // Equity Goal (Recommended 100% of Capital)
bool TradeStopUpdate = false;               // Set to true to Update Trade Stop On Reaching New Goal
//--- Global Variables ---//
ENUM_TIMEFRAMES ZoneA_TF, ZoneB_TF, ZoneC_TF, ZoneD_TF, ZoneE_TF, CurrentZone_TF;
ENUM_TIMEFRAMES Zone_TF[8] = {PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
string currentZone = "Zone A";
bool updateChart = false, ZonesTFsSet = false, CycleStart = false, alertSent = false;
bool Alert_A_Sent = false, Alert_B_Sent = false, Alert_C_Sent = false;
int ZoneA_TradeCount = 8, ZoneB_TradeCount = 7, ZoneC_TradeCount = 6, ZoneD_TradeCount = 5, ZoneE_TradeCount = 4;
double ZoneA_Lots = 1, ZoneB_Lots = 2, ZoneC_Lots = 3, ZoneD_Lots = 4, ZoneE_Lots = 5;
double MaxSpread = 50;
double myPoint;

int RecordedObjects;

input string dt;//.
input int TheFontSize = 8; //Font size

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   bool tester_mode=(bool)MQLInfoInteger(MQL_TESTER);
   bool visual_tester_mode=(bool)MQLInfoInteger(MQL_VISUAL_MODE);

if(!tester_mode || visual_tester_mode)
   if(!CheckLicense())
      return INIT_FAILED;

//---
   ChartSetInteger(ChartID(),CHART_FOREGROUND,0);

   ChartSetInteger(ChartID(),CHART_COLOR_BACKGROUND,C'41,41,50');
   ChartSetInteger(ChartID(),CHART_SHOW_GRID,true);
   ChartSetInteger(ChartID(),CHART_COLOR_GRID,C'64,64,80');
   ChartSetInteger(ChartID(),CHART_COLOR_FOREGROUND,clrWhite);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_UP,C'223,223,223');
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_DOWN,C'223,223,223');
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BULL,clrBlack);
   ChartSetInteger(ChartID(),CHART_COLOR_CANDLE_BEAR,clrBlack);
   ChartSetInteger(ChartID(),CHART_COLOR_STOP_LEVEL,clrRed);
   ChartSetInteger(ChartID(),CHART_COLOR_ASK,clrRed);
   ChartSetInteger(ChartID(),CHART_SHOW_ASK_LINE,false);
   ChartSetInteger(ChartID(),CHART_COLOR_VOLUME,clrWhite);
   ChartSetInteger(ChartID(),CHART_COLOR_CHART_LINE,clrDeepSkyBlue);

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0,true);
//---

   ObjectDelete(0,"ac1");
   ObjectDelete(0,"ac2");
   ObjectDelete(0,"ac3");
   ObjectDelete(0,"ac4");
   ObjectDelete(0,"a1");
   ObjectDelete(0,"a2");
   ObjectDelete(0,"c1");
   ObjectDelete(0,"c2");
   ObjectDelete(0,"c3");
   ObjectDelete(0,"c4");

   MathSrand(GetTickCount());
   if(Use_AutoLot)
      auto_lot();

   if(Digits % 2 == 1)
     {
      myPoint = 10 * Point;
     }
   else
      if(Digits == 2)
        {
         myPoint = 100 * Point;
        }
      else
        {
         myPoint = Point;
        }

   if(!Use_LotMultiplier)
     {
      ZoneA_Lots = 1;
      ZoneB_Lots = 1;
      ZoneC_Lots = 1;
      ZoneD_Lots = 1;
      ZoneE_Lots = 1;
     }

   EventSetTimer(1);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Del(ID);
   Del(ID1);
   Del(IDX);
   TheLogo.Destroy();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double getSpread;
   if(Use_Spread)
      getSpread = MarketInfo(Symbol(), MODE_SPREAD);
   else
      getSpread = 0;

   double equity = AccountEquity();
   string name = AccountServer();
   int acctNum = AccountNumber();
   double balance = AccountBalance();
   bool newBar = IsNewBar(false);


   if(Use_AutoLot)
      auto_lot();
   if(Hour() == DailyAlertHour && Minute() < 5 && MobileAlert && newBar)
     {
      SendNotification(WindowExpertName() + " on " + name + ", " + IntegerToString(acctNum) + " is running smoothly.");
     }

   if(equity < TradeStopEquity)
     {
      closeAllOrders();
     }

   if(balance * (110 - Alert_A) / 100 <= equity)
     {
      Alert_A_Sent = false;
     }
   else
      if(balance * (110 - Alert_B) / 100 <= equity)
        {
         Alert_B_Sent = false;
        }
      else
         if(balance * (110 - Alert_C) / 100 <= equity)
           {
            Alert_C_Sent = false;
           }

   if(balance * (100 - Alert_A) / 100 >= equity && !Alert_A_Sent && MobileAlert)
     {
      Alert_A_Sent = true;
      SendNotification("Your drawdown is now at " + IntegerToString(Alert_A) + "% on " + name + ", " + IntegerToString(acctNum) + ".");
     }

   if(balance * (100 - Alert_B) / 100 >= equity && !Alert_B_Sent && MobileAlert)
     {
      Alert_B_Sent = true;
      SendNotification("Your drawdown is now at " + IntegerToString(Alert_B) + "% on " + name + ", " + IntegerToString(acctNum) + ".");
     }

   if(balance * (100 - Alert_C) / 100 >= equity && !Alert_C_Sent && MobileAlert)
     {
      Alert_C_Sent = true;
      SendNotification("Your drawdown is now at " + IntegerToString(Alert_C) + "% on " + name + ", " + IntegerToString(acctNum) + ".");
     }

   /*
   if(equity >= EquityGoal && !alertSent){
      closeAllOrders();
      EquityGoal *= 2;
      TradeSize *= 2;
      if(TradeStopUpdate){
         TradeStopEquity = EquityGoal / 4;
      }
      alertSent = true;
      if(MobileAlert){
         SendNotification("Congratulations, your current account balance is now $" + DoubleToStr(balance, 2) + " on " + name + ", " + IntegerToString(acctNum) +
            ". Your new profit target is $" + DoubleToStr(EquityGoal, 2) + "." + "\n\n" + "New trade size: " + DoubleToStr(TradeSize, 2) + "\n" + "Trade stop: $" + DoubleToStr(TradeStopEquity, 2) +
            "\n" + "Profit goal: " + DoubleToStr(ProfitGoal * TradeSize, 2) + "\n" + "Profit increment: " + DoubleToStr(ProfitIncrement * TradeSize, 2));
      }
   }
   */
   if((!UseTrailing || TradeCount() > 1) && CheckOpenProfit() >= (ProfitIncrement * TradeCount() + ProfitGoal) * TradeSize)
      closeAllOrders();

   if(TradeCount() == 0)
     {
      CycleStart = false;
      ZonesTFsSet = false;
     }

   if(UseTrailing && TradeCount() == 1)
      SetTrailingStops();

//if(equity >= TradeStopEquity && equity <= EquityGoal && TradeCount() == 0 && MaxSpread > getSpread && !LastCycle){
   if(equity >= TradeStopEquity && TradeCount() == 0 && MaxSpread > getSpread && !LastCycle)
     {
      int num = MathRand() % 2;
      if(num == 0)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneA_Lots, comment_order);
         currentZone = "Zone A";
         CycleStart = true;
        }
      if(num == 1)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneA_Lots, comment_order);
         currentZone = "Zone A";
         CycleStart = true;
        }
     }

   if((!ZonesTFsSet && CycleStart) || (!ZonesTFsSet && TradeCount()>0))
     {
      for(int i = 0; i < ArraySize(Zone_TF) - 5; i++)
        {
         if(getATR(Zone_TF[i]) * MathPow(10, Digits) > getSpread * 3 &&
            getATR(Zone_TF[i]) * MathPow(10, Digits) * TradeSize > ProfitGoal * TradeSize)
           {
            ZoneA_TF = Zone_TF[i];
            ZoneB_TF = Zone_TF[i + 1];
            ZoneC_TF = Zone_TF[i + 2];
            ZoneD_TF = Zone_TF[i + 3];
            ZoneE_TF = Zone_TF[i + 4];
            CurrentZone_TF = ZoneA_TF;
            break;
           }
         else
           {
            ZoneA_TF = Zone_TF[3];
            ZoneB_TF = Zone_TF[4];
            ZoneC_TF = Zone_TF[5];
            ZoneD_TF = Zone_TF[6];
            ZoneE_TF = Zone_TF[7];
            CurrentZone_TF = ZoneA_TF;
           }
        }
      ZonesTFsSet = true;
      updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
     }

   if(TradeCount() >= 1 && TradeCount() < ZoneA_TradeCount + 1)
     {
      if(Ask <= (LastTradePrice(1) - (getATR(ZoneA_TF) * ATRMultiplier)) && OrderType() == OP_BUY)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneA_Lots, comment_order);
         currentZone = "Zone A";
        }
      if(Bid >= (LastTradePrice(-1) + (getATR(ZoneA_TF) * ATRMultiplier)) && OrderType() == OP_SELL)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneA_Lots, comment_order);
         currentZone = "Zone A";
        }
     }

   if(TradeCount() >= ZoneA_TradeCount + 1 && TradeCount() < ZoneA_TradeCount + ZoneB_TradeCount + 1)
     {
      if(Ask <= (LastTradePrice(1) - (getATR(ZoneB_TF) * ATRMultiplier)) && OrderType() == OP_BUY)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneB_Lots, comment_order);
         CurrentZone_TF = ZoneB_TF;
         currentZone = "Zone B";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }

      if(Bid >= (LastTradePrice(-1) + (getATR(ZoneB_TF) * ATRMultiplier)) && OrderType() == OP_SELL)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneB_Lots, comment_order);
         CurrentZone_TF = ZoneB_TF;
         currentZone = "Zone B";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
     }

   if(TradeCount() >= ZoneA_TradeCount + ZoneB_TradeCount + 1 && TradeCount() < ZoneA_TradeCount + ZoneB_TradeCount + ZoneC_TradeCount + 1)
     {
      if(Ask <= (LastTradePrice(1) - (getATR(ZoneC_TF) * ATRMultiplier)) && OrderType() == OP_BUY)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneC_Lots, comment_order);
         CurrentZone_TF = ZoneC_TF;
         currentZone = "Zone C";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
      if(Bid >= (LastTradePrice(-1) + (getATR(ZoneC_TF) * ATRMultiplier)) && OrderType() == OP_SELL)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneC_Lots, comment_order);
         CurrentZone_TF = ZoneC_TF;
         currentZone = "Zone C";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
     }

   if(TradeCount() >= ZoneA_TradeCount + ZoneB_TradeCount + ZoneC_TradeCount + 1 && TradeCount() < ZoneA_TradeCount + ZoneB_TradeCount + ZoneC_TradeCount + ZoneD_TradeCount + 1)
     {
      if(Ask <= (LastTradePrice(1) - (getATR(ZoneD_TF) * ATRMultiplier)) && OrderType() == OP_BUY)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneD_Lots, comment_order);
         CurrentZone_TF = ZoneD_TF;
         currentZone = "Zone D";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
      if(Bid >= (LastTradePrice(-1) + (getATR(ZoneD_TF) * ATRMultiplier)) && OrderType() == OP_SELL)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneD_Lots, comment_order);
         CurrentZone_TF = ZoneD_TF;
         currentZone = "Zone D";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);

        }
     }

   if(TradeCount() >= ZoneA_TradeCount + ZoneB_TradeCount + ZoneC_TradeCount + ZoneD_TradeCount + 1 && TradeCount() < ZoneA_TradeCount + ZoneB_TradeCount + ZoneC_TradeCount + ZoneD_TradeCount + ZoneE_TradeCount + 1)
     {
      if(Ask <= (LastTradePrice(1) - (getATR(ZoneE_TF) * ATRMultiplier)) && OrderType() == OP_BUY)
        {
         newOrderSend(OP_BUY, TradeSize * ZoneD_Lots, comment_order);
         CurrentZone_TF = ZoneE_TF;
         currentZone = "Zone E";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
      if(Bid >= (LastTradePrice(-1) + (getATR(ZoneE_TF) * ATRMultiplier)) && OrderType() == OP_SELL)
        {
         newOrderSend(OP_SELL, TradeSize * ZoneD_Lots, comment_order);
         CurrentZone_TF = ZoneE_TF;
         currentZone = "Zone E";
         updateChart = ChartSetSymbolPeriod(0, NULL, CurrentZone_TF);
        }
     }

//Comment("Current Zone: ", currentZone, ", Current Timeframe: ", CurrentZone_TF, ", Start Timeframe: ", ZoneA_TF, "\n",
//        "Net Price: ", DoubleToStr(NetAveragePrice(), Digits), ", Total Lots: ", DoubleToStr(TotalSize(), 2), ", Net Profit: ", DoubleToStr(CheckOpenProfit(), 2), ", Trade Count: ", TradeCount(), "\n",
//        "Trade Stop: ", DoubleToStr(TradeStopEquity, 2), ", Profit Goal: ", DoubleToStr(ProfitGoal * TradeSize, 2), ", Profit Increment: ", DoubleToStr(ProfitIncrement * TradeSize, 2));


   TheDashboard();

   BalanceCurve();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   TheDashboard();

   BalanceCurve();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TheDashboard()
  {
   int PanelX = 5;
   int PanelY = 20;

   if(RecordedObjects!=ObjectsTotal())
     {
      RecordedObjects=ObjectsTotal();

      Del(ID1);
     }
   int RowHeight = 23;

   string CurrentZoneText = "Current Zone : "+currentZone;
   string CurrentTimeframeText = "Current Timeframe : "+(string)CurrentZone_TF;
   string StartTimeframeText = "Start Timeframe : "+(string)ZoneA_TF;
   string NetPriceText = "Net Price : "+DoubleToStr(NetAveragePrice(), Digits);
   string TotalLotsText = "Total Lots : "+DoubleToStr(TotalSize(), 2);
   string NetProfitText = "Net Profit : "+DoubleToStr(CheckOpenProfit(), 2);
   string TradeCountText = "Trade Count : "+(string)TradeCount();
   string TradeStopText = "Trade Stop : "+DoubleToStr(TradeStopEquity, 2);
   string ProfitGoalText = "Profit Goal : "+DoubleToStr(ProfitGoal * TradeSize, 2);
   string ProfitIncrementText = "Profit Increment : "+DoubleToStr(ProfitIncrement * TradeSize, 2);
   string SpreadText = "Spread : "+(string)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   string StatusText = "Status : "+TradingStatus();

   CreateButton(0,ID1+"Panel",0,PanelX,PanelY,210,297+6,NULL,BgColor,PanelBoarderColor,"FX Scalper Dashboard");
   CreateButton(0,ID1+"Panel_X",0,PanelX+5,PanelY+15,200,270+6,NULL,BgColor,clrWhite,"FX Scalper Dashboard");

   CreateButton(0,ID1+"currentZone",0,PanelX+10,PanelY+35+3,190,20+3,CurrentZoneText,PanelBoarderColor,BgColor,"Current Zone","Calibri",9,clrWhite);
   CreateButton(0,ID1+"CurrentTimeframe",0,PanelX+10,PanelY+55+3,190,20+3,CurrentTimeframeText,PanelBoarderColor,BgColor,"Current Timeframe","Calibri",9,clrWhite);
   CreateButton(0,ID1+"StartTimeframe",0,PanelX+10,PanelY+75+3,190,20+3,StartTimeframeText,PanelBoarderColor,BgColor,"Start Timeframe","Calibri",9,clrWhite);
   CreateButton(0,ID1+"NetPrice",0,PanelX+10,PanelY+95+3,190,20+3,NetPriceText,PanelBoarderColor,BgColor,"Net Price","Calibri",9,clrWhite);
   CreateButton(0,ID1+"TotalLots",0,PanelX+10,PanelY+115+3,190,20+3,TotalLotsText,PanelBoarderColor,BgColor,"Total Lots","Calibri",9,clrWhite);
   CreateButton(0,ID1+"NetProfit",0,PanelX+10,PanelY+135+3,190,20+3,NetProfitText,PanelBoarderColor,BgColor,"Net Profit","Calibri",9,clrWhite);
   CreateButton(0,ID1+"TradeCount",0,PanelX+10,PanelY+155+3,190,20+3,TradeCountText,PanelBoarderColor,BgColor,"Trade Count","Calibri",9,clrWhite);
   CreateButton(0,ID1+"TradeStop",0,PanelX+10,PanelY+175+3,190,20+3,TradeStopText,PanelBoarderColor,BgColor,"Trade Stop","Calibri",9,clrWhite);
   CreateButton(0,ID1+"ProfitGoal",0,PanelX+10,PanelY+195+3,190,20+3,ProfitGoalText,PanelBoarderColor,BgColor,"Profit Goal","Calibri",9,clrWhite);
   CreateButton(0,ID1+"ProfitIncrement",0,PanelX+10,PanelY+215+3,190,20+3,ProfitIncrementText,PanelBoarderColor,BgColor,"Profit Increment","Calibri",9,clrWhite);
   CreateButton(0,ID1+"Spread",0,PanelX+10,PanelY+235+3,190,20+3,SpreadText,PanelBoarderColor,BgColor,"Spread","Calibri",9,clrWhite);
   CreateButton(0,ID1+"Status",0,PanelX+10,PanelY+255+3,190,20+3,StatusText,PanelBoarderColor,BgColor,"Status","Calibri",9,clrWhite);

   CreateButton(0,ID1+"TheLogo_Back",0,PanelX+21,PanelY+5+3,167,23,NULL,clrBlack,clrWhite,"Fx Scalper");
   TheLogo.Create(0,ID1+"TheLogo",0,PanelX+27,PanelY+7,10,10);
   TheLogo.BmpNames(FxScalperLogo,FxScalperLogo);
   ObjectSetString(0,ID1+"TheLogo",OBJPROP_TOOLTIP,"Fx Scalper");
   ObjectSetInteger(0,ID1+"TheLogo",OBJPROP_XDISTANCE,PanelX+27);
   ObjectSetInteger(0,ID1+"TheLogo",OBJPROP_YDISTANCE,PanelY+10);

   CreateButton(0,ID1+"Version",0,PanelX+5,PanelY+275+3,200,20+3,"Version 2.0",BgColor,BgColor,"Version","Calibri",9,clrWhite);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TradingStatus()
  {
   for(int x=0; x<OrdersTotal(); x++)
     {
      if(OrderSelect(x,SELECT_BY_POS) && OrderSymbol()==_Symbol && OrderMagicNumber()==MagicNumber)
        {
         return "Trading";
        }
     }

   return "Waiting for Entry";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BalanceCurve()
  {
   int ChartWidth = (int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
   int ChartHeight = (int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);

   int PanelWidth = 210;
   int PanelHeight = 200;

   int PanelX = ChartWidth-PanelWidth;
   int PanelY = ChartHeight-PanelHeight;

   double TheProfit = AccountInfoDouble(ACCOUNT_BALANCE)-AccountDeposits();

   string Balance = SeparateDouble(AccountInfoDouble(ACCOUNT_BALANCE));
   string Equity = SeparateDouble(AccountInfoDouble(ACCOUNT_EQUITY));
   string Profit =  SeparateDouble(AccountInfoDouble(ACCOUNT_BALANCE)-AccountDeposits());
   string Deposit = SeparateDouble(AccountDeposits());
   string Withdrawal = SeparateDouble(AccountWithdrawals());

   double TheMonthlyProfit = TotalProfit("ALL",iTime(_Symbol,PERIOD_MN1,0),TimeCurrent());
   double TheDayProfit = TotalProfit("ALL",iTime(_Symbol,PERIOD_D1,0),TimeCurrent());

   string MonthlyProfit = DoubleToStr((AccountInfoDouble(ACCOUNT_BALANCE)<=0 || TheMonthlyProfit==0)?0:(TheMonthlyProfit/(AccountInfoDouble(ACCOUNT_BALANCE)-TheMonthlyProfit))*100,2)+"%";
   string DailyProfit = DoubleToStr((AccountInfoDouble(ACCOUNT_BALANCE)<=0 || TheDayProfit==0)?0:(TheDayProfit/(AccountInfoDouble(ACCOUNT_BALANCE)-TheDayProfit))*100,2)+"%";

   string Gain = DoubleToStr((AccountInfoDouble(ACCOUNT_BALANCE)-TheProfit)!=0?(TheProfit/(AccountInfoDouble(ACCOUNT_BALANCE)-TheProfit))*100:0,2)+"%";

   string GainText = "Gain : "+Gain;
   string DailyProfitText = "Day Profit : "+DailyProfit;
   string MonthlyProfitText = "Month Profit : "+MonthlyProfit;
   string BalanceText = "Balance : $"+Balance;
   string EquityText = "Equity : $"+Equity;
   string ProfitText = "Profit : $"+Profit;
   string DepositsText = "Deposits : $"+Deposit;
   string WithdrawalsText = "Withdrawals : $"+Withdrawal;

   CreateButton(0,IDX+"Info Panel",0,PanelX-15,PanelY+30,PanelWidth+10,PanelHeight-32,NULL,BgColor,PanelBoarderColor,"FX Scalper Dashboard");
   CreateButton(0,IDX+"Gain",0,PanelX-10,PanelY+35,PanelWidth,20+3,GainText,clrBlack,BgColor,"Gain","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Daily Profit",0,PanelX-10,PanelY+55,PanelWidth,20+3,DailyProfitText,clrBlack,BgColor,"Daily Profit","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Monthly Profit",0,PanelX-10,PanelY+75,PanelWidth,20+3,MonthlyProfitText,clrBlack,BgColor,"Monthly Profit","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Balance",0,PanelX-10,PanelY+95,PanelWidth,20+3,BalanceText,clrBlack,BgColor,"Balance","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Equity",0,PanelX-10,PanelY+115,PanelWidth,20+3,EquityText,clrBlack,BgColor,"Equity","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Profit",0,PanelX-10,PanelY+135,PanelWidth,20+3,ProfitText,clrBlack,BgColor,"Profit","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Deposits",0,PanelX-10,PanelY+155,PanelWidth,20+3,DepositsText,clrBlack,BgColor,"Deposits","Calibri",9,clrWhite);
   CreateButton(0,IDX+"Withdrawals",0,PanelX-10,PanelY+175,PanelWidth,20+3,WithdrawalsText,clrBlack,BgColor,"Withdrawals","Calibri",9,clrWhite);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string SeparateDouble(double TheDoubleX)
  {
   string Numbers[];

   double TheDouble = MathAbs(TheDoubleX);

   int SepNumber = StringSplit(DoubleToStr(TheDouble,2),StringGetChar(".",0),Numbers);

   if(SepNumber!=2)
     {
      return (string)TheDouble;
     }

   int DigitsCount = StringLen(Numbers[0]);

   if(DigitsCount>3)
     {
      string NewString;

      for(int x=DigitsCount-1; x>=0; x--)
        {
         NewString+=CharToStr((char)StringGetChar(Numbers[0],MathAbs(DigitsCount-1-x)));
         if(x%3==0 && x!=0)
           {
            NewString+=",";
           }
        }

      if(TheDoubleX>=0)
         return NewString+"."+Numbers[1];
      else
         return "-"+NewString+"."+Numbers[1];
     }

   return DoubleToStr(TheDoubleX>=0?TheDouble:-TheDouble,2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalProfit(string ThisSymbol, datetime StartTime,datetime StopTime,int PL=0)
  {
   double TheProfit = 0;
   double ReturnProfit = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderCloseTime()>=StartTime && OrderCloseTime()<=StopTime)
        {
         if(OrderSymbol()==ThisSymbol || ThisSymbol=="ALL")
           {
            TheProfit=OrderProfit()+OrderCommission()+OrderSwap();

            if(PL==-1 && TheProfit<0)
              {
               ReturnProfit+=OrderProfit()+OrderCommission()+OrderSwap();
              }

            if(PL==0)
              {
               ReturnProfit+=OrderProfit()+OrderCommission()+OrderSwap();
              }

            if(PL==1 && TheProfit>0)
              {
               ReturnProfit+=OrderProfit()+OrderCommission()+OrderSwap();
              }
           }
        }
     }

   return ReturnProfit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AccountDeposits()
  {
   double total=0;

   for(int i=0; i<OrdersHistoryTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         if(OrderType()>5)
           {
            total+=OrderProfit();
           }
        }
     }

   return(total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AccountWithdrawals()
  {
   double total=0;

   for(int i=0; i<OrdersHistoryTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         if(OrderType()>5 && OrderProfit()<0)
           {
            total+=MathAbs(OrderProfit());
           }
        }
     }

   return(total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateButton(const long              chart_ID=0,
                  const string            name="Button",
                  const int               sub_window=0,
                  const int               x=0,
                  const int               y=0,
                  const int               button_width=50,
                  const int               button_height=18,
                  const string            text="",
                  const color             background_color=clrWhite,
                  const color             Theborder_color=clrBlack,
                  const string            Tip = "",
                  const string            MyFont = "Arial",
                  const int               MyFontSize = 10,
                  const color             TheTextColor = clrBlack,
                  const bool              Back = false)
  {
//---

   if(ObjectFind(0,name)==-1)
     {
      ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0);
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,button_width);
      ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,button_height);
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,TheFontSize);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,TheTextColor);
      ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,background_color);
      ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,Theborder_color);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,Back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(chart_ID,name,OBJPROP_STATE,false);
      ObjectSetString(chart_ID,name,OBJPROP_TOOLTIP,Tip);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,100);
      ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ANCHOR_RIGHT);
     }

   if(text!="")
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);

   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);

   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,button_width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,button_height);

   return(true);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Del(string r6)
  {
   int t1;

   t1=ObjectsTotal();
   while(t1>=0)
     {
      if(StringFind(ObjectName(t1),r6,0)!=-1)
        {
         ObjectDelete(0,ObjectName(t1));
        }
      t1--;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getATR(ENUM_TIMEFRAMES TF)
  {
   return(iATR(Symbol(), TF, ATR_Period, 1));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CheckOpenProfit()
  {
   double total = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         OrderMagicNumber() == MagicNumber)
        {
         total += OrderProfit()+OrderSwap()+OrderCommission();
        }
     }
   return(NormalizeDouble(total, 2));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TradeCount()
  {
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         OrderType() < 2 &&
         OrderMagicNumber() == MagicNumber)
        {
         count += 1;
        }
     }
   return(count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TotalSize()
  {
   double lots = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         OrderType() < 2 &&
         OrderMagicNumber() == MagicNumber)
        {
         lots += OrderLots();
        }
     }
   return(NormalizeDouble(lots, 2));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NetAveragePrice()
  {
   double nap = 0;
   double sumlots = 0;
   double sumlotprice = 0;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS) &&
         OrderSymbol() == Symbol() &&
         OrderType() < 2 &&
         OrderMagicNumber() == MagicNumber)
        {
         sumlots += OrderLots();
         sumlotprice += (OrderOpenPrice()*OrderLots());
         nap = sumlotprice/sumlots;
        }
     }
   return(NormalizeDouble(nap, Digits));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LastTradePrice(int direction)
  {
   double result = 0;
   if(direction <0)
      result=999999;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderType() > 1)
         continue;
      if((direction < 0 && OrderType() == OP_BUY) || (direction > 0 && OrderType() == OP_SELL))
         continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         result = OrderOpenPrice();
         break;
        }
     }
   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void newOrderSend(int type, double size, string comment)
  {
   double price = 0;
   int clr = clrWhite;
   if(type == OP_BUY)
     {
      price = Ask;
      clr = clrBlue;
     }
   if(type == OP_SELL)
     {
      price = Bid;
      clr = clrRed;
     }

   while(IsTradeContextBusy())
      Sleep(100);
   RefreshRates();
   int openPos = OrderSend(Symbol(), type, size, price, Trade_Slippage, 0, 0, comment, MagicNumber, 0, clr);
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS))
         continue;
      int GetTicket = OrderTicket();

      if(OrderSymbol() == Symbol() && OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber)
        {
         while(IsTradeContextBusy())
            Sleep(100);
         bool ClosePos = OrderClose(GetTicket, OrderLots(), Bid, Trade_Slippage, clrWhite);
        }

      if(OrderSymbol() == Symbol() && OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber)
        {
         while(IsTradeContextBusy())
            Sleep(100);
         bool ClosePos = OrderClose(GetTicket, OrderLots(), Ask, Trade_Slippage, clrWhite);
        }
     }
   return;
  }

datetime CurrentBarTime;
bool IsNewBar(bool TriggerAtStart)
  {
   datetime NewTime = Time[0];
   if(CurrentBarTime != NewTime)
     {
      if(!TriggerAtStart && CurrentBarTime == 0)
        {
         CurrentBarTime = NewTime;
         return false;
        }
      CurrentBarTime = NewTime;
      return true;
     }
   return false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void auto_lot()
  {
   if(Risk_Mode==0)
         TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/3000),2);
   else if(Risk_Mode== 1)
      TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/6000),2);
   else if(Risk_Mode == 2)
         TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/9000),2);    
   else if(Risk_Mode == 3)
         TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/12000),2); 
   else if(Risk_Mode == 4)
         TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/24000),2);
   else if(Risk_Mode == 5)
         TradeSize = NormalizeDouble(0.01*MathFloor(AccountBalance()/48000),2);

   if(TradeSize < 0.01)
      TradeSize = 0.01;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetTrailingStops()
  {
   for(int cnt=0 ; cnt < OrdersTotal() ; cnt++)
     {
      if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
        {
         if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
           {
            double trailstart;
            bool s;
            int TrailBy, TrailingStart, TrailingStep;
            if(OrderType()==OP_BUY)
              {
               TrailBy = BuyTrailBy;
               TrailingStart = BuyTrailingStart;
               TrailingStep = BuyTrailingStep;
               if(TrailBy > 0)
                 {
                  trailstart = OrderOpenPrice() + TrailingStart * myPoint;
                  if(Bid >= trailstart)
                    {
                     if(OrderStopLoss()==0 || OrderStopLoss() < trailstart - TrailBy * myPoint || OrderStopLoss() < Bid - (TrailBy+TrailingStep)* myPoint)
                       {
                        Print("Bid @ "+DoubleToStr(Bid,Digits));
                        s = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - TrailBy * myPoint, OrderTakeProfit(), 0);
                       }
                    }
                 }
              }
            else
              {
               TrailBy = SellTrailBy;
               TrailingStart = SellTrailingStart;
               TrailingStep = SellTrailingStep;
               if(TrailBy > 0)
                 {
                  trailstart = OrderOpenPrice() - TrailingStart * myPoint;
                  if(Ask <= trailstart)
                    {
                     if(OrderStopLoss()==0 || OrderStopLoss() > trailstart + TrailBy*myPoint || OrderStopLoss() > Ask + (TrailBy+TrailingStep) * myPoint)
                       {
                        Print("Ask @ "+DoubleToStr(Ask,Digits));
                        s = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + TrailBy * myPoint, OrderTakeProfit(), 0);
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
