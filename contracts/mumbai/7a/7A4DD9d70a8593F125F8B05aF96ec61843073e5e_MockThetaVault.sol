// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockThetaVault {
    address oTokenAddress;
    address public strikeSelection;
    address asset;
    uint256 auctionID;
    uint256 public currentOTokenPremium;
    uint256 nextOptionReadyAt;
    uint256 strikePrice;

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    function set(
        address _oTokenAddress,
        address _asset,
        address _strikeSelection,
        uint256 _auctionID
    ) external {
        require(strikePrice > 0, "strikePrice should be greater than zero");
        require(
            (_strikeSelection != address(0)) && (_asset != address(0)),
            "_strikeSelection should not be a zero address"
        );
        oTokenAddress = _oTokenAddress;
        asset = _asset;
        strikeSelection = _strikeSelection;
        auctionID = _auctionID;
    }

    function setRandomVal() private returns (uint256) {
        return (block.timestamp);
    }

    function reset() external {
        oTokenAddress = address(0);
        asset = address(0);
        strikeSelection = address(0);
        auctionID = 0;
        currentOTokenPremium = 0;
        strikePrice = 0;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be positive");
        // An approve() by the msg.sender is required beforehand
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Initiate the gnosis auction.
     */
    function startAuction() external {
        _startAuction();
    }

    /**
     * @notice Initiate the gnosis auction.
     */
    function _startAuction() private {
        require(
            currentOTokenPremium > 0,
            "currentOtokenPremium should be greater than zero"
        );

        emit InitiateGnosisAuction(oTokenAddress, asset, auctionID, msg.sender);
    }

    /**
     * @notice Sets the next option the vault will be shorting, and closes the existing short.
     *         This allows all the users to withdraw if the next option is malicious.
     */
    function commitAndClose() external {
        // Strike price is set
        strikePrice = setRandomVal() / 1e4;
        require(strikePrice != 0, "strikePrice should not be zero");

        currentOTokenPremium = setRandomVal() / 1e6;
        require(
            currentOTokenPremium > 0,
            "currentOtokenPremium should be greater than zero"
        );
        nextOptionReadyAt = block.timestamp;
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     */
    function rollToNextOption() external {
        require(
            block.timestamp > nextOptionReadyAt,
            "Option did not start yet."
        );
        //slither-disable-next-line reentrancy-benign
        _startAuction();
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