// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./mintmepromo.sol";

contract MintMeUser
{
    MintMePromo private _promo;

    constructor(MintMePromo promo)
    {
        _promo = promo;
    }

    function buy(address referrer) public payable
    {
        _promo.buy{value: msg.value}(referrer);
    }
}

contract MintMePromoFactory is Context
{
    using Address for address payable;

    MintMePromo public _promo;
    address     public _referrer;

    event Deployed();

    constructor(address promo)
    {
        _promo = MintMePromo(promo);
        _referrer = _msgSender();
        emit Deployed();
    }

    function buy() public payable
    {
        uint256 amount = msg.value;
        while(amount >= _promo.price())
        {
            uint256 price = _promo.price();
            amount -= price;
            MintMeUser u = new MintMeUser(_promo);
            u.buy{value: price}(_referrer);
        }
        if (amount > 0)
        {
            payable(_msgSender()).sendValue(amount);
        }
    }
}