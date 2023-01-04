/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]
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


// File contracts/helpers/LicenseMetadata.sol
// HashUp Contracts V1
pragma solidity ^0.8.0;

/**
 * @dev HashUp implementation of ERC20 Metadata that suits Hashuplicense.
 */
contract LicenseMetadata is Ownable {
	// License name
	string private _name;

	// License symbol
	string private _symbol;

	// License color
	string private _color;

	// Other Metadata URL
	string private _metadataUrl;

	/**
	 * @dev Initializes the License Contract and sets
	 * correct color for provided supply and metadata.
	 */
	constructor(
		string memory name_,
		string memory symbol_,
		string memory metadataUrl_,
		uint256 totalSupply_
	) {
		_name = name_;
		_symbol = symbol_;
		_metadataUrl = metadataUrl_;
		_color = _getColorForSupply(totalSupply_);
	}

	/**
	 * @dev Updates current URL to metadata object that stores configuration of visuals,
	 * descriptions etc. that will appear while browsing on HashUp ecosystem.
	 *
	 * NOTE: We use IPFS by default in HashUp.
	 *
	 * Requirements:
	 * - the caller must be creator
	 */
	function setMetadata(string memory newMetadata) public onlyOwner {
		_metadataUrl = newMetadata;
	}

	/**
	 * NOTE: ERC20 Tokens usually use 18 decimal places but our
	 * CEO said it's stupid and we should use 2 decimals
	 */
	function decimals() public pure returns (uint8) {
		return 2;
	}

	/**
	 * @dev Returns the color of license. See {_getColorForSupply}
	 * function for details
	 */
	function color() public view returns (string memory) {
		return _color;
	}

	/**
	 * @dev Returns the name of the license.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the license.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the URL of other license metadata
	 */
	function metadataUrl() public view returns (string memory) {
		return _metadataUrl;
	}

	/**
	 * @dev Returns License color for specified supply. There are three types
	 * of licenses based on a totalSupply (numbers without including decimals)
	 * 0 - 133.700 => Gold License
	 * 133.701 - 100 000 000 => Gray License
	 * 100 000 001+ => Custom License
	 *
	 * NOTE: Color doesn't affect License Token logic, it's used for display
	 * purposes so we can simplify token economics visually.
	 */
	function _getColorForSupply(uint256 supply)
		private
		pure
		returns (string memory color)
	{
		if (supply <= 133_700 * 10**decimals()) {
			return "gold";
		} else if (supply <= 100_000_000 * 10**decimals()) {
			return "gray";
		}
		return "custom";
	}
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/HashupLicense.sol

// HashUp Contracts V1
pragma solidity ^0.8.17;


/**
 * @dev HashUp profile Contract, used for managing profiles,
 * in future we want to use it to sending ERC20 Licenses
 * providing only friend name and more
 */
contract HashupLicense is IERC20, LicenseMetadata {
    // Fee to creator on transfer
    uint256 public _creatorFee;

    // Amount of Licenses gathered from fees
    uint256 private _feeCounter;

    // HashUp Store contract address
    address private _store;

    // Mapping address to License balance
    mapping(address => uint256) private _balances;

    // Mapping address to mapping of allowances
    mapping(address => mapping(address => uint256)) private _allowed;

    // Total amount of Licenses
    uint256 private _totalSupply;

    // Whether {transferFrom} is available for users
    bool private _isOpen;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory metadataUrl_,
        uint256 totalSupply_,
        uint256 creatorFee_,
        address store_
    ) LicenseMetadata(name_, symbol_, metadataUrl_, totalSupply_) {
        require(
            creatorFee_ < 100 * 10**feeDecimals(),
            "HashupLicense: Incorrect fee"
        );
        _balances[msg.sender] = totalSupply_;
        _totalSupply = totalSupply_;
        _creatorFee = creatorFee_;
        _store = store_;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns percentage of amount that goes to the
     * creator when transferring Licenses
     */
    function creatorFee() public view returns (uint256) {
        return _creatorFee;
    }

    /**
     * @dev Returns sum of of Licenses gathered
     * by creator via transfer fees
     */
    function feeCounter() public view returns (uint256) {
        return _feeCounter;
    }

    /**
     * @dev Amount of decimals in fee number, its 1 so
     * for example 5 is 0.5%  and 50 is 5%
     */
    function feeDecimals() public pure returns (uint8) {
        return 1;
    }

    /**
     * @dev Address of HashUp store that license will
     * be listed on. We save it here so interaction with
     * store (for example sending games to it) doesn't
     * take any fees
     */
    function store() public view returns (address) {
        return _store;
    }

    /**
     * @dev Address of HashUp store that license will
     * be listed on. We save it here so interaction with
     * store (for example sending games to it) doesn't
     * take any fees
     */
    function setStore(address newStore) public onlyOwner {
        _store = newStore;
    }

    /**
     * @dev Stores whether transferFrom is blocked,
     * it can be unlocked by admin to enable it for
     * usage in other smart contracts for example DEX
     */
    function isOpen() public view returns (bool) {
        return _isOpen;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Sets `_isOpen` to true and enables transferFrom
     *
     * Requirements:
     * - sender must be admin
     */
    function switchSale() public {
        require(
            msg.sender == owner(),
            "HashupLicense: only admin can enable transferFrom"
        );
        _isOpen = true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool success)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(
            owner != address(0),
            "HashupLicense: approve from the zero address"
        );
        require(
            spender != address(0),
            "HashupLicense: approve to the zero address"
        );
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Splits value between recipient and License creator
     *
     * NOTE: If sender is store or owner it doesn't count
     * creator fee and gives everything to recipient
     **/
    function calculateFee(uint256 value, address sender)
        public
        view
        returns (uint256 recipientPart, uint256 creatorPart)
    {
        if (sender == _store || sender == owner()) {
            return (value, 0);
        }
        uint256 fee = (value * _creatorFee) / 1000;
        uint256 remaining = value - fee;

        return (remaining, fee);
    }

    /**
     * @dev It calls _transferFrom that calculates and sends fee to License creator
     **/
    function transfer(address to, uint256 value)
        public
        virtual
        override
        returns (bool success)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    /**
     * @dev It calls _transferFrom that calculates and sends fee to License creator
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool success) {
        require(
            from != address(0),
            "HashupLicense: transfer from the zero address"
        );

        if (!_isOpen) {
            require(
                from == owner() || from == _store,
                "HashupLicense: transferFrom is closed"
            );
        }

        _spendAllowance(from, msg.sender, value);
        _transferFrom(from, to, value);

        return true;
    }

    /**
     * @dev Internal transfer from to remove redundance on transfer
     * and transferFrom
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(
            _to != address(0),
            "HashupLicense: transfer to the zero address"
        );

        require(
            _balances[_from] >= _value,
            "HashupLicense: insufficient token balance"
        );

        (uint256 recipientPart, uint256 creatorPart) = calculateFee(
            _value,
            _from
        );

        _balances[_from] -= _value;
        _balances[_to] += recipientPart;

        _balances[owner()] += creatorPart;
        _feeCounter += creatorPart;

        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "HashupLicense: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


// File contracts/HashupStoreV1.sol
pragma solidity 0.8.17;




/// @title Hashup Multimarketplace Store
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract HashupStoreV1 is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // Sale consists of price in ERC20 token and percent of sale that goes to marketplace
    struct SaleInformation {
        uint256 price;
        uint256 marketplaceFee;
        bool sale;
    }

    event Bought(
        address license,
        address marketplace,
        uint256 price,
        uint256 amount,
        address referrer
    );

    event NewSale(
        address creator,
        address license,
        string symbol,
        string name,
        string color,
        uint256 price,
        string metadata,
        uint256 totalSupply,
        uint256 transferFee,
        uint256 marketplaceFee
    );

    event PriceChanged(address license, uint256 newPrice);
    
    event Withdrawal(address license, uint256 amount);

    // Whitelist of addresses that are elgible to take marketplace fee
    mapping(address => bool) private _marketWhitelist;

    mapping(address => SaleInformation) private _licenseSales;

    uint256 constant MAX_HASHUP_FEE = 10;
    uint256 constant MAX_MARKETPLACE_FEE = 90;

    uint256 private _hashupFee;
    address private _paymentToken;

    function initialize() public initializer {
        _transferOwnership(msg.sender);
        _setHashupFee(10);
        _setPaymentToken(address(0));
    }

    function setHashupFee(uint256 newHashupFee) public onlyOwner {
        _setHashupFee(newHashupFee);
    }

    function _setHashupFee(uint256 newHashupFee) internal {
        require(
            newHashupFee <= MAX_HASHUP_FEE,
            "HashupStore: HashupFee exceeded max limit"
        );
        _hashupFee = newHashupFee;
    }

    function getHashupFee() external view returns (uint256) {
        return _hashupFee;
    }

    function getPaymentToken() external view returns (address) {
        return _paymentToken;
    }

    function setPaymentToken(address newPaymentToken) public onlyOwner {
        _setPaymentToken(newPaymentToken);
    }

    function _setPaymentToken(address newPaymentToken) internal {
        _paymentToken = newPaymentToken;
    }

    // Used to toggle state of Pausable contract
    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // NOTE: We need to discuss whether we have right to disable whitelist
    function toggleWhitelisted(address marketplace) public onlyOwner {
        _marketWhitelist[marketplace] = !_marketWhitelist[marketplace];
    }

    modifier onlyWhitelisted(address marketplace) {
        _checkWhitelisted(marketplace);
        _;
    }

    // Returns whether address is whitelisted marketplace
    function _checkWhitelisted(address marketplace) internal {
        require(
            _marketWhitelist[marketplace] == true,
            "HashupStore: marketplace must be whitelisted."
        );
    }

    function isWhitelisted(address marketplace) public view returns (bool) {
        return _marketWhitelist[marketplace];
    }

    modifier onlyLicenseCreator(address License) {
        _checkLicenseCreator(License);
        _;
    }

    function _checkLicenseCreator(address license) internal view {
        require(
            msg.sender == HashupLicense(license).owner(),
            "HashupStore: must be License creator"
        );
    }



    function sendLicenseToStore(
        address license,
        uint256 price,
        uint256 amount,
        uint256 marketplaceFee
    ) public onlyLicenseCreator(license) whenNotPaused {
        require(
            _licenseSales[license].sale == false,
            "HashupStore: Can't set for sale second time"
        );
        require(
            marketplaceFee <= MAX_MARKETPLACE_FEE,
            "HashupStore: Marketplace fee is too high"
        );

        HashupLicense licenseToken = HashupLicense(license);
        licenseToken.transferFrom(msg.sender, address(this), amount);

        _licenseSales[license] = SaleInformation(price, marketplaceFee, true);

        emit NewSale(
            msg.sender,
            license,
            licenseToken.symbol(),
            licenseToken.name(),
            licenseToken.color(),
            price,
            licenseToken.metadataUrl(),
            licenseToken.totalSupply(),
            licenseToken.creatorFee(),
            marketplaceFee
        );
    }

    function withdrawLicenses(address license, uint256 amount)
        external
        onlyLicenseCreator(license)
        returns (uint256)
    {
        HashupLicense licenseToken = HashupLicense(license);
        uint256 availableAmount = licenseToken.balanceOf(address(this));

        if (availableAmount >= amount) {
            // Return all licenses
            licenseToken.transfer(msg.sender, amount);
            emit Withdrawal(license, amount);
            return amount;
        } else {
            // Return as much as possible
            licenseToken.transfer(msg.sender, availableAmount);
            emit Withdrawal(license, availableAmount);
            return availableAmount;
        }
    }

    function getLicensePrice(address license) public view returns (uint256) {
        return _licenseSales[license].price;
    }

    function getLicenseMarketplaceFee(address license)
        public
        view
        returns (uint256)
    {
        return _licenseSales[license].marketplaceFee;
    }

    function changeLicensePrice(address license, uint256 newPrice)
        public
        onlyLicenseCreator(license)
    {
        require(
            _licenseSales[license].sale == true,
            "HashupStore: License isn't listed in store"
        );
        _licenseSales[license].price = newPrice;
        emit PriceChanged(license, newPrice);
    }

    function distributePayment(
        uint256 totalValue,
        uint256 hashupFee,
        uint256 marketplaceFee
    )
        internal
        pure
        returns (
            uint256 toCreator,
            uint256 toMarketplace,
            uint256 toHashup
        )
    {
        // Split provided price between HashUp, marketplace and License creator
        uint256 hashupPart = (totalValue * hashupFee) / 100;
        uint256 marketplacePart = (totalValue * marketplaceFee) / 100;
        uint256 creatorPart = totalValue - hashupPart - marketplacePart;

        return (creatorPart, marketplacePart, hashupPart);
    }

    function buyLicense(
        address license,
        uint256 amount,
        address marketplace,
        address referrer
    ) public whenNotPaused onlyWhitelisted(marketplace) {
        IERC20 paymentToken = IERC20(_paymentToken);
        HashupLicense licenseToken = HashupLicense(license);

        require(_licenseSales[license].sale == true, "HashupStore: License must be listed");

        uint256 totalPrice = getLicensePrice(license) * amount;

        (
            uint256 toCreator,
            uint256 toMarketplace,
            uint256 toHashup
        ) = distributePayment(
                totalPrice,
                _hashupFee,
                getLicenseMarketplaceFee(license)
            );

        // Send licenses from HashupStore to buyer
        licenseToken.transfer(msg.sender, amount);

        // Send payment token to creator
        paymentToken.transferFrom(msg.sender, licenseToken.owner(), toCreator);

        // Send payment token to marketplace
        paymentToken.transferFrom(msg.sender, marketplace, toMarketplace);

        // Send tokens to HashUp
        paymentToken.transferFrom(msg.sender, owner(), toHashup);

        emit Bought(license, marketplace, totalPrice, amount, referrer);
    }
}