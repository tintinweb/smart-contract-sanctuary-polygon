// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter_flattened.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 0.001 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    function fund() public payable{
        // Want to be able to set a minimum fund amout in USD
        // 1. How do we sent ETH to this contract?
        require(msg.value.getMaticConversionRate()  > MINIMUM_USD, "Didn't send enough token");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    // A modifier is used to modify the behavior of a fucntion
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != i_owner) { revert NotOwner();}
        _;
    }
    
    function withDraw() public onlyOwner {
       for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
           address funder = funders[funderIndex];
           addressToAmountFunded[funder] = 0;
       }
       // reset the array
       funders = new address[](0);

        // transfer :
        // payable(msg.sender).transfer(address(this).balance);

        // send :
        // bool sendSucess = payable(msg.sender).send(address(this).balance);
        // require(sendSucess, "Send failed");

        // call :
        (bool callSucess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSucess, "Call failed");
    }

    /* A contract can now have only one receive function that is declared with the syntax 
    receive() external payable {…} (without the function keyword).
    It executes on calls to the contract with no data (calldata), such as calls made via send() or transfer().
    */
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }


    

}