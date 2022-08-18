//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";
import "./Ownable.sol";

contract Dex is Ownable, ReentrancyGuard {
    Token public token;

    event Bought(address indexed buyer, uint256 amount);

    constructor() {
        token = new Token("BotSuperTrendToken", "BSTT", _msgSender());
    }

    function buy() payable public nonReentrant {
        uint256 amountToBuy = msg.value;
        require(amountToBuy > 0, "You need to send some MATIC");
        token.mint(_msgSender(), amountToBuy);
        token.mint(owner(), amountToBuy);
        emit Bought(_msgSender(), amountToBuy);
    }

    receive() external payable {
        buy();
    }

    function withdrawFonds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Token: Could not withdraw MATIC");
    }
}