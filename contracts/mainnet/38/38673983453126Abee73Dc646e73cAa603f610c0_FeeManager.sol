// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FeeManager is OwnableUpgradeable {
	uint256 public constant MAX_FEE = 10000;

	mapping(address => uint256) vaults;
	mapping(address => uint256) lending;

	uint256 private swapFee;

	function initialize() public initializer {
		__Ownable_init();
	}

	function getVaultFee(address _vault) external view returns (uint256) {
		return vaults[_vault];
	}

	function getVaultFeeMultiple(address[] memory _vaults)
		external
		view
		returns (uint256[] memory)
	{
		uint256[] memory _fees = new uint256[](_vaults.length);

		for (uint256 i = 0; i < _vaults.length; i++)
			_fees[i] = vaults[_vaults[i]];

		return _fees;
	}

	function getLendingFee(address _asset) external view returns (uint256) {
		return lending[_asset];
	}

	function getLendingFeeMultiple(address[] memory _assets)
		external
		view
		returns (uint256[] memory)
	{
		uint256[] memory _fees = new uint256[](_assets.length);

		for (uint256 i = 0; i < _assets.length; i++)
			_fees[i] = lending[_assets[i]];

		return _fees;
	}

	function getSwapFee() external view returns (uint256) {
		return swapFee;
	}

	function setVaultFee(address _vault, uint256 _fee) external onlyOwner {
		require(_fee <= MAX_FEE);
		vaults[_vault] = _fee;
	}

	function setVaultFeeMulti(address[] memory _vaults, uint256[] memory _fees)
		external
		onlyOwner
	{
		require(_vaults.length == _fees.length, "!LENGTH");
		for (uint256 i = 0; i < _vaults.length; i++) {
			require(_fees[i] <= MAX_FEE);
			vaults[_vaults[i]] = _fees[i];
		}
	}

	function setLendingFee(address _asset, uint256 _fee) external onlyOwner {
		lending[_asset] = _fee;
	}

	function setLendingFeeMulti(
		address[] memory _assets,
		uint256[] memory _fees
	) external onlyOwner {
		require(_assets.length == _fees.length, "!LENGTH");
		for (uint256 i = 0; i < _assets.length; i++) {
			require(_fees[i] <= MAX_FEE);
			lending[_assets[i]] = _fees[i];
		}
	}

	function setSwapFee(uint256 _swapFee) external onlyOwner {
		swapFee = _swapFee;
	}
}