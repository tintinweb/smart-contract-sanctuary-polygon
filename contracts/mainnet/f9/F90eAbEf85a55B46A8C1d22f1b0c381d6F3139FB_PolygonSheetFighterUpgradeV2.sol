// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ISheetFighterToken.sol";
import "IShredsToken.sol";
import "PolygonVRFConsumerBaseV2.sol";
import "VRFCoordinatorV2Interface.sol";

/// @title  Contract allowing for upgrading the attributes of the non-fungible in-game utility token for the game Sheet Figher
/// @author Overlord Paper Co
/// @notice This defines the methods for upgrading the attributes of the non-fungible in-game utility token for the game Sheet Figher
contract PolygonSheetFighterUpgradeV2 is Ownable, PolygonVRFConsumerBaseV2 {

    /// @dev state of a token within the upgrade process
    enum TokenUpgradeState {
        NO_ATTRIBUTE,
        ROLLING_ATTRIBUTE,
        HAS_ATTRIBUTE,
        ROLLING_UPGRADE
    }

    enum AttributeType {
        NOT_SET,
        HP,
        ATTACK,
        DEFENSE,
        CRITICAL,
        HEAL
    }

    uint256 public constant ATTRIBUTE_ROLL_PRICE = 1e18; // 2 $SHREDS
    uint8 public constant DAILY_UPGRADE_LIMIT = 5;
    uint8 public constant ATTRIBUTE_ROLLS_LIMIT = 3;

    address public sheetFighterToken;
    address public cellToken; // legacy: keep for upgrade-compatible storage layout
    bytes32 public keyHash; 
    uint256 public vrfFee; // legacy: keep for upgrade-compatible storage layout

    mapping(uint256 => uint256) public requestIdToTokenId; // requestId -> tokenId
    mapping(uint256 => uint256) public requestIdToUpgradeRisk; // requestId -> upgrade risk
    mapping(uint256 => uint256) public tokenIdToAttributeRequestId; // tokenId -> requestId
    mapping(uint256 => uint256) public tokenIdToUpgradeRequestId; // tokenId -> requestId
    mapping(uint256 => TokenUpgradeState) public tokenIdToTokenUpgradeState; // tokenId -> token upgrade state
    mapping(uint256 => AttributeType) public tokenIdToAttributeTypeRolled; // tokenId -> AttributeType
    mapping(uint256 => uint8) public tokenIdToAttributeRollCount; // tokenId => number of attribute rolls
    mapping(uint256 => uint256[DAILY_UPGRADE_LIMIT]) public tokenIdToLastUpgradeTimes; // tokenId => timestamps of last upgrades (most recent at 0)

    /// @dev Chainlink VRF v2
    uint64 subscriptionId;
    uint32 callbackGasLimit; 
    uint32 constant DEFAULT_CB_GAS_LIMIT = 100000;

    address public shredsToken;

    event AttributeRolling(uint256 indexed tokenId);
    event AttributeRolled(uint256 indexed tokenId, AttributeType indexed attribute);
    event UpgradeRolling(uint256 indexed tokenId);
    event UpgradeRolled(uint256 indexed tokenId, uint8 indexed upgradedStat);

    /// @dev Initiatilize state for proxy contract
    /// @dev Only use if deploying NEW CONTRACT. 
    /// For SETUP after contract upgrade, use functions from section below
    /// @param _sheetFighterToken Address of the PolygonSheetFighterToken contract
    /// @param _shredsToken Address of the ShredsToken contract
    /// @param _vrfCoordinator Address of the Chainlink VRF coordinator
    /// @param _keyHash Chainlink VRF keyhash
    /// @param _subscriptionId Chainlink VRF subscription ID 
    function initialize(
        address _sheetFighterToken,
        address _shredsToken,
        address _vrfCoordinator,         
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) external onlyOwner {
        sheetFighterToken = _sheetFighterToken;
        shredsToken = _shredsToken;
        keyHash = _keyHash;
        vrfCoordinator = _vrfCoordinator;
        subscriptionId = _subscriptionId;
        callbackGasLimit = DEFAULT_CB_GAS_LIMIT;
    }

    /// ------------ INITIALIZATION AFTER UPGRADE FROM V1 ------------- //
    /**
        @dev since we now use SHREDS instead of CELL, we need to initialize
        - shredsToken

         @dev since we upgrade VRF from V1 to V2, we need to initialize 
        - coordinator
        - callbackGasLimit
        - subscriptionId
     */

     function setShredsToken(address _shredsToken) external onlyOwner {
         shredsToken = _shredsToken;
     }
    
    /// @notice sets vrf coordinator 
    /// @param _vrfCoordinator address of VRFCoordinator contract
    function setVrfCoordinator(address _vrfCoordinator) external onlyOwner {
        vrfCoordinator = _vrfCoordinator;
    }

    /// @notice sets vrf keyhash
    /// @param _keyHash keyHash for VRF
    function setVrfKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /// @notice Set gas limit for chainlink vrf v2 callbacks (battle setup / battle playout)
    /// @param _callbackGasLimit gas limit for VRF v2 callbacks
    function setVrfCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    /// @notice Set subscription id for chainlink vrf v2
    /// @param _subscriptionId chainlink VRF v2 subscription id
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /// ------------   ---------------------   ------------- //

    /// @notice Initiate roll to select an attribute to upgrade
    /// @dev Initiates a chainlink VRF request
    /// @param tokenId SheetFighterToken id
    function rollForAttribute(uint256 tokenId) external {
        require(
            ISheetFighterToken(sheetFighterToken).ownerOf(tokenId) == msg.sender,
            "You don't own this Sheet!"
        );

        TokenUpgradeState tokenState = tokenIdToTokenUpgradeState[tokenId];
        require(
            tokenState != TokenUpgradeState.ROLLING_ATTRIBUTE &&
            tokenState != TokenUpgradeState.ROLLING_UPGRADE,
            "Currently rolling"
        );

        require(_canUpgradeGivenDailyLimit(tokenId),
            "daily maximum of upgrades reached"
        );

        require(tokenIdToAttributeRollCount[tokenId] < ATTRIBUTE_ROLLS_LIMIT, "maximum attribute rolls reached!");
        
        uint256 requestId = _requestRandomness();

        requestIdToTokenId[requestId] = tokenId;
        tokenIdToAttributeRequestId[tokenId] = requestId;
        tokenIdToAttributeRollCount[tokenId] += 1;
        tokenIdToTokenUpgradeState[tokenId] = TokenUpgradeState.ROLLING_ATTRIBUTE;

        // Burn $SHREDS
        IShredsToken(shredsToken).burnFrom(msg.sender, ATTRIBUTE_ROLL_PRICE);

        emit AttributeRolling(tokenId);
    }

    /// @notice Initiate roll to upgrade the Sheet's stat
    /// @notice Requires that rollForAttribute and subsequent VRF callback were executed successfully
    /// @dev Initiates a chainlink VRF request
    /// @param tokenId SheetFighterToken id
    /// @param riskLevel The risk level for the upgrade represented as a number in the range [0, 3] inclusive
    function rollForUpgrade(uint256 tokenId, uint32 riskLevel) external {
        require(
            ISheetFighterToken(sheetFighterToken).ownerOf(tokenId) == msg.sender, 
            "You don't own this Sheet!"
        );

        TokenUpgradeState tokenState = tokenIdToTokenUpgradeState[tokenId];
        require(
            tokenState == TokenUpgradeState.HAS_ATTRIBUTE, 
            "You need to Roll for attribute first"
        ); 
        
        // Roll for upgrade amount
        uint256 requestId = _requestRandomness();

        // Update state
        requestIdToTokenId[requestId] = tokenId;
        requestIdToUpgradeRisk[requestId] = riskLevel;
        tokenIdToUpgradeRequestId[tokenId] = requestId;
        tokenIdToTokenUpgradeState[tokenId] = TokenUpgradeState.ROLLING_UPGRADE;

        // Get statLevel
        (uint8 HP, uint8 critical, uint8 heal, uint8 defense, uint8 attack,,) = ISheetFighterToken(sheetFighterToken).tokenStats(tokenId);
        AttributeType attributeRolled = tokenIdToAttributeTypeRolled[tokenId];

        uint8 statLevel;
        if(attributeRolled == AttributeType.HP) {
            statLevel = HP;
        } else if(attributeRolled == AttributeType.CRITICAL) {
            statLevel = critical;
        } else if(attributeRolled == AttributeType.HEAL) {
            statLevel = heal;
        } else if(attributeRolled == AttributeType.DEFENSE) {
            statLevel = defense;
        } else if(attributeRolled == AttributeType.ATTACK) {
            statLevel = attack;
        } 
        
        // Burn shreds
        IShredsToken(shredsToken).burnFrom(msg.sender, getPriceForStatLevel(statLevel, riskLevel));

        emit UpgradeRolling(tokenId);
    }

    /// @notice Returns # of upgrades remaining for current 24-hour period for Sheet
    /// @param tokenId SheetFighterToken id
    /// @return uint256 Number of upgrades remaning for current 24-hour period
    function dailyUpgradesRemaining(uint256 tokenId) external view returns(uint256) {
        // Timestamps are in chronological order from oldest to most recent
        // Iterate from the front (oldest) until one is < 1 day old
        uint256 upgradesRemaining = 0;
        for(uint8 i = 0; i < DAILY_UPGRADE_LIMIT; i++) {
            uint256 timestamp = tokenIdToLastUpgradeTimes[tokenId][i];
            if(timestamp + 1 days < block.timestamp) {
                upgradesRemaining++;
            } else {
                break;
            }
        }
        return upgradesRemaining;
    }

    /// @notice Get the price to upgrade a stat based on its current value and a risk level
    /// @param statLevel The value of the stat being upgraded
    /// @param riskLevel The risk level for the upgrade represented as a number in the range [0, 3] inclusive
    /// @return uint256 The $SHREDS cost to upgrade the stat
    function getPriceForStatLevel(uint8 statLevel, uint256 riskLevel) public pure returns(uint256){
        uint256 cost = _getBasePriceForStatLevel(statLevel);

        if(riskLevel == 0) {
            return cost;
        } else if(riskLevel == 1) {
            return (cost * 15) / 10;
        } else if(riskLevel == 2) {
            return cost * 2;
        } else if(riskLevel == 3) {
            return (cost * 25) / 10;
        } else {
            revert("invalid riskLevel");
        }
    }

    /// @dev Set state for rolled attribute and upgrading state
    /// @dev This function is called as a part of Chainlink's VRF callback
    /// @param requestId Chainlink VRF request id, used to get current update state
    /// @param randomness Random number generated by Chainlink VRF
    function _setRolledAttributeType(uint256 requestId, uint256 randomness) internal {
        uint256 tokenId = requestIdToTokenId[requestId];
        // Increase modulus result by 1 to account for "NOT_SET" type at value 0
        AttributeType attributeRolled = AttributeType(randomness % 5 + 1);
        tokenIdToAttributeTypeRolled[tokenId] = attributeRolled;
        tokenIdToTokenUpgradeState[tokenId] = TokenUpgradeState.HAS_ATTRIBUTE;
        emit AttributeRolled(tokenId, attributeRolled);
    }

    /// @dev Update the Sheet's stat and update contract upgrading state 
    /// @dev This function is called as a part of Chainlink's VRF callback
    /// @param requestId Chainlink VRF request id, used to get current update state
    /// @param randomness Random number generated by Chainlink VRF
    function _updateAttributeForToken(uint256 requestId, uint256 randomness) internal {
        uint256 tokenId = requestIdToTokenId[requestId];

        //get attribute that was previously rolled
        AttributeType attributeRolled = tokenIdToAttributeTypeRolled[tokenId];
        require(attributeRolled != AttributeType.NOT_SET, "Attribute not rolled");
        
        uint256 riskLevel = requestIdToUpgradeRisk[requestId];
        require(0 <= riskLevel && riskLevel <= 3, "Invalid risk level");

        // Get lower and upper bounds
        int256 lowerBound;
        int256 upperBound;
        if(riskLevel == 0) {
            lowerBound = 1;
            upperBound = 1;
        } else if(riskLevel == 1) {
            lowerBound = 0;
            upperBound = 3;
        } else if(riskLevel == 2) {
            lowerBound = -1;
            upperBound = 5;
        } else if(riskLevel == 3) {
            lowerBound = -2;
            upperBound = 7;
        }

        // Get attribute's upgrade delta
        // Type casting must be done in this order to ensure data type conversions that don't result in undefined behavior
        int256 upgradeDelta = _getUpgradeDelta(lowerBound, upperBound, randomness);

        // Get attribute's current stat value
        (uint8 HP, uint8 critical, uint8 heal, uint8 defense, uint8 attack,,) = ISheetFighterToken(sheetFighterToken).tokenStats(tokenId);

        // Upgrade stat
        uint8 upgradedStat;
        if(attributeRolled == AttributeType.HP) {
            upgradedStat = _getUpgradedStat(HP, upgradeDelta);
            ISheetFighterToken(sheetFighterToken).updateStats(tokenId, 0, upgradedStat);
        } else if(attributeRolled == AttributeType.CRITICAL) {
            upgradedStat = _getUpgradedStat(critical, upgradeDelta);
            ISheetFighterToken(sheetFighterToken).updateStats(tokenId, 1, upgradedStat);
        } else if(attributeRolled == AttributeType.HEAL) {
            upgradedStat = _getUpgradedStat(heal, upgradeDelta);
            ISheetFighterToken(sheetFighterToken).updateStats(tokenId, 2, upgradedStat);
        } else if(attributeRolled == AttributeType.DEFENSE) {
            upgradedStat = _getUpgradedStat(defense, upgradeDelta);
            ISheetFighterToken(sheetFighterToken).updateStats(tokenId, 3, upgradedStat);
        } else if(attributeRolled == AttributeType.ATTACK) {
            upgradedStat = _getUpgradedStat(attack, upgradeDelta);
            ISheetFighterToken(sheetFighterToken).updateStats(tokenId, 4, upgradedStat);
        } else {
            revert("No attribute type rolled");
        }

        // Update state
        tokenIdToAttributeTypeRolled[tokenId] = AttributeType.NOT_SET;
        tokenIdToTokenUpgradeState[tokenId] = TokenUpgradeState.NO_ATTRIBUTE;
        tokenIdToAttributeRollCount[tokenId] = 0;
        _updateLastUpgradeTimes(tokenId);
        
        emit UpgradeRolled(tokenId, upgradedStat);
    }

    /// @dev Updates upgrade times for token
    /// @dev Highest index has most recent timestamp
    /// @param tokenId SheetFighterToken id
    function _updateLastUpgradeTimes(uint256 tokenId) internal {
        uint8 lastIndex = DAILY_UPGRADE_LIMIT - 1;
        for (uint8 i = 0; i <= lastIndex - 1; i++) {
            tokenIdToLastUpgradeTimes[tokenId][i] = tokenIdToLastUpgradeTimes[tokenId][i+1];    
        }
        tokenIdToLastUpgradeTimes[tokenId][lastIndex] = block.timestamp;
    } 

    function _requestRandomness() internal returns(uint256){
        /// @dev TODO TBD: move these up if we need them adjustable 
        uint16 requestConfirmations = 3;
        uint32 wordsPerRequest = 1;
        // Roll for opponent moves amount
        return VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            wordsPerRequest
        );
    }

    /**
    * @dev VRFConsumerBase expects its subcontracts to have a method with this
    * @dev signature, and will call it once it has verified the proof
    * @dev associated with the randomness. (It is triggered via a call to
    * @dev rawFulfillRandomness, below.)
    * @param requestId The Id initially returned by requestRandomness
    * @param randomWords the VRF output.
    */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {

        // TODO: Check security implications
        // TODO: Add check that requestId relates to a real request

        TokenUpgradeState tokenState = tokenIdToTokenUpgradeState[requestIdToTokenId[requestId]];
        if(tokenState == TokenUpgradeState.ROLLING_ATTRIBUTE){
            _setRolledAttributeType(requestId, randomWords[0]);
        }
        else if(tokenState == TokenUpgradeState.ROLLING_UPGRADE) {
            _updateAttributeForToken(requestId, randomWords[0]);
        }
    }

    /// @dev Returns bool indicating Sheet can be upgraded given daily upgrade limit
    /// @param tokenId SheetFighterToken id
    /// @return bool True if can be upgrade, false otherwise
    function _canUpgradeGivenDailyLimit(uint256 tokenId) internal view returns(bool) {
        return tokenIdToLastUpgradeTimes[tokenId][0] < block.timestamp - 1 days;
    }

    /// @dev Get the base price to upgrade a Sheet's stat given its current value
    /// @dev The "base price" is the price to upgrade, not including risk level multipliers
    /// @param statLevel The value of the stat that is being upgraded
    /// @return uint256 The base price to upgrade the stat
    function _getBasePriceForStatLevel(uint8 statLevel) internal pure returns(uint256) {
        uint256 SHREDS = 1e18;
        if(statLevel < 75) {
            return 3 * SHREDS;
        } else if(statLevel < 100) {
            return 4 * SHREDS;
        } else if(statLevel < 125) {
            return 7 * SHREDS;
        } else if(statLevel < 150) {
            return 11 * SHREDS;
        } else if(statLevel < 175) {
            return 19 * SHREDS;
        } else if(statLevel < 200) {
            return 30 * SHREDS;
        } else if(statLevel < 225) {
            return 50 * SHREDS;
        } else {
            return 81 * SHREDS;
        }
    }

    /// @dev Takes a random number and bounds it between a lower and upper bound
    /// @param lowerBound Lower bound
    /// @param upperBound Upper bound
    /// @param randomness Random number
    /// @return int256 Bounded random number
    function _getUpgradeDelta(int256 lowerBound, int256 upperBound, uint256 randomness) internal pure returns(int256) {
        return int256(randomness % uint256(upperBound - lowerBound + 1)) + lowerBound;
    }

    /// @dev Calculates a Sheet's final stat after upgrade, given an upgrade delta
    /// @dev This function returns a uint8
    /// @dev This function prevents integer overflow ( < 0 or > 255);
    /// @param currentStat Sheet's stat before upgrade
    /// @param delta The change in the Sheet's value after upgrading, not accounting for overflow prevention
    /// @return uint8 Sheet's final stat after upgrade
    function _getUpgradedStat(uint8 currentStat, int256 delta) internal pure returns(uint8) {
        int256 unboundedValue = int256(uint256(currentStat)) + delta;
        if(unboundedValue < 0) return 0;
        if(unboundedValue > 255) return 255;
        return uint8(uint256(unboundedValue));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

import "IERC721Enumerable.sol";

interface ISheetFighterToken is IERC721Enumerable {

    /// @notice Update the address of the CellToken contract
    /// @param _contractAddress Address of the CellToken contract
    function setCellTokenAddress(address _contractAddress) external;

    /// @notice Update the address which signs the mint transactions
    /// @dev    Used for ensuring GPT-3 values have not been altered
    /// @param  _mintSigner New address for the mintSigner
    function setMintSigner(address _mintSigner) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Update the address of the upgrade contract
    /// @dev Used for authorization
    /// @param  _upgradeContract New address for the upgrade contract
    function setUpgradeContract(address _upgradeContract) external;

    /// @dev Withdraw funds as owner
    function withdraw() external;

    /// @notice Set the sale state: options are 0 (closed), 1 (presale), 2 (public sale) -- only owner can call
    /// @dev    Implicitly converts int argument to TokenSaleState type -- only owner can call
    /// @param  saleStateId The id for the sale state: 0 (closed), 1 (presale), 2 (public sale)
    function setSaleState(uint256 saleStateId) external;

    /// @notice Mint up to 20 Sheet Fighters
    /// @param  numTokens Number of Sheet Fighter tokens to mint (1 to 20)
    function mint(uint256 numTokens) external payable;

    /// @notice "Print" a Sheet. Adds GPT-3 flavor text and attributes
    /// @dev    This function requires signature verification
    /// @param  _tokenIds Array of tokenIds to print
    /// @param  _flavorTexts Array of strings with flavor texts concatonated with a pipe character
    /// @param  _signature Signature verifying _flavorTexts are unmodified
    function print(
        uint256[] memory _tokenIds,
        string[] memory _flavorTexts,
        bytes memory _signature
    ) external;

    /// @notice Bridge the Sheets
    /// @dev Transfers Sheets to bridge
    /// @param tokenOwner Address of the tokenOwner who is bridging their tokens
    /// @param tokenIds Array of tokenIds that tokenOwner is bridging
    function bridgeSheets(address tokenOwner, uint256[] calldata tokenIds) external;

    /// @notice Update the sheet to sync with actions that occured on otherside of bridge
    /// @param tokenId Id of the SheetFighter
    /// @param HP New HP value
    /// @param critical New luck value
    /// @param heal New heal value
    /// @param defense New defense value
    /// @param attack New attack value
    function syncBridgedSheet(
        uint256 tokenId,
        uint8 HP,
        uint8 critical,
        uint8 heal,
        uint8 defense,
        uint8 attack
    ) external;

    /// @notice Get Sheet stats
    /// @param _tokenId Id of SheetFighter
    /// @return tuple containing sheet's stats
    function tokenStats(uint256 _tokenId) external view returns(uint8, uint8, uint8, uint8, uint8, uint8, uint8);

    /// @notice Return true if token is printed, false otherwise
    /// @param _tokenId Id of the SheetFighter NFT
    /// @return bool indicating whether or not sheet is printed
    function isPrinted(uint256 _tokenId) external view returns(bool);

    /// @notice Returns the token metadata and SVG artwork
    /// @dev    This generates a data URI, which contains the metadata json, encoded in base64
    /// @param _tokenId The tokenId of the token whos metadata and SVG we want
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /// @notice Update the sheet to via upgrade contract
    /// @param tokenId Id of the SheetFighter
    /// @param attributeNumber specific attribute to upgrade
    /// @param value new attribute value
    function updateStats(uint256 tokenId,uint8 attributeNumber,uint8 value) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.0;

import "IERC20.sol";


/// @title  Contract creating fungible in-game utility tokens for the Sheet Fighter game
/// @author Overlord Paper Co
/// @notice This defines an in-game utility token used to reward winners in Sheet Fighter Game battles.
/// @notice This contract is HIGHLY adapted from the Anonymice $CHEETH contract
/// @notice Thank you MouseDev for writing the original $CHEETH contract!
interface IShredsToken is IERC20 {

    /// @notice Update the address of the SheetFighterToken contract
    /// @param _contractAddress Address of the SheetFighterToken contract
    function setSheetFighterTokenAddress(address _contractAddress) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Set whether an account is authorized to mint & burn SHREDS
    /// @param account Pertaining account
    /// @param status Whether it should be authorized or not
    function setMinterBurner(address account, bool status) external;

    /// @notice Mint tokens when bridging
    /// @dev This function is only used for bridging to mint tokens on one end
    /// @param to Address to send new tokens to
    /// @param value Number of new tokens to mint
    function bridgeMint(address to, uint256 value) external;

    /// @notice Burn tokens when bridging
    /// @dev This function is only used for bridging to burn tokens on one end
    /// @param from Address to burn tokens from
    /// @param value Number of tokens to burn
    function bridgeBurn(address from, uint256 value) external;

    /// @notice Generic SHREDS mint function
    /// @param to Account which receives the minted SHREDS
    /// @param value SHREDS amount to mint
    function mint(address to, uint256 value) external;

    /// @notice SHREDS burn function for caller's own tokens
    /// @param value SHREDS amount to burn
    function burn(uint256 value) external;
    
    /// @notice Generic SHREDS burn function for another account's tokens
    /// @param from Account from which SHREDS are burned 
    /// @param value SHREDS amount to burn
    function burnFrom(address from, uint256 value) external;
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
pragma solidity ^0.8.0;

/** 
 * @notice Interface for contracts using VRF randomness
 * @dev REPLICATE chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol
 *      And adjust to our needs:
 *      - vrfCoordinator non-private
 *      - vrfCoordinator initialized via separate function
 *      (for proxy deployment purposes)
 * 
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
 */
abstract contract PolygonVRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  /// ------ PRESERVING storage layout of V1 ---------

  /// @dev was LinkTokenInterface internal LINK in V1
  address public legacyPlaceholder1; 
  /// @dev was present in V1 too, can only init once
  address public vrfCoordinator; 
  /// @dev was nonces in V1
  mapping(bytes32 => uint256) private legacyPlaceholder2;

  /// ------ NOTHING ADDED to storage layout of V1 -------

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