/**
 * Created by junaidm on 7/8/21.
 * Update: KVennamaneni -  6/9/2022 - EVR-40 - Updated Queries to  get and assign Automatic Coupons by Product Grouping for cert 
 * 
 * 
 * 
 */

public with sharing class B2BCouponHelper {

    
    private static final String CLASSNAME = 'B2BCouponHelper';
    private static final String STOREFRONT = 'Forrester';
    private static final String MODULE_NAME = 'Coupon Module';

    private static final String COUPON_QUERY_FIELD = 'SELECT Id, DisplayName__c,Automatic__c,PriorityNumber__c,Start_Date__c,' +
                                                                        'Coupon_Code__c,Enabled__c, End_Date__c, Rule_Type__c, Discount_Type__c, ' +
                                                                        'Discount_Amount__c, Target_Selection__c, TargetMinimumQuantity__c,Target_Product__c,' +
                                                                        'Target_Product__r.Id,Target_Product__r.ProductCode,Target_Product__r.Parent_Product__c, ' +
                                                                        'Target_Product__r.Parent_Product__r.Id, Target_Product__r.Parent_Product__r.ProductCode,' +
                                                                        'Target_Product__r.B2B_Event_Product__r.Event_Category__c,' +
                                                                        'Target_Quantity__c,Max_Use__c,Total_Used__c, Category__r.Id, RedeemedQuantity__c, ' +
                                                                        'AvailableQuantity__c, Available_to_Use__c, Category__r.Name,Categorization__c ';
    private static final String COUPON_ASSOCIATION_QUERY = '(SELECT Id, Account__c, Account__r.Id, Account__r.Name FROM ' +
                                                                    ' B2B_Coupon_Associations__r WHERE Enabled__c=TRUE)';
    private static final String COUPON_PRODUCTS_ASSOCIATION_QUERY = '(SELECT Id,Enabled__c, Product__r.Id,Product__r.ProductCode,Product__r.Parent_Product__c, ' +
            ' Product__r.Parent_Product__r.Id, Product__r.Parent_Product__r.ProductCode,Product__r.B2B_Event_Product__r.Event_Category__c ' +
            ' FROM B2B_Coupon_Event_Associations__r WHERE Enabled__c=TRUE )';
    
    public static Map<String,Object> fetchCartCouponDetails(Map<String, Object> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        List<CartItem> cartItemsList = new List<CartItem>();
        if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)))
        {
            WebCart theCart = B2BCouponHelper.fetchWebCart(params);
            if (theCart != null && theCart.CartItems != null)
            {
                for (CartItem cartItem : theCart.CartItems)
                {
                    if (cartItem.Coupon__c != null)
                    {
                        cartItemsList.add(cartItem);
                    }
                }
            }
            resultMap.put(B2BCouponConstant.COUPON_LIST , cartItemsList);
        }
        return resultMap;
    }

   /* public static Map<String,Object> applyCoupon(Map<String, Object> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)) &&
                params.containsKey(B2BCouponConstant.COUPON_VALUE) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.COUPON_VALUE)))
        {
            //validating a coupon
            B2BCouponService b2BServiceCouponImpl = new B2BCouponServiceImpl();
            resultMap = b2BServiceCouponImpl.validateCoupon(params);
            if (resultMap.containsKey(B2BCouponConstant.IS_VALID))
            {
                if ((!(Boolean) resultMap.get(B2BCouponConstant.IS_VALID)))
                {
                    return resultMap;
                }
                else
                {
                    //applying a coupon
                    Map<String, Object> processCouponMap = b2BServiceCouponImpl.processCoupon(resultMap);
                    if (processCouponMap.get(B2BCouponConstant.SUCCESS) == false)
                    {
                        resultMap.put(B2BCouponConstant.SUCCESS, false);
                        resultMap.put(B2BCouponConstant.MESSAGE, (String) processCouponMap.get(B2BCouponConstant.MESSAGE));
                        return resultMap;
                    } else {
                        resultMap.put(B2BCouponConstant.SUCCESS, true);
                        resultMap.put(B2BCouponConstant.MESSAGE , (String) processCouponMap.get(B2BCouponConstant.MESSAGE));
                    }
                }
            }
        }
        return resultMap;
    }*/
    //DSS-90 OOTB coupons
    public static Map<String,Object> applyCoupon(Map<String, Object> params ){
       
        String methodName = 'applyCoupon';
        String supportData = '';     
        String couponCode = string.valueOf(params.get('couponValue'));
        String WebStoreId = B2BUtils.resolveCommunityIdToWebstoreId(String.valueOf(params.get('communityId')));
        String cartId = String.valueOf(params.get('cartId'));
        WebCart webCartObject = B2BCouponHelper.fetchWebCart(params);
        String effectiveAccountId = webCartObject.AccountId;

        try{
            ConnectApi.cartCouponInput input = new ConnectApi.cartCouponInput();
            input.couponCode = couponCode;
            System.debug('line100-->b2bcouponhelper-->'+ input.couponCode);
            ConnectApi.cartCouponCollection collection = ConnectApi.CommerceCart.applyCartCoupon(WebStoreId,effectiveAccountId,cartId,input);
            System.debug('collection--' + collection);
            params.put(B2BCouponConstant.SUCCESS, true);
            params.put('cartcoupons',couponCode);
        }catch (Exception ex){
            B2BExceptionLogs.storeExceptionLog(ex, STOREFRONT, MODULE_NAME, CLASSNAME, methodName, supportData);
            params.put(B2BCouponConstant.SUCCESS, false);
        }
        return params;
    }

/*
    public static Map<String,Object> removeCoupon(Map<String, Object> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)) &&
                params.containsKey(B2BCouponConstant.COUPON_VALUE) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.COUPON_VALUE)))
        {
            B2BCouponService b2BServiceCouponImpl = new B2BCouponServiceImpl();
            resultMap = b2BServiceCouponImpl.removeCoupon(params);
        }
        return resultMap;
    }
*/
  @AuraEnabled
    public static ConnectApi.cartCouponCollection getCoupons(Map<String,Object> params){
        String methodName = 'getCoupons';
        String supportData = ''; 
        System.debug('line 129 apex params value -->'+params );
        String WebStoreId = B2BUtils.resolveCommunityIdToWebstoreId(String.valueOf(params.get('communityId')));
        String cartId = String.valueOf(params.get('cartId'));
        WebCart webCartObject = B2BCouponHelper.fetchWebCart(params);
        String effectiveAccountId = webCartObject.AccountId;
        ConnectApi.cartCouponCollection collection;
        try{
            collection = ConnectApi.CommerceCart.getCartCoupons(WebStoreId,effectiveAccountId,cartId);
            System.debug('138 line collection-->'+ collection);          
            }catch (Exception ex){
                B2BExceptionLogs.storeExceptionLog(ex, STOREFRONT, MODULE_NAME, CLASSNAME, methodName, supportData);
            }
           return collection;
    }
//Dss-90 remove OOTB coupon.
    public static Map<String, Object> removeCoupon(Map<String, Object> params ){    
        String methodName = 'removeCoupon';
        String supportData = ''; 
        String WebStoreId = B2BUtils.resolveCommunityIdToWebstoreId(String.valueOf(params.get('communityId')));
        String cartId = String.valueOf(params.get('cartId'));
        WebCart webCartObject = B2BCouponHelper.fetchWebCart(params);
        String effectiveAccountId = webCartObject.AccountId;
            if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)) &&
                params.containsKey(B2BCouponConstant.COUPON_VALUE) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.COUPON_VALUE))) 
            {
                try{
                ConnectApi.cartCouponCollection  collection = getCoupons(params);
                //TODO ITERATE COLLECTION.CARTCOUPONS AND ALSO CHECK FOR COUPONS DELETED BY USER  AS SAME USER ENTERD .
                List<ConnectApi.CartCoupon> cartCouponList = collection.cartCoupons.coupons;
                List<webCartAdjustmentBasis> webCartAdj = [Select Id,AdjustmentBasisReferenceId	 FROM WebCartAdjustmentBasis WHERE Id =:cartCouponList[0].cartCouponId LIMIT 1];
                System.debug('webCartAdj-->'+  webCartAdj[0].AdjustmentBasisReferenceId);              
                System.debug('collection cart coupons line155->'+ collection.cartCoupons);
                ConnectApi.CommerceCart.deleteCartCoupon(WebStoreId,effectiveAccountId,cartId,cartCouponList[0].cartCouponId  );
                params.put(B2BCouponConstant.SUCCESS, true);
                } catch(Exception ex){
                    B2BExceptionLogs.storeExceptionLog(ex, STOREFRONT, MODULE_NAME, CLASSNAME, methodName, supportData);
                }
            
            }
        return params;
     
}


    public static Map<String,Object> repriceCart(Map<String, Object> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)))
        {
            //validating a coupon
            B2BCouponService b2BServiceCouponImpl = new B2BCouponServiceImpl();
            resultMap = b2BServiceCouponImpl.repriceCart(params);
        }
        return resultMap;
    }

    public static Map<String,Object> applyAutomaticCoupon(Map<String, Object> params) {
        Map<String, Object> resultMap = new Map<String, Object>();
        if (params != null && params.containsKey(B2BCouponConstant.CART_ID) &&
                String.isNotBlank((String) params.get(B2BCouponConstant.CART_ID)))
        {
            //validating a coupon
            B2BCouponService b2BServiceCouponImpl = new B2BCouponServiceImpl();
            resultMap = b2BServiceCouponImpl.validateCoupon(params);
            if (resultMap.containsKey(B2BCouponConstant.IS_VALID))
            {
                if ((!(Boolean) resultMap.get(B2BCouponConstant.IS_VALID)))
                {
                    return resultMap;
                }
                else
                {
                    //applying a coupon
                    Map<String, Object> processCouponMap = b2BServiceCouponImpl.processCoupon(resultMap);
                    if (processCouponMap.get(B2BCouponConstant.SUCCESS) == false)
                    {
                        resultMap.put(B2BCouponConstant.SUCCESS, false);
                        resultMap.put(B2BCouponConstant.MESSAGE, (String) processCouponMap.get(B2BCouponConstant.MESSAGE));
                        return resultMap;
                    } else {
                        resultMap.put(B2BCouponConstant.SUCCESS, true);
                        resultMap.put(B2BCouponConstant.MESSAGE , (String) processCouponMap.get(B2BCouponConstant.MESSAGE));
                    }
                }
            }
        }
        return resultMap;
    }

    public static Map<String,Object> fetchAutoApplyCoupons(Map<String,Object> params)
    {
        List<B2BCoupon__c> couponList = null;
        Decimal cartItemQuantity = 1;
        Boolean blnCouponFound = false;
        CartItem b2bCartItemObject = null;
        String methodName = 'fetchAutoApplyCoupons';
        if(params!=null && params.containsKey(B2BCouponConstant.CART_ID) &&
                params.get(B2BCouponConstant.CART_ID)!=null)
        {
            WebCart webCartObject = null;
            if(params.containsKey(B2BCouponConstant.CART_OBJECT) &&
                    params.get(B2BCouponConstant.CART_OBJECT)!=null)
            {
                webCartObject = (WebCart)params.get(B2BCouponConstant.CART_OBJECT);
            }else
            {
                webCartObject = B2BCouponHelper.fetchWebCart(params);
            }
            params.put(B2BCouponConstant.CART_OBJECT , webCartObject);
            Set<String> setProductIds = new Set<String>();
            //Store the associated product grouping Coupon Ids so that we can use them in Query -
            Set<id> AssociatedCouponIds = new set<id>();
            if(webCartObject!=null && webCartObject.CartItems!=null && webCartObject.CartItems.size()>0)
            {
                for(CartItem cartItemObject : webCartObject.CartItems)
                {
                    //TODO need to check
                    // how to handle for multiple cart as Forrester is having only 1 cart item so it should work
                    b2bCartItemObject = cartItemObject;
                    cartItemQuantity = cartItemObject.Quantity;
                    setProductIds.add(cartItemObject.Product2Id);
                    if(String.isNotBlank(cartItemObject.Product2.Parent_Product__c))
                    {
                        setProductIds.add(cartItemObject.Product2.Parent_Product__c);
                    }
                    params.put(B2BCouponConstant.CART_ITEM_OBJECT , cartItemObject);
                }
                params.put(B2BCouponConstant.PRODUCT_IDS , setProductIds );
                //Query for Associated Product Grouping Coupons
                for(B2BCouponEventAssociation__c CA :[Select B2BCoupon__c from B2BCouponEventAssociation__c where Product__c IN :setProductIds AND Enabled__c = TRUE]){
                    AssociatedCouponIds.add(CA.B2BCoupon__c);
                }
                System.debug('fetchAutoApplyCoupon cartItemQuantity=== ' + cartItemQuantity);
                System.debug('fetchAutoApplyCoupon setProductIds=== ' + setProductIds);
                Map<String,List<Product2>> mapProduct2sByCategory =  fetchProductsByCategories(params);
                System.debug('fetchAutoApplyCoupon mapProduct2sByCategory=== ' + mapProduct2sByCategory.keySet());
                Set<String> setCategoryName = mapProduct2sByCategory.keySet();
                String query = COUPON_QUERY_FIELD;
                query +=' , ' +COUPON_ASSOCIATION_QUERY;
                query +=' , ' +COUPON_PRODUCTS_ASSOCIATION_QUERY;
                query +=' FROM B2BCoupon__c';
                query += ' WHERE Start_Date__c <= TODAY AND  End_Date__c >=TODAY AND Automatic__c = TRUE  AND enabled__c = TRUE ';
                query += ' AND (( ';
                query +=' Target_Product__c IN : setProductIds ';
                if(setCategoryName!=null && setCategoryName.size()>0)
                {
                    query += ' OR Category__r.Name  IN : setCategoryName';
                }
                query += ') ';
                //fetch Associated Product Grouping Coupons with B2B_Coupon_Event_Associations__r
                if(AssociatedCouponIds != null && AssociatedCouponIds.size()>0){
                    query +='OR (ID IN : AssociatedCouponIds )';
                }
                Query +=')';
                query += ' AND TargetMinimumQuantity__c <=:cartItemQuantity';
                query +=' ORDER BY PriorityNumber__c DESC,TargetMinimumQuantity__c DESC , Discount_Amount__c DESC' ;
                System.debug('fetchAutoApplyCoupon coupon Query=== ' + query);
                B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , 'Coupon Query');
                B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(query));
                couponList = Database.query(query);
                System.debug('fetchAutoApplyCoupon coupon List=== ' + couponList);
                if(couponList!=null && couponList.size()>0)
                {
                    //params.put(B2BCouponConstant.COUPON_LIST , couponList);
                    for(B2BCoupon__c b2BCouponObject : couponList)
                    {
                       if(isAutoCouponBestPrice( b2bCartItemObject , b2BCouponObject))
                       {
                           params.put(B2BCouponConstant.COUPON_OBJECT , b2BCouponObject);
                           blnCouponFound = true;
                           break;
                       }
                    }
                }
            }
        }
        params.put(B2BCouponConstant.AUTO_COUPON_FOUND , blnCouponFound);
        return params;
    }

    public static Boolean isAutoCouponBestPrice(CartItem cartItem , B2BCoupon__c couponObject)
    {
        Boolean blnIsAutoCouponBest = false;
        Map<String, Object> mapCouponResponse = calculateCouponDiscount(cartItem, couponObject);
        if (mapCouponResponse != null &&
                mapCouponResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE) &&
                mapCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE)!=null) 
        {
            Decimal totalAmountToReduce = (Decimal) mapCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE);
            if(totalAmountToReduce>0)
            {
                blnIsAutoCouponBest = true;
            }
        }
        return blnIsAutoCouponBest;
    }
    
    public static CartItem updateCartItemWithCoupon(CartItem cartItem, B2BCoupon__c coupon) {
        Decimal unitAmountToReduce = 0;
        Decimal totalAmountToReduce = 0;
        Decimal couponValidQty = 0;
        String methodName = '';
        Map<String, Object> mapResponse = calculateCouponDiscount(cartItem, coupon);
        if (mapResponse != null && mapResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_UNIT_PRICE) &&
                mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_UNIT_PRICE)!=null &&
                mapResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE) &&
                mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE)!=null &&
                mapResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_QUANTITY) &&
                mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_QUANTITY)!=null)
        {
            unitAmountToReduce = (Decimal)mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_UNIT_PRICE);
            totalAmountToReduce = (Decimal)mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE);
            couponValidQty = (Decimal)mapResponse.get(B2BCouponConstant.COUPON_DISCOUNT_QUANTITY);
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY , 'Coupon Valid Quantity');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(couponValidQty));
            if(cartItem.RedeemedQuantity__c==null)
            {
                cartItem.RedeemedQuantity__c = 0;
            }
            cartItem.RedeemedQuantity__c = couponValidQty;
            cartItem.TotalPrice -= totalAmountToReduce;
            cartItem.TotalCouponAdjustment__c = totalAmountToReduce;
            cartItem.UnitCouponAdjustment__c = unitAmountToReduce;
            cartItem.Coupon__c = coupon.Id;
            cartItem.Coupon__r = coupon;
        }
        return cartItem;
    }
    
    public static Map<String,Object> calculateCouponDiscount(CartItem cartItem, B2BCoupon__c coupon)
    {
        Map<String,Object> mapResponse = new Map<String,Object>();
        Decimal unitAmountToReduce = 0;
        Decimal totalAmountToReduce = 0;
        Decimal couponValidQty = 0;
        String methodName = 'calculateCouponDiscount';
        B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY , 'Started');
        if (coupon.Target_Quantity__c!=null)
        {
            if (cartItem.RedeemedQuantity__c == null)
            {
                cartItem.RedeemedQuantity__c = 0;
            }
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY , 'Cart  Item Used Quantity');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(cartItem.RedeemedQuantity__c));
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY , 'Cart Quantity');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(cartItem.Quantity));
            couponValidQty = cartItem.Quantity;//- cartItem.RedeemedQuantity__c;
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY ,'Available Coupon Quantity');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(coupon.AvailableQuantity__c));
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY ,'Cart Quantity');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(couponValidQty));
            if(cartItem.Quantity > cartItem.RedeemedQuantity__c) 
            {
                while (couponValidQty > coupon.AvailableQuantity__c) 
                {
                    couponValidQty--;
                    B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_ENTRY, 'Decreasing Coupon Quantity');
                    B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_VALUE, JSON.serialize(couponValidQty));
                }
                if (cartItem.Coupon__r != null && coupon.Id == cartItem.Coupon__r.Id && cartItem.RedeemedQuantity__c != null ) 
                {
                    couponValidQty += cartItem.RedeemedQuantity__c;
                }
            }
        }else
        {
            couponValidQty = cartItem.Quantity;
        }
        B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_ENTRY ,'Final Coupon Quantity');
        B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(couponValidQty));
        if(couponValidQty>0) 
        {
            if (coupon.Discount_Type__c == B2BCouponConstant.DISCOUNT_TYPE_ABSOLUTE) 
            {
                unitAmountToReduce = coupon.Discount_Amount__c;
                totalAmountToReduce = (coupon.Discount_Amount__c * couponValidQty);
            } 
            else if (coupon.Discount_Type__c == B2BCouponConstant.DISCOUNT_TYPE_PERCENTAGE)
            {
                System.debug('percentage coupon' + coupon.Discount_Amount__c);
                System.debug('percentage coupon');
                System.debug('percentage coupon');
                unitAmountToReduce = (coupon.Discount_Amount__c * cartItem.SalesPrice / 100);
                totalAmountToReduce = unitAmountToReduce * couponValidQty;
            } 
            else if (coupon.Discount_Type__c == B2BCouponConstant.DISCOUNT_TYPE_PRICE) 
            {
                System.debug('price coupon');
                unitAmountToReduce = cartItem.SalesPrice - coupon.Discount_Amount__c;
                totalAmountToReduce = (unitAmountToReduce * couponValidQty);
            }
            if(totalAmountToReduce>=cartItem.TotalPrice)
            {
                totalAmountToReduce = cartItem.TotalPrice;
            }
            mapResponse.put(B2BCouponConstant.COUPON_DISCOUNT_UNIT_PRICE, unitAmountToReduce);
            mapResponse.put(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE, totalAmountToReduce);
            mapResponse.put(B2BCouponConstant.COUPON_DISCOUNT_QUANTITY, couponValidQty);
        }
        B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_EXIT, 'unitAmountToReduce : '+unitAmountToReduce);
        B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_EXIT, 'totalAmountToReduce : '+totalAmountToReduce);
        B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_EXIT, 'couponValidQty : '+couponValidQty);
        B2BLogger.log(LoggingLevel.DEBUG, CLASSNAME, methodName, B2BConstants.MESSAGING_EXIT, 'End');
        return mapResponse;
    }
    
    public static Boolean isAutoCouponBestPrice(CartItem cartItem, B2BCoupon__c couponObject , B2BCoupon__c autoCouponObject )
    {
        Boolean b2bCoupon = false;
        String methodName = 'isAutoCouponBestPrice';
        Map<String, Object> mapCouponResponse = calculateCouponDiscount(cartItem, couponObject);
        Map<String, Object> mapAutoCouponResponse = calculateCouponDiscount(cartItem, autoCouponObject);
        if (mapCouponResponse != null &&  mapAutoCouponResponse != null &&
                mapCouponResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE) &&
                mapCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE)!=null && 
                mapAutoCouponResponse.containsKey(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE) &&
                mapAutoCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE)!=null ) 
        {
            Decimal totalCouponAmountToReduce = (Decimal) mapCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE);
            Decimal totalAutoCouponAmountToReduce = (Decimal) mapAutoCouponResponse.get(B2BCouponConstant.COUPON_DISCOUNT_TOTAL_PRICE);
            if(totalCouponAmountToReduce > totalAutoCouponAmountToReduce)
            {
                b2bCoupon = false;
            }else
            {
                b2bCoupon = true;
            }
        }
        return b2bCoupon;
    }

    public static void revertCartItem(CartItem cartItem, B2BCoupon__c coupon) {
        if(cartItem!=null && coupon!=null) 
        {
            cartItem.TotalPrice = cartItem.SalesPrice * cartItem.Quantity ;
            cartItem.Coupon__c = null;
            cartItem.UnitCouponAdjustment__c = 0;
            cartItem.TotalCouponAdjustment__c = 0;
            //handle Reverting the Redeem Quantity
            if (cartItem.RedeemedQuantity__c != null && coupon.RedeemedQuantity__c!=null) 
            {
                coupon.RedeemedQuantity__c -= cartItem.RedeemedQuantity__c;
                cartItem.RedeemedQuantity__c = null;
            }
        }
    }

    public static B2BCoupon__c fetchCoupon(Map<String,Object> params) {
        String couponCode = '';
        B2BCoupon__c couponObject = null;
        String methodName = 'fetchCoupon';
        if(params!=null && params.containsKey(B2BCouponConstant.COUPON_VALUE) &&
                String.isNotBlank((String)params.get(B2BCouponConstant.COUPON_VALUE)))
        {
            couponCode = (String)params.get(B2BCouponConstant.COUPON_VALUE);
            String query = COUPON_QUERY_FIELD;
            query +=' , ' +COUPON_ASSOCIATION_QUERY;
            query +=' , ' +COUPON_PRODUCTS_ASSOCIATION_QUERY;
            query +=' FROM B2BCoupon__c';
            query += ' WHERE Start_Date__c <= TODAY AND Coupon_Code__c =: couponCode AND enabled__c = TRUE' ;//AND  End_Date__c >=TODAY
            System.debug('couponquery=== ' + query);
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , 'Coupon Query');
            B2BLogger.log(LoggingLevel.DEBUG , CLASSNAME , methodName , B2BConstants.MESSAGING_VALUE , JSON.serialize(query));

            List<B2BCoupon__c> couponList = Database.query(query);
            if (couponList!=null && couponList.size()>0)
            {
                couponObject = couponList[0];
            }
            System.debug('theCoupon==== ' + couponObject);
        }
        return couponObject;
    }

    public static WebCart fetchWebCart(Map<String,Object> params) {
        String cartId = null;
        WebCart webCartObject = null;
        if(params!=null && params.containsKey(B2BCouponConstant.CART_ID)
                && String.isNotBlank((String)params.get(B2BCouponConstant.CART_ID)))
        {
            cartId = (String)params.get(B2BCouponConstant.CART_ID);
            String cartQuery = 'SELECT Id, AccountId, WebStoreId, Status, Type, TotalAmount, TotalChargeAmount, ' +
                    'TotalProductAmount, TotalListAmount, TotalProductTaxAmount, TotalChargeTaxAmount, ' +
                    'TotalTaxAmount, GrandTotalAmount, TotalProductCount, UniqueProductCount ';
            cartQuery += ', (SELECT Id,Name, UnitCouponAdjustment__c,totalCouponAdjustment__c,Type, ' +
                    'TotalAdjustmentAmount,Product2Id,Product2.Id, Product2.ProductCode, Product2.Parent_Product__c, ' +
                    'Product2.Parent_Product__r.Id,Product2.Parent_Product__r.ProductCode, CartDeliveryGroupId, CartId, Sku, Quantity, ListPrice, ' +
                    'SalesPrice, TotalListPrice, UnitAdjustedPrice, UnitAdjustmentAmount, TotalLineAmount, AdjustmentAmount, ' +
                    'TotalPrice, TotalLineTaxAmount, AdjustmentTaxAmount, TotalTaxAmount, TotalAmount,Coupon__c, ' +
                    'Coupon__r.Id,Coupon__r.Coupon_Code__c,Coupon__r.Start_Date__c,Coupon__r.Enabled__c, Coupon__r.End_Date__c, ' +
                    'Coupon__r.Rule_Type__c, Coupon__r.Discount_Type__c, Coupon__r.Discount_Amount__c, '+
                    'Coupon__r.Target_Selection__c, Coupon__r.Target_Product__c,Coupon__r.RedeemedQuantity__c, Coupon__r.AvailableQuantity__c,' +
                    'Coupon__r.Target_Product__r.Id,  Coupon__r.Target_Product__r.ProductCode,  Coupon__r.Target_Product__r.Parent_Product__c,  ' +
                    'Coupon__r.Target_Product__r.Parent_Product__r.Id, Coupon__r.Target_Product__r.Parent_Product__r.ProductCode,'+
                    'Coupon__r.Target_Product__r.B2B_Event_Product__r.Event_Category__c,' +
                    'Coupon__r.Target_Quantity__c,Coupon__r.Max_Use__c, Coupon__r.TargetMinimumQuantity__c,' +
                    'Coupon__r.Total_Used__c, Coupon__r.Category__r.Id, Coupon__r.Category__r.NAME, '+
                    'TotalPriceAfterAllAdjustments,RedeemedQuantity__c FROM CartItems ORDER BY TotalAmount DESC) ';
            cartQuery += ' FROM WebCart ' ;
            cartQuery += ' WHERE Id =: cartId limit 1';
            List<WebCart> cartList = Database.query(cartQuery);
            if (cartList != null && cartList.size() > 0)
            {
                webCartObject = cartList.get(0);
                System.debug('webCartObject== ' + webCartObject);
            }
        }
        return webCartObject;
    }

    public static Map<String, Object> checkProductCategoryOnCart(Map<String,Object> params)
    {
        Map<String, Object> mapResult = new Map<String,Object>();
        Set<String> setProductIds = new Set<String>();
        if(params!=null && params.containsKey(B2BCouponConstant.COUPON_OBJECT) &&
                params.get(B2BCouponConstant.COUPON_OBJECT)!=null &&
                params.containsKey(B2BCouponConstant.CART_OBJECT) &&
                params.get(B2BCouponConstant.CART_OBJECT)!=null)
        {
            WebCart webCartObject = (WebCart)params.get(B2BCouponConstant.CART_OBJECT);
            B2BCoupon__c couponObject = (B2BCoupon__c)params.get(B2BCouponConstant.COUPON_OBJECT);
            if(webCartObject!=null && webCartObject.CartItems!=null && couponObject!=null && couponObject.Category__r!=null)
            {
                String strCategoryName = couponObject.Category__r.Name;
                System.debug('>strCategoryName>>'+strCategoryName);
                for(CartItem cartItemObject : webCartObject.CartItems)
                {
                    setProductIds.add(cartItemObject.Product2Id);
                }
                if(setProductIds!=null && setProductIds.size()>0 && String.isNotBlank(strCategoryName))
                {
                    params.put(B2BCouponConstant.PRODUCT_IDS , setProductIds );
                    Map<String,List<Product2>> mapProduct2sByCategory =  fetchProductsByCategories(params);
                    if(mapProduct2sByCategory!=null && mapProduct2sByCategory.containsKey(strCategoryName))
                    {
                        List<Product2> lstProducts = mapProduct2sByCategory.get(strCategoryName);
                        for (CartItem cartItemObject : webCartObject.CartItems)
                        {
                            if(lstProducts!=null && lstProducts.size()>0)
                            {
                                for(Product2 product2Object : lstProducts)
                                {
                                    if(product2Object.Id == cartItemObject.Product2Id )
                                    {
                                        if(!mapResult.containsKey(B2BCouponConstant.CART_ITEM_OBJECT))
                                        {
                                            mapResult.put(B2BCouponConstant.CART_ITEM_OBJECT , cartItemObject);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return mapResult;
    }

    public static Map<String,List<Product2>> fetchProductsByCategories(Map<String, Object> params)
    {
        Map<String,List<Product2>> mapProductsByCategory = new Map<String, List<Product2>>();
        if(params!=null && params.containsKey(B2BCouponConstant.PRODUCT_IDS) &&
                params.get(B2BCouponConstant.PRODUCT_IDS)!=null)
        {
            Set<String> productIds = (Set<String>)params.get(B2BCouponConstant.PRODUCT_IDS);
            if(productIds!=null && productIds.size()>0)
            {
                List<ProductCategoryProduct> lstProductCategory = fetchProductCategories(productIds);
                if (lstProductCategory != null && lstProductCategory.size() > 0)
                {
                    for(ProductCategoryProduct productCategoryProductObject : lstProductCategory)
                    {
                        ProductCategory categoryObject = productCategoryProductObject.ProductCategory;
                        if(categoryObject!=null)
                        {
                            List<Product2> lstProduct = null;
                            if (mapProductsByCategory.containsKey(productCategoryProductObject.ProductCategory.Name))
                            {
                                lstProduct = mapProductsByCategory.get(productCategoryProductObject.ProductCategory.Name);
                            }else
                            {
                                lstProduct = new List<Product2>();
                            }
                            Product2 product2Object = productCategoryProductObject.Product;
                            lstProduct.add(product2Object);
                            mapProductsByCategory.put(categoryObject.Name , lstProduct);
                        }
                    }
                }
            }
        }
        return mapProductsByCategory;
    }

    public static List<ProductCategoryProduct> fetchProductCategories(Set<String> productIds)
    {
        List<ProductCategoryProduct> lstProductCategories = null;
        if(productIds!=null && productIds.size()>0)
        {
            lstProductCategories = [SELECT Id,Product.Id, Product.ProductCode, ProductCategory.Id, ProductCategory.Name
                                                FROM ProductCategoryProduct WHERE Product.Id IN : productIds];
        }
        return  lstProductCategories;
    }
    public static void updateCartCoupons(Map<String, Object> params){
        String methodName = 'updateCartCoupons';
        String supportData = '';
        try{
            ConnectApi.cartCouponCollection  collection = getCoupons(params);
            System.debug('collection-->'+ collection);
            List<String> coupons = new List<String>();
            if(collection != null) {
                ConnectApi.CartCouponList couponList = collection.cartCoupons;
                if(couponList != null) {
                    List<ConnectApi.CartCoupon> cpns = couponList.coupons;
                    for(ConnectApi.CartCoupon cpn : cpns) {
                        System.debug(cpn);
                        coupons.add(cpn.couponCode);
                    }
                    for(String cpnCode : coupons){
                        params.put('couponValue', cpnCode);
                        removeCoupon(params);
                    }
                    for(String cpnCode : coupons){
                        params.put('couponValue', cpnCode);
                        applyCoupon(params);
                    }
                }
            
            }
        } catch(Exception ex){
            B2BExceptionLogs.storeExceptionLog(ex, STOREFRONT, MODULE_NAME, CLASSNAME, methodName, supportData);
        }
        
    }
}