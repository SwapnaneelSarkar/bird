# Performance Test Guide

## Testing the Optimizations

### Before Testing
1. Clear all caches to ensure fresh data:
```dart
OrderHistoryService.clearOrderDetailsCache();
OrderHistoryService.clearRestaurantDetailsCache();
MenuItemService.clearMenuItemCache();
```

### Test Scenarios

#### 1. Chat Page Loading Test
**Steps:**
1. Navigate to Order History page
2. Tap on any order to open Chat page
3. Measure loading time from tap to fully loaded chat

**Expected Results:**
- **Before**: ~30 seconds
- **After**: ~2-5 seconds (85-90% improvement)

**Performance Monitor Logs to Check:**
```
⏱️ PerformanceMonitor: Started timing ChatDataLoading
⏱️ PerformanceMonitor: ChatDataLoading completed in XXXXms
📊 PerformanceMonitor: Performance Statistics
```

#### 2. Order Details Page Loading Test
**Steps:**
1. Navigate to Order History page
2. Tap on any order to open Order Details page
3. Measure loading time from tap to fully loaded details

**Expected Results:**
- **Before**: ~25-30 seconds
- **After**: ~2-4 seconds (85-90% improvement)

**Performance Monitor Logs to Check:**
```
⏱️ PerformanceMonitor: Started timing OrderDetailsLoading
⏱️ PerformanceMonitor: OrderDetailsLoading completed in XXXXms
```

#### 3. Cache Hit Test
**Steps:**
1. Open Chat page for an order (first time)
2. Go back to Order History
3. Open Chat page for the same order again (second time)
4. Compare loading times

**Expected Results:**
- **First time**: ~2-5 seconds
- **Second time**: ~0.5-1 second (cache hit)

**Cache Logs to Check:**
```
OrderHistoryService: ✅ Returning cached order details for: [orderId]
MenuItemService: ✅ Returning cached menu item details for: [menuId]
OrderHistoryService: ✅ Returning cached restaurant details for: [partnerId]
```

#### 4. Restaurant API Call Reduction Test
**Steps:**
1. Open Order History page
2. Check debug logs for restaurant API calls
3. Verify no duplicate calls for same restaurant

**Expected Results:**
- Only one API call per unique restaurant
- Cached results for subsequent orders from same restaurant

**Logs to Check:**
```
OrderHistoryBloc: Fetching data for X unique restaurants
OrderHistoryService: ✅ Returning cached restaurant details for: [partnerId]
```

### Performance Metrics to Monitor

#### 1. Loading Times
- Chat page: Target < 5 seconds
- Order details page: Target < 4 seconds
- Cache hits: Target < 1 second

#### 2. API Call Reduction
- Order details: 1 call per order (cached)
- Menu items: 1 call per unique menu item (cached)
- Restaurant details: 1 call per unique restaurant (cached)

#### 3. Memory Usage
- Cache size should be reasonable
- No memory leaks from cached data

### Debug Commands

#### Clear All Caches
```dart
// In debug console or test code
OrderHistoryService.clearOrderDetailsCache();
OrderHistoryService.clearRestaurantDetailsCache();
MenuItemService.clearMenuItemCache();
```

#### View Performance Statistics
```dart
// In debug console
PerformanceMonitor.logAllStatistics();
```

#### View Cache Status
```dart
// Check cache hits in debug logs
// Look for "✅ Returning cached" messages
```

### Expected Performance Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Chat Loading | 30s | 2-5s | 85-90% |
| Order Details Loading | 25-30s | 2-4s | 85-90% |
| Cache Hits | N/A | <1s | N/A |
| API Calls | Multiple per item | 1 per unique item | 70-80% reduction |

### Troubleshooting

#### If Still Slow:
1. Check network connectivity
2. Verify API endpoints are responding quickly
3. Check for any remaining delays in the code
4. Monitor debug logs for performance bottlenecks

#### If Cache Not Working:
1. Verify cache duration settings
2. Check cache clearing logic
3. Ensure cache keys are consistent

#### If API Calls Still Duplicate:
1. Check deduplication logic
2. Verify unique ID extraction
3. Monitor cache hit/miss logs

### Success Criteria
- ✅ Chat page loads in < 5 seconds
- ✅ Order details page loads in < 4 seconds
- ✅ Cache hits work correctly
- ✅ No duplicate API calls for same data
- ✅ Performance monitor shows improvement
- ✅ No memory leaks or crashes 