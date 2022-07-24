// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./accessControl.sol";

contract Payment is AccessControl{

    struct buyer {
        string name;
        address addr;
    }

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct seller {
        string name;
        address addr;
    }

    mapping(address => buyer) public buyers;
    mapping(address => seller) public sellers;
    mapping(uint256 => uint256) private amount;
    mapping(uint256 => string) private uri;

    event payToSellerLog(
        address indexed _seller,
        uint256 _amount,
        uint256 _productId
    );
    event refundLog(address indexed buyer, uint256 _amount, uint256 _productId);

    receive() external payable {}

    function sellerSignUp(string memory _name) public {
        sellers[msg.sender].name = _name;
        sellers[msg.sender].addr = msg.sender;
    }

    function buyerSignIn(string memory _name) public {
        buyers[msg.sender].name = _name;
        buyers[msg.sender].addr = msg.sender;
    }

    function buy(uint256 _amount) public payable {
        require(msg.value > 0, "Minimum value should not be zero");
        require(msg.value >= _amount, "Less amount");
        (bool sent, ) = payable(owner).call{value: msg.value}("");
        require(sent, "Failed to send matic");
        // amount[_id] = _amount;
    }

    function payToSeller(
        address payable _seller,
        uint256 _amount,
        uint256 _id
    ) public payable {
        require(amount[_id] == _amount, "Invalid Amount");
        require(sellers[_seller].addr == _seller, "Incorrect seller");
        (bool sent, ) = payable(_seller).call{value: msg.value}("");
        require(sent, "Failed to send matic");
        emit payToSellerLog(_seller, _amount, _id);
    }

    /* 
       We can use this feature, if there is delivery ecosystem. 
       Any user will claim for refund if order is canceled order before delivery 
    */

    function refund(
        address _buyer,
        uint256 _amount,
        uint256 _id
    ) public payable {
        require(amount[_id] == _amount, "Invalid amount");
        require(buyers[_buyer].addr == _buyer, "Incorrect buyer");
        (bool sent, ) = payable(_buyer).call{value: _amount}("");
        require(sent, "Failed to send matic");
        emit refundLog(_buyer, _amount, _id);
    }

    function productURI(string memory _uri, uint256 _productId)
        public
        returns (bool)
    {
        uri[_productId] = _uri;
        return true;
    }

    function getProductURI(uint256 _id) public view returns (string memory) {
        return uri[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AccessControl {

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 public constant BUYER = keccak256(abi.encodePacked("BUYER"));
    bytes32 public constant SELLER = keccak256(abi.encodePacked("SELLER"));

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }
}