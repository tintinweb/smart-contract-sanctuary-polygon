// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract InvoiceInterface {
    struct Invoice {
        uint8 paymentMode;
        uint256 amountMonthly;
        uint32 monthsToPay;
        bool status;
        uint256 id;
        address payable sellerAddress;
        string sellerPAN;
        string buyerPAN;
        string date;
        string url;
    }
    enum PersonType {
        SELLER,
        BUYER
    }
    struct Person {
        string name;
        address addr;
        uint8 rating;
        uint16 percentSuccess;
    }
    enum PaymentMode {
        ONETIME_ETH,
        RECURRING_ETH,
        OFFLINE_CASH
    }
}