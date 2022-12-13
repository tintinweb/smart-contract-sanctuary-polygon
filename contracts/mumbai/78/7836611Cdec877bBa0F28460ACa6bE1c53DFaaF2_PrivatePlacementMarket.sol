// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./OwnablePausable.sol";
import "./StockERC1155.sol";
import "./StakingReward.sol";
import "./StockMargin.sol";

interface ITdex {
    function getPrice(address tokenContract) external pure returns(uint256);
}

contract PrivatePlacementMarket is OwnablePausable, ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event Buy(
        address indexed trader,
        uint256 indexed index,
        uint256 usdtAmount,
        uint256 ttAmountInUsdt,
        uint256 ttStakedAmount,
        uint256 stockMarginInUsdt,
        uint256 stockNftId
    );
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);
    event BagChanged(uint256[] bag0, uint256[] bag1, uint256[] bag2, uint256[] bag3, uint256[] bag4);
    event MarginWithdrawn(address indexed withdrawer, uint256 principal, uint256 compensation);

    struct Bag {
        uint256 amount;
        uint256 ttValue;
        uint256 stockValue;
        uint256 amountForStockMargin;
    }
    
    EnumerableSetUpgradeable.UintSet private _stockNftIds;

    uint256 private TT_PRICE_PRECISION;

    address private _usdtIncomeAddress;
    address private _payOutAddress;
    address private _usdtAddress;
    address private _ttAddress;

    uint128 private _usdtDecimals;
    uint128 private _ttDecimals;
    bool private _openBuyFunction;

    StockERC1155 private _stockERC1155;
    StockMargin private _stockMargin;
    StakingReward private _stackingReward;
    ITdex private _tdex;
    mapping(uint256 => Bag) private _bags;

    //mapping(address => bool) private _whitelist;

    uint256 private _launchResult; //0-init 1-suc 2-fail

    uint256[50] private __gap;

    function initialize(
        address owner,
        address usdtAddress, 
        address ttAddress, 
        address usdtIncomeAddr,
        address payOutAddr,
        address stockERC1155Address,
        address stockMarginAddress,
        address stackingRewardAddress,
        address tdex,
        uint256 ttPricePrecision) public initializer {
            __OwnablePausable_init(owner); 
            __ReentrancyGuard_init();   
            _openBuyFunction = true;
            _usdtAddress = usdtAddress;
            _ttAddress = ttAddress;
            _usdtIncomeAddress = usdtIncomeAddr;
            _payOutAddress = payOutAddr;
            _stockERC1155 = StockERC1155(stockERC1155Address);
            _stockMargin = StockMargin(stockMarginAddress);
            _stackingReward = StakingReward(stackingRewardAddress);
            _tdex = ITdex(tdex);
            _usdtDecimals = IERC20MetadataUpgradeable(usdtAddress).decimals();
            _ttDecimals = IERC20MetadataUpgradeable(ttAddress).decimals();

            TT_PRICE_PRECISION = ttPricePrecision;

            uint256 usdtPrecision = 10**_usdtDecimals;

            _bags[0] = Bag(99*usdtPrecision/10, 0, 99*usdtPrecision/10, 99*usdtPrecision/10);
            _bags[1] = Bag(1000*usdtPrecision, 500*usdtPrecision, 550*usdtPrecision, 500*usdtPrecision);
            _bags[2] = Bag(4000*usdtPrecision, 2200*usdtPrecision, 2200*usdtPrecision, 2000*usdtPrecision);
            _bags[3] = Bag(20000*usdtPrecision, 11000*usdtPrecision, 12000*usdtPrecision, 10000*usdtPrecision);
            _bags[4] = Bag(60000*usdtPrecision, 36000*usdtPrecision, 39000*usdtPrecision, 30000*usdtPrecision);
            _stockNftIds.add(_bags[0].stockValue);
            _stockNftIds.add(_bags[1].stockValue);
            _stockNftIds.add(_bags[2].stockValue);
            _stockNftIds.add(_bags[3].stockValue);
            _stockNftIds.add(_bags[4].stockValue);

            IERC20Upgradeable(_usdtAddress).safeApprove(stockMarginAddress, type(uint256).max);
    }

    // function addWhitelist(address[] calldata addresses, bool[] calldata inList) external onlyOwnerOrOperator {
    //     require(addresses.length == inList.length, "size error");
    //     for (uint256 i; i < addresses.length; i++) {
    //         _whitelist[addresses[i]] = inList[i];
    //     }
    //     emit WhitelistAdded(addresses, inList);
    // }

    function buy(uint256 index) external whenNotPaused {
        require(index < 5, "index error");
        address trader = msg.sender;
        //require(_openBuyFunction && _whitelist[trader], "can not buy");

        //check usdt balance and approve
        uint256 requireUsdt = _bags[index].amount;
        require(requireUsdt <= IERC20Upgradeable(_usdtAddress).balanceOf(trader), "USDT not enough");
        require(IERC20Upgradeable(_usdtAddress).allowance(trader, address(this)) > requireUsdt, "not approved");
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(trader, address(this), requireUsdt);

        //exchange half to stockNFT
        if (_bags[index].stockValue > 0) {
            _stockMargin.addStockMargin(trader, _bags[index].amountForStockMargin);
            _stockERC1155.mint(trader, _bags[index].stockValue, 1);
        }
        
        //exchange half to tt
        uint256 ttAmount;
        if (_bags[index].ttValue > 0) {
            IERC20Upgradeable(_usdtAddress).safeTransfer(_usdtIncomeAddress, requireUsdt - _bags[index].amountForStockMargin);
            uint256 ttPrice = _tdex.getPrice(_ttAddress);
            ttAmount = _bags[index].ttValue*TT_PRICE_PRECISION/ttPrice;
            IERC20Upgradeable(_ttAddress).safeTransferFrom(_payOutAddress, address(_stackingReward), ttAmount);
            _stackingReward.deposit(trader, ttAmount);
        }
        
        emit Buy(
            trader, 
            index, 
            requireUsdt, 
            _bags[index].ttValue,
            ttAmount,
            _bags[index].amountForStockMargin,
            _bags[index].stockValue);
    }

    function exchangeStockNFT(uint256[] memory ids, uint256[] memory amounts) external onlyOperator whenNotPaused nonReentrant{
        require(_launchResult == 1, "launch state error");
        _stockERC1155.burnBatch(msg.sender, ids, amounts);
    }

    function withdrawStockMargin() external whenNotPaused nonReentrant{
        require(_launchResult == 2, "launch state error");
        uint256[] memory ids = _stockNftIds.values();
        for(uint256 i; i < ids.length; i++) {
            uint256 amount = _stockERC1155.balanceOf(msg.sender, ids[i]);
            if (amount > 0) {
                _stockERC1155.burn(msg.sender, ids[i], amount);
            }
        }
        (uint256 principal, uint256 compensation) = _stockMargin.withdrawMargin(msg.sender);
        emit MarginWithdrawn(msg.sender, principal, compensation);
    }

    function setBag(
        uint256[] calldata bag0, 
        uint256[] calldata bag1, 
        uint256[] calldata bag2, 
        uint256[] calldata bag3,
        uint256[] calldata bag4) 
        external onlyOwnerOrOperator {
        _bags[0] = Bag(bag0[0], bag0[1], bag0[2], bag0[3]);
        _bags[1] = Bag(bag1[0], bag1[1], bag1[2], bag1[3]);
        _bags[2] = Bag(bag2[0], bag2[1], bag2[2], bag2[3]);
        _bags[3] = Bag(bag3[0], bag3[1], bag3[2], bag3[3]);
        _bags[4] = Bag(bag4[0], bag4[1], bag4[2], bag4[3]);

        _stockNftIds.add(bag0[2]);
        _stockNftIds.add(bag1[2]);
        _stockNftIds.add(bag2[2]);
        _stockNftIds.add(bag3[2]);
        _stockNftIds.add(bag4[2]);

        emit BagChanged(bag0, bag1, bag2, bag3, bag4);
    }

    function setMarginDepositAddress(address marginDepositAddr) external onlyOwnerOrOperator {
        _stockMargin.setMarginDepositAddress(marginDepositAddr);
    }


    function setPayOutAddress(address payOutAddress_) external onlyOwnerOrOperator {
        _payOutAddress = payOutAddress_;
    }

    function setUsdtIncomeAddress(address usdtIncomeAddress_) external onlyOwnerOrOperator {
        _usdtIncomeAddress = usdtIncomeAddress_;
    }

    function setOpenBuyFunction(bool open) external onlyOwnerOrOperator {
        _openBuyFunction = open;
    }

    function launchSuccess() external onlyOwnerOrOperator {
        require(_launchResult == 0, "launch state error");
        _launchResult = 1;
    }

    function launchFailed() external onlyOwnerOrOperator {
        require(_launchResult == 0, "launch state error");
        _launchResult = 2;
    }

    function launchResult() external view returns(uint256) {
        return _launchResult;
    }


    function totalUserStockMargin() external view returns(uint256) {
        return _stockMargin.userTotalMargin();
    }

    function userStockMargin(address user) external view returns(uint256) {
        return _stockMargin.userMargin(user);
    }

    function bag(uint256 index) external view returns (Bag memory) {
        return _bags[index];
    }

    // function inWhitelist(address user) external view returns(bool) {
    //     return _whitelist[user];
    // }

    function stockNftIds() external view returns(uint256[] memory) {
        return _stockNftIds.values();
    }

    function listStockNft(address user) external view returns(
        uint256[] memory ids, 
        uint256[] memory amounts
    ) {
        ids = _stockNftIds.values();
        address[] memory accounts = new address[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            accounts[i] = user;
        }
        amounts = _stockERC1155.balanceOfBatch(accounts, ids);
    }

    function getTokens() external view returns (
        address usdtAddress,
        uint256 usdtDecimals,
        address ttAddress,
        uint256 ttDecimals
    ) {
        return (_usdtAddress, _usdtDecimals, _ttAddress, _ttDecimals);
    }

    function getTTPrice() external view returns(uint256, uint256) {
        return (_tdex.getPrice(_ttAddress), TT_PRICE_PRECISION);
    }

    function payOutAddress() external view returns(address) {
        return _payOutAddress;
    }

    function usdtIncomeAddress() external view returns(address) {
        return _usdtIncomeAddress;
    }

    function marginDepositAddress() external view returns(address) {
        return _stockMargin.marginDepositAddress();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./OwnablePausable.sol";


interface ITransferProxy {
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
} 

contract StockERC1155 is OwnablePausable, ERC1155SupplyUpgradeable {
    
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);

    address private _ppmAddress;
    ITransferProxy private _transferProxy;
    bool private _whitelistOpen;
    mapping(address => bool) private _whitelist;

    uint256[50] private __gap;

    function initialize(address owner) public initializer {
        __OwnablePausable_init(owner);
        _whitelistOpen = true;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function addWhitelist(address[] calldata addresses, bool[] calldata inList) external onlyOperator {
        require(addresses.length == inList.length, "size error");
        for (uint256 i; i < addresses.length; i++) {
            _whitelist[addresses[i]] = inList[i];
        }
        emit WhitelistAdded(addresses, inList);
    }

    function openWhitelist(bool open) external onlyOperator {
        _whitelistOpen = open;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from == address(0) || to == address(0)) { //mint or burn only by ppm
            require(msg.sender == _ppmAddress, "not PPM");
            if (address(_transferProxy) != address(0)) {
                _transferProxy.beforeTokenTransfer(operator, from, to, ids, amounts, data);
            }
        }
        
        if (from != address(0) && to != address(0)) { //common transfer
            //transfer checked by proxy contract
            if (address(_transferProxy) == address(0)) {
                require(!_whitelistOpen || _whitelist[from], "transfer not supported");
            } else {
                _transferProxy.beforeTokenTransfer(operator, from, to, ids, amounts, data);
            }
        }
        ERC1155SupplyUpgradeable._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (address(_transferProxy) != address(0)) {
            _transferProxy.afterTokenTransfer(operator, from, to, ids, amounts, data);
        }
    }

    function setTransferProxy(address transferProxy) external onlyOwnerOrOperator {
        _transferProxy = ITransferProxy(transferProxy);
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyPPM {
        _mint(to, id, amount, bytes(''));
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyPPM {
        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyPPM {
        _burnBatch(from, ids, amounts);
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

    function inWhitelist(address user) external view returns(bool) {
        return _whitelist[user];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


contract OwnablePausable is ContextUpgradeable, PausableUpgradeable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    address private _candidate;
    address private _operator;
    address private _deployer;

    uint256[50] private __gap;

    // constructor(address owner_) {
    //     require(owner_ != address(0), "owner is zero");
    //     _owner = owner_;
    //     _deployer = msg.sender;
    // }

    function __OwnablePausable_init(address owner_) internal initializer {
        __Context_init_unchained();
        __Pausable_init();

        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
        _deployer = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(_operator == msg.sender || _owner == msg.sender, "Ownable: caller is not the operator or owner");
        _;
    }

    modifier onlyDeployer() {
        require(_deployer == msg.sender, "Ownable: caller is not the deployer");
        _;
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }


    function candidate() public view returns (address) {
        return _candidate;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner zero address");
        require(newOwner != _owner, "newOwner same as original");
        require(newOwner != _candidate, "newOwner same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "candidate is zero address");
        require(_candidate == _msgSender(), "not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;



import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OwnablePausable.sol";
import "./interface/IPPM.sol";

contract StockMargin is OwnablePausable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;


    address private _usdtAddress;
    address private _ppmAddress;
    uint256 private _userTotalMargin;
    address private _marginDepositAddress;

    mapping(address => uint256) private _margins;
    uint256[50] private __gap;

    function initialize(address owner, 
        address usdtAddress, 
        address marginDepositAddr) public initializer {
        __OwnablePausable_init(owner);
        __ReentrancyGuard_init();   
    
        _usdtAddress = usdtAddress;
        _marginDepositAddress = marginDepositAddr;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PrivatePlacement");
        _;
    }

    function addStockMargin(address user, uint256 margin) external onlyPPM{
        _margins[user] += margin;
        _userTotalMargin += margin;
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(_ppmAddress, _marginDepositAddress, margin);
    }

    
    function withdrawMargin(
        address withdrawer
    ) external onlyPPM whenNotPaused returns(uint256 principal, uint256 compensation) {
        principal = _margins[withdrawer];
        require(principal > 0, "no margin");
        compensation = principal*5/100;
        _margins[withdrawer] = 0;
        _userTotalMargin -= principal;

        IERC20Upgradeable(_usdtAddress).safeTransferFrom(_marginDepositAddress, withdrawer, principal);
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(IPPM(_ppmAddress).payOutAddress(), withdrawer, compensation);
    }


    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function setMarginDepositAddress(address marginDepositAddr) external onlyPPM {
        _marginDepositAddress = marginDepositAddr;
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

    function marginDepositAddress() external view returns(address){
        return _marginDepositAddress;
    }

    function userTotalMargin() external view returns(uint256) {
        return _userTotalMargin;
    }

    function userMargin(address user) external view returns(uint256) {
        return _margins[user];
    }

    


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./OwnablePausable.sol";
import "./interface/IPPM.sol";

/**
 * @title StakingReward
 * @notice Stake TT and Earn TT
 */
contract StakingReward is OwnablePausable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event TdexTokenWithdrawn(address indexed user, uint256 withdrawn, uint256 remained);
    event RewardsClaim(address indexed user, uint256 rewardDebt, uint256 pendingRewards);
    event TokenWithdrawnOwner(uint256 amount);
    event UserLevelChanged(address user, uint256 oldLevel, uint256 newLevel);
    event ApyAdded(uint256[] level, uint256[] apy);

    struct UserInfo {
        uint256 stakedAmount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
        uint256 level; //0-4
    }

    struct OrderInfo {
        uint256 addedBlock;
        uint256 totalAmount; //total amount, not changed
        uint256 remainedAmount; //remained TT for staking
        uint256 lastReleasedAmount; //releasedAmount after last withdraw 
        uint256 lastRewardBlock;
    }

    struct ApyLevel {
        uint256 startBlock;
        uint256 apy;
    }

    struct UserLevel {
        uint256 startBlock;
        uint256 level;
    }

    // Precision factor for calculating rewards
    uint256 private constant PRECISION_FACTOR = 10**18;
    uint256 public RELEASE_CYCLE;
    uint256 public RELEASE_CYCLE_TIMES;
    uint256 private SECONDS_PER_BLOCK;
    //1% apy for 1 token unit corresponds to 1 block reward
    uint256 public BASE_REWARD_PER_BLOCK; //1个代币单位 1%的apy 对应1个区块的奖励
    
    uint256 private lastPausedTimestamp;

    address private _ttAddress;
    address private _ppmAddress;
    
    mapping(address => UserInfo) private _userInfo;
    mapping(address => OrderInfo[]) private _orders;
    //index => apy
    mapping(uint256 => ApyLevel[]) private _apys;
    mapping(address => UserLevel[]) private _userLevels;
    
    uint256[50] private __gap;

    function initialize(
        address owner, 
        uint256 secondsPerBlock, 
        address ttAddress) public initializer {
        __OwnablePausable_init(owner);
        __ReentrancyGuard_init();


        RELEASE_CYCLE = 30 days;
        RELEASE_CYCLE_TIMES = 6;

        SECONDS_PER_BLOCK = secondsPerBlock;
        BASE_REWARD_PER_BLOCK = SECONDS_PER_BLOCK*PRECISION_FACTOR/360 days/100;
        _ttAddress = ttAddress;

        uint256 number = block.number;
        _apys[0].push(ApyLevel(number, 18));

        //broker-level
        _apys[1].push(ApyLevel(number, 20));
        _apys[2].push(ApyLevel(number, 28));
        _apys[3].push(ApyLevel(number, 30));
        _apys[4].push(ApyLevel(number, 32));
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function deposit(address staker, uint256 ttStakedAmount) external whenNotPaused onlyPPM {        
        OrderInfo[] storage userOrders = _orders[staker];
        require(userOrders.length < 200, "too many orders");
        UserInfo storage user = _userInfo[staker];
        user.stakedAmount += ttStakedAmount;
        userOrders.push(OrderInfo(block.number, ttStakedAmount, ttStakedAmount, 0, block.number));
        
        UserLevel[] storage levels = _userLevels[staker];
        if (levels.length == 0) {
            levels.push(UserLevel(block.number, 0));
        }
    }

    function updateUserLevel(address staker, uint256 level) external whenNotPaused onlyOwnerOrOperator {
        require(level>0 && level < 5, "level error");
        UserInfo storage user = _userInfo[staker];
        require(level != user.level, "lever not changed");

        UserLevel[] storage levels = _userLevels[staker];
        levels.push(UserLevel(block.number, level));

        uint256 oldLevel = user.level;
        user.level = level;
        emit UserLevelChanged(staker, oldLevel, level);
    }

    function addApy(uint256[] calldata levels, uint256[] calldata apys_) external whenNotPaused onlyOwnerOrOperator{
        require(levels.length == apys_.length, "size error");
        for (uint i; i<levels.length; i++) {
            _apys[levels[i]].push(ApyLevel(block.number, apys_[i]));
        }
        emit ApyAdded(levels, apys_);
    }

    function depositMock(uint256 amount, uint256 loopCounter) external {
        address staker = msg.sender;
        UserInfo storage user = _userInfo[staker];
        OrderInfo[] storage userOrders = _orders[staker]; 
        user.stakedAmount += loopCounter*amount;
        for (uint256 i; i<loopCounter; i++) {
            userOrders.push(OrderInfo(block.number, amount, amount, 0, block.number));
        }
        UserLevel[] storage levels = _userLevels[staker];
        if (levels.length == 0) {
            levels.push(UserLevel(block.number, 0));
        }
    }

    /**
     *               init block
     *          block |300        |1000                      |2000               |2500
     *          apy   |18         |20                        |22                 |24
     * 
     * case1: staked at block 3000                                                            3000 
     *                                                                                        [3000, block.number) apy=24
     * 
     * case1: staked at block 1500      1500
     *                                  [1500,2000) apy=20
     *                                                        [2000,2500) apy=22   
     *                                                                            [2500,block.number) apy=24 
     *                                                                
     */
    function calculatePendingRewards(address staker, uint256 toBlock) public view returns(uint256 rewardDebt, uint256 pendingRewards) {
        UserInfo memory user = _userInfo[staker];
        OrderInfo[] memory userOrders = _orders[staker];
        if (_userInfo[staker].stakedAmount == 0) {
            return(user.rewardDebt, 0);
        }
        UserLevel[] memory levels = _userLevels[staker];
        uint256 levelSize = levels.length;
        for (uint256 i; i < userOrders.length; i++) {
            pendingRewards += _calculatePendingReward(userOrders[i], levels, levelSize, toBlock);
        }
        return (user.rewardDebt, pendingRewards);
    }

    function _calculatePendingReward(
        OrderInfo memory userOrder,
        UserLevel[] memory levels,
        uint256 levelSize,
        uint256 toBlock
    ) internal view returns(uint256 pendingReward) {
        if (toBlock == 0) {
            toBlock = block.number;
        }
        uint256 lastRewardBlock = userOrder.lastRewardBlock;
        uint256 endBlock = userOrder.addedBlock + RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK;
        if (lastRewardBlock >= levels[levelSize-1].startBlock) {
            pendingReward += __calculatePendingReward(lastRewardBlock, toBlock,
                                    userOrder.remainedAmount, levels[levelSize-1].level, endBlock);
        } else {
            uint256 matches; //0-没有重合，1-第一次重合 2-第1次重合之后的区间
            for (uint256 j; j < levelSize-1; j++) {
                if (matches == 0 && levels[j].startBlock <= lastRewardBlock && lastRewardBlock < levels[j+1].startBlock) {
                    matches = 1;
                }
                if (matches >= 1) {
                    pendingReward += __calculatePendingReward(matches == 1 ? lastRewardBlock : levels[j].startBlock, toBlock, 
                                    userOrder.remainedAmount, levels[j].level, levels[j+1].startBlock);                       
                    matches = 2;
                }
            }
            pendingReward += __calculatePendingReward(levels[levelSize-1].startBlock, toBlock,
                                    userOrder.remainedAmount, levels[levelSize-1].level, endBlock);    
        }
    }

    function __calculatePendingReward(
        uint256 rewardFromBlock, 
        uint256 rewardToBlock,
        uint256 remainedAmount, 
        uint256 userLevel,
        uint256 endBlock
    ) internal view returns (uint256 pendingReward) {
        //uint256 lastRewardBlock = userOrder.lastRewardBlock;
        //uint256 endBlock = userOrder.addedBlock + RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK;
        ApyLevel[] memory apyLevels = _apys[userLevel];
        uint256 apySize = apyLevels.length;

        if (rewardFromBlock >= apyLevels[apySize-1].startBlock) {
            uint256 multiplier = _getMultiplier(rewardFromBlock, rewardToBlock, endBlock);
            pendingReward += remainedAmount*multiplier*apyLevels[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
        } else {
            uint256 matches; //0-没有重合，1-第一次重合 2-第1次重合之后的区间
            for (uint256 i; i < apySize-1; i++) {
                if (matches == 0 && apyLevels[i].startBlock <= rewardFromBlock && rewardFromBlock < apyLevels[i+1].startBlock) {
                    matches = 1;
                }

                if (matches >= 1) {
                    uint256 realToBlock = apyLevels[i+1].startBlock > rewardToBlock ? rewardToBlock : apyLevels[i+1].startBlock;
                    uint256 multiplier = _getMultiplier(matches == 1 ? rewardFromBlock : apyLevels[i].startBlock, realToBlock, endBlock);
                    pendingReward += remainedAmount*multiplier*apyLevels[i].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
                    matches = 2;
                }
            }
            uint256 multiplier_ = _getMultiplier(apyLevels[apySize-1].startBlock, rewardToBlock, endBlock);
            pendingReward += remainedAmount*multiplier_*apyLevels[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
        }
    }

    function calculatePendingWithdraw(address staker, uint256 toBlock) 
        public 
        view 
        returns(
            uint256[] memory pendingWithdrawAmounts, 
            uint256[] memory releasedAmounts, 
            uint256 totalPendingWithdrawAmount
        ) {
            if (toBlock == 0) {
                toBlock = block.number;
            }
            OrderInfo[] memory userOrders = _orders[staker];
            uint256 len = userOrders.length;
            pendingWithdrawAmounts = new uint256[](len);
            releasedAmounts = new uint256[](len);
            if (_userInfo[staker].stakedAmount > 0) {
                for (uint256 i; i < len; i++) {
                    if (userOrders[i].remainedAmount == 0 || toBlock <= userOrders[i].addedBlock) {
                        continue;
                    }
                    uint256 period = (toBlock - userOrders[i].addedBlock)/(RELEASE_CYCLE/SECONDS_PER_BLOCK);
                    if (period > RELEASE_CYCLE_TIMES) {
                        period = RELEASE_CYCLE_TIMES;
                    }
                    if (period > 0) {
                        uint256 totalRelease = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;

                        if (totalRelease > userOrders[i].lastReleasedAmount) { 
                            releasedAmounts[i] = totalRelease;
                        } else {
                            releasedAmounts[i] = userOrders[i].lastReleasedAmount;
                        }
                        pendingWithdrawAmounts[i] = releasedAmounts[i] - (userOrders[i].totalAmount-userOrders[i].remainedAmount);
                        totalPendingWithdrawAmount += pendingWithdrawAmounts[i];
                    }
                }
            }
    }


    function claim() external whenNotPaused nonReentrant{
        address staker = msg.sender;

        (, uint256 pendingRewards) = calculatePendingRewards(staker, block.number);
        UserInfo storage user = _userInfo[staker];
        uint256 claimAmount = user.rewardDebt + pendingRewards;
        require(claimAmount > 0, "no TT claimed");
        user.rewardDebt = 0;
        
        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
        }
        IERC20Upgradeable(_ttAddress).safeTransferFrom(IPPM(_ppmAddress).payOutAddress(), staker, claimAmount);
        emit RewardsClaim(staker, user.rewardDebt, pendingRewards);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant returns(uint256 withdrawn){
        withdrawn = _withdraw(msg.sender, amount);
        require(withdrawn > 0, "No TT withdrawn");
        IERC20Upgradeable(_ttAddress).safeTransfer(msg.sender, withdrawn);
    }    

    function withdrawMock(uint256 amount) external {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        IERC20Upgradeable(_ttAddress).safeTransferFrom(IPPM(_ppmAddress).payOutAddress(), msg.sender, withdrawn);
    }

    function _withdraw(address staker, uint256 amount) internal returns(uint256 withdrawn) {
        OrderInfo[] storage userOrders = _orders[staker];
        UserInfo storage user = _userInfo[staker];  
        require(user.stakedAmount > 0, "no TT staked");

        UserLevel[] memory levels = _userLevels[staker];
        uint256 levelSize = levels.length;
        uint256 len = userOrders.length;
        uint256 pendingRewards;
        for (uint256 i; i < len; i++) {
            if (userOrders[i].remainedAmount == 0) {
                continue;
            }
            uint256 period = (block.number - userOrders[i].addedBlock)/(RELEASE_CYCLE/SECONDS_PER_BLOCK);
            if (period > RELEASE_CYCLE_TIMES) {
                period = RELEASE_CYCLE_TIMES;
            }
            if (period == 0) {
                continue;
            }

            uint256 totalReleased = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;
            uint256 releasedAmount;
            if (totalReleased > userOrders[i].lastReleasedAmount) { 
                releasedAmount = totalReleased;
            } else {
                releasedAmount = userOrders[i].lastReleasedAmount;
            }
            uint256 pendingWithdrawAmount = releasedAmount - (userOrders[i].totalAmount - userOrders[i].remainedAmount);
            if (pendingWithdrawAmount == 0) { //all releasedAmount was withdrawn 
                continue;
            }

            //pendingRewards must happen before state changed
            pendingRewards += _calculatePendingReward(userOrders[i], levels, levelSize, block.number);

            userOrders[i].lastReleasedAmount = releasedAmount;
            uint256 orderWithdrawAmount;
            if (amount - withdrawn >= pendingWithdrawAmount) {
                orderWithdrawAmount = pendingWithdrawAmount;
            } else {
                orderWithdrawAmount = amount - withdrawn;
            }
            withdrawn += orderWithdrawAmount;
            userOrders[i].remainedAmount -= orderWithdrawAmount;
            userOrders[i].lastRewardBlock = block.number;
            
            if (withdrawn == amount) {
                break;
            }
        }

        user.rewardDebt += pendingRewards;
        user.stakedAmount -= withdrawn;
        emit TdexTokenWithdrawn(staker, withdrawn, user.stakedAmount);
    }


    function setReleaseCycle(uint256 releaseCycle, uint256 releaseCycleTimes) external onlyOperator {
        RELEASE_CYCLE = releaseCycle;
        RELEASE_CYCLE_TIMES = releaseCycleTimes;
    }

    function pauseStake() external onlyOwner { //access auth handled by parent
        lastPausedTimestamp = block.timestamp;
        super.pause();
    }

    function unpauseStake() external onlyOwner { //access auth handled by parent
        super.unpause();
    }

    /**
     * @notice Transfer TT tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTdexTokens(uint256 amount) external onlyOwner whenPaused {
        require(block.timestamp > (lastPausedTimestamp + 3 days), "Too early to withdraw");
        IERC20Upgradeable(_ttAddress).safeTransfer(msg.sender, amount);
        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to, uint256 endBlock) internal pure returns (uint256) {
        if (to <= from) {
            return 0;
        }
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }


    function userInfo(address staker) external view returns(UserInfo memory) {
        return _userInfo[staker];
    }

    function orders(address staker) external view returns(OrderInfo[] memory) {
        return _orders[staker];
    }

    function apy(uint256 index) external view returns(ApyLevel[] memory) {
        return _apys[index];
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPPM {
    function payOutAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}