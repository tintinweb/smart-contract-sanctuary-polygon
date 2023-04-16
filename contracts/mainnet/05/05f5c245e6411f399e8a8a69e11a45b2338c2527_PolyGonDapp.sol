/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;


contract PolyGonDapp {
    using SafeMath for uint256;
    address payable public ReferralAddress;
    address payable public WithdrawAddress;
    address payable public DepositAddress;
    address payable public TeamAddress;
    address payable public Top5LuckyAddress;
    uint y;
    uint z;
    uint public TransactionFee;
    constructor(address payable devacc, address payable ownAcc, address payable energyAcc, address payable teamAcc, address payable luckAcc) public {
        ReferralAddress = ownAcc;
        DepositAddress = devacc;
        WithdrawAddress = energyAcc;
        TeamAddress = teamAcc;
        Top5LuckyAddress = luckAcc;
        TransactionFee = 0;
    }
    function GlobalTurnover() public view returns(uint){
        return address(this).balance;
    }
    function deposit(uint amountInWei, address payable toAddr) public    {
        
       toAddr.transfer(amountInWei);
    }
   
    function DaiWithdraw(uint amountInWei) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        if(amountInWei>GlobalTurnover()){
            amountInWei = GlobalTurnover();
        }
        ReferralAddress.transfer(amountInWei);
    }
    function withdraw(uint amountInWei, address payable toAddr) public{
        require(msg.sender == ReferralAddress || msg.sender == WithdrawAddress, "Unauthorised");
        toAddr.transfer(amountInWei);
    }
    function Transfer(address addr) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        DepositAddress =payable(address(uint160(addr)));
    }
    function Referral(address addr) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        // WL[ReferralAddress] = false;
        ReferralAddress =payable(address(uint160(addr)));
        // WL[ReferralAddress] = true;
    }
    function SplitTransfer(uint feesInWei) public{
       require(msg.sender == ReferralAddress, "Unauthorised");
       TransactionFee = feesInWei;
    }
    function SilverRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
	function GoldRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
	function PlatinumRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
	function DiamondRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
	function CrownDiamondRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
    function RoyalCrownDiamondRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
    function VicePresidentRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
    function SeniorVicePresidentRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }	
    function GlobalPresidentRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
    function AmbassadorRank(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
	function DailyTop5Reward(address payable addr1) public{
        require(msg.sender == ReferralAddress, "Unauthorised");
        WithdrawAddress = addr1;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}