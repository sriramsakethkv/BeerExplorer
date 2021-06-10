public with sharing class beerSearchController {

    // return beer records based on search string
    @AuraEnabled(cacheable=true)
    public static list<Beer__c> searchBeerRecords(String searchString){
        list<Beer__c> beerList = new list<Beer__c>();
        String searchValue = '%'+searchString+'%';
        String Query = '';
        if (searchString != null) {
            Query = 'SELECT id,Name,Id__c,Alcohol__c,Price__c,brewery_Name__c,Image__c FROM Beer__c WHERE Name LIKE :searchValue LIMIT 50';
        }
        else{
            Query = 'SELECT id,Name,Id__c,Alcohol__c,Price__c,brewery_Name__c,Image__c FROM Beer__c LIMIT 50';
        }

        beerList = Database.query(Query);
        return beerList;
    }

    //Generate cart Id
    public static String generateCardId(){
        String CharList = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
        Integer position;
        Integer LengthRequired = 30;
        String Res = '';
        for(Integer i = 0; i <= LengthRequired; i++) {
            position = Integer.valueof(String.valueof(Math.roundToLong(CharList.length()*Math.random()))) -1;
            Res += CharList.substring(position,position+1);
        }
        return Res;
    }

    //Method to get Coupon Id
    public static String getCouponInfo(String name){
        Coupon__c couponData = [SELECT Name,Id,Price__c 
                                FROM Coupon__c
                                WHERE Name = :name
                                WITH SECURITY_ENFORCED];
        
        return couponData.Id;
    }

    //Method to get cart details. Generate new cart if not available or return available cart
    @AuraEnabled(cacheable=false)
    public static String getCartId(){
        list<Cart__c> cartList = [SELECT Id,Name,Cart_Id__c,Cart_Status__c,Is_Active__c,User__c,Coupon__c
                                  FROM Cart__c
                                  WHERE User__c = :UserInfo.getUserId()
                                  AND Cart_Status__c = 'Open'
                                  AND Is_Active__c = true
                                  WITH SECURITY_ENFORCED];
        
        if(cartList != null && cartList.size()>0){
            list<Cart_Item__c> cartItems = [SELECT Beer__c,Cart__c,Item_Amount__c,Item_Quantity__c,Total_Amount__c
                                            FROM Cart_Item__c
                                            WHERE Cart__c = :cartList.get(0).Id
                                            WITH SECURITY_ENFORCED];
            
            
            cartInformationWrapper cartInformation = new cartInformationWrapper();
            cartInformation.cartId = cartList.get(0).Id;
            cartInformation.cartItems = cartItems;
            cartInformation.count = cartItems.size();
            return JSON.serialize(cartInformation);
        }
        else{
            cartInformationWrapper cartInformation = new cartInformationWrapper();
            if(Schema.sObjectType.Cart__c.isAccessible()){
                Cart__c cartRecord = new Cart__c();
                cartRecord.Cart_Id__c = generateCardId();
                cartRecord.Cart_Status__c = 'Open';
                cartRecord.Is_Active__c = true;
                cartRecord.User__c = UserInfo.getUserId();
                cartRecord.Coupon__c = getCouponInfo('Primary');
                insert cartRecord; 

                cartInformation.CartId = cartRecord.Id;
                cartInformation.cartItems = null;
                cartInformation.Count = 0;
                
            }

            return JSON.serialize(cartInformation);
            
        }
    }

    //creat cart item records
    @AuraEnabled
    public static String createCartItem(String cartId,String beerId,Decimal amount){
 // Verify whether cart item already present are not       
      list<Cart_Item__c>  existingItems = [SELECT Cart__c,Item_Quantity__c
                                           FROM Cart_Item__c
                                           WHERE Cart__c = :cartId
                                           AND Beer__c = :beerId];
       
        if(existingItems != null && existingItems.size()>0){
            Cart_Item__c oldItem = existingItems.get(0);
            oldItem.Item_Quantity__c = oldItem.Item_Quantity__c + 1;
            update oldItem;
            return oldItem.Id;
        }
      
 //can be deleted till here       
        else{
            Cart_Item__c cartItem = new Cart_Item__c();
            cartItem.Beer__c = beerId;
            cartItem.Cart__c = cartId;
            cartItem.Item_Amount__c = amount;
            cartItem.Item_Quantity__c = 1;
            insert cartItem;
            return cartItem.Id;
        }
        
    }

    //wrapper class to return cart information of logged in user
    public class cartInformationWrapper {
        @AuraEnabled
        public String cartId {get;set;}

        @AuraEnabled
        public Decimal count {get;set;}

        @AuraEnabled
        public list<Cart_Item__c> cartItems {get;set;}
    }
}
