/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Abstract
interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CrowdFunding{

    USDC public USDc;

    mapping(address=>uint) public contributors; //contributors[msg.sender]=100
    address payable public owner; 
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public sellingTarget;
    uint public raisedAmount;
    uint public noOfContributors;

    constructor(address _usdcContractAddress, uint _target, uint _deadline, uint _minimumContribution){
        USDc = USDC(_usdcContractAddress);
        target=_target;
        deadline=block.timestamp+_deadline; //10sec + 3600sec (60*60)
        minimumContribution= _minimumContribution;
        owner= payable(msg.sender);
    }

    // All Modifiers starts here --------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function.");
        _;
    }

    modifier isDeadlinePassed() {
        require(
            block.timestamp < deadline,
            "Crowd Funding deadline has passed. Please try again later."
        );
        _;
    }

    modifier isContributor() {
        require(contributors[msg.sender] > 0, "Sorry, you are not a contributor. Try to contribute to crowd funding then try again. Thanks.");
        _;
    }

    // All Modifiers Ends here --------------------------------------------------

    // get USDC balance
    function getContractBalanceUSDC() public view returns(uint){
        return USDc.balanceOf(address(this));
    }

    // Contribute
    function contribute(uint _amountUSDC) public payable isDeadlinePassed {
        require(
            _amountUSDC >= minimumContribution,
            "Minimum 100 USDC is required to contribute."
        );

        // Transfer USDC to this contract from the sender account
        USDc.transferFrom(msg.sender, address(this), _amountUSDC * 10 ** 6);  

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }

        contributors[msg.sender] += (_amountUSDC * 10 ** 6);
        raisedAmount+=(_amountUSDC * 10 ** 6);
    }

    // Refund the money if the target is not fulfilled and deadline has passed.
    function refund() public {
        require(block.timestamp>deadline && raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address user=(msg.sender);
        //user.transfer(contributors[msg.sender]);
        USDc.transfer(user, contributors[msg.sender]);  
        contributors[msg.sender]=0;
    }

    function getAllFund() public onlyOwner {
        USDc.transferFrom(address(this), owner, USDc.balanceOf(address(this)));
    }

    //GOOD transfer fund from smart contract to owner
    function receiveAllFund() public onlyOwner {
        USDc.transfer(owner, USDc.balanceOf(address(this)));  
    }


    function receiveFund(uint _amountUSDC) public onlyOwner {
        USDc.transfer(owner, _amountUSDC);  
    }

    function purchase(uint _amountUSDC) public {
        require(
            _amountUSDC>=sellingTarget,
            "please check the minimum sale price."
            );
        
        // Transfer USDC to this contract from the sender account
        USDc.transferFrom(msg.sender, address(this), _amountUSDC * 10 ** 6);  
    }

    function setSellingTarget(uint _sellingTarget) public onlyOwner {
        sellingTarget = _sellingTarget;  
    }

}