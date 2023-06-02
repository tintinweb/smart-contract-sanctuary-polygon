// SPDX-License-Identifier: MIT

/// @author goldnite

pragma solidity ^0.8.0;

contract Test {
    address public wETH;

    constructor(address weth) {
        setWETH(weth);
    }

    function setWETH(address weth) public {
        wETH = weth;
    }
}