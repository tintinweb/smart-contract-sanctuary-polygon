// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./utils/IBalanceVault.sol";

/**
 * @dev Use to provide gachapon service.
 * Has a function to create gachapon.
 * Has functions to add and remove gachapon items.
 * Has a function to buy gachapon.
 * Has a function to claim gachapon items.
 * Has functions for retriving gachapon, gachapon index, gachapon items, random info.
 * @notice Is pausable to prevent malicious behavior.
 * @notice Utilize Chainlink VRF for randomness.
 */
contract GachaponService is VRFConsumerBaseV2, AccessControl, Ownable, Pausable, ERC721Holder, ERC1155Holder {

    enum NftType {
        UNKNOWN,
        NFT721,
        NFT1155
    }
    struct Gacha {
        uint256 gachaId;
        address gachaOwner;
        uint256 gachaPrice;
        uint256 gachaTotalItem;
        mapping(uint256 => uint256) itemsIdByGachaIdx;
        uint256 gachaIdxCurrentSize;
        uint256 gachaIdxActualSize;
        mapping(uint256 => Items) itemsById;
        uint256 itemsCount;
    }
    struct Items {
        uint256 itemsId;
        Item[] itemList;
        address reciever;
    }
    struct Item {
        address itemAddress;
        uint256 itemTokenId;
        uint256 itemAmount;
        NftType nftType;
    }
	struct RandomInfo {
        address user;
        uint256 gachaId;
        uint256 randomWord;
        uint256 currentSize;
        uint256 itemsId;
    }

    bytes4 public constant ERC721INTERFACE = 0x80ac58cd;
    bytes4 public constant ERC1155INTERFACE = 0xd9b67a26;
    bytes32 public constant WORKER = keccak256("WORKER");

    VRFCoordinatorV2Interface public coordinator;
    IBalanceVault public balanceVault;

    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;

    mapping(uint256 => Gacha) public gachaByGachaId;
	mapping(uint256 => RandomInfo) public randomInfos;
    address public adminAddress;
    uint256 public creationFees;
    uint256 public itemFees;
	uint256 public latestGachaId;

	event GachaponCreated(uint256 indexed gachaId, address indexed gachaOwner, uint256 price, uint256 fees);
    event GachaponItemsAdded(uint256 indexed gachaId, uint256 fees);
    event GachaponItemsRemoved(uint256 indexed gachaId, uint256 indexed itemsId, uint256 fees);
	event GachaponItemAdded(uint256 indexed gachaId, uint256 indexed itemsId, Item item);
    event GachaponItemTransfered(uint256 indexed gachaId, address indexed userAddress, Item item);
	event GachaponBought(uint256 indexed gachaId, address indexed userAddress, uint256 requestId);
    event GachaponItemsClaimed(uint256 indexed gachaId, uint256 indexed requestId, uint256 itemsId);
    event GachaOwnerUpdated(uint256 indexed gachaId, address gachaOwner);
    event GachaPriceUpdated(uint256 indexed gachaId, uint256 price);
	event RandomFulfilled(uint256 indexed requestId, uint256 indexed itemsId, uint256 randomWord);

    error InvalidItem(uint256 itemsIdx, uint256 itemIdx, string reason);
    error InvalidItems(uint256 itemsIdx, string reason);

    /** 
    * @dev Setup variables, setup role for deployer.
    * @param  _balanceVaultAddress - address of balance vault.
    * @param  _subscriptionId - chainlink vrf subscription id.
    * @param  _vrfCoordinator - chainlink vrf coordinator address.
    * @param  _keyHash - chainlink vrf max gas price key hash.
    * @param  _callbackGasLimit - chainlink vrf callback gas limit.
    * @param  _requestConfirmations - chainlink vrf number of request confirmation.
    * @param  _numWords - chainlink vrf number of random words.
    * @param  _adminAddress - admin address for fees transfer.
    * @param  _creationFees - fees per one gachapon creation.
    * @param  _itemFees - fees per one item added to gachapon.
    */
    constructor(
        address _balanceVaultAddress,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        address _adminAddress,
		uint256 _creationFees,
        uint256 _itemFees
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        balanceVault = IBalanceVault(_balanceVaultAddress);
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        adminAddress = _adminAddress;
		creationFees = _creationFees;
        itemFees = _itemFees;
    }

    /** 
    * @dev Override support interface.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[GachaponService] Revert receive function.");
    }
    fallback() external payable {
        revert("[GachaponService] Revert fallback function.");
    }

    modifier onlyGachaOwner(uint256 _gachaId) {
        require(
            gachaByGachaId[_gachaId].gachaOwner == msg.sender,
            "[GachaponService.onlyGachaOwner] Only gacha owner"
        );
        _;
    }
    modifier notEmptyItems(Item[][] memory _itemsList) {
        require(
            _itemsList.length > 0,
            "[GachaponService.notEmptyItems] Items array should not be empty"
        );
        _;
    }

    // VRF setter
	function setSubscriptionId(uint64 _subscriptionId) external whenPaused onlyOwner {
        subscriptionId = _subscriptionId;
    }
    function setCallbackGasLimit(uint32 _callbackGasLimit) external whenPaused onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }
    function setRequestConfirmations(uint16 _requestConfirmations) external whenPaused onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    // Contract params setter
	function setCreationFees(uint256 _creationFees) external onlyRole(WORKER) {
		creationFees = _creationFees;
	}
    function setItemFees(uint256 _itemFees) external onlyRole(WORKER) {
		itemFees = _itemFees;
	}
    function setGachaOwner(uint256 _gachaId, address _gachaOwner) external onlyOwner {
        gachaByGachaId[_gachaId].gachaOwner = _gachaOwner;
    }
    function setBalanceVaultAddress(address _balanceVaultAddress) external onlyOwner {
        balanceVault = IBalanceVault(_balanceVaultAddress);
    }
    function setAdminAddress(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }
    function setGachaPrice(uint256 _gachaId, uint256 _price) external onlyGachaOwner(_gachaId) {
        gachaByGachaId[_gachaId].gachaPrice = _price;
    }
    function pauseGachaponService() external onlyOwner {
        _pause();
    }
    function unpauseGachaponService() external onlyOwner {
        _unpause();
    }

    /** 
    * @dev Create gachapon, gachapon index, transfer and store item, deduct fees from gacha owner vault.
    * @param _itemsList - array of set of gachapon item.
    * @param _price - betting period ending time.
    */
	function createGachapon(Item[][] memory _itemsList, uint256 _price) external whenNotPaused notEmptyItems(_itemsList) {
        latestGachaId++;
		Gacha storage gacha = gachaByGachaId[latestGachaId];

		gacha.gachaOwner = msg.sender;
        gacha.gachaId = latestGachaId;
        gacha.gachaPrice = _price;
        gacha.gachaIdxActualSize = _itemsList.length;
        verifyAndAddItems(gacha, _itemsList);
        uint256 fees = creationFees + (itemFees * gacha.gachaTotalItem);
        if(fees > 0) {
            balanceVault.decreaseBalance(msg.sender, fees);
            balanceVault.increaseBalance(adminAddress, fees);
        }

		emit GachaponCreated(latestGachaId, msg.sender, _price, fees);
	}
    
    /** 
    * @dev Add item to exist gachapon, update gachapon index, transfer and store added item, deduct fees from gacha owner vault.
    * @param _gachaId - existing gachapon id.
    * @param _itemsList - array of set of gachapon item.
    */
    function addGachaponItems(uint256 _gachaId, Item[][] memory _itemsList) external whenNotPaused onlyGachaOwner(_gachaId) notEmptyItems(_itemsList) {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        uint256 prevTotalItems = gacha.gachaTotalItem;

        gacha.gachaIdxActualSize += _itemsList.length;
        verifyAndAddItems(gacha, _itemsList);
        uint256 fees = itemFees * (gacha.gachaTotalItem - prevTotalItems);
        if(fees > 0) {
            balanceVault.decreaseBalance(msg.sender, fees);
            balanceVault.increaseBalance(adminAddress, fees);
        }

        emit GachaponItemsAdded(_gachaId, fees);
    }

    /** 
    * @dev Buy gachapon, request random words from chainlink vrf, store random info, transfer balance from user to gacha owner.
    * @param _gachaId - existing gachapon id.
    */
	function buyGachapon(uint256 _gachaId) external whenNotPaused {
        Gacha storage gacha = gachaByGachaId[_gachaId];
		require(
            gacha.gachaIdxActualSize > 0,
            "[GachaponService.buyGachapon] Gachapon sold out"
        );
        require(
            balanceVault.getBalance(msg.sender) >= gacha.gachaPrice,
            "[GachaponService.buyGachapon] Insufficient balance"
        );
		balanceVault.decreaseBalance(msg.sender, gacha.gachaPrice);
        balanceVault.increaseBalance(gacha.gachaOwner, gacha.gachaPrice);
        gacha.gachaIdxActualSize--;

		uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
		RandomInfo storage randomInfo = randomInfos[requestId];
        randomInfo.user = msg.sender;
        randomInfo.gachaId = _gachaId;

		emit GachaponBought(_gachaId, msg.sender, requestId);
	}

    /** 
    * @dev Transfer gachapon items back to gacha owner if valid, update gachapon index, deduct fees from gacha owner vault.
    * @param _gachaId - existing gachapon id.
    * @param _gachaIdx - to be removed gacha index.
    * @param _itemsId - to be removed items id.
    * @param _fees - removing fees.
    */
    function removeGachaponItems(uint256 _gachaId, uint256 _gachaIdx, uint256 _itemsId, uint256 _fees) external whenNotPaused onlyRole(WORKER) {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        require(
            gacha.gachaIdxActualSize > 0,
            "[GachaponService.removeGachaponItems] Gachapon is empty"
        );
        require(
            _gachaIdx <= (gacha.gachaIdxCurrentSize - 1),
            "[GachaponService.removeGachaponItems] Gacha index exceed gachapon current size"
        );

        uint256 itemsId = gacha.itemsIdByGachaIdx[_gachaIdx];
        require(
            itemsId == _itemsId,
            "[GachaponService.removeGachaponItems] Items id from gacha index not matched"
        );

        gacha.gachaIdxActualSize--;
        removeGachaponIndex(gacha, _gachaIdx);
        transferItems(_gachaId, gacha.gachaOwner, itemsId);
        if(_fees > 0) {
            balanceVault.decreaseBalance(gacha.gachaOwner, _fees);
            balanceVault.increaseBalance(adminAddress, _fees);
        }

        emit GachaponItemsRemoved(_gachaId, _itemsId, _fees);
    }

    /** 
    * @dev Transfer random items from gachapon purchasing.
    * @param _gachaId - existing gachapon id.
    * @param _requestId - to be claimed request id.
    */
    function claimGachaponItems(uint256 _gachaId, uint256 _requestId) external {
        RandomInfo storage randomInfo = randomInfos[_requestId];

        require(
            msg.sender == randomInfo.user,
            "[GachaponService.claimGachaponItems] Not claimable user"
        );
        require(
            randomInfo.itemsId != 0,
            "[GachaponService.claimGachaponItems] Request id pending"
        );

        transferItems(_gachaId, msg.sender, randomInfo.itemsId);

        emit GachaponItemsClaimed(_gachaId, _requestId, randomInfo.itemsId);
    }

    /** 
    * @dev Retrieve overall gachapon info.
    * @param _gachaId - existing gachapon id.
    */
    function getGachaponInfo(uint256 _gachaId)
        external
        view
        returns (
            uint256 gachaId,
            address gachaOwner,
            uint256 gachaPrice,
            uint256 gachaTotalItem,
            uint256 gachaIdxCurrentSize,
            uint256 gachaIdxActualSize,
            uint256 itemsCount
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];

        gachaId = gacha.gachaId;
        gachaOwner = gacha.gachaOwner;
        gachaPrice = gacha.gachaPrice;
        gachaTotalItem = gacha.gachaTotalItem;
        gachaIdxCurrentSize = gacha.gachaIdxCurrentSize;
        gachaIdxActualSize = gacha.gachaIdxActualSize;
        itemsCount = gacha.itemsCount;
    }

    /** 
    * @dev Retrieve gachapon specific item in items.
    * @param _gachaId - existing gachapon id.
    * @param _itemsId - gachapon items id.
    * @param _itemIdx - item index in items.
    */
    function getGachaponItem(uint256 _gachaId, uint256 _itemsId, uint256 _itemIdx)
        external
        view
        returns (
            Item memory item
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        item = gacha.itemsById[_itemsId].itemList[_itemIdx];
    }

    /** 
    * @dev Retrieve gachapon items.
    * @param _gachaId - existing gachapon id.
    * @param _itemsId - gachapon items id.
    */
    function getGachaponItems(uint256 _gachaId, uint256 _itemsId)
        external
        view
        returns (
            Items memory items
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        items = gacha.itemsById[_itemsId];
    }

    /** 
    * @dev Retrieve current gachapon index items.
    * @param _gachaId - existing gachapon id.
    */
    function getGachaponIndexItemsList(uint256 _gachaId)
        external
        view
        returns (
            Items[] memory gachaItemsList
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        gachaItemsList = getGachaponItemsList(
            _gachaId,
            getGachaponIndexes(_gachaId, 0, gacha.gachaIdxCurrentSize - 1)
        );
    }

    /** 
    * @dev Retrieve gachapon items from list of request id.
    * @param _gachaId - existing gachapon id.
    * @param _requestIdList - array of request id.
    */
    function getGachaponItemsListFromRequestIdList(uint256 _gachaId, uint256[] memory _requestIdList)
        external
        view
        returns (
            Items[] memory gachaItemsList
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];

        gachaItemsList = new Items[](_requestIdList.length);
        for (uint256 i = 0; i < _requestIdList.length; i++) {
            RandomInfo memory randomInfo = randomInfos[_requestIdList[i]];
            gachaItemsList[i] = gacha.itemsById[randomInfo.itemsId];
        }
    }

    /** 
    * @dev Retrieve random info.
    * @param _requestId - random info request id.
    */
    function getRandomInfos(uint256 _requestId)
        external
        view
        returns (
            address user,
            uint256 gachaId,
            uint256 randomWord,
            uint256 currentSize,
            uint256 itemsId
        )
    {
        RandomInfo storage randomInfo = randomInfos[_requestId];
        user = randomInfo.user;
        gachaId = randomInfo.gachaId;
        randomWord = randomInfo.randomWord;
        currentSize = randomInfo.currentSize;
        itemsId = randomInfo.itemsId;
    }

    /** 
    * @dev Retrieve gachapon items specify in items id list.
    * @param _gachaId - existing gachapon id.
    * @param _itemsIdList - array of items id.
    */
    function getGachaponItemsList(uint256 _gachaId, uint256[] memory _itemsIdList)
        public
        view
        returns (
            Items[] memory gachaItemsList
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];

        gachaItemsList = new Items[](_itemsIdList.length);
        for (uint256 i = 0; i < _itemsIdList.length; i++) {
            gachaItemsList[i] = gacha.itemsById[_itemsIdList[i]];
        }
    }

    /** 
    * @dev Retrieve current gachapon index in specify length.
    * @param _start - index start at.
    * @param _end - index end at.
    */
    function getGachaponIndexes(uint256 _gachaId, uint256 _start, uint256 _end)
        public
        view
        returns (
            uint256[] memory gachaIdx
        )
    {
        Gacha storage gacha = gachaByGachaId[_gachaId];

        uint256 length = _end - _start + 1;
        gachaIdx = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 idx = i + _start;
            gachaIdx[i] = gacha.itemsIdByGachaIdx[idx];
        }
    }

    /** 
    * @dev Verify items validity, transfer items to contract, update gachapon index.
    * @param _gacha - gacha storage.
    * @param _itemsList - array of set of gachapon item.
    */
    function verifyAndAddItems(Gacha storage _gacha, Item[][] memory _itemsList) internal {
        // Loop create items index
		for (uint256 i = 0; i < _itemsList.length; i++) {
            // itemsId started from 1 to prevent confusion on getters usage
            uint256 itemsId = i + _gacha.itemsCount + 1;
            _gacha.itemsById[itemsId].itemsId = itemsId;

            if(_itemsList[i].length == 0)
                revert InvalidItems(i, "Item array should not be empty");

            // Loop verify item and add to items
            for (uint256 j = 0; j < _itemsList[i].length; j++) {
                Item memory item = _itemsList[i][j];

                if(item.itemAddress == address(0))
                    revert InvalidItem(i, j, "Invalid item address");

                if(item.nftType == NftType.UNKNOWN) {
                    revert InvalidItem(i, j, "Invalid NFT type");
                // verify 721 interface, owner, amount
                } else if(item.nftType == NftType.NFT721) {
                    IERC721 erc721 = IERC721(item.itemAddress);

                    if(!erc721.supportsInterface(ERC721INTERFACE))
                        revert InvalidItem(i, j, "Invalid NFT type for item address");
                    if(item.itemAmount != 1)
                        revert InvalidItem(i, j, "Invalid item amount for NFT type");
                    if(erc721.ownerOf(item.itemTokenId) != msg.sender)
                        revert InvalidItem(i, j, "Invalid owner");

                    erc721.safeTransferFrom(msg.sender, address(this), item.itemTokenId);

                // verify 1155 interface, amount, amount owned
                } else {
                    IERC1155 erc1155 = IERC1155(item.itemAddress);

                    if(!erc1155.supportsInterface(ERC1155INTERFACE))
                        revert InvalidItem(i, j, "Invalid NFT type for item address");
                    if(item.itemAmount == 0)
                        revert InvalidItem(i, j, "Invalid item amount for NFT type");
                    if(erc1155.balanceOf(msg.sender, item.itemTokenId) < item.itemAmount)
                        revert InvalidItem(i, j, "Invalid item amount owned");

                    erc1155.safeTransferFrom(msg.sender, address(this), item.itemTokenId, item.itemAmount, bytes(""));
                }
                _gacha.itemsById[itemsId].itemList.push(item);
                _gacha.gachaTotalItem++;

                emit GachaponItemAdded(_gacha.gachaId, itemsId, item);
            }
            _gacha.itemsIdByGachaIdx[_gacha.gachaIdxCurrentSize] = itemsId;
            _gacha.gachaIdxCurrentSize++;
		}
        _gacha.itemsCount += _itemsList.length;
	}

    /** 
    * @dev Transfer specify items id to reciever.
    * @param _gachaId - existing gachapon id.
    * @param _reciever - items reciever.
    * @param _itemsId - gachapon items id.
    */
    function transferItems(uint256 _gachaId, address _reciever, uint256 _itemsId) internal {
        Gacha storage gacha = gachaByGachaId[_gachaId];
        Items storage items = gacha.itemsById[_itemsId];

        require(
            items.reciever == address(0),
            "[GachaponService.transferItems] Items already transfered"
        );
        require(
            _reciever != address(0),
            "[GachaponService.transferItems] Items reciever invalid"
        );
        items.reciever = _reciever;
        for (uint256 i = 0; i < items.itemList.length; i++) {
            Item memory item = items.itemList[i];
            gacha.gachaTotalItem--;

            if(item.nftType == NftType.NFT721) {
                IERC721 erc721 = IERC721(item.itemAddress);
                erc721.safeTransferFrom(address(this), _reciever, item.itemTokenId);
            } else {
                IERC1155 erc1155 = IERC1155(item.itemAddress);
                erc1155.safeTransferFrom(address(this), _reciever, item.itemTokenId, item.itemAmount, bytes(""));
            }

            emit GachaponItemTransfered(_gachaId, items.reciever, item);
        }
    }

    /** 
    * @dev Replace gachapon index and remove last index to maintain size.
    * @param _gacha - gacha storage.
    * @param _gachaIdx - index to be remove and replace.
    */
    function removeGachaponIndex(Gacha storage _gacha, uint256 _gachaIdx) internal {
        _gacha.itemsIdByGachaIdx[_gachaIdx] = _gacha.itemsIdByGachaIdx[_gacha.gachaIdxCurrentSize - 1];
        delete _gacha.itemsIdByGachaIdx[_gacha.gachaIdxCurrentSize - 1];
        _gacha.gachaIdxCurrentSize--;
    }

    /** 
    * @dev Calculate random result, update random info, update gachapon index.
    * @param _requestId - random request id.
    * @param _randomWords - random words from chainlink vrf.
    */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
		RandomInfo storage randomInfo = randomInfos[_requestId];
        Gacha storage gacha = gachaByGachaId[randomInfo.gachaId];
        uint256 gachaIdx = _randomWords[0] % gacha.gachaIdxCurrentSize;
        uint256 itemsId = gacha.itemsIdByGachaIdx[gachaIdx];

        // Update random Info
        randomInfo.randomWord = _randomWords[0];
        randomInfo.currentSize = gacha.gachaIdxCurrentSize;
        randomInfo.itemsId = itemsId;
        // Update gacha index
        removeGachaponIndex(gacha, gachaIdx);

		emit RandomFulfilled(_requestId, itemsId, _randomWords[0]);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function increaseReward(uint256 _upoAmount) external;
    function decreaseReward(uint256 _upoAmount) external;
    function getBalance(address _userAddress) external view returns (uint256);
    function getReward() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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