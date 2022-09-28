/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC1155 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    uint public mintFee = 0;
    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;
    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external {

        require(_to != address(0x0), "incorrect adddress");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "You are Not Authorized for this");

        balances[_id][_from] = balances[_id][_from] - _value;
        balances[_id][_to]   = balances[_id][_to] + _value;

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // if (_to.isContract()) {
        //     _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        // }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_to != address(0x0), "incorrect adddress");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "You are Not Authorized for this");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            balances[id][_from] = balances[id][_from] - value;
            balances[id][_to]   = balances[id][_to] + value;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // if (_to.isContract()) {
        //     _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        // }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function mint(address _account, uint _id, uint256 _value) public payable returns (uint){
        require(msg.value == mintFee);
        balances[_id][_account] = _value;
        return _id;
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) payable public
    {   
        require(msg.value == mintFee);
        require(_to != address(0x0), "incorrect adddress");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            balances[id][_to]   = balances[id][_to] + value;
        }
    }

}