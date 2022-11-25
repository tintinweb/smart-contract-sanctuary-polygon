// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IObjectMarketplaceManager.sol";

contract MarketplaceManager is IObjectMarketplaceManager, Ownable {
    
    uint256 public marketplaceFeePoints;
    address public feeReceiver;

    mapping(address => bool) private authorizedERC20;
    mapping(address => bool) private authorizedObject;

    modifier noZeroAddress(address newAddress){
        if(newAddress == address(0)){
            revert ZeroAddress();
        } else {
            _;
        }
    }

    constructor(uint256 marketplaceFee, address initialFeeReceiver, address[] memory initialERC20, address[] memory initialObject) noZeroAddress(initialFeeReceiver) {

        marketplaceFeePoints = marketplaceFee;
        feeReceiver  = initialFeeReceiver;

        for (uint256 i = 0; i < initialERC20.length; i++){
            addAuthorizedERC20(initialERC20[i]);
        }

        for (uint256 i = 0; i < initialObject.length; i++){
            addAuthorizedObject(initialObject[i]);
        }
    }
    
    /// @notice changes marketplace fee
    /** 
     * @dev 1% fee is 100 points in @param newFee
     * @param newFee is the amount set as the marketplace fee for every item sold
     * */
    function setMarketplaceFees(uint256 newFee) external onlyOwner {
        marketplaceFeePoints = newFee;

        emit MarketplaceFeeChanged(newFee, block.timestamp);
    }

    /// @notice modify receiver of marketplace fees 
    /**
     * @param newReceiver address of new marketplace fees receiver
     */
    function setFeeReceiver(address newReceiver) external onlyOwner {
        feeReceiver = newReceiver;

        emit FeeReceiverChanged(newReceiver, block.timestamp);
    }

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newToken token to be added to permissions
     */
    function addAuthorizedERC20(address newToken) public noZeroAddress(newToken) onlyOwner{

        if(authorizedERC20[newToken] == true){
            revert AlreadyAuthorized();
        }
        authorizedERC20[newToken] = true;

        emit AddedPermission(newToken, block.timestamp);
    }
    
    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /**
     * @param token token to be revoked permission
     */
    function deleteAuthorizedERC20(address token) external noZeroAddress(token) onlyOwner{

        if(authorizedERC20[token] == false){
            revert UnauthorizedERC20();
        }

        authorizedERC20[token] = false;

        emit EliminatedPermission(token, block.timestamp);
    }

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newObject new NFT object to be added to the authorized list
     */
    function addAuthorizedObject(address newObject) public noZeroAddress(newObject) onlyOwner{

        if(authorizedObject[newObject] == true){
            revert AlreadyAuthorized();
        }
        authorizedObject[newObject] = true;

        emit AddedPermission(newObject, block.timestamp);
    }
    
    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /** 
     * @param object NFT to be revoked authorization
     */
    function deleteAuthorizedObject(address object) external noZeroAddress(object) onlyOwner{

        if(authorizedObject[object] == false){
            revert UnauthorizedObject();
        }

        authorizedObject[object] = false;

        emit EliminatedPermission(object, block.timestamp);
    }

    /// @notice check if token is authorized
    /**
     * @param token token to be checked
     */
    function checkAuthorizedERC20(address token) external view returns (bool){
        return authorizedERC20[token];
    }

    /// @notice check if object is authorized
    /**
     * @param object object to be checked
     */
    function checkAuthorizedObject(address object) external view returns (bool){
        return authorizedObject[object];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IObjectMarketplaceManager {
    
    error AlreadyAuthorized();
    error UnauthorizedERC20();
    error UnauthorizedObject();
    error ZeroAddress();
    
    // Emitted after granting authorization to a new NFT/ERC20 address
    event AddedPermission(address authorized, uint256 timestamp);
    // Emitted after revoking authorization to a previously authorized NFT/ERC20 address
    event EliminatedPermission(address Unauthorized, uint256 timestamp);
    // Emitted after changing the recipient of marketplace fees
    event FeeReceiverChanged(address newReceiver, uint256 timestamp);
    // Emitted after changing the marketplace fee amount
    event MarketplaceFeeChanged(uint256 newFee, uint256 timestamp);

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newToken token to be added to permissions
     */
    function addAuthorizedERC20(address newToken) external;

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newObject new NFT object to be added to the authorized list
     */
    function addAuthorizedObject(address newObject) external;
    
    /// @notice check if token is authorized
    /**
     * @param token token to be checked
     */
    function checkAuthorizedERC20(address token) external view returns (bool);

    /// @notice check if object is authorized
    /**
     * @param object object to be checked
     */
    function checkAuthorizedObject(address object) external view returns (bool);

    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /**
     * @param token token to be revoked permission
     */
    function deleteAuthorizedERC20(address token) external;

    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /** 
     * @param object NFT to be revoked authorization
     */
    function deleteAuthorizedObject(address object) external;

    /// @notice changes marketplace fee
    /** 
     * @dev 1% fee is 100 points in @param newFee
     * @param newFee is the amount set as the marketplace fee for every item sold
     * */
    function setMarketplaceFees(uint256 newFee) external;

    /// @notice modify receiver of marketplace fees 
    /**
     * @param newReceiver address of new marketplace fees receiver
     */
    function setFeeReceiver(address newReceiver) external;
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