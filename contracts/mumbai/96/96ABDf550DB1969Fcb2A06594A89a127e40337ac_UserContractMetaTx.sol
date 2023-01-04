// SPDX-License-Identifier: MIT
/*
/$$      /$$                  /$$                  /$$$$$$                      /$$                    
|  $$   /$$/                 | $$                 /$$__  $$                    |__/                    
 \  $$ /$$//$$$$$$  /$$   /$$| $$  /$$$$$$       | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$  /$$$$$$$ 
  \  $$$$//$$__  $$|  $$ /$$/| $$ /$$__  $$      | $$$$$$$$ /$$__  $$ /$$__  $$| $$ |____  $$| $$__  $$
   \  $$/| $$$$$$$$ \  $$$$/ | $$| $$$$$$$$      | $$__  $$| $$  \ $$| $$  \ $$| $$  /$$$$$$$| $$  \ $$
    | $$ | $$_____/  >$$  $$ | $$| $$_____/      | $$  | $$| $$  | $$| $$  | $$| $$ /$$__  $$| $$  | $$
    | $$ |  $$$$$$$ /$$/\  $$| $$|  $$$$$$$      | $$  | $$| $$$$$$$/| $$$$$$$/| $$|  $$$$$$$| $$  | $$
    |__/  \_______/|__/  \__/|__/ \_______/      |__/  |__/| $$____/ | $$____/ |__/ \_______/|__/  |__/
                                                           | $$      | $$                              
                                                           | $$      | $$                              
                                                           |__/      |__/                                                                                                                                                                   
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UserContractMetaTx is ERC2771Context, Ownable{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error notAdmin();
    error addressAlreadyRegistered();
    error zeroAddressNotSupported();
    error adminAlreadyExist();
    error notL1Address();
    error approverAlreadyExist();
    
    address public trustedForwarder;
    address[] private pushUsers;
    address[] private adminAddresses;
    address private L1Approver;
    
    mapping(address => bool) private isUser;
    mapping(address => bool) private adminAddress;
    mapping(address => bool) private approverAddress;

    struct userBulkData{
        address _ad;
    }

    constructor(address _trustedForwarder)ERC2771Context(_trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    function setTrustedForwarder(address _newForwarder) external onlyOwner{
        trustedForwarder = _newForwarder;
    }

    function versionRecipient() external pure returns(string memory){
        return "1";
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns(address){
        return ERC2771Context._msgSender();
    } 

    function _msgData() internal view override(Context, ERC2771Context) returns(bytes calldata){
        return ERC2771Context._msgData();
    }

    function whitelistApproverL1(address _approverAd) external onlyOwner{
        if(_approverAd == address(0)){ revert zeroAddressNotSupported();}
        if(approverAddress[_approverAd] == true){revert approverAlreadyExist();}
        approverAddress[_approverAd] = true;
        L1Approver = _approverAd;
    }
    
    /**
        *  addUser
        * @param _ad - Admin has the access to enter the user address to the blockchain.
    */
    function addUser(address _ad) external {
        if(_msgSender() != L1Approver){ revert notL1Address();}
        if(isUser[_ad] == true){ revert addressAlreadyRegistered();}
        isUser[_ad] = true;
        pushUsers.push(_ad);
    }

    /**
        * addUserBulk
        * @param _userData - Enter the user data (address and type) as array format.
    */
    function addUserBulk(userBulkData[] memory _userData) external {
        if(_msgSender() != L1Approver){ revert notL1Address();}
        for(uint i = 0; i < _userData.length; i++){
            if(isUser[_userData[i]._ad] == true){ revert addressAlreadyRegistered();}
            isUser[_userData[i]._ad] = true;
            pushUsers.push(_userData[i]._ad);
        }
    }

    /**
        *  verifyUser
        * @param _ad - Enter the address, to know about the role
    */
    function verifyUser(address _ad) external view returns(bool){
        if(isUser[_ad]){
            return true;
        }else{
            return false;
        }
    }

    /**
        *  getAllUserAddress
        *  outputs all the entered user address from the blockchain.
    */
    function getAllUserAddress() external view returns(address[] memory){
        return pushUsers;
    }   

    function L1ApproverAddress() external view returns(address){
        return L1Approver;
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
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