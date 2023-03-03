/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Store is Context{
    // The core owner of the contract
    address public core_owner;
    
    // The count of Assets
    uint256 public countOfAsset;

    // Mapping from asset ID to the property of the asset
    mapping(uint256 => string) private _property;

    // Mapping from asset ID to the history of the asset
    mapping(uint256 => string []) private _history;

    // Asset history structure
    struct AssetHistory {
        uint256 assetId;
        string history;
    }

    // The total history of the assets
    AssetHistory [] public totalHistory;

    // The array of the users
    mapping(address => bool) public users;

    // Mapping from asset ID to fractioned count
    mapping(uint256 => uint256) private _fractionedCount;

    // Mapping from asset ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _fractional_balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _fractional_operatorApprovals;

    event Mint(address indexed from, address indexed to, uint256 indexed assetId, string property);
    event AddHistory(address indexed caller, uint256 indexed assetId, string history);
    event AddUser(address user);
    event RemoveUser(address user);
    event MintFraction(address indexed owner, uint256 assetId, uint256 indexed fractionedCount);
    event BurnFraction(address indexed owner, uint256 assetId);
    event Transfer(address indexed from, address indexed to, uint256 indexed assetId, uint256 fractionCount);
    event Approve(address indexed owner, address indexed operator, bool indexed approved);

    /**
     * @dev See {_setURI}.
     */
    constructor(address _core_owner) {
        core_owner = _core_owner;
        users[_core_owner] = true;
    }

    function addHistory(uint256 assetId, string memory _oneHistory) external {
        require(users[_msgSender()], "Store: Only users can add history");
        require(assetId < countOfAsset, "Store: invalid asset id");
        AssetHistory memory newHistory = AssetHistory(assetId, _oneHistory);
        totalHistory.push(newHistory);
        _history[assetId].push(_oneHistory);
        emit AddHistory(_msgSender(), assetId, _oneHistory);
    }

    function addUser(address _user) external {
        require(_msgSender() == core_owner, "Store: Only core user can add users");
        users[_user] = true;
        emit AddUser(_user);
    }

    function removeUser(address _user) external {
        require(_msgSender() == core_owner, "Store: Only core user can remove users");
        users[_user] = false;
        emit RemoveUser(_user);
    }

    function getAssetHistory(uint256 assetId, uint256 id) public view returns(string memory){
        return _history[assetId][id];
    }

    function getAssetHistoryLength(uint256 assetId) public view returns(uint256){
        return _history[assetId].length;
    }

    function getTotalHistory(uint256 id) public view returns(AssetHistory memory){
        return totalHistory[id];
    }

    function getTotalHistoryLength() public view returns(uint256){
        return totalHistory.length;
    }

    function getProperty(uint256 assetId) public view returns(string memory){
        require(assetId < countOfAsset, "Store: invalid asset ID");
        return _property[assetId];
    }

    function mintAsset(address to, uint256 assetId, string memory property) external {
        require(to != address(0), "ERC721: mint to the zero address");
        require(assetId == countOfAsset, "Store: invalid asset ID");
        require(_msgSender() == core_owner, "Store: only core owner can create assets");
        countOfAsset += 1;
        _property[assetId] = property;
        _fractionedCount[assetId] = 1;
        _fractional_balances[assetId][to] = 1;

        emit Mint(address(0), to, assetId, property);
    }

    function getFractionedCount(uint256 assetId) public view returns(uint256){
        return _fractionedCount[assetId];
    }

    function getFranctionalBalances(uint256 assetId, address owner) public view returns(uint256){
        return _fractional_balances[assetId][owner];
    }

    function getFranctionalApprovals(address from, address to) public view returns(bool) {
        return _fractional_operatorApprovals[from][to];
    }

    function isApprovedOrOwner(address from, address to) public view returns(bool) {
        if(getFranctionalApprovals(to, from) || to == _msgSender())
            return true;
        return false;
    }

    function fractionAsset(uint256 assetId, uint256 fractionCount) external {
        require(getFractionedCount(assetId) == 1, "Fraction: the asset is already fractioned");
        require(getFranctionalBalances(assetId, _msgSender()) == 1, "Fraction: only owner can fraction the asset");
        _fractionedCount[assetId] = fractionCount;
        _fractional_balances[assetId][_msgSender()] = fractionCount;
        emit MintFraction(_msgSender(), assetId, fractionCount);
    }

    function burnAsset(uint256 assetId) external {
        require(getFractionedCount(assetId) == getFranctionalBalances(assetId, _msgSender()), "Fraction: the burner must have all asset franctions");
        _fractionedCount[assetId] = 1;
        _fractional_balances[assetId][_msgSender()] = 1;
        emit BurnFraction(_msgSender(), assetId);
    }

    function safeTransfer(address from, address to, uint256 assetId, uint256 fractionCount) public {
        require(isApprovedOrOwner(_msgSender(), from), "Fraction: the caller does not allowed to transfer asset fractions");
        require(fractionCount <= getFranctionalBalances(assetId, from), "Fraction: from do not have enough asset fractions");
        _fractional_balances[assetId][from] -= fractionCount;
        _fractional_balances[assetId][to] += fractionCount;
        emit Transfer(from, to, assetId, fractionCount);
    }

    function approve(address operator) public {
        _fractional_operatorApprovals[_msgSender()][operator] = true;
        emit Approve(_msgSender(), operator, true);
    }
}