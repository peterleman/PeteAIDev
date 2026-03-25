import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class IdvInputFields extends LightningElement {
    @api customerNumber = '';
    @api phoneNumber = '';
    @api email = '';

    handleCustomerNumberChange(event) {
        this.customerNumber = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('customerNumber', this.customerNumber));
    }

    handlePhoneNumberChange(event) {
        this.phoneNumber = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('phoneNumber', this.phoneNumber));
    }

    handleEmailChange(event) {
        this.email = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('email', this.email));
    }
}
