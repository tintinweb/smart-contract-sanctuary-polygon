// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/IPUSHCommInterface.sol";

/* Errors */
error Payments_ZeroBalance();


contract SacPayments {

    event NewTips(
        address indexed from,
        address indexed to,
        uint256 timestamp,
        string message
    );

    struct TipInfo {
        address from;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    mapping(address => TipInfo[]) public profiles;
    mapping(address => uint256) public totalReceived;
    mapping(address => uint256) public totalDonated;

    function tip(address payable tipAddress, string memory message) public payable {
        if(msg.value > 0)
        {
            revert Payments_ZeroBalance();
        }

        profiles[tipAddress].push(TipInfo(msg.sender, msg.value, message, block.timestamp));

        totalReceived[tipAddress] += msg.value;
        totalDonated[msg.sender] += msg.value;

        tipAddress.transfer(msg.value);

        emit NewTips(
            msg.sender,
            tipAddress,
            block.timestamp,
            message
        );

    //     IPUSHCommInterface("0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa").sendNotification(
    //     YOUR_CHANNEL_ADDRESS,
    //     tipAddress,
    //     bytes(
    //         string(
    //             abi.encodePacked(
    //                 "0",
    //                 "+",
    //                 "3",
    //                 "+",
    //                 "You have received a tip - Sendacoin",
    //                 "+",
    //                 "You have received a tip from x Address - Y amount"
    //             )
    //         )
    //     )
    // );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}