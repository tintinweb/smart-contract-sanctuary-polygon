/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function burn(uint256 amount) external; 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

contract vault {
    mapping(address => bool) hasAccess; // mapping is used internally by contract to check if address has access
    mapping(address => mapping(address => int)) deposited; // mapping is internally used by contract to see deposits of address of token
    mapping(address => bool) exists; // mapping internally used by contract to check if token exists in tokens array
    address[] tokens; // array internally used by contract to see all tokens deposited
    
    constructor(address[] memory _address) {
        hasAccess[msg.sender] = true;
        for(uint i; i < _address.length; i++) {
            hasAccess[_address[i]] = true;
        } 
    }

    /*\
    function with this modifier can only be accessed by those with access
    \*/
    modifier onlyAccess() {
        require(hasAccess[msg.sender], "no access, please contact owner!");
        _;
    }



////////////////////////////////////////////////////////////////////////////////////////////////////
// MAIN FUNCTIONS

    /*\
    used to deposit new tokens into contract
    can be used by anyone
    \*/
    function deposit(address _token, uint _amount) public returns(bool){
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount));
        require(_add(_token, _amount));
        emit newDeposit(msg.sender, _amount, _token);
        return true;
    }

    /*\
    used to withdraw funds from contract
    can only be used by those with access
    \*/
    function withdraw(address _token, uint _amount) public onlyAccess returns(bool){
        require(_subtract(_token, _amount));
        require(IERC20(_token).transfer(msg.sender, _amount));
        emit newWithdraw(msg.sender, _amount, _token);
        return true;
    }

    /*\
    used to transfer funds to someone else
    can only be used by those with access
    \*/
    function transfer(address _token, address _to, uint _amount) public onlyAccess returns(bool) {
        require(_subtract(_token, _amount));
        require(IERC20(_token).transfer(_to, _amount));
        emit newTransfer(msg.sender, _to, _amount, _token);
        return true;
    }

    /*\
    used to increase allowance of _to from _token with _amount
    can only be used by those with access
    \*/
    function addAllowance(address _token, address _to, uint _amount) public onlyAccess returns(bool) {
        require(IERC20(_token).approve(_to, _amount));
        emit newApproval(_token, _to, _amount, msg.sender);
        return true;
    }

    /*\
    used to decrease allowance of _of from _token with _amount
    can only be used by those with access
    \*/
    function decreaseAllowance(address _token, address _of, uint _amount) public onlyAccess returns(bool) {
       require(IERC20(_token).decreaseAllowance(_of, _amount));
       emit newDecreaseAllowance(_token, _of, _amount, msg.sender);
       return true;
    }


///////////////////////////////////////////////////////////////
// MISC/VIEW/PRIVATE/EVENTS


    /*\
    used to show deposits of an address from _token
    return might be negative if wallet has more withdraws than deposits
    \*/
    function deposits(address _of, address _token) public view returns(int) {
        return deposited[_of][_token];
    }

    /*\
    shows total deposits tokens of _token
    \*/
    function totalDepositsOf(address _token) public view returns(uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /*\
    used to check if address has access to use functions as withdraw
    \*/
    function checkAccess(address _of) public view returns(bool) {
        return hasAccess[_of]; 
    }

    /*\
    shows all deposited tokens
    \*/
    function depositedTokens() public view returns(address[] memory) {
        return tokens;
    }

    /*\
    used at deposit
    can only be accessed by contract internally
    \*/
    function _add(address _token, uint _amount) private returns(bool) {
        deposited[msg.sender][_token] += int(_amount);
        if(!exists[_token]) {
            exists[_token] = true;
            tokens.push(_token);
        }
        return true;
    }

    /*\
    used at withdraw
    can only be accessed by contract internally
    \*/
    function _subtract(address _token, uint _amount) private returns(bool) {
        deposited[msg.sender][_token] -= int(_amount);
        if(totalDepositsOf(_token) == 0 && exists[_token]) {
            exists[_token] = false;
            require(_remove(_token));
        }
        return true;
    }

    /*\
    might be used at withdraw
    can only be accessed by contract internally
    \*/
    function _remove(address _token) private returns(bool) {
        uint index;
        for(uint i; i < tokens.length; i++) {
            if(tokens[i] == _token)
                index = i;
        }
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();

        for(uint i = index; i < tokens.length-1; i++){
            tokens[i] = tokens[i+1];      
        }
        tokens.pop();
        return true;
    } 


    event newDeposit(address indexed from, uint indexed amount, address indexed token); // deposit event
    event newWithdraw(address indexed to, uint indexed amount, address indexed token); // withdraw event
    event newTransfer(address indexed from, address indexed to, uint indexed amount, address token); // transfer event
    event newApproval(address indexed token, address indexed spender, uint indexed amount, address from); // increasing allowance event
    event newDecreaseAllowance(address indexed token, address indexed spender, uint indexed amount, address from); // decreasing allowance event
}