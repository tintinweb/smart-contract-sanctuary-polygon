/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8 .12;

interface IERC20 {
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns(bool);

    function allowance(address owner, address spender)
    external
    view
    returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function burnFrom(address user, uint256 amount) external;

    function mint(address user, uint256 amount) external;
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface Ireciept is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns(uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns(uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns(bool);

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

    function mint(address _to, uint _id, uint _amount) external;

    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external;

    function burn(uint _id, uint _amount) external;

    function burnFrom(address user, uint _id, uint _amount) external;

    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external;

    function burnFromBatch(address user, uint[] memory _ids, uint[] memory _amounts) external;

    function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external;

    function setURI(uint _id, string memory _uri) external;
}

interface IshipBase is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);

    function ownerOf(uint256 tokenId) external view returns(address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns(address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mint(
        address _to,
        string memory tokenURI_
    ) external;

    function burn(uint256 ID) external;

    function postSetTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IshipDB {
    function pushSpeed(uint256 shipnum, uint256 newSpeed) external;

    function pushStrength(uint256 shipnum, uint256 newStrength) external;

    function pushAttack(uint256 shipnum, uint256 newAttack) external;

    function pushID(uint256 shipnum) external;

    function pushFuel(uint256 shipnum, uint256 newFuel) external;

    function pushClass(uint256 shipnum, uint256 newClass) external;

    function pushAll(uint256 shipnum, uint256 newSpeed, uint256 newStrength, uint256 newAttack, uint256 newFuel, uint256 newClass) external;

    function getSpeed(uint256 shipnum) external view returns(uint256);

    function getStrength(uint256 shipnum) external view returns(uint256);

    function getAttack(uint256 shipnum) external view returns(uint256);

    function getID(uint256 shipnum) external view returns(uint256);

    function getFuel(uint256 shipnum) external view returns(uint256);

    function getClass(uint256 shipnum) external view returns(uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NFTstaking is Ownable {


    address public fuel = 0xb54382325bBe0109BE150190C51C2801EaCf0ACd;
    address public avatar = 0xBb45f950fc8Ed38b92b5D673b7f459958d8be7Dc;
    address public shipBase = 0x1f7CD6deB3726A76B51a24ddBA193Df0d27e5BD7;
    address public shipDB = 0xa365F7Fe150a7f1a6B50f983f048bFD3519CaD61;
    address public avatarReciept = 0x222F7Ee2Ebf3b7200ABAfda1aBEcb847B31cD82b;
    address public shipReciept = 0x29242958Cc4D5059Bb5Fa3293887C97d64148e60;

    uint256 public avatarDaily = 25;
    uint256 public class1Daily = 10;
    uint256 public class2Daily = 20;
    uint256 public class3Daily = 30;
    uint256 private stamp = 60 * 60 * 24;

    struct Spaceship {
        address staker;
        uint256 id;
        uint256 time;
    }
    mapping(uint256 => Spaceship) spaceships;

    struct Avatar {
        address staker;
        uint256 id;
        uint256 time;
    }
    mapping(uint256 => Avatar) avatars;

    function stakeShip(uint256 ID) external {
        IshipBase sb = IshipBase(shipBase);
        Ireciept sr = Ireciept(shipReciept);
        require(sb.ownerOf(ID) == msg.sender);
        sb.transferFrom(msg.sender, address(this), ID);
        pushShip(msg.sender, ID, block.timestamp);
        sr.mint(msg.sender, ID, 1);
    }

    function unstakeShip(uint256 ID) external {
        IshipBase sb = IshipBase(shipBase);
        Ireciept sr = Ireciept(shipReciept);
        IERC20 fl = IERC20(fuel);
        require(block.timestamp >= getShipTime(ID) + 7 days);
        sr.burnFrom(msg.sender, ID, 1);
        pushShip(0x0000000000000000000000000000000000000000, ID, 0);
        sb.transferFrom(address(this), msg.sender, ID);
        fl.mint(msg.sender, calculateShipPay(ID));
    }

    function stakeAvatar(uint256 ID) external {
        IshipBase av = IshipBase(avatar);
        Ireciept ar = Ireciept(avatarReciept);
        require(av.ownerOf(ID) == msg.sender);
        av.transferFrom(msg.sender, address(this), ID);
        pushAvatar(msg.sender, ID, block.timestamp);
        ar.mint(msg.sender, ID, 1);
    }

    function unstakeAvatar(uint256 ID) external {
        IshipBase av = IshipBase(avatar);
        Ireciept ar = Ireciept(avatarReciept);
        IERC20 fl = IERC20(fuel);
        require(block.timestamp >= getAvTime(ID) + 7 days);
        ar.burnFrom(msg.sender, ID, 1);
        pushAvatar(0x0000000000000000000000000000000000000000, ID, 0);
        av.transferFrom(address(this), msg.sender, ID);
        fl.mint(msg.sender, calculateAvatarPay(ID));
    }

    function pushAvatar(address setstaker, uint256 setID, uint256 settime) internal {
        avatars[setID].staker = setstaker;
        avatars[setID].id = setID;
        avatars[setID].time = settime;
    }

    function pushShip(address setstaker, uint256 setID, uint256 settime) internal {
        spaceships[setID].staker = setstaker;
        spaceships[setID].id = setID;
        spaceships[setID].time = settime;
    }

    function calculateShipPay(uint256 ID) public view returns(uint256 calculatedShip) {
        IshipDB db = IshipDB(shipDB);
        if (db.getClass(ID) == 1) {
            return (class1Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
        if (db.getClass(ID) == 2) {
            return (class2Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
        if (db.getClass(ID) == 3) {
            return (class3Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
    }

    function calculateAvatarPay(uint256 ID) public view returns(uint256) {
        return (avatarDaily * (block.timestamp - avatars[ID].time)) / stamp;
    }

    function getShipTime(uint256 ID) internal view returns(uint256) {
        return spaceships[ID].time;
    }

    function getAvTime(uint256 ID) internal view returns(uint256) {
        return avatars[ID].time;
    }

    function setFuelAddr(address newFuel) external onlyOwner {
        fuel = newFuel;
    }

    function setAvAddr(address newAv) external onlyOwner {
        avatar = newAv;
    }

    function setShipBase(address newBase) external onlyOwner {
        shipBase = newBase;
    }

    function setDB(address newDB) external onlyOwner {
        shipDB = newDB;
    }

    function setAvRec(address newAvRec) external onlyOwner {
        avatarReciept = newAvRec;
    }

    function setShipRec(address newShipRec) external onlyOwner {
        shipReciept = newShipRec;
    }

    function setAvPay(uint256 value) external onlyOwner {
        avatarDaily = value;
    }

    function setC1Pay(uint256 value) external onlyOwner {
        class1Daily = value;
    }

    function setC2Pay(uint256 value) external onlyOwner {
        class2Daily = value;
    }

    function setC3Pay(uint256 value) external onlyOwner {
        class3Daily = value;
    }
}