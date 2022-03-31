/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

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

interface IliquidRNG {
    function random1(uint256 mod, uint256 demod) external view returns(uint256);

    function random2(uint256 mod, uint256 demod) external view returns(uint256);

    function random3(uint256 mod, uint256 demod) external view returns(uint256);

    function random4(uint256 mod, uint256 demod) external view returns(uint256);

    function random5(uint256 mod, uint256 demod) external view returns(uint256);

    function random6() external view returns(uint256);

    function random7() external view returns(uint256);

    function random8() external view returns(uint256);

    function random9() external view returns(uint256);

    function random10() external view returns(uint256);

    function randomFull() external view returns(uint256);

    function requestMixup() external;
}

interface IshipDB {
    function pushSpeed(uint256 shipnum, uint256 newSpeed) external;

    function pushStrength(uint256 shipnum, uint256 newStrength) external;

    function pushAttack(uint256 shipnum, uint256 newAttack) external;

    function pushID(uint256 shipnum) external;

    function pushFuel(uint256 shipnum, uint256 newFuel) external;

    function pushAll(uint256 newSpeed, uint256 newStrength, uint256 newAttack, uint256 shipnum, uint256 newFuel, uint256 newClass) external;

    function getSpeed(uint256 shipnum) external view returns(uint256);

    function getStrength(uint256 shipnum) external view returns(uint256);

    function getAttack(uint256 shipnum) external view returns(uint256);

    function getID(uint256 shipnum) external view returns(uint256);

    function getFuel(uint256 shipnum) external view returns(uint256);
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns(bool);
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

    function totalSupply() external view returns (uint256);
}

interface Iitems is IERC165 {

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

contract ShipBuilding is Ownable {

    struct Timelock {
        uint256 id;
        uint256 time;
    }
    mapping(uint256 => Timelock) timeMark;

   string private XylakUri1 = "xylak-class-one";
    string private XylakUri2 = "xylak-class-two";
    string private XylakUri3 = "xylak-class-three";
    string private LlithanonUri1 = "ilithanon-class-one";
    string private LlithanonUri2 = "ilithanon-class-two";
    string private LlithanonUri3 = "ilithanon-class-three";
    string private MaonodUri1 = "maonod-class-one";
    string private MaonodUri2 = "maonod-class-two";
    string private MaonodUri3 = "maonod-class-three";
    string private RumidianUri1 = "rumidian-class-one";
    string private RumidianUri2 = "rumidian-class-two";
    string private RumidianUri3 = "rumidian-class-three";
    string private CarlithianUri1 = "carlithian-class-one";
    string private CarlithianUri2 = "carlithian-class-two";
    string private CarlithianUri3 = "carlithian-class-three";
    string private AdaliosUri1 = "adalios-class-one";
    string private AdaliosUri2 = "adalios-class-two";
    string private AdaliosUri3 = "adalios-class-three";

    address public fuel = 0xb54382325bBe0109BE150190C51C2801EaCf0ACd;
    address public ice = 0xbe607E15EB5ddBacA3354F076822B74095cD71ff;
    address public item = 0x0f1D7ad15D00cC988e9F754B87D9F8A55f67282D;
    address public shipDB = 0xB31a865129b5E2Beb44a926680AfcFd4fb439f81;
    address public shipBase = 0xccEb710D7BE276b17Ec65d5693C0eBDEa92E111B;
    address public liquidRNG = 0xed5ee5f4028B2D34051D5E20F1c2aD8338D3a1BD;
    address public avatars = 0xBb45f950fc8Ed38b92b5D673b7f459958d8be7Dc;
    address public iceWallet = 0xff594fEC9B78E9bD17808E02B354a09DfFF74C24;

    uint256 public class1Cost = 1500;
    uint256 public class2Cost = 2100;
    uint256 public class3Cost = 2800;
    uint256 public icePrice = 100;

    bool public paused = false;

    //MINT AND UPGRADE SHIPS

    function buildClass1(uint256 avID) external {
        IERC20 fl = IERC20(fuel);
        IERC20 ic = IERC20(ice);
        Iitems items = Iitems(item);
        IshipBase sb = IshipBase(shipBase);
        IshipBase av = IshipBase(avatars);
        IliquidRNG rng = IliquidRNG(liquidRNG);
        require(paused == false);
        if(msg.sender != owner()){
        require(av.ownerOf(avID) == msg.sender);
        if(sb.balanceOf(msg.sender) > 0){
        if (getTime(avID) != 0) {
            require(block.timestamp >= getTime(avID) + 30 days);
        }
        }
        fl.burnFrom(msg.sender, class1Cost * 1e18);
        ic.transferFrom(msg.sender, iceWallet, icePrice * 1e18);
        items.burnFrom(msg.sender, 1, 1);
        }
        rng.requestMixup();
        uint256 randomShip = rng.random5(100, 1);
        if (randomShip >= 60 && randomShip <= 78) {
            sb.mint(msg.sender, XylakUri1);
        }
        if (randomShip >= 12 && randomShip <= 23) {
            sb.mint(msg.sender, LlithanonUri1);
        }
        if (randomShip >= 41 && randomShip <= 59) {
            sb.mint(msg.sender, MaonodUri1);
        }
        if (randomShip >= 24 && randomShip <= 40) {
            sb.mint(msg.sender, RumidianUri1);
        }
        if (randomShip <= 11) {
            sb.mint(msg.sender, CarlithianUri1);
        }
        if (randomShip >= 79 && randomShip <= 100) {
            sb.mint(msg.sender, AdaliosUri1);
        }
        pushTimelock(avID, block.timestamp);
        setClass1Stat(randomShip);
    }

    function buildClass2(uint256 ID, uint256 avID) external {
        IERC20 fl = IERC20(fuel);
        IERC20 ic = IERC20(ice);
        Iitems items = Iitems(item);
        IshipBase sb = IshipBase(shipBase);
        IshipBase av = IshipBase(avatars);
        require(paused == false);
        require(sb.ownerOf(ID) == msg.sender);
        require(av.ownerOf(avID) == msg.sender);
        if(msg.sender != owner()){
        require(block.timestamp >= getTime(avID) + 30 days);
        fl.burnFrom(msg.sender, class2Cost * 1e18);
        ic.transferFrom(msg.sender, iceWallet, icePrice * 1e18);
        items.burnFrom(msg.sender, 1, 3);
        }
        if (compare(sb.tokenURI(ID), XylakUri1) == true) {
            sb.postSetTokenURI(ID, XylakUri2);
        }
        if (compare(sb.tokenURI(ID), LlithanonUri1) == true) {
            sb.postSetTokenURI(ID, LlithanonUri2);
        }
        if (compare(sb.tokenURI(ID), MaonodUri1) == true) {
            sb.postSetTokenURI(ID, MaonodUri2);
        }
        if (compare(sb.tokenURI(ID), RumidianUri1) == true) {
            sb.postSetTokenURI(ID, RumidianUri2);
        }
        if (compare(sb.tokenURI(ID), CarlithianUri1) == true) {
            sb.postSetTokenURI(ID, CarlithianUri2);
        }
        if (compare(sb.tokenURI(ID), AdaliosUri1) == true) {
            sb.postSetTokenURI(ID, AdaliosUri2);
        }
        pushTimelock(avID, block.timestamp);
        setClass2Stat(ID);
    }

    function buildClass3(uint256 ID, uint256 avID) external {
        IERC20 fl = IERC20(fuel);
        IERC20 ic = IERC20(ice);
        Iitems items = Iitems(item);
        IshipBase sb = IshipBase(shipBase);
        IshipBase av = IshipBase(avatars);
        require(paused == false);
        require(sb.ownerOf(ID) == msg.sender);
        require(av.ownerOf(avID) == msg.sender);
        if(msg.sender != owner()){
        require(block.timestamp >= getTime(avID) + 30 days);
        fl.burnFrom(msg.sender, class3Cost * 1e18);
        ic.transferFrom(msg.sender, iceWallet, icePrice * 1e18);
        items.burnFrom(msg.sender, 1, 6);
        }
        if (compare(sb.tokenURI(ID), XylakUri2) == true) {
            sb.postSetTokenURI(ID, XylakUri3);
        }
        if (compare(sb.tokenURI(ID), LlithanonUri2) == true) {
            sb.postSetTokenURI(ID, LlithanonUri3);
        }
        if (compare(sb.tokenURI(ID), MaonodUri2) == true) {
            sb.postSetTokenURI(ID, MaonodUri3);
        }
        if (compare(sb.tokenURI(ID), RumidianUri2) == true) {
            sb.postSetTokenURI(ID, RumidianUri3);
        }
        if (compare(sb.tokenURI(ID), CarlithianUri2) == true) {
            sb.postSetTokenURI(ID, CarlithianUri3);
        }
        if (compare(sb.tokenURI(ID), AdaliosUri2) == true) {
            sb.postSetTokenURI(ID, AdaliosUri3);
        }
        pushTimelock(avID, block.timestamp);
        setClass3Stat(ID);
    }
    //PUSH STATS TO DB
    function setClass1Stat(uint256 species) internal {
        IshipDB db = IshipDB(shipDB);
        IshipBase bs = IshipBase(shipBase);
        IliquidRNG rng = IliquidRNG(liquidRNG);
        if (species == 1) {
            db.pushAll(rng.random1(25, 10), rng.random2(25, 30), rng.random3(25, 10), bs.totalSupply(), rng.random4(25, 20), 1);
        }
        if (species == 2) {
            db.pushAll(rng.random1(25, 10), rng.random2(25, 35), rng.random3(25, 25), bs.totalSupply(), rng.random4(25, 30), 1);
        }
        if (species == 3) {
            db.pushAll(rng.random1(25, 25), rng.random2(25, 10), rng.random3(30, 40), bs.totalSupply(), rng.random4(25, 20), 1);
        }
        if (species == 4) {
            db.pushAll(rng.random1(25, 15), rng.random2(25, 20), rng.random3(25, 30), bs.totalSupply(), rng.random4(25, 25), 1);
        }
        if (species == 5) {
            db.pushAll(rng.random1(25, 20), rng.random2(25, 20), rng.random3(25, 35), bs.totalSupply(), rng.random4(25, 35), 1);
        }
        if (species == 6) {
            db.pushAll(rng.random1(25, 10), rng.random2(25, 25), rng.random3(25, 15), bs.totalSupply(), rng.random4(25, 10), 1);
        }
    }

    function setClass2Stat(uint256 ID) internal {
        IshipDB db = IshipDB(shipDB);
        IshipBase sb = IshipBase(shipBase);
        IliquidRNG rng = IliquidRNG(liquidRNG);
        rng.requestMixup();
        if (compare(sb.tokenURI(ID), XylakUri2) == true) {
            db.pushAll(rng.random1(25, 50), rng.random2(25, 30), rng.random3(25, 40), ID, rng.random4(25, 30), 2);
        }
        if (compare(sb.tokenURI(ID), LlithanonUri2) == true) {
            db.pushAll(rng.random1(25, 30), rng.random2(25, 55), rng.random3(25, 45), ID, rng.random4(25, 50), 2);
        }
        if (compare(sb.tokenURI(ID), MaonodUri2) == true) {
            db.pushAll(rng.random1(25, 45), rng.random2(25, 30), rng.random3(20, 60), ID, rng.random4(25, 40), 2);
        }
        if (compare(sb.tokenURI(ID), RumidianUri2) == true) {
            db.pushAll(rng.random2(25, 40), rng.random2(25, 40), rng.random3(25, 50), ID, rng.random4(25, 45), 2);
        }
        if (compare(sb.tokenURI(ID), CarlithianUri2) == true) {
            db.pushAll(rng.random1(25, 40), rng.random2(25, 40), rng.random3(25, 55), ID, rng.random4(25, 55), 2);
        }
        if (compare(sb.tokenURI(ID), AdaliosUri2) == true) {
            db.pushAll(rng.random1(25, 30), rng.random2(25, 45), rng.random3(25, 35), ID, rng.random4(25, 30), 2);
        }
    }

    function setClass3Stat(uint256 ID) internal {
        IshipDB db = IshipDB(shipDB);
        IshipBase sb = IshipBase(shipBase);
        IliquidRNG rng = IliquidRNG(liquidRNG);
        rng.requestMixup();
        if (compare(sb.tokenURI(ID), XylakUri3) == true) {
            db.pushAll(rng.random1(25, 50), rng.random2(25, 30), rng.random3(25, 40), ID, rng.random4(25, 30), 3);
        }
        if (compare(sb.tokenURI(ID), LlithanonUri3) == true) {
            db.pushAll(rng.random1(25, 50), rng.random2(25, 75), rng.random3(25, 65), ID, rng.random4(25, 70), 3);
        }
        if (compare(sb.tokenURI(ID), MaonodUri3) == true) {
            db.pushAll(rng.random1(25, 65), rng.random2(25, 50), rng.random3(20, 70), ID, rng.random4(25, 60), 3);
        }
        if (compare(sb.tokenURI(ID), RumidianUri3) == true) {
            db.pushAll(rng.random1(25, 55), rng.random2(25, 60), rng.random3(25, 70), ID, rng.random4(25, 65), 3);
        }
        if (compare(sb.tokenURI(ID), CarlithianUri3) == true) {
            db.pushAll(rng.random1(25, 60), rng.random2(25, 60), rng.random3(25, 75), ID, rng.random4(25, 75), 3);
        }
        if (compare(sb.tokenURI(ID), AdaliosUri3) == true) {
            db.pushAll(rng.random1(25, 50), rng.random2(25, 65), rng.random3(25, 55), ID, rng.random4(25, 50), 3);
        }
    }
    //HELPERS
    function compare(string memory a, string memory b) internal pure returns(bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function pushTimelock(uint256 newid, uint256 newtime) internal {
        timeMark[newid].id = newid;
        timeMark[newid].time = newtime;
    }

    function getTime(uint256 avID) internal view returns(uint256) {
        return timeMark[avID].time;
    }
    function timeRemaining(uint256 avID) external view returns(uint256) {
        return (timeMark[avID].time + 30 days) - block.timestamp;
    }
    //ADMIN
    function chgFuelAddr(address newFuel) external onlyOwner {
        fuel = newFuel;
    }

    function chgIceAddr(address newIce) external onlyOwner {
        ice = newIce;
    }

    function chgItemAddr(address newItem) external onlyOwner {
        item = newItem;
    }

    function chgShipDbAddr(address newDB) external onlyOwner {
        shipDB = newDB;
    }

    function chgShipBaseAddr(address newShipBase) external onlyOwner {
        shipBase = newShipBase;
    }

    function chgRngAddr(address newRNG) external onlyOwner {
        liquidRNG = newRNG;
    }

    function setIceWallet(address newWallet) external onlyOwner {
        iceWallet = newWallet;
    }

    function setIcePrice(uint256 newPrice) external onlyOwner {
        icePrice = newPrice;
    }

    function setClassCosts(uint256 class1, uint256 class2, uint256 class3) external onlyOwner {
        class1Cost = class1;
        class2Cost = class2;
        class3Cost = class3;
    }

    function playPause(bool status) external onlyOwner {
        paused = status;
    }
}