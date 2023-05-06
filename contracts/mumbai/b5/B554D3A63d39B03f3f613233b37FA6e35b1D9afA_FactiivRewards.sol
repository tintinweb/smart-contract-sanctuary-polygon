// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library FactiivRewards {

    address private constant NULL_ADDRESS = address(0);
    uint256 private constant PRECISION = 10**18;

    event PaidReward(
        address indexed from,
        address indexed to, 
        uint256 grossAmount, 
        uint256 netAmount, 
        uint256 allocatedToParent);

    struct App {
        uint256 parentSharePercent;             // portion of rewards to share with referrer
        mapping(address => Balance) balance;    // user balance with meta data
    }

    struct Balance {
        address parent;                         // usually a referrer, receives a portion of rewards earned by referrals
        uint256 user;                           // user balance available to withdraw or spend
        uint256 toParent;                       // funds to pass on to the parent
    }

    function setParentSharePercent(App storage self, uint256 _parentShare) public{
        require(_parentShare > 0, "FactiivRewards.setParentSharePercent:: Share is zero");
        self.parentSharePercent = _parentShare;
    }

    function initializeUser(App storage self, address user, address parent) public{
        Balance storage balance = self.balance[user];
        require(balance.parent == NULL_ADDRESS, "FactiivRewards:initializeUser:: User is already initialized");
        balance.parent = parent;
    }

    function isInitialized(App storage self, address user) public view returns(bool) {
        return self.balance[user].parent != NULL_ADDRESS;
    }

    function balanceOf(App storage self, address user) public view returns(uint256) {
        return self.balance[user].user;
    }

    function toParent(App storage self, address user) public view returns(uint256) {
        return self.balance[user].toParent;
    }

    function userParent(App storage self, address user) public view returns(address) {
        return self.balance[user].parent;
    }

    function add(App storage self, address user, uint256 amount) public{
        Balance storage bal = self.balance[user];
        bal.user += amount;
        sendUp(self, user);
    }

    function sub(App storage self, address user, uint256 amount) public{
        Balance storage bal = self.balance[user];
        bal.user -= amount;
        sendUp(self, user);
    }

    function payReward(App storage self, address user, uint256 reward) public{
        Balance storage bal = self.balance[user];
        uint256 _toParent = (bal.parent == user) ? 0 : (reward * self.parentSharePercent) / PRECISION;
        uint256 grossReward = reward;
        reward -= _toParent;
        bal.toParent += _toParent;
        bal.user += reward;
        emit PaidReward(
            user,
            bal.parent,
            grossReward, 
            reward, 
            grossReward - reward);        
        sendUp(self, user);
    }

    function sendUp(App storage self, address user) internal {
        Balance storage bal = self.balance[user];
        address parent = bal.parent;
        if(bal.toParent > 0) pullUp(self, parent, user);
    }

    function pullUp(App storage self, address user, address referral) internal {
        Balance storage userBalance = self.balance[user];
        Balance storage referralBalance = self.balance[referral];
        uint256 referralToParent = referralBalance.toParent;
        require(referralBalance.parent == user, "FactiivRewards.pullUp:: cannot pull from unrelated user");
        require(referralToParent > 0, "FactiivRewards.pullUp:: Not Enough To Pull");
        uint256 toUserParent = (referralToParent * self.parentSharePercent) / PRECISION;
        if(toUserParent > 0) {
            userBalance.toParent += toUserParent;
            userBalance.user += referralToParent - toUserParent;
            referralBalance.toParent = 0;
        }

        emit PaidReward(
            referral,
            user,
            referralToParent, 
            referralToParent - toUserParent,
            toUserParent); 
    }

}