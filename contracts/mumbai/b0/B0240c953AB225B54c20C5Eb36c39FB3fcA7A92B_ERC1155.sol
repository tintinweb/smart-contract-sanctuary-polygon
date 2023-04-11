// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155Receiver.sol";

contract ERC1155 {
    // token id => (address => balance)
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // owner => (operator => yes/no)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    // token id => token uri
    mapping(uint256 => string) internal _tokenUris;
    // token id => supply
    mapping(uint256 => uint256) public totalSupply;

    uint256 public nextTokenIdToMint;
    string public name;
    string public symbol;
    address public owner;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        nextTokenIdToMint = 0;
    }

    function balanceOf(address _owner, uint256 _tokenId) public view returns(uint256) {
        require(_owner != address(0), "Add0");
        return _balances[_tokenId][_owner];
    }

    function balanceOfBatch(address[] memory _accounts, uint256[] memory _tokenIds) public view returns(uint256[] memory) {
        require(_accounts.length == _tokenIds.length, "accounts id length mismatch");
        // create an array dynamically
        uint256[] memory balances = new uint256[](_accounts.length);

        for(uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = balanceOf(_accounts[i], _tokenIds[i]);
        }

        return balances;
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
    }

    function isApprovedForAll(address _account, address _operator) public view returns(bool) {
        return _operatorApprovals[_account][_operator];
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "not authorized");
        // create an array
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = _id;
        amounts[0] = _amount;
        // transfer
        _transfer(_from, _to, ids, amounts);
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
        // safe transfer checks
        _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public {
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "not authorized");
        require(_ids.length == _amounts.length, "length mismatch");

        _transfer(_from, _to, _ids, _amounts);
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _amounts, _data);
    }

    function uri(uint256 _tokenId) public view returns(string memory) {
        return _tokenUris[_tokenId];
    }

    function mintTo(address _to, uint256 _tokenId, string memory _uri, uint256 _amount) public {
        require(owner == msg.sender, "not authorized");

        uint256 tokenIdToMint;

        if (_tokenId == type(uint256).max) {
            tokenIdToMint = nextTokenIdToMint;
            nextTokenIdToMint += 1;
            _tokenUris[tokenIdToMint] = _uri;
        } else {
            require(_tokenId < nextTokenIdToMint, "invalid id");
            tokenIdToMint = _tokenId;
        }

        _balances[tokenIdToMint][_to] += _amount;
        totalSupply[tokenIdToMint] += _amount;
        
        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }

    // INTERNAL FUNCTIONS

    function _transfer(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_to != address(0), "transfer to address 0");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            uint256 fromBalance = _balances[id][_from];
            require(fromBalance >= amount, "insufficient balance for transfer");
            _balances[id][_from] -= amount;
            _balances[id][_to] += amount;
        }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }
}