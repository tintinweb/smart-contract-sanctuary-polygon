// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CarbonOffsetMarketplace {
    struct Offset {
        address seller;
        uint256 tonnesCO2;
        uint256 price;
        bool sold;
    }
    
    Offset[] public offsets;
    
    function sellOffset(uint256 tonnesCO2, uint256 price) public {
        offsets.push(Offset({
            seller: msg.sender,
            tonnesCO2: tonnesCO2,
            price: price,
            sold: false
        }));
    }
    
    function buyOffset(uint256 offsetId) public payable {
        Offset storage offset = offsets[offsetId];
        require(!offset.sold, "Offset already sold");
        require(msg.value == offset.price, "Incorrect value sent");
        
        uint256 amount = offset.price;

        (bool sent, ) = payable(offset.seller).call{value : amount}("");

        if(sent) {
             offset.sold = true;

        }
    }
}