// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ERC1155TokenReceiver } from "solmate/tokens/ERC1155.sol";

import { Auth } from "./mixins/Auth.sol";
import { Transfers } from "./mixins/Transfers.sol";

import { IExchange } from "./interfaces/IExchange.sol";
import { IFeeModule } from "./interfaces/IFeeModule.sol";

import { Order, Side } from "./libraries/Structs.sol";
import { CalculatorHelper } from "./libraries/CalculatorHelper.sol";

/// @title Polymarket CTF Fee Module
/// @notice Proxies the CTFExchange contract and refunds maker orders
/// @author Jon Amenechi ([email protected])
contract FeeModule is IFeeModule, Auth, Transfers, ERC1155TokenReceiver {
    /// @notice The Exchange contract
    IExchange public immutable exchange;

    /// @notice The Collateral token
    address public immutable collateral;

    /// @notice The CTF contract
    address public immutable ctf;

    constructor(address _exchange) {
        exchange = IExchange(_exchange);
        collateral = exchange.getCollateral();
        ctf = exchange.getCtf();
    }

    /// @notice Matches a taker order against a list of maker orders, refunding maker order fees if necessary
    /// @param takerOrder       - The active order to be matched
    /// @param makerOrders      - The array of maker orders to be matched against the active order
    /// @param takerFillAmount  - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts - The array of amounts to fill on the maker orders, always in terms of the maker amount
    /// @param makerFeeRate     - The fee rate to be charged to maker orders
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 makerFeeRate
    ) external onlyAdmin {
        // Match the orders on the exchange
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, makerFillAmounts);

        // Refund maker fees
        _refundFees(makerOrders, makerFillAmounts, makerFeeRate);
    }

    /// @notice Withdraw collected fees
    /// @param id       - The tokenID to be withdrawn. If 0, will be the collateral token.
    /// @param amount   - The amount to be withdrawn
    function withdrawFees(address to, uint256 id, uint256 amount) external onlyAdmin {
        address token = id == 0 ? collateral : ctf;
        _transfer(token, address(this), to, id, amount);
        emit FeeWithdrawn(token, to, id, amount);
    }

    /// @notice Refund fees for a set of orders
    /// @param orders       - The array of orders
    /// @param fillAmounts  - The array of fill amounts for the orders
    /// @param feeRate      - The fee rate to be charged to maker orders
    function _refundFees(Order[] memory orders, uint256[] memory fillAmounts, uint256 feeRate) internal {
        uint256 length = orders.length;
        uint256 i = 0;
        for (; i < length;) {
            if(orders[i].feeRateBps > feeRate) {
                _refundFee(orders[i], fillAmounts[i], feeRate);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Refund fee for an order
    /// @param order        - The order
    /// @param fillAmount   - The fill amount for the order
    /// @param feeRate      - The fee rate to be charged to maker orders
    function _refundFee(Order memory order, uint256 fillAmount, uint256 feeRate) internal {
        // Calculate refund for the order, if any
        uint256 refund = CalculatorHelper.calcRefund(
            order.feeRateBps,
            feeRate,
            order.side == Side.BUY ? CalculatorHelper.calculateTakingAmount(fillAmount, order.makerAmount, order.takerAmount) : fillAmount,
            order.makerAmount,
            order.takerAmount,
            order.side
        );

        uint256 id = order.side == Side.BUY ? order.tokenId : 0;
        address token = order.side == Side.BUY ? ctf : collateral;

        // If the refund is non-zero, transfer it to the order maker
        if (refund > 0) {
            _transfer(token, address(this), order.maker, id, refund);
            emit FeeRefunded(token, order.maker, id, refund);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IAuth } from "../interfaces/IAuth.sol";

/// @title Auth
/// @notice Provides access control modifiers
abstract contract Auth is IAuth {
    /// @notice Auth
    mapping(address => uint256) public admins;

    modifier onlyAdmin() {
        if (admins[msg.sender] != 1) revert NotAdmin();
        _;
    }

    constructor() {
        admins[msg.sender] = 1;
    }

    /// @notice Adds an Admin
    /// @param admin - The address of the admin
    function addAdmin(address admin) external onlyAdmin {
        admins[admin] = 1;
        emit NewAdmin(msg.sender, admin);
    }

    /// @notice Removes an admin
    /// @param admin - The address of the admin to be removed
    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = 0;
        emit RemovedAdmin(msg.sender, admin);
    }

    /// @notice Renounces Admin privileges from the caller
    function renounceAdmin() external onlyAdmin {
        admins[msg.sender] = 0;
        emit RemovedAdmin(msg.sender, msg.sender);
    }

    /// @notice Checks if an address is an admin
    /// @param addr - The address to be checked
    function isAdmin(address addr) external view returns (bool) {
        return admins[addr] == 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { TransferHelper } from "../libraries/TransferHelper.sol";

contract Transfers {
    /// @notice Transfers tokens. no-op if amount is zero
    /// @param token    - The Token to be transferred
    /// @param from     - The originating address
    /// @param to       - The destination address
    /// @param id       - The TokenId to be transferred, 0 if ERC20
    /// @param amount   - The amount of tokens to be transferred
    function _transfer(address token, address from, address to, uint256 id, uint256 amount) internal {
        if (amount > 0) {
            if (id == 0) {
                return from == address(this)
                    ? TransferHelper._transferERC20(token, to, amount)
                    : TransferHelper._transferFromERC20(token, from, to, amount);
            }
            return TransferHelper._transferFromERC1155(token, from, to, id, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order } from "../libraries/Structs.sol";

interface IExchange {
    function getCollateral() external view returns (address);

    function getCtf() external view returns (address);

    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order } from "../libraries/Structs.sol";

interface IFeeModuleEE {
    /// @notice Emitted when fees are withdrawn from the FeeModule
    event FeeWithdrawn(address token, address to, uint256 id, uint256 amount);

    /// @notice Emitted when fees are refunded to the order maker
    event FeeRefunded(address token, address to, uint256 id, uint256 amount);
}

interface IFeeModule is IFeeModuleEE {
    function matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 makerFeeRate
    ) external;

    function withdrawFees(address to, uint256 id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum Side {
    // 0: buy
    BUY,
    // 1: sell
    SELL
}

enum SignatureType {
    // 0: ECDSA EIP712 signatures signed by EOAs
    EOA,
    // 1: EIP712 signatures signed by EOAs that own Polymarket Proxy wallets
    POLY_PROXY,
    // 2: EIP712 signatures signed by EOAs that own Polymarket Gnosis safes
    POLY_GNOSIS_SAFE
}

struct OrderStatus {
    bool isFilledOrCancelled;
    uint256 remaining;
}

struct Order {
    /// @notice Unique salt to ensure entropy
    uint256 salt;
    /// @notice Maker of the order, i.e the source of funds for the order
    address maker;
    /// @notice Signer of the order
    address signer;
    /// @notice Address of the order taker. The zero address is used to indicate a public order
    address taker;
    /// @notice Token Id of the CTF ERC1155 asset to be bought or sold
    /// If BUY, this is the tokenId of the asset to be bought, i.e the makerAssetId
    /// If SELL, this is the tokenId of the asset to be sold, i.e the takerAssetId
    uint256 tokenId;
    /// @notice Maker amount, i.e the maximum amount of tokens to be sold
    uint256 makerAmount;
    /// @notice Taker amount, i.e the minimum amount of tokens to be received
    uint256 takerAmount;
    /// @notice Timestamp after which the order is expired
    uint256 expiration;
    /// @notice Nonce used for onchain cancellations
    uint256 nonce;
    /// @notice Fee rate, in basis points, charged to the order maker, charged on proceeds
    uint256 feeRateBps;
    /// @notice The side of the order: BUY or SELL
    Side side;
    /// @notice Signature type used by the Order: EOA, POLY_PROXY or POLY_GNOSIS_SAFE
    SignatureType signatureType;
    /// @notice The order signature
    bytes signature;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Order, Side } from "../libraries/Structs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    /// @notice Calculates the fee refund for an Order
    /// @notice Used to refund Order makers if a user signs a fee into an Order that is > the expeceted fee
    /// @param orderFeeRateBps      - The fee rate signed into the order by the user
    /// @param operatorFeeRateBps   - The fee rate chosen by the operator
    /// @param outcomeTokens        - The number of outcome tokens
    /// @param makerAmount          - The maker amount of the order
    /// @param takerAmount          - The taker amount of the order
    /// @param side                 - The side of the order
    function calcRefund(
        uint256 orderFeeRateBps,
        uint256 operatorFeeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256) {
        if (orderFeeRateBps <= operatorFeeRateBps) return 0;

        uint256 fee = calculateFee(orderFeeRateBps, outcomeTokens, makerAmount, takerAmount, side);

        // fee calced using order fee minus fee calced using the operator fee
        if (operatorFeeRateBps == 0) return fee;
        return fee - calculateFee(operatorFeeRateBps, outcomeTokens, makerAmount, takerAmount, side);
    }

    /// @notice Calculates the taking amount, i.e the amount of tokens to be received
    /// @param makingAmount - The making amount
    /// @param makerAmount  - The maker amount of the order
    /// @param takerAmount  - The taker amount of the order
    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        if (makerAmount == 0) return 0;
        return makingAmount * takerAmount / makerAmount;
    }

    /// @notice Calculates the fee for an order
    /// @dev Fees are calculated based on amount of outcome tokens and the order's feeRate
    /// @param feeRateBps       - Fee rate, in basis points
    /// @param outcomeTokens    - The number of outcome tokens
    /// @param makerAmount      - The maker amount of the order
    /// @param takerAmount      - The taker amount of the order
    /// @param side             - The side of the order
    function calculateFee(
        uint256 feeRateBps,
        uint256 outcomeTokens,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal pure returns (uint256 fee) {
        if (feeRateBps > 0) {
            uint256 price = _calculatePrice(makerAmount, takerAmount, side);
            if (price > 0 && price <= ONE) {
                if (side == Side.BUY) {
                    // Fee charged on Token Proceeds:
                    // baseRate * min(price, 1-price) * (outcomeTokens/price)
                    fee = (feeRateBps * min(price, ONE - price) * outcomeTokens) / (price * BPS_DIVISOR);
                } else {
                    // Fee charged on Collateral proceeds:
                    // baseRate * min(price, 1-price) * outcomeTokens
                    fee = feeRateBps * min(price, ONE - price) * outcomeTokens / (BPS_DIVISOR * ONE);
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        if (side == Side.BUY) return takerAmount != 0 ? makerAmount * ONE / takerAmount : 0;
        return makerAmount != 0 ? takerAmount * ONE / makerAmount : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAuthEE {
    error NotAdmin();

    /// @notice Emitted when a new admin is added
    event NewAdmin(address indexed admin, address indexed newAdminAddress);

    /// @notice Emitted when an admin is removed
    event RemovedAdmin(address indexed admin, address indexed removedAdmin);
}

interface IAuth is IAuthEE {
    function isAdmin(address) external view returns (bool);

    function addAdmin(address) external;

    function removeAdmin(address) external;

    function renounceAdmin() external;
}

// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { ERC1155 } from "solmate/tokens/ERC1155.sol";
import { SafeTransferLib, ERC20 } from "solmate/utils/SafeTransferLib.sol";

/// @title TransferHelper
/// @notice Helper method to transfer tokens
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @param token    - The contract address of the token which will be transferred
    /// @param to       - The recipient of the transfer
    /// @param amount   - The amount to be transferred
    function _transferERC20(address token, address to, uint256 amount) internal {
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param amount   - The amount to be transferred
    function _transferFromERC20(address token, address from, address to, uint256 amount) internal {
        SafeTransferLib.safeTransferFrom(ERC20(token), from, to, amount);
    }

    /// @notice Transfer an ERC1155 token
    /// @param token    - The contract address of the token to be transferred
    /// @param from     - The originating address from which the tokens will be transferred
    /// @param to       - The destination address of the transfer
    /// @param id       - The tokenId of the token to be transferred
    /// @param amount   - The amount to be transferred
    function _transferFromERC1155(address token, address from, address to, uint256 id, uint256 amount) internal {
        ERC1155(token).safeTransferFrom(from, to, id, amount, "");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
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