/**
 *Submitted for verification at polygonscan.com on 2022-11-18
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
    address payable public  manager; 
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;
   

    constructor(uint _target, address _usdcContractAddress){
        USDc = USDC(_usdcContractAddress);
        target=_target;
        //deadline=block.timestamp+_deadline; //10sec + 3600sec (60*60)
        // minimumContribution=100 wei;
        manager= payable(msg.sender);
    }

    function wFund(uint $USDC) public payable {

        // Transfer USDC to this contract from the sender account
        USDc.transferFrom(msg.sender, address(this), $USDC * 10 ** 6);  

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+= ($USDC * 10 ** 6);
        raisedAmount+=($USDC * 10 ** 6);

    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function wgetRaisedAmount() public view returns(uint){
        return raisedAmount;
    }

    function wgetContractBalance() public view returns(uint){
        return USDc.balanceOf(address(this));
    }

    function refund() public {
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    function getAllFund() public onlyManger {
        USDc.transferFrom(address(this), manager, USDc.balanceOf(address(this)));
    }

    receive() payable external {
        manager.transfer(address(this).balance);
     } 

    modifier onlyManger(){
        require(msg.sender==manager,"Only manager can calll this function");
        _;
    }

}