// SPDX-License-Identifier: GPL-3.0

/// @title DafoMinter
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDafoToken} from './interfaces/IDafoToken.sol';
import {IDafoCustomizer} from './interfaces/IDafoCustomizer.sol';

pragma solidity ^0.8.18;

contract DafoMinter is Ownable{

    // The DafoToken ERC721 token contract
    IDafoToken public dafoToken;
    // The DafoCustomizer contract
    IDafoCustomizer public dafoCustomizer;
    // minimum price to be paid for minting
    uint256 public reservePrice;
    bool public mintEnabled;
    address public crossmintAddress;

    event AuctionReservePriceUpdated(uint256);

    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
        emit AuctionReservePriceUpdated(_reservePrice);
    }

    function initializeParams(address _dafoTokenAddress, address _dafoCustomizerAddress) external onlyOwner {
        dafoToken = IDafoToken(_dafoTokenAddress);
        dafoCustomizer = IDafoCustomizer(_dafoCustomizerAddress);
    }

    function flipMintStatus() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mintDafoToken(IDafoCustomizer.CustomInput calldata _customInput, address _to) external payable {    
       // require(msg.value > reservePrice,"Incorrect value");   
        dafoToken.mint(_customInput, _to); 
    }

    function crossmint(address _to, uint256 _tokenId, uint8 _role, uint8 _palette, bool _outline) external payable {    
       // require(msg.value > reservePrice,"Incorrect value");   
       require(msg.sender == crossmintAddress);
        IDafoCustomizer.CustomInput memory _customInput = IDafoCustomizer.CustomInput(_tokenId, _role, _palette, _outline);
        dafoToken.mint(_customInput, _to); 
    }

    function setCrossmintAddress(address _crossmintAddress) external onlyOwner {
        crossmintAddress = _crossmintAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoCustomizer

pragma solidity ^0.8.6;

import {IDafoDescriptor} from './IDafoDescriptor.sol';

interface IDafoCustomizer {
    struct CustomInput {
        uint256 tokenId;
        uint8 role;
        uint8 palette;
        bool outline;
    }

    function generateInput(
        uint256 unavailableId,
        uint256 tokenMax,
        IDafoDescriptor descriptor
    ) external view returns (CustomInput memory);

    function create(
        uint256 tokenId,
        uint8 role,
        uint8 palette,
        bool outline
    ) external view returns (CustomInput memory);

    function isInBounds(IDafoDescriptor descriptor, IDafoCustomizer.CustomInput calldata _customInput) external view;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoToken

pragma solidity ^0.8.6;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IDafoDescriptor} from './IDafoDescriptor.sol';
import {IDafoCustomizer} from './IDafoCustomizer.sol';

interface IDafoToken is IERC721 {
    event DafoCreated(uint256 indexed tokenId, IDafoCustomizer.CustomInput customInput);

    event DafoBurned(uint256 indexed tokenId);

    event DafoundersDAOUpdated(address dafoundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event EarlyAccessMinterLocked();

    event DescriptorUpdated(IDafoDescriptor descriptor);

    event DescriptorLocked();

    event CustomizerUpdated(IDafoCustomizer customizer);

    event CustomizerLocked();

    function mint(IDafoCustomizer.CustomInput memory customizer, address to) external returns (uint256);

    function burn(uint256 tokenId) external;

    function exists(uint256 tokenId) external returns (bool);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDafoundersDAO(address dafoundersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function lockEarlyAccessMinter() external;

    function setDescriptor(IDafoDescriptor descriptor) external;

    function lockDescriptor() external;

    function setCustomizer(IDafoCustomizer customizer) external;

    function lockCustomizer() external;

    function findNextAvailable(uint16 representative) external view returns (uint16);
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for DafoDescriptor

pragma solidity ^0.8.6;

import {IDafoCustomizer} from './IDafoCustomizer.sol';

interface IDafoDescriptor {
    struct Palette {
        string background;
        string fill;
    }

    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function paletteCount() external view returns (uint256);

    function digitCount() external view returns (uint256);

    function roleCount() external view returns (uint256);

    function addManyPalettes(Palette[] calldata _palettes) external;

    function addManyDigits(string[] calldata _digits) external;

    function addManyRoles(string[] calldata _roles) external;

    function addPalette(uint8 index, Palette calldata _palette) external;

    function addDigit(uint8 index, string calldata _digit) external;

    function addRole(uint8 index, string calldata _roles) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function dataURI(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IDafoCustomizer.CustomInput memory customInput
    ) external view returns (string memory);

    function generateSVGImage(IDafoCustomizer.CustomInput memory customInput) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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