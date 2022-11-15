// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IAdminConfig {
    function updateAdmin(address admin_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBetFoundationFactory {
    function provideBetData(address betAddress_)
        external
        view
        returns (
            address,
            address,
            uint256,
            bool,
            bool
        );

    function raiseDispute(address betAddress_) external returns (bool);

    function postDisputeProcess(address betAddress_) external returns (bool);

    function createBet(
        address parentBet_,
        address betId_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_,
        uint256 lossSimulationPercentage_
    ) external payable returns (bool _status, address _betTrendSetter);

    function joinBet(
        address betAddress_,
        uint256 tokenLiqidity_,
        uint256 selectedOptionByUser_,
        uint256 tokenId_
    ) external payable returns (bool);

    function withdrawLiquidity(address betAddress_)
        external
        payable
        returns (bool);

    function resolveBet(
        address betAddress_,
        uint256 finalOption_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        bool isCustomized_,
        bool lossSimulationFlag_
    ) external returns (bool);

    function banBet(address betAddress_, bool lossSimulationFlag_)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IBetLiquidityHolder {
    function receiveLiquidityCreator(
        uint256 tokenLiquidity_,
        address tokenAddress_,
        address betCreator_,
        address betTrendSetter_,
        uint256 lossSimulationPercentage
    ) external;

    function receiveLiquidityTaker(
        uint256 tokenLiquidity_,
        address betTaker_,
        address registry_,
        bool forwarderFlag_
    ) external;

    function withdrawLiquidity(address user_) external payable;

    function claimReward(
        address betWinnerAddress_,
        address betLooserAddress_,
        address registry_,
        address agreegatorAddress_,
        bool lossSimulationFlag_
    ) external payable returns (bool);

    function processDrawMatch(address registry_, bool lossSimulationFlag_)
        external
        payable
        returns (bool);

    function processBan(address registry_, bool lossSimulationFlag_)
        external
        payable
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IConfig {

    function getLatestVersion() external view returns (uint);

    function getAdmin() external view returns (address);

    function getAaveTimeThresold() external view returns (uint256);

    function getBlacklistedAsset(address asset_) external view returns (bool);

    function setDisputeConfig(
        uint256 escrowAmount_,
        uint256 requirePaymentForJury_
    ) external returns (bool);

    function getDisputeConfig() external view returns (uint256, uint256);

    function setWalletAddress(address developer_, address escrow_)
        external
        returns (bool);

    function getWalletAddress() external view returns (address, address);

    function getTokensPerStrike(uint256 strike_)
        external
        view
        returns (uint256);

    function getJuryTokensShare(uint256 strike_, uint256 version_)
        external
        view
        returns (uint256);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_,
        uint256 pool_distribution_amount_without_trendsetter_,
        uint256 burn_amount_without_trendsetter
    ) external returns (bool);

    function setAaveFeeConfig(
        uint256 aave_apy_bet_winner_distrubution_,
        uint256 aave_apy_bet_looser_distrubution_
    ) external returns (bool);

    function getFeeDeductionConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAaveConfig() external view returns (uint256, uint256);

    function setAddresses(
        address lendingPoolAddressProvider_,
        address wethGateway_,
        address aWMATIC_,
        address aDAI_,
        address uniswapV2Factory,
        address uniswapV2Router
    )
        external
        returns (
            address,
            address,
            address,
            address
        );

    function getAddresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        );

    function setPairAddresses(address tokenA_, address tokenB_)
        external
        returns (bool);

    function getPairAddress(address tokenA_)
        external
        view
        returns (address, address);

    function getUniswapRouterAddress() external view returns (address);

    function getAaveRecovery()
        external
        view
        returns (
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IDisputeResolution {
    function stake() external returns (bool);

    function withdraw() external returns (bool);

    function createDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function createDispute(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external returns (bool);

    function processVerdict(
        bytes32 hash_,
        bytes memory signature_,
        uint256 selectedVerdict_,
        address betAddress_
    ) external returns (bool);

    function brodcastFinalVerdict(
        address betAddress_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function adminResolution(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        address[] memory users_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function getUserStrike(address user_) external view returns (uint256);

    function getJuryStrike(address user_) external view returns (uint256);

    function getBetStatus(address betAddress_)
        external
        view
        returns (bool, bool);

    function forwardVerdict(address betAddress_)
        external
        view
        returns (uint256);

    function adminResolutionForUnavailableEvidance(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external returns (bool);

    function getUserVoteStatus(address user_, address betAddress)
        external
        view
        returns (bool);

    function getJuryStatistics(address user_)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getJuryVersion(address user_) external view returns (uint256);

    function adminWithdrawal(address user_) external returns (bool status_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.6.12;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Interfaces/IUniswapV2Router02.sol";
import "../Interfaces/IERC20.sol";

library ProcessData {
    function rsvExtracotr(bytes32 hash_, bytes memory sig_)
        public
        pure
        returns (address)
    {
        require(sig_.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");
        return recoverSigner(hash_, v, r, s);
    }

    function recoverSigner(
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

    function getProofStatus(
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        address betInitiator_,
        address betTaker_
    ) public pure returns (bool _makerProof, bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = rsvExtracotr(hash_[0], maker_);
        a[1] = rsvExtracotr(hash_[1], taker_);
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == betInitiator_) {
                _makerProof = true;
            }
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == betTaker_) {
                _takerProof = true;
            }
        }
    }

    function resolutionClearance(
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        address betInitiator,
        address betTaker
    ) public pure returns (bool status_) {
        bool _makerProof;
        bool _takerProof;
        (_makerProof, _takerProof) = getProofStatus(
            hash_,
            maker_,
            taker_,
            betInitiator,
            betTaker
        );
        if (_makerProof || _takerProof) status_ = true;
    }

    function swapping(
        address uniswapV2Router_,
        address tokenA_,
        address tokenB_
    ) public view returns (uint256) {
        //IERC20(tokenB_).approve(uniswapV2Router_,address(this).balance);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint256[] memory amount = new uint256[](2);
        amount = tokenA_ == 0x5B67676a984807a212b1c59eBFc9B3568a474F0a
            ? IUniswapV2Router02(uniswapV2Router_).getAmountsOut(
                address(this).balance,
                t
            )
            : IUniswapV2Router02(uniswapV2Router_).getAmountsOut(
                IERC20(tokenA_).balanceOf(address(this)),
                t
            );
        return amount[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

// import "./BetLiquidityHolder.sol";
import "../MetadataConfig/TokenConfig.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IBetLiquidityHolder.sol";
import "../Interfaces/IDisputeResolution.sol";
import "../Interfaces/IBetFoundationFactory.sol";
import "../Interfaces/IConfig.sol";
import "../Libraries/ProcessData.sol";

contract BetFoundationFactory is TokenConfig, IBetFoundationFactory {
    address internal config;
    address internal aggregator;
    address internal disputeResolver;
    uint256 internal totalBets;

    constructor(
        address admin_,
        address config_,
        address aggregator_
    ) public {
        admin = admin_;
        config = config_;
        aggregator = aggregator_;
    }

    receive() external payable {}

    function setDisputeResolver(address resolver_) external returns (bool) {
        disputeResolver = resolver_;

        return true;
    }

    event BetCreated(address betAddress_);

    function createBet(
        address parentBet_,
        address betId_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_,
        uint256 lossSimulationPercentage_
    )
        external
        payable
        override
        isBetEndingTimeCorrect(betEndingTime_)
        returns (bool _status, address _betTrendSetter)
    {
        require(
            IDisputeResolution(disputeResolver).getUserStrike(tx.origin) < 5,
            "Strike Level Exceed"
        );
        require(betId_ != address(0), "Invalid BetId");
        // BetLiquidityHolder _blh = new BetLiquidityHolder();
        // address __blh = address(_blh);
        address _token = getTokenAddress(tokenId_);
        if (_token == address(0)) {
            (_status, _betTrendSetter) = setBetDetails(
                parentBet_,
                betId_,
                betTakerRequiredLiquidity_,
                betEndingTime_,
                tokenId_,
                totalBetOptions_,
                selectedOptionByUser_,
                tokenLiqidity_
            );

            payable(betId_).transfer(tokenLiqidity_);
        } else {
            (_status, _betTrendSetter) = setBetDetails(
                parentBet_,
                betId_,
                betTakerRequiredLiquidity_,
                betEndingTime_,
                tokenId_,
                totalBetOptions_,
                selectedOptionByUser_,
                tokenLiqidity_
            );
            require(
                ercForwarderToHolder(_token, betId_, tokenLiqidity_),
                "ERC Transfer Failed"
            );
        }
        IBetLiquidityHolder(betId_).receiveLiquidityCreator(
            tokenLiqidity_,
            _token,
            tx.origin,
            _betTrendSetter,
            lossSimulationPercentage_
        );
        emit BetCreated(betId_);

        return (true, _betTrendSetter);
    }

    event BetJoined(address betAddress_);

    function joinBet(
        address betAddress_,
        uint256 tokenLiqidity_,
        uint256 selectedOptionByUser_,
        uint256 tokenId_
    )
        external
        payable
        override
        isBetDetailCorrect(
            betAddress_,
            tokenLiqidity_,
            selectedOptionByUser_,
            address(this)
        )
        returns (bool)
    {
        // require(tx.origin != betDetails[betAddress_].betInitiator,"Initiator Is Available");
        require(
            IDisputeResolution(disputeResolver).getUserStrike(tx.origin) < 5,
            "Strike Level Exceed"
        );
        require(
            selectedOptionByUser_ != 0 &&
                tx.origin != betDetails[betAddress_].betInitiator,
            "Draw Option Or Same Address"
        );
        require(
            betDetails[betAddress_].selectedOptionByUser[
                selectedOptionByUser_
            ] == address(this),
            "This Option Is Already Selected"
        );
        require(
            tokenId_ == betDetails[betAddress_].tokenId,
            "Payment Must Be Same"
        );
        address _token = getTokenAddress(betDetails[betAddress_].tokenId);
        if (_token == address(0)) {
            payable(betAddress_).transfer(tokenLiqidity_);
        } else {
            require(
                ercForwarderToHolder(_token, betAddress_, tokenLiqidity_),
                "ERC Transfer Failed"
            );
        }
        betDetails[betAddress_].betTaker = tx.origin;
        betDetails[betAddress_].isTaken = true;
        betDetails[betAddress_].userLiquidity[tx.origin] = tokenLiqidity_;
        betDetails[betAddress_].selectedOptionByUser[selectedOptionByUser_] = tx
            .origin;
        bool _timeThresholdStatus;
        if (
            betDetails[betAddress_].betEndingTime >=
            betDetails[betAddress_].betStartingTime +
                IConfig(config).getAaveTimeThresold()
        ) {
            _timeThresholdStatus = true;
        }
        IBetLiquidityHolder(betAddress_).receiveLiquidityTaker(
            tokenLiqidity_,
            tx.origin,
            config,
            _timeThresholdStatus
        );
        emit BetJoined(betAddress_);

        return true;
    }

    function ercForwarderToHolder(
        address token_,
        address betAddress_,
        uint256 tokenLiqidity_
    ) internal returns (bool) {
        IERC20(token_).transferFrom(tx.origin, address(this), tokenLiqidity_);
        IERC20(token_).approve(betAddress_, tokenLiqidity_);
        IERC20(token_).transfer(betAddress_, tokenLiqidity_);
        return true;
    }

    function setBetDetails(
        address parentBet_,
        address holderAddress_,
        uint256 betTakerRequiredLiquidity_,
        uint256 betEndingTime_,
        uint256 tokenId_,
        uint256 totalBetOptions_,
        uint256 selectedOptionByUser_,
        uint256 tokenLiqidity_
    ) internal returns (bool, address) {
        address _betTrendSetter;
        betDetails[holderAddress_].parentBet = parentBet_;
        betDetails[holderAddress_].betInitiator = tx.origin;
        betDetails[holderAddress_].betTaker = address(0);
        betDetails[holderAddress_]
            .betTakerRequiredLiquidity = betTakerRequiredLiquidity_;
        betDetails[holderAddress_].betStartingTime = block.timestamp;
        betDetails[holderAddress_].betEndingTime = betEndingTime_;
        betDetails[holderAddress_].isTaken = false;
        betDetails[holderAddress_].tokenId = tokenId_;
        betDetails[holderAddress_].totalBetOptions = totalBetOptions_;
        for (uint256 i = 0; i <= totalBetOptions_; i++) {
            betDetails[holderAddress_].selectedOptionByUser[i] = address(this);
        }
        require(
            betDetails[holderAddress_].selectedOptionByUser[
                selectedOptionByUser_
            ] == address(this),
            "Selected Option Is Not Valid"
        );
        require(
            selectedOptionByUser_ != 0,
            "This Option Is Only Be Used For Draw"
        );
        betDetails[holderAddress_].selectedOptionByUser[
            selectedOptionByUser_
        ] = tx.origin;
        betDetails[holderAddress_].userLiquidity[tx.origin] = tokenLiqidity_;
        if (parentBet_ != address(0)) {
            _betTrendSetter = betDetails[parentBet_].betInitiator;

            replicatedBets[parentBet_].betTrendSetter = _betTrendSetter;
            uint256 _counter = replicatedBets[parentBet_].underlyingBetCounter;
            replicatedBets[parentBet_].underlyingBets[
                _counter
            ] = holderAddress_;
            replicatedBets[parentBet_].underlyingBetCounter += 1;
        }
        bets[totalBets] = holderAddress_;
        totalBets += 1;
        betStatus[holderAddress_] = true;
        return (true, _betTrendSetter);
    }

    function withdrawLiquidity(address betAddress_)
        external
        payable
        override
        isBetEligibleForWithdraw(betAddress_, tx.origin)
        returns (bool)
    {
        betDetails[betAddress_].userWithdrawalStatus[tx.origin] = true;
        IBetLiquidityHolder(betAddress_).withdrawLiquidity(tx.origin);

        return true;
    }

    event DrawMatch(address betAddress_);

    function resolveBet(
        address betAddress_,
        uint256 finalOption_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        bool isCustomized_,
        bool lossSimulationFlag_
    ) external override returns (bool) {
        (bool _resolved, bool _adminResolution) = IDisputeResolution(
            disputeResolver
        ).getBetStatus(betAddress_);
        address maker__ = betDetails[betAddress_].betInitiator;
        address taker__ = betDetails[betAddress_].betTaker;
        if (isCustomized_)
            require(
                ProcessData.resolutionClearance(
                    hash_,
                    maker_,
                    taker_,
                    maker__,
                    taker__
                ) || _adminResolution,
                "Not Provided Evidance Or Not Resolved"
            );
        require(
            betDetails[betAddress_].betEndingTime <= block.timestamp &&
                betStatus[betAddress_],
            "This Bet Has Not Been Ended Or Issue With Bet"
        );
        //require(betStatus[betAddress_],"Issue With Bet Status");
        require(
            betDetails[betAddress_].winner == address(0) ||
                !betDetails[betAddress_].isDrawed,
            "This Bet has Winner or Bet Is In Draw Stage"
        );
        require(!betDetails[betAddress_].isDisputed, "This Bet Has Dispute");
        setResolution(
            _resolved,
            _adminResolution,
            betAddress_,
            finalOption_,
            lossSimulationFlag_
        );
        return true;
    }

    function setResolution(
        bool _resolved,
        bool _adminResolution,
        address betAddress_,
        uint256 finalOption_,
        bool lossSimulationFlag_
    ) internal returns (bool) {
        if (_resolved || _adminResolution) {
            uint256 _verdict = IDisputeResolution(disputeResolver)
                .forwardVerdict(betAddress_);
            if (_verdict != 0) {
                require(
                    betDetails[betAddress_].selectedOptionByUser[_verdict] ==
                        betDetails[betAddress_].betInitiator ||
                        betDetails[betAddress_].selectedOptionByUser[
                            _verdict
                        ] ==
                        betDetails[betAddress_].betTaker,
                    "Not Valid Option"
                );
                (address _winner, address _looser) = getWinnerAddress(
                    betAddress_,
                    _verdict
                );
                betDetails[betAddress_].winner = _winner;
                IBetLiquidityHolder(betAddress_).claimReward(
                    _winner,
                    _looser,
                    config,
                    aggregator,
                    lossSimulationFlag_
                );
            } else {
                betDetails[betAddress_].isDrawed = true;
                IBetLiquidityHolder(betAddress_).processDrawMatch(
                    config,
                    lossSimulationFlag_
                );
                emit DrawMatch(betAddress_);
            }
            betDetails[betAddress_].winnerOption = _verdict;
        } else {
            if (finalOption_ != 0) {
                require(
                    betDetails[betAddress_].selectedOptionByUser[
                        finalOption_
                    ] ==
                        betDetails[betAddress_].betInitiator ||
                        betDetails[betAddress_].selectedOptionByUser[
                            finalOption_
                        ] ==
                        betDetails[betAddress_].betTaker,
                    "Not Valid Option"
                );
                (address _winner, address _looser) = getWinnerAddress(
                    betAddress_,
                    finalOption_
                );
                betDetails[betAddress_].winner = _winner;
                IBetLiquidityHolder(betAddress_).claimReward(
                    _winner,
                    _looser,
                    config,
                    aggregator,
                    lossSimulationFlag_
                );
            } else {
                betDetails[betAddress_].isDrawed = true;
                IBetLiquidityHolder(betAddress_).processDrawMatch(
                    config,
                    lossSimulationFlag_
                );
                emit DrawMatch(betAddress_);
            }
            betDetails[betAddress_].winnerOption = finalOption_;
        }
        betStatus[betAddress_] = false;

        return true;
    }

    function getWinnerAddress(address betAddress_, uint256 finalOption_)
        internal
        view
        returns (address winner_, address looser_)
    {
        winner_ = betDetails[betAddress_].selectedOptionByUser[finalOption_];
        winner_ == betDetails[betAddress_].betInitiator
            ? looser_ = betDetails[betAddress_].betTaker
            : looser_ = betDetails[betAddress_].betInitiator;
    }

    function banBet(address betAddress_, bool lossSimulationFlag_)
        external
        override
        isAdmin(admin)
        returns (bool)
    {
        require(betStatus[betAddress_], "Can Not Ban");
        betStatus[betAddress_] = false;
        IBetLiquidityHolder(betAddress_).processBan(
            config,
            lossSimulationFlag_
        );
        return true;
    }

    function raiseDispute(address betAddress_)
        external
        override
        returns (bool)
    {
        require(!betDetails[betAddress_].isDisputed, "Already Disputed");
        betDetails[betAddress_].isDisputed = true;

        return true;
    }

    function postDisputeProcess(address betAddress_)
        external
        override
        returns (bool)
    {
        //require(betDetails[betAddress_].isDisputed,"Already Disputed");
        betDetails[betAddress_].isDisputed = false;

        return true;
    }

    function provideBetData(address betAddress_)
        external
        view
        override
        returns (
            address betInitiator,
            address betTaker,
            uint256 totalBetOptions,
            bool isDisputed,
            bool _betStatus
        )
    {
        return (
            betDetails[betAddress_].betInitiator,
            betDetails[betAddress_].betTaker,
            betDetails[betAddress_].totalBetOptions,
            betDetails[betAddress_].isDisputed,
            betStatus[betAddress_]
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Utils/Modifiers.sol";
import "../Interfaces/IAdminConfig.sol";

contract Admin is Modifiers, IAdminConfig {
    address public admin;

    event AdminUpdated(address admin_);

    function updateAdmin(address admin_)
        external
        override
        isAdmin(admin)
        returns (bool)
    {
        admin = admin_;

        emit AdminUpdated(admin);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Utils/Mappings.sol";
import "../Utils/Modifiers.sol";
import "./AdminConfig.sol";

contract TokenConfig is Mappings, Modifiers, Admin {
    address[] private tokens;

    event TokenActivated(address tokenAddress_);
    event TokenDeActivated(address tokenAddress_);

    function setToken(address tokenAddress_)
        external
        isAdmin(admin)
        returns (bool)
    {
        if (!checkTokenExistance(tokenAddress_)) tokens.push(tokenAddress_);
        isTokenValid[tokenAddress_] = true;

        emit TokenActivated(tokenAddress_);

        return true;
    }

    // function removeToken(address tokenAddress_) public isAdmin(admin) returns (bool) {
    //     if (isTokenValid[tokenAddress_]) {
    //         isTokenValid[tokenAddress_] = false;
    //     }

    //     emit TokenDeActivated(tokenAddress_);

    //     return true;
    // }

    function checkTokenExistance(address tokenAddress_)
        public
        view
        returns (bool check_)
    {
        for (uint256 i; i < tokens.length; i++) {
            if (tokenAddress_ == tokens[i]) check_ = true;
        }

        return check_;
    }

    function getTokenAddress(uint256 tokenId_)
        public
        view
        returns (address tokenAddress_)
    {
        require(isTokenValid[tokens[tokenId_]], "Token Is Not Active");
        tokenAddress_ = tokens[tokenId_];
    }

    // function getAllTokens() public view returns (address[] memory) {
    //     return tokens;
    // }

    // function getAllActiveTokens() public view returns (address[] memory) {
    //     address[] memory _availableTokens = new address[](tokens.length);
    //     for (uint i; i < tokens.length; i++) {
    //         if (isTokenValid[tokens[i]]) {
    //             _availableTokens[i] = tokens[i];
    //         }
    //     }

    //     return _availableTokens;
    // }

    // function checkTokenValidity(address tokenAddress_)
    //     public
    //     view
    //     returns (bool status_)
    // {
    //     if (isTokenValid[tokenAddress_]) status_ = true;

    //     return status_;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./Structs.sol";

contract Mappings is Structs {
    mapping(uint256 => address) public bets;
    mapping(address => BetDetail) public betDetails;
    mapping(address => ReplicatedBet) public replicatedBets;
    mapping(address => bool) public betStatus;
    mapping(address => bool) public isTokenValid;
    mapping(address => DisputeRoom) public disputeRooms;
    mapping(address => uint256) public userStrikes;
    mapping(address => uint256) public juryStrike;
    mapping(address => uint256) public lastWithdrawal;
    mapping(address => uint256) public usersStake;
    mapping(address => uint256) public userInitialStake;
    mapping(address => bool) public isActiveStaker;
    mapping(address => uint256) public juryVersion;
    mapping(address => bool) public isAdminWithdrawed;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./Mappings.sol";
import "./Structs.sol";

contract Modifiers is Mappings {
    modifier isAdmin(address admin_) {
        require(tx.origin == admin_, "Caller Is Not Admin!!!");
        _;
    }

    modifier isBetEndingTimeCorrect(uint256 betEndingTime_) {
        require(
            betEndingTime_ >= block.timestamp,
            "Ending time can't be before current time"
        );
        _;
    }

    modifier isBetDetailCorrect(
        address betAddress_,
        uint256 tokenLiquidity_,
        uint256 selectedOptionByUser_,
        address foundationAddress_
    ) {
        require(
            betDetails[betAddress_].betTaker == address(0),
            "This Bet Has Already Bet Taker"
        );
        require(
            betDetails[betAddress_].betInitiator != address(0),
            "This Bet Is Not Available"
        );
        require(
            betDetails[betAddress_].betTakerRequiredLiquidity ==
                tokenLiquidity_,
            "Provide Enough Liquidity"
        );
        require(
            betDetails[betAddress_].betEndingTime > block.timestamp,
            "This Bet Is Terminated"
        );
        require(
            !betDetails[betAddress_].isTaken,
            "This Bet Has Been Already Taken"
        );
        require(betStatus[betAddress_], "This Bet Is Not Ongoing");
        require(
            betDetails[betAddress_].winner == address(0),
            "Winner Has Been Declared"
        );
        require(
            selectedOptionByUser_ != 0,
            "This Option Is Only Be Used For Draw"
        );
        require(
            betDetails[betAddress_].selectedOptionByUser[
                selectedOptionByUser_
            ] == foundationAddress_,
            "Selected Option Is Not Valid"
        );
        _;
    }

    modifier isBetEligibleForWithdraw(address betAddress_, address user_) {
        require(!betDetails[betAddress_].isTaken, "This Bet Has Bet Taker");
        require(
            !betDetails[betAddress_].userWithdrawalStatus[user_],
            "You can not withdraw"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract Structs {
    struct BetDetail {
        address parentBet;
        address betInitiator;
        address betTaker;
        address winner;
        uint256 betTakerRequiredLiquidity;
        uint256 betStartingTime;
        uint256 betEndingTime;
        uint256 tokenId;
        uint256 winnerOption;
        bool isTaken;
        bool isWithdrawed;
        uint256 totalBetOptions;
        bool isDisputed;
        bool isDrawed;
        mapping(address => bool) userWithdrawalStatus;
        mapping(uint256 => address) selectedOptionByUser;
        mapping(address => uint256) userLiquidity;
    }

    struct ReplicatedBet {
        address betTrendSetter;
        uint256 underlyingBetCounter;
        mapping(uint256 => address) underlyingBets;
    }

    struct DisputeRoom {
        address betCreator;
        address betTaker;
        uint256 totalOptions;
        uint256 finalOption;
        uint256 userStakeAmount;
        mapping(uint256 => address[]) selectedOptionByJury;
        mapping(uint256 => uint256) optionWeight;
        mapping(address => bool) isVerdictProvided;
        bool isResolvedByAdmin;
        uint256 disputeCreatedAt;
        bool isResolved;
        uint256 jurySize;
        uint256 disputedOption;
        bool isCustomized;
        address disputeCreator;
    }
}