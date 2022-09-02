// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../BreedPlanet.sol";

contract MockBreedPlanet is BreedPlanet {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() BreedPlanet() {}

    // constructor() BreedPlanet() initializer {}

    // function initialize() external override initializer {
    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    // }

    function getCurrentPlanetId() external view returns (uint256) {
        return currentPlanetId;
    }

    function breed(
        uint256 planetAId,
        uint256 planetBId,
        bool shouldUseMiniBlackhole
    ) external {
        _breed(msg.sender, planetAId, planetBId, shouldUseMiniBlackhole, false);
    }

    function requestRandomWords() internal virtual override returns (uint256) {
        // for mock test case
        return 999;
    }

    function rngCallBack(uint256 requestId) external {
        // for mock test case
        return _rngCallBack(requestId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./BreedPlanetBase.sol";
import "./PlanetAttributeManager.sol";
import "./interfaces/IBlacklist.sol";
import "./utils/ChainlinkRng.sol";

contract BreedPlanet is BreedPlanetBase, ChainlinkRng {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    struct BreedStruct {
        address userAddress;
        uint256 planetAId;
        uint256 planetBId;
        bool shouldUseMiniBlackhole;
        bool isDone; // for client check breed is finish or not
        uint256 planetId;
    }

    PlanetAttributeManager public planetAttributeManagerContract;
    IBlacklist public blacklistContract;
    ERC1155BurnableUpgradeable public apeironGodiverseCollection;
    IERC20Upgradeable public aprsToken;
    IERC20Upgradeable public animaToken;

    // bool public isPrimevalActive = true;
    bool public isPrimevalActive;
    uint256 public aprsPrice;
    mapping(uint256 => mapping(uint256 => uint256)) public animaPrices; // bloodline => breedcount => cost
    mapping(uint256 => mapping(uint256 => uint256))
        public apeironGodiverseCollectionNumbers; // bloodline => breedcount => cost
    mapping(uint256 => mapping(uint256 => uint256))
        public primevalApeironGodiverseCollectionNumbers; // bloodline => breedcount => cost, only use for primeval planet id <= 4585

    // uint256 public currentPlanetId = 4585; // production id
    // uint256 public normalBreedBaseInterval = 14 * 3600 * 24;
    // uint256 public bornBaseInterval = 7 * 3600 * 24;
    // uint256 public additionBornBaseInterval = 14 * 3600 * 24;
    // uint256 public miniBlackholeTokenId = 1; // apeironGodiverseCollection id
    uint256 public currentPlanetId; // production id
    uint256 public normalBreedBaseInterval;
    uint256 public bornBaseInterval;
    uint256 public additionBornBaseInterval;
    uint256 public miniBlackholeTokenId; // apeironGodiverseCollection id

    mapping(uint256 => BreedStruct) public BreedStructMap; // uint256: Chainlink requestId

    event RequestBreed(uint256 requestId);
    event BreedSuccess(uint256 indexed _tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() BreedPlanetBase() ChainlinkRng() initializer {}

    function initialize() external virtual initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        isPrimevalActive = true;
        currentPlanetId = 4585; // production id
        normalBreedBaseInterval = 14 * 3600 * 24;
        bornBaseInterval = 7 * 3600 * 24;
        additionBornBaseInterval = 14 * 3600 * 24;
        miniBlackholeTokenId = 1; // apeironGodiverseCollection id
    }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function updateContractSetting(
        address _nftAddress,
        address _breedAddress,
        address _blacklistAddress,
        address _apeironGodiverseCollectionAddress,
        address _aprsTokenAddress,
        address _animaTokenAddress,
        address _planetAttributeManagerContract,
        ChainlinkStruct memory _chainlinkStruct
    ) external onlyOwner {
        _updateBaseContractSetting(_nftAddress, _breedAddress);

        require(
            _blacklistAddress.isContract(),
            "_blacklistAddress must be a contract"
        );
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
        require(
            _planetAttributeManagerContract.isContract(),
            "_planetAttributeManagerContract must be a contract"
        );

        blacklistContract = IBlacklist(_blacklistAddress);
        apeironGodiverseCollection = ERC1155BurnableUpgradeable(
            _apeironGodiverseCollectionAddress
        );
        aprsToken = IERC20Upgradeable(_aprsTokenAddress);
        animaToken = IERC20Upgradeable(_animaTokenAddress);
        planetAttributeManagerContract = PlanetAttributeManager(
            _planetAttributeManagerContract
        );

        // update chainlink
        updateChainlinkStruct(_chainlinkStruct);
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
    function setCurrentPlanetId(uint256 _currentPlanetId) external onlyAdmin {
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

        // require(
        //     planetAttributeManagerContract.breed(
        //         userAddress,
        //         planetAId,
        //         planetBId,
        //         shouldUseMiniBlockhole,
        //         isDryRun
        //     ),
        //     "planetAttributeManagerContract.breed is not pass"
        // );

        // start breed
        if (!isDryRun) {
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

    /// @notice set Primeval Apeiron Godiverse Collection Number (mini blackhold)
    /// @param _primevalApeironGodiverseCollectionNumbers first[] is bloodline (must be 4), second[] is breed count price (must be 5)
    function setPrimevalApeironGodiverseCollectionNumber(
        uint256[][] memory _primevalApeironGodiverseCollectionNumbers
    ) public onlyOwner {
        require(
            _primevalApeironGodiverseCollectionNumbers.length == 4,
            "Number length are wrong"
        );

        for (
            uint256 i = 0;
            i < _primevalApeironGodiverseCollectionNumbers.length;
            i++
        ) {
            require(
                _primevalApeironGodiverseCollectionNumbers[i].length == 5,
                "Number length are wrong"
            );
            for (
                uint256 j = 0;
                j < _primevalApeironGodiverseCollectionNumbers[i].length;
                j++
            ) {
                primevalApeironGodiverseCollectionNumbers[i][
                    j
                ] = _primevalApeironGodiverseCollectionNumbers[i][j];
            }
        }
    }

    function getApeironGodiverseCollection()
        external
        returns (ERC1155BurnableUpgradeable)
    {
        return apeironGodiverseCollection;
    }

    function getAprsToken() external returns (IERC20Upgradeable) {
        return aprsToken;
    }

    function getAnimaToken() external returns (IERC20Upgradeable) {
        return animaToken;
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
        IERC20Upgradeable(tokenAddress).safeTransfer(wallet, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Burnable_init_unchained();
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IApeironPlanet.sol";
import "./interfaces/IBreedPlanetData.sol";

import "./planets/contracts/utils/AccessProtectedUpgradable.sol";
import "./planets/contracts/utils/Random.sol";

contract BreedPlanetBase is
    Random,
    Initializable,
    UUPSUpgradeable,
    AccessProtectedUpgradable
{
    using AddressUpgradeable for address;

    IApeironPlanet public planetContract;
    IBreedPlanetData public breedPlanetDataContract;

    struct ElementStruct {
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
        uint256 domainValue;
        uint256 domainIndex; // 1: fire, 2: water, 3: air, 4: earth
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    // /// @dev Initialize the contract
    // function initialize() external initializer {
    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    // }

    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    function _updateBaseContractSetting(
        address _nftAddress,
        address _breedAddress
    ) internal onlyOwner {
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
pragma solidity 0.8.12;

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./BreedPlanetBase.sol";
import "./BreedPlanet.sol";

contract PlanetAttributeManager is BreedPlanetBase {
    struct PlanetTag {
        uint256 id;
        uint256 fire;
        uint256 water;
        uint256 air;
        uint256 earth;
    }

    using SafeERC20Upgradeable for IERC20Upgradeable;

    BreedPlanet public breedContract;

    mapping(uint256 => PlanetTag[]) planetTagsPerBloodline;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() BreedPlanetBase() initializer {}

    function initialize() external virtual initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setUpContract(address _planetAddress, address _breedAddress)
        external
        onlyOwner
    {
        planetContract = IApeironPlanet(_planetAddress);
        breedContract = BreedPlanet(_breedAddress);
    }

    function setUpBloodline(uint256 bloodline, PlanetTag memory planetTagArray)
        external
        onlyOwner
    {
        planetTagsPerBloodline[bloodline].push(planetTagArray);
    }

    /// @notice planet breed function
    /// @param userAddress planet user address
    /// @param planetAId planetAId
    /// @param planetBId planetBId
    /// @param shouldUseMiniBlockhole should Use Mini Blockhole
    /// @param isDryRun is dry run
    function breed(
        address userAddress,
        uint256 planetAId,
        uint256 planetBId,
        bool shouldUseMiniBlockhole,
        bool isDryRun // if isDryRun, not run mint, transfer and burn token
    ) external virtual onlyAdmin returns (bool) {
        // _checkAndAddBreedCountMax(planetAId);
        // _checkAndAddBreedCountMax(planetBId);

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
            _aprsPrice = breedContract.aprsPrice();
            _animaPrice =
                breedContract.animaPrices(
                    planetABloodline,
                    _getPlanetData(planetAId).breedCount
                ) +
                breedContract.animaPrices(
                    planetBBloodline,
                    _getPlanetData(planetBId).breedCount
                );
        }
        if (!isDryRun && _aprsPrice > 0) {
            breedContract.getAprsToken().safeTransferFrom(
                userAddress,
                address(breedContract),
                _aprsPrice
            );
        }
        if (!isDryRun && _animaPrice > 0) {
            breedContract.getAnimaToken().safeTransferFrom(
                userAddress,
                address(breedContract),
                _animaPrice
            );
        }

        // burn apeironGodiverseCollection miniBlackhole
        if (shouldUseMiniBlockhole) {
            uint256 targetApeironGodiverseCollectionNumber = 0;
            if (planetAId <= 4585) {
                targetApeironGodiverseCollectionNumber += breedContract
                    .primevalApeironGodiverseCollectionNumbers(
                        planetABloodline,
                        _getPlanetData(planetAId).breedCount
                    );
            } else {
                targetApeironGodiverseCollectionNumber += breedContract
                    .apeironGodiverseCollectionNumbers(
                        planetABloodline,
                        _getPlanetData(planetAId).breedCount
                    );
            }

            if (planetBId <= 4585) {
                targetApeironGodiverseCollectionNumber += breedContract
                    .primevalApeironGodiverseCollectionNumbers(
                        planetBBloodline,
                        _getPlanetData(planetBId).breedCount
                    );
            } else {
                targetApeironGodiverseCollectionNumber += breedContract
                    .apeironGodiverseCollectionNumbers(
                        planetBBloodline,
                        _getPlanetData(planetBId).breedCount
                    );
            }

            if (!isDryRun) {
                breedContract.getApeironGodiverseCollection().burn(
                    userAddress,
                    breedContract.miniBlackholeTokenId(),
                    targetApeironGodiverseCollectionNumber
                );
            }
        }

        // start breed
        if (!isDryRun) {
            uint256[] memory parents = new uint256[](2);
            parents[0] = planetAId;
            parents[1] = planetBId;
            breedContract.setCurrentPlanetId(
                breedContract.currentPlanetId() + 1
            );

            // genid for element
            uint256 geneId = _convertToGeneId(
                _getUpdateAttributesOnBreed(planetAId, planetBId)
            );
            planetContract.safeMint(
                geneId,
                parents,
                userAddress,
                breedContract.currentPlanetId()
            );

            // // 7 days cooldown for the born
            // // +14 days if grandparent are same
            // bool isGrandparentRepeat = false;
            // (isGrandparentRepeat, ) = _checkIsGrandparentRepeat(
            //     planetAId,
            //     planetBId
            // );

            // uint256 bornInterval;
            // if (isGrandparentRepeat) {
            //     bornInterval =
            //         breedContract.bornBaseInterval() +
            //         breedContract.additionBornBaseInterval();
            // } else {
            //     bornInterval = breedContract.bornBaseInterval();
            // }
            // breedPlanetDataContract.updatePlanetNextBornMap(
            //     breedContract.currentPlanetId(),
            //     block.timestamp + bornInterval
            // );

            // emit BreedSuccess(currentPlanetId);
        }

        return true;
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
        // planet ownership
        require(
            planetContract.ownerOf(planetAId) == userAddress &&
                planetContract.ownerOf(planetBId) == userAddress,
            "Planet is not owned"
        );

        // planet is blacklisted
        require(
            !breedContract.blacklistContract().blacklistedNFT(
                userAddress,
                address(planetContract),
                planetAId
            ) &&
                !breedContract.blacklistContract().blacklistedNFT(
                    userAddress,
                    address(planetContract),
                    planetBId
                ),
            "Planet is blacklisted"
        );

        // planet data
        IApeironPlanet.PlanetData memory planetAData = _getPlanetData(
            planetAId
        );
        IApeironPlanet.PlanetData memory planetBData = _getPlanetData(
            planetBId
        );
        require(
            planetAData.lastBreedTime +
                breedContract.normalBreedBaseInterval() <
                block.timestamp &&
                planetBData.lastBreedTime +
                    breedContract.normalBreedBaseInterval() <
                block.timestamp &&
                planetAData.breedCount + 1 <= planetAData.breedCountMax &&
                planetBData.breedCount + 1 <= planetBData.breedCountMax &&
                !_parentIsRepeated(planetAId, planetBId),
            "Planet is not match breed require"
        );

        // apeironGodiverseCollection nft
        // require no parent
        if (breedContract.isPrimevalActive()) {
            require(
                !_hasParent(planetAId) &&
                    !_hasParent(planetBId) &&
                    shouldUseMiniBlockhole,
                "Does not match Primeval require"
            );
        }

        return true;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBlacklist {
    function blacklistedNFT(
        address _owner,
        address _token,
        uint256 _id
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./VRFConsumerBaseV2.sol";
import "../planets/contracts/utils/Random.sol";

// contract ChainlinkRng is VRFConsumerBaseV2, Random, Ownable {
contract ChainlinkRng is VRFConsumerBaseV2, Random, OwnableUpgradeable {
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
    // uint32 callbackGasLimit = 2000000;
    uint32 callbackGasLimit;

    // The default is 3, but you can set this higher.
    // uint16 requestConfirmations = 3;
    uint16 requestConfirmations;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    // uint32 numWords = 2;
    uint32 numWords;

    // Storage parameters
    uint256[] public s_randomWords;
    uint64 public s_subscriptionId;

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() VRFConsumerBaseV2() initializer {}

    // function initialize() external virtual initializer {
    //     __Ownable_init();
    // }

    function updateChainlinkStruct(ChainlinkStruct memory _chainlinkStruct)
        internal
    {
        _setVrfCoordinator(_chainlinkStruct.vrfCoordinator);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
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

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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
    // address of VRFCoordinator contract
    address private vrfCoordinator;

    constructor() {}

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function _setVrfCoordinator(address _vrfCoordinator) internal {
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
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}