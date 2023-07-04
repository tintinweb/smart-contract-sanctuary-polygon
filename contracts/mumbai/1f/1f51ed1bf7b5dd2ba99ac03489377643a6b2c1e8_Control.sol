// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IRegistry.sol";
import "./interfaces/INFTGoods.sol";
import "./interfaces/ILootBoxNFT.sol";
import "./interfaces/IControl.sol";
import "./Governed.sol";
import "./Constants.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "forge-deploy-proxy/ForgeDeploy_Proxied.sol";

contract Control is Initializable, Proxied, Governed {
    mapping(address => mapping(uint256 => uint256)) public tensOfThousands;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public hundreds;

    IRegistry public registry;

    constructor() {}

    // solhint-disable-next-line
    function saveNFTGoodsInformation(address nft, uint256 id, address from, address to) external {
        IRegistry tempRegistry = registry;

        if (tempRegistry.getNFTGoodsId(msg.sender) == 0) {
            revert ControlNotNFTGoods();
        }

        uint256 tenThousand = id / BIG_PACK_SIZE;
        uint256 hundred = (id % BIG_PACK_SIZE) / SMALL_PACK_SIZE;

        if (to == tempRegistry.root()) {
            if (hundreds[nft][tenThousand][hundred] == SMALL_PACK_SIZE) {
                --tensOfThousands[nft][tenThousand];
            }
            --hundreds[nft][tenThousand][hundred];
        } else {
            ++hundreds[nft][tenThousand][hundred];
            if (hundreds[nft][tenThousand][hundred] == SMALL_PACK_SIZE) {
                ++tensOfThousands[nft][tenThousand];
            }
        }
    }

    function openLootBox(uint256 lootBoxNFTId, address nftGoods) external {
        IRegistry tempRegistry = registry;
        ILootBoxNFT lootBoxNFT = ILootBoxNFT(tempRegistry.getLootBoxNFT());
        INFTGoods nftGoodsContract = INFTGoods(nftGoods);
        uint256 collectionId = lootBoxNFT.getCollectionId(lootBoxNFTId);
        uint256 nftGoodsId = tempRegistry.getNFTGoodsId(nftGoods);
        address root = tempRegistry.root();

        if (msg.sender != tx.origin) {
            revert ControlNotWallet();
        }
        if (lootBoxNFT.ownerOf(lootBoxNFTId) != msg.sender) {
            revert ControlNotAnOwnerOfNFT();
        }
        if (!tempRegistry.checkConnection(collectionId, nftGoodsId)) {
            revert ControlConnectionDoesntExist();
        }

        uint256[] memory randomNumbers = getRandomNumbers(3);

        uint256 tenThousand = getRandomTenThousand(randomNumbers[0], nftGoods);
        uint256 hundred = getRandomHundred(randomNumbers[1], nftGoods, tenThousand);
        uint256 mintId = getRandomToken(randomNumbers[2], root, nftGoodsContract, tenThousand, hundred);

        lootBoxNFT.burn(lootBoxNFTId);
        nftGoodsContract.transferFrom(root, msg.sender, mintId);
    }

    function initialize(address _registry) public proxied initializer {
        registry = IRegistry(_registry);
        setGovernor(msg.sender);
    }

    function getRandomTenThousand(uint256 randomNumber, address nftGoods) internal view returns (uint256) {
        uint256 countTensOfThousandsNFT = INFTGoods(nftGoods).countTensOfThousands();
        uint256 randomTenThousand = randomNumber % countTensOfThousandsNFT;
        uint256 tempTenThousand = randomTenThousand;

        for (; tempTenThousand < countTensOfThousandsNFT; ) {
            if (tensOfThousands[nftGoods][tempTenThousand] < SMALL_PACK_SIZE) break;
            unchecked {
                ++tempTenThousand;
            }
        }
        if (tempTenThousand == countTensOfThousandsNFT) {
            for (tempTenThousand = 0; tempTenThousand < randomTenThousand; ) {
                if (tensOfThousands[nftGoods][tempTenThousand] < SMALL_PACK_SIZE) break;
                unchecked {
                    ++tempTenThousand;
                }
            }
            if (tempTenThousand == randomTenThousand) {
                revert ControlNoNFTGoodsLeft();
            }
        }

        return tempTenThousand;
    }

    function getRandomHundred(
        uint256 randomNumber,
        address nftGoods,
        uint256 tenThousand
    ) internal view returns (uint256) {
        uint256 randomHundred = randomNumber % SMALL_PACK_SIZE;
        uint256 tempHundred = randomHundred;

        for (; tempHundred < SMALL_PACK_SIZE; ) {
            if (hundreds[nftGoods][tenThousand][tempHundred] < SMALL_PACK_SIZE) break;
            unchecked {
                ++tempHundred;
            }
        }
        if (tempHundred == SMALL_PACK_SIZE) {
            for (tempHundred = 0; tempHundred < randomHundred; ) {
                if (hundreds[nftGoods][tenThousand][tempHundred] < SMALL_PACK_SIZE) break;
                unchecked {
                    ++tempHundred;
                }
            }
        }

        return tempHundred;
    }

    function getRandomToken(
        uint256 randomNumber,
        address root,
        INFTGoods nftGoodsContract,
        uint256 tenThousand,
        uint256 hundred
    ) internal view returns (uint256) {
        uint256 randomUnit = randomNumber % SMALL_PACK_SIZE;
        uint256 tempUnit = randomUnit;
        uint256 tokenId;

        for (; tempUnit < SMALL_PACK_SIZE; ) {
            tokenId = tenThousand * BIG_PACK_SIZE + hundred * SMALL_PACK_SIZE + tempUnit;
            if (nftGoodsContract.ownerOf(tokenId) == root && nftGoodsContract.getStatus(tokenId) == Status.Packed)
                break;
            unchecked {
                ++tempUnit;
            }
        }
        if (tempUnit == SMALL_PACK_SIZE) {
            for (tempUnit = 0; tempUnit < randomUnit; ) {
                tokenId = tenThousand * BIG_PACK_SIZE + hundred * SMALL_PACK_SIZE + tempUnit;
                if (nftGoodsContract.ownerOf(tokenId) == root && nftGoodsContract.getStatus(tokenId) == Status.Packed)
                    break;
                unchecked {
                    ++tempUnit;
                }
            }
        }

        return tokenId;
    }

    function getRandomNumbers(uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory randomNumbers = new uint256[](n);
        randomNumbers[0] = 0;
        randomNumbers[1] = 0;
        randomNumbers[2] = 0;
        // uint256 initialRandomNumber = uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             msg.sender,
        //             block.coinbase,
        //             block.timestamp,
        //             block.prevrandao,
        //             blockhash(block.number - 1)
        //         )
        //     )
        // );
        // randomNumbers[0] = initialRandomNumber;
        // for (uint256 i = 1; i < n; ) {
        //     randomNumbers[i] = uint256(keccak256(abi.encode(initialRandomNumber, i)));
        //     unchecked {
        //         ++i;
        //     }
        // }
        return randomNumbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error RegistryNFTGoodsAlreadyAdded(address nftGoods);
error RegistryNonExistentNFTGoodsId();
error RegistryConnectionAlreadyAdded(uint256 collectionId, uint256 nftGoodsId);
error RegistryConnectionDoesntExist(uint256 collectionId, uint256 nftGoodsId);

interface IRegistry {
    function setControl(address control) external;

    function setLootBoxNFT(address lootBoxNFT) external;

    function setStaking(address staking) external;

    function setHoldingAwardsPool(address holdingAwardsPool) external;

    function addNFTGoods(address[] memory nftGoods) external;

    function changeNFTGoods(uint256 id, address nftGoods) external;

    function changeConnectionsLootBox(uint256 idCollection, uint256[] memory nftGoods, bool add) external;

    function setRoot(address newRoot) external;

    function getNFTGoodsAddr(uint256 id) external view returns (address);

    function getNFTGoodsPage(uint256 amountElementsOnPage, uint256 pageNumber) external view returns (address[] memory);

    function getNFTGoodsAmount() external view returns (uint256);

    function getConnectionsLootBoxPage(
        uint256 idCollection,
        uint256 amountElementsOnPage,
        uint256 pageNumber
    ) external view returns (uint256[] memory);

    function getConnectionsNFTGoodsPage(
        uint256 nftGoodsId,
        uint256 amountElementsOnPage,
        uint256 pageNumber
    ) external view returns (uint256[] memory);

    function checkConnection(uint256 idCollection, uint256 nftGoodsId) external view returns (bool);

    function getControl() external view returns (address);

    function getLootBoxNFT() external view returns (address);

    function getStaking() external view returns (address);

    function getHoldingAwardsPool() external view returns (address);

    function getNFTGoodsId(address nftGoods) external view returns (uint256);

    function root() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum Status {
    Packed,
    Unpacked
}

error NFTGoodsMaxStatusReached();
error NFTGoodsTransferNotAllowed();
error NFTGoodsNotAnOwnerOfNFT();
error NFTGoodsCountNFTsIsZero();

interface INFTGoods is IERC721 {
    event StatusUpgraded(uint256 tokenId, Status newStatus);
    event TokenURIChanged(uint256 tokenId, string newURI);

    function upgradeStatus(uint256 tokenId) external;

    function changeTokenURI(uint256 tokenId, string memory newURI) external;

    function mint(address to, uint256 tokenId, string memory uri) external;

    function burn(uint256 tokenId) external;

    function setCountTensOfThousands(uint256 _countTensOfThousands) external;

    function getStatus(uint256 tokenId) external view returns (Status);

    function countTensOfThousands() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILootBoxNFT is IERC721 {
    event CollectionURIChanged(uint256 collectionId, string newURI);

    function changeCollectionURI(uint256 collectionId, string memory newURI) external;

    function mint(address to, uint256 collectionId) external;

    function burn(uint256 tokenId) external;

    function balanceOf(address owner, uint256 collectionId) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function collectionTotalSupply(uint256 collectionId) external view returns (uint256);

    function getCollectionId(uint256 tokenId) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error ControlNotNFTGoods();
error ControlNotWallet();
error ControlNotAnOwnerOfNFT();
error ControlConnectionDoesntExist();
error ControlNoNFTGoodsLeft();

interface IControl {
    function saveNFTGoodsInformation(address nft, uint256 id, address from, address to) external;

    function openLootBox(uint256 lootBoxNFTId, address nftGoods) external;

    function tensOfThousands(address nft, uint256 tenThousand) external view returns (uint256);

    function hundreds(address nft, uint256 tenThousand, uint256 hundred) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

uint256 constant BIG_PACK_SIZE = 10000;
uint256 constant SMALL_PACK_SIZE = 100;

uint256 constant TIME_FOR_DEACTIVATION_STACKING = 15;
uint256 constant TIME_FOR_START_PASSIVE_STACKING = 15;
uint256 constant TIME_FOR_FR3_STACKING = 90;
uint256 constant TIME_FOR_FR6_STACKING = 180;
uint256 constant TIME_FOR_FR1Y_STACKING = 365;
uint256 constant TIME_FOR_FR2Y_STACKING = 730;
uint256 constant TIME_FOR_FR5Y_STACKING = 1825;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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