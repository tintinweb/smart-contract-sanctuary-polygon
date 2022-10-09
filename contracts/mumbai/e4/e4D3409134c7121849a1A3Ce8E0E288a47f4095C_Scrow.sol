// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


//import "hardhat/console.sol";

/**
@title Scrow contract
@dev Allows a send referred transaction to a certain recipient
@notice Known limitation: this contact can store only 1 TX per sender and recipient.
@notice Internally it uses block number for time measurement as timestamp is not a fullhy secure global parameter
@notice Functions to update parameters, owner management, pausing mechanisms has not been addressed to keep this contract as simple as possible
@notice Once funds have been doposited in contract, sender won't be able to get them back. In some cases this functionality could be interesting; 
 however, we do not implement it to keep contract simple
 */
contract Scrow is Context {
   
    struct LedgerEntry{
        uint256 amount;
        uint256 time_period_in_blocks;
    }

    event Deposit(address from, address _address, uint256 _time_period, uint256 _amount, uint256 _timestamp);
    event Withdraw(address from,  address _address, uint256 _amount, uint256 _timestamp);

    // ERC-20 token address. 
   address public tokenAddress;
   // NUmber of secons per block (this parameter depends on network and, despite it is not exact, it is enough accurate)
   uint256 public block2SecConversion;
   // TO_ADDRESESS => FROM_ADDRESS => LedgerEntry
   mapping(address => mapping(address => LedgerEntry)) public ledger;

    /**
        Constructor
        @param  _tokenAddress token erc20 used for transaction
        @param _block2SecConversion secons per block (depends on network)
    */
   constructor(address _tokenAddress, uint256 _block2SecConversion){
        tokenAddress=_tokenAddress;
        block2SecConversion=_block2SecConversion;
   }

    /**
    Called by the tx sender
    @notice Previously sender must approve this contract in token contract
    @param _address Recipient address
    @param _time_period Period in seconds this tx will not be availalbe for withdrawal
    @param _amount tx amount
    */
   function deposit(address _address, uint256 _time_period, uint256 _amount) external {
        require(ledger[_address][_msgSender()].amount==0,"Scrow:Already deposited");

        require(
            IERC20(tokenAddress).transferFrom(_msgSender(),address(this),_amount),
            "Scrow:transfer errror"
        );

        ledger[_address][_msgSender()].amount=_amount;
        // Calculate time with block heigh instead in seconds (block timestamp) as it is more secure
        ledger[_address][_msgSender()].time_period_in_blocks=block.number+_time_period/block2SecConversion;

        // timestamp is used for informational purposes
        emit Deposit(_msgSender(), _address,_time_period,_amount,block.timestamp);
   }

    /**
    Called by the tx recipient when the tx is available for withdrawal. It will send funds to recipient if time  period has been fulfilled
    @param from Sender  address. Same recipient can have several tx pending to withdrawall from different senders
    */
   function withdraw(address from) external {
        LedgerEntry storage entry = ledger[_msgSender()][from];
        require(entry.amount>0,"Scrow:Not deposited");
        require(entry.time_period_in_blocks <= block.number,"Scrow:wrong time");

        require(
            IERC20(tokenAddress).transfer(_msgSender(),entry.amount),
            "Scrow:transfer errror"
        );
        uint256 oldAmount = entry.amount;
        entry.amount=0;
        
        emit Withdraw(_msgSender(), from,oldAmount,block.timestamp);
   }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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