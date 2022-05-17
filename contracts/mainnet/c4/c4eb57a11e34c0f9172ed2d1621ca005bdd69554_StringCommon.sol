pragma solidity >=0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Immutable String - common constants and string routines
/// @author Sean Lawless for ImmutableSoft Inc.
/// @dev StringCommon is string related general/pure functions
contract StringCommon is Initializable, OwnableUpgradeable
{
  // Entity Status
  // Type is first 32 bits (bits 0 through 31)
  uint256 public constant Unknown =         0;
  uint256 public constant Creator =         1;
  uint256 public constant Distributor =     2;
  uint256 public constant EndUser =         3;

  // Flags begin at bit 32 and go until bit 63
  uint256 public constant Nonprofit =       (1 << 32);
  uint256 public constant Automatic =       (1 << 33);
  uint256 public constant CustomToken =     (1 << 34);

  // Country of origin
  uint256 public constant CoutryCodeOffset =64;
  uint256 public constant CoutryCodeMask =  (0xFFFF << CoutryCodeOffset);

  // Product Details
  // Category is first 32 bits (bits 0 through 31)
  uint256 public constant Tools =          0;
  uint256 public constant System =         1;
  uint256 public constant Platform =       2;
  uint256 public constant Education =      3;
  uint256 public constant Entertainment =  4;
  uint256 public constant Communications = 5;
  uint256 public constant Professional =   6;
  uint256 public constant Manufacturing =  7;
  uint256 public constant Business =       8;
  // Room here for expansion

  // Flags begin at bit 32 and go until bit 63
  uint256 public constant Hazard =         (1 << 32);
  uint256 public constant Adult =          (1 << 33);
  uint256 public constant Restricted =     (1 << 34);
  // Distribution restricted by export laws of orgin country?
  uint256 public constant USCryptoExport = (1 << 35);
  uint256 public constant EUCryptoExport = (1 << 36);

  // Languages begin at bit 64 and go until bit 127
  //   Ordered by percentage of native speakers
  //   https://en.wikipedia.org/wiki/List_of_languages_by_number_of_native_speakers
  uint256 public constant Mandarin =       (1 << 64);
  uint256 public constant Spanish =        (1 << 65);
  uint256 public constant English =        (1 << 66);
  uint256 public constant Hindi =          (1 << 67);
  uint256 public constant Bengali =        (1 << 68);
  uint256 public constant Portuguese =     (1 << 69);
  uint256 public constant Russian =        (1 << 70);
  uint256 public constant Japanese =       (1 << 71);
  uint256 public constant Punjabi =        (1 << 71);
  uint256 public constant Marathi =        (1 << 72);
  uint256 public constant Teluga =         (1 << 73);
  uint256 public constant Wu =             (1 << 74);
  uint256 public constant Turkish =        (1 << 75);
  uint256 public constant Korean =         (1 << 76);
  uint256 public constant French =         (1 << 77);
  uint256 public constant German =         (1 << 78);
  uint256 public constant Vietnamese =     (1 << 79);
  // Room here for 47 additional languages (bit 127)
  // Bits 128 - 255 Room here for expansion
  //   Up to 128 additional languages for example

  // Product Release Version
  // Version is first four 16 bit values (first 64 bits)
  // Version 0.0.0.0

  // Language bits from above form bits 64 to 127

  // The Platform Type begins at bit 128 and goes until bit 159
  uint256 public constant Windows_x86 =    (1 << 128);
  uint256 public constant Windows_amd64 =  (1 << 129);
  uint256 public constant Windows_aarch64 =(1 << 130);
  uint256 public constant Linux_x86 =      (1 << 131);
  uint256 public constant Linux_amd64 =    (1 << 132);
  uint256 public constant Linux_aarch64 =  (1 << 133);
  uint256 public constant Android_aarch64 =(1 << 134);
  uint256 public constant iPhone_arm64 =   (1 << 135);
  uint256 public constant BIOS_x86 =       (1 << 136);
  uint256 public constant BIOS_amd64 =     (1 << 137);
  uint256 public constant BIOS_aarch32 =   (1 << 138);
  uint256 public constant BIOS_aarch64 =   (1 << 139);
  uint256 public constant BIOS_arm64 =     (1 << 140);
  uint256 public constant Mac_amd64 =      (1 << 141);
  uint256 public constant Mac_arm64 =      (1 << 142);
  // Room here for expansion

  // End with general types
  uint256 public constant SourceCode =     (1 << 156);
  uint256 public constant Agnostic =       (1 << 157);
  uint256 public constant NotApplicable =  (1 << 158);
  uint256 public constant Other =          (1 << 159);
  // Room for expansion up to value (255 << 152) (last byte of type)

  // Bits 160 through 256 are available for expansion

  // Product License Activation Flags
  
  // Flags begin at bit 160 and go until bit 191
  uint256 public constant ExpirationFlag =     (1 << 160); // Activation expiration
  uint256 public constant LimitationFlag =     (1 << 161); // Version/language limitations
                                                    // Cannot be used with feature
  uint256 public constant NoResaleFlag =       (1 << 162); // Disallow resale after purchase
                                                    // Per EU "first sale" law, cannot
                                                    // be set if expiration NOT set
  uint256 public constant FeatureFlag =        (1 << 163); // Specific application feature
                                                    // ie. Value is feature specific
                                                    // CANNOT be used with Limitation
                                                    // flag

  uint256 public constant LimitedOffersFlag =  (1 << 164); // Limited number of offers
                                                    // UniqueId is used for number
                                                    // Offer flag only, not used in
                                                    // activate token id
  uint256 public constant BulkOffersFlag =     (1 << 165); // Limited number of offers
                                                    // UniqueId is used for number
                                                    // Offer flag only, not used in
                                                    // activate token id. Cannot be
                                                    // used with LimitedOffersFlag
  uint256 public constant RicardianReqFlag =   (1 << 166); // Ricardian client token
                                                    // ownership required before
                                                    // transfer or activation is allowed

  // Offset and mask of entity and product identifiers
  uint256 public constant EntityIdOffset = 224;
  uint256 public constant EntityIdMask =  (0xFFFFFFFF << EntityIdOffset);
  uint256 public constant ProductIdOffset = 192;
  uint256 public constant ProductIdMask =  (0xFFFFFFFF << ProductIdOffset);

  // CreatorToken only: Release id 32 bits
  uint256 public constant ReleaseIdOffset = 160;
  uint256 public constant ReleaseIdMask =  (0xFFFFFFFF << ReleaseIdOffset);

  // ActivateToken only: 16 bits to enforce unique token
  uint256 public constant UniqueIdOffset = 176;
  uint256 public constant UniqueIdMask =  (0xFFFF << UniqueIdOffset);

  // Flags allow different activation types and Value layout
  uint256 public constant FlagsOffset = 160;
  uint256 public constant FlagsMask =  (0xFFFF << FlagsOffset);

  // Expiration is common, last before common 128 bit Value
  uint256 public constant ExpirationOffset = 128;
  uint256 public constant ExpirationMask = (0xFFFFFFFF <<
                                     ExpirationOffset);

  // If limitation flag set, the Value is entirely utilized
/* NOT USED BY SMART CONTRACTS - Dapp only - here for reference
  // Bits 64 - 127 are for language (as defined above)
  uint256 public constant LanguageOffset = 64;
  uint256 public constant LanguageMask =  (0xFFFFFFFFFFFFFFFF <<
                                    LanguageOffset);

  // Final 64 bits of value is version (4 different 16 bit values)
  uint256 public constant LimitVersionOffset = 0;
  uint256 public constant LimitVersionMask =  (0xFFFFFFFFFFFFFFFF <<
                                        LimitVersionOffset);
*/

  // The value is the 128 LSBs
  //   32 bits if limitations flag set (96 bits version/language)
  //   All 128 bits if limitations flag not set
  //   
  uint256 public constant ValueOffset = 0;
  uint256 public constant ValueMask =  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  // Error strings
  string public constant EntityIsZero = "EntityID zero";
  string public constant OfferNotFound = "Offer not found";
  string public constant EntityNotValidated = "Entity not validated";

  string public constant ProductNotFound = "Product not found";

  string public constant TokenEntityNoMatch = "Token entity does not match";
  string public constant TokenProductNoMatch = "Token product id does not match";
  string public constant TokenNotUnique = "TokenId is NOT unique";

  /// @notice Initialize the StringCommon smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  function initialize() public initializer
  {
    __Ownable_init();
/*
  constructor() Ownable()
  {
*/
  }

/*
  /// @notice Convert a base ENS node and label to a node (namehash).
  /// ENS nodes are represented as bytes32.
  /// @param node The ENS subnode the label is a part of
  /// @param label The bytes32 of end label
  /// @return The namehash in bytes32 format
  function namehash(bytes32 node, bytes32 label)
    public pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(node, label));
  }

  /// @notice Convert an ASCII string to a normalized string.
  /// Oversimplified, removes many legitimate characters.
  /// @param str The string to normalize
  /// @return The normalized string
  function normalizeString(string memory str)
    public pure returns (string memory)
  {
    bytes memory bStr = bytes(str);
    uint j = 0;
    uint i = 0;

    // Loop to count number of characters result will have
    for (i = 0; i < bStr.length; i++) {
      // Skip if character is not a letter
      if ((bStr[i] < 'A') || (bStr[i] > 'z') ||
          ((bStr[i] > 'Z') && (bStr[i] < 'a')))
        continue;
      ++j;
    }

    // Allocate the resulting string
    bytes memory bLower = new bytes(j);

    // Loop again converting characters to normalized equivalent
    j = 0;
    for (i = 0; i < bStr.length; i++)
    {
      // Skip if character is not a letter
      if ((bStr[i] < 'A') || (bStr[i] > 'z') ||
          ((bStr[i] > 'Z') && (bStr[i] < 'a')))
        continue;

      // Convert uppercase to lower
      if ((bStr[i] >= 'A') && (bStr[i] <= 'Z')) {
        // So we add 32 to make it lowercase
        bLower[j] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[j] = bStr[i];
      }
      ++j;
    }
    return string(bLower);
  }
*/

  /// @notice Compare strings and return true if equal.
  /// Case sensitive.
  /// @param _a The string to be compared
  /// @param _b The string to compare
  /// @return true if strings are equal, otherwise false
  function stringsEqual(string memory _a, string memory _b)
    public pure virtual returns (bool)
  {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);

    // Return false if length mismatch
    if (a.length != b.length)
      return false;

    // Loop and return false if any character does not match
    for (uint i = 0; i < a.length; i ++)
      if (a[i] != b[i])
        return false;

    // Otherwise strings match so return true
    return true;
  }

/*
  /// @notice Convert a string to a bytes32 equivalent.
  /// Case sensitive.
  /// @param source The source string
  /// @return the bytes32 equivalent of 'source'
  function stringToBytes32(string memory source)
    public pure returns (bytes32 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0)
      return 0x0;

    assembly
    {
      result := mload(add(source, 32))
    }
  }
*/
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}