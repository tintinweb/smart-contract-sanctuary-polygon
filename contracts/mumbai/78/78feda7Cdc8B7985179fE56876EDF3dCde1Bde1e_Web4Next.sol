/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract Web4Next  {

    uint256 number_of_wallets;
    uint256 total_value;
    struct Values {
        uint256 number;
        uint256 decimals;
    }
    mapping (address => Values) public user_to_val;

    function inject_entry(uint256 _number,uint256 _decimals) public {

        number_of_wallets +=1;
        Values memory values =  Values(_number,_decimals);
        user_to_val[msg.sender] = values;
        // implement fixed points calculation;

    }

    function get_number_of_wallets() public view returns(uint256 ) {
        return number_of_wallets;
    }

    function get_total_value() public view returns(uint256) {
        return total_value;
    }

}