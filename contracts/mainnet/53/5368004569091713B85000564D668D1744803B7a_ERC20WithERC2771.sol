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
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * The caller must be the current contract itself.
 */
error ErrSenderIsNotSelf();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./ERC2771ContextStorage.sol";

abstract contract ERC2771ContextInternal is Context {
    function _isTrustedForwarder(address operator) internal view returns (bool) {
        return ERC2771ContextStorage.layout().trustedForwarder == operator;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC2771ContextStorage {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.ERC2771Context");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC20BaseERC2771.sol";
import "./extensions/supply/ERC20SupplyExtension.sol";
import "./extensions/mintable/ERC20MintableExtension.sol";
import "./extensions/burnable/ERC20BurnableExtension.sol";

/**
 * @title ERC20 - with meta-transactions
 * @notice Standard EIP-20 with ability to accept meta transactions (mainly transfer and approve methods).
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IERC20 IERC20Base IERC20SupplyExtension IERC20MintableExtension
 */
contract ERC20WithERC2771 is ERC20BaseERC2771, ERC20SupplyExtension, ERC20MintableExtension {
    function _msgSender() internal view virtual override(Context, ERC20BaseERC2771) returns (address) {
        return ERC20BaseERC2771._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC20BaseERC2771) returns (bytes calldata) {
        return ERC20BaseERC2771._msgData();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20BaseInternal, ERC20SupplyExtension) {
        ERC20SupplyExtension._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { IERC20Base } from "./IERC20Base.sol";
import { ERC20BaseInternal } from "./ERC20BaseInternal.sol";
import { ERC20BaseStorage } from "./ERC20BaseStorage.sol";

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20Base is IERC20Base, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20Base
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20Base
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20Base
     */
    function allowance(address holder, address spender) public view virtual returns (uint256) {
        return _allowance(holder, spender);
    }

    /**
     * @inheritdoc IERC20Base
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        return _approve(_msgSender(), spender, amount);
    }

    /**
     * @inheritdoc IERC20Base
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        return _transfer(_msgSender(), recipient, amount);
    }

    /**
     * @inheritdoc IERC20Base
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../metatx/ERC2771ContextInternal.sol";

import "./ERC20Base.sol";

/**
 * @title Base ERC20 contract with meta-transactions support (via ERC2771).
 */
abstract contract ERC20BaseERC2771 is ERC20Base, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import { IERC20BaseInternal } from "./IERC20BaseInternal.sol";
import { ERC20BaseStorage } from "./ERC20BaseStorage.sol";

/**
 * @title Base ERC20 internal functions, excluding optional extensions
 */
abstract contract ERC20BaseInternal is Context, IERC20BaseInternal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().totalSupply;
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(address account) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().balances[account];
    }

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function _allowance(address holder, address spender) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    /**
     * @notice enable spender to spend tokens on behalf of holder
     * @param holder address on whose behalf tokens may be spent
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ERC20BaseStorage.layout().allowances[holder][spender] = amount;

        emit Approval(holder, spender, amount);

        return true;
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += amount;
        l.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 balance = l.balances[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            l.balances[account] = balance - amount;
        }
        l.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     * @return success status (always true; otherwise function should revert)
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        require(holder != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        require(holderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function _transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        uint256 currentAllowance = _allowance(holder, _msgSender());

        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked {
            _approve(holder, _msgSender(), currentAllowance - amount);
        }

        _transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice ERC20 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param amount quantity of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC20BaseStorage {
    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC20Base");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { IERC20BaseInternal } from "./IERC20BaseInternal.sol";

/**
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20Base is IERC20BaseInternal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20BaseInternal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../../common/Errors.sol";
import "../../base/ERC20BaseInternal.sol";
import "./IERC20BurnableExtension.sol";

/**
 * @title Extension of {ERC20} that allows users or approved operators to burn tokens.
 */
abstract contract ERC20BurnableExtension is IERC20BurnableExtension, ERC20BaseInternal {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Burn from another facet, allow skipping of ownership check as facets are trusted.
     */
    function burnByFacet(address account, uint256 amount) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that allows holders or approved operators to burn tokens.
 */
interface IERC20BurnableExtension {
    function burn(uint256 amount) external;

    function burnByFacet(address account, uint256 id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../base/ERC20BaseInternal.sol";
import "./IERC20MintableExtension.sol";

/**
 * @title Extension of {ERC20} that allows other facets of the diamond to mint based on arbitrary logic.
 */
abstract contract ERC20MintableExtension is IERC20MintableExtension, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20MintableExtension
     */
    function mintByFacet(address to, uint256 amount) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _mint(to, amount);
    }

    /**
     * @inheritdoc IERC20MintableExtension
     */
    function mintByFacet(address[] calldata tos, uint256[] calldata amounts) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that allows other facets from the diamond to mint tokens.
 */
interface IERC20MintableExtension {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function mintByFacet(address to, uint256 amount) external;

    function mintByFacet(address[] memory tos, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC20BaseInternal.sol";
import "./ERC20SupplyStorage.sol";
import "./ERC20SupplyInternal.sol";
import "./IERC20SupplyExtension.sol";

abstract contract ERC20SupplyExtension is IERC20SupplyExtension, ERC20BaseInternal, ERC20SupplyInternal {
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function maxSupply() external view virtual override returns (uint256) {
        return _maxSupply();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0)) {
            if (to != address(0)) {
                if (_totalSupply() + amount > ERC20SupplyStorage.layout().maxSupply) {
                    revert ErrMaxSupplyExceeded();
                }
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC20BaseInternal.sol";
import "./IERC20SupplyInternal.sol";
import "./ERC20SupplyStorage.sol";

abstract contract ERC20SupplyInternal is IERC20SupplyInternal {
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function _maxSupply() internal view returns (uint256) {
        return ERC20SupplyStorage.layout().maxSupply;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC20SupplyStorage {
    struct Layout {
        // Maximum possible supply of tokens.
        uint256 maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC20Supply");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that tracks supply and defines a max supply cap.
 */
interface IERC20SupplyExtension {
    /**
     * @dev Maximum amount of tokens possible to exist.
     */
    function maxSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20SupplyInternal {
    error ErrMaxSupplyExceeded();
}