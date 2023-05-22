/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: dappsocial_contracts/Ownable.sol


pragma solidity ^0.8.19;


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

// File: dappsocial_contracts/IERC20.sol



pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// File: dappsocial_contracts/DAppSocialPool.sol


pragma solidity ^0.8.18;



contract DAppSocialPool is Ownable {

    enum RequestStatus {
        CREATED,
        CANCELLED,
        ACCEPTED,
        COMPLETED
    }

    struct Request {
        uint8 fromChain;
        uint8 toChain;
        address tokenAddress;
        address fromAddress;
        address toAddress;
        RequestStatus status;
        uint256 amount;
        uint256 amountToClaim;
        bool isClaimed;
        uint256 expTime;
    }

    mapping (address => uint256) _nativeBalances; // Native Coin Balances Address => Value
    mapping (address => uint256) _pendingNativeBalances; 
    mapping (address => mapping(address => uint256)) _tokenBalances; // Token Balances Token => Address => Value
    mapping (address => mapping(address => uint256)) _pendingTokenBalances; // Token Balances Token => Address => Value
    mapping (uint256 => mapping(address => uint256)) _createdRecords; // Id => Address => Amount
    mapping (uint256 => mapping(address => uint256)) _acceptedRecords; // Id => Address => Amount
    mapping (address => bool) _supportedTokens;
    mapping (uint256 => Request) _requests;
    mapping (address => bool) _adminList;
    address private exchangeAddress;

    uint256 serviceFee = 15 * 10**6; // 6 decimals for USDT / USDC
    uint256 platformFee = 5 * 10**6; // 6 decimals for USDT / USDC

    address private adminAddress;


    event TokenSupport_Added(address indexed, bool);
    event TokenSupport_Removed(address indexed, bool);
    event Deposit(address indexed, uint256);
    event Withdrawn(address indexed, uint256);

    event TokenDeposited(address indexed, address indexed, uint256);
    event TokenWithdrawn(address indexed, address indexed, uint256);
    event TokenRequested(address indexed tokenAddress, address indexed fromAddress, uint256 amount);
    event TokenAccepted(address indexed tokenAddress, address indexed fromAddress, address toAddress, uint256 amount);
    event TokenUpdated(address indexed tokenAddress, address indexed fromAddress, address toAddress, uint256 amount);
    event TokenCancelled(address indexed tokenAddress, address indexed fromAddress, uint256 amount);
    event AdminAddressAdded(address indexed oldAdderess, bool flag);
    event AdminAddressRemoved(address indexed oldAdderess, bool flag);


    error FailedETHSend();

    constructor() {
        // adminAddress = msg.sender;
    }

    function addAdmin(address newAddress) external onlyOwner{
        require(!_adminList[newAddress], "Address is already Admin");
        _adminList[newAddress] = true;
        emit AdminAddressAdded(newAddress, true);
    }

    function removeAdmin(address oldAddress) external onlyOwner {
        require(_adminList[oldAddress], "The Address is not admin");
        _adminList[oldAddress] = false;
        emit AdminAddressRemoved(oldAddress, false);
    }

    modifier adminOnly() {
        require(_adminList[msg.sender], "only Admin action");
        _;
    }

    modifier exchangeOnly() {
        require(exchangeAddress == msg.sender, "only Exchange action");
        _;
    }

    function addSupportedToken(address tokenAddress) external adminOnly {
        _supportedTokens[tokenAddress] = true;
        emit TokenSupport_Added(tokenAddress, true);
    }

    function removeSupportedToken(address tokenAddress) external adminOnly {
        _supportedTokens[tokenAddress] = false;
        emit TokenSupport_Removed(tokenAddress, false);
    }

    function updateExchange(address newAddress) external onlyOwner {
        exchangeAddress = newAddress;
    }

    function depositETH() external payable {
        require(msg.value > 0, "Amount should be greater than 0");
        _nativeBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function depositTokens(address tokenAddress, uint256 amount) external {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _tokenBalances[tokenAddress][msg.sender] += amount;
        emit TokenDeposited(tokenAddress, msg.sender, amount);

    }

    function withdrawETH(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _nativeBalances[msg.sender], "Not Enough Amount available to withdraw");
        _nativeBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(msg.sender, amount);
        } else {
            revert FailedETHSend();
        }

    }

    function transferETH(address fromAddress, uint256 amount) external exchangeOnly {
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _nativeBalances[fromAddress], "Not Enough Amount available to withdraw");
        _nativeBalances[fromAddress] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(fromAddress, amount);
        } else {
            revert FailedETHSend();
        }
    }

    function transferPendingETH(address fromAddress, uint256 amount) external exchangeOnly {
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _pendingNativeBalances[fromAddress], "Not Enough Amount available to withdraw");
        _pendingNativeBalances[fromAddress] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(fromAddress, amount);
        } else {
            revert FailedETHSend();
        }
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to withdraw");
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    function getNativeBalance() external view returns (uint256) {
        return _nativeBalances[msg.sender];
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        return _tokenBalances[tokenAddress][msg.sender];
    }

    function getNativeBalance(address account) external view returns (uint256) {
        return _nativeBalances[account];
    }

    function getTokenBalance(address tokenAddress, address account) external view returns (uint256) {
        return _tokenBalances[tokenAddress][account];
    }

    function getPendingTokenBalance(address tokenAddress, address account) external view returns (uint256) {
        return _pendingTokenBalances[tokenAddress][account];
    }

    function getPendingNativeBalance(address account) external view returns (uint256) {
        return _pendingNativeBalances[account];
    }

    function placeTPBid(address account, uint256 amount) external exchangeOnly {
        _nativeBalances[account] -= amount;
        _pendingNativeBalances[account] += amount;
    }

    function cancelOrClaimTPBid(address account, uint256 amount) external exchangeOnly {
        _nativeBalances[account] += amount;
        _pendingNativeBalances[account] -= amount;
    }

    function requestTokens(uint256 id, address tokenAddress, uint256 amount) external {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to transfer");
        require(amount >= serviceFee, "Not Enough amount available to cover the Fee");
        _createdRecords[id][tokenAddress] = amount;
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        _pendingTokenBalances[tokenAddress][msg.sender] += amount;
        emit TokenRequested(tokenAddress, msg.sender, amount);
    }

    function createRecord(uint256 id, address tokenAddress, uint256 amount) external adminOnly {
        require(_supportedTokens[tokenAddress], "Token is not supported");
        _acceptedRecords[id][tokenAddress] = amount;

    }

    function acceptRequest(uint256 id, address tokenAddress, address toAddress) external {
        require(_acceptedRecords[id][tokenAddress] != 0, "Invalid record");
        uint256 amount = _acceptedRecords[id][tokenAddress];
        require(amount >= _tokenBalances[tokenAddress][msg.sender], "Not Enough Amount available to support transfer");
        _tokenBalances[tokenAddress][msg.sender] -= amount;
        _tokenBalances[tokenAddress][toAddress] += amount;
        _acceptedRecords[id][tokenAddress] = 0;
        emit TokenAccepted(tokenAddress, msg.sender, toAddress, amount);
    }

    function updateAmount(uint256 id, address tokenAddress, address fromAddress, address toAddress, uint256 initialAmount, uint256 amount) external adminOnly {
        require(_createdRecords[id][tokenAddress] != 0, "Invalid record");
        _tokenBalances[tokenAddress][toAddress] += amount;
        _pendingTokenBalances[tokenAddress][fromAddress] -= initialAmount;
        _createdRecords[id][tokenAddress] = 0;
        emit TokenUpdated(tokenAddress, fromAddress, toAddress, amount);
    }

    function cancelRequest(address tokenAddress, address fromAddress, uint256 initialAmount) external adminOnly {
        require(_pendingTokenBalances[tokenAddress][fromAddress] >= initialAmount, "Not enough balance to cancel");
        _pendingTokenBalances[tokenAddress][fromAddress] -= initialAmount;
        _tokenBalances[tokenAddress][fromAddress] += initialAmount;
        emit TokenCancelled(tokenAddress, fromAddress, initialAmount);
    }

}