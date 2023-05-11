// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CustomApprove {
    function customApprove(address tokenAddress, bytes memory data) public {
        (bool success, bytes memory returnData) = tokenAddress.call(data);
        require(success, "CustomApprove: Approve call failed");
    }
}