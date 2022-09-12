// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract CrossSwap {

function executeSwap(address payable exchange, uint256 val, bytes memory data) public {
    (bool success,) = exchange.call{value: val }(data);
    require(success, "SWAP_CALL_FAILED");
}
}