/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: Brit/FeeManagement.sol


pragma solidity ^0.8.0;


library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


contract BritGoldFeeManagement is Ownable {

    uint256 public managementFee;

    address private safeAddress;

    uint256 public startTime;

    struct ManagementFees {
        bool paid;
        uint256 amount;
        uint256 timestamp;
        address paidBy;
        address token;
    }

    mapping(uint256 => mapping(uint256=>ManagementFees)) public feeData;

    mapping(address=>bool) public tokenAllowed;

    event ManagementFeeSet(uint256 managementFee);
    event ManagementFeeCollected(uint256 indexed tokenId, uint256 yearCount, uint256 managementFee, address payer, address token);
    
    
    constructor(uint256 _managementFee, uint256 _startTime) {
        managementFee = _managementFee;
        startTime = _startTime;
    }
    
    function setManagementFee(uint256 newFee) external onlyOwner {
        managementFee = newFee;
        emit ManagementFeeSet(newFee);
    }

    function setTokenAllowed(address token, bool status) external onlyOwner {
        tokenAllowed[token] = status;
    }

    function setSafeAddress(address safe) external onlyOwner {
        safeAddress = safe;
    }

    function payManagementFees(uint256 tokenId, uint256 yearCount, address token) external {
        require(tokenAllowed[token], "Token not allowed");
        require(!feeData[tokenId][yearCount].paid, "Fees Already Paid");
        uint256 fees = managementFee;
        TransferHelper.safeTransferFrom(token, msg.sender, safeAddress, fees);
        feeData[tokenId][yearCount] = ManagementFees({
            paid: true, 
            amount: fees,
            paidBy: msg.sender,
            timestamp: block.timestamp,
            token: token
            });
        emit ManagementFeeCollected(tokenId, yearCount, managementFee, msg.sender, token);
    }
    
    function isFeesPaid(uint256 tokenId, uint256 yearCount) public view returns (bool) {
        return feeData[tokenId][yearCount].paid;
    }
    
    function feesData(uint256 tokenId, uint256 yearCount) public view returns (ManagementFees memory data) {
        return feeData[tokenId][yearCount];
    }

    function getYearCounter() public view returns (uint256) {
        uint256 yearCount = block.timestamp - startTime > 365 days ? (block.timestamp - startTime) / 365 days : 0;
        return yearCount;
    }

}