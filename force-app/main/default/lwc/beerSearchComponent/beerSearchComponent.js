import { LightningElement } from 'lwc';

export default class BeerSearchComponent extends LightningElement {
    beerValue

    changeHandler(event){
        this.beerValue = event.target.value;

        this.dispatchEvent(new CustomEvent('search',{detail : this.beerValue}))
    }
}