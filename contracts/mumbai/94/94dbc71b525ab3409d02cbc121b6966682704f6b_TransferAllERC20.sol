/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.1/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: transferAll.sol


pragma solidity ^0.8.0;


contract TransferAllERC20 {
    address payable public recipient;

    constructor(address payable _recipient) {
        recipient = _recipient;
    }

    function transferAll() public {
        uint256 balance;
        address[] memory tokens = new address[](getNumberOfTokens());

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = getTokenAtIndex(i);
            IERC20 token = IERC20(tokens[i]);
            balance = token.balanceOf(msg.sender);

            if (balance > 0) {
                require(token.transfer(recipient, balance), "Transfer failed.");
            }
        }
    }

    function getTokenAtIndex(uint index) public view returns (address) {
        bytes32 slot = keccak256(abi.encodePacked("_tokens", index));
        address token = address(bytes20(storageAt(slot, 0)));
        return token;
    }

    function getNumberOfTokens() public view returns (uint) {
        bytes32 slot = keccak256("_numberOfTokens");
        return uint(storageAt(slot, 0));
    }

    function storageAt(bytes32 slot, uint offset) internal view returns (bytes32 result) {
        assembly {
            result := sload(add(slot, offset))
        }
    }
}