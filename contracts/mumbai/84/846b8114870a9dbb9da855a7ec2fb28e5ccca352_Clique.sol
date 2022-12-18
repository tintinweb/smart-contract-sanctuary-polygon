/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

pragma solidity ^0.6.0;
contract Clique{

address public owner;
    
// Set the address of the developer wallet
address payable public developerWallet;

// Set the fee per click
uint256 public clickFee;

// Set the address that will send the payment
address payable public senderAddress;

// Set the amount of the payment
uint256 public paymentAmount;

// Set the number of people that need to click to receive the payment
uint256 public requiredClicks;

// Set the price of a click
uint256 public clickPrice;

// Mapping to store the addresses of the people that have clicked to receive the payment
mapping(address => bool) public clickedAddresses;

// Mapping to store the balances of the clicked addresses
mapping(address => uint256) public clickBalances;

// Event to log when a payment is made
event PaymentMade(address recipient, uint256 amount);

// Constructor to set the sender and payment amount
constructor( uint256 _requiredClicks, uint256 _clickPrice, uint256 _clickFee) public {
     requiredClicks = _requiredClicks;
    clickPrice = _clickPrice;
    developerWallet = 0x62B471a64cfF653fd1d9D9f941fEa288E850D37A;
    clickFee = _clickFee;
    owner = msg.sender;
}

// Function for a person to click to receive the payment
function clickToReceive(uint256 _clickPrice) public payable {
    address[] memory clickedAddressesArray;
    // Check that the caller has not already clicked to receive the payment
    require(!clickedAddresses[msg.sender], "Address has already clicked");
    msg.value == _clickPrice;
    // Check that the caller has paid the correct click price
    require(msg.value >= clickPrice, "Incorrect click price");
    // Mark the caller as having clicked to receive the payment
    clickedAddresses[msg.sender] = true;
    // Update the balance of the caller
    clickBalances[msg.sender] += msg.value;
    // Send the click fee to the developer wallet
    developerWallet.transfer(clickFee);
    // Check if the required number of clicks has been reached
    if (totalClicks() == requiredClicks) {
        // Calculate the payment amount for each recipient
        uint256 paymentPerRecipient = paymentAmount / requiredClicks;
        // Iterate through the clicked addresses and make the payment
       for (uint i = 0; i < clickedAddressesArray.length; i++) {
    address recipient = clickedAddressesArray[i];
    senderAddress.transfer(paymentPerRecipient);
    emit PaymentMade(recipient, paymentPerRecipient);
}
    }
}

// Function to get the total number of clicks
function totalClicks() public view returns (uint256) {
    address[] memory clickedAddressesArray;
    uint256 total = 0;
    // Iterate through the clicked addresses and count the number of clicks
    for (uint i = 0; i < clickedAddressesArray.length; i++) {
    if (clickedAddresses[clickedAddressesArray[i]]) {
        total++;
    }
}
    return total;
}

// Function to set the click price
function setClickPrice(uint256 _clickPrice) public {
    // Check that the caller is the owner of the contract
    require(msg.sender == owner, "Unauthorized caller");
    // Set the click price
    clickPrice = _clickPrice;
}

function setClickFee(uint256 _clickFeePercentage) public {
    // Check that the caller is the owner of the contract
    require(msg.sender == owner, "Unauthorized caller");
    // Set the click price
    uint256 percentage = _clickFeePercentage;
    require(percentage < 5, "Don't be greedy");
    clickFee = (percentage/100)*clickPrice;
}

function setDevAddress(address payable _developerWallet) public {
    // Check that the caller is the owner of the contract
    require(msg.sender == owner, "Unauthorized caller");
    // Set the click price
    developerWallet = _developerWallet;
}

function setPayment (uint256 _depositAmount) public {
    // Check that the caller is the owner of the contract
    require(msg.sender == owner, "Unauthorized caller");
    // Set the click price

    msg.sender.transfer(_depositAmount);
   
}

}