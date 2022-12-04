/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// File: contracts/Fundme.sol


pragma solidity ^0.8.0;

contract FundMe {
    uint256 public amount;
    mapping (address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    

    constructor() {
        owner = msg.sender;
    }

function Amount(uint256 _amount) external virtual {
    amount = _amount;
}

function retrieve() external view returns (uint256){
    return amount;
}

function fund() public payable {
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
}


modifier onlyOwner {
    require(msg.sender == owner, 'Sender is not owner!'); 
    _;
}
function withdraw() public onlyOwner {
    for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
        address funder = funders[funderIndex];
        addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);

    (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
}
  fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

}