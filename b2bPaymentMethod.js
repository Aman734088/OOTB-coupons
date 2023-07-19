/**
 * Created by awalia on 6/14/2021.
 */

import {
    LightningElement,
    api,track
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    NavigationMixin
} from 'lightning/navigation';
// import basePath from '@salesforce/community/basePath';
import {
    applicationLogging,
    consoleLogging
} from 'c/b2bUtil';
import savePaymentData from '@salesforce/apex/B2BCartController.savePaymentData';
import applyCoupon from '@salesforce/apex/B2BCartController.applyCoupon';
import removeCoupon from '@salesforce/apex/B2BCartController.removeCoupon';
import communityId from '@salesforce/community/Id';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import getCoupons from '@salesforce/apex/B2BCouponHelper.getCoupons';

export default class B2BPaymentMethod extends NavigationMixin(LightningElement) {
    @api canCheckOut;
    @api productAddedToCart;
    @api cartId;
    @api productCategory;
    @api productCartItem;
    @api communityId = communityId;
    @track cartcoupons = [];
    errorMsg;

    paymentMethods;
    userEmail = '';
    selectedPaymentMethod = '';
    showVoucherCode = true;
    couponValue = false;
    isPPT = false;
    isSU = false;
    pptCode = '';
    suCode = '';
    voucherCodeValue = '';
    showSpinner = false;

    payMethodChange(event) {
        let val = event.detail.value;
        this.selectedPaymentMethod = val;
        this.handlePmChange(val);
    }

    handlePmChange(val) {
        if (val === 'Pre-Purchased Ticket') {
            this.isPPT = true;
        } else {
            this.isPPT = false;
        }

        if (val === 'Service Units') {
            this.isSU = true;
        } else {
            this.isSU = false;
        }

        if (val === 'Credit Card')
        {
            this.showVoucherCode = true;
        }
        else
        {
            this.showVoucherCode = false;
        }
        
        this.savePaymentData(false);
        
    }

    emailChange(event) {
        this.userEmail = event.target.value;
    }

    redirectToCheckout() {
        let pageRef = {
                type: 'standard__webPage',
                    attributes: {
                        url: '/checkout/' + this.cartId
                    }
            };
        this[NavigationMixin.Navigate](pageRef);
    }

    proceedToCheckOut() {
        if (this.validationData()) {
            this.savePaymentData(true);
        }
    }
    savePaymentData(redirect) {
        let isCouponApplied = false;
        if(this.productCartItem && this.productCartItem.Coupon__c !=null && this.productCartItem.Coupon__c !==''){
            isCouponApplied = true;
        }
        let reqData = {
            'cartId': this.cartId,
            'selectedPaymentMethod': this.selectedPaymentMethod,
            'pptCode': this.pptCode,
            'couponValue': this.voucherCodeValue,
            'isCouponApplied':isCouponApplied,
            'doValidate':redirect
        }
        this.showSpinner = true;
        savePaymentData({
            'dataMap': reqData
        }).then((result) => {
            consoleLogging(result);
            this.showSpinner = false;
            result.isRedirect = redirect;
            this.handlePaymentDataResponse(result);
            if (result && result.log) {
                applicationLogging(result.log);
            }
        }).catch((e) => {
            consoleLogging(e);
        });
    }

    handlePaymentDataResponse(result) {
        if (result && result.isSuccess) {
            this.errorMsg = null;
            if(result.isRedirect){
                this.redirectToCheckout();
            }else{
                this.handleCouponResponse(result);
            }
        } else {
            if(result.msg == null || result.msg==''){
                result.msg = 'Some error occured while adding item to cart, Please contact forrester support.';
            }
            this.errorMsg = result.msg;
            //this.showToast('Error', result.msg, 'error','sticky');
        }
    }

    pptChange(event) {
        this.pptCode = event.target.value;
    }

    vcChange(event) {
        this.voucherCodeValue = event.target.value;
        
    }

    applyCoupon(){
        if(this.selectedPaymentMethod && this.selectedPaymentMethod!=null && this.selectedPaymentMethod!=''){
            let vcCode = this.voucherCodeValue ;
            if(vcCode && vcCode!==''){
                let reqData = {
                    'cartId': this.cartId,
                    'couponValue': this.voucherCodeValue,
                    'communityId': this.communityId
                };
                this.showSpinner = true;
                applyCoupon({
                    'dataMap': reqData
                }).then((result) => {
                    this.showSpinner = false;
                    console.log('line165 result-->'+ JSON.stringify(result));
                    console.log('line167 couponvalue-->'+ JSON.stringify(result.cartcoupons));
                    // this.cartcoupons = result.cartcoupons;
                    consoleLogging(result);
                    if(result.isSuccess){
                        this.showToast('Coupon Applied!', result.message, 'success');
                        this.handleCouponResponse(result);
                        this.fetchCartCoupons();
                    }else{
                        this.showToast('Error', result.message, 'error');
                    }
                    if (result && result.log) {
                        applicationLogging(result.log);
                    }
                }).catch((e) => {
                    consoleLogging(e);                                                                                                                                                                                                                                                      
                });
            }
        }else{
            this.showToast('Error', 'Please select the Payment method', 'error');
        }
    }

    @api setProductCartItem(productCartItem){                              
        this.productCartItem = productCartItem ;
        this.handleProductCartItem(productCartItem);
        this.fetchCartCoupons();
    }

    handleCouponResponse(result){
        this.productCartItem = result.productCartItem ;
        this.dispatchEvent(
            new CustomEvent('couponupdate', {
                detail: result.productCartItem
            })
        );
    }

    cancelErr(){
        this.errorMsg = null;
    }
    fetchCartCoupons(){
        this.couponValue = false;
        let reqData = {
            'cartId': this.cartId,
            'communityId': this.communityId
        }
        this.showSpinner = true;
        getCoupons({
            'params': reqData
        }).then((result)=>{
            this.showSpinner = false;
            console.log('line 219 result get coupon-->'+ JSON.stringify(result));
            this.cartcoupons = [];
            let couponArray = result.cartCoupons.coupons;
            for (let index = 0; index < couponArray.length; index++) {
                const element = couponArray[index];
                this.cartcoupons.push(element.couponCode);             
            }
            if (this.cartcoupons.length > 0) 
            {
                this.couponValue = true;
            }
             console.log('cartcoupns-->'+ this.cartcoupons);
        }).catch((e) => {
            console.log(e);
        });


    }

    removeCoupon(){
       // let vcCode = this.voucherCodeValue ;
       let vcCode = this.cartcoupons[0];
        if(vcCode && vcCode!==''){
            let reqData = {
                'cartId': this.cartId,
                'couponValue':vcCode,
                'communityId': this.communityId
            }
            this.showSpinner = true;
            removeCoupon({
                'dataMap': reqData
            }).then((result) => {
                this.showSpinner = false;
                console.log('line 219 result remove coupon-->'+ JSON.stringify(result));
                consoleLogging(result);
                if(result.isSuccess){
                    this.showToast('Coupon removed !', result.message, 'success');
                    // this.cartcoupons = '';                         
                    this.handleCouponResponse(result);
                    this.fetchCartCoupons();
                }else{
                    this.showToast('Error', result.message, 'error');
                }
                if (result && result.log) {
                    applicationLogging(result.log);
                }
            }).catch((e) => {
                consoleLogging(e);
            });
        }
    }

    validationData() {
        let userEmail = this.userEmail;
        let pptCode = this.pptCode;
        let selectedPaymentMethod = this.selectedPaymentMethod;
        const isInputsCorrect = [...this.template.querySelectorAll('input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
            if(this.selectedPaymentMethod && this.selectedPaymentMethod!=null && this.selectedPaymentMethod!=''){
                return true;
            }else{
                this.showToast('Error', 'Please select the Payment method', 'error');
            }
            
        }

    }

    showToast(title, message, variant,mode) {
        if(!mode){
            mode = 'dismissable'
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            })
        );
    }

    connectedCallback() {
        if (this.productCategory === 'Certification') {
            this.paymentMethods = [{
                    label: 'Credit card and/or discount voucher',
                    value: 'Credit Card'
                },
                {
                    label: 'Pre-purchased code',
                    value: 'Pre-Purchased Ticket'
                }
            ];
        } else {
            this.paymentMethods = [{
                label: 'Credit card and/or discount voucher',
                value: 'Credit Card'
                },
                {
                    label: 'Service units',
                    value: 'Service Units'
                },
                {
                    label: 'Pre-purchased code',
                    value: 'Pre-Purchased Ticket'
                }
            ];
            
        }
        let pc = this.productCartItem;
        this.handleProductCartItem(pc);
        
    }

    handleProductCartItem(pc){
        if (pc ) {
            if(pc.Cart.Payment_Method__c && pc.Cart.Payment_Method__c !== ''){
                this.selectedPaymentMethod = pc.Cart.Payment_Method__c;
                this.handlePmChange(pc.Cart.Payment_Method__c);
                if (this.selectedPaymentMethod === 'Pre-Purchased Ticket' && pc.Cart.Access_Group__r) {
                    this.pptCode = pc.Cart.Access_Group__r.Web_Registration_Id__c;
                }
            }
            if(pc.Coupon__c && pc.Coupon__c !== '')
            {
                this.voucherCodeValue =  pc.Coupon__r.Coupon_Code__c ;
            }
        }
    }
    
}