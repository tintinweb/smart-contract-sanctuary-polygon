/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165Storage is IERC165 {
    mapping(bytes4 => bool) private _supportsInterface;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            _supportsInterface[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportsInterface[interfaceId] = true;
    }
}

interface IERC1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface EscrowInt {
    function placeOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256[2] calldata _timeline,
        uint256 _adminPlatformFee,
        address _tokenAddress
    ) external returns (bool);
}

interface IERC2981 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

abstract contract ERC2981 is IERC2981 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
        internal
        virtual
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

contract ERC1155 is Context, ERC165Storage, ERC2981, IERC1155 {
    using Address for address;

    address public admin;
    uint256 public tokenId;
    uint256 public maxEditionsPerNFT;
    string public contractURI;
    address[] public paymentTokens;
    address public escrowAddress;
    EscrowInt public EscrowInterface;

    struct owner {
        address creator;
        uint256 percent1;
        address coCreator;
        uint256 percent2;
    }

    enum Type {
        Instant,
        Auction
    }

    event AdminChanged(address indexed _newAdmin, uint256 timestamp);
    event EscrowChanged(address indexed _newEscrow, uint256 timestamp);
    event CreatorStatusUpdated(
        address indexed _creator,
        bool _status,
        uint256 fee,
        uint256 timestamp
    );
    event PaymentTokenUpdated(
        address indexed _paymentToken,
        bool _status,
        uint256 timestamp
    );
    event MaxEditionsUpdated(
        uint256 prevValue,
        uint256 newValue,
        uint256 timestamp
    );

    mapping(address => bool) public creator;
    mapping(address => uint256) public creatorFee;
    mapping(uint256 => owner) private ownerOf;
    mapping(uint256 => string) public uri;
    mapping(address => bool) public paymentEnabled;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => bool) public released;

    constructor(
        address _admin,
        address _escrowAddress,
        string memory _contractURI,
        address _defaultRoyaltyReceiver,
        uint96 _royaltyPercent
    ) {
        require(_admin != address(0), "Zero admin address");
        require(_escrowAddress != address(0), "Zero Escrow address");
        admin = _admin;
        escrowAddress = _escrowAddress;
        EscrowInterface = EscrowInt(escrowAddress);
        creator[_admin] = true;
        paymentEnabled[address(0)] = true;
        paymentTokens.push(address(0));
        contractURI = _contractURI;
        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(IERC2981).interfaceId);
        _setDefaultRoyalty(_defaultRoyaltyReceiver, _royaltyPercent);
        emit AdminChanged(_admin, block.timestamp);
        emit EscrowChanged(_escrowAddress, block.timestamp);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin returns (bool) {
        require(_admin != address(0), "Zero admin address");
        admin = _admin;
        emit AdminChanged(_admin, block.timestamp);
        return true;
    }

    function release(uint256 _token) external {
        require(_msgSender() == escrowAddress);
        released[_token] = true;
    }

    // function setTokenRoyalty(
    //     uint256 _tokenId,
    //     address _receiver,
    //     uint96 _feeNumerator
    // ) external onlyAdmin {
    //     _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    // }

    function setEscrowAddress(address _escrowAddress)
        external
        onlyAdmin
        returns (bool)
    {
        require(_escrowAddress != address(0), "Zero escrow address");
        escrowAddress = _escrowAddress;
        EscrowInterface = EscrowInt(escrowAddress);
        emit EscrowChanged(_escrowAddress, block.timestamp);
        return true;
    }

    function approveCreators(
        address[] memory _creators,
        uint256[] calldata _fees
    ) external onlyAdmin {
        require(_creators.length == _fees.length, "Length Mismatch");
        for (uint256 i = 0; i < _creators.length; i++) {
            creator[_creators[i]] = true;
            require(_fees[i] < 100, "Fee greater than 99");
            creatorFee[_creators[i]] = _fees[i];
            emit CreatorStatusUpdated(
                _creators[i],
                true,
                _fees[i],
                block.timestamp
            );
        }
    }

    function disableCreators(address[] memory _creators) external onlyAdmin {
        for (uint256 i = 0; i < _creators.length; i++) {
            creator[_creators[i]] = false;
            emit CreatorStatusUpdated(_creators[i], false, 0, block.timestamp);
        }
    }

    function addPaymentTokens(address tokenAddress) external onlyAdmin {
        require(tokenAddress != address(0), "Zero token address");
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            if (paymentTokens[i] == tokenAddress) {
                paymentEnabled[tokenAddress] = true;
            } else {
                paymentTokens.push(tokenAddress);
                paymentEnabled[tokenAddress] = true;
            }

            emit PaymentTokenUpdated(tokenAddress, true, block.timestamp);
        }
    }

    function disablePaymentTokens(address tokenAddress) external onlyAdmin {
        paymentEnabled[tokenAddress] = false;
        emit PaymentTokenUpdated(tokenAddress, false, block.timestamp);
    }

    function ownerOfToken(uint256 _tokenId)
        public
        view
        returns (
            address,
            uint256,
            address,
            uint256
        )
    {
        return (
            ownerOf[_tokenId].creator,
            ownerOf[_tokenId].percent1,
            ownerOf[_tokenId].coCreator,
            ownerOf[_tokenId].percent2
        );
    }

    function setMaxEditions(uint256 _number) external onlyAdmin {
        require(_number > 0, "Zero editions per NFT");
        uint256 prevValue = maxEditionsPerNFT;
        maxEditionsPerNFT = _number;
        emit MaxEditionsUpdated(prevValue, _number, block.timestamp);
    }

    function mintToken(
        uint256 _editions,
        string memory _tokenURI,
        address _creator,
        address _coCreator,
        uint256 _creatorPercent,
        uint256 _coCreatorPercent,
        Type _saleType,
        uint256[2] calldata _timeline,
        uint256 _pricePerNFT,
        uint256 _adminPlatformFee,
        address tokenAddress
    ) external returns (bool) {
        require(bytes(_tokenURI).length > 0, "Invalid token URI");
        require(creator[msg.sender], "Only approved users can mint");
        require(
            paymentEnabled[tokenAddress],
            "Selected token payment disabled"
        );

        require(
            _saleType == Type.Instant || _saleType == Type.Auction,
            "Invalid saletype"
        );
        if (_saleType == Type.Auction && msg.sender != admin) {
            require(_timeline[1] > 0 && _timeline[1] <= 120, "Incorrect time");
        }
        if (msg.sender != admin) {
            require(
                _editions <= maxEditionsPerNFT,
                "Editions greater than allowed"
            );
            require(msg.sender == _creator, "Invalid Parameters");
            if (_saleType == Type.Auction) {
                require(
                    _timeline[1] > 0 && _timeline[1] <= 120,
                    "Incorrect time"
                );
            }
        }
        require(
            _creatorPercent + (_coCreatorPercent) == 100,
            "Wrong percentages"
        );
        tokenId = tokenId + (1);
        if (msg.sender == admin) {
            require(_adminPlatformFee <= 100, "Admin fee too high");
            _adminPlatformFee = _adminPlatformFee;
        } else if (creatorFee[msg.sender] > 0) {
            _adminPlatformFee = creatorFee[msg.sender];
            _setTokenRoyalty(
                tokenId,
                msg.sender,
                uint96(creatorFee[msg.sender] * 100)
            );
        } else {
            _adminPlatformFee = 0;
        }

        _mint(escrowAddress, tokenId, _editions, "");
        {
            uri[tokenId] = _tokenURI;
            ownerOf[tokenId] = owner(
                _creator,
                _creatorPercent,
                _coCreator,
                _coCreatorPercent
            );
            EscrowInterface.placeOrder(
                _creator,
                tokenId,
                _editions,
                _pricePerNFT,
                uint256(_saleType),
                _timeline,
                _adminPlatformFee,
                tokenAddress
            );
        }
        return true;
    }

    function burn(
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool) {
        require(
            released[_tokenId] || msg.sender == escrowAddress,
            "Only escrow contract"
        );
        _burn(from, _tokenId, amount);
        return true;
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length);

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
            released[id] || _msgSender() == escrowAddress,
            "Only escrow contract"
        );
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "Not owner or not approved"
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
        for (uint256 i; i < ids.length; i++) {
            require(
                released[ids[i]] || _msgSender() == escrowAddress,
                "Only escrow contract"
            );
        }
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155:Caller is not owner nor approved"
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

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
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

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
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

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 accountBalance = _balances[id][account];
        require(
            accountBalance >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(
                accountBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

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
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
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
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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