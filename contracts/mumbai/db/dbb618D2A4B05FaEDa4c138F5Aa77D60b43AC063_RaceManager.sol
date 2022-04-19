// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "../../lib/solmate/src/utils/FixedPointMathLib.sol";

contract RaceManager {
    // this should be in another contract?
    enum Action {
        Boost,
        Accelerate,
        Fortify,
        Weaken,
        Halt,
        Failure,
        Poison,
        ExpMultiplier
    }

    struct Race {
        bool valid;
        uint256 raceDNA;
        uint256 raceStartingTime;
        uint256 raceDuration;
        uint256 raceDistance;
        uint256 raceCurrentStage;
        uint256 raceMaxStage;
        uint256 raceRocketLimit;
        uint256[3] raceWinners;
    }

    struct RocketRaceState {
        bool valid;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 position;
        uint256 velocity;
        uint256 acceleration;
    }

    struct RecruitmentEvent {
        uint256 recruiterId;
        uint256 recruiteeId;
        Action action;
    }

    event RaceCreated(uint256 indexed raceId, Race race);
    event RaceJoined(
        uint256 indexed raceId,
        uint256 indexed rocketId,
        uint256 rocketState
    );
    event RaceTurn(
        uint256 indexed raceId,
        uint256 indexed rocketId,
        uint256 stage
    );
    event PlayerAction(
        uint256 indexed raceId,
        uint256 stage,
        RecruitmentEvent recruitmentEvent
    );
    event RocketDefeat(
        uint256 indexed raceId,
        uint256 rocketId,
        uint256 position
    );

    uint256 raceCount = 0;

    mapping(uint256 => Race) public raceInfo;
    mapping(uint256 => uint256) public rocketInRace;
    mapping(uint256 => mapping(uint256 => RecruitmentEvent[]))
        public raceEvents; // merge with states?
    mapping(uint256 => mapping(uint256 => RocketRaceState[]))
        public raceRocketStates;

    modifier isStaked(uint256 rocketId) {
        // rocket must be staked
        _;
    }

    function createRace(Race calldata _race) public {
        raceInfo[raceCount++] = _race;
    }

    function getRaceInfo(uint256 id) public returns (Race memory) {
        return raceInfo[id];
    }

    function joinRace(uint256 raceId, uint256 rocketId) public {
        rocketInRace[rocketId] = raceId;

        raceRocketStates[raceId][rocketId].push(
            RocketRaceState({
                valid: true,
                timeStart: getRaceInfo(raceId).raceStartingTime, //now
                timeEnd: 0,
                position: 0,
                velocity: 10e18,
                acceleration: 0.11e18
            })
        );
    }

    function leaveRace(uint256 raceId, uint256 rocketId) public {
        rocketInRace[rocketId] = 0;

        raceRocketStates[raceId][rocketId][0].valid = false;
    }

    function calculateNewState(uint256 raceId, uint256 rocketId)
        public
        returns (uint256)
    {
        RocketRaceState[] memory tmpState = raceRocketStates[raceId][rocketId];
        uint256 totalDistance = 0;

        for (uint256 i = 0; i < tmpState.length; i++) {
            if (
                tmpState[i].timeEnd != 0 &&
                block.timestamp > tmpState[i].timeEnd
            ) {
                uint256 elapsed = tmpState[i].timeEnd - tmpState[i].timeStart;
                totalDistance += distance(
                    elapsed * 1e18,
                    tmpState[i].velocity,
                    tmpState[i].acceleration
                );
            } else {
                uint256 elapsed = block.timestamp - tmpState[i].timeStart;
                totalDistance += distance(
                    elapsed * 1e18,
                    tmpState[i].velocity,
                    tmpState[i].acceleration
                );
            }
        }

        return totalDistance;
    }

    function calculateState(uint256 raceId, uint256 rocketId)
        public
        returns (uint256)
    {
        RocketRaceState[] memory tmpState = raceRocketStates[raceId][rocketId];
        uint256 totalDistance = 0;

        for (uint256 i = 0; i < tmpState.length; i++) {
            uint256 timeSlot;

            if (
                i + 1 < tmpState.length &&
                tmpState[i + 1].timeStart != 0 &&
                block.timestamp > tmpState[i + 1].timeStart
            ) {
                timeSlot = tmpState[i + 1].timeStart;
            } else {
                timeSlot = block.timestamp;
            }

            uint256 elapsed = block.timestamp - tmpState[i].timeStart;

            totalDistance += distance(
                elapsed * 1e18,
                tmpState[i].velocity,
                tmpState[i].acceleration
            );
        }

        return totalDistance;
    }

    function addRocketState(
        uint256 raceId,
        uint256 rocketId,
        RocketRaceState memory state
    ) public {
        RocketRaceState[] memory tmp = raceRocketStates[raceId][rocketId];
        raceRocketStates[raceId][rocketId][tmp.length - 1].timeEnd = block
            .timestamp;
        raceRocketStates[raceId][rocketId].push(state);
    }

    function calculateCurrentDistance(uint256 raceId, uint256 rocketId)
        public
        returns (uint256)
    {
        uint256 elapsed = block.timestamp - raceInfo[raceId].raceStartingTime;

        RocketRaceState memory initial = raceRocketStates[raceId][rocketId][0];

        return distance(elapsed * 1e18, initial.velocity, initial.acceleration);
    }

    function recruitAction(
        uint256 raceId,
        uint256 stage,
        RecruitmentEvent calldata _recruitmentEvent
    ) public returns (uint256) {
        // Check recruiter is in race
        // Check recruitee is msg.sender owner
        // Check recruitee cooldown is valid
        // Check recruiter can execute a turn

        return 0;
    }

    function claimRewards(uint256 raceId, uint256 rocketId)
        public
        returns (uint256)
    {
        // Check that rocket has passed the finish line
        // Check rocket HP
        // Send appropiate prize (based on position?)
        return 0;
    }

    function distance(
        uint256 t,
        uint256 v,
        uint256 a
    ) public returns (uint256) {
        uint256 t2 = FixedPointMathLib.rpow(t, 2, 1e18);
        uint256 at2 = FixedPointMathLib.mulWadUp(a, t2);
        uint256 vt = FixedPointMathLib.mulWadUp(v, t);
        return vt + FixedPointMathLib.mulWadUp(0.5e18, at2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
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