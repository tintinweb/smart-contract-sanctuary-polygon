// SPDX-License-Identifier: MIT
/*
 *
 *    Web:      
 *    Discord:  
 *    Twitter:  
 */


import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IterableMapping.sol";

pragma solidity 0.8.4;

contract SharesManager is Ownable, Pausable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct SharesEntity {
        string name;
        uint id;
        uint creationTime;
        uint lastClaimTime;
        uint256 amount;
        address owner;
    }

     struct Offer {
        bool isForSale;
        uint id;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public sharesOfferedForSale;

    IterableMapping.Map private sharesOwners;
    mapping(address => SharesEntity[]) private _sharesOfUser;
    SharesEntity[] public allShares;

    address public token;
    uint8 public rewardPerShares;
    uint256 public minPrice;

    uint256 public totalSharesCreated = 0;
    uint256 public maxSharesCreated = 10000;
    uint256 public totalStaked = 0;
    uint256 public totalClaimed = 0;
    uint256 public maxSharePerAccount = 10;

    event ShareCreated(
        uint256 indexed amount,
        address indexed account,
        uint indexed blockTime
    );

    event ShareOffered(uint indexed id, uint minValue, address indexed toAddress);
    event ShareBought(uint indexed id, uint value, address indexed fromAddress, address indexed toAddress);
    event ShareNoLongerForSale(uint indexed id);

    modifier onlyGuard() {
        require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");
        _;
    }

    modifier onlySharesOwner(address account) {
        require(isShareOwner(account), "NOT_OWNER");
        _;
    }

    constructor(
        uint8 _rewardPerShare,
        uint256 _minPrice
    ) {
        rewardPerShares = _rewardPerShare;
        minPrice = _minPrice;
    }

    // Private methods

    function _isNameAvailable(address account, string memory shareName)
        private
        view
        returns (bool)
    {
        SharesEntity[] memory shares = _sharesOfUser[account];
        for (uint256 i = 0; i < shares.length; i++) {
            if (keccak256(bytes(shares[i].name)) == keccak256(bytes(shareName))) {
                return false;
            }
        }
        return true;
    }


    function _uint2str(uint256 _i)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _calculateShareRewards(uint _lastClaimTime, uint256 amount_) private view returns (uint256 rewards) {
        uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
        uint256 rewardPerDay = amount_.mul(rewardPerShares).div(100);
        return ((rewardPerDay.mul(10000).div(1440) * (elapsedTime_ / 1 minutes)) / 10000);
    }

    function _getShareReward(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        SharesEntity[] storage shares = _sharesOfUser[account];
        require(
            shares.length > 0,
            "CASHOUT ERROR: You don't have shares to cash-out"
        );
        SharesEntity storage share = shares[id];
        return _calculateShareRewards(share.lastClaimTime, share.amount);
    }

    function _sharesAvailable()
        private
        view
        returns (bool)
    {
        if (totalSharesCreated >= maxSharesCreated) {
            return false;
        } else {
            return true;
        }
    }

    function _getIndexOfKey(address account) private view returns (int256) {
        require(account != address(0));
        return sharesOwners.getIndexOfKey(account);
    }

    function _burn(uint256 index) private  {
        require(index < sharesOwners.size());
        sharesOwners.remove(sharesOwners.getKeyAtIndex(index));
    }

    // External methods

    function createShare(address account, string memory shareName, uint256 amount_) external onlyGuard whenNotPaused {
        require(
            _sharesAvailable(), "Maximum Shares reached"
        );
        require(
            _isNameAvailable(account, shareName),
            "Name not available"
        );
        SharesEntity[] storage _shares = _sharesOfUser[account];
        require(_shares.length < maxSharePerAccount, "Max shares exceeded");
        _shares.push(
            SharesEntity({
                name: shareName,
                id: totalSharesCreated,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        allShares.push(
            SharesEntity({
                name: shareName,
                id: totalSharesCreated,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        sharesOwners.set(account, _sharesOfUser[account].length);
        emit ShareCreated(amount_, account, block.timestamp);
        totalSharesCreated++;
        totalStaked += amount_;
    }


    function getSharesRewards(address account)
        public
        view
        returns (uint256)
    {
        SharesEntity[] storage shares = _sharesOfUser[account];
        uint256 sharesCount = shares.length;
        require(sharesCount > 0, "NODE: CREATIME must be higher than zero");
        SharesEntity storage _share;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < sharesCount; i++) {
            _share = shares[i];
            rewardsTotal += _calculateShareRewards(_share.lastClaimTime, _share.amount);
        }
        return rewardsTotal;
    }

    function getCurrentShareOwnerOffer(uint id) external view returns (address) {
        Offer storage offer = sharesOfferedForSale[id];
        return offer.seller;
    }

    function compoundShareReward(address account)
        external
        onlyGuard
        onlySharesOwner(account)
        whenNotPaused
    {
        SharesEntity[] storage shares = _sharesOfUser[account];
        require(
            shares.length > 0,
            "CASHOUT ERROR: You don't have shares to cash-out"
        );
        for (uint256 i = 0; i < shares.length; i++) {
            SharesEntity storage share = shares[i];
            uint256 rewardAmount_ = _getShareReward(account, i);
            share.amount += rewardAmount_;
            share.lastClaimTime = block.timestamp;
        }
    }

    function compoundShareRewardId(address account, uint256 id)
        external
        onlyGuard
        onlySharesOwner(account)
        whenNotPaused
    {
        SharesEntity[] storage shares = _sharesOfUser[account];
        require(
            shares.length > 0,
            "CASHOUT ERROR: You don't have shares to cash-out"
        );
            SharesEntity storage share = shares[id];
            uint256 rewardAmount_ = _getShareReward(account, id);
            share.amount += rewardAmount_;
            share.lastClaimTime = block.timestamp;
    }

    function cashoutSharesRewards(address account)
        external
        onlyGuard
        onlySharesOwner(account)
        whenNotPaused
    {
        SharesEntity[] storage shares = _sharesOfUser[account];
        uint256 sharesCount = shares.length;
        require(sharesCount > 0, "NODE: CREATIME must be higher than zero");
        SharesEntity storage _share;
        for (uint256 i = 0; i < sharesCount; i++) {
            _share = shares[i];
            _share.lastClaimTime = block.timestamp;
        }
    }

    function getSharesNames(address account)
        public
        view
        onlySharesOwner(account)
        returns (string memory)
    {
        SharesEntity[] memory shares = _sharesOfUser[account];
        uint256 sharesCount = shares.length;
        SharesEntity memory _share;
        string memory names = shares[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < sharesCount; i++) {
            _share = shares[i];
            names = string(abi.encodePacked(names, separator, _share.name));
        }
        return names;
    }

    function getSharesCreationTime(address account)
        public
        view
        onlySharesOwner(account)
        returns (string memory)
    {
        SharesEntity[] memory shares = _sharesOfUser[account];
        uint256 sharesCount = shares.length;
        SharesEntity memory _share;
        string memory _creationTimes = _uint2str(shares[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < sharesCount; i++) {
            _share = shares[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    _uint2str(_share.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function getSharesLastClaimTime(address account)
        public
        view
        onlySharesOwner(account)
        returns (string memory)
    {
        SharesEntity[] memory shares = _sharesOfUser[account];
        uint256 sharesCount = shares.length;
        SharesEntity memory _share;
        string memory _lastClaimTimes = _uint2str(shares[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < sharesCount; i++) {
            _share = shares[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    _uint2str(_share.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function updateToken(address newToken) external onlyOwner {
        token = newToken;
    }

    function updateReward(uint8 newVal) external onlyOwner {
        rewardPerShares = newVal;
    }

    function updateMinPrice(uint256 newVal) external onlyOwner {
        minPrice = newVal;
    }

    function updateMaxShares(uint256 newVal) external onlyOwner {
        maxSharesCreated = newVal;
    }

    function updateMaxSharePerAccount(uint256 newVal) external onlyOwner {
        maxSharePerAccount = newVal;
    }

    function getMinPrice() external view returns (uint256) {
        return minPrice;
    }

    function isShareOwner(address account) public view returns (bool) {
        return sharesOwners.get(account) > 0;
    }

    function getShares(address account) external view returns (SharesEntity[] memory) {
        return _sharesOfUser[account];
    }

    function getIndexOfKey(address account) external view onlyGuard returns (int256) {
        require(account != address(0));
        return sharesOwners.getIndexOfKey(account);
    }

    function burn(uint256 index) external onlyGuard {
        require(index < sharesOwners.size());
        sharesOwners.remove(sharesOwners.getKeyAtIndex(index));
    }

    function offerShareToSale(uint256 minSalePriceInWei) external {
        address account = _msgSender();
        SharesEntity[] storage shares = _sharesOfUser[account];
        require(
            shares.length > 0,
            "CASHOUT ERROR: You don't have shares"
        );
        uint id = shares[0].id;
        sharesOfferedForSale[id] = Offer(true, id, msg.sender, minSalePriceInWei, address(0));
        emit ShareOffered(id, minSalePriceInWei, address(0));
    }


    function offerShareToSaleToAddress(uint256 minSalePriceInWei, address toAddress) external {
        address account = _msgSender();
        SharesEntity[] storage shares = _sharesOfUser[account];
        require(
            shares.length > 0,
            "CASHOUT ERROR: You don't have shares"
        );
        uint id = shares[0].id;
        sharesOfferedForSale[id] = Offer(true, id, msg.sender, minSalePriceInWei, toAddress);
        emit ShareOffered(id, minSalePriceInWei, toAddress);
    }
    
    function buyShare(uint id, uint256 _amount, string memory shareName, address account) external onlyGuard {
        Offer storage offer = sharesOfferedForSale[id];
        require(offer.isForSale, 'share not for sale');                // share not actually for sale
        require(offer.onlySellTo == address(0) || offer.onlySellTo == account, 'Offer is not available for this account');  // share not supposed to be sold to this user
        require(_amount > offer.minValue, 'amount is under minValue');      // Didn't send enough ETH
        require(offer.seller == allShares[id].owner, 'seller is not the owner'); // Seller no longer owner of punk

        SharesEntity[] storage _sharesSeller = _sharesOfUser[offer.seller];
        SharesEntity[] storage _sharesBuyer = _sharesOfUser[account];

        require(_sharesBuyer.length < 1, "Max shares exceeded");

        allShares[id].owner = account;
        allShares[id].name = shareName;
        uint256 amount_ = allShares[id].amount;

        int256 key = sharesOwners.getIndexOfKey(offer.seller);
        sharesOwners.remove(sharesOwners.getKeyAtIndex(uint256(key)));
        _sharesSeller.pop();
        _sharesBuyer.push(
            SharesEntity({
                name: shareName,
                id: id,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        sharesOwners.set(account, _sharesOfUser[account].length);
        shareNoLongerForSale(id, account);
        
        emit ShareBought(id, _amount, offer.seller, account);
    }

    function shareNoLongerForSale(uint id, address account) private {
        sharesOfferedForSale[id] = Offer(false, id, account, 0, address(0));

        emit ShareNoLongerForSale(id);
    }

    function shareNoLongerForSale(uint id) external {
        address account = _msgSender();
        require(allShares[id].owner == account, 'sender is not the owner');
        sharesOfferedForSale[id] = Offer(false, id, account, 0, address(0));

        emit ShareNoLongerForSale(id);
    }

}