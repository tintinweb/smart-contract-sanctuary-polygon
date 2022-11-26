/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SOLO1155 {

  function mint(address _to, uint _id, uint _amount) external;

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external;

  function burn(address account,uint _id, uint _amount) external;

  function burnBatch(address account, uint[] memory _ids, uint[] memory _amounts) external;

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external;

  function setURI(uint _id, string memory _uri) external;

  function uri(uint _id) external view returns (string memory);

  function totalSupply(uint256 id) external view returns (uint256);

  function exists(uint256 id) external view returns (bool);

  function balanceOf(address account, uint256 id) external view returns (uint256);

}

interface SOLOOCDB {

    function setID(address u, uint256 id) external;

    function setDate(address u, uint256 time) external;

    function setEnable(address u, bool tOrF) external;

    function getID(address u) external view returns(uint256);

    function getDate(address u) external view returns(uint256);

    function getEnable(address u) external view returns(bool);
}

abstract contract MjolnirRBAC {
    mapping(address => bool) internal _thors;

    modifier onlyThor() {
        require(
            _thors[msg.sender] == true || address(this) == msg.sender,
            "Caller cannot wield Mjolnir"
        );
        _;
    }

    function addThor(address _thor)
        public
        onlyOwner
    {
        _thors[_thor] = true;
    }

    function delThor(address _thor)
        external
        onlyOwner
    {
        delete _thors[_thor];
    }

    function disableThor(address _thor)
        external
        onlyOwner
    {
        _thors[_thor] = false;
    }

    function isThor(address _address)
        public
        view
        returns (bool allowed)
    {
        allowed = _thors[_address];
    }

    function toAsgard() external onlyThor {
        delete _thors[msg.sender];
    }
    //Oracle-Role
    mapping(address => bool) internal _oracles;

    modifier onlyOracle() {
        require(
            _oracles[msg.sender] == true || address(this) == msg.sender,
            "Caller is not the Oracle"
        );
        _;
    }

    function addOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = true;
    }

    function delOracle(address _oracle)
        external
        onlyOwner
    {
        delete _oracles[_oracle];
    }

    function disableOracle(address _oracle)
        external
        onlyOwner
    {
        _oracles[_oracle] = false;
    }

    function isOracle(address _address)
        external
        view
        returns (bool allowed)
    {
        allowed = _oracles[_address];
    }

    function relinquishOracle() external onlyOracle {
        delete _oracles[msg.sender];
    }
    //Ownable-Compatability
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    //contextCompatability
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract soloDistv1 is MjolnirRBAC {

    address public baseSFT = 0x93E074B2C798D7Db1AB1c489DAF9ece9Ca3Ad68c;
    address public ocDB = 0xAb85fbeE86454F4b3Ee6b04bF1A9b9E6dD29cEaA;
    SOLO1155 bs = SOLO1155(baseSFT);
    SOLOOCDB db = SOLOOCDB(ocDB);
    uint256 public regNonce = 0;
    bool public isOperable = true;

    function registerUser() external {
    require(isOperable == true, "System Powered Off!");
    require(db.getEnable(msg.sender) != true, "User Already Active!");
    require(db.getDate(msg.sender) == 0, "User Has Been Disabled!");
    if (regNonce != 0){
        require(db.getID(msg.sender) == 0, "Token Already Bound!");
    }
    bs.mint(msg.sender,regNonce,1);
    db.setID(msg.sender,regNonce);
    db.setDate(msg.sender,block.timestamp);
    db.setEnable(msg.sender,true);
    regNonce++;
    }

    function setBase(address sft) external onlyThor {
        baseSFT = sft;
    }

    function setDB(address ocdb) external onlyThor {
        ocDB = ocdb;
    }

    function fixNonce(uint256 newNonce) external onlyThor {
        regNonce = newNonce;
    }

    function systemPowerOn(bool tOrF) external onlyThor {
        isOperable = tOrF;
    }

}