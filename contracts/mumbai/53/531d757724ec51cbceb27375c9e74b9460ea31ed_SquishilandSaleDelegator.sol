/**
 *Submitted for verification at polygonscan.com on 2022-12-01
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

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the `signature`.
    ///
    /// This function does NOT accept EIP-2098 short form signatures.
    /// Use `recover(bytes32 hash, bytes32 r, bytes32 vs)` for EIP-2098
    /// short form signatures instead.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(signature.length, 65) {
                // Copy the free memory pointer so that we can restore it later.
                let m := mload(0x40)
                // Directly copy `r` and `s` from the calldata.
                calldatacopy(0x40, signature.offset, 0x40)

                // If `s` in lower half order, such that the signature is not malleable.
                if iszero(gt(mload(0x60), _MALLEABILITY_THRESHOLD)) {
                    mstore(0x00, hash)
                    // Compute `v` and store it in the scratch space.
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x40, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // Restore the zero slot.
                    mstore(0x60, 0)
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    result := mload(sub(0x60, returndatasize()))
                }
                // Restore the free memory pointer.
                mstore(0x40, m)
            }
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    ///
    /// This function only accepts EIP-2098 short form signatures.
    /// See: https://eips.ethereum.org/EIPS/eip-2098
    ///
    /// To be honest, I do not recommend using EIP-2098 signatures
    /// for simplicity, performance, and security reasons. Most if not
    /// all clients support traditional non EIP-2098 signatures by default.
    /// As such, this method is intentionally not fully inlined.
    /// It is merely included for completeness.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        result = recover(hash, v, r, s);
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)

            // If `s` in lower half order, such that the signature is not malleable.
            if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                mstore(0x00, hash)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes (i.e. 0x1a).
            // The next multiple of 32 above 78 + 26 is 128 (i.e. 0x80).

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for { let temp := sLength } 1 {} {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            // Copy the header over to the memory.
            mstore(sub(ptr, 0x20), "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            // Compute the keccak256 of the memory.
            result := keccak256(sub(ptr, 0x1a), sub(end, sub(ptr, 0x1a)))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

interface ISquishilandSaleDelegator {
    /// @notice Pack information about a coordinate
    struct Coordinate {
        uint32 internalId;
        bool minted;
    }

    /// @notice Sale status
    enum SaleStatus {
        CLOSED,
        RESERVE,
        OPEN
    }

    /// @notice Token not found
    error TokenNotFound();

    /// @notice Parameters mismatched
    error ParameterMismatch();

    /// @notice Land is taken
    error LandReserved(uint256 internalId);

    /// @notice Not an owner of the land owner
    error LandNonOwner(uint256 tokenId);

    /// @notice Invalid signature
    error InvalidSignature();

    /**
     * @notice Mint specific coordinates
     */
    function mintMany(
        uint256[] calldata internalIds,
        ISquishiland.LandSize[] calldata sizes,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Mint a specific coordinate
     */
    function mint(
        uint256 internalId,
        ISquishiland.LandSize size,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Reserve a plot
     */
    function reserveMany(
        uint256[] calldata tokenIds,
        uint256[] calldata internalIds,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Reserve a plot
     */
    function reserve(
        uint256 tokenId,
        uint256 internalId,
        bytes calldata signature
    ) external payable;

    /**
     * @notice Return the ownership of the land contract back
     */
    function transferBackLandContract() external;

    /**
     * @notice Determine if a coordinate has been minted
     */
    function getTokenFromInternalId(uint256 internalId)
        external
        view
        returns (uint256);

    /**
     * @notice Determine coordinate from token id
     */
    function getInternalIdFromToken(uint256 tokenId)
        external
        view
        returns (uint256);
}

contract SquishilandSaleDelegator is ISquishilandSaleDelegator, Ownable {
    using ECDSA for bytes32;

    /// @notice Maximum lands
    uint256 public constant MAX_SUPPLY = 4444;

    /// @notice Land contract
    ISquishiland private immutable _land;

    /// @notice Oracle
    address private _oracleAddress;

    /// @notice Mark signature
    mapping(uint256 => uint256) private _internalIdToToken;

    /// @notice Status of the sale
    SaleStatus public saleStatus;

    constructor(ISquishiland land, address oracleAddress_) {
        _land = land;
        _oracleAddress = oracleAddress_;
        saleStatus = SaleStatus.CLOSED;
    }

    /**
     * @notice Mint specific coordinates
     */
    function mintMany(
        uint256[] calldata internalIds,
        ISquishiland.LandSize[] calldata sizes,
        bytes calldata signature
    ) public payable {
        require(saleStatus == SaleStatus.OPEN, "!mint_not_open");
        require(internalIds.length == sizes.length, "!param_mismatch");
        // if (internalIds.length != sizes.length) {
        //     revert ParameterMismatch();
        // }
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                ISquishilandSaleDelegator.mintMany.selector,
                internalIds,
                sizes
            )
        );
        require(_signatureValidated(hash_, signature), "!bad_signature");
        // if (!_signatureValidated(hash_, signature)) {
        //     revert InvalidSignature();
        // }
        for (uint256 i; i < internalIds.length; i++) {
            _mint(internalIds[i], sizes[i]);
        }
    }

    /**
     * @notice Mint a specific coordinate
     */
    function mint(
        uint256 internalId,
        ISquishiland.LandSize size,
        bytes calldata signature
    ) public payable vacantInternalId(internalId) {
        require(saleStatus == SaleStatus.OPEN, "!mint_not_open");
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                ISquishilandSaleDelegator.mint.selector,
                internalId,
                size
            )
        );
        require(_signatureValidated(hash_, signature), "!bad_signature");
        // if (!_signatureValidated(hash_, signature)) {
        //     revert InvalidSignature();
        // }
        _mint(internalId, size);
    }

    /**
     * @notice Reserve a plot
     */
    function reserveMany(
        uint256[] calldata tokenIds,
        uint256[] calldata internalIds,
        bytes calldata signature
    ) public payable {
        require(saleStatus != SaleStatus.CLOSED, "!sale_closed");
        require(internalIds.length == tokenIds.length, "!param_mismatch");
        // if (tokenIds.length != internalIds.length) {
        //     revert ParameterMismatch();
        // }
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                ISquishilandSaleDelegator.reserveMany.selector,
                tokenIds,
                internalIds
            )
        );
        require(_signatureValidated(hash_, signature), "!bad_signature");
        // if (!_signatureValidated(hash_, signature)) {
        //     revert InvalidSignature();
        // }
        for (uint256 i; i < internalIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_land.ownerOf(tokenId) == msg.sender, "!land_non-owner");
            // if (_land.ownerOf(tokenId) != msg.sender) {
            //     revert LandNonOwner(tokenId);
            // }
            _reserve(internalIds[i], tokenId);
        }
    }

    /**
     * @notice Reserve a coordinate
     */
    function reserve(
        uint256 tokenId,
        uint256 internalId,
        bytes calldata signature
    ) public payable vacantInternalId(internalId) {
        require(saleStatus != SaleStatus.CLOSED, "!sale_closed");
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                ISquishilandSaleDelegator.reserve.selector,
                tokenId,
                internalId
            )
        );
        require(_signatureValidated(hash_, signature), "!bad_signature");
        // if (!_signatureValidated(hash_, signature)) {
        //     revert InvalidSignature();
        // }
        require(_land.ownerOf(tokenId) == msg.sender, "!land_non-owner");
        // if (_land.ownerOf(tokenId) != msg.sender) {
        //     revert LandNonOwner(tokenId);
        // }
        _reserve(internalId, tokenId);
    }

    /**
     * @dev Ensure a plot of land is not minted twice
     */
    modifier vacantInternalId(uint256 internalId) {
        require(_internalIdToToken[internalId] == 0, "!not_vacant");
        // if (_internalIdToToken[internalId] != 0) {
        //     revert LandReserved(internalId);
        // }
        _;
    }

    /**
     * @dev Mint a specific coordinate
     */
    function _mint(uint256 internalId, ISquishiland.LandSize size) private {
        ISquishiland.LandAttribute memory landInfo = _land.land(size);
        uint256 nextId = landInfo.minted + landInfo.startingId;

        // @todo MAY BE exploitable!!!! must check recursively that msg.value decreases
        require(msg.value >= landInfo.price, "!no_funds");

        // associate token to coordinate
        _reserve(nextId, internalId);

        // mint as an admin
        _land.mintAdmin(size, msg.sender, 1);
    }

    /**
     * @dev Reserve a coordinate
     */
    function _reserve(uint256 tokenId, uint256 internalId) internal {
        _internalIdToToken[internalId] = tokenId;
    }

    modifier notReserved(uint256 internalId) {
        if (_internalIdToToken[internalId] == 0) {}
        _;
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
    function getTokenFromInternalId(uint256 internalId)
        public
        view
        returns (uint256)
    {
        uint256 tokenId = _internalIdToToken[internalId];
        require(tokenId != 0, "!not_found");
        // if (tokenId == 0) {
        //     revert TokenNotFound();
        // }
        return tokenId;
    }

    /**
     * @notice Determine coordinate from token id
     */
    function getInternalIdFromToken(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        unchecked {
            for (uint256 i; i < _land.totalSupply(); ++i) {
                if (_internalIdToToken[i] == tokenId) {
                    return i;
                }
            }
            revert TokenNotFound();
        }
    }

    /**
     * @notice Get available land plots
     */
    function getAvailableInternalIds() public view returns (uint256[] memory) {
        unchecked {
            uint256[] memory tokenIds = new uint256[](MAX_SUPPLY);
            uint256 tokenIdsIdx;
            for (uint256 i; i < tokenIds.length; ++i) {
                if (_internalIdToToken[i] == 0) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @notice Get available land plots
     */
    function getUnavailableInternalIds()
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory tokenIds = new uint256[](MAX_SUPPLY);
            uint256 tokenIdsIdx;
            for (uint256 i; i < tokenIds.length; ++i) {
                if (_internalIdToToken[i] != 0) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @notice Get all user land and their respective internal ids
     */
    function getOwnedLands(address account)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = _land.balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                try _land.ownerOf(i) returns (address originalOwner) {
                    if (originalOwner == account) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                } catch (bytes memory) {}
            }
            return tokenIds;
        }
    }

    /**
     * @dev Verifies if a hash was signed by the oracle
     */
    function _signatureValidated(bytes32 hash_, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        return
            hash_.toEthSignedMessageHash().recover(signature) == _oracleAddress;
    }

    /**
     * @notice Set the sale status
     */
    function setSaleStatus(SaleStatus status) public onlyOwner {
        saleStatus = status;
    }

    /**
     * @notice Set oracle address
     */
    function setOracleAddress(address address_) public onlyOwner {
        _oracleAddress = address_;
    }
}