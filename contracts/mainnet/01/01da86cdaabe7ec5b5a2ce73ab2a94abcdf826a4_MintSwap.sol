// SPDX-License-Identifier: mit
pragma solidity 0.8.19;

import "forge-std/interfaces/IERC20.sol";

interface LP {
    function token0() external returns (address);
    function token1() external returns (address);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
}

contract MintSwap {
    constructor() { }

    function swap(address _lp, uint amount0, uint amount1) external {
        LP lp = LP(_lp);
        IERC20(lp.token0()).transferFrom(msg.sender, _lp, amount0);
        IERC20(lp.token1()).transferFrom(msg.sender, _lp, amount1);
        lp.mint(_lp);
        lp.burn(msg.sender);
    }

    function swapRepeat(address _lp, uint amount0, uint amount1, uint loops) external {
        LP lp = LP(_lp);
        IERC20(lp.token0()).transferFrom(msg.sender, _lp, amount0);
        IERC20(lp.token1()).transferFrom(msg.sender, _lp, amount1);
        while(loops-- > 0){
            _swap(lp);
        }
        _transferTokensTo(lp, msg.sender);
    }

    function _transferTokensTo(LP lp, address to) internal{
        if (IERC20(lp.token0()).balanceOf(address(this)) > 0) {
            IERC20(lp.token0()).transfer(to, IERC20(lp.token0()).balanceOf(address(this)));
        }
        if (IERC20(lp.token1()).balanceOf(address(this)) > 0) {
            IERC20(lp.token1()).transfer(to, IERC20(lp.token1()).balanceOf(address(this)));
        }
    }

    function _swap(LP lp) internal {
        _transferTokensTo(lp, address(lp));
        lp.mint(address(lp));
        lp.burn(address(this));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}