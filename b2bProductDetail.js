/**
 * Created by awalia on 6/13/2021.
 */

import { LightningElement,api } from 'lwc';
import FORRESTER_IMAGES from '@salesforce/resourceUrl/FooterIcons';
import { getConstants, applicationLogging, consoleLogging } from 'c/b2bUtil';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class B2BProductDetail extends LightningElement {
    @api product;
    @api cartId;
    @api productAddedToCart;
    @api isCartLocked;
    @api productCartItem;

    attendeeAdded = false;

    @api setInformation(product,productCartItem){
        this.showSpinner =false;
        this.product = product;
        this.productCartItem = productCartItem;
        setTimeout(() => {
            this.template.querySelector('c-b2b-payment-method').setProductCartItem(productCartItem);
        }, 500);
        this.setProductData(this.product);
    }

    @api hideSpinner(){
        this.showSpinner =false;
    }


    handleCoupon(event){
        this.productCartItem = event.detail;
        if(this.productCartItem && this.productCartItem!=null && this.productCartItem.attendeeAdded){
            //TODO checking this.attendeeAdded = productCartItem.attendeeAdded ;
        }
    }

    qtyValue=1;
    minqtyValue=1;
    maxqtyValue=9999;

    productId;
    productName;
    productSku;
    productDesc;
    productImage;
    productImageSec;
    productCategory;
    unitPrice;
    hasPrice;
    currencyCode;
    startDate;
    endDate;
    registrationStartDate;
    registrationEndDate;

    get isEvent(){
        let ret = false;
        if(this.productCategory === 'Event'){
            ret = true;
        }
        return ret;
    }

    get isCertification(){
            let ret = false;
            if(this.productCategory === 'Certification'){
                ret = true;
            }
            return ret;
        }

    connectedCallback() {
        this._resolveConnected();
        let p = this.product ;
        if(p){
            this.setProductData(p);
        }
        consoleLogging(this.productAddedToCart);
    }

    setProductData(p){

        this.showSpinner =false;
        this.productId = p.productId ;
        this.productName = p.productName ;
        this.productSku = p.productSku ;
        this.productDesc = p.productDesc ;
        consoleLogging( p.productImage);
        this.productImage = p.productImage != null && p.productImage!== '' ? p.productImage : FORRESTER_IMAGES+'/FooterIcons/default.png';
        this.productImageSec = p.productImageSec ;
        this.productCategory = p.productCategory ;
        this.unitPrice = p.unitPrice;
        this.hasPrice = p.priceAvailable ;
        this.currencyCode = p.currencyIsoCode ;
        this.startDate = p.startDateStr;
        this.endDate = p.endDateStr;
        this.registrationStartDate = p.registrationStartDateStr;
        this.registrationEndDate = p.registrationEndDateStr;
        consoleLogging( this.startDate);
        consoleLogging( this.endDate);
        consoleLogging(this.productCartItem);
        if(this.productCartItem)
        {
            this.unitPrice = this.productCartItem.TotalPrice;
            this.qtyValue = this.productCartItem.Quantity;
            this.checkMaxQty();
            this.checkMinQty();
        }
        if(this.productCartItem && this.productCartItem.attendeeAdded){
           //TODO checking this.attendeeAdded = true;
        }else{
            this.attendeeAdded = false;
        }
    }

    handleQuantityIncrement(){
         let qty = this.qtyValue;
         qty++;
         this.qtyValue = qty;
         this.checkMaxQty();
         this.checkMinQty();
         this.notifyUpdateCart();
    }

    handleQuantityDeIncrement(){
             let qty = this.qtyValue;
             qty--;
             this.qtyValue = qty;
             this.checkMaxQty();
             this.checkMinQty();
             this.notifyUpdateCart();
    }

    showSpinner=false;
    disableMinQty;
    disableMaxQty;
    checkMinQty(){
        let qty = this.qtyValue;
        if(qty && qty>this.minqtyValue ){
            this.disableMinQty = false;
        }else{
            this.disableMinQty = true ;
        }
    }

    checkMaxQty(){
        let qty = this.qtyValue;
        if(qty && qty<=this.maxqtyValue){
           this.disableMaxQty = false;
       }else{
           this.disableMaxQty =  true;
       }
    }

    handleCertSelect(event){
         this.showSpinner =true;
        let selectedValue = event.detail;
        this.dispatchEvent(
           new CustomEvent('certselect', {
               detail: selectedValue
           })
       );
    }
    handleQuantityChange(event){

        if (event.target.validity.valid && event.target.value) {
            let qty = event.target.value;
            if(qty && qty>0){
                this.qtyValue = qty;
                this.notifyUpdateCart();

            }
        }
        this.checkMaxQty();
        this.checkMinQty();
    }

    notifyUpdateCart(event) {
        this.showSpinner =true;
        let quantity = this.qtyValue;
        let detailMap = {};
        detailMap.quantity = quantity ;
        this.dispatchEvent(
            new CustomEvent('updatecart', {
                detail: detailMap
            })
        );
    }

    addToCartQtyChange(event){
        if (event.target.validity.valid && event.target.value) {
            this.qtyValue = event.target.value;
        }
    }

    notifyAddToCart(){
        let quantity = this.qtyValue;
        let detailMap = {};
        detailMap.quantity = quantity ;
        this.showSpinner =true;
        this.dispatchEvent(
            new CustomEvent('addtocart', {
                detail: detailMap
            })
        );
    }

    _resolveConnected;
    _connected = new Promise((resolve) => {
        this._resolveConnected = resolve;
    });

    disconnectedCallback() {
        this._connected = new Promise((resolve) => {
            this._resolveConnected = resolve;
        });
    }

    get isDesktop() {
        return FORM_FACTOR === 'Large';
    }     

}