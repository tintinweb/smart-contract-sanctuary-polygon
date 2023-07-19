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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity ^0.8.17;

import "./Operator.sol";

contract Common is Operator {
	bool public locked;

	modifier notLocked() virtual {
		require(!locked, "Operation locked");
		_;
	}

	function setupLock(bool _locked) external onlyOperator {
		locked = _locked;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Operator {
	event SetOperator(address indexed _addr);
	event DeleteOperator(address indexed _addr);

	mapping(address => bool) internal _operators;

	modifier onlyOperator() virtual {
		require(_operators[msg.sender], "Not operator");
		_;
	}

	function _setOperator(address operator) internal virtual {
		_operators[operator] = true;
		emit SetOperator(operator);
	}

	function _deleteOperator(address operator) internal virtual {
		delete _operators[operator];
		emit DeleteOperator(operator);
	}

	function isOperator(address _addr) public view returns (bool) {
		return _operators[_addr];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ICommonProvider.sol";
import "./common/Common.sol";

contract IndieProvider is ICommonProvider, Ownable, Common {
	uint256 constant divider = 10_000;

	address public feeReceiver;
	uint256 public defaultFanCollectionMintFee;
	uint256 public defaultFundingCollectionMintFee;

	mapping(address => uint256) private _fanCollectionConsumerToFee;
	mapping(address => uint256) private _fundingCollectionConsumerToFee;

	constructor() payable {
		_setOperator(_msgSender());
	}

	// Function to receive Ether. msg.data must be empty
	receive() external payable {}

	fallback() external payable {}

	function isApprovedOperator(address _addr) external view override returns (bool) {
		return this.isOperator(_addr);
	}

	function setOperator(address operator) external onlyOwner {
		_setOperator(operator);
	}

	function deleteOperator(address operator) external onlyOwner {
		_deleteOperator(operator);
	}

	function _providerFee(uint256 _salePrice, uint256 _fee) private pure returns (uint256) {
		uint256 value = (_salePrice * _fee);
		return value < divider ? 0 : value / divider;
	}

	function onTokenTransfer(
		address _collection,
		address _from,
		address _to,
		uint256 _startTokenId
	) external override {
		emit ProviderTransfer(_collection, _from, _to, _startTokenId);
	}

	function onTokenMint(
		address _collection,
		address _to,
		uint256 _startTokenId,
		uint256 _quantity,
		bytes calldata _data
	) external override {
		emit ProviderMint(_collection, _to, _startTokenId, _quantity, _data);
	}

	function onTokenUpdate(
		address _collection,
		bytes4 _selector,
		bytes calldata _data
	) external override {
		emit ProviderUpdate(_collection, _selector, _data);
	}

	function fanCollectionMintFee(
		uint256 _salePrice,
		address _consumer
	) public view virtual override returns (uint256, address) {
		uint256 consumerFee = _fanCollectionConsumerToFee[_consumer];
		uint256 fee = consumerFee > 0 ? consumerFee : defaultFanCollectionMintFee;

		return (_providerFee(_salePrice, fee), feeReceiver);
	}

	function fundingCollectionMintFee(
		uint256 _salePrice,
		address _consumer
	) public view virtual override returns (uint256, address) {
		uint256 consumerFee = _fundingCollectionConsumerToFee[_consumer];
		uint256 fee = consumerFee > 0 ? consumerFee : defaultFundingCollectionMintFee;

		return (_providerFee(_salePrice, fee), feeReceiver);
	}

	function setFanCollectionConsumerFee(address _consumer, uint256 _fee) external onlyOperator {
		_fanCollectionConsumerToFee[_consumer] = _fee;
	}

	function setFundingCollectionConsumerFee(
		address _consumer,
		uint256 _fee
	) external onlyOperator {
		_fundingCollectionConsumerToFee[_consumer] = _fee;
	}

	function setDefaultFees(
		uint256 _fanCollectionFee,
		uint256 _fundingCollectionFee,
		address _feeReceiver
	) external onlyOperator {
		defaultFanCollectionMintFee = _fanCollectionFee;
		defaultFundingCollectionMintFee = _fundingCollectionFee;
		feeReceiver = _feeReceiver;
	}

	function updateProvider(address _contract, address _newProvider) public {
		bytes memory signature = abi.encodeWithSignature("setProvider(address)", _newProvider);
		_exec(_contract, signature);
	}

	function _exec(address _contract, bytes memory data) public onlyOperator {
		(bool success, ) = _contract.call(data);
		require(success, "Call failed");
	}

	function withdraw(address beneficiary, uint256 amount) external onlyOwner {
		Address.sendValue(payable(beneficiary), amount);
	}

	function balance() public view returns (uint256) {
		return address(this).balance;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ICommonProvider {
	event ProviderMint(
		address indexed collection,
		address indexed to,
		uint256 startTokenId,
		uint256 quantity,
		bytes data
	);

	event ProviderUpdate(address indexed collection, bytes4 selector, bytes data);

	event ProviderTransfer(
		address indexed collection,
		address indexed from,
		address indexed to,
		uint256 tokenId
	);

	/**
	 * @dev Returns provider fee and fee receiver address
	 */
	function fanCollectionMintFee(
		uint256 salePrice,
		address consumer
	) external virtual returns (uint256, address);

	function fundingCollectionMintFee(
		uint256 salePrice,
		address consumer
	) external virtual returns (uint256, address);

	/**
	 * @dev Hook that is called after a set of serially-ordered token IDs
	 * have been transferred. This includes minting and burning.
	 */
	function onTokenTransfer(
		address collection,
		address from,
		address to,
		uint256 tokenId
	) external virtual;

	function onTokenMint(
		address collection,
		address to,
		uint256 startTokenId,
		uint256 quantity,
		bytes calldata data
	) external virtual;

	function onTokenUpdate(
		address collection,
		bytes4 selector,
		bytes calldata data
	) external virtual;

	function isApprovedOperator(address _addr) external view virtual returns (bool);
}