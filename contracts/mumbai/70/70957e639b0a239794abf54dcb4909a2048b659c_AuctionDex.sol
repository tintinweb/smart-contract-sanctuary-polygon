// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IXanaliaNFT.sol";
import "./interfaces/IXanaliaAddressesStorage.sol";

contract AuctionDex is Initializable, OwnableUpgradeable {
	uint256 public constant BASE_DENOMINATOR = 10_000;
	uint256 public constant MINIMUM_BID_RATE = 500;
	uint256 public totalAuctions;
	uint256 public totalBidAuctions;

	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	struct Auction {
		address owner;
		address collectionAddress;
		address paymentToken;
		uint256 tokenId;
		uint256 startPrice;
		uint256 startTime;
		uint256 endTime;
		uint256[] listBidId;
	}

	struct BidAuction {
		address bidder;
		address paymentToken;
		address collectionAddress;
		uint256 tokenId;
		uint256 auctionId;
		uint256 bidPrice;
		bool status;
		bool isOwnerAccepted;
		uint256 expireTime;
	}

	mapping(uint256 => Auction) public auctions;
	mapping(uint256 => BidAuction) public bidAuctions;

	mapping(address => mapping(uint256 => bool)) public tokenOnAuction; //collectionAddress => tokenId => bool

	mapping(uint256 => uint256) public auctionHighestBidId; //auctionId => bidId

	mapping(uint256 => uint256) public auctionBidCount;

	function initialize(address _xanaliaAddressesStorage) public initializer {
        __Ownable_init_unchained();
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}

	modifier onlyXanaliaDex() {
        require(
            msg.sender == xanaliaAddressesStorage.xanaliaDex(),
            "Xanalia: caller is not xanalia dex"
        );
        _;
    }

	receive() external payable {}

	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external onlyXanaliaDex returns (uint256 _auctionId) {
		totalAuctions++;
		_auctionId = totalAuctions;

		tokenOnAuction[_collectionAddress][_tokenId] = true;

		Auction storage newAuction = auctions[_auctionId];

		newAuction.owner = _itemOwner;
		newAuction.collectionAddress = _collectionAddress;
		newAuction.paymentToken = _paymentToken;
		newAuction.tokenId = _tokenId;
		newAuction.startPrice = _startPrice;
		newAuction.startTime = _startTime;
		newAuction.endTime = _endTime;

		return _auctionId;
	}

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		address _bidOwner,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external onlyXanaliaDex returns (uint256 _bidAuctionId) {
		Auction storage currentAuction = auctions[_auctionId];
		require(currentAuction.paymentToken == _paymentToken, "Incorrect-payment-method");
		require(currentAuction.owner != _bidOwner, "Owner-can-not-bid");
		require(
			block.timestamp >= currentAuction.startTime && block.timestamp <= currentAuction.endTime,
			"Not-in-auction-time"
		);

		if (bidAuctions[auctionHighestBidId[_auctionId]].bidPrice == 0) {
			require(_price >= currentAuction.startPrice, "Price-lower-than-start-price");
		} else {
			require(
				_price >= (bidAuctions[auctionHighestBidId[_auctionId]].bidPrice * MINIMUM_BID_RATE) / BASE_DENOMINATOR,
				"Price-bid-less-than-max-price"
			);
		}

		require(tokenOnAuction[_collectionAddress][_tokenId], "Auction-closed");

		auctionBidCount[_auctionId] += 1;

		BidAuction memory newBidAuction;
		newBidAuction.bidder = _bidOwner;
		newBidAuction.bidPrice = _price;
		newBidAuction.tokenId = _tokenId;
		newBidAuction.auctionId = _auctionId;
		newBidAuction.collectionAddress = _collectionAddress;
		newBidAuction.status = true;
		newBidAuction.isOwnerAccepted = false;
		newBidAuction.paymentToken = _paymentToken;
		newBidAuction.expireTime = _expireTime;

		totalBidAuctions++;

		bidAuctions[totalBidAuctions] = newBidAuction;
		_bidAuctionId = totalBidAuctions;

		currentAuction.listBidId.push(_bidAuctionId);

		auctionHighestBidId[_auctionId] = _bidAuctionId;

		return _bidAuctionId;
	}

	function cancelAuction(uint256 _auctionId, address _auctionOwner) external onlyXanaliaDex returns (uint256) {
		require(auctions[_auctionId].owner == _auctionOwner, "Not-auction-owner");

		Auction storage currentAuction = auctions[_auctionId];
		require(
			tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] ||
				currentAuction.endTime > block.timestamp,
			"Auction-cancelled-or-ended"
		);

		tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] = false;

		return _auctionId;
	}

	function cancelBidAuction(uint256 _bidAuctionId, address _auctionOwner)
		external
		onlyXanaliaDex
		returns (
			uint256,
			uint256,
			address
		)
	{
		BidAuction storage currentBid = bidAuctions[_bidAuctionId];
		Auction storage currentAuction = auctions[currentBid.auctionId];

		require(currentBid.status, "Bid-cancelled");
		require(_auctionOwner == currentBid.bidder, "Not-owner-of-bid-auction");

		currentBid.status = false;
		// Set new highest bid if highest bid is cancelled
		if (bidAuctions[auctionHighestBidId[currentBid.auctionId]].bidPrice == currentBid.bidPrice) {
			uint256 newHighestBidId;
			BidAuction memory bidInfo;
			if (currentAuction.listBidId.length == 1) {
				newHighestBidId = 0;
			} else {
				for (uint256 i = currentAuction.listBidId.length - 2; i >= 0; i--) {
					bidInfo = bidAuctions[currentAuction.listBidId[i]];
					if (bidInfo.status == true) {
						newHighestBidId = currentAuction.listBidId[i];
						break;
					}
				}
				if (newHighestBidId == auctionHighestBidId[currentBid.auctionId]) {
					newHighestBidId = 0;
				}
			}
			auctionHighestBidId[currentBid.auctionId] = newHighestBidId;
		}

		return (_bidAuctionId, currentBid.bidPrice, currentBid.paymentToken);
	}

	function reclaimAuction(uint256 _auctionId, address _auctionOwner) external onlyXanaliaDex returns (address, uint256) {
		Auction memory currentAuction = auctions[_auctionId];

		require(
			currentAuction.endTime < block.timestamp ||
				!tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId],
			"Auction-not-end-or-cancelled"
		);
		require(currentAuction.owner == _auctionOwner, "Not-auction-owner");

		tokenOnAuction[currentAuction.collectionAddress][currentAuction.tokenId] = false;

		return (currentAuction.collectionAddress, currentAuction.tokenId);
	}

	function acceptBidAuction(uint256 _bidAuctionId, address _auctionOwner)
		external
		onlyXanaliaDex
		returns (
			uint256,
			address,
			address,
			uint256,
			address,
			address
		)
	{
		BidAuction storage currentBid = bidAuctions[_bidAuctionId];
		Auction memory currentAuction = auctions[currentBid.auctionId];
		require(currentAuction.owner == _auctionOwner, "Not-owner-of-auction");
		require(block.timestamp < currentBid.expireTime && currentBid.status, "Bid-expired-or-cancelled");

		require(currentBid.bidPrice >= currentAuction.startPrice, "Bid-not-valid");

		require(!currentBid.isOwnerAccepted, "Bid-accepted");

		currentBid.isOwnerAccepted = true;
		tokenOnAuction[currentBid.collectionAddress][currentBid.tokenId] = false;

		return (
			currentBid.bidPrice,
			currentBid.collectionAddress,
			currentBid.paymentToken,
			currentBid.tokenId,
			currentAuction.owner,
			currentBid.bidder
		);
	}

	function setAddressesStorage (address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXanaliaNFT {
	function setXanaliaUriAddress(address _xanaliaUriAddress) external;

	function getCreator(uint256 _id) external view returns (address);

	function getRoyaltyFee(uint256 _id) external view returns (uint256);

	function create(
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _owner
	) external returns (uint256);

	function tokenURI(uint256 tokenId_) external view returns (string memory);

	function getContractAuthor() external view returns (address);

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXanaliaAddressesStorage {
	event XNftURIAddressChanged(address xNftURI);
	event AuctionDexChanged(address auctionDex);
	event MarketDexChanged(address marketDex);
	event OfferDexChanged(address offerDex);
	event XanaliaDexChanged(address xanaliaDex);
	event TreasuryChanged(address xanaliaTreasury);
	event DeployerChanged(address collectionDeployer);

	function xNftURI() external view returns (address);

	function auctionDex() external view returns (address);

	function marketDex() external view returns (address);

	function offerDex() external view returns (address);

	function xanaliaDex() external view returns (address);

	function xanaliaTreasury() external view returns (address);

	function collectionDeployer() external view returns (address);
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