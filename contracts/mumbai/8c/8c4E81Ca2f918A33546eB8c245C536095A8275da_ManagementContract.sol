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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
// import "./HELPER_CONTRACTS/EIP712MetaTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// error PinataVerify__NoApproval(address approvedFrom, address approvedTo);
// error PinataVerify__NotVerified(address approvedFrom, address approvedTo);

// - handle subscription from institues
//   - Store institute and contract address
// - register as institute and stored on chain --> User just stored on deployed contract, institutes on management contract
// - Handle gasless payments
// -

contract ManagementContract {
    // enum PermissionLevel {
    //     None,
    //     Private,
    //     Public
    // }
    struct IPFSObject {
        string cid;
        string ipfsId;
    }
    event deploymentSuccess(address indexed approvedFrom, string cid, string ipfsId);
    // event dataUploadSuccess(
    //     address indexed uploadedFrom,
    //     address indexed approvedFrom,
    //     DataUpload dataUpload
    // );
    // event dataUploadVerified(
    //     address indexed uploadedFrom,
    //     address indexed approvedFrom,
    //     DataUpload dataUpload
    // );
    mapping(address => IPFSObject) private s_deployments;

    // mapping(address => mapping(address => DataUpload)) private s_uploads;
    // mapping(address => address[]) private s_name_register;
    // modifier isApproved(address approvedFrom) {
    //     PermissionLevel permissionLevel = s_approvals[approvedFrom][msg.sender];
    //     if (permissionLevel == PermissionLevel.None) {
    //         revert PinataVerify__NoApproval(approvedFrom, msg.sender);
    //     }
    //     _;
    // }
    // modifier isVerified(address approvedTo) {
    //     PermissionLevel permissionLevel = s_approvals[msg.sender][approvedTo];
    //     if (permissionLevel == PermissionLevel.None) {
    //         revert PinataVerify__NotVerified(approvedTo, msg.sender);
    //     }
    //     _;
    // }
    function storeDeploymenmt(string memory cid, string memory ipfsId) public {
        s_deployments[msg.sender] = IPFSObject(cid, ipfsId);
        emit deploymentSuccess(msg.sender, cid, ipfsId);
    }
    // function uploadData(
    //     address approvedFrom,
    //     string memory ipfsHash,
    //     string memory ipfsId
    // ) external isApproved(approvedFrom) {
    //     DataUpload memory dataUpload = DataUpload(ipfsHash, ipfsId, false);
    //     s_uploads[msg.sender][approvedFrom] = DataUpload(ipfsHash, ipfsId, false);
    //     emit dataUploadSuccess(msg.sender, approvedFrom, dataUpload);
    // }
    // function verifyDataUpload(
    //     address approvedTo,
    //     string memory signedIpfsHash
    // ) external isVerified(approvedTo) {
    //     s_uploads[approvedTo][msg.sender].verified = true;
    //     s_uploads[approvedTo][msg.sender].ipfsHash = signedIpfsHash;
    //     DataUpload memory dataUpload = s_uploads[approvedTo][msg.sender];
    //     emit dataUploadVerified(approvedTo, msg.sender, dataUpload);
    // }
    // function checkGivenPermission(address approvedTo) public view returns (PermissionLevel) {
    //     return s_approvals[msg.sender][approvedTo];
    // }
    // function checkReceivedPermission(address approvedFrom) public view returns (PermissionLevel) {
    //     return s_approvals[approvedFrom][msg.sender];
    // }
    // function checkUploads(address approvedFrom) public view returns (DataUpload[2] memory) {
    //     return [s_uploads[msg.sender][approvedFrom], s_uploads[approvedFrom][msg.sender]];
    // }
}