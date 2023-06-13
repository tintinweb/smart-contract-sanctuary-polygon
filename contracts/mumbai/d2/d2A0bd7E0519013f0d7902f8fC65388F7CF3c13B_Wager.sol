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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

contract Wager {
    struct Bet {
        // packing into two slots
        address long;
        address short;
        uint96 amount;
        uint96 expiration;
        // packing into one slot
        uint120 createdAt;
        uint128 openingPrice;
        bool isActive;
    }

    error TransferFailed();
    error BetDoesntExist();
    error BetAlreadyTaken();
    error BetHasNotYetExpired();
    error BetIsExpiredAlready();
    error BetIsActive();
    error NotYourBet();
    error AddressDidntWin();
    error AddressIsNotBetCreator();

    event BetMade(
        address initiator,
        bool long,
        uint256 indexed betId,
        uint96 amount,
        uint96 expiration,
        uint128 openingPrice
    );
    event JoinBet(address indexed joiner, uint256 indexed betId);
    event Withdrawn(address winner, uint256 indexed betId);
    event BetCanceled(address creator, uint256 indexed betId);

    // USDC returns true on transfer so we can omit SafeERC20 library
    uint256 internal betId;
    IERC20 internal usdc;
    AggregatorV3Interface internal priceFeed;

    mapping(uint256 => Bet) public bets;

    constructor(address _usdc, address _priceFeed) {
        usdc = IERC20(_usdc);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice cancel a bet if it has not been taken by the other side
    /// @param _betId id of the bet to cancel
    function cancelBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];

        if (bet.isActive) revert BetIsActive();

        address receiver = bet.long != address(0) ? bet.long : bet.short;
        if (receiver != msg.sender) revert AddressIsNotBetCreator();

        bool sent = usdc.transfer(msg.sender, bet.amount);
        if (!sent) revert TransferFailed();

        emit BetCanceled(msg.sender, _betId);

        delete bets[_betId];
    }

    /// @notice used to open a bet
    /// @param _amount amount of USDC which will be taken from openers address
    /// @param _expiration amount in seconds after which a bet will be closed
    /// @param _long if long is true, then msg.sender takes long, if false, then short
    function openBet(uint96 _amount, uint96 _expiration, bool _long) external {
        bool sent = usdc.transferFrom(msg.sender, address(this), _amount);
        if (!sent) revert TransferFailed();

        uint256 assetPrice = getLatestPrice();

        if (_long) {
            bets[betId] = Bet(
                msg.sender,
                address(0),
                _amount,
                _expiration,
                uint112(block.timestamp),
                uint128(assetPrice),
                false
            );
        } else {
            bets[betId] = Bet(
                address(0),
                msg.sender,
                _amount,
                _expiration,
                uint112(block.timestamp),
                uint128(assetPrice),
                false
            );
        }

        emit BetMade(
            msg.sender,
            _long,
            betId,
            _amount,
            _expiration,
            uint128(assetPrice)
        );

        unchecked {
            ++betId;
        }
    }

    /// @notice joins a bet which has not yet been joined
    /// @param _betId id of the bet to join
    function joinBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];

        if (bet.long == address(0) && bet.short == address(0))
            revert BetDoesntExist();

        if (bet.createdAt + bet.expiration <= block.timestamp)
            revert BetIsExpiredAlready();

        if (bet.isActive) revert BetAlreadyTaken();

        bool sent = usdc.transferFrom(msg.sender, address(this), bet.amount);
        if (!sent) revert TransferFailed();

        if (bet.short == address(0)) {
            bet.short = msg.sender;
        } else {
            bet.long = msg.sender;
        }

        bet.isActive = true;
        emit JoinBet(msg.sender, _betId);
    }

    /// @notice resolves a bet and withdraws reward from a bet which has been resolved
    /// @param _betId id of the bet to resolve
    function resolveAndWithdraw(uint256 _betId) external {
        Bet storage bet = bets[_betId];

        if (block.timestamp <= bet.expiration + bet.createdAt)
            revert BetHasNotYetExpired();

        if (!(bet.long == msg.sender || bet.short == msg.sender))
            revert NotYourBet();

        uint256 closingPrice = getLatestPrice();

        bool won = (bet.long == msg.sender &&
            closingPrice > bet.openingPrice) ||
            (bet.short == msg.sender && closingPrice < bet.openingPrice);

        if (!won) revert AddressDidntWin();

        bool sent = usdc.transfer(msg.sender, bet.amount * 2);
        if (!sent) revert TransferFailed();

        delete bets[_betId];
        emit Withdrawn(msg.sender, _betId);
    }

    function getLatestPrice() internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}