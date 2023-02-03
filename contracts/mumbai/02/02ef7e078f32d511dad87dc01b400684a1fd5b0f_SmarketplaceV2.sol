// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IRoyaltiesStorageV2 {
    function getRoyalties(
        address tokenAddress,
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        returns (
            uint256[] memory royaltyFeeAmounts,
            address[] memory royaltyRecipients
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title LibBp
/// @dev Library for computing basis points.
/// @author Smart-Chain Team

library LibBp {
    /// @dev Compute percentage
    /// @param value amount to compute percentage from
    /// @param bpFee percentage fee in base 100
    /// @return uint256 computed amount from sent percentage
    function bp(uint256 value, uint256 bpFee) internal pure returns (uint256) {
        return bpFee != 0 ? (value * bpFee) / 10_000 : 0;
    }

    /// @dev Safe substraction with computed percentage amount from fees
    /// @param value amount to compute percentage from
    /// @param total total amount to substract fees with
    /// @param feeInBp percentage fee in base 100
    /// @return newValue computed left amount from substracted fees
    /// @return realFee computed amount for fees
    function subFeeInBp(uint256 value, uint256 total, uint256 feeInBp)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        return subFee(value, bp(total, feeInBp));
    }

    /// @dev Safe substraction from computed fees
    /// @param value amount to compare and susbtract fee amount with
    /// @param fee computed amount for fees
    /// @return newValue computed left amount from substracted fees
    /// @return realFee computed amount for fees
    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            unchecked {
                newValue = value - fee;
            }
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IRoyaltiesStorageV2} from "./Interfaces/IRoyaltiesStorageV2.sol";
import {LibBp} from "./LibBp.sol";
import {SmartOrder} from "./SmartOrder.sol";
import {TransferProxy} from "./TransferProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from
    "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//                           #&&&&&&&&&#
//                      .%&&&&&&&&&&&&&&
//                  ,&%&&&&&&&&&&&&&&&&*
//              #&&&&&&&&&&&&&&&&&&&,
//         .%&&&&&&&&&&&&&&&&%&%                          .
//     .&&&&&&&&&&&&&&&&&&&#                         %&&&%&%&&/
//    .&&&&&&&&&&&&&&&&&&                       ,%&%%&&&&&&&&&&.
//     *&&&&&&&&&&&&&&&&&&&(                /&&&&&&&&&&&&&&&&&%
//         ,%&&&&&&&&&&&&&&&&%&&.       %&&&&&&&&&&&&&&&&&%%.
//              #&&&&&&&&&&&&&&&&&%%&&%&&&&&&&&&&&&&&&&%
//                  ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&/
//                       %&&&&&&&&&&&&&&&&&&&&%.
//                           /&&&&&&&&&&&&%             %&&&&%
//                               *&&&&(               %&&&&&&&&(
//                                                    &&&&&&&&&%
//                                                    %&&&&&&&&%
//         ,#&&#                                     (&&&&&&&&&%
//       #&&&&&&&&&&,                              ,&&&&&&&&&&&%
//       &&&&&&&&&&&&&%&(                      *&&&&&&&&&&&&&&&%
//       .&%&&&&&&&&&&&&&&&&%              #%&&&&&&&&&&&&&%&%&%
//           (&%&&&&&&&&&&&&&&&&&*    .%&&&&&&&&&&&&&&&&&&#
//               *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%&&%/
//                   .%&&&&&&&&&&&&&&&&&&&&&&&&&%&.
//                        (&&%&&&&&&&&&&&&&&%#
//                            ,&&&&&&&%&&/
//  ____  __  __    _    ____  _  _______ _____ ____  _        _    ____ _____
// / ___||  \/  |  / \  |  _ \| |/ | ____|_   _|  _ \| |      / \  / ___| ____|
// \___ \| |\/| | / _ \ | |_) | ' /|  _|   | | | |_) | |     / _ \| |   |  _|
//  ___) | |  | |/ ___ \|  _ <| . \| |___  | | |  __/| |___ / ___ | |___| |___
// |____/|_|  |_/_/   \_|_| \_|_|\_|_____| |_| |_|   |_____/_/   \_\____|_____|

/// @title Smarketplace V2
/// @dev Core smart-contract for the Marketplace product.
/// It verifies and execute token transfers if order condition are met.
/// Cancelation of orders is also possible if you are the originator.
/// Allows the trade of the following pairs:
/// - ERC-721 <-> ETH
/// - ERC-721 <-> ERC-20
/// - ERC-721 <-> ERC-721
/// - ERC-721 <-> ERC-1155
/// - ERC-20 <-> ETH
/// - ERC-20 <-> ERC-20
/// - ERC-20 <-> ERC-721
/// - ERC-20 <-> ERC-1155
/// - ERC-1155 <-> ETH
/// - ERC-1155 <-> ERC-20
/// - ERC-1155 <-> ETH
/// - ERC-1155 <-> ERC-20
/// - ERC-1155 <-> ERC-721
/// - ERC-1155 <-> ERC-1155
/// @notice The V2 adds the following features:
/// - added batched orders execution
/// - updated royalty payments with RoyaltiesStorageV2
/// @author Smart-Chain Team

contract SmarketplaceV2 is
    Ownable,
    ReentrancyGuard,
    SmartOrder,
    TransferProxy
{
    /// @dev Error when the contract is paused.
    error SmarketplaceV2__ContractIsPaused();

    /// @dev Error when the caller is not the maker of the order.
    error SmarketplaceV2__NotMakerOfOrder();

    /// @dev Error when the order has already expired.
    error SmarketplaceV2__OrderHasExpired();

    /// @dev Error when the order has not started yet.
    error SmarketplaceV2__OrderHasNotStarted();

    /// @dev Error when the order is already cancelled.
    error SmarketplaceV2__OrderIsCancelled();

    /// @dev Error when the order is already executed.
    error SmarketplaceV2__OrderAlreadyExecuted();

    /// @dev Error when the transfer execution fails on one side.
    /// @param side - side which failed
    error SmarketplaceV2__TransferExecutionFailed(bytes32 side);

    /// @dev Error when zero amount is given for transfer.
    error SmarketplaceV2__CannotTransferZeroAmount();

    /// @dev Error when the sent amount is incorrect.
    error SmarketplaceV2__IncorrectSentAmount();

    /// @dev Error when the tokenId given is not zero.
    /// @param assetType - type of asset which failed
    error SmarketplaceV2__TokenIdIsNotZero(bytes32 assetType);

    /// @dev Error when the verified originator is incorrect.
    error SmarketplaceV2__IncorrectOriginator();

    /// @dev Error when the amount given is not one for ERC-721.
    error SmarketplaceV2__TokenAmountIsNotOne();

    /// @dev Error when the sell asset class is ETH.
    error SmarketplaceV2__SellAssetClassCannotBeETH();

    /// @dev Error when sending ETH.
    error SmarketplaceV2__ErrorWhileTransferringETH();

    /// @dev Error when trying to execute zero orders.
    error SmarketplaceV2__CannotExecuteZeroOrders();

    /// @dev Error when the batch of params is incorrect.
    error SmarketplaceV2__IncorrectExecuteOrdersParams();

    /// @dev Error when delegating to ZERO address.
    error SmarketplaceV2__CannotDelegateToZeroAddress();

    enum FeeSide {
        NONE,
        BUY,
        SELL
    }

    enum State {
        Open,
        Executed,
        Canceled
    }

    struct NFTAsset {
        // @notice Address of the token contract.
        address tokenAddress;
        // @notice Id of the NFT token.
        uint256 tokenId;
    }

    struct SplitSignature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // @notice Commission fee for the marketplace. (base percent a 100)
    uint256 public commissionFee;

    // @notice Address of the public reserve for the commission fee.
    address public reserveAddress;

    // @notice Hash to State status of the order.
    mapping(bytes32 => State) public orderHashToState;

    // @notice Royalties storage contract.
    address public royaltiesStorage;

    // @notice Contract state for emergency pause.
    bool public isPaused;

    /// @dev @TODO The asset type is missing inside the event.
    /// It makes the indexing part more difficult.
    event OrderExecuted(
        address indexed sellerAddress,
        address indexed sellTokenAddress,
        uint256 indexed sellTokenId,
        address buyerAddress,
        address recipientAddress,
        uint256 sellTokenAmount,
        address buyTokenAddress,
        uint256 buyTokenId,
        uint256 buyTokenAmount,
        bytes32 hash_
    );

    event OrderCancelled(
        address indexed sellerAddress,
        address indexed sellTokenAddress,
        uint256 indexed sellTokenId,
        uint256 sellTokenAmount,
        bytes32 hash_
    );

    event CommissionFeeUpdated(uint256 commissionFee);
    event ReserveAddressUpdated(address reserveAddress);
    event RoyaltiesStorageUpdated(address royaltiesStorage);
    event EmergencyPause(bool status);

    /// @dev Modifier to check if the contract is paused.
    modifier isNotPaused() {
        if (isPaused) {
            revert SmarketplaceV2__ContractIsPaused();
        }
        _;
    }

    constructor(address royaltiesStorage_) SmartOrder() {
        royaltiesStorage = royaltiesStorage_;
    }

    /// @dev Cancel order
    /// @param ordersData array of data containing the orders to cancel
    function cancelOrder(Order[] calldata ordersData)
        external
        nonReentrant
        isNotPaused
    {
        uint256 ordersDataLength = ordersData.length;
        for (uint256 i; i < ordersDataLength; i = unchecked_inc(i)) {
            if (ordersData[i].sellerAddress != msg.sender) {
                revert SmarketplaceV2__NotMakerOfOrder();
            }

            bytes32 hash_ = hashOrder(ordersData[i]);

            /// @dev @TODO Add tests for this branch (in TS and sol).
            if (orderHashToState[hash_] == State.Executed) {
                revert SmarketplaceV2__OrderAlreadyExecuted();
            }

            orderHashToState[hash_] = State.Canceled;
            emit OrderCancelled(
                ordersData[i].sellerAddress,
                ordersData[i].sellTokenAddress,
                ordersData[i].sellTokenId,
                ordersData[i].sellTokenAmount,
                hash_
                );
        }
    }

    function executeOrder(
        Order calldata orderData,
        SplitSignature calldata splitSignature,
        address recipientAddress
    ) external payable nonReentrant isNotPaused {
        if (
            orderData.askAssetClass == SmartOrder.AssetClass.ETH
                && msg.value != orderData.askTokenAmount
        ) {
            revert SmarketplaceV2__IncorrectSentAmount();
        }
        _executeOrder(orderData, splitSignature, recipientAddress);
    }

    /// @notice We assume the recipientAddress will stay the same when executing this entrypoint.
    /// May change later if we need to package orders in a custodial manner.
    function batchExecuteOrders(
        Order[] calldata orderData,
        SplitSignature[] calldata splitSignature,
        address recipientAddress
    ) external payable nonReentrant isNotPaused {
        uint256 orderDataLength = orderData.length;
        if (orderDataLength == 0) {
            revert SmarketplaceV2__CannotExecuteZeroOrders();
        }
        if (orderDataLength != splitSignature.length) {
            revert SmarketplaceV2__IncorrectExecuteOrdersParams();
        }

        uint256 accumulatedPayments;
        for (uint256 i; i < orderDataLength; i = unchecked_inc(i)) {
            if (orderData[i].askAssetClass == SmartOrder.AssetClass.ETH) {
                accumulatedPayments += orderData[i].askTokenAmount;
                if (msg.value < accumulatedPayments) {
                    revert SmarketplaceV2__IncorrectSentAmount();
                }
            }
            _executeOrder(orderData[i], splitSignature[i], recipientAddress);
        }
    }

    /// @dev Update commissions fee in base 100
    /// @param commissionFee_ commission fee in base 100 to update
    function setCommissionFee(uint256 commissionFee_) external onlyOwner {
        commissionFee = commissionFee_;

        emit CommissionFeeUpdated(commissionFee_);
    }

    /// @dev Update reserve address which receives commissions fees
    /// @param reserveAddress_ address to update reserve with
    function setReserveAddress(address reserveAddress_) external onlyOwner {
        reserveAddress = reserveAddress_;

        emit ReserveAddressUpdated(reserveAddress_);
    }

    /// @dev Update royalty storage address
    /// @param royaltiesStorage_ address to update royalties storage with
    function setRoyaltiesStorageAddress(address royaltiesStorage_)
        external
        onlyOwner
    {
        royaltiesStorage = royaltiesStorage_;

        emit RoyaltiesStorageUpdated(royaltiesStorage_);
    }

    /// @dev Pause contract if necessary
    /// @param status boolean status for contract
    function emergencyPause(bool status) external onlyOwner {
        isPaused = status;

        emit EmergencyPause(status);
    }

    /// @dev Withdraw ETH from marketplace contract when buyers are over-paying their orders.
    function withdrawLockedFunds() external payable onlyOwner {
        transferETH(payable(owner()), address(this).balance);
    }

    /// @dev Execute transfers for an order.
    /// @param orderData data of the order to execute
    /// @param splitSignature signed message of the order to execute from the trade originator
    /// @param recipientAddress Recipient address of the bougth asset.
    function _executeOrder(
        Order calldata orderData,
        SplitSignature calldata splitSignature,
        address recipientAddress
    ) internal {
        if (recipientAddress == address(0)) {
            revert SmarketplaceV2__CannotDelegateToZeroAddress();
        }

        if (orderData.expirationTime < block.timestamp) {
            revert SmarketplaceV2__OrderHasExpired();
        }

        if (orderData.startTime > block.timestamp) {
            revert SmarketplaceV2__OrderHasNotStarted();
        }

        /// @TODO: Check if ETH pending withdrawal attack is still possible.
        if (orderData.sellAssetClass == SmartOrder.AssetClass.ETH) {
            revert SmarketplaceV2__SellAssetClassCannotBeETH();
        }

        bytes32 hash_ = hashOrder(orderData);
        require(
            verifyOriginator(
                orderData.sellerAddress,
                hash_,
                splitSignature.v,
                splitSignature.r,
                splitSignature.s
            )
        );

        if (orderHashToState[hash_] == State.Canceled) {
            revert SmarketplaceV2__OrderIsCancelled();
        }

        if (orderHashToState[hash_] == State.Executed) {
            revert SmarketplaceV2__OrderAlreadyExecuted();
        }

        orderHashToState[hash_] = State.Executed;

        FeeSide feeSide =
            getFeeSide(orderData.sellAssetClass, orderData.askAssetClass);

        NFTAsset memory nftAsset;
        if (orderData.sellAssetClass == AssetClass.ERC721) {
            nftAsset =
                NFTAsset(orderData.sellTokenAddress, orderData.sellTokenId);
        } else {
            nftAsset = NFTAsset(orderData.askTokenAddress, orderData.askTokenId);
        }

        // Sending asset to BUYER
        if (
            !executeTransfer(
                orderData.sellerAddress,
                recipientAddress,
                orderData.sellTokenAddress,
                orderData.sellTokenId,
                orderData.sellTokenAmount,
                orderData.sellAssetClass,
                feeSide == FeeSide.SELL,
                nftAsset
            )
        ) {
            revert SmarketplaceV2__TransferExecutionFailed("BUYER");
        }

        // Sending asset to SELLER
        if (
            !executeTransfer(
                msg.sender,
                orderData.sellerAddress,
                orderData.askTokenAddress,
                orderData.askTokenId,
                orderData.askTokenAmount,
                orderData.askAssetClass,
                feeSide == FeeSide.BUY,
                nftAsset
            )
        ) {
            revert SmarketplaceV2__TransferExecutionFailed("SELLER");
        }

        emit OrderExecuted(
            orderData.sellerAddress,
            orderData.sellTokenAddress,
            orderData.sellTokenId,
            msg.sender,
            recipientAddress,
            orderData.sellTokenAmount,
            orderData.askTokenAddress,
            orderData.askTokenId,
            orderData.askTokenAmount,
            hash_
            );
    }

    /// @dev Execute a ETH/token transfer
    /// @param from spender address
    /// @param to receiver address
    /// @param tokenAddress asset address to use for transfer
    /// @param tokenId asset tokenId to use for transfer
    /// @param tokenAmount total amount of tokens to use for transfer
    /// @param assetClass asset class of the token used for transfer
    /// @param hasFees boolean to determine if spender will pay for commission and royalty fees as well
    /// @param nftAsset details on the NFT asset being exchanged
    /// @return bool if transfer has been successful
    function executeTransfer(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 tokenAmount,
        AssetClass assetClass,
        bool hasFees,
        NFTAsset memory nftAsset
    ) internal returns (bool) {
        if (tokenAmount == 0) {
            revert SmarketplaceV2__CannotTransferZeroAmount();
        }

        uint256 commissionFee_;
        uint256 amountLeft = tokenAmount;
        uint256[] memory royaltyFeeAmounts_;
        address[] memory royaltyRecipients_;

        if (hasFees) {
            (amountLeft, commissionFee_) =
                LibBp.subFeeInBp(tokenAmount, tokenAmount, commissionFee);
            (royaltyFeeAmounts_, royaltyRecipients_) = IRoyaltiesStorageV2(
                royaltiesStorage
            ).getRoyalties(nftAsset.tokenAddress, nftAsset.tokenId, amountLeft);
        }

        if (assetClass == AssetClass.ETH) {
            if (tokenId != 0) {
                revert SmarketplaceV2__TokenIdIsNotZero("ETH");
            }

            transferETH(payable(address(reserveAddress)), commissionFee_);
            amountLeft = executeRoyaltyTransfers(
                royaltyFeeAmounts_,
                royaltyRecipients_,
                from,
                tokenAddress,
                tokenId,
                assetClass,
                amountLeft
            );
            transferETH(payable(address(to)), amountLeft);
        } else if (assetClass == AssetClass.ERC20) {
            if (tokenId != 0) {
                revert SmarketplaceV2__TokenIdIsNotZero("ERC20");
            }
            if (hasFees) {
                if (commissionFee_ != 0) {
                    transferERC20(
                        tokenAddress,
                        from,
                        address(reserveAddress),
                        commissionFee_
                    );
                }
                amountLeft = executeRoyaltyTransfers(
                    royaltyFeeAmounts_,
                    royaltyRecipients_,
                    from,
                    tokenAddress,
                    tokenId,
                    assetClass,
                    amountLeft
                );
            }
            transferERC20(tokenAddress, from, to, amountLeft);
        } else if (assetClass == AssetClass.ERC721) {
            if (tokenAmount != 1) {
                revert SmarketplaceV2__TokenAmountIsNotOne();
            }
            transferERC721(tokenAddress, from, to, tokenId);
        } else {
            // Last AssetClass is ERC-1155
            if (hasFees) {
                if (commissionFee_ != 0) {
                    transferERC1155(
                        tokenAddress,
                        from,
                        address(reserveAddress),
                        tokenId,
                        commissionFee_
                    );
                }
                amountLeft = executeRoyaltyTransfers(
                    royaltyFeeAmounts_,
                    royaltyRecipients_,
                    from,
                    tokenAddress,
                    tokenId,
                    assetClass,
                    amountLeft
                );
            }
            transferERC1155(tokenAddress, from, to, tokenId, amountLeft);
        }
        return true;
    }

    /// @dev Execute transfers for royalty payments to concerned parties
    /// @param royaltyFeeAmounts_ array of royalty percentage fees in base 100
    /// @param royaltyRecipients_ array of royalty reciptients
    /// @param from address that will pay for the royalties
    /// @param tokenAddress asset address to use for royalty payments
    /// @param tokenId asset tokenId to use for royalty payments if ERC-1155
    /// @param assetClass asset class of the token used for royalty payments
    /// @param amountLeft amount left from the commission payment
    /// @return uint256 return the left amount to transfer to final user after royalty payments
    function executeRoyaltyTransfers(
        uint256[] memory royaltyFeeAmounts_,
        address[] memory royaltyRecipients_,
        address from,
        address tokenAddress,
        uint256 tokenId,
        AssetClass assetClass,
        uint256 amountLeft
    ) internal returns (uint256) {
        uint256 royaltyRecipientLength = royaltyRecipients_.length;
        if (royaltyRecipientLength != 0 && amountLeft != 0) {
            for (uint256 i; i < royaltyRecipientLength; i = unchecked_inc(i)) {
                uint256 royaltyFeeAmount_ = royaltyFeeAmounts_[i];
                if (
                    royaltyFeeAmount_ != 0
                        && royaltyRecipients_[i] != address(0) && amountLeft != 0
                ) {
                    /// @dev We check for underflow.
                    if (amountLeft < royaltyFeeAmount_) {
                        royaltyFeeAmount_ = amountLeft;
                        amountLeft = 0;
                    } else {
                        /// @dev Since we check for underflow above, this line should be fine.
                        unchecked {
                            amountLeft -= royaltyFeeAmount_;
                        }
                    }

                    if (assetClass == AssetClass.ETH) {
                        transferETH(
                            payable(address(royaltyRecipients_[i])),
                            royaltyFeeAmount_
                        );
                    } else if (assetClass == AssetClass.ERC20) {
                        transferERC20(
                            tokenAddress,
                            from,
                            address(royaltyRecipients_[i]),
                            royaltyFeeAmount_
                        );
                    } else if (assetClass == AssetClass.ERC1155) {
                        transferERC1155(
                            tokenAddress,
                            from,
                            address(royaltyRecipients_[i]),
                            tokenId,
                            royaltyFeeAmount_
                        );
                    }
                }
            }
        }
        return amountLeft;
    }

    /// @dev Transfer ETH
    /// @param user ETH recipient address
    /// @param amount ETH amount to send
    function transferETH(address payable user, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        bool success;
        assembly {
            success := call(gas(), user, amount, 0, 0, 0, 0)
        }
        if (!success) {
            revert SmarketplaceV2__ErrorWhileTransferringETH();
        }
    }

    /// @dev Get the side of the trade who will pay commission and royalty fees
    /// @param sellSideAssetClass asset class of the seller side
    /// @param buySideAssetClass asset class of the buyer side
    /// @return FeeSide uint8 from enum FeeSide corresponding to the payer side of the fees
    function getFeeSide(
        AssetClass sellSideAssetClass,
        AssetClass buySideAssetClass
    ) internal pure returns (FeeSide) {
        if (
            sellSideAssetClass == AssetClass.ERC721
                && buySideAssetClass == AssetClass.ERC721
        ) {
            return FeeSide.NONE;
        }
        if (uint256(sellSideAssetClass) > uint256(buySideAssetClass)) {
            return FeeSide.BUY;
        }
        return FeeSide.SELL;
    }

    /// @dev Increment value through unchecked arithmetic for saving gas
    /// @param i - value to increment
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return ++i;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title SmartOrder
/// @dev Contract defining the structure and validity of an Order.
/// @author Smart-Chain Team

abstract contract SmartOrder {
    /// @dev Error when the signature is invalid.
    error SmartOrder__InvalidSignature();

    using ECDSA for bytes32;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Order {
        address sellerAddress;
        address sellTokenAddress;
        uint256 sellTokenId;
        uint256 sellTokenAmount;
        address askTokenAddress;
        uint256 askTokenId;
        uint256 askTokenAmount;
        uint256 startTime;
        uint256 expirationTime;
        uint256 salt;
        AssetClass sellAssetClass;
        AssetClass askAssetClass;
    }

    enum AssetClass {
        ETH,
        ERC20,
        ERC1155,
        ERC721
    }

    string internal constant EIP191_HEADER = "\x19\x01";

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address sellerAddress,address sellTokenAddress,uint256 sellTokenId,uint256 sellTokenAmount,address askTokenAddress,uint256 askTokenId,uint256 askTokenAmount,uint256 startTime,uint256 expirationTime,uint256 salt,uint8 sellAssetClass,uint8 askAssetClass)"
    );

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = _buildDomainSeparator(
            EIP712Domain({
                name: "Smarketplace",
                version: "1",
                chainId: _getChainId(),
                verifyingContract: address(this)
            })
        );
    }

    /// @dev Verify the originator of the signed message with the order sell address
    /// @param sellerAddress seller address of the order to verify
    /// @param hash_ hash of the order to verify
    /// @param v signed message of the order
    /// @param r signed message of the order
    /// @param s signed message of the order
    /// @return bool to confirm the user signature address
    function verifyOriginator(
        address sellerAddress,
        bytes32 hash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        require(
            sellerAddress == hash_.recover(v, r, s), "ECDSA: invalid Signature"
        );
        // if (orderData.sellerAddress != hash_.recover(sig)) {
        //     revert SmartOrder__InvalidSignature();
        // }
        return true;
    }

    /// @dev Get the Chain Id where the contract is deployed
    /// @return chainId current ChainId
    function _getChainId() internal view returns (uint256 chainId) {
        chainId = block.chainid;
    }

    /// @dev Hash the order by following the EIP-712 typehashing
    /// @param orderData data of the order to verify
    /// @return bytes32 hashed order ready to be signed or verified
    function hashOrder(Order calldata orderData)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        ORDER_TYPEHASH,
                        orderData.sellerAddress,
                        orderData.sellTokenAddress,
                        orderData.sellTokenId,
                        orderData.sellTokenAmount,
                        orderData.askTokenAddress,
                        orderData.askTokenId,
                        orderData.askTokenAmount,
                        orderData.startTime,
                        orderData.expirationTime,
                        orderData.salt,
                        orderData.sellAssetClass,
                        orderData.askAssetClass
                    )
                )
            )
        );
    }

    /// @dev Hash the domain of the contract by following the EIP-712 typehashing
    /// @param eip712Domain data of the contract domain
    /// @return bytes32 hashed domain
    function _buildDomainSeparator(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TransferProxy
/// @dev Contract helper for transferring tokens in a safely manner.
/// @author Smart-Chain Team

abstract contract TransferProxy {
    using SafeERC20 for IERC20;

    /// @dev Transfer ERC-20 tokens from two accounts in a safely manner
    /// @param tokenAddress ERC-20 token address to transfer
    /// @param from address of the ERC-20 token spender
    /// @param to recipient address of the ERC-20 token
    /// @param amount amount of ERC-20 tokens to transfer
    function transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(tokenAddress).safeTransferFrom(from, to, amount);
    }

    /// @dev Transfer ERC-721 tokens from two accounts in a safely manner
    /// @param tokenAddress ERC-721 token address to transfer
    /// @param from address of the ERC-721 token spender
    /// @param to recipient address of the ERC-721 token
    /// @param tokenId tokenId of the ERC-721 token to transfer
    function transferERC721(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        IERC721(tokenAddress).safeTransferFrom(from, to, tokenId);
    }

    /// @dev Transfer ERC-1155 tokens from two accounts in a safely manner
    /// @param tokenAddress ERC-1155 token address to transfer
    /// @param from address of the ERC-1155 token spender
    /// @param to recipient address of the ERC-1155 token
    /// @param tokenId tokenId of the ERC-1155 token to transfer
    /// @param amount amount of ERC-1155 tokens to transfer
    function transferERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}