/**
 *Submitted for verification at polygonscan.com on 2023-04-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface BEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract Auth {
    address internal owner;
    address internal potentialOwner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) external onlyOwner {
        require(adr != owner, "OWNER cant be unauthorized");
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) external onlyOwner {
        require(adr != owner, "Already the owner");
        require(adr != address(0), "Can not be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;

        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
}

contract CircleLaunchpadApprover is Auth {
    bool public enableWhitelist;
    bool public enableBlacklist;
    mapping (address => bool) public whitelistedTokens;
    mapping (address => bool) public blacklistedTokens;

    constructor () Auth(msg.sender) {
        enableBlacklist = true;
        enableWhitelist = true;
    }

    receive() external payable { }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if(tokens == 0){
            tokens = BEP20(tokenAddress).balanceOf(address(this));
        }
        return BEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    } 

    function whitelistStatus(bool _status) external onlyOwner {
        enableWhitelist = _status;
    }
    function blacklistStatus(bool _status) external onlyOwner {
        enableBlacklist = _status;
    }

    function manageBlacklist(address[] calldata addresses, bool status) external authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            blacklistedTokens[addresses[i]] = status;
        }
    }
    function manageWhitelist(address[] calldata addresses, bool status) external authorized {
        for (uint256 i=0; i < addresses.length; ++i) {
            whitelistedTokens[addresses[i]] = status;
        }
    }
    function checkApproval(address _token) public view returns(bool) {
        bool status = true;
        if(enableWhitelist){
            status = whitelistedTokens[_token];
        }

        if(enableBlacklist && blacklistedTokens[_token]){
            status = false;
        }
        return status;
    }
}