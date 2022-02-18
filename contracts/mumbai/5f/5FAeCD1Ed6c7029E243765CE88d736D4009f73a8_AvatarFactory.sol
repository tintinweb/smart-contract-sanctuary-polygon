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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

string constant FREE_STATUS = "On the loose";
string constant CAPTURED_STATUS = "Captured";

enum AvatarStatus {
    Free,
    Captured
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PirateAvatar.sol";
import "../traits/TokenTrait.sol";
import "./AvatarStatus.sol";

interface IAvatarContract {
    function mint(address account, bool isGovernor) external returns(uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function updatePirateAvatar(uint256 tokenId, PirateAvatar calldata pirateAvatar, TokenTrait[] calldata traits) external;
    function addPirateAvatarNotorietyPoints(uint256 tokenId, uint256 notorietyPoints) external;
    function getNotorietyLevel(uint256 tokenId, string memory notorietyTraitTypeName) external view returns(uint8 level);

    function getStatus(uint256 tokenId) external view returns(string memory);
    function setStatus(uint256 tokenId, AvatarStatus status) external;
    function getPirateAvatar(uint256 tokenId) external view returns (PirateAvatar memory);
    function getTokenTraits(uint256 tokenId) external view returns (TokenTrait[] memory);

    function isCaptured(uint256 tokenId) external view returns(bool);

    function mintedPirateAvatars() external view returns (uint256);
    function mintedPirateGovernors() external view returns (uint256);

    function walletOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PirateAvatar.sol";
import "../traits/TokenTrait.sol";
import "./AvatarStatus.sol";

interface IPirateAvatarMetadata {
    
    function pirateAvatarExists(uint256 tokenId) external view returns (bool);

    function addPirateAvatar(uint256 pirateAvatarTokenId, PirateAvatar calldata pirateAvatar, TokenTrait[] calldata tokenTraits) external;

    function updatePirateAvatar(uint256 tokenId, PirateAvatar calldata pirateAvatar, TokenTrait[] calldata traits) external;

    function addToNumberTraitType(uint256 tokenId, uint256 amount, string memory traitTypeName) external;

    function getTraitTypeValue(uint256 tokenId, string memory traitTypeName) external view returns(string memory);

    function setTraitTypeValue(uint256 tokenId, string memory traitValue, string memory traitTypeName) external;
    
    function getPirateAvatar(uint256 tokenId) external view returns (PirateAvatar memory);

    function getTokenTraits(uint256 tokenId) external view returns (TokenTrait[] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getNotorietyLevel(uint256 tokenId, string memory notorietyTraitTypeName) external view returns(uint8 level);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct PirateAvatar {
    string name; // required
    string imageUri;
    bool isGovernor;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../MVPS/IAvatarContract.sol";
import "../MVPS/IPirateAvatarMetadata.sol";
import "../MVPS/PirateAvatar.sol";
import "../traits/TokenTrait.sol";

import "./IRandomNumberFactory.sol";
import "./IRandomRequester.sol";

import "../../roles/Roles.sol";

//import "hardhat/console.sol";

contract AvatarFactory is 
    Ownable, 
    IRandomRequester
{
    using Strings for uint256;
    using SafeMath for uint256;

    IAvatarContract internal avatarContract;
    IRandomNumberFactory internal randomNumberFactory;
    IERC721 internal mvpsContract;
    IPirateAvatarMetadata internal pirateAvatarMetadataContract;

    address internal randomNumberFactoryAddress;
    address internal mvpsContractAddress;
    address internal avatarContractAddress;
    address internal pirateAvatarMetadataContractAddress;    

    mapping(uint256 => uint256) private _pirateTokenIdToPirateAvatarTokenId;

    event MintingAvatar(bytes32 indexed requestId, address indexed account);
    event AvatarCreated(address account, uint256 indexed pirateAvatarTokenId, bool isGovernor);

    struct MintData {
        address owner;
        uint256 pirateTokenId;
        string uri;
    }
    mapping(bytes32 => MintData) private mintRequests;

    constructor(
        address _randomNumberFactoryAddress,
        address _avatarContractAddress,
        address _mvpsContractAddress, 
        address _pirateAvatarMetadataContractAddress 
    )
    {
        setRandomNumberFactory(_randomNumberFactoryAddress);
        setAvatarContract(_avatarContractAddress);
        setMvpsContract(_mvpsContractAddress);
        setPirateAvatarMetadataContract(_pirateAvatarMetadataContractAddress);
    }

    function setRandomNumberFactory(address _randomNumberFactoryAddress) public onlyOwner {
        randomNumberFactoryAddress = _randomNumberFactoryAddress;
        randomNumberFactory = IRandomNumberFactory(randomNumberFactoryAddress);
    }

    function setAvatarContract(address _avatarContractAddress) public onlyOwner {
        avatarContractAddress = _avatarContractAddress;
        avatarContract = IAvatarContract(avatarContractAddress);
    }

    function setMvpsContract(address _mvpsContractAddress) public onlyOwner {
        mvpsContractAddress = _mvpsContractAddress;
        mvpsContract = IERC721(_mvpsContractAddress);
    }

    function setPirateAvatarMetadataContract(address _pirateAvatarMetadataContractAddress) public onlyOwner {
        pirateAvatarMetadataContractAddress = _pirateAvatarMetadataContractAddress;
        pirateAvatarMetadataContract = IPirateAvatarMetadata(pirateAvatarMetadataContractAddress);
    }

    function randomnessFulfilled(uint256 randomness, bytes32 requestId) external override {
        
        MintData storage mintData = mintRequests[requestId];
        require(mintData.owner != address(0), "Invalid request");

        // 5% (1 in 20) chance of being a governor
        bool isGovernor = randomness.mod(100).add(1) <= 50; // TODO #2 - remoe for testing

        uint256 pirateAvatarTokenId = avatarContract.mint(mintData.owner, isGovernor);

        _pirateTokenIdToPirateAvatarTokenId[mintData.pirateTokenId] = pirateAvatarTokenId;

        PirateAvatar memory pirateAvatar = PirateAvatar(
            string(abi.encodePacked("Pirate Avatar #", pirateAvatarTokenId.toString())),
            mintData.uri,
            isGovernor
        );

        TokenTrait[] memory tokenTraits = new TokenTrait[](2);

        tokenTraits[0] = TokenTrait(
                NOTORIETY_POINTS_TRAIT_NAME,
                "0",
                TraitDisplayType.Number
        );
        
        tokenTraits[1] = TokenTrait(
            PIRATE_TYPE_NAME,
            isGovernor ? "Governor" : "Buccaneer",
            TraitDisplayType.String
        );

        tokenTraits[1] = TokenTrait(
            STATUS_TYPE_NAME,
            FREE_STATUS,
            TraitDisplayType.String
        );

        pirateAvatarMetadataContract.addPirateAvatar(pirateAvatarTokenId, pirateAvatar, tokenTraits);

        emit AvatarCreated(mintData.owner, pirateAvatarTokenId, isGovernor);
    }

    function mintPirateAvatar(uint256 pirateTokenId, string memory uri) public {
        require(mvpsContract.ownerOf(pirateTokenId) == msg.sender, "Not MVPS Member");

        // pirateTokenId must not have been used in the past to mint. One free mint per pirate
        require(_pirateTokenIdToPirateAvatarTokenId[pirateTokenId] == 0, "Avatar already created");

        bytes32 requestId = randomNumberFactory.randomRequest();
        
        // storing request
        mintRequests[requestId] = MintData(
            msg.sender,
            pirateTokenId,
            uri 
        );

        emit MintingAvatar(requestId, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomNumberFactory {
    function requestorExists(address requestor) external view returns(bool exists);
    function registerRequestor(address requestor) external;
    function unRegisterRequestor(address requestor) external;
    function randomRequest() external returns (bytes32 requestId);
    function expand(uint256 randomValue, uint256 n) external returns (uint256[] memory expandedValues); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomRequester {
    function randomnessFulfilled(uint256 randomness, bytes32 requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TraitDisplayType.sol";

string constant NOTORIETY_POINTS_TRAIT_NAME = "Notoriety Points";
string constant PIRATE_TYPE_NAME = "Pirate Type";
string constant STATUS_TYPE_NAME = "Status";
string constant PROFICIENCY_TRAIT_NAME = "Proficiency";
string constant SHIP_TYPE_NAME = "Ship Type";

string constant PROFICIENCY_BONUS_TRAIT_NAME = "Proficiency Bonus";
string constant VALUE_TRAIT_NAME = "Value";

struct TokenTrait {
    string traitType; // required
    string traitValue;
    TraitDisplayType displayType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum TraitDisplayType {
    String,
    Number
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

bytes32 constant AVATAR_MANAGER_ROLE = keccak256("AVATAR_MANAGER_ROLE");
bytes32 constant AVATAR_MINTER_ROLE = keccak256("AVATAR_MINTER_ROLE");
bytes32 constant PIRATE_ITEM_MANAGER_ROLE = keccak256("PIRATE_ITEM_MANAGER_ROLE");
bytes32 constant SHIP_MANAGER_ROLE = keccak256("SHIP_MANAGER_ROLE");
bytes32 constant STAKING_ROLE = keccak256("STAKING_ROLE");
bytes32 constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");