// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IDAO, IERC20} from "./interfaces/IDAO.sol";
import {IAaveV3Router} from "./interfaces/IAaveV3Router.sol";
import {ISwapRouter} from "./interfaces/IUniswapV3SwapRouter.sol";

/**
 * Sample contract to manage borrowed value in our flow.
 * Basically, we want to swap our borrowed tokens to tokenToBuyVotes and then enter the proposal.
 */
contract BorrowManager {
    address immutable dao;
    address immutable swapRouter;
    address immutable tokenToBuyVotes;

    event SwapExecuted(
        uint256 indexed amountOut,
        address indexed to,
        bytes _path
    );

    /**
     * @param _dao address of the DAO.
     * @param _swapRouter address of the UniswapV3 swap router.
     * @param _tokenToBuyVotes address of the tokenToBuyVotes.
     */
    constructor(address _dao, address _swapRouter, address _tokenToBuyVotes) {
        dao = _dao;
        swapRouter = _swapRouter;
        tokenToBuyVotes = _tokenToBuyVotes;
    }
 

    /**
     * Function that executes swap from our borrowed asset to tokenToBuyVotes.
     * @param _asset address of asset that we are using as tokenIn.
     * @param _amountIn amount of tokenIn.
     * @param _minAmountOut min desired amount of tokens out from the swap.
     */
    function swapToTokensToBuyVotes(
        address _asset,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint24 _poolFee
    ) external {
        bytes memory _path = abi.encodePacked(
            _asset,
            _poolFee,
            tokenToBuyVotes
        );
        executeSwap(_asset, _amountIn, _minAmountOut, _path);
    }

    /**
     * Function that deposit tokenToBuyVotes to DAO and participate in proposal.
     * @param _amount of tokens to deposit in DAO.
     * @param _id id of proposal that we will partcipate in.
     * @param _decision for/against boolean flag for proposal.
     */
    function depositAndVote(
        uint256 _amount,
        uint256 _id,
        bool _decision
    ) external {

    }

    /**
     * Sample function to execute generic swap on UniswapV3
     * @param _asset address of asset that we are using as tokenIn.
     * @param _amountIn amount of tokenIn.
     * @param _minAmountOut min desired amount of tokens out from the swap.
     * @param _path hashed path of swap.
     */
    function executeSwap(
        address _asset,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes memory _path
    ) public {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amountIn);

        IERC20(_asset).approve(swapRouter, _amountIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter
        .ExactInputParams({
            path: _path,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _minAmountOut
        });

        uint256 amountOut = ISwapRouter(swapRouter).exactInput(params);

        emit SwapExecuted(amountOut, msg.sender, _path);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveV3Router {
    function supply(
        address _aavePool,
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function borrow(
        address _aavePool,
        address _aTokens,
        uint256 _interestRateMode,
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function withdraw(
        address _aavePool,
        address _aTokens,
        address _asset,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @dev Interface of the decentralized autonomous organization.
 */
interface IDAO {
    /* -------------------------------------------------- */
    /* --------------------- ERRORS --------------------- */
    /* -------------------------------------------------- */

    /// Reverts if minimum quorum is not reached.
    error InvalidQuorum();

    /// Reverts if proposal time is not ended.
    error InvalidTime();

    /// Reverts if proposal ID is invalid.
    error InvalidProposalId();

    /// Reverts if user trying to withdraw locked tokens.
    error UserTokensLocked();

    /// Reverts if user is already voted in a proposal.
    error AlreadyVoted();

    /// Reverts if trying to vote in finished proposal.
    error InvalidStage();

    /// Reverts if voter without deposit trying to vote.
    error InvalidDeposit();

    /* -------------------------------------------------- */
    /* ---------------------- ENUMS --------------------- */
    /* -------------------------------------------------- */

    enum ProposalStatus {
        UNDEFINED,
        ADDED,
        FINISHED
    }

    /* -------------------------------------------------- */
    /* -------------------- STRUCTS --------------------- */
    /* -------------------------------------------------- */

    struct Proposal {
        address recipient;
        uint96 end;
        uint128 votesFor;
        uint128 votesAgainst;
        bytes callData;
        string description;
        ProposalStatus status;
    }

    struct User {
        uint128 amount;
        uint128 lockedTill;
    }

    /* -------------------------------------------------- */
    /* --------------------- EVENTS --------------------- */
    /* -------------------------------------------------- */

    /**
     * @dev Emits every time proposal is added.
     *
     * @param proposalId Id of the proposal.
     * @param callData Call data for make a call to another contract.
     */
    event AddedProposal(uint256 indexed proposalId, bytes callData);

    /**
     * @dev Emits when some user is voted
     *
     * @param user Address of the user, which want to vote.
     * @param proposalId ID of the proposal, user want to vote
     * @param support Boolean value, represents the user opinion
     */
    event Voted(address indexed user, uint256 indexed proposalId, bool support);

    /**
     * @dev Emits every time proposal is finished.
     *
     * @param proposalId Id of the proposal.
     * @param isAccepted Result of the proposal.
     * @param isSuccessfulCall Result of the call.
     */
    event FinishedProposal(
        uint256 indexed proposalId,
        bool isAccepted,
        bool isSuccessfulCall
    );

    /**
     * @dev Emits when some user deposits any amount of tokens.
     *
     * @param user Address of the user, who deposits
     * @param amount Amount of tokens to deposit
     */
    event Deposited(address indexed user, uint256 amount);

    /**
     * @dev Emits when some user withdraws any amount of tokens.
     *
     * @param user Address of the user, who withdraws
     * @param amount Amount of tokens to withdraw
     */
    event Withdrawed(address indexed user, uint256 amount);

    /* -------------------------------------------------- */
    /* -------------------- FUNCTIONS ------------------- */
    /* -------------------------------------------------- */

    /**
     * @dev Adds the proposal for the voting.
     * NOTE: Anyone can add new proposal
     *
     * @param recipient Address of the contract to call the function with call data
     * @param description Short description of the proposal
     * @param callData Call data for calling the function with call()
     */
    function addProposal(
        address recipient,
        string memory description,
        bytes memory callData
    ) external;

    /**
     * @dev Votes for the particular proposal
     * NOTE: Before voting user should deposit some tokens into DAO
     *
     * @param id Proposal ID you want to vote for
     * @param support Represents your support of this proposal
     */
    function vote(uint256 id, bool support) external;

    /**
     * @dev Finishes the particular proposal
     * @notice Proposal could be finished after duration time
     * @notice Proposal considers successful if enough quorum is used for voting
     */
    function finishProposal(uint256 id) external;

    /**
     * @dev Deposits `amount` of tokens to the DAO
     *
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Withdraws all the tokens from DAO
     *
     * @notice Tokens could be withdrawn only after the longer proposal duration user votes for
     *
     */
    function withdraw() external;

    /**
     * @dev Sets the minimal quorum.
     *
     * @param newQuorum New minimal quorum you want to set.
     * @notice Only admin can call this funciton.
     */
    function setMinimalQuorum(uint256 newQuorum) external;

    /**
     * @dev Sets the debating period for proposals.
     *
     * @param newPeriod New debating period you want to set.
     * @notice Only admin can call this funciton.
     */
    function setDebatingPeriod(uint256 newPeriod) external;

    /**
     * @dev Returns the address of the voting token.
     */
    function asset() external view returns (address);

    /**
     * @dev Returns minimal quorum for the proposals.
     */
    function minimumQuorum() external view returns (uint256);

    /**
     * @dev Returns debating duration for the proposals.
     */
    function debatingDuration() external view returns (uint256);

    /**
     * @dev Returns the amount of the proposals.
     */
    function proposalId() external view returns (uint256);

    /**
     * @dev Returns information about sender
     */
    function getUserInfo() external view returns (User memory);

    /**
     * @dev Returns the voting status of the user
     *
     * @param user Address of the user
     * @param id Proposal ID
     */
    function getVotingStatus(
        address user,
        uint256 id
    ) external view returns (bool);

    /**
     * @dev Returns the proposal
     *
     * @param id ID of the proposal
     */
    function getProposal(uint256 id) external view returns (Proposal memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(
        ExactInputSingleParams memory params
    ) external returns (uint256 amountOut);

    function exactInput(
        ExactInputParams memory params
    ) external returns (uint256 amountOut);
}