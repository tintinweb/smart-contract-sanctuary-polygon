/*
This file is part of the MintMe project.

The MintMe Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The MintMe Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the MintMe Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

// To interact with this contract visit https://mintme.global/promo

pragma solidity ^0.8.0;

import "./mintme.sol";


contract MintMePromo is Ownable, ReentrancyGuard
{
    using Address for address payable;

    event PromoSaleStarted(uint256 supply, uint256 price);
    event PromoterAdded(address indexed promoter, address indexed referrer);
    event Bought(address indexed promoter, uint256 cost, uint256 price, address indexed actualReferrer);
    event Sold(address indexed promoter, uint256 price);

    struct Promouter
    {
        bool    found;
        address referrer;
        bool    hasToken;
        uint256 tokenPrice;
        uint256 restForUnlock;
        uint256 singleContribution;
    }

    uint256 public totalSupply;
    uint256 public availableSupply;
    uint256 public price;
    uint256 public lastAction;
    mapping (address => Promouter) public promouters;

    constructor ()
    {
        price = 0;
        totalSupply = 100;
        availableSupply = totalSupply;
        emit PromoSaleStarted(availableSupply, price);
    }

    function sell(address mintme) public nonReentrant
    {
        MintMe mm = MintMe(mintme);
        Promouter storage p = promouters[_msgSender()]; 
        require(p.hasToken, "MintMePromo: Nothing to sell");
        require(p.restForUnlock == 0, "MintMePromo: Not enought referrals purchases");
        require(mm.owner() == _msgSender(), "MintMePromo: You do not own the collection");
        require(mm.balanceOf(_msgSender()) > 0, "MintMePromo: No tokens inside your collection");
        uint256 value = p.tokenPrice;
        p.tokenPrice = 0;
        p.hasToken = false;
        p.singleContribution = 0;
        payable(_msgSender()).sendValue(value);
        emit Sold(_msgSender(), value);
        lastAction = block.timestamp;
    }

    function buy(address referrer) public payable
    {
        Promouter storage p = promouters[_msgSender()]; 
        require(!p.hasToken, "MintMePromo: the only token for single person is available");
        if (price == 0)
        {
            payable(_msgSender()).sendValue(msg.value);
            p.found = true;
            p.hasToken = true;
            p.tokenPrice = 6 ether / 10;
            p.restForUnlock = 3;
            p.singleContribution = p.tokenPrice / p.restForUnlock;
            emit PromoterAdded(_msgSender(), address(0));
            emit Bought(_msgSender(), 0, p.tokenPrice, address(0));
        }
        else
        {
            require(msg.value >= price, "MintMePromo: not enough funds");
            if (!p.found)
            {
                require(promouters[referrer].found, "MintMePromo: Referrer not found");
                p.found = true;
                p.referrer = referrer;
                emit PromoterAdded(_msgSender(), referrer);
            }
            p.hasToken = true;
            p.restForUnlock = 3;
            p.tokenPrice = price * p.restForUnlock;
            p.singleContribution = price; //p.tokenPrice / p.restForUnlock;

            address actualReferrer = address(0);
            uint256 valueToReferrer = 0;
            address iterator = p.referrer;
            while(actualReferrer == address(0) && iterator != address(0))
            {
                Promouter storage r = promouters[iterator];
                if (r.hasToken && r.restForUnlock > 0)
                {
                    actualReferrer = iterator;
                    r.restForUnlock--;
                    valueToReferrer = r.singleContribution;
                }
                iterator = r.referrer;
            }
            if (valueToReferrer < msg.value)
            {
                payable(owner()).sendValue(msg.value - valueToReferrer);
            }
            emit Bought(_msgSender(), price, p.tokenPrice, actualReferrer);
        }
        availableSupply--;
        if (availableSupply == 0)
        {
            totalSupply *= 2;
            price = (price == 0) ? 2 ether / 10 : price * 2;
            availableSupply = totalSupply;
            emit PromoSaleStarted(totalSupply, price);
        }
        lastAction = block.timestamp;
    }

    function finish() public onlyOwner
    {
        require(block.timestamp - lastAction > 30 days, "MintMePromo: promo is in progress");
        selfdestruct(payable(_msgSender()));
    }
}