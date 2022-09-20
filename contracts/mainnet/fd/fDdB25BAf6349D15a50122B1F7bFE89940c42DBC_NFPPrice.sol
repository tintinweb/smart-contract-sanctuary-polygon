/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

pragma solidity ^0.8.0;


contract NFPPrice{

    constructor() {
    }

    function mintPrice(uint256 number) external pure returns(uint256 price){
        for (uint256 i=1; i<105; i++) {
            if (number < i * 10000){
                return i * 1000000000000000000;
            }
        }
        return 1000000000000000000000;
    }

    function transferFee(uint256 price) external pure returns(uint256 fee){
        return price / 100 * 3;
    }
}