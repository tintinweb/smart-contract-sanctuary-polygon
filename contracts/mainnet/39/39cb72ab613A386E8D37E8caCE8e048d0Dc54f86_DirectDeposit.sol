// SPDX-License-Identifier: CC0-1.0
// Compiler: 0.8.0
// Author: @krkmu - Alice's Ring
// ETHDenver - For you zkBOB

pragma solidity ^0.8.0;

import "./IZkBobDirectDeposits.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677 {
    function transferAndCall(address to, uint256 amount, bytes calldata data) external;
}

contract DirectDeposit {

    address public owner;
    mapping (address => uint256) public deposits;

    // Polygon Mainnet
    IERC677 public bob = IERC677(0xB0B195aEFA3650A6908f15CdaC7D92F8a5791B0B); 
    IERC20 bobi = IERC20(0xB0B195aEFA3650A6908f15CdaC7D92F8a5791B0B);
    IZkBobDirectDeposits queue = IZkBobDirectDeposits(0x668c5286eAD26fAC5fa944887F9D2F20f7DDF289);

    // Sepolia testnet 
    // We use the IERC677 interface to call the transferAndCall function of the BOB token
    // and we use the IERC20 interface to call the transfer function of the BOB token
    // nb : BOB token has 18 decimals
    // IERC677 public bob = IERC677(0x2C74B18e2f84B78ac67428d0c7a9898515f0c46f); 
    // IERC20 public bobi = IERC20(0x2C74B18e2f84B78ac67428d0c7a9898515f0c46f); 
    // IZkBobDirectDeposits public queue = IZkBobDirectDeposits(0xE3Dd183ffa70BcFC442A0B9991E682cA8A442Ade);

    //Some basic events to help us track the deposit and withdrawal of BOB tokens
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);
    event Received(address, uint256);

    constructor() {
        owner = msg.sender;
    }

    /*
    @notice Performs a direct deposit to the specified zk address.
    User should first have performed a deposit (and BOB approve) of BOB tokens to this contract.
    @param amount direct deposit amount.
    @param zkRecieverAddress receiver zk address.
    @param fallbackReceiver fallback receiver address.
    Direct Deposit limits:
    1. Max amount of a single deposit - 1,000 BOB
    2. Max daily sum of all single user deposits - 10,000 BOB
    In case the deposit cannot be processed, it can be refunded later to the fallbackReceiver (msg.sender) address.
    */
    function directDeposit(uint256 amount, string memory zkRecieverAddress, address fallbackReceiver) public {
        require(deposits[msg.sender]>=amount, "Not enough funds");
        bytes memory zkAddress = bytes(zkRecieverAddress);
        bob.transferAndCall(address(queue), amount, abi.encode(fallbackReceiver, zkAddress));
        deposits[msg.sender] -= amount;
    }

    /*
    @notice Performs a direct deposit to the specified zk address.
    User should first have performed a approve this contract for BOB transfer.
    @param amount direct deposit amount.
    */
    function despositBob(uint256 amount) public {
        bobi.transferFrom(msg.sender,address(this),amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    /*
    @notice Withdraw the deposited BOB.
    @param amount direct deposit amount.
    */
    function withdrawBob(uint256 amount) public {
        require(deposits[msg.sender]>=amount, "Not enough funds");
        bobi.transfer(msg.sender,amount);
        deposits[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    /*
    @notice Withdraw the deposited BOB.
    @param amount direct deposit amount.
    */
    function getContractBobBalance() public view returns (uint256) {
        return bobi.balanceOf(address(this));
    }

    /*
    @notice View the BOB amount allowed by user to be transfered by the contract.
    */
    function getContractBobAllowance(address user) public view returns (uint256) {
        return bobi.allowance(user,address(this));
    } 

    // Contract Utils

    fallback () external payable 
	{
        emit Received(msg.sender, msg.value);
    }

    //It executes on calls to the contract with no data (calldata), such as calls made via send() or transfer()
	receive () external payable 
	{
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    @notice Withdraw native coin from contract.
    Only owner can perform this action.
    */
    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IZkBobDirectDeposits {
    enum DirectDepositStatus {
        Missing, // requested deposit does not exist
        Pending, // requested deposit was submitted and is pending in the queue
        Completed, // requested deposit was successfully processed
        Refunded // requested deposit was refunded to the fallback receiver
    }

    struct DirectDeposit {
        address fallbackReceiver; // refund receiver for deposits that cannot be processed
        uint96 sent; // sent amount in BOB tokens (18 decimals)
        uint64 deposit; // deposit amount, after subtracting all fees (9 decimals)
        uint64 fee; // deposit fee (9 decimals)
        uint40 timestamp; // deposit submission timestamp
        DirectDepositStatus status; // deposit status
        bytes10 diversifier; // receiver zk address, part 1/2
        bytes32 pk; // receiver zk address, part 2/2
    }

    /**
     * @notice Retrieves the direct deposits from the queue by its id.
     * @param depositId id of the submitted deposit.
     * @return deposit recorded deposit struct
     */
    function getDirectDeposit(uint256 depositId) external view returns (DirectDeposit memory deposit);

    /**
     * @notice Performs a direct deposit to the specified zk address.
     * In case the deposit cannot be processed, it can be refunded later to the fallbackReceiver address.
     * @param fallbackReceiver receiver of deposit refund.
     * @param amount direct deposit amount.
     * @param zkAddress receiver zk address.
     * @return depositId id of the submitted deposit to query status for.
     */
    function directDeposit(
        address fallbackReceiver,
        uint256 amount,
        bytes memory zkAddress
    )
        external
        returns (uint256 depositId);

    /**
     * @notice Performs a direct deposit to the specified zk address.
     * In case the deposit cannot be processed, it can be refunded later to the fallbackReceiver address.
     * @param fallbackReceiver receiver of deposit refund.
     * @param amount direct deposit amount.
     * @param zkAddress receiver zk address.
     * @return depositId id of the submitted deposit to query status for.
     */
    function directDeposit(
        address fallbackReceiver,
        uint256 amount,
        string memory zkAddress
    )
        external
        returns (uint256 depositId);

    /**
     * @notice ERC677 callback for performing a direct deposit.
     * Do not call this function directly, it's only intended to be called by the token contract.
     * @param from original tokens sender.
     * @param amount direct deposit amount.
     * @param data encoded address pair - abi.encode(address(fallbackReceiver), bytes(zkAddress))
     * @return ok true, if deposit of submitted successfully.
     */
    function onTokenTransfer(address from, uint256 amount, bytes memory data) external returns (bool ok);

    /**
     * @notice Tells the direct deposit fee, in zkBOB units (9 decimals).
     * @return fee direct deposit submission fee.
     */
    function directDepositFee() external view returns (uint64 fee);

    /**
     * @notice Tells the timeout after which unprocessed direct deposits can be refunded.
     * @return timeout duration in seconds.
     */
    function directDepositTimeout() external view returns (uint40 timeout);

    /**
     * @notice Tells the nonce of next direct deposit.
     * @return nonce direct deposit nonce.
     */
    function directDepositNonce() external view returns (uint32 nonce);

    /**
     * @notice Refunds specified direct deposit.
     * Can be called by anyone, but only after the configured timeout has passed.
     * Function will revert for deposit that is not pending.
     * @param index deposit id to issue a refund for.
     */
    function refundDirectDeposit(uint256 index) external;

    /**
     * @notice Refunds multiple direct deposits.
     * Can be called by anyone, but only after the configured timeout has passed.
     * Function will do nothing for non-pending deposits and will not revert.
     * @param indices deposit ids to issue a refund for.
     */
    function refundDirectDeposit(uint256[] memory indices) external;
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