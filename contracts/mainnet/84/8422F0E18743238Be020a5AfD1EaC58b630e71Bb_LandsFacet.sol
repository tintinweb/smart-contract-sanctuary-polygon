// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {ERC721WithDiamondStorage} from "ERC721WithDiamondStorage.sol";

import {IERC20} from "IERC20.sol";

import {LibDiamond} from "LibDiamond.sol";

contract LandsFacet is ERC721WithDiamondStorage {
    event LandMinted(uint8 indexed landType, uint256 tokenId, address owner);

    function paymentToken() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.WethTokenAddress;
    }

    function firstSaleLandPrices() external view returns (uint256[10] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256[10] memory prices;
        for (uint256 i = 0; i < 10; i++) {
            prices[i] = ds.firstSaleLandPrices[uint8(i + 1)];
        }
        return prices;
    }

    function firstSaleIsActive() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.firstSaleIsActive;
    }

    function firstSaleIsPublic() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.firstSaleIsPublic;
    }

    function setPaymentToken(address tokenAddress) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.WethTokenAddress = tokenAddress;
    }

    function setFirstSaleLandPrices() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        //Mythic
        ds.firstSaleLandPrices[1] = 0.1 * 10**18;

        //Rare
        ds.firstSaleLandPrices[2] = 0.05 * 10**18;
        ds.firstSaleLandPrices[3] = 0.05 * 10**18;
        ds.firstSaleLandPrices[4] = 0.05 * 10**18;

        //Common
        ds.firstSaleLandPrices[5] = 0.025 * 10**18;
        ds.firstSaleLandPrices[6] = 0.025 * 10**18;
        ds.firstSaleLandPrices[7] = 0.025 * 10**18;
        ds.firstSaleLandPrices[8] = 0.025 * 10**18;
        ds.firstSaleLandPrices[9] = 0.025 * 10**18;
        ds.firstSaleLandPrices[10] = 0.025 * 10**18;
    }

    function setFirstSaleStartIndexByLandType() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint8 i = 1; i <= 10; i++) {
            ds.firstSaleStartIndexByLandType[i] = (uint256(i) - 1) * 1000 + 1;
        }
    }

    function setFirstSaleIsActive(bool isActive) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.firstSaleIsActive = isActive;
    }

    function setFirstSaleIsPublic(bool isPublic) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.firstSaleIsPublic = isPublic;
    }

    function _mintNextFirstSaleToken(address _to, uint8 landType)
        internal
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(ds.firstSaleIsActive, "LandsFacet: first sale is not active");

        uint256 currMinted = ds.numMintedTokensByLandType[landType];

        require(
            ds.numMintedTokensByLandType[landType] <
                LibDiamond.FIRST_SALE_NUM_TOKENS_PER_TYPE,
            "LandsFacet: No more tokens to mint for the given land type"
        );

        require(
            ds.firstSaleStartIndexByLandType[landType] > 0,
            "LandsFacet: setFirstSaleStartIndexByLandType has not been called"
        );

        uint256 nextTokenId = ds.firstSaleStartIndexByLandType[landType] +
            currMinted;

        //Update land type state
        ds.landTypeByTokenId[nextTokenId] = landType;
        ds.numMintedTokensByLandType[landType]++;

        super._mint(_to, nextTokenId);

        emit LandMinted(landType, nextTokenId, _to);
        return nextTokenId;
    }

    function getLandTypeByTokenId(uint256 tokenId)
        external
        view
        returns (uint8)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.landTypeByTokenId[tokenId];
    }

    function getPaymentToken() internal view returns (IERC20) {
        return IERC20(LibDiamond.diamondStorage().WethTokenAddress);
    }

    function withdrawWeth(address _receiver, uint256 _amount) public {
        LibDiamond.enforceIsContractOwner();
        require(
            msg.sender == _receiver,
            "ERC721Facet: This contract currently only supports its owner withdrawing to self"
        );
        getPaymentToken().transfer(_receiver, _amount);
    }

    function mintFirstSaleToken(address _to, uint8 landType) public {
        LibDiamond.enforceIsContractOwner();
        _mintNextFirstSaleToken(_to, landType);
    }

    function _setMintAllowances(address _address, uint8[3] calldata allowances)
        internal
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        for (uint8 i = 1; i <= 3; i++) {
            ds.firstSaleMintAllowance[_address][i] = allowances[i - 1];
        }
    }

    function setMintAllowances(address _address, uint8[3] calldata allowances)
        external
    {
        LibDiamond.enforceIsContractOwner();
        _setMintAllowances(_address, allowances);
    }

    function batchSetMintAllowances(
        address[] memory addresses,
        uint8[3] calldata allowances
    ) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i = 0; i < addresses.length; i++) {
            _setMintAllowances(addresses[i], allowances);
        }
    }

    function getMintAllowance(address _address)
        public
        view
        returns (uint256[] memory)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256[] memory result = new uint256[](3);
        for (uint8 i = 1; i <= 3; i++) {
            result[i - 1] = ds.firstSaleMintAllowance[_address][i];
        }
        return result;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public {
        LibDiamond.enforceIsOwnerOrGameServer();
        super._setTokenURI(tokenId, tokenURI);
    }

    function batchSetTokenURI(
        uint256[] calldata tokenIds,
        string[] calldata tokenURIs
    ) external {
        LibDiamond.enforceIsOwnerOrGameServer();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], tokenURIs[i]);
        }
    }

    function changeContractURI(string memory _contractURI) public {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractURI(_contractURI);
    }

    function changeLicenseURI(string memory _licenseURI) public {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setLicenseURI(_licenseURI);
    }

    function claimFirstSaleTokens(
        address _to,
        uint8[10] calldata numTokensByLandType
    ) external virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        IERC20 wethToken = getPaymentToken();

        uint256 requiredPaymentAmount = 0;

        for (uint8 i = 1; i <= 10; i++) {
            uint8 numTokens = numTokensByLandType[i - 1];
            uint8 landRarity = LibDiamond.getLandRarityForLandType(i);
            require(
                landRarity > 0,
                "LandsFacet: claimFirstSaleTokens -- invalid landRarity"
            );
            require(
                numTokens <= ds.firstSaleMintAllowance[_to][landRarity],
                "LandsFacet: Insufficient allowance in mint whitelist for _to address"
            );
            require(
                numTokens <= ds.firstSaleMintAllowance[_to][3],
                "LandsFacet: Insufficient total allowance in mint whitelist for _to address"
            );
            ds.firstSaleMintAllowance[_to][landRarity] -= numTokens;
            if (landRarity < 3) {
                ds.firstSaleMintAllowance[_to][3] -= numTokens;
            }

            if (numTokens == 0) {
                // caller doesn't want this land type
                continue;
            }
            // Transaction sender will pay for the transfer, othervice anyone can submit
            // a transaction where _to is your address and force you pay, if you had allowed
            // to transfer your weth
            requiredPaymentAmount +=
                ds.firstSaleLandPrices[i] *
                uint256(numTokens);
        }

        require(
            requiredPaymentAmount > 0,
            "LandsFacet: setFirstSaleLandPrices has not been called"
        );

        require(
            wethToken.allowance(msg.sender, address(this)) >=
                requiredPaymentAmount,
            "ERC721Facet: Insufficient allowance to transfer Weth"
        );

        wethToken.transferFrom(
            msg.sender,
            address(this),
            requiredPaymentAmount
        );

        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= numTokensByLandType[i - 1]; j++) {
                _mintNextFirstSaleToken(_to, i);
            }
        }
    }

    function claimPublicFirstSaleTokens(
        address _to,
        uint8[10] calldata numTokensByLandType
    ) external virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(
            ds.firstSaleIsPublic,
            "LandsFacet: claimPublicFirstSaleTokens -- first sale is not yet open to the public"
        );

        IERC20 wethToken = getPaymentToken();

        uint256 requiredPaymentAmount = 0;

        //Land types are indexed from 1
        uint8[4] memory publicSaleMintAllowance = [0, 1, 2, 4];

        for (uint8 i = 1; i <= 10; i++) {
            uint8 numTokens = numTokensByLandType[i - 1];
            if (numTokens == 0) {
                // caller doesn't want this land type
                continue;
            }
            uint8 landRarity = LibDiamond.getLandRarityForLandType(i);
            require(
                landRarity > 0,
                "LandsFacet: claimFirstSaleTokens -- invalid landRarity"
            );
            require(
                numTokens <= publicSaleMintAllowance[landRarity],
                "LandsFacet: claimPublicFirstSaleTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            require(
                numTokens <= publicSaleMintAllowance[3],
                "LandsFacet: claimPublicFirstSaleTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            publicSaleMintAllowance[landRarity] -= numTokens;
            if (landRarity < 3) {
                publicSaleMintAllowance[3] -= numTokens;
            }
            // Transaction sender will pay for the transfer, othervice anyone can submit
            // a transaction where _to is your address and force you pay, if you had allowed
            // to transfer your weth
            requiredPaymentAmount +=
                ds.firstSaleLandPrices[i] *
                uint256(numTokens);
        }

        require(
            requiredPaymentAmount > 0,
            "LandsFacet: setFirstSaleLandPrices has not been called"
        );

        require(
            wethToken.allowance(msg.sender, address(this)) >=
                requiredPaymentAmount,
            "ERC721Facet: Insufficient allowance to transfer Weth"
        );

        wethToken.transferFrom(
            msg.sender,
            address(this),
            requiredPaymentAmount
        );

        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= numTokensByLandType[i - 1]; j++) {
                _mintNextFirstSaleToken(_to, i);
            }
        }
    }

    /**
    This function returns number of all of minted lands by land type (including all sales)
     */
    function getNumMintedTokensByLandType()
        external
        view
        returns (
            uint256 mythic,
            uint256 rareLight,
            uint256 rareWonder,
            uint256 rareMystery,
            uint256 commonHeart,
            uint256 commonCloud,
            uint256 commonFlower,
            uint256 commonCandy,
            uint256 commonCrystal,
            uint256 commonMoon
        )
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        mythic = ds.numMintedTokensByLandType[1];
        rareLight = ds.numMintedTokensByLandType[2];
        rareWonder = ds.numMintedTokensByLandType[3];
        rareMystery = ds.numMintedTokensByLandType[4];
        commonHeart = ds.numMintedTokensByLandType[5];
        commonCloud = ds.numMintedTokensByLandType[6];
        commonFlower = ds.numMintedTokensByLandType[7];
        commonCandy = ds.numMintedTokensByLandType[8];
        commonCrystal = ds.numMintedTokensByLandType[9];
        commonMoon = ds.numMintedTokensByLandType[10];
    }

    /**
    This is for second sale only
     **/
    function getNumMintedSecondSaleTokensByLandType()
        external
        view
        returns (
            uint256 mythic,
            uint256 rareLight,
            uint256 rareWonder,
            uint256 rareMystery,
            uint256 commonHeart,
            uint256 commonCloud,
            uint256 commonFlower,
            uint256 commonCandy,
            uint256 commonCrystal,
            uint256 commonMoon
        )
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        mythic = ds.numMintedSecondSaleTokensByLandType[1];
        rareLight = ds.numMintedSecondSaleTokensByLandType[2];
        rareWonder = ds.numMintedSecondSaleTokensByLandType[3];
        rareMystery = ds.numMintedSecondSaleTokensByLandType[4];
        commonHeart = ds.numMintedSecondSaleTokensByLandType[5];
        commonCloud = ds.numMintedSecondSaleTokensByLandType[6];
        commonFlower = ds.numMintedSecondSaleTokensByLandType[7];
        commonCandy = ds.numMintedSecondSaleTokensByLandType[8];
        commonCrystal = ds.numMintedSecondSaleTokensByLandType[9];
        commonMoon = ds.numMintedSecondSaleTokensByLandType[10];
    }

    function _setSecondSaleMintAllowances(
        address _address,
        uint8 _totalAllowance
    ) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.secondSaleMintAllowance[_address][1] = ds.firstSaleMintAllowance[
            _address
        ][1];
        ds.secondSaleMintAllowance[_address][2] = ds.firstSaleMintAllowance[
            _address
        ][2];
        ds.secondSaleMintAllowance[_address][3] = _totalAllowance;
    }

    function setSecondSaleLandPrices() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        //Mythic
        ds.secondSaleLandPrices[1] = 0.1 * 10**18;

        //Rare
        ds.secondSaleLandPrices[2] = 0.05 * 10**18;
        ds.secondSaleLandPrices[3] = 0.05 * 10**18;
        ds.secondSaleLandPrices[4] = 0.05 * 10**18;

        //Common
        ds.secondSaleLandPrices[5] = 0.025 * 10**18;
        ds.secondSaleLandPrices[6] = 0.025 * 10**18;
        ds.secondSaleLandPrices[7] = 0.025 * 10**18;
        ds.secondSaleLandPrices[8] = 0.025 * 10**18;
        ds.secondSaleLandPrices[9] = 0.025 * 10**18;
        ds.secondSaleLandPrices[10] = 0.025 * 10**18;
    }

    function setSecondSaleStartIndexByLandType() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint8 i = 1; i <= 10; i++) {
            ds.secondSaleStartIndexByLandType[i] =
                10000 + //First sale lands
                ((uint256(i) - 1) * 1000) + //1000 lands per type
                1;
        }
    }

    function secondSaleLandPrices() external view returns (uint256[10] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256[10] memory prices;
        for (uint256 i = 0; i < 10; i++) {
            prices[i] = ds.secondSaleLandPrices[uint8(i + 1)];
        }
        return prices;
    }

    function secondSaleIsActive() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.secondSaleIsActive;
    }

    function secondSaleIsPublic() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.secondSaleIsPublic;
    }

    function setSecondSaleIsActive(bool isActive) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.secondSaleIsActive = isActive;
    }

    function setSecondSaleIsPublic(bool isPublic) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.secondSaleIsPublic = isPublic;
    }

    function _mintNextSecondSaleToken(address _to, uint8 landType)
        internal
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(ds.secondSaleIsActive, "LandsFacet: second sale is not active");

        uint256 currMinted = ds.numMintedSecondSaleTokensByLandType[landType];

        require(
            ds.numMintedSecondSaleTokensByLandType[landType] <
                LibDiamond.SECOND_SALE_NUM_TOKENS_PER_TYPE,
            "LandsFacet: No more tokens to mint for the given land type"
        );

        require(
            ds.secondSaleStartIndexByLandType[landType] > 0,
            "LandsFacet: setSecondSaleStartIndexByLandType has not been called"
        );

        uint256 nextTokenId = ds.secondSaleStartIndexByLandType[landType] +
            currMinted;

        //Update land type state
        ds.landTypeByTokenId[nextTokenId] = landType;
        ds.numMintedTokensByLandType[landType]++;
        ds.numMintedSecondSaleTokensByLandType[landType]++;

        super._mint(_to, nextTokenId);

        emit LandMinted(landType, nextTokenId, _to);
        return nextTokenId;
    }

    function setSecondSaleMintAllowances(
        address _address,
        uint8 _totalAllowance
    ) external {
        LibDiamond.enforceIsContractOwner();
        _setSecondSaleMintAllowances(_address, _totalAllowance);
    }

    function batchSetSecondSaleMintAllowances(
        address[] memory addresses,
        uint8 _totalAllowance
    ) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i = 0; i < addresses.length; i++) {
            _setSecondSaleMintAllowances(addresses[i], _totalAllowance);
        }
    }

    function getSecondSaleMintAllowance(address _address)
        public
        view
        returns (uint256[] memory)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256[] memory result = new uint256[](3);
        for (uint8 i = 1; i <= 3; i++) {
            result[i - 1] = ds.secondSaleMintAllowance[_address][i];
        }
        return result;
    }

    function claimSecondSaleTokens(uint8[10] calldata numTokensByLandType)
        external
        virtual
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        IERC20 wethToken = getPaymentToken();

        require(
            ds.secondSaleIsActive,
            "claimSecondSaleTokens: second sale is not active"
        );

        uint256 requiredPaymentAmount = 0;
        address _to = msg.sender;

        for (uint8 i = 1; i <= 10; i++) {
            uint8 numTokens = numTokensByLandType[i - 1];
            uint8 landRarity = LibDiamond.getLandRarityForLandType(i);
            require(
                landRarity > 0,
                "LandsFacet: claimSecondSaleTokens -- invalid landRarity"
            );
            require(
                numTokens <= ds.secondSaleMintAllowance[_to][landRarity],
                "LandsFacet: Insufficient allowance in mint whitelist for address"
            );
            require(
                numTokens <= ds.secondSaleMintAllowance[_to][3],
                "LandsFacet: Insufficient total allowance in mint whitelist for _to address"
            );
            ds.secondSaleMintAllowance[_to][landRarity] -= numTokens;
            if (landRarity < 3) {
                ds.secondSaleMintAllowance[_to][3] -= numTokens;
            }

            if (numTokens == 0) {
                // caller doesn't want this land type
                continue;
            }
            // Transaction sender will pay for the transfer, othervice anyone can submit
            // a transaction where _to is your address and force you pay, if you had allowed
            // to transfer your weth
            requiredPaymentAmount +=
                ds.secondSaleLandPrices[i] *
                uint256(numTokens);
        }

        require(
            requiredPaymentAmount > 0,
            "LandsFacet: setSecondSaleLandPrices has not been called"
        );

        require(
            wethToken.allowance(msg.sender, address(this)) >=
                requiredPaymentAmount,
            "LandsFacet: Insufficient allowance to transfer Weth"
        );

        wethToken.transferFrom(
            msg.sender,
            address(this),
            requiredPaymentAmount
        );

        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= numTokensByLandType[i - 1]; j++) {
                _mintNextSecondSaleToken(_to, i);
            }
        }
    }

    function claimPublicSecondSaleTokens(uint8[10] calldata numTokensByLandType)
        external
        virtual
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address _to = msg.sender;
        require(
            ds.secondSaleIsPublic,
            "LandsFacet: claimPublicSecondSaleTokens -- second sale is not yet open to the public"
        );

        IERC20 wethToken = getPaymentToken();

        uint256 requiredPaymentAmount = 0;

        //Land types are indexed from 1
        uint8[4] memory publicSaleMintAllowance = [0, 1, 2, 4];

        for (uint8 i = 1; i <= 10; i++) {
            uint8 numTokens = numTokensByLandType[i - 1];
            if (numTokens == 0) {
                // caller doesn't want this land type
                continue;
            }
            uint8 landRarity = LibDiamond.getLandRarityForLandType(i);
            require(
                landRarity > 0,
                "LandsFacet: claimPublicSecondSaleTokens -- invalid landRarity"
            );
            require(
                numTokens <= publicSaleMintAllowance[landRarity],
                "LandsFacet: claimPublicSecondSaleTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            require(
                numTokens <= publicSaleMintAllowance[3],
                "LandsFacet: claimPublicSecondSaleTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            publicSaleMintAllowance[landRarity] -= numTokens;
            if (landRarity < 3) {
                publicSaleMintAllowance[3] -= numTokens;
            }

            requiredPaymentAmount +=
                ds.secondSaleLandPrices[i] *
                uint256(numTokens);
        }

        require(
            requiredPaymentAmount > 0,
            "LandsFacet: setSecondSaleLandPrices has not been called"
        );

        require(
            wethToken.allowance(msg.sender, address(this)) >=
                requiredPaymentAmount,
            "ERC721Facet: Insufficient allowance to transfer Weth"
        );

        wethToken.transferFrom(
            msg.sender,
            address(this),
            requiredPaymentAmount
        );

        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= numTokensByLandType[i - 1]; j++) {
                _mintNextSecondSaleToken(_to, i);
            }
        }
    }

    function setThirdSaleStartIndexByLandType() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint8 i = 1; i <= 10; i++) {
            ds.thirdSaleStartIndexByLandType[i] =
                20000 + //First sale lands
                ((uint256(i) - 1) * 1000) + //1000 lands per type
                1;
        }
    }

    function setThirdSaleLandPrices() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        //Mythic
        ds.thirdSaleLandPrices[1] = 0.1 * 10**18;

        //Rare
        ds.thirdSaleLandPrices[2] = 0.05 * 10**18;
        ds.thirdSaleLandPrices[3] = 0.05 * 10**18;
        ds.thirdSaleLandPrices[4] = 0.05 * 10**18;

        //Common
        ds.thirdSaleLandPrices[5] = 0.025 * 10**18;
        ds.thirdSaleLandPrices[6] = 0.025 * 10**18;
        ds.thirdSaleLandPrices[7] = 0.025 * 10**18;
        ds.thirdSaleLandPrices[8] = 0.025 * 10**18;
        ds.thirdSaleLandPrices[9] = 0.025 * 10**18;
        ds.thirdSaleLandPrices[10] = 0.025 * 10**18;
    }

    function _mintNextThirdSaleToken(address _to, uint8 landType)
        internal
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 currMinted = ds.numMintedThirdSaleTokensByLandType[landType];

        require(
            ds.numMintedThirdSaleTokensByLandType[landType] <
                LibDiamond.THIRD_SALE_NUM_TOKENS_PER_TYPE,
            "LandsFacet: No more tokens to mint for the given land type"
        );

        require(
            ds.thirdSaleStartIndexByLandType[landType] > 0,
            "LandsFacet: setThirdSaleStartIndexByLandType has not been called"
        );

        uint256 nextTokenId = ds.thirdSaleStartIndexByLandType[landType] +
            currMinted;

        //Update land type state
        ds.landTypeByTokenId[nextTokenId] = landType;
        ds.numMintedTokensByLandType[landType]++;
        ds.numMintedThirdSaleTokensByLandType[landType]++;

        super._mint(_to, nextTokenId);

        emit LandMinted(landType, nextTokenId, _to);
        return nextTokenId;
    }

    //numTokensByLandType is in reverse order, compared to previous sales
    //indexes:
    // 9 = mythic => mythic
    // 8 = rare (light)
    // 7 = rare (wonder)
    // 6 = rare (mystery)
    // 5 = common (heart)
    // 4 = common (cloud)
    // 3 = common (flower)
    // 2 = common (candy)
    // 1 = common (crystal)
    // 0 = common (moon)
    function claimThirdPublicSaleTokens(uint8[10] calldata numTokensByLandType)
        external
        virtual
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address _to = msg.sender;
        require(
            ds.thirdSaleIsPublic,
            "LandsFacet: claimThirdSalePublicTokens -- third sale is not yet open to the public"
        );

        IERC20 wethToken = getPaymentToken();

        uint256 requiredPaymentAmount = 0;

        //Land types are indexed from 1
        uint8[4] memory publicSaleMintAllowance = [0, 1, 2, 4];

        for (uint8 i = 1; i <= 10; i++) {
            uint8 numTokens = numTokensByLandType[10 - i]; // before it wast [i - 1], but we want reverse order
            if (numTokens == 0) {
                // caller doesn't want this land type
                continue;
            }
            uint8 landRarity = LibDiamond.getLandRarityForLandType(i);
            require(
                landRarity > 0,
                "LandsFacet: claimThirdSalePublicTokens -- invalid landRarity"
            );
            require(
                numTokens <= publicSaleMintAllowance[landRarity],
                "LandsFacet: claimThirdSalePublicTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            require(
                numTokens <= publicSaleMintAllowance[3],
                "LandsFacet: claimThirdSalePublicTokens -- You are not allowed to mint more than 1 mythic land, 2 rare lands, and 4 total lands"
            );
            publicSaleMintAllowance[landRarity] -= numTokens;
            if (landRarity < 3) {
                publicSaleMintAllowance[3] -= numTokens;
            }

            requiredPaymentAmount +=
                ds.thirdSaleLandPrices[i] *
                uint256(numTokens);
        }

        require(
            requiredPaymentAmount > 0,
            "LandsFacet: claimThirdSalePublicTokens -- setthirdSaleLandPrices has not been called"
        );

        require(
            wethToken.allowance(msg.sender, address(this)) >=
                requiredPaymentAmount,
            "ERC721Facet: claimThirdSalePublicTokens -- Insufficient allowance to transfer Weth"
        );

        wethToken.transferFrom(
            msg.sender,
            address(this),
            requiredPaymentAmount
        );

        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= numTokensByLandType[10 - i]; j++) {
                _mintNextThirdSaleToken(_to, i);
            }
        }
    }

    function setThirdSaleIsPublic(bool isPublic) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.thirdSaleIsPublic = isPublic;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "IERC721Enumerable.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

import {LibDiamond} from "LibDiamond.sol";
import {LibLandDNA} from "LibLandDNA.sol";

contract ERC721WithDiamondStorage is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721WithDiamondStorage: balance query for the zero address"
        );
        return LibDiamond.diamondStorage().erc721_balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = LibDiamond.diamondStorage().erc721_owners[tokenId];
        require(
            owner != address(0),
            "ERC721WithDiamondStorage: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return LibDiamond.diamondStorage().erc721_name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return LibDiamond.diamondStorage().erc721_symbol;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return LibDiamond.diamondStorage().erc721_contractURI;
    }

    /**
     * @dev Reference URI for the NFT license file hosted on Arweave permaweb.
     */
    function license() public view returns (string memory) {
        return LibDiamond.diamondStorage().erc721_licenseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721WithDiamondStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = LibDiamond.diamondStorage().erc721_tokenURIs[
            tokenId
        ];
        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721WithDiamondStorage.ownerOf(tokenId);
        require(to != owner, "ERC721WithDiamondStorage: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721WithDiamondStorage: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721WithDiamondStorage: approved query for nonexistent token"
        );

        return LibDiamond.diamondStorage().erc721_tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            LibDiamond.diamondStorage().erc721_operatorApprovals[owner][
                operator
            ];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721WithDiamondStorage: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721WithDiamondStorage: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721WithDiamondStorage: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return LibDiamond.diamondStorage().erc721_owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721WithDiamondStorage: operator query for nonexistent token"
        );
        address owner = ERC721WithDiamondStorage.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721WithDiamondStorage: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721WithDiamondStorage: mint to the zero address");
        require(!_exists(tokenId), "ERC721WithDiamondStorage: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        require(
            LibLandDNA._landIsTransferrable(tokenId), 
            "ERC721WithDiamondStorage: Cannot burn a Land locked into the game or cooling down from an unlock. Unlock it first or wait until cooldown is over."
        );
        address owner = ERC721WithDiamondStorage.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[owner] -= 1;
        delete ds.erc721_owners[tokenId];

        if (bytes(ds.erc721_tokenURIs[tokenId]).length != 0) {
            delete ds.erc721_tokenURIs[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721WithDiamondStorage.ownerOf(tokenId) == from,
            "ERC721WithDiamondStorage: transfer of token that is not own"
        );
        require(to != address(0), "ERC721WithDiamondStorage: transfer to the zero address");
        require(
            LibLandDNA._landIsTransferrable(tokenId), 
            "ERC721WithDiamondStorage: Cannot transfer a Land locked into the game or cooling down from an unlock. Unlock it first or wait until cooldown is done."
        );

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[from] -= 1;
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_tokenApprovals[tokenId] = to;
        emit Approval(ERC721WithDiamondStorage.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721WithDiamondStorage: approve to caller");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721WithDiamondStorage: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * The following methods add support for IERC721Enumerable.
     */

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.erc721_allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            index < balanceOf(owner),
            "ERC721WithDiamondStorage: owner index out of bounds"
        );
        return ds.erc721_ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return ds.erc721_allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = balanceOf(to);
        ds.erc721_ownedTokens[to][length] = tokenId;
        ds.erc721_ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = ds.erc721_ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ds.erc721_ownedTokens[from][lastTokenIndex];

            ds.erc721_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ds.erc721_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ds.erc721_ownedTokensIndex[tokenId];
        delete ds.erc721_ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.erc721_allTokensIndex[tokenId] = ds.erc721_allTokens.length;
        ds.erc721_allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ds.erc721_allTokens.length - 1;
        uint256 tokenIndex = ds.erc721_allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ds.erc721_allTokens[lastTokenIndex];

        ds.erc721_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ds.erc721_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ds.erc721_allTokensIndex[tokenId];
        ds.erc721_allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Modified from original contract, which was written by:
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    uint256 constant FIRST_SALE_NUM_TOKENS_PER_TYPE = 1000;
    uint256 constant SECOND_SALE_NUM_TOKENS_PER_TYPE = 1000;
    uint256 constant THIRD_SALE_NUM_TOKENS_PER_TYPE = 1000;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        // LG game server wallet
        address gameServer;
        // Erc721 state:
        // Mapping from token ID to owner address
        mapping(uint256 => address) erc721_owners;
        // Mapping owner address to token count
        mapping(address => uint256) erc721_balances;
        // Mapping of owners to owned token IDs
        mapping(address => mapping(uint256 => uint256)) erc721_ownedTokens;
        // Mapping of tokens to their index in their owners ownedTokens array.
        mapping(uint256 => uint256) erc721_ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] erc721_allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) erc721_allTokensIndex;
        // Mapping from token ID to approved address
        mapping(uint256 => address) erc721_tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) erc721_operatorApprovals;
        string erc721_name;
        // Token symbol
        string erc721_symbol;
        // Token contractURI - permaweb location of the contract json file
        string erc721_contractURI;
        // Token licenseURI - permaweb location of the license.txt file
        string erc721_licenseURI;
        mapping(uint256 => string) erc721_tokenURIs;
        //whitelist_addresses
        mapping(address => uint8) erc721_mint_whitelist;
        address WethTokenAddress;
        //  (tokenId) -> (1-10) land type
        // 1 = mythic
        // 2 = rare (light)
        // 3 = rare (wonder)
        // 4 = rare (mystery)
        // 5 = common (heart)
        // 6 = common (cloud)
        // 7 = common (flower)
        // 8 = common (candy)
        // 9 = common (crystal)
        // 10 = common (moon)
        mapping(uint256 => uint8) landTypeByTokenId;
        // (1-10) land type -> number of tokens minted with that land type
        mapping(uint8 => uint256) numMintedTokensByLandType;
        // (1-10) land type -> index of the first token of that land type for presale 1
        // 1 = mythic => 1
        // 2 = rare (light) => 1001
        // 3 = rare (wonder) => 2001
        // 4 = rare (mystery) => 3001
        // 5 = common (heart) => 4001
        // 6 = common (cloud) => 5001
        // 7 = common (flower) => 6001
        // 8 = common (candy) => 7001
        // 9 = common (crystal) => 8001
        // 10 = common (moon) => 9001
        // i -> (i-1) * FIRST_SALE_NUM_TOKENS_PER_TYPE + 1
        mapping(uint8 => uint256) firstSaleStartIndexByLandType;
        // Price in WETH (18 decimals) for each type of land
        mapping(uint8 => uint256) firstSaleLandPrices;
        // Number of tokens of each type that an address is allowed to mint as part of the first sale.
        // address -> allowance type -> number of tokens of that allowance type that the address is allowed to mint
        // Land type -> land rarity mapping:
        // 1 = mythic => mythic = 1, total = 3
        // 2 = rare (light) => rare = 2, total = 3
        // 3 = rare (wonder) => rare = 2, total = 3
        // 4 = rare (mystery) => rare = 2, total = 3
        // 5 = common (heart) => total = 3
        // 6 = common (cloud) => total = 3
        // 7 = common (flower) => total = 3
        // 8 = common (candy) => total = 3
        // 9 = common (crystal) => total = 3
        // 10 = common (moon) => total = 3
        mapping(address => mapping(uint8 => uint8)) firstSaleMintAllowance;
        // True if first sale is active and false otherwise.
        bool firstSaleIsActive;
        // True if first sale is public and false otherwise.
        bool firstSaleIsPublic;
        //Second sale:

        // 1 = mythic => 10001
        // 2 = rare (light) => 11001
        // 3 = rare (wonder) => 12001
        //...
        // i -> (i-1) * SECOND_SALE_NUM_TOKENS_PER_TYPE + 1 + 10000
        mapping(uint8 => uint256) secondSaleStartIndexByLandType;
        mapping(uint8 => uint256) secondSaleLandPrices;
        mapping(address => mapping(uint8 => uint8)) secondSaleMintAllowance;
        // Need to store the number of tokens minted by the second sale seperately
        mapping(uint8 => uint256) numMintedSecondSaleTokensByLandType;
        bool secondSaleIsActive;
        bool secondSaleIsPublic;
        // Third sale:

        // 1 = mythic => 20001
        // 2 = rare (light) => 21001
        // 3 = rare (wonder) => 22001
        //...
        // i -> (i-1) * THIRD_SALE_NUM_TOKENS_PER_TYPE + 1 + 20000
        mapping(uint8 => uint256) thirdSaleStartIndexByLandType;
        mapping(uint8 => uint256) thirdSaleLandPrices;
        // Need to store the number of tokens minted by the second sale seperately
        mapping(uint8 => uint256) numMintedThirdSaleTokensByLandType;
        bool thirdSaleIsPublic;
        // Seed for the cheap RNG
        uint256 rngNonce;
        // Land token -> DNA mapping. DNA is represented by a uint256.
        mapping(uint256 => uint256) land_dna;
        // Land token -> Last timestamp when it was unlocked forcefully
        mapping(uint256 => uint256) erc721_landLastForceUnlock;
        // When a land is unlocked forcefully, user has to wait erc721_forceUnlockLandCooldown seconds to be able to transfer
        uint256 erc721_forceUnlockLandCooldown;
        // The state of the NFT when it is round-tripping with the server
        mapping(uint256 => uint256) idempotence_state;

        // LandType -> True if the ID has been registered
        mapping(uint256 => bool) registeredLandTypes;
        // LandType -> ClassId
        mapping(uint256 => uint256) classByLandType;
        // LandType -> ClassGroupId
        mapping(uint256 => uint256) classGroupByLandType;
        // LandType -> rarityId
        mapping(uint256 => uint256) rarityByLandType;
        // LandType -> True if limited edition
        mapping(uint256 => bool) limitedEditionByLandType;

        // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) middleNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validMiddleNames;
        uint256[] validLastNames;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Ownership functionality
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setGameServerAddress(address _newAddress) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.gameServer = _newAddress;
    }

    function setName(string memory _name) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_name = _name;
    }

    function setSymbol(string memory _symbol) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_symbol = _symbol;
    }

    function setContractURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_contractURI = _uri;
    }

    function setLicenseURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_licenseURI = _uri;
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_tokenURIs[_tokenId] = _uri;
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function gameServer() internal view returns (address) {
        return diamondStorage().gameServer;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    function enforceIsGameServer() internal view {
        require(
            msg.sender == diamondStorage().gameServer,
            "LibDiamond: Must be trusted game server"
        );
    }

    function enforceIsOwnerOrGameServer() internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.contractOwner || msg.sender == ds.gameServer,
            "LibDiamond: Must be contract owner or trusted game server"
        );
    }

    function enforceCallerOwnsNFT(uint256 _tokenId) internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.erc721_owners[_tokenId],
            "LibDiamond: NFT must belong to the caller"
        );
    }

    //  This is not a secure RNG - avoid using it for value-generating
    //  transactions (eg. rarity), and when possible, keep the results hidden
    //  from reads within the same block the RNG was computed.
    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function getLandRarityForLandType(uint8 landType)
        internal
        pure
        returns (uint8)
    {
        if (landType == 0) {
            return 0;
        } else if (landType == 1) {
            return 1;
        } else if (landType <= 4) {
            return 2;
        } else if (landType <= 10) {
            return 3;
        } else {
            return 0;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";
library LibLandDNA {
    event DNAUpdated(uint256 tokenId, uint256 dna);

    uint256 internal constant DNA_VERSION = 1;

    uint256 public constant RARITY_MYTHIC = 1;
    uint256 public constant RARITY_RARE = 2;
    uint256 public constant RARITY_COMMON = 3;


    //  version is in bits 0-7 = 0b11111111
    uint256 internal constant DNA_VERSION_MASK = 0xFF;

    //  origin is in bits 8-9 = 0b1100000000
    uint256 internal constant DNA_ORIGIN_MASK = 0x300;

    //  locked is in bit 10 = 0b10000000000
    uint256 internal constant DNA_LOCKED_MASK = 0x400;

    //  limitedEdition is in bit 11 = 0b100000000000
    uint256 internal constant DNA_LIMITEDEDITION_MASK = 0x800;

    //  Futureproofing: Rarity derives from LandType but may be decoupled later
    //  rarity is in bits 12-13 = 0b11000000000000
    uint256 internal constant DNA_RARITY_MASK = 0x3000;

    //  landType is in bits 14-23 = 0b111111111100000000000000
    uint256 internal constant DNA_LANDTYPE_MASK = 0xFFC000;

    //  level is in bits 24-31 = 0b11111111000000000000000000000000
    uint256 internal constant DNA_LEVEL_MASK = 0xFF000000;

    //  firstName is in bits 32-41 = 0b111111111100000000000000000000000000000000
    uint256 internal constant DNA_FIRSTNAME_MASK = 0x3FF00000000;

    //  middleName is in bits 42-51 = 0b1111111111000000000000000000000000000000000000000000
    uint256 internal constant DNA_MIDDLENAME_MASK = 0xFFC0000000000;

    //  lastName is in bits 52-61 = 0b11111111110000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_LASTNAME_MASK = 0x3FF0000000000000;

    function _getDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibDiamond.diamondStorage().land_dna[_tokenId];
    }

    function _setDNA(uint256 _tokenId, uint256 _dna) internal returns (uint256) {
        require(_dna > 0, "LibLandDNA: cannot set 0 DNA");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.land_dna[_tokenId] = _dna;
        emit DNAUpdated(_tokenId, ds.land_dna[_tokenId]);
        return ds.land_dna[_tokenId];
    }

    function _getVersion(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }

    function _setVersion(uint256 _dna, uint256 _version) internal pure returns (uint256) {
        return LibBin.splice(_dna, _version, DNA_VERSION_MASK);
    }

    function _getOrigin(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_ORIGIN_MASK);
    }

    function _setOrigin(uint256 _dna, uint256 _origin) internal pure returns (uint256) {
        return LibBin.splice(_dna, _origin, DNA_ORIGIN_MASK);
    }

    function _getGameLocked(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }

    function _setGameLocked(uint256 _dna, bool _val) internal pure returns (uint256) {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function _getLimitedEdition(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function _setLimitedEdition(uint256 _dna, bool _val) internal pure returns (uint256) {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function _getClass(uint256 _dna) internal view returns (uint256) {
        return LibDiamond.diamondStorage().classByLandType[_getLandType(_dna)];
    }

    function _getClassGroup(uint256 _dna) internal view returns (uint256) {
        return LibDiamond.diamondStorage().classGroupByLandType[_getLandType(_dna)];
    }

    function _getMythic(uint256 _dna) internal view returns (bool) {
        return LibDiamond.diamondStorage().rarityByLandType[_getLandType(_dna)] == RARITY_MYTHIC;
    }

    function _getRarity(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_RARITY_MASK);
    }

    function _setRarity(uint256 _dna, uint256 _rarity) internal pure returns (uint256) {
        return LibBin.splice(_dna, _rarity, DNA_RARITY_MASK);
    }

    function _getLandType(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LANDTYPE_MASK);
    }

    function _setLandType(uint256 _dna, uint256 _landType) internal pure returns (uint256) {
        return LibBin.splice(_dna, _landType, DNA_LANDTYPE_MASK);
    }

    function _getLevel(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LEVEL_MASK);
    }

    function _setLevel(uint256 _dna, uint256 _level) internal pure returns (uint256) {
        return LibBin.splice(_dna, _level, DNA_LEVEL_MASK);
    }

    function _getFirstNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FIRSTNAME_MASK);
    }

    function _setFirstNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_FIRSTNAME_MASK);
    }

    function _getMiddleNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MIDDLENAME_MASK);
    }

    function _setMiddleNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_MIDDLENAME_MASK);
    }

    function _getLastNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LASTNAME_MASK);
    }

    function _setLastNameIndex(uint256 _dna, uint256 _index) internal pure returns (uint256) {
        return LibBin.splice(_dna, _index, DNA_LASTNAME_MASK);
    }

    function enforceDNAVersionMatch(uint256 _dna) internal pure {
        require(
            _getVersion(_dna) == DNA_VERSION,
            "LibLandDNA: Invalid DNA version"
        );
    }

    function _landIsTransferrable(uint256 tokenId) internal view returns(bool) {
        if(_getGameLocked(_getDNA(tokenId))) {
            return false;
        }
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bool coolingDownFromForceUnlock = (ds.erc721_landLastForceUnlock[tokenId] + ds.erc721_forceUnlockLandCooldown) >= block.timestamp;

        return !coolingDownFromForceUnlock;
    }

    function _enforceLandIsNotCoolingDown(uint256 tokenId) internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bool coolingDownFromForceUnlock = (ds.erc721_landLastForceUnlock[tokenId] + ds.erc721_forceUnlockLandCooldown) >= block.timestamp;
        require(!coolingDownFromForceUnlock, "LibLandDNA: Land cooling down from force unlock");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibBin {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Using the mask, determine how many bits we need to shift to extract the desired value
    //  @param _mask A bitstring with right-padding zeroes
    //  @return The number of right-padding zeroes on the _mask
    function _getShiftAmount(uint256 _mask) internal pure returns (uint256) {
        uint256 count = 0;
        while (_mask & 0x1 == 0) {
            _mask >>= 1;
            ++count;
        }
        return count;
    }

    //  Insert _insertion data into the _bitArray bitstring
    //  @param _bitArray The base dna to manipulate
    //  @param _insertion Data to insert (no right-padding zeroes)
    //  @param _mask The location in the _bitArray where the insertion will take place
    //  @return The combined _bitArray bitstring
    function splice(
        uint256 _bitArray,
        uint256 _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        uint256 _off_set = _getShiftAmount(_mask);
        uint256 passthroughMask = MAX ^ _mask;
        //  remove old value,  shift new value to correct spot,  mask new value
        return (_bitArray & passthroughMask) | ((_insertion << _off_set) & _mask);
    }

    //  Alternate function signature for boolean insertion
    function splice(
        uint256 _bitArray,
        bool _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        return splice(_bitArray, _insertion ? 1 : 0, _mask);
    }

    //  Retrieves a segment from the _bitArray bitstring
    //  @param _bitArray The dna to parse
    //  @param _mask The location in teh _bitArray to isolate
    //  @return The data from _bitArray that was isolated in the _mask (no right-padding zeroes)
    function extract(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (uint256)
    {
        uint256 _off_set = _getShiftAmount(_mask);
        return (_bitArray & _mask) >> _off_set;
    }

    //  Alternate function signature for boolean retrieval
    function extractBool(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (bool)
    {
        return (_bitArray & _mask) != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}