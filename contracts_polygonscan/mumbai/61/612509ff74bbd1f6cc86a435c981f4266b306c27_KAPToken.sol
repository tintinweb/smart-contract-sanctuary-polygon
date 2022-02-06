// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./ERC20.sol";
import "./Ownable.sol";

contract KAPToken is ERC20("KAPACITOR", "KAP"), Ownable {
    constructor(address treasury) {
        require(
            treasury != address(0),
            "treasury cannot be the 0 address"
        );
        uint256 supply = 6000000000 ether;
        _mint(treasury, supply);
    }

    function getOwner() external view returns (address) {
        return owner();
    }
}