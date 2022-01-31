/**
 *Submitted for verification at polygonscan.com on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
contract ICOHBlock {
    event NewContribution(address indexed holder, uint tokenAmount, uint maticAmount);
    uint tokensForPresale=35000000  * 10**18;
    uint public tokensSold=0;
    address public owner;
    mapping (address => uint256) private balances;
    address[] public investors;
    address public token=0x1b69D5b431825cd1fC68B8F883104835F3C72C80;
    bool public isIcoActive=true;
    modifier onlyOwner() {
        require(msg.sender == owner,"Not owner");
        _;
    }
    modifier icoActive() {
        require(isIcoActive,"ICO Not active");
        _;
    }
    modifier icoNotActive() {
        require(isIcoActive==false,"ICO active");
        _;
    }
    constructor(){
        owner=msg.sender;
    }
    function purchaseICO() public payable icoActive {
        uint tokens = msg.value*600;
        require((tokensSold+tokens) <= tokensForPresale,"Insufficient tokens left");
        tokensSold+=tokens;
        if(balances[msg.sender]==0){
            investors.push(msg.sender);
        }
        balances[msg.sender] += tokens;
        emit NewContribution(msg.sender, tokens, msg.value);
    }
    function sendAllTokensToContributors() public icoNotActive {
        for (uint i = 0; i <investors.length; i++) {
            if (balances[investors[i]]>0) {
                IERC20(token).transfer(investors[i], balances[investors[i]]);
                balances[investors[i]]=0;
            }
        }
    }
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function setIsIcoActive(bool active) public onlyOwner {
        isIcoActive = active;
    }
    function setToken(address _token) public onlyOwner {
        token = _token;
    }
    receive() external payable {}
    function withdraw() public icoNotActive onlyOwner {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
        payable(owner).transfer(address(this).balance);
    }
}