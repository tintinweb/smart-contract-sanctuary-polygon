/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
 
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}
 
interface AggregatorV3Interface {
  function decimals()
    external
    view
    returns (
      uint8
    );
  function description()
    external
    view
    returns (
      string memory
    );
  function version()
    external
    view
    returns (
      uint256
    );
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract SwapContract is Ownable {

    IERC20 public meacToken;
    AggregatorV3Interface private priceFeed;
    mapping(address => uint256) public depositsMATIC;
    mapping(address => uint256) public depositsUSDC;
    mapping(address => uint256) public lockedMeac;
    mapping(address => uint256) public deposittimes;
    uint256 public  totalLockedMeac = 0 ether;
    uint256 public  totallockTime = 180 days;
    uint256 public  minDepositAmount = 25 / 10 * (10 ** 6); 
    uint256       tokensAmountForUSDC = 0.12 ether; 
    uint256 public  totalSwapedMATIC;
    uint256 public  totalSwapedUSDC;
    address private usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    
    constructor(IERC20 _token) {
        meacToken = _token;
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    function changeMeacToken(address _newMeacAdd) external onlyOwner{
        meacToken = IERC20(_newMeacAdd);
    }

    function depositUSDCForLockToken(uint256 amnt) public {
        require(amnt >= minDepositAmount, "Minimum amount is 2.5USDC");
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), amnt);
        uint256 tokenAmount = (getTokensAmount(amnt));
        depositsUSDC[msg.sender] = depositsUSDC[msg.sender]+amnt;
        lockedMeac[msg.sender] = lockedMeac[msg.sender]+tokenAmount;
        deposittimes[msg.sender] = block.timestamp;
        totalLockedMeac = totalLockedMeac+tokenAmount;
    }
    function depositMATICForLockToken() public payable {
       require(theUSDCAmount(msg.value) >= minDepositAmount, "Minimum amount is 2.5USDC");
        uint256 usdcAmount =  getUSDCAmount(msg.value);
        uint256 tokenAmount = (MaticTokensAmount(usdcAmount));
        depositsMATIC[msg.sender] = depositsMATIC[msg.sender]+msg.value;
        lockedMeac[msg.sender] = lockedMeac[msg.sender]+tokenAmount;
        deposittimes[msg.sender] = block.timestamp;
        totalLockedMeac = totalLockedMeac+tokenAmount;
    }
    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }
    function depositUSDCForUnlockToken(uint256 amnt) public {
        require(amnt >= minDepositAmount, "Minimum amount is 2.5USDC");
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), amnt);
        uint256 tokenAmount = (getTokensAmount(amnt));
        meacToken.transfer(msg.sender, tokenAmount);
        totalSwapedUSDC = totalSwapedUSDC+amnt;
    }
    function depositMATICForUnlockToken() public payable {
        require(theUSDCAmount(msg.value) >= minDepositAmount, "Minimum amount is 2.5USDC");
        uint256 usdcAmount = getUSDCAmount(msg.value);
        uint256 tokenAmount = (MaticTokensAmount(usdcAmount));
        meacToken.transfer(msg.sender, tokenAmount);
        totalSwapedMATIC = totalSwapedMATIC+msg.value;
    }
    function claimTokens() public {
        require(lockedMeac[msg.sender] > 0, "There are no deposited tokens for you.");
        require(checkTime(msg.sender), "Your tokens are locked now.");
        meacToken.transfer(msg.sender, lockedMeac[msg.sender]);
        totalLockedMeac = totalLockedMeac-lockedMeac[msg.sender];
        lockedMeac[msg.sender] = 0;
        depositsMATIC[msg.sender] = 0;
        depositsUSDC[msg.sender] = 0;
        deposittimes[msg.sender] = 0;
    }
    function read(address add) public view returns(uint256 _depositMATIC, uint256 _depositUSDC, uint256 _lockedMeac, uint256 _restTime, bool _checkTime) {
        _depositMATIC = depositsMATIC[add];
        _depositUSDC = depositsUSDC[add];
        _lockedMeac = lockedMeac[add];
        _restTime = 0;
        if(totallockTime >= (block.timestamp - deposittimes[add]))
            _restTime = totallockTime - (block.timestamp - deposittimes[add]);
        _checkTime = checkTime(add);
    }
    function getUSDCPerMATIC() public view returns (uint256) {
        (
            ,
            int256 price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return (uint256(price));
    }

    function getUSDCAmount(uint256 maticAmount) public view returns(uint256){
        uint256 usdcAmount = maticAmount*getUSDCPerMATIC();
        return (usdcAmount);
    }

    function theUSDCAmount(uint256 maticAmount) private view returns(uint256){
        uint256 maticrate= getUSDCPerMATIC()/1e2;
        uint256 usdcAmount = maticAmount*maticrate;
        return (usdcAmount/1e18);
    }

    function getTokensAmount(uint256 usdcAmount) private view returns(uint256) {
        uint256 tokensAmount = ((usdcAmount*1e12)*1e18)/tokensAmountForUSDC;
        return tokensAmount;
    }

    function MaticTokensAmount(uint256 usdcAmount) private view returns(uint256) {
        uint256 tokensAmount = usdcAmount*1e18/tokensAmountForUSDC;
        return (tokensAmount/1e8);
    }

    function checkTime(address add) private view returns(bool) {
        bool ret = ((deposittimes[add] != 0) && (block.timestamp >= (deposittimes[add] + totallockTime)));
        return ret;
    }

    function releaseFunds(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function releaseFundsAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
      require(IERC20(tokenAddress).balanceOf(address(this))>0, "Not this amount in contract!");
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function recoverUSDC(uint256 tokenAmount) external onlyOwner {
      require(IERC20(usdcAddress).balanceOf(address(this))>0, "Not this amount in contract!");
        IERC20(usdcAddress).transfer(msg.sender, tokenAmount);
        emit Recovered(usdcAddress, tokenAmount);
    }
    
    event Recovered(address token, uint256 amount);
}