// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

enum StickerStatus {
    None,
    Fixed,
    Free
}

enum WhitelistStatus {
    None,
    Fixed
}

struct StickerPrice {
    StickerStatus status;
    uint256 price;
    address seller;
    uint256 amount;
}

struct StickerWhitelist {
    WhitelistStatus status;
    mapping(address => bool) whitelist;
}

contract DMTPMarket {
    event SetPrice(
        uint256 indexed stickerId,
        uint256 indexed price,
        StickerStatus indexed status
    );
    event SetWhiteList(uint256 indexed stickerId, string whitelist);
    event ClearWhitelist(uint256 indexed stickerId);
    event Buy(
        uint256 indexed stickerId,
        address indexed buyer,
        uint256 indexed price
    );

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => StickerWhitelist) private _whitelist;
    mapping(uint256 => StickerPrice) private _stickerPrice;

    IERC20 private _token;
    IERC1155 private _sticker;
    IAccessControl private _accessControl;

    constructor(address token, address sticker) {
        _token = IERC20(token);
        _sticker = IERC1155(sticker);
        _accessControl = IAccessControl(sticker);
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `MINTER_ROLE`.
     */
    modifier onlyMintRole() {
        require(
            _accessControl.hasRole(MINTER_ROLE, msg.sender),
            "DMTPMarket: only minter"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `sticker` is not sale.
     */
    modifier onlyStickerSale(uint256 stickerId) {
        require(
            _stickerPrice[stickerId].status != StickerStatus.None,
            "DMTPMarket: sticker not for sale"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not owner of sticker.
     */
    modifier onlyOwner(uint256 stickerId) {
        require(
            _sticker.balanceOf(msg.sender, stickerId) > 0,
            "DMTPMarket: only owner"
        );
        _;
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is not in whitelist to Buy sticker, in case sticker have whitelist.
     */
    modifier onlyWhitelist(uint256 stickerId) {
        if (_whitelist[stickerId].status == WhitelistStatus.Fixed)
            require(
                _whitelist[stickerId].whitelist[msg.sender],
                "DMTPMarket: not in whitelist"
            );
        _;
    }

    /**
     * @dev set price for sticker.
     *
     * Requirements:
     * - `msg.sender` must be owner of sticker.
     * - `msg.sender` must be have `MINTER_ROLE`.
     * - `status` equa None for disallow to Buy sticker.
     * - `status` equa Free for airdrop sticker.
     * - `status` equa Fixed for sale sticker.
     * - `price` must be equal 0 when `status` equa Free.
     * - `price` must be greater than 0 when `status` equa Fixed.
     * - `price` will be dont care when `status` equa None.
     * - `whitelist` empty when everyone can Buy.
     * - `whitelist` not empty when only address in whitelist can Buy.
     */
    function setStickerPrice(
        uint256 stickerId,
        uint256 amount,
        uint256 price,
        bool sellable,
        address[] memory whitelist
    ) public onlyMintRole onlyOwner(stickerId) {
        StickerStatus status;
        if (sellable) {
            if (price > 0) status = StickerStatus.Fixed;
            else status = StickerStatus.Free;
        }

        _stickerPrice[stickerId] = StickerPrice(
            status,
            price,
            msg.sender,
            amount
        );
        emit SetPrice(stickerId, price, status);
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = true;
            }
            emit SetWhiteList(stickerId, joinAddress(whitelist));
        }
    }

    function setStickerPriceBatch(
        uint256[] memory stickerIds,
        uint256[] memory amounts,
        uint256[] memory prices,
        bool[] memory sellables,
        address[][] memory whitelists
    ) public {
        require(
            stickerIds.length == prices.length &&
                stickerIds.length == amounts.length &&
                stickerIds.length == sellables.length &&
                stickerIds.length == whitelists.length,
            "DMTPMarket: length not match"
        );
        for (uint256 i = 0; i < stickerIds.length; i++) {
            setStickerPrice(
                stickerIds[i],
                amounts[i],
                prices[i],
                sellables[i],
                whitelists[i]
            );
        }
    }

    /**
     * @dev set whitelist for sticker.
     *
     * Requirements:
     *
     * - `msg.sender` must be owner of sticker.
     * - `msg.sender` must be have `MINTER_ROLE`.
     * - `whitelist` empty when everyone can Buy.
     * - `whitelist` not empty when only address in whitelist can Buy.
     */
    function setStickerWhitelist(uint256 stickerId, address[] memory whitelist)
        public
        onlyMintRole
        onlyOwner(stickerId)
    {
        if (whitelist.length == 0) {
            delete _whitelist[stickerId];
            emit ClearWhitelist(stickerId);
        } else {
            _whitelist[stickerId].status = WhitelistStatus.Fixed;
            for (uint256 i = 0; i < whitelist.length; i++) {
                _whitelist[stickerId].whitelist[whitelist[i]] = true;
            }
            emit SetWhiteList(stickerId, joinAddress(whitelist));
        }
    }

    function setStickerWhitelistBatch(
        uint256[] memory stickerIds,
        address[][] memory whitelist
    ) public {
        require(
            stickerIds.length == whitelist.length,
            "DMTPMarket: stickerIds and whitelist length not match"
        );
        for (uint256 i = 0; i < stickerIds.length; i++) {
            setStickerWhitelist(stickerIds[i], whitelist[i]);
        }
    }

    /**
     * @dev Buy sticker.
     *
     * Requirements:
     * - `msg.sender` must be have `appvore` erc20 token on this contract before call this function.
     * - `sticker` owner must be have `appvore` erc721 sticker nft on this contract before this function call.
     * - `stickerId` must be exist.
     * - `stickerId` must be for sale.
     * - `msg.sender` must be in whitelist if sticker have whitelist.
     */
    function buy(uint256 stickerId)
        external
        onlyStickerSale(stickerId)
        onlyWhitelist(stickerId)
    {
        require(
            _sticker.balanceOf(msg.sender, stickerId) == 0,
            "DMTPMarket: only own one sticker"
        );
        StickerPrice memory stickerPrice = _stickerPrice[stickerId];
        require(
            stickerPrice.amount > 0,
            "DMTPMarket: sticker amount not enough"
        );
        uint256 price = stickerPrice.price;

        _token.transferFrom(msg.sender, stickerPrice.seller, price);
        _sticker.safeTransferFrom(
            stickerPrice.seller,
            msg.sender,
            stickerId,
            1,
            ""
        );
        delete _stickerPrice[stickerId];
        delete _whitelist[stickerId];
        emit Buy(stickerId, msg.sender, _stickerPrice[stickerId].price);
    }

    function joinAddress(address[] memory addresses)
        private
        pure
        returns (string memory)
    {
        bytes memory output;

        for (uint256 i = 0; i < addresses.length; i++) {
            output = abi.encodePacked(
                output,
                ",",
                Strings.toHexString(addresses[i])
            );
        }

        return string(output);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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