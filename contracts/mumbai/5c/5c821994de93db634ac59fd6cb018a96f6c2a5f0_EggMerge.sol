// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// _____                                    _____
// __|__   |__   __   _   ______   __  __   __|___  |__   ____     ______     __     _____   _____   __    _ 
// |     \     | |  | | | |   ___| |  |/ /  |   ___|    | |    \   |   ___|  _|  |_  /     \ |     |  \ \  // 
// |      \    | |  |_| | |   |__  |     \  |   ___|    | |     \  |   |__  |_    _| |     | |     \   \ \//  
// |______/  __| |______| |______| |__|\__\ |___|     __| |__|\__\ |______|   |__|   \_____/ |__|\__\  /__/ 
//   |_____|                                  |_____|

import './IStarNFT.sol';
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import './Guard.sol';
import './VRFConsumerBaseV2.sol';
import './VRFCoordinatorV2Interface.sol';

contract EggMerge is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    using Address for address;

    enum MergeMood {
        PAUSED,
        ONLYL1,
        ONLYL2,
        BOTH
    }

    struct RequestStatus {
        uint256[] randomWords;
        // 1 for merging lvl 1s, 2 for merging lvl 2s
        uint8 mergeLvl;
        // 0 for unlucky! || 6 for lucky
        uint8 lucky;
        // merged from address
        address nftAddress;
        address sender;
    }

    uint256 constant EGG_L2 = 0;
    uint256 constant EGG_L3 = 1;
    uint256 constant GOLDEN_EGG = 2;

    uint256 internal constant MAX_CHANCE_VALUE = 10000;
    uint256 internal MIN_CHANCE_L1 = 9600;
    uint256 internal MIN_CHANCE_L2 = 7200;
    
    uint256 public taxAmountL1;
    uint256 public taxAmountL2;

    mapping(uint256 => RequestStatus) private vrf_requests; /* requestId --> requestStatus */

    MergeMood public mood = MergeMood.ONLYL1;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => string) private _tokenURIs;

    // ========================== VRF ===================================

     VRFCoordinatorV2Interface private immutable vrfCoordinatorG;
     uint64 private immutable subscriptionId;
     uint32 private immutable callbackGasLimit = 2_000_000;
     uint32 private constant NUM_WORDS = 3;
     uint16 private constant REQUEST_CONFIRMATIONS = 3;
     bytes32 private immutable gasLane;

    constructor(uint64 subscriptionId_, address vrfCoordinatorV2_, bytes32 gasLane_, uint256 taxAmountL1_,  uint256 taxAmountL2_)
        VRFConsumerBaseV2(vrfCoordinatorV2_){
            taxAmountL1 = taxAmountL1_;
            taxAmountL2 = taxAmountL2_;
            _setupOwner(msg.sender);    
            subscriptionId = subscriptionId_;
            vrfCoordinatorG = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
            gasLane = gasLane_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return tokenURI;
    }

     /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
     function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }
    
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

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

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

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

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

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

    //

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function mergeGenesis(uint256[] calldata ids, IStarNFT _starNFT) public payable nonReentrant() returns (uint256 requestId) {
        require(mood == MergeMood.BOTH || mood == MergeMood.ONLYL1, "Merge is Paused");
        require(msg.value >= taxAmountL1, "ERR");
        payable(address(this)).transfer(taxAmountL1);

        _starNFT.burnBatch(msg.sender, ids);

        // initialize VRF request
        requestId = vrfCoordinatorG.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );

        vrf_requests[requestId] = RequestStatus(
            {
                randomWords: new uint256[](0),
                mergeLvl: 1,
                lucky: 0,
                nftAddress: address(_starNFT),
                sender: msg.sender
            });

        emit RequestSent(requestId, NUM_WORDS);
        return requestId;

    }

    function mergeL2() public payable nonReentrant() returns (uint256 requestId) {
        require(mood == MergeMood.BOTH || mood == MergeMood.ONLYL2, "Merge is Paused");

        require(msg.value >= taxAmountL2, "ERR");
        payable(address(this)).transfer(taxAmountL2);

        uint256 fromBalance = _balances[0][msg.sender];
        require(fromBalance >= 3, "DuckFactory: insufficient balance");

        _burn(msg.sender, 0, 3);

        // initialize VRF request
        requestId = vrfCoordinatorG.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );

        vrf_requests[requestId] = RequestStatus(
            {
                randomWords: new uint256[](0),
                mergeLvl: 2,
                lucky: 0,
                nftAddress: address(this),
                sender: msg.sender
            });

        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;
        address merger = vrf_requests[_requestId].sender;
        uint8 mode = vrf_requests[_requestId].mergeLvl;
        uint256 moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;
        uint256[2] memory chanceL1 = chanceArray(1);
        uint256[2] memory chanceL2 = chanceArray(2);

        if (mode == 1) {
            if (moddedRng < chanceL1[0]) {
                _mint(merger, EGG_L2, 1, "");
            } else {
                // Lucky Ducky!
                vrf_requests[_requestId].lucky = 6;
                _mint(merger, GOLDEN_EGG, 1, "");
            }
        } else if (mode == 2) {
            if (moddedRng < chanceL2[0]) {
                _mint(merger, EGG_L3, 1, "");
            } else {
                // Lucky Ducky!
                vrf_requests[_requestId].lucky = 6;
                _mint(merger, GOLDEN_EGG, 1, "");
            }
        } else {
            revert callErr();
        }

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function chanceArray(uint8 lvl) internal view returns (uint256[2] memory) {
        if (lvl == 1) {
            return [MIN_CHANCE_L1, MAX_CHANCE_VALUE];
        } else if (lvl == 2) {
            return [MIN_CHANCE_L2, MAX_CHANCE_VALUE];
        } else {
            revert callErr();
        }
    }

    function setChanceL1(uint256 _min) external onlyOwner {
        if (_min > MAX_CHANCE_VALUE) revert callErr();
        MIN_CHANCE_L1 = _min;
        emit ChanceIsSet(_min);
    }

    function setChanceL2(uint256 _min) external onlyOwner {
        if (_min > MAX_CHANCE_VALUE) revert callErr();
        MIN_CHANCE_L2 = _min;
        emit ChanceIsSet(_min);
    }

    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        if (_rescueTo == address(0)) revert callErr();
        _rescueTo.transfer(_amount);
    }

    function setTaxAmount(uint256[2] memory _taxAmount) external onlyOwner {
        require(_taxAmount[0] <= 10 ether || _taxAmount[1] <= 10 ether, "Can't set higher than 10");
        taxAmountL1 = _taxAmount[0];
        taxAmountL2 = _taxAmount[1];
        emit TaxSetted(_taxAmount);
    }

    function setMergeMood(MergeMood _mood) external onlyOwner {
        mood = _mood;
    }

}