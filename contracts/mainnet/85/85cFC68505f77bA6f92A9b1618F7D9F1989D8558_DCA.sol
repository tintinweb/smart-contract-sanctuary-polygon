//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import "./interfaces/ITrident.sol";
import "./interfaces/IAggregatorInterface.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";

/// @title DCA
/// @author HHK-ETH
/// @notice Sustainable DCA vault using bentobox and trident
contract DCA is Clone {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------
  error OwnerOnly();
  error ToClose();

  /// -----------------------------------------------------------------------
  /// Events
  /// -----------------------------------------------------------------------
  event ExecuteDCA(uint256 timestamp, uint256 amount);

  /// -----------------------------------------------------------------------
  /// Immutable variables
  /// -----------------------------------------------------------------------

  ///@notice address of the BentoBox
  function bentoBox() internal pure returns (IBentoBox _bentobox) {
    return IBentoBox(_getArgAddress(0));
  }

  ///@notice Address of the vault owner
  function owner() public pure returns (address _owner) {
    return _getArgAddress(20);
  }

  ///@notice Address of the token to sell
  function sellToken() public pure returns (address _sellToken) {
    return _getArgAddress(40);
  }

  ///@notice Address of the token to buy
  function buyToken() public pure returns (address _buyToken) {
    return _getArgAddress(60);
  }

  ///@notice Infos about the DCA
  ///@return _sellTokenPriceFeed Address of the priceFeed
  ///@return _buyTokenPriceFeed Address of the priceFeed
  ///@return _epochDuration Minimum time between each buy
  ///@return _decimalsDiff buyToken decimals - sellToken decimals
  ///@return _buyAmount Amount of token to use as swap input
  function dcaData()
    public
    pure
    returns (
      IAggregatorInterface _sellTokenPriceFeed,
      IAggregatorInterface _buyTokenPriceFeed,
      uint64 _epochDuration,
      uint8 _decimalsDiff,
      uint256 _buyAmount
    )
  {
    return (
      IAggregatorInterface(_getArgAddress(80)),
      IAggregatorInterface(_getArgAddress(100)),
      _getArgUint64(120),
      _getArgUint8(128),
      _getArgUint256(129)
    );
  }

  /// -----------------------------------------------------------------------
  /// Mutable variables
  /// -----------------------------------------------------------------------

  ///@notice Store last buy timestamp
  uint256 public lastBuy;

  /// -----------------------------------------------------------------------
  /// State change functions
  /// -----------------------------------------------------------------------

  ///@notice Execute the DCA buy
  ///@param path Trident path
  function executeDCA(ITrident.Path[] calldata path) external {
    (
      IAggregatorInterface sellTokenPriceFeed,
      IAggregatorInterface buyTokenPriceFeed,
      uint64 epochDuration,
      uint8 decimalsDiff,
      uint256 buyAmount
    ) = dcaData();
    IBentoBox bento = bentoBox();

    if (lastBuy + epochDuration > block.timestamp) {
      revert ToClose();
    }
    lastBuy = block.timestamp;

    //query oracles and determine minAmount, both priceFeed must have same decimals.
    uint256 sellTokenPrice = uint256(sellTokenPriceFeed.latestAnswer());
    uint256 buyTokenPrice = uint256(buyTokenPriceFeed.latestAnswer());

    uint256 minAmount;

    unchecked {
      uint256 ratio = (sellTokenPrice * 1e24) / buyTokenPrice;
      minAmount = (((ratio * buyAmount) * (10**decimalsDiff)) * 99) / 100 / 1e24;
    }

    //execute the swap on trident by default but since we don't check if pools are whitelisted
    //an intermediate contract could redirect the swap to pools outside of trident.
    bento.transfer(sellToken(), address(this), path[0].pool, buyAmount);
    for (uint256 i; i < path.length; ) {
      IPool(path[i].pool).swap(path[i].data);
      unchecked {
        ++i;
      }
    }

    //transfer minAmount minus 1% fee to the owner.
    bento.transfer(buyToken(), address(this), owner(), bento.toShare(buyToken(), minAmount, false));
    //transfer remaining shares (up to 1% of minAmount) from the vault to dca executor as a reward.
    bento.transfer(buyToken(), address(this), msg.sender, bento.balanceOf(buyToken(), address(this)));

    emit ExecuteDCA(lastBuy, minAmount);
  }

  ///@notice Allow the owner to withdraw its token from the vault
  function withdraw(uint256 _share) external {
    if (msg.sender != owner()) {
      revert OwnerOnly();
    }
    bentoBox().transfer(sellToken(), address(this), owner(), _share);
  }
}

//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import "./IBentobox.sol";

interface ITrident {
  struct Path {
    address pool;
    bytes data;
  }

  struct ExactInputParams {
    address tokenIn;
    uint256 amountIn;
    uint256 amountOutMinimum;
    Path[] path;
  }

  function bento() external returns (IBentoBox bento);

  function exactInput(ExactInputParams calldata params) external returns (uint256 amountOut);
}

interface IPool {
  function swap(bytes calldata data) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorInterface {
  function latestAnswer() external view returns (int256);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

interface IBentoBox {
  function transfer(
    address token,
    address from,
    address to,
    uint256 share
  ) external;

  function balanceOf(address token, address account) external returns (uint256);

  function toAmount(
    address token,
    uint256 share,
    bool roundUp
  ) external returns (uint256);

  function toShare(
    address token,
    uint256 amount,
    bool roundUp
  ) external returns (uint256);
}