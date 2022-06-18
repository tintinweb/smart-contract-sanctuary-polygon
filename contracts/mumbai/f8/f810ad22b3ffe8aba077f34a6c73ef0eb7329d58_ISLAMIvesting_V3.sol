// SPDX-License-Identifier: MIT

//This is a vesting contract for ISLAMI token, with monthly percentage claims after total locking


import "./ISLAMICOIN.sol";

pragma solidity = 0.8.13;

contract ISLAMIvesting_V3 {
    using SafeMath for uint256;

    address public BaytAlMal = 0xC315A5Ce1e6330db2836BD3Ed1Fa7228C068cE20;
    //address public feeReceiver = 0x605bD43F4B3C80B9d409Ca07375dbC27052cDeD1;
    ISLAMICOIN public ISLAMI;
    address private owner;
    uint256 Sonbola = 10**7;
    uint256 public constant monthly = 1; //30 days;
    uint256 public investorCount;
    uint256 private IDinvestor;
    uint256 public investorVault;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 constant hPercent = 100; //100%
    uint256 private _status;
    uint256 public mP = 5; /* Monthy percentage */
    uint256 public minLock = 100000 * Sonbola;
    uint256 public votingFee = 50 * Sonbola;
    uint256 private satoshi = 10000000 * Sonbola; /* Each 10 Million ISLAMI equal One Vote!   */

    event ISLAMIClaimed(address Investor, uint256 Amount);
    event ChangeOwner(address NewOwner);
    event Voted(address Voter, uint256 voteFee);
    event WithdrawalMatic(uint256 _amount, uint256 decimal, address to); 
    event WithdrawalISLAMI(uint256 _amount,uint256 sonbola, address to);
    event WithdrawalERC20(address _tokenAddr, uint256 _amount,uint256 decimals, address to);
    
    struct VaultInvestor{
        uint256 investorID;
        uint256 amount;
        uint256 monthLock;
        uint256 lockTime;
        uint256 timeStart;
    }
    struct SelfLock{
        uint256 slInvestorID;
        uint256 slAmount;
        uint256 slMonthLock;
        uint256 slLockTime;
        uint256 slTimeStart;
    }
    struct VoteSystem{
        string projectName;
        uint256 voteCount;
    }
 
    mapping(address => bool) public Investor;
    mapping(uint => address) public InvestorCount;
    mapping(address => VaultInvestor) public investor;

    mapping(address => bool) public slInvestor;
    mapping(uint => address) public slInvestorCount;
    mapping(address => SelfLock) public slinvestor;  
    //mapping(uint => voteSystem) public projectToVote;

    VoteSystem[] public voteSystem;

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
    function changeBaytAlMal(address _newBaytAlMal) external onlyOwner{
        BaytAlMal = _newBaytAlMal;
    }
    function setMonthlyPercentage(uint256 _mP) external onlyOwner{
        mP = _mP;
    }
    function setMinLock(uint256 _minLock) external onlyOwner{
        minLock = _minLock;
    }
    function setVotingFee(uint256 _vF) external onlyOwner{
        votingFee = _vF * Sonbola;
    }
    function setSatoshi(uint256 _sat) external onlyOwner{
        satoshi = _sat * Sonbola;
    }
    function addToVote(string memory _projectName) external onlyOwner{
        VoteSystem memory newVoteSystem = VoteSystem({
            projectName: _projectName,
            voteCount: 0
        });
        voteSystem.push(newVoteSystem);
    }
    function newVote(uint256 projectIndex, uint256 _vP) internal{
        voteSystem[projectIndex].voteCount += _vP;
    }
    function deleteVoteProject(uint256 projectIndex) external onlyOwner{
        voteSystem[projectIndex] = voteSystem[voteSystem.length -1];
        voteSystem.pop();
    }
    function addInvestor(address _investor, uint256 _amount, uint256 _lockTime) external onlyOwner{
        uint256 amount = _amount.mul(Sonbola);
        require(ISLAMI.balanceOf(address(this)) >= investorVault.add(amount));
        uint256 lockTime = _lockTime.mul(1);//(1 days);
        require(amount > 0, "Amount cannot be zero!");
        if(investor[_investor].amount > 0){
            investor[_investor].amount += amount;
            investor[_investor].monthLock += lockTime.add(block.timestamp);
            investorVault += amount;
            return;
        }
        //require(lockTime > monthly.mul(3), "Please set a time in the future more than 90 days!"); need to activate after testing
        IDinvestor++;
        investor[_investor].investorID = IDinvestor;
        investor[_investor].amount = amount;
        investor[_investor].lockTime = lockTime.add(block.timestamp);
        
        investor[_investor].timeStart = block.timestamp;
        investor[_investor].monthLock = lockTime.add(block.timestamp);
        Investor[_investor] = true;
        investorVault += amount;
        investorCount++;
    }
    function selfLock(uint256 _amount, uint256 _lockTime) external nonReentrant{
        uint256 amount = _amount * Sonbola;
        require(amount >= minLock, "Amount is less than minimum!");
        uint256 lockTime = _lockTime.mul(1 days);
        require(ISLAMI.balanceOf(msg.sender) >= amount);
        require(lockTime > monthly.mul(1), "Please set a time in the future more than 37560 days!");
        if(slinvestor[msg.sender].slAmount > 0){
            slinvestor[msg.sender].slAmount += amount;
            slinvestor[msg.sender].slMonthLock += lockTime.add(block.timestamp);
            investorVault += amount;
            return();
        }
        IDinvestor++;
        slinvestor[msg.sender].slInvestorID = IDinvestor;
        slinvestor[msg.sender].slAmount = amount; 
        slinvestor[msg.sender].slTimeStart = block.timestamp;
        slinvestor[msg.sender].slMonthLock = lockTime.add(block.timestamp);
        Investor[msg.sender] = true;
        investorVault += amount;
        investorCount++;
    }
    function claimMonthlyAmount() external isInvestor(msg.sender) nonReentrant{
        uint256 totalTimeLock = investor[msg.sender].monthLock;
        uint256 remainAmount = investor[msg.sender].amount;
        require(totalTimeLock <= block.timestamp, "Your need to wait till your token get unlocked");
        require(remainAmount > 0, "You don't have any tokens");
        //uint256 percentage = investor[msg.sender].monthAllow;   
        uint256 amountAllowed = remainAmount.mul(mP).div(hPercent);
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
        uint256 fullTime = hPercent.div(mP).mul(monthly);
        uint256 totalTimeLock = investor[msg.sender].lockTime.add(fullTime);
        require(totalTimeLock <= block.timestamp, "You can't claim your remaining yet!");
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
        timeLeft = (investor[_investor].monthLock.sub(block.timestamp)).div(1 days);
        return(_amount, timeLeft);
    }
    
    function voteFor(uint256 projectIndex)public nonReentrant{
        address voter = msg.sender;
        uint256 votePower;
        if(Investor[voter] == true){
            uint256 basePower = ISLAMI.balanceOf(voter);
            votePower = basePower.div(satoshi);
            newVote(projectIndex, votePower);
            emit Voted(msg.sender, 0);
            return();
        }
        
        
        ISLAMI.transferFrom(msg.sender, BaytAlMal, votingFee);
        votePower = 1;
        newVote(projectIndex, votePower);
        emit Voted(msg.sender, votingFee);
    }
    
    function withdrawalISLAMI(uint256 _amount, uint256 sonbola, address to) external onlyOwner() {
        ERC20 _tokenAddr = ISLAMI;
        uint256 amount = ISLAMI.balanceOf(address(this)).sub(investorVault);
        require(amount > 0, "No ISLAMI available for withdrawal!");// can only withdraw what is not locked for investors.
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