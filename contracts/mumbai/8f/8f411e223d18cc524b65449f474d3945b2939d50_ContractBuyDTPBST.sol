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

    function buyToken() payable public nonReentrant {
        uint256 amountToBuy = msg.value;
        require(amountToBuy > 0, "DEX: You need to send some MATIC");
        token.mint(_msgSender(), amountToBuy);
        token.mint(owner(), amountToBuy);
        emit Bought(_msgSender(), amountToBuy);
    }

    receive() external payable {
        buyToken();
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