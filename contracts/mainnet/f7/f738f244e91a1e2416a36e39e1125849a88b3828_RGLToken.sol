/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: rgltoken.sol



/*
 w:  https://retrogameslibrary.co.uk
 tw: @retrogamelib
*/

//This token has a max hold amount of 1% of Total Supply and a max transaction size of 0.5% of Total Supply

pragma solidity >=0.8.0 <0.9.0;





contract RGLToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public devWallet;
    address public managementWallet;
    address public communityWallet;
    bool public isPaused;

    uint8 private _decimals;

    uint8 private dFee = 50;    
    uint8 private rFee = 30;
    uint8 private cFee = 20;

    mapping (address => bool) isExemptFromFees;
    mapping (address => bool) isTeamWallet;

    mapping (address => bool) admin;

    uint private maxSupply;

    constructor (
        string memory _setName,
        string memory _setSymbol,
        uint _supply,
        uint8 _setDecimals
        ) {
        _name = _setName;
        _symbol = _setSymbol;
        _decimals = _setDecimals;
        maxSupply = _supply * 10**_decimals;
        devWallet = owner();
        isExemptFromFees[owner()] = true;
    }

    modifier isAdmin() {
        require(admin[_msgSender()], "Caller is not Admin");
        _; 
    }

//onlyOwner() funcs
//Standard set fees function - Capped - when setting: 10 == 1% to allow for percentages to decimal places
    function setFees(uint8 _dFee, uint8 _rFee, uint8 _cFee) public onlyOwner {
        require((_dFee + _rFee + _cFee) <= 100, "Fees cannot exceed 10%");
        dFee = _dFee;
        rFee = _rFee;
        cFee = _cFee;
    }

    function setDevWallet(address _address) public onlyOwner {
        require (devWallet != _address, "This address is already the Dev Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        }
        devWallet = _address;
    }

    function setManagementWallet(address _address) public onlyOwner {
        require (managementWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        managementWallet = _address;
    }

    function setComWallet(address _address) public onlyOwner {
        require (communityWallet != _address, "This address is already the management Wallet");
        if (!isExemptFromFees[_address]) {
            isExemptFromFees[_address] = true;
        } 
        communityWallet = _address;
    }

//Pauses transfers
    function setPause(bool _bool) public onlyOwner {
        require(isPaused != _bool, "isPaused already matches that state");
        isPaused = _bool;
    }
//Adds team wallet with fee exemption
    function addTeamWallet(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as a Team Wallet");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }
        isTeamWallet[_address] = true;
    }

    function removeTeamWallet(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as a Team Wallet");
        removeFeeExemption(_address);
        isTeamWallet[_address] = false;
    }

    function setAdmin(address _address) public onlyOwner {
        require(!isTeamWallet[_address], "Address already registered as admin");
        if (!isExemptFromFees[_address]) {
        isExemptFromFees[_address] = true;
        }
        admin[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        require(isTeamWallet[_address], "Address already not currently registered as admin");
        removeFeeExemption(_address);
        admin[_address] = false;
    }

    function setExemptFromFees(address _address) public onlyOwner {
        require(!isExemptFromFees[_address], "Address is already exempt");
        isExemptFromFees[_address] = true;
    }

    function removeFeeExemption(address _address) public onlyOwner {
        require(_address != owner(), "Owner cannot be removed");
        require(_address != devWallet, "DevWallet cannot be removed. Change DevWallet address first");
        require(_address != managementWallet, "Management Wallet cannot be removed. Change managementWallet address first");
        
        isExemptFromFees[_address] = false; 
    }

//Gets the tax amounts for each normal transaction
    function getTaxAmount(uint256 _amount) private view returns (uint, uint, uint, uint){
        uint _dFee = (_amount * dFee) / 1000;
        uint _rFee = (_amount * rFee) / 1000;
        uint _cFee = (_amount * cFee) / 1000;
        uint _tAmount = _amount - (_dFee + _rFee + _cFee);
        return (_tAmount, _dFee, _rFee, _cFee);
    }

    function mint(address account, uint256 amount) public isAdmin {
        require(_totalSupply + amount <= maxSupply, "You cannot mint more than the max supply");
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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

// transfer function to account for fees
    function _transferNormal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= maxSupply / 200, "Tx amount cant be more than 0.5% of total supply");
        
            (uint _tAmount, uint _dFee, uint _rFee, uint _cFee) = getTaxAmount(amount);
            require(_balances[recipient] + _tAmount <= maxSupply / 100, "Cant hold more than 1% of maxSupply");

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += _tAmount;
            _balances[devWallet] += _dFee;
            _balances[managementWallet] += _rFee;
            _balances[communityWallet] += _cFee;

            emit Transfer(sender, recipient, _tAmount);
            emit Transfer(sender, devWallet, _dFee);
            emit Transfer(sender, managementWallet, _rFee);
            emit Transfer(sender, communityWallet, _cFee);
    }

//Added transfer function for sending to wallets with no max hold limits
    function _transferNoFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

// Means of retrieval in case of tokens being sent to contract
    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), amount), "Transfer failed");
    }

    function withdrawEth(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
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

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

// Adapted transfer call to cater for fee exemptions
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        require(balanceOf(_msgSender()) >= amount, "You don't have enough balance to transfer that amount");
            if (isExemptFromFees[_msgSender()] || isExemptFromFees[recipient]) {
                _transferNoFees(_msgSender(), recipient, amount);
            } else {
                _transferNormal(_msgSender(), recipient, amount);
            }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isPaused, "Transfers are paused, check official announcements for info");
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        if (isExemptFromFees[sender] || isExemptFromFees[recipient]) {
                _transferNoFees(sender, recipient, amount);
        } else {
                _transferNormal(sender, recipient, amount);
            }
      return true;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("cannot renounceOwnership here");
    }

// Public Views

    function checkIfFeeExempt(address _address) public view returns (bool) {
        return isExemptFromFees[_address];
    }

    function checkIfTeam(address _address) public view returns (bool) {
        return isTeamWallet[_address];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function communityBalance() public view returns (uint256) {
        return balanceOf(communityWallet);
    }

    function fees() public view returns (uint8) {
        uint8 _fees = (dFee + cFee) + rFee;
        return (_fees);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    receive() external payable {}
}