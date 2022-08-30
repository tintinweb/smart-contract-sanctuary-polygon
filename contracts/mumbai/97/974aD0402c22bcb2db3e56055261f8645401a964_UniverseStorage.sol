// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/Context.sol";
import "./interface/IUniverseStorage.sol";

/**
 * Universe Storage Contract for User
 */
contract UniverseStorage is Context {
    mapping(address => bool) private accessAllowed;

    address public userAddress;
    address public immutable universeFactory;

    bytes[] private userEncryptedPersonalInfo;

    event SetUserData(uint setTime);

    constructor() {
        universeFactory = _msgSender();
    }

    /**
     * @dev Initialize Contract
     */
    function initialize(address _userAddress, bytes[] memory _userData) external {
        require(_msgSender() == universeFactory, "Universe: FORBIDDEN");
        userAddress = _userAddress;
        userEncryptedPersonalInfo = _userData;
        accessAllowed[_userAddress] = true;
    }

    /**
     * @dev Write User's Encryped Data on contract, only User call it
     */
    function writeUserData(bytes[] memory _inputData) external {
        require(msg.sender == userAddress, "Universe: Only Owner could write data");

        userEncryptedPersonalInfo = _inputData;

        emit SetUserData(block.timestamp);
    }

    /**
     * @dev Get User's Encryped Data on contract
     */
    function getUserData() external view returns (bytes[] memory info) {
        if(accessAllowed[msg.sender]) info = userEncryptedPersonalInfo;
    }

    /**
     * @dev Check User's Access Permission
     */
    function checkAllowance(address user) external view returns(bool allowed) {
        allowed = accessAllowed[user] ? true : false;
    }

    /**
     * @dev Set Permission to User
     */
    function setAllowance(address user, bool flag) external {
        require(msg.sender == userAddress, "Not user");
        
        accessAllowed[user] = flag;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniverseStorage {
    function initialize(address _userAddress, bytes[] memory _userData) external;

    function writeUserData(bytes[] memory _inputData) external;
    
    function getUserData() external view returns (bytes[] memory);
}