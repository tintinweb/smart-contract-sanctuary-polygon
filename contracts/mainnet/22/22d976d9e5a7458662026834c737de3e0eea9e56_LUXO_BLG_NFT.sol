/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC721Metadata {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

interface ILuxochainNFT {
    event OwnershipTransferred(address indexed, address indexed);

    function owner() external view returns (address);

    function exists(uint256 tokenId) external view returns (bool);

    function getStorageType() external view returns (uint256);

    function isLuxochainNFT() external view returns (bool);

    function transferOwnership(address newIssuer) external;

    function totalSupply() external view returns (uint256);

    function count() external view returns (uint256);

    event TokenFreezed(uint256 tokenId, address unfreezableAddress);

    event TokenUnfreezed(uint256 tokenId, address newOwner);

    event VoterPromoted(address newVoter);

    event VoterRemoved(address oldVoter);

    function safeMint(
        uint256 tokenId,
        address to,
        string calldata tokenMetadataURI
    ) external;

    function multipleSafeMint(
        uint256[] calldata _tokensIds,
        address _to,
        string[] calldata _tokenMetadataURIs
    ) external;

    function freezeToken(uint256 tokenId, address unfreezeAddress) external;

    function unfreezeToken(uint256 tokenId, address newOwner) external;

    function isTokenFreezed(uint256 tokenId) external view returns (bool);

    function burn(uint256 tokenId) external;

    function voteForMinting(uint256 tokenId) external;

    function voteForAddingVoter(address newVoter) external;
    
    function voteForUnfreeze(uint256 tokenId) external;

    function voteForRemovingVoter(address voter) external;

    function addVoter(address newVoter) external;

    function removeVoter(address voter) external;

    function getVoters() external view returns (address[] memory);

    function isAVoter(address addr) external view returns (bool);

    function quorum() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);
}

contract LUXO_BLG_NFT is IERC721, IERC721Metadata, ILuxochainNFT {
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    uint256 private _totalSupply;
    uint256 private _maxTotalSupply;
    uint256 private _count;

    string private _name;
    string private _symbol;

    address private _issuer;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _metadataURIs;
    mapping(uint256 => bool) private _freezed;
    mapping(uint256 => address) private _unfreezeAddresses;
    mapping(uint256 => mapping(address => bool)) private _tokensVoters;
    mapping(uint256 => mapping(address => bool)) private _unfreezeVoters;
    mapping(uint256 => uint256) private _tokensVotes;
    mapping(address => mapping(address => bool)) private _addressesVoters;
    mapping(address => uint256) private _addressesVotes;
    mapping(address => mapping(address => bool)) private _revokeAddressesVoters;
    mapping(address => uint256) private _revokeAddressesVotes;
    mapping(uint256 => uint256) private _unfreezeVotes;
    mapping(address => bool) private _voters;
    address[] private _votersArray;
    uint256 private _numberOfVoters;
    bool private _isFreeMintable;

    constructor(
        string memory name_,
        string memory symbol_,
        bool isFreeMintable_,
        uint256 maxTotalSupply_,
        address[] memory voters_
    ) {
        _name = name_;
        _symbol = symbol_;
        _isFreeMintable = isFreeMintable_;
        _issuer = msg.sender;
        _maxTotalSupply = maxTotalSupply_;
        require(voters_.length > 0, "Not enough voters for quorum");
        for (uint256 i = 0; i < voters_.length; i++) {
            address newVoter = voters_[i];
            require(
                _voters[newVoter] == false,
                "This address is already a voter"
            );
            _votersArray.push(newVoter);
            _voters[newVoter] = true;
            _numberOfVoters++;
        }
    }

    function maxTotalSupply() public view override returns (uint256) {
        return _maxTotalSupply;
    }

    function getVoters() public view override returns (address[] memory) {
        return _votersArray;
    }

    function isAVoter(address addr) public view override returns (bool) {
        return _voters[addr] == true;
    }

    function isLuxochainNFT() public view virtual override returns (bool) {
        return true;
    }

    function getStorageType() public view virtual override returns (uint256) {
        return 1;
    }

    function owner() public view virtual override returns (address) {
        return _issuer;
    }

    function transferOwnership(address newIssuer) public virtual override {
        require(msg.sender == _issuer, "Not issuer");
        require(newIssuer != address(0), "New issuer is the zero address");
        _issuer = newIssuer;
        emit OwnershipTransferred(msg.sender, newIssuer);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC721_METADATA ||
            interfaceId == _INTERFACE_ID_ERC721 ||
            interfaceId == _INTERFACE_ID_ERC165;
    }

    function balanceOf(address __owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[__owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _owners[tokenId];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function count() external view override returns (uint256) {
        return _count;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _metadataURIs[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "Transfer to non ERC721Receiver implementer"
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != address(0), "Transfer to the zero address");
        require(!_freezed[tokenId], "Token is freezed");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Sender cannot transfer token"
        );
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        _approve(address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function exists(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _owners[tokenId] != address(0);
    }

    function voteForMinting(uint256 tokenId) public override {
        require(_voters[msg.sender] == true, "You are not a voter");
        require(
            _tokensVoters[tokenId][msg.sender] == false,
            "You have already vote for this token"
        );
        _tokensVoters[tokenId][msg.sender] = true;
        _tokensVotes[tokenId]++;
    }

    function voteForUnfreeze(uint256 tokenId) public override {
        require(_voters[msg.sender] == true, "You are not a voter");
        require(
            _unfreezeVoters[tokenId][msg.sender] == false,
            "You have already vote for this token"
        );
        _unfreezeVoters[tokenId][msg.sender] = true;
        _unfreezeVotes[tokenId]++;
    }

    function voteForAddingVoter(address newVoter) public override {
        require(_voters[msg.sender] == true, "You are not a voter");
        require(
            _addressesVoters[newVoter][msg.sender] == false,
            "You have already vote for this address"
        );
        _addressesVoters[newVoter][msg.sender] = true;
        _addressesVotes[newVoter]++;
    }

    function voteForRemovingVoter(address voter) public override {
        require(_voters[msg.sender] == true, "You are not a voter");
        require(
            _revokeAddressesVoters[voter][msg.sender] == false,
            "You have already vote for this address"
        );
        _revokeAddressesVoters[voter][msg.sender] = true;
        _revokeAddressesVotes[voter]++;
    }

    function removeVoter(address voter) public override {
        require(
            _revokeAddressesVotes[voter] >= _getNeededVotersNumber(),
            "Not enought voters"
        );
        require(_numberOfVoters > 1, "Not enought remaining voters");
        require(_voters[voter] == true, "This address is not a voter ");
        uint256 indexVoter;
        for (uint256 i = 0; i < _votersArray.length; i++) {
            address loopVoter = _votersArray[i];
            if (loopVoter == voter) {
                indexVoter = i;
            }
            _addressesVoters[voter][loopVoter] = false;
        }
        _numberOfVoters--;
        _voters[voter] = false;
        _addressesVotes[voter] = 0;
        delete _votersArray[indexVoter];
        emit VoterRemoved(voter);
    }

    function addVoter(address newVoter) public override {
        require(
            _addressesVotes[newVoter] >= _getNeededVotersNumber(),
            "Not enought voters"
        );
        require(_voters[newVoter] == false, "This address is already a voter");
        for (uint256 i = 0; i < _votersArray.length; i++) {
            _revokeAddressesVoters[newVoter][_votersArray[i]] = false;
        }
        _voters[newVoter] = true;
        _numberOfVoters++;
        _votersArray.push(newVoter);
        _revokeAddressesVotes[newVoter] = 0;
        emit VoterPromoted(newVoter);
    }

    function _safeMint(
        uint256 tokenId,
        address to,
        string calldata tokenMetadataURI
    ) internal virtual {
        require(
            _isFreeMintable ||
                _tokensVotes[tokenId] >= _getNeededVotersNumber(),
            "Not enought voters"
        );
        _owners[tokenId] = to;
        _metadataURIs[tokenId] = tokenMetadataURI;
        emit Transfer(address(0), to, tokenId);
    }

    function safeMint(
        uint256 tokenId,
        address to,
        string calldata tokenMetadataURI
    ) external override {
        require(to != address(0), "Mint to the zero address");
        require(!exists(tokenId), "Token already minted");
        _totalSupply += 1;
        require(_maxTotalSupply >= _totalSupply, "Max total supply reached");
        _count += 1;
        _balances[to] += 1;
        _safeMint(tokenId, to, tokenMetadataURI);
    }

    function multipleSafeMint(
        uint256[] calldata tokensIds,
        address to,
        string[] calldata tokenMetadataURIs
    ) external override {
        require(
            tokensIds.length == tokenMetadataURIs.length,
            "Different number of tokens and metadata provided"
        );
        require(to != address(0), "Mint to the zero address");
        require(
            _maxTotalSupply >= _totalSupply + tokensIds.length,
            "Max total supply reached"
        );
        for (uint256 i = 0; i < tokensIds.length; i++) {
            uint256 tokenId = tokensIds[i];
            require(!exists(tokenId), "Token already minted");
            _safeMint(tokenId, to, tokenMetadataURIs[i]);
        }
        _count += tokensIds.length;
        _totalSupply += tokensIds.length;
        _balances[to] += tokensIds.length;
    }

    function freezeToken(uint256 tokenId, address unfreezeAddress)
        external
        override
    {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Cannot freeze token: permission denied"
        );
        require(unfreezeAddress != address(0), "Invalid unfreeze address");
        _freezed[tokenId] = true;
        _unfreezeAddresses[tokenId] = unfreezeAddress;
        emit TokenFreezed(tokenId, unfreezeAddress);
    }

    function unfreezeToken(uint256 tokenId, address newOwner)
        external
        override
    {
        require(
            _unfreezeVotes[tokenId] >= _getNeededVotersNumber(),
            "Not enought voters"
        );
         require(
            _unfreezeAddresses[tokenId] == msg.sender,
            "You're not allowed to unfreeze this token"
        );
        require(newOwner != address(0), "Invalid new owner address");
        delete _freezed[tokenId];
        delete _unfreezeAddresses[tokenId];
        _owners[tokenId] = newOwner;
        emit TokenUnfreezed(tokenId, newOwner);
    }

    function isTokenFreezed(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _freezed[tokenId];
    }

    function burn(uint256 tokenId) external override {
        require(!_freezed[tokenId], "Token is freezed");
        address __owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "Permission denied");
        _totalSupply -= 1;
        _balances[__owner] -= 1;
        delete _owners[tokenId];
        for (uint256 i = 0; i < _votersArray.length; i++) {
            _tokensVoters[tokenId][_votersArray[i]] = false;
        }
        _tokensVotes[tokenId] = 0;
        _approve(address(0), tokenId);
        emit Transfer(__owner, address(0), tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!isContract(to)) return true;
        try
            IERC721Receiver(to).onERC721Received(
                msg.sender,
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("Transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(exists(tokenId), "Operator query for nonexistent token");
        address __owner = ownerOf(tokenId);
        return (spender == __owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(__owner, spender));
    }

    function _setApprovalForAll(
        address __owner,
        address operator,
        bool approved
    ) internal virtual {
        require(__owner != operator, "Approve to caller");
        _operatorApprovals[__owner][operator] = approved;
        emit ApprovalForAll(__owner, operator, approved);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address __owner = ownerOf(tokenId);
        require(to != __owner, "Approval to current owner");
        require(
            msg.sender == __owner || isApprovedForAll(__owner, msg.sender),
            "Approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(exists(tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address __owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[__owner][operator];
    }

    function _getNeededVotersNumber() internal view returns (uint256) {
        uint256 quotient = _numberOfVoters / 2;
        if (quotient == 0) {
            return 1;
        }
        uint256 remainder = _numberOfVoters - 2 * quotient;
        if (remainder > 0) {
            return quotient + 1;
        }
        return quotient;
    }

    function quorum() external view returns (uint256) {
        return _getNeededVotersNumber();
    }
}