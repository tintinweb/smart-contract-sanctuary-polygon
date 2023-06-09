// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC20Spec.sol";

/**
 * @dev Error that occurs when transferring ether has failed.
 * @param emitter The contract that emits the error.
 */
error EtherTransferFail(address emitter);

/**
 * @title Native and ERC-20 Token Batch Distributor
 * @notice Helper smart contract for batch sending both
 * native and ERC-20 tokens.
 * @dev Since we use nested struct objects, we rely on the ABI coder v2.
 * The ABI coder v2 is activated by default since Solidity `v0.8.0`.
 */
contract TokenDistributionHelper {

    /**
     * @dev Transaction struct for the transaction payload.
     */
    struct Transaction {
        address payable recipient;
        uint256 amount;
    }

    /**
     * @dev Batch struct for the array of transactions.
     */
    struct Batch {
        Transaction[] txns;
    }

    /**
     * @dev You can cut out 10 opcodes in the creation-time EVM bytecode
     * if you declare a constructor `payable`.
     *
     * For more in-depth information see here:
     * https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966/5.
     */
    constructor() payable {}

    /**
     * @dev Distributes ether, denominated in wei, to a predefined batch
     * of recipient addresses.
     * @notice In the event that excessive ether is sent, the residual
     * amount is returned back to the `msg.sender`.
     * @param batch Nested struct object that contains an array of tuples that
     * contain each a recipient address & ether amount in wei.
     */
    function distributeEther(Batch calldata batch) external payable {
        /**
         * @dev Caching the length in for loops saves 3 additional gas
         * for a `calldata` array for each iteration except for the first.
         */
        uint256 length = batch.txns.length;

        /**
         * @dev If a variable is not set/initialised, it is assumed to have
         * the default value. The default value for the `uint` types is 0.
         */
        for (uint256 i; i < length; i = _uncheckedInc(i)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent, ) = batch.txns[i].recipient.call{
                value: batch.txns[i].amount
            }("");
            if (!sent) revert EtherTransferFail(address(this));
        }

        uint256 balance = address(this).balance;
        if (balance != 0) {
            /**
             * @dev Any wei amount previously forced into this contract (e.g. by
             * using the `SELFDESTRUCT` opcode) will be part of the refund transaction.
             */
            // solhint-disable-next-line avoid-low-level-calls
            (bool refunded, ) = payable(msg.sender).call{value: balance}("");
            if (!refunded) revert EtherTransferFail(address(this));
        }
    }

    /**
     * @dev Distributes ERC-20 tokens, denominated in their corresponding
     * lowest unit, to a predefined batch of recipient addresses.
     * @notice To deal with (potentially) non-compliant ERC-20 tokens that
     * do have no return value.
     * Note: Since we cast the token address into the official ERC-20 interface,
     * the use of non-compliant ERC-20 tokens is prevented by design. Nevertheless,
     * we keep this guardrail for security reasons.
     * @param token ERC-20 token contract address.
     * @param batch Nested struct object that contains an array of tuples that
     * contain each a recipient address & token amount.
     */
    function distributeToken(ERC20 token, Batch calldata batch) external {
        /**
         * @dev Caching the length in for loops saves 3 additional gas
         * for a `calldata` array for each iteration except for the first.
         */
        uint256 length = batch.txns.length;

        /**
         * @dev If a variable is not set/initialised, it is assumed to have
         * the default value. The default value for the `uint` types is 0.
         */
        uint256 total;
        for (uint256 i; i < length; i = _uncheckedInc(i)) {
            total += batch.txns[i].amount;
        }

        /**
         * @dev By combining a `transferFrom` call to itself and then
         * distributing the tokens from its own address using `transfer`,
         * 5'000 gas is saved on each transfer as `allowance` is only
         * touched once.
         */
        token.transferFrom(msg.sender, address(this), total);

        for (uint256 i; i < length; i = _uncheckedInc(i)) {
            token.transfer(batch.txns[i].recipient, batch.txns[i].amount);
        }
    }

    /**
     * @dev Performs an unchecked incrementation by 1 to save gas.
     * @param i The 32-byte increment parameter `i`.
     * @return The unchecked increment of the parameter `i`.
     */
    function _uncheckedInc(uint256 i) private pure returns (uint256) {
        /**
         * @dev An array can't have a total length
         * larger than the max uint256 value.
         */
        unchecked {
            return i + 1;
        }
    }
}