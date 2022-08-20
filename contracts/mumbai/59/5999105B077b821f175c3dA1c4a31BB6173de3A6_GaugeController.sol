//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { IveToken } from "../interfaces/IveToken.sol";
import { IGauge } from "../interfaces/IGauge.sol";
import { LiquidityGauge } from "./LiquidityGauge.sol";
import { ERC20 } from "../tokens/ERC20.sol";

/// @title GaugeController
/// @notice Controls reward distribution
/// @dev Explain to a developer any extra details
contract GaugeController is Ownable {

    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
 
    event GenesisCreated(address indexed by, uint256 startTime);
    event EpochCreated(uint256 start, uint256 end, address indexed reaper);
    event RewardsTokenSet(address indexed tokenAddress, address indexed by);
    event VeTokenSet(address indexed tokenAddress, address indexed by);
    event GaugeCreated(address indexed by, uint256 startTime);
    event Voted(address indexed account, address indexed gauge, uint256 votes);
    event Rebalance(address indexed reaper, uint256 totalWeight);

    struct Epoch {
        uint256 start;
        uint256 end;
        uint256 totalVotes;
        address reaper;
    }

    struct GaugeVotes {
        address gauge;
        uint256 votes;
    }

    struct GaugeRewards {
        address gauge;
        uint256 rewards;
    }

    uint256 public constant EPOCH_LENGTH = 2 minutes; // 14 days in prod

    uint256 public constant REAPER_FEE = 15 * 1e15; // 1.5%

    /// @notice List of all the created gauges.
    address[] public gauges;

    /// @notice The number of votes a gauge has received in the current epoch.
    /// @dev This is reset to 0 each epoch.
    /// gauge address => number of votes
    mapping(address => uint256) public gaugeVotes;

    /// @notice List of all the created epochs.
    Epoch[] private _epochs;

    /// @notice Represents a percentage state of the pie. 1 WAD = 100%
    /// @dev Explain to a developer any extra details
    mapping(address => uint256) internal _currentRelativeWeight;

    IveToken public veToken;
    ERC20 public rewardsToken;

    /// @notice Keeps track on if account has claimed rewards in the current epoch.
    /// @dev Mapping: epoch number => account => claimed.
    mapping(uint256 => mapping(address => bool)) public rewardsClaimed;

    /// @notice Tracks if an account has voted in a given epoch
    /// @dev epoch number => account => voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    bool internal _isInitialized;

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Creates the first epoch.
    /// @dev Can only be called by contract owner. Can only be called once.
    /// @param startTime The start time of the first epoch. All future epochs
    /// start and end times are relative to this time. 
    function createGenesisEpoch(uint256 startTime) external onlyOwner {
        require(!_isInitialized, "GC: Genesis already created");
        _epochs.push(_createFirstEpoch(startTime));
        _isInitialized = true;
    }

    function setRewardsToken(address _rewards) external onlyOwner {
        require(_rewards != address(0), "GC: Zero address");
        rewardsToken = ERC20(_rewards);
    }

    function setVEToken(address _ve) external onlyOwner {
        require(_ve != address(0), "GC: Zero address");
        veToken = IveToken(_ve);
    }

    /// @notice Creates a new gauge which can then start to receive rewards
    /// @dev Can ony be called by owner of this contract.
    /// Gauges have to be voted on by veToken holders to receive any rewards
    function createGauge() external onlyOwner {
        require(address(veToken) != address(0) && 
        address(rewardsToken) != address(0), "GC: Zero address");
        LiquidityGauge gauge = new LiquidityGauge(rewardsToken, veToken);
        gauges.push(address(gauge));
    }

    /// @notice Returns an array of all the gauge addresses.
    /// @return g the list of gauge addresses.
    function allGauges() external view returns (address[] memory g) {
        g = gauges;
    }

    /// @notice Returns the number of gauges in existence.
    /// @return n the number of gauges.
    function numberOfGauges() external view returns (uint n) {
        n = gauges.length;
    }

    /*///////////////////////////////////////////////////////////////
                                VOTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Records an address's vote for the specified gauge.
    /// @dev An account can only vote once per epoch. The weight of the vote is the 
    /// user's current veToken balance.
    function vote(address gaugeAddress) external {
        require(_epochs.length > 0, "GC: No epochs");
        require(veToken.balanceOf(msg.sender) != 0, "GC: Zero votes");
        require(!_votedInEpoch(epochNumber()), "GC: Already voted");
        require(_isValidGauge(gaugeAddress), "GC: Invalid address");
        
        uint256 votePower = veToken.balanceOf(msg.sender);

        require(votePower > 0, "GC: No voting power");

        gaugeVotes[gaugeAddress] += votePower;
        _currentEpoch().totalVotes += votePower;
        IGauge(gaugeAddress).recordVote(msg.sender);
        hasVoted[epochNumber()][msg.sender] = true;
        emit Voted(msg.sender, gaugeAddress, votePower);
    }

    function currentEpochTotalVotes() external view returns (uint256) {
        return _currentEpoch().totalVotes;
    }

    function _votedInEpoch(uint256 epoch) internal view returns (bool) {
        return hasVoted[epoch][msg.sender];
    }

    /// @notice Checks if a specified address is a valid gauge address.
    /// @return isValid is true if `gaugeAddress` is of a valid gauge, false otherwise.
    function _isValidGauge(address gaugeAddress) internal view returns (bool isValid) {
        isValid = false;
        for (uint256 i = 0; i < gauges.length; i++) {
            if (gauges[i] == gaugeAddress) {
                isValid = true;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDS MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Allocate weights to gauges for the current epoch.
    /// @dev Can only be called once per epoch. The caller of this function specifies the
    /// address that should receive the reward for calling.
    /// This function also distributes rewards accumulated in the controller to the
    /// individual gauges, proportionally based on the votes received in current epoch.
    /// @param reaper The address that should receive reaper fees.
    function rebalance(address reaper) external {
        require(_isInitialized, "GC: Not initialized");
        Epoch storage epoch = _currentEpoch();
        require(epoch.start != 0 && epoch.end <= block.timestamp, "GC: Not ended");

        uint256 totalWeights = 0;
        for (uint256 i = 0; i < gauges.length; i++) {
            totalWeights += gaugeVotes[gauges[i]];
        }
        for (uint256 i = 0; i < gauges.length; i++) {
            address gaugeAddress = gauges[i];
            uint256 gaugeWeight = gaugeVotes[gaugeAddress];
            _currentRelativeWeight[gaugeAddress] = gaugeWeight.divWadDown(totalWeights);
        }

        _distribute(reaper);
        _epochs.push(_createEpoch(reaper));

        emit Rebalance(reaper, totalWeights);
    }

    function _distribute(address reaper) internal {
        require(_isInitialized, "GC: Not initialized");
        uint256 currentBalance = rewardsToken.balanceOf(address(this));
        uint256 reaperReward = currentBalance.mulWadDown(REAPER_FEE);
        uint256 pie = currentBalance - reaperReward;

        for (uint256 i = 0; i < gauges.length; i++) {
            address gaugeAddress = gauges[i];
            uint256 weightedWeight = _currentRelativeWeight[gaugeAddress];
            uint256 portion = pie.mulWadDown(weightedWeight); // * gauge_weight / total weights
            rewardsToken.transfer(gaugeAddress, portion);
            _resetGauge(gaugeAddress, portion);
        }
        rewardsToken.safeTransfer(reaper, reaperReward);
    }

    function _resetGauge(address gauge, uint256 portion) internal {
        uint256 pieSize = rewardsToken.balanceOf(gauge);
        IGauge(gauge).rollover(pieSize, gaugeVotes[gauge], portion.mulWadUp(EPOCH_LENGTH).divWadDown(52)); 
        gaugeVotes[gauge] = 0;
    }

    function _createFirstEpoch(uint256 startTime) internal view returns (Epoch memory epoch) {
        require(block.timestamp < startTime, "GC: Invalid start");
        uint256 endTime = startTime + EPOCH_LENGTH;
        epoch = Epoch({
            start: startTime ,
            end: endTime,
            totalVotes: 0,
            reaper: msg.sender
        });
    }

    function _createEpoch(address reaper) internal view returns (Epoch memory epoch) {
        uint256 startTime = block.timestamp;
        uint256 endTime = _currentEpoch().end + EPOCH_LENGTH;

        while (endTime < startTime) {
            endTime +=  EPOCH_LENGTH;
        }
        epoch = Epoch({
            start: startTime,
            end: endTime,
            totalVotes: 0,
            reaper: reaper
        });
    }

    function ts() public view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Explain to an end user what this does
    /// @dev Will revert if no epochs exist, which is the expected behavior.
    /// @return epoch the currnet epoch.
    function currentEpoch() external view returns (Epoch memory epoch) {
        epoch = _currentEpoch();
    }
    
    function _currentEpoch() internal view returns (Epoch storage epoch) {
        epoch = _epochs[_epochs.length - 1];
    }

    function _firstEpoch() internal view returns (Epoch storage epoch) {
        epoch = _epochs[0];
    }

    /// @notice Returns the current epoch number    .
    /// @return number The 0 based epoch number
    function epochNumber() public view returns (uint256 number) {
        if (_epochs.length == 0) {
            return 0;
        }
        number = _epochs.length - 1;
    }

    function allGaugeVotes() external view returns (GaugeVotes[] memory) {
        GaugeVotes[] memory votesByGauge = new GaugeVotes[](gauges.length);
        for (uint256 i = 0; i < gauges.length; i++) {
            GaugeVotes memory gv = GaugeVotes({
                gauge: gauges[i],
                votes: gaugeVotes[gauges[i]]
            });
            votesByGauge[i] = gv;
        }
        return votesByGauge;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma abicoder v2;

interface IveToken {

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function commit_transfer_ownership(address addr) external;
    function apply_transfer_ownership() external;
    function commit_smart_wallet_checker(address addr) external;
    function apply_smart_wallet_checker() external;
    function toggleEmergencyUnlock() external;
    function recoverERC20(address token_addr, uint256 amount) external;
    function get_last_user_slope(address addr) external view returns (int128);
    function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);
    function locked__end(address _addr) external view returns (uint256);
    function checkpoint() external;
    function deposit_for(address _addr, uint256 _value) external;
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
    function balanceOf(address addr) external view returns (uint256);
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalSupply(uint256 t) external view returns (uint256);
    function totalSupplyAt(uint256 _block) external view returns (uint256);
    function totalFXSSupply() external view returns (uint256);
    function totalFXSSupplyAt(uint256 _block) external view returns (uint256);
    function changeController(address _newController) external;
    function token() external view returns (address);
    function supply() external view returns (uint256);
    function locked(address addr) external view returns (LockedBalance memory);
    function epoch() external view returns (uint256);
    function point_history(uint256 arg0) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxs_amt);
    function user_point_history(address arg0, uint256 arg1) external view returns (int128 bias, int128 slope, uint256 ts, uint256 blk, uint256 fxs_amt);
    function user_point_epoch(address arg0) external view returns (uint256);
    function slope_changes(uint256 arg0) external view returns (int128);
    function controller() external view returns (address);
    function transfersEnabled() external view returns (bool);
    function emergencyUnlockActive() external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint256);
    function future_smart_wallet_checker() external view returns (address);
    function smart_wallet_checker() external view returns (address);
    function admin() external view returns (address);
    function future_admin() external view returns (address);
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

interface IGauge {
    function claim() external;
    function rollover(uint256 balance, uint256 weight, uint256 rate) external;
    function setRewardRate(uint256 rate) external;
    function recordVote(address account) external;
    function rewardToken() external view returns (address);
    function rewardRate() external view returns (uint256);
}

//SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.9;

import { ERC20 } from "../tokens/ERC20.sol";
import { IveToken } from "../interfaces/IveToken.sol";
import { IGauge } from "../interfaces/IGauge.sol";
import { FixedPointMathLib } from "../lib/FixedPointMathLib.sol";
import { SafeTransferLib } from "../lib/SafeTransferLib.sol";

contract LiquidityGauge is IGauge {

    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /// @notice token to be distributed on this gauge
    ERC20 internal _rewardToken;

    uint256 public _rewardRate;

    /// @notice token that tracks user voting power. 
    /// Used to determine portion of rewards user is entitled to
    IveToken public _veToken;

    address public controller;

    /// @notice Keeps track of various snapshot values.
    /// @param timestamp The snapshot time
    /// @param balance The balance at time of snapshot
    /// @param  The snapshot time
    /// @param timestamp The snapshot time
    struct GaugeSnapshot {
        uint256 timestamp;
        uint256 balance;
        uint256 weight;
        uint256 rate;
    }

    GaugeSnapshot internal empty;
    /// @notice The current snapshot
    GaugeSnapshot[] internal snapshots;

    /// @notice Keeps track on if account has claimed rewards in the current epoch.
    /// @dev Mapping: snapshot timestamp => address => claimed.
    mapping(uint256 => mapping(address => bool)) public rewardsClaimed;
    mapping(uint256 => mapping(address => uint256)) public accountVoted;

    modifier onlyController() {
        require(msg.sender == controller, "LG: Only Controller");
        _;
    }

    /// @notice Constructor
    /// @param rewards The rewards token
    /// @param ve The VE token that also represents voting power
    constructor(ERC20 rewards, IveToken ve) {
        controller = msg.sender;
        _rewardToken = rewards;
        _veToken = ve;

        _initialize();
    }

    function _initialize() internal {
        _createNewSnapshot();
    }

    /// @notice Resets the gauge's current snapshot.
    /// @dev Can only be called by the GaugeController contract.
    /// This start the new epoch where token holders can vote and accrue rewards
    function rollover(uint256 _balance, uint256 _weight, uint256 _rate) external onlyController {
        GaugeSnapshot storage current = _currentSnapshot();
        current.balance = _balance;
        current.weight = _weight;
        current.rate = _rate;

        _createNewSnapshot();
    } 

    /// @notice Records a users vote so we know who is eligible to claim rewards in the next epoch.
    /// @dev Can only be called by the GaugeController contract.
    function recordVote(address account) external onlyController {
        GaugeSnapshot memory snapshot = _currentSnapshot();
        uint256 votingPower = _veToken.balanceOf(account, snapshot.timestamp);
        accountVoted[snapshot.timestamp][account] = votingPower;
    }

    /// @notice Claims any pending rewards for the caller from this gauge.
    /// @dev Can only be called at most once successfully per epoch by each caller.
    function claim() external {
        GaugeSnapshot memory snapshot = _previousSnapshot();
        require(snapshot.weight != 0 && snapshot.balance != 0 && snapshot.timestamp != 0,
        "LG: Invalid snapshot");

        address account = msg.sender;
        uint256 vp = accountVoted[snapshot.timestamp][account];

        // check that user actually voted for this gauge
        require(vp > 0, "LG: Vote not recorded");

        // check if user has already claimed reward
        require(!rewardsClaimed[snapshot.timestamp][account], "LG: already claimed");

        rewardsClaimed[snapshot.timestamp][account] = true;
        // get snapshot at point
        // check total tokens available
        // get total votes
        // get user vote share
        // compute token share
        // transfer token share to 
        // share = voting power at snapshot / total votes for gauge
        // vp / votes for gauge * snapshotBalance
        uint256 portion = vp.mulWadDown(snapshot.weight).divWadDown(snapshot.balance);
        _rewardToken.safeTransfer(account, portion);
    }

    function claimAmount(address account) external view returns (uint256 amount, bool claimed) {
        GaugeSnapshot memory snapshot = _previousSnapshot();
        if (snapshot.timestamp == 0) {
            return (0, false);
        }

        claimed = rewardsClaimed[snapshot.timestamp][account];
        if (snapshot.balance == 0) {
            return (0, claimed);
        }
        uint256 votePower = accountVoted[snapshot.timestamp][account];
        if (votePower > 0) { // votes should use previous timestamp
            amount = votePower.mulWadDown(snapshot.weight).divWadDown(snapshot.balance); 
        } else {
            amount = 0;
        }
    }

    /// @notice Returns this address's current balance of rewards token
    function balance() external view returns (uint256 blnc) {
        blnc = _rewardToken.balanceOf(address(this));
    }

    /// @notice Returns this address's balance of rewards token at the time of the snapshot.
    /// This represents the total amount that can be claimed in this epoch.
    function snapshotBalance() external view returns (uint256) {
        return _currentSnapshot().balance;
    }

    function rewardToken() external view returns (address) {
        return address(_rewardToken);
    }

    function veToken() external view returns (address) {
        return address(_veToken);
    }

    function setRewardRate(uint256 rate) external onlyController {
        _rewardRate = rate;
    }

    function rewardRate() external view returns (uint256) {
        return _rewardRate;
    }

    function currentSnapshot() external view returns (GaugeSnapshot memory) {
        return _currentSnapshot();
    }

    function _createNewSnapshot() internal {
        GaugeSnapshot memory newSnapshot = _emptySnapshot();
        newSnapshot.timestamp = block.timestamp;
        snapshots.push(newSnapshot);
    }

    function _currentSnapshot() internal view returns (GaugeSnapshot storage) {
        return snapshots[snapshots.length - 1];
    }

    function _previousSnapshot() internal view returns (GaugeSnapshot memory) {
        if (snapshots.length <= 1) {
            return _emptySnapshot();
        }
        return snapshots[snapshots.length - 2];
    }

    function _emptySnapshot() internal pure returns (GaugeSnapshot memory) {
        return GaugeSnapshot({
            timestamp: 0,
            balance: 0,
            weight: 0,
            rate: 0
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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