// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./OptionsVault.sol";

contract FlipFlop is OptionsVault {
    // event Initialized(address indexed swapVault, address indexed whitelist);

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev init the contract. Should be called from main contract in the initializer function
    /// @param _asset1 - address of asset1
    /// @param _asset2 - address of asset2
    /// @param _fundamentalVault1 - address of the fundamental Vault1
    /// @param _fundamentalVault2 - address of the fundamental Vault2
    /// @param _chainLinkPriceOracle - address of the chainLink oracle;
    /// @param _isReverseQuote - indicates that the price of the chainLink oracle should be inverted
    /// @param _additionalChainLinkPriceOracle - address of an additional chainLink oracle if it is needed
    /// @param _isReverseAdditionalQuote -indicates that the price of the additional chainLink oracle should be
    /// inverted
    /// @param _whiteList - address of the whitelist
    /// @param _swapVault - address of swapVault contract
    /// @param _wmaticAddress - address of WMATIC token
    function initialize(
        address _asset1,
        address _asset2,
        ITrufinThetaVault _fundamentalVault1,
        ITrufinThetaVault _fundamentalVault2,
        address _chainLinkPriceOracle,
        bool _isReverseQuote,
        address _additionalChainLinkPriceOracle,
        bool _isReverseAdditionalQuote,
        IMasterWhitelist _whiteList,
        ISwapVault _swapVault,
        address _wmaticAddress
    ) public initializer {
        //init BaseDoubleLinkedList
        list.last = LinkedListLib.HEAD;
        list.iterationCountLimit = 115;
        //OZ-contracts initialization
        __ReentrancyGuard_init_unchained();
        __Ownable_init_unchained();
        FlipFlopLib.checkInitVault(
            _asset1,
            _asset2,
            _fundamentalVault1,
            _fundamentalVault2,
            _whiteList,
            _swapVault,
            _wmaticAddress
        );

        fundamentalVault1 = _fundamentalVault1;
        fundamentalVault2 = _fundamentalVault2;
        //slither-disable-next-line missing-zero-check
        asset1 = _asset1;
        //slither-disable-next-line missing-zero-check
        asset2 = _asset2;
        //read decimals of asset1
        decimalsOfAsset1 = IERC20Metadata(_asset1).decimals();
        //read decimals of asset2
        decimalsOfAsset2 = IERC20Metadata(_asset2).decimals();
        setChainLinkOracles(
            _chainLinkPriceOracle,
            _isReverseQuote,
            _additionalChainLinkPriceOracle,
            _isReverseAdditionalQuote
        );
        //slither-disable-next-line missing-zero-check
        WMATIC = _wmaticAddress;

        // this is considered to be the default state of the contract, deposits will work when in this
        vaultState = FlipFlopStates.EpochOnGoing;

        whiteList = _whiteList;

        swapVault = _swapVault;
        //slither-disable-next-line reentrancy-benign
        poolIdAsset1ToAsset2 = swapVault.getPoolId(asset1, asset2);
        //slither-disable-next-line reentrancy-benign
        poolIdAsset2ToAsset1 = swapVault.getPoolId(asset2, asset1);
        n_T = 10**18;
    }

    function emergencyWithdrawFromSwapVault() external {
        swapVault.emergencyWithdraw(requestId);
    }

    function updateState(FlipFlopStates newContractState) external onlyOwner {
        vaultState = newContractState;
    }
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
pragma solidity =0.8.14;

import "./Withdraw.sol";
import "../../interfaces/ITrufinVault.sol";
import "../../interfaces/GammaInterface.sol";
import "../../interfaces/IOracle.sol";

/// @title OptionsVault
/// @notice  Contract responsible for interaction with Swap and Fundamental Vaults,
/// user shares minting and performance fee charging.
contract OptionsVault is Withdraw, ITrufinVault {
    using Compute for uint256;
    using SafeERC20 for IERC20;

    /// @notice number of iterations to do per call while assigning shares
    uint256 private batchSize;
    uint256 private expirationTime;
    bool internal firstIteration;

    /// @notice swap structure storing the swap data
    Swap internal swap;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    event InternalSwapComputation(
        uint256 asset1OldPrice,
        uint256 asset1NewPrice,
        uint256 asset2OldPrice,
        uint256 asset2NewPrice
    );

    event StartEpoch(uint256 amountOfAsset1, uint256 amountOfAsset2);

    event UpdateUserShares(
        address user,
        uint256 amountOfAsset1Used,
        uint256 amountOfAsset2Used,
        uint256 sharesMinted
    );

    event NextUser(address nextUser);
    event SentSwappedFunds(address asset, uint256 amount);
    event ReceivedSwappedFunds(
        uint256 _receivedAsset1,
        uint256 receivedAsset2,
        uint256 _totalAmountOfAsset1,
        uint256 _totalAmountOfAsset2
    );

    /// @dev Throws if called by any account other than the keeper.
    function _onlyKeeperShouldCall() private {
        require(msg.sender == keeper, "e50");
    }

    // *************
    //  Epoch Start
    // *************

    /// @notice Function called post swap to compute the vaults new Asset1 amount and Asset2 amount
    //  called post the funds are send from swap contract to flipflop
    function internalSwapComputationPostSwap() external {
        _onlyKeeperShouldCall();
        uint256 realAmountOfAsset1 = totalAmountOfAsset1 -
            totalLockedAmountOfAsset1;
        uint256 realAmountOfAsset2 = totalAmountOfAsset2 -
            totalLockedAmountOfAsset2;
        FlipFlopLib.verifyInternalSwap(
            vaultState,
            realAmountOfAsset1,
            realAmountOfAsset2,
            swap.S1
        );

        vaultState = FlipFlopStates.FundsToBeSendToFundamentalVaults;

        uint256 A_S = swap.A_S;
        uint256 S1 = swap.S1;

        if (swap.asset == asset2) {
            A_S = Compute.divPrice(
                A_S,
                decimalsOfAsset2,
                S1,
                18,
                decimalsOfAsset1
            );
        }

        internalSwapAsset1 = realAmountOfAsset1 - A_S;

        internalSwapAsset2 =
            realAmountOfAsset2 +
            Compute.mulPrice(S1, 18, A_S, decimalsOfAsset1, decimalsOfAsset2);

        emit InternalSwapComputation(
            totalAmountOfAsset1,
            internalSwapAsset1,
            totalAmountOfAsset2,
            internalSwapAsset2
        );
    }

    /// @notice Deposits the funds to fundamental vaults. Readjusts the vault positions.
    // Withdrawals are done before this function is called.

    function startEpoch() external nonReentrant {
        _onlyKeeperShouldCall();
        require(
            vaultState == FlipFlopStates.FundsToBeSendToFundamentalVaults,
            "e39"
        );
        vaultState = FlipFlopStates.CalculateS_EAndS_U;
        firstIteration = true;

        e_V = totalAmountOfAsset1 - totalLockedAmountOfAsset1;
        u_V = totalAmountOfAsset2 - totalLockedAmountOfAsset2;
        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        require(
            IERC20(asset1).approve(address(fundamentalVault1), e_V) &&
                IERC20(asset2).approve(address(fundamentalVault2), u_V),
            "e48"
        );

        // transfer to fundamental vaults
        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        fundamentalVault1.deposit(e_V);
        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        fundamentalVault2.deposit(u_V);
        totalAmountOfAsset1 = 0;
        totalAmountOfAsset2 = 0;

        ++currentRound;

        emit StartEpoch(e_V, u_V);
    }

    /// @notice function to calculate S_E and S_U
    /// @param _startFrom The address of the user to start the iteration from, set to zero address ( or any other address
    /// just be sure that in future tx with new _startFrom, that address might get reused) to start from the first user
    /// @return _toContinue The value of next user in the loop to continue iterating through
    function calculateS_E_S_U(address _startFrom)
        external
        returns (address _toContinue)
    {
        _onlyKeeperShouldCall();
        require(vaultState == FlipFlopStates.CalculateS_EAndS_U, "e40");

        UserDoubleLinkedList.User memory user;
        if (firstIteration) {
            S_E = 0;
            S_U = 0;
            user = getFirstUser();
            firstIteration = false;
        } else user = getUser(_startFrom);

        uint8 i = 0;
        uint256 size = batchSize;
        while (user.user != ZERO_ADDRESS && i < size) {
            _calculateS_E_S_U(user);
            user = getNextUser();
            unchecked {
                i++;
            }
        }
        if (user.user == ZERO_ADDRESS) {
            vaultState = FlipFlopStates.MintUserShares;
            firstIteration = true;
        }

        emit NextUser(user.user);
        return user.user;
    }

    /// @notice internal function to do the calcuations for S_E and S_U
    /// @param user The user struct containing all the info related to a particular user
    function _calculateS_E_S_U(UserDoubleLinkedList.User memory user) internal {
        //slither-disable-next-line calls-loop
        if (
            //slither-disable-next-line calls-loop
            !whiteList.isVaultWhitelisted(user.user) &&
            //slither-disable-next-line calls-loop
            !whiteList.isUserWhitelisted(user.user)
        ) {
            if (user.queuedAmountOfAsset1ToWithdraw != type(uint104).max) {
                user.queuedAmountOfAsset1ToWithdraw = type(uint104).max;
                putUser(user);
            }
            delete whiteListedUsers[user.user];
        } else {
            whiteListedUsers[user.user] = true;
        }
        (uint256 lock1, uint256 lock2) = FlipFlopLib.calcLockedAmount(
            user,
            minDepositOfAsset1,
            minDepositOfAsset2
        );
        uint256 e = user.amountOfAsset1 - lock1;
        uint256 u = user.amountOfAsset2 - lock2;
        uint256 UbyS = Compute.divPrice(
            u,
            decimalsOfAsset2,
            swap.S,
            18,
            decimalsOfAsset1
        );

        if (e > UbyS) {
            //slither-disable-next-line costly-loop
            S_E = S_E + (e - UbyS) / 2;
        } else {
            //slither-disable-next-line costly-loop
            S_U =
                S_E +
                (u -
                    Compute.mulPrice(
                        e,
                        decimalsOfAsset1,
                        swap.S,
                        18,
                        decimalsOfAsset2
                    )) /
                2;
        }
    }

    /// @notice for minting new user position post swap and deposit to fundamental vaults
    /// @param _startFrom The address to start the position readjustment from, set to zero address ( or any other address
    /// just be sure that in future tx with new _startFrom, that address might get reused) to start from the first user
    /// @return _toContinue The next address mint shares to.
    function startMint(address _startFrom)
        external
        returns (address _toContinue)
    {
        _onlyKeeperShouldCall();
        require(vaultState == FlipFlopStates.MintUserShares, "e41");

        UserDoubleLinkedList.User memory user;
        if (firstIteration) {
            user = getFirstUser();
            firstIteration = false;
        } else {
            user = getUser(_startFrom);
        }
        uint8 i = 0;
        uint256 size = batchSize;
        while (user.user != ZERO_ADDRESS && i < size) {
            if (whiteListedUsers[user.user]) {
                _assignUserShares(user);
            }
            user = getNextUser();
            unchecked {
                i++;
            }
        }
        if (user.user == ZERO_ADDRESS) {
            vaultState = FlipFlopStates.EpochOnGoing;
        }

        emit NextUser(user.user);
        return user.user;
    }

    /// @notice Internal function that calculates and assigns the number of shares for a user
    /// @param user - The user to whom shares are to be minted

    function _assignUserShares(UserDoubleLinkedList.User memory user) internal {
        Swap memory temp = Swap(
            swap.S,
            swap.S1,
            swap.S2,
            swap.A_S,
            swap.A,
            swap.asset,
            swap.amountOfAsset1BeforeSending,
            swap.amountOfAsset2BeforeSending
        );

        FlipFlopLib.checkComputeNewDeposit(temp, user);

        FlipFlopLib.AssetDetails memory assetDetails = FlipFlopLib.AssetDetails(
            asset1,
            asset2,
            decimalsOfAsset1,
            decimalsOfAsset2,
            S_E,
            S_U
        );

        (
            uint256 e1, // e1(e, u, S, S1)
            uint256 u1 // u1(e, u, S, S1)
        ) = FlipFlopLib._computeUserValues(temp, user, assetDetails);

        uint256 n;

        {
            uint256 InternalSwapXS2 = Compute.mulPrice(
                internalSwapAsset1,
                decimalsOfAsset1,
                swap.S2,
                18,
                decimalsOfAsset2
            );

            //n → 10^18 * (u1(e,u,S,S1) + S2*e1(e,u,S,S1)) / (U1+S2*E1)
            //  → {10^18 * [ u1 + S2 * e1  ]} / (U1 + S2 * E1)
            n = (10**18 *
                (u1 +
                    Compute.scaleDecimals(
                        swap.S2.wadMul(e1),
                        decimalsOfAsset1,
                        decimalsOfAsset2
                    ))).wadDiv(internalSwapAsset2 + InternalSwapXS2);
        }

        emit UpdateUserShares(
            user.user,
            user.amountOfAsset1,
            user.amountOfAsset2,
            n
        );

        user.amountOfAsset1 = 0;
        user.amountOfAsset2 = 0;
        user.numberOfShares = n;

        putUser(user);
    }

    // ************
    // DURING EPOCH
    // ************

    /// @notice Schedule withdraw from fundamental vaults
    /// @dev only owner function
    function scheduleWithdrawFromFundamentalVaults() external nonReentrant {
        _onlyKeeperShouldCall();
        require(vaultState == FlipFlopStates.EpochOnGoing, "e24");

        uint256 sharesAsset1 = fundamentalVault1.shares(address(this));
        uint256 sharesAsset2 = fundamentalVault2.shares(address(this));

        //slither-disable-next-line reentrancy-benign
        fundamentalVault1.initiateWithdraw(sharesAsset1);
        //slither-disable-next-line arbitrary-send, low-level-calls, reentrancy-benign
        fundamentalVault2.initiateWithdraw(sharesAsset2);
        Vault.OptionState memory optionState = fundamentalVault1.optionState();
        expirationTime = optionState.currentOptionExpirationAt;
    }

    // *********
    // EPOCH END
    // *********

    /// @notice Complete the withdraw from fundamental vaults

    /// @dev called by owner after the end of epoch on fundamental vaults

    //actually we don't need nonReentrant here (nothing changes)
    function withdrawFromFundamentalVaults() external {
        _onlyKeeperShouldCall();
        require(vaultState == FlipFlopStates.EpochOnGoing, "e24");

        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        // Amount of funds received at the end of epoch for asset 1
        e_o = fundamentalVault1.completeWithdraw();
        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        // Amount of funds received at the end of epoch for asset 2
        u_o = fundamentalVault2.completeWithdraw();

        //if we've received native tokens, convert it to wrapped
        if ((asset1 == WMATIC) || (asset2 == WMATIC)) {
            IWMATIC(WMATIC).deposit{value: address(this).balance};
        }
        updateVaultWithIncreasedAmount(e_o, u_o);

        vaultState = FlipFlopStates.PerformanceFeeNeedsToBeCharged;
    }

    /// @notice function to convert shares back to assets post epoch
    /// @param _startFrom The address of the user to start the iteration from, set to zero address ( or any other address
    /// just be sure that in future tx with new _startFrom, that address might get reused) to start from the first user.
    /// @return _toContinue The value of next user in the loop to continue iterating through
    function redeemUserShares(address _startFrom)
        external
        returns (address _toContinue)
    {
        _onlyKeeperShouldCall();
        require(
            vaultState == FlipFlopStates.UserLastEpochFundsNeedsToBeRedeemed,
            "e29"
        );

        UserDoubleLinkedList.User memory user;

        if (firstIteration) {
            totalLockedAmountOfAsset1 = 0;
            totalLockedAmountOfAsset2 = 0;
            user = getFirstUser();
            firstIteration = false;
        } else {
            user = getUser(_startFrom);
        }
        uint256 size = batchSize;
        uint8 i = 0;
        while (user.user != ZERO_ADDRESS && i < size) {
            if (whiteListedUsers[user.user]) {
                _redeemUserShares(user);
            }
            user = getNextUser();
            unchecked {
                ++i;
            }
        }

        if (user.user == ZERO_ADDRESS) {
            vaultState = FlipFlopStates.SwapNeedsToTakePlace;
        }

        emit NextUser(user.user);
        return user.user;
    }

    /// @notice internal function to do the calcuations for converting user shares back to asset 1 and asset 2 amount
    /// @param user The user struct containing all the info related to a particular user
    function _redeemUserShares(UserDoubleLinkedList.User memory user) internal {
        uint256 n = user.numberOfShares;

        uint256 ratio = n / n_T;
        // n/n_T * E
        user.amountOfAsset1 =
            user.amountOfAsset1 +
            Compute.mulPrice(
                e_o,
                decimalsOfAsset1,
                ratio,
                18,
                decimalsOfAsset1
            );

        // n/n_T * U
        user.amountOfAsset2 =
            user.amountOfAsset2 +
            Compute.mulPrice(
                u_o,
                decimalsOfAsset2,
                ratio,
                18,
                decimalsOfAsset2
            );
        user.numberOfShares = 0;

        (uint256 lock1, uint256 lock2) = FlipFlopLib.calcLockedAmount(
            user,
            minDepositOfAsset1,
            minDepositOfAsset2
        );
        //slither-disable-next-line costly-loop
        totalLockedAmountOfAsset1 = totalLockedAmountOfAsset1 + lock1;
        //slither-disable-next-line costly-loop
        totalLockedAmountOfAsset2 = totalLockedAmountOfAsset2 + lock2;
        putUser(user);
    }

    // ****
    // SWAP
    // ****

    /// @notice Function to send funds to the swap vault
    function sendToSwapVault() external nonReentrant {
        require(whiteList.isSwapManagerWhitelisted(msg.sender), "e51");
        require(vaultState == FlipFlopStates.SwapNeedsToTakePlace, "e23");

        uint256 S = getInternalSwapRate(poolIdAsset1ToAsset2);
        uint256 realAmountOfAsset1 = totalAmountOfAsset1 -
            totalLockedAmountOfAsset1;
        uint256 realAmountOfAsset2 = totalAmountOfAsset2 -
            totalLockedAmountOfAsset2;
        (uint256 A, , address asset) = FlipFlopLib.computeA(
            S,
            realAmountOfAsset1,
            realAmountOfAsset2,
            asset1,
            asset2,
            decimalsOfAsset1,
            decimalsOfAsset2
        );
        swap.A = A;
        swap.amountOfAsset1BeforeSending = realAmountOfAsset1;
        swap.amountOfAsset2BeforeSending = realAmountOfAsset2;

        if (asset == asset1) {
            //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
            require(IERC20(asset1).approve(address(swapVault), A), "e48");
            totalAmountOfAsset1 = totalAmountOfAsset1 - A;
            //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
            requestId = swapVault.deposit(poolIdAsset1ToAsset2, A);
        } else {
            //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
            require(IERC20(asset2).approve(address(swapVault), A), "e48");
            totalAmountOfAsset2 = totalAmountOfAsset2 - A;
            //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
            requestId = swapVault.deposit(poolIdAsset2ToAsset1, A);
        }

        vaultState = FlipFlopStates.SwapIsInProgress;
        emit SentSwappedFunds(asset, A);
    }

    /// @notice Interface function used by the swap vault to send funds to flip flop vault
    /// param id - The swap pair id (it is not using now)
    /// @param _S1 - The amount at which the real swap took place with the MM.
    /// @param _S2 - The midway market price
    /// @param _A_S - Amount swapped (in assetTo)
    /// @param _A - Amount not swapped (in assetFrom)
    function receiveSwappedFunds(
        bytes32, //id,
        uint256 _S1,
        uint256 _S2,
        uint256 _A_S,
        uint256 _A
    ) external nonReentrant {
        require(msg.sender == address(swapVault), "e32");
        require(vaultState == FlipFlopStates.SwapIsInProgress, "e43");
        (address from, , bytes32 poolId) = swapVault.getAssetFromRequestId(
            requestId
        );
        requestId = 0;
        Swap memory tempSwap = swap;

        tempSwap.asset = from;
        tempSwap.A_S = tempSwap.A - _A;
        bool isAsset1 = asset1 == from;

        if (isAsset1) {
            tempSwap.S = getInternalSwapRate(poolId);
            tempSwap.S1 = _S1;
            tempSwap.S2 = _S2;
        } else {
            uint256 one = 10**18;
            tempSwap.S = one.wadDiv(getInternalSwapRate(poolId));
            tempSwap.S1 = one.wadDiv(_S1);
            tempSwap.S2 = one.wadDiv(_S2);
        }

        uint256 amountAsset1 = isAsset1 ? _A : _A_S;
        uint256 amountAsset2 = isAsset1 ? _A_S : _A;

        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        IERC20(asset1).safeTransferFrom(
            address(swapVault),
            address(this),
            amountAsset1
        );

        //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
        IERC20(asset2).safeTransferFrom(
            address(swapVault),
            address(this),
            amountAsset2
        );
        updateVaultWithIncreasedAmount(amountAsset1, amountAsset2);

        swap = tempSwap;

        vaultState = FlipFlopStates.InternalRatioComputationToBeDone;
        emit ReceivedSwappedFunds(
            amountAsset1,
            amountAsset2,
            totalAmountOfAsset1,
            totalAmountOfAsset2
        );
    }

    // ****************
    // HELPER FUNCTIONS
    // ****************

    /// @notice function to transfer asset fees to destination addresses
    function chargePerformanceFee() external nonReentrant {
        _onlyKeeperShouldCall();
        require(
            vaultState == FlipFlopStates.PerformanceFeeNeedsToBeCharged,
            "e31"
        );

        //we can use any from fundamentalVault, so, let's use fundamentalVault1
        (uint256 expirationPrice, bool isFinalized) = (
            IOracle(
                (IController(fundamentalVault1.GAMMA_CONTROLLER())).oracle()
            )
        ).getExpiryPrice(asset1, expirationTime);
        require(isFinalized, "e46");

        (
            uint256 asset1PerformanceFee,
            uint256 asset2PerformanceFee
        ) = FlipFlopLib.calculatePerformanceFee(
                e_o,
                e_V,
                u_o,
                u_V,
                asset1,
                asset2,
                expirationPrice
            );

        totalAmountOfAsset1 = totalAmountOfAsset1 - asset1PerformanceFee;
        totalAmountOfAsset2 = totalAmountOfAsset2 - asset2PerformanceFee;

        e_V = e_V - asset1PerformanceFee;
        u_V = u_V - asset2PerformanceFee;

        if (asset1PerformanceFee > 0) {
            //slither-disable-next-line reentrancy-no-eth
            transferAsset(asset1, treasuryAddress, asset1PerformanceFee);
        }

        if (asset2PerformanceFee > 0) {
            //slither-disable-next-line reentrancy-no-eth
            transferAsset(asset2, treasuryAddress, asset2PerformanceFee);
        }

        vaultState = FlipFlopStates.UserLastEpochFundsNeedsToBeRedeemed;
        firstIteration = true;
    }

    /// @notice helper function to interact with swap vault to get the internal swap rate
    function getInternalSwapRate(bytes32 poolId)
        internal
        view
        returns (uint256)
    {
        return swapVault.getInternalSwapRate(poolId);
    }

    // function withdrawInstantlyFromFundamentalVaults(
    //     uint256 amount1,
    //     uint256 amount2
    // ) external {
    //     Vault.OptionState memory optionState = fundamentalVault1.optionState();
    //     expirationTime = optionState.currentOptionExpirationAt;

    //     //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
    //     fundamentalVault1.withdrawInstantly(amount1);
    //     //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
    //     fundamentalVault2.withdrawInstantly(amount2);

    //     // Amount of funds received at the end of epoch for asset 1
    //     e_o = amount1;
    //     // Amount of funds received at the end of epoch for asset 2
    //     u_o = amount2;

    //     //if we've received native tokens, convert it to wrapped
    //     if ((asset1 == WMATIC) || (asset2 == WMATIC)) {
    //         IWMATIC(WMATIC).deposit{value: address(this).balance};
    //     }
    //     updateVaultWithIncreasedAmount(e_o, u_o);
    //     vaultState = FlipFlopStates.PerformanceFeeNeedsToBeCharged;
    // }

    // ****************
    // SETTER FUNCTIONS
    // ****************

    /// @notice function to set the numebr of users to interate when assigning shares
    /// @param _size The iterator count
    function setBatchSize(uint256 _size) external onlyOwner {
        batchSize = _size;
    }

    /// @notice Sets the new keeper
    /// @param newKeeper is the address of the new keeper
    function setKeeper(address newKeeper) external onlyOwner {
        keeper = newKeeper;
    }

    /// @notice function to set the treasury address
    /// @param _treasury new Treasure address
    function setTreasuryAddress(address _treasury) external onlyOwner {
        treasuryAddress = _treasury;
    }

    function checkIf() external view returns (bool) {
        if ((asset1 == WMATIC) || (asset2 == WMATIC)) {
            return true;
        }
    }

    function checkMaticDeposit() external {
        IWMATIC(WMATIC).deposit{value: address(this).balance};
    }

    // function setAssetData(uint256 _asset1, uint256 _asset2) external {
    //     _onlyKeeperShouldCall();
    //     totalAmountOfAsset1 = _asset1;
    //     totalAmountOfAsset2 = _asset2;
    // }
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
pragma solidity =0.8.14;

import "./Deposit.sol";

/// @title Withdraw
/// @notice Contract covering user withdrawals
contract Withdraw is Deposit {
    using SafeERC20 for IERC20;

    /// @dev event which is emitted when a new withdrawal happens
    /// @param _user - address of user making the withdraw
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    event WithdrawCurrentBalance(
        address indexed _user,
        uint256 _asset1Amount,
        uint256 _asset2Amount
    );

    /// @dev event which is emitted when a new queued withdrawal happens. One of _queuedAmountOfAsset1 or
    /// @dev _queuedAmountOfAsset2 should be zero
    /// @param _user - address of user making the queued withdrawal
    /// @param _queuedAmountOfAsset1 - queued amount of asset1 which is wanted to withdraw
    /// @param _queuedAmountOfAsset2 - queued amount of asset2 which is wanted to withdraw
    event QueuedWithdraw(
        address indexed _user,
        uint256 _queuedAmountOfAsset1,
        uint256 _queuedAmountOfAsset2
    );

    /// @dev event which is emitted when queued withdrawal completes
    /// @param _user - address of user who completed withdrawal
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    event CompleteQueuedWithdraw(
        address indexed _user,
        uint256 _asset1Amount,
        uint256 _asset2Amount
    );

    /// @dev event which is emitted when an emergency withdrawal happens
    /// @param _owner - the owner, who made an emergency withdrawal
    /// @param _asset1Amount - amount of asset1 which was withdrawn
    /// @param _asset2Amount - amount of asset2 which was withdrawn
    /// @param _nativeCoinAmount - amount of the native coin which was withdrawn
    event EmergencyWithdrawal(
        address indexed _owner,
        uint256 _asset1Amount,
        uint256 _asset2Amount,
        uint256 _nativeCoinAmount
    );

    /// @notice function that withdraw balance which was deposited in the current round. Both assets will be withdrawn but only one
    /// @notice amount is used as the input parameter. Amount of the other asset will be calculated using the proportion of
    /// @notice the "first" asset to withdraw to the "second" asset in the user account in the Vault.
    /// @notice Function doesn't work when the contract is paused
    /// @param _assetToWithdraw - what asset to withdraw
    /// @param _amountOfAssetToWithdraw - how much of asset to withdraw

    // nonReentrant actually doesn't need here
    function withdrawCurrentBalance(
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw
    ) external {
        _requireNotPaused();
        User memory user = getUser(msg.sender);

        bool isFirstAsset = FlipFlopLib.verifyWithdrawCurrentBalance(
            user,
            _assetToWithdraw,
            _amountOfAssetToWithdraw,
            asset1,
            asset2,
            whiteList,
            vaultState
        );

        /// calculate the amount of asset1 to withdraw
        //slither-disable-next-line divide-before-multiply
        uint256 amountOfAsset1ToWithdraw = isFirstAsset
            ? _amountOfAssetToWithdraw
            : (user.amountOfAsset1 * _amountOfAssetToWithdraw) /
                user.amountOfAsset2;

        /// if after withdrawal, the amount of asset1 remaining is less than minDeposit of asset1
        /// withdraw all user funds of asset1
        if (
            user.amountOfAsset1 < minDepositOfAsset1 + amountOfAsset1ToWithdraw
        ) {
            amountOfAsset1ToWithdraw = user.amountOfAsset1;
        }

        /// calculate the amount of asset2 to withdraw
        uint256 amountOfAsset2ToWithdraw = isFirstAsset
            ? (user.amountOfAsset2 * amountOfAsset1ToWithdraw) /
                user.amountOfAsset1
            : _amountOfAssetToWithdraw;

        /// if after withdrawal, the amount of asset2 remaining is less than minDeposit of asset2
        /// withdraw all user funds of asset2
        if (
            user.amountOfAsset2 < minDepositOfAsset2 + amountOfAsset2ToWithdraw
        ) {
            amountOfAsset2ToWithdraw = user.amountOfAsset2;
            // withdraw all user's funds of asset1 (because, during prev calculation of amounOfAsset1ToWithdraw, this amount
            // can be not equal to user.amountOfAsset1, but Vault's logic is designed to work with 2 assets, not only one,
            // so, both asset should be withdrawn in full amount)
            amountOfAsset1ToWithdraw = user.amountOfAsset1;
        }

        //if the user withdraws all funds and doesn't have any options
        if (
            (user.amountOfAsset1 == amountOfAsset1ToWithdraw) &&
            (user.numberOfShares == 0) &&
            (user.queuedAmountOfAsset1ToWithdraw == 0) &&
            (user.queuedAmountOfAsset2ToWithdraw == 0)
        ) {
            // this user will be removed from the Vault
            removeUser(msg.sender);
            delete whiteListedUsers[msg.sender];
        } else {
            // else just update the user's User structure with new value of remaining funds
            user.amountOfAsset1 =
                user.amountOfAsset1 -
                amountOfAsset1ToWithdraw;
            user.amountOfAsset2 =
                user.amountOfAsset2 -
                amountOfAsset2ToWithdraw;
            putUser(user);
        }

        totalAmountOfAsset1 = totalAmountOfAsset1 - amountOfAsset1ToWithdraw;
        totalAmountOfAsset2 = totalAmountOfAsset2 - amountOfAsset2ToWithdraw;

        emit WithdrawCurrentBalance(
            msg.sender,
            amountOfAsset1ToWithdraw,
            amountOfAsset2ToWithdraw
        );

        transferAsset(asset1, msg.sender, amountOfAsset1ToWithdraw);
        transferAsset(asset2, msg.sender, amountOfAsset2ToWithdraw);
    }

    /// @notice initiates a queued withdrawal. Function replaces previous amount to withdraw if it exists. Function allows
    /// @notice to pass more _amountOfAssetToWithdraw than stored currently. If after expiration
    /// @notice _amountOfAssetToWithdraw still will be more than allowed, the maximum allowed amount will be withdrawn.
    /// @notice Function allows to withdraw a small amount if the account will still hold more than the minDeposit.
    /// @notice Function doesn't work when the contract is paused
    /// @param _assetToWithdraw - which asset is queued (during completeWithdraw all calculations will be done
    /// relatively to this asset)
    /// @param _amountOfAssetToWithdraw - requested amount of asset to withdraw
    function initiateWithdraw(
        address _assetToWithdraw,
        uint256 _amountOfAssetToWithdraw
    ) external {
        _requireNotPaused();
        User memory user = getUser(msg.sender);
        bool isAsset1 = FlipFlopLib.verifyInitializeWithdraw(
            user,
            _assetToWithdraw,
            _amountOfAssetToWithdraw,
            asset1,
            asset2,
            whiteList,
            vaultState
        );

        // only one of queuedAmountOfAsset1ToWithdraw and queuedAmountOfAsset2ToWithdraw can be non-zero
        // if the user calls initiateWithdraw with asset1 and after then calls initiateWithdraw with
        // asset2 - completeWithdraw will be based on asset2
        user.queuedAmountOfAsset1ToWithdraw = isAsset1
            ? _amountOfAssetToWithdraw
            : 0;
        user.queuedAmountOfAsset2ToWithdraw = isAsset1
            ? 0
            : _amountOfAssetToWithdraw;

        // save the current round. We need this to know during completeWithdraw that options were expired (the
        // round will be higher than currentRound)
        user.roundWhenQueuedWithdrawalWasRequested = currentRound;
        //save the user
        putUser(user);

        emit QueuedWithdraw(
            msg.sender,
            user.queuedAmountOfAsset1ToWithdraw,
            user.queuedAmountOfAsset2ToWithdraw
        );
    }

    /// @notice Complete queued withdrawal, should be called after round when initiateWithdraw happened. If the
    /// @notice requested amount will be less than actual, the amount of the "second" asset will be returned in
    /// @notice proportion based on requested_amount_of_requested_asset/actual_amount_of_requested_asset. Function
    /// @notice doesn't work when contract is paused
    function completeWithdraw() public {
        _requireNotPaused();
        User memory user = getUser(msg.sender);

        FlipFlopLib.verifyCompleteWithdraw(
            user,
            whiteList,
            currentRound,
            vaultState
        );

        // get amounts to withdraw
        (
            uint256 amountOfAsset1ToWithdraw,
            uint256 amountOfAsset2ToWithdraw
        ) = FlipFlopLib.calcLockedAmount(
                user,
                minDepositOfAsset1,
                minDepositOfAsset2
            );
        require(amountOfAsset1ToWithdraw > 0, "e36");

        //if all funds will be withdrawn and the user doesn't have other funds in options
        if (
            (user.amountOfAsset1 == amountOfAsset1ToWithdraw) &&
            (user.numberOfShares == 0)
        ) {
            //remove the user from the Vault
            removeUser(msg.sender);
            delete whiteListedUsers[msg.sender];
        } else {
            //else update the user's User structure
            user.amountOfAsset1 =
                user.amountOfAsset1 -
                amountOfAsset1ToWithdraw;
            user.amountOfAsset2 =
                user.amountOfAsset2 -
                amountOfAsset2ToWithdraw;
            user.queuedAmountOfAsset1ToWithdraw = 0;
            user.queuedAmountOfAsset2ToWithdraw = 0;

            //save the user
            putUser(user);
        }
        //update total amount of the Vault assets
        totalAmountOfAsset1 = totalAmountOfAsset1 - amountOfAsset1ToWithdraw;
        totalAmountOfAsset2 = totalAmountOfAsset2 - amountOfAsset2ToWithdraw;

        //make erc20-transfer from the Vault to the user
        transferAsset(asset1, msg.sender, amountOfAsset1ToWithdraw);
        transferAsset(asset2, msg.sender, amountOfAsset2ToWithdraw);

        emit CompleteQueuedWithdraw(
            msg.sender,
            amountOfAsset1ToWithdraw,
            amountOfAsset2ToWithdraw
        );
    }

    /// @notice emergency withdraw all funds of the Vault to the owner. Only the owner can call this function
    function emergencyWithdraw() external onlyOwner {
        uint256 assetOneAmount = IERC20(asset1).balanceOf(address(this));
        uint256 assetTwoAmount = IERC20(asset2).balanceOf(address(this));

        if (assetOneAmount > 0) {
            transferAsset(asset1, msg.sender, assetOneAmount);
        }
        if (assetTwoAmount > 0) {
            transferAsset(asset2, msg.sender, assetTwoAmount);
        }

        uint256 nativeCoinAmount = address(this).balance;
        if (nativeCoinAmount > 0) {
            bool sent = payable(msg.sender).send(nativeCoinAmount);
            require(sent, "e37");
        }

        emit EmergencyWithdrawal(
            msg.sender,
            assetOneAmount,
            assetTwoAmount,
            nativeCoinAmount
        );
    }

    function transferAsset(
        address _asset,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_asset == WMATIC) {
            //slither-disable-next-line reentrancy-eth
            IWMATIC(WMATIC).withdraw(_amount);
            //slither-disable-next-line arbitrary-send, low-level-calls, reentrancy-benign
            (bool success, ) = _recipient.call{value: _amount}("");
            require(success, "e49");
        } else {
            IERC20(_asset).safeTransfer(_recipient, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/// @title
/// @author Tanishk Goyal
interface ITrufinVault {
    function receiveSwappedFunds(
        bytes32 _requestId,
        uint256 spotRate,
        uint256 midSpotRate,
        uint256 amountSwapped,
        uint256 amountLeftover
    ) external;
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral
        // in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(address owner)
        external
        view
        returns (uint256);

    function oracle() external view returns (address);

    function getVault(address _owner, uint256 _vaultId)
        external
        view
        returns (GammaTypes.Vault memory);

    function getProceed(address _owner, uint256 _vaultId)
        external
        view
        returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IOracle {
    function setAssetPricer(address _asset, address _pricer) external;

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (uint256, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../libraries/FlipFlopLib.sol";
import "../../interfaces/IWMATIC.sol";
import "./helpers/UserDoubleLinkedList.sol";

/// @title Deposit
/// @notice Contract covers users deposit functionality
contract Deposit is UserDoubleLinkedList {
    using SafeERC20 for IERC20;

    /// @notice Polygon ChainLink's oracles:
    /// @notice usdc/eth - 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE
    /// @notice matic/usd - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
    /// @notice wbtc/usd - 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6
    /// @notice usdc/usd - 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7

    /// @notice Mumbai ChainLink's oracles:
    /// @notice eth/usd - 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    /// @notice matic/usd - 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
    /// @notice btc/usd - 0x007A22900a3B98143368Bd5906f8E17e9867581b
    /// @notice usdc/usd - 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0

    AggregatorV3Interface internal chainLinkPriceOracle;
    /// @notice if we don't have price oracle asset1/asset2 or asset2/asset1, we can use additional price oracle
    /// @notice so, if we have asset1/asset3 price oracle and additional asset3/asset2 price oracle, we can calculate
    /// @notice asset1/asset2 = (asset1/asset3) * (asset3/asset2)
    AggregatorV3Interface internal additionalChainLinkPriceOracle;

    /// @notice when we have price feed asset2/asset1 instead of asset1/asset2, this flag should be set to true
    bool public isReverseQuote;

    /// @notice when we have additional price feed asset2/asset1 instead of asset1/asset2, this flag should be set to
    /// @notice true
    bool public isReverseAdditionalQuote;

    /// @dev price divider for some price mul and div operations
    uint256 private priceDivider;

    /// @dev price multiplier for some price mul and div operations
    uint256 private priceMultiplier;

    /// @notice oracle decimals
    /// @dev saved with purpose to avoid external calls every time when it is needed
    uint8 public oracleDecimals;

    /// @notice additional oracle decimals
    /// @dev saved with purpose to avoid external calls every time when it is needed
    uint8 public additionalOracleDecimals;

    /// @dev address of WMATIC contract
    address public WMATIC;

    // https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    /// @dev event which is emitted when new cap's parameters are set
    event CapChanged(
        uint256 _newMinDepositOfAsset1,
        uint256 _newMaxCapOfAsset1,
        uint256 _newMinDepositOfAsset2,
        uint256 _newMaxCapOfAsset2
    );

    /// @dev event which is emitted when new oracles are set
    event OracleChanged(
        address _chainLinkPriceOracle,
        address _additionalChainLinkPriceOracle
    );

    /// @dev event which is emitted when a new deposit occurs
    event Deposited(
        address indexed _user,
        uint256 _amountOfAsset1,
        uint256 _amountOfAsset2
    );

    /// @notice set up new chainLink oracle(s). Only the owner can call this function
    /// @param _chainLinkPriceOracle - address of a chainLink oracle;
    /// @param _isReverseQuote - indicates that the price of the chainLink oracle should be inverted
    /// @param _additionalChainLinkPriceOracle - address of an additional chainLink oracle if needed
    /// @param _isReverseAdditionalQuote -indicates that the price of the additional chainLink oracle should be
    /// inverted
    function setChainLinkOracles(
        address _chainLinkPriceOracle,
        bool _isReverseQuote,
        address _additionalChainLinkPriceOracle,
        bool _isReverseAdditionalQuote
    ) public onlyOwner {
        require(_chainLinkPriceOracle != ZERO_ADDRESS, "e6");
        chainLinkPriceOracle = AggregatorV3Interface(_chainLinkPriceOracle);
        isReverseQuote = _isReverseQuote;
        //read oracle's decimals
        oracleDecimals = chainLinkPriceOracle.decimals();
        //as we operate uint104 for fundamental vaults,
        //max oracle decimals = log10(2^104) = log2(2^104)/log2(10) = ~104/3 = ~34
        require(oracleDecimals < 34, "e7");
        //if decimals of asset1 plus oracle's decimals more than decimals of asset, it means that when we mul amount
        //of asset1 on oracle price (=getting of amount of asset2) we will have too much decimals and we need to divide
        //result on the appropriate divider to get right decimals of asset2. Otherwise, we should mul instead of div.
        if (decimalsOfAsset1 + oracleDecimals > decimalsOfAsset2) {
            priceDivider =
                10**(decimalsOfAsset1 + oracleDecimals - decimalsOfAsset2);
            priceMultiplier = 0;
        } else {
            priceDivider = 0;
            priceMultiplier =
                10**(decimalsOfAsset2 - oracleDecimals - decimalsOfAsset1);
        }
        additionalChainLinkPriceOracle = AggregatorV3Interface(
            _additionalChainLinkPriceOracle
        );
        isReverseAdditionalQuote = _isReverseAdditionalQuote;
        //if an additional chainLink price oracle is set
        if (_additionalChainLinkPriceOracle != ZERO_ADDRESS) {
            //read decimals of the additional price oracle
            additionalOracleDecimals = additionalChainLinkPriceOracle.decimals();
            require(additionalOracleDecimals < 34, "e8");
        }
        emit OracleChanged(
            _chainLinkPriceOracle,
            _additionalChainLinkPriceOracle
        );
    }

    /// @notice deposit native Matic if the Vault accepts Matic.
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC. Function doesn't work if the contract is paused
    function depositMATIC() external payable {
        _depositMATIC(msg.sender);
    }

    /// @notice deposit native Matic as a creditor to a debtor if vault accepts Matic
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC. Function doesn't work if the contract is paused
    /// @param _toUser - the debtor address
    function depositMATICFor(address _toUser) external payable {
        _depositMATIC(_toUser);
    }

    /// @notice deposit assets into the Vault. Function doesn't work if the contract is paused. Appropriate amount of
    /// asset1 and asset2 should be approved to the contract to allow transfer
    /// @param _asset1Amount - deposited amount of asset1. Amount of asset2 will be calculated using chainLink
    /// oracle(s)
    function deposit(uint256 _asset1Amount) external {
        _deposit(msg.sender, msg.sender, _asset1Amount);
    }

    /// @notice deposit assets as a creditor to a debtor into the Vault. Function doesn't work if the contract is
    /// @notice paused. Appropriate amount of asset1 and asset2 should be approved to the contract to allow transfer
    /// @param _asset1Amount - deposited amount of asset1. Amount of asset2 will be calculated using chainLink oracle(s)
    function depositFor(address _forUser, uint256 _asset1Amount) external {
        _deposit(msg.sender, _forUser, _asset1Amount);
    }

    /// @notice set Cap params. Function can be called only by the owner
    /// @param _minDepositOfAsset1 - min accepted amount of a deposit of asset1
    /// @param _maxCapOfAsset1 - max cap of the Vault for asset1
    /// @param _minDepositOfAsset2 - min accepted amount of a deposit of asset2
    /// @param _maxCapOfAsset2 - max cap of the Vault for asset2
    function setCap(
        uint256 _minDepositOfAsset1,
        uint256 _maxCapOfAsset1,
        uint256 _minDepositOfAsset2,
        uint256 _maxCapOfAsset2
    ) external onlyOwner {
        FlipFlopLib.checkSetCap(
            _minDepositOfAsset1,
            _maxCapOfAsset1,
            _minDepositOfAsset2,
            _maxCapOfAsset2
        );

        maxCapOfAsset1 = _maxCapOfAsset1;
        maxCapOfAsset2 = _maxCapOfAsset2;
        minDepositOfAsset1 = _minDepositOfAsset1;
        minDepositOfAsset2 = _minDepositOfAsset2;

        emit CapChanged(
            _minDepositOfAsset1,
            _maxCapOfAsset1,
            _minDepositOfAsset2,
            _maxCapOfAsset2
        );
    }

    /// @notice deposit native Matic if vault accepts Matic
    /// @dev Matic can be accepted if asset1 or asset2 equal WMATIC
    /// @param _toUser - to whom this deposit
    function _depositMATIC(address _toUser) private nonReentrant {
        _requireNotPaused();
        bool asset1IsMATIC = FlipFlopLib.checkDepositMaticArgs(
            asset1,
            asset2,
            WMATIC,
            whiteList,
            _toUser,
            totalAmountOfAsset1,
            totalAmountOfAsset2,
            minDepositOfAsset1,
            minDepositOfAsset2,
            maxCapOfAsset1,
            maxCapOfAsset2,
            vaultState
        );
        uint256 amountOfAssetToDeposit;
        //if asset1 == WMATIC
        if (asset1IsMATIC) {
            // get amount of asset2 to deposit by mul value * spotPrice and bring the result to asset2 decimals
            amountOfAssetToDeposit =
                FlipFlopLib.getSpotPrice(
                    chainLinkPriceOracle,
                    additionalChainLinkPriceOracle,
                    isReverseQuote,
                    isReverseAdditionalQuote,
                    oracleDecimals,
                    additionalOracleDecimals
                ) *
                msg.value;
            if (priceDivider > 0) {
                // we don't need to make rounding here because user's deposits rebalancing will happen soon
                //slither-disable-next-line divide-before-multiply
                amountOfAssetToDeposit /= priceDivider;
            } else {
                //slither-disable-next-line divide-before-multiply
                amountOfAssetToDeposit *= priceMultiplier;
            }
            //slither-disable-next-line reentrancy-benign, reentrancy-events
            _depositAsset(asset2, msg.sender, amountOfAssetToDeposit);
        } else {
            // asset2 == WMATIC, so the amount is asset1 is value / spotPrice .
            if (decimalsOfAsset2 < decimalsOfAsset1) {
                // we don't need to make rounding here because user's deposits rebalancing will happen soon
                amountOfAssetToDeposit =
                    (msg.value *
                        10 **
                            ((oracleDecimals << 1) +
                                decimalsOfAsset1 -
                                decimalsOfAsset2)) /
                    FlipFlopLib.getSpotPrice(
                        chainLinkPriceOracle,
                        additionalChainLinkPriceOracle,
                        isReverseQuote,
                        isReverseAdditionalQuote,
                        oracleDecimals,
                        additionalOracleDecimals
                    ) /
                    10**oracleDecimals;
            } else {
                // we don't need to make rounding here because user's deposits rebalancing will happen soon
                amountOfAssetToDeposit =
                    (msg.value * 10**(oracleDecimals << 1)) /
                    FlipFlopLib.getSpotPrice(
                        chainLinkPriceOracle,
                        additionalChainLinkPriceOracle,
                        isReverseQuote,
                        isReverseAdditionalQuote,
                        oracleDecimals,
                        additionalOracleDecimals
                    ) /
                    10**(oracleDecimals + decimalsOfAsset2 - decimalsOfAsset1);
            }
            _depositAsset(asset1, msg.sender, amountOfAssetToDeposit);
        }
        //slither-disable-next-line reentrancy-events
        emit Deposited(
            _toUser,
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );

        uint256 balanceOfMATIC = IERC20(WMATIC).balanceOf(address(this));
        IWMATIC(WMATIC).deposit{value: msg.value}();

        require(
            IERC20(WMATIC).balanceOf(address(this)) - balanceOfMATIC >=
                msg.value,
            "e19"
        );

        //update the user info
        updateUser(
            _toUser,
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );
        //update the Vault info
        updateVaultWithIncreasedAmount(
            asset1IsMATIC ? msg.value : amountOfAssetToDeposit,
            asset1IsMATIC ? amountOfAssetToDeposit : msg.value
        );
    }

    /// @dev function that increases the global total amount of assets in the Vault
    /// @param _amountOfAsset1ToDeposit - amount of asset1 which was added
    /// @param _amountOfAsset2ToDeposit - amount of asset2 which was added
    function updateVaultWithIncreasedAmount(
        uint256 _amountOfAsset1ToDeposit,
        uint256 _amountOfAsset2ToDeposit
    ) internal {
        totalAmountOfAsset1 = totalAmountOfAsset1 + _amountOfAsset1ToDeposit;
        totalAmountOfAsset2 = totalAmountOfAsset2 + _amountOfAsset2ToDeposit;
    }

    /// @dev erc20 transfer the asset into the Vault
    /// @param asset - address of the asset
    /// @param _user - from user
    /// @param _amountOfAsset - amount of asset to be transferred
    function _depositAsset(
        address asset,
        address _user,
        uint256 _amountOfAsset
    ) private {
        bool isAsset1 = asset1 == asset;
        require(
            _amountOfAsset >=
                (isAsset1 ? minDepositOfAsset1 : minDepositOfAsset2),
            "e20"
        );
        require(
            _amountOfAsset +
                (isAsset1 ? totalAmountOfAsset1 : totalAmountOfAsset2) <=
                (isAsset1 ? maxCapOfAsset1 : maxCapOfAsset2),
            "e21"
        );
        uint256 balanceOfAsset = IERC20(asset).balanceOf(address(this));
        // needs to be approved by the user
        //slither-disable-next-line reentrancy-eth, reentrancy-benign
        IERC20(asset).safeTransferFrom(_user, address(this), _amountOfAsset);

        require(
            IERC20(asset).balanceOf(address(this)) - _amountOfAsset >=
                balanceOfAsset,
            "e22"
        );
    }

    /// @dev deposit funds from the creditor to the debitor's account in the Vault
    /// @param _fromUser - debitor address
    /// @param _toUser - creditor address
    /// @param _amountOfAsset1 - amount of asset1 to deposit. Amount of asset2 will be calculated using the oracle
    function _deposit(
        address _fromUser,
        address _toUser,
        uint256 _amountOfAsset1
    ) private nonReentrant {
        _requireNotPaused();
        FlipFlopLib.checkDeposit(whiteList, vaultState, _fromUser, _toUser);
        //transfer _amountOfAsset from _fromUser to the Vault;
        //slither-disable-next-line reentrancy-benign
        _depositAsset(asset1, _fromUser, _amountOfAsset1);
        //calculate amountOfAsset2
        uint256 amountOfAsset2 = FlipFlopLib.getSpotPrice(
            chainLinkPriceOracle,
            additionalChainLinkPriceOracle,
            isReverseQuote,
            isReverseAdditionalQuote,
            oracleDecimals,
            additionalOracleDecimals
        ) * _amountOfAsset1;
        if (priceDivider > 0) {
            //slither-disable-next-line divide-before-multiply
            amountOfAsset2 /= priceDivider;
        } else {
            //slither-disable-next-line divide-before-multiply
            amountOfAsset2 *= priceMultiplier;
        }
        //transfer amountOfAsset2 from _fromUser to the Vault
        _depositAsset(asset2, _fromUser, amountOfAsset2);
        //update _toUser User structure with additional amount of asset
        updateUser(_toUser, _amountOfAsset1, amountOfAsset2);
        //update the global amount of assets
        updateVaultWithIncreasedAmount(_amountOfAsset1, amountOfAsset2);
        //slither-disable-next-line reentrancy-events
        emit Deposited(_toUser, _amountOfAsset1, amountOfAsset2);
    }

    /// @dev update User structure or create new if _user isn't in the list. Amount of assets is added to existant
    /// @param _user - address of the user to update
    /// @param _amountOfAsset1 - amount of asset1 to add
    /// @param _amountOfAsset2 - amount of asset2 to add
    function updateUser(
        address _user,
        uint256 _amountOfAsset1,
        uint256 _amountOfAsset2
    ) private {
        //get existing user or empty User structure
        User memory user = getUser(_user);
        user.amountOfAsset1 = user.amountOfAsset1 + _amountOfAsset1;
        user.amountOfAsset2 = user.amountOfAsset2 + _amountOfAsset2;
        user.user = _user;
        //save the user
        putUser(user);
    }

    function _requireNotPaused() internal view {
        require(vaultState != FlipFlopStates.ContractIsPaused, "e49");
    }
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
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
    ) public view returns (uint256, uint256) {
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
            temp.A = Compute.divPrice(
                temp.A,
                assetDetails.decimalsOfAsset2,
                temp.S1,
                18,
                18
            );
            temp.A_S = Compute.divPrice(
                temp.A_S,
                assetDetails.decimalsOfAsset2,
                temp.S1,
                18,
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
                            revert("Unexpected: S_E < A");
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
pragma solidity =0.8.14;

interface IWMATIC {
    /**
     * @notice wrap deposited MATIC into WMATIC
     */
    function deposit() external payable;

    /**
     * @notice withdraw MATIC from contract
     * @dev Unwrap from WMATIC to MATIC
     * @param wad amount WMATIC to unwrap and withdraw
     */
    function withdraw(uint256 wad) external;

    /**
     * @notice Returns the WMATIC balance of @param account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice transfer WMATIC
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transfer(address dst, uint256 wad) external returns (bool);

    /**
     * @notice Returns amount spender is allowed to spend on behalf of the owner
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice approve transfer
     * @param guy address to approve
     * @param wad amount of WMATIC
     * @return True if tx succeeds, False if not
     */
    function approve(address guy, uint256 wad) external returns (bool);

    /**
     * @notice transfer from address
     * @param src source address
     * @param dst destination address
     * @param wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function decimals() external view returns (uint8);

    function mint(address receiver_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "../storage/Storage.sol";
import "../../../libraries/LinkedList.sol";

/// @title UserDoubleLinkedList
/// @notice It extends to the User struct the base functionality of a mapped list BaseDoubleLinkedList with O(1)
/// @notice complexity for add, delete, get and check if it exists
contract UserDoubleLinkedList is Storage {
    using LinkedListLib for LinkedListLib.LinkedListStorage;
    uint256 private constant ZERO = 0;
    address internal constant ZERO_ADDRESS = address(0);
    /// @dev mapping to store users, the key is user address
    mapping(address => User) internal users;

    LinkedListLib.LinkedListStorage internal list;

    //https://docs.openzeppelin.com/contracts/3.x/upgradeable#storage_gaps
    uint256[50] private __gap;

    /// @dev when a user is removed, this event will be emit
    /// @param _user - address of removed user
    event UserRemoved(address indexed _user);

    /// @dev when a user is added/updated, this event will be emit
    /// @param _user - address of the user
    event UserUpdated(User _user);

    /// @dev add a user to the list
    /// @param _user - User structure
    function putUser(User memory _user) internal {
        require(_user.user != ZERO_ADDRESS, "e1");
        //put address into BaseDoubleLinkedList
        //slither-disable-next-line unused-return
        list._put(_user.user);
        //put User structure into internal mapping
        users[_user.user] = _user;
        //slither-disable-next-line reentrancy-events
        emit UserUpdated(_user);
    }

    /// @dev remove a user from the list
    /// @param _user - user's address
    /// @return true if the user was removed else false
    function removeUser(address _user) internal returns (bool) {
        bool result = list.exists(_user) && list._remove(_user);
        if (result) {
            //if the user was removed - remove according item of internal users mapping
            delete users[_user];
            emit UserRemoved(_user);
        }
        return (result);
    }

    /// @notice gets User structure
    /// @param _user - user's address
    /// @return User structure or zeroed User structure if _user isn't in the list
    function getUser(address _user) public view returns (User memory) {
        return (users[_user]);
    }

    /// @dev gets the first user in the list. Internal iterator will be used
    /// @return User structure of the first user or zeroed User structure if the list is empty
    function getFirstUser() internal returns (User memory) {
        return (users[list.iterate_first()]);
    }

    /// @dev gets the next user in the list. Internal iterator is used
    /// @return User structure of the next user or zeroed User structure if the iterator has achieved the end of the
    /// list
    function getNextUser() internal returns (User memory) {
        return (users[list.iterate_next()]);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
        uint256 S;
        uint256 S1;
        uint256 S2;
        uint256 A_S;
        uint256 A;
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
        /// @dev Underlying asset of the options sold by vault
        address underlying;
        /// @dev Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        /// @dev Vault cap
        uint104 cap;
    }

    /// @dev struct for vault state of the options sold and the timelocked option
    struct OptionState {
        /// @dev Option that the vault is shorting / longing in the next cycle
        address nextOption;
        /// @dev Option that the vault is currently shorting / longing
        address currentOption;
        /// @dev The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library LinkedListLib {
    address public constant ZERO_ADDRESS = address(0);
    /// @dev uses as prev for the first item
    address constant HEAD = address(1);

    struct LinkedListStorage {
        /// @dev pointer on the next item
        mapping(address => address) next;
        /// @dev pointer on the previous item
        mapping(address => address) prev;
        /// @dev items count. In some cases, for complicated structures, size can not be equal to item count, so size can
        /// @dev be redefined (as function) in a child contract. But for most cases size = items count
        uint256 size;
        /// @dev pointer to the last item
        address last;
        /// @dev uses for iteration through list in iterateFirst/iterateNext functions
        address iterator;
        /// @dev max iteration limit for one call of clear_start\clear_next. It can happen if the list is huge and clear
        /// @dev all items for one call will be impossible because of the block gas limit. So, this variable regulates
        /// @dev iteration limit for a single call. The value depends on use-cases and can be set to different numbers for
        /// @dev different project (gas consumption of clear_start\clear_next is stable, but it is unknown gas-consumption
        /// @dev of a caller, so this value should be picked up individually for each project)

        uint256 iterationCountLimit;
    }

    function _addressHeadCheck(address _address) private pure {
        require(_address > HEAD, "e0");
    }

    /// @dev list doesn't accept reserved values (ZERO_ADDRESS and HEAD)
    /// @param _address - address to check
    modifier shouldntUseReservedValues(address _address) {
        _addressHeadCheck(_address);
        _;
    }

    /// @dev init the last element and point it to Head
    /// @param _iterationCountLimit - max iteration limit for one call of clear_start\clear_next
    function initBaseDoubleLinkedList(
        LinkedListStorage storage list,
        uint256 _iterationCountLimit
    ) public {
        list.last = HEAD;
        list.iterationCountLimit = _iterationCountLimit;
    }

    /// @dev add an item to the list with complexity O(1)
    /// @param _address - item
    /// @return true if an item was added, false otherwise
    function _put(LinkedListStorage storage list, address _address)
        public
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //new item always has prev[_address] equal ZERO_ADDRESS
        if (list.prev[_address] == ZERO_ADDRESS) {
            //set the next element to _address for the current last element
            list.next[list.last] = _address;
            //set prev element of _address to the current last element
            list.prev[_address] = list.last;
            //set last to _address
            list.last = _address;
            ++list.size;
            return true;
        }
        return false;
    }

    /// @dev remove an item from the list with complexity of O(1).
    /// @param _address - item to delete
    /// @return true if the item was deleted, false otherwise
    function _remove(LinkedListStorage storage list, address _address)
        public
        shouldntUseReservedValues(_address)
        returns (bool)
    {
        //existing item has prev[_address] non equal ZERO_ADDRESS.
        if (list.prev[_address] != ZERO_ADDRESS) {
            address prevAddress = list.prev[_address];
            address nextAddress = list.next[_address];
            delete list.next[_address];
            //set next of prevAddress to next of _address
            list.next[prevAddress] = nextAddress;
            //if iterateFirst\iterateNext iterator equal _address, it means that it pointed to the deleted item,
            //So, the iterator should be reset to the next item
            if (list.iterator == _address) {
                list.iterator = nextAddress;
            }
            //if removed the last (by order, not by size) item
            if (nextAddress == ZERO_ADDRESS) {
                //set the pointer of the last item to prevAddress
                list.last = prevAddress;
            } else {
                //else prev item of next address sets to prev address of deleted item
                list.prev[nextAddress] = prevAddress;
            }

            delete list.prev[_address];
            --list.size;
            return true;
        }
        return false;
    }

    /// @dev check if _address is in the list
    /// @param _address - address to check
    /// @return true if _address is in the list, false otherwise
    function exists(LinkedListStorage storage list, address _address)
        external
        view
        returns (bool)
    {
        //items in the list have prev which points to non ZERO_ADDRESS
        return list.prev[_address] != ZERO_ADDRESS;
    }

    /// @dev starts iterating through the list. The iterator will be saved inside contract
    /// @return address of first item or ZERO_ADDRESS if the list is empty
    function iterate_first(LinkedListStorage storage list)
        public
        returns (address)
    {
        list.iterator = list.next[HEAD];
        return list.iterator;
    }

    /// @dev gets the next item which is pointed by the iterator
    /// @return next item or ZERO_ADDRESS if the iterator is pointed to the last item
    function iterate_next(LinkedListStorage storage list)
        public
        returns (address)
    {
        //if the iterator is ZERO_ADDRES, it means that the list is empty or the iteration process is finished
        if (list.iterator == ZERO_ADDRESS) {
            return ZERO_ADDRESS;
        }
        list.iterator = list.next[list.iterator];
        return list.iterator;
    }

    /// @dev remove min(size, iterationCountLimit) of items
    /// @param _iterator - address, which is a start point of removing
    /// @return address of the item, which can be passed to _clear to continue removing items. If all items removed,
    /// ZERO_ADDRESS will be returned
    function _clear(LinkedListStorage storage list, address _iterator)
        public
        returns (address)
    {
        uint256 i = 0;
        while ((_iterator != ZERO_ADDRESS) && (i < list.iterationCountLimit)) {
            address nextIterator = list.next[_iterator];
            _remove(list, _iterator);
            _iterator = nextIterator;
            unchecked {
                i = i + 1;
            }
        }
        return _iterator;
    }

    /// @dev starts removing all items
    /// @return next item to pass into clear_next, if list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_init(LinkedListStorage storage list)
        external
        returns (address)
    {
        return (_clear(list, list.next[HEAD]));
    }

    /// @dev continues to remove all items
    /// @param _startFrom - address which is a start point of removing
    /// @return next item to pass into clear_next, if current list's size > iterationCountLimit, ZERO_ADDRESS otherwise
    function clear_next(LinkedListStorage storage list, address _startFrom)
        external
        returns (address)
    {
        return (_clear(list, _startFrom));
    }

    /// @dev get the first item of the list
    /// @return first item of the list or ZERO_ADDRESS if the list is empty
    function getFirst(LinkedListStorage storage list)
        external
        view
        returns (address)
    {
        return (list.next[HEAD]);
    }

    /// @dev gets the next item following _prev
    /// @param _prev - current item
    /// @return the next item following _prev
    function getNext(LinkedListStorage storage list, address _prev)
        external
        view
        returns (address)
    {
        return (list.next[_prev]);
    }
}