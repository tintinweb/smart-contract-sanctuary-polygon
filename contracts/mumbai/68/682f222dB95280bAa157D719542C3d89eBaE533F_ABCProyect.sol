/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;


library SafeMath{
    // Restas
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    // Sumas
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    // Multiplicacion
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

interface IERC20{

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

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

contract ERC20 is Context, IERC20 {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _cap;
    uint256 _TokenPrice;

    constructor(string memory name_, string memory symbol_, uint256 cap_, uint256 TokenPrice_) {
        _name = name_;
        _symbol = symbol_;
        _cap = cap_;
        _TokenPrice = TokenPrice_;

    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function tokenPrice() public view virtual returns (uint256){
        return _TokenPrice;
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account != address(this), "Use create function");
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _create(uint256 amount) internal virtual {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");

        _beforeTokenTransfer(address(0), address(this), amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[address(this)] += amount;
        }
        emit Transfer(address(0), address(this), amount);
        _afterTokenTransfer(address(0), address(this), amount);

    }

    function _ChangePrice(uint256 _NewPrice) internal virtual{
        _TokenPrice = _NewPrice;

    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);
    event PauseHack(address account, address hacker);

    bool private _paused;
    bool private _hacked;

    constructor() {
        _paused = false;
        _hacked = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function paused() public view virtual returns (bool) {
        return _paused;
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

contract ABCProyect is ERC20, Pausable, Ownable {

    // Price 1 ETH = 1000000000000000000 WEI
    // Amount 1 HTL = 1000000000000000000 tokens 

    struct staker {
        uint256 tokens;
        uint256 time; 
        uint256 TxT;
    }

    mapping (address => staker) stMapping;

    uint256 public totalStake;
    uint256 public totalTxT;
    bool public rewardsOpen; 


    constructor () ERC20("ABC PROYECT", "ABC", 100000000000000000000000000, 1000000000000000){}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount*1000000000000000000);
    }

    function create(uint256 amount) public onlyOwner{
        _create(amount*1000000000000000000);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override{
        super._beforeTokenTransfer(from, to, amount);
    }

    function changePrice(uint256 NewPrice) public onlyOwner{
        _ChangePrice((NewPrice * 1000000000000000000));

    }
    
    function buyTokens(uint256 amount) public payable {
        
        uint256 tokenValue = _TokenPrice * amount;
        uint256 returnValue = msg.value - tokenValue;

        require(msg.value >= tokenValue, "Need more ETH");
        require(amount <= (balanceOf(address(this)) - totalStake), "Buy less PPT");

        payable(msg.sender).transfer(returnValue);
        _transfer(address(this), msg.sender, amount * 1000000000000000000);      

    }

    function stake(uint256 amount) public {

        require(stMapping[msg.sender].tokens == 0, "Staking position is open");
        require(balanceOf(msg.sender) > 0, "You dont have tokens");

        _transfer(msg.sender, address(this), amount * 1000000000000000000);

        stMapping[msg.sender].tokens = amount;
        stMapping[msg.sender].time = block.timestamp;

        totalStake = totalStake + amount;

    }

    function unstake() public {

        require(stMapping[msg.sender].tokens > 0, "Staking position is NOT open");

        uint256 time1 = block.timestamp;

        _transfer(address(this), msg.sender, (stMapping[msg.sender].tokens) * 1000000000000000000);

        stMapping[msg.sender].TxT = stMapping[msg.sender].TxT + (stMapping[msg.sender].tokens * (time1-stMapping[msg.sender].time));

        totalStake = totalStake - stMapping[msg.sender].tokens;

        totalTxT = totalTxT + (stMapping[msg.sender].tokens * (time1-stMapping[msg.sender].time));

        stMapping[msg.sender].tokens = 0;
        stMapping[msg.sender].time = 0;
    }

    function TxTOf(address _address) view public returns(uint256){
        
        return (stMapping[_address].TxT);
    
    }

    function depositEther(uint256 amount) public payable {

        uint256 payback = msg.value - (amount * 1000000000000000000);
        payable(msg.sender).transfer(payback);

    }

    function withdrawEther() public payable onlyOwner{

        payable(msg.sender).transfer(address(this).balance);

    }

    function openRewards(bool _bool) public onlyOwner{

        rewardsOpen = _bool;

    }

    function withdrawRewards() public payable {

        require(rewardsOpen == true, "Staking rewards not avaible yet");
        require(stMapping[msg.sender].TxT > 0, "You dont have rewards yet");

        uint256 addressReward = (address(this).balance*(stMapping[msg.sender].TxT * 1000000000000000000 / totalTxT)/1000000000000000000); 

        payable(msg.sender).transfer(addressReward);

        totalTxT = totalTxT - stMapping[msg.sender].TxT;

        stMapping[msg.sender].TxT = 0;

    }

}