// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;



/* Errors */

error Payments_AmntLessMin();

contract SacPayments {

    struct TipInfo {
        address user;
        uint256 amount;
    }

     mapping(address => TipInfo[]) public profiles;
    mapping(address => uint256) public totalReceived;
    mapping(address => uint256) public totalDonated;

    function tip(address payable tipAddress) public payable {

        profiles[tipAddress].push(TipInfo(msg.sender, msg.value));

        totalReceived[tipAddress] += msg.value;
        totalDonated[msg.sender] += msg.value;

        tipAddress.transfer(msg.value);

    }


    function getTipsHistory(address userAddress ) public view returns (TipInfo[] memory){
            uint256 length = profiles[userAddress].length;

            TipInfo[] memory ret = new TipInfo[](length);

            for (uint i = 0; i < length; i++) {
                ret[i] = profiles[userAddress][i];
            }

            return ret;
    }

}