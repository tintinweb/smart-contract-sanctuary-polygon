/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.7;

contract CronTest {

    // deployed on mumbai at: 0x6495C9684Cc5702522A87adFd29517857FC99f45

    bytes32 public currentPrice; 

    // this function is called by the chainlink cron job (see: jobs - CronTest.toml)
    function someFunction(bytes32 _price) public {
        currentPrice = _price;
    }
}