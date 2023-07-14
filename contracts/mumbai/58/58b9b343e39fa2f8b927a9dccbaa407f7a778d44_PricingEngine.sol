/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;




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




interface TugStorageInterface {
    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardians
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;

    // Known frequent queries to reduce calldata gas
    function getPricingEngineAddress() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getTokenRegistryAddress() external view returns (address);
}




interface TokenRegistryInterface {
    /// @notice Emitted when a new token is registered with the protocol
    event TokenRegistered(string symbol, uint8 index);

    /// @notice Looks up price of given token index
    function getPrice(uint8 _index, bytes[] calldata priceUpdateData)
        external payable returns (uint256 price, uint8 decimal);

    /// @notice Obtain the symbol of a given index
    function getSymbol(uint8 _index) external returns (string calldata symbol);

    /// @notice Given a string, return the associated token index
    function getTokenIndex(string calldata _symbol)
        external
        returns (uint8 index);

    /// @notice Registers a new token for use in Tug
    /// @param _symbol Associated String for human readability
    /// @param _chainlinkOracle Chainlink oracle address to be used to get price
    /// @return index of the new token.
    // function registerToken(string calldata _symbol, address _chainlinkOracle) external returns (uint index);
}




interface PricingEngineInterface {
    /// @notice Computes the USD price per tug share, given to a predetermined decimal
    /// @param _startTime The start time of the current tug period
    /// @param _endTime The time the current tug will end
    /// @param _purchaseTime The timestamp for the given investment
    /// @param _token0StartPrice The price of token0 at the start of tug
    /// @param _token1StartPrice The price of token1 at the start of tug
    /// @param _token0Index Index of the first token
    /// @param _token1Index Index of the second token
    /// @param _buyDirection 0 if buying token0, 1 if buying token1
    /// @return price USD price per share
    function getUsdPerShare(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseTime,
        uint256 _token0StartPrice,
        uint256 _token1StartPrice,
        uint8 _token0Index,
        uint8 _token1Index,
        uint8 _buyDirection,
        bytes[] calldata priceUpdateData
    ) external payable returns (uint256 price);

    /// @notice Returns the corresponding decimals for the `getUsdPerShare()` call.
    /// @dev Seperated to save gas costs as this is not needed as a return value in the usual calculation.
    function getSharePriceDecimal() external pure returns (uint8 decimals);
}


contract PricingEngine is PricingEngineInterface {
    using FixedPointMathLib for uint256;

    TugStorageInterface public tugStorage;

    error IllegalTimeWindow(
        uint256 startTime,
        uint256 endTime,
        uint256 currentTime
    );
    error UnableToFetchPrice(uint8 tokenIndex);
    error InvalidTugSide(uint8 sideRequested);

    constructor(address tugStorageAddress) {
        tugStorage = TugStorageInterface(tugStorageAddress);
    }

    // @dev timePremium = 1  + ((currentTime - startTime) / (endTime-startTime)) * 10000
    //((current time -start time)*1000)/(end time - start time)
    function getTimePremium(
        uint256 startTime,
        uint256 endTime,
        uint256 givenCurrentTime
    ) private pure returns (uint256 timePremium) {
        if (startTime >= endTime || givenCurrentTime < startTime) {
            revert IllegalTimeWindow({
                startTime: startTime,
                endTime: endTime,
                currentTime: givenCurrentTime
            });
        }
        // givenCurrentTime can be larger than endTime, but we limit it to the endTime to cap premium calculation.
        uint256 currentTime = givenCurrentTime > endTime
            ? endTime
            : givenCurrentTime;
        timePremium = (currentTime - startTime).mulDivDown(10000, endTime - startTime);
    }

    /// @inheritdoc PricingEngineInterface
    // timePremium * (currentRatio / initialRatio) * 10e5
    // - timePremium = 1 + ((currentTime - startTime) / (endTime-startTime)) * 1
    // - currentRatio = currentTokenPrice / currentOtherTokenPrice
    // - initialRatio = initialTokenPrice / initialOtherTokenPrice
    function getUsdPerShare(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _purchaseTime,
        uint256 _token0StartPrice,
        uint256 _token1StartPrice,
        uint8 _token0Index,
        uint8 _token1Index,
        uint8 _buyDirection,
        bytes[] calldata priceUpdateData
    ) external payable override returns (uint256 price) {
        if (_buyDirection > 1) revert InvalidTugSide(_buyDirection);
        TokenRegistryInterface tokenRegistry = TokenRegistryInterface(
            tugStorage.getTokenRegistryAddress()
        );
        (uint256 token0Price, ) = tokenRegistry.getPrice(_token0Index, priceUpdateData);
        if (token0Price == 0) revert UnableToFetchPrice(_token0Index);
        (uint256 token1Price, ) = tokenRegistry.getPrice(_token1Index, priceUpdateData);
        if (token1Price == 0) revert UnableToFetchPrice(_token1Index);
        uint256 timePremium = getTimePremium(
            _startTime,
            _endTime,
            _purchaseTime
        ); 
        uint256 thisTokenCurrentPrice;
        uint256 thisTokenInitialPrice;
        uint256 thatTokenCurrentPrice;
        uint256 thatTokenInitialPrice;
        if (_buyDirection == 0) {
            thisTokenCurrentPrice = token0Price;
            thisTokenInitialPrice = _token0StartPrice;
            thatTokenCurrentPrice = token1Price;
            thatTokenInitialPrice = _token1StartPrice;
        } else {
            thisTokenCurrentPrice = token1Price;
            thisTokenInitialPrice = _token1StartPrice;
            thatTokenCurrentPrice = token0Price;
            thatTokenInitialPrice = _token0StartPrice;
        }
        uint256 initialRatio = thisTokenInitialPrice.mulDivDown(
            10000,
            thatTokenInitialPrice
        );
        uint256 currentRatio = thisTokenCurrentPrice.mulDivDown(
            10000,
            thatTokenCurrentPrice
        );
        price = timePremium.mulDivUp(currentRatio, initialRatio);
    }

    /// @inheritdoc PricingEngineInterface
    function getSharePriceDecimal() external pure returns (uint8 decimals) {
        // Implemented via multiplier in getUsdPerShare(). Remember to update if that changes.
        decimals = 5;
    }
}