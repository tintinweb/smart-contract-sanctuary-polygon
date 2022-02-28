// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import './ERC1155.sol';
import './Strings.sol';
import './SafeMath.sol';
import './SafeOwnable.sol';

contract MAYA1155 is ERC1155, SafeOwnable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private _currentTokenID = 0;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public types;
    mapping(uint256 => uint256) public values;
    mapping(uint256 => bool) public disableTransfer;
    string public name;
    string public symbol;
    mapping(uint256 => string) private uris;
    string public baseMetadataURI;

    modifier onlyOwnerOrCreator(uint256 id) {
        require(msg.sender == owner() || msg.sender == creators[id], "only owner or creator can do this");
        _;
    }

    function disableTokenTransfer(uint _id) external onlyOwnerOrCreator(_id) {
        disableTransfer[_id] = true;
    }

    function enableTokenTransfer(uint _id) external onlyOwnerOrCreator(_id) {
        disableTransfer[_id] = false;
    }

    constructor(string memory _uri, string memory name_, string memory symbol_) ERC1155(_uri) SafeOwnable(msg.sender) {
        name = name_;
        symbol = symbol_;
        baseMetadataURI = _uri;
    }

    function setURI(string memory newuri) external {
        baseMetadataURI = newuri;
    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "ERC1155#uri: NONEXISTENT_TOKEN");

        if(bytes(uris[_id]).length > 0){
            return uris[_id];
        }
        if (types[_id] > 0) {
            return string(abi.encodePacked(baseMetadataURI, "?type=", types[_id].toString()));
        } else {
            return string(abi.encodePacked(baseMetadataURI, "/", _id.toString()));
        }
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function updateUri(uint256 _id, string memory _uri) external onlyOwnerOrCreator(_id) {
        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
        else{
            delete uris[_id];
            emit URI(string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json")), _id);
        }
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256 _type,
        bytes memory _data
    ) external returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        types[_id] = _type;
        emit URI(string(abi.encodePacked(baseMetadataURI, "?type=", _id.toString())), _id);

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function createBatch(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256[] memory _types,
        uint256[] memory _values,
        bytes memory _data
    ) public returns (uint256[] memory tokenIds) {
        require(_types.length > 0 && _types.length == _values.length, "illegal type length");
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        require(_types.length > 0, "illegal type length");
        tokenIds = new uint[](_types.length);
        for (uint i = 0; i < _types.length; i ++) {
            uint id = _currentTokenID.add(i + 1);
            tokenIds[i] = id;
            creators[id] = msg.sender;
            types[id] = _types[i];
            values[id] = _values[i];
            if (_initialSupply != 0) _mint(msg.sender, id, _initialSupply, _data);
            tokenSupply[id] = _initialSupply;
            tokenMaxSupply[id] = _maxSupply;
        }
        _currentTokenID= _currentTokenID.add(_types.length);
    }

    function createBatchDefault(uint256[] memory _types, uint256[] memory _values) external returns (uint256[] memory tokenIds) {
        return createBatch(uint(-1), 0, _types, _values, new bytes(0));
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
    
    function mint(address to, uint256 _id, uint256 _quantity, bytes memory _data) public onlyOwnerOrCreator(_id) {
        uint256 tokenId = _id;
        require(tokenSupply[tokenId].add(_quantity) <= tokenMaxSupply[tokenId], "Max supply reached");
        _mint(to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function burn(address _account, uint256 _id, uint256 _amount) external onlyOwnerOrCreator(_id) {
        _burn(_account, _id, _amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external {
        for (uint i = 0; i < ids.length; i ++) {
            require(msg.sender == owner() || msg.sender == creators[ids[i]], "only owner or creator can do this");
        }
        _burnBatch(account, ids, amounts);
    }

    function multiSafeTransferFrom(address from, address[] memory tos, uint256 id, uint256[] memory amounts, bytes memory data) external {
        require(tos.length == amounts.length, "illegal num");
        for (uint i = 0; i < tos.length; i ++) {
            safeTransferFrom(from, tos[i], id, amounts[i], data);
        }
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    )
        internal
        view
        override
    { 
        if (from != address(0) && to != address(0)) {
            for (uint i = 0; i < ids.length; i ++) {
                require(amounts[i] == 0 || !disableTransfer[ids[i]], "Token Transfer Disabled");
            }
        }
    }

    function totalBalance (
        address account,
        uint256[] memory ids
    )
        external
        view
        returns (uint256, uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](ids.length);
        uint256 _totalBalance = 0;

        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = balanceOf(account, ids[i]);
            _totalBalance = _totalBalance.add(batchBalances[i]);
        }

        return (_totalBalance, batchBalances);
    }
}