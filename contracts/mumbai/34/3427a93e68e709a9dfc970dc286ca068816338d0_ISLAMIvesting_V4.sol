// SPDX-License-Identifier: MIT

/*
@dev: This code is developed by Jaafar Krayem and is free to be used by anyone
*/

/*
@dev: This is a vesting contract for ISLAMI token, with monthly percentage claims after total locking
also used for voting and recovery wallet service
*/


import "./ISLAMICOIN.sol";

pragma solidity = 0.8.15;

contract ISLAMIvesting_V4 {
    using SafeMath for uint256;
    address private owner;
    ISLAMICOIN public ISLAMI;

    address public BaytAlMal = 0xC315A5Ce1e6330db2836BD3Ed1Fa7228C068cE20;
    address public constant zeroAddress = address(0x0);
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    
/*
@dev: Private values
*/  
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    uint256 private OneVote = 100000 * Sonbola; /* Each 100K ISLAMI equal One Vote!   */

/*
@dev: public values
*/
    uint256 public Sonbola = 10**7; // Number of Decimals in ISLAMI
    uint256 public constant monthly = 1;// 30 days;
    uint256 public investorCount;
    uint256 public investorVault;
    uint256 public slinvestorCount;
    uint256 public slInvestorVault;
    uint256 public allVaults;
    uint256 public votingEventID;
    uint256 public constant hPercent = 100; //100%
    uint256 public mP = 5; /* Monthy percentage */
    uint256 public minLock = 100000 * Sonbola;
    uint256 public ewFee = 1; //1% of locked amount
    
/*
@dev: Bool Values
*/
    bool votingEventLive = false;

/*
@dev: Events
*/
    event InvestorAdded(address Investor, uint256 Amount);
    event ISLAMIClaimed(address Investor, uint256 Amount);
    event SelfLockInvestor(address Investor, uint256 Amount);
    event EditSelfLock(address Investor, uint256 Amount);
    event ExtendSelfLock(address Investor, uint256 Time);
    event SelfISLAMIClaim(address Investor, uint256 Amount);
    event EmergencyWithdraw(address Investor, address NewWallet, uint256 Amount);
    event ChangeOwner(address NewOwner);
    event Voted(uint256 VotingEvent, address Voter, uint256 voteFee);
    event VoteResults(uint256 VotingEvent, string projectName,uint256 Result);
    event WithdrawalMatic(uint256 _amount, uint256 decimal, address to); 
    event WithdrawalISLAMI(uint256 _amount,uint256 sonbola, address to);
    event WithdrawalERC20(address _tokenAddr, uint256 _amount,uint256 decimals, address to);
/*
@dev: Investor Vault
*/   
    struct VaultInvestor{
        uint256 falseAmount; //represents the actual amount locked in order to keep track of monthly percentage to unlock
        uint256 amount;
        address recoveryWallet;
        uint256 monthLock;
        uint256 lockTime;
        uint256 timeStart;
        bool voted;
        uint256 votedForEvent;
    }
/*
@dev: Self Investor Vault
*/    
    struct SelfLock{
        uint256 slAmount;
        uint256 slLockTime;
        uint256 slTimeStart;
        address recoveryWallet;
        bool voted;
        uint256 votedForEvent;
    }
/*
@dev: Voting System
*/
    struct VoteSystem{
        string projectName;
        uint256 voteCount;
    }
 

/*
 @dev: Mappings
*/
    mapping(address => bool) public Investor;
    
    mapping(address => VaultInvestor) public investor;

    mapping(address => bool) public slInvestor;
   
    mapping(address => SelfLock) public slinvestor;

    mapping(address => bool) public blackList; 
/**/   

    VoteSystem[] public voteSystem;

/* @dev: Check if contract owner */
    modifier onlyOwner (){
        require(msg.sender == owner, "Only ISLAMICOIN owner can add Investors");
        _;
    }
/*
    @dev: check if user is investor
*/
    modifier isInvestor(address _investor){
        require(Investor[_investor] == true, "Not an Investor!");
        _;
    }
/*
    @dev: check if user is self investor
*/
    modifier ISslInvestor(address _investor){
        require(slInvestor[_investor] == true, "Not an Investor!");
        _;
    }
/*
    @dev: Check if user is Blacklisted
*/
    modifier isNotBlackListed(address _investor){
        require(blackList[_investor] != true, "Your wallet is Blacklisted!");
        _;
    }
/*
    @dev: prevent reentrancy when function is executed
*/
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    constructor(ISLAMICOIN _ISLAMI) {
        owner = msg.sender;
        investorCount = 0;
        ISLAMI = _ISLAMI;
        _status = _NOT_ENTERED;
    }
/*
    @dev: Change the contract owner
*/
    function transferOwnership(address _newOwner)external onlyOwner{
        require(_newOwner != zeroAddress,"Zero Address");
        emit ChangeOwner(_newOwner);
        owner = _newOwner;
    }
/*
    @dev: If Bay Al-Mal contract is updated, then it should
    be changed here in order to have the same address
*/
    function changeBaytAlMal(address _newBaytAlMal) external onlyOwner{
        require(_newBaytAlMal != zeroAddress,"Zero Address");
        BaytAlMal = _newBaytAlMal;
    }
/*
    @dev: Set monthly percentage allowed for long term investors
    to collect after the whole period of locking has ended
    minimum 1% maximum 50%
*/
    function setMonthlyPercentage(uint256 _mP) external onlyOwner{
        require(_mP > 0 && _mP <= 50,"!");
        mP = _mP;
    }
/*
    @dev: Set minimum ammount to be locked for user to be 
    allowed to vote
*/
    function setMinLock(uint256 _minLock) external onlyOwner{
        minLock = _minLock;
    }
/*
    @dev: set the emergency fee
    paid by user if used emergencyWithdrawal
*/
    function setEmergencyFee(uint256 _eW) external onlyOwner{
        ewFee = _eW;
    }
/*
    @dev: Set One vote count equal to how much ISLAMI
*/
    function setOneVote(uint256 _oneVote) external onlyOwner{
        require(_oneVote !=0,"Zero!");
        OneVote = _oneVote;
    }
/*
    @dev: Add voting project and start the voting event
*/
    function setVotingEvent(string memory p1, string memory p2, string memory p3) external onlyOwner{
        votingEventLive = true;
        addToVote(p1);
        addToVote(p2);
        addToVote(p3);
        votingEventID++;
    }
/*
    @dev: If voting projects are more than 3 owner can add 
    additions projects for voting using this function.
    maily used to setVotingEvents
*/
    function addToVote(string memory _projectName) public{
        require(msg.sender == owner || msg.sender == address(this),"Not Allowed!");
        require(votingEventLive == true,"!");
        VoteSystem memory newVoteSystem = VoteSystem({
            projectName: _projectName,
            voteCount: 0
        });
        voteSystem.push(newVoteSystem);
    }
/*
    @dev: add vote value submitted by user
*/
    function newVote(uint256 projectIndex, uint256 _vP) internal{
        voteSystem[projectIndex].voteCount += _vP;
    }
/*
     @dev: This function will delete all projects for voting
     it will also set the votingEventLive value to false.
*/
    function endVotingEvent() external onlyOwner{

        for(uint i = 0; i<=voteSystem.length; i++){
            emit VoteResults(votingEventID, voteSystem[i].projectName, voteSystem[i].voteCount);
            voteSystem[i] = voteSystem[voteSystem.length -1];
            voteSystem.pop();
        }
        votingEventLive = false;
    }
/*
    @dev: Calculate total locked tokens and set value to
    the reserve (allVaults)
*/
    function totalLocked() internal{
        allVaults = investorVault.add(slInvestorVault);
    }
/*
    @dev: Long term investors & first investors who had their tokens 
    locked before in other contract and in old vesting contract are 
    reconfigured here.
*/
    function addInvestor(address _investor, uint256 _amount, uint256 _lockTime, address _recoveryWallet) external onlyOwner{
        uint256 amount = _amount.mul(Sonbola);
        totalLocked();
        uint256 availableAmount = ISLAMI.balanceOf(address(this)).sub(allVaults);
        require(availableAmount >= amount,"No ISLAMI");
        uint256 lockTime = _lockTime.mul(1);//(1 days);
        require(amount > 0, "Amount!");
        if(investor[_investor].amount > 0){
            investor[_investor].amount += amount;
            investor[_investor].falseAmount = investor[_investor].amount;
            investorVault += amount;
            return;
        }
        //require(lockTime > monthly.mul(3), "Please set a time in the future more than 90 days!"); should activate after testing
        emit InvestorAdded(msg.sender, amount);
        investor[_investor].falseAmount = amount;
        investor[_investor].amount = amount;
        investor[_investor].recoveryWallet = _recoveryWallet;
        investor[_investor].lockTime = lockTime.add(block.timestamp);
        investor[_investor].timeStart = block.timestamp;
        investor[_investor].monthLock = lockTime.add(block.timestamp);
        Investor[_investor] = true;
        investorVault += amount;
        totalLocked();
        investorCount++;
    }
/*
    @dev: require approval on spen allowance from token contract
    this function for investors who want to lock their tokens
    usage: 
           1- if usrr want to use recovery wallet service
           2- if user want to vote on projects!
*/
    function selfLock(uint256 _amount, uint256 _lockTime, address _recoveryWallet) external isNotBlackListed(msg.sender) nonReentrant{
       
        require(_recoveryWallet != deadAddress, "Burn!");
        if(_recoveryWallet == zeroAddress){
            _recoveryWallet = address(this);
        }
        require(slInvestor[msg.sender] != true,"Double locking!");
        uint256 amount = _amount;
        require(amount >= minLock, "Amount!");
        uint256 lockTime = _lockTime.mul(1);//(1 days);
        require(ISLAMI.balanceOf(msg.sender) >= amount);
        ISLAMI.transferFrom(msg.sender, address(this), amount);
        emit SelfLockInvestor(msg.sender, amount);
        slinvestor[msg.sender].slAmount = amount; 
        slinvestor[msg.sender].slTimeStart = block.timestamp;
        slinvestor[msg.sender].slLockTime = lockTime.add(block.timestamp);
        slinvestor[msg.sender].recoveryWallet = _recoveryWallet;
        slInvestor[msg.sender] = true;
        slInvestorVault += amount;
        totalLocked();
        slinvestorCount++;
    }
/*
    @dev: require approval on spen allowance from token contract
    this function is to edit the amount locked by user
    usage: if user want to raise his voting power
*/
    function editSelfLock(uint256 _amount) external ISslInvestor(msg.sender) nonReentrant{
        uint256 amount = _amount;// * Sonbola;
        require(ISLAMI.balanceOf(msg.sender) >= amount);
        ISLAMI.transferFrom(msg.sender, address(this), amount);
        slinvestor[msg.sender].slAmount += amount;
        slInvestorVault += amount;
        emit EditSelfLock(msg.sender, amount);
        totalLocked();
    }
/*
    @dev: Extend the period of locking, used if user wants
    to vote and the period is less than 30 days
*/
    function extendSelfLock(uint256 _lockTime) external ISslInvestor(msg.sender) nonReentrant{
        uint256 lockTime = _lockTime.mul(1 days);
        slinvestor[msg.sender].slLockTime += lockTime;
        emit ExtendSelfLock(msg.sender, lockTime);
    }
/*
    @dev: Investor lost his phone or wallet, or passed away!
    only the wallet registered as recovery can claim tokens after lock is done
*/
    function recoverWallet(address _investor) external ISslInvestor(_investor) nonReentrant{
        require(msg.sender == slinvestor[_investor].recoveryWallet &&
        slinvestor[_investor].slLockTime < block.timestamp,
        "Not allowed");
        useRecovery(_investor);
    }
/*
    @dev: Unlock locked tokens for user
    only the original sender can call this function
*/
    function selfUnlock(uint256 _amount) external ISslInvestor(msg.sender) nonReentrant{
        require(slinvestor[msg.sender].slLockTime <= block.timestamp, "Not yet");
        uint256 amount = _amount;
        require(slinvestor[msg.sender].slAmount >= amount, "Amount!");
        slinvestor[msg.sender].slAmount -= amount;
        slInvestorVault -= amount;
        if(slinvestor[msg.sender].slAmount == 0){
            slInvestor[msg.sender] = false;
            delete slinvestor[msg.sender];
            slinvestorCount--;
        }
        totalLocked();
        emit SelfISLAMIClaim(msg.sender, amount);
        ISLAMI.transfer(msg.sender, amount);
    }
/*
    @dev: If self lock investor wallet was hacked!
    Warning: this will blacklist the message sender!
*/
    function emergencyWithdrawal() external ISslInvestor(msg.sender) nonReentrant{
        useRecovery(msg.sender);
    }
/*
    @dev: Recover Wallet Service, also used by emergencyWithdrawal!
    * Check if statment
    if user didn't add a recovery wallet when locking his tokens
    the recovery wallet is set this contract and tokens are safe 
    and released to the contract itself.
    This contract does not have a function to release the tokens
    in case of emerergency it is only done by the user.
    if(newWallet == address(this))
    Release tokens to smart contract, investor should contact project owner on Telegram @jeffrykr
*/
    function useRecovery(address _investor) internal {
        blackList[_investor] = true;
        uint256 feeToPay = slinvestor[_investor].slAmount.mul(ewFee).div(100);
        address newWallet = slinvestor[_investor].recoveryWallet;
        uint256 fullBalance = slinvestor[_investor].slAmount.sub(feeToPay);
        slInvestorVault -= slinvestor[_investor].slAmount;
        slInvestor[_investor] = false;
        delete slinvestor[_investor];
        totalLocked();
        slinvestorCount--;
        emit EmergencyWithdraw(_investor, newWallet, fullBalance);
        if(newWallet == address(this)){  
            return();
        }
        ISLAMI.transfer(newWallet, fullBalance);
    }
/*
    @dev: Claim Monthly allowed amount for long term investors
*/
    function claimMonthlyAmount() external isInvestor(msg.sender) nonReentrant{
        uint256 totalTimeLock = investor[msg.sender].monthLock;
        uint256 mainAmount = investor[msg.sender].falseAmount;
        uint256 remainAmount = investor[msg.sender].amount;
        require(totalTimeLock <= block.timestamp, "Not yet");
        require(remainAmount > 0, "No ISLAMI");  
        uint256 amountAllowed = mainAmount.mul(mP).div(hPercent);
        investor[msg.sender].amount = remainAmount.sub(amountAllowed);
        investor[msg.sender].monthLock += monthly;
        investorVault -= amountAllowed;
        if(investor[msg.sender].amount == 0){
            Investor[msg.sender] = false;
            delete investor[msg.sender];
            investorCount--;
        }
        totalLocked();
        emit ISLAMIClaimed(msg.sender, amountAllowed);
        ISLAMI.transfer(msg.sender, amountAllowed);
    }
/*
    @dev: If their are any leftovers after claiming all allowed amounts
*/
    function claimRemainings() external isInvestor(msg.sender) nonReentrant{
        uint256 fullTime = hPercent.div(mP).mul(monthly);
        uint256 totalTimeLock = investor[msg.sender].lockTime.add(fullTime);
        require(totalTimeLock <= block.timestamp, "Not yet");
        uint256 remainAmount = investor[msg.sender].amount;
        investor[msg.sender].amount = 0;
        investorVault -= remainAmount;
        Investor[msg.sender] = false;
        delete investor[msg.sender];
        emit ISLAMIClaimed(msg.sender, remainAmount);
        ISLAMI.transfer(msg.sender, remainAmount);
        totalLocked();
        investorCount--;
    }
/*
    @dev: Voting for projects
    user can vote only once in an event
    user power is calculated with respect to locked tokens balance
    Voting fee is not obligatory
*/
    function voteFor(uint256 projectIndex, uint256 _votingFee) isNotBlackListed(msg.sender) public nonReentrant{
        require(votingEventLive == true,"No voting event");
        require(Investor[msg.sender] == true || slInvestor[msg.sender] == true,"not allowed");
        address voter = msg.sender;
        uint256 votePower;
        uint256 votingFee = _votingFee;
        uint256 lockedBasePower;
        uint256 mainPower;

        if(Investor[voter] == true && slInvestor[voter] != true){
            if(votingEventID > investor[msg.sender].votedForEvent){
                investor[msg.sender].voted = false;
        }
            require(investor[msg.sender].voted != true,"Already Voted!");
            lockedBasePower = investor[voter].amount;
            require(lockedBasePower > votingFee,"Need more ISLAMI");
            investor[voter].amount -= votingFee;
            investor[msg.sender].voted = true;
            investor[msg.sender].votedForEvent = votingEventID;
            investorVault -= votingFee;
        }
        if(slInvestor[voter] == true && Investor[voter] != true){
            if(votingEventID > slinvestor[msg.sender].votedForEvent){
                slinvestor[msg.sender].voted = false;
        }
            require(slinvestor[msg.sender].voted != true,"Already Voted!");
            require(slinvestor[msg.sender].slLockTime >= monthly,"Should lock 30 days");
            lockedBasePower = slinvestor[voter].slAmount;
            require(lockedBasePower > votingFee,"Need more ISLAMI");
            slinvestor[voter].slAmount -= votingFee;
            slinvestor[msg.sender].voted = true;
            slinvestor[msg.sender].votedForEvent = votingEventID;
            slInvestorVault -= votingFee;
        }
        if(Investor[voter] == true && slInvestor[voter] == true){
            if(votingEventID > investor[msg.sender].votedForEvent){
                investor[msg.sender].voted = false;
        }
            require(investor[msg.sender].voted != true,"Already Voted!");
            uint256 lockedBasePower1 = investor[voter].amount;
            uint256 lockedBasePower2 = slinvestor[voter].slAmount;
            lockedBasePower = lockedBasePower1.add(lockedBasePower2);
            require(lockedBasePower2 > votingFee,"Need more ISLAMI");
            slinvestor[voter].slAmount -= votingFee;
            investor[msg.sender].voted = true;
            investor[msg.sender].votedForEvent = votingEventID;
            slInvestorVault -= votingFee;
        }
        mainPower = lockedBasePower*10**2;
        if(votingFee > 0){
            ISLAMI.transfer(BaytAlMal, votingFee);
        }
        votePower = mainPower.div(OneVote);
        newVote(projectIndex, votePower);
        emit Voted(votingEventID, msg.sender, votingFee);
    }
/*
    @dev: If long term investor wallet was lost!
*/
    function releaseWallet(address _investor) isInvestor(_investor) external nonReentrant{
        uint256 fullTime = hPercent.div(mP).mul(monthly);
        uint256 totalTimeLock = investor[_investor].lockTime.add(fullTime);
        require(msg.sender == investor[_investor].recoveryWallet &&
        totalTimeLock < block.timestamp,"Not yet!");
        blackList[_investor] = true;
        uint256 remainAmount = investor[_investor].amount;
        investor[_investor].amount = 0;
        investorVault -= remainAmount;
        totalLocked();
        Investor[_investor] = false;
        delete investor[_investor];
        investorCount--;
        emit EmergencyWithdraw(_investor, msg.sender, remainAmount);
        ISLAMI.transfer(msg.sender, remainAmount);
    }
/*
    @dev: Withdrwa ISLAMI that are not locked for Investors
    usage: sending ISLAMI by user directly to contract,
    in this function we can return only what is sent by mistake
*/
    function withdrawalISLAMI(uint256 _amount, uint256 sonbola, address to) external onlyOwner() {
        totalLocked();
        uint256 dcml = 10 ** sonbola;
        uint256 amount = ISLAMI.balanceOf(address(this)).sub(allVaults);
        require(amount > 0 && _amount*dcml <= amount, "No ISLAMI!");
        emit WithdrawalISLAMI( _amount, sonbola, to);
        ISLAMI.transfer(to, _amount*dcml);
    }
/*
    @dev: Withdrwa ERC20 tokens if sent by mistake to contract
    and return back to sender
*/
    function withdrawalERC20(address _tokenAddr, uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        uint256 dcml = 10 ** decimal;
        ERC20 token = ERC20(_tokenAddr);
        require(token != ISLAMI, "No!"); //Can't withdraw ISLAMI using this function!
        emit WithdrawalERC20(_tokenAddr, _amount, decimal, to);
        token.transfer(to, _amount*dcml); 
    }  
/*
    @dev: Withdrwa Matic token!
    return back to sender if sent by mistake
*/
    function withdrawalMatic(uint256 _amount, uint256 decimal, address to) external onlyOwner() {
        require(address(this).balance >= _amount,"Balanace"); //No matic balance available
        uint256 dcml = 10 ** decimal;
        emit WithdrawalMatic(_amount, decimal, to);
        payable(to).transfer(_amount*dcml);      
    }
/*
    @dev: contract is payable (can receive Matic)
*/
    receive() external payable {}
}


               /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2022
               **********************************************************/