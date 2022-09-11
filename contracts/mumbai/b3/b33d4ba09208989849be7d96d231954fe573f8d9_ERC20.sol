/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

// File: contracts/_ERC20forStaking.sol


pragma solidity ^0.8.13;

contract ERC20{
    uint public totalTokens;
    mapping(address => uint) public tokensOf; // tokensOf any account
    mapping(address => mapping(address => uint)) public allowence; // allow from to amount 
    address public ownerAddress;
    address public contractAddress;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokens);

    constructor() {
        ownerAddress = msg.sender;
        contractAddress = address(this);
        totalTokens = 1000;
        tokensOf[contractAddress] = totalTokens;
        emit Transfer(address(0), contractAddress, totalTokens);
    }

    modifier checkRemainingAvailabeTokens(uint256 _tokens){
        require(tokensOf[contractAddress] > _tokens , "not enough Total tokens available");
        _;
    }

    modifier checkSenderAvailableTokens(address _from, uint256 _tokens){
        require(tokensOf[_from] > _tokens , "not enough tokens available");
        _;
    }

    modifier checkApprovedTokens(address _from, uint256 _tokens){
        require(allowence[_from][msg.sender] >=  _tokens , "not enough money approved");
        allowence[_from][msg.sender] -= _tokens;
        _;
    }

    modifier NotSelfAddresses(address _from, address _to){
         require(_from != _to, "Both Parteis Can not be same");
        _;
    }

    modifier NotSameAddresses(address _from, address _to){
         require(_from != _to, "Both Parteis Can not be same");
        _;
    }

    modifier notOwner(address _address){
         require(_address != contractAddress, "Owner can not give token to self");
        _;
    }

    function transfer(address _to, uint256 _tokens) public checkRemainingAvailabeTokens(_tokens) notOwner(_to) returns (bool success){
        tokensOf[contractAddress] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(contractAddress, _to, _tokens);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _tokens) public checkSenderAvailableTokens(_from, _tokens) NotSelfAddresses(_from, _to) returns (bool success){
        tokensOf[_from] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens) public checkSenderAvailableTokens(msg.sender, _tokens) NotSelfAddresses(msg.sender, _spender) returns (bool success){
        allowence[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferAprovedTokens(address _from, address _to, uint256 _tokens) public checkApprovedTokens(_from, _tokens) NotSameAddresses(_from, _to) returns (bool success){
        tokensOf[_from] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function remainingTokens() public view returns (uint) {
        return tokensOf[contractAddress]  ;
    }

}
// File: contracts/_ERC20Staking.sol


pragma solidity ^0.8.13;


contract ERC20Staking {


    ERC20 ERC20Contract;

    // 1 Days (1 * 24 * 60 * 60)
    uint256 public planDuration = 30;
    uint256 _planExpired = 300;

    uint8 public interestRate = 20;     //20%
    uint256 public planExpired;
    uint8 public totalStakers;

    struct StakeInfo {        
        uint256 startTS;
        uint256 endTS;        
        uint256 amount; 
        uint256 claimed;       
    }

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    
    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;
    bool private lock;

    modifier onlyOwner() {
        require(msg.sender == ERC20Contract.ownerAddress(),"You must be the contract's owner.");
        _;
    }

    modifier notOwner(){
        require(msg.sender != ERC20Contract.ownerAddress(),"Owner can not stake Tokens");
        _;
    }

    modifier pauseTillTransaction() {
        require(!lock, "re-entrancy not allowed");
        lock = true;
        _;
        lock = false;
    }

    constructor(ERC20 _ERC20Address) {
        require(address(_ERC20Address) != address(0),"address cannot be null");                
        ERC20Contract = _ERC20Address;        
        planExpired = block.timestamp + _planExpired;
        totalStakers = 0;
    }    

    function transferToken(address to,uint256 amount) external onlyOwner{
        require(ERC20Contract.transfer(to, amount), "Token transfer failed!");  
    }

    function stakeToken(uint256 stakeAmount) external payable notOwner pauseTillTransaction {
        require(stakeAmount >0, "Stake amount should not be zero");
        require(block.timestamp < planExpired , "Our plan is Expired");
        require(!addressStaked[msg.sender], "You have already participated in plan");
        require(ERC20Contract.tokensOf(msg.sender) >= stakeAmount, "Insufficient Balance");
        require(ERC20Contract.tokensOf(ERC20Contract.contractAddress()) >= stakeAmount + (stakeAmount * interestRate / 100), "Insufficient Balance in contract Address");
        
        ERC20Contract.transferFrom(msg.sender, ERC20Contract.contractAddress(), stakeAmount);
        totalStakers++;
        addressStaked[msg.sender] = true;

        stakeInfos[msg.sender] = StakeInfo({                
            startTS: block.timestamp,
            endTS: block.timestamp + planDuration,
            amount: stakeAmount,
            claimed: 0
        });
        
        emit Staked(msg.sender, stakeAmount);
    }

    function claimReward() external returns (bool){
        require(addressStaked[msg.sender] == true, "You are not participated in plan");
        require(stakeInfos[msg.sender].endTS < block.timestamp, "Stake Time is not over yet");
        require(stakeInfos[msg.sender].claimed == 0, "Already claimed");

        uint256 stakeAmount = stakeInfos[msg.sender].amount;
        uint256 totalTokens = stakeAmount + (stakeAmount * interestRate / 100);
        stakeInfos[msg.sender].claimed == totalTokens;
        ERC20Contract.transfer(msg.sender, totalTokens);
        emit Claimed(msg.sender, totalTokens);

        // After cashing reward remove from staking List
        addressStaked[msg.sender] = false;
        totalStakers--;
        delete stakeInfos[msg.sender];

        return true;
    }

    function getTokenExpiry() external view returns (uint256) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        return stakeInfos[msg.sender].endTS;
    }

    function getMyTokens() public view returns (uint) {
        return ERC20Contract.tokensOf(msg.sender);
    }

}