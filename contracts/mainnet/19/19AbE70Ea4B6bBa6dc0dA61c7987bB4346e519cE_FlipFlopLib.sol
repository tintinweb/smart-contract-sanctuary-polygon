// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./Compute.sol";
import "../vaults/FlipFlopVaults/storage/Storage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library FlipFlopLib {
    using Compute for uint256;

    address public constant ZERO_ADDRESS = address(0);

    struct AssetDetails {
        address asset1;
        address asset2;
        uint8 decimalsOfAsset1;
        uint8 decimalsOfAsset2;
        uint256 S_E;
        uint256 S_U;
    }

    /// @notice Computes A, weather it will be asset 1 which will be swapped, or asset 2 which will get swapped
    /// @param S The public swap rate
    /// @param E Total Amount Of Asset 1
    /// @param U Total Amount Of Asset 2
    /// @return A The final value A to be send to swap vault
    /// @return decimals The number of decimals for A
    /// @return asset The asset to be swapped
    function computeA(
        uint256 S,
        uint256 E,
        uint256 U,
        address asset1,
        address asset2,
        uint8 decimalsOfAsset1,
        uint8 decimalsOfAsset2
    )
        external
        pure
        returns (
            uint256 A,
            uint8 decimals,
            address asset
        )
    {
        if (
            _isAsset1PriceGreaterThanAsset2(
                S,
                E,
                U,
                decimalsOfAsset1,
                decimalsOfAsset2
            )
        ) {
            // A=(E-U/S)/2
            A =
                (E -
                    Compute.divPrice(
                        U,
                        decimalsOfAsset2,
                        S,
                        18,
                        decimalsOfAsset1
                    )) /
                2;

            decimals = decimalsOfAsset1;
            asset = asset1;
        } else {
            // A=(U-S*E)/2
            A =
                (U -
                    Compute.mulPrice(
                        E,
                        decimalsOfAsset1,
                        S,
                        18,
                        decimalsOfAsset2
                    )) /
                2;
            decimals = decimalsOfAsset2;
            asset = asset2;
        }
    }

    /// @notice public function to check which asset is in excess, asset 1 or asset 2
    /// @param S The public swap rate
    /// @param E The amount of Asset 1
    /// @param U The amount of Asset 2
    /// @return :true if S*E > U. false otherwise.
    function _isAsset1PriceGreaterThanAsset2(
        uint256 S,
        uint256 E,
        uint256 U,
        uint8 decimalsOfAsset1,
        uint8 decimalsOfAsset2
    ) public pure returns (bool) {
        return
            Compute.scaleDecimals(
                S.wadMul(E),
                decimalsOfAsset1,
                decimalsOfAsset2
            ) > U;
    }

    /// @dev calculates amounts to withdraw or locked amount (which should not be used for option writing)

    /// @return amounts which can (will) be withdrawn
    function calcLockedAmount(
        Storage.User memory user,
        uint256 minDepositOfAsset1,
        uint256 minDepositOfAsset2
    ) external pure returns (uint256, uint256) {
        uint256 amountOfAsset1ToWithdraw = 0;
        uint256 amountOfAsset2ToWithdraw = 0;
        //if there is a requested amount
        if (
            (user.queuedAmountOfAsset1ToWithdraw *
                user.queuedAmountOfAsset2ToWithdraw ==
                0) &&
            (user.queuedAmountOfAsset1ToWithdraw +
                user.queuedAmountOfAsset2ToWithdraw >
                0)
        ) {
            //if asset1 was requested
            if (user.queuedAmountOfAsset1ToWithdraw > 0) {
                //if after withdrawal/locking, the amount of asset1 remains less than min deposit of asset1 - withdraw
                //all funds
                amountOfAsset1ToWithdraw = user.amountOfAsset1 <
                    minDepositOfAsset1 + user.queuedAmountOfAsset1ToWithdraw
                    ? user.amountOfAsset1
                    : user.queuedAmountOfAsset1ToWithdraw;
                //calc the amount of asset2 to withdraw/lock
                //slither-disable-next-line divide-before-multiply
                amountOfAsset2ToWithdraw =
                    (user.amountOfAsset2 * amountOfAsset1ToWithdraw) /
                    user.amountOfAsset1;
                //if after withdrawal/locking, the amount of asset2 remains less than min deposit of asset2
                if (
                    user.amountOfAsset2 <
                    amountOfAsset2ToWithdraw + minDepositOfAsset2
                ) {
                    //withdraw all funds
                    amountOfAsset2ToWithdraw = user.amountOfAsset2;
                    //also a whole amount of asset2, because above amountOfAsset1ToWithdraw can be not equal _amountOfAsset1
                    amountOfAsset1ToWithdraw = user.amountOfAsset1;
                }
            } else {
                //asset2 was requested
                //if after withdrawal/locking, the amount of asset2 remains less than min deposit of asset2 - withdraw all
                //funds
                amountOfAsset2ToWithdraw = user.amountOfAsset2 <
                    minDepositOfAsset2 + user.queuedAmountOfAsset2ToWithdraw
                    ? user.amountOfAsset2
                    : user.queuedAmountOfAsset2ToWithdraw;
                //calc the amount of asset1 to withdraw/lock
                amountOfAsset1ToWithdraw =
                    (user.amountOfAsset1 * amountOfAsset2ToWithdraw) /
                    user.amountOfAsset2;
                //if after withdrawal/locking, the amount of asset1 remains less than min deposit of asset1
                if (
                    user.amountOfAsset1 <
                    minDepositOfAsset1 + amountOfAsset1ToWithdraw
                ) {
                    //withdraw all funds
                    amountOfAsset1ToWithdraw = user.amountOfAsset1;
                    //also a whole amount of asset1, because above amountOfAsset2ToWithdraw can be not equal _amountOfAsset2
                    amountOfAsset2ToWithdraw = user.amountOfAsset2;
                }
            }
        }

        return (amountOfAsset1ToWithdraw, amountOfAsset2ToWithdraw);
    }

    /// @notice Function to calcuate performance fee for the epoch
    /// @param E_O The balance of asset1 in the vault at the start of the epoch immediately before the option mint
    /// @param E_v Amount of asset 1 after expiry, before withdrawal and deposit
    /// @param U_O The balance of asset2 in the vault at the start of the epoch immediately before the option mint
    /// @param U_v Amount of asset 2 after expiry, before withdrawal and deposit
    /// @param _price Price in terms of asset2/asset1, 8 digits only
    /// @return asset1PerformanceFee Amount of asset 1 to be charged ( can be +ve or -ve )
    /// @return asset2PerformanceFee Amount of asset 2 to be charged ( can be +ve or -ve )
    function calculatePerformanceFee(
        uint256 E_O,
        uint256 E_v,
        uint256 U_O,
        uint256 U_v,
        address asset1,
        address asset2,
        uint256 _price
    )
        public
        view
        returns (uint256 asset1PerformanceFee, uint256 asset2PerformanceFee)
    {
        if (E_O < E_v && U_O < U_v) {
            asset1PerformanceFee = (E_v - E_O) / 10; // calculated fee in asset1
            asset2PerformanceFee = (U_v - U_O) / 10; // calculated fee in asset2
        } else if (E_O >= E_v && U_O >= U_v) {
            asset1PerformanceFee = 0;
            asset2PerformanceFee = 0;
        } else {
            E_v = Compute._scaleAssetAmountTo18(asset1, E_v);
            E_O = Compute._scaleAssetAmountTo18(asset1, E_O);
            U_v = Compute._scaleAssetAmountTo18(asset2, U_v);
            U_O = Compute._scaleAssetAmountTo18(asset2, U_O);
            uint256 price = Compute.scaleDecimals(_price, 8, 18);

            if (
                E_v >= E_O &&
                U_O >= U_v &&
                ((E_v - E_O) > ((U_O - U_v).wadDiv(price)))
            ) {
                asset1PerformanceFee =
                    ((E_v - E_O) - ((U_O - U_v).wadDiv(price))) /
                    10;
                asset2PerformanceFee = 0;
            } else if (
                U_v >= U_O &&
                E_O >= E_v &&
                ((U_v - U_O) > ((E_O - E_v).wadMul(price)))
            ) {
                asset1PerformanceFee = 0;
                asset2PerformanceFee =
                    ((U_v - U_O) - ((E_O - E_v).wadMul(price))) /
                    10;
            } else {
                asset1PerformanceFee = 0;
                asset2PerformanceFee = 0;
            }

            asset1PerformanceFee = Compute._unscaleAssetAmountToOriginal(
                asset1,
                asset1PerformanceFee
            );
            asset2PerformanceFee = Compute._unscaleAssetAmountToOriginal(
                asset2,
                asset2PerformanceFee
            );
        }
    }

    /// @notice verifies conditions to deposit funds from the creditor to the debitor's
    // account in the Vault
    /// @param whiteList whitelist contract address
    /// @param _fromUser  - debitor address
    /// @param _toUser - creditor address
    function checkDeposit(
        IMasterWhitelist whiteList,
        Storage.FlipFlopStates vaultState,
        address _fromUser,
        address _toUser
    ) external view {
        require(whiteList.isUserWhitelisted(_fromUser), "e14");
        require(whiteList.isUserWhitelisted(_toUser), "e15");
        require(vaultState == Storage.FlipFlopStates.EpochOnGoing, "e24");
    }

    /// @notice verifies conditions to make a withdraw of current balance
    function verifyWithdrawCurrentBalance(
        Storage.User memory user,
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw,
        address asset1,
        address asset2,
        IMasterWhitelist whiteList,
        Storage.FlipFlopStates vaultState
    ) external view returns (bool) {
        require(vaultState == Storage.FlipFlopStates.EpochOnGoing, "e24");
        require(
            _amountOfAssetToWithdraw > 0,
            "Withdrawal amount should be positive"
        );
        require(!whiteList.isUserBlacklisted(msg.sender), "e30");

        bool isFirstAsset = _assetToWithdraw == asset1;

        require(
            isFirstAsset || (_assetToWithdraw == asset2),
            "Incorrect asset to withdraw"
        );

        require(
            user.amountOfAsset1 * user.amountOfAsset2 > 0,
            "You don't have funds to withdraw"
        );

        return isFirstAsset;
    }

    function verifyInitializeWithdraw(
        Storage.User memory user,
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw,
        address asset1,
        address asset2,
        IMasterWhitelist whiteList,
        Storage.FlipFlopStates vaultState
    ) external view returns (bool) {
        require(vaultState == Storage.FlipFlopStates.EpochOnGoing, "e43");
        require(
            _amountOfAssetToWithdraw > 0,
            "_amountOfAssetToWithdraw should be positive"
        );
        require(!whiteList.isUserBlacklisted(msg.sender), "e30");
        bool isAsset1 = _assetToWithdraw == asset1;
        require(
            isAsset1 || (_assetToWithdraw == asset2),
            "Wrong asset to withdraw"
        );
        require(user.user != ZERO_ADDRESS, "User doesn't have deposit");
        return isAsset1;
    }

    /// @notice verifies conditions to complete a withdrawal
    /// @param whiteList whitelist address
    /// @param currentRound current round when completeWithdraw is called
    /// @param vaultState vault state when completeWithdraw is called
    function verifyCompleteWithdraw(
        Storage.User memory user,
        IMasterWhitelist whiteList,
        uint256 currentRound,
        Storage.FlipFlopStates vaultState
    ) external view {
        require(vaultState == Storage.FlipFlopStates.EpochOnGoing, "e43");
        require(!whiteList.isUserBlacklisted(msg.sender), "e30");
        require(user.user != ZERO_ADDRESS, "User doesn't have deposit");
        require(
            (user.queuedAmountOfAsset1ToWithdraw > 0) ||
                (user.queuedAmountOfAsset2ToWithdraw > 0),
            "Queued withdraw wasn't requested in the previous round"
        );
        require(
            user.roundWhenQueuedWithdrawalWasRequested < currentRound,
            "Withdraw can be done after end of the current round"
        );
    }

    /// @notice function that calculates inversePrice = 1/_price
    /// @param _price - price to inverse
    /// @return inversePrice with oracleDecimals
    function inversePrice(uint256 _price, uint8 oracleDecimals)
        public
        pure
        returns (uint256)
    {
        //we should do price = 1\_price
        //we will return value with same decimals as oracleDecimals
        //so inverseOne = 10 ** oracleDecimals
        //but price can be very close to inverseOne as calculated above
        //(for instance, price = 99999999, reverseOne = 100000000)
        //so, only reverseOne is not enough
        //we introduce mult = 10 ** (oracleDecimals * 2)
        return ((10**(oracleDecimals << 1)) / _price);
    }

    /// @notice get spot price of asset1/asset2
    /// @dev function takes account of if an oracle price should be inverted, including additional oracle if it is set
    /// @return spot price with oracle decimals
    function getSpotPrice(
        AggregatorV3Interface chainLinkPriceOracle,
        AggregatorV3Interface additionalChainLinkPriceOracle,
        bool isReverseQuote,
        bool isReverseAdditionalQuote,
        uint8 oracleDecimals,
        uint8 additionalOracleDecimals
    ) external view returns (uint256) {
        //get the oracle price
        (, int256 price, , , ) = chainLinkPriceOracle.latestRoundData();
        require(price > 0, "e11");
        uint256 uPrice = uint256(price);

        //invert the oracle price if it should be inverted
        if (isReverseQuote) {
            uPrice = inversePrice(uPrice, oracleDecimals);
        }
        //if an additional oracle is set
        if (address(additionalChainLinkPriceOracle) != ZERO_ADDRESS) {
            //get the additional oracle price
            (, int256 additionalPrice, , , ) = additionalChainLinkPriceOracle
                .latestRoundData();
            require(additionalPrice > 0, "e12");
            uint256 uAdditionalPrice = uint256(additionalPrice);
            //if the additional oracle price should be inverted
            if (isReverseAdditionalQuote) {
                //invert the additional oracle price
                uAdditionalPrice = inversePrice(
                    uAdditionalPrice,
                    additionalOracleDecimals
                );
            }
            //set final price. We need to remove additionalOracleDecimals because this decimals were added during mul
            uPrice =
                (uPrice * uAdditionalPrice) /
                (10**additionalOracleDecimals);
        }
        return uPrice;
    }

    /// @notice verifies conditions before a user deposits MATIC to the vault
    /// @return bool true if asset1 is MATIC, false if it's asset2
    function checkDepositMaticArgs(
        address asset1,
        address asset2,
        address WMATIC,
        IMasterWhitelist whiteList,
        address _toUser,
        uint256 totalAmountOfAsset1,
        uint256 totalAmountOfAsset2,
        uint256 minDepositOfAsset1,
        uint256 minDepositOfAsset2,
        uint256 maxCapOfAsset1,
        uint256 maxCapOfAsset2,
        Storage.FlipFlopStates vaultState
    ) external returns (bool) {
        require((asset1 == WMATIC) || (asset2 == WMATIC), "e16");
        require(whiteList.isUserWhitelisted(msg.sender), "e14");
        require(whiteList.isUserWhitelisted(_toUser), "e15");
        require(vaultState == Storage.FlipFlopStates.EpochOnGoing, "e24");
        bool asset1IsMATIC = asset1 == WMATIC;
        require(
            (asset1IsMATIC && (msg.value >= minDepositOfAsset1)) ||
                (!asset1IsMATIC && (msg.value >= minDepositOfAsset2)),
            "e17"
        );
        require(
            (asset1IsMATIC &&
                (msg.value + totalAmountOfAsset1 <= maxCapOfAsset1)) ||
                (!asset1IsMATIC &&
                    (msg.value + totalAmountOfAsset2 <= maxCapOfAsset2)),
            "e18"
        );

        return asset1IsMATIC;
    }

    function _computeUserValues(
        Storage.Swap memory temp,
        Storage.User memory user,
        AssetDetails memory assetDetails
    ) public pure returns (uint256, uint256) {
        uint256 e = user.amountOfAsset1;
        uint256 u = user.amountOfAsset2;

        e = Compute.scaleDecimals(e, assetDetails.decimalsOfAsset1, 18);
        u = Compute.scaleDecimals(u, assetDetails.decimalsOfAsset2, 18);

        assetDetails.S_E = Compute.scaleDecimals(
            assetDetails.S_E,
            assetDetails.decimalsOfAsset1,
            18
        );
        assetDetails.S_U = Compute.scaleDecimals(
            assetDetails.S_U,
            assetDetails.decimalsOfAsset2,
            18
        );

        if (temp.asset == assetDetails.asset1) {
            temp.A = Compute.scaleDecimals(
                temp.A,
                assetDetails.decimalsOfAsset1,
                18
            );
            temp.A_S = Compute.scaleDecimals(
                temp.A_S,
                assetDetails.decimalsOfAsset1,
                18
            );

            if (Compute.wadMul(e, temp.S) > u) {
                uint256 UbyS = u.wadDiv(temp.S);

                uint256 stack = temp.S1.wadMul(temp.A_S);
                {
                    uint256 SmulS_E;
                    if (assetDetails.S_E < temp.A) {
                        if ((temp.A - assetDetails.S_E) < 10)
                            SmulS_E = temp.S.wadMul(temp.A - assetDetails.S_E);
                        else {
                            revert("Unexpected: S_E < A");
                        }
                    } else {
                        SmulS_E = temp.S.wadMul(assetDetails.S_E - temp.A); // A <= S_E always, so this is just a small precision issue
                    }
                    stack = stack.wadDiv(assetDetails.S_E);
                    stack = (SmulS_E).wadDiv(assetDetails.S_E) + stack;
                }

                uint256 S_EMinusA = assetDetails.S_E + temp.A_S - temp.A;

                // e1=e-0.5*(e-u/S)*(S_E - A + A_S)/S_E
                user.amountOfAsset1 =
                    e -
                    ((e - UbyS).wadMul(S_EMinusA).wadDiv(assetDetails.S_E)) /
                    2;
                // u1=u+0.5*((e-u/S)*(S*(S_E-A)/S_E)+S1*A_S/S_E)
                user.amountOfAsset2 = u + (e - UbyS).wadMul(stack) / 2;
            } else {
                uint256 uDivS;
                uint256 eMulS;

                {
                    uDivS = u.wadDiv(temp.S);
                    eMulS = e.wadMul(temp.S);
                }

                // e1=e+0.5*(u/S-e)
                user.amountOfAsset1 = e + (uDivS - e) / 2;
                // u1=u-0.5*(u-e*S)
                user.amountOfAsset2 = u - (u - eMulS) / 2;
            }
        } else {
            temp.A = Compute.scaleDecimals(
                temp.A,
                assetDetails.decimalsOfAsset2,
                18
            );
            temp.A_S = Compute.scaleDecimals(
                temp.A_S,
                assetDetails.decimalsOfAsset2,
                18
            );

            if (temp.S.wadMul(e) > u) {
                // e1=e-0.5*(e-u/S)
                user.amountOfAsset1 = e - (e - u.wadDiv(temp.S)) / 2;
                // u1=u+0.5*(e*S-u)
                user.amountOfAsset2 = u + (e.wadMul(temp.S) - u) / 2;
            } else {
                uint256 EtoU = e.wadMul(temp.S);
                uint256 stack;

                {
                    uint256 S_UToAsset1 = (assetDetails.S_U.wadMul(temp.S1));

                    uint256 divValue = assetDetails.S_U.wadMul(temp.S);

                    if (assetDetails.S_U < temp.A) {
                        if ((temp.A - assetDetails.S_U) < 10)
                            // withing precision difference
                            stack = (temp.A - assetDetails.S_U).wadDiv(
                                divValue
                            );
                        else {
                            revert("Unexpected: S_U < A");
                        }
                    } else {
                        stack = (assetDetails.S_U - temp.A).wadDiv(divValue); // A <= S_E always, so this is just a small precision issue
                    }

                    stack += temp.A_S.wadDiv(S_UToAsset1);
                }

                // e1=e+0.5*(u-e*S)*((S_U-A)/(S_U*S)+A_S/(S_U*S1))
                user.amountOfAsset1 = e + ((((u - EtoU).wadMul(stack))) / 2);

                // u1=u-0.5*(u-e*S)*(S_U - A + A_S)/S_U
                user.amountOfAsset2 =
                    u -
                    ((u - EtoU).wadMul(assetDetails.S_U + temp.A_S - temp.A))
                        .wadDiv(assetDetails.S_U) /
                    2;
            }
        }

        user.amountOfAsset1 = Compute.scaleDecimals(
            user.amountOfAsset1,
            18,
            assetDetails.decimalsOfAsset1
        );

        user.amountOfAsset2 = Compute.scaleDecimals(
            user.amountOfAsset2,
            18,
            assetDetails.decimalsOfAsset2
        );

        return (user.amountOfAsset1, user.amountOfAsset2);
    }

    /**
     * @dev require that the given number is within uint104 range
     */
    function assertUint104(uint256 num) public pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    /// @notice verifies Cap parameters
    function checkSetCap(
        uint256 _minDepositOfAsset1,
        uint256 _maxCapOfAsset1,
        uint256 _minDepositOfAsset2,
        uint256 _maxCapOfAsset2
    ) external pure {
        require(
            (_maxCapOfAsset1 != 0) &&
                (_maxCapOfAsset2 != 0) &&
                (_minDepositOfAsset1 != 0) &&
                (_minDepositOfAsset2 != 0),
            "e9"
        );

        require(
            (_minDepositOfAsset1 <= _maxCapOfAsset1) &&
                (_minDepositOfAsset2 <= _maxCapOfAsset2),
            "e10"
        );
        //Fundamental Vaults don't accept amounts which exceed uint104
        assertUint104(_maxCapOfAsset1);
        assertUint104(_maxCapOfAsset2);
        assertUint104(_minDepositOfAsset1);
        assertUint104(_minDepositOfAsset2);
    }

    function checkComputeNewDeposit(
        Storage.Swap memory temp,
        Storage.User memory user
    ) external pure {
        require(user.user != address(0), "User address is address(0)");
        require(temp.S > 0, "e25");
        require(temp.S1 > 0, "e26");
        require(user.amountOfAsset1 > 0, "e27");
        require(user.amountOfAsset2 > 0, "e28");
    }

    function verifyInternalSwap(
        Storage.FlipFlopStates vaultState,
        uint256 totalAmountOfAsset1,
        uint256 totalAmountOfAsset2,
        uint256 S1
    ) external pure {
        require(
            vaultState ==
                Storage.FlipFlopStates.InternalRatioComputationToBeDone,
            "State not set to internal swap computation"
        );
        require(totalAmountOfAsset1 > 0, "e33");
        require(totalAmountOfAsset2 > 0, "e34");
        require(S1 > 0, "e35");
    }

    /// @notice verifies FlipFlop initialization parameters
    function checkInitVault(
        address _asset1,
        address _asset2,
        ITrufinThetaVault _fundamentalVault1,
        ITrufinThetaVault _fundamentalVault2,
        IMasterWhitelist _whiteList,
        ISwapVault _swapVault,
        address _wmaticAddress
    ) external view {
        require(
            address(_whiteList) != ZERO_ADDRESS,
            "WhiteList address is address(0)"
        );
        require(
            address(_swapVault) != ZERO_ADDRESS,
            "swapVault address is address(0)"
        );
        require(_wmaticAddress != ZERO_ADDRESS, "WMATIC address is address(0)");
        require((_asset1 != ZERO_ADDRESS) && (_asset2 != ZERO_ADDRESS), "e2");
        require(
            (address(_fundamentalVault1) != ZERO_ADDRESS) &&
                (address(_fundamentalVault2) != ZERO_ADDRESS),
            "e3"
        );
        //read parameters of the fundamental vault1;
        Vault.VaultParams memory vaultParams1 = _fundamentalVault1
            .vaultParams();
        //read parameters of the fundamental vault2;
        Vault.VaultParams memory vaultParams2 = _fundamentalVault2
            .vaultParams();
        require(vaultParams1.underlying == vaultParams2.underlying, "e4");
        require(vaultParams1.isPut != vaultParams2.isPut, "e5");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./WadRay.sol";

library Compute {
    using WadRayMath for uint256;

    function mulPrice(
        uint256 _price1,
        uint8 _decimals1,
        uint256 _price2,
        uint8 _decimals2,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _decimals1;
        uint8 multiplier2 = 18 - _decimals2;
        uint8 outMultiplier = 18 - _outDecimals;

        _price1 *= 10**multiplier;
        _price2 *= 10**multiplier2;

        uint256 output = _price1.wadMul(_price2);

        return output / (10**outMultiplier);
    }

    function divPrice(
        uint256 _numerator,
        uint8 _numeratorDecimals,
        uint256 _denominator,
        uint8 _denominatorDecimals,
        uint8 _outDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier = 18 - _numeratorDecimals;
        uint8 multiplier2 = 18 - _denominatorDecimals;
        uint8 outMultiplier = 18 - _outDecimals;
        _numerator *= 10**multiplier;
        _denominator *= 10**multiplier2;

        uint256 output = _numerator.wadDiv(_denominator);
        return output / (10**outMultiplier);
    }

    function scaleDecimals(
        uint256 value,
        uint8 _oldDecimals,
        uint8 _newDecimals
    ) internal pure returns (uint256) {
        uint8 multiplier;
        if (_oldDecimals > _newDecimals) {
            multiplier = _oldDecimals - _newDecimals;
            return value / (10**multiplier);
        } else {
            multiplier = _newDecimals - _oldDecimals;
            return value * (10**multiplier);
        }
    }

    function wadDiv(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadDiv(value2);
    }

    function wadMul(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        return value1.wadMul(value2);
    }

    function _scaleAssetAmountTo18(address _asset, uint256 _originalAmount)
        internal
        view
        returns (uint256)
    {
        uint8 decimals = IERC20Metadata(_asset).decimals();
        uint256 scaledAmount;
        if (decimals <= 18) {
            scaledAmount = _originalAmount * (10**(18 - decimals));
        } else {
            scaledAmount = _originalAmount / (10**(decimals - 18));
        }
        return scaledAmount;
    }

    function _unscaleAssetAmountToOriginal(
        address _asset,
        uint256 _scaledAmount
    ) internal view returns (uint256) {
        uint8 decimals = IERC20Metadata(_asset).decimals();
        uint256 unscaledAmount;
        if (decimals <= 18) {
            unscaledAmount = _scaledAmount / (10**(18 - decimals));
        } else {
            unscaledAmount = _scaledAmount * (10**(decimals - 18));
        }
        return unscaledAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../../interfaces/ITrufinThetaVault.sol";
import "../../../interfaces/ISwapVault.sol";
import "../../../interfaces/IMasterWhitelist.sol";

/// @title Storage
contract Storage is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct User {
        uint256 amountOfAsset1;
        uint256 amountOfAsset2;
        uint256 numberOfShares;
        uint256 queuedAmountOfAsset1ToWithdraw;
        uint256 queuedAmountOfAsset2ToWithdraw;
        uint256 roundWhenQueuedWithdrawalWasRequested;
        address user;
        uint256 reservedValue1;
        uint256 reservedValue2;
        uint256 reservedValue3;
        uint256 reservedValue4;
        uint256 reservedValue5;
    }

    /// @param S - The internal swap price
    /// @param S1 - The amount at which the real swap took place with the MM.
    /// @param S2 - The midway market price
    /// @param A - The amount of asset 1 or 2 that is send to the vault for swap
    /// @param A_S - The amount of asset 1 or 2 that actually got swapped
    struct Swap {
        uint256 S; // asset from to asset 2
        uint256 S1; // ||
        uint256 S2; // ||
        uint256 A_S; // in asset from
        uint256 A; // asset from
        address asset;
        uint256 amountOfAsset1BeforeSending;
        uint256 amountOfAsset2BeforeSending;
    }

    uint256 public maxCapOfAsset1;
    uint256 public minDepositOfAsset1;
    uint256 public totalAmountOfAsset1;
    uint256 internal totalLockedAmountOfAsset1;
    uint256 public maxCapOfAsset2;
    uint256 public minDepositOfAsset2;
    uint256 public totalAmountOfAsset2;
    uint256 internal totalLockedAmountOfAsset2;
    //slither-disable-next-line uninitialized-state
    uint256 internal currentRound;

    uint256 public internalSwapAsset1;
    uint256 public internalSwapAsset2;

    uint256 internal S_E;
    uint256 internal S_U;

    // Amount of usdc without current deposit, i.e. what was left in the vault from the previous vault
    uint256 internal e_V;
    // Amount of usdc without current deposit, i.e. what was left in the vault from the previous vault
    uint256 internal u_V;

    uint256 internal n_T; // Total amount of shares in the contract ( == 10**18 constant )
    uint256 internal e_o; // Amount of funds received at the end of epoch for asset 1
    uint256 internal u_o; // Amount of funds received at the end of epoch for asset 2

    ITrufinThetaVault public fundamentalVault1;
    ITrufinThetaVault public fundamentalVault2;
    address public asset1;
    address public asset2;
    address internal keeper;
    address internal treasuryAddress;
    uint8 internal decimalsOfAsset1;
    uint8 internal decimalsOfAsset2;

    bytes32 poolIdAsset1ToAsset2;
    bytes32 poolIdAsset2ToAsset1;

    ISwapVault swapVault;

    //slither-disable-next-line uninitialized-state
    IMasterWhitelist internal whiteList;

    /// @notice stores the request id from the swap vault
    bytes32 internal requestId;

    /// @notice users who were whitelisted before swap and minting
    mapping(address => bool) whiteListedUsers;

    enum FlipFlopStates {
        EpochOnGoing,
        PerformanceFeeNeedsToBeCharged,
        UserLastEpochFundsNeedsToBeRedeemed,
        SwapNeedsToTakePlace,
        SwapIsInProgress,
        InternalRatioComputationToBeDone,
        FundsToBeSendToFundamentalVaults,
        CalculateS_EAndS_U,
        MintUserShares,
        ContractIsPaused
    }

    FlipFlopStates internal vaultState;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library WadRayMath {
    uint256 public constant WAD = 1e18;
    uint256 public constant halfWAD = WAD / 2;

    uint256 public constant RAY = 1e27;
    uint256 public constant halfRAY = RAY / 2;

    uint256 public constant WAD_RAY_RATIO = 1e9;

    function ray() public pure returns (uint256) {
        return RAY;
    }

    function wad() public pure returns (uint256) {
        return WAD;
    }

    function halfRay() public pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() public pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) public pure returns (uint256) {
        return (halfWAD + (a * b)) / (WAD);
    }

    function wadDiv(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 halfB = b / 2;

        return (halfB + (a * WAD)) / (b);
    }

    function rayMul(uint256 a, uint256 b) public pure returns (uint256) {
        return (halfRAY + (a * b)) / (RAY);
    }

    function rayDiv(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 halfB = b / 2;

        return (halfB + (a * (RAY))) / (b);
    }

    function rayToWad(uint256 a) public pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return (halfRatio + a) / (WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) public pure returns (uint256) {
        return a * WAD_RAY_RATIO;
    }

    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) public pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {Vault} from "../libraries/Vault.sol";

interface ITrufinThetaVault {
    // Getter function of Vault.OptionState.currentOption
    // Option that the vault is currently shorting / longing
    function currentOption() external view returns (address);

    // Getter function of Vault.OptionState.nextOption
    // Option that the vault is shorting / longing in the next cycle
    function nextOption() external view returns (address);

    // Getter function of struct Vault.VaultParams
    function vaultParams() external view returns (Vault.VaultParams memory);

    // Getter function of struct Vault.VaultState
    function vaultState() external view returns (Vault.VaultState memory);

    // Getter function of struct Vault.OptionParams
    function optionState() external view returns (Vault.OptionState memory);

    // Getter function which returs gammaController
    function GAMMA_CONTROLLER() external view returns (address);

    // Returns the Gnosis AuctionId of this vault option
    function optionAuctionID() external view returns (uint256);

    function withdrawInstantly(uint256 amount) external;

    function completeWithdraw() external returns (uint256 withdrawAmount);

    function initiateWithdraw(uint256 numShares) external;

    function shares(address account) external view returns (uint256);

    function deposit(uint256 amount) external;

    function accountVaultBalance(address account)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface ISwapVault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    enum PoolStatus {
        INACTIVE,
        WAITING_FOR_RATE,
        UNLOCKED,
        LOCKED,
        EMERGENCY
    }

    // toLockedAmount -- never change
    // fromLiquidAmount
    // toLiquidAmount

    struct SwapPool {
        PoolStatus status; // Current Status of the Pool
        address assetFrom; // Address of the asset which needs to be swapped
        address assetTo; // Address of the asset which the assetFrom is being swapped to
        uint256 lastLockedTime; // the most recent time this pool was locked
        uint256 fromLiquidAmount; // amount of liquid funds in the pool in assetFrom
        uint256 toLiquidAmount; // amount of liquid funds in the pool in assetTo
        uint256 originalAmount; // total amount of deposits in the pool in assetFrom
        uint256 internalSwapRate; // Spot Rate S, at which internal swap happens
        uint256 aggregateSwapRate; // Spot Rate S1, which is aggregated from both internal and external swaps
        uint256 toLockedAmount; // Total Amount of assetTo which was swapped in internal Rebalancing
        uint256 totalAmountSwappedinFrom; // Total amount of assetFrom which was swapped successfully
        uint256 midSwapRate; // Mid Swap Rate S2
        bytes32[] requestIds; // Array of requestIds pending in the pool
        uint256[] orderIds; // Array of orderIds pending in the pool
    }

    // User will receive
    // totalAmountSwappedinFrom * aggregateSwapRate = amount of assetTo
    // originalAmount - totalAmountSwappedinFrom =  amount of assetFrom
    // aggregateSwapRate
    // midSwapRate
    struct SwapRequest {
        address userAddress; // Address of the user who made the deposit
        bytes32 poolId; // Id of the pool to which the deposit belongs
        uint256 amount; // Amount of deposit (in assetFrom)
    }

    struct SwapOrder {
        bool isReverseOrder; // True if swap is from assetTo to assetFrom
        bytes32 MMId; // ID of MM who can fill swap order
        bytes32 poolId; // ID of pool from which funds are swapped
        uint256 amount; // Amount of funds to be swapped ( in assetFrom or assetTo depending on isReverseOrder)
        uint256 rate; // Swap Rate at which swap is offered
    }

    function getPoolId(address assetFrom, address assetTo)
        external
        returns (bytes32);

    function deposit(bytes32 _poolId, uint256 _amount)
        external
        returns (bytes32);

    function fillSwapOrder(uint256 orderId) external;

    function withdrawInstantly(bytes32 requestId, uint256 _amount) external;

    function emergencyWithdraw(bytes32 requestId) external;

    function getInternalSwapRate(bytes32 poolId)
        external
        view
        returns (uint256);

    function getAssetFromRequestId(bytes32 requestId)
        external
        view
        returns (
            address,
            address,
            bytes32
        );

    /************************************************
     *  EVENTS
     ***********************************************/
    event DepositAsset(address asset, address from, uint256 _amount);
    event SetInternalSwapRate(
        bytes32 poolId,
        uint256 swapRate,
        uint256 oppositSwapRate
    );
    event SetMidSwapRate(
        bytes32 poolId,
        uint256 swapRate,
        uint256 oppositSwapRate
    );
    event PoolStatusChange(bytes32 indexed poolId, PoolStatus status);
    event ResetPool(bytes32 indexed poolId, PoolStatus status);
    event DeleteSwapRequest(bytes32 indexed poolId, bytes32 requestId);
    event AddSwapPool(
        bytes32 indexed poolId,
        bytes32 indexed oppPoolId,
        address from,
        address to
    );
    event CreatedSwapOrder(
        uint256 indexed orderId,
        bytes32 indexed poolId,
        bool isReverseOrder,
        bytes32 mmId,
        uint256 amount,
        uint256 rate
    );
    event FilledSwapOrder(
        uint256 indexed orderId,
        bytes32 indexed poolId,
        bytes32 mmId
    );
    event DeleteSwapOrder(bytes32 indexed poolId, uint256 orderId);
    event DeleteSwapPool(bytes32 indexed poolId, bytes32 indexed oppPoolId);
    event EmergencyWithdraw(bytes32 indexed poolId, bytes32 requestId);
    event Withdrawn(bytes32 indexed poolId, bytes32 requestId, uint256 amount);

    event CloseAllPoolOrders(bytes32 indexed poolId);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @dev Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    /// @dev Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    /// @dev Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    /// @dev Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    /// @dev Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /// @dev struct for vault general data
    struct VaultParams {
        /// @dev Option type the vault is selling
        bool isPut;
        /// @dev Token decimals for vault shares
        uint8 decimals;
        /// @dev Asset used in Theta Vault
        address asset;
        /// @dev deprecated: Underlying asset of the options sold by vault
        address underlying;
        /// @dev Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        /// @dev Vault cap
        uint104 cap;
    }

    /// @dev struct for vault state of the options sold and the timelocked option
    struct OptionState {
        /// @dev deprecated: Option that the vault is shorting / longing in the next cycle
        // todo: remove before a new deployment
        address unused;
        /// @dev Option that the vault is currently shorting / longing
        address currentOption;
        /// @dev deprecated: The timestamp when the `nextOption` can be used by the vault
        // todo: remove before a new deployment
        uint32 unused2;
        /// @dev The timestamp when the `nextOption` will expire
        uint256 currentOptionExpirationAt;
    }

    /// @dev struct for vault accounting state
    struct VaultState {
        /**
         * @dev 32 byte slot 1
         * Current round number. `round` represents the number of `period`s elapsed.
         */
        uint16 round;
        /// @dev Amount that is currently locked for selling options
        uint104 lockedAmount;
        /**
         * @dev Amount that was locked for selling options in the previous round
         * used for calculating performance fee deduction
         */
        uint104 lastLockedAmount;
        /**
         * @dev 32 byte slot 2
         * Stores the total tally of how much of `asset` there is
         * to be used to mint rTHETA tokens
         */
        uint128 totalPending;
        /// @dev Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
    }

    //todo: make it without mapping and use mapping in code
    /// @dev struct for fee rebate for whitelisted vaults depositings
    struct VaultFee {
        /// @dev Amount for whitelisted vaults
        mapping(uint16 => uint256) whitelistedVaultAmount;
        /// @dev Fees not to recipient fee recipient: Will be sent to the vault at complete
        mapping(uint16 => uint256) feesNotSentToRecipient;
    }

    /// @dev struct for pending deposit for the round
    struct DepositReceipt {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        /// @dev Unredeemed shares balance
        uint128 unredeemedShares;
    }

    /// @dev struct for pending withdrawals
    struct Withdrawal {
        /// @dev Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        /// @dev Number of shares withdrawn
        uint128 shares;
    }

    /// @dev struct for auction sell order
    struct AuctionSellOrder {
        /// @dev Amount of `asset` token offered in auction
        uint96 sellAmount;
        /// @dev Amount of oToken requested in auction
        uint96 buyAmount;
        /// @dev User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}