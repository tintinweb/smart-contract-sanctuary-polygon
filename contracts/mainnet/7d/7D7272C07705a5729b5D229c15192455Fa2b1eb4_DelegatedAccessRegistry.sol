// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DelegatedAccessRegistry is Ownable {
    // mainWallet => delegatedWallet)
    mapping(address => address) public mainToDelegatedWallets;
    // delegatedWallet => mainWallet
    mapping(address => address) private delegatedToMainWallets;

    uint256 constant public AUTHORIZE_CHALLENGE_TYPE = 0;
    uint256 constant public REVOKE_CHALLENGE_TYPE = 1;

    event Authorized(address indexed mainWallet, address delegatedWallet);
    event Revoked (address indexed mainWallet, address delegatedWallet);

    // mainWallet => isKnown 
    mapping(address=>bool) public mainWallets;

    /*
    // wallet => joinedPolicyAddresses => isJoined
    mapping(address => mapping(address => bool)) public joinedPolicies;
    */
    
    // wallet => joinedPolicyAddresses
    mapping(address => address[]) public joinedPolicies;

    constructor() Ownable(){}

    function verifyDelegationChallenge(
        address delegatedUser_,
        uint256 actionType,
        bytes memory signature_
    ) internal view returns (bool isValid) {
        require(signature_.length == 65, "error_badSignatureLength");

        bytes32 r; bytes32 s; uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature_, 32))
            s := mload(add(signature_, 64))
            v := byte(0, mload(add(signature_, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "error_badSignatureVersion");

        bytes32 messageHash = keccak256(abi.encodePacked(
            actionType, 
            _msgSender()
        ));

        return delegatedUser_ == ecrecover(messageHash, v, r, s);
    }

    function authorize(address delegatedUser_, bytes memory signature_) public {
        require(verifyDelegationChallenge(delegatedUser_, AUTHORIZE_CHALLENGE_TYPE, signature_), "error_badChallengeSignature");
        mainToDelegatedWallets[_msgSender()] = delegatedUser_;
        delegatedToMainWallets[delegatedUser_] = _msgSender();
        mainWallets[_msgSender()] = true;
        emit Authorized(_msgSender(), delegatedUser_);
    }
    
    function revoke(address delegatedUser_, bytes memory signature_) public {
        require(verifyDelegationChallenge(delegatedUser_, REVOKE_CHALLENGE_TYPE, signature_), "error_badChallengeSignature");
        mainToDelegatedWallets[_msgSender()] = address(0x0);
        delegatedToMainWallets[delegatedUser_] = address(0x0);
        mainWallets[_msgSender()] = false;
        emit Revoked(_msgSender(), delegatedUser_);
    }
    
    function isUserAuthorized(address mainUser_, address delegatedUser_) public view returns (bool) {
        return mainToDelegatedWallets[mainUser_] == delegatedUser_;
    }

    function isAuthorized(address delegatedUser_) public view returns (bool) {
        return isUserAuthorized(_msgSender(), delegatedUser_);
    }
    
    function getMainWalletFor(address delegatedUser_) public view returns (address){
        return delegatedToMainWallets[delegatedUser_];
    }

    function getDelegatedWalletFor(address mainUser_) public view returns (address){
        return mainToDelegatedWallets[mainUser_];
    }
    
    function isMainWallet(address wallet) public view returns (bool) {
        return mainWallets[wallet];
    }
    
    function isDelegatedWallet(address wallet) public view returns (bool) {
        return delegatedToMainWallets[wallet] != address(0x0);
    }
    
    function isWalletKnown(address wallet) public view returns (bool) {
        return isMainWallet(wallet) || isDelegatedWallet(wallet);
    }
    
    function areMainWallets(address[] memory queryWallets) public view returns (bool[] memory) {
        bool[] memory out = new bool[](queryWallets.length + 1);
        for (uint i = 0; i < queryWallets.length; i++) {
            out[i] = isMainWallet(queryWallets[i]);
        }
        return out;
    }    
    
    function areDelegatedWallets(address[] memory queryWallets) public view returns (bool[] memory) {
        bool[] memory out = new bool[](queryWallets.length + 1);
        for (uint i = 0; i < queryWallets.length; i++) {
            out[i] = isDelegatedWallet(queryWallets[i]);
        }
        return out;
    }    

    function areWalletsKnown(address[] memory queryWallets) public view returns (bool[] memory) {
        bool[] memory out = new bool[](queryWallets.length + 1);
        for (uint i = 0; i < queryWallets.length; i++) {
            out[i] = isWalletKnown(queryWallets[i]);
        }
        return out;
    }

    function addPolicyToWallet(address policyAddress_) public {
        joinedPolicies[_msgSender()].push(policyAddress_);
    }

    function removePolicyFromWallet(address policyAddress_) public {
        for (uint i = 0; i < joinedPolicies[_msgSender()].length; i++) {
            if (joinedPolicies[_msgSender()][i] == policyAddress_) {
                joinedPolicies[_msgSender()][i] = joinedPolicies[_msgSender()][joinedPolicies[_msgSender()].length - 1];
                joinedPolicies[_msgSender()].pop();
                break;
            }
        }   

    }

    function getPoliciesForWallet(address wallet_) public view returns (address[] memory){
       return joinedPolicies[wallet_];
    }
}