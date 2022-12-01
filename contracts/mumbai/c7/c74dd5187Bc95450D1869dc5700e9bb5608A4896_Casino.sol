// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";

contract Casino is Ownable{

    event RouletteGame (
        uint NumberWin,
        bool result,
        uint tokensEarned
    );

    ERC20 private token;
     address public tokenAddress;

    function precioTokens(uint256 _numTokens) public pure returns (uint256){
        return _numTokens * (0.001 ether); // price in matic
    }

    function tokenBalance(address _of) public view returns (uint256){
        return token.balanceOf(_of);
    }
    constructor(){
        token =  new ERC20("Casino", "CAS");
        tokenAddress = address(token);
        token.mint(1000000); //1m
    }

    // Visualization of the ethers balance of the Smart Contract
    function balanceEthersSC() public view returns (uint256){
        return address(this).balance / 10**18;
    }
     function compraTokens(uint256 _numTokens) public payable{
        // User registration
        // Establishment of the cost of the tokens to buy
        // Evaluation of the money that the client pays for the tokens
        require(msg.value >= precioTokens(_numTokens), "Buy less tokens or pay with more ethers");
        // Creation of new tokens in case there is not enough supply
        if  (token.balanceOf(address(this)) < _numTokens){
            token.mint(_numTokens*100000);
        }
        // Return of the remaining money
        // The Smart Contract returns the remaining amount
        payable(msg.sender).transfer(msg.value - precioTokens(_numTokens));
        // Send the tokens to the client/user
        token.transfer(address(this), msg.sender, _numTokens);
    }

    // Return of tokens to the Smart Contract
    function devolverTokens(uint _numTokens) public payable {
        // The number of tokens must be greater than 0
        require(_numTokens > 0, "You need to return a number of tokens greater than 0");
        // The user must prove that they have the tokens they want to return
        require(_numTokens <= token.balanceOf(msg.sender), "You don't have the tokens you want to return");
        // The user transfers the tokens to the Smart Contract
        token.transfer(msg.sender, address(this), _numTokens);
        // The Smart Contract sends the ethers to the user
        payable(msg.sender).transfer(precioTokens(_numTokens)); 
    }

    struct Bet {
        uint tokensBet;
        uint tokensEarned;
        string game;
    }

    struct RouleteResult {
        uint NumberWin;
        bool result;
        uint tokensEarned;
    }

    mapping(address => Bet []) historialApuestas;

    function retirarEth(uint _numEther) public payable onlyOwner {
        // The number of tokens must be greater than 0
        require(_numEther > 0, "You need to return a number of tokens greater than 0");
        // The user must prove that they have the tokens they want to return
        require(_numEther <= balanceEthersSC(), "You don't have the tokens you want to return");
        // Transfer the requested ethers to the owner of the smart contract'
        payable(owner()).transfer(_numEther);
    }

    function tuHistorial(address _propietario) public view returns(Bet [] memory){
        return historialApuestas[_propietario];
    }

    function jugarRuleta(uint _start, uint _end, uint _tokensBet) public{
        require(_tokensBet <= token.balanceOf(msg.sender));
        require(_tokensBet > 0);
        uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % 14);
        uint tokensEarned = 0;
        bool win = false;
        token.transfer(msg.sender, address(this), _tokensBet);
        if ((random <= _end) && (random >= _start)) {
            win = true;
            if (random == 0) {
                tokensEarned = _tokensBet*14;
            } else {
                tokensEarned = _tokensBet * 2;
            }
            if  (token.balanceOf(address(this)) < tokensEarned){
            token.mint(tokensEarned*100000);
            }
            token.transfer( address(this), msg.sender, tokensEarned);
        }
            addHistorial("Roulette", _tokensBet, tokensEarned, msg.sender);
            emit RouletteGame(random, win, tokensEarned);
    }

    function addHistorial(string memory _game, uint _tokensBet,  uint _tokenEarned, address caller) internal{
        Bet memory apuesta = Bet(_tokensBet, _tokenEarned, _game);
        historialApuestas[caller].push(apuesta);
    }

    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    //Returns the number of existing tokens.
    function totalSupply() external view returns (uint256);

    //Returns the number of tokens owned by an `account`.
    function balanceOf(address account) external view returns (uint256);

    /* Perform a transfer of tokens to a recipient.
    Returns a boolean value indicating whether the operation was successful. 
    Emits a {Transfer} event. */
    function transfer(address from, address to, uint256 amount) external returns (bool);

    /* Emitted when a token transfer is performed.
    understand that `value` can be zero. */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// Smart Contract of ERC20 tokens
contract ERC20 is IERC20 {

    // Data structures
    mapping(address => uint256) private _balances;
    
    // Variables
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address public owner;

    modifier onlyOwner(address _direccion) {
        require(_direccion == owner, "You do not have permissions to execute this function.");
        _;
    }

    /* Sets the value of the token name and token. 
    The default value of {decimaes} is 18. To select a different value for
    {decimals} must be replaced. */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
    }

    // Returns the name of the token.
    function name() public view virtual returns (string memory) {
        return _name;
    }

    // Return the token symbol, usually a shorter version of the name.
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /* Returns the number of decimal places used to get your user representation.
    For example, if `decimals` equals `2`, a balance of `505` tokens should be
    appear to the user as `5.05` (`505 / 10 ** 2`).
    The tokens usually opt for a value of 18, mimicking the relationship between
    Ether and Wei. This is the value used by {ERC20}, unless this function is
    be annulled. */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // See: {IERC20-totalSupply}.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // See: {IERC20-balanceOf}.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /* See: {IERC20-transfer}.
    Requirements:
    - `to` cannot be address zero.
    - the person executing must have a balance of at least `amount`. */
    function transfer(address from,address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function mint(uint256 amount) public virtual onlyOwner(msg.sender) returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    /* Move `amount` of tokens from `sender` to `recipient`.
    This builtin function is equivalent to {transfer}, and can be used to
    for example, implement automatic token fees, etc.
    Emits a {Transfer} event.
    Requirements:
    - `from` and `to` cannot be zero addresses.
    - `from` must have a balance of at least `amount`. */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    /* Create `amount` tokens and assign them to `account`, increasing
    the entire supply.
    Emits a {Transfer} event with "from" as address zero.
    Requirements:
    - `account` cannot be address zero. */
    function _mint(address account, uint256 amount) internal virtual{
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}