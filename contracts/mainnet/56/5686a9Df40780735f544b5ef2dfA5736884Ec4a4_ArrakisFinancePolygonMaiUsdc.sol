// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

contract ArrakisFinancePolygonMaiUsdc is DefiiWithCustomExit {
    IERC20 constant MAI = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1);
    IERC20 constant USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 constant QI = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);

    IGUniRouter constant router =
        IGUniRouter(0x477E509B9d08862baEb8Ab69e901Ae72b13efcA0);
    IERC20 constant arrakisPool =
        IERC20(0xA199569AF06cB68960869Fe376C9b41f68d8E2D1);
    IFarm constant farm = IFarm(0x9f9F0456005eD4E7248199B6260752E95682a883);

    IUniswapV3Pool constant usdcMaiPool =
        IUniswapV3Pool(0x7de263D0Ad6e5D208844E65118c3a02A9A5D56B6);
    IUniswapV3Router constant uniswapV3Router =
        IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 constant FARMING_PID = 0;

    function hasAllocation() external view override returns (bool) {
        return farm.deposited(FARMING_PID, address(this)) > 0;
    }

    function exitParams(bool swap, uint256 slippage)
        external
        view
        returns (bytes memory)
    {
        require(!swap || slippage > 800, "Slippage must be >800, (>80%)");
        require(!swap || slippage < 1200, "Slippage must be <1200, (<120%)");

        (uint160 sqrtPriceX96, , , , , , ) = usdcMaiPool.slot0();

        uint256 usdcMaiprice = ((uint256(sqrtPriceX96) *
            uint256(sqrtPriceX96)) >> (2 * 96));
        uint256 maiUsdcPrice = 1e30 / usdcMaiprice;
        uint256 minPrice = (maiUsdcPrice * slippage) / 1000;

        return abi.encode(swap, minPrice);
    }

    function _enter() internal override {
        USDC.approve(address(router), type(uint256).max);
        MAI.approve(address(router), type(uint256).max);
        (, , uint256 lpAmount) = router.addLiquidity(
            address(arrakisPool),
            USDC.balanceOf(address(this)),
            MAI.balanceOf(address(this)),
            0,
            0,
            address(this)
        );
        USDC.approve(address(router), 0);
        MAI.approve(address(router), 0);

        arrakisPool.approve(address(farm), lpAmount);
        farm.deposit(FARMING_PID, lpAmount);
    }

    function _exitWithParams(bytes memory params) internal override {
        (bool swap, uint256 minPrice) = abi.decode(params, (bool, uint256));

        uint256 lpAmount = farm.deposited(FARMING_PID, address(this));
        farm.withdraw(FARMING_PID, lpAmount);
        withdrawERC20(QI);

        arrakisPool.approve(address(router), lpAmount);
        router.removeLiquidity(
            address(arrakisPool),
            lpAmount,
            0,
            0,
            address(this)
        );
        if (!swap) {
            return;
        }

        uint256 maiAmount = MAI.balanceOf(address(this));
        uint256 minUsdcAmount = (maiAmount * minPrice) / 1e18 / 1e12;

        MAI.approve(address(uniswapV3Router), maiAmount);
        uniswapV3Router.exactInputSingle(
            IUniswapV3Router.ExactInputSingleParams({
                tokenIn: address(MAI),
                tokenOut: address(USDC),
                fee: 100,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: maiAmount,
                amountOutMinimum: minUsdcAmount,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function _harvest() internal override {
        farm.withdraw(FARMING_PID, 0);
        withdrawERC20(QI);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(MAI);
        withdrawERC20(USDC);
    }
}

interface IGUniRouter {
    function addLiquidity(
        address pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function removeLiquidity(
        address pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );
}

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";

abstract contract DefiiWithCustomExit is Defii {
    function exitWithParams(bytes memory params) external onlyOnwerOrExecutor {
        _exitWithParams(params);
    }

    function exitWithParamsAndWithdraw(bytes memory params)
        public
        onlyOnwerOrExecutor
    {
        _exitWithParams(params);
        _withdrawFunds();
    }

    function _exitWithParams(bytes memory params) internal virtual;

    function _exit() internal pure override {
        revert("Run exitWithParams");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

abstract contract Defii is IDefii {
    address public owner;
    address public factory;

    /// @notice Sets owner and factory addresses. Could run only once, called by factory.
    /// @param owner_ Owner (for ACL and transfers out)
    /// @param factory_ For validation and info about executor
    function init(address owner_, address factory_) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
    }

    //////
    // owner functions
    //////

    /// @notice Enters to DEFI instrument. Could run only by owner.
    function enter() external onlyOwner {
        _enter();
    }

    /// @notice Runs custom transaction. Could run only by owner.
    /// @param target Address
    /// @param value Transaction value (e.g. 1 AVAX)
    /// @param data Enocded function call
    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        (bool success, ) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    /// @notice Runs custom multiple transactions. Could run only by owner.
    /// @param targets List of address
    /// @param values List of transactions value (e.g. 1 AVAX)
    /// @param datas List of enocded function calls
    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwner {
        require(
            targets.length == values.length,
            "targets and values length not match"
        );
        require(
            targets.length == datas.length,
            "targets and datas length not match"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            runTx(targets[i], values[i], datas[i]);
        }
    }

    //////
    // owner and executor functions
    //////

    /// @notice Exit from DEFI instrument. Could run by owner or executor. Don't withdraw funds to owner account.
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }

    /// @notice Exit from DEFI instrument. Could run by owner or executor.
    function exitAndWithdraw() external onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    /// @notice Claim rewards and withdraw to owner.
    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    /// @notice Claim rewards, sell it and and withdraw to owner.
    /// @param params Encoded params (use encodeParams function for it)
    function harvestWithParams(bytes memory params)
        external
        onlyOnwerOrExecutor
    {
        _harvestWithParams(params);
    }

    /// @notice Withdraw funds to owner (some hardcoded assets, which uses in instrument).
    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    /// @notice Withdraw ERC20 to owner
    /// @param token ERC20 address
    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    /// @notice Withdraw native token to owner (e.g ETH, AVAX, ...)
    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }

    receive() external payable {}

    //////
    // internal functions - common logic
    //////

    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.transfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    //////
    // internal functions - defii specific logic
    //////

    function _enter() internal virtual;

    function _exit() internal virtual;

    function _harvest() internal virtual {
        revert("Use harvestWithParams");
    }

    function _withdrawFunds() internal virtual;

    function _harvestWithParams(bytes memory) internal virtual {
        revert("Run harvest");
    }

    //////
    // modifiers
    //////

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(
            msg.sender == owner ||
                msg.sender == IDefiiFactory(factory).executor(),
            "Only owner or executor"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDefii {
    function hasAllocation() external view returns (bool);

    function init(address owner_, address factory_) external;

    function enter() external;

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) external;

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external;

    function exit() external;

    function exitAndWithdraw() external;

    function harvest() external;

    function withdrawERC20(IERC20 token) external;

    function withdrawETH() external;

    function withdrawFunds() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Info {
    address wallet;
    address defii;
    bool hasAllocation;
}

interface IDefiiFactory {
    function executor() external view returns (address executor);

    function getDefiiFor(address wallet) external view returns (address defii);

    function getAllWallets() external view returns (address[] memory);

    function getAllDefiis() external view returns (address[] memory);

    function getAllAllocations() external view returns (bool[] memory);

    function getAllInfos() external view returns (Info[] memory);

    function createDefii() external;

    function createDefiiFor(address owner) external;
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