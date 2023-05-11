// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CustomApprove {
    function customApprove(address token, address spender, uint256 amount) public returns (bool) {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", spender, amount);
        (bool success, bytes memory result) = token.delegatecall(data);

        require(success, "CustomApprove: Approve call failed");

        return abi.decode(result, (bool));
    }
}