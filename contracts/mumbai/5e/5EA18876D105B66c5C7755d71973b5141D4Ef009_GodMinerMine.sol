/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IGOMTOKEN is IERC20{
    function mint(address account, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IGodMiner is IERC721 {
    function existed(uint256 tokenId) external view returns (bool);
    function minerStamina(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function staminaOfOwner(address owner) external view returns (uint256);
}

contract GodMinerMine is Ownable {
    using SafeMath for uint256;

    IGOMTOKEN  public tokenContract;
    IGodMiner public minerContract;

    uint256 public startTime;
    uint256 public period = 1 days;
    uint256 public outputPerStamina = 10**18;
    uint256 public validPeriodCount = 7;

    uint256 public totalMineAmount; //Asset that have been claimed

    mapping (uint256 => uint256) public mineAmount;
    mapping (uint256 => uint256) public mineLastTime;

    event  MineByTokenID(address indexed user, uint256 indexed tokenID, uint256 mineAmount, uint256 mineTime);
    event  Mine(address indexed user, uint256 mineAmount, uint256 mineTime);

    constructor(IGOMTOKEN _tokenContract, IGodMiner _minerContract, uint256 _startTime) {
        tokenContract = _tokenContract;
        minerContract = _minerContract;
        startTime = _startTime;
    }

    function transferETH(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(owner(), value);
    }

    function transferOtherAsset(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, owner(), value);
    }

    function setTime(uint256 _startTime) public onlyOwner() {
        startTime = _startTime;
    }

    function setPeriod(uint256 _period) public onlyOwner() {
        period = _period;
    }

    function setOutputPerStamina(uint256 _outputPerStamina) public onlyOwner() {
        outputPerStamina = _outputPerStamina;
    }

    function setValidPeriodCount(uint256 _validPeriodCount) public onlyOwner() {
        validPeriodCount = _validPeriodCount;
    }

    function setContract(IGOMTOKEN _tokenContract, IGodMiner _minerContract) public onlyOwner() {
        tokenContract = _tokenContract;
        minerContract = _minerContract;
    }

    function mineByTokenID(uint256 tokenId) public {
        require(minerContract.existed(tokenId), "This miner NFT is not existed.");
        address _NFT_Owner = minerContract.ownerOf(tokenId);
        require(_NFT_Owner == msg.sender, "Only NFT owner can claim the bonus");
        //require(_NFT_Owner != address(0), "NFT owner query for nonexistent token");

        uint256 baseTime = startTime;
        if (baseTime < mineLastTime[tokenId]) baseTime = mineLastTime[tokenId];

        uint256 nowTime = block.timestamp;
        require(baseTime < nowTime, "Mining is not start.");

        uint256 workTime = nowTime.sub(baseTime);
        if (workTime > period.mul(validPeriodCount)) workTime = period.mul(validPeriodCount);

        uint256 clacStamina = minerContract.minerStamina(tokenId);

        uint256 mineCalcAmount = clacStamina.mul(outputPerStamina).mul(workTime).div(period);

        mineLastTime[tokenId] = nowTime;
        mineAmount[tokenId] = mineAmount[tokenId].add(mineCalcAmount);
        totalMineAmount = totalMineAmount.add(mineCalcAmount);
        tokenContract.mint(msg.sender, mineCalcAmount);

        emit MineByTokenID(msg.sender, tokenId, mineCalcAmount, nowTime);
    }

    function clacMineAmountByTokenID(uint256 tokenId) public view returns (uint256) {
        if (!minerContract.existed(tokenId)) return 0;

        uint256 baseTime = startTime;
        if (baseTime < mineLastTime[tokenId]) baseTime = mineLastTime[tokenId];

        uint256 nowTime = block.timestamp;
        require(baseTime < nowTime, "Mining is not start.");

        uint256 workTime = nowTime.sub(baseTime);
        if (workTime > period.mul(validPeriodCount)) workTime = period.mul(validPeriodCount);

        uint256 clacStamina = minerContract.minerStamina(tokenId);

        uint256 mineCalcAmount = clacStamina.mul(outputPerStamina).mul(workTime).div(period);
        return mineCalcAmount;
    }

    function mine() public {
        uint256 _count = minerContract.balanceOf(msg.sender);
        require(_count > 0, "No NFT");

        uint256 baseTime = startTime;
        uint256 nowTime = block.timestamp;
        require(baseTime < nowTime, "Mining is not start.");

        uint256 totalCalcAmount;
        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = minerContract.tokenOfOwnerByIndex(msg.sender, i);
            if (baseTime < mineLastTime[tokenId]) baseTime = mineLastTime[tokenId];
            uint256 workTime = nowTime.sub(baseTime);
            if (workTime > period.mul(validPeriodCount)) workTime = period.mul(validPeriodCount);
            uint256 clacStamina = minerContract.minerStamina(tokenId);
            uint256 mineCalcAmount = clacStamina.mul(outputPerStamina).mul(workTime).div(period);

            mineLastTime[tokenId] = nowTime;
            mineAmount[tokenId] = mineAmount[tokenId].add(mineCalcAmount);
            totalCalcAmount = totalCalcAmount.add(mineCalcAmount);
        }

        totalMineAmount = totalMineAmount.add(totalCalcAmount);
        tokenContract.mint(msg.sender, totalCalcAmount);

        emit Mine(msg.sender, totalCalcAmount, nowTime);
    }

    function clacMineAmount(address user) public view returns (uint256) {
        uint256 _count = minerContract.balanceOf(user);
        if(_count == 0) return 0;

        uint256 baseTime = startTime;
        uint256 nowTime = block.timestamp;
        if (baseTime < nowTime) return 0;

        uint256 totalCalcAmount;
        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = minerContract.tokenOfOwnerByIndex(user, i);
            if (baseTime < mineLastTime[tokenId]) baseTime = mineLastTime[tokenId];
            uint256 workTime = nowTime.sub(baseTime);
            if (workTime > period.mul(validPeriodCount)) workTime = period.mul(validPeriodCount);
            uint256 clacStamina = minerContract.minerStamina(tokenId);
            uint256 mineCalcAmount = clacStamina.mul(outputPerStamina).mul(workTime).div(period);
            totalCalcAmount = totalCalcAmount.add(mineCalcAmount);
        }

        return totalCalcAmount;
    }

}