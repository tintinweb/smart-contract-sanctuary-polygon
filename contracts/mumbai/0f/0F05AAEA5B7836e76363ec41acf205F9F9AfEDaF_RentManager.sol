// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// fTNFT interface declaration
interface IfTNFT is IERC721 {
    function fractionShares(uint256 tokenId) external view returns (uint256);

    function fullShare() external view returns (uint256);
}

/**
 * @title Rent Manager
 * @author Daniel Kuppitz
 * @dev This contract is a system for managing the deposit, vesting, and claiming of rent for NFTs.
 *
 * This contract allows users to deposit rent for specific NFTs, check how much rent is claimable for a token, claim the
 * rent for a token, and handle the fractionalization and defractionalization of NFTs.
 *
 * The system supports both regular NFTs (TNFTs) and fractionalized NFTs (fTNFTs). In the case of fTNFTs, the rent is
 * split among the fraction tokens based on their shares.
 *
 * The contract uses a time-based linear vesting system. A user can deposit rent for a token for a specified period of
 * time. The rent then vests linearly over that period, and the owner of the token can claim the vested rent at any time.
 *
 * The contract keeps track of the deposited, claimed, and unclaimed amounts for each token.
 * When an NFT is fractionalized, the contract splits these amounts among the fraction tokens based on their shares.
 * When an NFT is defractionalized, the contract aggregates these amounts from the fraction tokens.
 *
 * The contract also provides a function to calculate the claimable rent for a token or a fraction token.
 *
 * To ensure that only valid fTNFTs can interact with the contract, the contract includes a whitelisting system.
 * A fractional TNFT contract must be whitelisted and associated with a TNFT token id before it can interact with the
 * contract.
 *
 * The contract emits events for rent deposits, fractionalizations, and defractionalizations.
 *
 * @custom:tester Milica Mihailovic
 */
contract RentManager is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using Math for uint256;
    using SafeERC20 for IERC20;

    struct FractionalRentInfo {
        uint256 depositAmount;
        uint256 claimedAmount;
        uint256 unclaimedAmount;
    }

    struct RentInfo {
        uint256 depositAmount;
        uint256 claimedAmount;
        uint256 unclaimedAmount;
        uint256 depositTime;
        uint256 endTime;
        address rentToken;
    }

    address public immutable TNFT_ADDRESS;
    address public depositor;
    address public factory;

    // Mapping: tokenId => RentInfo
    mapping(uint256 => RentInfo) public rentInfo;

    // Mapping: fTNFT token address => tokenId => fractional RentInfo
    mapping(address => mapping(uint256 => FractionalRentInfo))
        private fractionalRentInfo;

    // Mapping: fTNFT token address => whitelisted
    mapping(address => bool) private whitelistedNFTs;

    // Mapping: TNFT token id => fTNFT address
    mapping(uint256 => address) private fractionalNFTs;

    // Mapping: fTNFT address => TNFT token id
    mapping(address => uint256) private tnftTokenIds;

    // Mapping: TNFT tokenId => fTNFT tokenId set
    mapping(uint256 => EnumerableSet.UintSet) private fractionalTokenIds;

    /**
     * @dev Emitted when rent is deposited for a token.
     *
     * @param depositor The address of the user who deposited the rent.
     * @param tokenId The ID of the token for which rent was deposited.
     * @param rentToken The address of the token used to pay the rent.
     * @param amount The amount of rent deposited.
     */
    event RentDeposited(
        address depositor,
        uint256 indexed tokenId,
        address rentToken,
        uint256 amount
    );

    /**
     * @dev Emitted when rent is claimed for a token.
     *
     * @param claimer The address of the user who claimed the rent.
     * @param nft The address of the NFT contract.
     * @param tokenId The ID of the token for which rent was claimed.
     * @param rentToken The address of the token used to pay the rent.
     * @param amount The amount of rent claimed.
     */
    event RentClaimed(
        address indexed claimer,
        address indexed nft,
        uint256 indexed tokenId,
        address rentToken,
        uint256 amount
    );

    /**
     * @dev Emitted when an NFT is fractionalized.
     *
     * @param originalNFT The address of the original NFT.
     * @param originalTokenId The ID of the original NFT.
     * @param fractionNFT The address of the fractional NFT.
     * @param fractionTokenIds The IDs of the fractional tokens.
     */
    event Fractionalized(
        address indexed originalNFT,
        uint256 originalTokenId,
        address fractionNFT,
        uint256[] fractionTokenIds
    );

    /**
     * @dev Emitted when a fractionalized NFT is defractionalized.
     *
     * @param originalNFT The address of the original NFT.
     * @param originalTokenIds The IDs of the original NFTs.
     * @param defractionalizedNFT The address of the defractionalized NFT.
     * @param defractionalizedTokenId The ID of the defractionalized NFT.
     */
    event Defractionalized(
        address indexed originalNFT,
        uint256[] originalTokenIds,
        address defractionalizedNFT,
        uint256 defractionalizedTokenId
    );

    /**
     * @dev Emitted when a fractional TNFT is whitelisted.
     *
     * @param fractionalNFT The address of the fractional TNFT.
     * @param tnftTokenId The ID of the TNFT token.
     */
    event WhitelistedFractionalTNFT(
        address indexed fractionalNFT,
        uint256 tnftTokenId
    );

    /**
     * @dev Constructor that initializes the TNFT contract address.
     * @param _tnftAddress The address of the TNFT contract.
     */
    constructor(address _tnftAddress) {
        require(_tnftAddress != address(0), "TNFT address cannot be 0");
        TNFT_ADDRESS = _tnftAddress;
    }

    /**
     * @dev Function to update the address of the rent depositor.
     * Only callable by the owner of the contract.
     * @param _newDepositor The address of the new rent depositor.
     */
    function updateDepositor(address _newDepositor) external onlyOwner {
        require(_newDepositor != address(0), "Depositor address cannot be 0");
        depositor = _newDepositor;
    }

    /**
     * @dev Function to update the address of the factory contract.
     * Only callable by the owner of the contract.
     * @param _newFactory The address of the new factory contract.
     */
    function updateFactory(address _newFactory) external onlyOwner {
        require(_newFactory != address(0), "Factory address cannot be 0");
        factory = _newFactory;
    }

    /**
     * @dev Allows the rent depositor to deposit rent for a specific token.
     *
     * This function requires the caller to be the current rent depositor.
     * It also checks whether the specified end time is in the future.
     * If the token's current rent token is either the zero address or the same as the provided token address,
     * the function allows the deposit.
     *
     * The function first transfers the specified amount of the rent token from the depositor to the contract.
     * If the token's rent token is the zero address, it sets the rent token to the provided token address.
     *
     * The function then calculates the token's vested amount.
     *
     * If the token is fractionalized, the function propagates the deposit to all fraction tokens of the token.
     *
     * The function then calculates the token's unvested amount, updates the token's unclaimed amount,
     * resets the token's claimed amount, adds the deposit amount to the token's unvested amount,
     * updates the deposit time, and sets the end time.
     *
     * Finally, the function emits a `RentDeposited` event.
     *
     * @param tokenId The ID of the token for which to deposit rent.
     * @param tokenAddress The address of the rent token to deposit.
     * @param amount The amount of the rent token to deposit.
     * @param endTime The end time of the rent deposit.
     */
    function deposit(
        uint256 tokenId,
        address tokenAddress,
        uint256 amount,
        uint256 endTime
    ) external {
        require(
            msg.sender == depositor,
            "Only the rent depositor can call this function"
        );
        require(endTime > block.timestamp, "End time must be in the future");
        RentInfo storage rent = rentInfo[tokenId];
        require(
            rent.rentToken == address(0) || rent.rentToken == tokenAddress,
            "Invalid rent token"
        );

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (rent.rentToken == address(0)) {
            rent.rentToken = tokenAddress;
        }

        uint256 vestedAmount = _vestedAmount(rent);

        if (_isFractionalized(tokenId)) {
            address fractionalNFT = fractionalNFTs[tokenId];
            IfTNFT fractionNFT = IfTNFT(fractionalNFT);
            _propagateDeposit(
                fractionalNFT,
                fractionalTokenIds[tokenId].values(),
                fractionNFT.fullShare(),
                vestedAmount,
                amount
            );
        }

        uint256 unvestedAmount = rent.depositAmount - vestedAmount;
        rent.unclaimedAmount = vestedAmount - rent.claimedAmount;
        rent.claimedAmount = 0;
        rent.depositAmount = unvestedAmount + amount;
        rent.depositTime = block.timestamp;
        rent.endTime = endTime;

        emit RentDeposited(msg.sender, tokenId, tokenAddress, amount);
    }

    /**
     * @dev Returns the amount of rent that can be claimed for a given token.
     *
     * If the NFT is a TNFT, the function calculates the claimable rent based on the rent info of the token.
     * If the NFT is a fractionalized NFT, the function calculates the claimable rent based on the fraction share of the
     * token.
     *
     * @param nft The address of the NFT contract.
     * @param tokenId The ID of the token.
     * @return The amount of claimable rent for the token.
     */
    function claimableRentForToken(address nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (nft == TNFT_ADDRESS) {
            RentInfo storage rent = rentInfo[tokenId];
            return
                rent.unclaimedAmount + _vestedAmount(rent) - rent.claimedAmount;
        } else {
            require(whitelistedNFTs[nft], "Invalid fTNFT");
            IfTNFT fractionalNFT = IfTNFT(nft);
            uint256 tnftTokenId = tnftTokenIds[nft];
            RentInfo storage rent = rentInfo[tnftTokenId];
            return
                _claimableRentForFraction(
                    nft,
                    tokenId,
                    _vestedAmount(rent),
                    fractionalNFT.fractionShares(tokenId),
                    fractionalNFT.fullShare()
                );
        }
    }

    /**
     * @dev Allows the owner of a token to claim their rent.
     *
     * The function first checks that the caller is the owner of the token.
     * It then retrieves the amount of claimable rent for the token and requires that the amount is greater than zero,
     * and that the token is either not a TNFT or is a non-fractionalized TNFT.
     *
     * If the NFT is a fTNFT, the function also updates the claimed and unclaimed amounts of the fractional rent info of
     * the token.
     *
     * In both cases, the function updates the claimed and unclaimed amounts of the rent info of the corresponding TNFT
     * token.
     *
     * The function then transfers the claimable rent to the caller and emits a `RentClaimed` event.
     *
     * @param nft The address of the NFT contract.
     * @param tokenId The ID of the token.
     */
    function claimRentForToken(address nft, uint256 tokenId) external {
        IERC721 nftContract = IERC721(nft);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Caller is not the owner of the token"
        );

        uint256 claimableRent = claimableRentForToken(nft, tokenId);
        require(
            claimableRent > 0 &&
                (nft != TNFT_ADDRESS || !_isFractionalized(tokenId)),
            "No rent to claim"
        );

        RentInfo storage rent;

        if (nft != TNFT_ADDRESS) {
            uint256 tnftTokenId = tnftTokenIds[nft];
            rent = rentInfo[tnftTokenId];
            FractionalRentInfo storage fractionalRent = fractionalRentInfo[nft][
                tokenId
            ];
            fractionalRent.claimedAmount +=
                claimableRent -
                fractionalRent.unclaimedAmount;
            fractionalRent.unclaimedAmount = 0;
        } else {
            rent = rentInfo[tokenId];
        }

        if (rent.unclaimedAmount > 0) {
            if (rent.unclaimedAmount < claimableRent) {
                unchecked {
                    rent.claimedAmount += claimableRent - rent.unclaimedAmount;
                    rent.unclaimedAmount = 0;
                }
            } else {
                unchecked {
                    rent.unclaimedAmount -= claimableRent;
                }
            }
        } else {
            rent.claimedAmount += claimableRent;
        }
        IERC20(rent.rentToken).safeTransfer(msg.sender, claimableRent);

        emit RentClaimed(
            msg.sender,
            nft,
            tokenId,
            rent.rentToken,
            claimableRent
        );
    }

    /**
     * @dev Handles the fractionalization of an NFT.
     *
     * This function is intended to be called by a fractionalized NFT (fTNFT) contract when an NFT is fractionalized.
     * It requires the caller to be a whitelisted fractionalized NTF contract.
     *
     * The function first checks if the original NFT is not a TNFT. If so, it retrieves the fractional rent info of the
     * original token and the ID of the TNFT token that corresponds to the fractionalized NFT. It also removes the
     * original token ID from the list of fractional token IDs of the TNFT token.
     * If the original NFT is a TNFT, the function retrieves the rent info of the original token and sets the ID of the
     * TNFT token to be the original token ID. It also sets the fractionalized NFT of the original token to be the
     * fractionalized NFT.
     *
     * The function then adds each fraction token ID to the list of fractional token IDs of the TNFT token.
     *
     * It then calls the `_splitRentInfo` function to split the deposited, claimed, and unclaimed amounts among the
     * fraction tokens based on their shares.
     *
     * Finally, the function emits a `Fractionalized` event.
     *
     * @param originalNFT The address of the original NFT contract.
     * @param originalTokenId The ID of the original token.
     * @param originalShare The total number of shares before the fractionalization.
     * @param fractionNFT The address of the fractionalized NFT contract.
     * @param fractionTokenIds An array of the token IDs representing the fraction tokens of the fractionalized NFT.
     */
    function onFractionalize(
        address originalNFT,
        uint256 originalTokenId,
        uint256 originalShare,
        address fractionNFT,
        uint256[] calldata fractionTokenIds
    ) external {
        require(
            whitelistedNFTs[msg.sender],
            "Only whitelisted fTNTFs can call this function"
        );

        uint256 totalDeposited;
        uint256 totalClaimed;
        uint256 totalUnclaimed;
        uint256 tnftTokenId;

        if (originalNFT != TNFT_ADDRESS) {
            FractionalRentInfo storage fractionalRent = fractionalRentInfo[
                originalNFT
            ][originalTokenId];
            totalDeposited = fractionalRent.depositAmount;
            totalClaimed = fractionalRent.claimedAmount;
            totalUnclaimed = fractionalRent.unclaimedAmount;
            tnftTokenId = tnftTokenIds[fractionNFT];
            fractionalTokenIds[tnftTokenId].remove(originalTokenId);
        } else {
            RentInfo storage rent = rentInfo[originalTokenId];
            totalDeposited = rent.depositAmount;
            totalClaimed = rent.claimedAmount;
            totalUnclaimed = rent.unclaimedAmount;
            tnftTokenId = originalTokenId;
            fractionalNFTs[originalTokenId] = fractionNFT;
        }

        for (uint256 i = 0; i < fractionTokenIds.length; i++) {
            fractionalTokenIds[tnftTokenId].add(fractionTokenIds[i]);
        }

        _splitRentInfo(
            IfTNFT(fractionNFT),
            fractionTokenIds,
            originalShare,
            totalDeposited,
            totalClaimed,
            totalUnclaimed
        );

        emit Fractionalized(
            originalNFT,
            originalTokenId,
            fractionNFT,
            fractionTokenIds
        );
    }

    /**
     * @dev Handles the defractionalization of an NFT.
     *
     * This function is intended to be called by a fractionalized NFT (fTNFT) contract when an NFT is defractionalized.
     * It requires the caller to be a whitelisted fTNFT contract.
     *
     * The function first determines the ID of the TNFT token that corresponds to the defractionalized NFT. It then
     * loops over the original token IDs of the fractionalized NFT and aggregates their deposited, claimed, and
     * unclaimed amounts. It also deletes the fractional rent info of each original token and removes its ID from the
     * list of fractional token IDs of the TNFT token.
     *
     * If the defractionalized NFT is not a TNFT, the function updates the fractional rent info of the defractionalized
     * token with the total deposited, claimed, and unclaimed amounts and adds its ID to the list of fractional token
     * IDs of the TNFT token.
     *
     * Finally, the function emits a `Defractionalized` event.
     *
     * @param originalNFT The address of the original NFT contract.
     * @param originalTokenIds An array of the original token IDs of the fractionalized NFT.
     * @param defractionalizedNFT The address of the defractionalized NFT contract.
     * @param defractionalizedTokenId The ID of the defractionalized token.
     */
    function onDefractionalize(
        address originalNFT,
        uint256[] calldata originalTokenIds,
        address defractionalizedNFT,
        uint256 defractionalizedTokenId
    ) external {
        require(
            whitelistedNFTs[msg.sender],
            "Only whitelisted fTNTFs can call this function"
        );

        uint256 totalDeposited = 0;
        uint256 totalClaimed = 0;
        uint256 totalUnclaimed = 0;
        uint256 tnftTokenId = (defractionalizedNFT != TNFT_ADDRESS)
            ? tnftTokenIds[defractionalizedNFT]
            : defractionalizedTokenId;

        for (uint256 i = 0; i < originalTokenIds.length; i++) {
            uint256 originalTokenId = originalTokenIds[i];
            FractionalRentInfo storage fractionalRent = fractionalRentInfo[
                originalNFT
            ][originalTokenId];
            totalDeposited += fractionalRent.depositAmount;
            totalClaimed += fractionalRent.claimedAmount;
            totalUnclaimed += fractionalRent.unclaimedAmount;
            delete fractionalRentInfo[originalNFT][originalTokenId];
            fractionalTokenIds[tnftTokenId].remove(originalTokenId);
        }

        if (defractionalizedNFT != TNFT_ADDRESS) {
            FractionalRentInfo storage fractionalRent = fractionalRentInfo[
                defractionalizedNFT
            ][defractionalizedTokenId];
            fractionalRent.depositAmount = totalDeposited;
            fractionalRent.claimedAmount = totalClaimed;
            fractionalRent.unclaimedAmount = totalUnclaimed;
            fractionalTokenIds[tnftTokenId].add(defractionalizedTokenId);
        }

        emit Defractionalized(
            originalNFT,
            originalTokenIds,
            defractionalizedNFT,
            defractionalizedTokenId
        );
    }

    /**
     * @dev Whitelists a new fractional TNFT contract and associates it with a TNFT token id.
     *
     * This function can only be called by the Tangible factory contract and should be invoked on the initial
     * fractionalization of a TNFT. This is to ensure that only valid fTNFTs created by the factory contract can
     * interact with this contract. The association of a TNFT token ID with the fractional NFT address helps in keeping
     * track of the origin of the fractional NFTs.
     *
     * @param fractionalNFT The address of the fractional TNFT contract to be whitelisted.
     * @param tnftTokenId The TNFT token id associated with the fractional TNFT.
     */
    function whitelistFractionalTNFT(address fractionalNFT, uint256 tnftTokenId)
        external
    {
        require(
            msg.sender == factory,
            "Only the factory contract can call this function"
        );
        whitelistedNFTs[fractionalNFT] = true;
        tnftTokenIds[fractionalNFT] = tnftTokenId;

        emit WhitelistedFractionalTNFT(fractionalNFT, tnftTokenId);
    }

    /**
     * @dev Calculates the amount of rent that can be claimed for a fraction token.
     *
     * The function first calculates the vested amount for the fraction share of the token. It then retrieves the
     * fractional rent info of the token and calculates the claimable rent based on the vested amount and the claimed
     * amount.
     *
     * @param fractionalNFT The address of the fractionalized NFT contract.
     * @param fractionalTokenId The ID of the fraction token.
     * @param totalVested The total vested amount for the original token.
     * @param share The share of the fraction token.
     * @param fullShare The total number of shares of the fractionalized NFT.
     * @return The amount of claimable rent for the fraction token.
     */
    function _claimableRentForFraction(
        address fractionalNFT,
        uint256 fractionalTokenId,
        uint256 totalVested,
        uint256 share,
        uint256 fullShare
    ) private view returns (uint256) {
        uint256 vested = totalVested.mulDiv(share, fullShare);
        FractionalRentInfo storage fractionalRent = fractionalRentInfo[
            fractionalNFT
        ][fractionalTokenId];
        return
            fractionalRent.unclaimedAmount +
            vested -
            fractionalRent.claimedAmount;
    }

    /**
     * @dev Checks whether a TNFT is fractionalized.
     *
     * This internal function takes a token ID and checks whether it's associated with a fractional NFT and has fraction
     * tokens. If both conditions are met, the function returns true, indicating that the token is fractionalized.
     *
     * @param tokenId The ID of the TNFT to be checked.
     *
     * @return A boolean indicating whether the TNFT is fractionalized.
     */
    function _isFractionalized(uint256 tokenId) private view returns (bool) {
        address fractionalNFT = fractionalNFTs[tokenId];
        if (fractionalNFT != address(0)) {
            return fractionalTokenIds[tokenId].length() > 0;
        }
        return false;
    }

    /**
     * @dev Propagates a deposit across all fractional NFTs, updating their rent info.
     *
     * This internal function takes the address of a fractional NFT, an array of fraction token IDs, a full share
     * amount, a vested amount, and a deposit amount. It then updates the deposit, claimed, and unclaimed amounts for
     * each fraction token based on its proportionate share of the full share.
     *
     * The function uses fixed-point math to ensure precision, rounding down for deposit and vested amounts. The updated
     * values are stored in the `fractionalRentInfo` mapping for later retrieval.
     *
     * @param fractionalNFT The address of the fractional NFT whose rent info is to be updated.
     * @param fractionTokenIds An array of token IDs representing the fraction tokens of the fractional NFT.
     * @param fullShare The total number of shares.
     * @param vestedAmount The amount of rent that has vested before the deposit was made.
     * @param depositAmount The amount of rent being deposited.
     */
    function _propagateDeposit(
        address fractionalNFT,
        uint256[] memory fractionTokenIds,
        uint256 fullShare,
        uint256 vestedAmount,
        uint256 depositAmount
    ) private {
        IfTNFT fractionNFT = IfTNFT(fractionalNFT);
        for (uint256 i = 0; i < fractionTokenIds.length; i++) {
            uint256 fractionTokenId = fractionTokenIds[i];
            uint256 share = fractionNFT.fractionShares(fractionTokenId);
            uint256 fractionalDepositAmount = depositAmount.mulDiv(
                share,
                fullShare
            );
            uint256 fractionalVestedAmount = vestedAmount.mulDiv(
                share,
                fullShare
            );
            FractionalRentInfo storage fractionalRent = fractionalRentInfo[
                fractionalNFT
            ][fractionTokenId];
            uint256 fractionalUnvestedAmount = fractionalRent.depositAmount -
                fractionalVestedAmount;
            fractionalRent.unclaimedAmount =
                fractionalRent.unclaimedAmount +
                fractionalVestedAmount -
                fractionalRent.claimedAmount;
            fractionalRent.claimedAmount = 0;
            fractionalRent.depositAmount =
                fractionalUnvestedAmount +
                fractionalDepositAmount;
        }
    }

    /**
     * @dev Splits rent information among fractional NFTs based on their shares.
     *
     * This internal function takes a fractional NFT and an array of fraction token IDs, along with the original share,
     * total deposited, total claimed, and total unclaimed amounts. It then calculates the deposit, claimed, and
     * unclaimed amounts for each fraction token, based on its proportionate share of the original share.
     *
     * The function uses fixed-point math to ensure precision, rounding up for claimed amounts and rounding down for
     * deposited and unclaimed amounts. The results are stored in the `fractionalRentInfo` mapping for later retrieval.
     *
     * @param fractionalNFT The fractional NFT whose rent information is to be split.
     * @param fractionTokenIds An array of token IDs representing the fraction tokens of the fractional NFT.
     * @param originalShare The total number of shares before the deposit was made.
     * @param totalDeposited The total amount deposited before the split.
     * @param totalClaimed The total amount claimed before the split.
     * @param totalUnclaimed The total amount unclaimed before the split.
     */
    function _splitRentInfo(
        IfTNFT fractionalNFT,
        uint256[] memory fractionTokenIds,
        uint256 originalShare,
        uint256 totalDeposited,
        uint256 totalClaimed,
        uint256 totalUnclaimed
    ) private {
        for (uint256 i = 0; i < fractionTokenIds.length; i++) {
            uint256 fractionTokenId = fractionTokenIds[i];
            uint256 share = fractionalNFT.fractionShares(fractionTokenId);
            uint256 depositedForFraction = totalDeposited.mulDiv(
                share,
                originalShare
            );
            fractionalRentInfo[address(fractionalNFT)][
                fractionTokenId
            ] = FractionalRentInfo({
                depositAmount: depositedForFraction,
                claimedAmount: totalClaimed.mulDiv(
                    share,
                    originalShare,
                    Math.Rounding.Up
                ),
                unclaimedAmount: totalUnclaimed.mulDiv(share, originalShare)
            });
        }
    }

    /**
     * @dev Calculates the vested amount for a rent deposit.
     *
     * If the current time is past the end time of the rent period, the function returns the deposit amount.
     * If the current time is before the end time of the rent period, the function calculates the vested amount based on
     * the elapsed time and the vesting duration.
     *
     * @param rent The storage pointer to the rent info of a token.
     * @return The vested amount for the rent deposit.
     */
    function _vestedAmount(RentInfo storage rent)
        private
        view
        returns (uint256)
    {
        if (block.timestamp >= rent.endTime) {
            return rent.depositAmount;
        } else {
            uint256 elapsedTime = block.timestamp - rent.depositTime;
            uint256 vestingDuration = rent.endTime - rent.depositTime;
            return rent.depositAmount.mulDiv(elapsedTime, vestingDuration);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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