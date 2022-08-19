//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Ownable.sol";

contract ContractBuyDTPBST is Ownable, ReentrancyGuard {
    DTPBST public token;
    string private _name;

    event Bought(address indexed buyer, uint256 amount);

    constructor() {
        token = new DTPBST();
        token.grantRole(token.ROLE_ADMIN(), _msgSender());
        token.revokeRole(token.ROLE_ADMIN(), address(this));
        _name = "ContractBuyDTPBST";
    }

    receive() external payable {
        require(msg.value >= 1e18, "DEX: You need to send minimum 1 MATIC");
        uint256 amount_ = msg.value / 1e12;
        token.mint(_msgSender(), amount_);
        token.mint(owner(), amount_);
        emit Bought(_msgSender(), amount_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "DEX: new owner is the zero address");
        token.grantRole(token.ROLE_ADMIN(), newOwner);
        token.revokeRole(token.ROLE_ADMIN(), owner());
        _transferOwnership(newOwner);
    }

    function withdrawFonds(address to) external onlyOwner {
        require(to != address(0), "DEX: to is the zero address");
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "DEX: Could not withdraw MATIC");
    }

    function name() public view returns (string memory) {
        return _name;
    }
}