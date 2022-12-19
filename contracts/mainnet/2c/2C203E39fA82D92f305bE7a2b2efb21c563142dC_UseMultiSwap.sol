// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAnyswapV4Router {
	function anySwapOutUnderlying(
		address token,
		address to,
		uint amount,
		uint toChainID
	) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IAnyswapV4Router.sol";
import "./interfaces/IERC20.sol";

contract UseMultiSwap {
	//polygon anyswapV4Router
	// https://polygonscan.com/address/0x4f3aff3a747fcade12598081e80c6605a8be192f#code
	address public MULTI = 0x4f3Aff3A747fCADe12598081e80c6605A8be192F;

	receive() external payable {}

	/**
    //AnyswapV4Router.sol
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external {
        TransferHelper.safeTransferFrom(AnyswapV1ERC20(token).underlying(), msg.sender, token, amount);
        AnyswapV1ERC20(token).depositVault(amount, msg.sender);
        _anySwapOut(msg.sender, token, to, amount, toChainID);
    }
*/
	//@token : 보내는 토큰에 대응하는 any토큰
	//@to : 보내느 사람 주소 - 나
	//@amount : 수량
	//@toChainID : 받는 체인아이디  bnb = 56

	// fromToken : 0xc2132D05D31c914a87C6611C10748AEb04B58e8F USDT
	// fromAnyToken : 0xE3eeDa11f06a656FcAee19de663E84C7e61d3Cac anyUSDT
	// to : 0x63291171109607F7a0a850f3bc429fd903474496
	// amount : 21107700
	// toChainId : 56

	//성공 근데 toChain받을때 컨트랙트로 들어가는듯함. 그럴때 어디로 토큰이 오는지 나오는게 없음
	function multiChain(
		address fromToken,
		address fromAnyToken,
		address to,
		uint amount,
		uint toChainID
	) public {
		// 컨트랙트에 유저가 토큰보냄
		IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
		IERC20(fromToken).approve(MULTI, amount);
		// 그거를 이 컨트랙트가 애로 보냄
		IAnyswapV4Router(MULTI).anySwapOutUnderlying(
			fromAnyToken,
			to,
			amount,
			toChainID
		);
	}

	/**
    fromChain에서 multiChain함수를 써서 날리는 건 성공. 
    그런데 toChain에서 어디로 갔는지.. 
    */
}