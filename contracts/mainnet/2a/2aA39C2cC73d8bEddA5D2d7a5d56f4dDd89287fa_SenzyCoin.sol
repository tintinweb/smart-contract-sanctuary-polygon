/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

pragma solidity ^0.8.0;
/** 
    This contract is the Senzy Coin ($SENZY) smart contract
    It will be deployed on different networks with exactly 
    same contract address based on deployer's 0 nonce
**/

contract SenzyCoin is Ownable, ERC20 {
    address public marketFeeAddress;
    uint256 public burnFeePercentage; 
    uint256 public marketFeePercentage;
    uint256 private constant MAX_BURN_FEE_PERCENTAGE = 25;
    uint256 private constant MAX_MARKET_FEE_PERCENTAGE = 15;

    mapping(address => bool) public blacklists;
    mapping(address => uint256) public burnedTokens;
    mapping(address => bool) private _excludedFromFee;

    event MarketFeeAddressUpDated(address indexed marketFeeAddress);
    event BurnFeePercentageUpDated(uint256 burnFeePercentage);
    event MarketFeePercentageUpDated(uint256 marketFeePercentage);
    event Burned(address indexed from, uint256 value);
    event MarketingFee(address indexed from, uint256 value);

    constructor(uint256 _totalSupply) ERC20("Senzy Coin", "SENZY") {
        _mint(msg.sender, _totalSupply);
        _excludedFromFee[msg.sender] = true;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setMarketFeeAddress(address _marketFeeAddress) external onlyOwner {
        marketFeeAddress = _marketFeeAddress;
        emit MarketFeeAddressUpDated(_marketFeeAddress);
    }

    function setBurnFeePercentage(uint256 _burnFeePercentage) external onlyOwner {
        require(_burnFeePercentage <= MAX_BURN_FEE_PERCENTAGE, "Exceeded maximum burn fee percentage; Max Burn fee is 2,5%");
        burnFeePercentage = _burnFeePercentage;
        emit BurnFeePercentageUpDated(_burnFeePercentage);
    }

    function setMarketFeePercentage(uint256 _marketFeePercentage) external onlyOwner {
        require(_marketFeePercentage <= MAX_MARKET_FEE_PERCENTAGE, "Exceeded maximum market fee percentage; Max Marketing fee is 1,5%");
        marketFeePercentage = _marketFeePercentage;
        emit MarketFeePercentageUpDated(_marketFeePercentage);
    }

    function excludeFromFee(address account) external onlyOwner {
        _excludedFromFee[account] = true;
    }

    function removeFromFeeExclusion(address account) external onlyOwner {
        _excludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _excludedFromFee[account];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value > 0, "Invalid transfer amount.");
        require(balanceOf(msg.sender) >= value, "Insufficient balance.");
        require(!blacklists[msg.sender], "Sender is blacklisted.");

        uint256 transferAmount = value;
        uint256 burnAmount = 0;
        uint256 marketFeeAmount = 0;

        if (!_excludedFromFee[msg.sender] && msg.sender != owner()) {
            burnAmount = (value * burnFeePercentage) / 1000;
            marketFeeAmount = (value * marketFeePercentage) / 1000;
            transferAmount = value - burnAmount - marketFeeAmount;
            }

        _transfer(msg.sender, to, transferAmount);

        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
            emit Burned(msg.sender, burnAmount);
            }

        if (marketFeeAmount > 0) {
            _transfer(msg.sender, marketFeeAddress, marketFeeAmount);
            emit MarketingFee(msg.sender, marketFeeAmount);
            }

        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
        burnedTokens[msg.sender] += value;
        emit Burned(msg.sender, value);
    }

    function getBurnedTokens(address account) public view returns (uint256) {
        return burnedTokens[account];
    }

    receive() external payable {
        if (msg.value > 0) {
            payable(marketFeeAddress).transfer(msg.value);
        }
    }

}