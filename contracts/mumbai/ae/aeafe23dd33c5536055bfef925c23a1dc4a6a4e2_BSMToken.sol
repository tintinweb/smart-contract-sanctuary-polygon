/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol 

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract EIP20Simplified is IERC20 {

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed; 
    uint256 internal _totalSupply;
      
    function transfer(address _destinatariodeTokens, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value,"no tienes tantos tokens");
        balances[msg.sender] -= _value;
        balances[_destinatariodeTokens] += _value;
        emit Transfer(msg.sender, _destinatariodeTokens, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowances = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowances >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
   
}
	


contract BSMToken is EIP20Simplified {
    string public name;                  
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier 
    address public owner;
    uint256 public MAX_TOTAL_SUPPLY = 20000000000*1000000000000000000; //MAX = 2000 TOKEN
    uint256 public eth_token_ratio = 100;   //0.01 eth = 1 token --> 100 token = 1eth
    mapping(address=>bool) claimed;

    constructor()  {
        name = "Blockchain School for Management Token";  // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = "BSM";                               // Set the symbol for display purposes
        owner = msg.sender;
        uint256 _initialAmount = 100*10**decimals;     //100 tokens for owner 
        mint(_initialAmount);  //initial amout for creator 
    }

    function buyTokens() public payable {
       require(msg.value >= 0.01 ether, "compra minima 1 token no alanzada");  //minimum buy 0.001 tokens
       uint newTokens = msg.value * eth_token_ratio;  // 0.01 ethers = 1 token
       mint(newTokens);
    }
    receive () external payable  {   //   receive() external payable {      
       buyTokens();
    }
    function claimFreeTokens() public {
        require(!claimed[msg.sender],"ya has obtenido free tokens");
        uint freeTokenAmount = 2*10**decimals; //2 tokens
        claimed[msg.sender] = true;
        mint(freeTokenAmount);
    }

    /*function mint(uint256 _nuevosTokens) internal returns(bool success) {
        require(msg.sender == owner, "only owner");
        _totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        return true;
    }*/
    
    function mint(uint256 _nuevosTokens) internal returns(bool success) {
        require(_nuevosTokens+_totalSupply <= MAX_TOTAL_SUPPLY, "Superada cantidad maxima total de tokens");
        _totalSupply += _nuevosTokens;
        balances[msg.sender] += _nuevosTokens;
        emit Transfer(address(0), msg.sender, _nuevosTokens); 
        return true;
    }
    
    function burn(uint256 _tokensaEliminar) public returns(bool success) {
        require(msg.sender == owner, "only owner");
        require(balances[msg.sender] >= _tokensaEliminar);
        _totalSupply -= _tokensaEliminar;
        balances[msg.sender] -= _tokensaEliminar;
        uint256 eth_value =_tokensaEliminar/ eth_token_ratio;
        payable(msg.sender).transfer(eth_value);
        return true;
    }
    
}