// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./BountyProxy.sol";
import "./IBountyProxyFactory.sol";
import "./BountyPool.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BountyProxyFactory is Ownable, Initializable {
    using Clones for address;
    /// PUBLIC STORAGE ///

    address public bountyProxyBase;

    address public manager;

    uint256 public constant VERSION = 1;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping to track all deployed proxies.
    mapping(address => bool) internal _proxies;

    function initiliaze(address payable _bountyProxyBase, address _manager)
        external
        initializer
        onlyOwner
    {
        bountyProxyBase = _bountyProxyBase;
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    function deployBounty(address _beacon, bytes memory _data)
        public
        onlyManager
        returns (BountyPool proxy)
    {
        proxy = BountyPool(bountyProxyBase.clone());

        BountyProxy newBounty = BountyProxy(payable(address(proxy)));
        newBounty.initialize(_beacon, _data, msg.sender);
        // proxy.initializeImplementation(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts/contracts/proxy/Proxy.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BountyProxy is Proxy, ERC1967Upgrade, Initializable {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    function initialize(
        address _beaconAddress,
        bytes memory _data,
        address _manager
    ) external payable initializer {
        // require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _upgradeBeaconToAndCall(_beaconAddress, _data, false);
        _changeAdmin(_manager);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual override {
        // access control
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual override {
        // access control
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender);
        _fallback();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./BountyProxy.sol";
import "./BountyPool.sol";

/// @title IBountyProxyFactory
/// @notice Deploys new proxies with CREATE2.
interface IBountyProxyFactory {
    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Mapping to track all deployed proxies.
    /// @param proxy The address of the proxy to make the check for.
    function isProxy(address proxy) external view returns (bool result);

    /// @notice The release version of PRBProxy.
    /// @dev This is stored in the factory rather than the proxy to save gas for end users.
    function VERSION() external view returns (uint256);

    // /// @notice Deploys a new proxy for a given owner and returns the address of the newly created proxy
    // /// @param _projectWallet The owner of the proxy.
    // /// @return proxy The address of the newly deployed proxy contract.
    function deployBounty(
        address _beacon,
        address _projectWallet,
        bytes memory _data
    ) external returns (BountyPool proxy);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "./SaloonWallet.sol";

//  OBS: Better suggestions for calculating the APY paid on a fortnightly basis are welcomed.

contract BountyPool is Ownable, Initializable {
    using SafeERC20 for IERC20;
    //#################### State Variables *****************\\

    address public manager;

    uint256 public constant VERSION = 1;
    uint256 public constant BOUNTY_COMMISSION = 10 * 1e18;
    uint256 public constant PREMIUM_COMMISSION = 2 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;
    uint256 public constant YEAR = 365 days;

    uint256 public projectDeposit;

    uint256 public saloonBountyCommission;

    uint256 public saloonPremiumFees;
    uint256 public premiumBalance;
    uint256 public desiredAPY;
    uint256 public poolCap;
    uint256 public lastTimePaid;
    uint256 public requiredPremiumBalancePerPeriod;
    uint256 public poolPeriod = 2 weeks;

    // staker => last time premium was claimed
    mapping(address => uint256) public lastClaimed;
    // staker address => StakingInfo array
    mapping(address => StakingInfo[]) public staker;

    // staker address => amount => timelock time
    mapping(address => mapping(uint256 => TimelockInfo)) public stakerTimelock;

    mapping(uint256 => TimelockInfo) public poolCapTimelock;
    mapping(uint256 => TimelockInfo) public APYTimelock;
    mapping(uint256 => TimelockInfo) public withdrawalTimelock;

    struct StakingInfo {
        uint256 stakeBalance;
        uint256 balanceTimeStamp;
    }

    struct APYperiods {
        uint256 timeStamp;
        uint256 periodAPY;
    }

    struct TimelockInfo {
        uint256 timelock;
        bool executed;
    }

    address[] public stakerList;

    APYperiods[] public APYrecords;

    StakingInfo[] public stakersDeposit;

    bool public APYdropped;

    //#################### State Variables End *****************\\

    function initializeImplementation(address _manager) public initializer {
        manager = _manager;
    }

    //#################### Modifiers *****************\\

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    modifier onlyManagerOrSelf() {
        require(
            msg.sender == manager || msg.sender == address(this),
            "Only manager or self allowed"
        );
        _;
    }

    //#################### Modifiers END *****************\\

    //#################### Functions *******************\\

    // ADMIN PAY BOUNTY public
    // this implementation uses investors funds first before project deposit,
    // future implementation might use a more hybrid and sophisticated splitting of costs.
    function payBounty(
        address _token,
        address _saloonWallet,
        address _hunter,
        uint256 _amount
    ) public onlyManager returns (bool) {
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length - 1;

        // cache list
        address[] memory stakersList = stakerList;
        // cache length
        uint256 length = stakersList.length;

        // check if stakersDeposit is enough
        if (stakersDeposits[stakingLenght].stakeBalance >= _amount) {
            // decrease stakerDeposit
            stakersDeposits[stakingLenght].stakeBalance -= _amount;
            // push new value to array
            StakingInfo memory stakingInfo;
            stakingInfo.balanceTimeStamp = block.timestamp;
            stakingInfo.stakeBalance = stakersDeposits[stakingLenght]
                .stakeBalance;

            // if staker deposit == 0
            // check new pushed value
            if (stakersDeposits[stakingLenght].stakeBalance == 0) {
                for (uint256 i; i < length; ++i) {
                    // update StakingInfo struct
                    StakingInfo memory newInfo;
                    newInfo.balanceTimeStamp = block.timestamp;
                    newInfo.stakeBalance = 0;

                    address stakerAddress = stakersList[i];
                    staker[stakerAddress].push(newInfo);

                    // deduct saloon commission and transfer
                    calculateCommissioAndTransferPayout(
                        _token,
                        _hunter,
                        _saloonWallet,
                        _amount
                    );
                }

                // update stakersDeposit
                stakersDeposit.push(stakingInfo);
                // clean stakerList array
                delete stakerList;
                return true;
            }
            // calculate percentage of stakersDeposit
            uint256 percentage = _amount /
                stakersDeposits[stakingLenght].stakeBalance;
            // loop through all stakers and deduct percentage from their balances
            for (uint256 i; i < length; ++i) {
                address stakerAddress = stakersList[i];
                uint256 arraySize = staker[stakerAddress].length - 1;
                uint256 oldStakerBalance = staker[stakerAddress][arraySize]
                    .stakeBalance;

                // update StakingInfo struct
                StakingInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakeBalance =
                    oldStakerBalance -
                    ((oldStakerBalance * percentage) / DENOMINATOR);

                staker[stakerAddress].push(newInfo);
            }
            // push to
            stakersDeposit.push(stakingInfo);

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            return true;
        } else {
            // reset baalnce of all stakers
            for (uint256 i; i < length; ++i) {
                // update StakingInfo struct
                StakingInfo memory newInfo;
                newInfo.balanceTimeStamp = block.timestamp;
                newInfo.stakeBalance = 0;

                address stakerAddress = stakersList[i];
                staker[stakerAddress].push(newInfo);
            }
            // clean stakerList array
            delete stakerList;
            // if stakersDeposit not enough use projectDeposit to pay the rest
            uint256 remainingCost = _amount -
                stakersDeposits[stakingLenght].stakeBalance;
            // descrease project deposit by the remaining amount
            projectDeposit -= remainingCost;

            // set stakers deposit to 0
            StakingInfo memory stakingInfo;
            stakingInfo.balanceTimeStamp = block.timestamp;
            stakingInfo.stakeBalance = stakersDeposits[stakingLenght]
                .stakeBalance;
            stakersDeposit.push(stakingInfo);

            // deduct saloon commission and transfer
            calculateCommissioAndTransferPayout(
                _token,
                _hunter,
                _saloonWallet,
                _amount
            );

            return true;
        }
    }

    function calculateCommissioAndTransferPayout(
        address _token,
        address _hunter,
        address _saloonWallet,
        uint256 _amount
    ) internal returns (bool) {
        // deduct saloon commission
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // transfer to hunter
        IERC20(_token).safeTransfer(_hunter, hunterPayout);
        // transfer commission to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonCommission);

        return true;
    }

    // ADMIN HARVEST FEES public
    function collectSaloonPremiumFees(address _token, address _saloonWallet)
        external
        onlyManager
        returns (uint256)
    {
        // send current fees to saloon address
        IERC20(_token).safeTransfer(_saloonWallet, saloonPremiumFees);
        uint256 totalCollected = saloonPremiumFees;
        // reset claimable fees
        saloonPremiumFees = 0;

        return totalCollected;
    }

    // PROJECT DEPOSIT
    // project must approve this address first.
    function bountyDeposit(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // transfer from project account
        IERC20(_token).safeTransferFrom(_projectWallet, address(this), _amount);

        // update deposit variable
        projectDeposit += _amount;

        return true;
    }

    function schedulePoolCapChange(uint256 _newPoolCap) external onlyManager {
        poolCapTimelock[_newPoolCap].timelock = block.timestamp + poolPeriod;
        poolCapTimelock[_newPoolCap].executed = false;
    }

    // PROJECT SET CAP
    function setPoolCap(uint256 _amount) external onlyManager {
        // check timelock if current poolCap != 0
        if (poolCap != 0) {
            // Check If queued check time has passed && its hasnt been executed && timestamp cant be =0
            require(
                poolCapTimelock[_amount].timelock < block.timestamp &&
                    poolCapTimelock[_amount].executed == false &&
                    poolCapTimelock[_amount].timelock != 0,
                "Timelock not set or not completed"
            );
            // set executed to true
            poolCapTimelock[_amount].executed = true;
        }

        poolCap = _amount;
    }

    function scheduleAPYChange(uint256 _newAPY) external onlyManager {
        poolCapTimelock[_newAPY].timelock = block.timestamp + poolPeriod;
        poolCapTimelock[_newAPY].executed = false;
    }

    // PROJECT SET APY
    // project must approve this address first.
    // project will have to pay upfront cost of full period on the first time.
    // this will serve two purposes:
    // 1. sign of good faith and working payment system
    // 2. if theres is ever a problem with payment the initial premium deposit can be used as a buffer so users can still be paid while issue is fixed.
    function setDesiredAPY(
        address _token,
        address _projectWallet,
        uint256 _desiredAPY // make sure APY has right amount of decimals (1e18)
    ) external onlyManager returns (bool) {
        // check timelock if current APY != 0
        if (desiredAPY != 0) {
            // Check If queued check time has passed && its hasnt been executed && timestamp cant be =0
            require(
                APYTimelock[_desiredAPY].timelock < block.timestamp &&
                    APYTimelock[_desiredAPY].executed == false &&
                    APYTimelock[_desiredAPY].timelock != 0,
                "Timelock not set or not completed"
            );
            // set executed to true
            APYTimelock[_desiredAPY].executed = true;
        }
        uint256 currentPremiumBalance = premiumBalance;
        uint256 newRequiredPremiumBalancePerPeriod;
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length;
        if (stakingLenght != 0) {
            if (stakersDeposits[stakingLenght - 1].stakeBalance != 0) {
                // bill all premium due before changing APY
                billPremium(_token, _projectWallet);
            }
        } else {
            // ensure there is enough premium balance to pay stakers new APY for one period
            newRequiredPremiumBalancePerPeriod =
                (((poolCap * _desiredAPY) / DENOMINATOR) / YEAR) *
                poolPeriod;
            // NOTE: this might lead to leftover premium if project decreases APY, we will see what to do about that later
            if (currentPremiumBalance < newRequiredPremiumBalancePerPeriod) {
                // calculate difference to be paid
                uint256 difference = newRequiredPremiumBalancePerPeriod -
                    currentPremiumBalance;
                // transfer to this address
                IERC20(_token).safeTransferFrom(
                    _projectWallet,
                    address(this),
                    difference
                );
                // increase premium
                premiumBalance += difference;
            }
        }

        requiredPremiumBalancePerPeriod = newRequiredPremiumBalancePerPeriod;

        // register new APYperiod
        APYperiods memory newAPYperiod;
        newAPYperiod.timeStamp = block.timestamp;
        newAPYperiod.periodAPY = _desiredAPY;
        APYrecords.push(newAPYperiod);

        // set APY
        desiredAPY = _desiredAPY;

        // loop through stakerList array and push new balance for new APY period time stamp for every staker

        address[] memory stakersList = stakerList;
        if (stakersList.length > 0) {
            uint256 length = stakersList.length - 1; // TODO this will fail before first staker. Fix like you did with position
            for (uint256 i; i < length; ) {
                address stakerAddress = stakersList[i];
                uint256 arraySize = staker[stakerAddress].length - 1;

                StakingInfo memory newInfo;
                // get last balance
                newInfo.stakeBalance = staker[stakerAddress][arraySize]
                    .stakeBalance;
                // update current time
                newInfo.balanceTimeStamp = block.timestamp;
                // push to array so user can claim it.
                staker[stakerAddress].push(newInfo);

                unchecked {
                    ++i;
                }
            }
        }
        // disable instant withdrawals
        APYdropped = false;

        return true;
    }

    function calculatePremiumOwed(
        uint256 _apy,
        uint256 _stakingLenght,
        uint256 _lastPaid,
        StakingInfo[] memory _stakersDeposits
    ) internal pure returns (uint256) {
        uint256 premiumOwed;
        for (uint256 i = _stakingLenght; i > 0; --i) {
            if (_stakersDeposits[i].balanceTimeStamp > _lastPaid) {
                // calcualte payout for every change in staking according to time
                uint256 duration = _stakersDeposits[i].balanceTimeStamp -
                    _lastPaid;
                //TODO  @audit this calculation is returning the wrong value. Too high.
                premiumOwed +=
                    ((
                        ((_stakersDeposits[i].stakeBalance * _apy) /
                            DENOMINATOR)
                    ) / YEAR) *
                    duration;
            }
            // premiumOwed += 1000;
        }
        return premiumOwed;
    }

    // PROJECT PAY weekly/monthly PREMIUM to this address
    // this address needs to be approved first
    function billPremium(address _token, address _projectWallet)
        public
        onlyManagerOrSelf
        returns (bool)
    {
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length - 1;
        uint256 lastPaid = lastTimePaid;
        uint256 apy = desiredAPY;

        // check when function was called last time and pay premium according to how much time has passed since then.
        /*
        - average variance since last paid
            - needs to take into account how long each variance is...
        - use that
        */
        // this is very granular and maybe not optimal...
        // @audit why is this function call returning zero?
        uint256 premiumOwed = calculatePremiumOwed(
            apy,
            stakingLenght,
            lastPaid,
            stakersDeposits
        );
        // uint256 premiumOwed = lastPaid;

        if (
            !IERC20(_token).safeTransferFrom(
                _projectWallet,
                address(this),
                premiumOwed
            )
        ) {
            // if transfer fails APY is reset and premium is paid with new APY
            // register new APYperiod
            APYperiods memory newAPYperiod;
            newAPYperiod.timeStamp = block.timestamp;
            newAPYperiod.periodAPY = viewcurrentAPY();
            APYrecords.push(newAPYperiod);
            // set new APY
            desiredAPY = viewcurrentAPY();
            //     // TODO EMIT EVENT??? - would have to be done in MANAGER -> check that APY before and after this call are the same

            APYdropped = true;

            return false;
        }
        // Calculate saloon fee
        uint256 saloonFee = (premiumOwed * PREMIUM_COMMISSION) / DENOMINATOR;

        // update saloon claimable fee
        saloonPremiumFees += saloonFee;

        // update premiumBalance
        premiumBalance += premiumOwed;

        lastTimePaid = block.timestamp;

        // disable instant withdrawals
        APYdropped = false;

        return true;
    }

    // PROJECT EXCESS PREMIUM BALANCE WITHDRAWAL -- NOT SURE IF SHOULD IMPLEMENT THIS
    // timelock on this?

    function scheduleprojectDepositWithdrawal(uint256 _amount)
        external
        onlyManager
        returns (bool)
    {
        withdrawalTimelock[_amount].timelock = block.timestamp + poolPeriod;
        withdrawalTimelock[_amount].executed = false;
        return true;
    }

    // PROJECT DEPOSIT WITHDRAWAL
    function projectDepositWithdrawal(
        address _token,
        address _projectWallet,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // time lock check
        // Check If queued check time has passed && its hasnt been executed && timestamp cant be =0
        require(
            withdrawalTimelock[_amount].timelock < block.timestamp &&
                withdrawalTimelock[_amount].executed == false &&
                withdrawalTimelock[_amount].timelock != 0,
            "Timelock not set or not completed"
        );
        withdrawalTimelock[_amount].executed = true;

        projectDeposit -= _amount;
        IERC20(_token).safeTransfer(_projectWallet, _amount);
        return true;
    }

    // STAKING
    // staker needs to approve this address first
    function stake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // dont allow staking if stakerDeposit >= poolCap

        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length;

        if (stakingLenght == 0) {
            StakingInfo memory init;
            init.stakeBalance = 0;
            init.balanceTimeStamp = 0;
            stakersDeposit.push(init);
        }
        uint256 positioning = stakersDeposit.length - 1;

        require(
            stakersDeposit[positioning].stakeBalance + _amount <= poolCap,
            "Staking Pool already full"
        );

        uint256 arrayLength = staker[_staker].length;

        // uint256 position = arrayLength == 0 ? 0 : arrayLength - 1;

        //  if array length is  == 0 we must push first
        if (arrayLength == 0) {
            StakingInfo memory init;
            init.stakeBalance = 0;
            init.balanceTimeStamp = 0;
            staker[_staker].push(init);
        }

        uint256 position = staker[_staker].length - 1;

        // Push to stakerList array if previous balance = 0
        if (staker[_staker][position].stakeBalance == 0) {
            stakerList.push(_staker);
        }

        // update StakingInfo struct
        StakingInfo memory newInfo;
        newInfo.balanceTimeStamp = block.timestamp;
        newInfo.stakeBalance = staker[_staker][position].stakeBalance + _amount;

        // if staker is new update array[0] created earlier
        if (arrayLength == 0) {
            staker[_staker][position] = newInfo;
        } else {
            // if staker is not new:
            // save info to storage
            staker[_staker].push(newInfo);
        }

        StakingInfo memory depositInfo;
        depositInfo.stakeBalance =
            stakersDeposit[positioning].stakeBalance +
            _amount;

        depositInfo.balanceTimeStamp = block.timestamp;

        if (stakingLenght == 0) {
            stakersDeposit[positioning] = depositInfo;
        } else {
            // push to global stakersDeposit
            stakersDeposit.push(depositInfo);
        }

        // transferFrom to this address
        IERC20(_token).safeTransferFrom(_staker, address(this), _amount);

        return true;
    }

    function scheduleUnstake(address _staker, uint256 _amount)
        external
        onlyManager
        returns (bool)
    {
        // this cant be un-initiliazed because its already been when staking
        uint256 arraySize = staker[_staker].length - 1;
        require(
            staker[_staker][arraySize].stakeBalance >= _amount,
            "Insuficcient balance"
        );

        stakerTimelock[_staker][_amount].timelock =
            block.timestamp +
            poolPeriod;
        stakerTimelock[_staker][_amount].executed = false;

        return true;
    }

    // UNSTAKING
    // allow instant withdraw if stakerDeposit >= poolCap or APY = 0%
    // otherwise have to wait for timelock period
    function unstake(
        address _token,
        address _staker,
        uint256 _amount
    ) external onlyManager returns (bool) {
        // allow for immediate withdrawal if APY drops from desired APY
        // going to need to create an extra variable for storing this when apy changes for worse
        if (desiredAPY != 0 || APYdropped == true) {
            // time lock check
            // Check If queued check time has passed && its hasnt been executed && timestamp cant be =0
            require(
                stakerTimelock[_staker][_amount].timelock < block.timestamp &&
                    stakerTimelock[_staker][_amount].executed == false &&
                    stakerTimelock[_staker][_amount].timelock != 0,
                "Timelock not set or not completed"
            );
            stakerTimelock[_staker][_amount].executed = true;

            uint256 arraySize = staker[_staker].length - 1;

            // decrease staker balance
            // update StakingInfo struct
            StakingInfo memory newInfo;
            newInfo.balanceTimeStamp = block.timestamp;
            newInfo.stakeBalance =
                staker[_staker][arraySize].stakeBalance -
                _amount;

            address[] memory stakersList = stakerList;
            if (newInfo.stakeBalance == 0) {
                // loop through stakerlist
                uint256 length = stakersList.length;
                for (uint256 i; i < length; ) {
                    // find staker
                    if (stakersList[i] == _staker) {
                        // exchange it with last address in array
                        address lastAddress = stakersList[length - 1];
                        stakerList[length - 1] = _staker;
                        stakerList[i] = lastAddress;
                        // pop it
                        stakerList.pop();
                        break;
                    }

                    unchecked {
                        ++i;
                    }
                }
            }
            // save info to storage
            staker[_staker].push(newInfo);

            StakingInfo[] memory stakersDeposits = stakersDeposit;
            uint256 stakingLenght = stakersDeposits.length - 1;

            StakingInfo memory depositInfo;
            depositInfo.stakeBalance =
                stakersDeposits[stakingLenght].stakeBalance -
                _amount;
            depositInfo.balanceTimeStamp = block.timestamp;

            // decrease global stakersDeposit
            stakersDeposit.push(depositInfo);

            // transfer it out
            IERC20(_token).safeTransfer(_staker, _amount);

            return true;
        }
    }

    // claim premium
    /* @audit Some of this calcualtions seem to be a bit redundant:
    Why differentiate between a claim premium within a week period or a longer period?
    The `calculatePremiumToClaim` does use more gas but does it matter given that the user will
    pay for it and we will be using chains that are not super has expensive?
    */
    function claimPremium(
        address _token,
        address _staker,
        address _projectWallet
    ) external onlyManager returns (uint256, bool) {
        // how many chunks of time (currently = 2 weeks) since lastclaimed?
        uint256 lastTimeClaimed = lastClaimed[_staker];
        uint256 sinceLastClaimed = block.timestamp - lastTimeClaimed;
        uint256 paymentPeriod = poolPeriod;
        StakingInfo[] memory stakingInfo = staker[_staker];
        uint256 stakerLength = stakingInfo.length;
        // if last time premium was called > 1 period

        if (sinceLastClaimed > paymentPeriod) {
            uint256 totalPremiumToClaim = calculatePremiumToClaim(
                lastTimeClaimed,
                stakingInfo,
                stakerLength
            );
            // Calculate saloon fee
            uint256 saloonFee = (totalPremiumToClaim * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            totalPremiumToClaim -= saloonFee;
            uint256 owedPremium = totalPremiumToClaim;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billPremium(_token, _projectWallet);
                /* NOTE: if function above changes APY than accounting is going to get messed up,
                because the APY used for for new transfer will be different than APY 
                used to calculate totalPremiumToClaim.
                If function above fails then it fails... 
                */
            }

            // update premiumBalance
            premiumBalance -= totalPremiumToClaim;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        } else {
            // calculate currently owed for the week
            uint256 owedPremium = (((stakingInfo[stakerLength - 1]
                .stakeBalance * desiredAPY) / DENOMINATOR) / YEAR) * poolPeriod;
            // pay current period owed

            // Calculate saloon fee
            uint256 saloonFee = (owedPremium * PREMIUM_COMMISSION) /
                DENOMINATOR;
            // subtract saloon fee
            owedPremium -= saloonFee;

            if (!IERC20(_token).safeTransfer(_staker, owedPremium)) {
                billPremium(_token, _projectWallet);
                /* NOTE: if function above changes APY than accounting is going to get messed up,
                because the APY used for for new transfer will be different than APY 
                used to calculate totalPremiumToClaim.
                If function above fails then it fails... 
                */
            }

            // update premium
            premiumBalance -= owedPremium;

            // update last time claimed
            lastClaimed[_staker] = block.timestamp;
            return (owedPremium, true);
        }
    }

    function calculatePremiumToClaim(
        uint256 _lastTimeClaimed,
        StakingInfo[] memory _stakingInfo,
        uint256 _stakerLength
    ) internal view returns (uint256) {
        uint256 length = APYrecords.length;
        // loop through APY periods (reversely) until last missed period is found
        uint256 lastMissed;
        uint256 totalPremiumToClaim;
        for (uint256 i = length - 1; i == 0; --i) {
            if (APYrecords[i].timeStamp < _lastTimeClaimed) {
                lastMissed = i + 1;
            }
        }
        // loop through all missed periods
        for (uint256 i = lastMissed; i < length; ++i) {
            uint256 periodStart = APYrecords[i].timeStamp;
            // period end end is equal NOW for last APY that has been set
            uint256 periodEnd = APYrecords[i + 1].timeStamp != 0
                ? APYrecords[i + 1].timeStamp
                : block.timestamp;
            uint256 periodLength = periodEnd - periodStart;
            // loop through stakers balance fluctiation during this period

            uint256 periodTotalBalance;
            for (uint256 j; j < _stakerLength; ++j) {
                // check staker balance at that moment
                if (
                    _stakingInfo[j].balanceTimeStamp > periodStart &&
                    _stakingInfo[j].balanceTimeStamp < periodEnd
                ) {
                    // add it to that period total
                    periodTotalBalance += _stakingInfo[j].stakeBalance;
                    /* note: StakingInfo is updated for every user everytime 
                    APY changes. 
                    
                    */
                }
            }

            //calcualte owed APY for that period: (APY * amount / Seconds in a year) * number of seconds in X period
            totalPremiumToClaim +=
                (((periodTotalBalance * APYrecords[i + 1].periodAPY) /
                    DENOMINATOR) / YEAR) *
                periodLength;
        }

        return totalPremiumToClaim;
    }

    ///// VIEW FUNCTIONS /////

    // View currentAPY
    function viewcurrentAPY() public view returns (uint256) {
        uint256 apy = premiumBalance / poolCap;
        return apy;
    }

    // View total balance
    function viewHackerPayout() external view returns (uint256) {
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length;
        uint256 totalBalance;
        if (stakingLenght == 0) {
            totalBalance = projectDeposit;
        } else {
            totalBalance =
                projectDeposit +
                stakersDeposits[stakingLenght - 1].stakeBalance;
        }
        uint256 saloonCommission = (totalBalance * BOUNTY_COMMISSION) /
            DENOMINATOR;

        return totalBalance - saloonCommission;
    }

    function viewBountyBalance() external view returns (uint256) {
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length;
        uint256 totalBalance;
        if (stakingLenght == 0) {
            totalBalance = projectDeposit;
        } else {
            totalBalance =
                projectDeposit +
                stakersDeposits[stakingLenght - 1].stakeBalance;
        }

        return totalBalance;
    }

    // View stakersDeposit balance
    function viewStakersDeposit() external view returns (uint256) {
        StakingInfo[] memory stakersDeposits = stakersDeposit;
        uint256 stakingLenght = stakersDeposits.length;
        if (stakingLenght == 0) {
            return 0;
        } else {
            return stakersDeposit[stakingLenght - 1].stakeBalance;
        }
    }

    // View deposit balance
    function viewProjecDeposit() external view returns (uint256) {
        return projectDeposit;
    }

    // view premium balance
    function viewPremiumBalance() external view returns (uint256) {
        return premiumBalance;
    }

    // view required premium balance
    function viewRequirePremiumBalance() external view returns (uint256) {
        return requiredPremiumBalancePerPeriod;
    }

    // View APY
    function viewDesiredAPY() external view returns (uint256) {
        return desiredAPY;
    }

    // View Cap
    function viewPoolCap() external view returns (uint256) {
        return poolCap;
    }

    // View user staking balance
    function viewUserStakingBalance(address _staker)
        external
        view
        returns (uint256, uint256)
    {
        uint256 length = staker[_staker].length;
        return (
            staker[_staker][length - 1].stakeBalance,
            staker[_staker][length - 1].balanceTimeStamp
        );
    }

    //note view user current claimable premium ???

    //note view version function??

    ///// VIEW FUNCTIONS END /////
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        return true;
    }

    // THIS FUNCTION HAS BEEN EDITED TO RETURN A VALUE
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        return true;
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SaloonWallet {
    using SafeERC20 for IERC20;

    uint256 public constant BOUNTY_COMMISSION = 12 * 1e18;
    uint256 public constant DENOMINATOR = 100 * 1e18;

    address public immutable manager;

    // premium fees to collect
    uint256 public premiumFees;
    uint256 public saloonTotalBalance;
    uint256 public cummulativeCommission;
    uint256 public cummulativeHackerPayouts;

    // hunter balance per token
    // hunter address => token address => amount
    mapping(address => mapping(address => uint256)) public hunterTokenBalance;

    // saloon balance per token
    // token address => amount
    mapping(address => uint256) public saloonTokenBalance;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    // bountyPaid
    function bountyPaid(
        address _token,
        address _hunter,
        uint256 _amount
    ) external onlyManager {
        // calculate commision
        uint256 saloonCommission = (_amount * BOUNTY_COMMISSION) / DENOMINATOR;
        uint256 hunterPayout = _amount - saloonCommission;
        // update variables and mappings
        hunterTokenBalance[_hunter][_token] += hunterPayout;
        cummulativeHackerPayouts += hunterPayout;
        saloonTokenBalance[_token] += saloonCommission;
        saloonTotalBalance += saloonCommission;
        cummulativeCommission += saloonCommission;
    }

    function premiumFeesCollected(address _token, uint256 _amount)
        external
        onlyManager
    {
        saloonTokenBalance[_token] += _amount;
        premiumFees += _amount;
        saloonTotalBalance += _amount;
    }

    //
    // WITHDRAW FUNDS TO ANY ADDRESS saloon admin
    function withdrawSaloonFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyManager returns (bool) {
        require(_amount <= saloonTokenBalance[_token], "not enough balance");
        // decrease saloon funds
        saloonTokenBalance[_token] -= _amount;
        saloonTotalBalance -= _amount;

        IERC20(_token).safeTransfer(_to, _amount);

        return true;
    }

    ///////////////////////   VIEW FUNCTIONS  ////////////////////////

    // VIEW SALOON CURRENT TOTAL BALANCE
    function viewSaloonBalance() external view returns (uint256) {
        return saloonTotalBalance;
    }

    // VIEW COMMISSIONS PLUS PREMIUM
    function viewTotalEarnedSaloon() external view returns (uint256) {
        uint256 premiums = viewTotalPremiums();
        uint256 commissions = viewTotalSaloonCommission();

        return premiums + commissions;
    }

    // VIEW TOTAL PAYOUTS MADE - commission - fees
    function viewTotalHackerPayouts() external view returns (uint256) {
        return cummulativeHackerPayouts;
    }

    // view hacker payouts by hunter
    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return hunterTokenBalance[_hunter][_token];
    }

    // VIEW TOTAL COMMISSION
    function viewTotalSaloonCommission() public view returns (uint256) {
        return cummulativeCommission;
    }

    // VIEW TOTAL IN PREMIUMS
    function viewTotalPremiums() public view returns (uint256) {
        return premiumFees;
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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