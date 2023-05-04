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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OPXStaking is Initializable {
    address public owner;
    address public TOKEN_CONTRACT_ADDRESS;
    address public MAIN_CONTRACT_ADDRESS;

    mapping(address => bool) public isGovernor;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    TRC20 internal token20;
    CLUB internal club;

    uint256 public immatureUnstakeDeduction;
    bool public online;

    bool public immatureUnstakeEnabled;

    Package[] public packages;

    mapping(address => mapping(uint256 => Staker)) public stakes;

    struct Package {
        uint256 amount;
        uint256 trxAmount;
        uint16 numDays;
        uint8 growth;
        uint8 tier;
        uint8 minimumCyclecount;
        bool hidden;
        bool nonActiveCanSubscribe;
        uint96 stakeFee;
        uint96 harvestFee;
        uint96 unstakeFee;
        uint8[] activePackagesRequired;
    }

    struct Staker {
        uint64 endDate;
        uint64 lastClaim;
    }

    function initialize(
        address _owner,
        address tokenAddress,
        address clubAddress
    ) external initializer {
        owner = _owner;
        MAIN_CONTRACT_ADDRESS = clubAddress;
        TOKEN_CONTRACT_ADDRESS = tokenAddress;

        online = true;
        immatureUnstakeDeduction = 70;

        token20 = TRC20(TOKEN_CONTRACT_ADDRESS);
        club = CLUB(MAIN_CONTRACT_ADDRESS);
    }

    function setAddress(
        uint256 n,
        address addr
    ) external onlyOwner returns (bool) {
        if (n == 1) {
            TOKEN_CONTRACT_ADDRESS = addr;
            token20 = TRC20(TOKEN_CONTRACT_ADDRESS);
        } else if (n == 2) {
            MAIN_CONTRACT_ADDRESS = addr;
            club = CLUB(MAIN_CONTRACT_ADDRESS);
        }
        return true;
    }

    function isSubscribedToTier(
        address addr,
        uint256 tier
    ) internal view returns (bool) {
        uint256 length = packages.length;
        for (uint256 i = 0; i < length; ++i) {
            if (
                packages[i].tier == tier &&
                stakes[addr][i].endDate > block.timestamp
            ) return true;
        }
        return false;
    }

    function getPackage(
        address user,
        uint256 index
    )
        external
        view
        returns (Package memory, uint8[] memory, bool, uint64, uint64)
    {
        bool canSubscribe = true;
        for (
            uint256 i = 0;
            i < packages[index].activePackagesRequired.length;
            ++i
        ) {
            if (
                !isSubscribedToTier(
                    user,
                    packages[index].activePackagesRequired[i]
                )
            ) {
                canSubscribe = false;
                break;
            }
        }
        if (canSubscribe) {
            if (!packages[index].nonActiveCanSubscribe) {
                (, , uint32 expiration, ) = club.users(user);
                if (expiration < block.timestamp) {
                    canSubscribe = false;
                }
            }
        }

        return (
            packages[index],
            packages[index].activePackagesRequired,
            canSubscribe,
            stakes[msg.sender][index].endDate,
            stakes[msg.sender][index].lastClaim
        );
    }

    function makeStake(uint256 index) external payable returns (bool) {
        require(online, "Contract is offline.");

        (, uint32 join_date, uint32 expiration, ) = club.users(msg.sender);
        require(join_date > 0, "Only members can stake.");

        require(packages.length > index, "Out of bound.");
        Package memory package = packages[index];

        if (!package.nonActiveCanSubscribe) {
            require(
                expiration > block.timestamp,
                "Only active members can stake."
            );
        }

        require(!package.hidden, "Package is already hidden.");
        require(
            stakes[msg.sender][index].endDate == 0,
            "Claim the package first before staking again."
        );

        require(
            msg.value >= package.trxAmount + package.stakeFee,
            "Insufficient amount"
        );

        require(
            club.getUserDownlinesLength(msg.sender) >=
                package.minimumCyclecount,
            "Minimum cyclecount not met."
        );

        uint256 length = package.activePackagesRequired.length;
        for (uint256 i = 0; i < length; ++i) {
            require(
                isSubscribedToTier(
                    msg.sender,
                    package.activePackagesRequired[i]
                ),
                "Requirements not met."
            );
        }

        token20.governanceTransfer(msg.sender, address(this), package.amount);

        uint256 maturityDate = block.timestamp + (package.numDays * 1 days);
        stakes[msg.sender][index].endDate = uint64(maturityDate);

        emit Staked(msg.sender, index, maturityDate);

        return true;
    }

    function claim(uint256 index) public payable returns (bool) {
        Package memory package = packages[index];
        require(msg.value >= package.harvestFee, "Insufficient unstake fee.");
        require(packages.length > index, "Out of bound.");

        require(
            stakes[msg.sender][index].endDate != 0,
            "You haven't bought this package yet."
        );
        require(
            block.timestamp < stakes[msg.sender][index].endDate,
            "Unstake the package."
        );

        uint256 duration = package.numDays * 1 days;

        uint256 startDate = stakes[msg.sender][index].endDate - duration;

        uint256 lastClaimTime = startDate > stakes[msg.sender][index].lastClaim
            ? startDate
            : stakes[msg.sender][index].lastClaim;

        require(
            block.timestamp - lastClaimTime > 1 days,
            "You can only claim daily."
        );

        token20.transfer(
            msg.sender,
            (((package.amount * package.growth) / 100) *
                (block.timestamp - lastClaimTime)) / duration
        );

        stakes[msg.sender][index].lastClaim = uint64(block.timestamp);
        emit Claim(msg.sender, index);
        return true;
    }

    function unstake(uint256 index) public payable returns (bool) {
        require(packages.length > index, "Out of bound.");
        Package memory package = packages[index];

        require(
            stakes[msg.sender][index].endDate != 0,
            "You haven't bought this package yet."
        );
        require(msg.value >= package.unstakeFee, "Insufficient unstake fee.");

        require(
            stakes[msg.sender][index].endDate < block.timestamp,
            "You can't unstake yet."
        );

        uint256 duration = package.numDays * 1 days;

        uint256 startDate = stakes[msg.sender][index].endDate - duration;

        uint256 lastClaimTime = startDate > stakes[msg.sender][index].lastClaim
            ? startDate
            : stakes[msg.sender][index].lastClaim;

        uint256 time = block.timestamp > stakes[msg.sender][index].endDate
            ? stakes[msg.sender][index].endDate
            : block.timestamp;

        payable(msg.sender).transfer(package.trxAmount);
        token20.transfer(
            msg.sender,
            package.amount +
                ((((package.amount * package.growth) / 100) *
                    (time - lastClaimTime)) / duration)
        );

        stakes[msg.sender][index].endDate = 0;

        emit Unstaked(msg.sender, index);

        return true;
    }

    function immatureUnstake(uint256 index) external payable returns (bool) {
        if (stakes[msg.sender][index].endDate < block.timestamp) {
            return unstake(index);
        }

        require(packages.length > index, "Out of bound.");
        Package memory package = packages[index];

        require(
            stakes[msg.sender][index].endDate != 0,
            "You haven't bought this package yet."
        );
        require(msg.value >= package.unstakeFee, "Insufficient unstake fee.");

        uint256 duration = package.numDays * 1 days;

        uint256 startDate = stakes[msg.sender][index].endDate - duration;

        uint256 lastClaimTime = startDate > stakes[msg.sender][index].lastClaim
            ? startDate
            : stakes[msg.sender][index].lastClaim;

        uint256 time = block.timestamp > stakes[msg.sender][index].endDate
            ? stakes[msg.sender][index].endDate
            : block.timestamp;

        uint256 trxAmount = (package.trxAmount * immatureUnstakeDeduction) /
            100;
        uint256 amount = (package.amount * immatureUnstakeDeduction) / 100;

        payable(msg.sender).transfer(trxAmount);
        token20.transfer(
            msg.sender,
            amount +
                ((((package.amount * package.growth) / 100) *
                    (time - lastClaimTime)) / duration)
        );

        stakes[msg.sender][index].endDate = 0;

        emit Unstaked(msg.sender, index);

        return true;
    }

    event Staked(
        address indexed staker,
        uint256 indexed id,
        uint256 maturityDate
    );
    event Unstaked(address indexed staker, uint256 indexed id);
    event Claim(address indexed staker, uint256 indexed id);

    // Operators

    function addPackage(
        uint256 amount,
        uint256 trxAmount,
        uint8 growth,
        uint16 numDays,
        uint8 tier,
        uint8 minimumCyclecount,
        uint8[] memory activePackagesRequired,
        bool nonActiveCanSubscribe,
        uint96 stakeFee,
        uint96 harvestFee,
        uint96 unstakeFee
    ) public onlyGovernors returns (bool) {
        packages.push(
            Package(
                amount,
                trxAmount,
                numDays,
                growth,
                tier,
                minimumCyclecount,
                false,
                nonActiveCanSubscribe,
                stakeFee,
                harvestFee,
                unstakeFee,
                activePackagesRequired
            )
        );
        return true;
    }

    function tweakPackage(
        uint256 packageID,
        uint256 index,
        uint256 newValue
    ) public onlyGovernors {
        if (index == 1) {
            packages[packageID].amount = newValue;
        } else if (index == 2) {
            packages[packageID].trxAmount = newValue;
        } else if (index == 3) {
            packages[packageID].growth = uint8(newValue);
        } else if (index == 4) {
            packages[packageID].numDays = uint16(newValue);
        } else if (index == 5) {
            packages[packageID].tier = uint8(newValue);
        } else if (index == 6) {
            packages[packageID].minimumCyclecount = uint8(newValue);
        } else if (index == 7) {
            packages[packageID].hidden = newValue == 1;
        } else if (index == 8) {
            packages[packageID].nonActiveCanSubscribe = newValue == 1;
        }
    }

    function tweakPackageMultiple(
        uint256 packageID,
        uint256[] memory indexes,
        uint256[] memory values
    ) public onlyGovernors returns (bool) {
        uint256 length = indexes.length;
        uint256 index;
        for (uint256 i = 0; i < length; ++i) {
            index = indexes[i];
            if (index == 1) {
                packages[packageID].amount = values[i];
            } else if (index == 2) {
                packages[packageID].trxAmount = values[i];
            } else if (index == 3) {
                packages[packageID].growth = uint8(values[i]);
            } else if (index == 4) {
                packages[packageID].numDays = uint16(values[i]);
            } else if (index == 5) {
                packages[packageID].tier = uint8(values[i]);
            } else if (index == 6) {
                packages[packageID].minimumCyclecount = uint8(values[i]);
            } else if (index == 7) {
                packages[packageID].hidden = values[i] == 1;
            } else if (index == 8) {
                packages[packageID].nonActiveCanSubscribe = values[i] == 1;
            } else if (index == 9) {
                packages[packageID].stakeFee = uint96(values[i]);
            } else if (index == 10) {
                packages[packageID].harvestFee = uint96(values[i]);
            } else if (index == 11) {
                packages[packageID].unstakeFee = uint96(values[i]);
            }
        }
        return true;
    }

    function tweakActivePackagesRequired(
        uint256 packageID,
        uint8[] memory activePackagesRequired
    ) public onlyGovernors returns (bool) {
        packages[packageID].activePackagesRequired = activePackagesRequired;
        return true;
    }

    function setOnline(bool value) public onlyGovernors returns (bool) {
        online = value;
        return true;
    }

    function tweakSettings(uint256 index, uint256 value) public onlyGovernors {
        if (index == 1) {
            immatureUnstakeDeduction = value;
        } else if (index == 2) {
            immatureUnstakeEnabled = value == 1;
        }
    }

    function withdrawToken(uint256 amount) external onlyOwner returns (bool) {
        token20.transfer(msg.sender, amount);
        return true;
    }

    function withdrawTrx(uint256 amount) external onlyOwner returns (bool) {
        payable(owner).transfer(amount);
        return true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyGovernors() {
        require(
            isGovernor[msg.sender] == true || msg.sender == owner,
            "Not a governor."
        );
        _;
    }

    function giveGovernance(address governor) public onlyOwner {
        isGovernor[governor] = true;
    }

    function revokeGovernance(address governor) public onlyOwner {
        isGovernor[governor] = false;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface TRC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function governanceTransfer(
        address owner,
        address buyer,
        uint256 numTokens
    ) external returns (bool);
}

interface CLUB {
    function users(
        address
    ) external view returns (address, uint32, uint32, uint32);

    function getUserDownlinesLength(address) external view returns (uint256);
}