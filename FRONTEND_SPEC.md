# Frontend Specification: Liquidation Monitor Dashboard

Build a Next.js 14 dashboard app called "Liquidation Monitor" with 3 pages using TailwindCSS and shadcn/ui. The app monitors Aave borrower positions and their liquidation risk on Stagenet testnet. Use ethers.js to connect to the blockchain. Use recharts for charts. Use App Router with TypeScript.

---

## 🌐 GLOBAL SETUP

### Network Configuration
```javascript
const CONTRACT_ADDRESS = "0x2cdED3F23eb62f809D9577e89e73d5d317BD5bB6"  // Current active deployment
const CONTRACT_ADDRESS_AUTOMATED = "0xcAa317607CC82889E346f931673d28007a554863"  // Automated version (optional)
const RPC_URL = "https://rpc.contract.dev/b5a1407e7d0eafbfcd04ad6f4d84d817"
const CHAIN_ID = 99561  // Contract.dev Workspace
const CHAIN_NAME = "Contract.dev"
```

### Contract ABI Functions

**Read Functions:**
- `getMonitoredWallets()` → returns `address[]`
- `checkHealth(address wallet)` → returns `(uint256 healthFactor, uint8 status)`
- `getHealthFactor(address wallet)` → returns `(uint256 healthFactor, uint8 status)` [view only]
- `lastHealthFactor(address wallet)` → returns `uint256`
- `getWalletCount()` → returns `uint256`
- `isMonitored(address wallet)` → returns `bool`
- `dangerThreshold()` → returns `uint256` (default: 1.1e18)
- `criticalThreshold()` → returns `uint256` (default: 1.05e18)
- `owner()` → returns `address`

**Write Functions (for future features):**
- `checkAllWallets()` → void
- `addWallet(address wallet)` → void [onlyOwner]
- `removeWallet(address wallet)` → void [onlyOwner]

### Contract Events
- `HealthChecked(address indexed wallet, uint256 healthFactor, uint8 status)`
- `WarningAlert(address indexed wallet, uint256 healthFactor, uint256 blockNumber)`
- `CriticalAlert(address indexed wallet, uint256 healthFactor, uint256 blockNumber)`
- `PositionSafe(address indexed wallet, uint256 healthFactor)`
- `WalletAdded(address indexed wallet)`
- `WalletRemoved(address indexed wallet)`

### Data Format Rules
- **Health Factor:** uint256 scaled by 1e18. Divide by 1e18 to get the real number (e.g., 1500000000000000000 = 1.5)
- **Status Codes:**
  - `0` = Recovered (was in danger, now safe)
  - `1` = Safe
  - `2` = Warning (danger zone)
  - `3` = Critical (near liquidation)

### Color Coding for Health Factor
- **🟢 Green (Safe):** ≥ 1.5
- **🟡 Yellow (Watch):** 1.1 - 1.5
- **🟠 Orange (Danger):** 1.05 - 1.1
- **🔴 Red (Critical):** < 1.05

### Threshold Reference Lines
- **Danger Threshold:** 1.1 (show as orange dashed line)
- **Critical Threshold:** 1.05 (show as red dashed line)

---

## 📱 PAGE 1: DASHBOARD (route: "/" or page.tsx)

### Header Bar
- **Left:** App name "Liquidation Monitor" with logo/icon
- **Right:** 
  - Network status indicator: Green dot + "Stagenet Connected" 
  - Current block number (auto-update every 10 seconds)
  - Wallet connection button (optional for future)

### Summary Cards (4 cards in a row)
1. **Total Monitored Wallets**
   - Large number
   - Subtitle: "Active positions"
   - Icon: wallet icon

2. **Active Warnings**
   - Number of wallets with status = 2
   - Subtitle: "Need attention"
   - Icon: yellow warning triangle
   - Color: yellow/orange accent

3. **Critical Alerts**
   - Number of wallets with status = 3
   - Subtitle: "Immediate risk"
   - Icon: red alert circle
   - Color: red accent

4. **Last Check Time**
   - Show "X minutes ago" or timestamp
   - Subtitle: "Last update"
   - Icon: clock icon
   - Add "Refresh" button here

### Main Wallets Table
**Above table:**
- "Refresh All" button (re-fetches all wallet data)
- Search bar to filter wallets by address
- Total count: "Showing X of Y wallets"

**Table Columns:**
1. **Wallet Address** 
   - Show: `0x1234...abcd` (first 6 + last 4 chars)
   - Clickable → routes to `/wallet/:address`
   - Copy button on hover

2. **Health Factor**
   - Colored number with 2 decimal places
   - Color based on value (see color coding above)
   - Show trend icon: ↑ (improving) / ↓ (declining) / → (stable)
   - Compare with `lastHealthFactor` to determine trend

3. **Status Badge**
   - Colored pill/badge with text
   - 🟢 Safe / 🟡 Warning / 🟠 Danger / 🔴 Critical / 💚 Recovered
   - Pulse animation for Critical status

4. **Last Checked**
   - Block number: "Block #12345"
   - Or "Never checked" if no data

5. **Actions**
   - "Check Now" button → calls `checkHealth(wallet)`
   - Loading spinner when checking
   - Show last check timestamp on hover

**Table Features:**
- Sortable columns (click header to sort)
- Loading skeleton while fetching
- Empty state: "No wallets monitored yet"
- Pagination if > 20 wallets

### Auto-Refresh Feature
- Toggle switch: "Auto-refresh every 30 seconds"
- Show countdown timer when enabled

---

## 📊 PAGE 2: ALERT HISTORY (route: "/alerts" or app/alerts/page.tsx)

### Page Header
- **Title:** "Alert History"
- **Subtitle:** "All on-chain warning and critical alerts from the contract"
- **Time Range:** "Last 1000 blocks" or "Last 24 hours"

### Stats Bar (3 cards in a row)
1. **Total Alerts** - Count of all Warning + Critical events
2. **Total Warnings** - Count of WarningAlert events
3. **Total Criticals** - Count of CriticalAlert events

### Filter Bar
- **Text Input:** "Filter by wallet address..." (0x...)
- **Dropdown:** "Alert Type" - Options: All / Warning / Critical / Recovered
- **Date Range:** "Last 24h / 7d / 30d / All time"
- **Clear Filters** button
- **Export CSV** button (optional)

### Alert Feed (Scrollable List)
Each alert card shows:
- **Icon:** 
  - 🟡 Yellow triangle with ! for Warning
  - 🔴 Red circle with X for Critical
  - 🟢 Green checkmark for Recovered
- **Alert Type:** "Warning Alert" / "Critical Alert" / "Position Recovered"
- **Wallet Address:** Shortened, clickable → routes to wallet detail
- **Health Factor:** e.g., "1.08" (colored)
- **Block Number:** "Block #12345"
- **Timestamp:** "2 hours ago" or actual time
- **Previous Health Factor:** Show if available (for context)

**Alert Card Layout:**
```
┌─────────────────────────────────────────┐
│ 🔴 CRITICAL ALERT                       │
│                                         │
│ Wallet: 0x1234...abcd                  │
│ Health Factor: 1.03 → 1.01             │
│ Block: #24605680                       │
│ Time: 5 minutes ago                    │
└─────────────────────────────────────────┘
```

### Features
- **Infinite scroll** or pagination
- **Real-time updates** (listen for new events)
- **"No alerts found"** empty state with illustration
- **Loading spinner** while fetching events

### Event Fetching Strategy
- Query last 10,000 blocks initially
- Use ethers.js event filters:
  ```javascript
  contract.queryFilter("WarningAlert", fromBlock, toBlock)
  contract.queryFilter("CriticalAlert", fromBlock, toBlock)
  contract.queryFilter("PositionSafe", fromBlock, toBlock)
  ```

---

## 🔍 PAGE 3: WALLET DETAIL (route: "/wallet/[address]" or app/wallet/[address]/page.tsx)

Accessible by clicking a wallet row on Dashboard or from Alert History. Uses Next.js dynamic routes.

### Top Section
- **Back Button:** "← Back to Dashboard"
- **Wallet Address:** Full address with copy button
- **Add to Favorites:** Star icon (optional)

### Health Status Card (Large Card)
- **Current Health Factor:** Large number (e.g., 1.42), colored
- **Status Badge:** Current status with icon
- **Change Indicator:** "+0.12 from last check" with up/down arrow
- **Last Updated:** "Block #12345, 2 minutes ago"
- **Refresh Button:** Manual refresh for this wallet

### Health Factor Chart
**Chart Type:** Line chart (recharts LineChart)
- **X Axis:** Block number
- **Y Axis:** Health Factor (0 to 3.0 range, or auto-scale)
- **Data Source:** HealthChecked events for this wallet
- **Reference Lines:**
  - Red dashed line at y=1.05 (Critical threshold)
  - Orange dashed line at y=1.1 (Danger threshold)
  - Green dashed line at y=1.5 (Safe threshold)
- **Tooltip:** Show exact health factor + block number on hover
- **Time Range Selector:** Last 100 blocks / 1000 blocks / All time

**Chart Features:**
- Smooth line with gradient fill
- Data points on hover
- Zoom functionality (optional)
- Color changes based on threshold zones

### Aave Position Details (Optional Enhancement)
If you want to show more Aave data:
- **Total Collateral:** Query from Aave Pool
- **Total Debt:** Query from Aave Pool
- **Liquidation Price:** Calculate from health factor
- **Assets Used:** List of tokens

### Alert History for This Wallet
**Section Title:** "Alert History for This Wallet"

A table showing all alerts (Warning + Critical + Recovered) for this specific wallet:
- **Date/Time**
- **Alert Type** (colored badge)
- **Health Factor** at time of alert
- **Block Number**
- **Status Change** (e.g., "Warning → Critical")

### Additional Stats (Optional)
- **Times in Danger:** Count of warnings
- **Times Critical:** Count of critical alerts
- **Average Health Factor:** Over monitored period
- **Lowest Health Factor:** Historical minimum

---

## 🧭 NAVIGATION

### Sidebar (Persistent Layout Component)
- **Logo + App Name** at top
- **Navigation Links:** Use Next.js `<Link>` component
  - 🏠 Dashboard (/)
  - 🚨 Alert History (/alerts)
  - ℹ️ About (optional)
- **Footer:**
  - Contract address (shortened, copy button)
  - Network: Stagenet badge
  - GitHub link

### Mobile Responsive
- Hamburger menu for mobile using shadcn/ui Sheet component
- Collapsible sidebar on tablet

### Layout Structure
Create a root layout (`app/layout.tsx`) with sidebar, and page-specific content in `page.tsx` files.

---

## 🎨 STYLING & DESIGN

### Theme
- **Dark Mode:** Primary (recommended for DeFi feel)
  - Background: `#0f172a` (slate-900)
  - Card background: `#1e293b` (slate-800)
  - Text: `#f1f5f9` (slate-100)
  - Borders: `#334155` (slate-700)

- **Light Mode:** Optional alternative

### TailwindCSS & shadcn/ui Components
- **Cards:** Use shadcn/ui `<Card>` component with `bg-slate-800 border-slate-700`
- **Buttons:** Use shadcn/ui `<Button>` component with variants
- **Badges:** Use shadcn/ui `<Badge>` component
- **Tables:** Use shadcn/ui `<Table>` component
- **Sheet/Dialog:** For mobile menu and modals
- **Skeleton:** For loading states

### Color Palette
- **Primary:** Blue (`#3b82f6`) for actions
- **Success:** Green (`#10b981`) for safe status
- **Warning:** Yellow (`#fbbf24`) for warnings
- **Danger:** Red (`#ef4444`) for critical
- **Info:** Cyan (`#06b6d4`) for info

### Animations
- Smooth transitions: `transition-all duration-200`
- Pulse animation for critical alerts
- Fade in/out for loading states
- Skeleton loaders while fetching data

### Professional UI Elements
- Glass morphism effect on cards (subtle transparency)
- Subtle shadows: `shadow-lg shadow-slate-900/50`
- Hover states on interactive elements
- Loading skeletons using shadcn/ui Skeleton (not just spinners)
- Toast notifications using Sonner
- Smooth page transitions with Next.js View Transitions (optional)
- Use shadcn/ui components for consistent design system

---

## 🔧 TECHNICAL IMPLEMENTATION NOTES

### Next.js 14 Setup
- Use Next.js 14 with App Router (not Pages Router)
- TypeScript for type safety
- Server Components by default, Client Components (`'use client'`) for interactivity
- React Server Components for initial data fetching
- Context API or Zustand for client-side state
- TanStack Query (React Query) for data fetching and caching

### Project Structure
```
app/
  ├── layout.tsx           # Root layout with sidebar
  ├── page.tsx             # Dashboard (/)
  ├── alerts/
  │   └── page.tsx         # Alert history
  ├── wallet/
  │   └── [address]/
  │       └── page.tsx     # Wallet detail (dynamic route)
  └── api/                 # Optional API routes
components/
  ├── ui/                  # shadcn/ui components
  ├── dashboard/           # Dashboard-specific components
  ├── alerts/              # Alert-specific components
  └── wallet/              # Wallet-specific components
lib/
  ├── contract.ts          # Contract ABI and addresses
  ├── ethers.ts            # Ethers.js provider setup
  └── utils.ts             # Helper functions
```

### Ethers.js Integration (Client Components)
```typescript
'use client';

import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider(RPC_URL);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);

// Get wallets
const wallets = await contract.getMonitoredWallets();

// Check health
const [healthFactor, status] = await contract.getHealthFactor(walletAddress);
const healthFactorNumber = Number(healthFactor) / 1e18;

// Listen for events (in useEffect)
useEffect(() => {
  contract.on("WarningAlert", (wallet, healthFactor, blockNumber) => {
    // Handle new warning
  });
  
  return () => {
    contract.removeAllListeners();
  };
}, []);
```

**Important:** Components that use ethers.js event listeners, state, or browser APIs must be Client Components (`'use client'`). Use Server Components for static layouts and initial data fetching.

### Data Refresh Strategy
1. **Initial Load:** Server Component fetches initial data (SSR)
2. **Client-side Updates:** TanStack Query for auto-refetch every 30 seconds
3. **Event Listening:** Real-time updates in Client Components
4. **Manual Refresh:** Router refresh or query invalidation

### Next.js Specific Considerations
- **Dynamic Routes:** Use `[address]` folder for wallet detail pages
- **Loading States:** Use `loading.tsx` files for automatic loading UI
- **Error Handling:** Use `error.tsx` files for error boundaries
- **Metadata:** Add `metadata` export in page.tsx for SEO
- **Image Optimization:** Use `<Image>` from `next/image` for logos

### Error Handling
- Network errors: Show reconnect banner
- Contract errors: Display user-friendly messages
- Loading states: Show skeletons/spinners
- Empty states: Provide helpful messages

### Performance Optimization
- Memoize expensive calculations
- Virtual scrolling for large lists
- Debounce search inputs
- Lazy load charts and heavy components

### Testing Considerations
- Mock provider for development
- Test with various health factors
- Test event listening
- Test error states
- Use Next.js testing libraries (Jest + React Testing Library)

### v0.dev Usage Tips
When using v0.dev to generate this app:
1. **Start with layout:** Generate the root layout with sidebar first
2. **Page by page:** Create each page separately (Dashboard → Alerts → Wallet Detail)
3. **Components:** Break down into reusable components (WalletCard, AlertCard, etc.)
4. **Prompt structure:** Include "Next.js 14 App Router" and "shadcn/ui" in every prompt
5. **Specify client/server:** Mention which components need `'use client'` directive

---

## 📦 DEPENDENCIES

### Required Packages
```json
{
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "ethers": "^6.9.0",
    "recharts": "^2.10.0",
    "tailwindcss": "^3.4.0",
    "lucide-react": "^0.300.0",
    "date-fns": "^2.30.0",
    "sonner": "^1.3.0",
    "@tanstack/react-query": "^5.17.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0"
  }
}
```

### shadcn/ui Components to Install
Run these commands after setting up Next.js:
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add card
npx shadcn-ui@latest add button
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add table
npx shadcn-ui@latest add sheet
npx shadcn-ui@latest add skeleton
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add select
npx shadcn-ui@latest add input
npx shadcn-ui@latest add switch
```

### Optional Enhancements
- `zustand` - Client-side state management
- `framer-motion` - Animations
- `@tanstack/react-table` - Advanced table features

---

## 🚀 FUTURE FEATURES (Phase 2)

1. **Wallet Connection**
   - Connect MetaMask/WalletConnect
   - Allow owner to add/remove wallets from UI
   - Show user's own wallet status

2. **Notifications**
   - Browser push notifications
   - Email alerts (via backend)
   - Telegram bot integration

3. **Advanced Analytics**
   - Heatmap of risk periods
   - Correlation with ETH price
   - Liquidation profitability calculator

4. **Multi-Contract Support**
   - Switch between Manual and Automated versions
   - Support multiple chains

5. **Export Features**
   - Export alerts to CSV
   - Generate reports
   - Share wallet status links

---

## 📋 ACCEPTANCE CRITERIA

### Must Have ✅
- [x] All 3 pages render correctly
- [x] Can fetch and display monitored wallets
- [x] Health factors display with correct colors
- [x] Alert history shows contract events
- [x] Wallet detail page shows health factor chart
- [x] Mobile responsive
- [x] Dark theme with professional styling
- [x] Loading and error states

### Nice to Have 🌟
- [ ] Real-time event updates
- [ ] Auto-refresh toggle
- [ ] Export functionality
- [ ] Search and filtering
- [ ] Wallet connection
- [ ] Toast notifications

---

## 🎯 DESIGN REFERENCE

Think of these popular DeFi dashboards for inspiration:
- **Aave Dashboard** - Clean, professional
- **DeBank** - Great wallet detail views
- **Dune Analytics** - Excellent charts
- **Zapper** - Modern card layouts

Keep it clean, focused on data, and easy to scan quickly for critical information.

---

## 🚀 GETTING STARTED WITH v0.dev

### Step 1: Initial Setup
Prompt v0.dev:
```
Create a Next.js 14 app with App Router and TypeScript. Set up TailwindCSS and shadcn/ui. 
Create a dark theme layout with a persistent sidebar. The app is called "Liquidation Monitor" 
and monitors Aave positions. Add navigation links for Dashboard (/), Alert History (/alerts), 
and a placeholder for wallet detail pages.
```

### Step 2: Dashboard Page
Prompt v0.dev:
```
Create the Dashboard page (app/page.tsx) for a liquidation monitor. Show:
1. Four summary cards: Total Wallets, Active Warnings, Critical Alerts, Last Check Time
2. A data table with columns: Wallet Address, Health Factor (colored), Status Badge, Last Checked, Actions
3. Use shadcn/ui Card, Table, and Badge components
4. Dark theme with slate colors
5. Add a refresh button and search bar above the table
```

### Step 3: Alert History Page
Prompt v0.dev:
```
Create the Alert History page (app/alerts/page.tsx). Show:
1. Three stat cards at top: Total Alerts, Total Warnings, Total Criticals
2. Filter bar with: text input for wallet address, dropdown for alert type, date range selector
3. Scrollable list of alert cards showing: icon, alert type, wallet address, health factor, block number, timestamp
4. Use shadcn/ui components, dark theme
```

### Step 4: Wallet Detail Page
Prompt v0.dev:
```
Create a dynamic Wallet Detail page (app/wallet/[address]/page.tsx). Show:
1. Back button and wallet address at top
2. Large health status card with current health factor (colored) and status badge
3. Recharts line chart showing health factor history over blocks
4. Add reference lines at y=1.05 (red), y=1.1 (orange), y=1.5 (green)
5. Alert history table for this specific wallet below the chart
6. Use shadcn/ui components, dark theme
```

### Step 5: Add Ethers.js Integration
Prompt v0.dev:
```
Add ethers.js integration to fetch data from a smart contract. Create:
1. lib/contract.ts with contract address, ABI, and provider setup
2. Client component hooks to fetch monitored wallets
3. Function to convert health factors from uint256 (divide by 1e18)
4. Use TanStack Query for data fetching with 30-second refetch interval
5. Add 'use client' directive where needed
```

---

**END OF SPECIFICATION**

This spec is optimized for v0.dev! Start with the setup prompt and build page by page. Each section above gives you the exact prompt structure to use.
