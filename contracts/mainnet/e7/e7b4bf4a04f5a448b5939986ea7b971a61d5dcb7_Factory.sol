//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import "./Vault.sol";

/// @title Vault factory
/// @author HHK-ETH
/// @notice Factory to create DCA vaults
contract Factory {
    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    event CreateDCA(Vault newVault);

    /// -----------------------------------------------------------------------
    /// Immutable variables and constructor
    /// -----------------------------------------------------------------------
    Vault public immutable implementation;

    constructor(Vault _implementation) {
        implementation = _implementation;
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Deploy a new DCA vault
    ///@param params ABI encode packed of params
    ///@return newVault Vault address
    ///@param waitEpochPeriod false so first execDca can be called or true to wait for epochPeriod before first exec
    function createDCA(bytes calldata params, bool waitEpochPeriod) external returns (Vault newVault) {
        //address bentobox address
        //address owner Address of the owner of the vault
        //address sellToken Address of the token to sell
        //address buyToken Address of the token to buy
        //address sellTokenPriceFeed Address of the priceFeed to use to determine sell token price
        //address buyTokenPriceFeed Address of the priceFeed to use to determine buy token price
        //uint64 epochDuration Minimum time between each buy
        //uint256 amount Amount to use on each buy
        //uint256 sellTokenDecimalsFactor 10 ** ERC20(sellToken).decimals();
        //uint256 buyTokenDecimalsFactor 10 ** ERC20(buyToken).decimals();

        newVault = Vault(address(implementation).clone(params));
        newVault.setLastBuy(waitEpochPeriod);
        emit CreateDCA(newVault);
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
pragma solidity ^0.8.17;

import {IAggregatorInterface} from "./interfaces/IAggregator.sol";
import {IBentoBox} from "./interfaces/IBentoBox.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {IMulticall3} from "./interfaces/IMulticall3.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

/// @title DCA vault implementation
/// @author HHK-ETH
/// @notice Sustainable and gas efficient DCA vault
contract Vault is Clone {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error OwnerOnly();
    error TooClose();
    error NotEnough();
    error OracleError();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------
    event ExecuteDCA(uint256 received);
    event Withdraw(ERC20 token, uint256 amount);
    event Cancel();

    /// -----------------------------------------------------------------------
    /// Immutable variables
    /// -----------------------------------------------------------------------

    uint256 private constant PRECISION = 1e24;

    ///@notice Address of the BentoBox
    function bento() public pure returns (IBentoBox) {
        return IBentoBox(payable(_getArgAddress(0)));
    }

    ///@notice Address of the vault owner
    function owner() public pure returns (address) {
        return _getArgAddress(20);
    }

    ///@notice Address of the token to sell
    function sellToken() public pure returns (ERC20) {
        return ERC20(_getArgAddress(40));
    }

    ///@notice Address of the token to buy
    function buyToken() public pure returns (ERC20) {
        return ERC20(_getArgAddress(60));
    }

    ///@notice Infos about the DCA
    ///@return _sellTokenPriceFeed Address of the priceFeed
    ///@return _buyTokenPriceFeed Address of the priceFeed
    ///@return _epochDuration Minimum time between each buy
    ///@return _sellAmount Amount of token to sell
    ///@return _sellTokenDecimalsFactor 10 ** sellToken.decimals()
    ///@return _buyTokenDecimalsFactor 10 ** buyToken.decimals()
    function dcaData()
        public
        pure
        returns (IAggregatorInterface, IAggregatorInterface, uint64, uint256, uint256, uint256)
    {
        return (
            IAggregatorInterface(_getArgAddress(80)),
            IAggregatorInterface(_getArgAddress(100)),
            _getArgUint64(120),
            _getArgUint256(128),
            _getArgUint256(160),
            _getArgUint256(192)
        );
    }

    /// -----------------------------------------------------------------------
    /// Mutable variables
    /// -----------------------------------------------------------------------

    ///@notice Store last buy timestamp, init as block.timestamp
    uint256 public lastBuy;

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner()) {
            revert OwnerOnly();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// State change functions
    /// -----------------------------------------------------------------------

    ///@notice Execute the DCA buy
    ///@param multicall Multicall contract
    ///@param calls Actions to execute on the multicall
    function executeDCA(IMulticall3 multicall, IMulticall3.Call[] calldata calls) external {
        (
            IAggregatorInterface sellTokenPriceFeed,
            IAggregatorInterface buyTokenPriceFeed,
            uint64 epochDuration,
            uint256 sellAmount,
            uint256 sellTokenDecimalsFactor,
            uint256 buyTokenDecimalsFactor
        ) = dcaData();

        if (lastBuy + epochDuration > block.timestamp) {
            revert TooClose();
        }
        lastBuy = block.timestamp;

        uint256 minAmount;
        //Put minAmount calculation in a block to avoid stack too deep
        {
            //query oracles and determine minAmount, both priceFeed must have same decimals.
            uint256 sellTokenPriceUSD = getPrice(sellTokenPriceFeed);
            uint256 buyTokenPriceUSD = getPrice(buyTokenPriceFeed);

            assembly {
                let ratio := div(mul(sellTokenPriceUSD, PRECISION), buyTokenPriceUSD)
                minAmount := mul(ratio, sellAmount)
                minAmount := div(minAmount, sellTokenDecimalsFactor)
                minAmount := mul(minAmount, buyTokenDecimalsFactor)
                minAmount := mul(minAmount, 995)
                minAmount := div(minAmount, 1000)
                minAmount := div(minAmount, PRECISION)
            }
        }

        //save current balance
        uint256 previousBalance = bento().balanceOf(buyToken(), address(this));
        //send tokens to worker contract and call job
        bento().transfer(sellToken(), address(this), address(multicall), sellAmount);
        multicall.aggregate(calls);

        //Check if received enough
        uint256 minAmountToShare = bento().toShare(buyToken(), minAmount, false);
        uint256 received = bento().balanceOf(buyToken(), address(this)) - previousBalance;
        if (received < minAmountToShare) {
            revert NotEnough();
        }

        emit ExecuteDCA(received);
    }

    ///@notice Allow the owner to withdraw its token from the vault
    function withdraw(ERC20 token, uint256 amount) external onlyOwner {
        bento().withdraw(token, address(this), owner(), amount, 0);
        emit Withdraw(token, amount);
    }

    ///@notice Allow the owner to withdraw total balance and emit a Cancel event so UI stop showing the contract
    ///@notice Doesn't use selfdestruct as it is deprecated
    function cancel() external onlyOwner {
        bento().withdraw(sellToken(), address(this), owner(), 0, bento().balanceOf(sellToken(), address(this)));
        bento().withdraw(buyToken(), address(this), owner(), 0, bento().balanceOf(buyToken(), address(this)));
        emit Cancel();
    }

    ///@notice function to set last buy on vault creation
    ///@param waitEpochPeriod false to set to 1 so first execDca can be called or true to wait for epochPeriod before first exec
    function setLastBuy(bool waitEpochPeriod) external {
        if (lastBuy == 0) {
            if (waitEpochPeriod) {
                lastBuy = block.timestamp;
            } else {
                lastBuy = 1;
            }
        }
    }

    function getPrice(IAggregatorInterface sellTokenPriceFeed) internal view returns (uint256) {
        (, int256 integerPrice,,,) = sellTokenPriceFeed.latestRoundData();
        if (integerPrice <= 0) {
            revert OracleError();
        }
        return uint256(integerPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorInterface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint256);
}

//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IBentoBox {
    function transfer(ERC20 token, address from, address to, uint256 share) external;

    function withdraw(ERC20 token_, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function balanceOf(ERC20 token, address account) external returns (uint256);

    function toAmount(ERC20 token, uint256 share, bool roundUp) external returns (uint256);

    function toShare(ERC20 token, uint256 amount, bool roundUp) external returns (uint256);
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

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT
interface IMulticall3 {
    struct Call {
        address target;
        bytes callData;
    }
    
    function aggregate(Call[] calldata calls) external payable returns (uint256 blockNumber, bytes[] memory returnData);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}