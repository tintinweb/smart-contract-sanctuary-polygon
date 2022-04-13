// SPDX-License-Identifier: MIT

//This is a vesting contract for ISLAMI token, with monthly percentage claims after total locking


import "./ISLAMICOIN.sol";

pragma solidity = 0.8.13;

contract ISLAMIvesting2 {
    using SafeMath for uint256;
    ISLAMICOIN public ISLAMI;
    address private owner;
    uint256 Sonbola = 10**7;
    uint256 public constant monthly = 30 days;
    uint256 public investorCount;
    uint256 private IDinvestor;
    uint256 public investorVault;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event ISLAMIClaimed(address Investor, uint256 Amount);
    event ChangeOwner(address NewOwner);
    event WithdrawalMatic(uint256 _amount, uint256 decimal, address to); 
    event WithdrawalISLAMI(uint256 _amount,uint256 sonbola, address to);
    event WithdrawalERC20(address _tokenAddr, uint256 _amount,uint256 decimals, address to);
    
    struct VaultInvestor{
        uint256 investorID;
        uint256 amount;
        uint256 monthLock;
        uint256 monthAllow;
        uint256 lockTime;
        uint256 timeStart;
    }
 
    mapping(address => bool) public Investor;
    mapping(uint => address) public InvestorCount;
    mapping(address => VaultInvestor) public investor;

    modifier onlyOwner (){
        require(msg.sender == owner, "Only ISLAMICOIN owner can add Investors");
        _;
    }

    modifier isInvestor(address _investor){
        require(Investor[_investor] == true);
        _;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    constructor(ISLAMICOIN _ISLAMI) {
        owner = msg.sender;
        investorCount = 0;
        IDinvestor = 0;
        ISLAMI = _ISLAMI;
        _status = _NOT_ENTERED;
    }
    function transferOwnership(address _newOwner)external onlyOwner{
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }

    function addInvestor(address _investor, uint256 _amount, uint256 _lockTime, uint256 _monthAllow) external onlyOwner{
        require(Investor[_investor] != true, "Investor Already exist!");
        uint256 amount = _amount.mul(Sonbola);
        require(ISLAMI.balanceOf(address(this)) >= investorVault.add(amount));
        uint256 lockTime = _lockTime.mul(1 days);
        require(amount > 0, "Amount cannot be zero!");
        require(_monthAllow != 0, "Percentage cann't be equal to zero!");
        require(lockTime > monthly.mul(3), "Please set a time in the future more than 90 days!");
        uint256 monthCount = (lockTime.div(monthly));
        uint256 amountAllowed = amount.mul(_monthAllow).div(100);
        require(amount >= amountAllowed.mul(monthCount), "Operation is not legit please do proper calculations");
        IDinvestor++;
        investor[_investor].investorID = IDinvestor;
        investor[_investor].amount = amount;
        investor[_investor].lockTime = lockTime.add(block.timestamp);
        investor[_investor].monthAllow = _monthAllow;
        investor[_investor].timeStart = block.timestamp;
        investor[_investor].monthLock = lockTime.add(block.timestamp);
        Investor[_investor] = true;
        investorVault += amount;
        investorCount++;
    }
    function claimMonthlyAmount() external isInvestor(msg.sender) nonReentrant{
        uint256 totalTimeLock = investor[msg.sender].monthLock;
        uint256 remainAmount = investor[msg.sender].amount;
        require(totalTimeLock <= block.timestamp, "Your need to wait till your token get unlocked");
        require(remainAmount > 0, "You don't have any tokens");
        uint256 percentage = investor[msg.sender].monthAllow;   
        uint256 amountAllowed = remainAmount.mul(percentage).div(100);
        uint256 _investorID = investor[msg.sender].investorID;
        investor[msg.sender].amount = remainAmount.sub(amountAllowed);
        investor[msg.sender].monthLock += monthly;
        investorVault -= amountAllowed;
        if(investor[msg.sender].amount == 0){
            Investor[msg.sender] = false;
            delete investor[msg.sender];
            delete InvestorCount[_investorID];
            investorCount--;
        }
        emit ISLAMIClaimed(msg.sender, amountAllowed);
        ISLAMI.transfer(msg.sender, amountAllowed);
    }
    function claimRemainings() external isInvestor(msg.sender) nonReentrant{
        uint256 totalTimeLock = investor[msg.sender].lockTime.add(365 days);
        require(totalTimeLock <= block.timestamp, "You can't claim you remaining yet!");
        uint256 remainAmount = investor[msg.sender].amount;
        uint256 _investorID = investor[msg.sender].investorID;
        investor[msg.sender].amount = 0;
        investorVault -= remainAmount;
        Investor[msg.sender] = false;
        delete investor[msg.sender];
        delete InvestorCount[_investorID];
        emit ISLAMIClaimed(msg.sender, remainAmount);
        ISLAMI.transfer(msg.sender, remainAmount);
        investorCount--;
    }
    function returnInvestorLock(address _investor) public view returns(uint256 _amount, uint256 timeLeft){
        _amount = investor[_investor].amount;
        timeLeft = (investor[_investor].lockTime.sub(block.timestamp)).div(1 days);
        return(_amount, timeLeft);
    }
    function returnInvestorMonthLock(address _investor) public view returns(uint256 _amount, uint256 timeLeft){
        uint256 monthAllowed = investor[_investor].monthAllow;
        _amount = investor[_investor].amount.mul(monthAllowed).div(100);
        timeLeft = (investor[_investor].monthLock.sub(block.timestamp)).div(1 days);
        return(_amount, timeLeft);
    }
    function withdrawalISLAMI(uint256 _amount, uint256 sonbola, address to) external onlyOwner() {
        ERC20 _tokenAddr = ISLAMI;
        uint256 amount = ISLAMI.balanceOf(address(this)).sub(investorVault);
        require(amount > 0, "No ISLAMI available for withdrawal!");// can only withdraw what is not locked for team or investors.
        uint256 dcml = 10 ** sonbola;
        ERC20 token = _tokenAddr;
        emit WithdrawalISLAMI( _amount, sonbola, to);
        token.transfer(to, _amount*dcml);
    }
    function withdrawalERC20(address _tokenAddr, uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        uint256 dcml = 10 ** decimal;
        ERC20 token = ERC20(_tokenAddr);
        require(token != ISLAMI, "Can't withdraw ISLAMI using this function!");
        emit WithdrawalERC20(_tokenAddr, _amount, decimal, to);
        token.transfer(to, _amount*dcml); 
    }  
    function withdrawalMatic(uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        require(address(this).balance >= _amount);
        uint256 dcml = 10 ** decimal;
        emit WithdrawalMatic(_amount, decimal, to);
        payable(to).transfer(_amount*dcml);      
    }
    receive() external payable {}
}


//********************************************************
// Proudly Developed by MetaIdentity ltd. Copyright 2022
//********************************************************