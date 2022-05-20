// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './Billing.sol';
import '../interfaces/IFundWallet.sol';
import '../access/OwnerWithdrawable.sol';
import '../access/Pauser.sol';

/// @author Alexandas
/// @dev FundWallet contract
contract FundWallet is IFundWallet, Billing, OwnerWithdrawable, Pauser, ReentrancyGuardUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	/// @dev keccak256("Recharge(address provider,uint64 nonce,bytes32 account,uint256 amount)")
	bytes32 public override rechargeTypedHash;

	/// @dev provider nonces for account
	mapping(address => mapping(bytes32 => mapping(uint64 => Purpose))) public nonces;

	/// @dev account wallet
	mapping(address => mapping(bytes32 => Wallet)) internal wallets;

	modifier onlyWalletOwner(address provider, bytes32 account) {
		require(wallets[provider][account].owner == msg.sender, 'FundWallet: caller is not wallet owner');
		_;
	}

	modifier nonNonce(
		address provider,
		bytes32 account,
		uint64 nonce
	) {
		require(nonces[provider][account][nonce] == Purpose.Null, 'FundWallet: invalid nonce');
		_;
	}

	constructor() initializer {}

	/// @dev proxy initialize function
	/// @param owner contract owner
	/// @param pauser contract pauser
	/// @param adaptor resource adaptor contract address
	/// @param _providers providers contract address
	/// @param _token token address
	/// @param name EIP712 domain name
	/// @param version EIP712 domain version
	/// @param rechargeTypes recharge types
	/// @param billsTypes bills types
	function initialize(
		address owner,
		address pauser,
		IResourceAdaptor adaptor,
		IProviders _providers,
		IERC20Upgradeable _token,
		string memory name,
		string memory version,
		string memory rechargeTypes,
		string memory billsTypes
	) external initializer {
		_transferOwnership(owner);
		__Init_Pauser(pauser);
		__Init_Providers(_providers);
		__Init_Resource_Adaptor(adaptor);
		__Init_Token(_token);
		__EIP712_init(name, version);
		__Init_Recharge_Typed_Hash(rechargeTypes);
		__Init_Bills_Typed_Hash(billsTypes);
	}

	/// @dev initialize recharge typed hash
	/// @param types recharge types
	function __Init_Recharge_Typed_Hash(string memory types) internal onlyInitializing {
		_setRechargeTypedHash(keccak256(bytes(types)));
	}

	/// @dev recharge for account
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param amount token amount
	/// @param signature provider signature
	function recharge(
		address provider,
		uint64 nonce,
		bytes32 account,
		uint256 amount,
		bytes memory signature
	) external override nonNonce(provider, account, nonce) whenNotPaused nonReentrant {
		if (ownerOf(provider, account) != address(0)) {
			require(ownerOf(provider, account) == msg.sender, 'FundWallet: caller is not the wallet owner');
		} else {
			_setWalletOwner(provider, account, msg.sender);
		}
		_recharge(provider, nonce, account, amount, signature);
	}

	function _recharge(
		address provider,
		uint64 nonce,
		bytes32 account,
		uint256 amount,
		bytes memory signature
	) internal {
		require(amount > 0, 'FundWallet: zero amount');
		bytes32 hash = hashTypedDataV4ForRecharge(provider, nonce, account, amount);
		require(providers.isValidSignature(provider, hash, signature), 'FundWallet: invalid signature');
		wallets[provider][account].amount = wallets[provider][account].amount.add(amount);
		token.safeTransferFrom(msg.sender, address(this), amount);
		_updateNonce(provider, account, nonce, Purpose.Recharge);

		emit Recharged(provider, nonce, account, amount);
	}

	/// @dev spend bills for account
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param bills bills bytes
	/// @param expiration tx expiration
	/// @param signature provider signature
	/// @param fee bills fee
	function spend(
		address provider,
		uint64 nonce,
		bytes32 account,
		bytes memory bills,
		uint256 expiration,
		bytes memory signature
	) external override nonNonce(provider, account, nonce) whenNotPaused nonReentrant returns (uint256 fee) {
		fee = _spend(Payload(provider, nonce, account, bills, expiration), signature);
		wallets[provider][account].amount = wallets[provider][account].amount.sub(fee);
		_updateNonce(provider, account, nonce, Purpose.Spend);
	}

	/// @dev withdraw token for account
	/// @param payload bill payload
	/// @param to token receiver
	/// @param amount token amount
	/// @param signature provider signature
	/// @return fee bill fee
	function withdraw(
		Payload memory payload,
		address to,
		uint256 amount,
		bytes memory signature
	) external override nonNonce(payload.provider, payload.account, payload.nonce) onlyWalletOwner(payload.provider, payload.account) whenNotPaused nonReentrant returns (uint256 fee) {
		fee = _spend(payload, signature);
		address provider = payload.provider;
		bytes32 account = payload.account;
		uint64 nonce = payload.nonce;
		uint256 left = wallets[provider][account].amount.sub(fee);
		address receiver = to;
		uint256 value = amount;
		require(left >= value, 'FundWallet: insufficient balance');
		wallets[provider][account].amount = left.sub(value);
		token.safeTransfer(receiver, value);
		_updateNonce(provider, account, nonce, Purpose.Withdraw);

		emit Withdrawn(provider, nonce, account, receiver, value);
	}

	/// @dev transfer wallet owner for account
	/// @param provider provider address
	/// @param account user account
	/// @param newOwner new wallet owner for account
	function transferWalletOwner(
		address provider,
		bytes32 account,
		address newOwner
	) external override whenNotPaused onlyWalletOwner(provider, account) {
		require(ownerOf(provider, account) != address(0), 'FundWallet: nonexistent wallet owner');
		require(newOwner != address(0), 'FundWallet: zero address');
		_setWalletOwner(provider, account, newOwner);
	}

	function _setWalletOwner(
		address provider,
		bytes32 account,
		address owner
	) internal {
		wallets[provider][account].owner = owner;
		emit WalletOwnerTransferred(provider, account, owner);
	}

	/// @dev return owner of account
	/// @param provider provider address
	/// @param account user account
	/// @return owner wallet owner for account
	function ownerOf(address provider, bytes32 account) public view override returns (address) {
		return wallets[provider][account].owner;
	}

	/// @dev return balance of account
	/// @param provider provider address
	/// @param account user account
	/// @return balance of account account
	function balanceOf(address provider, bytes32 account) public view override returns (uint256) {
		return wallets[provider][account].amount;
	}

	/// @dev update recharge typed hash
	/// @param types recharge types
	function setRechargeTypedHash(string memory types) external onlyOwner {
		_setRechargeTypedHash(keccak256(bytes(types)));
	}

	/// @dev update bills typed hash
	/// @param types bills types
	function setBillsTypedHash(string memory types) external onlyOwner {
		_setBillsTypedHash(keccak256(bytes(types)));
	}

	/// @dev update token
	/// @param _token token address
	function setToken(IERC20Upgradeable _token) external onlyOwner {
		_setToken(_token);
	}

	/// @dev return recharge typed hash
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param amount token amount
	/// @return recharge typed hash
	function rechargeHash(
		address provider,
		uint64 nonce,
		bytes32 account,
		uint256 amount
	) public view returns (bytes32) {
		return keccak256(abi.encode(rechargeTypedHash, provider, nonce, account, amount));
	}

	/// @dev return recharge hash typed v4
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param amount token amount
	/// @return recharge hash typed v4
	function hashTypedDataV4ForRecharge(
		address provider,
		uint64 nonce,
		bytes32 account,
		uint256 amount
	) public view returns (bytes32) {
		return _hashTypedDataV4(rechargeHash(provider, nonce, account, amount));
	}

	function _setRechargeTypedHash(bytes32 hash) internal {
		rechargeTypedHash = hash;
		emit RechargeTypedHashUpdated(hash);
	}

	function _updateNonce(
		address provider,
		bytes32 account,
		uint64 nonce,
		Purpose purpose
	) internal {
		nonces[provider][account][nonce] = purpose;
		emit NonceUpdated(provider, account, nonce, purpose);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol';

import '../providers/ProvidersWrapper.sol';
import '../interfaces/IBilling.sol';
import '../resources/interfaces/IResourceAdaptor.sol';
import '../payment/ResourcePayTokenWrapper.sol';

/// @author Alexandas
/// @dev Billing contract
abstract contract Billing is IBilling, ResourcePayTokenWrapper, ProvidersWrapper, EIP712Upgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	struct SpendPayload {
		address provider;
		uint64 nonce;
		bytes32 account;
		bytes bill;
		bytes signature;
	}

	/// @dev keccak256("Bills(address provider,uint64 nonce,bytes32 account,bytes bills,uint256 expiration)")
	bytes32 public override billsTypedHash;

	/// @dev resource adaptor contract address
	IResourceAdaptor public override adaptor;

	/// @dev initialize bills type hash
	/// @param types bills types
	function __Init_Bills_Typed_Hash(string memory types) internal onlyInitializing {
		_setBillsTypedHash(keccak256(bytes(types)));
	}

	/// @dev initialize resource adaptor
	/// @param _adaptor resource adaptor contract address
	function __Init_Resource_Adaptor(IResourceAdaptor _adaptor) internal onlyInitializing {
		_setResourceAdaptor(_adaptor);
	}

	/// @dev return hash for bills
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param bills user bills
	/// @param expiration bills expiration
	/// @return bills hash
	function billsHash(
		address provider,
		uint64 nonce,
		bytes32 account,
		bytes memory bills,
		uint256 expiration
	) public view returns (bytes32) {
		return keccak256(abi.encode(billsTypedHash, provider, nonce, account, keccak256(bills), expiration));
	}

	/// @dev return hash typed v4 for sign
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param bills user bills
	/// @return bills hash typed v4
	function hashTypedDataV4ForBills(
		address provider,
		uint64 nonce,
		bytes32 account,
		bytes memory bills,
		uint256 expiration
	) public view returns (bytes32) {
		return _hashTypedDataV4(billsHash(provider, nonce, account, bills, expiration));
	}

	/// @dev encode bill to bytes
	/// @param bills user bills
	/// @return bills bytes
	function encodeBills(Bill[] memory bills) external pure returns (bytes memory) {
		return abi.encode(bills);
	}

	/// @dev decode bill bytes to user bill
	/// @param data bill bytes
	/// @return user bills
	function decodeBills(bytes memory data) external pure returns (Bill[] memory) {
		return abi.decode(data, (Bill[]));
	}

	function _setResourceAdaptor(IResourceAdaptor _adaptor) internal {
		require(address(_adaptor) != address(0), 'Billing: zero address');
		adaptor = _adaptor;
		emit ResourceAdaptorUpdated(_adaptor);
	}

	function _validateBills(bytes memory data) internal view returns (uint256 value) {
		Bill[] memory bills = abi.decode(data, (Bill[]));
		require(bills.length > 0, 'Billing: empty bill payloads');
		for (uint256 i = 0; i < bills.length; i++) {
			Bill memory bill = bills[i];
			require(bill.entries.length > 0, 'Billing: empty bill entry');
			for (uint256 j = 0; j < bill.entries.length; j++) {
				BillEntry memory entry = bill.entries[i];
				uint256 billing = adaptor.getValueAt(entry.resourceType, entry.amount, bill.indexBlock);
				value = value.add(billing);
			}
		}
	}

	function _spend(
		Payload memory payload,
		bytes memory signature
	) internal returns (uint256 amount) {
		require(payload.expiration > block.timestamp, 'Billing: tx expired');
		require(providers.isProvider(msg.sender), 'Billing: caller is not a provider');
		bytes32 hash = hashTypedDataV4ForBills(payload.provider, payload.nonce, payload.account, payload.bills, payload.expiration);
		require(providers.isValidSignature(payload.provider, hash, signature), 'Billing: invalid signature');
		if (payload.bills.length > 0) {
			uint256 balance = balanceOf(payload.provider, payload.account);
			amount = matchResourceToToken(_validateBills(payload.bills));
			require(balance >= amount, 'Billing: insufficient balance');
		}

		emit Billing(payload.provider, payload.nonce, payload.account, payload.bills, amount);
	}

	function _setBillsTypedHash(bytes32 hash) internal {
		billsTypedHash = hash;
		emit BillsTypedHashUpdated(hash);
	}

	function balanceOf(address provider, bytes32 account) public view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import './IBilling.sol';

/// @author Alexandas
/// @dev FundWallet interface
interface IFundWallet is IBilling {
	enum Purpose {
		Null,
		Recharge,
		Spend,
		Withdraw
	}

	struct Wallet {
		address owner;
		uint256 amount;
	}

	/// @dev emit when recharge type hash updated
	/// @param hash recharge type hash
	event RechargeTypedHashUpdated(bytes32 hash);

	/// @dev emit when nonce updated
	/// @param provider provider address
	/// @param account user account
	/// @param nonce nonce
	/// @param purpose nonce used for
	event NonceUpdated(address provider, bytes32 account, uint64 nonce, Purpose purpose);

	/// @dev emit when wallet owner changed
	/// @param provider provider address
	/// @param account user account
	/// @param newOwner new wallet owner for `account`
	event WalletOwnerTransferred(address provider, bytes32 account, address newOwner);

	/// @dev emit when account recharged
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param amount token amount
	event Recharged(address provider, uint64 nonce, bytes32 account, uint256 amount);

	/// @dev emit when user withdrawn
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param to token receiver
	/// @param amount token amount
	event Withdrawn(address provider, uint64 nonce, bytes32 account, address to, uint256 amount);

	/// @dev return recharge typed hash
	function rechargeTypedHash() external view returns (bytes32);

	/// @dev return owner of account
	/// @param provider provider address
	/// @param account user account
	/// @return owner wallet owner for account
	function ownerOf(address provider, bytes32 account) external view returns (address);

	/// @dev transfer wallet owner for account
	/// @param provider provider address
	/// @param account user account
	/// @param newOwner new wallet owner for account
	function transferWalletOwner(
		address provider,
		bytes32 account,
		address newOwner
	) external;

	/// @dev recharge for account
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param amount token amount
	/// @param signature provider signature
	function recharge(
		address provider,
		uint64 nonce,
		bytes32 account,
		uint256 amount,
		bytes memory signature
	) external;

	/// @dev withdraw token for account
	/// @param payload bill payload
	/// @param to token receiver
	/// @param amount token amount
	/// @param signature provider signature
	/// @return fee bill fee
	function withdraw(
		Payload memory payload,
		address to,
		uint256 amount,
		bytes memory signature
	) external returns (uint256 fee);

	/// @dev spend bill for account
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param bills bills bytes
	/// @param expiration tx expiration
	/// @param signature provider signature
	/// @param fee bills fee
	function spend(
		address provider,
		uint64 nonce,
		bytes32 account,
		bytes memory bills,
		uint256 expiration,
		bytes memory signature
	) external returns (uint256 fee);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

/// @author Alexandas
/// @dev Make the contract owner can withdraw token and eth
abstract contract OwnerWithdrawable is OwnableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	/// @dev emit when token is withdrawn
	/// @param token token address
	/// @param to receiver address
	/// @param value token value
	event Withdrawal(IERC20Upgradeable token, address to, uint256 value);

	/// @dev emit when ETH is withdrawn
	/// @param to receiver address
	/// @param value token value
	event NativeWithdrawal(address to, uint256 value);

	/// @dev withdraw token
	/// @param token token address
	/// @param to receiver address
	/// @param value token value
	function ownerWithdrawERC20(
		IERC20Upgradeable token,
		address to,
		uint256 value
	) external onlyOwner {
		token.safeTransfer(to, value);
		emit Withdrawal(token, to, value);
	}

	/// @dev withdraw ETH
	/// @param to receiver address
	/// @param value token value
	function ownerWithdrawNative(address payable to, uint256 value) external onlyOwner {
		bool success = to.send(value);
		require(success, 'Payment: withdraw native token failed');
		emit NativeWithdrawal(to, value);
	}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

/// @author Alexandas
/// @dev make contract pausable
abstract contract Pauser is OwnableUpgradeable, PausableUpgradeable {
	/// @dev all pausers
	mapping(address => bool) public pausers;

	/// @dev emit when pauser is added
	/// @param account pauser address
	event PauserAdded(address account);

	/// @dev emit when pauser is removed
	/// @param account pauser address
	event PauserRemoved(address account);

	function __Init_Pauser(address account) internal onlyInitializing {
		_addPauser(account);
	}

	modifier onlyPauser() {
		require(isPauser(msg.sender), 'Pauser: caller is not the pauser');
		_;
	}

	/// @dev pause the contract
	function pause() public onlyPauser {
		_pause();
	}

	/// @dev unpause the contract
	function unpause() public onlyPauser {
		_unpause();
	}

	/// @dev whether the account is the contract pauser
	/// @param account address
	/// @return whether account is a pauser
	function isPauser(address account) public view returns (bool) {
		return pausers[account];
	}

	/// @dev add a pauser for the contract
	/// @param account address
	function addPauser(address account) public onlyOwner {
		_addPauser(account);
	}

	/// @dev remove a pauser for the contract
	/// @param account address
	function removePauser(address account) public onlyOwner {
		_removePauser(account);
	}

	/// @dev remove a pauser for the contract
	function renouncePauser() public {
		_removePauser(msg.sender);
	}

	function _addPauser(address account) private {
		require(!isPauser(account), 'Pauser: account is already pauser');
		pausers[account] = true;
		emit PauserAdded(account);
	}

	function _removePauser(address account) private {
		require(isPauser(account), 'Pauser: account is not pauser');
		delete pausers[account];
		emit PauserRemoved(account);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '../interfaces/IProvidersWrapper.sol';

/// @author Alexandas
/// @dev providers wrapper contract
abstract contract ProvidersWrapper is IProvidersWrapper, Initializable {
	/// @dev providers contract address
	IProviders public override providers;

	/// @dev initialize providers contract
	/// @param _providers providers contract address
	function __Init_Providers(IProviders _providers) internal onlyInitializing {
		_setProviders(_providers);
	}

	function _setProviders(IProviders _providers) internal {
		providers = _providers;
		emit ProvidersUpdated(_providers);
	}
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '../libraries/ResourceData.sol';
import '../resources/interfaces/IResourceAdaptor.sol';
import './IProvidersWrapper.sol';

/// @author Alexandas
/// @dev Billing interface
interface IBilling is IProvidersWrapper {
	struct BillEntry {
		ResourceData.ResourceType resourceType;
		uint256 amount;
	}

	struct Bill {
		uint256 indexBlock;
		BillEntry[] entries;
	}

	struct Payload {
		address provider;
		uint64 nonce;
		bytes32 account;
		bytes bills;
		uint256 expiration;
	}

	/// @dev emit when BillTypedHash updated
	/// @param hash BillTypedHash
	event BillsTypedHashUpdated(bytes32 hash);

	/// @dev emit when resource adaptor updated
	/// @param adaptor resource adaptor address
	event ResourceAdaptorUpdated(IResourceAdaptor adaptor);

	/// @dev emit when bills finalized
	/// @param provider provider address
	/// @param nonce nonce
	/// @param account user account
	/// @param bills bills data
	/// @param amount fee
	event Billing(address provider, uint64 nonce, bytes32 account, bytes bills, uint256 amount);

	/// @dev get bills types hash
	/// @return type hash for bills
	function billsTypedHash() external view returns (bytes32);

	/// @dev get the resource adaptor
	/// @return resource adaptor address
	function adaptor() external view returns (IResourceAdaptor);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../../libraries/ResourceData.sol';

/// @author Alexandas
/// @dev resource adpator interface
interface IResourceAdaptor {
	struct PriceAdaptor {
		ResourceData.ResourceType resourceType;
		uint256 price;
	}

	/// @dev emit when price updated
	/// @param adaptors price adaptors
	event PriceAdaptorsUpdated(PriceAdaptor[] adaptors);

	/// @dev get price for resource at a specific block
	/// @param resourceType resource type
	/// @param _indexBlock block number
	/// @return price for resource at a specific block
	function priceAt(ResourceData.ResourceType resourceType, uint256 _indexBlock) external view returns (uint256);

	/// @dev get value for `amount` resource at a specific block
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @param _indexBlock block number
	/// @return token value in resource decimals(18)
	function getValueAt(
		ResourceData.ResourceType resourceType,
		uint256 amount,
		uint256 _indexBlock
	) external view returns (uint256);

	/// @dev get amount resource with value at a specific block
	/// @param resourceType resource type
	/// @param value token value
	/// @param _indexBlock block numer
	/// @return resource amount
	function getAmountAt(
		ResourceData.ResourceType resourceType,
		uint256 value,
		uint256 _indexBlock
	) external view returns (uint256);

	/// @dev return resource price
	/// @param resourceType resource type
	/// @return resource price
	function priceOf(ResourceData.ResourceType resourceType) external view returns (uint256);

	/// @dev return value of amount resource
	/// @param resourceType resource type
	/// @param amount resource amount
	/// @return token value in resource decimals(18)
	function getValueOf(ResourceData.ResourceType resourceType, uint256 amount) external view returns (uint256);

	/// @dev return resource amount with value
	/// @param resourceType resource type
	/// @param value token value in resource decimals(18)
	/// @return resource amount
	function getAmountOf(ResourceData.ResourceType resourceType, uint256 value) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

/// @author Alexandas
/// @dev token wrapper contract
abstract contract ResourcePayTokenWrapper is Initializable {
	using SafeMathUpgradeable for uint256;

	/// @dev token address
	IERC20Upgradeable public token;

	/// @dev emit when token updated
	/// @param token token address
	event TokenUpdated(IERC20Upgradeable token);

	/// @dev initialize token
	/// @param _token token address
	function __Init_Token(IERC20Upgradeable _token) internal onlyInitializing {
		_setToken(_token);
	}

	function _setToken(IERC20Upgradeable _token) internal {
		require(address(_token) != address(0), 'ResourcePayTokenWrapper: zero address');
		token = _token;
		emit TokenUpdated(token);
	}

	/// @dev match token amount to resource decimals
	/// @param value token amount with resource decimals
	/// @return resource value
	function matchTokenToResource(uint256 value) public view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals();
		uint256 _resourceDecimals = resourceDecimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.mul(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.div(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev match value to token decimals
	/// @param value resource value
	/// @return token value
	function matchResourceToToken(uint256 value) public view returns (uint256) {
		uint256 _tokenDecimals = tokenDecimals();
		uint256 _resourceDecimals = resourceDecimals();
		if (_tokenDecimals <= _resourceDecimals) {
			return value.div(10**(_resourceDecimals.sub(_tokenDecimals)));
		}
		return value.mul(10**(_tokenDecimals.sub(_resourceDecimals)));
	}

	/// @dev return resource decimals
	/// @return resource decimals
	function resourceDecimals() public view returns (uint256) {
		return 18;
	}

	/// @dev return token decimals
	/// @return token decimals
	function tokenDecimals() public view returns (uint256) {
		// keccak256(bytes4('decimals()'))
		(bool success, bytes memory data) = address(token).staticcall(hex'313ce567');
		require(success, 'ResourcePayTokenWrapper: invalid token');
		return abi.decode(data, (uint256));
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

import '../interfaces/IProviders.sol';

/// @author Alexandas
/// @dev providers wrapper interface
interface IProvidersWrapper {
	/// @dev emit when providers contract updated
	/// @param providers providers contract
	event ProvidersUpdated(IProviders providers);

	/// @dev return providers contract address
	function providers() external view returns (IProviders);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev providers interface
interface IProviders {
	/// @dev emit when provider is added
	/// @param provider provider address
	event AddProvider(address provider);

	/// @dev emit when provider removed
	/// @param provider provider address
	event RemoveProvider(address provider);

	/// @dev return whether address is a provider
	/// @param provider address
	function isProvider(address provider) external view returns (bool);

	/// @dev return whether a valid signature
	/// @param provider address
	/// @param hash message hash
	/// @param signature provider signature for message hash
	/// @return is valid signature
	function isValidSignature(
		address provider,
		bytes32 hash,
		bytes memory signature
	) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.8.0;

/// @author Alexandas
/// @dev resource data library
library ResourceData {
	enum ResourceType {
		Null,
		BuildingTime,
		Bandwidth,
		ARStorage,
		IPFSStorage
	}

	struct Payload {
		ResourceData.ResourceType resourceType;
		uint256[] values;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}