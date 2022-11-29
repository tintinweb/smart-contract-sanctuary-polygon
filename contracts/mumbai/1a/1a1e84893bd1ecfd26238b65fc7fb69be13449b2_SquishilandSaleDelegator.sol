/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// Squishiland by Squishiverse (www.squishiland.com / www.squishiverse.com)

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdlod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'....,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..;cll:,..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXkc'..,cldddddol;'..,lOXWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXkl,..,:lddoodoooooool:'..;oOXWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOl,..';lodddooodddollloodol;...;o0NWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWNOl,..';cloddddxxxxxddollodddddoc:,...;o0NWMMMMMMMMMMMMM
// MMMMMMMMMMMNOo;..';coooodxxxxxkkxdddoodxxxddddooolc;...:d0NMMMMMMMMMMM
// MMMMMMMMN0o;...;coddddddxxxxxddddddddxkOkkxdxxxxddddo:,...:xKNMMMMMMMM
// MMMMMN0d:...;lodddddxxxxxxxxdddxxxddxkkkxxxxdxxxxxxddolc;'..'cxKWMMMMM
// MMN0d:'..,:odxxddddxxkOOkxxxddodxxxxdddddddddxxxxxddollllol:,..'cxKWMM
// Kd:'..,:coodddddddxxxkkkkxxxddoodddddxxxxxdxkOO00kdolllloooool:,..'ckX
// :..';cooooodddddddddddddddddddoooooddxxxxxxxxk00Okddoolloooodddol:'..l
// '..:cloooooddddddddddddddddxxdddoooooddddddxxxxxxdoooooddddddollcl;..:
// ;..',;coddddddddddddddddxxxdddddddddddoooddxxxxxdolllloooooooolc::,..c
// c....',;clooooddddddddxxxxxddddddddddddddddddxxxollllllllclllcc;;;'..o
// o.......';::cldddddddxxxxxxxdddddddddddddddddooolllooooolc:::;;,,,'..d
// x. .......'',:loddddddddddddddxkkxddddddddddddollloooolc:,;,,,''',. .x
// k. ..........',;clooooooddddddxO0Okkxddoooddddoolcccc:;,''''''''''..'O
// O' .............',;;:clloddddxkOOkkkxooooollllool:;,,,''''''''.'''..;0
// O,..................';:cloodddxxdooollooooolccccc:,''',,,,'''.......:K
// 0;...................',,;:clddooloddoloddolc::::;,,''',,,''.........lX
// 0:......................'',;clooodxxdolllc:;,,,,,'''''''''..........dN
// Kc. .......................',,:coxxddl:;;,,''''''',,,''.'......... .xN
// Xo. .........................',;:loll:;,''''''''',,,''............ 'kW
// Nd. ...........................',;:::;,,,,'',,,''',''............. 'OW
// Wk' ............................',;;;,,,;,'',,,'''''.............. 'OM
// M0;. ............ ..............',,,;;;,,'''''''...................;0M
// MNk;.  ..........................',,;;,''''''''...................:OWM
// MMWXOl'.  ............ ..........',,,,''''''''.................,lONWMM
// MMMMMWKx:.. .....................',,,,''...'''..............'ckXWMMMMM
// MMMMMMMMNOo,.  ..................',,,''...................,d0NMMMMMMMM
// MMMMMMMMMMWKkc..  ...............'',''.................'lkXWMMMMMMMMMM
// MMMMMMMMMMMMMW0o,.  ..............'''................;dKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXkc'.  ...........................,lONWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0d;.   ......................:xXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWXkc'.  ........''.......,o0NMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWKx:.. ............'ckXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMNOo,..........;d0NMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'....'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOocld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @title ISquishiland
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice Interface for the Squishiland ERC721 contract.
 */
interface ISquishiland is IERC721 {
    /// @dev Land sizes
    enum LandSize {
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    /// @dev Attribute for each piece of land
    struct LandAttribute {
        uint256 price;
        uint256 supply;
        uint256 startingId;
        uint256 minted;
        uint256 burnt;
    }

    /**
     * @notice Fetch total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Fetch total burnt
     */
    function totalBurnt() external view returns (uint256);

    /**
     * @notice Burn a piece of land
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Fetch the total minted on a per size basis
     */
    function totalSupplyBySize(LandSize _size) external view returns (uint256);

    /**
     * @notice Fetch the total burnt on a per size basis
     */
    function totalBurntBySize(LandSize _size) external view returns (uint256);

    /**
     * @notice Get the land size for a token
     */
    function getLandSize(uint256 _tokenId) external view returns (LandSize);

    /**
     * @notice Allows the contract owner to mint within limits
     */
    function mintAdmin(
        LandSize _size,
        address _recipient,
        uint256 _quantity
    ) external;

    /**
     * @notice Get the land information
     */
    function land(LandSize size) external view returns (LandAttribute memory);

    /**
     * @notice Transfers ownership of the contract to a new account
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Returns the address of the current contract owner
     */
    function owner() external view returns (address);
}

contract SquishilandSaleDelegator is Ownable, Pausable {
    /// @notice Land contract
    ISquishiland private immutable _land;

    /// @notice Pack information about a coordinate
    struct Coordinate {
        uint32 x;
        uint32 y;
        bool minted;
    }

    /// @notice Map a token id to a coordinate
    mapping(uint256 => Coordinate) private coordinateOfToken;

    /// @notice Map coordinate to a token id
    mapping(uint32 => mapping(uint32 => uint256)) private tokenOfCoordinate;

    /// @notice Token not found
    error TokenNotFound();

    /// @notice Parameters mismatched
    error ParameterMismatch();

    /// @notice When a token does not have a coordinate
    error TokenHasNoCoordinate(uint256 tokenId);

    /// @notice Coordinate is occupied
    error CoordinateOccupied(uint32 x, uint32 y);

    constructor(ISquishiland land) {
        _land = land;
    }

    /**
     * @notice Mint specific coordinates
     */
    function mintMany(
        uint32[] calldata x,
        uint32[] calldata y,
        uint256[] calldata sizes
    ) public payable {
        if (x.length != y.length && x.length != sizes.length) {
            revert ParameterMismatch();
        }
        // @todo prevent minting same coordinate
        for (uint256 i; i < x.length; i++) {
            _mint(x[i], y[i], ISquishiland.LandSize(sizes[i]));
        }
    }

    /**
     * @notice Mint a specific coordinate
     */
    function mint(
        uint32 x,
        uint32 y,
        ISquishiland.LandSize size
    ) public payable whereCoordinateVacant(x, y) {
        // @todo prevent minting same coordinate
        _mint(x, y, size);
    }

    /**
     * @notice Reserve a coordinate
     */
    function reserve(
        uint256 tokenId,
        uint32 x,
        uint32 y
    ) public payable whereCoordinateVacant(x, y) {
        _reserve(tokenId, x, y, false);
    }

    /**
     * @dev Mint a specific coordinate
     */
    function _mint(
        uint32 x,
        uint32 y,
        ISquishiland.LandSize size
    ) private whenNotPaused {
        ISquishiland.LandAttribute memory landInfo = _land.land(size);
        uint256 nextId = landInfo.minted + landInfo.startingId;

        // @todo MAY BE exploitable!!!! must check recursively that msg.value decreases
        require(msg.value >= landInfo.price, "!nofunds");

        // associate token to coordinate
        _reserve(nextId, x, y, true);

        // mint as an admin
        _land.mintAdmin(size, msg.sender, 1);
    }

    /**
     * @dev Reserve a coordinate
     */
    function _reserve(
        uint256 tokenId,
        uint32 x,
        uint32 y,
        bool minted
    ) internal whenNotPaused {
        coordinateOfToken[tokenId] = Coordinate({x: x, y: y, minted: minted});
        tokenOfCoordinate[x][y] = tokenId;
    }

    /**
     * @notice Return the ownership of the land contract back
     */
    function transferBackLandContract() public onlyOwner {
        _land.transferOwnership(msg.sender);
    }

    /**
     * @notice Determine if a coordinate has been minted
     */
    function getTokenFromCoordinate(uint32 x, uint32 y)
        public
        view
        returns (uint256)
    {
        uint256 tokenId = tokenOfCoordinate[x][y];
        Coordinate memory coord = coordinateOfToken[tokenId];
        if (coord.x != x && coord.y != y) {
            revert TokenNotFound();
        }
        return tokenId;
    }

    /**
     * @notice Determine coordinate from token id
     */
    function getCoordinateFromToken(uint256 tokenId)
        public
        view
        returns (Coordinate memory)
    {
        Coordinate memory coord = coordinateOfToken[tokenId];
        if (coord.x != 0 && coord.y != 0) {
            return coord;
        }
        revert TokenHasNoCoordinate(tokenId);
    }

    /**
     * @dev Ensure a coordinate is not taken
     */
    modifier whereCoordinateVacant(uint32 x, uint32 y) {
        uint256 tokenId = tokenOfCoordinate[x][y];
        if (tokenId == 0) {
            Coordinate memory coord = coordinateOfToken[tokenId];
            if (coord.x == x && coord.y == y) {
                revert CoordinateOccupied(x, y);
            }
        } else {
            revert CoordinateOccupied(x, y);
        }
        _;
    }

    /**
     * @notice Pause state of contract
     */
    function pause() public onlyOwner {
        if (paused()) {
            _pause();
        } else {
            _unpause();
        }
    }
}