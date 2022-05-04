/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    address public fuel = 0x0edb04e937E66D34e33f3DB7795B2C4413eC1798;
    address public avatar = 0x8A514A40eD06fc44B6E0C9875cDd58e20063d10e;
    address public shipBase = 0x2dE932AAF7C5b091AA36fBC75aF787B4aBd096Cf;
    address public shipDB = 0x76679fB89599682620D1D130B00216ac50E0F914;
    address public avatarReciept = 0x51016911D662Fe2f16b7274E68D7aebd31b77891;
    address public shipReciept = 0xE968BD0543228694B9bcB74bFe33467d5FE0C53E;
    IERC20 fl = IERC20(fuel);
    IshipBase sb = IshipBase(shipBase);
    IshipBase av = IshipBase(avatar);
    Ireciept sr = Ireciept(shipReciept);
    Ireciept ar = Ireciept(avatarReciept);
    IshipDB db = IshipDB(shipDB);

    uint256 public avatarDaily = 25;
    uint256 public class1Daily = 10;
    uint256 public class2Daily = 20;
    uint256 public class3Daily = 30;
    uint256 private stamp = 60 * 60 * 24;
    bool public emergencyClaim = false;
    bool public systemOn = true;

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
        require(systemOn == true);
        require(emergencyClaim == false);
        require(sb.ownerOf(ID) == msg.sender);
        sb.transferFrom(msg.sender, address(this), ID);
        pushShip(msg.sender, ID, block.timestamp);
        sr.mint(msg.sender, ID, 1);
    }

    function unstakeShip(uint256 ID) external {
        if(emergencyClaim == false){
        require(block.timestamp >= getShipTime(ID) + 5 days);
        }
        sr.burnFrom(msg.sender, ID, 1);
        sb.transferFrom(address(this), msg.sender, ID);
        fl.mint(msg.sender, calculateShipPay(ID) * 1e18);
        pushShip(0x0000000000000000000000000000000000000000, ID, 0);
    }

    function stakeAvatar(uint256 ID) external {
        require(systemOn == true);
        require(emergencyClaim == false);
        require(av.ownerOf(ID) == msg.sender);
        av.transferFrom(msg.sender, address(this), ID);
        pushAvatar(msg.sender, ID, block.timestamp);
        ar.mint(msg.sender, ID, 1);
    }

    function unstakeAvatar(uint256 ID) external {
        if(emergencyClaim == false){
        require(block.timestamp >= getAvTime(ID) + 5 days);
        }
        ar.burnFrom(msg.sender, ID, 1);
        av.transferFrom(address(this), msg.sender, ID);
        fl.mint(msg.sender, calculateAvatarPay(ID) * 1e18);
        pushAvatar(0x0000000000000000000000000000000000000000, ID, 0);
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

    function calculateShipPay(uint256 ID) public view returns(uint256 shipPay) {
        if (db.getClass(ID) == 1) {
            shipPay = (class1Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
        if (db.getClass(ID) == 2) {
            shipPay = (class2Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
        if (db.getClass(ID) == 3) {
            shipPay = (class3Daily * (block.timestamp - spaceships[ID].time)) / stamp;
        }
    }

    function calculateAvatarPay(uint256 ID) public view returns(uint256) {
        return (avatarDaily * (block.timestamp - avatars[ID].time)) / stamp;
    }

    function isShipStaked(uint256 ID) public view returns (bool shipIsStaked) {
        if(spaceships[ID].time == 0) {
            shipIsStaked = false;
        } else  {
            shipIsStaked = true;
        }
    }

    function isAvatarStaked(uint256 ID) public view returns (bool avatarIsStaked) {
        if(avatars[ID].time == 0) {
            avatarIsStaked = false;
        } else {
            avatarIsStaked = true;
        }
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

    function setEmerStatus(bool isEmer) external onlyOwner {
        emergencyClaim = isEmer;
    }

    function systemPower() external onlyOwner {
    if(systemOn == false){systemOn = true;}
    if(systemOn == true){systemOn = false;}
    }
}