// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721Receiver.sol";
import "Strings.sol";

import "IViciAccess.sol";
import "OwnerOperator.sol";
import "AddressUtils.sol";
import "IERC721Operations.sol";

/**
 * @title ERC721 Operations
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev This contract implements most ERC721 behavior on behalf of a main 
 * ERC721 contract, to reduce the bytecode size of the main contract.
 * @dev The main contract MUST be the owner of this contract.
 * @dev Main contracts SHOULD refer to this contract via the IERC721Operations
 * interface.
 */
contract ERC721Operations is OwnerOperator, IERC721Operations {
    using AddressUtils for address;
    using Strings for string;

    /**
     * Tracks all information for an NFT collection.
     * ` tracks who owns which NFT, and who is approved to act on which
     *     accounts behalf.
     * `maxSupply` is the total maximum possible size for the collection.
     * `requireCategory` can be set to `true` to prevent tokens from being
     *     minted outside of a drop (i.e. with empty category name).
     * `dynamicURI` is the address of a contract that can override the default
     *     mechanism for generating tokenURIs.
     * `baseURI` is the string prefixed to the token id to build the token URI
     *     for tokens minted outside of a drop.
     * `allDropNames` is the collection of every drop that has been started.
     * `tokensReserved` is the count of all unminted tokens reserved by all
     *     active drops.
     * `customURIs` contains URI overrides for individual tokens.
     * `dropByName` is a lookup for the ManagedDrop.
     * `dropNameByTokenId` is a lookup to match a token to the drop it was
     *     minted in.
     * `maxRecallPeriod` is the maximum amount of time after minting, in
     *     seconds, that the contract owner or other authorized user can
     *     "recall" the NFT.
     * `bornOnDate` is the block timestamp when the token was minted.
     */
    uint256 public override maxRecallPeriod;
    mapping(uint256 => uint256) bornOnDate;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize(uint256 maxRecall) public virtual initializer {
        __ERC721Operations_init(maxRecall);
    }

    function __ERC721Operations_init(uint256 maxRecall)
        internal
        onlyInitializing
    {
        __OwnerOperator_init();
        __ERC721Operations_init_unchained(maxRecall);
    }

    function __ERC721Operations_init_unchained(uint256 maxRecall)
        internal
        onlyInitializing
    {
        maxRecallPeriod = maxRecall;
    }

    // @dev see ViciAccess
    modifier notBanned(IViciAccess ams, address account) {
        ams.enforceIsNotBanned(account);
        _;
    }

    // @dev see OwnerOperatorApproval
    modifier tokenExists(uint256 tokenId) {
        enforceItemExists(tokenId);
        _;
    }

    // @dev see ViciAccess
    modifier onlyOwnerOrRole(
        IViciAccess ams,
        address account,
        bytes32 role
    ) {
        ams.enforceOwnerOrRole(role, account);
        _;
    }

    /**
     * @dev reverts if the current time is past the recall window for the token
     *     or if the token has been made unrecallable.
     */
    modifier recallable(uint256 tokenId) {
        requireRecallable(tokenId);
        _;
    }

    /**
     * @dev revert if `account` is not the owner of the token or is not
     *      approved to transfer the token on behalf of its owner.
     */
    function enforceAccess(address account, uint256 tokenId)
        public
        view
        virtual
        override
    {
        enforceAccess(account, ownerOf(tokenId), tokenId, 1);
    }

    /**
     * @dev see IERC721
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address owner)
    {
        return ownerOfItemAtIndex(tokenId, 0);
    }

    /* ################################################################
     * Minting
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenId` MUST NOT exist.
     */
    function mint(IViciAccess ams, ERC721MintData memory mintData)
        public
        virtual
        override
        onlyOwner
        onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole)
        notBanned(ams, mintData.toAddress)
    {
        _mint(mintData);
    }

    /**
     * @dev Safely mints the new tokens and transfers them to the specified
     *     addresses.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - `_toAddresses` MUST NOT contain 0x0.
     * - `_toAddresses` MUST NOT contain any banned addresses.
     * - The length of `_toAddresses` must equal the length of `_tokenIds`.
     * - If any of `_toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenIds` MUST NOT exist.
     */
    function batchMint(IViciAccess ams, ERC721BatchMintData memory mintData)
        public
        virtual
        override
        onlyOwner
        onlyOwnerOrRole(ams, mintData.operator, mintData.requiredRole)
    {
        require(
            mintData.toAddresses.length == mintData.tokenIds.length,
            "array length mismatch"
        );

        for (uint256 i = 0; i < mintData.tokenIds.length; i++) {
            ams.enforceIsNotBanned(mintData.toAddresses[i]);

            _mint(
                ERC721MintData(
                    mintData.operator,
                    mintData.requiredRole,
                    mintData.toAddresses[i],
                    mintData.tokenIds[i],
                    "",
                    ""
                )
            );
        }
    }

    function _mint(ERC721MintData memory mintData) internal virtual {
        require(
            mintData.toAddress != address(0),
            "ERC721: mint to the zero address"
        );
        require(!exists(mintData.tokenId), "ERC721: token already minted");

        doTransfer(
            mintData.operator,
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            1
        );
        setBornOnDate(mintData.tokenId);
        checkOnERC721Received(
            mintData.operator,
            address(0),
            mintData.toAddress,
            mintData.tokenId,
            mintData.data
        );
    }

    /* ################################################################
     * Burning
     * ##############################################################*/

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     * - `burnData.tokenId` must exist
     */
    function burn(IViciAccess ams, ERC721BurnData memory burnData)
        public
        virtual
        override
        onlyOwner
        onlyOwnerOrRole(ams, burnData.operator, burnData.requiredRole)
    {
        _burn(burnData);
    }

    function _burn(ERC721BurnData memory burnData) internal virtual {
        address tokenowner = ownerOf(burnData.tokenId);

        doTransfer(
            burnData.operator,
            tokenowner,
            address(0),
            burnData.tokenId,
            1
        );
        clearBornOnDate(burnData.tokenId);
    }

    /* ################################################################
     * Transferring
     * ##############################################################*/

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be `transferData.fromAddress` or be approved by
     *     `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function transfer(IViciAccess ams, ERC721TransferData memory transferData)
        public
        virtual
        override
        onlyOwner
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _transfer(transferData);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be the `transferData.fromAddress` or be approved by
     *     the `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function safeTransfer(
        IViciAccess ams,
        ERC721TransferData memory transferData
    )
        public
        virtual
        override
        onlyOwner
        notBanned(ams, transferData.operator)
        notBanned(ams, transferData.fromAddress)
        notBanned(ams, transferData.toAddress)
    {
        _safeTransfer(transferData);
    }

    function _safeTransfer(ERC721TransferData memory transferData)
        internal
        virtual
    {
        _transfer(transferData);
        checkOnERC721Received(
            transferData.operator,
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            transferData.data
        );
    }

    function _transfer(ERC721TransferData memory transferData)
        internal
        virtual
    {
        require(
            transferData.toAddress != address(0),
            "ERC721: transfer to the zero address"
        );

        doTransfer(
            transferData.operator,
            transferData.fromAddress,
            transferData.toAddress,
            transferData.tokenId,
            1
        );
    }

    /* ################################################################
     * Approvals
     * ##############################################################*/

    /**
     * Requirements
     *
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `operator` MUST NOT be the zero address.
     * - `operator` and calling user MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function approve(
        IViciAccess ams,
        address caller,
        address operator,
        uint256 tokenId
    )
        public
        override
        onlyOwner
        notBanned(ams, caller)
        notBanned(ams, operator)
        tokenExists(tokenId)
    {
        address owner = ownerOf(tokenId);
        require(
            caller == owner || isApprovedForAll(owner, caller),
            "not authorized"
        );
        approveForItem(owner, operator, tokenId);
    }

    /**
     * @dev see IERC721
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        return getApprovedForItem(ownerOf(tokenId), tokenId);
    }

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `caller` and `operator` MUST NOT be the same address.
     * - `caller` MUST NOT be banned.
     * - `operator` MUST NOT be the zero address.
     * - If `approved` is `true`, `operator` MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function setApprovalForAll(
        IViciAccess ams,
        address caller,
        address operator,
        bool approved
    ) public override onlyOwner notBanned(ams, caller) {
        if (approved) {
            ams.enforceIsNotBanned(operator);
        }
        setApprovalForAll(caller, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (bool)
    {
        return isApproved(spender, ownerOf(tokenId), tokenId, 1);
    }

    /* ################################################################
     * Recall
     * ##############################################################*/

    /**
     * @dev revert if the recall period has expired.
     */
    function requireRecallable(uint256 tokenId) internal view {
        require(_recallTimeRemaining(tokenId) > 0, "not recallable");
    }

    /**
     * @dev If the bornOnDate for `tokenId` + `_maxRecallPeriod` is later than
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `tokenId`  doesn't exist in `_tracker`,
     * returns 0.
     */
    function recallTimeRemaining(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return _recallTimeRemaining(tokenId);
    }

    /**
     * @dev Returns the `bornOnDate` for `tokenId` as a Unix timestamp.
     * @dev If `tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return bornOnDate[tokenId];
    }

    /**
     * @dev Returns true if `tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return bornOnDate[tokenId] != 0;
    }

    /**
     * @dev Sets the `bornOnDate` for `tokenId` to the current timestamp.
     * @dev This should only be called when the token is minted.
     */
    function setBornOnDate(uint256 tokenId) internal {
        require(!hasBornOnDate(tokenId));
        bornOnDate[tokenId] = block.timestamp;
    }

    /**
     * @dev Remove `tokenId` from `_tracker`.
     * @dev This should be called when the token is burned, or when the end
     * customer has confirmed that they can access the token.
     */
    function clearBornOnDate(uint256 tokenId) internal {
        bornOnDate[tokenId] = 0;
    }

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * Requirements:
     *
     * - `transferData.operator` MUST be the contract owner or have the
     *      required role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `transferData.toAddress` MAY be 0, in which case the token is burned
     *     rather than recalled to a wallet.
     */
    function recall(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        override
        onlyOwner
        notBanned(ams, transferData.toAddress)
        tokenExists(transferData.tokenId)
        recallable(transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        _doRecall(transferData, requiredRole);
    }

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `transferData.operator` MUST be the contract owner.
     * - The owner of `transferData.tokenId` MUST be banned or OFAC sanctioned
     * - `transferData.destination` MAY be the zero address, in which case the
     *     asset is burned.
     */
    function recoverSanctionedAsset(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    )
        public
        override
        onlyOwner
        notBanned(ams, transferData.toAddress)
        tokenExists(transferData.tokenId)
        onlyOwnerOrRole(ams, transferData.operator, requiredRole)
    {
        require(
            ams.isBanned(transferData.fromAddress) ||
                ams.isSanctioned(transferData.fromAddress),
            "Not banned or sanctioned"
        );
        _doRecall(transferData, requiredRole);
    }

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * Requirements:
     *
     * - `caller` MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - `caller` MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(
        IViciAccess ams,
        address caller,
        bytes32 serviceRole,
        uint256 tokenId
    ) public override onlyOwner notBanned(ams, caller) tokenExists(tokenId) {
        if (caller != ams.owner() && !ams.hasRole(serviceRole, caller)) {
            enforceAccess(caller, ownerOf(tokenId), tokenId, 1);
        }

        clearBornOnDate(tokenId);
    }

    function _recallTimeRemaining(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 currentTimestamp = block.timestamp;
        uint256 recallDeadline = bornOnDate[tokenId] + maxRecallPeriod;
        if (currentTimestamp >= recallDeadline) {
            return 0;
        }

        return recallDeadline - currentTimestamp;
    }

    function _doRecall(
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    ) internal {
        approveForItem(
            transferData.fromAddress,
            transferData.operator,
            transferData.tokenId
        );

        if (transferData.toAddress == address(0)) {
            _burn(
                ERC721BurnData(
                    transferData.operator,
                    requiredRole,
                    transferData.fromAddress,
                    transferData.tokenId
                )
            );
        } else {
            _safeTransfer(transferData);
        }
    }

    /* ################################################################
     * Hooks
     * ##############################################################*/

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param fromAddress address representing the previous owner of the given token ID
     * @param toAddress target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function checkOnERC721Received(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (toAddress.isContract()) {
            try
                IERC721Receiver(toAddress).onERC721Received(
                    operator,
                    fromAddress,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                require(
                    retval == IERC721Receiver.onERC721Received.selector,
                    "ERC721: transfer to non ERC721Receiver implementer"
                );
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IAccessControlEnumerable.sol";

/**
 * @title ViciAccess Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for ViciAccess.
 * @dev External contracts SHOULD refer to implementers via this interface.
 */
interface IViciAccess is IAccessControlEnumerable {
    /**
     * @dev emitted when the owner changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    function enforceIsNotBanned(address account) external view;

    /**
     * @dev reverts if the account is not the owner and doesn't have the required role.
     */
    function enforceOwnerOrRole(bytes32 role, address account) external view;

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) external view returns (bool);

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) external view returns (bool);
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
pragma solidity ^0.8.17;

import "EnumerableSet.sol";

import "Ownable.sol";
import "EnumerableUint256Set.sol";
import "IOwnerOperator.sol";

/**
 * @title Owner Operator
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This contract manages ownership of items, and allows an owner to delegate
 *     other addresses as their agent.
 * @dev Concrete subclasses SHOULD add functionality to support a specific type
 *     of item.
 * @dev It can be used to manage ownership of various types of tokens, such as
 *     ERC20, ERC677, ERC721, ERC777, and ERC1155.
 * @dev For coin-type tokens such as ERC20, ERC677, or ERC721, always pass `1`
 *     as `thing`. Comments that refer to the use of this library to manage
 *     these types of tokens will use the shorthand `COINS:`.
 * @dev For NFT-type tokens such as ERC721, always pass `1` as the `amount`.
 *     Comments that refer to the use of this library to manage these types of
 *     tokens will use the shorthand `NFTS:`.
 * @dev For semi-fungible tokens such as ERC1155, use `thing` as the token ID
 *     and `amount` as the number of tokens with that ID.
 */

abstract contract OwnerOperator is Ownable, IOwnerOperator {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableUint256Set for EnumerableUint256Set.Uint256Set;

    /*
     * For ERC20 / ERC777, there will only be one item
     */
    EnumerableUint256Set.Uint256Set allItems;

    EnumerableSet.AddressSet allOwners;

    /*
     * amount of each item
     * mapping(itemId => amount)
     * for ERC721, amount will be 1 or 0
     * for ERC20 / ERC777, there will only be one key
     */
    mapping(uint256 => uint256) amountOfItem;

    /*
     * which items are owned by which owners?
     * for ERC20 / ERC777, the result will have 0 or 1 elements
     */
    mapping(address => EnumerableUint256Set.Uint256Set) itemIdsByOwner;

    /*
     * which owners hold which items?
     * For ERC20 / ERC777, there will only be 1 key
     * For ERC721, result will have 0 or 1 elements
     */
    mapping(uint256 => EnumerableSet.AddressSet) ownersByItemIds;

    /*
     * for a given item id, what is the address's balance?
     * mapping(itemId => mapping(owner => amount))
     * for ERC20 / ERC777, there will only be 1 key
     * for ERC721, result is 1 or 0
     */
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(uint256 => address)) itemApprovals;

    /*
     * for a given owner, how much of each item id is an operator allowed to control?
     */
    mapping(address => mapping(uint256 => mapping(address => uint256))) allowances;
    mapping(address => mapping(address => bool)) operatorApprovals;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function __OwnerOperator_init() internal onlyInitializing {
        __Ownable_init();
        __OwnerOperator_init_unchained();
    }

    function __OwnerOperator_init_unchained() internal onlyInitializing {}

    /**
     * @dev revert if the item does not exist
     */
    modifier itemExists(uint256 thing) {
        require(exists(thing), "invalid item");
        _;
    }

    /**
     * @dev revert if the user is the null address
     */
    modifier validUser(address user) {
        require(user != address(0), "invalid user");
        _;
    }

    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing)
        public
        view
        virtual
        override
        itemExists(thing)
    {}

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) public view virtual override returns (bool) {
        return amountOfItem[thing] > 0;
    }

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() public view virtual override returns (uint256) {
        return allOwners.length();
    }

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        require(allOwners.length() > index, "owner index out of bounds");
        return allOwners.at(index);
    }

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() public view virtual override returns (uint256) {
        return allItems.length();
    }

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(allItems.length() > index, "item index out of bounds");
        return allItems.at(index);
    }

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return amountOfItem[thing];
    }

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(address owner, uint256 thing)
        public
        view
        virtual
        override
        validUser(owner)
        returns (uint256)
    {
        return balances[thing][owner];
    }

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user)
        public
        view
        virtual
        override
        validUser(user)
        returns (uint256[] memory)
    {
        return itemIdsByOwner[user].asList();
    }

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(address owner)
        public
        view
        virtual
        override
        validUser(owner)
        returns (uint256)
    {
        return itemIdsByOwner[owner].length();
    }

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        validUser(owner)
        returns (uint256)
    {
        require(
            itemIdsByOwner[owner].length() > index,
            "item index out of bounds"
        );
        return itemIdsByOwner[owner].at(index);
    }

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing)
        public
        view
        virtual
        override
        itemExists(thing)
        returns (uint256)
    {
        return ownersByItemIds[thing].length();
    }

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(uint256 thing, uint256 index)
        public
        view
        virtual
        override
        itemExists(thing)
        returns (address owner)
    {
        require(
            ownersByItemIds[thing].length() > index,
            "owner index out of bounds"
        );
        return ownersByItemIds[thing].at(index);
    }

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) public virtual override onlyOwner {
        // can't mint and burn in same transaction
        require(
            fromAddress != address(0) || toAddress != address(0),
            "invalid transfer"
        );

        // can't transfer nothing
        require(amount > 0, "invalid transfer");

        if (fromAddress == address(0)) {
            // minting
            allItems.add(thing);
            amountOfItem[thing] += amount;
        } else {
            enforceItemExists(thing);
            if (operator != fromAddress) {
                require(
                    _checkApproval(operator, fromAddress, thing, amount),
                    "not authorized"
                );
                if (allowances[fromAddress][thing][operator] > 0) {
                    allowances[fromAddress][thing][operator] -= amount;
                }
            }
            require(
                balances[thing][fromAddress] >= amount,
                "insufficient balance"
            );

            itemApprovals[fromAddress][thing] = address(0);

            if (fromAddress == toAddress) return;

            balances[thing][fromAddress] -= amount;
            if (balances[thing][fromAddress] == 0) {
                allOwners.remove(fromAddress);
                ownersByItemIds[thing].remove(fromAddress);
                itemIdsByOwner[fromAddress].remove(thing);
                if (itemIdsByOwner[fromAddress].length() == 0) {
                    delete itemIdsByOwner[fromAddress];
                }
            }
        }

        if (toAddress == address(0)) {
            // burning
            amountOfItem[thing] -= amount;
            if (amountOfItem[thing] == 0) {
                allItems.remove(thing);
                delete ownersByItemIds[thing];
            }
        } else {
            allOwners.add(toAddress);
            itemIdsByOwner[toAddress].add(thing);
            ownersByItemIds[thing].add(toAddress);
            balances[thing][toAddress] += amount;
        }
    }

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual override {
        require(
            balances[thing][fromAddress] >= amount &&
                _checkApproval(operator, fromAddress, thing, amount),
            "not authorized"
        );
    }

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) public view virtual override returns (bool) {
        return _checkApproval(operator, fromAddress, thing, amount);
    }

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return operatorApprovals[fromAddress][operator];
    }

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) public override onlyOwner validUser(fromAddress) validUser(operator) {
        require(operator != fromAddress, "approval to self");
        operatorApprovals[fromAddress][operator] = approved;
    }

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) public view virtual override returns (uint256) {
        return allowances[fromAddress][thing][operator];
    }

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    )
        public
        virtual
        override
        onlyOwner
        validUser(fromAddress)
        validUser(operator)
    {
        require(operator != fromAddress, "approval to self");
        allowances[fromAddress][thing][operator] = amount;
    }

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(address fromAddress, uint256 thing)
        public
        view
        virtual
        override
        returns (address)
    {
        require(amountOfItem[thing] > 0);
        return itemApprovals[fromAddress][thing];
    }

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) public virtual override onlyOwner validUser(fromAddress) {
        require(operator != fromAddress, "approval to self");
        require(ownersByItemIds[thing].contains(fromAddress));
        itemApprovals[fromAddress][thing] = operator;
    }

    function _checkApproval(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) internal view virtual returns (bool) {
        return (operator == fromAddress ||
            operatorApprovals[fromAddress][operator] ||
            itemApprovals[fromAddress][thing] == operator ||
            allowances[fromAddress][thing][operator] >= amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import "Context.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's OwnableUpgradeable, 
 * moved here, renamed, and modified to use our Context and Initializable 
 * contracts so we don't have to deal with incompatibilities between OZ's
 * contracts and contracts-upgradeable packages.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;
import "Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * @dev This contract is a direct copy of OpenZeppelin's ContextUpgradeable, 
 * moved here, renamed, and modified to use our Initializable interface so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
 */
abstract contract Context is Initializable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.17;

import "AddressUtils.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's InitializableUpgradeable, 
 * moved here, renamed, and modified to use our AddressUtils library so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUtils.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.17;

/**
 * @dev Collection of functions related to the address type
 *
 * @dev This contract is a direct copy of OpenZeppelin's AddressUpgradeable, 
 * moved here and renamed so we don't have to deal with incompatibilities 
 * between OZ'` contracts and contracts-upgradeable `
 */
library AddressUtils {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Enumerable Uint256 Set
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 */
library EnumerableUint256Set {
    struct Uint256Set {
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint256Set storage _set, uint256 _value) internal view returns (bool) {
        return _set.indexes[_value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint256Set storage _set) internal view returns (uint256) {
        return _set.values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Uint256Set storage _set, uint256 _index) internal view returns (uint256) {
        return _set.values[_index];
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        if (!contains(_set, _value)) {
            _set.values.push(_value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            _set.indexes[_value] = _set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Uint256Set storage _set, uint256 _value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = _set.indexes[_value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = _set.values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = _set.values[lastIndex];

                // Move the last value to the index where the value to delete is
                _set.values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                _set.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            _set.values.pop();

            // Delete the index for the deleted slot
            delete _set.indexes[_value];

            return true;
        } else {
            return false;
        }
    }

    function asList(Uint256Set storage _set) internal view returns (uint256[] memory) {
        return _set.values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Owner Operator Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev public interface for the Owner Operator contract
 */
interface IOwnerOperator {
    /**
     * @dev revert if the item does not exist
     */
    function enforceItemExists(uint256 thing) external view;

    /* ################################################################
     * Queries
     * ##############################################################*/

    /**
     * @dev Returns whether `thing` exists. Things are created by transferring
     *     from the null address, and things are destroyed by tranferring to
     *     the null address.
     * @dev COINS: returns whether any have been minted and are not all burned.
     *
     * @param thing identifies the thing.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1.
     */
    function exists(uint256 thing) external view returns (bool);

    /**
     * @dev Returns the number of distict owners.
     * @dev use with `ownerAtIndex()` to iterate.
     */
    function ownerCount() external view returns (uint256);

    /**
     * @dev Returns the address of the owner at the index.
     * @dev use with `ownerCount()` to iterate.
     *
     * @param index the index into the list of owners
     *
     * Requirements
     * - `index` MUST be less than the number of owners.
     */
    function ownerAtIndex(uint256 index) external view returns (address);

    /**
     * @dev Returns the number of distict items.
     * @dev use with `itemAtIndex()` to iterate.
     * @dev COINS: returns 1 or 0 depending on whether any tokens exist.
     */
    function itemCount() external view returns (uint256);

    /**
     * @dev Returns the ID of the item at the index.
     * @dev use with `itemCount()` to iterate.
     * @dev COINS: don't use this function. The ID is always 1.
     *
     * @param index the index into the list of items
     *
     * Requirements
     * - `index` MUST be less than the number of items.
     */
    function itemAtIndex(uint256 index) external view returns (uint256);

    /**
     * @dev for a given item, returns the number that exist.
     * @dev NFTS: don't use this function. It returns 1 or 0 depending on
     *     whether the item exists. Use `exists()` instead.
     */
    function itemSupply(uint256 thing) external view returns (uint256);

    /**
     * @dev Returns how much of an item is held by an address.
     * @dev NFTS: Returns 0 or 1 depending on whether the address owns the item.
     *
     * @param owner the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function getBalance(address owner, uint256 thing)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the list of distinct items held by an address.
     * @dev COINS: Don't use this function.
     *
     * @param user the user
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     */
    function userWallet(address user) external view returns (uint256[] memory);

    /**
     * @dev For a given address, returns the number of distinct items.
     * @dev Returns 0 if the address doesn't own anything here.
     * @dev use with `itemOfOwnerByIndex()` to iterate.
     * @dev COINS: don't use this function. It returns 1 or 0 depending on
     *     whether the address has a balance. Use `balance()` instead.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `thing` MUST exist.
     */
    function ownerItemCount(address owner) external view returns (uint256);

    /**
     * @dev For a given address, returns the id of the item at the index.
     * @dev COINS: don't use this function.
     *
     * @param owner the owner.
     * @param index the index in the list of items.
     *
     * Requirements:
     * - `owner` MUST NOT be the null address.
     * - `index` MUST be less than the number of items.
     */
    function itemOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev For a given item, returns the number of owners.
     * @dev use with `ownerOfItemAtIndex()` to iterate.
     * @dev COINS: don't use this function. Use `ownerCount()` instead.
     * @dev NFTS: don't use this function. If `thing` exists, the answer is 1.
     *
     * Requirements:
     * - `thing` MUST exist.
     */
    function itemOwnerCount(uint256 thing) external view returns (uint256);

    /**
     * @dev For a given item, returns the owner at the index.
     * @dev use with `itemOwnerCount()` to iterate.
     * @dev COINS: don't use this function. Use `ownerAtIndex()` instead.
     * @dev NFTS: Returns the owner.
     *
     * @param thing identifies the item.
     * @param index the index in the list of owners.
     *
     * Requirements:
     * - `thing` MUST exist.
     * - `index` MUST be less than the number of owners.
     * - NFTS: `index` MUST be 0.
     */
    function ownerOfItemAtIndex(uint256 thing, uint256 index)
        external
        view
        returns (address owner);

    /* ################################################################
     * Minting / Burning / Transferring
     * ##############################################################*/

    /**
     * @dev transfers an amount of thing from one address to another.
     * @dev if `fromAddress` is the null address, `amount` of `thing` is
     *     created.
     * @dev if `toAddress` is the null address, `amount` of `thing` is
     *     destroyed.
     *
     * @param operator the operator
     * @param fromAddress the current owner
     * @param toAddress the current owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     * - `fromAddress` and `toAddress` MUST NOT both be the null address
     * - `amount` MUST be greater than 0
     * - if `fromAddress` is not the null address
     *   - `amount` MUST NOT be greater than the current owner's balance
     *   - `operator` MUST be approved
     */
    function doTransfer(
        address operator,
        address fromAddress,
        address toAddress,
        uint256 thing,
        uint256 amount
    ) external;

    /* ################################################################
     * Allowances / Approvals
     * ##############################################################*/

    /**
     * @dev Reverts if `operator` is allowed to transfer `amount` of `thing` on
     *     behalf of `fromAddress`.
     * @dev Reverts if `fromAddress` is not an owner of at least `amount` of
     *     `thing`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function enforceAccess(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view;

    /**
     * @dev Returns whether `operator` is allowed to transfer `amount` of
     *     `thing` on behalf of `fromAddress`.
     *
     * @param operator the operator
     * @param fromAddress the owner
     * @param thing identifies the item.
     * @param amount the amount
     *
     * Requirements:
     * - NFTS: `amount` SHOULD be 1
     * - COINS: `thing` SHOULD be 1
     */
    function isApproved(
        address operator,
        address fromAddress,
        uint256 thing,
        uint256 amount
    ) external view returns (bool);

    /**
     * @dev Returns whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     */
    function isApprovedForAll(address fromAddress, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Toggles whether an operator is approved for all items belonging to
     *     an owner.
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param approved the new approval status
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function setApprovalForAll(
        address fromAddress,
        address operator,
        bool approved
    ) external;

    /**
     * @dev returns the approved allowance for an operator.
     * @dev NFTS: Don't use this function. Use `getApprovedForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     */
    function allowance(
        address fromAddress,
        address operator,
        uint256 thing
    ) external view returns (uint256);

    /**
     * @dev sets the approval amount for an operator.
     * @dev NFTS: Don't use this function. Use `approveForItem()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     * @param amount the allowance amount.
     *
     * Requirements:
     * - COINS: `thing` SHOULD be 1
     * - `fromUser` MUST NOT be the null address
     * - `operator` MUST NOT be the null address
     * - `operator` MUST NOT be the `fromUser`
     */
    function approve(
        address fromAddress,
        address operator,
        uint256 thing,
        uint256 amount
    ) external;

    /**
     * @dev Returns the address of the operator who is approved for an item.
     * @dev Returns the null address if there is no approved operator.
     * @dev COINS: Don't use this function.
     *
     * @param fromAddress the owner
     * @param thing identifies the item.
     *
     * Requirements:
     * - `thing` MUST exist
     */
    function getApprovedForItem(address fromAddress, uint256 thing)
        external
        view
        returns (address);

    /**
     * @dev Approves `operator` to transfer `thing` to another account.
     * @dev COINS: Don't use this function. Use `setApprovalForAll()` or
     *     `approve()`
     *
     * @param fromAddress the owner
     * @param operator the operator
     * @param thing identifies the item.
     *
     * Requirements:
     * - `fromUser` MUST NOT be the null address
     * - `operator` MAY be the null address
     * - `operator` MUST NOT be the `fromUser`
     * - `fromUser` MUST be an owner of `thing`
     */
    function approveForItem(
        address fromAddress,
        address operator,
        uint256 thing
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IOwnerOperator.sol";
import "IViciAccess.sol";

/**
 * Information needed to mint a single token.
 */
struct ERC721MintData {
    address operator;
    bytes32 requiredRole;
    address toAddress;
    uint256 tokenId;
    string customURI;
    bytes data;
}

/**
 * Information needed to mint a batch of tokens.
 */
struct ERC721BatchMintData {
    address operator;
    bytes32 requiredRole;
    address[] toAddresses;
    uint256[] tokenIds;
}

/**
 * Information needed to transfer a token.
 */
struct ERC721TransferData {
    address operator;
    address fromAddress;
    address toAddress;
    uint256 tokenId;
    bytes data;
}

/**
 * Information needed to burn a token.
 */
struct ERC721BurnData {
    address operator;
    bytes32 requiredRole;
    address fromAddress;
    uint256 tokenId;
}

/**
 * @title ERC721 Operations Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 * 
 * @dev Interface for ERC721 Operations.
 * @dev Main contracts SHOULD refer to the ops contract via this interface.
 */
interface IERC721Operations is IOwnerOperator {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev emitted when a token is recalled during the recall period.
     * @dev emitted when a token is recovered from a banned or OFAC sanctioned
     *     user.
     */
    event TokenRecalled(uint256 tokenId, address recallWallet);

    /**
     * @dev revert if `account` is not the owner of the token or is not
     *      approved to transfer the token on behalf of its owner.
     */
    function enforceAccess(address account, uint256 tokenId) external view;

    /**
     * @dev see IERC721
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /* ################################################################
     * Minting
     * ##############################################################*/

    /**
     * @dev Safely mints a new token and transfers it to the specified address.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - If `mintData.toAddress` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenId` MUST NOT exist.
     */
    function mint(IViciAccess ams, ERC721MintData memory mintData) external;

    /**
     * @dev Safely mints the new tokens and transfers them to the specified
     *     addresses.
     * @dev Validates drop and available quantities
     * @dev Updates available quantities
     * @dev Deactivates drop when last one is minted
     *
     * Requirements:
     *
     * - `mintData.operator` MUST be owner or have the required role.
     * - `mintData.operator` MUST NOT be banned.
     * - `mintData.category` MAY be an empty string, in which case the token will
     *      be minted in the default category.
     * - If `mintData.category` is an empty string, `requireCategory`
     *      MUST NOT be `true`.
     * - If `mintData.category` is not an empty string it MUST refer to an
     *      existing, active drop with sufficient supply.
     * - `mintData.toAddress` MUST NOT be 0x0.
     * - `mintData.toAddress` MUST NOT be banned.
     * - `_toAddresses` MUST NOT contain 0x0.
     * - `_toAddresses` MUST NOT contain any banned addresses.
     * - The length of `_toAddresses` must equal the length of `_tokenIds`.
     * - If any of `_toAddresses` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}, which is called upon a safe
     *      transfer.
     * - `mintData.tokenIds` MUST NOT exist.
     */
    function batchMint(IViciAccess ams, ERC721BatchMintData memory mintData)
        external;

    /* ################################################################
     * Burning
     * ##############################################################*/

    /**
     * @dev Burns the identified token.
     * @dev Updates available quantities
     * @dev Will not reactivate the drop.
     *
     * Requirements:
     *
     * - `burnData.operator` MUST be owner or have the required role.
     * - `burnData.operator` MUST NOT be banned.
     * - `burnData.operator` MUST own the token or be authorized by the
     *     owner to transfer the token.
     * - `burnData.tokenId` must exist
     */
    function burn(IViciAccess ams, ERC721BurnData memory burnData) external;

    /* ################################################################
     * Transferring
     * ##############################################################*/

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be `transferData.fromAddress` or be approved by
     *     `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function transfer(IViciAccess ams, ERC721TransferData memory transferData)
        external;

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev See {safeTransferFrom}.
     *
     * - `transferData.fromAddress` and `transferData.toAddress` MUST NOT be
     *     the zero address.
     * - `transferData.toAddress`, `transferData.fromAddress`, and
     *     `transferData.operator` MUST NOT be banned.
     * - `transferData.tokenId` MUST belong to `transferData.fromAddress`.
     * - Calling user must be the `transferData.fromAddress` or be approved by
     *     the `transferData.fromAddress`.
     * - `transferData.tokenId` must exist
     */
    function safeTransfer(
        IViciAccess ams,
        ERC721TransferData memory transferData
    ) external;

    /* ################################################################
     * Approvals
     * ##############################################################*/

    /**
     * Requirements
     *
     * - caller MUST be the token owner or be approved for all by the token
     *     owner.
     * - `operator` MUST NOT be the zero address.
     * - `operator` and calling user MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function approve(
        IViciAccess ams,
        address caller,
        address operator,
        uint256 tokenId
    ) external;

    /**
     * @dev see IERC721
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * Requirements
     *
     * - Contract MUST NOT be paused.
     * - `caller` and `operator` MUST NOT be the same address.
     * - `caller` MUST NOT be banned.
     * - `operator` MUST NOT be the zero address.
     * - If `approved` is `true`, `operator` MUST NOT be banned.
     *
     * @dev see IERC721
     */
    function setApprovalForAll(
        IViciAccess ams,
        address caller,
        address operator,
        bool approved
    ) external;

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);

    /* ################################################################
     * Recall
     * ##############################################################*/

    /**
     * @dev the maximum amount of time after minting, in seconds, that the
     * contract owner or other authorized user can "recall" the NFT.
     */
    function maxRecallPeriod() external view returns (uint256);

    /**
     * @dev If the bornOnDate for `tokenId` + `_maxRecallPeriod` is later than
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `tokenId`  doesn't exist in `_tracker`,
     * returns 0.
     */
    function recallTimeRemaining(uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the `bornOnDate` for `tokenId` as a Unix timestamp.
     * @dev If `tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns true if `tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(uint256 tokenId) external view returns (bool);

    /**
     * @notice An NFT minted on this contact can be "recalled" by the contract
     * owner for an amount of time defined here.
     * @notice An NFT cannot be recalled once this amount of time has passed
     * since it was minted.
     * @notice The purpose of the recall function is to support customers who
     * have supplied us with an incorrect address or an address that doesn't
     * support Polygon (e.g. Coinbase custodial wallet).
     * @notice Divide the recall period by 86400 to convert from seconds to days.
     *
     * Requirements:
     *
     * - `transferData.operator` MUST be the contract owner or have the
     *      required role.
     * - The token must exist.
     * - The current timestamp MUST be within `maxRecallPeriod` of the token's
     *    `bornOn` date.
     * - `transferData.toAddress` MAY be 0, in which case the token is burned
     *     rather than recalled to a wallet.
     */
    function recall(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    ) external;

    /**
     * @notice recover assets in banned or sanctioned accounts
     *
     * Requirements
     * - `transferData.operator` MUST be the contract owner.
     * - The owner of `transferData.tokenId` MUST be banned or OFAC sanctioned
     * - `transferData.destination` MAY be the zero address, in which case the
     *     asset is burned.
     */
    function recoverSanctionedAsset(
        IViciAccess ams,
        ERC721TransferData memory transferData,
        bytes32 requiredRole
    ) external;

    /**
     * @notice Prematurely ends the recall period for an NFT.
     * @notice This action cannot be reversed.
     *
     * Requirements:
     *
     * - `caller` MUST be one of the following:
     *    - the contract owner.
     *    - the a user with customer service role.
     *    - the token owner.
     *    - an address authorized by the token owner.
     * - `caller` MUST NOT be banned or on the OFAC sanctions list
     */
    function makeUnrecallable(
        IViciAccess ams,
        address caller,
        bytes32 serviceRole,
        uint256 tokenId
    ) external;
}