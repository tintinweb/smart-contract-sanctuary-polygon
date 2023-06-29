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
import {IAaveV3Pool} from "./interfaces/IAaveV3Pool.sol";

/**
 * Simple router for AaveV3 pool contract that provides functionality to supply, borrow, repay or withdraw value to/from pool.
 */
contract AaveV3Router {
    constructor() {}

    event Supplied(
        address indexed _asset,
        uint256 indexed _amount,
        address _onBehalfOf,
        uint16 _referralCode
    );

    event Borrowed(
        address indexed _asset,
        uint256 indexed _amount,
        address _onBehalfOf,
        uint16 _referralCode,
        uint256 _interestRateMode
    );

    event Repaid(
        address indexed _asset,
        uint256 indexed _amount,
        address _onBehalfOf,
        uint256 _interestRateMode,
        uint256 _repaidValue
    );

    event Withdrawed(address indexed _asset, uint256 indexed _amount);

    /**
     * Function that supply value to Aave's V3 pool.
     * @param _aavePool address of aaveV3 pool.
     * @param _asset address of asset that we will provide as the collateral.
     * @param _amount amount of asset that we want to supply.
     * @param _onBehalfOf address of user that will connect to this collateral and will get interest.
     * @param _referralCode code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(
        address _aavePool,
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);

        IERC20(_asset).approve(_aavePool, _amount);
        IAaveV3Pool(_aavePool).supply(
            _asset,
            _amount,
            _onBehalfOf,
            _referralCode
        );

        emit Supplied(_asset, _amount, _onBehalfOf, _referralCode);
    }

    /**
     * Function that borrow assets from Aave's V3 pool.
     * @param _aavePool address of aaveV3 pool.
     * @param _interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable.
     * @param _asset address of asset that we want to borrow.
     * @param _amount amount of asset that we want to borrow.
     * @param _onBehalfOf the address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance.
     * @param _referralCode refferal code.
     */
    function borrow(
        address _aavePool,
        uint256 _interestRateMode,
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external {
        IAaveV3Pool(_aavePool).borrow(
            _asset,
            _amount,
            _interestRateMode,
            _referralCode,
            _onBehalfOf // msg.sender
        );

        IERC20(_asset).transfer(msg.sender, _amount);

        emit Borrowed(
            _asset,
            _amount,
            _onBehalfOf,
            _referralCode,
            _interestRateMode
        );
    }

    /**
     * Function that repay asset to Aave's V3 pool.
     * @param _aavePool address of aaveV3 pool.
     * @param _asset address of asset that we want to repay.
     * @param _amount amount of asset that we want to repay.
     * @param _interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable.
     * @param _onBehalfOf the address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed.
     */
    function repay(
        address _aavePool,
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        address _onBehalfOf
    ) external returns (uint256 _repaid) {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);

        IERC20(_asset).approve(_aavePool, _amount);
        _repaid = IAaveV3Pool(_aavePool).repay(
            _asset,
            _amount,
            _interestRateMode, 
            _onBehalfOf
        );

        emit Repaid(
            _asset,
            _amount,
            _onBehalfOf,
            _interestRateMode,
            _repaid
        );
    }

    /**
     * Function that withdraw asset from Aave's V3 pool.
     * @param _aavePool address of aaveV3 pool.
     * @param _aToken address of aToken that we will provide.
     * @param _asset address of asset that we want to withdraw.
     * @param _amount amount of asset that we want to withdraw.
     */
    function withdraw(
        address _aavePool,
        address _aToken,
        address _asset,
        uint256 _amount
    ) external {
        IERC20(_aToken).transferFrom(msg.sender, address(this), _amount);

        IERC20(_aToken).approve(_aavePool, _amount);

        IAaveV3Pool(_aavePool).withdraw(
            _asset,
            _amount,
            msg.sender
        );

        emit Withdrawed(_asset, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveV3Pool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    function withdraw(address asset, uint256 amount, address to) external;
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