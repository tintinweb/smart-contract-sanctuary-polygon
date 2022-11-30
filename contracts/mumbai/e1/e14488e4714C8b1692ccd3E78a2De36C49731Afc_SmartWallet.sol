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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEToken is IERC20 {
    function deposit(uint256 subAccountId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarket {
    function enterMarket(uint256 subAccountId, address tokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IEToken.sol";
import "./interfaces/IMarket.sol";

contract SmartWallet {
    bool public initialized = false;
    uint256 public balance;
    address public owner;
    address public sender;
    IEToken public eToken;

    // IEToken(0x4ea65A17ddF15a5607e74a2B910268182e140957);

    function init(address user, address _eToken) external {
        sender = msg.sender;
        require(!initialized, "Contract already initialized");
        owner = user;
        eToken = IEToken(_eToken);
        initialized = true;
    }

    function handleEnterMarket(address underlying) internal {
        IMarket market = IMarket(0x3419a9C22F665d61ED964Ec999Fc633d00755e55);
        market.enterMarket(0, underlying);
    }

    function deposit(uint256 depositAmount, address underlyingToken)
        public
        returns (uint256 res)
    {
        handleEnterMarket(address(underlyingToken));

        balance = eToken.balanceOf(address(this));

        eToken.deposit(0, depositAmount);

        // (bool success, bytes memory data) = address(eToken).delegatecall(
        //     abi.encodeWithSignature(
        //         "deposit(uint256,uint256)",
        //         0,
        //         depositAmount
        //     )
        // );

        // The nested xcall
        uint256 curr_balance = eToken.balanceOf(address(this));

        res = curr_balance - balance;
        balance = curr_balance;

        return res;
    }
}