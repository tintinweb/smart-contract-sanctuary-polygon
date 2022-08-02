/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// SPDX-License-Identifier: unlicensed
/*
Created hiddenfox.eth
Fund control Contract & Token
*/
pragma solidity >=0.4.0 <0.9.0;
pragma solidity ^0.5.00;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */


  // function balanceOf(address account) external view returns (uint256);
  //  function balanceOf(address who) constant returns (uint256);
  //  function transfer(address to, uint256 value) public;
   // event Transfer(address indexed from, address indexed to, uint256 value);

  // function allowance(address _owner, address spender) external view returns (uint256);
   // function allowance(address owner, address spender) constant returns (uint256);
  //  function transferFrom(address from, address to, uint256 value)public;
   // function approve(address spender, uint256 value)public;
  //  event Approval(address indexed owner, address indexed spender, uint256 value);


contract Controll {
  // uint256 public totalSupply; 
 string public name = "Fund Control Token";
    string public symbol = "FCT";
    uint256 public decimals = 0;
    uint256 public initialSupply = 1;
    uint256 public totalSupply=1;

address public owner;
    //tokenImage
    /* 
    * Stores the contribution in wei
    * Stores the amount received in TKR
    */
    struct Contributor {
        uint256 contributed;
        uint256 received;
        uint256 dividend;
    }
    /* Backers are keyed by their address containing a Contributor struct */
    mapping(address => Contributor) public contributors;

 mapping(address => uint256) balances;
 mapping (address => mapping (address => uint256)) allowed;


    /* Events to emit when a contribution has successfully processed */
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
   // event MigratedTokens(address indexed _address, uint256 value);
event DataStored(uint256 data1, bytes indexed data2);
   uint256 data1;
   uint256 data2;
    /* Constants */
    uint256 public constant TOKEN_CAP = 100000000 * 10 ** 18;
    uint256 public constant MINIMUM_CONTRIBUTION = 1**16;
    uint256 public constant TOKENS_PER_ETHER = 1000;
    uint256 public constant sharesSALE_DURATION = 30 days;
    /* Public Variables */
//    TKRToken public token;
 //   TKRPToken public preToken;
    address public sharessaleOwner;
    uint256 public etherReceived;
    uint256 public tokensSent;
    uint256 public sharessaleStartTime;
    uint256 public sharessaleEndTime;
    uint256 public ctrl;
    uint8 public led;
    uint8 public ledfx;
    /* Modifier to check whether the sharessale is running */
    modifier sharessaleRunning() {
        require(now < sharessaleEndTime && sharessaleStartTime != 0);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    /**
    * @dev Fallback function which invokes the processContribution function
    * param _tokenAddress TKR Token address
    * param _to sharessale owner address
    */ 
    constructor() public{
 //       token = this.address;
  owner = msg.sender;
        sharessaleOwner = msg.sender;
      //  address(this).balance=0;
    }
    /**
    * @dev Fallback function which invokes the processContribution function
    */
    function() sharessaleRunning payable external{
        processContribution(msg.sender);
        require(msg.data.length == 0); emit DataStored(msg.value,msg.data);
    }
 //   receive() external payable {
  //    emit  Transfer(address(this),sharessaleOwner,address(this).balance);
  // }
    /**
    * @dev Starts the sharessale
    */
    function start() onlyOwner public{
        require(sharessaleStartTime == 0);
        sharessaleStartTime = now;            
        sharessaleEndTime = now + sharesSALE_DURATION;    
    }
    /**
    * @dev A backup fail-safe drain if required
    */
    function drain() onlyOwner public{
      //  assert(sharessaleOwner.send
      msg.sender.transfer(address(this).balance);
    }
    function safeTransfer(address token, address to, uint value) onlyOwner public{
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
   
   //function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
     //   return tokenAddress.call(tokenAddress.transfer(msg.sender, tokens));
   // }
   
   
   //function drainToken(address token) onlyOwner public{
      //  assert(sharessaleOwner.send
     // msg.sender.transfer(address(token).balance);
   // }
    /**
    * @dev Finalizes the sharessale and sends funds
    */
    function finalize() onlyOwner public{
        require(sharessaleStartTime != 0 );
        msg.sender.transfer(address(this).balance);
        sharessaleStartTime=0;
    }
function deletec() onlyOwner public{
       
        msg.sender.transfer(address(this).balance);
        selfdestruct(msg.sender);
    }
   
    function processContribution(address sender) internal {
        require(msg.value >= MINIMUM_CONTRIBUTION);
        // // /* Calculate total (+bonus) amount to send, throw if it exceeds cap*/
        uint256 contributionInTokens = div(mul(msg.value,TOKENS_PER_ETHER),(1 ether));
        require(add(contributionInTokens,tokensSent) <= TOKEN_CAP);
        /* Send the tokens */
      //  token.transfer(sender, contributionInTokens);
        emit Transfer(address(0), sender, contributionInTokens);
        /* Create a contributor struct and store the contributed/received values */
        Contributor storage contributor = contributors[sender];
        contributor.received = add(contributor.received,contributionInTokens);
        contributor.contributed = add(contributor.contributed,msg.value);
        // /* Update the total amount of tokens sent and ether received */
        etherReceived = add(etherReceived,msg.value);
        tokensSent = add(tokensSent,contributionInTokens);
        totalSupply=tokensSent;
        // /* Emit log events */
        balances[sender] = add(balances[sender],contributionInTokens);
        emit TokensSent(sender, contributionInTokens);
        emit ContributionReceived(sender, msg.value);
    }
    /**
    * @dev Calculates the bonus amount based on the contribution date
    * @param amount The contribution amount given
    */
    function bonus(uint256 amount) internal view returns (uint256) {
        /* This adds a bonus 20% such as 100 + 100/5 = 120 */
      //  if (now < sharessaleStartTime.add(2 days)) return amount.add(amount.div(5));
        /* This adds a bonus 10% such as 100 + 100/10 = 110 */
      //  if (now < sharessaleStartTime.add(14 days)) return amount.add(amount.div(10));
        /* This adds a bonus 5% such as 100 + 100/20 = 105 */
      //  if (now < sharessaleStartTime.add(21 days)) return amount.add(amount.div(20));
        /* No bonus is given */
        return amount;
    }
    function set_ctrl(uint256 val)  public{
        require(val != 0 );
        ctrl=val;
    }
     function set_led(uint8 val) payable public{
        require(val != 0 );
        led=val;
         processContribution(msg.sender);
        require(msg.data.length == 0); emit DataStored(msg.value,msg.data);
    }
     function set_ledfx(uint8 val)  public{
        require(val != 0 );
        ledfx=val;

    }


     function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal returns (uint256) {
         assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
         assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

       function transfer(address _to, uint256 _value) public{
        balances[msg.sender] = sub(balances[msg.sender],_value);
        balances[_to] = add(balances[_to],_value);
        emit Transfer(msg.sender, _to, _value);
    }
   
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }
  
    function transferFrom(address _from, address _to, uint256 _value) public{
        uint256 _allowance = allowed[_from][msg.sender];
 
        balances[_to] = add(balances[_to],_value);
        balances[_from] = sub(balances[_from],_value);
        allowed[_from][msg.sender] = sub(_allowance,_value);
        emit Transfer(_from, _to, _value);
    }
  
    function approve(address _spender, uint256 _value) public{
             require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
   
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}