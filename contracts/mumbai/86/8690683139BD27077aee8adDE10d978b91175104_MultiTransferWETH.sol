/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// File: contracts/MultiTransferWETH.sol

pragma solidity >=0.8;

interface IERC20 {
    function transferFrom(address, address, uint256) external;
}

contract MultiTransferWETH {
    // @dev: Mumbai WETH address: 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa
    // Polygon WETH address: 0x7ceb23fd6bc0add59e62ac25578270cff1b9f619
    address public constant WETH_ADDRESS = 0x3e6607adB9dfB40139dDf9Bead10643a5126b0f0;
    address public immutable owner;
    constructor() {
        owner = msg.sender;
    }
    
     // @dev: Before callign this function you need to go to 
     //https://polygonscan.com/token/0x7ceb23fd6bc0add59e62ac25578270cff1b9f619#writeContract
     // and approve the total amount of funds (sum of amountEarned)
     // use of the funds by the smart contract.
     // @param: users addresses that will receive the funds
     // @param: amountEarned balance that will be transfer to the user on the same index level
    
    function payoutUsers(address[] calldata users, uint[] calldata amountEarned) external {
        IERC20 weth = IERC20(WETH_ADDRESS);
        address _owner = owner;
        for(uint256 i = 0; i<users.length;) {
            weth.transferFrom(_owner, users[i], amountEarned[i]);
            unchecked {
                ++i;
            }
        }
    }
}