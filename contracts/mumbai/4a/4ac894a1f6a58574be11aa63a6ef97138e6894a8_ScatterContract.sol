/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract ScatterContract {
    token public DAI = token(0x25Ca4E40c20c6e5a2e5eF7E8b207F94C4DfF1981);

    address a1;
    address a2;
    address a3;

    constructor(address _a1, address _a2, address _a3) {
        a1 = _a1;
        a2 = _a2;
        a3 = _a3;
    }

    function withdraw() public {
        uint256 balance = DAI.balanceOf(address(this));
        DAI.transfer(a1, balance / 3);
        DAI.transfer(a2, balance / 3);
        DAI.transfer(a3, balance / 3);
    }
}