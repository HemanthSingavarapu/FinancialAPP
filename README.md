# 💸 Financial App 📱

A **comprehensive Flutter application** that provides **real-time financial information**, including the latest **news**, **stock data**, and **cryptocurrency prices** — all in one sleek, intuitive interface.

![Home Screen](https://github.com/HemanthSingavarapu/FinancialAPP/blob/e62a90b4b98aeb73aefe4be58a48fb2b7cb92173/screenshots/HOMEPage1.png)

---

## ✨ Features

- 📰 **Financial News** — Stay updated with the latest financial and stock market headlines from trusted sources.  
- 📈 **Stock Market Data** — Get live updates, market trends, and stock details in real-time.  
- 💰 **Cryptocurrency Tracking** — Track prices, trends, and market caps of major cryptocurrencies.  
- 🎨 **Beautiful UI** — Clean, modern design with smooth animations and intuitive navigation.  
- 📱 **Responsive Design** — Seamlessly optimized for both Android and iOS platforms.

---

## 📸 Screenshots

### 🗞️ NEWS Screen
![News Screen](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/news_screen.png)

---

### 💹 Stocks Section
![Stock Screen](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/Stockscreen.png)
![Stock Details 1](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/StockDetails1.png)
![Stock Details 2](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/StockDetails2.png)
![Stock Details 3](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/StockDetails3.png)

---

### 🪙 Cryptocurrency Section
![Crypto Screen](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/cryptoScreen.png)
![Crypto Details](https://github.com/HemanthSingavarapu/FinancialAPP/blob/952e62ce5a51d28f267a34e7fb2bb9076dd2e7b9/screenshots/CryptoDetails.png)

---

## 🔑 API Keys

This app uses multiple **third-party APIs** to fetch real-time financial data.  
You’ll need to obtain free API keys from the following services:

### 📰 1. News API — [newsapi.org](https://newsapi.org)
**Used for:** Fetching the latest financial and stock market news.  
**Steps:**
1. Visit [newsapi.org](https://newsapi.org)
2. Sign up for a free account
3. Get your API key from the dashboard  
**Free Tier:** 100 requests/day

---

### 💹 2. Financial Modeling Prep API — [financialmodelingprep.com](https://financialmodelingprep.com)
**Used for:** Stock market data and company information.  
**Steps:**
1. Visit [financialmodelingprep.com](https://financialmodelingprep.com)
2. Create a free account
3. Obtain your API key  
**Free Tier:** 250 requests/day

---

### 🪙 3. CoinMarketCap API — [coinmarketcap.com/api](https://coinmarketcap.com/api)
**Used for:** Cryptocurrency prices and market data.  
**Steps:**
1. Visit [coinmarketcap.com/api](https://coinmarketcap.com/api)
2. Sign up for a developer account
3. Get your API key  
**Free Tier:** 10,000 requests/month

---

### ⚡ 4. Groq API (Optional – For AI Insights)
If you’ve integrated **AI financial insights or chatbot** features, use **Groq API** for intelligent responses.

**Setup:**
1. Get your API key from [Groq Console](https://console.groq.com)
2. Create a `.env` file in your Flutter project:
   ```env
   GROQ_API_KEY=your_api_key_here
