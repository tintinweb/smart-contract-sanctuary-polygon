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

import "../Utils/Mappings.sol";
import "../Interfaces/IConfig.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IDisputeResolution.sol";
import "../Interfaces/IBetFoundationFactory.sol";
import "../Libraries/ProcessData.sol";

contract DisputeResolvers is Mappings, IDisputeResolution {
    address internal admin;
    address internal config;
    address internal aggregator;
    address internal Factory;
    address internal dbethAddress;

    uint256 internal jurySize;

    constructor(
        address admin_,
        address config_,
        address aggregator_,
        address dbethAddress_
    ) public {
        require(admin_ != address(0), "NON ZERO ADDRESS");
        require(config_ != address(0), "NON ZERO ADDRESS");
        require(aggregator_ != address(0), "NON ZERO ADDRESS");
        require(dbethAddress_ != address(0), "NON ZERO ADDRESS");
        admin = admin_;
        config = config_;
        aggregator = aggregator_;
        jurySize = 3;
        dbethAddress = dbethAddress_;
    }

    function setConfig_(address config_) external returns (bool) {
        require(tx.origin== admin, "Caller Is Not Admin");
        require(config_ != address(0), "NON ZERO ADDRESS");
        config = config_;

        return true;
    }

    function setAggregator(address aggregator_) external returns (bool) {
        require(tx.origin== admin, "Caller Is Not Admin");
        require(aggregator_ != address(0), "NON ZERO ADDRESS");
        aggregator = aggregator_;

        return true;
    }

    function setFactory(address factory_) external returns (bool) {
        require(tx.origin== admin, "Caller Is Not Admin");
        require(factory_ != address(0), "NON ZERO ADDRESS");
        Factory = factory_;

        return true;
    }

    function getJuryVersion(address user_)
        external
        view
        override
        returns (uint256)
    {
        return juryVersion[user_];
    }

    event DisputeRoomCreation(address indexed betAddress_);

    function stake() external override returns (bool) {
        require(juryStrike[tx.origin] < 4, "Strike Level Exceeds");
        require(usersStake[tx.origin] != 30000000000000000000, "Already Staked");
        if (juryVersion[tx.origin] == 0)
            juryVersion[tx.origin] = IConfig(config).getLatestVersion();
        uint256 amount;
        if (juryStrike[tx.origin] == 0) {
            (, amount) = IConfig(config).getDisputeConfig();
            // require(amount ==  lastWithdrawal[tx.origin],"Not Provided Enough Liquidity");
            usersStake[tx.origin] += amount;
            lastWithdrawal[tx.origin] = 0;
            userInitialStake[tx.origin] = amount;
            IERC20(dbethAddress).transferFrom(tx.origin, address(this), amount);
        } else {
            amount = lastWithdrawal[tx.origin];
            usersStake[tx.origin] += amount;
            lastWithdrawal[tx.origin] = 0;
            IERC20(dbethAddress).transferFrom(tx.origin, address(this), amount);
        }
        isActiveStaker[tx.origin] = true;

        return true;
    }

    function withdraw() external override returns (bool) {
        require(juryStrike[tx.origin] < 4, "Strike Level Exceeds");
        require(isActiveStaker[tx.origin], "User has withdrawed his funds");
        uint256 amount_ = calculateStrikeAmount(tx.origin);
        lastWithdrawal[tx.origin] = userInitialStake[tx.origin] - amount_;
        require(lastWithdrawal[tx.origin] != 0, "ZERO WITHDRAWAL");
        IERC20(dbethAddress).transfer(tx.origin, lastWithdrawal[tx.origin]);
        if (!isAdminWithdrawed[tx.origin])
            IERC20(dbethAddress).transfer(
                admin,
                (usersStake[tx.origin] - lastWithdrawal[tx.origin])
            );
        usersStake[tx.origin] = 0;
        isActiveStaker[tx.origin] = false;
        if (isAdminWithdrawed[tx.origin] == true)
            isAdminWithdrawed[tx.origin] = false;

        return true;
    }

    function createDisputeRoom(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external override returns (bool) {
        require(
            disputeRooms[betAddress_].betCreator == address(0),
            "Already Raised Dispute"
        );
        require(
            !isSignatureUsed[signature_],
            "Signature Has Been Already Used"
        );
        require(
            ProcessData.rsvExtracotr(hash_, signature_) == tx.origin,
            "Signature Not Verified"
        );
        if (ProcessData.rsvExtracotr(hash_, signature_) != address(0))
            isSignatureUsed[signature_] = true;
        address betInitiator;
        address betTaker;
        uint256 totalBetOptions;
        (betInitiator, betTaker, totalBetOptions, , ) = IBetFoundationFactory(
            Factory
        ).provideBetData(betAddress_);
        require(userStrikes[tx.origin] < 5, "Strike Level Exceed");
        require(
            hash_.length > 0 && signature_.length > 0,
            "Not Provided Evidance"
        );
        disputeRooms[betAddress_].betCreator = betInitiator;
        disputeRooms[betAddress_].betTaker = betTaker;
        disputeRooms[betAddress_].totalOptions = totalBetOptions + 1;
        disputeRooms[betAddress_].disputeCreatedAt = block.timestamp;
        disputeRooms[betAddress_].disputedOption = disputedOption_;
        IBetFoundationFactory(Factory).raiseDispute(betAddress_);
        disputeRooms[betAddress_].isCustomized = true;
        disputeRooms[betAddress_].disputeCreator = tx.origin;

        emit DisputeRoomCreation(betAddress_);

        return true;
    }

    function createDispute(
        address betAddress_,
        uint256 disputedOption_,
        bytes32 hash_,
        bytes memory signature_
    ) external override returns (bool) {
        require(
            disputeRooms[betAddress_].betCreator == address(0),
            "Already Raised Dispute"
        );
        require(
            !isSignatureUsed[signature_],
            "Signature Has Been Already Used"
        );
        require(
            ProcessData.rsvExtracotr(hash_, signature_) == tx.origin,
            "Signature Not Verified"
        );
        if (ProcessData.rsvExtracotr(hash_, signature_) != address(0))
            isSignatureUsed[signature_] = true;
        address betInitiator;
        address betTaker;
        uint256 totalBetOptions;
        (betInitiator, betTaker, totalBetOptions, , ) = IBetFoundationFactory(
            Factory
        ).provideBetData(betAddress_);
        // require(betTaker ==  tx.origin,"Only Bet Taker Can Raise Dispute");
        require(userStrikes[tx.origin] < 5, "Strike Level Exceed");
        require(
            hash_.length > 0 && signature_.length > 0,
            "Not Provided Evidance"
        );
        disputeRooms[betAddress_].betCreator = betInitiator;
        disputeRooms[betAddress_].betTaker = betTaker;
        disputeRooms[betAddress_].totalOptions = totalBetOptions + 1;
        //(uint escrowAmount,uint requirePaymentForRaiseDispute,uint requirePaymentForJury) = IConfig(config).getDisputeConfig();
        disputeRooms[betAddress_].userStakeAmount = IConfig(config)
            .getTokensPerStrike(userStrikes[tx.origin]);
        disputeRooms[betAddress_].disputeCreatedAt = block.timestamp;
        disputeRooms[betAddress_].disputedOption = disputedOption_;
        IBetFoundationFactory(Factory).raiseDispute(betAddress_);
        disputeRooms[betAddress_].isCustomized = true;
        disputeRooms[betAddress_].disputeCreator = tx.origin;
        IERC20(dbethAddress).transferFrom(
            tx.origin,
            address(this),
            IConfig(config).getTokensPerStrike(userStrikes[tx.origin])
        );

        emit DisputeRoomCreation(betAddress_);

        return true;
    }

    function processVerdict(
        bytes32 hash_,
        bytes memory signature_,
        uint256 selectedVerdict_,
        address betAddress_
    ) external override returns (bool) {
        require(juryStrike[tx.origin] < 4, "Strike Level Exceed");
        require(usersStake[tx.origin] > 0, "User Does Not Have Balance");
        require(
            !disputeRooms[betAddress_].isVerdictProvided[tx.origin],
            "Already Provided Verdict"
        );

        require(
            ProcessData.rsvExtracotr(hash_, signature_) == tx.origin,
            "Signature Not Verified"
        );
        require(
            !isSignatureUsed[signature_],
            "Signature Has Been Already Used"
        );
        if (ProcessData.rsvExtracotr(hash_, signature_) != address(0))
            isSignatureUsed[signature_] = true;
        disputeRooms[betAddress_].jurySize += 1;
        require(disputeRooms[betAddress_].jurySize <= jurySize, "Room Is Full");
        disputeRooms[betAddress_].selectedOptionByJury[selectedVerdict_].push(
            tx.origin
        );
        disputeRooms[betAddress_].optionWeight[selectedVerdict_] += 1;
        disputeRooms[betAddress_].isVerdictProvided[tx.origin] = true;

        return true;
    }

    function userStrikeManager(
        address betAddress_,
        bool _makerProof,
        bool _takerProof,
        uint256 _highestSelected
    ) internal {
        if (
            disputeRooms[betAddress_].betCreator ==
            disputeRooms[betAddress_].disputeCreator ||
            !_makerProof
        ) {
            if (
                disputeRooms[betAddress_].disputedOption != _highestSelected ||
                !_makerProof
            ) {
                userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            }
        } else if (
            disputeRooms[betAddress_].betTaker ==
            disputeRooms[betAddress_].disputeCreator ||
            !_takerProof
        ) {
            bool maker_one;
            bool taker_one;
            bool taker_two;
            if (disputeRooms[betAddress_].disputedOption != _highestSelected)
                taker_one = true;
            if (disputeRooms[betAddress_].disputedOption == _highestSelected)
                maker_one = true;
            if (!_takerProof) taker_two = true;
            if (!_makerProof) maker_one = false;
            if (maker_one)
                userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            if (taker_one || taker_two)
                userStrikes[disputeRooms[betAddress_].betTaker] += 1;
        }
    }

    function brodcastFinalVerdict(
        address betAddress_,
        bytes32[] memory hash_,
        bytes memory makerSig_,
        bytes memory takerSig_
    ) external override returns (bool) {
        require(
            jurySize == disputeRooms[betAddress_].jurySize,
            "Not Received Enough Votes"
        );
        require(
            !disputeRooms[betAddress_].isResolved ||
                !disputeRooms[betAddress_].isResolvedByAdmin,
            "This Bet Is Already Resolved"
        );
        require(hash_.length > 0, "Not Enough Evidance Provided");
        require(
            !isSignatureUsed[makerSig_],
            "Maker Signature Has Been Already Used"
        );
        require(
            !isSignatureUsed[takerSig_],
            "Taker Signature Has Been Already Used"
        );
        (uint256 _highestSelected, bool _isForAdmin) = calculateFinalVerdict(
            betAddress_
        );
        (bool _makerProof, bool _takerProof) = getProofStatus(
            hash_,
            makerSig_,
            takerSig_,
            betAddress_
        );
        if (!_makerProof && !_takerProof) _isForAdmin = true;
        require(!_isForAdmin, "Only Admin Can Resolve This Bet");
        if (ProcessData.rsvExtracotr(hash_[0], makerSig_) != address(0))
            isSignatureUsed[makerSig_] = true;
        if (ProcessData.rsvExtracotr(hash_[1], takerSig_) != address(0))
            isSignatureUsed[takerSig_] = true;
        disputeRooms[betAddress_].isResolved = true;
        disputeRooms[betAddress_].finalOption = _highestSelected;
        userStrikeManager(
            betAddress_,
            _makerProof,
            _takerProof,
            _highestSelected
        );
        if (_highestSelected == disputeRooms[betAddress_].disputedOption || _highestSelected == 0) {
            if (disputeRooms[betAddress_].userStakeAmount > 0)
                IERC20(dbethAddress).transfer(
                    disputeRooms[betAddress_].betTaker,
                    disputeRooms[betAddress_].userStakeAmount
                );
            // if(userStrikes[disputeRooms[betAddress_].betTaker] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betTaker] -= 1;
            // }
            //if(_makerProof) userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        } else {
            // if(userStrikes[disputeRooms[betAddress_].betCreator] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betCreator] -= 1;
            // }
            //if(_takerProof) userStrikes[disputeRooms[betAddress_].betTaker] += 1;
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        }
        uint256 escrowAmount;
        (escrowAmount, ) = IConfig(config).getDisputeConfig();
        for (
            uint256 i = 0;
            i <
            disputeRooms[betAddress_]
                .selectedOptionByJury[_highestSelected]
                .length;
            i++
        ) {
            if (_highestSelected == disputeRooms[betAddress_].disputedOption) {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] != 0) {
                //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] -= 1;
                // }
                address to = disputeRooms[betAddress_].selectedOptionByJury[
                    _highestSelected
                ][i];
                uint256 value = escrowAmount /
                    disputeRooms[betAddress_]
                        .selectedOptionByJury[_highestSelected]
                        .length;
                IERC20(dbethAddress).transferFrom(admin, to, value);
            } else {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] != 0) {
                //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[_highestSelected][i]] -= 1;
                // }
                if (disputeRooms[betAddress_].userStakeAmount > 0) {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[
                        _highestSelected
                    ][i];
                    uint256 value = disputeRooms[betAddress_].userStakeAmount /
                        disputeRooms[betAddress_]
                            .selectedOptionByJury[_highestSelected]
                            .length;
                    IERC20(dbethAddress).transfer(to, value);
                } else {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[
                        _highestSelected
                    ][i];
                    uint256 value = escrowAmount /
                        disputeRooms[betAddress_]
                            .selectedOptionByJury[_highestSelected]
                            .length;
                    IERC20(dbethAddress).transferFrom(admin, to, value);
                }
            }
        }
        for (uint256 i = 0; i < disputeRooms[betAddress_].totalOptions; i++) {
            if (i != _highestSelected) {
                for (
                    uint256 j = 0;
                    j <
                    disputeRooms[betAddress_].selectedOptionByJury[i].length;
                    j++
                ) {
                    //IERC20(dbethAddress).transfer(admin,calculateStrikeAmount(disputeRooms[betAddress_].selectedOptionByJury[i][j]));
                    address _temp = disputeRooms[betAddress_]
                        .selectedOptionByJury[i][j];
                    juryStrike[_temp] += 1;
                }
            }
        }

        return true;
    }

    function getProofStatus(
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        address betAddress_
    ) internal view returns (bool _makerProof, bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = ProcessData.rsvExtracotr(hash_[0], maker_);
        a[1] = ProcessData.rsvExtracotr(hash_[1], taker_);
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == disputeRooms[betAddress_].betCreator) {
                if (!_makerProof) _makerProof = true;
            }
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == disputeRooms[betAddress_].betTaker) {
                if (!_takerProof) _takerProof = true;
            }
        }
    }

    function calculateStrikeAmount(address user_)
        internal
        view
        returns (uint256)
    {
        uint256 amount;
        amount =
            (IConfig(config).getJuryTokensShare(
                juryStrike[user_],
                juryVersion[user_]
            ) * userInitialStake[user_]) /
            1e2;
        return (amount);
    }

    function calculateFinalVerdict(address betAddress_)
        internal
        view
        returns (uint256 _highestSelected, bool _isForAdmin)
    {
        uint256 _options = disputeRooms[betAddress_].totalOptions;
        uint256[] memory a = new uint256[](_options);

        for (uint256 i = 0; i < _options; i++) {
            a[i] = disputeRooms[betAddress_].optionWeight[i];
        }
        uint256 _temp;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == 1) _temp += 1;
        }
        if (_temp == 3) {
            _isForAdmin = true;
        } else {
            uint256 _highest;
            for (uint256 i = 0; i < a.length; i++) {
                if (a[i] > _highest) {
                    _highest = a[i];
                }
            }
            for (uint256 i = 0; i < a.length; i++) {
                if (a[i] == _highest) {
                    _highestSelected = i;
                }
            }
            if (_highestSelected == 3 || _highest == 1) {
                _isForAdmin = true;
            }
        }
    }

    function updateAdmin(address admin_) external returns (bool) {
        admin = admin_;

        return true;
    }

    function adminResolutionForUnavailableEvidance(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external override returns (bool) {
        require(tx.origin == admin, "Caller Is Not Owner");
        disputeRooms[betAddress_].finalOption = finalVerdictByAdmin_;
        disputeRooms[betAddress_].isResolvedByAdmin = true;
        (bool _makerProof, bool _takerProof) = getProofStatus(
            hash_,
            maker_,
            taker_,
            betAddress_
        );
        if (!_makerProof) {
            userStrikes[disputeRooms[betAddress_].betCreator] += 1;
        } else if (!_takerProof) {
            userStrikes[disputeRooms[betAddress_].betTaker] += 1;
        }
        IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);

        return true;
    }

    function adminResolution(
        address betAddress_,
        uint256 finalVerdictByAdmin_,
        address[] memory users_,
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_
    ) external override returns (bool) {
        require(tx.origin == admin, "Caller Is Not Owner");
        require(!disputeRooms[betAddress_].isResolved, "Already Resolved");
        disputeRooms[betAddress_].finalOption = finalVerdictByAdmin_;
        disputeRooms[betAddress_].isResolvedByAdmin = true;
        (bool _makerProof, bool _takerProof) = getProofStatus(
            hash_,
            maker_,
            taker_,
            betAddress_
        );
        userStrikeManager(
            betAddress_,
            _makerProof,
            _takerProof,
            finalVerdictByAdmin_
        );
        if (disputeRooms[betAddress_].disputedOption == finalVerdictByAdmin_ || finalVerdictByAdmin_ == 0) {
            // if(userStrikes[disputeRooms[betAddress_].betTaker] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betTaker] -= 1;
            // }
            //if(_makerProof) userStrikes[disputeRooms[betAddress_].betCreator] += 1;
            if (disputeRooms[betAddress_].userStakeAmount > 0)
                IERC20(dbethAddress).transfer(
                    disputeRooms[betAddress_].betTaker,
                    disputeRooms[betAddress_].userStakeAmount
                );
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        } else {
            // if(userStrikes[disputeRooms[betAddress_].betCreator] != 0) {
            //     userStrikes[disputeRooms[betAddress_].betCreator] -= 1;
            // }
            //if(_takerProof) userStrikes[disputeRooms[betAddress_].betTaker] += 1;
            IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
        }
        uint256 escrowAmount;
        (escrowAmount, ) = IConfig(config).getDisputeConfig();
        for (
            uint256 i = 0;
            i <
            disputeRooms[betAddress_]
                .selectedOptionByJury[finalVerdictByAdmin_]
                .length;
            i++
        ) {
            if (
                disputeRooms[betAddress_].disputedOption == finalVerdictByAdmin_
            ) {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] != 0) {
                //         juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] -= 1;
                // }
                address to = disputeRooms[betAddress_].selectedOptionByJury[
                    finalVerdictByAdmin_
                ][i];
                uint256 value = escrowAmount /
                    disputeRooms[betAddress_]
                        .selectedOptionByJury[finalVerdictByAdmin_]
                        .length;
                IERC20(dbethAddress).transferFrom(admin, to, value);
                // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
            } else {
                // if(juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] != 0) {
                //     juryStrike[disputeRooms[betAddress_].selectedOptionByJury[finalVerdictByAdmin_][i]] -= 1;
                // }
                if (disputeRooms[betAddress_].userStakeAmount > 0) {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[
                        finalVerdictByAdmin_
                    ][i];
                    uint256 value = disputeRooms[betAddress_].userStakeAmount /
                        disputeRooms[betAddress_]
                            .selectedOptionByJury[finalVerdictByAdmin_]
                            .length;
                    IERC20(dbethAddress).transfer(to, value);
                    // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
                } else {
                    address to = disputeRooms[betAddress_].selectedOptionByJury[
                        finalVerdictByAdmin_
                    ][i];
                    uint256 value = escrowAmount /
                        disputeRooms[betAddress_]
                            .selectedOptionByJury[finalVerdictByAdmin_]
                            .length;
                    IERC20(dbethAddress).transferFrom(admin, to, value);
                    // IBetFoundationFactory(Factory).postDisputeProcess(betAddress_);
                }
            }
        }
        for (uint256 i = 0; i < disputeRooms[betAddress_].totalOptions; i++) {
            if (i != finalVerdictByAdmin_) {
                for (
                    uint256 j = 0;
                    j <
                    disputeRooms[betAddress_].selectedOptionByJury[i].length;
                    j++
                ) {
                    //IERC20(dbethAddress).transfer(admin,calculateStrikeAmount(disputeRooms[betAddress_].selectedOptionByJury[i][j]));
                    address _temp = disputeRooms[betAddress_]
                        .selectedOptionByJury[i][j];
                    juryStrike[_temp] += 1;
                }
            }
        }
        for (uint256 i = 0; i < users_.length; i++) {
            juryStrike[users_[i]] += 1;
        }

        return true;
    }

    function getUserStrike(address user_)
        external
        view
        override
        returns (uint256)
    {
        return userStrikes[user_];
    }

    function getJuryStrike(address user_)
        external
        view
        override
        returns (uint256)
    {
        return juryStrike[user_];
    }

    function getBetStatus(address betAddress_)
        external
        view
        override
        returns (bool, bool)
    {
        return (
            disputeRooms[betAddress_].isResolved,
            disputeRooms[betAddress_].isResolvedByAdmin
        );
    }

    function forwardVerdict(address betAddress_)
        external
        view
        override
        returns (uint256)
    {
        return disputeRooms[betAddress_].finalOption;
    }

    function getUserVoteStatus(address user_, address betAddress)
        external
        view
        override
        returns (bool _status)
    {
        return disputeRooms[betAddress].isVerdictProvided[user_];
    }

    function getJuryStatistics(address user_)
        external
        view
        override
        returns (
            uint256 usersStake_,
            uint256 lastWithdrawal_,
            uint256 userInitialStake_,
            bool isActiveStaker_
        )
    {
        usersStake_ = usersStake[user_];
        lastWithdrawal_ = lastWithdrawal[user_];
        userInitialStake_ = userInitialStake[user_];
        isActiveStaker_ = isActiveStaker[user_];
    }

    function adminWithdrawal(address user_)
        external
        override
        returns (bool status_)
    {
        require(
            !isAdminWithdrawed[user_] || usersStake[user_] > 0,
            "Admin Has Already Withdrawed Or User Stake Is 0"
        );
        uint256 amount_ = calculateStrikeAmount(user_);
        uint256 temp = userInitialStake[tx.origin] - amount_;
        if (juryStrike[user_] == 4) {
            IERC20(dbethAddress).transfer(admin, usersStake[user_]);
        } else {
            IERC20(dbethAddress).transfer(admin, usersStake[user_] - temp);
        }
        isAdminWithdrawed[user_] = true;

        return true;
    }
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
    mapping(bytes => bool) public isSignatureUsed;
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