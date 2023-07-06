// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 *  Exercise: Bob and Alice are entering an escrow. Alice wants to exchange 10 A-Tokens for 1 wei from Bob.
 *            Alice and Bob don't trust each other, so they use a smart contract to execute this exchange.
 *
 *            [1] Write an ESCROW smart contract that does the following:
 *
 *              - In the constructor:
 *                  - Let Bob deposit a given amount of ether into the smart contract.
 *                  - Store escrow details: 
 *                      (a) the address of Alice 
 *                      (b) the expected currency + amount that Alice must deposit to get the ether stored in the contract by Bob
 *                      (c) the amount of time Bob is willing to wait for Alice to execute the escrow.
 *
 *              - Allow Alice to execute the escrow by by sending the expected currency + amount to the contract,
 *                to receive the stored ether in exchange.
 *
 *              - If Alice hasn't executed the escrow within the time that Bob expects, let Bob withdraw the ether stored in the contract.
 *
 *            [2] Create a file `src/test/Escrow.t.sol` and write test cases for the Escrow smart contract.
 *
 *            [3] Since Alice and Bob don't trust each other, they want to make sure that the smart contract
 *                is not malicious. So -- deploy the smart contract to the Goerli blockchain and verify it.
 *
 *  HINT: You can use the IERC20 contract to represent the A-Tokens.
**/
import "./IERC20.sol";

// addresses of alice and bob
// the token contract
// the amount of time bob is willing to wait
// the time of contract creation
// boolean which states if escrow has yet to be executed

contract Escrow {
    address public bob;
    address public alice;
    IERC20 public token;
    uint public amount;
    uint public deadline;
    uint public startTime;
    bool public executed;
    
    // state variables
    constructor(
        address _bob,
        address _alice,
        address _token,
        uint _amount,
        uint _deadline
    ) payable {

        bob = _bob;
        alice = _alice;
        token = IERC20(_token);
        amount = _amount;
        deadline = _deadline;
        startTime = block.timestamp;
        executed = false;
    }
    
    function executeEscrow() external {
        require(!executed, "Escrow already executed.");
        require(block.timestamp <= startTime + deadline, "Escrow deadline has passed.");
        // Transfer A-Tokens from Alice to the contract
        token.transferFrom(alice, bob, amount);
        // Transfer Ether from the contract to Alice
        payable(alice).transfer(address(this).balance);
        executed = true;
    }
    
    function withdraw() external {
        require(executed || block.timestamp > startTime + deadline, "Escrow is still in progress.");
        // Transfer Ether from the contract to Bob
        payable(bob).transfer(address(this).balance);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}