// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./LuckyNumberGenerator.sol";

contract LuckyNumberGeneratorImpl is LuckyNumberGenerator {
    address private _proxy;

    constructor() {}

    modifier onlyProxy() {
        require(msg.sender == _proxy, "Not called from proxy");
        _;
    }

    function setProxy(address proxy) external {
        require(_proxy == address(0), "Proxy already set");
        _proxy = proxy;
    }

    function generateLuckyNumber(Game memory game) external view onlyProxy returns (uint24) {
        require(block.number > game.endBlock, "Too early !!!");
        bytes32 winningNumber = blockhash(game.endBlock);
        return uint24(uint256(winningNumber) & uint256(0xfffff));
    }

    function kill() external onlyProxy {
        selfdestruct(payable(msg.sender));
    }
}