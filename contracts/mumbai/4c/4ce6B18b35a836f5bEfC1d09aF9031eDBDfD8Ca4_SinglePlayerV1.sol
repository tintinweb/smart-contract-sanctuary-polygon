// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../gacha/GachaV1.sol";

contract GachaDummyImplementation is GachaV1 {
    string public dummyUpgrade;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMelXNFT} from "../melX/IMelXNFT.sol";
import {IGacha} from "./IGacha.sol";
import "../upgradeable/VRFConsumerBaseV2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract GachaV1 is
    IGacha,
    Initializable,
    VRFConsumerBaseV2Upgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    struct RarityRate {
        string name;
        uint16 rate;
        bool isExist;
    }

    struct RequestData {
        address user;
        string city;
        address referralAddress;
    }

    event MintWithGacha(
        string rarityName,
        address indexed to,
        string indexed city,
        uint256 tokenId
    );

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public melxNftAddress;
    address public melTokenAddress;

    uint8 public whitelistBatch;
    bool public whitelistStatus;
    bool public referralStatus;

    string[] public rarityNameList;
    mapping(string => RarityRate) public rarityNameToRarityRate;
    mapping(uint256 => uint256) public requestIdToRandomness;
    mapping(uint256 => RequestData) public requestIdToRequestData;
    mapping(uint8 => mapping(address => bool))
        public whitelistBatchToAddressMap;
    mapping(string => mapping(string => IMelXNFT.NftData)) rarityTypeToNftData;

    uint16[] public cumulativeWeight;
    uint16 public maxCumulativeWeight;

    LinkTokenInterface public LINKTOKEN;
    VRFCoordinatorV2Interface public COORDINATOR;

    uint16 public requestConfirmation;
    uint32 public callbackGasLimit;
    uint32 public numWords;
    uint64 public subscriptionId;
    bytes32 public keyHash;

    event WhitelistStatus(bool status);
    event ReferralStatus(bool status);
    event WhitelistBatch(uint8 batch);
    event WhitelistusersBulk(uint8 indexed batch, address[] users);
    event WhitelistUsers(
        uint8 indexed batch,
        address indexed user,
        bool indexed status
    );

    /**
     * @dev Modifier onlyAdmin, admin data come from MelXNFT contract
     */
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /**
     * @dev Modifider whitelistMiddleware, only whitelisted user or whiteliststatus is false
     * can execute next
     */
    modifier whitelistMiddleware() {
        require(
            whitelistBatchToAddressMap[whitelistBatch][_msgSender()] == true ||
                !whitelistStatus,
            "Need to be in whitelist"
        );
        _;
    }

    /**
     * @dev function to withdraw link token from this contract to other address
     * @param _to address to the new token owner
     * only admin who can call this admin
     * only when contract is unpause admin can call this function
     */
    function withdrawLink(address _to) external whenNotPaused onlyAdmin {
        require(
            LINKTOKEN.transfer(_to, LINKTOKEN.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @dev pause function to pause contract
     * Only admin can call this contract
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev unpause function to pause contract
     * Only admin can call this contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev Top up link token
     * @param amount link token amount
     */
    function topUpSubscription(uint256 amount) external {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(subscriptionId)
        );
    }

    function initialize(
        address _vrfCoordinator,
        address _linkTokenAddress,
        bytes32 _keyhash,
        address _melxNftAddress,
        address _melTokenAddress,
        uint16 _requestConfirmation,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) public initializer {
        LINKTOKEN = LinkTokenInterface(_linkTokenAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyhash;
        melxNftAddress = _melxNftAddress;
        melTokenAddress = _melTokenAddress;
        whitelistBatch = 1;
        whitelistStatus = false;
        referralStatus = true;
        setVrfParams(_requestConfirmation, _callbackGasLimit, _numWords);
        __VRFConsumerBase_init(_vrfCoordinator);
        createNewSubscription();
    }

    /**
     * @dev Set whitelist status to true
     */
    function whitelistStatusOn() public onlyAdmin whenNotPaused {
        require(!whitelistStatus, "Whitelist status already on");
        whitelistStatus = true;
        emit WhitelistStatus(true);
    }

    /**
     * @dev Set whitelist status to false
     */
    function whitelistStatusOff() public onlyAdmin whenNotPaused {
        require(whitelistStatus, "Whitelist status already off");
        whitelistStatus = false;
        emit WhitelistStatus(false);
    }

    /**
     * @dev Set referral status to true
     */
    function referralStatusOn() public onlyAdmin whenNotPaused {
        require(!referralStatus, "Referral status already on");
        referralStatus = true;
        emit ReferralStatus(true);
    }

    /**
     * @dev Set referral status to false
     */
    function referralStatusOff() public onlyAdmin whenNotPaused {
        require(referralStatus, "Referral status already off");
        referralStatus = false;
        emit ReferralStatus(false);
    }

    /**
     * @dev whitelisted an address based on whitelist batch
     */
    function addAddressToWhitelist(address _address)
        public
        onlyAdmin
        whenNotPaused
    {
        require(
            whitelistBatchToAddressMap[whitelistBatch][_address] == false,
            "Already whitelisted"
        );
        whitelistBatchToAddressMap[whitelistBatch][_address] = true;
        emit WhitelistUsers(whitelistBatch, _address, true);
    }

    /**
     * @dev remove an address from whitelist batch
     */
    function removeAddressFromWhitelist(address _address)
        public
        onlyAdmin
        whenNotPaused
    {
        require(
            whitelistBatchToAddressMap[whitelistBatch][_address] == true,
            "Not in whitelist"
        );
        whitelistBatchToAddressMap[whitelistBatch][_address] = false;
        emit WhitelistUsers(whitelistBatch, _address, false);
    }

    function setVrfParams(
        uint16 _requestConfirmation,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) public {
        requestConfirmation = _requestConfirmation;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    /**
     * @dev bulk input whitelisted user
     */
    function addBulkAddressToWhitelist(address[] calldata _addresses)
        public
        onlyAdmin
        whenNotPaused
    {
        address[] memory whitelistAddress = new address[](_addresses.length);
        for (
            uint256 itemIndex = 0;
            itemIndex < _addresses.length;
            itemIndex++
        ) {
            if (
                whitelistBatchToAddressMap[whitelistBatch][
                    _addresses[itemIndex]
                ] == false
            ) {
                whitelistBatchToAddressMap[whitelistBatch][
                    _addresses[itemIndex]
                ] = true;
                whitelistAddress[itemIndex] = _addresses[itemIndex];
            }
        }
        emit WhitelistusersBulk(whitelistBatch, whitelistAddress);
    }

    /**
     * @dev Bump whitelist batch
     */
    function increaseWhitelistBatch() public onlyAdmin whenNotPaused {
        whitelistBatch += 1;
        emit WhitelistBatch(whitelistBatch);
    }

    /**
     * @dev Gacha function to do Gacha
     * Only when contract is unpause user can call this function
     */
    function gacha(string calldata _city)
        public
        override
        whenNotPaused
        whitelistMiddleware
    {
        _gacha(_city, address(0));
    }

    /**
     * @dev Gacha function to do Gacha with referral address
     * Only when contract is unpause user can call this function and
     * referral program is on going
     */
    function gachaWithReferral(string calldata _city, address _referralAddress)
        public
        override
        whenNotPaused
        whitelistMiddleware
    {
        require(referralStatus, "Referral program is off");
        require(
            _referralAddress != _msgSender(),
            "Cannot use your own address"
        );
        require(
            IERC721Upgradeable(melxNftAddress).balanceOf(_referralAddress) > 0,
            "Referral address minimal have 1 NFT"
        );
        _gacha(_city, _referralAddress);
    }

    /**
     * @dev Add or update rarity data
     * @param _name Name of rarity
     * @param _rate Rate or chance to get this rarity
     */
    function addRarity(string calldata _name, uint16 _rate)
        public
        whenNotPaused
        onlyAdmin
    {
        if (!rarityNameToRarityRate[_name].isExist) {
            rarityNameList.push(_name);
        }
        rarityNameToRarityRate[_name] = RarityRate(_name, _rate, true);
        delete cumulativeWeight;
        for (uint8 i = 0; i < rarityNameList.length; i++) {
            uint16 previousValue;
            if (i == 0) {
                previousValue = 0;
            } else {
                uint16 tmp = i - 1;
                previousValue = cumulativeWeight[tmp];
            }
            cumulativeWeight.push(
                rarityNameToRarityRate[rarityNameList[i]].rate + previousValue
            );
        }

        maxCumulativeWeight = cumulativeWeight[cumulativeWeight.length - 1];
    }

    /**
     * @dev Add or update bike name and image;
     */
    function addBikeInfo(
        string memory _rarity,
        string memory _types,
        string memory _name,
        string memory _imageUrl,
        uint16 _baseAcceleration,
        uint16 _baseSpeed,
        uint16 _baseDrift,
        uint16 _accelerationGrowth,
        uint16 _speedGrowth,
        uint16 _driftGrowth
    ) public whenNotPaused onlyAdmin {
        rarityTypeToNftData[_rarity][_types] = IMelXNFT.NftData({
            name: _name,
            imageUrl: _imageUrl,
            rarity: _rarity,
            bikeType: _types,
            level: 1,
            exp: 0,
            baseAcceleration: _baseAcceleration,
            baseSpeed: _baseSpeed,
            baseDrift: _baseDrift,
            accelerationGrowth: _accelerationGrowth,
            speedGrowth: _speedGrowth,
            driftGrowth: _driftGrowth
        });
    }

    /**
     * @dev Gacha function to do Gacha
     * Only when contract is unpause user can call this function
     */
    function _gacha(string calldata _city, address _referralAddress) internal {
        address paymentAddress = IMelXNFT(melxNftAddress).paymentAddress();
        uint256 feeAmount = IMelXNFT(melxNftAddress).feeAmount();
        uint256 minimalMel = IMelXNFT(melxNftAddress).minimalMel();
        require(
            IERC20Upgradeable(melTokenAddress).balanceOf(_msgSender()) >=
                minimalMel,
            "Not enough mel token"
        );
        require(
            IERC20Upgradeable(paymentAddress).balanceOf(_msgSender()) >=
                feeAmount,
            "Not enough fee token"
        );
        require(
            IERC20Upgradeable(paymentAddress).allowance(
                _msgSender(),
                melxNftAddress
            ) >= feeAmount,
            "Need to approve mint fee with Mel token"
        );
        _getRandomNumberForGacha(_city, _referralAddress);
    }

    /**
     * @dev Gacha function to request the randomness value from VRF Chainlink
     */
    function _getRandomNumberForGacha(
        string calldata _city,
        address _referralAddress
    ) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmation,
            callbackGasLimit,
            numWords
        );

        requestIdToRequestData[requestId] = RequestData(
            _msgSender(),
            _city,
            _referralAddress
        );
    }

    /**
     * @dev Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal virtual override {
        requestIdToRandomness[_requestId] = _randomWords[0];
        _getGachaResult(_requestId);
    }

    /**
     * @dev Get rarity based on randomness value that chainlink give
     * @param _requestId Request ID from chainlink
     */
    function _getGachaResult(uint256 _requestId) internal {
        uint256 randomness = (requestIdToRandomness[_requestId] %
            maxCumulativeWeight) + 1;

        string memory bikeType;

        if (requestIdToRandomness[_requestId] % 4 == 0) {
            bikeType = "ACCELERATOR";
        } else if (requestIdToRandomness[_requestId] % 4 == 1) {
            bikeType = "DRIFTER";
        } else if (requestIdToRandomness[_requestId] % 4 == 2) {
            bikeType = "SPEEDSTER";
        } else {
            bikeType = "BALANCED";
        }

        for (
            uint256 itemIndex = 0;
            itemIndex < rarityNameList.length;
            itemIndex++
        ) {
            if (cumulativeWeight[itemIndex] >= randomness) {
                string memory rarityName = rarityNameList[itemIndex];
                IMelXNFT.NftData memory nftData = rarityTypeToNftData[
                    rarityName
                ][bikeType];
                RequestData memory requestData = requestIdToRequestData[
                    _requestId
                ];

                uint256 tokenId = IMelXNFT(melxNftAddress).safeMintWithGacha(
                    requestData.user,
                    requestData.city,
                    requestData.referralAddress,
                    nftData
                );
                emit MintWithGacha(
                    nftData.name,
                    requestIdToRequestData[_requestId].user,
                    requestIdToRequestData[_requestId].city,
                    tokenId
                );
                return;
            }
        }
    }

    /**
     * @dev Create new subscript VRF, will assign subscription ID
     */
    function createNewSubscription() private {
        subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    /**
     * @dev Middleware for upgradeTo function to upgrading contract
     */
    function _authorizeUpgrade(address _newImplementation)
        internal
        view
        override
    {
        _onlyAdmin();
    }

    /**
     * @dev Private function onlyAdmin, admin data come from MelXNFT contract
     */
    function _onlyAdmin() private view {
        require(
            IAccessControlUpgradeable(melxNftAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                _msgSender()
            ),
            "Only Admin"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IMelXNFT {
    struct NftData {
        string name;
        string imageUrl;
        string rarity;
        string bikeType;
        uint8 level;
        uint16 exp;
        uint16 baseAcceleration;
        uint16 baseSpeed;
        uint16 baseDrift;
        uint16 accelerationGrowth;
        uint16 speedGrowth;
        uint16 driftGrowth;
    }

    function safeMintWithSignature(
        address _to,
        string calldata _cid,
        string calldata _city,
        bytes calldata _data
    ) external returns (uint256 nftTokenId);

    function safeMintWithGacha(
        address _to,
        string calldata _city,
        address _referralAddress,
        NftData calldata _nftData
    ) external returns (uint256 nftTokenId);

    function feeAmount() external view returns (uint256);

    function minimalMel() external view returns (uint256);

    function paymentAddress() external view returns (address);

    function getNftBaseStat(uint256 _nftId) external view returns (uint256);

    function getNftData(uint256 _nftId) external view returns (NftData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGacha {
    function gacha(string calldata _city) external;

    function gachaWithReferral(string calldata _city, address _referralAddress)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function __VRFConsumerBase_init(address _vrfCoordinator)
        internal
        initializer
    {
        __VRFConsumerBase_init_unchained(_vrfCoordinator);
    }

    function __VRFConsumerBase_init_unchained(address _vrfCoordinator)
        internal
        initializer
    {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBaseUpgradeable is Initializable {
    LinkTokenInterface internal LINK;
    VRFV2WrapperInterface internal VRF_V2_WRAPPER;

    /**
     * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    function __VRFConsumerBase_init(address _link, address _vrfV2Wrapper)
        internal
        initializer
    {
        __VRFConsumerBase_init_unchained(_link, _vrfV2Wrapper);
    }

    function __VRFConsumerBase_init_unchained(
        address _link,
        address _vrfV2Wrapper
    ) internal initializer {
        LINK = LinkTokenInterface(_link);
        VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
    }

    /**
     * @dev Requests randomness from the VRF V2 wrapper.
     *
     * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
     *        fulfillRandomWords function.
     * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
     *        request. A higher number of confirmations increases security by reducing the likelihood
     *        that a chain re-org changes a published randomness outcome.
     * @param _numWords is the number of random words to request.
     *
     * @return requestId is the VRF V2 request ID of the newly created randomness request.
     */
    function requestRandomness(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) internal returns (uint256 requestId) {
        LINK.transferAndCall(
            address(VRF_V2_WRAPPER),
            VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
            abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
        );
        return VRF_V2_WRAPPER.lastRequestId();
    }

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
     * @notice implement it.
     *
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal virtual;

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        require(
            msg.sender == address(VRF_V2_WRAPPER),
            "only VRF V2 wrapper can fulfill"
        );
        fulfillRandomWords(_requestId, _randomWords);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISinglePlayer} from "./ISinglePlayer.sol";
import {IMelXNFT} from "../melX/IMelXNFT.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "../game/IEnergy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SinglePlayerV1 is ISinglePlayer, Initializable, UUPSUpgradeable {
    struct TrackInformation {
        string name;
        uint8 accelerationMultiplier;
        uint8 speedMultiplier;
        uint8 driftMultiplier;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint8 public energyCost;

    address public melxNftAddress;
    address public storeContractAddress;

    mapping(uint8 => TrackInformation) trackIdToTrackInformation;

    event RaceResult(
        uint8 exp,
        uint8 bb,
        uint256 nftId,
        string nftName,
        bool result
    );

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyNftOwner(uint256 _nftId, address _owner) {
        require(
            IERC721Upgradeable(melxNftAddress).ownerOf(_nftId) == msg.sender,
            "You are not the owner of this nft!"
        );
        _;
    }

    function initialize(address _melxNftAddress, address _storeContractAddress)
        public
        initializer
    {
        melxNftAddress = _melxNftAddress;
        storeContractAddress = _storeContractAddress;
        energyCost = 1;
    }

    function addTrackInformation(
        string memory _name,
        uint8 _trackId,
        uint8 _accelerationMultiplier,
        uint8 _speedMultiplier,
        uint8 _driftMultiplier
    ) public override onlyAdmin {
        TrackInformation storage currentTrack = trackIdToTrackInformation[
            _trackId
        ];

        currentTrack.name = _name;
        currentTrack.accelerationMultiplier = _accelerationMultiplier;
        currentTrack.speedMultiplier = _speedMultiplier;
        currentTrack.driftMultiplier = _driftMultiplier;
    }

    function startRace(uint256 _nftId) public onlyNftOwner(_nftId, msg.sender) {
        require(
            IEnergy(storeContractAddress).getPlayerEnergy(msg.sender) >=
                energyCost,
            "You do not have enough energy"
        );
        IEnergy(storeContractAddress).useEnergy(msg.sender, energyCost);

        _race(_nftId);
    }

    function setEnergyCost(uint8 _energyCost) public onlyAdmin {
        energyCost = _energyCost;
    }

    function getTrackInformation(uint8 _trackId)
        public
        view
        returns (TrackInformation memory)
    {
        return trackIdToTrackInformation[_trackId];
    }

    function getCurrentTrack()
        external
        view
        returns (uint8, TrackInformation memory)
    {
        uint8 trackId = uint8(
            uint256(
                keccak256(
                    abi.encodePacked((block.timestamp / 1 days), address(this))
                )
            ) % 12
        );
        return (trackId, getTrackInformation(trackId));
    }

    /**
     * @dev Private function to decide single player result
     */
    function _race(uint256 _nftId) internal {
        emit RaceResult(
            10,
            100,
            _nftId,
            IMelXNFT(melxNftAddress).getNftData(_nftId).name,
            true
        );
    }

    /**
     * @dev Middleware for upgradeTo function to upgrading contract
     */
    function _authorizeUpgrade(address _newImplementation)
        internal
        view
        override
    {
        _onlyAdmin();
    }

    /**
     * @dev Private function onlyAdmin, admin data come from MelXNFT contract
     */
    function _onlyAdmin() private view {
        require(
            IAccessControlUpgradeable(melxNftAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ),
            "Only Admin"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISinglePlayer {
    function addTrackInformation(
        string memory _name,
        uint8 _trackId,
        uint8 _accelerationMultiplier,
        uint8 _speedMultiplier,
        uint8 _driftMultiplier
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnergy {
    function editEnergyPackage(
        uint256 _energyId,
        string memory _energyName,
        uint256 _energyAmount,
        uint256 _energyPrice,
        bool _isAvailable
    ) external;

    function addEnergyPackage(
        string memory _energyName,
        uint256 _energyAmount,
        uint256 _energyPrice,
        bool _isAvailable
    ) external;

    function buyEnergy(uint256 _energyId) external;

    function useEnergy(address _address, uint256 _energy) external;

    function getPlayerEnergy(address _address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRace} from "./IRace.sol";
import {IMelXNFT} from "../melX/IMelXNFT.sol";
import "../upgradeable/VRFConsumerBaseV2Upgradeable.sol";
import {DummyBB} from "../dummy-token/DummyBB.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract RaceV1 is
    IRace,
    Initializable,
    UUPSUpgradeable,
    VRFConsumerBaseV2Upgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Struct to keep information needed to start a round
    struct RoundInformation {
        // Map to keep address has join status
        mapping(address => bool) addressToPlayerStatus;
        // Map to keep nftId has join status
        mapping(uint256 => bool) nftIdToBikeStatus;
        // Map to keep nftId to playerSequence
        mapping(uint256 => uint256) nftIdToPlayerSequence;
        // Map to keep player sequence to random number
        mapping(uint256 => uint256) playerSequenceToRandomNumber;
        // Map to keep nftId to claim prize status
        mapping(uint256 => bool) nftIdToClaimStatus;
        // Variable to keep number of round participant
        uint8 numberOfParticipant;
        // Variable to keep number of round winner
        uint8 numberOfWinner;
        // Variable to keep round opened start time
        uint256 startTime;
        // Variable to keep highest participant stat
        uint256 highestStat;
        // Variable to keep total prize pool
        uint256 prizePool;
    }

    // Integer to save race id
    CountersUpgradeable.Counter raceId;

    // Variable to save LINK Token Address
    LinkTokenInterface LINKTOKEN;
    // Variable to save VRF Coordinator
    VRFCoordinatorV2Interface COORDINATOR;

    // Variable to save keyhash for randomization
    bytes32 keyHash;

    // Role to start race
    bytes32 constant ADMIN_START_RACE_ROLE = keccak256("ADMIN_START_RACE");

    // Variable to set number of minimum player per round
    uint8 minPlayerPerRound;
    // Variable to set number of maximum player per round
    uint8 maxPlayerPerRound;
    // Variable to set number of winner per round
    uint8 numberOfWinner;
    // Variable to set minimum number of confirmation blocks before VRF give random number
    uint16 requestConfirmation;
    // Variable to set maximum amount of gas unit that will be used by VRF's callback function
    uint32 callbackGasLimit;
    // Variable to set number of random number that want to be returned
    uint32 numWords;
    // Variable to keep VRF subscription id
    uint64 subscriptionId;
    //variable to keep race fee percentage;
    uint256 raceCommission;
    //variable to keep race fee percentage divider;
    uint256 raceCommissionDivider;
    // Variable to set minimum time needed before the race can be started
    uint256 minimumTimeToStartRace;
    // Variable to keep extra point for random number mod
    uint256 extraPoint;
    // Variable to keep entry race pool fee
    uint256 racePoolFee;
    // Variable to keep total fee claimable by smart contract
    uint256 claimableCommission;
    // Variable to keep prize percentage;
    uint256 prizePercentage;
    // Variable to keep prize percentage divider;
    uint256 prizePercentageDivider;
    // Variable to keep start race incentive
    uint256 startRaceIncentive;
    // Variable to keep melx nft's contract address
    address melxNftAddress;
    // Variable tok keep bb Token contract address
    address bbTokenAddress;

    // Map to keep round information struct with round id
    mapping(uint256 => RoundInformation) roundIdToRoundInformation;

    // Map to keep information of prize ratio per winner
    mapping(uint256 => uint256[]) numberOfWinnerToPrizeRatio;

    event JoinRace(
        address indexed playerAddress,
        string nftName,
        uint256 nftId,
        uint256 roundId
    );
    event ClaimPrize(
        address indexed playerAddress,
        uint16 rank,
        uint256 roundId,
        uint256 prize
    );
    event RaceStarted(address indexed userAddress, uint256 roundId);
    event RaceFinished(uint256 roundId);

    /**
     * @dev Modifier to check nft ownership
     */
    modifier onlyNftOwner(uint256 _nftId, address _owner) {
        require(
            IERC721Upgradeable(melxNftAddress).ownerOf(_nftId) == msg.sender,
            "You are not the owner of this nft!"
        );
        _;
    }

    //constructor
    /**
     * @dev Function to initialize variable value to use the smart contract properly
     */
    function initialize(
        address _link,
        address _vrfCoordinator,
        address _melxNftAddress,
        address _bbTokenAddress,
        uint16 _requestConfirmation,
        uint32 _callbackGasLimit,
        uint32 _numWords,
        bytes32 _keyHash
    ) public initializer {
        LINKTOKEN = LinkTokenInterface(_link);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        __VRFConsumerBase_init(_vrfCoordinator);
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        melxNftAddress = _melxNftAddress;
        bbTokenAddress = _bbTokenAddress;
        createNewSubscription();
        requestConfirmation = _requestConfirmation;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
        keyHash = _keyHash;
        maxPlayerPerRound = 5;
        numberOfWinner = 3;
        minPlayerPerRound = 3;
        extraPoint = 1;
        racePoolFee = 5 ether;
        startRaceIncentive = 5 ether;
        raceCommission = 1000;
        raceCommissionDivider = 10000;
        numberOfWinnerToPrizeRatio[1] = [100];
        numberOfWinnerToPrizeRatio[2] = [60, 40];
        numberOfWinnerToPrizeRatio[3] = [50, 30, 20];
        prizePercentageDivider = 100;
    }

    //external
    /**
     * @dev Function to top up VRF subscription
     */
    function topUpSubscription(uint256 _amount) external {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(subscriptionId)
        );
    }

    /**
     * @dev Function to withdraw token from smart contract
     */
    function withdraw(uint256 _amount, address _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LINKTOKEN.transfer(_to, _amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return AccessControlUpgradeable.supportsInterface(_interfaceId);
    }

    /**
     * @dev Function to upgrade VRF parameters
     */
    function setVrfParams(
        uint16 _requestConfirmation,
        uint32 _callbackGasLimit,
        uint32 _numWords
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        requestConfirmation = _requestConfirmation;
        callbackGasLimit = _callbackGasLimit;
        numWords = _numWords;
    }

    /**
     * @dev Function to update maximum player that can join the race
     */
    function setMaxPlayerPerRound(uint8 _maxPlayerPerRound)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxPlayerPerRound = _maxPlayerPerRound;
    }

    /**
     * @dev Function to let player join race
     */
    function joinRace(uint256 _nftId)
        public
        override
        onlyNftOwner(_nftId, msg.sender)
    {
        RoundInformation storage roundInformation = roundIdToRoundInformation[
            raceId.current()
        ];

        require(
            roundInformation.numberOfParticipant < maxPlayerPerRound,
            "Number of maximum participant has been reached!"
        );
        require(
            !roundInformation.nftIdToBikeStatus[_nftId],
            "This bike already join this round!"
        );
        require(
            !roundInformation.addressToPlayerStatus[msg.sender],
            "This wallet already join this round!"
        );
        require(
            DummyBB(bbTokenAddress).balanceOf(msg.sender) >= racePoolFee,
            "Not enough BB token"
        );

        DummyBB(bbTokenAddress).transferFrom(
            msg.sender,
            address(this),
            racePoolFee
        );

        roundInformation.prizePool += racePoolFee;

        roundInformation.nftIdToPlayerSequence[_nftId] = roundInformation
            .numberOfParticipant;
        roundInformation.nftIdToBikeStatus[_nftId] = true;
        roundInformation.addressToPlayerStatus[msg.sender] = true;
        roundInformation.nftIdToClaimStatus[_nftId] = true;
        roundInformation.playerSequenceToRandomNumber[
            roundInformation.numberOfParticipant
        ] += IMelXNFT(melxNftAddress).getNftBaseStat(_nftId);
        roundInformation.numberOfParticipant += 1;

        if (
            roundInformation.highestStat <
            roundInformation.playerSequenceToRandomNumber[
                roundInformation.numberOfParticipant
            ]
        ) {
            roundInformation.highestStat = roundInformation
                .playerSequenceToRandomNumber[
                    roundInformation.numberOfParticipant
                ];
        }

        IMelXNFT.NftData memory nftData = IMelXNFT(melxNftAddress).getNftData(
            _nftId
        );

        emit JoinRace(msg.sender, nftData.name, _nftId, raceId.current());
    }

    /**
     * @dev Function to start race, give incentive to the user
     */
    function startRace() public override {
        _startRace();
        DummyBB(bbTokenAddress).transfer(msg.sender, startRaceIncentive);
        emit RaceStarted(msg.sender, raceId.current());
    }

    /**
     * @dev Function to start race
     */
    function startRaceAdmin() public override onlyRole(ADMIN_START_RACE_ROLE) {
        _startRace();
        emit RaceStarted(msg.sender, raceId.current());
    }

    /**
     * @dev Function to let winners claim prize
     */
    function claimPrize(uint256 _nftId, uint256 _roundId)
        public
        onlyNftOwner(_nftId, msg.sender)
    {
        RoundInformation storage roundInformation = roundIdToRoundInformation[
            _roundId
        ];

        require(
            roundInformation.nftIdToClaimStatus[_nftId],
            "You are not eligible to claim prize"
        );
        uint16 rank = getRank(_nftId, _roundId);
        roundInformation.nftIdToClaimStatus[_nftId] = false;
        if (rank <= roundIdToRoundInformation[_roundId].numberOfWinner) {
            _claimPrize(_roundId, rank, msg.sender);
        } else {
            emit ClaimPrize(msg.sender, rank, _roundId, 0);
        }
    }

    /**
     * @dev Function to let admin collect claimable prize pool
     */
    function claimCollectableCommission() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 claimable = claimableCommission;
        claimableCommission = 0;
        DummyBB(bbTokenAddress).transfer(msg.sender, claimable);
    }

    /**
     * @dev Function to let admin update number of winner
     */
    function setNumberOfWinner(uint8 _numberOfWinner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        numberOfWinner = _numberOfWinner;
    }

    /**
     * @dev Function to let admin update extra point
     */
    function setExtraPoint(uint256 _extraPoint)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        extraPoint = _extraPoint;
    }

    /**
     * @dev Function to let admin update race pool entry fee
     */
    function setRacePoolFee(uint256 _racePoolFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        racePoolFee = _racePoolFee;
    }

    /**
     * @dev Function to let admin update race pool commission
     */
    function setRaceCommission(uint256 _raceCommission)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        raceCommission = _raceCommission;
    }

    /**
     * @dev Function to let admin update race pool commission divider
     */
    function setRaceCommissionDivider(uint256 _raceCommissionDivider)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        raceCommissionDivider = _raceCommissionDivider;
    }

    /**
     * @dev Function to let admin update race pool prize ratio
     */
    function setPrizeRatio(uint8 _numberOfWinner, uint256[] memory _ratio)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        numberOfWinnerToPrizeRatio[_numberOfWinner] = _ratio;
    }

    /**
     * @dev Function to let admin update minimum player needed
     */
    function setMinPlayer(uint8 _minPlayerPerRound)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minPlayerPerRound = _minPlayerPerRound;
    }

    /**
     * @dev Function to let admin update minimum time needed
     */
    function setMinimumTimeToStartRound(uint256 _minimumTimeToStartRace)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minimumTimeToStartRace = _minimumTimeToStartRace;
    }

    function setStartRaceIncentive(uint256 _startRaceIncentive)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startRaceIncentive = _startRaceIncentive;
    }

    /**
     * @dev Function to get current number of winner;
     */
    function getNumberOfWinner() public view returns (uint8) {
        return numberOfWinner;
    }

    /**
     * @dev Function to get current raceId;
     */
    function getRaceId() public view returns (uint256) {
        return raceId.current();
    }

    /**
     * @dev Function to let user get rank
     */
    function getRank(uint256 _nftId, uint256 _roundId)
        public
        view
        returns (uint16)
    {
        uint16 rank;
        uint256 playerSequence = roundIdToRoundInformation[_roundId]
            .nftIdToPlayerSequence[_nftId];

        require(
            _roundId <= raceId.current() &&
                roundIdToRoundInformation[_roundId].nftIdToBikeStatus[_nftId],
            "Invalid NFT or Round ID"
        );

        for (
            uint256 i = 0;
            i < roundIdToRoundInformation[_roundId].numberOfParticipant;
            i++
        ) {
            if (
                roundIdToRoundInformation[_roundId]
                    .playerSequenceToRandomNumber[playerSequence] <=
                roundIdToRoundInformation[_roundId]
                    .playerSequenceToRandomNumber[i]
            ) {
                rank += 1;
            }
        }
        return rank;
    }

    /**
     * @dev Function to get race pool entry fee
     */
    function getEntryFee() public view returns (uint256) {
        return racePoolFee;
    }

    /**
     * @dev Function to get race commission
     */
    function getRaceCommission() public view returns (uint256) {
        uint256 commission = (1 ether / raceCommissionDivider) * raceCommission;
        return commission;
    }

    /**
     * @dev Function to get total claimable commission
     */
    function getClaimableCommission() public view returns (uint256) {
        return claimableCommission;
    }

    /**
     * @dev Function to get prize ratio
     */
    function getPrizeRatio(uint8 _numberOfWinner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ratio = numberOfWinnerToPrizeRatio[_numberOfWinner];
        for (uint256 i = 0; i < _numberOfWinner; i++) {
            ratio[i] = (1 ether / prizePercentageDivider) * ratio[i];
        }

        return ratio;
    }

    /**
     * @dev Function to get minimum time to start race
     */
    function getMinimumTimeToStartRace() public view returns (uint256) {
        return minimumTimeToStartRace;
    }

    /**
     * @dev Function to get minimum player to start race
     */
    function getMinimumPlayerToStartRace() public view returns (uint8) {
        return minPlayerPerRound;
    }

    /**
     * @dev Function to get maximum player to start race
     */
    function getMaximumPlayerToStartRace() public view returns (uint8) {
        return maxPlayerPerRound;
    }

    /**
     * @dev Function to get total user who already join the race
     */
    function getNumberOfParticipant(uint256 _roundId)
        public
        view
        returns (uint8)
    {
        return roundIdToRoundInformation[_roundId].numberOfParticipant;
    }

    /**
     * @dev Function to get number of start race incentive
     */
    function getStartRaceIncentive() public view returns (uint256) {
        return startRaceIncentive;
    }

    /**
     * @dev Function to get extrapoints
     */
    function getExtraPoint() public view returns (uint256) {
        return extraPoint;
    }

    /**
     * @dev Function to get user status on current on going race
     * return true if user already join
     */
    function getUserJoinStatus(address _player) public view returns (bool) {
        return
            roundIdToRoundInformation[raceId.current()].addressToPlayerStatus[
                _player
            ];
    }

    /**
     * @dev Function to return when the user can start the race
     */
    function getCurrentRaceStartTime() public view returns (uint256) {
        return
            roundIdToRoundInformation[raceId.current()].startTime +
            minimumTimeToStartRace;
    }

    /**
     * @dev Function to return VRF subscription ID
     */
    function getVrfSubscriptionId() public view returns (uint64) {
        return subscriptionId;
    }

    /**
     * @dev Function to return VRF coordinator address
     */
    function getVrfCoordinatorAddress() public view returns (address) {
        return address(COORDINATOR);
    }

    /**
     * @dev Middleware for upgradeTo function to upgrading contract
     */
    function _authorizeUpgrade(address _newImplementation)
        internal
        view
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /**
     * @dev Internal function to request random number to VRF
     */
    function _requestRandomness(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );

        return requestId;
    }

    /**
     * @dev Function to fulfill random number
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal virtual override {
        raceId.increment();
        for (
            uint256 i = 0;
            i <
            roundIdToRoundInformation[raceId.current() - 1].numberOfParticipant;
            i++
        ) {
            roundIdToRoundInformation[raceId.current() - 1]
                .playerSequenceToRandomNumber[i] +=
                _randomWords[i] %
                (roundIdToRoundInformation[raceId.current() - 1].highestStat +
                    extraPoint);
        }

        emit RaceFinished(raceId.current() - 1);
    }

    /**
     * @dev Create a new subscription when the contract is initially deployed.
     */
    function createNewSubscription() private {
        subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    function _startRace() private {
        RoundInformation storage roundInformation = roundIdToRoundInformation[
            raceId.current()
        ];

        require(
            roundInformation.numberOfParticipant >= minPlayerPerRound,
            "Minimum player has not been reached"
        );
        require(
            block.timestamp >=
                roundInformation.startTime + minimumTimeToStartRace,
            "Minimum time has not been reached"
        );

        roundIdToRoundInformation[raceId.current() + 1].startTime = block
            .timestamp;
        claimableCommission +=
            (roundInformation.prizePool / raceCommissionDivider) *
            raceCommission;
        roundInformation.prizePool -=
            (roundInformation.prizePool / raceCommissionDivider) *
            raceCommission;
        roundInformation.numberOfWinner = numberOfWinner;

        _requestRandomness(
            callbackGasLimit,
            requestConfirmation,
            roundInformation.numberOfParticipant
        );
    }

    /**
     * @dev private function to claim prize
     */
    function _claimPrize(
        uint256 _roundId,
        uint16 _rank,
        address _claimer
    ) private {
        uint256[] memory prize = numberOfWinnerToPrizeRatio[
            roundIdToRoundInformation[_roundId].numberOfWinner
        ];

        uint256 userPrize = (roundIdToRoundInformation[_roundId].prizePool /
            prizePercentageDivider) * prize[_rank - 1];
        DummyBB(bbTokenAddress).transfer(_claimer, userPrize);
        emit ClaimPrize(_claimer, _rank, _roundId, userPrize);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRace {
    function joinRace(uint256 _nftId) external;

    function startRace() external;

    function startRaceAdmin() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyBB is ERC20 {
    constructor() ERC20("BikeBattle", "BB") {
        _mint(msg.sender, 12000000 * 10**18);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// A mock for testing code that relies on VRFCoordinatorV2.
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFCoordinatorV2Mock is VRFCoordinatorV2Interface {
    uint96 public immutable BASE_FEE;
    uint96 public immutable GAS_PRICE_LINK;
    uint16 public immutable MAX_CONSUMERS = 100;

    error InvalidSubscription();
    error InsufficientBalance();
    error MustBeSubOwner(address owner);
    error TooManyConsumers();
    error InvalidConsumer();
    error InvalidRandomWords();

    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint96 payment,
        bool success
    );
    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );
    event SubscriptionCanceled(
        uint64 indexed subId,
        address to,
        uint256 amount
    );
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event ConsumerRemoved(uint64 indexed subId, address consumer);

    uint64 s_currentSubId;
    uint256 s_nextRequestId = 1;
    uint256 s_nextPreSeed = 100;
    struct Subscription {
        address owner;
        uint96 balance;
    }
    mapping(uint64 => Subscription) s_subscriptions; /* subId */ /* subscription */
    mapping(uint64 => address[]) s_consumers; /* subId */ /* consumers */

    struct Request {
        uint64 subId;
        uint32 callbackGasLimit;
        uint32 numWords;
    }
    mapping(uint256 => Request) s_requests; /* requestId */ /* request */

    receive() external payable {}

    constructor(uint96 _baseFee, uint96 _gasPriceLink) {
        BASE_FEE = _baseFee;
        GAS_PRICE_LINK = _gasPriceLink;
    }

    function consumerIsAdded(uint64 _subId, address _consumer)
        public
        view
        returns (bool)
    {
        address[] memory consumers = s_consumers[_subId];
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == _consumer) {
                return true;
            }
        }
        return false;
    }

    modifier onlyValidConsumer(uint64 _subId, address _consumer) {
        if (!consumerIsAdded(_subId, _consumer)) {
            revert InvalidConsumer();
        }
        _;
    }

    /**
     * @notice fulfillRandomWords fulfills the given request, sending the random words to the supplied
     * @notice consumer.
     *
     * @dev This mock uses a simplified formula for calculating payment amount and gas usage, and does
     * @dev not account for all edge cases handled in the real VRF coordinator. When making requests
     * @dev against the real coordinator a small amount of additional LINK is required.
     *
     * @param _requestId the request to fulfill
     * @param _consumer the VRF randomness consumer to send the result to
     */
    function fulfillRandomWords(uint256 _requestId, address _consumer)
        external
    {
        fulfillRandomWordsWithOverride(_requestId, _consumer, new uint256[](0));
    }

    /**
     * @notice fulfillRandomWordsWithOverride allows the user to pass in their own random words.
     *
     * @param _requestId the request to fulfill
     * @param _consumer the VRF randomness consumer to send the result to
     * @param _words user-provided random words
     */
    function fulfillRandomWordsWithOverride(
        uint256 _requestId,
        address _consumer,
        uint256[] memory _words
    ) public {
        uint256 startGas = gasleft();
        if (s_requests[_requestId].subId == 0) {
            revert("nonexistent request");
        }
        Request memory req = s_requests[_requestId];

        if (_words.length == 0) {
            _words = new uint256[](req.numWords);
            for (uint256 i = 0; i < req.numWords; i++) {
                _words[i] = uint256(keccak256(abi.encode(_requestId, i)));
            }
        } else if (_words.length != req.numWords) {
            revert InvalidRandomWords();
        }

        VRFConsumerBaseV2 v;
        bytes memory callReq = abi.encodeWithSelector(
            v.rawFulfillRandomWords.selector,
            _requestId,
            _words
        );
        (bool success, ) = _consumer.call{gas: req.callbackGasLimit}(callReq);

        uint96 payment = uint96(
            BASE_FEE + ((startGas - gasleft()) * GAS_PRICE_LINK)
        );
        if (s_subscriptions[req.subId].balance < payment) {
            revert InsufficientBalance();
        }
        s_subscriptions[req.subId].balance -= payment;
        delete (s_requests[_requestId]);
        emit RandomWordsFulfilled(_requestId, _requestId, payment, success);
    }

    /**
     * @notice fundSubscription allows funding a subscription with an arbitrary amount for testing.
     *
     * @param _subId the subscription to fund
     * @param _amount the amount to fund
     */
    function fundSubscription(uint64 _subId, uint96 _amount) public {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        uint96 oldBalance = s_subscriptions[_subId].balance;
        s_subscriptions[_subId].balance += _amount;
        emit SubscriptionFunded(_subId, oldBalance, oldBalance + _amount);
    }

    function requestRandomWords(
        bytes32 _keyHash,
        uint64 _subId,
        uint16 _minimumRequestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords
    )
        external
        override
        onlyValidConsumer(_subId, msg.sender)
        returns (uint256)
    {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }

        uint256 requestId = s_nextRequestId++;
        uint256 preSeed = s_nextPreSeed++;

        s_requests[requestId] = Request({
            subId: _subId,
            callbackGasLimit: _callbackGasLimit,
            numWords: _numWords
        });

        emit RandomWordsRequested(
            _keyHash,
            requestId,
            preSeed,
            _subId,
            _minimumRequestConfirmations,
            _callbackGasLimit,
            _numWords,
            msg.sender
        );
        return requestId;
    }

    function createSubscription() external override returns (uint64 _subId) {
        s_currentSubId++;
        s_subscriptions[s_currentSubId] = Subscription({
            owner: msg.sender,
            balance: 0
        });
        emit SubscriptionCreated(s_currentSubId, msg.sender);
        return s_currentSubId;
    }

    function getSubscription(uint64 _subId)
        external
        view
        override
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        if (s_subscriptions[_subId].owner == address(0)) {
            revert InvalidSubscription();
        }
        return (
            s_subscriptions[_subId].balance,
            0,
            s_subscriptions[_subId].owner,
            s_consumers[_subId]
        );
    }

    function cancelSubscription(uint64 _subId, address _to)
        external
        override
        onlySubOwner(_subId)
    {
        emit SubscriptionCanceled(_subId, _to, s_subscriptions[_subId].balance);
        delete (s_subscriptions[_subId]);
    }

    modifier onlySubOwner(uint64 _subId) {
        address owner = s_subscriptions[_subId].owner;
        if (owner == address(0)) {
            revert InvalidSubscription();
        }
        if (msg.sender != owner) {
            revert MustBeSubOwner(owner);
        }
        _;
    }

    function getRequestConfig()
        external
        pure
        override
        returns (
            uint16,
            uint32,
            bytes32[] memory
        )
    {
        return (3, 2000000, new bytes32[](0));
    }

    function addConsumer(uint64 _subId, address _consumer)
        external
        override
        onlySubOwner(_subId)
    {
        if (s_consumers[_subId].length == MAX_CONSUMERS) {
            revert TooManyConsumers();
        }

        if (consumerIsAdded(_subId, _consumer)) {
            return;
        }

        s_consumers[_subId].push(_consumer);
        emit ConsumerAdded(_subId, _consumer);
    }

    function removeConsumer(uint64 _subId, address _consumer)
        external
        override
        onlySubOwner(_subId)
        onlyValidConsumer(_subId, _consumer)
    {
        address[] storage consumers = s_consumers[_subId];
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == _consumer) {
                address last = consumers[consumers.length - 1];
                consumers[i] = last;
                consumers.pop();
                break;
            }
        }

        emit ConsumerRemoved(_subId, _consumer);
    }

    function getConfig()
        external
        view
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 stalenessSeconds,
            uint32 gasAfterPaymentCalculation
        )
    {
        return (4, 2_500_000, 2_700, 33285);
    }

    function getFeeConfig()
        external
        view
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5
        )
    {
        return (
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            100000, // 0.1 LINK
            0,
            0,
            0,
            0
        );
    }

    function getFallbackWeiPerUnitLink() external view returns (int256) {
        return 4000000000000000; // 0.004 Ether
    }

    function requestSubscriptionOwnerTransfer(uint64 _subId, address _newOwner)
        external
        pure
        override
    {
        revert("not implemented");
    }

    function acceptSubscriptionOwnerTransfer(uint64 _subId)
        external
        pure
        override
    {
        revert("not implemented");
    }

    function pendingRequestExists(uint64 subId)
        public
        view
        override
        returns (bool)
    {
        revert("not implemented");
    }

    function viewBalance() external view returns (uint256) {
        return address(this).balance;
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MelXNFTPayment is Initializable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 internal _feeAmount;
    uint256 internal _minimalMel;
    uint256 public totalFeeAmount;
    uint256 public totalReferralRewardAmount;
    uint256 public amountOfReferralReward;
    address public feeReceiver;
    IERC20Upgradeable internal paymentToken;
    IERC20Upgradeable internal melToken;
    mapping(address => uint256) public referralToReward;

    event PayFee(
        address indexed minter,
        address indexed feeReceiver,
        address indexed referral,
        uint256 feeAmount,
        uint256 referralRewardAmount
    );

    function __MelXNFTPayment_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __MelXNFTPayment_init_unchained(
        uint256 __feeAmount,
        uint256 __minimalMel,
        uint256 _amountOfReferralReward,
        address _receiver,
        address _tokenPayment,
        address _tokenMel
    ) internal initializer {
        _feeAmount = __feeAmount;
        _minimalMel = __minimalMel;
        feeReceiver = _receiver;
        amountOfReferralReward = _amountOfReferralReward;
        paymentToken = IERC20Upgradeable(_tokenPayment);
        melToken = IERC20Upgradeable(_tokenMel);
    }

    function _fee(address _payer) internal {
        _fee(_payer, address(0));
    }

    function _fee(address _payer, address _referral) internal {
        require(feeReceiver != address(0), "Receiver address not set");
        require(_feeAmount > 0, "Fee Amount not set");
        require(_minimalMel > 0, "Minimal Mel Amount not set ");
        require(
            melToken.balanceOf(_payer) >= _minimalMel,
            "Minimal Mel not fulfilled"
        );

        totalFeeAmount += _feeAmount;

        if (_referral == address(0)) {
            // Transfer All fee to Fee Receiver to be burn later
            paymentToken.transferFrom(_payer, feeReceiver, _feeAmount);
        } else {
            referralToReward[_referral] += amountOfReferralReward;
            totalReferralRewardAmount += amountOfReferralReward;
            // Transfer part of fee to Fee Receiver to be burn later
            uint256 feeToBurn = _feeAmount - amountOfReferralReward;
            paymentToken.transferFrom(_payer, feeReceiver, feeToBurn);
            // Share Reward to Referral Address
            paymentToken.transferFrom(
                _payer,
                _referral,
                amountOfReferralReward
            );
        }

        emit PayFee(
            _payer,
            feeReceiver,
            _referral,
            _feeAmount,
            amountOfReferralReward
        );
    }

    function _setFeeReceiver(address _newFeeReceiver) internal {
        feeReceiver = _newFeeReceiver;
    }

    function _setReferralReward(uint256 _newAmountOfReferralReward) internal {
        require(
            _newAmountOfReferralReward < _feeAmount,
            "Referral must lower than Fee"
        );
        amountOfReferralReward = _newAmountOfReferralReward;
    }

    function _setFeeAmount(uint256 _newFeeAmount) internal {
        _feeAmount = _newFeeAmount;
    }

    function _setMinimalMelAmount(uint256 _newMinimalMelAmount) internal {
        _minimalMel = _newMinimalMelAmount;
    }

    function _setPaymentToken(address _newTokenPaymentAddress) internal {
        paymentToken = IERC20Upgradeable(_newTokenPaymentAddress);
    }

    function _setMelToken(address _newTokenMel) internal {
        melToken = IERC20Upgradeable(_newTokenMel);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../upgradeable/VRFConsumerBaseUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IMelXNFT} from "../melX/IMelXNFT.sol";
import {IEnergy} from "./IEnergy.sol";
import {IPart} from "./IPart.sol";

contract StoreV1 is
    IEnergy,
    IPart,
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    struct EnergyInfo {
        uint256 amount;
        string name;
        uint256 price;
        bool isAvailable;
    }

    struct Part {
        string name;
        uint256 statusAmount;
        uint256 price;
        bool isAvailable;
    }

    address public bbTokenAddress;
    address public melxNftAddress;
    address public feeReceiver;
    uint256 public latestPartId;
    uint256 public latestEnergyId;
    bytes32 constant SPEND_ENERGY_ROLE = keccak256("SPEND_ENERGY");
    mapping(address => uint256) public addressToEnergy;
    mapping(uint256 => EnergyInfo) public energyIdToEnergyInfo;
    mapping(uint256 => Part) public partIdToPart;

    event TopUpEnergy(
        uint256 energyAmount,
        address indexed user,
        string energyName
    );

    event UseEnergy(uint256 energyAmount, address indexed user);

    event BuyPart(uint256 partId, address indexed user);

    event NewPart(
        uint256 id,
        uint256 statusAmount,
        string name,
        uint256 price,
        bool isAvailable
    );

    event NewEnergy(
        uint256 id,
        uint256 amount,
        string name,
        uint256 price,
        bool isAvailable
    );

    event UpdatePart(
        uint256 id,
        uint256 amount,
        string name,
        uint256 price,
        bool isAvailable
    );

    event UpdateEnergy(
        uint256 id,
        uint256 amount,
        string name,
        uint256 price,
        bool isAvailable
    );

    function initialize(
        address _bbTokenAddress,
        address _melxNftAddress,
        address _feeReceiver
    ) public initializer {
        bbTokenAddress = _bbTokenAddress;
        melxNftAddress = _melxNftAddress;
        feeReceiver = _feeReceiver;
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev withdraw wrongfully transfered ERC20 token
     */
    function withdrawERC20(address _tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20Upgradeable(_tokenAddress).transfer(
            msg.sender,
            IERC20Upgradeable(_tokenAddress).balanceOf(address(this))
        );
    }

    /**
     * @dev pause function to pause contract
     * Only admin can call this contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev unpause function to pause contract
     * Only admin can call this contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setFeeReceiver(address _feeReceiver)
        external
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev Add energy data
     * @param _energyName Energy package name
     * @param _energyAmount Energy amount
     * @param _energyPrice Energy price
     * @param _isAvailable Flag if energy is available
     */
    function addEnergyPackage(
        string memory _energyName,
        uint256 _energyAmount,
        uint256 _energyPrice,
        bool _isAvailable
    ) public override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_energyAmount != 0, "Energy amount cannot be zero");
        energyIdToEnergyInfo[latestEnergyId] = EnergyInfo(
            _energyAmount,
            _energyName,
            _energyPrice,
            _isAvailable
        );

        emit NewEnergy(
            latestEnergyId,
            _energyAmount,
            _energyName,
            _energyPrice,
            _isAvailable
        );

        latestEnergyId += 1;
    }

    /**
     * @dev Add part data
     * @param _partName Part name
     * @param _statusAmount Status amount
     * @param _partPrice Part price
     * @param _isAvailable Flag if part is available
     */
    function addPartPackage(
        string memory _partName,
        uint256 _statusAmount,
        uint256 _partPrice,
        bool _isAvailable
    ) public override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_statusAmount != 0, "Status amount cannot be zero");
        partIdToPart[latestPartId] = Part(
            _partName,
            _statusAmount,
            _partPrice,
            _isAvailable
        );

        emit NewPart(
            latestEnergyId,
            _statusAmount,
            _partName,
            _partPrice,
            _isAvailable
        );

        latestPartId += 1;
    }

    /**
     * @dev Edit part data
     * @param _partId Part Id
     * @param _partName Part name
     * @param _statusAmount Status amount
     * @param _partPrice Part price
     * @param _isAvailable Flag if part is available
     */
    function editPartPackage(
        uint256 _partId,
        string memory _partName,
        uint256 _statusAmount,
        uint256 _partPrice,
        bool _isAvailable
    ) public override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_statusAmount != 0, "Status amount cannot be zero");
        require(_partId < latestPartId, "Invalid Part Id");
        partIdToPart[_partId] = Part(
            _partName,
            _statusAmount,
            _partPrice,
            _isAvailable
        );

        emit UpdatePart(
            _partId,
            _statusAmount,
            _partName,
            _partPrice,
            _isAvailable
        );

        latestPartId += 1;
    }

    /**
     * @dev Edit energy data
     * @param _energyId Energy Id
     * @param _energyName Energy package name
     * @param _energyAmount Energy amount
     * @param _energyPrice Energy price
     * @param _isAvailable Flag if energy is available
     */
    function editEnergyPackage(
        uint256 _energyId,
        string memory _energyName,
        uint256 _energyAmount,
        uint256 _energyPrice,
        bool _isAvailable
    ) public override whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_energyAmount != 0, "Energy amount cannot be zero");
        require(_energyId < latestEnergyId, "Invalid Energy Id");

        energyIdToEnergyInfo[_energyId] = EnergyInfo(
            _energyAmount,
            _energyName,
            _energyPrice,
            _isAvailable
        );

        emit UpdateEnergy(
            _energyId,
            _energyAmount,
            _energyName,
            _energyPrice,
            _isAvailable
        );
    }

    /**
     * @dev Buy part, transfer fee to feeReceiver
     * @param _partId Part Id
     */
    function buyPart(uint256 _partId) public override whenNotPaused {
        IERC20Upgradeable bbToken = IERC20Upgradeable(bbTokenAddress);
        uint256 userBalance = bbToken.balanceOf(_msgSender());

        require(_partId < latestPartId, "Invalid Part Id");
        require(partIdToPart[_partId].isAvailable, "Part package unavailable");
        require(
            userBalance >= partIdToPart[_partId].price,
            "Not enough balance to buy parts"
        );

        bbToken.transferFrom(
            _msgSender(),
            feeReceiver,
            partIdToPart[_partId].price
        );

        emit BuyPart(_partId, _msgSender());
    }

    /**
     * @dev Buy energy, transfer fee to feeReceiver
     * @param _energyId Energy Id
     */
    function buyEnergy(uint256 _energyId) public override whenNotPaused {
        IERC20Upgradeable bbToken = IERC20Upgradeable(bbTokenAddress);
        uint256 userBalance = bbToken.balanceOf(_msgSender());

        require(_energyId < latestEnergyId, "Invalid Energy Id");
        require(
            energyIdToEnergyInfo[_energyId].isAvailable,
            "Energy package unavailable"
        );
        require(
            userBalance >= energyIdToEnergyInfo[_energyId].price,
            "Not enough balance to buy energy"
        );

        bbToken.transferFrom(
            _msgSender(),
            feeReceiver,
            energyIdToEnergyInfo[_energyId].price
        );

        addressToEnergy[msg.sender] = energyIdToEnergyInfo[_energyId].amount;

        emit TopUpEnergy(
            energyIdToEnergyInfo[_energyId].amount,
            _msgSender(),
            energyIdToEnergyInfo[_energyId].name
        );
    }

    /**
     * @dev Function to deduct user energy
     */
    function useEnergy(address _address, uint256 _energy)
        public
        override
        onlyRole(SPEND_ENERGY_ROLE)
    {
        require(_energy > 0, "Energy cannot be zero");
        require(
            addressToEnergy[_address] >= _energy,
            "User dont have any energy to use"
        );
        addressToEnergy[_address] -= _energy;

        emit UseEnergy(_energy, _address);
    }

    /**
     * @dev Function to return player energy
     */
    function getPlayerEnergy(address _address)
        public
        view
        override
        returns (uint256)
    {
        return addressToEnergy[_address];
    }

    /**
     * @dev Middleware for upgradeTo function to upgrading contract
     */
    function _authorizeUpgrade(address _newImplementation)
        internal
        view
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBaseUpgradeable is
    VRFRequestIDBase,
    Initializable
{
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private USER_SEED_PLACEHOLDER;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
    {
        LINK.transferAndCall(
            vrfCoordinator,
            _fee,
            abi.encode(_keyHash, USER_SEED_PLACEHOLDER)
        );
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            USER_SEED_PLACEHOLDER,
            address(this),
            nonces[_keyHash]
        );
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    function __VRFConsumerBase_init(address _vrfCoordinator, address _link)
        internal
        initializer
    {
        __VRFConsumerBase_init_unchained(_vrfCoordinator, _link);
    }

    function __VRFConsumerBase_init_unchained(
        address _vrfCoordinator,
        address _link
    ) internal initializer {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
        USER_SEED_PLACEHOLDER = 0;
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPart {
    function editPartPackage(
        uint256 _partId,
        string memory _partName,
        uint256 _statusAmount,
        uint256 _partPrice,
        bool _isAvailable
    ) external;

    function addPartPackage(
        string memory _partName,
        uint256 _statusAmount,
        uint256 _partPrice,
        bool _isAvailable
    ) external;

    function buyPart(uint256 _partId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {SignatureVerificator} from "./SignatureVerificator.sol";
import {IMelXNFT} from "./IMelXNFT.sol";

contract MintingWithSignature is SignatureVerificator {  

    address public melXNFTContract;    
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 private constant MINTING_SIGNATURE_HASH =
        keccak256(
            "MintingSignature(address owner,uint256 randomNumber,uint32 nonce,string cid,string city)"
        );    

    struct MintingSignature {
        address owner;
        uint256 randomNumber;
        uint32 nonce;
        string cid;
        string city;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
    }

    event MintWithSignature(uint256 indexed tokenId, address owner, uint256 randomNumber, uint32 nonce, string cid); 

    constructor(address melXNFTContractAddress) SignatureVerificator() {
        melXNFTContract = melXNFTContractAddress;
    }    

    function mintNFTWithSignature(MintingSignature memory mintingSignature, bytes calldata data) external {
        _validateMintingSignature(mintingSignature);

        uint256 tokenId = IMelXNFT(melXNFTContract).safeMintWithSignature(mintingSignature.owner, mintingSignature.cid, mintingSignature.city, data);
        
        emit MintWithSignature(tokenId, mintingSignature.owner, mintingSignature.randomNumber, mintingSignature.nonce, mintingSignature.cid);
    }

    function _validateMintingSignature(MintingSignature memory mintingSignature) internal {
        // Check nonces
        require(getSignatureNonces(mintingSignature.owner) == mintingSignature.nonce,"Invalid Nonce");
        bytes memory hashSignature = _hash(mintingSignature.owner,mintingSignature.randomNumber,mintingSignature.nonce, mintingSignature.cid, mintingSignature.city);
        // Check signature
        require(_checkIsValidSigner(
            mintingSignature.sigV,
            mintingSignature.sigR,
            mintingSignature.sigS,
            hashSignature
        ),"Invalid Signature");        
        // Add nonces
        _increaseNonce(mintingSignature.owner);
    }

    function _hash(address owner,uint256 randomNumber,uint32 nonce, string memory cid, string memory city) internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                MINTING_SIGNATURE_HASH,
                owner,
                randomNumber,
                nonce,
                keccak256(bytes(cid)),
                keccak256(bytes(city))
            );
    }

    /**
     @dev Set valid/invalid signer only can be done by ADMIN
     */
    function setSigner(address signer, bool state) public {
        require(IAccessControlUpgradeable(melXNFTContract).hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Account is not an Admin");
        _setSigner(signer, state);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {EIP712} from "../EIP/EIP712.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SignatureVerificator is Initializable {
        
    mapping(address => uint32) private nonces;
    mapping(address => bool) private isSigner;  

    bytes32 public DOMAIN_SEPARATOR;    

    event SetSigner(address signer, bool state);

    constructor() {
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("mel-x-nft", "v1");
    }   

    function getSignatureNonces(address owner) public view returns (uint32) {
        return nonces[owner];
    }

    function _increaseNonce(address owner) internal {
        nonces[owner]++;
    }

    function _setSigner(address signerAddress, bool state) internal {
        isSigner[signerAddress] = state;
        emit SetSigner(signerAddress, state);
    }


    function _checkIsValidSigner(uint8 v,bytes32 r,bytes32 s, bytes memory data) internal view returns (bool){
        address signer = _getSigner(v,r,s,data);
        return isSigner[signer];
    }

    /**
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function _getSigner(uint8 v,bytes32 r,bytes32 s, bytes memory data)
        internal 
        view returns (address signer)   
    {        
        signer = EIP712.recover(
            DOMAIN_SEPARATOR,
            v,r,s,data
        );
    }    
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

import { ECRecover } from "./ECRecover.sol";

/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library EIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        return ECRecover.recover(digest, v, r, s);
    }
}

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.0;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library ECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ERC721PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract MelXNFTBasic is
    UUPSUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721PausableUpgradeable,
    AccessControlUpgradeable
{
    string private baseTokenURI;

    function __MelXNFTBasic_init(string calldata _baseTokenURI)
        internal
        initializer
    {
        __MelXNFTBasic_init_unchained(_baseTokenURI);
    }

    function __MelXNFTBasic_init_unchained(string calldata _baseTokenURI)
        internal
        initializer
    {
        baseTokenURI = _baseTokenURI;
    }

    function _setBaseURI(string calldata _newBaseURI) internal {
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Get token URI of asset, using the URI that stored on ERC721URIStorageUpgradeable
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(_tokenId);
    }

    /**
     * @dev Override _burn function of ERC721URIStorageUpgradeable and ERC721Upgradeable
     * using ERC721URIStorageUpgradeable since need to delete tokenURI data on state variable
     */
    function _burn(uint256 _tokenId)
        internal
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        ERC721URIStorageUpgradeable._burn(_tokenId);
    }

    /**
     * @dev Override _beforeTokenTransfer function of ERC721PausableUpgradeable and ERC721Upgradeable
     * using ERC721PausableUpgradeable to verify pause condition before make transaction (mint, burn, transfer)
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    ) internal virtual override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        ERC721PausableUpgradeable._beforeTokenTransfer(
            _from,
            _to,
            _tokenId,
            _batchSize
        );
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {} // solhint-disable-line no-empty-blocks

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(_interfaceId) ||
            AccessControlUpgradeable.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {
    }

    function __ERC721Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is Initializable, ERC721Upgradeable, PausableUpgradeable {
    function __ERC721Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {MelXNFTBasic} from "./MelXNFTBasic.sol";
import {MelXNFTPayment} from "./MelXNFTPayment.sol";
import {IMelXNFT} from "./IMelXNFT.sol";

contract MelXNFTV1 is IMelXNFT, MelXNFTPayment, MelXNFTBasic {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal _tokenIdCounter;
    mapping(string => uint64) public mintingLimit; // Mapping city to minting limit
    mapping(string => uint64) public cityToMinted; // Mapping city to NFT that have been minted
    mapping(uint256 => NftData) public nftIdToNftInformation;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER");
    bytes32 public constant OFF_CHAIN_MINTER_ROLE =
        keccak256("OFF_CHAIN_MINTER");
    bytes32 public constant GACHA_MINTER_ROLE = keccak256("GACHA_MINTER");

    event NewCity(string newCity, uint64 limitMinting);
    event UpdateCity(string newCity, uint64 newLimitMinting);
    event SetTokenURI(uint256 indexed tokenId, string tokenUri);

    modifier validateLimitMinting(string calldata _city) {
        require(mintingLimit[_city] > 0, "City is not set yet");
        require(
            mintingLimit[_city] > cityToMinted[_city] + 1,
            "Reach limit for minting"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string calldata _baseTokenURI,
        address _paymentTokenAddress,
        address _feeReceiverAddress,
        address _tokenMelAddress,
        uint256 _fee,
        uint256 _minimalMel,
        uint256 _referralReward
    ) public initializer {
        __ERC721Burnable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721_init_unchained(_name, _symbol);
        __AccessControl_init_unchained();
        __MelXNFTPayment_init_unchained(
            _fee,
            _minimalMel,
            _referralReward,
            _feeReceiverAddress,
            _paymentTokenAddress,
            _tokenMelAddress
        );
        __MelXNFTBasic_init_unchained(_baseTokenURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev
     * @param to is the accounts that request Minting Signature Data to API , and need to approve fee to this contract
     */
    function safeMintWithSignature(
        address _to,
        string calldata _cid,
        string calldata _city,
        bytes calldata _data
    )
        public
        override
        onlyRole(OFF_CHAIN_MINTER_ROLE)
        validateLimitMinting(_city)
        returns (uint256 nftTokenId)
    {
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(_to, tokenId, _data);
        _setTokenURI(tokenId, _cid);
        _tokenIdCounter.increment();
        cityToMinted[_city]++;

        _fee(_to); // Paying Fee

        return tokenId;
    }

    function safeMintWithGacha(
        address _to,
        string calldata _city,
        address _referralAddress,
        NftData memory _nftData
    )
        public
        override
        validateLimitMinting(_city)
        onlyRole(GACHA_MINTER_ROLE)
        returns (uint256 nftTokenId)
    {
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(_to, tokenId);
        nftIdToNftInformation[tokenId] = _nftData;
        _tokenIdCounter.increment();
        _fee(_to, _referralAddress); // Paying Fee

        return tokenId;
    }

    function setFeeReceiver(address _newFeeReceiver)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setFeeReceiver(_newFeeReceiver);
    }

    function setFeeAmount(uint256 _newFeeAmount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setFeeAmount(_newFeeAmount);
    }

    function setReferralReward(uint256 _newReferralReward)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setReferralReward(_newReferralReward);
    }

    function setMinimalMelAmount(uint256 _newMinimalMelAmount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMinimalMelAmount(_newMinimalMelAmount);
    }

    function setPaymentToken(address _newTokenPaymentAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setPaymentToken(_newTokenPaymentAddress);
    }

    function setMelToken(address _newTokenMelAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMelToken(_newTokenMelAddress);
    }

    /**
     * @dev Set Base URI for ERC 721
     */
    function setBaseURI(string calldata _newBaseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev Pause and Unpause function for pausable contract
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        PausableUpgradeable._pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        PausableUpgradeable._unpause();
    }

    /**
     * @dev Set token URI for each assets, only able to update by user wirh URI_SETTER's role
     */
    function setTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyRole(URI_SETTER_ROLE)
    {
        _setTokenURI(_tokenId, _newTokenURI);
        emit SetTokenURI(_tokenId, _newTokenURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, MelXNFTBasic)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(_interfaceId) ||
            AccessControlUpgradeable.supportsInterface(_interfaceId);
    }

    /**
     * @dev Add new city and set the minting limitation
     */
    function addNewCity(string calldata _newCity, uint64 _limitMinting)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(mintingLimit[_newCity] == 0, "City already setted");
        require(_limitMinting > 0, "Cannot set limit to 0");
        mintingLimit[_newCity] = _limitMinting;
        emit NewCity(_newCity, _limitMinting);
    }

    /**
     * @dev Update existing city and set the new minting limitation
     */
    function updateCityLimit(string calldata _city, uint64 _newLimitMinting)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(mintingLimit[_city] > 0, "City is not set yet");
        require(
            _newLimitMinting > cityToMinted[_city] && _newLimitMinting > 0,
            "New Limit too low"
        );
        mintingLimit[_city] = _newLimitMinting;
        emit UpdateCity(_city, _newLimitMinting);
    }

    function feeAmount() external view override returns (uint256) {
        return _feeAmount;
    }

    function minimalMel() external view override returns (uint256) {
        return _minimalMel;
    }

    function paymentAddress() external view override returns (address) {
        return address(paymentToken);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: invalid token ID");

        NftData memory nftInformation = nftIdToNftInformation[_tokenId];

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"description": "Bike that can be used in Melx Universe!",',
            '"image": "',
            nftInformation.imageUrl,
            '",',
            '"name" : "',
            nftInformation.name,
            " #",
            StringsUpgradeable.toString(_tokenId),
            '",',
            '"attributes": [',
            "{",
            '"trait_type": "Rarity", "value" : "',
            nftInformation.rarity,
            '"'
            "},",
            "{",
            '"trait_type": "Bike Type", "value" : "',
            nftInformation.bikeType,
            '"',
            "},",
            "{",
            '"trait_type": "Level", "value" : ',
            StringsUpgradeable.toString(nftInformation.level),
            "},",
            "{",
            '"trait_type": "Experience Point", "value" : ',
            StringsUpgradeable.toString(nftInformation.exp),
            "},",
            '{"trait_type" : "Acceleration", "value": ',
            StringsUpgradeable.toString(nftInformation.baseAcceleration),
            "},",
            '{"trait_type" : "Speed", "value": ',
            StringsUpgradeable.toString(nftInformation.baseSpeed),
            "},",
            '{"trait_type" : "Drift", "value": ',
            StringsUpgradeable.toString(nftInformation.baseDrift),
            "}",
            "]",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(dataURI)
                )
            );
    }

    function getNftBaseStat(uint256 _nftId)
        external
        view
        override
        returns (uint256)
    {
        NftData memory nftData = nftIdToNftInformation[_nftId];
        return nftData.baseAcceleration + nftData.baseSpeed + nftData.baseDrift;
    }

    function getNftData(uint256 _nftId)
        external
        view
        override
        returns (NftData memory)
    {
        return nftIdToNftInformation[_nftId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {MelXNFTV1} from "../melX/MelXNFTV1.sol";

contract MelXNFTDummyImplementation is MelXNFTV1 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../game/StoreV1.sol";

contract StoreDummyImplementation is StoreV1 {
    string public dummyUpgrade;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyUSDT is ERC20 {
    constructor() ERC20("DummyUSDT", "USDT") {
        _mint(msg.sender, 12000000 * 10**6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyMel is ERC20 {
    constructor() ERC20("DummyMel", "MEL") {
        _mint(msg.sender, 12000000 * 10**18);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyLink is ERC20 {
    constructor() ERC20("LINK", "LINK") {
        _mint(msg.sender, 12000000 * 10**18);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IWithdrawal.sol";

contract Withdrawal is IWithdrawal, Ownable, Pausable {
    using SafeMath for uint256;

    event Withdrawn(
        bytes32 indexed withdrawId,
        uint256 amount,
        address userAddress
    );

    event UpdateSigner(address signerAddress);

    event UpdatePoolAddress(address poolAddress);

    mapping(address => uint256) public nonces;
    address public bbTokenAddress;
    address public poolAddress;
    address public signerAddress;

    bytes32 DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes("BikeBattle")),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                bytes32(block.chainid)
            )
        );

    bytes32 constant WITHDRAWAL_TYPEHASH =
        keccak256(
            "Withdrawal(bytes32 withdrawId,uint256 amount,address userAddress,uint256 expiredAt,uint32 nonce)"
        );

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    constructor(
        address _bbTokenAddress,
        address _poolAddress,
        address _signerAddress
    ) {
        bbTokenAddress = _bbTokenAddress;
        poolAddress = _poolAddress;
        signerAddress = _signerAddress;
    }

    function withdraw(
        bytes32 _withdrawId,
        uint256 _amount,
        address _userAddress,
        uint256 _expiredAt,
        uint32 _nonce,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS
    ) external override whenNotPaused {
        require(block.timestamp <= _expiredAt, "Signature already expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        WITHDRAWAL_TYPEHASH,
                        _withdrawId,
                        _amount,
                        _userAddress,
                        _expiredAt,
                        _nonce
                    )
                )
            )
        );

        require(_nonce == nonces[_userAddress], "Invalid nonce");
        require(
            signerAddress == ecrecover(digest, _sigV, _sigR, _sigS),
            "Invalid signature"
        );
        nonces[_userAddress] = nonces[_userAddress].add(1);

        IERC20 bbToken = IERC20(bbTokenAddress);
        bbToken.transferFrom(poolAddress, _userAddress, _amount);

        emit Withdrawn(_withdrawId, _amount, _userAddress);
    }

    function setSignerAddress(address _signerAddress)
        external
        onlyOwner
        validAddress(_signerAddress)
    {
        signerAddress = _signerAddress;
        emit UpdateSigner(signerAddress);
    }

    function setPoolAddress(address _poolAddress)
        external
        onlyOwner
        validAddress(_poolAddress)
    {
        poolAddress = _poolAddress;
        emit UpdatePoolAddress(poolAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
pragma solidity ^0.8.0;

interface IWithdrawal {
    function withdraw(
        bytes32 _withdrawId,
        uint256 _amount,
        address _userAddress,
        uint256 _expiredAt,
        uint32 _nonce,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS
    ) external;
}