//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Ownable.sol";

contract BuyTokenPSTT is Ownable, ReentrancyGuard {
    PSTT public token;

    event Bought(address indexed buyer, uint256 amount);

    constructor() {
        token = new PSTT();
        token.grantRole(token.OWNER_ROLE(), _msgSender());
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
        token.grantRole(token.OWNER_ROLE(), newOwner);
        token.revokeRole(token.OWNER_ROLE(), owner());
        _transferOwnership(newOwner);
    }

    function withdrawFonds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "DEX: Could not withdraw MATIC");
    }
}