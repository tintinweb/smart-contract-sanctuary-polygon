//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "./DCA.sol";

/// @title DCA Factory
/// @author HHK-ETH
/// @notice Factory to create sustainable DCA vaults using bentobox and trident
contract DCAFactory {
  using ClonesWithImmutableArgs for address;

  /// -----------------------------------------------------------------------
  /// Events
  /// -----------------------------------------------------------------------
  event CreateDCA(DCA newVault, uint256 ok);

  /// -----------------------------------------------------------------------
  /// Immutable variables and constructor
  /// -----------------------------------------------------------------------
  DCA public immutable implementation;
  address public immutable bentobox;

  constructor(DCA _implementation, address _bentobox) {
    implementation = _implementation;
    bentobox = _bentobox;
  }

  /// -----------------------------------------------------------------------
  /// State change functions
  /// -----------------------------------------------------------------------

  ///@notice Deploy a new vault
  ///@param owner Address of the owner of the vault
  ///@param sellToken Address of the token to sell
  ///@param buyToken Address of the token to buy
  ///@param sellTokenPriceFeed Address of the priceFeed to use to determine sell token price
  ///@param buyTokenPriceFeed Address of the priceFeed to use to determine buy token price
  ///@param epochDuration Minimum time between each buy
  ///@param decimalsDiff buyToken decimals - sellToken decimals
  ///@param amount Amount to use on each buy
  ///@return newVault Vault address
  function createDCA(
    address owner,
    address sellToken,
    address buyToken,
    address sellTokenPriceFeed,
    address buyTokenPriceFeed,
    uint64 epochDuration,
    uint8 decimalsDiff,
    uint256 amount
  ) external returns (DCA newVault) {
    bytes memory data = abi.encodePacked(
      bentobox,
      owner,
      sellToken,
      buyToken,
      sellTokenPriceFeed,
      buyTokenPriceFeed,
      epochDuration,
      decimalsDiff,
      amount
    );
    newVault = DCA(address(implementation).clone(data));
    emit CreateDCA(newVault, 1);
  }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

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
  event Withdraw(uint256 share);

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

    //convert amount to bento shares
    buyAmount = bento.toShare(sellToken(), buyAmount, false);

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
  function withdraw(uint256 shares) external {
    if (msg.sender != owner()) {
      revert OwnerOnly();
    }
    bentoBox().transfer(sellToken(), address(this), owner(), shares);
    emit Withdraw(shares);
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