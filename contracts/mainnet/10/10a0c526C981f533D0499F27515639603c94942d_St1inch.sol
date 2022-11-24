// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/AddressSet.sol";

import "./interfaces/IERC20Pods.sol";
import "./interfaces/IPod.sol";

abstract contract ERC20Pods is ERC20, IERC20Pods {
    using AddressSet for AddressSet.Data;
    using AddressArray for AddressArray.Data;

    error PodAlreadyAdded();
    error PodNotFound();
    error InvalidPodAddress();
    error PodsLimitReachedForAccount();
    error InsufficientGas();

    uint256 private constant _POD_CALL_GAS_LIMIT = 200_000;

    uint256 public immutable podsLimit;

    mapping(address => AddressSet.Data) private _pods;

    constructor(uint256 podsLimit_) {
        podsLimit = podsLimit_;
    }

    function hasPod(address account, address pod) public view virtual returns(bool) {
        return _pods[account].contains(pod);
    }

    function podsCount(address account) public view virtual returns(uint256) {
        return _pods[account].length();
    }

    function podAt(address account, uint256 index) public view virtual returns(address) {
        return _pods[account].at(index);
    }

    function pods(address account) public view virtual returns(address[] memory) {
        return _pods[account].items.get();
    }

    function podBalanceOf(address pod, address account) public view returns(uint256) {
        if (hasPod(account, pod)) {
            return balanceOf(account);
        }
        return 0;
    }

    function addPod(address pod) public virtual {
        _addPod(msg.sender, pod);
    }

    function removePod(address pod) public virtual {
        _removePod(msg.sender, pod);
    }

    function removeAllPods() public virtual {
        _removeAllPods(msg.sender);
    }

    function _addPod(address account, address pod) internal virtual {
        if (pod == address(0)) revert InvalidPodAddress();
        if (!_pods[account].add(pod)) revert PodAlreadyAdded();
        if (_pods[account].length() > podsLimit) revert PodsLimitReachedForAccount();

        uint256 balance = balanceOf(account);
        if (balance > 0) {
            _updateBalances(pod, address(0), account, balance);
        }
    }

    function _removePod(address account, address pod) internal virtual {
        if (!_pods[account].remove(pod)) revert PodNotFound();

        uint256 balance = balanceOf(account);
        if (balance > 0) {
            _updateBalances(pod, account, address(0), balance);
        }
    }

    function _removeAllPods(address account) internal virtual {
        address[] memory items = _pods[account].items.get();
        uint256 balance = balanceOf(account);
        unchecked {
            for (uint256 i = items.length; i > 0; i--) {
                if (balance > 0) {
                    _updateBalances(items[i - 1], account, address(0), balance);
                }
                _pods[account].remove(items[i - 1]);
            }
        }
    }

    /// @notice Assembly implementation of the gas limited call to avoid return gas bomb,
    // moreover call to a destructed pod would also revert even inside try-catch block in Solidity 0.8.17
    /// @dev try IPod(pod).updateBalances{gas: _POD_CALL_GAS_LIMIT}(from, to, amount) {} catch {}
    function _updateBalances(address pod, address from, address to, uint256 amount) private {
        bytes4 selector = IPod.updateBalances.selector;
        bytes4 exception = InsufficientGas.selector;
        assembly {  // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, selector)
            mstore(add(ptr, 0x04), from)
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), amount)

            if lt(div(mul(gas(), 63), 64), _POD_CALL_GAS_LIMIT) {
                mstore(0, exception)
                revert(0, 4)
            }
            pop(call(_POD_CALL_GAS_LIMIT, pod, 0, ptr, 0x64, 0, 0))
        }
    }

    // ERC20 Overrides

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        super._afterTokenTransfer(from, to, amount);

        unchecked {
            if (amount > 0 && from != to) {
                address[] memory a = _pods[from].items.get();
                address[] memory b = _pods[to].items.get();
                uint256 aLength = a.length;
                uint256 bLength = b.length;

                for (uint256 i = 0; i < aLength; i++) {
                    address pod = a[i];

                    uint256 j;
                    for (j = 0; j < bLength; j++) {
                        if (pod == b[j]) {
                            // Both parties are participating of the same Pod
                            _updateBalances(pod, from, to, amount);
                            b[j] = address(0);
                            break;
                        }
                    }

                    if (j == bLength) {
                        // Sender is participating in a Pod, but receiver is not
                        _updateBalances(pod, from, address(0), amount);
                    }
                }

                for (uint256 j = 0; j < bLength; j++) {
                    address pod = b[j];
                    if (pod != address(0)) {
                        // Receiver is participating in a Pod, but sender is not
                        _updateBalances(pod, address(0), to, amount);
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Pods is IERC20 {
    function hasPod(address account, address pod) external view returns(bool);
    function podsCount(address account) external view returns(uint256);
    function podAt(address account, uint256 index) external view returns(address);
    function pods(address account) external view returns(address[] memory);
    function podBalanceOf(address pod, address account) external view returns(uint256);

    function addPod(address pod) external;
    function removePod(address pod) external;
    function removeAllPods() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPod {
    function updateBalances(address from, address to, uint256 amount) external; // onlyERC20Pods
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Library that implements address array on mapping, stores array length at 0 index.
library AddressArray {
    error IndexOutOfBounds();
    error PopFromEmptyArray();
    error OutputArrayTooSmall();

    /// @dev Data struct containing raw mapping.
    struct Data {
        mapping(uint256 => uint256) _raw;
    }

    /// @dev Length of array.
    function length(Data storage self) internal view returns (uint256) {
        return self._raw[0] >> 160;
    }

    /// @dev Returns data item from `self` storage at `i`.
    function at(Data storage self, uint256 i) internal view returns (address) {
        return address(uint160(self._raw[i]));
    }

    /// @dev Returns list of addresses from storage `self`.
    function get(Data storage self) internal view returns (address[] memory arr) {
        uint256 lengthAndFirst = self._raw[0];
        arr = new address[](lengthAndFirst >> 160);
        _get(self, arr, lengthAndFirst);
    }

    /// @dev Puts list of addresses from `self` storage into `output` array.
    function get(Data storage self, address[] memory output) internal view returns (address[] memory) {
        return _get(self, output, self._raw[0]);
    }

    function _get(
        Data storage self,
        address[] memory output,
        uint256 lengthAndFirst
    ) private view returns (address[] memory) {
        uint256 len = lengthAndFirst >> 160;
        if (len > output.length) revert OutputArrayTooSmall();
        if (len > 0) {
            output[0] = address(uint160(lengthAndFirst));
            unchecked {
                for (uint256 i = 1; i < len; i++) {
                    output[i] = address(uint160(self._raw[i]));
                }
            }
        }
        return output;
    }

    /// @dev Array push back `account` operation on storage `self`.
    function push(Data storage self, address account) internal returns (uint256) {
        unchecked {
            uint256 lengthAndFirst = self._raw[0];
            uint256 len = lengthAndFirst >> 160;
            if (len == 0) {
                self._raw[0] = (1 << 160) + uint160(account);
            } else {
                self._raw[0] = lengthAndFirst + (1 << 160);
                self._raw[len] = uint160(account);
            }
            return len + 1;
        }
    }

    /// @dev Array pop back operation for storage `self`.
    function pop(Data storage self) internal {
        unchecked {
            uint256 lengthAndFirst = self._raw[0];
            uint256 len = lengthAndFirst >> 160;
            if (len == 0) revert PopFromEmptyArray();
            self._raw[len - 1] = 0;
            if (len > 1) {
                self._raw[0] = lengthAndFirst - (1 << 160);
            }
        }
    }

    /// @dev Set element for storage `self` at `index` to `account`.
    function set(
        Data storage self,
        uint256 index,
        address account
    ) internal {
        uint256 len = length(self);
        if (index >= len) revert IndexOutOfBounds();

        if (index == 0) {
            self._raw[0] = (len << 160) | uint160(account);
        } else {
            self._raw[index] = uint160(account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "./AddressArray.sol";

/** @title Library that is using AddressArray library for AddressArray.Data
 * and allows Set operations on address storage data:
 * 1. add
 * 2. remove
 * 3. contains
 */
library AddressSet {
    using AddressArray for AddressArray.Data;

    /** @dev Data struct from AddressArray.Data items
     * and lookup mapping address => index in data array.
     */
    struct Data {
        AddressArray.Data items;
        mapping(address => uint256) lookup;
    }

    /// @dev Length of data storage.
    function length(Data storage s) internal view returns (uint256) {
        return s.items.length();
    }

    /// @dev Returns data item from `s` storage at `index`.
    function at(Data storage s, uint256 index) internal view returns (address) {
        return s.items.at(index);
    }

    /// @dev Returns true if storage `s` has `item`.
    function contains(Data storage s, address item) internal view returns (bool) {
        return s.lookup[item] != 0;
    }

    /// @dev Adds `item` into storage `s` and returns true if successful.
    function add(Data storage s, address item) internal returns (bool) {
        if (s.lookup[item] > 0) {
            return false;
        }
        s.lookup[item] = s.items.push(item);
        return true;
    }

    /// @dev Removes `item` from storage `s` and returns true if successful.
    function remove(Data storage s, address item) internal returns (bool) {
        uint256 index = s.lookup[item];
        if (index == 0) {
            return false;
        }
        if (index < s.items.length()) {
            unchecked {
                address lastItem = s.items.at(s.items.length() - 1);
                s.items.set(index - 1, lastItem);
                s.lookup[lastItem] = index;
            }
        }
        s.items.pop();
        delete s.lookup[item];
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../libraries/RevertReasonForwarder.sol";

/// @title Implements efficient safe methods for ERC20 interface.
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /// @dev If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry.
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /// @dev Allowance increase with safe math check.
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /// @dev Allowance decrease with safe math check.
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /// @dev Calls either ERC20 or Dai `permit` for `token`, if unsuccessful forwards revert from external call.
    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, permit)) RevertReasonForwarder.reRevert();
    }

    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool) {
        if (permit.length == 32 * 7) {
            return _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        }
        if (permit.length == 32 * 8) {
            return _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        }
        revert SafePermitBadLength();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

pragma solidity 0.8.17;

contract VotingPowerCalculator {
    uint256 private immutable _origin;
    uint256 private immutable _expTable0;
    uint256 private immutable _expTable1;
    uint256 private immutable _expTable2;
    uint256 private immutable _expTable3;
    uint256 private immutable _expTable4;
    uint256 private immutable _expTable5;
    uint256 private immutable _expTable6;
    uint256 private immutable _expTable7;
    uint256 private immutable _expTable8;
    uint256 private immutable _expTable9;
    uint256 private immutable _expTable10;
    uint256 private immutable _expTable11;
    uint256 private immutable _expTable12;
    uint256 private immutable _expTable13;
    uint256 private immutable _expTable14;
    uint256 private immutable _expTable15;
    uint256 private immutable _expTable16;
    uint256 private immutable _expTable17;
    uint256 private immutable _expTable18;
    uint256 private immutable _expTable19;
    uint256 private immutable _expTable20;
    uint256 private immutable _expTable21;
    uint256 private immutable _expTable22;
    uint256 private immutable _expTable23;
    uint256 private immutable _expTable24;
    uint256 private immutable _expTable25;
    uint256 private immutable _expTable26;
    uint256 private immutable _expTable27;
    uint256 private immutable _expTable28;
    uint256 private immutable _expTable29;

    constructor(uint256 expBase, uint256 origin) {
        _origin = origin;
        _expTable0 = expBase;
        _expTable1 = (_expTable0 * _expTable0) / 1e18;
        _expTable2 = (_expTable1 * _expTable1) / 1e18;
        _expTable3 = (_expTable2 * _expTable2) / 1e18;
        _expTable4 = (_expTable3 * _expTable3) / 1e18;
        _expTable5 = (_expTable4 * _expTable4) / 1e18;
        _expTable6 = (_expTable5 * _expTable5) / 1e18;
        _expTable7 = (_expTable6 * _expTable6) / 1e18;
        _expTable8 = (_expTable7 * _expTable7) / 1e18;
        _expTable9 = (_expTable8 * _expTable8) / 1e18;
        _expTable10 = (_expTable9 * _expTable9) / 1e18;
        _expTable11 = (_expTable10 * _expTable10) / 1e18;
        _expTable12 = (_expTable11 * _expTable11) / 1e18;
        _expTable13 = (_expTable12 * _expTable12) / 1e18;
        _expTable14 = (_expTable13 * _expTable13) / 1e18;
        _expTable15 = (_expTable14 * _expTable14) / 1e18;
        _expTable16 = (_expTable15 * _expTable15) / 1e18;
        _expTable17 = (_expTable16 * _expTable16) / 1e18;
        _expTable18 = (_expTable17 * _expTable17) / 1e18;
        _expTable19 = (_expTable18 * _expTable18) / 1e18;
        _expTable20 = (_expTable19 * _expTable19) / 1e18;
        _expTable21 = (_expTable20 * _expTable20) / 1e18;
        _expTable22 = (_expTable21 * _expTable21) / 1e18;
        _expTable23 = (_expTable22 * _expTable22) / 1e18;
        _expTable24 = (_expTable23 * _expTable23) / 1e18;
        _expTable25 = (_expTable24 * _expTable24) / 1e18;
        _expTable26 = (_expTable25 * _expTable25) / 1e18;
        _expTable27 = (_expTable26 * _expTable26) / 1e18;
        _expTable28 = (_expTable27 * _expTable27) / 1e18;
        _expTable29 = (_expTable28 * _expTable28) / 1e18;
    }

    function _votingPowerAt(uint256 balance, uint256 timestamp) internal view returns (uint256 votingPower) {
        unchecked {
            uint256 t = timestamp - _origin;
            votingPower = balance;
            if (t & 0x01 != 0) {
                votingPower = (votingPower * _expTable0) / 1e18;
            }
            if (t & 0x02 != 0) {
                votingPower = (votingPower * _expTable1) / 1e18;
            }
            if (t & 0x04 != 0) {
                votingPower = (votingPower * _expTable2) / 1e18;
            }
            if (t & 0x08 != 0) {
                votingPower = (votingPower * _expTable3) / 1e18;
            }
            if (t & 0x10 != 0) {
                votingPower = (votingPower * _expTable4) / 1e18;
            }
            if (t & 0x20 != 0) {
                votingPower = (votingPower * _expTable5) / 1e18;
            }
            if (t & 0x40 != 0) {
                votingPower = (votingPower * _expTable6) / 1e18;
            }
            if (t & 0x80 != 0) {
                votingPower = (votingPower * _expTable7) / 1e18;
            }
            if (t & 0x100 != 0) {
                votingPower = (votingPower * _expTable8) / 1e18;
            }
            if (t & 0x200 != 0) {
                votingPower = (votingPower * _expTable9) / 1e18;
            }
            if (t & 0x400 != 0) {
                votingPower = (votingPower * _expTable10) / 1e18;
            }
            if (t & 0x800 != 0) {
                votingPower = (votingPower * _expTable11) / 1e18;
            }
            if (t & 0x1000 != 0) {
                votingPower = (votingPower * _expTable12) / 1e18;
            }
            if (t & 0x2000 != 0) {
                votingPower = (votingPower * _expTable13) / 1e18;
            }
            if (t & 0x4000 != 0) {
                votingPower = (votingPower * _expTable14) / 1e18;
            }
            if (t & 0x8000 != 0) {
                votingPower = (votingPower * _expTable15) / 1e18;
            }
            if (t & 0x10000 != 0) {
                votingPower = (votingPower * _expTable16) / 1e18;
            }
            if (t & 0x20000 != 0) {
                votingPower = (votingPower * _expTable17) / 1e18;
            }
            if (t & 0x40000 != 0) {
                votingPower = (votingPower * _expTable18) / 1e18;
            }
            if (t & 0x80000 != 0) {
                votingPower = (votingPower * _expTable19) / 1e18;
            }
            if (t & 0x100000 != 0) {
                votingPower = (votingPower * _expTable20) / 1e18;
            }
            if (t & 0x200000 != 0) {
                votingPower = (votingPower * _expTable21) / 1e18;
            }
            if (t & 0x400000 != 0) {
                votingPower = (votingPower * _expTable22) / 1e18;
            }
            if (t & 0x800000 != 0) {
                votingPower = (votingPower * _expTable23) / 1e18;
            }
            if (t & 0x1000000 != 0) {
                votingPower = (votingPower * _expTable24) / 1e18;
            }
            if (t & 0x2000000 != 0) {
                votingPower = (votingPower * _expTable25) / 1e18;
            }
            if (t & 0x4000000 != 0) {
                votingPower = (votingPower * _expTable26) / 1e18;
            }
            if (t & 0x8000000 != 0) {
                votingPower = (votingPower * _expTable27) / 1e18;
            }
            if (t & 0x10000000 != 0) {
                votingPower = (votingPower * _expTable28) / 1e18;
            }
            if (t & 0x20000000 != 0) {
                votingPower = (votingPower * _expTable29) / 1e18;
            }
        }
        return votingPower;
    }

    function _balanceAt(uint256 votingPower, uint256 timestamp) internal view returns (uint256 balance) {
        unchecked {
            uint256 t = timestamp - _origin;
            balance = votingPower;
            if (t & 0x01 != 0) {
                balance = (balance * 1e18) / _expTable0;
            }
            if (t & 0x02 != 0) {
                balance = (balance * 1e18) / _expTable1;
            }
            if (t & 0x04 != 0) {
                balance = (balance * 1e18) / _expTable2;
            }
            if (t & 0x08 != 0) {
                balance = (balance * 1e18) / _expTable3;
            }
            if (t & 0x10 != 0) {
                balance = (balance * 1e18) / _expTable4;
            }
            if (t & 0x20 != 0) {
                balance = (balance * 1e18) / _expTable5;
            }
            if (t & 0x40 != 0) {
                balance = (balance * 1e18) / _expTable6;
            }
            if (t & 0x80 != 0) {
                balance = (balance * 1e18) / _expTable7;
            }
            if (t & 0x100 != 0) {
                balance = (balance * 1e18) / _expTable8;
            }
            if (t & 0x200 != 0) {
                balance = (balance * 1e18) / _expTable9;
            }
            if (t & 0x400 != 0) {
                balance = (balance * 1e18) / _expTable10;
            }
            if (t & 0x800 != 0) {
                balance = (balance * 1e18) / _expTable11;
            }
            if (t & 0x1000 != 0) {
                balance = (balance * 1e18) / _expTable12;
            }
            if (t & 0x2000 != 0) {
                balance = (balance * 1e18) / _expTable13;
            }
            if (t & 0x4000 != 0) {
                balance = (balance * 1e18) / _expTable14;
            }
            if (t & 0x8000 != 0) {
                balance = (balance * 1e18) / _expTable15;
            }
            if (t & 0x10000 != 0) {
                balance = (balance * 1e18) / _expTable16;
            }
            if (t & 0x20000 != 0) {
                balance = (balance * 1e18) / _expTable17;
            }
            if (t & 0x40000 != 0) {
                balance = (balance * 1e18) / _expTable18;
            }
            if (t & 0x80000 != 0) {
                balance = (balance * 1e18) / _expTable19;
            }
            if (t & 0x100000 != 0) {
                balance = (balance * 1e18) / _expTable20;
            }
            if (t & 0x200000 != 0) {
                balance = (balance * 1e18) / _expTable21;
            }
            if (t & 0x400000 != 0) {
                balance = (balance * 1e18) / _expTable22;
            }
            if (t & 0x800000 != 0) {
                balance = (balance * 1e18) / _expTable23;
            }
            if (t & 0x1000000 != 0) {
                balance = (balance * 1e18) / _expTable24;
            }
            if (t & 0x2000000 != 0) {
                balance = (balance * 1e18) / _expTable25;
            }
            if (t & 0x4000000 != 0) {
                balance = (balance * 1e18) / _expTable26;
            }
            if (t & 0x8000000 != 0) {
                balance = (balance * 1e18) / _expTable27;
            }
            if (t & 0x10000000 != 0) {
                balance = (balance * 1e18) / _expTable28;
            }
            if (t & 0x20000000 != 0) {
                balance = (balance * 1e18) / _expTable29;
            }
        }
        return balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVotable is IERC20 {
    /// @dev we assume that voting power is a function of balance that preserves order
    function votingPowerOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/erc20-pods/contracts/ERC20Pods.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "./helpers/VotingPowerCalculator.sol";
import "./interfaces/IVotable.sol";

contract St1inch is ERC20Pods, Ownable, VotingPowerCalculator, IVotable {
    using SafeERC20 for IERC20;

    event EmergencyExitSet(bool status);

    error ApproveDisabled();
    error TransferDisabled();
    error LockTimeMoreMaxLock();
    error LockTimeLessMinLock();
    error UnlockTimeHasNotCome();

    uint256 public constant MIN_LOCK_PERIOD = 1 days;
    uint256 public constant MAX_LOCK_PERIOD = 4 * 365 days;
    uint256 private constant _VOTING_POWER_DIVIDER = 10;

    IERC20 public immutable oneInch;

    mapping(address => uint256) private _unlockTime;
    mapping(address => uint256) private _deposits;

    uint256 public totalDeposits;
    bool public emergencyExit;
    uint256 public immutable expBase;
    // solhint-disable-next-line not-rely-on-time
    uint256 public immutable origin = block.timestamp;

    constructor(
        IERC20 _oneInch,
        uint256 _expBase,
        uint256 podsLimit
    )
        ERC20Pods(podsLimit)
        ERC20("Staking 1inch", "st1inch")
        VotingPowerCalculator(_expBase, origin)
    {
        oneInch = _oneInch;
        expBase = _expBase;
    }

    function setEmergencyExit(bool _emergencyExit) external onlyOwner {
        emergencyExit = _emergencyExit;
        emit EmergencyExitSet(_emergencyExit);
    }

    function depositsAmount(address account) external view returns (uint256) {
        return _deposits[account];
    }

    function unlockTime(address account) external view returns (uint256) {
        return _unlockTime[account];
    }

    function votingPowerOf(address account) external view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return _votingPowerAt(balanceOf(account), block.timestamp);
    }

    function votingPowerOfAt(address account, uint256 timestamp) external view returns (uint256) {
        return _votingPowerAt(balanceOf(account), timestamp);
    }

    function votingPower(uint256 balance) external view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return _votingPowerAt(balance, block.timestamp);
    }

    function votingPowerAt(uint256 balance, uint256 timestamp) external view returns (uint256) {
        return _votingPowerAt(balance, timestamp);
    }

    function deposit(uint256 amount, uint256 duration) external {
        _deposit(msg.sender, amount, duration);
    }

    function depositWithPermit(
        uint256 amount,
        uint256 duration,
        bytes calldata permit
    ) external {
        oneInch.safePermit(permit);
        _deposit(msg.sender, amount, duration);
    }

    function depositFor(
        address account,
        uint256 amount
    ) external {
        _deposit(account, amount, 0);
    }

    function depositForWithPermit(
        address account,
        uint256 amount,
        bytes calldata permit
    ) external {
        oneInch.safePermit(permit);
        _deposit(account, amount, 0);
    }

    function increaseLockDuration(uint256 duration) external {
        _deposit(msg.sender, 0, duration);
    }

    function increaseAmount(uint256 amount) external {
        _deposit(msg.sender, amount, 0);
    }

    /* solhint-disable not-rely-on-time */
    function _deposit(
        address account,
        uint256 amount,
        uint256 duration
    ) private {
        if (amount > 0) {
            oneInch.safeTransferFrom(msg.sender, address(this), amount);
            _deposits[account] += amount;
            totalDeposits += amount;
        }

        uint256 lockedTill = Math.max(_unlockTime[account], block.timestamp) + duration;
        uint256 lockedPeriod = lockedTill - block.timestamp;
        if (lockedPeriod < MIN_LOCK_PERIOD) revert LockTimeLessMinLock();
        if (lockedPeriod > MAX_LOCK_PERIOD) revert LockTimeMoreMaxLock();
        _unlockTime[account] = lockedTill;

        _mint(account, _balanceAt(_deposits[account], lockedTill) / _VOTING_POWER_DIVIDER - balanceOf(account));
    }

    /* solhint-enable not-rely-on-time */

    function withdraw() external {
        withdrawTo(msg.sender);
    }

    function withdrawTo(address to) public {
        // solhint-disable-next-line not-rely-on-time
        if (!emergencyExit && block.timestamp < _unlockTime[msg.sender]) revert UnlockTimeHasNotCome();

        uint256 balance = _deposits[msg.sender];
        totalDeposits -= balance;
        _deposits[msg.sender] = 0;
        _burn(msg.sender, balanceOf(msg.sender));

        oneInch.safeTransfer(to, balance);
    }

    // ERC20 methods disablers

    function approve(address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert ApproveDisabled();
    }

    function transfer(address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function transferFrom(address, address, uint256) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function increaseAllowance(address, uint256) public pure override returns (bool) {
        revert ApproveDisabled();
    }

    function decreaseAllowance(address, uint256) public pure override returns (bool) {
        revert ApproveDisabled();
    }
}