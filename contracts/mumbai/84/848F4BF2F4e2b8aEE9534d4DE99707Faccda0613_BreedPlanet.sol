// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BreedPlanetBase.sol";
import "./utils/ChainlinkRng.sol";

contract BreedPlanet is BreedPlanetBase, ChainlinkRng {
    // contract BreedPlanet is BreedPlanetBase {
    using SafeERC20 for IERC20;
    using Address for address;

    struct BreedStruct {
        address userAddress;
        uint256 planetAId;
        uint256 planetBId;
        bool shouldUseMiniBlackhole;
        bool isDone; // for client check breed is finish or not
        uint256 planetId;
    }

    ERC1155Burnable public immutable apeironGodiverseCollection;
    IERC20 public immutable aprsToken;
    IERC20 public immutable animaToken;

    bool public isPrimevalActive = true;
    uint256 public aprsPrice;
    mapping(uint256 => mapping(uint256 => uint256)) public animaPrices; // bloodline => breedcount => cost
    mapping(uint256 => mapping(uint256 => uint256))
        public apeironGodiverseCollectionNumbers; // bloodline => breedcount => cost

    uint256 public currentPlanetId = 4585; // production id
    uint256 public normalBreedBaseInterval = 14 * 3600 * 24;
    uint256 public bornBaseInterval = 7 * 3600 * 24;
    uint256 public additionBornBaseInterval = 14 * 3600 * 24;
    uint256 public miniBlackholeTokenId = 1; // apeironGodiverseCollection id

    mapping(uint256 => BreedStruct) public BreedStructMap; // uint256: Chainlink requestId

    event RequestBreed(uint256 requestId);
    event BreedSuccess(uint256 indexed _tokenId);

    constructor(
        address _nftAddress,
        address _breedAddress,
        address _apeironGodiverseCollectionAddress,
        address _aprsTokenAddress,
        address _animaTokenAddress,
        uint256 _aprsPrice,
        uint256[][] memory _animaPrices,
        uint256[][] memory _apeironGodiverseCollectionNumbers,
        ChainlinkStruct memory _chainlinkStruct
    )
        BreedPlanetBase(_nftAddress, _breedAddress)
        ChainlinkRng(_chainlinkStruct)
    {
        require(
            _apeironGodiverseCollectionAddress.isContract(),
            "_apeironGodiverseCollectionAddress must be a contract"
        );
        require(
            _aprsTokenAddress.isContract(),
            "_aprsTokenAddress must be a contract"
        );
        require(
            _animaTokenAddress.isContract(),
            "_animaTokenAddress must be a contract"
        );

        apeironGodiverseCollection = ERC1155Burnable(
            _apeironGodiverseCollectionAddress
        );
        aprsToken = IERC20(_aprsTokenAddress);
        animaToken = IERC20(_animaTokenAddress);

        // set up price
        setAprsAndAnimaPrices(_aprsPrice, _animaPrices);
        setApeironGodiverseCollectionNumber(_apeironGodiverseCollectionNumbers);
    }

    /// @notice request for breeding
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    /// @param shouldUseMiniBlackhole use mini blackhold or not
    function requestBreed(
        uint256 planetAId,
        uint256 planetBId,
        bool shouldUseMiniBlackhole
    ) external returns (uint256) {
        // dry run for check can breed
        _breed(msg.sender, planetAId, planetBId, shouldUseMiniBlackhole, true);

        // request rng for get random number
        uint256 requestId = requestRandomWords();

        BreedStruct memory breedStruct = BreedStruct(
            msg.sender,
            planetAId,
            planetBId,
            shouldUseMiniBlackhole,
            false,
            0
        );
        BreedStructMap[requestId] = breedStruct;

        emit RequestBreed(requestId);

        return requestId;
    }

    /// @notice after chainlink fulfillRandomWords will call this, and it will run breed function
    /// @param requestId requestId
    function _rngCallBack(uint256 requestId) internal virtual override {
        BreedStruct memory breedStruct = BreedStructMap[requestId];
        _breed(
            breedStruct.userAddress,
            breedStruct.planetAId,
            breedStruct.planetBId,
            breedStruct.shouldUseMiniBlackhole,
            false
        );
        // update isDone status for client
        BreedStructMap[requestId].isDone = true;
        BreedStructMap[requestId].planetId = currentPlanetId;
    }

    /// @notice set the currentPlanetId
    /// @param _currentPlanetId currentPlanetId
    function setCurrentPlanetId(uint256 _currentPlanetId) external onlyOwner {
        currentPlanetId = _currentPlanetId;
    }

    /// @notice set is primeval active
    /// @param _isPrimevalActive is Primeval Active
    function setPrimevalActive(bool _isPrimevalActive) external onlyOwner {
        isPrimevalActive = _isPrimevalActive;
    }

    /// @notice set MiniBlackholeTokenId; miniBlackhole is erc1155, and the TokenId is that id
    /// @param _miniBlackholeTokenId mini Blackhole Token Id
    function setMiniBlackholeTokenId(uint256 _miniBlackholeTokenId)
        external
        onlyOwner
    {
        miniBlackholeTokenId = _miniBlackholeTokenId;
    }

    /// @notice check planetA and B can breed or not, this function will not check the token balance
    /// @param userAddress planet owner address
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    /// @param shouldUseMiniBlockhole should Use Mini Blockhole
    function checkCanBreed(
        address userAddress,
        uint256 planetAId,
        uint256 planetBId,
        bool shouldUseMiniBlockhole
    ) public view returns (bool) {
        require(
            planetContract.ownerOf(planetAId) == userAddress &&
                planetContract.ownerOf(planetBId) == userAddress,
            "planet is not owned"
        );

        // planet data
        IApeironPlanet.PlanetData memory planetAData = _getPlanetData(
            planetAId
        );
        IApeironPlanet.PlanetData memory planetBData = _getPlanetData(
            planetBId
        );

        require(
            planetAData.lastBreedTime + normalBreedBaseInterval <
                block.timestamp &&
                planetBData.lastBreedTime + normalBreedBaseInterval <
                block.timestamp,
            "14 days cooldown for each breeding"
        );

        // planet reach max breed count
        require(
            planetAData.breedCount + 1 <= planetAData.breedCountMax &&
                planetBData.breedCount + 1 <= planetBData.breedCountMax,
            "planet reach max breed count"
        );

        // planet can't breed with parent and itself
        require(
            !_parentIsRepeated(planetAId, planetBId),
            "planet can't breed with parent"
        );

        // apeironGodiverseCollection nft
        // require no parent
        if (isPrimevalActive) {
            require(
                !_hasParent(planetAId) && !_hasParent(planetBId),
                "Primeval do not allow planetA or B has parent"
            );
            require(
                shouldUseMiniBlockhole,
                "Primeval require apeironGodiverseCollection token"
            );
        }
        if (shouldUseMiniBlockhole) {
            require(
                userAddress == address(this) ||
                    apeironGodiverseCollection.isApprovedForAll(
                        userAddress,
                        address(this)
                    ),
                "Grant apeironGodiverseCollection approval for breeding contract"
            );
        }

        return true;
    }

    /// @notice speacial handle presale planet breedCountMax
    /// @param planetId planetId
    function _checkAndAddBreedCountMax(uint256 planetId) internal {
        IApeironPlanet.PlanetData memory planetData = _getPlanetData(planetId);
        // speacial handle no parent breedCountMax
        if (!_hasParent(planetId) && planetData.breedCountMax == 0) {
            planetContract.updatePlanetData(
                planetId,
                planetData.gene,
                0,
                0,
                3,
                false
            );
        }
    }

    /// @notice planet breed function
    /// @param userAddress planet user address
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    /// @param shouldUseMiniBlockhole should Use Mini Blockhole
    /// @param isDryRun is dry run
    function _breed(
        address userAddress,
        uint256 planetAId,
        uint256 planetBId,
        bool shouldUseMiniBlockhole,
        bool isDryRun // if isDryRun, not run mint, transfer and burn token
    ) internal virtual {
        _checkAndAddBreedCountMax(planetAId);
        _checkAndAddBreedCountMax(planetBId);

        require(
            checkCanBreed(
                userAddress,
                planetAId,
                planetBId,
                shouldUseMiniBlockhole
            ),
            "planetA & planetB cannot be breed"
        );
        uint256 planetABloodline = _getPlanetBloodline(planetAId);
        uint256 planetBBloodline = _getPlanetBloodline(planetBId);
        // APRS and ANIMA Fees is require
        uint256 _aprsPrice;
        uint256 _animaPrice;
        if (shouldUseMiniBlockhole) {
            _aprsPrice = 0;
            _animaPrice = 0;
        } else {
            _aprsPrice = aprsPrice;
            _animaPrice =
                animaPrices[planetABloodline][
                    _getPlanetData(planetAId).breedCount
                ] +
                animaPrices[planetBBloodline][
                    _getPlanetData(planetBId).breedCount
                ];
        }
        if (!isDryRun && _aprsPrice > 0) {
            aprsToken.safeTransferFrom(userAddress, address(this), _aprsPrice);
        }
        if (!isDryRun && _animaPrice > 0) {
            animaToken.safeTransferFrom(
                userAddress,
                address(this),
                _animaPrice
            );
        }

        // burn apeironGodiverseCollection miniBlackhole
        if (shouldUseMiniBlockhole) {
            uint256 targetApeironGodiverseCollectionNumber = apeironGodiverseCollectionNumbers[
                    planetABloodline
                ][_getPlanetData(planetAId).breedCount] +
                    apeironGodiverseCollectionNumbers[planetBBloodline][
                        _getPlanetData(planetBId).breedCount
                    ];
            require(
                apeironGodiverseCollection.balanceOf(
                    userAddress,
                    miniBlackholeTokenId
                ) >= targetApeironGodiverseCollectionNumber,
                "User balanceOf apeironGodiverseCollection token is not enough"
            );
            if (!isDryRun) {
                apeironGodiverseCollection.burn(
                    userAddress,
                    miniBlackholeTokenId,
                    targetApeironGodiverseCollectionNumber
                );
            }
        }

        // start breed
        if (!isDryRun) {
            uint256[] memory parents = new uint256[](2);
            parents[0] = planetAId;
            parents[1] = planetBId;
            currentPlanetId++;

            // genid for element
            // uint256[] memory attributes = _getUpdateAttributesOnBreed(
            //     planetAId,
            //     planetBId
            // );
            // uint256 geneId = _convertToGeneId(attributes);
            uint256 geneId = _convertToGeneId(
                _getUpdateAttributesOnBreed(planetAId, planetBId)
            );
            planetContract.safeMint(
                geneId,
                parents,
                userAddress,
                currentPlanetId
            );

            // 7 days cooldown for the born
            // +14 days if grandparent are same
            bool isGrandparentRepeat = false;
            (isGrandparentRepeat, ) = _checkIsGrandparentRepeat(
                planetAId,
                planetBId
            );

            uint256 bornInterval;
            if (isGrandparentRepeat) {
                bornInterval = bornBaseInterval + additionBornBaseInterval;
            } else {
                bornInterval = bornBaseInterval;
            }
            breedPlanetDataContract.updatePlanetNextBornMap(
                currentPlanetId,
                block.timestamp + bornInterval
            );

            emit BreedSuccess(currentPlanetId);
        }
    }

    /// @notice get Attributes on Breed, will only update 0-4
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _getUpdateAttributesOnBreed(uint256 planetAId, uint256 planetBId)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory parents = _getParentIDArray(planetAId, planetBId);
        uint256 parentALegacyTag = _getPlanetAttributes(parents[0])[4];
        uint256 parentBLegacyTag = _getPlanetAttributes(parents[1])[4];

        // element
        ElementStruct memory elementStruct = ElementStruct(0, 0, 0, 0, 0, 0);
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < parents.length; i++) {
            uint256[] memory planetAttributes = _getPlanetAttributes(
                parents[i]
            );

            uint256 weight = 1;
            if (i == 0 || i == 1) {
                weight = 3;
            }
            elementStruct.fire += planetAttributes[0] * weight;
            elementStruct.water += planetAttributes[1] * weight;
            elementStruct.air += planetAttributes[2] * weight;
            elementStruct.earth += planetAttributes[3] * weight;
            totalWeight += weight;
        }
        elementStruct.fire = elementStruct.fire / totalWeight;
        elementStruct.water = elementStruct.water / totalWeight;
        elementStruct.air = elementStruct.air / totalWeight;
        elementStruct.earth = elementStruct.earth / totalWeight;

        // get planet domain element
        elementStruct.domainValue = Math.max(
            Math.max(elementStruct.fire, elementStruct.water),
            Math.max(elementStruct.air, elementStruct.earth)
        );
        if (elementStruct.domainValue == elementStruct.fire) {
            elementStruct.domainIndex = 1;
        } else if (elementStruct.domainValue == elementStruct.water) {
            elementStruct.domainIndex = 2;
        } else if (elementStruct.domainValue == elementStruct.air) {
            elementStruct.domainIndex = 3;
        } else {
            // elementStruct.domainValue == elementStruct.earth
            elementStruct.domainIndex = 4;
        }

        // dominant element adjust by parent legacy tag
        if (parentALegacyTag != 0 || parentBLegacyTag != 0) {
            // get parent planetTag
            PlanetTag memory planetATag = PlanetTag(0, 0, 0, 0, 0);
            PlanetTag memory planetBTag = PlanetTag(0, 0, 0, 0, 0);
            if (parentALegacyTag != 0) {
                planetATag = _getPlanetTagById(parentALegacyTag);
            }
            if (parentBLegacyTag != 0) {
                planetBTag = _getPlanetTagById(parentBLegacyTag);
            }

            // update element value by tag
            if (elementStruct.domainIndex == 1) {
                elementStruct.fire = Math.max(
                    elementStruct.fire,
                    Math.max(planetATag.fire, planetBTag.fire)
                );
            } else if (elementStruct.domainIndex == 2) {
                elementStruct.water = Math.max(
                    elementStruct.water,
                    Math.max(planetATag.water, planetBTag.water)
                );
            } else if (elementStruct.domainIndex == 3) {
                elementStruct.air = Math.max(
                    elementStruct.air,
                    Math.max(planetATag.air, planetBTag.air)
                );
            } else {
                // elementStruct.domainIndex == 4
                elementStruct.earth = Math.max(
                    elementStruct.earth,
                    Math.max(planetATag.earth, planetBTag.earth)
                );
            }
            // update domainValue
            elementStruct.domainValue = Math.max(
                Math.max(elementStruct.fire, elementStruct.water),
                Math.max(elementStruct.air, elementStruct.earth)
            );
        }

        // final adjust value to total 100
        elementStruct = _updateRemainValueForElementStruct(elementStruct);

        // attributes
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementStruct.fire; // element: fire
        attributes[1] = elementStruct.water; // element: water
        attributes[2] = elementStruct.air; // element: air
        attributes[3] = elementStruct.earth; // element: earth

        // primeval legacy tag
        uint256[] memory parentLegacyArray = _getParentLegacyArray(
            planetAId,
            planetBId
        );
        uint256 random = _randomRange(0, 99);
        random = random / 10;
        if (parentLegacyArray.length > random) {
            attributes[4] = parentLegacyArray[random];
        } else {
            attributes[4] = 0;
        }

        return attributes;
    }

    /// @notice update ElementStruct, it will adjust the total value to 100
    /// @param elementStruct elementStruct
    function _updateRemainValueForElementStruct(
        ElementStruct memory elementStruct
    ) internal returns (ElementStruct memory) {
        uint256 totalValue = elementStruct.fire +
            elementStruct.water +
            elementStruct.air +
            elementStruct.earth;
        uint256 remainValue;
        uint256 baseValue;

        if (totalValue > 100) {
            remainValue = 100 - elementStruct.domainValue;
            baseValue =
                elementStruct.fire +
                elementStruct.water +
                elementStruct.air +
                elementStruct.earth -
                elementStruct.domainValue;

            if (elementStruct.domainIndex != 1) {
                elementStruct.fire = ((elementStruct.fire * remainValue) /
                    (baseValue));
            }
            if (elementStruct.domainIndex != 2) {
                elementStruct.water = ((elementStruct.water * remainValue) /
                    (baseValue));
            }
            if (elementStruct.domainIndex != 3) {
                elementStruct.air = ((elementStruct.air * remainValue) /
                    (baseValue));
            }
            if (elementStruct.domainIndex != 4) {
                elementStruct.earth = ((elementStruct.earth * remainValue) /
                    (baseValue));
            }
        }

        totalValue =
            elementStruct.fire +
            elementStruct.water +
            elementStruct.air +
            elementStruct.earth;

        if (totalValue < 100) {
            remainValue = 100 - totalValue;
            uint256[] memory elementArray = new uint256[](4);
            uint256 elementCount = 0;
            if (!(elementStruct.fire == 0 || elementStruct.domainIndex == 1)) {
                elementArray[elementCount] = 1;
                elementCount++;
            }
            if (!(elementStruct.water == 0 || elementStruct.domainIndex == 2)) {
                elementArray[elementCount] = 2;
                elementCount++;
            }
            if (!(elementStruct.air == 0 || elementStruct.domainIndex == 3)) {
                elementArray[elementCount] = 3;
                elementCount++;
            }
            if (!(elementStruct.earth == 0 || elementStruct.domainIndex == 4)) {
                elementArray[elementCount] = 4;
                elementCount++;
            }
            elementArray = _shuffleOrdering(elementArray, elementCount);

            if (elementArray[0] == 1) {
                elementStruct.fire += remainValue;
            } else if (elementArray[0] == 2) {
                elementStruct.water += remainValue;
            } else if (elementArray[0] == 3) {
                elementStruct.air += remainValue;
            } else {
                // elementArray[0] == 4
                elementStruct.earth += remainValue;
            }
        }
        return elementStruct;
    }

    /// @notice get planetTag by tagID
    /// @param planetTagId planetTagId
    function _getPlanetTagById(uint256 planetTagId)
        internal
        view
        returns (PlanetTag memory)
    {
        require(
            planetTagId != 0 && planetTagId <= 62,
            "Tag should not be 0 to call this function"
        );

        if (planetTagId <= 18) {
            return planetTagsPerBloodline[1][planetTagId - 1];
        } else if (planetTagId <= 46) {
            return planetTagsPerBloodline[2][planetTagId - 18 - 1];
        } else {
            // planetTagId <= 62
            return planetTagsPerBloodline[3][planetTagId - 46 - 1];
        }
    }

    /// @notice get planet parent legacy array
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _getParentLegacyArray(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 count = 0;
        uint256[] memory parentArray = _getParentIDArray(planetAId, planetBId);
        uint256[] memory legacyTagArray = new uint256[](parentArray.length);
        for (uint256 i = 0; i < parentArray.length; i++) {
            uint256 planetLegacyTag = _getPlanetAttributes(parentArray[i])[4];

            if (planetLegacyTag != 0) {
                legacyTagArray[count] = planetLegacyTag;
                count++;
            }
        }

        return legacyTagArray;
    }

    /// @notice get planet Bloodline, result will be 0-3
    /// @param planetId planetId
    function _getPlanetBloodline(uint256 planetId)
        internal
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256[] memory planetAttributes = _getPlanetAttributes(planetId);
        // there are 4 element
        for (uint256 i = 0; i < 4; i++) {
            if (planetAttributes[i] > 0) {
                result++;
            }
        }

        return result - 1;
    }

    /// @notice set Normal Breed Base Interval
    /// @param interval interval
    function setNormalBreedBaseInterval(uint256 interval) external onlyOwner {
        normalBreedBaseInterval = interval;
    }

    /// @notice set Born Base Interval
    /// @param interval interval
    function setBornBaseInterval(uint256 interval) external onlyOwner {
        bornBaseInterval = interval;
    }

    /// @notice set addition Born Base Interval
    /// @param interval interval
    function setAdditionBornBaseInterval(uint256 interval) external onlyOwner {
        additionBornBaseInterval = interval;
    }

    /// @notice set aprs and anima prices
    /// @param _aprsPrice aprsPrice
    /// @param _animaPrices first[] is bloodline (must be 4), second[] is breed count price (must be 5)
    function setAprsAndAnimaPrices(
        uint256 _aprsPrice,
        uint256[][] memory _animaPrices
    ) public onlyOwner {
        aprsPrice = _aprsPrice;

        require(_animaPrices.length == 4, "Prices length are wrong");

        for (uint256 i = 0; i < _animaPrices.length; i++) {
            require(_animaPrices[i].length == 5, "Prices length are wrong");
            for (uint256 j = 0; j < _animaPrices[i].length; j++) {
                animaPrices[i][j] = _animaPrices[i][j];
            }
        }
    }

    /// @notice set Apeiron Godiverse Collection Number (mini blackhold)
    /// @param _apeironGodiverseCollectionNumbers first[] is bloodline (must be 4), second[] is breed count price (must be 5)
    function setApeironGodiverseCollectionNumber(
        uint256[][] memory _apeironGodiverseCollectionNumbers
    ) public onlyOwner {
        require(
            _apeironGodiverseCollectionNumbers.length == 4,
            "Number length are wrong"
        );

        for (
            uint256 i = 0;
            i < _apeironGodiverseCollectionNumbers.length;
            i++
        ) {
            require(
                _apeironGodiverseCollectionNumbers[i].length == 5,
                "Number length are wrong"
            );
            for (
                uint256 j = 0;
                j < _apeironGodiverseCollectionNumbers[i].length;
                j++
            ) {
                apeironGodiverseCollectionNumbers[i][
                    j
                ] = _apeironGodiverseCollectionNumbers[i][j];
            }
        }
    }

    /**
     * Withdraw any ERC20
     *
     * @param tokenAddress - ERC20 token address
     * @param amount - amount to withdraw
     * @param wallet - address to withdraw to
     */
    function withdrawFunds(
        address tokenAddress,
        uint256 amount,
        address wallet
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(wallet, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
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
pragma solidity 0.8.12;
// pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./planets/contracts/ApeironPlanetGenerator.sol";
import "./interfaces/IApeironPlanet.sol";
import "./interfaces/IBreedPlanetData.sol";

import "./planets/contracts/utils/AccessProtected.sol";

// todo _randomRange should be random orcale
contract BreedPlanetBase is ApeironPlanetGenerator, AccessProtected {
    using Address for address;

    IApeironPlanet public immutable planetContract;
    IBreedPlanetData public immutable breedPlanetDataContract;

    struct ElementStruct {
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
        uint256 domainValue;
        uint256 domainIndex; // 1: fire, 2: water, 3: air, 4: earth
    }

    constructor(address _nftAddress, address _breedAddress) {
        require(_nftAddress.isContract(), "_nftAddress must be a contract");
        require(_breedAddress.isContract(), "_breedAddress must be a contract");

        planetContract = IApeironPlanet(_nftAddress);
        breedPlanetDataContract = IBreedPlanetData(_breedAddress);
    }

    /// @notice get planetId Parent ID
    /// @param planetId planetId
    function getParentID(uint256 planetId)
        public
        view
        returns (uint256, uint256)
    {
        uint256 parentAId = 0;
        uint256 parentBId = 0;
        IApeironPlanet.PlanetData memory planetData = _getPlanetData(planetId);
        if (planetData.parents.length == 2) {
            parentAId = planetData.parents[0];
            parentBId = planetData.parents[1];
        }
        return (parentAId, parentBId);
    }

    /// @notice check planet has parent or not
    /// @param planetId planetId
    function _hasParent(uint256 planetId) internal view returns (bool) {
        if (_getPlanetData(planetId).parents.length == 2) {
            return true;
        }
        return false;
    }

    /// @notice get planetId Parent and Grandparent ID array, which Parent in first two slot
    /// @param planetId planetId
    function _getParentAndGrandparentIDArray(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        require(_hasParent(planetId), "planet have no parents");
        (uint256 parentAId, uint256 parentBId) = getParentID(planetId);
        return _getParentIDArray(parentAId, parentBId);
    }

    /// @notice get planetA planetB Parent's ID array, which planetAId & planetBId in first two slot
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _getParentIDArray(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 parentCount = 2;

        if (_hasParent(planetAId)) {
            parentCount += 2;
        }
        if (_hasParent(planetBId)) {
            parentCount += 2;
        }

        uint256[] memory parents = new uint256[](parentCount);
        uint256 index = 2;
        parents[0] = planetAId;
        parents[1] = planetBId;

        if (_hasParent(planetAId)) {
            (uint256 parentAAId, uint256 parentABId) = getParentID(planetAId);
            parents[index++] = parentAAId;
            parents[index++] = parentABId;
        }

        if (_hasParent(planetBId)) {
            (uint256 parentBAId, uint256 parentBBId) = getParentID(planetBId);
            parents[index++] = parentBAId;
            parents[index] = parentBBId;
        }
        return parents; // parent count 2-6
    }

    /// @notice check planetA planetB Parent is repeated
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _parentIsRepeated(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (bool)
    {
        uint256[] memory parentsArray = _getParentIDArray(planetAId, planetBId);
        for (uint256 i = 0; i < parentsArray.length - 1; i++) {
            for (uint256 j = i + 1; j < parentsArray.length; j++) {
                if (parentsArray[i] == parentsArray[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /// @notice check planetA planetB Grandparent is repeated, and repeated count
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    function _checkIsGrandparentRepeat(uint256 planetAId, uint256 planetBId)
        internal
        view
        returns (bool, uint256)
    {
        bool isGrandparentRepeat = false;
        uint256 repeatCount = 0;
        uint256[] memory parentAArray;
        uint256[] memory parentBArray;
        if (_hasParent(planetAId)) {
            parentAArray = _getParentAndGrandparentIDArray(planetAId);
        } else {
            parentAArray = new uint256[](1);
            parentAArray[0] = planetAId;
        }
        if (_hasParent(planetBId)) {
            parentBArray = _getParentAndGrandparentIDArray(planetBId);
        } else {
            parentBArray = new uint256[](1);
            parentBArray[0] = planetBId;
        }
        for (uint256 i = 0; i < parentAArray.length; i++) {
            for (uint256 j = 0; j < parentBArray.length; j++) {
                if (parentAArray[i] == parentBArray[j]) {
                    isGrandparentRepeat = true;
                    repeatCount++;
                }
            }
        }
        return (isGrandparentRepeat, repeatCount);
    }

    /// @notice ease way (without any array creation) to filter out all duplicated values, the result values will be moved to the beginning of array and return the new array length
    /// @dev use new array length to retrieve the non-duplicated values from the new array
    /// @param input input array
    /// @return output array and new array length
    function _removeDuplicated(uint256[] memory input)
        internal
        pure
        returns (uint256[] memory, uint256)
    {
        uint256 availableCount = 1;
        uint256 duplicatedIndex;
        for (uint256 i = 1; i < input.length; i++) {
            duplicatedIndex = 0;
            for (uint256 j = 0; j < i; j++) {
                if (input[i] == input[j]) {
                    duplicatedIndex = i;
                    break;
                }
            }

            //without duplication
            if (duplicatedIndex == 0) {
                input[availableCount] = input[i];
                ++availableCount;
            }
        }

        return (input, availableCount);
    }

    /// @notice random shuffle array ordering
    /// @param input input array
    /// @param availableSize array size
    function _shuffleOrdering(uint256[] memory input, uint256 availableSize)
        internal
        returns (uint256[] memory)
    {
        uint256 wrapindex;
        for (uint256 i = 0; i < availableSize - 1; i++) {
            wrapindex = _randomRange(i + 1, availableSize - 1);
            (input[i], input[wrapindex]) = (input[wrapindex], input[i]);
        }

        return input;
    }

    /// @notice convert geneId To Attributes array
    /// @param _geneId geneId
    /// @param _numOfAttributes Number Of Attributes
    function _convertToAttributes(uint256 _geneId, uint256 _numOfAttributes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory attributes = new uint256[](_numOfAttributes);

        uint256 geneId = _geneId;
        for (uint256 i = 0; i < attributes.length; i++) {
            attributes[i] = geneId % 256;
            geneId /= 256;
        }

        return attributes;
    }

    /// @notice get planet data
    /// @param planetId planetId
    function _getPlanetData(uint256 planetId)
        internal
        view
        returns (IApeironPlanet.PlanetData memory)
    {
        (IApeironPlanet.PlanetData memory planetData, ) = planetContract
            .getPlanetData(planetId);
        return planetData;
    }

    /// @notice get planet attributes
    /// @param planetId planetId
    function _getPlanetAttributes(uint256 planetId)
        internal
        view
        returns (uint256[] memory)
    {
        return _convertToAttributes(_getPlanetData(planetId).gene, 18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../planets/contracts/utils/Random.sol";

// abstract contract ChainlinkRng is VRFConsumerBaseV2, Random, Ownable {
contract ChainlinkRng is VRFConsumerBaseV2, Random, Ownable {
    struct ChainlinkStruct {
        uint64 chainlinkSubscriptionId;
        address vrfCoordinator;
        // address linkTokenContract;
        bytes32 keyHash;
    }

    VRFCoordinatorV2Interface COORDINATOR;
    // LinkTokenInterface LINKTOKEN;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // Matic testnet coordinator. For other networks,
    // address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    // address link_token_contract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // bytes32 keyHash =
    //     0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    bytes32 keyHash;

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    // max 2500000
    uint32 callbackGasLimit = 2000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    // Storage parameters
    uint256[] public s_randomWords;
    uint64 public s_subscriptionId;

    // constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    //     COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    //     LINKTOKEN = LinkTokenInterface(link_token_contract);
    //     s_owner = msg.sender;
    //     s_subscriptionId = subscriptionId;
    // }
    constructor(ChainlinkStruct memory _chainlinkStruct)
        VRFConsumerBaseV2(_chainlinkStruct.vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _chainlinkStruct.vrfCoordinator
        );
        // LINKTOKEN = LinkTokenInterface(_chainlinkStruct.linkTokenContract);
        keyHash = _chainlinkStruct.keyHash;
        s_subscriptionId = _chainlinkStruct.chainlinkSubscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal virtual returns (uint256) {
        // Will revert if subscription is not set and funded.
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        s_randomWords = randomWords;
        uint256 nonce = s_randomWords[0] % 100;
        _updateRandomNonce(nonce);

        _rngCallBack(requestId);
    }

    function _rngCallBack(uint256 requestId) internal virtual {}

    function setChainlinkPara(
        uint32 _gasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes32 _keyHash
    ) external onlyOwner {
        callbackGasLimit = _gasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        keyHash = _keyHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
pragma solidity 0.8.12;

import "./utils/Random.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract ApeironPlanetGenerator is Random {
    enum CoreType {
        Elemental,
        Mythic,
        Arcane,
        Divine,
        Primal
    }
    // enum Bloodline {
    //     Pure,    //0
    //     Duo,     //1
    //     Tri,     //2
    //     Mix      //3
    // }
    mapping(CoreType => mapping(uint256 => uint256)) bloodlineRatioPerCoreType;
    mapping(CoreType => uint256) haveTagRatioPerCoreType;

    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }
    mapping(uint256 => PlanetTag[]) planetTagsPerBloodline;

    // enum ElementType {
    //     Fire,   //0
    //     Water,  //1
    //     Air,    //2
    //     Earth   //3
    // }

    event GenerateGeneId(
        uint256 bloodline,
        uint256[] elementOrders,
        uint256[] attributes,
        uint256 geneId
    );

    constructor() {
        bloodlineRatioPerCoreType[CoreType.Primal][
            0 /*Bloodline.Pure*/
        ] = 100;

        bloodlineRatioPerCoreType[CoreType.Divine][
            0 /*Bloodline.Duo*/
        ] = 10;
        bloodlineRatioPerCoreType[CoreType.Divine][
            1 /*Bloodline.Duo*/
        ] = 90;

        bloodlineRatioPerCoreType[CoreType.Arcane][
            0 /*Bloodline.Pure*/
        ] = 2;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            1 /*Bloodline.Duo*/
        ] = 30;
        bloodlineRatioPerCoreType[CoreType.Arcane][
            2 /*Bloodline.Tri*/
        ] = 68;

        bloodlineRatioPerCoreType[CoreType.Mythic][
            0 /*Bloodline.Pure*/
        ] = 1;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            1 /*Bloodline.Duo*/
        ] = 9;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            2 /*Bloodline.Tri*/
        ] = 72;
        bloodlineRatioPerCoreType[CoreType.Mythic][
            3 /*Bloodline.Mix*/
        ] = 18;

        bloodlineRatioPerCoreType[CoreType.Elemental][
            2 /*Bloodline.Tri*/
        ] = 70;
        bloodlineRatioPerCoreType[CoreType.Elemental][
            3 /*Bloodline.Mix*/
        ] = 30;

        haveTagRatioPerCoreType[CoreType.Primal] = 0;
        haveTagRatioPerCoreType[CoreType.Divine] = 20;
        haveTagRatioPerCoreType[CoreType.Arcane] = 10;
        haveTagRatioPerCoreType[CoreType.Mythic] = 10;
        haveTagRatioPerCoreType[CoreType.Elemental] = 10;

        //18 tags for Duo
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(1, 0, 55, 0, 55)); //Archipelago
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(2, 0, 0, 0, 75)); //Tallmountain Falls
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(3, 0, 75, 0, 0)); //Deep Sea
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(4, 55, 0, 0, 55)); //Redrock Mesas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(5, 0, 0, 0, 65)); //Mega Volcanoes
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(6, 75, 0, 0, 0)); //Pillars of Flame
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(7, 0, 0, 55, 55)); //Karsts
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(8, 0, 0, 0, 60)); //Hidden Caves
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(9, 0, 0, 75, 0)); //Floating Lands
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(10, 55, 55, 0, 0)); //Ghostlight Swamp
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(11, 0, 65, 0, 0)); //Boiling Seas
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(12, 65, 0, 0, 0)); //Flametouched Oasis
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(13, 0, 55, 55, 0)); //White Frost
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(14, 0, 50, 0, 0)); //Monsoon
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(15, 0, 0, 65, 0)); //Frozen Gale
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(16, 55, 0, 55, 0)); //Anticyclonic Storm
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(17, 60, 0, 0, 0)); //Conflagration
        planetTagsPerBloodline[
            1 /*Bloodline.Duo*/
        ].push(PlanetTag(18, 0, 0, 60, 0)); //Hurricane

        //28 tags for Tri
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(19, 35, 35, 0, 35)); //Rainforest
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(20, 0, 0, 0, 55)); //Jungle Mountains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(21, 0, 55, 0, 0)); //Tallest Trees
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(22, 55, 0, 0, 0)); //Steamwoods
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(23, 0, 40, 0, 40)); //Alpine
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(24, 40, 0, 0, 40)); //Sandy Jungle
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(25, 40, 40, 0, 0)); //Mangrove
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(26, 0, 35, 35, 35)); //Tundra
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(27, 0, 0, 0, 40)); //Snow-capped Peaks
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(28, 0, 40, 0, 0)); //Frozen Lakes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(29, 0, 0, 55, 0)); //Taiga
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(30, 0, 35, 0, 35)); //Hibernia
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(31, 0, 0, 40, 40)); //Prairie
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(32, 0, 40, 40, 0)); //Hailstorm
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(33, 35, 0, 35, 35)); //Wasteland
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(34, 0, 0, 0, 40)); //Sheerstone Spires
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(35, 40, 0, 0, 0)); //Lava Fields
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(36, 0, 0, 40, 0)); //Howling Gales
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(37, 35, 0, 0, 35)); //Dunes
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(38, 0, 0, 35, 35)); //Barren Valleys
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(39, 40, 0, 40, 0)); //Thunder Plains
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(40, 35, 35, 35, 0)); //Salt Marsh
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(41, 0, 40, 0, 0)); //Coral Reef
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(42, 40, 0, 0, 0)); //Fire Swamp
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(43, 0, 0, 40, 0)); //Windswept Heath
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(44, 35, 35, 0, 0)); //Beachside Mire
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(45, 0, 35, 35, 0)); //Gentlesnow Bog
        planetTagsPerBloodline[
            2 /*Bloodline.Tri*/
        ].push(PlanetTag(46, 35, 0, 35, 0)); //Stormy Night Swamp

        //16 tags for Mix
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(47, 35, 35, 35, 35)); //Utopia
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(48, 30, 30, 30, 30)); //Garden
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(49, 0, 0, 0, 35)); //Mountain
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(50, 0, 35, 0, 0)); //Ocean
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(51, 35, 0, 0, 0)); //Wildfire
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(52, 0, 0, 35, 0)); //Cloud
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(53, 0, 30, 0, 30)); //Forest
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(54, 30, 0, 0, 30)); //Desert
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(55, 0, 0, 30, 30)); //Hill
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(56, 30, 30, 0, 0)); //Swamp
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(57, 0, 30, 30, 0)); //Snow
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(58, 30, 0, 30, 0)); //Plains
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(59, 0, 0, 0, 30)); //Dryland
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(60, 0, 30, 0, 0)); //Marsh
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(61, 30, 0, 0, 0)); //Drought
        planetTagsPerBloodline[
            3 /*Bloodline.Mix*/
        ].push(PlanetTag(62, 0, 0, 30, 0)); //Storm
    }

    function _getBloodline(CoreType coreType, uint256 randomBaseValue)
        internal
        view
        returns (uint256)
    {
        uint256 picked = 3; //Bloodline.Mix;

        uint256 baseValue = 0;
        for (
            uint256 idx = 0; /*Bloodline.Pure*/
            idx <= 3; /*Bloodline.Mix*/
            idx++
        ) {
            // from Pure to Mix
            baseValue += bloodlineRatioPerCoreType[coreType][idx];
            if (_randomRangeByBaseValue(randomBaseValue, 1, 100) <= baseValue) {
                picked = idx;
                break;
            }
        }

        return picked;
    }

    function _getPlanetTag(
        CoreType coreType,
        uint256 bloodline,
        uint256[2] memory randomBaseValues
    ) internal view returns (PlanetTag memory) {
        PlanetTag memory planetTag;
        //exclude if it is pure
        if (
            bloodline != 0 && /*Bloodline.Pure*/
            //according to ratio
            haveTagRatioPerCoreType[coreType] >=
            _randomRangeByBaseValue(randomBaseValues[0], 1, 100)
        ) {
            //random pick a tag from pool
            planetTag = planetTagsPerBloodline[bloodline][
                _randomByBaseValue(
                    randomBaseValues[1],
                    planetTagsPerBloodline[bloodline].length
                )
            ];
        }
        return planetTag;
    }

    function _getElementOrders(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[4] memory randomBaseValues
    ) internal pure returns (uint256[] memory) {
        uint256[4] memory orders;
        uint256[] memory results = new uint256[](1 + uint256(bloodline));
        uint256 pickedIndex;

        //have not any tag
        if (planetTag.id == 0) {
            //dominant element index
            pickedIndex = _randomByBaseValue(randomBaseValues[0], 4);
        }
        //have any tag
        else {
            uint256 possibleElementSize;
            if (planetTag.fire > 0) {
                orders[possibleElementSize++] = 0; //ElementType.Fire
            }
            if (planetTag.water > 0) {
                orders[possibleElementSize++] = 1; //ElementType.Water
            }
            if (planetTag.air > 0) {
                orders[possibleElementSize++] = 2; //ElementType.Air
            }
            if (planetTag.earth > 0) {
                orders[possibleElementSize++] = 3; //ElementType.Earth
            }

            //dominant element index (random pick from possibleElements)
            pickedIndex = orders[
                _randomByBaseValue(randomBaseValues[0], possibleElementSize)
            ];
        }

        orders[0] = 0; //ElementType.Fire
        orders[1] = 1; //ElementType.Water
        orders[2] = 2; //ElementType.Air
        orders[3] = 3; //ElementType.Earth

        //move the specified element to 1st place
        (orders[0], orders[pickedIndex]) = (orders[pickedIndex], orders[0]);
        //assign the value as result
        results[0] = orders[0];

        //process the remaining elements
        for (uint256 i = 1; i <= bloodline; i++) {
            //random pick the index from remaining elements
            pickedIndex = i + _randomByBaseValue(randomBaseValues[i], 4 - i);
            //move the specified element to {i}nd place
            (orders[i], orders[pickedIndex]) = (orders[pickedIndex], orders[i]);
            //assign the value as result
            results[i] = orders[i];
        }

        return results;
    }

    function _getMaxBetweenValueAndPlanetTag(
        uint256 value,
        uint256 elementType,
        PlanetTag memory planetTag
    ) internal pure returns (uint256) {
        if (planetTag.id > 0) {
            if (
                elementType == 0 /*ElementType.Fire*/
            ) {
                return Math.max(value, planetTag.fire);
            } else if (
                elementType == 1 /*ElementType.Water*/
            ) {
                return Math.max(value, planetTag.water);
            } else if (
                elementType == 2 /*ElementType.Air*/
            ) {
                return Math.max(value, planetTag.air);
            } else if (
                elementType == 3 /*ElementType.Earth*/
            ) {
                return Math.max(value, planetTag.earth);
            }
        }

        return value;
    }

    function _getElementValues(
        uint256 bloodline,
        PlanetTag memory planetTag,
        uint256[] memory elementOrders,
        uint256[3] memory randomBaseValues
    ) internal pure returns (uint256[4] memory) {
        require(elementOrders.length == bloodline + 1, "invalid elementOrders");

        uint256[4] memory values;

        if (
            bloodline == 0 /*Bloodline.Pure*/
        ) {
            values[uint256(elementOrders[0])] = 100;
        } else if (
            bloodline == 1 /*Bloodline.Duo*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 50, 59),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] =
                100 -
                values[uint256(elementOrders[0])];
        } else if (
            bloodline == 2 /*Bloodline.Tri*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 33, 43),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                23,
                Math.min(43, 95 - values[uint256(elementOrders[0])])
            );
            values[uint256(elementOrders[2])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])];
        } else if (
            bloodline == 3 /*Bloodline.Mix*/
        ) {
            values[uint256(elementOrders[0])] = _getMaxBetweenValueAndPlanetTag(
                _randomRangeByBaseValue(randomBaseValues[0], 25, 35),
                elementOrders[0],
                planetTag
            );
            values[uint256(elementOrders[1])] = _randomRangeByBaseValue(
                randomBaseValues[1],
                20,
                34
            );
            values[uint256(elementOrders[2])] = _randomRangeByBaseValue(
                randomBaseValues[2],
                20,
                Math.min(
                    34,
                    95 -
                        values[uint256(elementOrders[0])] -
                        values[uint256(elementOrders[1])]
                )
            );
            values[uint256(elementOrders[3])] =
                100 -
                values[uint256(elementOrders[0])] -
                values[uint256(elementOrders[1])] -
                values[uint256(elementOrders[2])];
        }

        return values;
    }

    function _generateGeneId(CoreType coreType) internal returns (uint256) {
        uint256 bloodline = _getBloodline(coreType, _getRandomBaseValue());
        PlanetTag memory planetTag = _getPlanetTag(
            coreType,
            bloodline,
            [_getRandomBaseValue(), _getRandomBaseValue()]
        );
        uint256[] memory elementOrders = _getElementOrders(
            bloodline,
            planetTag,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[4] memory elementValues = _getElementValues(
            bloodline,
            planetTag,
            elementOrders,
            [
                _getRandomBaseValue(),
                _getRandomBaseValue(),
                _getRandomBaseValue()
            ]
        );
        uint256[] memory attributes = new uint256[](18);
        attributes[0] = elementValues[0]; //element: fire
        attributes[1] = elementValues[1]; //element: water
        attributes[2] = elementValues[2]; //element: air
        attributes[3] = elementValues[3]; //element: earth
        attributes[4] = planetTag.id; //primeval legacy tag
        attributes[5] = _randomRange(0, 1); //body: sex
        attributes[6] = _randomRange(0, 11); //body: weapon
        attributes[7] = _randomRange(0, 3); //body: body props
        attributes[8] = _randomRange(0, 5); //body: head props
        attributes[9] = _randomRange(0, 23); //skill: cskill1
        attributes[10] = (attributes[9] + _randomRange(1, 23)) % 24; //skill: cskill2
        attributes[11] = (attributes[10] + _randomRange(1, 22)) % 24; //skill: cskill3
        if (attributes[11] == attributes[9]) {
            attributes[11] = (attributes[11] + 1) % 24;
        }
        attributes[12] = _randomRange(0, 31); //skill: pskill1
        attributes[13] = (attributes[12] + _randomRange(1, 31)) % 32; //skill: pskill2
        attributes[14] = _randomRange(0, 2); //class
        attributes[15] = _randomRange(0, 31); //special gene
        // attributes[16] = 0; //generation 1st digit
        // attributes[17] = 0; //generation 2nd digit
        uint256 geneId = _convertToGeneId(attributes);
        emit GenerateGeneId(bloodline, elementOrders, attributes, geneId);
        return geneId;
    }

    function _convertToGeneId(uint256[] memory attributes)
        internal
        pure
        returns (uint256)
    {
        uint256 geneId = 0;
        for (uint256 id = 0; id < attributes.length; id++) {
            geneId += attributes[id] << (8 * id);
        }

        return geneId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IApeironPlanet is IERC721 {
    struct PlanetData {
        uint256 gene;
        uint256 baseAge;
        uint256 evolve;
        uint256 breedCount;
        uint256 breedCountMax;
        uint256 createTime; // before hatch
        uint256 bornTime; // after hatch
        uint256 lastBreedTime;
        uint256[] relicsTokenIDs;
        uint256[] parents; //parent token ids
        uint256[] children; //children token ids
    }

    function safeMint(
        uint256 gene,
        // uint256 parentA,
        // uint256 parentB,
        uint256[] calldata parents,
        address to,
        uint256 tokenId
    ) external;

    function updatePlanetData(
        uint256 tokenId,
        uint256 gene,
        //  Add planet baseage, by absorb
        uint256 addAge,
        // evolve the planet.
        uint256 addEvolve,
        // add breed count max
        uint256 addBreedCountMax,
        // update born time to now
        bool setBornTime
    ) external;

    function getPlanetData(uint256 tokenId)
        external
        view
        returns (
            PlanetData memory, //planetData
            bool //isAlive
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBreedPlanetData {
    function updatePlanetNextBornMap(uint256 planetId, uint256 nextBornTime)
        external;

    function getPlanetNextBornTime(uint256 planetId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Random {
    uint256 randomNonce;

    function _updateRandomNonce(uint256 _num) internal {
        randomNonce = _num;
    }
    
    function _getRandomNonce() internal view returns (uint256) {
        return randomNonce;
    }

    function __getRandomBaseValue(uint256 _nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce
        )));
    }

    function _getRandomBaseValue() internal returns (uint256) {
        randomNonce++;
        return __getRandomBaseValue(randomNonce);
    }

    function __random(uint256 _nonce, uint256 _modulus) internal view returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return __getRandomBaseValue(_nonce) % _modulus;
    }

    function _random(uint256 _modulus) internal returns (uint256) {
        randomNonce++;
        return __random(randomNonce, _modulus);
    }

    function _randomByBaseValue(uint256 _baseValue, uint256 _modulus) internal pure returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return _baseValue % _modulus;
    }

    function __randomRange(uint256 _nonce, uint256 _start, uint256 _end) internal view returns (uint256) {
        if (_end > _start) {
            return _start + __random(_nonce, _end + 1 - _start);
        }
        else {
            return _end + __random(_nonce, _start + 1 - _end);
        }
    }

    function _randomRange(uint256 _start, uint256 _end) internal returns (uint256) {
        randomNonce++;
        return __randomRange(randomNonce, _start, _end);
    }

    function _randomRangeByBaseValue(uint256 _baseValue, uint256 _start, uint256 _end) internal pure returns (uint256) {
        if (_end > _start) {
            return _start + _randomByBaseValue(_baseValue, _end + 1 - _start);
        }
        else {
            return _end + _randomByBaseValue(_baseValue, _start + 1 - _end);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}