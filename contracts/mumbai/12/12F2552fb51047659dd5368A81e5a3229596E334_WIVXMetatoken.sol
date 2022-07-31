// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "../ERC-1155M/Metatoken1155.sol";

error BurnMetatokenFirst();
error FullMetatokenBurnRequired();
error FullMetatokenTransferRequired();
error FullSupplyOnly();
error NoNFTSupply();
error TokenLocked();

/**
 * METATOKEN 001
 *
 * WIVX Deposit Certificate Metatoken
 *
 * This metatoken describes the deposit certificate / value token for each NFT; this allows it
 * to be deposited into the WIVX vault. This metatoken is considered FULLY HELD for a given NFT
 * if this contract is the sole and total owner of the metatoken's supply for that NFT.
 *
 * Restrictions:
 *
 * - General
 *     - The metatoken cannot be minted if there is no supply for the corresponding NFT.
 *     - Only the total supply of a given metatoken can be transferred at once (no partials).
 * - If the metatoken's supply is non-zero and it is not FULLY HELD:
 *     - The metatoken cannot be minted.
 *     - The metatoken cannot be burned.
 *     - The metatoken can only be transferred to this contract.
 *     - The NFT cannot be transferred.
 *     - The NFT cannot be minted.
 *     - The NFT cannot be burned.
 */
contract WIVXMetatoken is Metatoken1155 {
    // Offset storage slots in 32KiB units.
    // STORAGE_OFFSET = 0xFFFF * (uint128(uint256(keccak256("WIVXMetatoken"))) << 16);
    bytes32[0x06efccfca48bd161d8c9058a1fdaab340000] _storageOffset;

    uint16 constant METATOKEN_HOOKS =
          CAT_HAS_HOOK_NFT_BURN
        | CAT_HAS_HOOK_NFT_TRANSFER
        | CAT_HAS_HOOK_META_BURN
        | CAT_HAS_HOOK_META_MINT
        | CAT_HAS_HOOK_META_TRANSFER;

    function metatokenHooks() external pure override returns (uint16) {
        return METATOKEN_HOOKS;
    }

    function beforeBurn(
        address /* from */,
        uint256 id,
        uint256 /* amount */
    ) external view override {
        // The NFT can only be burned if the metatoken supply is zero.
        if (totalSupply(id | currentMetatokenId()) > 0) {
            revert BurnMetatokenFirst();
        }
    }
    
    function beforeTransfer(
        address /* from */,
        address /* to */,
        uint256 id,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view override {
        // The token can only be transferred if the metatoken supply is zero.
        if (totalSupply(id | currentMetatokenId()) > 0) {
            revert FullMetatokenBurnRequired();
        }
    }

    function preMetaBurn(
        address /* from */,
        uint256 id,
        uint256 amount
    ) external view override isOwnMetatoken(id) {
        // The metatoken can only be burned if the supply is nonzero and it is fully held by this contract.
        uint256 supply = totalSupply(id);
        if (amount != supply || balanceOf(address(this), id) != supply) {
            revert FullMetatokenTransferRequired();
        }
    }

    function preMetaMint(
        address /* to */,
        uint256 id,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view override isOwnMetatoken(id) {
        // The metatoken can only be minted if the supply of the corresponding NFT is not zero.
        if (totalSupply(id & TOKEN_ID_MASK) == 0) {
            revert NoNFTSupply();
        }

        // The metatoken can only be minted if the supply is zero or it is fully held by this contract.
        uint256 supply = totalSupply(id);
        if (supply > 0 && balanceOf(address(this), id) != supply) {
            revert TokenLocked();
        }
    }

    function preMetaTransfer(
        address from,
        address /* to */,
        uint256 id,
        uint256 amount,
        bytes memory /* data */
    ) external view override isOwnMetatoken(id) {
        // We can only transfer if either the supply is zero or the full amount is transferring. This
        // will ensure that only a single address holds the full supply of the metatoken at once.
        if (totalSupply(id) > 0 && amount != balanceOf(from, id)) {
            revert FullSupplyOnly();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IMetatoken1155.sol";

address constant ZERO_ADDRESS = address(0);

error AddressMismatch(address, address, address, address);
error ZeroAddress();

abstract contract Metatoken1155 is ERC165, IMetatoken1155 {
    /// @dev These must match exactly with the corresponding ERC-1155M contract.
    // contracts/ERC-1155M/ERC1155SupplyNE.sol:ERC1155SupplyNE
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => uint256) private _totalSupply;
    string private _uri;
    // @openzeppelin/contracts/security/ReentrancyGuard.sol:ReentrancyGuard
    uint256 private _status;
    // contracts/ERC-1155M/ERC1155M.sol:ERC1155M
    mapping(IMetatoken1155 => bytes4) private _metatokenDetails;
    IMetatoken1155[] private _nftHookBurnExtensions;
    IMetatoken1155[] private _nftHookMintExtensions;
    IMetatoken1155[] private _nftHookTransferExtensions;
    IMetatoken1155 private _currentMetatoken;

    // Ensures that the token's metatoken address is this contract's address.
    modifier isOwnMetatoken(uint256 id) {
        if (address(uint160(id >> TOKEN_ADDRESS_SHIFT)) != address(_currentMetatoken)) {
            revert AddressMismatch(address(uint160(id >> TOKEN_ADDRESS_SHIFT)), address(_currentMetatoken), address(this), msg.sender);
        }
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IMetatoken1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /////////////////
    /// ERC-1155M ///
    ///////////////// 

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) internal view returns (uint256) {
        if (account == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        return _balances[id][account];
    }

    /**
     * @dev Returns the currently executing metatoken extension.
     */
    function currentMetatoken() internal view returns (IMetatoken1155) {
        return _currentMetatoken;
    }

    /**
     * @dev Returns the currently executing metatoken extension's ID offset.
     */
    function currentMetatokenId() internal view returns (uint256) {
        return uint256(uint160(address(_currentMetatoken))) << TOKEN_ADDRESS_SHIFT;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) internal view returns (uint256) {
        return _totalSupply[id];
    }
    
    ////////////////////////////
    /// NFT - Precheck Hooks ///
    ////////////////////////////

    /**
     * @dev Called prior to the burn of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function beforeBurn(
        address /* from */,
        uint256 /* id */,
        uint256 /* amount */
    ) external view virtual override {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the mint of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function beforeMint(
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view virtual override {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of an NFT.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function beforeTransfer(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view virtual override {
        // Hook is unused.
    }

    //////////////////////////////
    /// NFT - Postaction Hooks ///
    //////////////////////////////

    /**
     * @dev Called after the burn of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function afterBurn(
        address /* from */,
        uint256 /* id */,
        uint256 /* amount */
    ) external override virtual {
        // Hook is unused.
    }

    /**
     * @dev Called after the mint of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function afterMint(
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external override virtual {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of an NFT.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function afterTransfer(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external override virtual {
        // Hook is unused.
    }

    //////////////////////////////////
    /// Metatoken - Precheck Hooks ///
    //////////////////////////////////

    /**
     * @dev Called prior to the burn of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function preMetaBurn(
        address /* from */,
        uint256 /* id */,
        uint256 /* amount */
    ) external view virtual override {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the mint of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function preMetaMint(
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view virtual override {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function preMetaTransfer(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external view virtual override {
        // Hook is unused.
    }

    ////////////////////////////////////
    /// Metatoken - Postaction Hooks ///
    ////////////////////////////////////

    /**
     * @dev Called after the burn of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function postMetaBurn(
        address /* from */,
        uint256 /* id */,
        uint256 /* amount */
    ) external override virtual {
        // Hook is unused.
    }

    /**
     * @dev Called after the mint of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function postMetaMint(
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external override virtual {
        // Hook is unused.
    }

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function postMetaTransfer(
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256 /* amount */,
        bytes memory /* data */
    ) external override virtual {
        // Hook is unused.
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// How many bits to shift to get the token adadress (NFT vs metatoken).
uint256 constant TOKEN_ADDRESS_SHIFT = 96;
// The mask to get the metatoken address from a given token id.
uint256 constant TOKEN_ADDRESS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;
// The mask to get the NFT id from a given token id.
uint256 constant TOKEN_ID_MASK = 0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

// Which hooks a metatoken has enabled.
uint16 constant CAT_HAS_HOOK_NFT_BURN      = 0x01;
uint16 constant CAT_HAS_HOOK_NFT_MINT      = 0x04;
uint16 constant CAT_HAS_HOOK_NFT_TRANSFER  = 0x08;
uint16 constant CAT_HAS_HOOK_META_BURN     = 0x10;
uint16 constant CAT_HAS_HOOK_META_MINT     = 0x40;
uint16 constant CAT_HAS_HOOK_META_TRANSFER = 0x80;

/**
 * @dev A metatoken is an extension of metadata and logic on top of an ERC-1155 NFT.
 *
 * The highest-order (big-endian) 20 bytes of the token ID is the address of the metatoken extension
 * contract. The next 4 bytes are optional metadata. The remaining 8 bytes are the token ID.
 *
 * Libraries that implement metatokens will be trustfully registered to ERC-1155 NFT contracts.
 *
 * To reduce unintentional confusion between interacting with the root NFT and its metatokens,
 * the naming of the hooks differs slightly: before/after is used when writing NFT logic, pre/post
 * is used when writing metatoken logic.
 */
interface IMetatoken1155 is IERC165 {
    //////////////////////////////////////
    /// Metatoken Registration Details ///
    //////////////////////////////////////

    /**
     * @dev Which hooks this metatoken has enabled
     */
    function metatokenHooks() external pure returns (uint16);

    ////////////////////////////
    /// NFT - Precheck Hooks ///
    ////////////////////////////

    /**
     * @dev Called prior to the burn of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function beforeBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external view;

    /**
     * @dev Called prior to the mint of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function beforeMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of an NFT.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function beforeTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    //////////////////////////////
    /// NFT - Postaction Hooks ///
    //////////////////////////////

    /**
     * @dev Called after the burn of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function afterBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Called after the mint of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function afterMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of an NFT.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function afterTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    //////////////////////////////////
    /// Metatoken - Precheck Hooks ///
    //////////////////////////////////

    /**
     * @dev Called prior to the burn of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function preMetaBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external view;

    /**
     * @dev Called prior to the mint of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function preMetaMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function preMetaTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    ////////////////////////////////////
    /// Metatoken - Postaction Hooks ///
    ////////////////////////////////////

    /**
     * @dev Called after the burn of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function postMetaBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Called after the mint of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function postMetaMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function postMetaTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
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