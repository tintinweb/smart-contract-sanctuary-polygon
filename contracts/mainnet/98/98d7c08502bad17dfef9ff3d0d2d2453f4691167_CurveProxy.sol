/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// File: incognitocontracts/IERC20.sol



pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint amount) external;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// File: incognitocontracts/curve_proxy.sol


pragma solidity 0.7.6;


interface ICurveSwap {
	function exchange(uint256 i, uint256 j, uint256 amount, uint256 minAmount) external returns (uint256);
	function exchange_underlying(uint256 i, uint256 j, uint256 amount, uint256 minAmount) external returns (uint256);
	function coins(uint256 index) external view returns (address);
	function underlying_coins(uint256 index) external view returns (address);
	function get_dy(uint256 i, uint256 j, uint256 amount) external view returns (uint256);
	function get_dy_underlying(uint256 i, uint256 j, uint256 amount) external view returns (uint256);
	function exchange(uint256 amount, address[6] calldata route, uint256[8] calldata indices, uint256 mintReceived, address receiver) payable external;
}

//interface iWETH is IERC20 {
//	function withdraw(uint256 amount) external;
//}

contract CurveProxy {
	// Variables
	address constant public ETH_CONTRACT_ADDRESS = 0x0000000000000000000000000000000000000000;
	address constant public ETH_CURVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address public WETH;
	uint constant public MAX = uint(-1);

	//	/**
	//     * @dev Contract constructor
	//     * @param _weth uniswap routes contract address
	//     */
	//	constructor(address _weth) payable {
	//		WETH = _weth;
	//	}

	function exchange(uint256 i, uint256 j, uint256 amount, uint256 minAmount, ICurveSwap curvePool) external returns(address, uint) {
		require(amount > 0, "invalid swap amount");
		address source = curvePool.coins(i);
		address dest = curvePool.coins(j);
		address exactDest = dest == ETH_CURVE_ADDRESS ? ETH_CONTRACT_ADDRESS : dest;
		checkApproved(IERC20(source), amount, address(curvePool));
		uint256 amountOut = curvePool.exchange(i, j, amount, minAmount);
		require(amountOut >= minAmount, "Not enough coin");
		transfer(exactDest, amountOut);

		return (exactDest , amountOut);
	}

	function exchangeUnderlying(uint256 i, uint256 j, uint256 amount, uint256 minAmount, ICurveSwap curvePool) external returns(address, uint) {
		require(amount > 0, "invalid swap amount");
		address source = curvePool.underlying_coins(i);
		address dest = curvePool.underlying_coins(j);
		address exactDest = dest == ETH_CURVE_ADDRESS ? ETH_CONTRACT_ADDRESS : dest;
		checkApproved(IERC20(source), amount, address(curvePool));
		uint256 amountOut = curvePool.exchange_underlying(i, j, amount, minAmount);
		require(amountOut >= minAmount, "Not enough coin");
		transfer(exactDest, amountOut);

		return (exactDest, amountOut);
	}

	function exchange(
		IERC20 source,
		IERC20 dest,
		uint256 amount,
		address[6] calldata route,
		uint256[8] calldata indices,
		uint256 mintReceived,
		ICurveSwap curvePool
	) external payable returns(address, uint256) {
		require(amount > 0, "invalid swap amount");
		address exactDest = address(dest) == ETH_CURVE_ADDRESS ? ETH_CONTRACT_ADDRESS : address(dest);
		checkApproved(source, amount, address(curvePool));
		curvePool.exchange{value: msg.value}(amount, route, indices, mintReceived, address(this));
		uint256 amountOut = balanceOf(dest);
		require(amountOut >= mintReceived, "Not enough coin");
		transfer(exactDest, amountOut);

		return (exactDest, amountOut);
	}

	function balanceOf(IERC20 token) internal view returns (uint256) {
		if (address(token) == ETH_CONTRACT_ADDRESS) {
			return address(this).balance;
		}
		return token.balanceOf(address(this));
	}

	function checkApproved(IERC20 srcToken, uint256 amount, address destination) internal {
		if (msg.value == 0 && srcToken.allowance(address(this), address(destination)) < amount) {
			srcToken.approve(address(destination), MAX);
		}
	}

	function transfer(address token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount);
			(bool success, ) = msg.sender.call{value: amount}("");
			require(success);
		} else {
			IERC20(token).transfer(msg.sender, amount);
			require(checkSuccess());
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
	function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
		// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
			// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

			// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}

	/**
     * @dev Payable receive function to receive Ether from oldVault when migrating
     */
	receive() external payable {}
}