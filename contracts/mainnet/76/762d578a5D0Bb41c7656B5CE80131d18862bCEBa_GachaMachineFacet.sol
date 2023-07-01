// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../Vendor.sol";
import "../libraries/LibDiamond.sol";
import "../interfaces/ICollectionWhiteList.sol";
import "../interfaces/IOwnerOf.sol";
import "../libraries/LibGacheMachine.sol";

contract GachaMachineFacet {
    event CreateCollection(address _who, uint256 _collectionId);
    event PublishCollection(address _who, uint256 _collectionId);
    event UnpublishCollection(address _who, uint256 _collectionId);
    event NFTDeposit(address _who, address _tokenAddress, uint256 _tokenId);
    event NFTWithdraw(address _who, address _tokenAddress, uint256 _tokenId);
    event NFTClaim(address _who, address _tokenAddress, uint256 _tokenId);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function initialize(
        uint256 feeRate_, // 10000 = 100%, 100 = 1%
        address payable feeTo_
    ) external onlyOwner {
        GachaMachineStorage storage s = state();
        s.feeRate = feeRate_;
        s.feeTo = feeTo_;
    }

    function setFeeRate(uint256 feeRate_) external onlyOwner {
        state().feeRate = feeRate_;
    }

    function setFeeTo(address payable feeTo_) external onlyOwner {
        state().feeTo = feeTo_;
    }

    function setNftCoin(uint256 collectionId, address nftCoin_) external onlyOwner {
        state().allCollections[collectionId].nftCoin = nftCoin_;
    }
    
    function setNftPrice(uint256 collectionId, uint256 nftPrice_) external onlyOwner {
        state().allCollections[collectionId].nftPrice = nftPrice_;
    }

    function createCollection(
        string calldata name_,
        string memory cover_,
        string memory title_,
        string memory introduction_,
        uint256 flags,
        address nftCoin_,
        uint256 nftPrice_
    ) external payable returns (Collection memory) {
        Collection memory collection = _createCollection(
            name_,
            cover_,
            title_,
            introduction_,
            flags,
            nftCoin_,
            nftPrice_
        );
        return collection;
    }

    function updateCollectionDetail(
        uint256 collectionId,
        string memory cover_,
        string memory title_,
        string memory introduction_
    ) public {
        require(
            state().allCollections[collectionId].owner == _msgSender() ||
                owner() == _msgSender(),
            "owner only"
        );
        string[] memory detail = new string[](3);
        detail[0] = cover_;
        detail[1] = title_;
        detail[2] = introduction_;
        state().allCollections[collectionId].detail = detail;
    }

    function addNFTsToCollection(
        address tokenAddress_,
        uint256[] memory tokenIds,
        uint256 collectionId_
    ) external {
        require(
            state().allCollections[collectionId_].owner == _msgSender(),
            "Needs collection owner"
        );
        for(uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId_ = tokenIds[i];
            uint256 nftId = _depositNFT(tokenAddress_, tokenId_);
            _addNFTToCollection(nftId, collectionId_);
        }
    }

    function removeNFTFromCollection(uint256 nftId_, uint256 collectionId_)
        external
    {
        address nftOwner = state().allNFTs[nftId_].owner;
        _removeNFTFromCollection(nftId_, collectionId_);
        _withdrawNFT(nftOwner, nftId_, false, 0);
    }

    function publishCollection(
        uint256 collectionId_
    ) external {
        _publishCollection(collectionId_);
    }

    function drawBoxes(uint256 collectionId_, uint256 times_) public payable {
        require(ICollectionWhiteList(address(this)).isOpen(collectionId_, _msgSender()), "Not opening");
        (uint256 cost, uint256 whiteListTimes) = calculateCost(collectionId_, _msgSender(), times_);
        ICollectionWhiteList(address(this)).addWhiteListUsedCount(collectionId_, _msgSender(), whiteListTimes);
        _drawBox(collectionId_, _msgSender(), times_, cost);
    }

    function returnNFT(address tokenAddress_, uint256 tokenId_) public {
        uint256 nftId = state().nftIdMap[tokenAddress_][tokenId_];
        require(nftId > 0, "NFT not found");
        NFT memory nft = state().allNFTs[nftId];
        require(nft.collectionId > 0, "Collection not found");
        require(nft.claimAt > 0, "Not claim");
        require(IERC721(tokenAddress_).ownerOf(tokenId_) == _msgSender(), "Only NFT owner can return");

        IERC721(tokenAddress_).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId_
        );

        uint256 fee = nft.price * state().feeRate / 10000;
        IERC20(state().allCollections[nft.collectionId].nftCoin).safeTransfer(
                _msgSender(),
                nft.price - fee
        );
        IERC20(state().allCollections[nft.collectionId].nftCoin).safeTransfer(
                state().feeTo,
                fee
        );

        nft.claimAt = 0;
        state().allNFTs[nftId] = nft;
        state().allCollections[nft.collectionId].soldCount--;
    }

    function isPublished(uint256 collectionId_) public view returns (bool) {
        return state().allCollections[collectionId_].publishedAt > 0;
    }

    function hasFlags(uint256 flags, uint256 flag) private pure returns(bool) {
        return flags & flag == flag;
    }
    

    function _createCollection(
        string calldata name_,
        string memory cover_,
        string memory title_,
        string memory introduction_,
        uint256 flags,
        address nftCoin_,
        uint256 nftPrice_
    ) internal returns (Collection memory) {

        Collection memory collection;
        collection.owner = _msgSender();
        collection.name = name_;
        collection.publishedAt = 0;
        collection.flags = flags;
        collection.nftCoin = nftCoin_;
        collection.nftPrice = nftPrice_;

        string[] memory detail = new string[](3);
        detail[0] = cover_;
        detail[1] = title_;
        detail[2] = introduction_;

        collection.detail = detail;

        uint256 collectionId = _generateNextCollectionId();
        collection.id = collectionId;

        state().allCollections[collectionId] = collection;
        state().collectionsByOwner[_msgSender()].push(collectionId);
        emit CreateCollection(_msgSender(), collection.id);
        return collection;
    }

    function _generateNextNFTId() private returns (uint256) {
        return ++state().nextNFTId;
    }

    function _generateNextCollectionId() private returns (uint256) {
        return ++state().nextCollectionId;
    }

    function _depositNFT(address tokenAddress_, uint256 tokenId_)
        private
        returns (uint256)
    {
        IERC721(tokenAddress_).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId_
        );

        NFT memory nft;
        nft.tokenAddress = tokenAddress_;
        nft.tokenId = tokenId_;
        nft.owner = _msgSender();
        nft.collectionId = 0;
        nft.indexInCollection = 0;

        uint256 nftId;

        if (state().nftIdMap[tokenAddress_][tokenId_] > 0) {
            nftId = state().nftIdMap[tokenAddress_][tokenId_];
        } else {
            nftId = _generateNextNFTId();
            state().nftIdMap[tokenAddress_][tokenId_] = nftId;
        }

        nft.id = nftId;
        state().allNFTs[nftId] = nft;
        state().nftsByOwner[_msgSender()].push(nftId);

        emit NFTDeposit(_msgSender(), tokenAddress_, tokenId_);
        return nftId;
    }

    function _withdrawNFT(
        address who_,
        uint256 nftId_,
        bool isClaim_,
        uint256 price
    ) private {
        address tokenAddress = state().allNFTs[nftId_].tokenAddress;
        uint256 tokenId = state().allNFTs[nftId_].tokenId;

        IERC721(tokenAddress).safeTransferFrom(address(this), who_, tokenId);

        if (isClaim_) {
            state().allNFTs[nftId_].claimAt = block.timestamp;
            state().allNFTs[nftId_].owner = payable(who_);
            state().allNFTs[nftId_].price = price;

            emit NFTClaim(who_, tokenAddress, tokenId);
        } else {
            emit NFTWithdraw(who_, tokenAddress, tokenId);
        }
    }

    function _addNFTToCollection(
        uint256 nftId_,
        uint256 collectionId_
    ) private {
        require(
            state().allNFTs[nftId_].owner == _msgSender(),
            "Only NFT owner can add"
        );

        require(state().allNFTs[nftId_].collectionId == 0, "Already added");
        state().allNFTs[nftId_].collectionId = collectionId_;
        state().allNFTs[nftId_].indexInCollection = state().nftsByCollectionId[collectionId_]
            .length;

        // Push to nftsByCollectionId.
        state().nftsByCollectionId[collectionId_].push(nftId_);
    }

    function _removeNFTFromCollection(uint256 nftId_, uint256 collectionId_)
        private
    {
        Collection storage collection = state().allCollections[collectionId_];

        require(
            state().allNFTs[nftId_].owner == _msgSender() ||
                collection.owner == _msgSender(),
            "Only NFT owner or collection owner can remove"
        );
        require(
            state().allNFTs[nftId_].collectionId == collectionId_,
            "NFT not in collection"
        );

        state().allNFTs[nftId_].collectionId = 0;

        // Removes from nftsByCollectionId
        uint256 index = state().allNFTs[nftId_].indexInCollection;
        uint256 lastNFTId = state().nftsByCollectionId[collectionId_][
            state().nftsByCollectionId[collectionId_].length - 1
        ];

        state().nftsByCollectionId[collectionId_][index] = lastNFTId;
        state().allNFTs[lastNFTId].indexInCollection = index;
        state().nftsByCollectionId[collectionId_].pop();
    }

    function _drawBox(uint256 collectionId_, address user, uint256 times_, uint256 cost) private {
        require(times_ > 0, "times must be greater than 0");
        Collection storage collection = state().allCollections[collectionId_];
        require(collection.soldCount.add(times_) <= state().nftsByCollectionId[collectionId_].length, "Not enough left");
                if (state().allCollections[collectionId_].nftCoin == address(0)) {
            require(msg.value == cost, "not enough token");
        } else {
            require(
                IERC20(state().allCollections[collectionId_].nftCoin).allowance(
                    _msgSender(),
                    address(this)
                ) >= cost,
                "not enough erc20 token"
            );
            IERC20(state().allCollections[collectionId_].nftCoin).safeTransferFrom(
                _msgSender(),
                address(this),
                cost
            );
        }
        collection.soldCount = collection.soldCount.add(times_);
        _claimUserNFT(collectionId_, user, times_, cost);
    }

    function calculateCost(uint256 collectionId_, address payable to, uint256 times_) public view returns (uint256 cost, uint256 whiteListTimes) {
        uint256 price = state().allCollections[collectionId_].nftPrice;
        ICollectionWhiteList _collectionWhiteList = ICollectionWhiteList(address(this));
        ICollectionWhiteList.WhiteListItem
            memory whiteList = _collectionWhiteList.getCollectionWhiteListItem(collectionId_, to);
        bool allOpen = _collectionWhiteList.getCollectionAllOpen(collectionId_);
        bool whiteListOpen = _collectionWhiteList.getCollectionWhiteListOpen(collectionId_);
        uint256 whiteListLimit;
        if(!allOpen) {
            require(
                whiteListOpen
                && whiteList.price > 0,
                "Not opening"
            );
        }

        if(whiteListOpen && whiteList.price > 0) {
            whiteListLimit = whiteList.limit == 0 ? 1 : whiteList.limit;
            require(
                allOpen || times_.add(whiteList.usedCount) <= whiteListLimit,
                "Reach buy limit"
            );
        }
        uint256 canUseWhiteListTimes = whiteListLimit == 0 || whiteList.usedCount > whiteListLimit ? 0 : whiteListLimit.sub(whiteList.usedCount);
        whiteListTimes = times_ > canUseWhiteListTimes ? canUseWhiteListTimes : times_;
        cost = price.mul(times_.sub(whiteListTimes)).add(whiteListTimes.mul(whiteList.price));
    }

    function _claimUserNFT(
        uint256 collectionId_,
        address user,
        uint256 times_,
        uint256 cost
    ) private returns (NFT[] memory) {
        NFT[] memory nftList_ = new NFT[](times_);
        for (uint256 i = 0; i < times_; i++) {
            nftList_[i] = state().allNFTs[
                _claimNFT(collectionId_, user, cost / times_)
            ];
        }
        return nftList_;
    }

    function _claimNFT(uint256 collectionId_, address user, uint256 price)
        private
        returns (uint256)
    {
        NFT memory nft_ = _randomNft(collectionId_);
        uint256 nftId = nft_.id;
        _withdrawNFT(user, nftId, true, price);
        return nftId;
    }

    // random nft pending in collection
    function _randomNft(uint256 collectionId_) private view returns (NFT memory) {
        uint256[] memory nftsPending_ = _nftsPending(collectionId_);
        uint256 l = nftsPending_.length;
        uint256 r = _psuedoRandomness() % l;
        return state().allNFTs[nftsPending_[r]];
    }

    function _psuedoRandomness() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(_msgSender()))
                                )
                            ) / (block.timestamp)) +
                            block.number
                    )
                )
            );
    }

    // nft pending in collection
    function _nftsPending(uint256 collectionId_)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory nftIds_ = state().nftsByCollectionId[collectionId_];
        uint256[] memory nftsPending_ = new uint256[](nftIds_.length);
        uint256 j = 0;
        for (uint256 i = 0; i < nftIds_.length; i++) {
            if (state().allNFTs[nftIds_[i]].claimAt == 0) {
                nftsPending_[j] = nftIds_[i];
                j++;
            }
        }
        uint256[] memory nftsPending2_ = new uint256[](j);
        uint256 l = 0;
        for (uint256 k = 0; k < nftsPending_.length; k++) {
            if (nftsPending_[k] != 0) {
                nftsPending2_[l] = nftsPending_[k];
                l++;
            }
        }

        return nftsPending2_;
    }

    function _publishCollection(
        uint256 collectionId_
    ) private {
        Collection storage collection = state().allCollections[collectionId_];

        require(collection.owner == _msgSender(), "Only owner can publish");

        uint256 actualSize = state().nftsByCollectionId[collectionId_].length;
        collection.size = actualSize;
        collection.publishedAt = block.timestamp;
        emit PublishCollection(_msgSender(), collectionId_);
    }
    
    function _msgSender() private view returns (address payable) {
        return msg.sender;
    }
    

    function owner() private view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function state() private pure returns(GachaMachineStorage storage){
        return LibGachaMachine.gachaMachineStorage();
    }

    modifier onlyOwner() {
        require(
            LibDiamond.contractOwner() == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

library LibGachaMachine {
    bytes32 constant GACHAMACHINE_STORAGE_POSITION =
        keccak256("diamond.standard.gachamachine.storage");

    function gachaMachineStorage()
        internal
        pure
        returns (GachaMachineStorage storage ws)
    {
        bytes32 position = GACHAMACHINE_STORAGE_POSITION;
        assembly {
            ws.slot := position
        }
    }
}

struct GachaMachineStorage {
    uint256 feeRate;
    address payable feeTo;
    uint256 nextNFTId;
    uint256 nextCollectionId;

    // nftId => NFT
    mapping(uint256 => NFT) allNFTs;
    // owner => nftId[]
    mapping(address => uint256[]) nftsByOwner;
    // tokenAddress => tokenId => nftId
    mapping(address => mapping(uint256 => uint256)) nftIdMap;
    // collectionId => Collection
    mapping(uint256 => Collection) allCollections;
    // owner => collectionId[]
    mapping(address => uint256[]) collectionsByOwner;
    // collectionId => nftId[]
    mapping(uint256 => uint256[]) nftsByCollectionId;
}

struct NFT {
    uint256 id;
    address tokenAddress;
    uint256 tokenId;
    address payable owner;
    uint256 price;
    uint256 collectionId;
    uint256 indexInCollection;
    uint256 claimAt;
}

struct Collection {
    uint256 id;
    address payable owner;
    string name;
    uint256 size;
    string[] detail;
    uint256 publishedAt; // time that published.
    uint256 soldCount;
    uint256 flags;
    address nftCoin;
    uint256 nftPrice;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if(oldFacetAddress == _facetAddress) continue;

            removeFunction(oldFacetAddress, selector);

            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
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
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        if(_facetAddress == address(0)) return;
        DiamondStorage storage ds = diamondStorage();
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
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
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
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
pragma solidity ^0.7.6;

interface IOwnerOf {
    function ownerOf(uint256 id) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface ICollectionWhiteList
{
    struct WhiteListItem {
            uint256 price;
            uint256 usedCount;
            address addr;
            uint256 limit;
    }

    function getCollectionWhiteListAddress(uint256 collectionId) external view returns (address[] memory);
    function getCollectionWhiteList(uint256 collectionId) external view returns (WhiteListItem[] memory);
    function getCollectionAllOpen(uint256 collectionId) external view returns (bool);
    function getCollectionWhiteListOpen(uint256 collectionId) external view returns (bool);
    function getCollectionWhiteListItem(uint256 collectionId, address addr) external view returns (WhiteListItem memory);
    function setWhiteList(uint256 collectionId, address[] memory addressArray, uint256[] memory priceArray, uint256[] memory limitArray) external;
    function setCollectionWhiteListOpen(uint256 collectionId, bool open) external;
    function setCollectionAllOpen(uint256 collectionId, bool open) external;
    function addWhiteListUsedCount(uint256 collectionId, address addr, uint256 count) external;
    function isOpen(uint256 collectionId, address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
// File: @openzeppelin/contracts/utils/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    //    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    //    }
    //
    //    /**
    //     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //     * but performing a delegate call.
    //     *
    //     * _Available since v3.4._
    //     */
    //    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //        require(isContract(target), "Address: delegate call to non-contract");
    //
    //        // solhint-disable-next-line avoid-low-level-calls
    //        (bool success, bytes memory returndata) = target.delegatecall(data);
    //        return _verifyCallResult(success, returndata, errorMessage);
    //    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}