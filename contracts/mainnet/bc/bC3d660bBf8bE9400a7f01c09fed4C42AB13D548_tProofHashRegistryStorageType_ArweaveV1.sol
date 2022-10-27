// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ItProofHashRegistryStorageTypeInterface.sol";


// tProof.io is a tool for Decentralized Proof of Timestamp, that anyone can use
// to prove a digital content existed prior to a certain point in time.
// Solution is designed to work 100% on-chain, and to not rely on a central entity.
// Each proof is created in the form of an NFT.
//
// See https://tproof.io


// Managers Arweave V1 storage URLs
contract tProofHashRegistryStorageType_ArweaveV1 is Ownable, ItProofHashRegistryStorageTypeInterface {

    // struct
    /**
    * @notice represents the stored URL
    * @dev instead of storing a string, since we know Arweave identifiers are 43 chars, we optimized storage splitting their value in two bytes variables
    * @param url1 the first part of the Arweave TX id
    * @param url2 the remaining part of the Arweave TX id
    **/
    struct HashUrl {
        bytes32 url1;
        bytes11 url2;  // can be up to 32
    }

    // mappings
    /// @dev connects the URL to each NFT id
    mapping (uint => HashUrl) private nftUrl;

    // address
    address hashRegistryContract;

    constructor (address _hashRegistryAddress) {
        hashRegistryContract = _hashRegistryAddress;
    }

    /**
    * @notice saves the url identifier (Arweave 43 characters tx ID)
    * @param _nft the nft number connected to the url
    * @param _url the string representing the url
    **/
    function storeUrl (uint _nft, string calldata _url) external {
        require(msg.sender == hashRegistryContract, "Only hashRegistry can call");
        nftUrl[_nft].url1 = bytes32(bytes(_url)[0:32]);
        nftUrl[_nft].url2 = bytes11(bytes(_url)[32:43]);
    }

    /**
    * @notice get the string representing the url
    * @param _nft the nft connected to the url
    * @param _version the version of the URL to return. See docs based on storageType for the given file. Generally 0 for the essential storage data, 1 for the fullUrl version. Other values may be possible
    * @return a string representing the url, in the format required
    **/
    function getUrlString (uint _nft, uint _version) external view returns (string memory) {
        require(_version < 2, "Unsupported version value");
        bytes memory bytesUrl = bytes.concat(nftUrl[_nft].url1, nftUrl[_nft].url2);
        string memory arweaveTxId = string(bytesUrl);
        if (_version == 0) {
            // return the stored Arweave hash
            return arweaveTxId;
        } else {
            // return the full url version
            return string.concat("https://arweave.net/", arweaveTxId);
        }
    }

    /**
    * @notice set the hash registry contract in the emergency case we'll need to change it
    * @param _newAddress the new address
    **/
    function setHashRegistryContract(address _newAddress) public onlyOwner {
        hashRegistryContract = _newAddress;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ItProofHashRegistryStorageTypeInterface {

    /**
    * @notice saves the url identifier
    * @param _nft the nft number connected to the url
    * @param _url the string representing the url
    **/
    function storeUrl (uint _nft, string calldata _url) external;

    /**
    * @notice get the string representing the url
    * @param _nft the nft connected to the url
    * @param _version the version of the URL to return. Mandatory are 0 and 1: 0 for the essential value, 1 for the fullUrl version. Other values may be possible, see docs based on storageType
    * @return a string representing the url, in the format required
    **/
    function getUrlString (uint _nft, uint _version) external view returns (string memory);

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