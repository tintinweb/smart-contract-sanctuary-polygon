/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: MIT
// File: contracts/Interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

// File: contracts/Interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.12;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/Interfaces/IConfig.sol


pragma solidity >=0.6.12;

interface IConfig {

    function getAdmin() external view returns(address);
    function getAaveTimeThresold() external view returns(uint);
    function getBlacklistedAsset(address asset_) external view returns(bool);

    function setDisputeConfig(uint escrowAmount_,uint requirePaymentForJury_) external returns(bool);
    function getDisputeConfig() external view returns(uint,uint);

    function setWalletAddress(address developer_,address escrow_) external returns(bool);
    function getWalletAddress() external view returns(address,address);

    function getTokensPerStrike(uint strike_) external view returns(uint);
    function getJuryTokensShare(uint strike_,uint version_) external view returns(uint);

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
    ) external returns(bool);

    function setAaveFeeConfig(
        uint aave_apy_bet_winner_distrubution_,
        uint aave_apy_bet_looser_distrubution_
    ) external returns(bool);

    function getFeeDeductionConfig() external view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,uint);

    function getAaveConfig() external view returns(uint,uint);
    
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

    function getAddresses() external view returns(address,address,address,address,address,address);

    function setPairAddresses(address tokenA_,address tokenB_) external returns(bool);

    function getPairAddress(address tokenA_) external view returns(address,address);

    function getUniswapRouterAddress() external view returns(address);

    function getAaveRecovery() external view returns(address,address,address);


}
// File: contracts/Interfaces/IBetFoundationFactory.sol


pragma solidity >=0.6.12;

interface IBetFoundationFactory {
    function provideBetData(address betAddress_) external view returns(address,address,uint,bool,bool);
    function raiseDispute(address betAddress_) external returns(bool);
    function postDisputeProcess(address betAddress_) external returns(bool);
        function createBet(
        address parentBet_,
        address betId_,
        uint betTakerRequiredLiquidity_,
        uint betEndingTime_,
        uint tokenId_,
        uint totalBetOptions_,
        uint selectedOptionByUser_,
        uint tokenLiqidity_,
        uint lossSimulationPercentage_
    ) external payable returns (bool _status,address _betTrendSetter);
    function joinBet(
        address betAddress_,
        uint tokenLiqidity_,
        uint selectedOptionByUser_,
        uint tokenId_
    )
        external
        payable
        returns (bool);
    function withdrawLiquidity(address betAddress_) external payable returns (bool);
    function resolveBet(address betAddress_,uint finalOption_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,bool isCustomized_,bool lossSimulationFlag_) external returns(bool);
    function banBet(address betAddress_,bool lossSimulationFlag_) external returns(bool);
}
// File: contracts/Interfaces/IDisputeResolution.sol


pragma solidity >=0.6.12;

interface IDisputeResolution {
    function stake() external returns(bool);
    function withdraw() external returns(bool);
    function createDisputeRoom(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external returns (bool);
    function createDispute(address betAddress_,uint disputedOption_,bytes32 hash_,bytes memory signature_) external returns(bool);
    function processVerdict(bytes32 hash_,bytes memory signature_,uint selectedVerdict_,address betAddress_) external returns(bool);   
    function brodcastFinalVerdict(address betAddress_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function adminResolution(address betAddress_,uint finalVerdictByAdmin_,address[] memory users_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function getUserStrike(address user_) external view returns(uint);
    function getJuryStrike(address user_) external view returns(uint);
    function getBetStatus(address betAddress_) external view returns(bool,bool);
    function forwardVerdict(address betAddress_) external view returns(uint);
    function adminResolutionForUnavailableEvidance(address betAddress_,uint finalVerdictByAdmin_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_) external returns(bool);
    function getUserVoteStatus(address user_,address betAddress) external view returns (bool);
    function getJuryStatistics(address user_) external view returns (uint,uint,uint,bool);
    function getJuryVersion(address user_) external view returns (uint);
}
// File: contracts/Interfaces/IBetLiquidityHolder.sol



pragma solidity >=0.6.12;

interface IBetLiquidityHolder {
    function receiveLiquidityCreator(uint tokenLiquidity_,address tokenAddress_,address betCreator_,address betTrendSetter_,uint lossSimulationPercentage) external;
    function receiveLiquidityTaker(uint tokenLiquidity_,address betTaker_,address registry_,bool forwarderFlag_) external;
    function withdrawLiquidity(address user_) external payable;
    function claimReward(address betWinnerAddress_,address betLooserAddress_,address registry_ ,address agreegatorAddress_,bool lossSimulationFlag_) external payable returns(bool);
    function processDrawMatch(address registry_,bool lossSimulationFlag_) external payable returns(bool);
    function processBan(address registry_,bool lossSimulationFlag_) external payable returns(bool);
}
// File: contracts/Interfaces/IERC20.sol


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

// File: contracts/Libraries/ProcessData.sol


pragma solidity >=0.6.12;




library ProcessData {
    
    function rsvExtracotr(bytes32 hash_,bytes memory sig_) public pure returns (address) {
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

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) public pure returns(address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }    

    function getProofStatus(bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,address betInitiator_,address betTaker_) public pure returns(bool _makerProof,bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = rsvExtracotr(hash_[0],maker_);
        a[1] = rsvExtracotr(hash_[1],taker_);
        for(uint i=0;i<a.length;i++) {
            if(a[i] == betInitiator_) {
                _makerProof = true;
            }
        }
        for(uint i=0;i<a.length;i++) {
            if(a[i] == betTaker_) {
                _takerProof = true;
            }
        }
    }

    function resolutionClearance(bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,address betInitiator,address betTaker) public pure returns(bool status_) {
        bool _makerProof;bool _takerProof;
        (_makerProof,_takerProof) =  getProofStatus(hash_,maker_,taker_,betInitiator,betTaker);
        if(_makerProof || _takerProof) status_ = true;
    }

    function swapping(address uniswapV2Router_,address tokenA_,address tokenB_) public view returns(uint) {
        //IERC20(tokenB_).approve(uniswapV2Router_,address(this).balance);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint[] memory amount = new uint[](2);
        amount = tokenA_ == 0x5B67676a984807a212b1c59eBFc9B3568a474F0a ? IUniswapV2Router02(uniswapV2Router_).getAmountsOut(address(this).balance,t) : IUniswapV2Router02(uniswapV2Router_).getAmountsOut(IERC20(tokenA_).balanceOf(address(this)),t);
        return amount[1];
    }

}
// File: contracts/Interfaces/IAdminConfig.sol



pragma solidity >=0.6.12;


interface IAdminConfig {
    function updateAdmin(address admin_) external returns(bool);
}
// File: contracts/Utils/Structs.sol


pragma solidity >=0.6.12;

contract Structs {

    struct BetDetail {
        address parentBet;
        address betInitiator;
        address betTaker;
        address winner;
        uint betTakerRequiredLiquidity;
        uint betStartingTime;
        uint betEndingTime;
        uint tokenId;
        uint winnerOption;
        bool isTaken;
        bool isWithdrawed;
        uint totalBetOptions;
        bool isDisputed;
        bool isDrawed;
        mapping(address => bool) userWithdrawalStatus;
        mapping(uint => address) selectedOptionByUser;
        mapping(address => uint) userLiquidity;
    }

    struct ReplicatedBet {
        address betTrendSetter;
        uint underlyingBetCounter;
        mapping(uint => address) underlyingBets;
    }

    struct DisputeRoom {
        address betCreator;
        address betTaker;
        uint totalOptions;
        uint finalOption;
        uint userStakeAmount;
        mapping (uint => address[]) selectedOptionByJury;
        mapping (uint => uint) optionWeight;
        mapping (address => bool) isVerdictProvided;
        bool isResolvedByAdmin;
        uint disputeCreatedAt;
        bool isResolved;
        uint jurySize;
        uint disputedOption;
        bool isCustomized;
        address disputeCreator;
    }

}

// File: contracts/Utils/Mappings.sol


pragma solidity >=0.6.12;


contract Mappings is Structs {
    mapping(uint => address) public bets;
    mapping(address => BetDetail) public betDetails;
    mapping(address => ReplicatedBet) public replicatedBets;
    mapping(address => bool) public betStatus;
    mapping(address => bool) public isTokenValid;
    mapping(address => DisputeRoom) public disputeRooms;
    mapping(address => uint) public userStrikes;
    mapping(address => uint) public juryStrike;
    mapping(address => uint) public lastWithdrawal;
    mapping(address => uint) public usersStake;
    mapping(address => uint) public userInitialStake;
    mapping(address => bool) public isActiveStaker;
    mapping(address => uint) public juryVersion; 
}

// File: contracts/Utils/Modifiers.sol


pragma solidity >=0.6.12;



contract Modifiers is Mappings {

    modifier isAdmin(address admin_) {
        require(tx.origin == admin_, "Caller Is Not Admin!!!");
        _;
    }

    modifier isBetEndingTimeCorrect(uint betEndingTime_) {
        require(betEndingTime_ >= block.timestamp, "Ending time can't be before current time");
        _;
    }

    modifier isBetDetailCorrect(address betAddress_,uint tokenLiquidity_,uint selectedOptionByUser_,address foundationAddress_) {
        require(betDetails[betAddress_].betTaker == address(0), "This Bet Has Already Bet Taker");
        require(betDetails[betAddress_].betInitiator != address(0), "This Bet Is Not Available");
        require(betDetails[betAddress_].betTakerRequiredLiquidity == tokenLiquidity_, "Provide Enough Liquidity");
        require(betDetails[betAddress_].betEndingTime > block.timestamp, "This Bet Is Terminated");
        require(!betDetails[betAddress_].isTaken, "This Bet Has Been Already Taken");        
        require(betStatus[betAddress_],"This Bet Is Not Ongoing");
        require(betDetails[betAddress_].winner == address(0),"Winner Has Been Declared");
        require(selectedOptionByUser_ != 0, "This Option Is Only Be Used For Draw");
        require(betDetails[betAddress_].selectedOptionByUser[selectedOptionByUser_] == foundationAddress_,"Selected Option Is Not Valid");
        _;
    }

    modifier isBetEligibleForWithdraw(address betAddress_,address user_) {
        require(!betDetails[betAddress_].isTaken,"This Bet Has Bet Taker");
        require(!betDetails[betAddress_].userWithdrawalStatus[user_],"You can not withdraw");
        _;
    }

}
// File: contracts/MetadataConfig/AdminConfig.sol


pragma solidity >=0.6.12;



contract Admin is Modifiers,IAdminConfig {

    address public admin;

    event AdminUpdated(address admin_);

    function updateAdmin(address admin_) external override isAdmin(admin) returns(bool) {
        admin = admin_;

        emit AdminUpdated(admin);
        
        return true;
    }

}
// File: contracts/MetadataConfig/TokenConfig.sol


pragma solidity 0.6.12;




contract TokenConfig is Mappings, Modifiers, Admin {
    address[] private tokens;

    event TokenActivated(address tokenAddress_);
    event TokenDeActivated(address tokenAddress_);

    function setToken(address tokenAddress_) external isAdmin(admin) returns (bool) {
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
        for (uint i; i < tokens.length; i++) {
            if (tokenAddress_ == tokens[i]) check_ = true;
        }

        return check_;
    }

    function getTokenAddress(uint tokenId_)
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

// File: contracts/MainContractBucket/BetFoundationFactory.sol


pragma solidity >=0.6.12;

// import "./BetLiquidityHolder.sol";









contract BetFoundationFactory is TokenConfig,IBetFoundationFactory {

    address internal config;
    address internal aggregator;
    address internal disputeResolver;
    uint internal totalBets;

    constructor(address admin_,address config_,address aggregator_) public {
        admin = admin_;
        config = config_;
        aggregator = aggregator_;
    }

    receive() external payable{}

    function setDisputeResolver(address resolver_) external returns(bool) {
        disputeResolver = resolver_;

        return true;
    }

    event BetCreated(address betAddress_);

    function createBet(
        address parentBet_,
        address betId_,
        uint betTakerRequiredLiquidity_,
        uint betEndingTime_,
        uint tokenId_,
        uint totalBetOptions_,
        uint selectedOptionByUser_,
        uint tokenLiqidity_,
        uint lossSimulationPercentage_
    ) external payable override isBetEndingTimeCorrect(betEndingTime_) returns (bool _status,address _betTrendSetter) {
        require(IDisputeResolution(disputeResolver).getUserStrike(tx.origin) < 5, "Strike Level Exceed");
        require(betId_ != address(0), "Invalid BetId");
        // BetLiquidityHolder _blh = new BetLiquidityHolder();
        // address __blh = address(_blh);
        address _token = getTokenAddress(tokenId_);
        if (_token == address(0)) {
            (_status, _betTrendSetter) =
                setBetDetails(
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
            (_status, _betTrendSetter) =
                setBetDetails(
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


        return (true,_betTrendSetter);
    }

    event BetJoined(address betAddress_);

    function joinBet(
        address betAddress_,
        uint tokenLiqidity_,
        uint selectedOptionByUser_,
        uint tokenId_
    )
        external
        payable
        override
        isBetDetailCorrect(betAddress_, tokenLiqidity_,selectedOptionByUser_,address(this))
        returns (bool)
    {
        // require(tx.origin != betDetails[betAddress_].betInitiator,"Initiator Is Available");
        require(IDisputeResolution(disputeResolver).getUserStrike(tx.origin) < 5, "Strike Level Exceed");
        require(selectedOptionByUser_ != 0 && tx.origin != betDetails[betAddress_].betInitiator, "Draw Option Or Same Address");
        require(betDetails[betAddress_].selectedOptionByUser[selectedOptionByUser_] == address(this),"This Option Is Already Selected");
        require(tokenId_ == betDetails[betAddress_].tokenId,"Payment Must Be Same");
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
        betDetails[betAddress_].selectedOptionByUser[
            selectedOptionByUser_
        ] = tx.origin;
        bool _timeThresholdStatus;
        if(betDetails[betAddress_].betEndingTime >= betDetails[betAddress_].betStartingTime + IConfig(config).getAaveTimeThresold()){
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
        uint tokenLiqidity_
    ) internal returns (bool) { 
            IERC20(token_).transferFrom(tx.origin,address(this),tokenLiqidity_);
            IERC20(token_).approve(betAddress_,tokenLiqidity_);
            IERC20(token_).transfer(betAddress_,tokenLiqidity_);
        return true;
    }

    function setBetDetails(
        address parentBet_,
        address holderAddress_,
        uint betTakerRequiredLiquidity_,
        uint betEndingTime_,
        uint tokenId_,
        uint totalBetOptions_,
        uint selectedOptionByUser_,
        uint tokenLiqidity_
    ) internal returns (bool,address) {
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
        for(uint i=0; i<=totalBetOptions_;i++) {
            betDetails[holderAddress_].selectedOptionByUser[
                i
            ] = address(this);    
        }
        require(betDetails[holderAddress_].selectedOptionByUser[selectedOptionByUser_] == address(this),"Selected Option Is Not Valid");
        require(selectedOptionByUser_ != 0, "This Option Is Only Be Used For Draw");
        betDetails[holderAddress_].selectedOptionByUser[
            selectedOptionByUser_
        ] = tx.origin;
        betDetails[holderAddress_].userLiquidity[tx.origin] = tokenLiqidity_;
        if (parentBet_ != address(0)) {

            _betTrendSetter = betDetails[parentBet_].betInitiator;

            replicatedBets[parentBet_].betTrendSetter = _betTrendSetter;
            uint _counter = replicatedBets[parentBet_].underlyingBetCounter;
            replicatedBets[parentBet_].underlyingBets[
                _counter
            ] = holderAddress_;
            replicatedBets[parentBet_].underlyingBetCounter += 1;
        }
        bets[totalBets] = holderAddress_;
        totalBets += 1;
        betStatus[holderAddress_] = true;
        return (true,_betTrendSetter);
    }

    function withdrawLiquidity(address betAddress_) external override isBetEligibleForWithdraw(betAddress_,tx.origin) payable returns (bool) {
        betDetails[betAddress_].userWithdrawalStatus[tx.origin] = true;
        IBetLiquidityHolder(betAddress_).withdrawLiquidity(tx.origin);

        return true;
    }

    event DrawMatch(address betAddress_);
 
    function resolveBet(address betAddress_,uint finalOption_,bytes32[] memory hash_,bytes memory maker_,bytes memory taker_,bool isCustomized_,bool lossSimulationFlag_) external override returns(bool) {
        (bool _resolved,bool _adminResolution) = IDisputeResolution(disputeResolver).getBetStatus(betAddress_);
        address maker__ = betDetails[betAddress_].betInitiator;address taker__ = betDetails[betAddress_].betTaker;
        if(isCustomized_)  require(ProcessData.resolutionClearance(hash_,maker_,taker_,maker__,taker__) || _adminResolution,"Not Provided Evidance Or Not Resolved");
        require(betDetails[betAddress_].betEndingTime <= block.timestamp && betStatus[betAddress_],"This Bet Has Not Been Ended Or Issue With Bet");
        //require(betStatus[betAddress_],"Issue With Bet Status");
        require(betDetails[betAddress_].winner == address(0) || !betDetails[betAddress_].isDrawed,"This Bet has Winner or Bet Is In Draw Stage");
        require(!betDetails[betAddress_].isDisputed,"This Bet Has Dispute");
        setResolution(_resolved,_adminResolution,betAddress_,finalOption_,lossSimulationFlag_);        
        return true;
        
    }

    function setResolution(bool _resolved,bool _adminResolution,address betAddress_,uint finalOption_,bool lossSimulationFlag_) internal returns(bool) {
        if(_resolved || _adminResolution) {
            uint _verdict = IDisputeResolution(disputeResolver).forwardVerdict(betAddress_);
            if(_verdict != 0) {
                require(betDetails[betAddress_].selectedOptionByUser[_verdict] == betDetails[betAddress_].betInitiator || betDetails[betAddress_].selectedOptionByUser[_verdict] == betDetails[betAddress_].betTaker,"Not Valid Option");
                (address _winner,address _looser) = getWinnerAddress(betAddress_,_verdict);
                betDetails[betAddress_].winner = _winner;
                IBetLiquidityHolder(betAddress_).claimReward(_winner,_looser,config,aggregator,lossSimulationFlag_);
            } else {
                betDetails[betAddress_].isDrawed = true;
                IBetLiquidityHolder(betAddress_).processDrawMatch(config,lossSimulationFlag_);
                emit DrawMatch(betAddress_);
            }
            betDetails[betAddress_].winnerOption = _verdict;            
        } else {
            if(finalOption_ != 0) {
                require(betDetails[betAddress_].selectedOptionByUser[finalOption_] == betDetails[betAddress_].betInitiator || betDetails[betAddress_].selectedOptionByUser[finalOption_] == betDetails[betAddress_].betTaker,"Not Valid Option");
                (address _winner,address _looser) = getWinnerAddress(betAddress_,finalOption_);
                betDetails[betAddress_].winner = _winner;
                IBetLiquidityHolder(betAddress_).claimReward(_winner,_looser,config,aggregator,lossSimulationFlag_);
            } else {
                betDetails[betAddress_].isDrawed = true;
                IBetLiquidityHolder(betAddress_).processDrawMatch(config,lossSimulationFlag_);
                emit DrawMatch(betAddress_);
            }
            betDetails[betAddress_].winnerOption = finalOption_;
        }
        betStatus[betAddress_] = false;

        return true;
    }

    function getWinnerAddress(address betAddress_,uint finalOption_) internal view returns(address winner_,address looser_) {
        winner_ = betDetails[betAddress_].selectedOptionByUser[finalOption_];
        winner_ == betDetails[betAddress_].betInitiator ? looser_ = betDetails[betAddress_].betTaker : looser_ = betDetails[betAddress_].betInitiator;
    }

    function banBet(address betAddress_,bool lossSimulationFlag_) external override isAdmin(admin) returns(bool) {
        require(betStatus[betAddress_],"Can Not Ban");
        betStatus[betAddress_] = false;
        IBetLiquidityHolder(betAddress_).processBan(config,lossSimulationFlag_);
        return true;
    }

    function raiseDispute(address betAddress_) external override returns(bool) {
        require(!betDetails[betAddress_].isDisputed,"Already Disputed");
        betDetails[betAddress_].isDisputed = true;

        return true;
    }

    function postDisputeProcess(address betAddress_) external override returns(bool) {
        //require(betDetails[betAddress_].isDisputed,"Already Disputed");
        betDetails[betAddress_].isDisputed = false;

        return true;
    }
    function provideBetData(address betAddress_) external view override returns(address betInitiator,address betTaker,uint totalBetOptions,bool isDisputed,bool _betStatus) {
        return (betDetails[betAddress_].betInitiator,betDetails[betAddress_].betTaker,betDetails[betAddress_].totalBetOptions,betDetails[betAddress_].isDisputed,betStatus[betAddress_]);
    }

}