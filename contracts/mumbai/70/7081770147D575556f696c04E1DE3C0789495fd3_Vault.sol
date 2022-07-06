//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

import "./IERC20Permit.sol";

/**
 * @title Vault Contract
    Simple vault to demonstarte permit and transfer functionality of a wrapped ERC20 token with permit implementation. 
    This is a generalized vault that can accept any ERC20 token that allows permits.  
 * @author Shivali Sharma  
**/

contract Vault {
    address public owner;

    constructor() {
        owner = msg.sender;      
    }

    /**
     * @notice Function to transfer token using permit and transferFrom in a single transaction
     * @dev The permit and transferFrom are exposed using the interface contract IERC20Permit.sol
     * @param _token underlying ERC20 token that has permit implementation
     * @param _owner address of the owner 
     * @param _amount amount of tokens in uint
     * @param deadline The current blocktime should be less than or equal to 
     * @param v, r, s valid secp256k1 signature from owner of the message     
    */

    function depositWithPermit(address _token, address _owner, uint _amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit token = IERC20Permit(_token);
        token.permit(_owner, address(this), _amount, deadline, v, r, s);
        token.transferFrom(_owner, address(this), _amount);
    }

    function withdarw(address _token, address _recipient, uint _amount) external {
        require(msg.sender == owner, "Not authorized!");
        IERC20Permit token = IERC20Permit(_token);
        token.transfer(_recipient, _amount);
    }
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

/**
 * @author Shivali Sharma  
**/

interface IERC20Permit {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}