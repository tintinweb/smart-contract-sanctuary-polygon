// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IKycRegistry.sol";
import "../interfaces/IBadgeSet.sol";

/// @title KycRegistry
/// @author Brian watroba
/// @dev Registry mapping of user read-only addresses to linked wallet addresses. Used in BadgeSet contract to verify user ownership of wallet address.
/// @custom:version 1.0.2
contract KycRegistry is IKycRegistry, Ownable {
    mapping(address => address) private _walletsToUsers;
    mapping(address => address) private _usersToWallets;

    function linkWallet(address userAddress, address walletAddress)
        external
        onlyOwner
    {
        bool walletLinked = _walletsToUsers[userAddress] != address(0);
        bool userLinked = _usersToWallets[walletAddress] != address(0);
        if (walletLinked || userLinked) revert WalletAlreadyLinked();
        _walletsToUsers[userAddress] = walletAddress;
        _usersToWallets[walletAddress] = userAddress;
    }

    function getLinkedWallet(address userAddress)
        external
        view
        returns (address)
    {
        address linkedWallet = _walletsToUsers[userAddress];
        return linkedWallet == address(0) ? userAddress : linkedWallet;
    }

    function hashKycToUserAddress(
        bytes32 firstName,
        bytes32 lastName,
        uint256 phoneNumber
    ) external pure returns (address) {
        bytes32 userHash = keccak256(
            abi.encodePacked(firstName, lastName, phoneNumber)
        );
        address userAddress = address(uint160(uint256(userHash)));
        return userAddress;
    }

    function transitionBadgesByContracts(
        address kycAddress,
        address walletAddress,
        address[] memory contracts
    ) public {
        for (uint256 i = 0; i < contracts.length; i++) {
            address contractAddress = contracts[i];
            IBadgeSet(contractAddress).transitionWallet(
                kycAddress,
                walletAddress
            );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IKycRegistry { 

  error WalletAlreadyLinked();

  function linkWallet(address userAddress, address walletAddress) external;

  function getLinkedWallet(address userAddress) external view returns (address);

  function hashKycToUserAddress(bytes32 firstName, bytes32 lastName, uint256 phoneNumber) external pure returns (address);

  function transitionBadgesByContracts(address kycAddress, address walletAddress, address[] memory contracts) external;
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IBadgeSet {

    error ExpiryPassed();
    error ParamsLengthMismatch();
    error InsufficientBalance();
    error TokenAlreadyOwned();
    error InvalidAddress();

    event TransitionWallet(address indexed kycAddress, address indexed walletAddress);

    function contractURI() external view returns (string memory);
    
    function setURI(string memory newuri) external;

    function setContractURI(string memory newuri) external;
    
    function expiryOf(uint256 tokenId) external view returns (uint256);

    function mint(
        address account,
        uint96 badgeType,
        uint256 expiryTimestamp
    ) external returns (uint256 tokenId);

    function mintBatch(
        address to,
        uint96[] memory badgeTypes,
        uint256[] memory expiryTimestamps
    ) external;

    function revoke(
        address account,
        uint96 badgeType
    ) external returns(uint256 tokenId);

    function revokeBatch(
        address to,
        uint96[] memory badgeTypes
    ) external;

    function transitionWallet(address kycAddress, address walletAddress) external;

    function validateAddress(address _address) external view returns (address);

    function encodeTokenId(uint96 _tokenType, address _address) external pure returns (uint256);

    function decodeTokenId(uint256 data) external pure returns (uint96 _tokenType, address _address);

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