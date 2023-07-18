// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity 0.8.15;

import {EIP712Decoder, Delegation, SignedDelegation, Caveat} from "./TypesAndDecoders.sol";

import {CaveatEnforcer, Intent} from "./CaveatEnforcer.sol";

/**
 * @title CanDelegate
 * @notice A Delegatable contract will use this contract as it is core to walking and validating the delegation chain.
 */
abstract contract CanDelegate is EIP712Decoder {
    /**
     * This function checks the delegation chain of the sender to see if they have the right to perform the intent on behalf of another.
     * The delegator is implied by the signer of the first delegation, which should have an `authority` of 0x0.
     * The resulting
     * Can be read as `requestingSender` wants to perform `transactionIntent` on behalf of `rootAuthority`, given the `signedDelegationChain`.
     * This function is entrusted to tell the caller whether or not the delegation chain is valid for that given context.
     * The caller MUST have performed the authentication check to ensure that the requestingSender signed the intent in some form.
     * The caller may then behave as if `rootAuthority` authorized the intent.
     * The caller MUST validate the delegations array is not empty before calling this function.
     * The calling function MUST allow root owners to invoke methods directly without calling this method.
     * This function will throw if the delegation chain is invalid or does not culminate in the requestingSender having the right to perform the intent.
     * @param _delegations - The list of delegations that may grant the sender the right to this intent.
     * @param _intent - The intent the sender is requesting to perform. A minimal subset of a transaction or UserOperation.
     * @return rootAuthority The root authority of the delegation
     * @return approvedDelegate The approved delegate from the delegation chain
     */
    function _checkDelegation(
        SignedDelegation[] memory _delegations,
        Intent memory _intent
    ) internal returns (address rootAuthority, address approvedDelegate) {
        bytes32 authHash_ = 0x0;

        uint256 delegationLength_ = _delegations.length;
        for (uint256 d = 0; d < delegationLength_; d++) {
            SignedDelegation memory signedDelegation_ = _delegations[d];
            address delegationSigner_ = verifySignedDelegation(
                signedDelegation_
            );
            Delegation memory delegation_ = signedDelegation_.message;
            if (d == 0) {
                require(
                    delegation_.authority == 0x0,
                    "CanDelegate:invalid-root-authority"
                );
                // Implied sending account is the signer of the first delegation
                rootAuthority = delegationSigner_;
                approvedDelegate = delegationSigner_;
            }

            require(
                delegationSigner_ == approvedDelegate,
                "CanDelegate:invalid-delegation-signer"
            );

            require(
                delegation_.authority == authHash_,
                "CanDelegate:invalid-authority-delegation-link"
            );

            bytes32 delegationHash_ = getSigneddelegationPacketHash(
                signedDelegation_
            );

            _processCaveatsBefore(
                delegation_.caveats,
                _intent,
                delegationHash_
            );

            authHash_ = delegationHash_;
            approvedDelegate = delegation_.delegate;
        }
        return (rootAuthority, approvedDelegate);
    }

    /**
     * @notice Processes caveats before execution of an intent
     * @param _caveats The array of caveats to process
     * @param _intent The intent to be executed
     * @param _delegationHash The hash of the signed delegation
     */
    function _processCaveatsBefore(
        Caveat[] memory _caveats,
        Intent memory _intent,
        bytes32 _delegationHash
    ) internal {
        uint256 caveatsLength_ = _caveats.length;
        for (uint16 y = 0; y < caveatsLength_; y++) {
            CaveatEnforcer enforcer_ = CaveatEnforcer(_caveats[y].enforcer);
            bool caveatSuccess_ = enforcer_.enforceBefore(
                _caveats[y].terms,
                _intent,
                _delegationHash
            );
            require(caveatSuccess_, "CanDelegate:caveat-rejected");
        }
    }

    /**
     * @notice Performs checks after a transaction batch execution
     * @param _delegations The array of delegations used in the transaction batch
     * @param _intent The intent that was executed
     */
    function _checkPostOp(
        SignedDelegation[] calldata _delegations,
        Intent memory _intent
    ) internal {
        // if this gets called the trx batch must have been successful
        uint256 delegationsLength_ = _delegations.length;
        for (uint256 d = 0; d < delegationsLength_; d++) {
            bytes32 delegationHash_ = getSigneddelegationPacketHash(
                _delegations[d]
            );

            _processCaveatsAfter(
                _delegations[d].message.caveats,
                _intent,
                delegationHash_
            );
        }
    }

    /**
     * @notice Processes caveats after execution of an intent
     * @param _caveats The array of caveats to process
     * @param _intent The executed intent
     * @param _delegationHash The hash of the signed delegation
     */
    function _processCaveatsAfter(
        Caveat[] calldata _caveats,
        Intent memory _intent,
        bytes32 _delegationHash
    ) private {
        uint256 caveatsLength_ = _caveats.length;
        for (uint16 y = 0; y < caveatsLength_; y++) {
            CaveatEnforcer enforcer_ = CaveatEnforcer(_caveats[y].enforcer);
            bool cleanUpSuccess_ = enforcer_.enforceAfter(
                _caveats[y].terms,
                _intent,
                _delegationHash
            );
            require(cleanUpSuccess_, "CanDelegate:post-op-caveat-rejected");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Intent
 * @notice This struct represents the intent of a transaction.
 * @dev It is used to pass the intent of a transaction to a CaveatEnforcer.
 * It only includes the functional part of a transaction, allowing it to be
 * agnostic whether this was sent from a protocol-level tx or UserOperation.
 */
struct Intent {
    address to;
    uint256 value;
    bytes data;
}

/**
 * @title CaveatEnforcer
 * @notice This is an abstract contract that enforces custom pre and post-conditions for transactions.
 * @dev Child contracts can implement the enforceBefore method and/or enforceAfter method, both are optional.
 */
abstract contract CaveatEnforcer {
    /**
     * @notice Enforces the conditions that should hold before a transaction is performed.
     * @param terms The terms to enforce.
     * @param intent The intent of the transaction.
     * @param delegationHash The hash of the delegation.
     * @return A boolean indicating whether the conditions hold.
     */
    function enforceBefore(
        bytes calldata terms,
        Intent calldata intent,
        bytes32 delegationHash
    ) public virtual returns (bool) {
        return true;
    }

    /**
     * @notice Enforces the conditions that should hold after a transaction is performed.
     * @param terms The terms to enforce.
     * @param intent The intent of the transaction.
     * @param delegationHash The hash of the delegation.
     * @return A boolean indicating whether the conditions hold.
     */
    function enforceAfter(
        bytes calldata terms,
        Intent calldata intent,
        bytes32 delegationHash
    ) public virtual returns (bool) {
        return true;
    }

    /**
     * @notice Computes a hash from an intent and a delegation hash.
     * @param intent The intent of the transaction.
     * @param delegationHash The hash of the delegation.
     * @return The hash.
     */
    function caveatHash(Intent calldata intent, bytes32 delegationHash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(intent, delegationHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {eip712domainTypehash, EIP712Decoder, Delegation, Invocation, Batch, SignedBatch, Transaction, ReplayProtection} from "./TypesAndDecoders.sol";
import {CaveatEnforcer, Intent} from "./CaveatEnforcer.sol";
import {DelegatableCore} from "./DelegatableCore.sol";
import {IDelegatable} from "./interfaces/IDelegatable.sol";

abstract contract Delegatable is IDelegatable, DelegatableCore {
    /// @notice The hash of the domain separator used in the EIP712 domain hash.
    bytes32 public immutable domainHash;

    /**
     * @notice Delegatable Constructor
     * @param contractName string - The name of the contract
     * @param version string - The version of the contract
     */
    constructor(string memory contractName, string memory version) {
        domainHash = getEIP712DomainHash(
            contractName,
            version,
            block.chainid,
            address(this)
        );
    }

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) public view returns (bytes32) {
        bytes memory encoded = abi.encode(
            eip712domainTypehash,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        );
        return keccak256(encoded);
    }

    function getDomainHash() public view override returns (bytes32) {
        return domainHash;
    }

    // --------------------------------------
    // WRITES
    // --------------------------------------

    /// @inheritdoc IDelegatable
    function contractInvoke(Invocation[] calldata batch)
        external
        override
        returns (bool)
    {
        return _invoke(batch, msg.sender);
    }

    /// @inheritdoc IDelegatable
    function invoke(SignedBatch calldata signedBatch)
        external
        override
        returns (bool success)
    {
        address batchSigner = verifySignedBatch(signedBatch);
        Batch calldata batch = signedBatch.message;
        _enforceReplayProtection(batchSigner, batch.replayProtection);
        success = _invoke(batch.invocations, batchSigner);
    }

    /* ===================================================================================== */
    /* Internal Functions                                                                    */
    /* ===================================================================================== */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EIP712Decoder, Delegation, Invocation, SignedDelegation, Transaction, ReplayProtection} from "./TypesAndDecoders.sol";
import {CaveatEnforcer, Intent} from "./CaveatEnforcer.sol";
import {CanDelegate} from "./CanDelegate.sol";

abstract contract DelegatableCore is EIP712Decoder, CanDelegate {
    /// @notice Account delegation nonce manager
    mapping(address => mapping(uint256 => uint256)) internal multiNonce;

    function getNonce(address intendedSender, uint256 queue)
        external
        view
        returns (uint256)
    {
        return multiNonce[intendedSender][queue];
    }

    function _enforceReplayProtection(
        address intendedSender,
        ReplayProtection memory protection
    ) internal {
        uint256 queue = protection.queue;
        uint256 nonce = protection.nonce;
        require(
            nonce == (multiNonce[intendedSender][queue] + 1),
            "DelegatableCore:nonce2-out-of-order"
        );
        multiNonce[intendedSender][queue] = nonce;
    }

    function _execute(
        address to,
        bytes memory data,
        uint256 gasLimit,
        address sender
    ) internal returns (bool success) {
        bytes memory full = abi.encodePacked(data, sender);
        bytes memory errorMessage;
        (success, errorMessage) = address(to).call{gas: gasLimit}(full);

        if (!success) {
            if (errorMessage.length > 0) {
                string memory reason = extractRevertReason(errorMessage);
                revert(reason);
            } else {
                revert("DelegatableCore::execution-failed");
            }
        }
    }

    function extractRevertReason(bytes memory revertData)
        internal
        pure
        returns (string memory reason)
    {
        uint256 length_ = revertData.length;
        if (length_ < 68) return "";
        uint256 t;
        assembly {
            revertData := add(revertData, 4)
            t := mload(revertData) // Save the content of the length slot
            mstore(revertData, sub(length_, 4)) // Set proper length
        }
        reason = abi.decode(revertData, (string));
        assembly {
            mstore(revertData, t) // Restore the content of the length slot
        }
    }

    function _invoke(Invocation[] calldata invocations, address sender)
        internal
        returns (bool success)
    {
        uint256 invocationsLength_ = invocations.length;
        for (uint256 x = 0; x < invocationsLength_; x++) {
            Invocation calldata invocation = invocations[x];

            Intent memory intent = Intent({
                to: invocation.transaction.to,
                data: invocation.transaction.data,
                value: invocation.transaction.value
            });

            address rootAuthority = sender;
            address approvedDelegate = sender;

            if (invocation.authority.length > 0) {
                (rootAuthority, approvedDelegate) = _checkDelegation(
                    invocation.authority,
                    intent
                );
            }

            require(
                approvedDelegate == sender,
                "DelegatableCore:invalid-delegate"
            );

            // Here we perform the requested invocation.
            Transaction memory transaction = invocation.transaction;

            require(
                transaction.to == address(this),
                "DelegatableCore:invalid-invocation-target"
            );

            success = _execute(
                transaction.to,
                transaction.data,
                transaction.gasLimit,
                rootAuthority
            );
            require(success, "DelegatableCore::execution-failed");
        }

        // if we get here then all calls were successful, call post op clean up on caveats
        for (uint256 i = 0; i < invocationsLength_; i++) {
            // grab invocation
            Invocation calldata invocation_ = invocations[i];
            // build Intent
            Intent memory intent_ = Intent({
                to: invocation_.transaction.to,
                data: invocation_.transaction.data,
                value: invocation_.transaction.value
            });
            _checkPostOp(invocation_.authority, intent_);
        }

        // if we get here then all post op caveats were successful
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

struct SignedDelegation {
    Delegation message;
    bytes signature;
    address signer;
}

bytes32 constant signeddelegationTypehash = keccak256(
    "SignedDelegation(Delegation message,bytes signature,address signer)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats,uint256 salt)"
);

struct SignedBatch {
    Batch message;
    bytes signature;
    address signer;
}

bytes32 constant signedbatchTypehash = keccak256(
    "SignedBatch(Batch message,bytes signature,address signer)Batch(Invocation[] invocations,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats,uint256 salt)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation message,bytes signature,address signer)Transaction(address to,uint256 gasLimit,uint256 value,bytes data)"
);

struct SignedMultisigParams {
    MultisigParams message;
    bytes signature;
    address signer;
}

bytes32 constant signedmultisigparamsTypehash = keccak256(
    "SignedMultisigParams(MultisigParams message,bytes signature,address signer)MultisigParams(address[] signers,uint256 threshold)"
);

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

bytes32 constant eip712domainTypehash = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Delegation {
    address delegate;
    bytes32 authority;
    Caveat[] caveats;
    uint256 salt;
}

bytes32 constant delegationTypehash = keccak256(
    "Delegation(address delegate,bytes32 authority,Caveat[] caveats,uint256 salt)Caveat(address enforcer,bytes terms)"
);

struct Caveat {
    address enforcer;
    bytes terms;
}

bytes32 constant caveatTypehash = keccak256(
    "Caveat(address enforcer,bytes terms)"
);

struct MultisigParams {
    address[] signers;
    uint256 threshold;
}

bytes32 constant multisigparamsTypehash = keccak256(
    "MultisigParams(address[] signers,uint256 threshold)"
);

struct Transaction {
    address to;
    uint256 gasLimit;
    uint256 value;
    bytes data;
}

bytes32 constant transactionTypehash = keccak256(
    "Transaction(address to,uint256 gasLimit,uint256 value,bytes data)"
);

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

bytes32 constant replayprotectionTypehash = keccak256(
    "ReplayProtection(uint nonce,uint queue)"
);

struct Invocation {
    Transaction transaction;
    SignedDelegation[] authority;
}

bytes32 constant invocationTypehash = keccak256(
    "Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats,uint256 salt)SignedDelegation(Delegation message,bytes signature,address signer)Transaction(address to,uint256 gasLimit,uint256 value,bytes data)"
);

struct Batch {
    Invocation[] invocations;
    ReplayProtection replayProtection;
}

bytes32 constant batchTypehash = keccak256(
    "Batch(Invocation[] invocations,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats,uint256 salt)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation message,bytes signature,address signer)Transaction(address to,uint256 gasLimit,uint256 value,bytes data)"
);

abstract contract ERC1271Contract {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _hash
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        virtual
        returns (bytes4 magicValue);
}

abstract contract EIP712Decoder {
    function getDomainHash() public view virtual returns (bytes32);

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function getSigneddelegationPacketHash(SignedDelegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            signeddelegationTypehash,
            getDelegationPacketHash(_input.message),
            keccak256(_input.signature),
            _input.signer
        );
        return keccak256(encoded);
    }

    function getSignedbatchPacketHash(SignedBatch memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            signedbatchTypehash,
            getBatchPacketHash(_input.message),
            keccak256(_input.signature),
            _input.signer
        );
        return keccak256(encoded);
    }

    function getSignedmultisigparamsPacketHash(
        SignedMultisigParams memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            signedmultisigparamsTypehash,
            getMultisigparamsPacketHash(_input.message),
            keccak256(_input.signature),
            _input.signer
        );
        return keccak256(encoded);
    }

    function getEip712DomainPacketHash(EIP712Domain memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            eip712domainTypehash,
            keccak256(bytes(_input.name)),
            keccak256(bytes(_input.version)),
            _input.chainId,
            _input.verifyingContract
        );
        return keccak256(encoded);
    }

    function getDelegationPacketHash(Delegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            delegationTypehash,
            _input.delegate,
            _input.authority,
            getCaveatArrayPacketHash(_input.caveats),
            _input.salt
        );
        return keccak256(encoded);
    }

    function getCaveatArrayPacketHash(Caveat[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        // HELLO
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = abi.encodePacked(encoded, getCaveatPacketHash(_input[i]));
        }
        return keccak256(encoded);
    }

    function getCaveatPacketHash(Caveat memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            caveatTypehash,
            _input.enforcer,
            keccak256(_input.terms)
        );
        return keccak256(encoded);
    }

    function getAddressArrayPacketHash(address[] memory _input)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_input));
    }

    function getMultisigparamsPacketHash(MultisigParams memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            multisigparamsTypehash,
            getAddressArrayPacketHash(_input.signers),
            _input.threshold
        );
        return keccak256(encoded);
    }

    function getTransactionPacketHash(Transaction memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            transactionTypehash,
            _input.to,
            _input.gasLimit,
            _input.value,
            keccak256(_input.data)
        );
        return keccak256(encoded);
    }

    function getReplayprotectionPacketHash(ReplayProtection memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            replayprotectionTypehash,
            _input.nonce,
            _input.queue
        );
        return keccak256(encoded);
    }

    function getInvocationPacketHash(Invocation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            invocationTypehash,
            getTransactionPacketHash(_input.transaction),
            getSigneddelegationArrayPacketHash(_input.authority)
        );
        return keccak256(encoded);
    }

    function getSigneddelegationArrayPacketHash(
        SignedDelegation[] memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                getSigneddelegationPacketHash(_input[i])
            );
        }
        return keccak256(encoded);
    }

    function getInvocationArrayPacketHash(Invocation[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = abi.encodePacked(
                encoded,
                getInvocationPacketHash(_input[i])
            );
        }
        return keccak256(encoded);
    }

    function getBatchPacketHash(Batch memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            batchTypehash,
            getInvocationArrayPacketHash(_input.invocations),
            getReplayprotectionPacketHash(_input.replayProtection)
        );
        return keccak256(encoded);
    }

    function verifySignedDelegation(SignedDelegation memory _input)
        public
        view
        returns (address)
    {
        bytes32 packetHash = getDelegationPacketHash(_input.message);
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", getDomainHash(), packetHash)
        );

        if (_input.signer == 0x0000000000000000000000000000000000000000) {
            address recoveredSigner = recover(digest, _input.signature);
            return recoveredSigner;
        } else {
            // EIP-1271 signature verification
            bytes4 result = ERC1271Contract(_input.signer).isValidSignature(
                digest,
                _input.signature
            );
            require(result == 0x1626ba7e, "INVALID_SIGNATURE");
            return _input.signer;
        }
    }

    function verifySignedBatch(SignedBatch memory _input)
        public
        view
        returns (address)
    {
        bytes32 packetHash = getBatchPacketHash(_input.message);
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", getDomainHash(), packetHash)
        );

        if (_input.signer == 0x0000000000000000000000000000000000000000) {
            address recoveredSigner = recover(digest, _input.signature);
            return recoveredSigner;
        } else {
            // EIP-1271 signature verification
            bytes4 result = ERC1271Contract(_input.signer).isValidSignature(
                digest,
                _input.signature
            );
            require(result == 0x1626ba7e, "INVALID_SIGNATURE");
            return _input.signer;
        }
    }

    function verifySignedMultisigParams(SignedMultisigParams memory _input)
        public
        view
        returns (address)
    {
        bytes32 packetHash = getMultisigparamsPacketHash(_input.message);
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", getDomainHash(), packetHash)
        );

        if (_input.signer == 0x0000000000000000000000000000000000000000) {
            address recoveredSigner = recover(digest, _input.signature);
            return recoveredSigner;
        } else {
            // EIP-1271 signature verification
            bytes4 result = ERC1271Contract(_input.signer).isValidSignature(
                digest,
                _input.signature
            );
            require(result == 0x1626ba7e, "INVALID_SIGNATURE");
            return _input.signer;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Delegatable.sol";

contract ERC20Delegatable is ERC20, Delegatable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 amount
    ) Delegatable(name, "1") ERC20(name, symbol) {
        _mint(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _msgSender()
        internal
        view
        override(DelegatableCore, Context)
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Invocation, SignedBatch} from "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Allows a smart contract to submit a batch of invocations for processing, allowing itself to be the delegate.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Allows anyone to submit a batch of signed invocations for processing.
     * @param signedBatch SignedBatch - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedBatch calldata signedBatch)
        external
        returns (bool success);
}