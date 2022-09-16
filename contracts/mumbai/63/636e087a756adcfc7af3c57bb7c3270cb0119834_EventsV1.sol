/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: UNLICENSED

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


// File contracts/interface/IVenue.sol


pragma solidity ^0.8.0;

interface IVenue {
    //function bookVenue(address eventOrganiser, uint256 eventTokenId, uint256 tokenId, address tokenAddress, uint256 feeAmount, string memory _type, uint256 startTime, uint256 endTime) external payable;
    function getRentalFees(uint256 tokenId) external view returns(uint256 _rentalFees);
    function getTotalCapacity(uint256 tokenId) external view returns(uint256 _totalCapacity);
    function getVenueRentalCommission() external view returns(uint256 _venueRentalCommission);
    function getRentalFeesPerBlock(uint256 tokenId) external view returns(uint256 rentPerBlock);
    function getVenueOwner(uint256 tokenId) external view returns(address payable owner);
    function _exists(uint256 tokenId) external view returns (bool);
}


// File contracts/interface/IConversion.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the Price conversion contract
 */

interface IConversion {
    function convertFee(address paymentToken, uint256 mintFee)
        external
        view
        returns (uint256);

    function getBaseToken() external view returns(address);   

}


// File contracts/interface/ITicketMaster.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the Ticket Master contract
 */

interface ITicketMaster {
    function deployTicketNFT(uint eventId, string memory name, uint256[2] memory time, uint totalSupply) external returns(address);
}


// File contracts/interface/ITreasury.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the Treasury contract
 */

interface ITreasury {
    function claimFunds(address to, address tokenAddress, uint256 amount) external;
    function claimNft(address to, address tokenAddress, uint256 tokenId) external;
}


// File contracts/interface/ITicket.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the Ticket NFT contract
 */

interface ITicket {
    function ownerOf(uint eventId) external returns(address);
}


// File contracts/interface/IManageEvent.sol


pragma solidity ^0.8.0;

interface IManageEvent {
    function isEventEnded(uint256 eventId) external view returns(bool);
}


// File contracts/utils/EventStorage.sol



pragma solidity ^0.8.0;

contract EventStorage {
    //Details of the event
    struct Details {
        string name;
        string category;
        string description;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 venueTokenId;
        bool payNow;
        address payable eventOrganiser;
        uint256 ticketPrice;
    }

    //mapping for getting event details
    mapping(uint256 => Details) public getInfo;

    //mapping for getting supported erc20TokenAddress
    mapping(address => bool) public erc20TokenAddress;

    //mapping for getting supported erc721TokenAddress
    mapping(address => bool) public erc721TokenAddress;

    //mapping for featured events
    mapping(uint256 => bool) public featuredEvents;

    //mapping for favourite events
    mapping(address => mapping(uint256 => bool)) public favouriteEvents;

    //mapping for whiteListed address
    mapping(address => bool) public whiteListedAddress;

    //map venue ID to eventId list which are booked in that venue
    //when new event are created, add that event id to this array
    mapping(uint256 => uint256[]) public eventsInVenue;

    //mapping for getting rent status
    mapping(address => mapping(uint256 => bool)) public rentStatus;

    //mappping for storing erc20 balance against eventTokenId
    mapping(uint256 => uint256) public balance;

    // mapping for ticket NFT contract
    mapping(uint256 => address) public ticketNFTAddress;

    //mapping for storing tokenAddress against eventTokenId
    mapping(uint256 => address) public eventTokenAddress;

    //mapping for event start status
    mapping(uint256 => bool) public eventStartedStatus;

    //mapping for event cancel status
    mapping(uint256 => bool) public eventCancelledStatus;

    mapping(address => mapping(uint256 => bool)) public joinEventStatus;

    //block time
    uint256 public constant blockTime = 2;

    // Deviation Percentage
    uint256 internal deviationPercentage;

    //venue contract address
    address internal venueContract;

    //convesion contract address
    address internal conversionContract;

    //ticket master contract address
    address internal ticketMaster;

    //treasury contract
    address payable internal treasuryContract;

    address internal manageEvent;

    //isPublic true or false
    bool internal isPublic;

    //platformFeePercent
    uint256 internal platformFeePercent;

    address public signerAddress;

    //
    // This empty reserved space is put in place to allow future versions to add new
    // variables without shifting down storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    //
    uint256[999] private ______gap;
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     function ownable_init() internal initializer {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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


// File contracts/utils/EventERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

 contract EventERC721 is
    Initializable,
    Ownable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    // Base URI
    string private _baseURI;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init() internal onlyInitializing {
        _name = "Event NFT";
        _symbol = "EventNFT";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = EventERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) public view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = EventERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = EventERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            EventERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(EventERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;

}


// File contracts/utils/EventMetadata.sol

pragma solidity ^0.8.0;

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
contract EventMetadata is EventERC721 {

    uint256 private nextTokenId;

    mapping(uint256 => address payable) private tokenIdToCreator;

    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string indexed indexedTokenIPFSPath,
        string tokenIPFSPath
    );

    /**
     * @dev Stores hashes minted by a creator to prevent duplicates.
     */
    mapping(address => mapping(string => bool))
        private creatorToIPFSHashToMinted;

    event BaseURIUpdated(string baseURI);
    event NFTMetadataUpdated(string name, string symbol, string baseURI);
    event TokenCreatorUpdated(
        address indexed fromCreator,
        address indexed toCreator,
        uint256 indexed tokenId
    );

    /**
     * @notice Returns the IPFSPath to the metadata JSON file for a given NFT.
     */
    function getTokenCID(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _tokenURIs[tokenId];
    }

    /**
     * @notice Checks if the creator has already minted a given NFT.
     */
    function getHasCreatorMintedIPFSHash(
        address creator,
        string memory tokenIPFSPath
    ) public view returns (bool) {
        return creatorToIPFSHashToMinted[creator][tokenIPFSPath];
    }

    function _updateTokenCreator(uint256 tokenId, address payable creator)
        internal
    {
        emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

        tokenIdToCreator[tokenId] = creator;
    }

    /**
     * @notice Returns the creator's address for a given tokenId.
     */
    function tokenCreator(uint256 tokenId)
        public
        view
        returns (address payable)
    {
        return tokenIdToCreator[tokenId];
    }

    function _updateBaseURI(string memory _baseURI) internal {
        _setBaseURI(_baseURI);

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @dev The IPFS path should be the CID + file.extension, e.g.
     * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
     */
    function _setTokenIPFSPath(uint256 tokenId, string memory _tokenIPFSPath)
        internal
    {
        // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
        require(
            bytes(_tokenIPFSPath).length >= 46,
            "EventMetadata: Invalid IPFS path"
        );
        require(
            !creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath],
            "EventMetadata: NFT was already minted"
        );

        creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
        _setTokenURI(tokenId, _tokenIPFSPath);
    }

    /**
     * @notice Gets the tokenId of the next NFT minted.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     */
    function _initializeNFT721Mint() internal onlyInitializing {
        // Use ID 1 for the first NFT tokenId
        nextTokenId = 1;
        __ERC721_init();
    }

    /**
     * @notice Allows a creator to mint an NFT.
     */
    function _mintInternal(string memory _tokenIPFSPath)
        internal
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);
        _updateTokenCreator(tokenId, payable(msg.sender));
        _setTokenIPFSPath(tokenId, _tokenIPFSPath);
        emit Minted(msg.sender, tokenId, _tokenIPFSPath, _tokenIPFSPath);
    }

    /**
     * @notice Allows the creator to burn if they currently own the NFT.
     */
    function burn(uint256 tokenId) public {
        address owner = EventERC721.ownerOf(tokenId);
        require(msg.sender == owner, "EventMetadata: Invalid owner");
        _burn(tokenId);
    }

    uint256[999] private ______gap;

}


// File contracts/utils/VerifySignature.sol



pragma solidity ^0.8.0;

abstract contract VerifySignature {
    
    function getMessageHash(
        address ticketHolder,
        uint256 eventTokenId,
        uint256 ticketId
    ) public pure returns (bytes32) {
        if (ticketId == 0)
            return keccak256(abi.encodePacked(ticketHolder, eventTokenId));
        else
            return
                keccak256(
                    abi.encodePacked(ticketHolder, eventTokenId, ticketId)
                );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}


// File contracts/utils/EventAdminRole.sol



pragma solidity ^0.8.0;



contract EventAdminRole is EventStorage, EventMetadata, VerifySignature {

    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    ///@param venueContract venueContract address
    event VenueContractUpdated(address venueContract);

    ///@param treasuryContract treasuryContract address
    event TreasuryContractUpdated(address treasuryContract);

    ///@param conversionContract conversionContract address
    event ConversionContractUpdated(address conversionContract);

    ///@param ticketMaster ticketMaster contract address
    event TicketMasterContractUpdated(address ticketMaster);

    ///@param isPublic isPublic true or false
    event EventStatusUpdated(bool isPublic);

    ///@param platformFeePercent platformFeePercent
    event PlatformFeeUpdated(uint256 platformFeePercent);

    ///@param tokenAddress erc-20 token Address
    ///@param status status of the address(true or false)
    event Erc20TokenUpdated(address indexed tokenAddress, bool status);

    ///@param tokenAddress erc-721 token address
    ///@param status status of the address(true or false)
    event Erc721TokenUpdated(address indexed tokenAddress, bool status);
    ///@param percentage deviationPercentage
    event DeviationPercentageUpdated(uint256 percentage);

    ///@param whitelistedAddress users address
    ///@param status status of the address
    event WhiteList(address whitelistedAddress, bool status);

    ///@param signerAddress signer Address
    event signerAddressUpdated(address signerAddress);

    ///@notice Allows Admin to update deviation percentage
    ///@param _deviationPercentage deviationPercentage
    function updateDeviation(uint256 _deviationPercentage) external onlyOwner {
        deviationPercentage = _deviationPercentage;
        emit DeviationPercentageUpdated(_deviationPercentage);
    }

    ///@notice Add supported Erc-20 tokens for the payment
    ///@dev Only admin can call
    ///@dev -  Update the status of paymentToken
    ///@param tokenAddress erc-20 token Address
    ///@param status status of the address(true or false)
    function whitelistErc20TokenAddress(address tokenAddress, bool status)
        external
        onlyOwner
    {
         erc20TokenAddress[tokenAddress] = status;
        emit Erc20TokenUpdated(tokenAddress, status);
    
    }

    ///@notice Add supported Erc-721 tokens for the payment
    ///@dev Only admin can call
    ///@dev -  Update the status of paymentToken
    ///@param tokenAddress erc-721 token Address
    ///@param status status of the address(true or false)
    function whitelistErc721TokenAddress(address tokenAddress, bool status) external onlyOwner {
        erc721TokenAddress[tokenAddress] = status;
        emit Erc721TokenUpdated(tokenAddress, status);
    }

    ///@notice updates conversionContract address
    ///@param _conversionContract conversionContract address
    function updateConversionContract(address _conversionContract)
        external
        onlyOwner
    {
        require(
            _conversionContract.isContract(),
            "Events: Address is not a contract"
        );
        conversionContract = _conversionContract;
        emit ConversionContractUpdated(_conversionContract);
    }

    ///@notice updates conversionContract address
    ///@param _venueContract venueContract address
    function updateVenueContract(address _venueContract) external onlyOwner {
        require(
            _venueContract.isContract(),
            "Events: Address is not a contract"
        );
        venueContract = _venueContract;
        emit VenueContractUpdated(_venueContract);
    }

    ///@notice updates treasuryContract address
    ///@param _treasuryContract treasuryContract address
    function updateTreasuryContract(address payable _treasuryContract)
        external
        onlyOwner
    {
        require(
            _treasuryContract.isContract(),
            "Events: Address is not a contract"
        );
        treasuryContract = _treasuryContract;
        emit TreasuryContractUpdated(_treasuryContract);
    }

    ///@notice updates ticketMaster address
    ///@param _ticketMaster ticketMaster address
    function updateticketMasterContract(address _ticketMaster)
        external
        onlyOwner
    {
        require(
            _ticketMaster.isContract(),
            "Events: Address is not a contract"
        );
        ticketMaster = _ticketMaster;
        emit TicketMasterContractUpdated(_ticketMaster);
    }

    function updateManageEventContract(address _manageEvent) external onlyOwner {
        require(
            _manageEvent.isContract(),
            "Events: Address is not a contract"
        );
        manageEvent = _manageEvent;

    }

    ///@notice To update the event status(public or private events)
    ///@param _isPublic true or false
    function updateEventStatus(bool _isPublic) external onlyOwner {
        isPublic = _isPublic;
        emit EventStatusUpdated(_isPublic);
    }

    ///@notice updates platformFeePercent
    ///@param _platformFeePercent platformFeePercent
    function updatePlatformFee(uint256 _platformFeePercent) external onlyOwner {
        platformFeePercent = _platformFeePercent;
        emit PlatformFeeUpdated(_platformFeePercent);
    }

    ///@notice updates signer Address
    ///@param _signerAddress eventContract address
    function updateSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
        emit signerAddressUpdated(_signerAddress);
    }

    ///@notice Admin can whiteList users
    ///@param _whitelistAddresses users address
    ///@param _status status of the address
    function updateWhitelist(
        address[] memory _whitelistAddresses,
        bool[] memory _status
    ) external onlyOwner {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            whiteListedAddress[_whitelistAddresses[i]] = _status[i];
            emit WhiteList(_whitelistAddresses[i], _status[i]);
        }
    }

    ///@notice Returns venue contract address
    function getVenueContract() public view returns (address) {
        return venueContract;
    }

    ///@notice Returns conversionContract address
    function getConversionContract() public view returns (address) {
        return conversionContract;
    }

    ///@notice Returns treasuryContract address
    function getTreasuryContract() public view returns (address) {
        return treasuryContract;
    }

    ///@notice Returns ticketMaster address
    function getTicketMasterContract() public view returns (address) {
        return ticketMaster;
    }

    function getManageEventContract() public view returns (address) {
        return manageEvent;
    }

    ///@notice Returns deviationPercentage
    function getDeviationPercentage() public view returns (uint256) {
        return deviationPercentage;
    }

    ///@notice Returns platformFeePercent
    function getPlatformFeePercent() public view returns (uint256) {
        return platformFeePercent;
    }

    ///@notice Returns eventStatus
    function getEventStatus() public view returns (bool) {
        return isPublic;
    }

     ///@notice Returns whitelisted status of erc721TokenAddress
    function isErc721TokenWhitelisted(address tokenAddress) public view returns (bool) {
        return erc721TokenAddress[tokenAddress];
    }

    ///@notice Returns whitelisted status of erc20TokenAddress
    function isErc20TokenWhitelisted(address tokenAddress) public view returns (bool) {
        return erc20TokenAddress[tokenAddress];
    }

    function getSignerAddress() public view returns (address) {
        return signerAddress;
    }

    uint256[49] private ______gap;
}


// File contracts/event_newChanges.sol



pragma solidity ^0.8.0;
///@title Create and join events
///@author Prabal Srivastav
///@notice Users can create event and join events

contract EventsV1 is EventAdminRole {
    
    ///@param tokenId Event tokenId
    ///@param tokenCID Event tokenCID
    ///@param venueTokenId venueTokenId
    ///@param isEventPaid isEventPaid
    ///@param eventOrganiser address of the organiser
    ///@param ticketPrice ticketPrice of event
    event EventAdded(
        uint256 indexed tokenId,
        string tokenCID,
        uint256 venueTokenId,
        bool isVenueFeesPaid,
        bool isEventPaid,
        address eventOrganiser,
        uint256 ticketPrice,
        uint256 venueFeeAmount,
        address ticketNFTAddress
    );

    ///@param tokenId Event tokenId
    ///@param startTime Event startTime
    ///@param endTime Event endTime
    event EventUpdated(
        uint256 indexed tokenId,
        string description,
        uint256 startTime,
        uint256 endTime,
        uint256 venueFeeAmount
    );

    ///@param tokenId Event tokenId
    event Featured(uint256 indexed tokenId, bool isFeatured);

    ///@param user User address
    ///@param tokenId Event tokenId
    ///@param isFavourite is event favourite(true or false)
    event Favourite(address user, uint256 indexed tokenId, bool isFavourite);

    ///@param eventTokenId event tokenId
    ///@param eventOrganiser EventOrganiser address
    event VenueBooked(uint256 indexed eventTokenId, address eventOrganiser);

    ///@param eventTokenId event Token Id
    ///@param payNow pay venue fees now if(didn't pay earlier)
    event EventPaid(uint256 indexed eventTokenId, bool payNow, uint256 venueFeeAmount);

    ///@param eventTokenId event Token Id
    event EventStarted(uint eventTokenId);

    ///@param eventTokenId event Token Id
    event EventCancelled(uint256 indexed eventTokenId);

    ///@param tokenId Event tokenId
    ///@param user User address
    event Joined(
        uint256 indexed tokenId,
        address indexed user,
        uint256 joiningTime,
        uint256 ticketId
    );

    event VenueFeesClaimed(uint256 indexed venueTokenId, uint256[] eventIds, address venueOwner);

    event VenueFeesRefunded(uint256 indexed eventTokenId, address eventOrganiser);

    event EventEnded(uint256 indexed eventTokenId);

    //modifier for checking whitelistedUsers
    modifier onlyWhitelistedUsers() {
        require(
            whiteListedAddress[msg.sender] == true || isPublic == true,
            "Events : User address not whitelisted"
        );
        _;
    }

    //modifier for checking valid time
    modifier isValidTime(uint256 startTime, uint256 endTime) {
        require(
            startTime < endTime && startTime >= block.timestamp,
            "Invalid time input"
        );
        _;
    }

    function updateEvent(uint256 tokenId, string memory description, uint256[2] memory time) external {
        require(_exists(tokenId), "Events: TokenId does not exist");
        require(
            msg.sender == getInfo[tokenId].eventOrganiser,
            "Events: Address is not the event organiser address"
        );
        require(
            getInfo[tokenId].startTime > block.timestamp,
            "Events: Event is started"
        );
        uint256 venueTokenId = getInfo[tokenId].venueTokenId;
        require(
            isVenueAvailable(tokenId, venueTokenId, time[0], time[1], 1),
            "ERR_100:Events:Venue is not available"
        );
        if(time[0] != getInfo[tokenId].startTime || time[1] != getInfo[tokenId].endTime) {
            if(getInfo[tokenId].payNow == true) {
                uint256 feesPaid = balance[tokenId];
                (uint256 estimatedCost, uint256 _platformFees, ) = calculateRent(
                venueTokenId,
                time[0],
                time[1]
                );
                address tokenAddress = IConversion(conversionContract).getBaseToken();
                if(feesPaid > estimatedCost - _platformFees) {
                    ITreasury(treasuryContract).claimFunds(getInfo[tokenId].eventOrganiser,tokenAddress, feesPaid - estimatedCost - _platformFees);
                    balance[tokenId] -=  (feesPaid - estimatedCost - _platformFees);

                }
                else {
                    IERC20(tokenAddress).transferFrom(
                    getInfo[tokenId].eventOrganiser,
                    treasuryContract,
                    estimatedCost - _platformFees - feesPaid
                    );
                    balance[tokenId] += estimatedCost - _platformFees - feesPaid;
                }
            }
            getInfo[tokenId].startTime = time[0];
            getInfo[tokenId].endTime = time[1];
        }
        getInfo[tokenId].description = description;
        emit EventUpdated(tokenId, description, time[0], time[1], balance[tokenId]);
    }

    ///@notice Creates Event
    ///@dev Event organiser can call
    ///@dev - Check whether venue is available.
    ///@dev - Check whether event is paid or free for users.
    ///@dev - Check whether venue fees is paid or it is mark as pay later.
    ///@dev - Save all the fields in the contract.
    ///@param details[3] => details[0] = Event name, details[1] = Event category, details[2] = Event description
    ///@param time[2] => time[0] = Event startTime, time[1] = Event endTime
    ///@param tokenCID Event tokenCID
    ///@param venueTokenId venueTokenId
    ///@param venueFeeAmount fee of the venue
    ///@param ticketPrice ticketPrice of event
    ///@param isEventPaid isEventPaid(true or false)
    ///@param payNow pay venue fees now or later(true or false)
    function add(
        string[3] memory details,
        uint256[2] memory time,
        string memory tokenCID,
        uint256 venueTokenId,
        uint256 venueFeeAmount,
        uint256 ticketPrice,
        bool isEventPaid,
        bool payNow
    ) external onlyWhitelistedUsers {
        uint256 _tokenId = _mintInternal(tokenCID);
        require(
            IVenue(getVenueContract())._exists(venueTokenId),
            "Events: Venue tokenId does not exists"
        );
        require(
            isVenueAvailable(_tokenId, venueTokenId, time[0], time[1], 0),
            "ERR_100:Events:Venue is not available"
        );
        if (payNow == true) {
            checkVenueFees(
                venueTokenId,
                time[0],
                time[1],
                msg.sender,
                _tokenId,
                venueFeeAmount
            );
        }
        if (isEventPaid == false) {
            ticketPrice = 0;
        }
        getInfo[_tokenId] = Details(
            details[0],
            details[1],
            details[2],
            _tokenId,
            time[0],
            time[1],
            venueTokenId,
            payNow,
            payable(msg.sender),
            ticketPrice
        );

        ticketNFTAddress[_tokenId] = ITicketMaster(ticketMaster)
            .deployTicketNFT(
                _tokenId,
                details[0],
                time,
                IVenue(getVenueContract()).getTotalCapacity(venueTokenId)
            );
        emit EventAdded(
            _tokenId,
            tokenCID,
            venueTokenId,
            payNow,
            isEventPaid,
            msg.sender,
            ticketPrice,
            venueFeeAmount,
            ticketNFTAddress[_tokenId] 
        );
    }

    ///@notice Book venue
    ///@param eventTokenId eventTokenId
    function bookVenue(uint256 eventTokenId) internal {
        rentPaid(msg.sender, eventTokenId, true);
        emit VenueBooked(eventTokenId, msg.sender);
    }

    function calculateRent(
        uint256 venueTokenId,
        uint256 eventStartTime,
        uint256 eventEndTime
    )
        public
        view
        returns (
            uint256 _estimatedCost,
            uint256 _platformFees,
            uint256 _venueRentalCommissionFees
        )
    {
        uint256 noOfBlocks = (eventEndTime - eventStartTime) / blockTime;
        uint256 rentalFees = IVenue(getVenueContract()).getRentalFeesPerBlock(
            venueTokenId
        ) * noOfBlocks;
        uint256 platformFees = (rentalFees * platformFeePercent) / 100;
        uint256 venueRentalCommission = IVenue(getVenueContract())
            .getVenueRentalCommission();
        uint256 venueRentalCommissionFee = (rentalFees *
            venueRentalCommission) / 100;
        uint256 estimatedCost = rentalFees + platformFees;
        return (estimatedCost, platformFees, venueRentalCommissionFee);
    }

    ///@notice Feature the event
    ///@dev Only admin can call
    ///@dev - Mark the event as featured
    ///@param tokenId Event tokenId
    ///@param isFeatured Event featured(true/false)
    function featured(uint256 tokenId, bool isFeatured) external onlyOwner {
        require(_exists(tokenId), "Events: TokenId does not exist");
        featuredEvents[tokenId] = isFeatured;
        emit Featured(tokenId, isFeatured);
    }

    ///@notice Users can mark their favourite events
    ///@param tokenId Event tokenId
    ///@param isFavourite Event featured(true/false)
    function updateFavourite(uint256 tokenId, bool isFavourite) external {
        require(_exists(tokenId), "Events: TokenId does not exist");
        favouriteEvents[msg.sender][tokenId] = isFavourite;
        emit Favourite(msg.sender, tokenId, isFavourite);
    }

    function initialize() public initializer {
        Ownable.ownable_init();
        _initializeNFT721Mint();
        _updateBaseURI("https://ipfs.io/ipfs/");
    }


    ///@notice Returns true if rent paid
    ///@param eventOrganiser eventOrganiser address
    ///@param eventTokenId Event tokenId
    function isRentPaid(address eventOrganiser, uint256 eventTokenId)
        public
        view
        returns (bool)
    {
        return rentStatus[eventOrganiser][eventTokenId];
    }

    ///@notice To check amount is within deviation percentage
    ///@param feeAmount price of the ticket
    ///@param price price from the conversion contract
    function checkDeviation(uint256 feeAmount, uint256 price) public view {
        require(
            feeAmount >= price - ((price * (deviationPercentage)) / (100)) &&
                feeAmount <= price + ((price * (deviationPercentage)) / (100)),
            "Events: Amount not within deviation percentage"
        );
    }

    ///@notice Check for venue availability
    ///@param eventTokenId eventTokenId
    ///@param venueTokenId Venue tokenId
    ///@param startTime Venue startTime
    ///@param endTime Venue endTime
    ///@return _isAvailable Returns true if available
    function isVenueAvailable(
        uint256 eventTokenId,
        uint256 venueTokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 timeType
    ) internal isValidTime(startTime, endTime) returns (bool _isAvailable) {
        uint256[] memory bookedEvents = eventsInVenue[venueTokenId];
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < bookedEvents.length; i++) {
            if (bookedEvents[i] == eventTokenId || isEventCancelled(bookedEvents[i]) == true) continue;
            else {
                uint256 bookedStartTime = getInfo[bookedEvents[i]].startTime;
                uint256 bookedEndTime = getInfo[bookedEvents[i]].endTime;
                // skip for passed event
                if (currentTime >= bookedEndTime) continue;
                if (
                    currentTime >= bookedStartTime &&
                    currentTime <= bookedEndTime
                ) {
                    //check for ongoing event
                    if (startTime >= bookedEndTime) {
                        continue;
                    } else {
                        return false;
                    }
                } else {
                    //check for future event
                    if (
                        endTime <= bookedStartTime || startTime >= bookedEndTime
                    ) {
                        continue;
                    } else {
                        return false;
                    }
                }
            }
        }
        if (timeType == 0) eventsInVenue[venueTokenId].push(eventTokenId);
        return true;
    }

    ///@notice To check whether token is matic or any other token
    ///@param venueTokenId venueTokenId
    ///@param startTime event startTime
    ///@param endTime event endTime
    ///@param eventOrganiser event organiser address
    ///@param eventTokenId event tokenId
    ///@param feeAmount fee of the venue(rentalFee + platformFee)
    function checkVenueFees(
        uint256 venueTokenId,
        uint256 startTime,
        uint256 endTime,
        address eventOrganiser,
        uint256 eventTokenId,
        uint256 feeAmount
    ) internal {
        address tokenAddress = IConversion(conversionContract).getBaseToken();
        require(
            erc20TokenAddress[tokenAddress] == true,
            "Events: PaymentToken Not Supported"
        );
        (uint256 estimatedCost, uint256 _platformFees, ) = calculateRent(
            venueTokenId,
            startTime,
            endTime
        );
        uint256 platformFees = _platformFees;
        checkDeviation(feeAmount, estimatedCost);
        IERC20(tokenAddress).transferFrom(
            eventOrganiser,
            treasuryContract,
            feeAmount
        );
        balance[eventTokenId] = feeAmount - platformFees;
        eventTokenAddress[eventTokenId] = tokenAddress;
        bookVenue(eventTokenId);
    }

    function claimVenueFees(uint256 venueTokenId) external {
        require(
            IVenue(getVenueContract())._exists(venueTokenId),
            "Events: Venue tokenId does not exists"
        );
        uint256[] memory eventIds = eventsInVenue[venueTokenId];
        address tokenAddress = IConversion(conversionContract).getBaseToken();
        address venueOwner = IVenue(getVenueContract()).getVenueOwner(venueTokenId);
        require(msg.sender == venueOwner, "Events: Invalid Caller");
        for(uint256 i=0; i< eventIds.length; i++) {
            if(isEventCancelled(eventIds[i]) == false && block.timestamp > getInfo[eventIds[i]].endTime) {
                if(balance[eventIds[i]] > 0) {
                    ITreasury(treasuryContract).claimFunds(venueOwner,tokenAddress, balance[eventIds[i]]);
                    balance[eventIds[i]] = 0;
                }
            }
        }
        emit VenueFeesClaimed(venueTokenId, eventIds, venueOwner);
    }

    function refundVenueFees(uint256 eventTokenId) external {
        require(_exists(eventTokenId), "Events: TokenId does not exist");
        require(
            isEventCancelled(eventTokenId) == true,
            "Events: Event is not canceled"
        );
        require(msg.sender == getInfo[eventTokenId].eventOrganiser, "Events: Invalid Address");
        require(getInfo[eventTokenId].payNow == true, "Events: Fees not paid");
        address tokenAddress = IConversion(conversionContract).getBaseToken();
         (, , uint256 venueRentalCommissionFees) = calculateRent(
            getInfo[eventTokenId].venueTokenId,
            getInfo[eventTokenId].startTime,
            getInfo[eventTokenId].endTime
        );
        require(balance[eventTokenId] > 0, "Events: Funds already transferred");
        address venueOwner = IVenue(getVenueContract()).getVenueOwner(getInfo[eventTokenId].venueTokenId);
        ITreasury(treasuryContract).claimFunds(getInfo[eventTokenId].eventOrganiser,tokenAddress, balance[eventTokenId] - venueRentalCommissionFees);
        ITreasury(treasuryContract).claimFunds(venueOwner, tokenAddress, venueRentalCommissionFees);
        balance[eventTokenId] = 0;

        emit VenueFeesRefunded(eventTokenId, getInfo[eventTokenId].eventOrganiser);

    }

    ///@notice Start the event
    ///@param eventTokenId event Token Id
    ///@param venueFeeAmount fee of the venue
    function payEvent(uint256 eventTokenId, uint256 venueFeeAmount)
        external
    {
        require(_exists(eventTokenId), "Events: TokenId does not exist");
        (
            uint256 startTime,
            uint256 endTime,
            address eventOrganiser,
            bool payNow,
            uint256 venueTokenId,

        ) = getEventDetails(eventTokenId);
        require(
            endTime > block.timestamp,
            "Events: Event ended"
        );
        require(msg.sender == eventOrganiser, "Events: Invalid Address");

        require(
            eventStartedStatus[eventTokenId] == false,
            "Events: Event already started"
        );
        if (payNow == false) {
            checkVenueFees(
                venueTokenId,
                startTime,
                endTime,
                msg.sender,
                eventTokenId,
                venueFeeAmount
            );
            payNow = true;
            getInfo[eventTokenId].payNow = payNow;
            
        }
        else {
            uint256 feesPaid = balance[eventTokenId];
            (uint256 estimatedCost, uint256 _platformFees, ) = calculateRent(
            venueTokenId,
            startTime,
            endTime
            );
            address tokenAddress = IConversion(conversionContract).getBaseToken();
            if(feesPaid > estimatedCost - _platformFees) {
                ITreasury(treasuryContract).claimFunds(eventOrganiser,tokenAddress, feesPaid - estimatedCost - _platformFees);
                //IERC20(tokenAddress).transfer(eventOrganiser, feesPaid - estimatedCost - _platformFees);
                balance[eventTokenId] -=  (feesPaid - estimatedCost - _platformFees);

            }
            else {
                IERC20(tokenAddress).transferFrom(
                eventOrganiser,
                treasuryContract,
                estimatedCost - _platformFees - feesPaid
                );
                balance[eventTokenId] += estimatedCost - _platformFees - feesPaid;
            }
        }
        emit EventPaid(eventTokenId, payNow, venueFeeAmount);
    }

    function startEvent(uint256 eventTokenId) external {
        require(_exists(eventTokenId), "Events: TokenId does not exist");
        (
            uint256 startTime,
            uint256 endTime,
            address eventOrganiser,
            bool payNow,
            ,

        ) = getEventDetails(eventTokenId);
        require(
            block.timestamp >= startTime && endTime > block.timestamp,
            "Events: Event not live"
        );
        require(msg.sender == eventOrganiser, "Events: Invalid Address");
        require(payNow == true, "Events: Fees not paid");
        eventStartedStatus[eventTokenId] = true;
        emit EventStarted(eventTokenId);

    }

    ///@notice Cancel the event
    ///@param eventTokenId event Token Id
    function cancelEvent(uint256 eventTokenId) external {
        require(_exists(eventTokenId), "Events: TokenId does not exist");
        (
            ,
            ,
            address payable eventOrganiser,
            ,
            ,

        ) = getEventDetails(eventTokenId);
        require(isEventStarted(eventTokenId) == false, "Events: Event started");
        require(msg.sender == eventOrganiser, "Events: Invalid Address");
        require(
            eventCancelledStatus[eventTokenId] == false,
            "Events: Event already cancelled"
        );
        eventCancelledStatus[eventTokenId] = true;
        emit EventCancelled(eventTokenId);
    }


    ///@notice Users can join events
    ///@dev Public function
    ///@dev - Check whether event is started or not
    ///@dev - Check whether user has ticket if the event is paid
    ///@dev - Join the event
    ///@param eventTokenId Event tokenId
    function join(
        bytes memory signature,
        address ticketHolder, 
        uint256 eventTokenId, 
        uint256 ticketId
    ) external {
        require(
            recoverSigner(
                getMessageHash(ticketHolder, eventTokenId, ticketId),
                signature
            ) == getSignerAddress()
        );
        require(
            isEventCancelled(eventTokenId) == false,
            "Events: Event is cancelled"
        );
        require(
            _exists(eventTokenId),
            "Events: TokenId does not exist"
        );
        (uint256 startTime, uint256 endTime, address eventOrganiser , , , ) = getEventDetails(eventTokenId);
        require(
            isEventStarted(eventTokenId) == true,
            "Events: Event not started"
        );
        require(
            block.timestamp >= startTime && endTime > block.timestamp || isEventEnded(eventTokenId) == true,
            "Events: Event is not live" 
        );
        if(ticketHolder == eventOrganiser) {
            emit Joined(eventTokenId, ticketHolder, block.timestamp, ticketId);
        }
        else {
            require(
                ticketHolder == ITicket(ticketNFTAddress[eventTokenId]).ownerOf(ticketId),
                "Events: Caller is not the owner"
            );
            joinEventStatus[ticketNFTAddress[eventTokenId]][ticketId] = true;
            emit Joined(eventTokenId, ticketHolder, block.timestamp, ticketId);
        }
    }

    ///@notice Saves the status whether rent is paid or not
    ///@param eventOrganiser Event organiser address
    ///@param eventTokenId Event tokenId
    ///@param _isRentPaid true or false
    function rentPaid(
        address eventOrganiser,
        uint256 eventTokenId,
        bool _isRentPaid
    ) internal {
        rentStatus[eventOrganiser][eventTokenId] = _isRentPaid;
    }

    function isEventStarted(uint256 eventId) public view returns (bool) {
        return eventStartedStatus[eventId];
    }

    function isEventCancelled(uint256 eventId) public view returns (bool) {
        return eventCancelledStatus[eventId];
    }

    function getEventDetails(uint256 tokenId)
        public
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            address payable eventOrganiser,
            bool payNow,
            uint256 venueTokenId,
            uint256 ticketPrice
        )
    {
        return (
            getInfo[tokenId].startTime,
            getInfo[tokenId].endTime,
            getInfo[tokenId].eventOrganiser,
            getInfo[tokenId].payNow,
            getInfo[tokenId].venueTokenId,
            getInfo[tokenId].ticketPrice
        );
    }
        function getJoinEventStatus(address _ticketNftAddress, uint256 _ticketId)
        public
        view
        returns (bool)
    {
        return joinEventStatus[_ticketNftAddress][_ticketId];
    }

    function isEventEnded(uint256 eventId) public view returns (bool) {
        return IManageEvent(manageEvent).isEventEnded(eventId);
    }
}