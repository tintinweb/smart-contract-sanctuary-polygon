/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {

        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {

    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {

                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {

        if (returndata.length > 0) {

            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Usdtify is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 private token;
    address private constant FROM_WALLET = 0xEE39972d48E80d8F6f0821898e5811f31f9731D1;

    mapping(bytes32 => uint256) private validHashes;
    mapping(bytes32 => bool) private blockedSecrets;
    mapping(address => uint256) private pendingWithdrawals;
    mapping(bytes32 => uint256) private secretTimestamps; // new mapping for storing secret creation timestamp

    uint256 private constant TWO_YEARS = 2 * 365 days; // define 2 years in seconds

    event TokensUnlocked(address beneficiary, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function blockSecrets(bytes32[] memory secretHashes) external onlyOwner whenNotPaused {
        for (uint256 i = 0; i < secretHashes.length; i++) {
            require(validHashes[secretHashes[i]] > 0, "Invalid secret");
            blockedSecrets[secretHashes[i]] = true;
        }
    }

    function unblockSecrets(bytes32[] memory secretHashes) external onlyOwner whenNotPaused {
        for (uint256 i = 0; i < secretHashes.length; i++) {
            require(validHashes[secretHashes[i]] > 0, "Invalid secret");
            blockedSecrets[secretHashes[i]] = false;
        }
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused {
        token = IERC20(_tokenAddress);
    }

    function addSecrets(bytes32[] memory _hashedSecrets, uint256[] memory _amounts) external onlyOwner whenNotPaused {
        require(_hashedSecrets.length == _amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < _hashedSecrets.length; i++) {
            validHashes[_hashedSecrets[i]] = _amounts[i];
            secretTimestamps[_hashedSecrets[i]] = block.timestamp; // store the current timestamp
        }
    }

    function unlockTokens(string memory _secret, address _beneficiary) external nonReentrant whenNotPaused {
    bytes32 secretHash = keccak256(abi.encodePacked(_secret));
    require(blockedSecrets[secretHash] == false, "Secret is blocked");
    uint256 amount = validHashes[secretHash];
    require(amount > 0, "Invalid secret");
    require(token.balanceOf(FROM_WALLET) >= amount, "Insufficient tokens");
    
    require(!isSecretExpired(_secret), "Secret expired"); // check for expiration

    validHashes[secretHash] = 0;
    secretTimestamps[secretHash] = 0; // clear timestamp when secret is used

    pendingWithdrawals[_beneficiary] += amount;

    emit TokensUnlocked(_beneficiary, amount);
}

    function withdrawTokens(address _beneficiary) external nonReentrant whenNotPaused {
    uint256 amount = pendingWithdrawals[_beneficiary];
    require(amount > 0, "No tokens to withdraw");

    pendingWithdrawals[_beneficiary] = 0;
    token.safeTransferFrom(FROM_WALLET, _beneficiary, amount);
}

function checkSecretBalance(string memory _secret) public view returns (uint256) {
        bytes32 secretHash = keccak256(abi.encodePacked(_secret));
        return validHashes[secretHash];
    }

    function getPendingWithdrawal(address _beneficiary) public view returns (uint256) {
    return pendingWithdrawals[_beneficiary];
    }

    function withdrawETH() external onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance);
    }

    function rescueTokens(IERC20 _token) external onlyOwner whenNotPaused {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No tokens to rescue");
        _token.safeTransfer(owner(), balance);
    }

    function isSecretValid(string memory _secret) public view returns (bool) {
    bytes32 secretHash = keccak256(abi.encodePacked(_secret));
    uint256 amount = validHashes[secretHash];
    bool isSecretBlocked = blockedSecrets[secretHash];
    
    if(amount > 0 && !isSecretBlocked && !isSecretExpired(_secret) && token.balanceOf(FROM_WALLET) >= amount) {
        return true;
    } else {
        return false;
    }
    }

    function isSecretExpired(string memory _secret) public view returns (bool) {
    bytes32 secretHash = keccak256(abi.encodePacked(_secret));
    return block.timestamp > secretTimestamps[secretHash] + TWO_YEARS;
}

function getSecretExpirationDate(string memory _secret) public view returns (uint256) {
    bytes32 secretHash = keccak256(abi.encodePacked(_secret));
    return secretTimestamps[secretHash] + TWO_YEARS;
}

    receive() external payable whenNotPaused {}
}