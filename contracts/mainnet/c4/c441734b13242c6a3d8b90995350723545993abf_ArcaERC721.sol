// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IERC20} from "./Interfaces/IERC20.sol";
import {IERC721} from "./Interfaces/IERC721.sol";
import {SafeERC20} from "./Libraries/SafeERC20.sol";
import {FixedPointMathLib} from
    "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from
    "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721Holder} from
    "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

//
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
//
//
//                              ░░░░░░░░░░░░░░░░░░░░░░                 .--.
//                       )      ░░░░████████████████░░       %        /.-. '----------.
//     ▄▄█▀▀▀▀▀█▄▄      ) \     ░░██████████████████░░  ----------->  \'-' .--"--""-"-'
//   ▄█▀         ▀█▄   / ) (    ░░██████      ██████░░    EXIT-FEE     '--'
//   █   ERC-721   █   \(_)/    ░░░░████  ██  ██████░░                   Multisig (or EoA)
//   █  Governance █  ------->  ░░░░████      ██████░░
//   █    Token    █    BURN    ░░░░██████  ████████░░
//   ▀█▄         ▄█▀            ░░████████    ██████░░                                                   O
//     ▀▀█▄▄▄▄▄█▀▀              ░░██████████████████░░               ┌────────┐   ┌────────┐            /|\
//    (Can also be a)           ░░░░██ArcaERC721██░░░░  -----------> │ERC-20 A│ + │ERC-20 B│ + .... -->  |
//   (non-governance)           ░░░░░░░░░░░░░░░░░░░░░░    TRANSFER   └────────┘   └────────┘           _/ \_
//    (ERC-721 token)             ████          ████                                                Redeemer EoA
//                                                                                                  (or Multisig)
//
/// @title ArcaERC721
/// @dev Decentralized vault which allows governance tokens to be burned to redeem assets.
/// @author Smart-Chain Team

contract ArcaERC721 is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /// @dev Error when the caller is calling with amount ZERO.
    error ArcaERC721__CannotUseZeroAmount();

    /// @dev Error when the caller is trying to redeem more tokens than he owns.
    error ArcaERC721__CannotRedeemMoreThanYouOwn();

    /// @dev Error when a transfer fails.
    error ArcaERC721__TransferFailed();

    /// @dev Error when the admin is setting an exit-tax share value greather than 100%.
    error ArcaERC721__CannotSetExitTaxShareValueAbove100Bp();

    /// @dev Error when the caller is redeeming the basket with a share of Zero, despite having burned tokens.
    error ArcaERC721__CannotWithdrawWithZeroShare();

    address public indexedAssetAddress;
    address[] public indexOfAssetBasketAddresses;
    address public collectiveTreasuryAddress;
    /// @dev Exit-tax share value applied everytime a user wants to redeem from the basket.
    /// ex: 10/1_000 = 1% = ((1e18 * 10) / 1_000);
    /// @notice The exit-tax can be used by DAOs to create an additionnal revenue stream to feed a collective basket.
    uint256 public exitTaxForCollectiveTreasury;

    /// @dev Public accounting for FS.
    mapping(address => mapping(address => uint256)) public
        userAddressToBasketAssetAddressToAmountClaimed;

    struct ERC20Balance {
        address assetAddress;
        string name;
        uint256 amount;
    }

    event IndexOfAssetBasketAddressesUpdated(
        address[] indexOfAssetBasketAddresses
    );
    event IndexedAssetAddressUpdated(address indexed newIndexedAssetAddress);
    event CollectiveTreasuryAddressUpdated(
        address indexed newCollectiveTreasuryAddress
    );
    event ExitTaxForCollectiveTreasuryUpdated(
        uint256 indexed newExitTaxForCollectiveTreasury
    );
    event AdminWithdraw(
        address indexed addressOfAssetWithdrawn, uint256 amountWithdrawn
    );
    event RedeemProcessed(
        address indexed redeemerAddress,
        address indexed redeemedAssetAddress,
        uint256[] redeemedTokenIds,
        address[] redeemedAssetBasketAddresses,
        uint256[] redeemedAssetBasketAmounts
    );

    constructor(address initialIndexedAssetAddress) {
        /// @dev WARNING, the indexed ERC-721 asset should handle the `burn` and `totalSupply` method, otherwise the redeem mechanism won't work.
        indexedAssetAddress = initialIndexedAssetAddress;
    }

    /// @dev @TODO Add `address recipientAddress` to allow the caller to receive assets on another wallet.
    /// Can be useful for DAOs to delegate assets to third-parties.
    /// @dev Allow caller to redeem assets from the contract basket by burning an amount of owned indexed asset.
    /// @param tokenIds - Array of ERC-721 indexed asset token Ids to burn for redeeming the basket.
    function redeemBasketForAssetAmount(uint256[] memory tokenIds)
        external
        nonReentrant
    {
        uint256 amountOfAssetToRedeem = tokenIds.length;
        if (amountOfAssetToRedeem == 0) {
            revert ArcaERC721__CannotUseZeroAmount();
        }
        if (
            amountOfAssetToRedeem
                > IERC721(indexedAssetAddress).balanceOf(msg.sender)
        ) {
            revert ArcaERC721__CannotRedeemMoreThanYouOwn();
        }

        /// @dev We compute the share of asset redeemable inside the basket.
        /// If the ratio is too low, it may result to the transfer of ZERO amount of tokens.
        uint256 shareOfAssetToRedeem =
            getShareFromAssetAmount(amountOfAssetToRedeem);
        if (shareOfAssetToRedeem == 0) {
            revert ArcaERC721__CannotWithdrawWithZeroShare();
        }

        for (uint256 i; i < amountOfAssetToRedeem; i = unchecked_inc(i)) {
            /// @dev Assets are first set in escrow to this contract before burning them.
            IERC721(indexedAssetAddress).safeTransferFrom(
                msg.sender, address(this), tokenIds[i]
            );
            /// @dev We burn the assets of the user before sending the redeemed assets.
            /// If an issue is detected during the burning (incorrect balance/allowance/ownership), the transaction is immediately reverted.
            IERC721(indexedAssetAddress).burn(tokenIds[i]);
        }

        /// @dev We execute the transfer of each asset inside the basket.
        uint256 amountOfUniqueAssets = indexOfAssetBasketAddresses.length;
        uint256[] memory redeemedAssetBasketAmounts =
            new uint256[](amountOfUniqueAssets);
        for (uint256 j; j < amountOfUniqueAssets; j = unchecked_inc(j)) {
            address assetBasketAddress = indexOfAssetBasketAddresses[j];
            uint256 redeemAmountForAsset = previewRedeemWithShareForAsset(
                shareOfAssetToRedeem, assetBasketAddress
            );

            /// @dev If there is an exit-tax, we send it first to the collective basket.
            uint256 exitTaxForRedeemAmount =
                redeemAmountForAsset.mulWadDown(exitTaxForCollectiveTreasury);
            /// @dev The `collectiveTreasuryAddress` may not be initialized and we do not want to break the redeem process because of it.
            if (collectiveTreasuryAddress != address(0)) {
                IERC20(assetBasketAddress).safeTransfer(
                    collectiveTreasuryAddress, exitTaxForRedeemAmount
                );
                /// @dev We only truly apply the exit tax if the transfer to the collective treasury is successful.
                /// Otherwise, we keep the `redeemAmountForAsset` as is.
                /// In addition, since we cap the exit-tax share value at 100% (1e18), it should never underflow.
                unchecked {
                    redeemAmountForAsset -= exitTaxForRedeemAmount;
                }
            }

            /// @dev The redeem amount for a specific asset inside the basket is sent to the redeemer address.
            IERC20(assetBasketAddress).safeTransfer(
                msg.sender, redeemAmountForAsset
            );
            /// @dev The mapping could indeed overflow, so we do not put it as unchecked,
            /// even though there is no functional impact if there was an overflow.
            /// @TODO Check if we should put the `unchecked` or remove this accounting variable completely afterall.
            // solhint-disable-next-line reentrancy
            userAddressToBasketAssetAddressToAmountClaimed[msg.sender][assetBasketAddress]
            += redeemAmountForAsset;

            redeemedAssetBasketAmounts[j] = redeemAmountForAsset;
        }

        emit RedeemProcessed(
            msg.sender,
            indexedAssetAddress,
            tokenIds,
            indexOfAssetBasketAddresses,
            redeemedAssetBasketAmounts
            );
    }

    /// @dev Allow the admin of the contract to update the addressess of the indexed assets redeemable by hodlers.
    /// @param newIndexOfAssetBasketAddresses - Array of addresses containing the ERC-20 addresses of the assets.
    /// WARNING! The contract does not verify the validity of the given ERC-20 addressses since the ERC-20 does not implement ERC-165 natively.
    /// We could add a method that calls a random ERC-20 entrypoint for each address, but this would not protect from phishing contracts anyway.
    function updateIndexOfAssetBasketAddresses(
        address[] memory newIndexOfAssetBasketAddresses
    ) external onlyOwner {
        indexOfAssetBasketAddresses = newIndexOfAssetBasketAddresses;
        emit IndexOfAssetBasketAddressesUpdated(newIndexOfAssetBasketAddresses);
    }

    /// @dev Allow the admin of the contract to update the address of the indexed asset used for redeeming the contract basket.
    /// @param newIndexedAssetAddress - Address of an ERC-721 contract.
    /// WARNING! The contract does not verify the validity of the given ERC-721 addresss since the ERC-721 does not implement ERC-165 natively.
    /// We could add a method that calls a random ERC-721 entrypoint, but this would not protect from phishing contracts anyway.
    function updateIndexedAsset(address newIndexedAssetAddress)
        external
        onlyOwner
    {
        indexedAssetAddress = newIndexedAssetAddress;
        emit IndexedAssetAddressUpdated(newIndexedAssetAddress);
    }

    /// @dev Allow the admin of the contract to update the address of the collective treasury, which receives the exit-tax payments.
    /// @param newCollectiveTreasuryAddress - Address of the new treasury address (can be either an EoA or a contract).
    /// @notice If the updated address is ZERO address (by accident or not), there will be no impact for redeemers.
    /// However, the exit-tax payment will be ignored and the redeemer will get 100% of the redeemed amount.
    function updateCollectiveTreasuryAddress(
        address newCollectiveTreasuryAddress
    ) external onlyOwner {
        collectiveTreasuryAddress = newCollectiveTreasuryAddress;
        emit CollectiveTreasuryAddressUpdated(newCollectiveTreasuryAddress);
    }

    /// @dev Allow the admin of the contract to update the exit-tax share value.
    /// @param newExitTaxForCollectiveTreasury - Exit-tax share value to update to.
    /// If the latter is updated to ZERO, the exit-tax payment will be completely ignored during the redeeming process.
    function updateExitTaxForCollectiveTreasury(
        uint256 newExitTaxForCollectiveTreasury
    ) external onlyOwner {
        /// 1000/1000 = 100% = ((1e18 * 1000) / 1000); = 1e18;
        if (newExitTaxForCollectiveTreasury > 1e18) {
            revert ArcaERC721__CannotSetExitTaxShareValueAbove100Bp();
        }
        exitTaxForCollectiveTreasury = newExitTaxForCollectiveTreasury;
        emit ExitTaxForCollectiveTreasuryUpdated(
            newExitTaxForCollectiveTreasury
            );
    }

    /// @dev Allow the admin of the contract to withdraw any ERC-20 asset or ETH from the contract.
    /// @param addressOfAssetToWithdraw - Address of the asset to withdraw from the contract.
    /// If the admin requires a withdrawal of ETH, use `address(0)`.
    /// @notice This method can be used by the Admin to withdraw deposited assets.
    /// Can also be used for emergency purposes.
    function adminWithdrawForAsset(address addressOfAssetToWithdraw)
        external
        onlyOwner
    {
        address recipient = owner();
        uint256 amountToSend;
        /// @dev If `addressOfAssetToWithdraw` is ZERO address, it switches to ETH withdrawal.
        if (addressOfAssetToWithdraw == address(0)) {
            bool success;
            amountToSend = address(this).balance;
            assembly {
                success := call(gas(), recipient, amountToSend, 0, 0, 0, 0)
            }
            if (!success) {
                revert ArcaERC721__TransferFailed();
            }
        }
        /// @dev Otherwise, it should be an ERC-20 transfer by default.
        else {
            amountToSend =
                IERC20(addressOfAssetToWithdraw).balanceOf(address(this));
            IERC20(addressOfAssetToWithdraw).safeTransfer(
                recipient, amountToSend
            );
        }
        emit AdminWithdraw(addressOfAssetToWithdraw, amountToSend);
    }

    /// @dev This function is only used for FS purposes.
    /// It is too costly to use as is and may not even work properly as a view if nodes are non-compliant.
    /// @dev Return a preview of the redeemable amount for each basket assets based on a token amount of the indexed asset.
    /// @param amountOfAssetToRedeem - Token amount of the indexed asset.
    /// It will be used to compute a basket share redeemable based on a ratio with the indexed asset `totalSupply()`.
    /// @return ERC20Balance - Array of `ERC20Balance` struct containing the `name` and the redeemable amount for each indexed asset.
    /// WARNING! Since the `name()` entrypoint is optionnal in the EIP-20, we may encounter a revert during the call.
    /// We keep it as is for now since FS require it, but may disappear in a V2.
    function previewRedeemWithAmountForBasket(uint256 amountOfAssetToRedeem)
        external
        view
        returns (ERC20Balance[] memory)
    {
        if (
            amountOfAssetToRedeem
                > IERC721(indexedAssetAddress).balanceOf(msg.sender)
        ) {
            revert ArcaERC721__CannotRedeemMoreThanYouOwn();
        }

        /// @dev We pre-allocate memory for the return `ERC20Balance` variable.
        uint256 indexOfAssetBasketAddressesLength =
            indexOfAssetBasketAddresses.length;
        ERC20Balance[] memory basketBalance =
            new ERC20Balance[](indexOfAssetBasketAddressesLength);
        /// @dev We then compute the share of asset redeemable inside the basket.
        /// If the ratio is too low, it may result to the transfer of ZERO amount of tokens.
        uint256 shareOfAssetToRedeem =
            getShareFromAssetAmount(amountOfAssetToRedeem);

        /// @dev The preview for each basket asset is computed.
        for (
            uint256 i;
            i < indexOfAssetBasketAddressesLength;
            i = unchecked_inc(i)
        ) {
            address tmpTargetBasketAssetAddress = indexOfAssetBasketAddresses[i];
            string memory tmpTargetBasketAssetName =
                IERC20(tmpTargetBasketAssetAddress).name();
            uint256 assetRedeemableAmount = previewRedeemWithShareForAsset(
                shareOfAssetToRedeem, tmpTargetBasketAssetAddress
            );
            /// @dev If there is an exit-tax, we apply it on the final amount.
            /// Since we cap the exit-tax share value at 100% (1e18), it should never underflow.
            unchecked {
                uint256 assetRedeemableAmountAfterTax = assetRedeemableAmount
                    - assetRedeemableAmount.mulWadDown(exitTaxForCollectiveTreasury);
                basketBalance[i] = ERC20Balance(
                    tmpTargetBasketAssetAddress,
                    tmpTargetBasketAssetName,
                    assetRedeemableAmountAfterTax
                );
            }
        }
        /// @dev We return the `ERC20Balance` struct array.
        /// If the contract has no assets registered, the array will be empty by default.
        return basketBalance;
    }

    /// @dev Return the balance amount of each indexed assets inside the contract basket, set initially by the contract admin.
    /// @return ERC20Balance - Array of `ERC20Balance` struct containing the `name` and the basket balance for each indexed asset.
    /// WARNING! Since the `name()` entrypoint is optionnal in the EIP-20, we may encounter a revert during the call.
    /// We keep it as is for now since FS require it, but may disappear in a V2.
    function getBasketBalance() external view returns (ERC20Balance[] memory) {
        uint256 indexOfAssetBasketAddressesLength =
            indexOfAssetBasketAddresses.length;
        /// @dev We return an `ERC20Balance` struct for now.
        /// @TODO This is just in anticipation for FS needs. Can be removed or changed if considered useless.
        ERC20Balance[] memory basketBalance =
            new ERC20Balance[](indexOfAssetBasketAddressesLength);

        /// @dev We iterate for each asset registered inside the basket the owned balance by this contract.
        for (
            uint256 i;
            i < indexOfAssetBasketAddressesLength;
            i = unchecked_inc(i)
        ) {
            address tmpTargetBasketAssetAddress = indexOfAssetBasketAddresses[i];
            string memory tmpTargetBasketAssetName =
                IERC20(tmpTargetBasketAssetAddress).name();
            uint256 tmpTargetBasketAssetBalance =
                IERC20(tmpTargetBasketAssetAddress).balanceOf(address(this));

            basketBalance[i] = ERC20Balance(
                tmpTargetBasketAssetAddress,
                tmpTargetBasketAssetName,
                tmpTargetBasketAssetBalance
            );
        }
        /// @dev We return the `ERC20Balance` struct array.
        /// If the contract has no assets registered, the array will be empty by default.
        return basketBalance;
    }

    /// @dev Return the total amount of indexed assets inside the contract basket, set initially by the contract admin.
    /// @return uint256 - Amount of unique assets managed inside the basket.
    /// @notice Do not call `indexOfAssetBasketAddresses.length` with ethers, it won't work unless you call the storage slot directly.
    function totalAmountOfUniqueAssets() external view returns (uint256) {
        return indexOfAssetBasketAddresses.length;
    }

    /// @dev Return a preview of the redeemable amount for a specific basket asset based on a token share of indexed asset.
    /// @param shareOfAssetToRedeem - Share of the indexed asset. Computed based on a ratio with the indexed asset `totalSupply()`.
    /// @param addressOfAssetToWithdraw - Address of the ERC-20 basket asset contract.
    /// @return uint256 - Amount that can be redeemed for a specific asset.
    function previewRedeemWithShareForAsset(
        uint256 shareOfAssetToRedeem,
        address addressOfAssetToWithdraw
    ) public view returns (uint256) {
        uint256 balanceOfAssetToWithdraw =
            IERC20(addressOfAssetToWithdraw).balanceOf(address(this));
        return balanceOfAssetToWithdraw.mulWadDown(shareOfAssetToRedeem);
    }

    function getShareFromAssetAmount(uint256 assetAmount)
        internal
        view
        returns (uint256 shareAmount)
    {
        shareAmount =
            assetAmount.divWadDown(IERC721(indexedAssetAddress).totalSupply());
    }

    /// @dev Increment value through unchecked arithmetic for saving gas
    /// @param i Value to increment.
    /// @return uint256 Incremented value.
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return ++i;
        }
    }
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
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from, address indexed to, uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner, address indexed approved, uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)
// Forked from the OpenZeppelin repository and updated with additionnal interface entrypoints.

pragma solidity ^0.8.0;

import "../Interfaces/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token, abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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

        bytes memory returndata = address(token).functionCall(
            data, "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}