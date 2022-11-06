// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IAToken.sol";
import "./IdERC20.sol";
import "./IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Ownable {
    mapping(address => address) private s_USDAggregatorAddresses;
    address private s_USDCaddress;
    uint256 private constant DIVISION_GUARD = 1e18;

    constructor(
        address usdcAddress,
        address usdcAggregatorAddress,
        address usdtAddress,
        address usdtAggregatorAddress,
        address daiAddress,
        address daiAggregatorAddress
    ) {
        setUSDCaddress(usdcAddress);
        setAggregatorAddress(usdcAddress, usdcAggregatorAddress);
        setAggregatorAddress(usdtAddress, usdtAggregatorAddress);
        setAggregatorAddress(daiAddress, daiAggregatorAddress);
    }

    function _toWei(uint256 number, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 power = 18 - decimals;
        return number * (10**power);
    }

    function _usdToUSDC(uint256 value) internal view returns (uint256) {
        return
            (value *
                ((1e18 * DIVISION_GUARD) /
                    getPriceFromAggregator(
                        s_USDAggregatorAddresses[s_USDCaddress]
                    ))) / DIVISION_GUARD;
    }

    function _getUnderlyingBalanceOf(address owner, address aTokenAddress)
        internal
        view
        returns (uint256)
    {
        IERC20 underlyingToken = IERC20(_getUnderlyingAddressOf(aTokenAddress));
        return underlyingToken.balanceOf(owner);
    }

    function _getUnderlyingAddressOf(address aTokenAddress)
        internal
        view
        returns (address)
    {
        IAToken aToken = IAToken(aTokenAddress);
        return aToken.UNDERLYING_ASSET_ADDRESS();
    }

    function getPriceFromAggregator(address priceFeedAddress)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return _toWei(uint256(price), priceFeed.decimals());
    }

    function setUSDCaddress(address usdcAddress) public onlyOwner {
        s_USDCaddress = usdcAddress;
    }

    function setAggregatorAddress(
        address erc20Address,
        address aggregatorAddress
    ) public onlyOwner {
        s_USDAggregatorAddresses[erc20Address] = aggregatorAddress;
    }

    function getUSDValueOf(
        address valueHolder,
        address[3] calldata aTokenAddresses
    ) public view returns (uint256 usdValue) {
        for (uint256 i = 0; i < aTokenAddresses.length; i++) {
            address aTokenAddress = aTokenAddresses[i];
            IdERC20 aToken = IdERC20(aTokenAddress);

            uint256 aBalanceOfVault = aToken.balanceOf(valueHolder);
            uint256 pricePerToken = getPriceFromAggregator(
                s_USDAggregatorAddresses[_getUnderlyingAddressOf(aTokenAddress)]
            );

            usdValue +=
                (_toWei(aBalanceOfVault, aToken.decimals()) * pricePerToken) /
                1e18;
        }
    }

    function getUSDPriceOf(
        address vaultAddress,
        address tokenAddress,
        address[3] calldata aTokenAddresses
    ) external view override returns (uint256) {
        return
            (getUSDValueOf(vaultAddress, aTokenAddresses) * DIVISION_GUARD) /
            IERC20(tokenAddress).totalSupply();
    }

    function getUSDCPriceOf(
        address vaultAddress,
        address tokenAddress,
        address[3] calldata aTokenAddresses
    ) external view override returns (uint256) {
        return
            ((_usdToUSDC(getUSDValueOf(vaultAddress, aTokenAddresses))) *
                DIVISION_GUARD) / IERC20(tokenAddress).totalSupply();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPriceOracle {
    function getUSDPriceOf(
        address vaultAddress,
        address tokenAddress,
        address[3] calldata aTokenAddresses
    ) external view returns (uint256);

    function getUSDCPriceOf(
        address vaultAddress,
        address tokenAddress,
        address[3] calldata aTokenAddresses
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface for erc20 that also implements decimals getter
interface IdERC20 is IERC20 {
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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