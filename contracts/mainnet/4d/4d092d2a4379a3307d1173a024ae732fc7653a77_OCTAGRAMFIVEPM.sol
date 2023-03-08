// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "./Context.sol";
contract OCTAGRAMFIVEPM is Context {
    mapping(address => uint256) private _balances; 
    mapping (address => bool) private suspendedAddresses;
    mapping (address => uint256) public lastBuyBlockNumber;
    mapping(address => uint256) lastSellBlockNumber;
    mapping(address => bool) private allowedAddresses;
    uint256 public exchangeRate;
    uint256 public _totalSupply;
    uint256 public totalEtherBalance; 
    string public _name;
    string public _symbol;
    event Transfer(address indexed from, address indexed to, uint256 value);
    address public owner;
    address payable public feeRecipient;
    uint256 public tokenDistributionFactor;
    uint256 public transactionFeePercentage = 3;
    bool private locked;
    uint256 public lastCallTime;
    uint256 public constant minTimeBetweenCalls = 60 seconds;
    event LogBuy( uint256  tokensToBeAdded, uint256 exchangeRate, address buyer, uint256 etherAmount, uint256 fee);
    event LogSell(address indexed seller, uint256 amount, uint256 exchangeRate, uint256 etherSent, uint256 fee);
    bool private paused = false;
    
constructor() {
    _name = "OCTAGRAMFIVEPM";
    _symbol = "O5PM";
    _mint(msg.sender, 100 * 100 ** decimals());
    owner = msg.sender;
    feeRecipient = payable (0x51d6724C950690006b676D8bE7083C3312069342);
    tokenDistributionFactor = 9 / 10 * 100;
    }
 receive() external payable {
    revert("Invalid transaction: Ether not accepted");
}
modifier onlyOwner {
    require(msg.sender == owner, "Sender is not the contract owner");
    _;
    }
modifier nonReentrant() {
    require(!locked, "Function is locked");
    locked = true;
    _;
    locked = false;
}
modifier onlyBuyAndConstructor() {
    require(msg.sender == address(this) || msg.sender == tx.origin, "Mint function can only be called from the buy function or constructor");
    _;
}
modifier onlySell() {
    require(msg.sender == address(this) || msg.sender == _msgSender(), "Function can only be called from the sell function.");
    _;
}
modifier onlyEOA(address recipient) {
    require(!isContract(recipient), "Transfer to contract address not allowed");
    _;
}
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid new owner address");
    require(msg.sender != newOwner, "New owner address must be different from current owner address");
    require(tx.origin == owner, "Only the original caller can transfer ownership");
        owner = newOwner;
    }
function isContract(address addr) private view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
}
// Function to pause the contract
function pause() public onlyOwner {
    paused = true;
}
// Function to unpause the contract
function unpause() public onlyOwner {
    paused = false;
}
function setTokenDistributionFactor(uint256 _tokenDistributionFactor) public onlyOwner {
        tokenDistributionFactor = _tokenDistributionFactor;
    }
function changeFeeRecipient(address _newRecipient) public onlyOwner{
    feeRecipient = payable ( _newRecipient);

    }
// Function to update the transaction fee percentage
function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
    require(newFeePercentage >= 0, "Fee percentage cannot be negative.");
    transactionFeePercentage = newFeePercentage;
}
function name() public view virtual returns (string memory) {
        return _name;
    }
function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
function decimals() public view virtual  returns (uint8) {
        return 0;
    }
function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }
function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }
function suspendAddress(address _address) public onlyOwner {
    suspendedAddresses[_address] = true;
    }
function unsuspendAddress(address _address) public onlyOwner {
    suspendedAddresses[_address] = false;
    }
function transfer(address to, uint256 amount) public virtual onlyEOA(to) returns (bool) { 
    require(_balances[msg.sender] >= amount, "Insufficient balance");
    require(!suspendedAddresses[msg.sender], "Sender address is suspended");
    require(msg.sender != to, "Cannot transfer tokens to yourself");
    require(_balances[to] + amount > _balances[to], "Transfer amount causes integer overflow");
    require(lastCallTime + minTimeBetweenCalls <= block.timestamp, "Function can only be called once every 60 seconds.");
    _balances[msg.sender] -= amount;
    _balances[to] += amount;
    emit Transfer(msg.sender, to, amount);
    return true;
}
function transferFrom(address from, address to, uint256 amount ) public virtual onlyEOA(to) returns (bool) {
    require(_balances[from] >= amount, "Insufficient balance");
    require(!suspendedAddresses[from], "Sender address is suspended");
    require(from != to, "Cannot transfer tokens to yourself");
    require(_balances[to] + amount > _balances[to], "Transfer amount causes integer overflow");
    require(lastCallTime + minTimeBetweenCalls <= block.timestamp, "Function can only be called once every 60 seconds.");
    transfer(from, to, amount);
        return true;
    }
function trade(address _to, uint256 _value) private {
    // Check if the trade is a swap
    if (msg.data.length > 4) {
        // Revert the transaction if the trade is a swap
        revert();
    }
    // Perform the trade
    transfer(_to, _value);
}
function add() public payable onlyOwner {
    totalEtherBalance += msg.value;
    // Calculate the new exchange rate based on the AMM algorithm
    exchangeRate = calculateExchangeRate();
}
function calculateExchangeRate() internal view returns (uint256) {
    // Use an AMM algorithm to calculate the new exchange rate based on the total supply and total ether balance
    // Example algorithm: y = k / x where y is the exchange rate, x is the total supply and k is the total ether balance
    return totalEtherBalance / _totalSupply;
}
function calculateTokenValue() public view returns (uint256) {
    // Retrieve the user's token balance
    address user = msg.sender;
    uint256 tokenBalance = balanceOf(user);
    // Calculate the value of the tokens using the exchange rate
    return tokenBalance * exchangeRate;
}
function buy() public payable nonReentrant onlyBuyAndConstructor{
    // Make sure the amount of ether sent is greater than 0
    require(!paused || msg.sender == owner, "Buying tokens is currently paused.");
    require(lastCallTime + minTimeBetweenCalls <= block.timestamp, "Function can only be called once every 60 seconds.");
    lastCallTime = block.timestamp;
    require(!suspendedAddresses[msg.sender], "Sender address is suspended");
    require(msg.value > 0, "Amount of ether must be greater than zero.");
	require(msg.value >= exchangeRate * 100, "Minimum amount of ether to buy tokens is 100 times the exchange rate.");
    require(exchangeRate > 0, "Exchange rate cannot be zero.");
    require(lastBuyBlockNumber[msg.sender] != block.number, "Sender has already bought tokens during this block.");
    // Check if the buyer has enough ether to cover the amount of tokens they are trying to buy
    require(msg.value >= exchangeRate);
    // Update the total ether balance
    uint256 fee = msg.value * transactionFeePercentage / 100;
    totalEtherBalance += msg.value - fee;
    // Calculate the number of tokens that will be added to the buyer's balance
    uint256 tokensToBeAdded = (msg.value - fee) / exchangeRate * tokenDistributionFactor / 100;
    // Add the tokens that will be added to the buyer's balance to the buyer's balance
    _mint(msg.sender, tokensToBeAdded);
    // Send the fee to the designated recipient
    feeRecipient.transfer(fee);
    emit LogBuy( tokensToBeAdded, exchangeRate, msg.sender, msg.value, fee);
    // Calculate the new exchange rate based on the AMM algorithm
    exchangeRate = calculateExchangeRate(); 
}
function sell(uint256 amount) public payable nonReentrant onlySell{
     // Check that the user has enough tokens to sell
    require(lastCallTime + minTimeBetweenCalls <= block.timestamp, "Function can only be called once every 60 seconds.");
    lastCallTime = block.timestamp;
    require(!suspendedAddresses[msg.sender], "Sender address is suspended");
    require(amount > 0, "Amount of tokens to be sold must be greater than zero.");
    require(balanceOf(_msgSender()) >= amount);
    require(exchangeRate > 0, "Exchange rate cannot be zero.");
    require(lastSellBlockNumber[msg.sender] < block.number, "Sender has already sold tokens during this block.");
    // Calculate the amount of ether to be sent to the seller
    uint256 etherToBeSent = amount * exchangeRate;
    // Calculate the transaction fee
    uint256 fee = etherToBeSent * transactionFeePercentage / 100;
    // Subtract the fee from the ether to be sent to the seller
    etherToBeSent -= fee;
    // Update the total ether balance
    totalEtherBalance -= etherToBeSent + fee;
    // Burn the desired number of tokens from the seller's balance
    _burn(_msgSender(), amount);
    // Send the ether (minus the fee) to the seller
    address payable seller = payable(_msgSender());
    seller.transfer(etherToBeSent); 
    // Send the fee to the specified address
    feeRecipient.transfer(fee);
    emit LogSell(seller, amount, exchangeRate, etherToBeSent, fee);
    // Calculate the new exchange rate based on the AMM algorithm
    exchangeRate = calculateExchangeRate();
}
function transfer(address from,address to,uint256 amount ) internal onlyEOA(to) virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(msg.sender != to, "Cannot transfer tokens to yourself");
        require(_balances[to] + amount > _balances[to], "Transfer amount causes integer overflow");
        require(lastCallTime + minTimeBetweenCalls <= block.timestamp, "Function can only be called once every 10 seconds.");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
         _balances[from] = fromBalance - amount;
         _balances[to] += amount;
        _afterTokenTransfer(from, to, amount);
}
function _mint(address account, uint256 amount) internal virtual onlyBuyAndConstructor {
    require(account != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(0), account, amount);
    _totalSupply += amount;
     _balances[account] += amount;
     _afterTokenTransfer(address(0), account, amount);
}
function _burn(address account, uint256 amount) internal virtual onlySell{
    require(account != address(0), "ERC20: burn from the zero address");
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");   
     _totalSupply -= amount;
     _balances[account] = accountBalance - amount;  
}
    function _burnFromTotalSupply(uint256 amount) internal onlySell{
    // Decrease the total supply by the specified amount
    _totalSupply = _totalSupply - amount;
   }
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    // Override this function to execute code before a token transfer
}
function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    // Override this function to execute code after a token transfer
}
}