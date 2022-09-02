// SPDX-License-Identifier: MIT
// Version 0.1.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Interface_NFTManagementStore.sol";

contract NFTManagementStore is I_NFTManagementStore {

    address $owner;
    mapping(address => bool) $operators;
    mapping(bytes32 => Meta) private $metas;
    mapping(address => bool) public $activenesses;
    mapping(address => bool) public $allowances;
    mapping(uint256 => address) public $factories;
    mapping(bytes32 => address) public $nfts;
    mapping(bytes32 => address) public $users;

    uint256 $factoryCount = 0;
    uint256 $nftCount = 0;
    uint256 $userCount = 0;

    event Interaction(string message);

    modifier onlyOwner() {
        if (msg.sender != $owner) {
            revert();
        }
        _;
    }

    modifier onlyOperator() {
        if (!$operators[msg.sender]) {
            revert();
        }
        _;
    }

    modifier onlyApproved() {
        if (!$allowances[msg.sender]) {
            revert();
        }
        _;
    }

    constructor() {
        $owner = msg.sender;
        $operators[msg.sender] = true;
    }

    function transferOwnership(
        address owner
    ) public onlyOwner {
        require(msg.sender == $owner);
        $owner = owner;
        emit Interaction("Ownership transferred");
    }

    function setMeta(
        bytes32 key,
        string memory text,
        bytes memory data
    ) override public onlyOperator {
        $metas[key] = Meta({
            text: text,
            data: data
        });
    }

    function getMeta(bytes32 key) override public view returns (Meta memory meta) {
        meta = $metas[key];
    }

    function setActiveness(
        bool flag,
        address _contract
    ) override public onlyOperator {
        $activenesses[_contract] = flag;
    }

    function getActiveness(address _contract) override public view returns (bool isActive) {
        isActive = $activenesses[_contract];
    }

    function setAllowance(
        bool flag,
        address _contract
    ) override public onlyOperator {
        $allowances[_contract] = flag;
    }

    function getAllowance(address _contract) override public view returns (bool isActive) {
        isActive = $allowances[_contract];
    }

    function addFactory(
        uint256 built_version,
        address factory
    ) override public onlyOperator {
        require($factories[built_version] == address(0), "Factory built version already exists");
        $factories[built_version] = factory;
        $factoryCount += 1;
        emit Interaction("Factory added");
    }

    function getFactory(uint256 built_v) override public view returns (address) {
        return $factories[built_v];
    }

    function getTotalFactory() override public view returns (uint256) {
        return $factoryCount;
    }

    function addNFT(bytes32 signature, address nft)
        override public onlyOperator
    {
        $nfts[signature] = nft;
        $nftCount += 1;
        emit Interaction("NFT added");
    }

    function getNFT(bytes32 signature)
        override 
        public
        view
        returns (address)
    {
        return $nfts[signature];
    }

    function getTotalNFT() override public view returns (uint256) {
        return $nftCount;
    }

    function setUser(
        bytes32 signature,
        address _address
    )
        override public onlyOperator
    {
        $users[signature] = _address;
        $userCount += 1;
        emit Interaction("User set");
    }

    function getUser(bytes32 signature)
        override public view
        returns (address)
    {
        return $users[signature];
    }

    function getTotalUser() override public view returns (uint256) {
        return $userCount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface I_NFTManagementStore {    
    struct Meta {
        string text;
        bytes data;
    }

    function setMeta(bytes32 key, string memory text, bytes memory data) external;
    function getMeta(bytes32 key) external view returns (Meta memory meta);
    function setActiveness(bool flag, address factory) external;
    function getActiveness(address factory) external view returns (bool);
    function setAllowance(bool flag, address factory) external;
    function getAllowance(address factory) external view returns (bool);
    function addFactory(uint256 factory_built_version, address factory) external;
    function getFactory(uint256 factory_built_version) external view returns (address);
    function getTotalFactory() external view returns (uint256);
    function addNFT(bytes32 signature, address nft) external;
    function getNFT(bytes32 signature) external view returns (address);
    function getTotalNFT() external view returns (uint256);
    function setUser(bytes32 signature, address user) external;
    function getUser(bytes32 signature) external view returns (address);
    function getTotalUser() external view returns (uint256);
}