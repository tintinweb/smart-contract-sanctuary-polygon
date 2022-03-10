//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Credentials is Ownable {
    struct Credential {
        uint256 credentialId;
        address issuer; // By default can't be null
        address receiver; // Receiver can be blank incase receiver don't have an ETH address
        bool isValid; // Validity can be revoked by the issuer in the future
        string cert_material; // Certificate material can be anything (like stringifie JSON or IPFS hash)
    }

    uint256 public credentialId;

    mapping(uint256 => Credential) public credentials;
    mapping(address => bool) public isIssuer;

    modifier onlyListedIssuer() {
        require(
            isIssuer[msg.sender],
            "Credentials Contract: Not a listed Issuer"
        );
        _;
    }

    modifier onlyCredIssuer(uint256 _credentialId, address issuer) {
        require(credentials[_credentialId].issuer == issuer, "Credentials Contract: Not the issuer");
        _;
    }

    constructor() {
        isIssuer[msg.sender] = true; // The contract deployer is an Issuer
        credentialId = 1; // 1 because changing from 0 to 1 takes higher GAS
    }

    function addIssuer(address _issuer) public onlyOwner {
        isIssuer[_issuer] = true;
    }

    function removeIssuer(address _issuer) public onlyOwner {
        isIssuer[_issuer] = false;
    }

    function issueCredential(address _receiver, string memory _cert_material)
        public
        onlyListedIssuer
    {
        uint256 _credentialId = credentialId;
        require(_credentialId != 0, "Credentials Contract: Credential ID is 0 | Maximum credentials issued");
        credentials[_credentialId] = Credential(
            credentialId,
            msg.sender,
            _receiver,
            true,
            _cert_material
        );
        credentialId = _credentialId + 1;
    }

    function revokeCredential(uint256 _credentialId) public onlyCredIssuer(_credentialId, msg.sender) {
        credentials[_credentialId].isValid = false;
    }

    function validateCredential(uint256 _credentialId) public view returns(bool) {
        if(credentials[_credentialId].isValid) {
            return true;
        } else {
            return false;
        }
    }

    function getCertMaterial(uint256 _credentialId) public view returns(string memory) {
        require(validateCredential(_credentialId), "Credentials Contract: Credential is not valid");
        return credentials[_credentialId].cert_material;
    }
}

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