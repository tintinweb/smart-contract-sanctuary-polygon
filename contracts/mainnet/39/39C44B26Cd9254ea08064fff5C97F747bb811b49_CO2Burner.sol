// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Registry.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/INatureCarbonTonne.sol";
import "./interfaces/ITCO2.sol";

contract CO2Burner {
    Registry public immutable registry;
    IERC20 public immutable stablecoin;
    IUniswapV2Router02 public immutable dexRouter;
    address public immutable nctToken;

    event Retired(address indexed retiree, address indexed token, uint tcoAmount, uint usdcAmount);

    constructor(address _registry, address _stablecoin, address _nctToken, address _dexRouter) {
        registry = Registry(_registry);
        stablecoin = IERC20(_stablecoin);
        nctToken = _nctToken;
        dexRouter = IUniswapV2Router02(_dexRouter);
    }

    function burnCO2(uint stableCoinAmount, string memory filter) external returns (uint totalTco2AmountBurned, uint totalUsdcAmountBurned){
        address [] memory projectTokens = registry.findBestProjectTokens(filter);
        uint stableToBurn = stableCoinAmount;
        uint index = 0;
        totalTco2AmountBurned = 0;
        totalUsdcAmountBurned = 0;
        while (stableCoinAmount > 0 && index < projectTokens.length) {
            uint tco2AmountBurned;
            uint usdcAmountBurned;
            (tco2AmountBurned, usdcAmountBurned) = burnProjectToken(projectTokens[index], stableToBurn);
            stableToBurn -= usdcAmountBurned;
            totalTco2AmountBurned += tco2AmountBurned;
            totalUsdcAmountBurned += usdcAmountBurned;
            index++;
        }
    }

    function burnProjectToken(address projectToken, uint stableCoinAmount) public returns (uint, uint){
        address[] memory path = new address[](2);
        path[0] = address(stablecoin);
        path[1] = address(nctToken);
        uint[] memory amountsSt = dexRouter.getAmountsIn(INatureCarbonTonne(nctToken).tokenBalances(projectToken), path);
        uint maxStableIn = amountsSt[0];

        stableCoinAmount = min(stableCoinAmount, maxStableIn);

        uint[] memory amounts = dexRouter.getAmountsOut(stableCoinAmount, path);
        uint amountIn = amounts[0];
        uint amountOut = amounts[1];

        stablecoin.transferFrom(msg.sender, address(this), stableCoinAmount);
        stablecoin.approve(address(dexRouter), amountIn);
        dexRouter.swapExactTokensForTokens(stableCoinAmount, amountOut, path, address(this), block.timestamp);

        uint[] memory redeemAmounts = new uint[](1);
        redeemAmounts[0] = amountOut;

        address[] memory tco2s = new address[](1);
        tco2s[0] = projectToken;

        INatureCarbonTonne(nctToken).redeemMany(tco2s, redeemAmounts);
        uint projectTokenBalance = IERC20(projectToken).balanceOf(address(this));

        ITCO2(projectToken).retire(projectTokenBalance);
        emit Retired(msg.sender, projectToken, projectTokenBalance, stableCoinAmount);
        return (projectTokenBalance, stableCoinAmount);
    }

    function burnProjectTokenQuote(address projectToken, uint stableCoinAmount) public view returns (uint, uint){
        address[] memory path = new address[](2);
        path[0] = address(stablecoin);
        path[1] = address(nctToken);
        uint[] memory amountsSt = dexRouter.getAmountsIn(INatureCarbonTonne(nctToken).tokenBalances(projectToken), path);
        uint maxStableIn = amountsSt[0];

        stableCoinAmount = min(stableCoinAmount, maxStableIn);

        uint[] memory amounts = dexRouter.getAmountsOut(stableCoinAmount, path);
        uint amountIn = amounts[0];
        uint amountOut = amounts[1];

        uint[] memory redeemAmounts = new uint[](1);
        redeemAmounts[0] = amountOut;

        address[] memory tco2s = new address[](1);
        tco2s[0] = projectToken;
        uint nctRedeemFee = INatureCarbonTonne(nctToken).calculateRedeemFees(tco2s, redeemAmounts);
        return (amountOut - nctRedeemFee, stableCoinAmount);
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {

    address [] public allProjectTokens;
    mapping(string => address []) public projectTokensByCountry;
    mapping(string => address []) public projectTokensByCategory;

    constructor(){}

    function addAllProjectTokens(address [] memory projectTokens) external onlyOwner {
        allProjectTokens = projectTokens;
    }

    function addProjectTokenByCountry(string memory countryCode, address [] memory projectTokens) external onlyOwner {
        projectTokensByCountry[countryCode] = projectTokens;
    }

    function addProjectTokenByCategory(string memory category, address [] memory projectTokens) external onlyOwner {
        projectTokensByCategory[category] = projectTokens;
    }

    function getProjectTokenByCountry(string memory country) external view returns (address [] memory) {
        return projectTokensByCountry[country];
    }

    function getProjectTokenByCategory(string memory category) external view returns (address [] memory) {
        return projectTokensByCategory[category];
    }

    function findBestProjectTokens(string memory filter) external view returns (address [] memory) {
        uint filterLength = _strlen(filter);
        if (filterLength == 0) {
            return allProjectTokens;
        }
        require(filterLength == 5, "Invalid filter");
        string memory countryCode = _substring(filter, 0, 2);
        string memory category = _substring(filter, 2, 5);

        string memory emptyCategory = "XXX";
        string memory emptyCountry = "XX";

        if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked(emptyCategory))) {
            return projectTokensByCountry[countryCode];
        }

        if (keccak256(abi.encodePacked(countryCode)) == keccak256(abi.encodePacked(emptyCountry))) {
            return projectTokensByCategory[category];
        }

        address [] memory projectTokens = projectTokensByCountry[countryCode];
        address [] memory projectTokensByCategory = projectTokensByCategory[category];
        return _intersectArrays(projectTokens, projectTokensByCategory);
    }

    function _substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    /**
   * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
   * @param A The first array
   * @param B The second array
   * @return The intersection of the two arrays
   */
    function _intersectArrays(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint newLength = 0;
        for (uint i = 0; i < length; i++) {
            if (_contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint j = 0;
        for (uint i = 0; i < length; i++) {
            if (includeMap[i]) {
                newAddresses[j] = A[i];
                j++;
            }
        }
        return newAddresses;
    }

    function _contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}

// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <[email protected]> or visit security.toucan.earth
pragma solidity ^0.8.0;


/// @notice Nature Carbon Tonne (or NatureCarbonTonne)
/// Contract is an ERC20 compliant token that acts as a pool for TCO2 tokens
//slither-disable-next-line unprotected-upgrade
interface INatureCarbonTonne{

    event Deposited(address erc20Addr, uint256 amount);
    event Redeemed(address account, address erc20, uint256 amount);
    event ExternalAddressWhitelisted(address erc20addr);
    event ExternalAddressRemovedFromWhitelist(address erc20addr);
    event InternalAddressWhitelisted(address erc20addr);
    event InternalAddressBlacklisted(address erc20addr);
    event InternalAddressRemovedFromBlackList(address erc20addr);
    event InternalAddressRemovedFromWhitelist(address erc20addr);
    event AttributeStandardAdded(string standard);
    event AttributeStandardRemoved(string standard);
    event AttributeMethodologyAdded(string methodology);
    event AttributeMethodologyRemoved(string methodology);
    event AttributeRegionAdded(string region);
    event AttributeRegionRemoved(string region);
    event RedeemFeePaid(address redeemer, uint256 fees);
    event RedeemFeeBurnt(address redeemer, uint256 fees);
    event ToucanRegistrySet(address ContractRegistry);
    event MappingSwitched(string mappingName, bool accepted);
    event SupplyCapUpdated(uint256 newCap);
    event MinimumVintageStartTimeUpdated(uint256 minimumVintageStartTime);
    event TCO2ScoringUpdated(address[] tco2s);

    /// @dev Returns the current version of the smart contract
    function version() external pure returns (string memory);


    // ----------------------------
    //   Permissionless functions
    // ----------------------------

    /// @notice Deposit function for NCT pool that accepts TCO2s and mints NCT 1:1
    /// @param erc20Addr ERC20 contract address to be deposited, requires approve
    /// @dev Eligibility is checked via `checkEligible`, balances are tracked
    /// for each TCO2 separately
    function deposit(address erc20Addr, uint256 amount)external;

    /// @notice Checks if token to be deposited is eligible for this pool
    function checkEligible(address erc20Addr)
        external
        view
        returns (bool);

    /// @notice Checks whether incoming TCO2s match the accepted criteria/attributes
    function checkAttributeMatching(address erc20Addr)
        external
        view
        returns (bool);

    /// @notice Update the fee redeem percentage
    /// @param _feeRedeemPercentageInBase percentage of fee in base
    function setFeeRedeemPercentage(uint256 _feeRedeemPercentageInBase)
        external;

    /// @notice Update the fee redeem receiver
    /// @param _feeRedeemReceiver address to transfer the fees
    function setFeeRedeemReceiver(address _feeRedeemReceiver)
        external;

    /// @notice Update the fee redeem burn percentage
    /// @param _feeRedeemBurnPercentageInBase percentage of fee in base
    function setFeeRedeemBurnPercentage(uint256 _feeRedeemBurnPercentageInBase)
        external;

    /// @notice Update the fee redeem burn address
    /// @param _feeRedeemBurnAddress address to transfer the fees to burn
    function setFeeRedeemBurnAddress(address _feeRedeemBurnAddress)
        external;

    /// @notice Adds a new address for redeem fees exemption
    /// @param _address address to be exempted on redeem fees
    function addRedeemFeeExemptedAddress(address _address)
        external;


    /// @notice View function to calculate fees pre-execution
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// @return Total fees amount
    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) external view returns (uint256);

    /// @notice Redeems Pool tokens for multiple underlying TCO2s 1:1 minus fees
    /// @dev User specifies in front-end the addresses and amounts they want
    /// @param tco2s Array of TCO2 contract addresses
    /// @param amounts Array of amounts to redeem for each tco2s
    /// NCT Pool token in user's wallet get burned
    function redeemMany(address[] memory tco2s, uint256[] memory amounts)
        external;

    /// @notice Automatically redeems an amount of Pool tokens for underlying
    /// TCO2s from an array of ranked TCO2 contracts
    /// starting from contract at index 0 until amount is satisfied
    /// @param amount Total amount to be redeemed
    /// @dev NCT Pool tokens in user's wallet get burned
    function redeemAuto(uint256 amount) external;

    /// @notice Automatically redeems an amount of Pool tokens for underlying
    /// TCO2s from an array of ranked TCO2 contracts starting from contract at
    /// index 0 until amount is satisfied. redeemAuto2 is slightly more expensive
    /// than redeemAuto but it is going to be more optimal to use by other on-chain
    /// contracts.
    /// @param amount Total amount to be redeemed
    /// @return tco2s amounts The addresses and amounts of the TCO2s that were
    /// automatically redeemed
    function redeemAuto2(uint256 amount)
        external
        returns (address[] memory tco2s, uint256[] memory amounts);

    /// @dev Returns the remaining space in pool before hitting the cap
    function getRemaining() external view returns (uint256);


    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getScoredTCO2s() external view returns (address[] memory);

    function tokenBalances(address tco2) external view returns (uint256);
}

interface ITCO2{
    function retire(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}