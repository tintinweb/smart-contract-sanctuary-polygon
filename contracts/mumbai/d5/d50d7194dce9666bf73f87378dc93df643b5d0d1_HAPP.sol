/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


contract HAPP is ERC20, Ownable {

    using Counters for Counters.Counter;

    uint256 private constant MAX_CLAIM_COUNT = 24;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _claimed;
    mapping (address => string) private _btcAddresses;
    mapping(string => address) private _btcToAddress;
    mapping (address => uint256) private _claimCount;
    mapping(bytes32 => Order) private _orders;

    Counters.Counter private _orderIds;

    event DepositToOrder(
        bytes32 indexed orderId,
        address indexed depositor,
        address indexed destinationCoin,
        uint256 amount
    );

    event CompleteOrder(bytes32 indexed orderId, address indexed sender, address destinationCoin, uint256 amount);


    struct Order {
        address sender;
        address destinationCoin;
        uint256 amount;
        string btcAddress;
        uint256 status; // 0: Pending, 1: Completed, 2: Failed
    }
    
    constructor() ERC20("BRC20 HAPP", "HAPP") {
       _mint(address(this), 18900000 * (10 ** decimals()));
       _mint(msg.sender, 2100000 * (10 ** decimals()));
    }

    function claimTokens(string memory btcAddress, uint256 claimCount) public payable {
        uint256 claimAmount = claimCount * 1000 * (10 ** decimals());
        require(balanceOf(address(this)) >= claimAmount, "Contract balance is not enough.");
        require(msg.value == 0.01 ether * claimCount, "You need to pay ETH for each claim.");
        require(claimCount > 0 && claimCount <= MAX_CLAIM_COUNT, "You can only claim between 1 and 24 times.");
        require(_claimCount[msg.sender] + claimCount <= MAX_CLAIM_COUNT, "You can only claim up to 24 times.");
        _balances[msg.sender] += claimAmount;
        _btcAddresses[msg.sender] = btcAddress;
        _btcToAddress[btcAddress] = msg.sender;
        _claimCount[msg.sender] += claimCount;
        _transfer(address(this), msg.sender, claimAmount);
        emit Transfer(address(this), msg.sender, claimAmount);
    }

    function depositToOrder(string memory btcAddress,address destinationCoin, uint256 amount) public {
        require(bytes(_btcAddresses[msg.sender]).length != 0, "Please set your BTC address first.");
        require(amount > 0, "Amount should be greater than zero.");
        ERC20 token = ERC20(destinationCoin);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, destinationCoin, amount, block.timestamp));
        _orders[orderId] = Order(msg.sender, destinationCoin, amount,btcAddress, 0);
        emit DepositToOrder(orderId, msg.sender, destinationCoin, amount);
    }

    function withdrawToken(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero.");
        require(tokenAddress != address(this), "Token address cannot be this.");
        require(recipient != address(0), "Recipient address cannot be zero.");
        require(amount > 0, "Amount must be greater than zero.");    
        ERC20 token = ERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance.");    
        bool success = token.transfer(recipient, amount);
        require(success, "Transfer failed.");
    }

    function getOrder(bytes32 orderId) public view returns (Order memory) {
        return _orders[orderId];
    }

    function completeOrder(bytes32 orderId) public onlyOwner {
        require(_orders[orderId].status == 0, "Order is not pending.");
        _orders[orderId].status = 1;
        ERC20 token = ERC20(_orders[orderId].destinationCoin);
        require(token.transfer(_orders[orderId].sender, _orders[orderId].amount), "Token transfer failed.");
        emit CompleteOrder(orderId, _orders[orderId].sender, _orders[orderId].destinationCoin, _orders[orderId].amount);
    }

    function setBTCAddress(string memory btcAddress) public {
        require(bytes(btcAddress).length > 0, "BTC address can't be empty");
        _btcAddresses[msg.sender] = btcAddress;
        _btcToAddress[btcAddress] = msg.sender;
    }

    function getAddressByBTC(string memory btcAddress) public view returns (address) {
        return _btcToAddress[btcAddress];
    }

    function getBTCByAddress(string memory btcAddress) public view returns (address) {
        return _btcToAddress[btcAddress];
    }

}