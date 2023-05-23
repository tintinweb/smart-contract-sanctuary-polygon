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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/ILicenseManager.sol";
import "./interfaces/IStakingService.sol";

/**
 * @title AltrLicenseManager
 * @author Lucidao Developer
 * @dev This contract serves as a license manager for a software system. It allows for the owner to set
 * discounts for individual users and track conventions for each oracle. It also allows for the owner to
 * set the staking service and staked tokens required for oracle eligibility.
 */
contract AltrLicenseManager is Ownable, ERC165, ILicenseManager {
	using ERC165Checker for address;

	/**
	 * @dev mapping to store conventions for each oracle
	 */
	mapping(address => uint256) public conventions;

	/**
	 * @dev constant variable to define minimum discount
	 */
	uint256 public constant MIN_DISCOUNT = 0;

	/**
	 * @dev constant variable to define maximum discount
	 */
	uint256 public constant MAX_DISCOUNT = 9000;

	/**
	 * @dev staking service address
	 */
	address public stakingService;

	/**
	 * @dev staking service pool id
	 */
	uint256 public stakingServicePid;

	/**
	 * @dev staked tokens for oracle eligibility
	 */
	uint256 public stakedTokensForOracleEligibility;

	/**
	 * @dev Event emitted when a user's discount is set
	 * @param user Address of the user whose discount is being set
	 * @param discount The discount being set for the user
	 */
	event DiscountSet(address indexed user, uint256 discount);

	/**
	 * @dev Event emitted when the staking service address is set
	 * @param stakingService Address of the staking service
	 * @param stakingServicePid The pool id of the staking service
	 */
	event StakingServiceSet(address indexed stakingService, uint256 indexed stakingServicePid);

	/**
	 * @dev Event emitted when the staking service pool id is set
	 * @param pid The pool id of the staking service
	 */
	event StakingServicePidSet(uint256 indexed pid);

	/**
	 * @dev Event emitted when the amount of staked tokens required for oracle eligibility is set
	 * @param amount The amount of staked tokens required for oracle eligibility
	 */
	event StakedTokensForOracleEligibilitySet(uint256 indexed amount);

	/**
	 * @dev Constructor to initialize the staking service and staked tokens for oracle eligibility.
	 * @param stakingService_ The address of the staking service.
	 * @param stakingServicePid_ The pool id of the staking service.
	 * @param _stakedTokensForOracleEligibility The number of tokens required for oracle eligibility.
	 */
	constructor(address stakingService_, uint256 stakingServicePid_, uint256 _stakedTokensForOracleEligibility) {
		_setStakingService(stakingService_, stakingServicePid_);
		stakedTokensForOracleEligibility = _stakedTokensForOracleEligibility;
	}

	/**
	 * @dev Allows the owner of the contract to set a discount for a given user
	 * @param user Address of the user for which the discount will be set
	 * @param discount Amount of the discount for the user (in percents)
	 */
	function setDiscount(address user, uint256 discount) external onlyOwner {
		require(discount > MIN_DISCOUNT && discount <= MAX_DISCOUNT, "AltrLicenseManager: discount not in accepted range");
		conventions[user] = discount;

		emit DiscountSet(user, discount);
	}

	/**
	 * @dev Allows the owner of the contract to set the staking service
	 * @param stakingService_ address of the staking service
	 * @param pid_ pool id of the staking service
	 */
	function setStakingService(address stakingService_, uint256 pid_) external onlyOwner {
		_setStakingService(stakingService_, pid_);

		emit StakingServiceSet(stakingService_, pid_);
	}

	/**
	 * @dev Allows the owner of the contract to set the required staked tokens for an oracle to be qualified
	 * @param amount minimum amount of staked tokens
	 */
	function setStakedTokensForOracleEligibility(uint256 amount) external onlyOwner {
		stakedTokensForOracleEligibility = amount;

		emit StakedTokensForOracleEligibilitySet(amount);
	}

	/**
	 * @dev returns the discount for a given user
	 * @param user Address of the user for which the discount will be retrieved
	 * @return discount Amount of the discount for the user (in percents)
	 */

	function getDiscount(address user) external view override returns (uint256) {
		return conventions[user];
	}

	/**
	 * @dev returns true if the oracle has the minimum required staked tokens
	 * @param oracle address of the oracle
	 * @return bool returns true if the oracle is qualified
	 */
	function isAQualifiedOracle(address oracle) external view virtual returns (bool) {
		uint256 stakedTokens = IStakingService(stakingService).userInfo(stakingServicePid, oracle);
		if (stakedTokens < stakedTokensForOracleEligibility) return false;
		return true;
	}

	/**
	 * @dev Check if a given address supports the ILicenseManager interface
	 * @param interfaceId 4 bytes long ID of the interface to check
	 * @return bool returns true if the address implements the interface
	 */
	function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
		return interfaceId == type(ILicenseManager).interfaceId || super.supportsInterface(interfaceId);
	}

	/**
	 * @dev This function is responsible for setting the staking service for AltrLicenseManager. The address passed as an argument must not be a null address and must support the IStakingService interface
	 *
	 * @param stakingService_ the address of the contract implementing the IStakingService interface
	 * @param pid_ the pool id of the staking service
	 */
	function _setStakingService(address stakingService_, uint256 pid_) internal {
		require(stakingService_ != address(0), "AltrLicenseManager: cannot be null address");
		require(stakingService_.supportsInterface(type(IStakingService).interfaceId), "AltrLicenseManager: does not support IStakingService interface");

		address stakingToken = IStakingService(stakingService_).poolStakingToken(pid_);
		require(stakingToken != address(0), "AltrLicenseManager: pool id not valid");

		stakingServicePid = pid_;
		stakingService = stakingService_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILicenseManager {
	function getDiscount(address user) external view returns (uint256);

	function isAQualifiedOracle(address oracle) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStakingService {
	function poolStakingToken(uint256 pid) external view returns (address);

	function userInfo(uint256 pid, address user) external view returns (uint256);
}