// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import the required library to work with ERC20 tokens
import "./IERC20.sol";

contract FloppaCoinSale {
    address public owner; // 0x8Be61D5C4B98776cbF129Ae7eFEC1a6d68658761
    IERC20 public FloppaCoin; // IERC20(0x4d4ee07e77E1DFe7554B8fcbB7A31d6E99D5Ff9A)
    
    event TokensPurchased(address buyer, uint256 amount);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        FloppaCoin = IERC20(_tokenAddress);
    }


    function purchaseTokens() public payable {
        require(msg.value > 0, "Amount sent should be greater than zero");

        uint256 ethAmount = msg.value; // Sent ETH value

        // Calculate the equivalent amount of FLOPPA tokens based on the ETH value
        uint256 tokenAmount = calculateTokenAmount(ethAmount);

        // Transfers the FLOPPA tokens to the buyer's wallet
        IERC20(FloppaCoin).transferFrom(owner, msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function calculatetokenAmount(uint256 ethAmount) internal pure returns (uint256) {
        // Assuming 1 ETH is equivalent to 390000000 FLOPPA tokens
    uint256 tokenAmount = ethAmount * 390000000;
    return tokenAmount;
    }
    
    function buyTokensWithMATIC(uint256 maticAmount) public {
        require(maticAmount > 0, "Amount sent should be greater than zero");

        // Calculate the equivalent amount of FLOPPA tokens based on the MATIC value
        uint256 tokenAmount = calculateTokenAmount(maticAmount);

        // Transfer the specified amount of MATIC from the buyer's wallet to this contract
        FloppaCoin.transferFrom(msg.sender, address(this), maticAmount);

        // Transfers the equivalent amount of FLOPPA tokens to the buyer's wallet
        FloppaCoin.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    // Function to calculate the equivalent amount of FLOPPA tokens based on the value sent
    function calculateTokenAmount(uint256 maticAmount) internal pure returns (uint256) {
        // Assuming 1 MATIC is equivalent to 138400 FLOPPA tokens
    uint256 tokenAmount = maticAmount * 138400;
    return tokenAmount;
    }

    // Function to allow the contract owner to withdraw the funds collected during the public sale
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");

        uint256 contractBalance = FloppaCoin.balanceOf(address(this));

        // Transfers the remaining FLOPPA tokens to the contract owner's wallet
        FloppaCoin.transfer(owner, contractBalance);
    }
}