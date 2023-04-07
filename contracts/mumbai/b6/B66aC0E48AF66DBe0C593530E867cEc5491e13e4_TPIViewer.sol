// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IComptroller {
    function claimComp(address) external;
}
interface ITPI {
    function balanceOf(address account) external view returns(uint256);
}

contract TPIViewer {

    function pendingTPI(ITPI tpi, IComptroller comptroller, address account) external returns (uint256) {
        uint256 balance = tpi.balanceOf(account);
        comptroller.claimComp(account);
        uint256 newBalance = tpi.balanceOf(account);
        return newBalance - balance;
    }
}