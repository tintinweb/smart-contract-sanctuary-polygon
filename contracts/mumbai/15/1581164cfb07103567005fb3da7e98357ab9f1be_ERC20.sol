/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// File: contracts/_ERC20forICO.sol


pragma solidity ^0.8.13;

contract ERC20{
    uint public totalTokens;
    mapping(address => uint) public tokensOf; // tokensOf any account
    mapping(address => mapping(address => uint)) internal  allowence; // allow from to amount 
    address public  ownweAddress;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokens);

    constructor()  {
        ownweAddress = msg.sender;
        totalTokens = 10000;
        tokensOf[ownweAddress] = totalTokens;
        emit Transfer(address(0), ownweAddress, totalTokens);
    }

    modifier checkRemainingAvailabeTokens(uint256 _tokens){
        require(tokensOf[ownweAddress] > _tokens , "not enough Total tokens available");
        _;
    }

    modifier checkSenderAvailableTokens(uint256 _tokens){
        require(tokensOf[msg.sender] >= _tokens , "not enough tokens available");
        _;
    }

    modifier checkApprovedTokens(address _from, uint256 _tokens){
        require(allowence[_from][msg.sender] >=  _tokens , "not enough money approved");
        allowence[_from][msg.sender] -= _tokens;
        _;
    }

    modifier NotSelfAddresses(address _address){
         require(_address != msg.sender, "Both Parteis Can not be same");
        _;
    }

    modifier NotSameAddresses(address _from, address _to){
         require(_from != _to, "Both Parteis Can not be same");
        _;
    }

    modifier notOwner(address _address){
         require(_address != ownweAddress, "Owner can not give token to self");
        _;
    }

    function transfer(address _to, uint256 _tokens) internal checkRemainingAvailabeTokens(_tokens) notOwner(_to) returns (bool success){
        tokensOf[ownweAddress] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(ownweAddress, _to, _tokens);
        return true;
    }

    function transferBwUsers(address _to, uint256 _tokens) internal checkSenderAvailableTokens(_tokens) NotSelfAddresses(_to) returns (bool success){
        tokensOf[msg.sender] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens) internal checkSenderAvailableTokens(_tokens) NotSelfAddresses(_spender) returns (bool success){
        allowence[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferAprovedTokens(address _from, address _to, uint256 _tokens) internal checkApprovedTokens(_from, _tokens) NotSameAddresses(_from, _to) returns (bool success){
        tokensOf[_from] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function remainingTokens() public view returns (uint) {
        return tokensOf[ownweAddress]  ;
    }

}
// File: contracts/_ICO.sol


pragma solidity ^0.8.13;


contract ICO is ERC20{

    uint public constant EXPIRY_PERIOD = 120; // 1 Day = 86400s
    uint public constant MINIMUM_FUNDS_ACHIEVED = 0.1 * 10**18; // 5Ethers 5 * 10**18
    uint private startTime;
    uint private endTime;
    bool private saleAllowed;

    constructor(){
        startTime = block.timestamp;
        endTime= block.timestamp + EXPIRY_PERIOD;       
        saleAllowed = true;
    }

    modifier checkExpiryTime{
        require(block.timestamp < endTime, "Contract time Time Expired you can not buy tokens any more");
        _;
    }

    modifier checkTradingTime{
        require(block.timestamp > endTime, "You can not Trade before Contract Expiry Time");
        _;
    }

    modifier minimumFundsNotAchieved{
        require(address(this).balance > MINIMUM_FUNDS_ACHIEVED ,"Minimum funds Target not achieved");
        _;
    }

    modifier minimumFundsAchieved{
        require(address(this).balance < MINIMUM_FUNDS_ACHIEVED  ,"User can not withdraw Minimum funds Target achieved");
        _;
    }
    
    modifier onlyOwner{
        require(msg.sender == ownweAddress, "only owner of contract have rights");
        _;
    }

    modifier notTheOwner{
        require(msg.sender != ownweAddress, "owner of contract can not withdraw funds now");
        _;
    }

    modifier checkSaleAllowed{
        require(saleAllowed,"Sale is stoped by owner");
        _;
    }

    function buyTokens() external payable checkExpiryTime checkSaleAllowed returns(bool) {
        uint tokens = msg.value / 10**15 ;
        return transfer( msg.sender, tokens);
    }
    
    function transferTokens(address _to, uint256 _tokens) external checkTradingTime returns (bool){
        return transferBwUsers(_to, _tokens);        
    }

    function fundsWithdrawByOwner() external minimumFundsNotAchieved onlyOwner returns (bool){
        (bool success, ) = ownweAddress.call{value: address(this).balance}("");
        require(success, "tx fail"); 
        return success;   
    }

    function fundsWithdrawByUser(uint _tokens) external minimumFundsAchieved checkTradingTime checkSenderAvailableTokens(_tokens) notTheOwner {
        tokensOf[msg.sender] -= _tokens;
        tokensOf[ownweAddress] += _tokens;

        uint amountReturn = _tokens * 10**15;
        (bool success, ) = msg.sender.call{value:amountReturn}("");
        require(success, "tx fail");

        emit Transfer(msg.sender, ownweAddress, _tokens);
    }

    function stopTokensSale() external onlyOwner {
        saleAllowed = false;
    }

}