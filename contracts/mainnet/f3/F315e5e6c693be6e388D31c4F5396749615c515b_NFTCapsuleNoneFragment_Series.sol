/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// File: security/AccessControl.sol

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
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


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
// File: utils/INFTCapsuleNoneFragment.sol

pragma solidity >=0.8.0 <0.9.0;

interface INFTCapsuleNoneFragment {
    function seriesId() external view returns (uint256 seriesId);

    function picAmount() external view returns (uint256 picAmount);

    function fragmentAmount() external view returns (uint256 fragmentAmount);

    function maxFragmentAmount() external view returns (uint256 maxFragmentAmount);

    function setMaxSupply(uint256 _maxSupply) external;

    function getPrice() external view returns (uint256 price);

    function getTotalSupply() external view returns (uint256 totalSupply);

    function getTokenId() external returns (uint256 tokenId);

    function getTime() external view returns (uint256 _startTime, uint256 _endTime);
}

// File: NFTCapsuleNoneFragment.sol

pragma solidity ^0.8.4;



contract NFTCapsuleNoneFragment_Series is Pausable, INFTCapsuleNoneFragment {
    uint256 public override seriesId = 102; // 套圖編號
    uint256 public override picAmount = 0;
    uint256 public override fragmentAmount = 0;
    uint256 public override maxFragmentAmount = 0;

    uint256 tokenId = 102000000000000;
    uint256 public totalSupply; // 已鑄造數量
    uint256 public maxSupply = 5000;

    uint256 price = 1000000000000000000; // 售價 1 matic
    uint256 startTime = 0;
    uint256 endTime = 2000000000;

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

    function setMaxSupply(uint256 _maxSupply) external override onlyAdmin {
        maxSupply = _maxSupply;
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

    function getTime() external view override returns (uint256 _startTime, uint256 _endTime) {
        _startTime = startTime;
        _endTime = endTime;
    }

    function getTokenId() external override whenNotPaused returns (uint256 _tokenId) {
        require(block.timestamp >= startTime, "Wrong Time: Too early");
        require(block.timestamp <= endTime, "Wrong Time: Too late");
        require(totalSupply < maxSupply, "Not have enough token to mint");
        require(msg.sender == NFTCore, NO_PERMISSION);

        tokenId += 1e6;
        totalSupply++;
        return tokenId;
    }
}