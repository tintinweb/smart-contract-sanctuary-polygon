// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Affiliates.sol";

contract AffiliatesImpl is Affiliates {
    address private _proxy;

    mapping(address => uint256) private _affiliatesByAddress;
    mapping(string => uint256) private _affiliatesBySlug;
    Affiliate[] private _affiliates;

    constructor() {}

    modifier onlyProxy() {
        require(msg.sender == _proxy, "Not called from proxy");
        _;
    }

    modifier hasValidRegistrationData(address affiliateAddress, string memory slug) {
        if (_affiliates.length > 0) {
            require(
                _affiliates[_affiliatesByAddress[affiliateAddress]].affiliateAddress != affiliateAddress,
                "Already registerd as an Affiliate !!!"
            );
            require(!_compareStrings(_affiliates[_affiliatesBySlug[slug]].slug, slug), "Slug already taken !!!");
        }
        require(bytes(slug).length > 0, "Slug should not be empty !!!");
        require(!_compareStrings(slug, "_"), "Slug could not be _");
        _;
    }

    modifier isAffiliateByAddress(address affiliateAddress) {
        require(
            _affiliates.length > 0
             && _affiliates[_affiliatesByAddress[affiliateAddress]].affiliateAddress == affiliateAddress,
            "Not a valid affiliate !!!"
        );
        _;
    }

    function setProxy(address proxy) external {
        require(_proxy == address(0), "Proxy already set");
        _proxy = proxy;
    }

    function registerAffiliate(address affiliateAddress, string memory slug)
        external
        onlyProxy
        hasValidRegistrationData(affiliateAddress, slug)
    {
        _createAffiliate(affiliateAddress, slug);
    }

    function getAffiliateCount() external view onlyProxy returns (uint256) {
        return _affiliates.length;
    }

    function getAffiliates(uint256 start, uint256 maxReturnedCount)
        external
        view
        onlyProxy
        returns (Affiliate[] memory)
    {
        require(maxReturnedCount <= 100, "Only 100 affiliates can be requested at a time !!!");
        if (start > _affiliates.length) {
            start = _affiliates.length;
        }
        uint256 returnedResults = maxReturnedCount <= _affiliates.length - start
            ? maxReturnedCount
            : _affiliates.length - start;
        Affiliate[] memory result = new Affiliate[](returnedResults);
        for (uint256 i = 0; i < returnedResults; i++) {
            result[i] = _affiliates[i + start];
        }

        return result;
    }

    function registerAsAffiliate(address sender, string memory slug)
        external
        onlyProxy
        hasValidRegistrationData(sender, slug)
    {
        _createAffiliate(sender, slug);
    }

    function unregisterAsAffiliate(address sender) external onlyProxy isAffiliateByAddress(sender) {
        Affiliate storage affiliateLast = _affiliates[_affiliates.length - 1];
        Affiliate memory affiliateToRemove = _affiliates[_affiliatesByAddress[sender]];
        if (affiliateToRemove.balance > 0) {
            _claimProfit(sender);
        }

        affiliateLast.id = affiliateToRemove.id;
        _affiliates[affiliateToRemove.id] = affiliateLast;
        _affiliatesByAddress[affiliateLast.affiliateAddress] = affiliateLast.id;
        _affiliatesBySlug[affiliateLast.slug] = affiliateLast.id;

        _affiliatesByAddress[sender] = 0;
        _affiliatesBySlug[affiliateToRemove.slug] = 0;
        _affiliates.pop();
    }

    function getMyAffiliateInfo(address sender) external view onlyProxy isAffiliateByAddress(sender) returns (Affiliate memory) {
        return _affiliates[_affiliatesByAddress[sender]];
    }

    function isAffiliate(address sender) external view onlyProxy returns (bool) {
        if (_affiliates.length == 0) {
            return false;
        }
        return _affiliates[_affiliatesByAddress[sender]].affiliateAddress == sender;
    }

    function isAffiliateBySlug(string memory slug) external view onlyProxy returns (bool) {
        if (_affiliates.length == 0) {
            return false;
        }
        return _compareStrings(_affiliates[_affiliatesBySlug[slug]].slug, slug);
    }

    function getAffiliateBySlug(string memory slug) external view onlyProxy returns (Affiliate memory) {
        require(
            _affiliates.length > 0 
            && _compareStrings(_affiliates[_affiliatesBySlug[slug]].slug, slug),
            "Not a valid affiliate !!!"
        );
        return _affiliates[_affiliatesBySlug[slug]];
    }

    function claimProfit(address sender) external onlyProxy isAffiliateByAddress(sender) {
        _claimProfit(sender);
    }

    function registerSell(address affiliateAddress, uint256 itemsCount) external payable onlyProxy returns (uint256) {
        Affiliate storage affiliate = _affiliates[_affiliatesByAddress[affiliateAddress]];
        affiliate.totalSoldItems += itemsCount;
        affiliate.balance += msg.value;
        return affiliate.balance;
    }

    function _claimProfit(address sender) private {
        uint256 index = _affiliatesByAddress[sender];
        Affiliate storage affiliate = _affiliates[index];
        require(affiliate.balance > 0, "No profit or profit already claimed !!!");
        uint256 balance = affiliate.balance;
        affiliate.balance = 0;
        (bool success, ) = sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _createAffiliate(address affiliateAddress, string memory slug) private returns (uint256) {
        Affiliate memory affiliate = Affiliate({
            id: _affiliates.length,
            totalSoldItems: 0,
            balance: 0,
            affiliateAddress: affiliateAddress,
            slug: slug
        });
        _affiliates.push(affiliate);
        _affiliatesByAddress[affiliateAddress] = affiliate.id;
        _affiliatesBySlug[slug] = affiliate.id;
        return affiliate.id;
    }

    function kill() external onlyProxy {
        selfdestruct(payable(msg.sender));
    }
}