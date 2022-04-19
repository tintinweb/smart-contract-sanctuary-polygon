// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelistable is Ownable {

    address public whitelister;
    bool public whitelistEnabled;
    mapping(address => bool) internal whitelisted;
    uint256 public whitelistEndTime;

    event AddedWhitelist(address indexed _account);
    event RemovedWhitelist(address indexed _account);
    event NewWhitelistEndTime(uint256 _whitelistEndTime);
    event WhitelisterChanged(address indexed newWhitelister);

    /**
     * @dev Throws if called by any account other than the whitelister
     */
    modifier onlyWhitelister() {
        require(
            msg.sender == whitelister,
            "Whitelistable: caller is not the whitelister"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when setting the whitelist is not ended.
     */
    modifier whenNotEnded() {
        require(
            block.number < whitelistEndTime,
            "Whitelistable: set whitelist time is over"
        );
        _;
    }

    /**
     * @dev Throws if argument account is whitelisted
     * @param _account The address to check
     */
    modifier Whitelisted(address _account) {
        if(whitelistEnabled){
            require(
                whitelisted[_account],
                "Whitelistable: account is not whitelisted"
            );
        }
        _;
    }

    /**
     * @notice It allows the admin to update set whitelist end time
     * @param _whitelistEndTime: the new whitelist end time
     * @dev This function is only callable by admin.
     */
    function updateWhitelistEndTime(uint256 _whitelistEndTime) external onlyOwner {
        require(block.number < _whitelistEndTime, "Whitelistable::updateWhitelistEndTime: New whitelistEndTime must be higher than current block");

        whitelistEndTime = _whitelistEndTime;

        emit NewWhitelistEndTime(_whitelistEndTime);
    }

    /**
     * @dev Checks if account is whitelisted
     * @param _account The address to check
     */
    function isWhitelisted(address _account) external view returns (bool) {
        return whitelisted[_account];
    }

    /**
     * @dev Adds account to whitelist
     * @param _account The address to whitelist
     */
    function addWhitelist(address _account) external onlyWhitelister whenNotEnded {
        _addWhitelistInternal(_account);
    }

    /**
     * @dev Adds account to whitelist
     * @param _accounts The addresses to whitelist
     */
    function addWhitelists(address[] memory _accounts) external onlyWhitelister whenNotEnded {
        for (uint i = 0; i < _accounts.length; i++) {
            _addWhitelistInternal(_accounts[i]);
        }
    }

    function _addWhitelistInternal(address _account) internal {
        whitelisted[_account] = true;
        emit AddedWhitelist(_account);
    }

    /**
     * @dev Removes account from whitelist
     * @param _account The address to remove from the whitelist
     */
    function removeWhitelist(address _account) external onlyWhitelister whenNotEnded {
        _removeWhitelistInternal(_account);
    }

    /**
     * @dev Removes account from whitelist
     * @param _accounts The addresses to remove from the whitelist
     */
    function removeWhitelists(address[] memory _accounts) external onlyWhitelister whenNotEnded {
        for (uint i = 0; i < _accounts.length; i++) {
            _removeWhitelistInternal(_accounts[i]);
        }
    }

    function _removeWhitelistInternal(address _account) internal {
        whitelisted[_account] = false;
        emit RemovedWhitelist(_account);
    }

    function updateWhitelister(address _newWhitelister) external onlyOwner {
        require(
            _newWhitelister != address(0),
            "Whitelistable: new whitelister is the zero address"
        );
        whitelister = _newWhitelister;
        emit WhitelisterChanged(whitelister);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}