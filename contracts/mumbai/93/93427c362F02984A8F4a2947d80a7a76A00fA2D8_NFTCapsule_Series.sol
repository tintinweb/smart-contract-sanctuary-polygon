pragma solidity ^0.8.4;

import './utils/INFTCapsule.sol';
import './security/Pausable.sol';

contract NFTCapsule_Series is Pausable, INFTCapsule {
    uint256 public override seriesId = 101; // 套圖編號
    uint256 public override picAmount = 200; // 圖片數量
    uint256 public override fragmentAmount = 50; // 碎片數量
    uint256 public override maxFragmentAmount = 10; // 每個碎片的發行量

    uint256 maxSupply = 100000; // picAmount * fragmentAmount * maxFragmentAmount = 100,000
    uint256 maxSupplyPicAmount = 500; // 每個圖片的碎片總數量 fragmentAmount * maxFragmentAmount = 500

    uint256 totalSupply; // 已鑄造數量
    uint256 price = 20000000000000000000; // 售價
    uint256 startTime = 0;
    uint256 endTime = 2000000000;

    mapping(uint256 => uint256) public fragmentMintAmount; // 紀錄每個 tokenId 的鑄造數量
    mapping(uint256 => uint256) public picMintAmount; // 紀錄每個圖片的發行量 picMintAmount[picId] = 0...500
    uint256 counter = 1; // 用於產生隨機數

    address NFTCore;

    constructor(address _address) {
        NFTCore = _address;
    }

    function setSeries(uint256 _seriesId) external onlyAdmin {
        seriesId = _seriesId;
    }

    function setTime(uint256 _startTime, uint256 _endTime) external onlyAdmin {
        startTime = _startTime;
        endTime = _endTime;
    }

    ///@dev if the price is 1 matic, _price should be 1e18
    ///@param _price price unit is wei
    function setPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function setPicAmount(uint256 _picAmount) external onlyAdmin {
        picAmount = _picAmount;
    }

    function getTotalSupply() external view override returns (uint256 _totalSupply) {
        _totalSupply = totalSupply;
    }

    function getSeries() external view returns (uint256 _seriesId) {
        _seriesId = seriesId;
    }

    function getPrice() external view override returns (uint256 _price) {
        _price = price;
    }

    function getTime() external view returns (uint256 _startTime, uint256 _endTime) {
        _startTime = startTime;
        _endTime = endTime;
    }

    // 組成 tokenId (101,000001,000001 ~ 101,000200,000500
    function _buildTokenId(uint256 picId, uint256 fragmentId) public view returns (uint256) {
        return (seriesId * 1e12) + (picId * 1e6) + fragmentId;
    }

    function getTokenId() external override whenNotPaused returns (uint256 tokenId) {
        require(block.timestamp >= startTime, 'Wrong Time: Too early');
        require(block.timestamp <= endTime, 'Wrong Time: Too late');
        require(totalSupply < maxSupply, 'Not have enough token to mint');
        require(msg.sender == NFTCore, NO_PERMISSION);

        // 取得隨機編號
        uint256 picId = (uint256(sha256(abi.encodePacked(uint160(msg.sender) + block.timestamp + counter))) % picAmount) + 1;
        uint256 fragmentId = (uint256(sha256(abi.encodePacked(uint160(msg.sender) + block.timestamp))) % fragmentAmount) + 1;

        // 若 pic 已售出 500 張碎片，則表示該 pic 編號下的 fragmentId 1~50 皆已售完，故直接換圖 (picId), 可省去遍歷 fragmentId 的步驟
        // 該步驟重複的最大值為 (200 - 1) 次
        while (picMintAmount[picId] >= maxSupplyPicAmount) {
            // 若 picId 編號已到達最大值 200, 則從 1 開始
            if (picId >= picAmount) {
                picId = 1;
            } else {
                picId++;
            }
        }
        tokenId = _buildTokenId(picId, fragmentId);
        // 若 tokenId 已售出 10 張, 則更換碎片 (fragmentId), 該步驟重複的最大值為 (50 - 1) 次
        while (fragmentMintAmount[tokenId] >= maxFragmentAmount) {
            if (fragmentId >= fragmentAmount) {
                fragmentId = 1;
            } else {
                fragmentId++;
            }
            tokenId = _buildTokenId(picId, fragmentId);
        }

        picMintAmount[picId]++;
        fragmentMintAmount[tokenId]++;
        totalSupply++;
        counter++;
        return tokenId;
    }
}

pragma solidity >=0.8.0 <0.9.0;

interface INFTCapsule {
    function seriesId() external view returns (uint256 seriesId);

    function picAmount() external view returns (uint256 picAmount);

    function fragmentAmount() external view returns (uint256 fragmentAmount);

    function maxFragmentAmount() external view returns (uint256 maxFragmentAmount);

    function getPrice() external view returns (uint256 price);

    function getTotalSupply() external view returns (uint256 totalSupply);

    function getTokenId() external returns (uint256 tokenId);
}

pragma solidity >=0.8.0 <0.9.0;

import './AccessControl.sol';

contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}