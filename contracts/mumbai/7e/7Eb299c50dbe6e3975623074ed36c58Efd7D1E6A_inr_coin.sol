/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract inr_coin {
    using SafeERC20 for IERC20;
    string  _name;
    string  _symbol;
    string  _Image;
    address owner;
    mapping (address => uint256) _balanceOf;
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event UpdateName(string indexed name,string indexed symbol);
    modifier onlyOwner() {
        require(msg.sender == Owner(), "AnyswapV3ERC20: FORBIDDEN");
        _;
    }
    function Owner() public view returns (address) {
        return owner;
    }
    function name() public view returns(string memory){
        return _name;
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function Image() public view returns(string memory){
        return _Image;
    }
    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }
    function burn(address from, uint256 amount) external onlyOwner returns (bool) {
        require(from != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(from, amount);
        return true;
    }
    // Records number of AnyswapV3ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public allowance;

    constructor() {
        _name = "INR COIN";
        _symbol = "INR";
        _Image = "abcdc";
        _mint(msg.sender, 1000 * 10 ** decimals());
        uint256 chainId;
        assembly {chainId := chainid()}
        owner = msg.sender;
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balanceOf[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0) || to != address(this));
        uint256 balance = _balanceOf[msg.sender];
        require(balance >= value, "AnyswapV3ERC20: transfer amount exceeds balance");
        _balanceOf[msg.sender] = balance - value;
        _balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0) || to != address(this));
        _allowance(from, to, amount);
        _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from,address to,uint256 amount) internal returns(bool){
        uint256 balance = _balanceOf[from];
        require(balance >= amount, "transfer amount exceeds balance");
        _balanceOf[from] = balance - amount;
        _balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    function _allowance(address from,address to,uint256 amount) internal returns(bool){
        uint256 allowed = allowance[from][to];
        require(allowed >= amount, "request exceeds allowance");
        uint256 reduced = allowed - amount;
        allowance[from][to] = reduced;
        emit Approval(from, to, reduced);
        return true;
    }
    function updateName(string memory newname,string memory newsymbol) public onlyOwner returns(string memory _newname,string memory _newsymbol){
        _name = newname;
        _symbol = newsymbol;
        emit UpdateName(newname, newsymbol);
        return (_newname,_newsymbol);
    }
    function transferOwnership(address _newowner) public onlyOwner returns(address){
        owner = _newowner;
        return owner;
    }
    function balanceOf(address account) public view returns(uint256){
        return _balanceOf[account];
    }
}