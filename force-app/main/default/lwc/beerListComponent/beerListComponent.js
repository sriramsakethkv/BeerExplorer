import { LightningElement,wire} from 'lwc';
import searchBeerRecords from '@salesforce/apex/beerSearchController.searchBeerRecords'
import getCartId from '@salesforce/apex/beerSearchController.getCartId'
import cartImage from '@salesforce/resourceUrl/cartImage'
import createCartItem from '@salesforce/apex/beerSearchController.createCartItem'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class BeerListComponent extends LightningElement {
    searchString
    resultBeerArray
    cartId
    cartItemsCount=0
    cart = cartImage;
    connectedCallback(){
        this.generateCartId();
    }

    // Get Beer records on page load
    @wire(searchBeerRecords)
    wiredData({data,error}){
//        console.log('wired data is',data)
        this.resultBeerArray = data;
    }
    // Get Beer records based on search string
    searchHandler(event){
        this.searchString = event.detail;
//        console.log('search string is ', this.searchString);

        searchBeerRecords({searchString : this.searchString})
        .then(result=> {
//            console.log('result is ',result)
            this.resultBeerArray = result
        })
    }

    //Get cart Id of logged in user. If exists, get existing Id else get new Id
    generateCartId(){
        getCartId()
        .then(result => {
            const data = JSON.parse(result);
            this.cartId = data.cartId;
            this.cartItemsCount = data.count;
        })
    }

    //Method to handle add to cart functionality
    handleAddCart(event){
        const beerId = event.detail;
//        this.cartItemsCount = this.cartItemsCount+1;

        const amount = this.resultBeerArray.find(record => record.Id === beerId)

        createCartItem({
            cartId : this.cartId,
            beerId : beerId,
            amount : amount.Price__c
        })
        .then(result=> {
//            console.log('cart item id is',result)
            this.cartItemsCount = this.cartItemsCount+1
            const toast = new ShowToastEvent({
                title : 'Success',
                message : amount.Name+' added to cart',
                variant : 'success'
            })
            this.dispatchEvent(toast);
        })

        
    }
}