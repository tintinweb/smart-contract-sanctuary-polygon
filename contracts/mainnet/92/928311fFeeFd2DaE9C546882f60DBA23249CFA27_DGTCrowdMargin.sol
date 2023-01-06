// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DGTCrowdMargin is Initializable {
    token public DGToken;
    DAIGON public daigon;
    address public scatterContract;

    address public owner;
    address public a1;
    address public a2;
    address public a3;
    address public stakingFunder;

    PoolInfo[] public poolInfos;
    mapping(uint32 => Blob[]) public poolBlobs;
    mapping(uint32 => mapping(uint32 => bool)) public isPoolBlobClaimed;

    mapping(uint32 => uint32[]) public vacantBlobs;
    mapping(uint32 => uint32) public vacantBlobIndex;
    mapping(address => mapping(uint32 => bool)) public userForcedAutoFill;
    mapping(address => bool) public userEnabled;

    mapping(address => uint32[]) public userData;
    mapping(address => uint32) public lastDownlineCount;

    mapping(address => uint128) public totalIncome;

    uint32 public minimumDownline;
    uint32 public repeatMinimum;
    uint96 public joinFee;

    mapping(address => uint32) public totalBoxes;

    struct Blob {
    	address owner;
    	uint32 up;
    	uint32 left;
    	uint32 right;
    }

    struct PoolInfo {
    	uint128 amount;
    	uint32 nextPool;
    	uint96 penaltyAmount;
    }

    function initialize(address _stakingFunder, address _a1, address _a2, address _a3) external initializer {

	    DGToken = token(0xc71D4BFBF1914f7B1e977bceC4bc9A94f96178F5);
	    daigon = DAIGON(0xa4f3209ef68493e089c9105dC1841Da4dF2de643);
	    scatterContract = 0xD25ebFE20Cb23f14D1A53EB34B505b2fB0203A8B;

	    minimumDownline = 2;
	    repeatMinimum = 0;
	    joinFee = 10;

    	stakingFunder = _stakingFunder;
    	a1 = _a1;
    	a2 = _a2;
    	a3 = _a3;
    	owner = msg.sender;

    	createPool(50 ether, 1, 0);
    	createPool(100 ether, 2, 0);
    	createPool(200 ether, 3, 0);
    	createPool(400 ether, 4, 0);
    	createPool(800 ether, 0, 1000 ether);
    }

    function claimBlobAuto(uint32 poolNumber, uint32 blobNumber) internal {
    	PoolInfo memory poolInfo = poolInfos[poolNumber];
    	Blob memory blob = poolBlobs[poolNumber][blobNumber];

		PoolInfo memory nextPool = poolInfos[poolInfo.nextPool];

		uint256 transferAmount = poolInfo.amount * 3;
		transferAmount -= nextPool.amount;

		if(blob.owner == address(this)) {
			DGToken.transfer(a1, transferAmount / 3);
			DGToken.transfer(a2, transferAmount / 3);
			DGToken.transfer(a3, transferAmount / 3);
		}
		else {
			if(poolInfo.penaltyAmount > 0) {
	        	(,,,,,uint32 downlines_0,,,,,) = daigon.users(blob.owner);
	        	uint32 newDownlines = downlines_0 - lastDownlineCount[blob.owner];
	        	if(downlines_0 < minimumDownline || newDownlines < repeatMinimum) {
	        		uint256 penaltyBlobsCount = poolInfo.penaltyAmount / nextPool.amount;
	        		for(uint256 i = 0; i < penaltyBlobsCount; ++i) {
	        			transferAmount -= nextPool.amount;
						addToPool(address(this), poolInfo.nextPool, 0, false);
	        		}
	        	}
	        	lastDownlineCount[blob.owner] = downlines_0;
			}
			DGToken.transfer(blob.owner, transferAmount);
		}
		emit Claimed(blob.owner, transferAmount);

		totalIncome[blob.owner] += uint128(transferAmount);

		userForcedAutoFill[blob.owner][poolNumber] = true;
		isPoolBlobClaimed[poolNumber][blobNumber] = true;

		if(poolInfo.nextPool != 0) {
			addToPool(blob.owner, poolInfo.nextPool, 0, false);
		}
		else {
			addToPool(address(this), poolInfo.nextPool, 0, false);
		}
    }

    function findUnfilledBlob(uint32 poolNumber, uint32 blobNumber, uint32 priorityBlob) internal view returns (uint32) {
    	Blob memory currentBlob = poolBlobs[poolNumber][blobNumber];
    	if(currentBlob.right == 0) return blobNumber;

    	uint32 first;
    	uint32 second;

    	if(priorityBlob == currentBlob.right) {
    		first = priorityBlob;
    		second = currentBlob.left;
    	}
    	else {
    		first = currentBlob.left;
    		second = currentBlob.right;
    	}

    	Blob memory wingBlob = poolBlobs[poolNumber][first];
    	if(wingBlob.right == 0) return first;

    	wingBlob = poolBlobs[poolNumber][second];
    	if(wingBlob.right == 0) return second;

    	revert("Group fully filled");
    }

    function findGroupToFill(uint32 poolNumber, uint32 blobNumber) public view returns (uint32) {
		Blob memory currentBlob = poolBlobs[poolNumber][blobNumber];
		require(currentBlob.owner != address(0), "Invalid Group Number");

		if(currentBlob.up != 0 && !isPoolBlobClaimed[poolNumber][currentBlob.up]) {
			Blob memory upperBlob = poolBlobs[poolNumber][currentBlob.up];
			if(upperBlob.up != 0 && !isPoolBlobClaimed[poolNumber][upperBlob.up]) {
				return findUnfilledBlob(poolNumber, upperBlob.up, currentBlob.up);
			}
			return findUnfilledBlob(poolNumber, currentBlob.up, blobNumber);
		}
		return findUnfilledBlob(poolNumber, blobNumber, blobNumber);
    }

    function addToPool(address addr, uint32 poolNumber, uint32 origBlobNumber, bool isInitial) internal returns (uint32 blobId) {

    	PoolInfo memory poolInfo = poolInfos[poolNumber];
		if(!isInitial) DGToken.transfer(stakingFunder, poolInfo.amount / 4);

		uint32 blobNumber = origBlobNumber;

		bool forced = userForcedAutoFill[addr][poolNumber];

		if(origBlobNumber != 0 && !forced) {

			blobNumber = findGroupToFill(poolNumber, blobNumber);

		}
		else if(vacantBlobs[poolNumber].length > 0) {
			uint32 vacantIndex = vacantBlobIndex[poolNumber];
			uint256 length = vacantBlobs[poolNumber].length;
			Blob memory currentBlob;
			for(uint256 i = vacantIndex; i < length; ++i) {
				blobNumber = vacantBlobs[poolNumber][i];
				currentBlob = poolBlobs[poolNumber][blobNumber];
				if(currentBlob.right == 0) {
					if(i != vacantIndex) vacantBlobIndex[poolNumber] = uint32(i);
					break;
				}
			}

			if(forced) userForcedAutoFill[addr][poolNumber] = false;
		}

		poolBlobs[poolNumber].push(Blob(addr, blobNumber, 0, 0));
        blobId = uint32(poolBlobs[poolNumber].length) - 1;
		vacantBlobs[poolNumber].push(blobId);

		userData[addr].push(poolNumber);
		userData[addr].push(blobId);

		if(blobNumber != 0) {
			Blob storage upBlob = poolBlobs[poolNumber][blobNumber];

			uint32 upupIndex = upBlob.up;
			Blob memory upupBlob = poolBlobs[poolNumber][upupIndex];

			if(upBlob.left == 0) {
				upBlob.left = blobId;
			}
			else if(upBlob.right == 0) {
				upBlob.right = blobId;

				if(upupIndex != 0) {

					Blob memory otherBlob;
					if(blobNumber == upupBlob.left) {
						otherBlob = poolBlobs[poolNumber][upupBlob.right];
					}
					else {
						otherBlob = poolBlobs[poolNumber][upupBlob.left];
					}

					if(otherBlob.right != 0) {
						claimBlobAuto(poolNumber, upupIndex);
					}
				}
			}
		}
    }

    function joinPool(uint32 poolNumber, uint32 origBlobNumber) public {
    	if(poolNumber != 0) {
    		require(userEnabled[msg.sender], "You need to invest on 50 DGT first.");
    	}
    	else if(!userEnabled[msg.sender]) {
    		userEnabled[msg.sender] = true;
    	}

    	PoolInfo memory poolInfo = poolInfos[poolNumber];
    	require(poolInfo.amount > 0, "Invalid Pool.");

		DGToken.governanceTransfer(msg.sender, address(this), poolInfo.amount + (poolInfo.amount * joinFee / 100));

		if(joinFee > 0) DGToken.transfer(scatterContract, poolInfo.amount * joinFee / 100);

		uint32 blobId = addToPool(msg.sender, poolNumber, origBlobNumber, false);

		emit BlobInserted(msg.sender, blobId);

		totalBoxes[msg.sender]++;
    }

    function getUserInfo(address addr) external view returns (uint128, uint32, uint32, uint32, uint96, bool) {
    	return (totalIncome[addr], lastDownlineCount[addr], minimumDownline, repeatMinimum, joinFee, userEnabled[addr]);
    }

    function getUserData(address addr) external view returns (uint32[] memory, uint32[] memory, bool[] memory) {
		uint256 length = userData[addr].length;
		uint32[] memory poolNumber = new uint32[](length / 2);
		uint32[] memory blobNumber = new uint32[](length / 2);
		bool[] memory isClaimed = new bool[](length / 2);

		for(uint256 i = 0; i < length; i+=2) {
			poolNumber[i / 2] = userData[addr][i];
			blobNumber[i / 2] = userData[addr][i + 1];
			isClaimed[i / 2] = isPoolBlobClaimed[poolNumber[i / 2]][blobNumber[i / 2]];
		}

		return (poolNumber, blobNumber, isClaimed);
    }

    function getPoolInfos() external view returns(uint128[] memory, uint96[] memory) {
		uint256 length = poolInfos.length;
		uint128[] memory amount = new uint128[](length);
		uint96[] memory penaltyAmount = new uint96[](length);

		for(uint256 i = 0; i < length; ++i) {
			amount[i] = poolInfos[i].amount;
			penaltyAmount[i] = poolInfos[i].penaltyAmount;
		}
		return (amount, penaltyAmount);
    }

    function createPool(uint128 amount, uint32 nextPool, uint96 penaltyAmount) public onlyOwner {
    	poolInfos.push(PoolInfo(amount, nextPool, penaltyAmount));
    	uint32 poolNumber = uint32(poolInfos.length) - 1;
    	poolBlobs[poolNumber].push(Blob(address(0), 0, 0, 0));

    	addToPool(address(this), poolNumber, 0, true);
    	addToPool(address(this), poolNumber, 0, true);
    	addToPool(address(this), poolNumber, 0, true);
    }

    function editPool(uint32 poolNumber, uint128 amount, uint32 nextPool, uint96 penaltyAmount) external onlyOwner {
    	poolInfos[poolNumber].amount = amount;
    	poolInfos[poolNumber].nextPool = nextPool;
    	poolInfos[poolNumber].penaltyAmount = penaltyAmount;
    }

	function changeAddress(uint256 n, address addr) external onlyOwner {
		if(n == 1) {
			a1 = addr;
		}
		else if(n == 2) {
			a2 = addr;
		}
		else if(n == 3) {
			a3 = addr;
		}
		else if(n == 4) {
			stakingFunder = addr;
		}
		else if(n == 5) {
			owner = addr;
		}
		else if(n == 6) {
			scatterContract = addr;
		}
		else if(n == 7) {
    		daigon = DAIGON(addr);
		}
	}

	function changeValue(uint256 n, uint96 value) external onlyOwner {
		if(n == 1) {
			minimumDownline = uint32(value);
		}
		else if(n == 2) {
			repeatMinimum = uint32(value);
		}
		else if(n == 3) {
			joinFee = value;
		}
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	event Claimed(address indexed user, uint256 amount);
	event BlobInserted(address indexed user, uint32 indexed number);
}

interface DAIGON {
	function users(address) external view returns (address, uint32, uint32, uint128, uint96, uint32, uint96, uint32, uint96, uint32, uint96);
}

interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function governanceTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}