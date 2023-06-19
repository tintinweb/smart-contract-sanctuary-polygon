// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CashBonusConfig {
    uint32 timestamp;
    uint32 duration;
    uint16 rate;
}

interface CashReserve {
    function totalDeposits() external view returns (uint256);
}

interface CashInterface is IERC20 {
    event Mint(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 value,
        uint256 supply,
        uint256 deposits,
        uint256 reserves,
        uint256 timestamp
    );

    event Burn(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );

    event Issue(
        address indexed sender,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    event Inflate(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    event Deflate(
        address indexed sender,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );

    event Collect(
        address indexed sender,
        address indexed to,
        uint256 amount,
        uint256 found,
        uint256 timestamp
    );

    event SetBonus(
        address indexed from,
        uint32 bonus,
        uint32 duration,
        uint16 rate,
        uint256 timestamp
    );

    event SetReserve(
        address indexed from,
        CashReserve reserve,
        uint256 timestamp
    );

    event Lock(address indexed from, uint256 timestamp);

    function reserve() external view returns (CashReserve);

    function totalDeposits() external view returns (uint256);

    function bonusRate(uint256 value, uint256 timestamp) external view returns (uint256);

    function mint(address to) external payable returns (uint256);

    function swap(address to, uint256 cash) external returns (uint256);

    function burn(uint256 amount) external;

    function issue() external payable returns (uint256);

    function inflate(address to, uint256 amount) external;

    function deflate(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

struct Art {
    IERC721Metadata collection;
    uint256 collectable;
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

interface Encoder {
    function tokenURI(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "../helpers/Encoder.sol";
import "./TreasuryInterface.sol";

contract NoteEncoder is Encoder {
    TreasuryInterface private _treasury;

    function tokenURI(uint256 id) public view override returns (string memory) {
        Art memory art = _treasury.getPrintArt(id);
        return art.collection.tokenURI(art.collectable);
    }

    function treasury() external view returns (TreasuryInterface) {
        return _treasury;
    }

    constructor(TreasuryInterface treasury_) {
        _treasury = treasury_;
    }
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../helpers/Art.sol";

struct Security {
    address delegate;
    address releaseTo;
    address closeTo;
    address rewardTo;
    uint32 releaseBonus;
    uint32 rewardBonus;
}

struct Deposit {
    uint256 amount;
    uint64 timestamp;
    uint64 collected;
    uint64 duration;
    uint32 rate;
}

interface NoteInterface {
    event Print(
        address sender,
        uint256 indexed id,
        IERC721 indexed collection,
        uint256 indexed collectable,
        uint256 timestamp
    );

    event Secure(
        address indexed sender,
        uint256 indexed id,
        address indexed delegate,
        address releaseTo,
        address closeTo,
        address rewardTo,
        uint32 releaseBonus,
        uint32 rewardBonus,
        uint256 timestamp
    );

    event Certificate(
        address indexed sender,
        uint256 indexed id,
        uint256 indexed print,
        uint256 principal,
        uint64 duration,
        uint64 rate,
        uint256 amount,
        uint256 value,
        uint256 timestamp
    );

    function count() external view returns (uint256);

    function delegateOf(uint256 id) external view returns (address);

    function getArt(uint256 id) external view returns (Art memory);

    function getPrint(uint256 id) external view returns (uint256);

    function getPrintArt(uint256 id) external view returns (Art memory);

    function getSecurity(uint256 id) external view returns (Security memory);

    function getDeposit(uint256 id) external view returns (Deposit memory);

    function getReward(uint256 id) external view returns (uint256);

    function getClaim(uint256 id) external view returns (uint256);

    function getPenalty(uint256 id) external view returns (uint256);

    function getInterest(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "../cash/CashInterface.sol";
import "./NoteInterface.sol";
import "../helpers/Art.sol";

struct DepositParams {
    address to;
    uint256 amount;
    uint64 duration;
}

struct ReleaseParams {
    address to;
    uint256 id;
    uint256 limit;
}

struct CloseParams {
    uint256 id;
    address to;
    address releaseTo;
}

interface TreasuryInterface is NoteInterface, IERC721 {
    event Reward(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 reward,
        uint256 limit,
        uint32 rewardBonus,
        uint256 timestamp
    );

    event Release(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 interest,
        uint256 release,
        uint32 releaseBonus,
        uint256 timestamp
    );

    event Boost(
        address indexed sender,
        uint256 indexed id,
        uint256 interest,
        uint256 released,
        uint256 extra,
        uint256 value,
        uint256 principal,
        uint256 timestamp
    );

    event Close(
        address indexed sender,
        uint256 indexed id,
        address indexed closeTo,
        address releaseTo,
        uint256 amount,
        uint256 interest,
        uint256 penalty,
        uint256 released,
        uint256 captured,
        uint32 releaseBonus,
        uint256 timestamp
    );

    event Capture(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 penalty,
        uint256 captured,
        uint256 timestamp
    );

    function forge(
        address to,
        Art calldata art
    ) external returns (uint256 id);

    function deposit(
        uint256 print,
        DepositParams calldata params
    ) external payable returns (uint256 id);

    function forgeDeposit(
        Art calldata art,
        DepositParams calldata params
    ) external payable returns (uint256 id);

    function reward(ReleaseParams calldata params) external returns (uint256);

    function release(ReleaseParams calldata params) external returns (uint256);

    function boost(uint256 id, uint256 extra) external payable returns (uint256);

    function close(CloseParams calldata params) external;

    function secure(uint256 id, Security calldata params) external;

    function capture(uint256 id, address to) external returns (uint256);

    function captureMany(uint256[] memory ids, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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