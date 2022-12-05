/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalCirculation;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 45000000000 * 10 ** 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalCirculation += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract AirshipXCoin is ERC20, Ownable {

    uint256 public startTime;
    address public miner;
    address public add_Ecosystem = 0xC07Cc7494Edc9852485969C532c5B41b3a529A8C;
    address public add_Contributiors = 0xDC4Bf476CD818F60bd1096313D086B33Fb1BA076;
    uint256 public MAXECOSYSTEM = 315 * 10 ** 8 * 10 ** 18;
    uint256 public MAXCONTRIBUTIORS = 225 * 10 ** 7 * 10 ** 18;
    uint256 public rateEcosystem = 10;
    uint256 public amountEcosystem;
    uint256 public amountContributiors;
    uint256 public contributiorsReleasePerMonth = MAXCONTRIBUTIORS / 24;
    uint256 public yearPeriod = 365 days;

    constructor() ERC20("AirshipX Coin", "ASC"){
        _mint(0xde45dBa1310603572410D87Ac245215f6D8d9958,675 * 10 ** 7 * 10 ** 18);  
        _mint(0x563d08A133F4B4F197B0C334c8F0804571297B34,450 * 10 ** 7 * 10 ** 18);  
        miner = _msgSender();           
        startTime = 1669219140;     // 2022-11-23 23:59:00
    }

    function ecosystemReleaseMint() public {
        require(_msgSender() == miner,"ERROR ROLE");


        require(amountEcosystem < MAXECOSYSTEM,"RELEASE DONE");
        uint256 canReleaseAmount = getEcosystemCanReleaseAmount();

        if (amountEcosystem + canReleaseAmount > MAXECOSYSTEM) {
            _mint(add_Ecosystem, MAXECOSYSTEM - amountEcosystem);       
            amountEcosystem = MAXECOSYSTEM;
        }else {
           amountEcosystem += canReleaseAmount; 
           _mint(add_Ecosystem, canReleaseAmount);        
        }
        
    }

    function getEcosystemCanReleaseAmount() public view returns(uint256){
        uint256 amountPerDay = getEcosystemAmountPerDay();
        uint256 totalMintAmount = getEcosystemTotalMintAmount();
        return ((totalMintAmount - amountEcosystem) / amountPerDay) * amountPerDay;
    }

    function getEcosystemTotalMintAmount() public view returns(uint256){
        uint256 year = getYears();
        uint256 totalMint = 0;

        uint256 lastyear = startTime + year * yearPeriod;
        uint256 amountPerDay = getEcosystemAmountPerDay();

        if(year > 0){
            for (uint i ; i < year; i++){
                totalMint += MAXECOSYSTEM * rateEcosystem / ( 2 ** i * 100);
            }
        }  
        totalMint += (block.timestamp - lastyear) * amountPerDay / 1 days;

        return totalMint;
    }

    function contributiorsReleaseMint() public {
        require(_msgSender() == miner,"ERROR ROLE");

        require(amountContributiors < MAXCONTRIBUTIORS,"RELEASE DONE");
        uint256 canReleaseAmount = getContributiorsCanReleaseAmount();

        if (amountContributiors + canReleaseAmount > MAXCONTRIBUTIORS) {
            _mint(add_Contributiors, MAXCONTRIBUTIORS - amountContributiors);       
            amountContributiors = MAXCONTRIBUTIORS;
        }else {
           amountContributiors += canReleaseAmount; 
           _mint(add_Contributiors, canReleaseAmount);        
        }
    }

    function getContributiorsCanReleaseAmount() public view returns(uint256){
        uint256 amountPerMonth = contributiorsReleasePerMonth;
        uint256 totalMintAmount = getContributiorsTotalMintAmount();
        return ((totalMintAmount - amountContributiors) / amountPerMonth) * amountPerMonth;
    }

    function getContributiorsTotalMintAmount() public view returns(uint256){
        return (block.timestamp - startTime) * contributiorsReleasePerMonth / 30 days;
    }

    function getEcosystemAmountPerDay() public view returns(uint256){
        uint256 year = getYears();
        return MAXECOSYSTEM * rateEcosystem / ( 2 ** year * 100 * 365);
    }

    function getYears() public  view returns(uint256){
        return (block.timestamp - startTime) / yearPeriod;
    }

    function resetMiner(address _new) public onlyOwner(){
        miner = _new;
    }

    function resetContributiorsAddress(address _new) public onlyOwner(){
        add_Contributiors = _new;
    }
    function resetEcosystemAddress(address _new) public onlyOwner(){
        add_Ecosystem = _new;
    }
}