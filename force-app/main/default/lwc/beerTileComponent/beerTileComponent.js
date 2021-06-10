import { LightningElement,api } from 'lwc';

export default class BeerTileComponent extends LightningElement {
    @api beerInfo

    addToCartHandler(){
 //       console.log('beer id in child',this.beerInfo.Id)
        this.dispatchEvent(new CustomEvent('addcart',{detail : this.beerInfo.Id}))
    }
}