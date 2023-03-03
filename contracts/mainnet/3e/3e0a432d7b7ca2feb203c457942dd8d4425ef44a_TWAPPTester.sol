// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TWAPPriceGetter.sol";

contract TWAPPTester {

    TWAPPriceGetter private immutable _oracle = TWAPPriceGetter(0xcef1C791CDd8c3EA92D6AB32399119Fd30E1Ff21);
    address private immutable _gov;

    constructor(){
        _gov = msg.sender;
    }

    function getGnsPrice() external view returns(uint256){
        require(msg.sender==_gov,"only gov!!");
        return _oracle.tokenPriceDai();
    }
}