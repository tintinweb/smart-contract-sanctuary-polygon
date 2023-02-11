// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {KomonERC1155} from "KomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";
import {Modifiers} from "Modifiers.sol";
import {AddressUtils} from "AddressUtils.sol";

contract CreatorSpaceFacet is KomonERC1155, Modifiers {
    uint256 private constant LESS_THAN_TOKEN_NUMBER_ALLOWED = 2;

    function createSpaceToken(
        uint256[] calldata maxSupplies,
        uint256[] calldata prices,
        uint8[] calldata percentages,
        address creatorAccount
    ) external onlyKomonWeb {
        _createSpaceToken(maxSupplies, prices, percentages, creatorAccount);
    }

    function updateTokensPrice(
        uint256[] calldata tokenIds,
        uint256[] calldata prices
    ) external onlyKomonWeb {
        setTokensPrice(tokenIds, prices, true);
    }

    function updateTokensPercentage(
        uint256[] calldata tokenIds,
        uint8[] calldata percentages
    ) external onlyKomonWeb {
        setTokensPercentage(tokenIds, percentages, true);
    }

    function mintSpaceKey(uint256 id) external payable {
        require(
            balanceOf(msg.sender, id) + 1 < LESS_THAN_TOKEN_NUMBER_ALLOWED,
            "Can't have more than 1 token id type per wallet"
        );
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + 1) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        uint256 total = tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        distributeMintingCuts(id, total);
    }

    function mintSpaceKeyForAccount(uint256 id, address account)
        external
        payable
    {
        require(
            balanceOf(account, id) + 1 < LESS_THAN_TOKEN_NUMBER_ALLOWED,
            "Can't have more than 1 token id type per wallet"
        );
        uint256 tokenPrice = tokenPrice(id);
        require(
            (totalSupply(id) + 1) <= maxSupply(id),
            "Max amount of token reached."
        );
        require(tokenPrice > 0, "Token price must be more than 0.");

        uint256 total = tokenPrice * 1 wei;
        require(msg.value == total, "Amount sent is not correct.");

        distributeMintingCuts(id, total, account);
    }

    function upgradeKey(uint256 previousTokenId, uint256 nextTokenId)
        external
        payable
    {
        // Caller must own the previous token id
        require(
            balanceOf(msg.sender, previousTokenId) > 0,
            "Caller must be the owner of the token id to upgrade."
        );
        // There should be upgrade tokens available
        require(
            (totalSupply(nextTokenId) + 1) <= maxSupply(nextTokenId),
            "There are not tokens to mint available."
        );

        uint256 previousTokenPrice = tokenPrice(previousTokenId);
        uint256 nextTokenPrice = tokenPrice(nextTokenId);

        // Upgrade cost must be more than original token cost
        require(
            nextTokenPrice > previousTokenPrice,
            "Upgrade token cost must be more than the original token cost"
        );

        // Calculating difference between the two prices
        uint256 upgradeCost = nextTokenPrice - previousTokenPrice;

        // Ether amount sent must be equal to upgrade cost
        require(msg.value == upgradeCost, "Amount sent is not correct.");

        // Transfer previous token id to komon assets account
        address assetsToKomonAccount = KomonAccessControlBaseStorage
            .layout()
            ._assetsToKomonAccount;
        _safeTransfer(
            msg.sender,
            msg.sender,
            assetsToKomonAccount,
            previousTokenId,
            1,
            ""
        );

        distributeMintingCuts(nextTokenId, upgradeCost);
    }

    function upgradeKeyForAccount(
        uint256 previousTokenId,
        uint256 nextTokenId,
        address account
    ) external payable {
        // Caller must own the previous token id
        require(
            balanceOf(account, previousTokenId) > 0,
            "Account sent must be the owner of the token id to upgrade."
        );
        // There should be upgrade tokens available
        require(
            (totalSupply(nextTokenId) + 1) <= maxSupply(nextTokenId),
            "There are not tokens to mint available."
        );

        uint256 previousTokenPrice = tokenPrice(previousTokenId);
        uint256 nextTokenPrice = tokenPrice(nextTokenId);

        // Upgrade cost must be more than original token cost
        require(
            nextTokenPrice > previousTokenPrice,
            "Upgrade token cost must be more than the original token cost"
        );

        // Calculating difference between the two prices
        uint256 upgradeCost = nextTokenPrice - previousTokenPrice;

        // Ether amount sent must be equal to upgrade cost
        require(msg.value == upgradeCost, "Amount sent is not correct.");

        // Transfer previous token id to komon assets account
        address assetsToKomonAccount = KomonAccessControlBaseStorage
            .layout()
            ._assetsToKomonAccount;
        _safeTransfer(
            account,
            account,
            assetsToKomonAccount,
            previousTokenId,
            1,
            ""
        );

        distributeMintingCuts(nextTokenId, upgradeCost, account);
    }

    function mintInternalKey(uint256 amount) external onlyKomonWeb {
        require(amount > 0, "You have to mint at least 1 token.");
        _mintInternalKey(amount);
    }

    function removeLastSpaceToken() external onlyKomonWeb {
        _removeLastSpaceToken();
    }
}