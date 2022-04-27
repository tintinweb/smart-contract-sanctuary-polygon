/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// File: contracts/Token.sol

pragma solidity ^0.5.0;

contract EarnVille {
    string  public name = "EarnVille";
    string str = '2233';
    string  public symbol = "EAVL";
    uint256 public totalSupply = 1000000000000000000000000000; // 1 billion tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// File: contracts/EAVLSwap.sol

pragma solidity ^0.5.0;


contract EarnVilleInstantSwap {
  string public name = "EarnVille Instant Swap";
  EarnVille public token;
  uint public rate = 100;
  address public owner;
  address public lp_address = 0x0000000000000000000000000000000000000000;
  address payable public jackpot_pool_address = 0x0000000000000000000000000000000000000000;
  address public reward_pool_address = 0x0000000000000000000000000000000000000000;
  address payable public treasury_address = 0x0000000000000000000000000000000000000000;

  event TokensPurchased(
    address account,
    address token,
    uint amount,
    uint rate
  );

  event TokensSold(
    address account,
    address token,
    uint amount,
    uint rate
  );

  constructor(EarnVille _token) public {
    token = _token;
    owner = msg.sender;
  }

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

  function buyTokens() public payable {
    // Calculate the number of tokens to buy
    uint tokenAmount = msg.value * rate;
    uint total_ftm = msg.value;

    // Require that EthSwap has enough tokens
    require(token.balanceOf(address(this)) >= tokenAmount);

    uint lp_amount = (tokenAmount / 100) * 3 ;
    uint reward_amount = (tokenAmount / 100) * 10 ;
    uint jackpot_amount = (total_ftm / 100) * 2 ;
    uint user_amount = tokenAmount - (lp_amount+reward_amount) ;

    // Transfer tokens to the user
    token.transfer(msg.sender, user_amount);
    // Transfer tokens to lp
    token.transfer(lp_address, lp_amount);
    // Transfer tokens to reward pool
    token.transfer(reward_pool_address, reward_amount);
    // Transfer ftm to jackpot pool
    jackpot_pool_address.transfer(jackpot_amount);

    // Emit an event
    emit TokensPurchased(msg.sender, address(token), user_amount, rate);
    emit TokensPurchased(lp_address, address(token), lp_amount, rate);
    emit TokensPurchased(reward_pool_address, address(token), reward_amount, rate);
  }

  function addBalance() public payable {

  }

    function getRate() public view returns(uint){
        return rate;
    }

    function setRate(uint newRate) public onlyOwner {
        rate = newRate;
    }
    function get_lp_address() public view returns(address){
        return lp_address;
    }

    function set_lp_address(address new_lp_address) public onlyOwner {
        lp_address = new_lp_address;
    }
    function get_jackpot_pool_address() public view returns(address){
        return jackpot_pool_address;
    }

    function set_jackpot_pool_address(address payable new_jackpot_pool_address) public onlyOwner {
        jackpot_pool_address = new_jackpot_pool_address;
    }
    function get_reward_pool_address() public view returns(address){
        return reward_pool_address;
    }

    function set_reward_pool_address(address new_reward_pool_address) public onlyOwner {
        reward_pool_address = new_reward_pool_address;
    }
    function get_treasury_address() public view returns(address){
        return treasury_address;
    }

    function set_treasury_address(address payable new_treasury_address) public onlyOwner {
        treasury_address = new_treasury_address;
    }

  function sellTokens(uint _amount) public {
    // User can't sell more tokens than they have
    require(token.balanceOf(msg.sender) >= _amount);

    // Calculate the amount of Ether to redeem
    uint etherAmount = _amount / rate;
    uint jackpot_amount = (etherAmount / 100) * 3 ;
    uint treasury_amount = (etherAmount / 100) * 10 ;
    uint user_amount = etherAmount - (jackpot_amount + treasury_amount) ;

    
    // Transfer tokens to jackpot pool
    jackpot_pool_address.transfer(jackpot_amount);
    // Transfer tokens to treasury pool
    treasury_address.transfer(treasury_amount);
    // Transfer tokens to user
    msg.sender.transfer(user_amount);

    // Require that EthSwap has enough Ether
    require(address(this).balance >= etherAmount);

    // lp calculation
    uint lp_amount = (_amount / 100) * 7 ;
    uint contract_amount = _amount - lp_amount ;

    // Perform sale
    token.transferFrom(msg.sender, lp_address, lp_amount);
    token.transferFrom(msg.sender, address(this), contract_amount);
    

    // Emit an event
    emit TokensSold(msg.sender, address(token), _amount, rate);
  }

  function redeemBalance(uint _amount) public onlyOwner {


    // Calculate the amount of Ether to redeem
    uint etherAmount = _amount;

    // Require that EthSwap has enough Ether
    require(address(this).balance >= etherAmount);

    // Perform sale
    msg.sender.transfer(etherAmount);
  }

  function redeemToken(uint _amount) public onlyOwner {
    token.transfer(msg.sender, _amount);
  }
  
}