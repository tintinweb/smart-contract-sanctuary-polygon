// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155.sol";
import "./AssetPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Crafting
 * @author Jack Chuma
 * @dev Contract to facilitate crafting resources into game items in the PV Gaming Ecosystem
 */
contract Crafting is Ownable {

    uint256 public fee;
    address public rewards;
    address public lockedResources;
    address public gameItems;
    address public resources;
    AssetPool public assetPool;

    struct GameItem {
        uint256 pow;
        uint256[] resourceIds;
        uint256[] amounts;
    }

    struct UpgradeItemRequest {
        uint256 upgradeId;
        address user;
        uint256[] fromIds;
        uint256[] amountsToBurn;
        uint256[] toIds;
        uint256[] toAmounts;
    }

    struct SubscriptRequest {
        uint256 subscriptId;
        address user;
        uint256[] resourceIds;
        uint256[] resourceAmounts;
        uint256[] itemIds;
        uint256[] itemAmounts;
    }

    struct DestroyRequest {
        uint256 destroyId;
        address destroyer;
        address prey;
        address to;
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256[] resourceIds;
        uint256[] resourceAmounts;
    }

    error ZeroAddress();
    error InvalidCaller();
    error InvalidFee();
    error MustUpdateState();
    error LengthMismatch();

    event ItemUpgraded(
        uint256 indexed upgradeId,
        address indexed user,
        uint256[] fromIds,
        uint256[] amountsBurned,
        uint256[] toIds,
        uint256[] amountsSent
    );

    event Subscript(
        uint256 indexed subscriptId,
        address indexed user,
        uint256[] resourceIds,
        uint256[] resourceAmounts,
        uint256[] itemIds,
        uint256[] itemAmounts
    );

    event Destroy(
        uint256 indexed destroyId,
        address indexed destroyer,
        address indexed prey,
        address to,
        uint256[] itemIds,
        uint256[] itemAmounts,
        uint256[] resourceIds,
        uint256[] resourceAmounts
    );

    event FeeUpdated(
        uint256 indexed fee
    );

    event RewardsAddressUpdated(
        address indexed rewardsAddress
    );

    event LockedResourcesAddressUpdated(
        address indexed lockedResourcesAddress
    );

    event GameItemsAddressUpdated(
        address indexed gameItemsAddress
    );

    event ResourcesAddressUpdated(
        address indexed resourcesAddress
    );

    constructor(
        uint256 _fee, 
        address _rewards, 
        address _lockedResources, 
        address _gameItems, 
        address _resources,
        address _assetPool
    ) {
        if (
            _rewards == address(0) || 
            _lockedResources == address(0) || 
            _gameItems == address(0) || 
            _resources == address(0) || 
            _assetPool == address(0)
        ) revert ZeroAddress();
        if (_fee > 1000000000000000000) revert InvalidFee();

        fee = _fee;
        rewards = _rewards;
        lockedResources = _lockedResources;
        gameItems = _gameItems;
        resources = _resources;
        assetPool = AssetPool(_assetPool);
    }

    /**
     * @notice Called by contract owner to update crafting fee
     * @dev Fee is a number between 0 and 10 ** 18 to be used as a percentage
     * @param _fee New fee value to be stored
     */
    function setFee(uint256 _fee) external onlyOwner {
        if (_fee > 1000000000000000000) revert InvalidFee();
        if (_fee == fee) revert MustUpdateState();
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /**
     * @notice Called by contract owner to update stored Rewards contract address
     * @param _rewards Address of Rewards contract
     */
    function updateRewardsAddress(address _rewards) external onlyOwner {
        if (_rewards == address(0)) revert ZeroAddress();
        if (_rewards == rewards) revert MustUpdateState();
        rewards = _rewards;
        emit RewardsAddressUpdated(_rewards);
    }

    /**
     * @notice Called by contract owner to update stored Locked Resources contract address
     * @param _lockedResources Address of LockedResources contract
     */
    function updateLockedResources(address _lockedResources) external onlyOwner {
        if (_lockedResources == address(0)) revert ZeroAddress();
        if (_lockedResources == lockedResources) revert MustUpdateState();
        lockedResources = _lockedResources;
        emit LockedResourcesAddressUpdated(_lockedResources);
    }

    /**
     * @notice Called by contract owner to update stored Game Items contract address
     * @param _gameItems Address of GameItems contract
     */
    function updateGameItems(address _gameItems) external onlyOwner {
        if (_gameItems == address(0)) revert ZeroAddress();
        if (_gameItems == gameItems) revert MustUpdateState();
        gameItems = _gameItems;
        emit GameItemsAddressUpdated(_gameItems);
    }

    /**
     * @notice Called by contract owner to update stored Resources contract address
     * @param _resources Address of Resources contract
     */
    function updateResources(address _resources) external onlyOwner {
        if (_resources == address(0)) revert ZeroAddress();
        if (_resources == resources) revert MustUpdateState();
        resources = _resources;
        emit ResourcesAddressUpdated(_resources);
    }

    /**
     * @notice Called by contract owner to upgrade an item on behalf of user
     * @dev Burns items being traded in and transfers upgraded item to user
     * @param _requests Array of requests with `UpgradeItemRequest` structure to enable batching
     */
    function upgradeItems(
        UpgradeItemRequest[] calldata _requests
    ) external onlyOwner {
        uint256 _len = _requests.length;

        for (uint i = 0; i < _len; ) {
            UpgradeItemRequest calldata _request = _requests[i];

            if (_request.fromIds.length != _request.toIds.length) revert LengthMismatch();

            IERC1155(gameItems).burnBatch(
                _request.user, 
                _request.fromIds, 
                _request.amountsToBurn
            );

            IERC1155(gameItems).mintBatch(
                _request.user,
                _request.toIds,
                _request.toAmounts
            );

            emit ItemUpgraded(
                _request.upgradeId,
                _request.user,
                _request.fromIds,
                _request.amountsToBurn,
                _request.toIds,
                _request.toAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by Rewards contract to fulfill a game item reward
     * @dev Locks resources and sends game item to user
     * @param _user Address of user who earned the reward
     * @param _resourceIds Array of resource IDs to be locked in game item
     * @param _amounts Array of amounts of each resource to be locked in game item
     * @param _itemIds Array of IDs of game item to send to user
     */
    function craftGameItem(
        address _user,
        uint256[] calldata _resourceIds,
        uint256[] calldata _amounts,
        uint256[] calldata _itemIds,
        uint256[] calldata _itemAmounts
    ) external {
        if (msg.sender != rewards) revert InvalidCaller();

        IERC1155(resources).safeBatchTransferFrom(
            address(assetPool), 
            lockedResources, 
            _resourceIds, 
            _amounts, 
            ""
        );

        IERC1155(gameItems).safeBatchTransferFrom(
            address(assetPool), 
            _user, 
            _itemIds, 
            _itemAmounts, 
            ""
        );
    }

    /**
     * @notice Called by contract owner to subscript a game item for a user
     * @dev Locks resources and sends game item to user
     * @param _requests Array of subscript requests containing data in `SubscriptRequest` structure
     */
    function subscript(
        SubscriptRequest[] calldata _requests
    ) external onlyOwner {
        uint256 _len = _requests.length;

        for (uint i=0; i<_len; ) {
            SubscriptRequest calldata _request = _requests[i];

            // calc POW out from Resources in
            uint256 powOut = assetPool.calcPOWOutFromResourcesIn(
                _request.resourceIds, 
                _request.resourceAmounts
            );

            // burn resources
            IERC1155(resources).safeBatchTransferFrom(
                _request.user, 
                lockedResources, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                ""
            );

            // Calc fee using feePercentage
            uint256 powFee = powOut * fee / 1000000000000000000;

            // send POW fee from assetPool to Rewards contract
            assetPool.transfer(rewards, powFee);

            // send game items to user
            IERC1155(gameItems).safeBatchTransferFrom(
                address(assetPool),
                _request.user,
                _request.itemIds,
                _request.itemAmounts,
                ""
            );

            emit Subscript(
                _request.subscriptId, 
                _request.user, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                _request.itemIds,
                _request.itemAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked resources
     * @dev Burns game item and sends locked resources to `to` address
     * @param _requests Array of destroy for resources requests with `DestroyRequest` structure
     */
    function destroyForResources(
        DestroyRequest[] calldata _requests
    ) external onlyOwner {
        uint256 len = _requests.length;

        for (uint i = 0; i < len; ) {
            DestroyRequest calldata _request = _requests[i];

            //Burn Game Item
            IERC1155(gameItems).burnBatch(_request.prey, _request.itemIds, _request.itemAmounts);

            // If we're sending the resources back to AssetPool, return locked POW to Rewards contract
            if (_request.to == address(assetPool)) {
                uint256 _powVal = assetPool.calcPOWOutFromResourcesIn(_request.resourceIds, _request.resourceAmounts);
                assetPool.transfer(rewards, _powVal);
            }

            // Send locked resources to _request.to
            IERC1155(resources).safeBatchTransferFrom(
                lockedResources, 
                _request.to, 
                _request.resourceIds, 
                _request.resourceAmounts, 
                ""
            );

            emit Destroy(
                _request.destroyId,
                _request.destroyer, 
                _request.prey, 
                _request.to,
                _request.itemIds, 
                _request.itemAmounts,
                _request.resourceIds, 
                _request.resourceAmounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked POW
     * @dev Burns game item and sends locked POW to `to` address
     * @param _requests Array of destroy for pow requests with `DestroyRequest` structure
     */
    function destroyForPow(
        DestroyRequest[] calldata _requests
    ) external onlyOwner {
        uint256 len = _requests.length;

        for (uint i = 0; i < len; ) {
            DestroyRequest calldata _request = _requests[i];

            //Burn Game Item
            IERC1155(gameItems).burnBatch(_request.prey, _request.itemIds, _request.itemAmounts);

            // Calculate POW value
            uint256 _powVal = assetPool.calcPOWOutFromResourcesIn(_request.resourceIds, _request.resourceAmounts);

            // If we're sending the POW back to Rewards, return locked Resources to AssetPool contract. Otherwise, burn resources
            if (_request.to == rewards) {
                // Send locked resources to AssetPool
                IERC1155(resources).safeBatchTransferFrom(
                    lockedResources, 
                    address(assetPool), 
                    _request.resourceIds, 
                    _request.resourceAmounts, 
                    ""
                );
            } else {
                IERC1155(resources).burnBatch(lockedResources, _request.resourceIds, _request.resourceAmounts);
            }

            assetPool.transfer(_request.to, _powVal);

            emit Destroy(
                _request.destroyId,
                _request.destroyer, 
                _request.prey, 
                _request.to,
                _request.itemIds, 
                _request.itemAmounts,
                _request.resourceIds, 
                _request.resourceAmounts
            );

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

    /**
     * @notice Called by contract owner to add new resources
     * @dev Mints new Resources to AssetPool contract
     * @dev Can only create resources that don't already exist
     * @param _to Address to mint assets to
     * @param _ids Array of resources IDs to add
     * @param _amounts Array of amount of each resource to mint
     */
    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Called by whitelisted address to burn a batch of Resources
     * @param _from Address that owns Resources to burn
     * @param _ids Array of Resource IDs
     * @param _amounts Array of amounts of each Resource to burn
     */
    function burnBatch(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

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
pragma solidity ^0.8.9;

import "./Balancer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IERC1155.sol";

contract AssetPool is Ownable, ERC1155Holder {

    address public pow;
    address public resources;
    address public crafting;
    uint256 public powCoefficient;

    event ResourcesAddressSet(
        address indexed resourcesAddress
    );

    event PowCoefficientUpdated(
        uint256 indexed coefficient
    );

    event CraftingAddressSet(
        address indexed craftingAddress
    );

    error LengthMismatch();
    error DuplicateFound();
    error RoundingError();
    error POWMismatch();
    error InvalidSender();
    error MustUpdateState();
    error ZeroAddress();
    error SlippageExceeded();

    constructor(address _pow, uint256 _powCoefficient) {
        if (_pow == address(0)) revert ZeroAddress();
        pow = _pow;
        powCoefficient = _powCoefficient;
    }

    /**
     * @dev Called by contract owner in deploy script to set stored Resources contract address
     * @dev Can only be called once
     */
    function setResourcesAddress(address _resources) external onlyOwner {
        if (_resources == address(0)) revert ZeroAddress();
        if (_resources == resources) revert MustUpdateState();
        resources = _resources;
        emit ResourcesAddressSet(_resources);
    }

    /**
     * @notice Called by contract owner to update stored POW coefficient
     * @dev powCoefficient is used to set initial value in the Balancer pool
     * @param _newCoeff Value in wei
     */
    function updatePowCoefficient(uint256 _newCoeff) external onlyOwner {
        if (_newCoeff == powCoefficient) revert MustUpdateState();
        powCoefficient = _newCoeff;
        emit PowCoefficientUpdated(_newCoeff);
    }

    /**
     * @notice Called by contract owner to set stored address for Crafting contract
     * @param _crafting Address of Crafting contract
     */
    function setCraftingAddress(address _crafting) external onlyOwner {
        if (_crafting == address(0)) revert ZeroAddress();
        if (_crafting == crafting) revert MustUpdateState();
        crafting = _crafting;
        emit CraftingAddressSet(_crafting);
    }

    /**
     * @notice Called by contract owner to withdraw POW from this contract
     * @param _to Address to send POW to
     * @param _amount Amount of POW to send
     */
    function withdrawPOW(address _to, uint256 _amount) external onlyOwner {
        IERC20(pow).transfer(_to, _amount);
    }

    /**
     * @notice Called by Crafting contract to transfer $POW
     * @param _to Address to transfer $POW to
     * @param _amount Amount of $POW to transfer
     */
    function transfer(address _to, uint256 _amount) external {
        if (msg.sender != crafting) revert InvalidSender();
        IERC20(pow).transfer(_to, _amount);
    }

    /**
     * @notice Utility function to calculate how many units of certain resources can be bought with an amount of $POW
     * @param _powIn Total $POW value of resources earned
     * @param _resourceIds Array of resource IDs
     * @param _powSplitUp Individual POW amounts allocated to each resource (must add up to powIn)
     */
    function calcResourcesOutFromPOWIn(
        uint256 _powIn,
        uint256[] memory _resourceIds,
        uint256[] memory _powSplitUp,
        uint256[] memory _minAmountsOut
    ) external view returns (uint256[] memory) {
        uint256 _len = _resourceIds.length;

        if (
            _len != _powSplitUp.length ||
            _len != _minAmountsOut.length
        ) revert LengthMismatch();

        uint256 _totalPOWUsed;
        uint256[] memory _amounts = new uint256[](_len);
        uint256[] memory _idList = new uint256[](_len);

        for (uint256 i = 0; i < _len; ) {
            uint256 _id = _resourceIds[i];

            if (!idNotDuplicate(_idList, _id, i)) revert DuplicateFound();

            _idList[i] = _id;
            uint256 _amountI = _powSplitUp[i];

            // Use Balancer equation to calculate how much of this Resource will
            // come out from this amount of POW being traded in
            _amounts[i] = Balancer.outGivenIn(
                IERC1155(resources).balanceOf(address(this), _id), //balanceO
                IERC20(pow).balanceOf(address(this)) + powCoefficient + _totalPOWUsed, //balanceI
                _amountI
            );

            if (_amounts[i] < _minAmountsOut[i]) revert SlippageExceeded();
            if (_amounts[i] == 0) revert RoundingError();
            _totalPOWUsed += _amountI;
            unchecked { ++i; }
        }
        // Check that total POW spent is equal to _powIn value in request
        if (_totalPOWUsed != _powIn) revert POWMismatch();
        return _amounts;
    }

    /**
     * @notice Utility function to calculate how much POW will be received after turning in a batch of resources
     * @param _resourceIds Array of resource IDs
     * @param _amountsIn Array of amounts of each resource being traded in
     */
    function calcPOWOutFromResourcesIn(
        uint256[] calldata _resourceIds,
        uint256[] calldata _amountsIn
    ) external view returns (uint256 _amountPOW) {
        uint256 _len = _resourceIds.length;
        if (_len != _amountsIn.length) revert LengthMismatch();

        uint256[] memory _idList = new uint256[](_len);

        for (uint256 i = 0; i < _len; ) {
            uint256 _id = _resourceIds[i];

            if (!idNotDuplicate(_idList, _id, i)) revert DuplicateFound();

            _idList[i] = _id;

            // Use Balancer equation to calculate how much POW will come out
            // from this Resource being traded in
            uint256 _amountO = Balancer.outGivenIn(
                IERC20(pow).balanceOf(address(this)) + powCoefficient - _amountPOW, // balanceO
                IERC1155(resources).balanceOf(address(this), _id), // balanceI
                _amountsIn[i]
            );
            if (_amountO == 0) revert RoundingError();
            _amountPOW += _amountO;
            unchecked { ++i; }
        }
    }

    /**
     * @notice Utility function to calculate how much POW is required to get certain amounts of Resources out
     * @param _resourceIds Array of resource IDs
     * @param _amountsOut Array of amounts of each resource desired
     */
    function calcPowInFromResourcesOut(
        uint256[] calldata _resourceIds,
        uint256[] calldata _amountsOut
    ) external view returns (uint256 _powIn) {
        uint256 _len = _resourceIds.length;
        if (_len != _amountsOut.length) revert LengthMismatch();

        uint256[] memory _idList = new uint256[](_len);

        for (uint256 i = 0; i < _len; ) {
            uint256 _id = _resourceIds[i];

            if (!idNotDuplicate(_idList, _id, i)) revert DuplicateFound();

            _idList[i] = _id;

            // Use Balancer equation to calculate how much POW will come out
            // from this Resource being traded in
            uint256 _amountI = Balancer.inGivenOut(
                IERC20(pow).balanceOf(address(this)) + powCoefficient + _powIn, // balanceI
                IERC1155(resources).balanceOf(address(this), _id), // balanceO
                _amountsOut[i] // amountO
            );
            if (_amountI == 0) revert RoundingError();
            _powIn += _amountI;
            unchecked { 
                ++i; 
            }
        }
    }

    /**
     * @notice Private utility function that returns true if no duplicates are found and false if a duplicate is found in an array
     * @param _idList Array of uint256s to check
     * @param _id ID that we are checking for duplicates of
     * @param len Integer representing how many elements to check in _idList
     */
    function idNotDuplicate(
        uint256[] memory _idList,
        uint256 _id,
        uint256 len
    ) private pure returns (bool) {
        for (uint256 i = 0; i < len; ) {
            if (_idList[i] == _id) return false;
            unchecked { 
                ++i; 
            }
        }
        return true;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Balancer
 * @author Jack Chuma
 * @dev Computes out-given-in amounts based on balancer trading formulas that maintain a ratio of tokens in a contract
 * @dev wI and wO currently omitted from this implementation since they will always be equal for MHU
 */
library Balancer {
    /*
     * aO - amount of token o being bought by trader
     * bO - balance of token o, the token being bought by the trader
     * bI - balance of token i, the token being sold by the trader
     * aI - amount of token i being sold by the trader
     * wI - the normalized weight of token i
     * wO - the normalized weight of token o
    */
    uint256 public constant BONE = 10 ** 18;

    /**********************************************************************************
    // Out-Given-In                                                                  //
    // aO = amountO                                                                  //
    // bO = balanceO                    /      /     bI        \    (wI / wO) \      //
    // bI = balanceI         aO = bO * |  1 - | --------------  | ^            |     //
    // aI = amountI                     \      \   bI + aI     /              /      //
    // wI = weightI                                                                  //
    // wO = weightO                                                                  //
    **********************************************************************************/
    function outGivenIn(
        uint256 balanceO,
        uint256 balanceI,
        uint256 amountI
    ) internal pure returns (uint256 amountO) {
        uint y = bdiv(balanceI, (balanceI + amountI));
        uint foo = BONE - y;
        amountO = bmul(balanceO, foo);
    }

    /**********************************************************************************
    // calcInGivenOut                                                                //
    // aI = tokenAmountIn                 /  /     bO      \       \                 //
    // bO = tokenBalanceOut   aI =  bI * |  | ------------  |  - 1  |                //
    // bI = tokenBalanceIn                \  \ ( bO - aO ) /       /                 //
    // aO = tokenAmountOut                                                           //
    **********************************************************************************/
    function inGivenOut(
        uint tokenBalanceIn,
        uint tokenBalanceOut,
        uint tokenAmountOut
    )
        public pure
        returns (uint tokenAmountIn)
    {
        uint y = bdiv(tokenBalanceOut, (tokenBalanceOut - tokenAmountOut));
        tokenAmountIn = bmul(tokenBalanceIn, (y - BONE));
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * BONE;
        uint c1 = c0 + (b / 2);
        uint c2 = c1 / b;
        return c2;
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        uint c1 = c0 + (BONE / 2);
        uint c2 = c1 / BONE;
        return c2;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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