// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the required library to work with ERC20 tokens
import "./IERC20.sol";

contract BabyFloppaSale {
    address public owner; // 0x8Be61D5C4B98776cbF129Ae7eFEC1a6d68658761
    IERC20 public BabyFloppa; // IERC20(0x90f57f1B7F8e78c7E60E0ad1656E7aB5232F62A9)
    uint256 public tokenPrice = 638500000; // Price of 1 BBFP in MATIC (ufixed16x11)

    
    event TokensPurchased(address buyer, uint256 amount);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        BabyFloppa = IERC20(_tokenAddress);
        tokenPrice = 15661707; // 1 MATIC = 15661707 BBFP
    }


    function purchaseTokens() public payable {
        require(msg.value > 0, "Amount sent should be greater than zero");

        uint256 maticAmount = msg.value; // Sent MATIC value

        // Calculate the equivalent amount of BBFP based on the MATIC value and token price
        uint256 tokenAmount = maticAmount * tokenPrice;

        // Transfer the BBFP tokens to the buyer´s wallet
        BabyFloppa.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    // Function to allow the contract owner to withdraw the funds collected during the public sale
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");

        uint256 contractBalance = BabyFloppa.balanceOf(address(this));

        // Transfers the remaining FLOPPA tokens to the contract owner's wallet
        BabyFloppa.transfer(owner, contractBalance);
    }
}