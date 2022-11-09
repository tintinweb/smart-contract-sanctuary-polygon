/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.5;


interface IWETHGateway {
  function depositETH(address onBehalfOf, uint16 referralCode) external payable;

  function withdrawETH(uint256 amount, address onBehalfOf) external;

  function repayETH(
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external payable;

  function borrowETH(
    uint256 amount,
    uint256 interesRateMode,
    uint16 referralCode
  ) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

contract Escrows {
    struct Escrow {
        address beneficiary;
        address arbitrator;
        uint256 amount;
        bool approved;
    }

    address payable owner;
    uint256 public escrowDepositsBalance;

    IWETHGateway gateway =
        IWETHGateway(0x2a58E9bbb5434FdA7FF78051a4B82cb0EF669C17);
    IERC20 aWETH = IERC20(0xd575d4047f8c667E064a4ad433D04E25187F40BB);

    mapping(uint256 => Escrow) public escrows;

    constructor() {
        owner = msg.sender;
    }

    event Deposited(address beneficiary, address arbitrator, uint256 amount);

    function deposit(
        address payable _beneficiary,
        address _arbitrator,
        uint256 _escrowId
    ) external payable {
        require(
            escrows[_escrowId].beneficiary == address(0x0),
            "Escrow Id exists"
        );

        Escrow storage e = escrows[_escrowId];

        e.beneficiary = _beneficiary;
        e.arbitrator = _arbitrator;
        e.amount = msg.value;
        e.approved = false;

        escrowDepositsBalance += msg.value;
        // Deposit ETH through the WETH gateway
        gateway.depositETH{value: msg.value}(address(this), 0);

        emit Deposited(_beneficiary, _arbitrator, msg.value);
    }

    function approve(uint256 _escrowId) external {
        require(
            escrows[_escrowId].beneficiary != address(0x0),
            "Escrow does not exist"
        );
        require(
            msg.sender == escrows[_escrowId].arbitrator,
            "Only arbitrator can approve this escrow"
        );

        uint256 balance = escrows[_escrowId].amount;
        escrows[_escrowId].amount = 0;
        escrows[_escrowId].approved = true;
        escrowDepositsBalance -= balance;

        aWETH.approve(address(gateway), balance);
        gateway.withdrawETH(balance, address(this));

        payable(escrows[_escrowId].beneficiary).transfer(balance);
    }

    function profit() internal view returns (uint256) {
        uint256 balance = aWETH.balanceOf(address(this));
        return balance - escrowDepositsBalance;
    }

    function getCurrentProfitBalance() external view returns (uint256) {
        return profit();
    }

    function withDrawProfit() external {
        require(msg.sender == owner, "You are not the owner");

        uint256 profitBalance = profit();
        aWETH.approve(address(gateway), profitBalance);
        gateway.withdrawETH(profitBalance, address(this));

        owner.transfer(profitBalance);
    }

    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}