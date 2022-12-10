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

pragma solidity <=0.8.10;

interface IAaveLendingPool {
    
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;


    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
    ) external returns (uint256);

    function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IAaveLendingPool } from "./IAaveLendingPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract testAAVE {
    //Polygon aave lending pool tesnet contract: 0x1758d4e6f68166C4B2d9d0F049F33dEB399Daa1F
    //Mumbai matic token address: 0x0000000000000000000000000000000000001010
    IAaveLendingPool private aaveLendingPool;

    constructor(address _aaveAddress){
        setAaveContract(_aaveAddress);
    }

    function setAaveContract(address _aaveContract) public {
        aaveLendingPool = IAaveLendingPool(_aaveContract);
    }

    function approve(address token, uint256 amount) public {
        IERC20(token).approve(address(aaveLendingPool), amount);
    }

    function transfer(address token, uint256 amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function testSupply(address _token, uint256 _amount) public {
        aaveLendingPool.supply(address(IERC20(_token)), _amount, address(this), 0);
    }

}