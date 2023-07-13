// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 */

pragma solidity ^0.8.9;

import "TerminusFacet.sol";
import "IERC20.sol";
import "IERC1155.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "ERC1155Holder.sol";

import "ControllableWithTerminus.sol";
import "LootboxRandomness.sol";

/**
 * @title Moonstream Lootbox managing contract
 * @author Moonstream Engineering ([email protected])
 * @notice You can create lootboxes represented by terminus pools that includes ERC20 and ERC1155 tokens
 */
contract Lootbox is
    ERC1155Holder,
    ControllableWithTerminus,
    LootboxRandomness,
    Pausable,
    ReentrancyGuard
{
    address public terminusAddress;
    address public administratorTerminusAddress;
    uint256 private _totalLootboxCount;

    uint256 public ERC20_REWARD_TYPE = 20;
    uint256 public ERC1155_REWARD_TYPE = 1155;
    uint256 public TERMINUS_MINTABLE_REWARD_TYPE = 1;

    uint256 public ORDINARY_LOOTBOX_TYPE = 0;
    uint256 public RANDOM_LOOTBOX_TYPE_1 = 1;

    /**
     * @dev Lootbox item structure
     * @notice Only for erc20 and erc1155 tokens
     */

    struct LootboxItem {
        uint256 rewardType; // reward type: 20 for ERC20, 1155 for ERC1155
        address tokenAddress; // address of the token
        uint256 tokenId; // id of the token, any number for erc20
        uint256 amount; // amount of the token
        uint256 weight; // weight of item (only for random lootboxes)
    }

    // Mapping from lootbox id to lootbox items (access by index)
    mapping(uint256 => mapping(uint256 => LootboxItem)) private lootboxItems;
    // Mapping from lootbox id to lootbox item count
    mapping(uint256 => uint256) private lootboxItemCounts;

    mapping(uint256 => uint256) public terminusPoolIdbyLootboxId;
    mapping(uint256 => uint256) public lootboxIdbyTerminusPoolId;

    mapping(uint256 => uint256) public lootboxTypebyLootboxId;
    // 0 => ordinary lootbox
    // 1 => random lootbox

    event LootboxCreated(uint256 indexed lootboxId);
    event LootboxItemAdded(uint256 indexed lootboxId, LootboxItem lootboxItem);
    event LootboxItemRemoved(
        uint256 indexed lootboxId,
        LootboxItem lootboxItem
    );
    // How to call the user who opened the lootbox?
    event LootboxOpened(
        uint256 indexed lootboxId,
        address opener,
        uint256 lootboxItemCount
    );

    /**
     * @dev Initializes the Lootbox contract with the terminus address and administrator pool id.
     * @param _terminusAddress The address of the Terminus contract.
     * @param _administratorPoolId The id of the administrator terminus pool.
     */
    constructor(
        address _terminusAddress,
        address _administratorTerminusAddress,
        uint256 _administratorPoolId,
        address _VRFCoordinatorAddress,
        address _LinkTokenAddress,
        uint256 _ChainlinkVRFFee,
        bytes32 _ChainlinkVRFKeyhash
    )
        ControllableWithTerminus(
            _administratorTerminusAddress,
            _administratorPoolId
        )
        LootboxRandomness(
            _VRFCoordinatorAddress,
            _LinkTokenAddress,
            _ChainlinkVRFFee,
            _ChainlinkVRFKeyhash
        )
    {
        terminusAddress = _terminusAddress;
        administratorTerminusAddress = _administratorTerminusAddress;
    }

    function mintLootbox(
        uint256 lootboxId,
        address recipient,
        uint256 amount,
        bytes memory data
    ) public onlyAdministrator nonReentrant {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        terminusContract.mint(recipient, lootboxTerminusPoolId, amount, data);
    }

    function batchMintLootboxes(
        uint256 lootboxId,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) public onlyAdministrator nonReentrant {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);

        terminusContract.poolMintBatch(
            lootboxTerminusPoolId,
            toAddresses,
            amounts
        );
    }

    function batchMintLootboxesConstant(
        uint256 lootboxId,
        address[] memory toAddresses,
        uint256 amount
    ) public onlyAdministrator nonReentrant {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);

        for (uint256 i = 0; i < toAddresses.length; i++) {
            terminusContract.mint(
                toAddresses[i],
                lootboxTerminusPoolId,
                amount,
                ""
            );
        }
    }

    function getLootboxURI(
        uint256 lootboxId
    ) public view returns (string memory) {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        return terminusContract.uri(lootboxTerminusPoolId);
    }

    function setLootboxURI(
        uint256 lootboxId,
        string memory uri
    ) public onlyAdministrator {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        terminusContract.setURI(lootboxTerminusPoolId, uri);
    }

    function getLootboxBalance(
        uint256 lootboxId,
        address owner
    ) public view returns (uint256) {
        uint256 lootboxTerminusPoolId = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        return terminusContract.balanceOf(owner, lootboxTerminusPoolId);
    }

    /**
     * @dev Returns a initialized Terminus contract from the terminusAddress
     */
    function getTerminusContract() private view returns (TerminusFacet) {
        return TerminusFacet(terminusAddress);
    }

    /**
     * @dev Returns the total lootbox count
     */
    function totalLootboxCount() public view returns (uint256) {
        return _totalLootboxCount;
    }

    /**
     * @dev Returns the lootbox item count for a lootbox id
     * @param lootboxId The id of the lootbox
     */
    function lootboxItemCount(uint256 lootboxId) public view returns (uint256) {
        return lootboxItemCounts[lootboxId];
    }

    /**
     * @dev Returns the lootbox item for a lootbox id and item index
     * @param lootboxId The id of the lootbox
     * @param itemIndex The index of the item in the lootbox
     */
    function getLootboxItemByIndex(
        uint256 lootboxId,
        uint256 itemIndex
    ) public view returns (LootboxItem memory) {
        return lootboxItems[lootboxId][itemIndex];
    }

    /**
     * @dev creates a new lootbox with the given terminus pool id and lootbox items
     * @param items The lootbox items
     * @param terminusPoolId The terminus pool id
     */
    function createLootboxWithTerminusPool(
        LootboxItem[] memory items,
        uint256 terminusPoolId,
        uint256 lootboxType
    ) public {
        require(
            lootboxType == ORDINARY_LOOTBOX_TYPE ||
                lootboxType == RANDOM_LOOTBOX_TYPE_1,
            "Unknown lootbox type"
        );

        uint256 lootboxId = _totalLootboxCount + 1;
        _totalLootboxCount++;

        TerminusFacet terminusContract = TerminusFacet(terminusAddress);

        require(
            lootboxIdbyTerminusPoolId[terminusPoolId] == 0,
            "Another lootbox already exists formeaning this terminus pool"
        );

        require(
            terminusContract.terminusPoolController(terminusPoolId) ==
                address(this),
            "The terminus pool is not controlled by Lootbox contract, please transfer the control to the contract."
        );

        lootboxIdbyTerminusPoolId[terminusPoolId] = lootboxId;
        terminusPoolIdbyLootboxId[lootboxId] = terminusPoolId;
        emit LootboxCreated(lootboxId);

        // Add the lootbox items
        for (uint256 i = 0; i < items.length; i++) {
            if (lootboxType == RANDOM_LOOTBOX_TYPE_1) {
                require(
                    items[i].weight > 0,
                    "Lootbox item weight must be greater than 0"
                );
            }
            lootboxItems[lootboxId][i] = items[i];
            emit LootboxItemAdded(lootboxId, items[i]);
        }

        // Add the lootbox item count
        lootboxItemCounts[lootboxId] = items.length;
        lootboxTypebyLootboxId[lootboxId] = lootboxType;
    }

    function createLootbox(
        LootboxItem[] memory items,
        uint256 lootboxType
    ) public onlyAdministrator {
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        IERC20 terminusPaymentToken = IERC20(terminusContract.paymentToken());
        uint256 poolBaseFee = terminusContract.poolBasePrice();

        require(
            (terminusPaymentToken.balanceOf(address(this)) >= poolBaseFee),
            "Not enough funds to create a new lootbox. Please transfer more funds to the contract."
        );

        terminusPaymentToken.approve(terminusAddress, poolBaseFee);

        uint256 terminusPoolId = terminusContract.createPoolV1(
            10 ** 18 * 10 ** 18,
            true,
            true
        );

        createLootboxWithTerminusPool(items, terminusPoolId, lootboxType);
    }

    /**
     * @dev Adds an item to a lootbox
     * @param lootboxId The id of the lootbox
     * @param item The item to add to the lootbox
     */
    function addLootboxItem(
        uint256 lootboxId,
        LootboxItem memory item
    ) public onlyAdministrator {
        uint256 lootboxType = lootboxTypebyLootboxId[lootboxId];
        if (lootboxType == RANDOM_LOOTBOX_TYPE_1) {
            require(item.weight > 0, "Item weight must be greater than 0");
        }
        uint256 itemIndex = lootboxItemCounts[lootboxId];
        lootboxItems[lootboxId][itemIndex] = item;
        lootboxItemCounts[lootboxId]++;

        emit LootboxItemAdded(lootboxId, item);
    }

    /**
     * @dev Removes an item from a lootbox
     * @param lootboxId The id of the lootbox
     * @param itemIndex The index of the item in the lootbox
     */
    function removeLootboxItem(
        uint256 lootboxId,
        uint256 itemIndex
    ) public onlyAdministrator {
        //swap the item at the index with the last item in the array
        uint256 lastItemIndex = lootboxItemCounts[lootboxId] - 1;

        LootboxItem memory lastItem = lootboxItems[lootboxId][lastItemIndex];
        lootboxItems[lootboxId][lastItemIndex] = lootboxItems[lootboxId][
            itemIndex
        ];

        lootboxItems[lootboxId][itemIndex] = lastItem;
        delete lootboxItems[lootboxId][lastItemIndex]; //10k gas refund
        lootboxItemCounts[lootboxId]--;
    }

    function _sendItem(
        uint256 lootboxId,
        uint256 itemIndex,
        uint256 count
    ) internal {
        LootboxItem memory item = lootboxItems[lootboxId][itemIndex];
        if (item.rewardType == ERC20_REWARD_TYPE) {
            IERC20(item.tokenAddress).transfer(msg.sender, item.amount * count);
        } else if (item.rewardType == ERC1155_REWARD_TYPE) {
            IERC1155(item.tokenAddress).safeTransferFrom(
                address(this),
                msg.sender,
                item.tokenId,
                item.amount * count,
                ""
            );
        } else if (item.rewardType == TERMINUS_MINTABLE_REWARD_TYPE) {
            TerminusFacet terminusFacetContract = TerminusFacet(
                item.tokenAddress
            );
            terminusFacetContract.mint(
                msg.sender,
                item.tokenId,
                item.amount * count,
                ""
            );
        } else {
            revert("Unsupported reward type");
        }
    }

    /**
     * @dev user opens a lootbox and gets a lootbox items from it
     * @param lootboxId The id of the lootbox
     * @param count The number of lootboxes to open
     */
    function openLootbox(
        uint256 lootboxId,
        uint256 count
    ) public whenNotPaused nonReentrant {
        uint256 terminusPoolForLootbox = terminusPoolIdbyLootboxId[lootboxId];
        TerminusFacet terminusContract = getTerminusContract();

        require(count > 0, "Count must be greater than 0");
        require(
            terminusContract.balanceOf(msg.sender, terminusPoolForLootbox) >=
                count,
            "You don't have enough lootbox tokens"
        );

        terminusContract.burn(msg.sender, terminusPoolForLootbox, count);
        if (lootboxTypebyLootboxId[lootboxId] == ORDINARY_LOOTBOX_TYPE) {
            for (uint256 i = 0; i < lootboxItemCounts[lootboxId]; i++) {
                _sendItem(lootboxId, i, count);
            }
        } else if (lootboxTypebyLootboxId[lootboxId] == RANDOM_LOOTBOX_TYPE_1) {
            require(count == 1, "Count must be 1 for random lootbox");
            _startRandomLootboxOpening(lootboxId);
        } else {
            revert("Unknown lootbox type");
        }
    }

    function completeRandomLootboxOpening() public nonReentrant {
        bytes32 currentOpeningRequestId = CurrentOpeningforUser[msg.sender];
        LootboxOpening memory opening = ActiveLootboxOpenings[
            currentOpeningRequestId
        ];

        require(
            opening.status != 0,
            "There is no active opening for this user"
        );
        require(opening.status == 2, "Lootbox opening is not ready");

        uint256 weightSums = 0;
        uint256 currentLootboxItemCount = lootboxItemCounts[opening.lootboxId];
        for (uint256 i = 0; i < currentLootboxItemCount; i++) {
            weightSums += lootboxItems[opening.lootboxId][i].weight;
        }

        uint256 randomNumber = opening.randomness % weightSums;

        uint256 currentWeightSum = 0;

        for (uint256 i = 0; i < currentLootboxItemCount; i++) {
            currentWeightSum += lootboxItems[opening.lootboxId][i].weight;
            if (randomNumber < currentWeightSum) {
                _sendItem(opening.lootboxId, i, 1);
                break;
            }
        }
        delete ActiveLootboxOpenings[currentOpeningRequestId];
        delete CurrentOpeningforUser[msg.sender];
    }

    /**
     * @dev Owner withdraws erc20 tokens from the contract
     * @param tokenAddress The address of the erc20 token contract
     * @param amount The amount to withdraw
     */
    function withdrawERC20(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20 erc20Contract = IERC20(tokenAddress);
        erc20Contract.transfer(_msgSender(), amount);
    }

    /**
     * @dev Owner withdraws erc1155 tokens from the contract
     * @param tokenAddress The address of the erc1155 token contract
     * @param tokenId The id of the erc1155 token
     * @param amount The amount to withdraw
     */

    function withdrawERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        address _owner = owner();
        IERC1155 erc1155Contract = IERC1155(tokenAddress);
        erc1155Contract.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            amount,
            ""
        );
    }

    /**
     * @dev Transfer controll of the terminus pools from contract to owner
     * @param poolIds The array of terminus pool ids
     */
    function surrenderTerminusPools(
        uint256[] calldata poolIds
    ) external onlyOwner {
        address _owner = owner();
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        for (uint256 i = 0; i < poolIds.length; i++) {
            terminusContract.setPoolController(poolIds[i], _owner);
        }
    }

    /**
     * @dev Transfer control of the terminus contract from contract to owner
     */
    function surrenderTerminusControl() external onlyOwner {
        address _owner = owner();
        TerminusFacet terminusContract = TerminusFacet(terminusAddress);
        terminusContract.setController(_owner);
    }

    /**
     * @dev pause the contract
     * @notice only pauses the openLootbox function
     */
    function pause() external onlyOwner {
        require(!paused(), "Already paused");
        _pause();
    }

    /**
     * @dev unpause the contract
     */
    function unpause() external onlyOwner {
        require(paused(), "Already unpaused");
        _unpause();
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * This is an implementation of the Terminus decentralized authorization contract.
 *
 * Terminus users can create authorization pools. Each authorization pool has the following properties:
 * 1. Controller: The address that controls the pool. Initially set to be the address of the pool creator.
 * 2. Pool URI: Metadata URI for the authorization pool.
 * 3. Pool capacity: The total number of tokens that can be minted in that authorization pool.
 * 4. Pool supply: The number of tokens that have actually been minted in that authorization pool.
 * 5. Transferable: A boolean value which denotes whether or not tokens from that pool can be transfered
 *    between addresses. (Note: Implemented by TerminusStorage.poolNotTransferable since we expect most
 *    pools to be transferable. This negation is better for storage + gas since false is default value
 *    in map to bool.)
 * 6. Burnable: A boolean value which denotes whether or not tokens from that pool can be burned.
 */

pragma solidity ^0.8.0;

import "IERC20.sol";
import "ERC1155WithTerminusStorage.sol";
import "LibTerminus.sol";
import "LibDiamond.sol";

contract TerminusFacet is ERC1155WithTerminusStorage {
    constructor() {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.controller = msg.sender;
    }

    event PoolMintBatch(
        uint256 indexed id,
        address indexed operator,
        address from,
        address[] toAddresses,
        uint256[] amounts
    );

    function setController(address newController) external {
        LibTerminus.enforceIsController();
        LibTerminus.setController(newController);
    }

    function poolMintBatch(
        uint256 id,
        address[] memory toAddresses,
        uint256[] memory amounts
    ) public {
        require(
            toAddresses.length == amounts.length,
            "TerminusFacet: _poolMintBatch -- toAddresses and amounts length mismatch"
        );
        address operator = _msgSender();
        require(
            isApprovedForPool(id, operator),
            "TerminusFacet: poolMintBatch -- caller is neither owner nor approved"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        uint256 i = 0;
        uint256 totalAmount = 0;

        for (i = 0; i < toAddresses.length; i++) {
            address to = toAddresses[i];
            uint256 amount = amounts[i];
            require(
                to != address(0),
                "TerminusFacet: _poolMintBatch -- cannot mint to zero address"
            );
            totalAmount += amount;
            ts.poolBalances[id][to] += amount;
            emit TransferSingle(operator, address(0), to, id, amount);
        }

        require(
            ts.poolSupply[id] + totalAmount <= ts.poolCapacity[id],
            "TerminusFacet: _poolMintBatch -- Minted tokens would exceed pool capacity"
        );
        ts.poolSupply[id] += totalAmount;

        emit PoolMintBatch(id, operator, address(0), toAddresses, amounts);
    }

    function terminusController() external view returns (address) {
        return LibTerminus.terminusStorage().controller;
    }

    function paymentToken() external view returns (address) {
        return LibTerminus.terminusStorage().paymentToken;
    }

    function setPaymentToken(address newPaymentToken) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.paymentToken = newPaymentToken;
    }

    function poolBasePrice() external view returns (uint256) {
        return LibTerminus.terminusStorage().poolBasePrice;
    }

    function setPoolBasePrice(uint256 newBasePrice) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolBasePrice = newBasePrice;
    }

    function _paymentTokenContract() internal view returns (IERC20) {
        address paymentTokenAddress = LibTerminus
            .terminusStorage()
            .paymentToken;
        require(
            paymentTokenAddress != address(0),
            "TerminusFacet: Payment token has not been set"
        );
        return IERC20(paymentTokenAddress);
    }

    function withdrawPayments(address toAddress, uint256 amount) external {
        LibTerminus.enforceIsController();
        require(
            _msgSender() == toAddress,
            "TerminusFacet: withdrawPayments -- Controller can only withdraw to self"
        );
        IERC20 paymentTokenContract = _paymentTokenContract();
        paymentTokenContract.transfer(toAddress, amount);
    }

    function contractURI() public view returns (string memory) {
        return LibTerminus.terminusStorage().contractURI;
    }

    function setContractURI(string memory _contractURI) external {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.contractURI = _contractURI;
    }

    function setURI(uint256 poolID, string memory poolURI) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolURI[poolID] = poolURI;
    }

    function totalPools() external view returns (uint256) {
        return LibTerminus.terminusStorage().currentPoolID;
    }

    function setPoolController(uint256 poolID, address newController) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.setPoolController(poolID, newController);
    }

    function terminusPoolController(uint256 poolID)
        external
        view
        returns (address)
    {
        return LibTerminus.terminusStorage().poolController[poolID];
    }

    function terminusPoolCapacity(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolCapacity[poolID];
    }

    function terminusPoolSupply(uint256 poolID)
        external
        view
        returns (uint256)
    {
        return LibTerminus.terminusStorage().poolSupply[poolID];
    }

    function poolIsTransferable(uint256 poolID) external view returns (bool) {
        return !LibTerminus.terminusStorage().poolNotTransferable[poolID];
    }

    function poolIsBurnable(uint256 poolID) external view returns (bool) {
        return LibTerminus.terminusStorage().poolBurnable[poolID];
    }

    function setPoolTransferable(uint256 poolID, bool transferable) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolNotTransferable[poolID] = !transferable;
    }

    function setPoolBurnable(uint256 poolID, bool burnable) external {
        LibTerminus.enforcePoolIsController(poolID, msg.sender);
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.poolBurnable[poolID] = burnable;
    }

    function createSimplePool(uint256 _capacity) external returns (uint256) {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createSimplePool -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        return LibTerminus.createSimplePool(_capacity);
    }

    function createPoolV1(
        uint256 _capacity,
        bool _transferable,
        bool _burnable
    ) external returns (uint256) {
        LibTerminus.enforceIsController();
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        // TODO(zomglings): Implement requiredPayment update based on pool features.
        uint256 requiredPayment = ts.poolBasePrice;
        IERC20 paymentTokenContract = _paymentTokenContract();
        require(
            paymentTokenContract.allowance(_msgSender(), address(this)) >=
                requiredPayment,
            "TerminusFacet: createPoolV1 -- Insufficient allowance on payment token"
        );
        paymentTokenContract.transferFrom(
            msg.sender,
            address(this),
            requiredPayment
        );
        uint256 poolID = LibTerminus.createSimplePool(_capacity);
        if (!_transferable) {
            ts.poolNotTransferable[poolID] = true;
        }
        if (_burnable) {
            ts.poolBurnable[poolID] = true;
        }
        return poolID;
    }

    function mint(
        address to,
        uint256 poolID,
        uint256 amount,
        bytes memory data
    ) external {
        require(
            isApprovedForPool(poolID, msg.sender),
            "TerminusFacet: mint -- caller is neither owner nor approved"
        );
        _mint(to, poolID, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory poolIDs,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        for (uint256 i = 0; i < poolIDs.length; i++) {
            require(
                isApprovedForPool(poolIDs[i], msg.sender),
                "TerminusFacet: mintBatch -- caller is neither owner nor approved"
            );
        }
        _mintBatch(to, poolIDs, amounts, data);
    }

    function burn(
        address from,
        uint256 poolID,
        uint256 amount
    ) external {
        address operator = _msgSender();
        require(
            operator == from || isApprovedForPool(poolID, operator),
            "TerminusFacet: burn -- caller is neither owner nor approved"
        );
        _burn(from, poolID, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * An ERC1155 implementation which uses the Moonstream DAO common storage structure for proxies.
 * EIP1155: https://eips.ethereum.org/EIPS/eip-1155
 *
 * The Moonstream contract is used to delegate calls from an EIP2535 Diamond proxy.
 *
 * This implementation is adapted from the OpenZeppelin ERC1155 implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/6bd6b76d1156e20e45d1016f355d154141c7e5b9/contracts/token/ERC1155
 */

pragma solidity ^0.8.9;

import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "IERC1155MetadataURI.sol";
import "Address.sol";
import "Context.sol";
import "ERC165.sol";
import "LibTerminus.sol";

contract ERC1155WithTerminusStorage is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI
{
    using Address for address;

    constructor() {}

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
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 poolID)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return LibTerminus.terminusStorage().poolURI[poolID];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155WithTerminusStorage: balance query for the zero address"
        );
        return LibTerminus.terminusStorage().poolBalances[id][account];
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
        require(
            accounts.length == ids.length,
            "ERC1155WithTerminusStorage: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            LibTerminus.terminusStorage().globalOperatorApprovals[account][
                operator
            ];
    }

    function isApprovedForPool(uint256 poolID, address operator)
        public
        view
        returns (bool)
    {
        return LibTerminus._isApprovedForPool(poolID, operator);
    }

    function approveForPool(uint256 poolID, address operator) external {
        LibTerminus.enforcePoolIsController(poolID, _msgSender());
        LibTerminus._approveForPool(poolID, operator);
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
            from == _msgSender() ||
                isApprovedForAll(from, _msgSender()) ||
                isApprovedForPool(id, _msgSender()),
            "ERC1155WithTerminusStorage: caller is not owner nor approved"
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
            "ERC1155WithTerminusStorage: transfer caller is not owner nor approved"
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            !ts.poolNotTransferable[id],
            "ERC1155WithTerminusStorage: _safeTransferFrom -- pool is not transferable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: insufficient balance for transfer"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
        }
        ts.poolBalances[id][to] += amount;

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
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: transfer to the zero address"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            require(
                !ts.poolNotTransferable[id],
                "ERC1155WithTerminusStorage: _safeBatchTransferFrom -- pool is not transferable"
            );

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: insufficient balance for transfer"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
            }
            ts.poolBalances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolSupply[id] + amount <= ts.poolCapacity[id],
            "ERC1155WithTerminusStorage: _mint -- Minted tokens would exceed pool capacity"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ts.poolSupply[id] += amount;
        ts.poolBalances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
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
        require(
            to != address(0),
            "ERC1155WithTerminusStorage: mint to the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolSupply[ids[i]] + amounts[i] <= ts.poolCapacity[ids[i]],
                "ERC1155WithTerminusStorage: _mintBatch -- Minted tokens would exceed pool capacity"
            );
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            ts.poolSupply[ids[i]] += amounts[i];
            ts.poolBalances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
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
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        require(
            ts.poolBurnable[id],
            "ERC1155WithTerminusStorage: _burn -- pool is not burnable"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = ts.poolBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155WithTerminusStorage: burn amount exceeds balance"
        );
        unchecked {
            ts.poolBalances[id][from] = fromBalance - amount;
            ts.poolSupply[id] -= amount;
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
        require(
            from != address(0),
            "ERC1155WithTerminusStorage: burn from the zero address"
        );
        require(
            ids.length == amounts.length,
            "ERC1155WithTerminusStorage: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ts.poolBurnable[ids[i]],
                "ERC1155WithTerminusStorage: _burnBatch -- pool is not burnable"
            );
        }

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ts.poolBalances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155WithTerminusStorage: burn amount exceeds balance"
            );
            unchecked {
                ts.poolBalances[id][from] = fromBalance - amount;
                ts.poolSupply[id] -= amount;
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
        require(
            owner != operator,
            "ERC1155WithTerminusStorage: setting approval status for self"
        );
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalOperatorApprovals[owner][operator] = approved;
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
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
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
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert(
                        "ERC1155WithTerminusStorage: ERC1155Receiver rejected tokens"
                    );
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155WithTerminusStorage: transfer to non ERC1155Receiver implementer"
                );
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 *
 * Common storage structure and internal methods for Moonstream DAO Terminus contracts.
 * As Terminus is an extension of ERC1155, this library can also be used to implement bare ERC1155 contracts
 * using the common storage pattern (e.g. for use in diamond proxies).
 */

// TODO(zomglings): Should we support EIP1761 in addition to ERC1155 or roll our own scopes and feature flags?
// https://eips.ethereum.org/EIPS/eip-1761

pragma solidity ^0.8.9;

library LibTerminus {
    bytes32 constant TERMINUS_STORAGE_POSITION =
        keccak256("moonstreamdao.eth.storage.terminus");

    struct TerminusStorage {
        // Terminus administration
        address controller;
        bool isTerminusActive;
        uint256 currentPoolID;
        address paymentToken;
        uint256 poolBasePrice;
        // Terminus pools
        mapping(uint256 => address) poolController;
        mapping(uint256 => string) poolURI;
        mapping(uint256 => uint256) poolCapacity;
        mapping(uint256 => uint256) poolSupply;
        mapping(uint256 => mapping(address => uint256)) poolBalances;
        mapping(uint256 => bool) poolNotTransferable;
        mapping(uint256 => bool) poolBurnable;
        mapping(address => mapping(address => bool)) globalOperatorApprovals;
        mapping(uint256 => mapping(address => bool)) globalPoolOperatorApprovals;
        // Contract metadata
        string contractURI;
    }

    function terminusStorage()
        internal
        pure
        returns (TerminusStorage storage es)
    {
        bytes32 position = TERMINUS_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    event PoolControlTransferred(
        uint256 indexed poolID,
        address indexed previousController,
        address indexed newController
    );

    function setController(address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.controller;
        ts.controller = newController;
        emit ControlTransferred(previousController, newController);
    }

    function enforceIsController() internal view {
        TerminusStorage storage ts = terminusStorage();
        require(msg.sender == ts.controller, "LibTerminus: Must be controller");
    }

    function setTerminusActive(bool active) internal {
        TerminusStorage storage ts = terminusStorage();
        ts.isTerminusActive = active;
    }

    function setPoolController(uint256 poolID, address newController) internal {
        TerminusStorage storage ts = terminusStorage();
        address previousController = ts.poolController[poolID];
        ts.poolController[poolID] = newController;
        emit PoolControlTransferred(poolID, previousController, newController);
    }

    function createSimplePool(uint256 _capacity) internal returns (uint256) {
        TerminusStorage storage ts = terminusStorage();
        uint256 poolID = ts.currentPoolID + 1;
        setPoolController(poolID, msg.sender);
        ts.poolCapacity[poolID] = _capacity;
        ts.currentPoolID++;
        return poolID;
    }

    function enforcePoolIsController(uint256 poolID, address maybeController)
        internal
        view
    {
        TerminusStorage storage ts = terminusStorage();
        require(
            ts.poolController[poolID] == maybeController,
            "LibTerminus: Must be pool controller"
        );
    }

    function _isApprovedForPool(uint256 poolID, address operator)
        internal
        view
        returns (bool)
    {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        if (operator == ts.poolController[poolID]) {
            return true;
        } else if (ts.globalPoolOperatorApprovals[poolID][operator]) {
            return true;
        }
        return false;
    }

    function _approveForPool(uint256 poolID, address operator) internal {
        LibTerminus.TerminusStorage storage ts = LibTerminus.terminusStorage();
        ts.globalPoolOperatorApprovals[poolID][operator] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

import { IDiamondCut } from "IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
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

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adapted from the Diamond 3 reference implementation by Nick Mudge:
// https://github.com/mudgen/diamond-3-hardhat

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "ERC1155Receiver.sol";

/**
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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC1155Receiver.sol";
import "ERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 */

pragma solidity ^0.8.9;
import "TerminusFacet.sol";
import "Ownable.sol";

abstract contract ControllableWithTerminus is Ownable {
    TerminusFacet private terminus;
    uint256 public administratorPoolId;

    constructor(address _terminusContractAddress, uint256 _administratorPoolId)
    {
        terminus = TerminusFacet(_terminusContractAddress);
        administratorPoolId = _administratorPoolId;
    }

    /**
     * @dev throws if called by account that doesn't hold the administrator pool token
     * or is the contract owner
     */
    modifier onlyAdministrator() {
        require(
            terminus.balanceOf(msg.sender, administratorPoolId) > 0 ||
                msg.sender == owner(),
            "Lootbox.sol: Sender is not an administrator"
        );
        _;
    }

    function changeAdministratorPoolId(uint256 _administratorPoolId)
        public
        onlyOwner
    {
        administratorPoolId = _administratorPoolId;
    }

    function grantAdminRole(address to) public onlyOwner {
        require(
            address(this) ==
                terminus.terminusPoolController(administratorPoolId),
            "The contract is not the pool controller for the administrator pool. Please transfer the controller role to the contract."
        );
        terminus.mint(to, administratorPoolId, 1, "");
    }

    function revokeAdminRole(address from) public onlyOwner {
        TerminusFacet terminusContract = TerminusFacet(terminus);
        require(
            address(this) ==
                terminusContract.terminusPoolController(administratorPoolId),
            "The contract is not the pool controller for the administrator pool. Please transfer the controller role to the contract."
        );

        uint256 balance = terminusContract.balanceOf(from, administratorPoolId);
        terminusContract.burn(from, administratorPoolId, balance);
    }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Authors: Moonstream Engineering ([email protected])
 * GitHub: https://github.com/bugout-dev/dao
 */

pragma solidity ^0.8.0;

import "VRFConsumerBase.sol";

abstract contract LootboxRandomness is VRFConsumerBase {
    uint256 ChainlinkVRFFee;
    bytes32 ChainlinkVRFKeyhash;

    struct LootboxOpening {
        // Statuses:
        // 1 -> offered
        // 2 -> randomness fulfilled
        // 3 -> completed
        uint32 status;
        address user; // address which is openening the lootbox
        uint256 lootboxId;
        uint256 randomness;
    }

    event LootboxOpeningBegan(address lootboxOwner, uint256 lootboxId);
    event LootboxOpeningCompleted(
        address lootboxOwner,
        uint256 lootboxId,
        bytes32 requestId,
        uint256 randomness
    );

    mapping(bytes32 => LootboxOpening) public ActiveLootboxOpenings;
    mapping(address => bytes32) public CurrentOpeningforUser;

    constructor(
        address _VRFCoordinatorAddress,
        address _LinkTokenAddress,
        uint256 _ChainlinkVRFFee,
        bytes32 _ChainlinkVRFKeyhash
    ) VRFConsumerBase(_VRFCoordinatorAddress, _LinkTokenAddress) {
        ChainlinkVRFFee = _ChainlinkVRFFee;
        ChainlinkVRFKeyhash = _ChainlinkVRFKeyhash;
    }

    function getChainlinkVRFFee() public view returns (uint256) {
        return ChainlinkVRFFee;
    }

    function getChainlinkVRFKeyhash() public view returns (bytes32) {
        return ChainlinkVRFKeyhash;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        LootboxOpening storage currentLootboxOpening = ActiveLootboxOpenings[
            requestId
        ];
        if (currentLootboxOpening.status != 1) {
            return;
        }
        currentLootboxOpening.status = 2;
        currentLootboxOpening.randomness = randomness;
    }

    function _startRandomLootboxOpening(uint256 lootboxId) internal {
        require(
            CurrentOpeningforUser[msg.sender] == 0,
            "LootboxRandomness: _startRandomLootboxOpening -- Sender already has an incompleted opening"
        );

        emit LootboxOpeningBegan(msg.sender, lootboxId);

        LootboxOpening memory currentlootboxOpening;
        currentlootboxOpening.status = 1;
        currentlootboxOpening.user = msg.sender;
        currentlootboxOpening.lootboxId = lootboxId;

        bytes32 requestId = requestRandomness(
            ChainlinkVRFKeyhash,
            ChainlinkVRFFee
        );

        ActiveLootboxOpenings[requestId] = currentlootboxOpening;
        CurrentOpeningforUser[msg.sender] = requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

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
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
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
abstract contract VRFConsumerBase is VRFRequestIDBase {
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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

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
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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